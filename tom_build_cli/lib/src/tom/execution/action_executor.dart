/// Action execution for Tom CLI.
///
/// Handles the execution of actions on projects, including
/// placeholder resolution, template processing, and command execution.
///
/// ## Processing Phases
///
/// Tom CLI processes configuration through three distinct phases:
///
/// ### 1. Generation Phase (tom_master*.yaml construction)
///
/// | Type | Syntax | Description |
/// |------|--------|-------------|
/// | Environment | `[[VAR:-default]]` | Environment variable |
/// | Data Path | `[{path.to.value:-default}]` | Config value lookup |
///
/// These are resolved when writing tom_master*.yaml files.
///
/// ### 2. Runtime Phase (placeholder resolution)
///
/// | Type | Syntax | Description |
/// |------|--------|-------------|
/// | Value Reference | `$VAL{key.path:-default}` | Config value |
/// | Environment | `$ENV{NAME:-default}` | Environment variable |
/// | D4rt Expression | `$D4{expression}` | D4rt evaluation |
/// | D4rt Script | `$D4S{file.dart}` | Script file |
/// | D4rt Multiline Script | `$D4S\n<code>` | Inline script |
/// | D4rt Multiline Method | `$D4M\n<code>` | Method returning value |
/// | Generator | `$GEN{path.*.field;sep}` | Path expansion |
/// | Environment | `[[VAR]]` | Also at runtime |
/// | Data Path | `[{path}]` | Also at runtime |
///
/// These are resolved after loading YAML, before command execution.
///
/// ### 3. Execution Phase (command execution)
///
/// | Type | Syntax | Description |
/// |------|--------|-------------|
/// | Shell | `dart analyze lib` | Shell command |
/// | Tom CLI | `tom: :analyze` | Internal commands only |
/// | VS Code | `vscode: script.dart` | Via VS Code Bridge |
/// | DartScript | `dartscript: script.dart` | Local D4rt execution |
/// | Reflection | `Class.method()` | Method call |
///
/// Commands are executed sequentially after placeholder resolution.
///
/// ## D4rt Integration
///
/// Each action execution creates a new [ActionD4rtContext] to ensure:
/// - The same D4rt instance is used for all evaluations within an action
/// - A separate D4rt instance is created for each action
/// - All bridge classes are properly registered
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:tom_build/tom_build.dart';
import 'package:tom_dartscript_bridges/tom_dartscript_bridges.dart' show VSCodeBridgeClient, VSCodeBridgeResult;
import '../../dartscript/d4rt_instance.dart';
import '../template/tomplate_parser.dart';
import '../template/tomplate_processor.dart';
import '../cli/tom_cli.dart';
import 'command_runner.dart';
import 'd4rt_runner.dart';

// =============================================================================
// ACTION EXECUTOR
// =============================================================================

/// Configuration for action execution.
class ActionExecutorConfig {
  /// Path to the workspace root directory.
  final String workspacePath;

  /// Path to the .tom_metadata directory containing master files.
  final String? metadataPath;

  /// Whether to run in verbose mode.
  final bool verbose;

  /// Whether to run in dry-run mode (no actual execution).
  final bool dryRun;

  /// Environment variables to use during execution.
  final Map<String, String> environment;

  /// Creates action executor configuration.
  const ActionExecutorConfig({
    required this.workspacePath,
    this.metadataPath,
    this.verbose = false,
    this.dryRun = false,
    this.environment = const {},
  });

  /// Gets the metadata directory path.
  String get metadataDir => metadataPath ?? '$workspacePath/.tom_metadata';
}

/// Result of executing an action on a project.
class ActionExecutionResult {
  /// The project name.
  final String projectName;

  /// The action name.
  final String actionName;

  /// Whether execution was successful.
  final bool success;

  /// List of command results.
  final List<CommandResult> commandResults;

  /// Error message if execution failed.
  final String? error;

  /// Duration of execution.
  final Duration duration;

  const ActionExecutionResult._({
    required this.projectName,
    required this.actionName,
    required this.success,
    required this.commandResults,
    required this.duration,
    this.error,
  });

  /// Creates a successful result.
  factory ActionExecutionResult.success({
    required String projectName,
    required String actionName,
    required List<CommandResult> commandResults,
    required Duration duration,
  }) {
    return ActionExecutionResult._(
      projectName: projectName,
      actionName: actionName,
      success: true,
      commandResults: commandResults,
      duration: duration,
    );
  }

  /// Creates a failed result.
  factory ActionExecutionResult.failure({
    required String projectName,
    required String actionName,
    required String error,
    List<CommandResult> commandResults = const [],
    Duration duration = Duration.zero,
  }) {
    return ActionExecutionResult._(
      projectName: projectName,
      actionName: actionName,
      success: false,
      commandResults: commandResults,
      duration: duration,
      error: error,
    );
  }
}

/// Executes actions on projects.
///
/// The execution flow is:
/// 1. Load tom_master_<action>.yaml
/// 2. Create D4rt context for script execution
/// 3. Resolve $ENV{} placeholders
/// 4. Process .tomplate files to target files
/// 5. Execute pre-commands
/// 6. Execute commands
/// 7. Execute post-commands
/// 8. Dispose D4rt context
///
/// ## D4rt Instance Management
///
/// Each action execution creates a new [ActionD4rtContext] which:
/// - Creates a fresh D4rt instance with all bridges registered
/// - Uses the same instance for all D4rt evaluations within the action
/// - Is disposed when the action completes (success or failure)
class ActionExecutor {
  /// Creates an action executor.
  ActionExecutor({
    required this.config,
    CommandRunner? commandRunner,
    TomplateProcessor? tomplateProcessor,
  })  : _commandRunner = commandRunner ?? CommandRunner(),
        _tomplateProcessor = tomplateProcessor ?? TomplateProcessor();

  /// Executor configuration.
  final ActionExecutorConfig config;

  final CommandRunner _commandRunner;
  final TomplateProcessor _tomplateProcessor;
  final TomplateParser _tomplateParser = TomplateParser();

  // Cache for loaded master files
  final Map<String, TomMaster> _masterCache = {};

  /// Executes an action on a project.
  ///
  /// Parameters:
  /// - [actionName]: The action to execute (e.g., 'build', 'test')
  /// - [projectName]: The project to execute on
  /// - [additionalModes]: Additional modes to apply
  /// - [parameters]: Action-specific parameters
  ///
  /// ## D4rt Instance
  ///
  /// A new D4rt instance is created for this action and disposed when complete.
  /// The same instance is used for all D4rt evaluations within this action.
  Future<ActionExecutionResult> executeAction({
    required String actionName,
    required String projectName,
    Set<String>? additionalModes,
    Map<String, String>? parameters,
  }) async {
    final stopwatch = Stopwatch()..start();
    final commandResults = <CommandResult>[];

    // Create D4rt context for this action execution
    // This ensures a separate D4rt instance for each action
    final d4rtContext = ActionD4rtContext(
      workspacePath: config.workspacePath,
      projectName: projectName,
      actionName: actionName,
      additionalContext: {
        'parameters': parameters ?? {},
        'additionalModes': additionalModes?.toList() ?? [],
      },
    );

    try {
      // 1. Load master file for this action
      final master = await _loadMaster(actionName);

      // 2. Get project configuration
      final project = master.projects[projectName];
      if (project == null) {
        return ActionExecutionResult.failure(
          projectName: projectName,
          actionName: actionName,
          error: 'Project [$projectName] not found in master file for action [$actionName]\n'
              '  Resolution: Run :analyze to regenerate master files, or check project name spelling',
        );
      }

      // 3. Get action definition for this project
      final actionDef = project.actions[actionName];
      if (actionDef == null) {
        return ActionExecutionResult.failure(
          projectName: projectName,
          actionName: actionName,
          error: 'Action [$actionName] not defined for project [$projectName]\n'
              '  Resolution: Add action definition in tom_project.yaml or workspace actions:',
        );
      }

      // 4. Resolve project path
      final projectPath = _resolveProjectPath(projectName);

      // 5. Process tomplate files for this project
      await _processTomplates(
        projectPath: projectPath,
        project: project,
        master: master,
      );

      // 6. Get merged environment
      final environment = _mergeEnvironment(project);

      // Initialize the global tom context for D4rt scripts
      // This makes tom.project, tom.workspace, etc. available to dartscript commands
      initializeTomContext(
        workspace: master,
        currentProject: project,
        workspacePath: config.workspacePath,
      );

      // Re-register the tom global with the D4rt interpreter
      // This is necessary because the D4rtInstance was created before
      // initializeTomContext was called with the project, so the tom
      // variable registered during instance creation had no project info.
      d4rtContext.instance.updateTomGlobal();

      // Add project and master context to D4rt
      final contextMap = {
        'project': project.toYaml(),
        'master': master.toYaml(),
        'environment': environment,
      };
      d4rtContext.instance.setContextAll(contextMap);

      // Dump context information for debugging
      if (config.verbose) {
        try {
          final dumpFile = File('$projectPath/tom.$actionName.dump.info');
          // Use JsonEncoder for pretty-printed output of the context map
          const encoder = JsonEncoder.withIndent('  ');
          final dumpContent = encoder.convert(contextMap);
          await dumpFile.writeAsString(dumpContent);
          _log('Context dump written to: ${dumpFile.path}');
        } catch (e) {
          _log('Context dump failed: $e');
        }
      }

      // 7. Execute pre-commands
      final preCommands = actionDef.defaultConfig?.preCommands ?? [];
      for (final cmd in preCommands) {
        final result = await _executeCommand(
          command: cmd,
          workingDirectory: projectPath,
          environment: environment,
          d4rtContext: d4rtContext,
        );
        commandResults.add(result);
        if (!result.success) {
          return ActionExecutionResult.failure(
            projectName: projectName,
            actionName: actionName,
            error: 'Pre-command failed: $cmd',
            commandResults: commandResults,
            duration: stopwatch.elapsed,
          );
        }
      }

      // 8. Execute main commands
      final commands = actionDef.defaultConfig?.commands ?? [];
      for (final cmd in commands) {
        final result = await _executeCommand(
          command: cmd,
          workingDirectory: projectPath,
          environment: environment,
          d4rtContext: d4rtContext,
        );
        commandResults.add(result);
        if (!result.success) {
          if (config.verbose) {
            _log('Command failed. stderr: ${result.stderr}');
          }
          return ActionExecutionResult.failure(
            projectName: projectName,
            actionName: actionName,
            error: 'Command failed: $cmd',
            commandResults: commandResults,
            duration: stopwatch.elapsed,
          );
        }
      }

      // 9. Execute post-commands
      final postCommands = actionDef.defaultConfig?.postCommands ?? [];
      for (final cmd in postCommands) {
        final result = await _executeCommand(
          command: cmd,
          workingDirectory: projectPath,
          environment: environment,
          d4rtContext: d4rtContext,
        );
        commandResults.add(result);
        if (!result.success) {
          return ActionExecutionResult.failure(
            projectName: projectName,
            actionName: actionName,
            error: 'Post-command failed: $cmd',
            commandResults: commandResults,
            duration: stopwatch.elapsed,
          );
        }
      }

      stopwatch.stop();
      return ActionExecutionResult.success(
        projectName: projectName,
        actionName: actionName,
        commandResults: commandResults,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return ActionExecutionResult.failure(
        projectName: projectName,
        actionName: actionName,
        error: e.toString(),
        commandResults: commandResults,
        duration: stopwatch.elapsed,
      );
    } finally {
      // Always dispose the D4rt context when action completes
      d4rtContext.dispose();
    }
  }

  /// Executes an action on multiple projects in order.
  ///
  /// Uses the action order from the master file to determine execution order.
  Future<List<ActionExecutionResult>> executeActionOnProjects({
    required String actionName,
    required List<String> projectNames,
    bool stopOnFailure = true,
  }) async {
    final results = <ActionExecutionResult>[];

    // Load master to get action order
    final master = await _loadMaster(actionName);

    // Get the ordered list for this action
    final actionOrder = master.actionOrder[actionName] ?? master.buildOrder;

    // Filter to only the requested projects, maintaining order
    final orderedProjects =
        actionOrder.where((p) => projectNames.contains(p)).toList();

    // Add any requested projects not in the order (alphabetically)
    final unorderedProjects =
        projectNames.where((p) => !actionOrder.contains(p)).toList()..sort();
    orderedProjects.addAll(unorderedProjects);

    for (final projectName in orderedProjects) {
      final result = await executeAction(
        actionName: actionName,
        projectName: projectName,
      );
      results.add(result);

      if (!result.success && stopOnFailure) {
        break;
      }
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Private Methods
  // ---------------------------------------------------------------------------

  /// Loads the master file for an action.
  Future<TomMaster> _loadMaster(String actionName) async {
    // Check cache first
    if (_masterCache.containsKey(actionName)) {
      return _masterCache[actionName]!;
    }

    // Load from file
    final fileName = 'tom_master_$actionName.yaml';
    final filePath = '${config.metadataDir}/$fileName';
    final file = File(filePath);

    if (!file.existsSync()) {
      throw StateError(
        'Master file not found for action [$actionName]\n'
        '  File: [$filePath]\n'
        '  Resolution: Run :analyze first to generate master files, '
        'or verify action [$actionName] is in action-mode-configuration',
      );
    }

    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as Map;
    final yamlMap = _convertYamlMapToMap(yaml);

    final master = TomMaster.fromYaml(yamlMap);
    _masterCache[actionName] = master;
    return master;
  }

  /// Converts YAML map to regular Dart map.
  Map<String, dynamic> _convertYamlMapToMap(Map yaml) {
    final result = <String, dynamic>{};
    for (final entry in yaml.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is Map) {
        result[key] = _convertYamlMapToMap(value);
      } else if (value is List) {
        result[key] = _convertYamlListToList(value);
      } else {
        result[key] = value;
      }
    }
    return result;
  }

  /// Converts YAML list to regular Dart list.
  List<dynamic> _convertYamlListToList(List yaml) {
    return yaml.map((e) {
      if (e is Map) {
        return _convertYamlMapToMap(e);
      } else if (e is List) {
        return _convertYamlListToList(e);
      } else {
        return e;
      }
    }).toList();
  }

  /// Resolves the project path.
  String _resolveProjectPath(String projectName) {
    return '${config.workspacePath}/$projectName';
  }

  /// Processes tomplate files for a project.
  Future<void> _processTomplates({
    required String projectPath,
    required TomProject project,
    required TomMaster master,
  }) async {
    // Find all .tomplate files in the project
    final projectDir = Directory(projectPath);
    if (!projectDir.existsSync()) return;

    await for (final entity in projectDir.list(recursive: true)) {
      if (entity is File &&
          (entity.path.endsWith('.tomplate') ||
              entity.path.contains('.tomplate.'))) {
        await _processSingleTomplate(
          file: entity,
          project: project,
          master: master,
        );
      }
    }
  }

  /// Processes a single tomplate file.
  Future<void> _processSingleTomplate({
    required File file,
    required TomProject project,
    required TomMaster master,
  }) async {
    final template = _tomplateParser.parseFile(file.path);

    // Build context from master file
    final context = <String, dynamic>{
      'workspace': master.toYaml(),
      'project': project.toYaml(),
      'projects': master.projects.map((k, v) => MapEntry(k, v.toYaml())),
    };

    // Merge environment
    final environment = _mergeEnvironment(project);

    // Process with all placeholder types
    final processed = _tomplateProcessor.process(
      template: template,
      context: context,
      resolveEnvironment: true,
      environment: environment,
      resolveGenerators: true,
    );

    // Write to target file (unless dry-run)
    if (!config.dryRun) {
      _tomplateProcessor.writeToFile(processed);
    }

    if (config.verbose) {
      _log('Processed: ${file.path} -> ${processed.targetPath}');
    }
  }

  /// Merges environment variables.
  Map<String, String> _mergeEnvironment(TomProject project) {
    final result = <String, String>{};

    // Start with system environment
    result.addAll(Platform.environment);

    // Add config environment
    result.addAll(config.environment);

    // Add project-specific environment (if defined in customTags)
    final projectEnv = project.customTags['environment'];
    if (projectEnv is Map) {
      for (final entry in projectEnv.entries) {
        result[entry.key.toString()] = entry.value.toString();
      }
    }

    return result;
  }

  /// Executes a single command.
  ///
  /// Commands can be:
  /// - Map: `{shell: 'dart pub get'}`, `{dartscript: 'print("hello")'}`
  /// - String (legacy): `'dart pub get'` (treated as shell command)
  ///
  /// Map command keys:
  /// - `shell` - Shell command to execute
  /// - `dartscript` - D4rt code to execute
  /// - `vscode` - VS Code command to execute
  /// - `tom` - Tom CLI internal command
  ///
  /// Legacy string prefixes (for backwards compatibility):
  /// - `dartscript: <code>` - Execute D4rt code locally
  /// - `vscode: <script.dart>` - Execute via VS Code bridge
  /// - `tom: <:command>` - Execute Tom CLI internal command
  /// - Other strings - Execute as shell command
  Future<CommandResult> _executeCommand({
    required dynamic command,
    required String workingDirectory,
    required Map<String, String> environment,
    required ActionD4rtContext d4rtContext,
  }) async {
    // Handle map-based commands (new schema)
    if (command is Map) {
      return _executeMapCommand(
        command: command,
        workingDirectory: workingDirectory,
        environment: environment,
        d4rtContext: d4rtContext,
      );
    }

    // Handle string commands (legacy format with prefix detection)
    final commandStr = command.toString();

    // Resolve $ENV{} placeholders in command
    final resolvedCommand = _resolveEnvironmentPlaceholders(
      commandStr,
      environment,
    );

    if (config.verbose) {
      _log('Executing: $resolvedCommand');
    }

    // Check if this is a Tom CLI command (tom: prefix)
    if (resolvedCommand.isTomCommand) {
      return _executeTomCommand(
        command: resolvedCommand,
        workingDirectory: workingDirectory,
        environment: environment,
      );
    }

    // Check if this is a VS Code simple command (vscode: prefix, not $VSCODE)
    if (resolvedCommand.isVSCodeSimpleCommand) {
      return _executeVSCodeSimpleCommand(
        command: resolvedCommand,
        workingDirectory: workingDirectory,
      );
    }

    // Check if this is a VS Code D4rt placeholder command ($VSCODE prefix)
    if (resolvedCommand.isVSCodeCommand) {
      return _executeVSCodeCommand(
        command: resolvedCommand,
        workingDirectory: workingDirectory,
      );
    }

    // Check if this is a DartScript simple command (dartscript: prefix, not $D4)
    if (resolvedCommand.isDartscriptSimpleCommand) {
      return _executeDartscriptSimpleCommand(
        command: resolvedCommand,
        d4rtContext: d4rtContext,
        workingDirectory: workingDirectory,
      );
    }

    // Check if this is a local D4rt command (placeholder syntax $D4{}, etc.)
    if (resolvedCommand.isLocalD4rtCommand) {
      return _executeD4rtCommand(
        command: resolvedCommand,
        d4rtContext: d4rtContext,
        workingDirectory: workingDirectory,
      );
    }

    if (config.dryRun) {
      return CommandResult.success(
        command: resolvedCommand,
        stdout: '[dry-run] Would execute: $resolvedCommand',
        duration: Duration.zero,
      );
    }

    return await _commandRunner.run(
      command: resolvedCommand,
      workingDirectory: workingDirectory,
      environment: environment,
      verbose: config.verbose,
    );
  }

  /// Executes a map-based command.
  ///
  /// The map must have exactly one of these keys as the command type:
  /// - `shell` - Shell command to execute
  /// - `dartscript` - D4rt code to execute
  /// - `vscode` - VS Code command to execute
  /// - `tom` - Tom CLI internal command
  ///
  /// Additional keys can provide options:
  /// - `sudo` - Run with sudo (shell only)
  /// - `timeout` - Command timeout in seconds
  /// - `workingDir` - Override working directory
  Future<CommandResult> _executeMapCommand({
    required Map command,
    required String workingDirectory,
    required Map<String, String> environment,
    required ActionD4rtContext d4rtContext,
  }) async {
    // Determine command type from map key
    final commandType = _getCommandType(command);
    if (commandType == null) {
      return CommandResult.failure(
        command: command.toString(),
        stderr: 'Invalid command: Map must have one of: shell, dartscript, vscode, tom',
        exitCode: 1,
        duration: Duration.zero,
      );
    }

    final commandBody = command[commandType]?.toString() ?? '';
    final resolvedBody = _resolveEnvironmentPlaceholders(commandBody, environment);

    if (config.verbose) {
      _log('Executing [$commandType]: ${resolvedBody.length > 80 ? '${resolvedBody.substring(0, 80)}...' : resolvedBody}');
    }

    switch (commandType) {
      case 'shell':
        if (config.dryRun) {
          return CommandResult.success(
            command: resolvedBody,
            stdout: '[dry-run] Would execute shell: $resolvedBody',
            duration: Duration.zero,
          );
        }
        return await _commandRunner.run(
          command: resolvedBody,
          workingDirectory: workingDirectory,
          environment: environment,
          verbose: config.verbose,
        );

      case 'dartscript':
        // Use the existing dartscript execution logic
        // Prefix with 'dartscript: ' so the existing method can parse it
        return _executeDartscriptSimpleCommand(
          command: 'dartscript: $resolvedBody',
          d4rtContext: d4rtContext,
          workingDirectory: workingDirectory,
        );

      case 'vscode':
        return _executeVSCodeSimpleCommand(
          command: 'vscode: $resolvedBody',
          workingDirectory: workingDirectory,
        );

      case 'tom':
        return _executeTomCommand(
          command: 'tom: $resolvedBody',
          workingDirectory: workingDirectory,
          environment: environment,
        );

      default:
        return CommandResult.failure(
          command: command.toString(),
          stderr: 'Unknown command type: $commandType',
          exitCode: 1,
          duration: Duration.zero,
        );
    }
  }

  /// Determines the command type from a map command.
  ///
  /// Returns the first recognized key: `shell`, `dartscript`, `vscode`, `tom`.
  /// Returns null if no recognized key is found.
  String? _getCommandType(Map command) {
    const validTypes = ['shell', 'dartscript', 'vscode', 'tom'];
    for (final type in validTypes) {
      if (command.containsKey(type)) {
        return type;
      }
    }
    return null;
  }

  /// Executes a Tom CLI command directly without spawning a process.
  ///
  /// Commands starting with `tom:` execute internal commands only.
  /// This prevents recursive action invocation and ensures `tom:` is used
  /// only for built-in operations like `:analyze`, `:vscode`, `:dartscript`.
  ///
  /// The command line is parsed using shell-style argument splitting,
  /// which handles quoted strings properly:
  /// - `tom: :analyze` → `[':analyze']`
  /// - `tom: :vscode "print('hello')"` → `[':vscode', "print('hello')"]`
  ///
  /// Example: `tom: :analyze` → executes TomCli with `[':analyze']`
  Future<CommandResult> _executeTomCommand({
    required String command,
    required String workingDirectory,
    required Map<String, String> environment,
  }) async {
    final stopwatch = Stopwatch()..start();
    final argsList = command.tomCommandArgsList;
    final argsDisplay = command.tomCommandArgs;

    // Validate that the command is an internal command (starts with :)
    if (argsList.isEmpty) {
      stopwatch.stop();
      return CommandResult.failure(
        command: command,
        stderr: 'tom: command requires an internal command\n'
            '  Usage: tom: :command [args...]\n'
            '  Example: tom: :analyze\n'
            '  Available: :analyze, :vscode, :dartscript, :help, etc.',
        exitCode: 1,
        duration: stopwatch.elapsed,
      );
    }

    final firstArg = argsList.first;
    if (!firstArg.startsWith(':')) {
      stopwatch.stop();
      return CommandResult.failure(
        command: command,
        stderr: 'tom: only allows internal commands (starting with :)\n'
            '  Got: $firstArg\n'
            '  Usage: tom: :command [args...]\n'
            '  Example: tom: :analyze\n'
            '  Note: Actions cannot be invoked via tom: to prevent recursion',
        exitCode: 1,
        duration: stopwatch.elapsed,
      );
    }

    if (config.dryRun) {
      stopwatch.stop();
      return CommandResult.success(
        command: command,
        stdout: '[dry-run] Would execute Tom CLI: tom $argsDisplay',
        duration: stopwatch.elapsed,
      );
    }

    if (config.verbose) {
      _log('Executing Tom CLI: tom $argsDisplay');
    }

    try {
      // Change to working directory for the CLI execution
      final previousDir = Directory.current.path;
      Directory.current = workingDirectory;

      // Execute Tom CLI directly without spawning a process
      final exitCode = await runTomCli(argsList);

      // Restore previous directory
      Directory.current = previousDir;

      stopwatch.stop();

      if (exitCode == 0) {
        return CommandResult.success(
          command: command,
          stdout: '',
          duration: stopwatch.elapsed,
        );
      } else {
        return CommandResult.failure(
          command: command,
          stderr: 'Tom CLI exited with code $exitCode',
          stdout: '',
          exitCode: exitCode,
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return CommandResult.failure(
        command: command,
        stderr: 'Failed to execute Tom CLI: $e',
        exitCode: 1,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes a D4rt command.
  ///
  /// Supports:
  /// - D4rt expression: `$D4{expr}`
  /// - D4rt script file: `$D4S{file.dart}`
  /// - D4rt multiline script: String starting with `$D4S\n`
  /// - D4rt multiline method: String starting with `$D4M\n`
  /// - Reflection call: `Class.method()`
  Future<CommandResult> _executeD4rtCommand({
    required String command,
    required ActionD4rtContext d4rtContext,
    required String workingDirectory,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (config.dryRun) {
      stopwatch.stop();
      return CommandResult.success(
        command: command,
        stdout: '[dry-run] Would execute D4rt: $command',
        duration: stopwatch.elapsed,
      );
    }

    try {
      // Create a D4rt runner with the action's evaluator
      final runner = D4rtRunner(
        config: D4rtRunnerConfig(
          workspacePath: config.workspacePath,
          context: d4rtContext.context,
        ),
        evaluator: createEvaluatorFromContext(d4rtContext),
      );

      final result = await runner.run(command);
      stopwatch.stop();

      if (result.success) {
        return CommandResult.success(
          command: command,
          stdout: result.output,
          duration: result.duration,
        );
      } else {
        return CommandResult.failure(
          command: command,
          stderr: result.error ?? 'D4rt execution failed',
          exitCode: 1,
          duration: result.duration,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return CommandResult.failure(
        command: command,
        stderr: 'D4rt error: $e',
        exitCode: 1,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes a VS Code bridge command.
  ///
  /// Connects to the VS Code VS Code Bridge via socket and executes
  /// the command there. Supports:
  /// - VS Code expression: `$VSCODE{expr}` or `$VSCODE:{port}expr`
  /// - VS Code script file: `$VSCODE{S:file.dart}` or `$VSCODE:{port}S:file.dart`
  /// - VS Code multiline script: `$VSCODE{S:\n...}` or `$VSCODE:{port}S:\n...`
  /// - VS Code multiline method: `$VSCODE{M:\n...}` or `$VSCODE:{port}M:\n...`
  Future<CommandResult> _executeVSCodeCommand({
    required String command,
    required String workingDirectory,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (config.dryRun) {
      stopwatch.stop();
      return CommandResult.success(
        command: command,
        stdout: '[dry-run] Would execute via VS Code bridge: $command',
        duration: stopwatch.elapsed,
      );
    }

    // Extract port and command body using String extensions
    final port = command.vscodeCommandPort;
    final body = command.vscodeCommandBody;

    // Create client with custom port if specified
    final client = port != null
        ? VSCodeBridgeClient(port: port)
        : VSCodeBridgeClient();

    if (!await client.connect()) {
      stopwatch.stop();
      return CommandResult.failure(
        command: command,
        stderr: 'Failed to connect to VS Code VS Code Bridge on port '
            '${client.port}. Ensure the CLI integration server is running '
            '(use Command Palette: "DS: Start Tom CLI Integration Server").',
        exitCode: 1,
        duration: stopwatch.elapsed,
      );
    }

    try {
      VSCodeBridgeResult result;

      // Parse the body (now in $D4{...} format)
      if (body.startsWith(r'$D4{') && body.endsWith('}')) {
        // Expression: $D4{expr}
        final expr = body.substring(4, body.length - 1).trim();
        result = await client.executeExpression(expr);
      } else if (body.startsWith(r'$D4S{') && body.endsWith('}')) {
        // Script file: $D4S{file.dart}
        final filePath = body.substring(5, body.length - 1).trim();
        result = await client.executeScriptFile(filePath);
      } else if (body.startsWith(r'$D4S')) {
        // Multiline script: $D4S\n...
        final code = body.substring(4).trimLeft();
        result = await client.executeScript(code);
      } else if (body.startsWith(r'$D4M')) {
        // Multiline method: $D4M\n...
        final code = body.substring(4).trimLeft();
        // Wrap in immediate invocation for method syntax
        result = await client.executeExpression('($code)()');
      } else {
        stopwatch.stop();
        return CommandResult.failure(
          command: command,
          stderr: 'Unknown VS Code command format: $command',
          exitCode: 1,
          duration: stopwatch.elapsed,
        );
      }

      stopwatch.stop();
      await client.disconnect();

      if (result.success) {
        return CommandResult.success(
          command: command,
          stdout: result.output,
          duration: result.duration,
        );
      } else {
        return CommandResult.failure(
          command: command,
          stderr: result.error ?? 'VS Code bridge execution failed',
          exitCode: 1,
          duration: result.duration,
        );
      }
    } catch (e) {
      stopwatch.stop();
      await client.disconnect();
      return CommandResult.failure(
        command: command,
        stderr: 'VS Code bridge error: $e',
        exitCode: 1,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes a VS Code simple command (not a placeholder).
  ///
  /// Connects to the VS Code VS Code Bridge via socket and executes
  /// the command there. Supports:
  /// - `vscode: script.dart` - execute a script file
  /// - `vscode: "code..."` - execute inline code
  /// - `vscode:9743: script.dart` - with custom port
  Future<CommandResult> _executeVSCodeSimpleCommand({
    required String command,
    required String workingDirectory,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (config.dryRun) {
      stopwatch.stop();
      return CommandResult.success(
        command: command,
        stdout: '[dry-run] Would execute via VS Code bridge: $command',
        duration: stopwatch.elapsed,
      );
    }

    // Extract port and command body using String extensions
    final port = command.vscodeSimpleCommandPort;
    final body = command.vscodeSimpleCommandBody;

    // Create client with custom port if specified
    final client = port != null
        ? VSCodeBridgeClient(port: port)
        : VSCodeBridgeClient();

    if (!await client.connect()) {
      stopwatch.stop();
      return CommandResult.failure(
        command: command,
        stderr: 'Failed to connect to VS Code VS Code Bridge on port '
            '${client.port}. Ensure the CLI integration server is running '
            '(use Command Palette: "DS: Start Tom CLI Integration Server").',
        exitCode: 1,
        duration: stopwatch.elapsed,
      );
    }

    try {
      VSCodeBridgeResult result;

      // Check if this is inline code (quoted string) or a file
      if (body.startsWith('"') && body.endsWith('"')) {
        // Inline code: "print('hello')"
        final code = body.substring(1, body.length - 1);
        result = await client.executeScript(code);
      } else if (body.startsWith("'") && body.endsWith("'")) {
        // Inline code with single quotes: 'print("hello")'
        final code = body.substring(1, body.length - 1);
        result = await client.executeScript(code);
      } else if (body.endsWith('.dart')) {
        // Script file: script.dart
        result = await client.executeScriptFile(body);
      } else {
        // Treat as inline code
        result = await client.executeScript(body);
      }

      stopwatch.stop();
      await client.disconnect();

      if (result.success) {
        return CommandResult.success(
          command: command,
          stdout: result.output,
          duration: result.duration,
        );
      } else {
        return CommandResult.failure(
          command: command,
          stderr: result.error ?? 'VS Code bridge execution failed',
          exitCode: 1,
          duration: result.duration,
        );
      }
    } catch (e) {
      stopwatch.stop();
      await client.disconnect();
      return CommandResult.failure(
        command: command,
        stderr: 'VS Code bridge error: $e',
        exitCode: 1,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes a DartScript simple command (local execution).
  ///
  /// DartScript simple commands use `dartscript:` prefix and execute locally (not via VS Code).
  /// Supports:
  /// - `dartscript: script.dart` - execute a script file
  /// - `dartscript: "code..."` - execute inline code
  /// - `dartscript:9743: script.dart` - with custom port (reserved for future)
  Future<CommandResult> _executeDartscriptSimpleCommand({
    required String command,
    required ActionD4rtContext d4rtContext,
    required String workingDirectory,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (config.dryRun) {
      stopwatch.stop();
      return CommandResult.success(
        command: command,
        stdout: '[dry-run] Would execute D4rt locally: $command',
        duration: stopwatch.elapsed,
      );
    }

    // Extract command body (strip dartscript: prefix)
    final body = command.dartscriptSimpleCommandBody;

    try {
      // Create a D4rt runner with the action's evaluator
      final runner = D4rtRunner(
        config: D4rtRunnerConfig(
          workspacePath: config.workspacePath,
          context: d4rtContext.context,
        ),
        evaluator: createEvaluatorFromContext(d4rtContext),
      );

      D4rtResult result;

      // Check if this is inline code (quoted string) or a file
      if (body.startsWith('"') && body.endsWith('"')) {
        // Inline code: "print('hello')"
        final code = body.substring(1, body.length - 1);
        result = await runner.run(code);
      } else if (body.startsWith("'") && body.endsWith("'")) {
        // Inline code with single quotes: 'print("hello")'
        final code = body.substring(1, body.length - 1);
        result = await runner.run(code);
      } else if (body.endsWith('.dart')) {
        // Script file: script.dart
        result = await runner.run(body);
      } else {
        // Treat as inline code
        // Use eval() instead of executeScript() to preserve the global environment
        // from the initialization script (tom, env, project, etc. are available)
        final capturedOutput = StringBuffer();
        dynamic evalResult;
        var success = true;
        String? error;
        
        try {
          evalResult = await runZoned(
            () => d4rtContext.instance.evaluate(body),
            zoneSpecification: ZoneSpecification(
              print: (self, parent, zone, line) {
                capturedOutput.writeln(line);
                parent.print(zone, line);
              },
            ),
          );
        } catch (e) {
          success = false;
          error = e.toString();
        }

        if (success) {
           final resultStr = evalResult?.toString() ?? '';
           if (resultStr.isNotEmpty && resultStr != 'null') {
             capturedOutput.writeln(resultStr);
           }
           
           result = D4rtResult.success(
             code: body,
             value: evalResult,
             output: capturedOutput.toString().trim(),
           );
        } else {
           result = D4rtResult.failure(
             code: body,
             error: error ?? 'Unknown error',
             output: capturedOutput.toString().trim(),
           );
        }
      }

      stopwatch.stop();

      if (result.success) {
        return CommandResult.success(
          command: command,
          stdout: result.output,
          duration: result.duration,
        );
      } else {
        return CommandResult.failure(
          command: command,
          stderr: result.error ?? 'D4rt execution failed',
          exitCode: 1,
          duration: result.duration,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return CommandResult.failure(
        command: command,
        stderr: 'D4rt error: $e',
        exitCode: 1,
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Resolves $ENV{NAME:-default} placeholders.
  String _resolveEnvironmentPlaceholders(
    String content,
    Map<String, String> environment,
  ) {
    final pattern = RegExp(r'\$ENV\{([^}:]+)(?::-([^}]*))?\}');

    return content.replaceAllMapped(pattern, (match) {
      final envVar = match.group(1)!;
      final defaultValue = match.group(2);

      final value = environment[envVar];
      if (value != null) {
        return value;
      } else if (defaultValue != null) {
        return defaultValue;
      }

      // Leave unresolved
      return match.group(0)!;
    });
  }

  /// Logs a message.
  void _log(String message) {
    // ignore: avoid_print
    print(message);
  }
}
