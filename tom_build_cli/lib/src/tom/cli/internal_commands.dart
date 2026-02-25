// Internal Commands for Tom CLI
//
// Implements tom_tool_specification.md Section 6.4:
// - :analyze - Run workspace analyzer
// - :version-bump - Increment versions for changed packages
// - :reset-action-counter - Reset action counter to 0
// - :pipeline - Execute named pipeline
// - :generate-reflection - Run reflection generator
// - :generate-bridges - Generate D4rt BridgedClass implementations
// - :md2pdf - Convert markdown to PDF
// - :md2latex - Convert markdown to LaTeX
// - :prepper - Run mode processing
// - :vscode - Execute Dart via VS Code VS Code Bridge
// - :dartscript - Execute Dart locally via D4rt (default command)

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'git_helper.dart';
import 'version_bumper.dart';
import 'workspace_context.dart';
import '../execution/action_executor.dart';
import 'package:tom_build/tom_build.dart';
import 'package:tom_build/src/md_pdf_converter/md_pdf_converter.dart' show MdPdfConverterOptions;
import '../mode/mode_resolver.dart';
import '../template/tomplate_parser.dart';
import '../template/tomplate_processor.dart';
import '../execution/d4rt_runner.dart';
import 'package:tom_dartscript_bridges/tom_dartscript_bridges.dart' show VSCodeBridgeClient, VSCodeBridgeResult, defaultVSCodeBridgePort;

// =============================================================================
// INTERNAL COMMAND REGISTRY
// =============================================================================

/// Registry of all internal commands.
///
/// Internal commands are prefixed with `:` and can be chained with actions.
class InternalCommands {
  InternalCommands._();

  /// All registered internal commands.
  static const Map<String, InternalCommandInfo> commands = {
    'analyze': InternalCommandInfo(
      name: 'analyze',
      prefix: 'wa',
      description: 'Run workspace analyzer, generate all tom_master*.yaml files',
      requiresWorkspace: true,
    ),
    'generate-reflection': InternalCommandInfo(
      name: 'generate-reflection',
      prefix: 'gr',
      description: 'Run reflection generator',
      requiresWorkspace: true,
    ),
    'generate-bridges': InternalCommandInfo(
      name: 'generate-bridges',
      prefix: 'gb',
      description: 'Generate D4rt BridgedClass implementations from Dart classes',
      requiresWorkspace: false,
    ),
    'md2pdf': InternalCommandInfo(
      name: 'md2pdf',
      prefix: 'mp',
      description: 'Convert markdown to PDF',
      requiresWorkspace: false,
    ),
    'md2latex': InternalCommandInfo(
      name: 'md2latex',
      prefix: 'ml',
      description: 'Convert markdown to LaTeX',
      requiresWorkspace: false,
    ),
    'version-bump': InternalCommandInfo(
      name: 'version-bump',
      prefix: 'vb',
      description: 'Increment versions for changed packages',
      requiresWorkspace: true,
    ),
    'prepper': InternalCommandInfo(
      name: 'prepper',
      prefix: 'wp',
      description: 'Run mode processing (tomplate preparation) manually',
      requiresWorkspace: true,
    ),
    'reset-action-counter': InternalCommandInfo(
      name: 'reset-action-counter',
      prefix: null,
      description: 'Reset the global action counter',
      requiresWorkspace: true,
    ),
    'pipeline': InternalCommandInfo(
      name: 'pipeline',
      prefix: null,
      description: 'Run a named pipeline',
      requiresWorkspace: true,
    ),
    'help': InternalCommandInfo(
      name: 'help',
      prefix: null,
      description: 'Show help information',
      requiresWorkspace: false,
    ),
    'version': InternalCommandInfo(
      name: 'version',
      prefix: null,
      description: 'Show version information',
      requiresWorkspace: false,
    ),
    'vscode': InternalCommandInfo(
      name: 'vscode',
      prefix: null,
      description: 'Execute Dart code via VS Code VS Code Bridge',
      requiresWorkspace: false,
    ),
    'dartscript': InternalCommandInfo(
      name: 'dartscript',
      prefix: null,
      description: 'Execute Dart code locally via D4rt',
      requiresWorkspace: false,
    ),
  };

  /// Checks if a command name is an internal command.
  static bool isInternalCommand(String name) {
    return commands.containsKey(name);
  }

  /// Gets info for an internal command.
  static InternalCommandInfo? getCommand(String name) {
    return commands[name];
  }

  /// Gets the prefix for a command, or null if none.
  static String? getPrefix(String name) {
    return commands[name]?.prefix;
  }

  /// Gets the command name for a prefix, or null if not found.
  static String? getCommandForPrefix(String prefix) {
    for (final entry in commands.entries) {
      if (entry.value.prefix == prefix) {
        return entry.key;
      }
    }
    return null;
  }
}

/// Information about an internal command.
class InternalCommandInfo {
  const InternalCommandInfo({
    required this.name,
    required this.prefix,
    required this.description,
    required this.requiresWorkspace,
  });

  /// The command name (without : prefix).
  final String name;

  /// The argument prefix for this command (e.g., 'wa' for analyze).
  final String? prefix;

  /// Description of what the command does.
  final String description;

  /// Whether this command requires a workspace to be present.
  final bool requiresWorkspace;
}

// =============================================================================
// INTERNAL COMMAND EXECUTOR
// =============================================================================

/// Configuration for internal command execution.
class InternalCommandConfig {
  const InternalCommandConfig({
    required this.workspacePath,
    this.metadataPath,
    this.verbose = false,
    this.dryRun = false,
    this.projects = const [],
    this.groups = const [],
  });

  /// Path to the workspace root.
  final String workspacePath;

  /// Path to the metadata directory. Defaults to .tom_metadata.
  final String? metadataPath;

  /// Whether to print verbose output.
  final bool verbose;

  /// Whether to run in dry-run mode (no changes).
  final bool dryRun;

  /// Projects to limit scope to.
  final List<String> projects;

  /// Groups to limit scope to.
  final List<String> groups;

  /// Gets the metadata directory path.
  String get metadataDir => metadataPath ?? '$workspacePath/.tom_metadata';

  /// Gets the workspace state file path.
  String get stateFilePath => '$metadataDir/workspace_state.yaml';
}

/// Result of an internal command execution.
class InternalCommandResult {
  const InternalCommandResult._({
    required this.command,
    required this.success,
    this.message,
    this.error,
    required this.duration,
  });

  /// Creates a successful result.
  factory InternalCommandResult.success({
    required String command,
    String? message,
    required Duration duration,
  }) {
    return InternalCommandResult._(
      command: command,
      success: true,
      message: message,
      duration: duration,
    );
  }

  /// Creates a failed result.
  factory InternalCommandResult.failure({
    required String command,
    required String error,
    required Duration duration,
  }) {
    return InternalCommandResult._(
      command: command,
      success: false,
      error: error,
      duration: duration,
    );
  }

  /// The command that was executed.
  final String command;

  /// Whether the command succeeded.
  final bool success;

  /// Success message.
  final String? message;

  /// Error message if failed.
  final String? error;

  /// How long the command took.
  final Duration duration;
}

/// Executes internal commands.
///
/// Per Section 6.4, internal commands:
/// - Are prefixed with `:` on the command line
/// - Can be chained with actions
/// - Increment action counter before execution
class InternalCommandExecutor {
  InternalCommandExecutor({
    required this.config,
    ActionCounterManager? counterManager,
  }) : _counterManager = counterManager ??
            ActionCounterManager(stateFilePath: config.stateFilePath);

  /// Configuration for execution.
  final InternalCommandConfig config;

  /// Action counter manager.
  final ActionCounterManager _counterManager;

  /// Executes an internal command.
  ///
  /// Parameters:
  /// - [commandName]: The command to execute (without : prefix)
  /// - [parameters]: Command-specific parameters
  Future<InternalCommandResult> execute({
    required String commandName,
    Map<String, String> parameters = const {},
  }) async {
    final stopwatch = Stopwatch()..start();

    // Check if command exists
    final commandInfo = InternalCommands.getCommand(commandName);
    if (commandInfo == null) {
      stopwatch.stop();
      final availableCommands = InternalCommands.commands.keys.map((c) => ':$c').join(', ');
      return InternalCommandResult.failure(
        command: commandName,
        error: 'Unknown internal command: [:$commandName]\n'
            '  Available commands: $availableCommands\n'
            '  Resolution: Use :help to see all available commands',
        duration: stopwatch.elapsed,
      );
    }

    // Check workspace requirement
    if (commandInfo.requiresWorkspace) {
      final workspaceFile = File('${config.workspacePath}/tom_workspace.yaml');
      if (!workspaceFile.existsSync()) {
        stopwatch.stop();
        return InternalCommandResult.failure(
          command: commandName,
          error: 'Command [:$commandName] requires a Tom workspace\n'
              '  Searched: [${workspaceFile.path}]\n'
              '  Resolution: Navigate to a directory containing tom_workspace.yaml '
              'or create one with tom :init',
          duration: stopwatch.elapsed,
        );
      }
    }

    // Increment action counter before execution
    await _counterManager.increment();

    try {
      // Execute the command
      final result = await _executeCommand(
        commandName: commandName,
        parameters: parameters,
      );
      stopwatch.stop();
      return result.success
          ? InternalCommandResult.success(
              command: commandName,
              message: result.message,
              duration: stopwatch.elapsed,
            )
          : InternalCommandResult.failure(
              command: commandName,
              error: result.error ?? 'Unknown error',
              duration: stopwatch.elapsed,
            );
    } catch (e) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: commandName,
        error: 'Command :$commandName failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes the actual command.
  Future<InternalCommandResult> _executeCommand({
    required String commandName,
    required Map<String, String> parameters,
  }) async {
    switch (commandName) {
      case 'reset-action-counter':
        return _executeResetActionCounter();
      case 'analyze':
        return _executeAnalyze(parameters);
      case 'version-bump':
        return _executeVersionBump(parameters);
      case 'pipeline':
        return _executePipeline(parameters);
      case 'generate-reflection':
        return _executeGenerateReflection(parameters);
      case 'generate-bridges':
        return _executeGenerateBridges(parameters);
      case 'md2pdf':
        return _executeMd2Pdf(parameters);
      case 'md2latex':
        return _executeMd2Latex(parameters);
      case 'prepper':
        return _executePrepper(parameters);
      case 'help':
        return _executeHelp();
      case 'version':
        return _executeVersion();
      case 'vscode':
        return _executeVscode(parameters);
      case 'dartscript':
        return _executeDartscript(parameters);
      default:
        return InternalCommandResult.failure(
          command: commandName,
          error: 'Command :$commandName is not yet implemented',
          duration: Duration.zero,
        );
    }
  }

  /// Executes :reset-action-counter command.
  Future<InternalCommandResult> _executeResetActionCounter() async {
    await _counterManager.reset();
    return InternalCommandResult.success(
      command: 'reset-action-counter',
      message: 'Action counter reset to 0',
      duration: Duration.zero,
    );
  }

  /// Executes :analyze command.
  Future<InternalCommandResult> _executeAnalyze(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();

    if (config.dryRun) {
      return InternalCommandResult.success(
        command: 'analyze',
        message: '[dry-run] Would run workspace analyzer',
        duration: Duration.zero,
      );
    }

    try {
      // Load or get cached workspace context
      final context = await WorkspaceContext.load(config.workspacePath);

      // Generate master files using MasterGenerator
      final result = await context.ensureMasterFilesGenerated();

      stopwatch.stop();

      if (!result.success) {
        return InternalCommandResult.failure(
          command: 'analyze',
          error: result.message,
          duration: stopwatch.elapsed,
        );
      }

      return InternalCommandResult.success(
        command: 'analyze',
        message: 'Workspace analysis complete - ${result.message}',
        duration: stopwatch.elapsed,
      );
    } on WorkspaceContextException catch (e) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'analyze',
        error: e.message,
        duration: stopwatch.elapsed,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'analyze',
        error: 'Unexpected error during workspace analysis\n'
            '  Error: $e\n'
            '  Stack: $stack',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes :version-bump command.
  Future<InternalCommandResult> _executeVersionBump(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();
    final bumpType = parseBumpType(parameters['type']);

    if (config.dryRun) {
      return InternalCommandResult.success(
        command: 'version-bump',
        message: '[dry-run] Would bump versions\n'
            '  Bump type: ${bumpType.name}',
        duration: Duration.zero,
      );
    }

    try {
      // Load workspace context
      final context = await WorkspaceContext.load(config.workspacePath);

      // Initialize git helper
      final git = GitHelper(workspacePath: config.workspacePath);
      if (!git.isGitRepository()) {
        stopwatch.stop();
        return InternalCommandResult.failure(
          command: 'version-bump',
          error: 'Workspace is not a git repository\n'
              '  Resolution: Initialize git with `git init`',
          duration: stopwatch.elapsed,
        );
      }

      // Get publishable projects
      final publishableProjects = <String, String>{};
      for (final entry in context.projects.entries) {
        final projectEntry = context.workspace.projectInfo[entry.key];
        final isPublishable =
            projectEntry?.settings['publishable'] as bool? ?? false;
        if (isPublishable) {
          // Get path from project-info settings or use project name
          final projectPath = (projectEntry?.settings['path'] as String?) ?? entry.key;
          publishableProjects[entry.key] = projectPath;
        }
      }

      if (publishableProjects.isEmpty) {
        stopwatch.stop();
        return InternalCommandResult.success(
          command: 'version-bump',
          message: 'No publishable projects found',
          duration: stopwatch.elapsed,
        );
      }

      // Filter by scope if specified
      final targetProjects = <String, String>{};
      if (config.projects.isNotEmpty) {
        for (final name in config.projects) {
          if (publishableProjects.containsKey(name)) {
            targetProjects[name] = publishableProjects[name]!;
          }
        }
      } else if (config.groups.isNotEmpty) {
        for (final groupName in config.groups) {
          final group = context.groups[groupName];
          if (group != null) {
            for (final projectName in group.projects) {
              if (publishableProjects.containsKey(projectName)) {
                targetProjects[projectName] = publishableProjects[projectName]!;
              }
            }
          }
        }
      } else {
        targetProjects.addAll(publishableProjects);
      }

      // Detect changed projects
      final changedProjects = <String, String>{};
      for (final entry in targetProjects.entries) {
        final hasChanges = await git.hasProjectChanges(entry.value);
        if (hasChanges) {
          changedProjects[entry.key] = entry.value;
        }
      }

      if (changedProjects.isEmpty) {
        stopwatch.stop();
        return InternalCommandResult.success(
          command: 'version-bump',
          message: 'No changes detected in publishable projects',
          duration: stopwatch.elapsed,
        );
      }

      // Bump versions
      final bumper = VersionBumper(
        workspacePath: config.workspacePath,
        dryRun: config.dryRun,
        verbose: config.verbose,
      );

      final bumpResults = <VersionBumpResult>[];
      for (final entry in changedProjects.entries) {
        final result = await bumper.bumpVersion(
          entry.value,
          bumpType: bumpType,
        );
        bumpResults.add(result);
      }

      // Check for failures
      final failures = bumpResults.where((r) => !r.success).toList();
      if (failures.isNotEmpty) {
        stopwatch.stop();
        return InternalCommandResult.failure(
          command: 'version-bump',
          error: 'Some version bumps failed:\n'
              '${failures.map((f) => "  ${f.projectPath}: ${f.error}").join("\n")}',
          duration: stopwatch.elapsed,
        );
      }

      // Commit changes
      final projectNames = changedProjects.keys.join(', ');
      final commitMessage = 'chore: bump versions for $projectNames';
      final committed = await git.commitAll(commitMessage);

      if (!committed) {
        stopwatch.stop();
        return InternalCommandResult.failure(
          command: 'version-bump',
          error: 'Failed to commit version changes\n'
              '  Resolution: Check git status and resolve any issues',
          duration: stopwatch.elapsed,
        );
      }

      // Build summary
      final summary = StringBuffer()..writeln('Version bump complete:');
      for (final result in bumpResults) {
        summary.writeln(
            '  ${result.projectPath}: ${result.oldVersion} → ${result.newVersion}');
      }
      summary.writeln('  Committed: $commitMessage');

      stopwatch.stop();
      return InternalCommandResult.success(
        command: 'version-bump',
        message: summary.toString(),
        duration: stopwatch.elapsed,
      );
    } on WorkspaceContextException catch (e) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'version-bump',
        error: e.message,
        duration: stopwatch.elapsed,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'version-bump',
        error: 'Unexpected error during version bump\n'
            '  Error: $e\n'
            '  Stack: $stack',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes :pipeline command.
  Future<InternalCommandResult> _executePipeline(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();

    final pipelineName = parameters['name'];
    if (pipelineName == null || pipelineName.isEmpty) {
      return InternalCommandResult.failure(
        command: 'pipeline',
        error: 'Pipeline name required\n'
            '  Usage: :pipeline -name=<pipeline-name>\n'
            '  Resolution: Provide a valid pipeline name defined in tom_workspace.yaml',
        duration: Duration.zero,
      );
    }

    try {
      // Load workspace context to get pipeline definitions
      final context = await WorkspaceContext.load(config.workspacePath);
      final pipeline = context.pipelines[pipelineName];

      if (pipeline == null) {
        final availablePipelines = context.pipelines.keys.toList();
        stopwatch.stop();
        return InternalCommandResult.failure(
          command: 'pipeline',
          error: 'Pipeline "$pipelineName" not found\n'
              '  Available pipelines: ${availablePipelines.isEmpty ? "(none defined)" : availablePipelines.join(", ")}\n'
              '  Resolution: Check pipeline name in tom_workspace.yaml',
          duration: stopwatch.elapsed,
        );
      }

      // Collect actions to execute
      final actionsToRun = <String>[];
      for (final action in pipeline.actions) {
        actionsToRun.add(action.action);
      }

      // If no actions defined but projects are, use default "build" action
      if (actionsToRun.isEmpty && pipeline.projects.isNotEmpty) {
        actionsToRun.add('build');
      }

      // Get project names for scope limiting
      final projectNames = pipeline.projects.map((p) => p.name).toList();

      if (config.dryRun) {
        final summary = StringBuffer()
          ..writeln('[dry-run] Would execute pipeline "$pipelineName":')
          ..writeln('  Projects: ${projectNames.isEmpty ? "(all)" : projectNames.join(", ")}')
          ..writeln('  Actions: ${actionsToRun.join(", ")}');
        stopwatch.stop();
        return InternalCommandResult.success(
          command: 'pipeline',
          message: summary.toString(),
          duration: stopwatch.elapsed,
        );
      }

      // Execute pipeline actions
      final actionExecutor = ActionExecutor(
        config: ActionExecutorConfig(
          workspacePath: config.workspacePath,
          metadataPath: config.metadataDir,
          verbose: config.verbose,
          dryRun: config.dryRun,
        ),
      );

      final results = <ActionExecutionResult>[];
      for (final actionName in actionsToRun) {
        List<ActionExecutionResult> actionResults;
        if (projectNames.isNotEmpty) {
          // Run on specific projects
          actionResults = await actionExecutor.executeActionOnProjects(
            actionName: actionName,
            projectNames: projectNames,
          );
        } else {
          // Run on all projects (get from master)
          final master = await _loadMasterFile(actionName);
          if (master == null) {
            stopwatch.stop();
            return InternalCommandResult.failure(
              command: 'pipeline',
              error: 'Master file not found for action "$actionName"\n'
                  '  Resolution: Run :analyze first',
              duration: stopwatch.elapsed,
            );
          }
          actionResults = await actionExecutor.executeActionOnProjects(
            actionName: actionName,
            projectNames: master.projects.keys.toList(),
          );
        }
        results.addAll(actionResults);

        // Check for failures
        final failures = actionResults.where((r) => !r.success).toList();
        if (failures.isNotEmpty) {
          stopwatch.stop();
          return InternalCommandResult.failure(
            command: 'pipeline',
            error: 'Pipeline "$pipelineName" failed on action "$actionName"\n'
                '  ${failures.map((f) => "${f.projectName}: ${f.error}").join("\n  ")}',
            duration: stopwatch.elapsed,
          );
        }
      }

      // Build success summary
      final summary = StringBuffer()
        ..writeln('Pipeline "$pipelineName" completed successfully:')
        ..writeln('  Actions executed: ${actionsToRun.join(", ")}')
        ..writeln('  Projects: ${results.map((r) => r.projectName).toSet().join(", ")}');

      stopwatch.stop();
      return InternalCommandResult.success(
        command: 'pipeline',
        message: summary.toString(),
        duration: stopwatch.elapsed,
      );
    } on WorkspaceContextException catch (e) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'pipeline',
        error: e.message,
        duration: stopwatch.elapsed,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'pipeline',
        error: 'Unexpected error executing pipeline\n'
            '  Error: $e\n'
            '  Stack: $stack',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes :generate-reflection command.
  ///
  /// Parameters:
  /// - `gr-mode`: Mode to run in ('generate' or 'build', default: 'build')
  /// - `gr-target`: Target file, directory, or glob pattern (for generate mode)
  /// - `gr-all`: Process directories recursively (for generate mode)
  /// - `gr-verbose`: Enable verbose output
  /// - `gr-package`: Package name (default: 'tom_reflection')
  /// - `gr-extension`: Output extension (default: '.reflection.dart')
  ///
  /// For projects specified in config, runs on each project directory.
  Future<InternalCommandResult> _executeGenerateReflection(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Parse parameters
    final mode = parameters['mode'] ?? 'build';
    final target = parameters['target'];
    final allMode = parameters['all']?.toLowerCase() == 'true';
    final verbose = parameters['verbose']?.toLowerCase() == 'true' || config.verbose;
    final packageName = parameters['package'] ?? 'tom_reflection';
    final extension = parameters['extension'] ?? '.reflection.dart';

    if (config.dryRun) {
      final targetProjects = config.projects.isEmpty
          ? ['(all projects at workspace root)']
          : config.projects;
      return InternalCommandResult.success(
        command: 'generate-reflection',
        message: '[dry-run] Would run reflection generator\n'
            '  Mode: $mode\n'
            '  Projects: ${targetProjects.join(", ")}',
        duration: Duration.zero,
      );
    }

    try {
      // Determine which project directories to process
      final projectDirs = <String>[];

      if (config.projects.isNotEmpty) {
        // Use projects from config - project names are the relative paths
        for (final projectName in config.projects) {
          // Project name is the folder name relative to workspace root
          final projectDir = Directory('${config.workspacePath}/$projectName');
          if (projectDir.existsSync()) {
            projectDirs.add(projectName);
          } else if (verbose) {
            print('  Warning: Project directory not found: $projectName');
          }
        }
      } else {
        // No specific projects - run on workspace root
        projectDirs.add('.');
      }

      if (projectDirs.isEmpty) {
        stopwatch.stop();
        return InternalCommandResult.failure(
          command: 'generate-reflection',
          error: 'No valid projects found to process',
          duration: stopwatch.elapsed,
        );
      }

      final results = <ReflectionGeneratorRunnerResult>[];

      for (final projectDir in projectDirs) {
        final absoluteDir = projectDir == '.'
            ? config.workspacePath
            : '${config.workspacePath}/$projectDir';

        // Create reflection generator for this project
        final generator = ReflectionGeneratorRunner(
          absoluteDir,
          options: ReflectionGeneratorRunnerOptions(
            verbose: verbose,
            packageName: packageName,
            extension: extension,
          ),
        );

        if (verbose) {
          print('  Running reflection generator for: $absoluteDir');
        }

        // Run the appropriate mode
        final ReflectionGeneratorRunnerResult result;
        if (mode == 'generate') {
          result = await generator.generate(
            target: target ?? 'lib/',
            all: allMode,
          );
        } else {
          result = await generator.build();
        }

        results.add(result);
      }

      stopwatch.stop();

      final hasErrors = results.any((r) => !r.success);
      final resultMessages = results.map((r) => r.toString()).join('\n');

      if (hasErrors) {
        return InternalCommandResult.failure(
          command: 'generate-reflection',
          error: 'Reflection generation completed with errors\n'
              '$resultMessages',
          duration: stopwatch.elapsed,
        );
      }

      return InternalCommandResult.success(
        command: 'generate-reflection',
        message: 'Reflection generation completed\n'
            '$resultMessages',
        duration: stopwatch.elapsed,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'generate-reflection',
        error: 'Unexpected error during reflection generation\n'
            '  Error: $e\n'
            '  Stack: $stack',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes :generate-bridges command.
  ///
  /// Generates D4rt BridgedClass implementations by calling the external
  /// tom_d4rt_generator CLI tool. This command delegates to the generator
  /// instead of using an embedded analyzer to allow tom_build to be
  /// compiled as a standalone binary.
  ///
  /// Parameters:
  /// - `gb-project`: Project directory to generate bridges for
  /// - `gb-config`: Explicit path to d4rt_bridging.json config file
  /// - `gb-verbose`: Enable verbose output (default: false)
  Future<InternalCommandResult> _executeGenerateBridges(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Parse parameters
    final projectPath = parameters['project'] ?? config.workspacePath;
    final configPath = parameters['config'];
    final verbose = parameters['verbose']?.toLowerCase() == 'true' || config.verbose;

    if (config.dryRun) {
      return InternalCommandResult.success(
        command: 'generate-bridges',
        message: '[dry-run] Would run d4rt_generator:\n'
            '  Project: $projectPath\n'
            '  Config: ${configPath ?? "(from build.yaml or d4rt_bridging.json)"}\n'
            '  Verbose: $verbose',
        duration: Duration.zero,
      );
    }

    try {
      // Build command arguments
      final args = <String>[];
      
      if (configPath != null) {
        args.addAll(['--config', configPath]);
      } else {
        args.addAll(['--project', projectPath]);
      }
      
      if (verbose) {
        args.add('--verbose');
      }

      // Try to run the d4rt_generator CLI
      // First try as a dart run command (for development)
      ProcessResult result;
      
      // Check if we're in a workspace with tom_d4rt_generator
      final generatorPath = p.join(p.dirname(config.workspacePath), 'tom_d4rt_generator');
      if (Directory(generatorPath).existsSync()) {
        // Run from local package
        result = await Process.run(
          'dart',
          ['run', 'bin/d4rt_generator.dart', ...args],
          workingDirectory: generatorPath,
        );
      } else {
        // Try to run as global/activated package
        result = await Process.run(
          'dart',
          ['run', 'tom_d4rt_generator:d4rt_generator', ...args],
          workingDirectory: projectPath,
        );
      }

      stopwatch.stop();

      if (result.exitCode != 0) {
        return InternalCommandResult.failure(
          command: 'generate-bridges',
          error: 'Bridge generation failed\n'
              '  Exit code: ${result.exitCode}\n'
              '  Stderr: ${result.stderr}',
          duration: stopwatch.elapsed,
        );
      }

      return InternalCommandResult.success(
        command: 'generate-bridges',
        message: 'Bridge generation complete:\n${result.stdout}',
        duration: stopwatch.elapsed,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'generate-bridges',
        error: 'Failed to run d4rt_generator\n'
            '  Error: $e\n'
            '  Stack: $stack\n'
            '  Resolution: Ensure tom_d4rt_generator is available',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes :md2pdf command.
  ///
  /// Converts a markdown file to PDF using pandoc.
  ///
  /// Parameters:
  /// - `mp-input` or `mp-file`: Input markdown file path
  /// - `mp-output`: Output PDF file path (optional, defaults to input.pdf)
  /// - `mp-template`: LaTeX template to use (optional)
  /// - `mp-toc`: Include table of contents (default: false)
  /// - `mp-highlight`: Syntax highlighting style (default: tango)
  Future<InternalCommandResult> _executeMd2Pdf(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();
    final inputFile = parameters['input'] ?? parameters['file'];
    final outputFile = parameters['output'];
    final title = parameters['title'];
    final author = parameters['author'];

    if (inputFile == null || inputFile.isEmpty) {
      return InternalCommandResult.failure(
        command: 'md2pdf',
        error: 'Input file required\n'
            '  Usage: :md2pdf -mp-input=<path/to/file.md>\n'
            '  Resolution: Provide a markdown file path',
        duration: Duration.zero,
      );
    }

    // Resolve input path
    final absoluteInput = inputFile.startsWith('/') 
        ? inputFile 
        : '${config.workspacePath}/$inputFile';
    final file = File(absoluteInput);
    
    if (!file.existsSync()) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'md2pdf',
        error: 'Input file not found\n'
            '  File: [$absoluteInput]\n'
            '  Resolution: Check the file path',
        duration: stopwatch.elapsed,
      );
    }

    // Determine output directory
    final outputDir = outputFile != null
        ? p.dirname(outputFile.startsWith('/') ? outputFile : '${config.workspacePath}/$outputFile')
        : p.dirname(absoluteInput);

    if (config.dryRun) {
      final expectedOutput = outputFile ?? absoluteInput.replaceAll('.md', '.pdf');
      return InternalCommandResult.success(
        command: 'md2pdf',
        message: '[dry-run] Would convert:\n'
            '  Input: $absoluteInput\n'
            '  Output: $expectedOutput',
        duration: Duration.zero,
      );
    }

    try {
      // Use MdPdfConverter for conversion
      final converter = MdPdfConverter(
        absoluteInput,
        options: MdPdfConverterOptions(
          title: title,
          author: author,
        ),
      );

      if (config.verbose) {
        print('  Converting: $absoluteInput');
        print('  Output dir: $outputDir');
      }

      final result = await converter.convertFile(file, outputDir: outputDir);

      stopwatch.stop();

      return InternalCommandResult.success(
        command: 'md2pdf',
        message: 'PDF generated successfully\n'
            '  Input: ${result.sourcePath}\n'
            '  Output: ${result.outputPath}',
        duration: stopwatch.elapsed,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'md2pdf',
        error: 'PDF conversion failed\n'
            '  Error: $e\n'
            '  Stack: $stack',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes :md2latex command.
  ///
  /// Converts a markdown file to LaTeX using MdLatexConverter.
  ///
  /// Parameters:
  /// - `ml-input` or `ml-file`: Input markdown file path
  /// - `ml-output`: Output LaTeX file path (optional, defaults to input.tex)
  /// - `ml-standalone`: Generate standalone document with preamble (default: true)
  /// - `ml-toc`: Generate table of contents (default: true)
  /// - `ml-author`: Author for document metadata
  Future<InternalCommandResult> _executeMd2Latex(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();
    final inputFile = parameters['input'] ?? parameters['file'];
    final outputFile = parameters['output'];
    final standalone = parameters['standalone']?.toLowerCase() != 'false';
    final generateToc = parameters['toc']?.toLowerCase() != 'false';
    final author = parameters['author'];

    if (inputFile == null || inputFile.isEmpty) {
      return InternalCommandResult.failure(
        command: 'md2latex',
        error: 'Input file required\n'
            '  Usage: :md2latex -ml-input=<path/to/file.md>\n'
            '  Resolution: Provide a markdown file path',
        duration: Duration.zero,
      );
    }

    // Resolve input path
    final absoluteInput = inputFile.startsWith('/') 
        ? inputFile 
        : '${config.workspacePath}/$inputFile';
    final file = File(absoluteInput);
    
    if (!file.existsSync()) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'md2latex',
        error: 'Input file not found\n'
            '  File: [$absoluteInput]\n'
            '  Resolution: Check the file path',
        duration: stopwatch.elapsed,
      );
    }

    // Determine output directory
    final outputDir = outputFile != null
        ? p.dirname(outputFile.startsWith('/') ? outputFile : '${config.workspacePath}/$outputFile')
        : p.dirname(absoluteInput);

    if (config.dryRun) {
      final expectedOutput = outputFile ?? absoluteInput.replaceAll('.md', '.tex');
      return InternalCommandResult.success(
        command: 'md2latex',
        message: '[dry-run] Would convert:\n'
            '  Input: $absoluteInput\n'
            '  Output: $expectedOutput\n'
            '  Standalone: $standalone',
        duration: Duration.zero,
      );
    }

    try {
      // Use MdLatexConverter for conversion
      final converter = MdLatexConverter(
        absoluteInput,
        options: MdLatexConverterOptions(
          generatePreamble: standalone,
          generateToc: generateToc,
          author: author,
        ),
      );

      if (config.verbose) {
        print('  Converting: $absoluteInput');
        print('  Output dir: $outputDir');
      }

      final result = await converter.convertFile(file, outputDir: outputDir);

      stopwatch.stop();

      return InternalCommandResult.success(
        command: 'md2latex',
        message: 'LaTeX generated successfully\n'
            '  Input: ${result.sourcePath}\n'
            '  Output: ${result.outputPath}',
        duration: stopwatch.elapsed,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'md2latex',
        error: 'LaTeX conversion failed\n'
            '  Error: $e\n'
            '  Stack: $stack',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes :prepper command.
  ///
  /// Processes .tomplate files in the workspace, applying mode blocks
  /// and resolving placeholders.
  ///
  /// Parameters:
  /// - `pp-recursive`: Process subdirectories recursively (default: true)
  /// - `pp-verbose`: Show verbose output
  /// - `pp-mode-{type}`: Mode overrides (e.g., pp-mode-environment=prod)
  Future<InternalCommandResult> _executePrepper(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();
    final recursive = parameters['recursive']?.toLowerCase() != 'false';
    final verbose = parameters['verbose']?.toLowerCase() == 'true' || config.verbose;

    // Extract mode overrides from parameters (pp-mode-{type}=value)
    final modeOverrides = <String, String>{};
    for (final entry in parameters.entries) {
      if (entry.key.startsWith('mode-')) {
        final modeType = entry.key.substring(5); // Remove 'mode-' prefix
        modeOverrides[modeType] = entry.value;
      }
    }

    if (config.dryRun) {
      return InternalCommandResult.success(
        command: 'prepper',
        message: '[dry-run] Would run mode processing on .tomplate files\n'
            '  Mode overrides: ${modeOverrides.isEmpty ? "(none)" : modeOverrides}',
        duration: Duration.zero,
      );
    }

    try {
      // Load workspace context for mode configuration
      final context = await WorkspaceContext.load(config.workspacePath);
      final workspace = context.workspace;

      // Determine which directories to process
      final targetDirs = <String>[];
      if (config.projects.isNotEmpty) {
        for (final projectName in config.projects) {
          final projectDir = Directory('${config.workspacePath}/$projectName');
          if (projectDir.existsSync()) {
            targetDirs.add(projectDir.path);
          } else if (verbose) {
            print('  Warning: Project directory not found: $projectName');
          }
        }
      } else {
        targetDirs.add(config.workspacePath);
      }

      // Find all .tomplate files in target directories
      final tomplateFiles = <File>[];
      for (final targetDir in targetDirs) {
        final dir = Directory(targetDir);
        await for (final entity in dir.list(recursive: recursive)) {
          if (entity is File && entity.path.endsWith('.tomplate')) {
            // Skip files in hidden directories
            if (!entity.path.contains('/.')) {
              tomplateFiles.add(entity);
            }
          }
        }
      }

      if (tomplateFiles.isEmpty) {
        stopwatch.stop();
        return InternalCommandResult.success(
          command: 'prepper',
          message: 'No .tomplate files found',
          duration: stopwatch.elapsed,
        );
      }

      // Create processor and parser
      final processor = TomplateProcessor();
      final parser = TomplateParser();
      final modeResolver = ModeResolver();

      // Resolve modes for the 'prepper' action
      final resolvedModes = modeResolver.resolve(
        actionName: 'prepper',
        workspaceModes: workspace.workspaceModes,
        modeDefinitions: workspace.modeDefinitions,
        cliOverrides: modeOverrides,
      );

      if (verbose) {
        print('  Active modes: ${resolvedModes.activeModes}');
        print('  Mode type values: ${resolvedModes.modeTypeValues}');
      }

      // Process each tomplate file
      var processedCount = 0;
      var errorCount = 0;
      final errors = <String>[];

      for (final file in tomplateFiles) {
        final relativePath = file.path.substring(config.workspacePath.length + 1);

        try {
          // Parse the template file
          final template = parser.parseFile(file.path);

          // Build context for placeholder resolution
          final placeholderContext = <String, dynamic>{
            'workspace': workspace.toYaml(),
            'modes': resolvedModes.modeTypeValues,
          };

          // Process the template
          final processed = processor.process(
            template: template,
            resolvedModes: resolvedModes,
            context: placeholderContext,
            resolveEnvironment: true,
            environment: Platform.environment,
          );

          // Write the output file
          processor.writeToFile(processed);

          processedCount++;
          if (verbose) {
            final targetRelative =
                processed.targetPath.substring(config.workspacePath.length + 1);
            print('  ✓ $relativePath → $targetRelative');
          }
        } catch (e) {
          errorCount++;
          errors.add('  ✗ $relativePath: $e');
          if (verbose) {
            print('  ✗ $relativePath: $e');
          }
        }
      }

      stopwatch.stop();

      final summary = StringBuffer()
        ..writeln('Processed $processedCount files${errorCount > 0 ? ', $errorCount errors' : ''}');

      if (verbose && resolvedModes.activeModes.isNotEmpty) {
        summary.writeln('  Active modes: ${resolvedModes.activeModes.join(', ')}');
      }

      if (errors.isNotEmpty) {
        summary.writeln('Errors:');
        for (final error in errors.take(5)) {
          summary.writeln(error);
        }
        if (errors.length > 5) {
          summary.writeln('  ... and ${errors.length - 5} more errors');
        }
      }

      if (errorCount > 0) {
        return InternalCommandResult.failure(
          command: 'prepper',
          error: summary.toString(),
          duration: stopwatch.elapsed,
        );
      }

      return InternalCommandResult.success(
        command: 'prepper',
        message: summary.toString(),
        duration: stopwatch.elapsed,
      );
    } on WorkspaceContextException catch (e) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'prepper',
        error: e.message,
        duration: stopwatch.elapsed,
      );
    } catch (e, stack) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'prepper',
        error: 'Unexpected error during prepper execution\n'
            '  Error: $e\n'
            '  Stack: $stack',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes :help command.
  Future<InternalCommandResult> _executeHelp() async {
    final buffer = StringBuffer();
    buffer.writeln('Tom CLI - Workspace automation tool');
    buffer.writeln();
    buffer.writeln('Usage: tom [options] [commands/actions...]');
    buffer.writeln();
    buffer.writeln('Internal Commands:');
    for (final entry in InternalCommands.commands.entries) {
      final prefix = entry.value.prefix != null ? ' (${entry.value.prefix}-)' : '';
      buffer.writeln('  :${entry.key}$prefix');
      buffer.writeln('      ${entry.value.description}');
    }
    buffer.writeln();
    buffer.writeln('Options:');
    buffer.writeln('  -verbose       Show verbose output');
    buffer.writeln('  -dry-run       Run without making changes');
    buffer.writeln('  -help, -h      Show this help');
    buffer.writeln('  -version, -v   Show version');
    buffer.writeln();
    buffer.writeln('Examples:');
    buffer.writeln('  tom build                    Run build action');
    buffer.writeln('  tom :analyze                 Run workspace analyzer');
    buffer.writeln('  tom :projects p1 p2 build    Build specific projects');
    buffer.writeln('  tom :groups frontend build   Build frontend group');

    return InternalCommandResult.success(
      command: 'help',
      message: buffer.toString(),
      duration: Duration.zero,
    );
  }

  /// Executes :version command.
  Future<InternalCommandResult> _executeVersion() async {
    try {
      // Try to read version from package's pubspec.yaml
      // The CLI is part of tom_build_cli, but the lib is tom_build
      // We'll look for pubspec.yaml relative to the script or use fallback
      final version = await _readPackageVersion();
      return InternalCommandResult.success(
        command: 'version',
        message: 'Tom CLI version $version',
        duration: Duration.zero,
      );
    } catch (e) {
      return InternalCommandResult.success(
        command: 'version',
        message: 'Tom CLI version unknown (could not read pubspec.yaml)',
        duration: Duration.zero,
      );
    }
  }

  /// Executes :vscode command.
  ///
  /// Executes Dart code via VS Code VS Code Bridge.
  ///
  /// Parameters:
  /// - `file`: Path to a .dart file to execute
  /// - `code`: Inline code to execute (if no file specified)
  /// - `mode`: 'script' (default) or 'expression'
  /// - `host`: Custom host (default: localhost)
  /// - `port`: Custom port (default: 19900)
  /// - positional `host|port|host:port` as first argument
  Future<InternalCommandResult> _executeVscode(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Parse parameters
    final file = parameters['file'];
    final code = parameters['code'];
    final mode = parameters['mode'] ?? 'script';
    final hostParam = parameters['host'];
    final hostPortParam = parameters['hostport'];
    final portStr = parameters['port'];
    var host = hostParam ?? 'localhost';
    var port = defaultVSCodeBridgePort;

    if (hostPortParam != null && hostPortParam.isNotEmpty) {
      final hostPort = hostPortParam.trim();
      if (hostPort.contains(':')) {
        final colonIndex = hostPort.lastIndexOf(':');
        final hostPart = hostPort.substring(0, colonIndex);
        final portPart = hostPort.substring(colonIndex + 1);
        final parsedPort = int.tryParse(portPart);
        if (parsedPort == null) {
          stopwatch.stop();
          return InternalCommandResult.failure(
            command: 'vscode',
            error: 'Invalid port: $portPart',
            duration: stopwatch.elapsed,
          );
        }
        host = hostPart.isEmpty ? host : hostPart;
        port = parsedPort;
      } else {
        final parsedPort = int.tryParse(hostPort);
        if (parsedPort != null) {
          port = parsedPort;
        } else {
          host = hostPort;
        }
      }
    }

    if (hostParam != null && hostParam.isNotEmpty) {
      host = hostParam;
    }

    if (portStr != null) {
      final parsedPort = int.tryParse(portStr);
      if (parsedPort == null) {
        stopwatch.stop();
        return InternalCommandResult.failure(
          command: 'vscode',
          error: 'Invalid port: $portStr',
          duration: stopwatch.elapsed,
        );
      }
      port = parsedPort;
    }

    if (file == null && code == null) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'vscode',
        error: 'Either file or code parameter is required\n'
            '  Usage: tom :vscode [host|port|host:port] -file=script.dart\n'
            '         tom :vscode [host|port|host:port] -code="print(\'hello\')"\n'
            '         tom :vscode 19900 -file=script.dart -mode=expression',
        duration: stopwatch.elapsed,
      );
    }

    if (config.dryRun) {
      stopwatch.stop();
      return InternalCommandResult.success(
        command: 'vscode',
        message: '[dry-run] Would execute via VS Code bridge:\n'
            '  File: ${file ?? "(inline code)"}\n'
            '  Mode: $mode\n'
            '  Host: $host\n'
            '  Port: $port',
        duration: stopwatch.elapsed,
      );
    }

    // Connect to VS Code bridge
    final client = VSCodeBridgeClient(host: host, port: port);

    if (!await client.connect()) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'vscode',
        error: 'Failed to connect to VS Code VS Code Bridge on port '
            '${client.port} (host: $host).\n'
            '  Ensure the CLI integration server is running in VS Code\n'
            '  (use Command Palette: "DS: Start Tom CLI Integration Server").',
        duration: stopwatch.elapsed,
      );
    }

    try {
      VSCodeBridgeResult result;

      if (file != null) {
        // Execute file
        final fileContent = _readFileContent(file);
        if (fileContent == null) {
          await client.disconnect();
          stopwatch.stop();
          return InternalCommandResult.failure(
            command: 'vscode',
            error: 'File not found: $file',
            duration: stopwatch.elapsed,
          );
        }

        if (mode == 'expression') {
          result = await client.executeExpression(fileContent);
        } else {
          result = await client.executeScript(fileContent);
        }
      } else {
        // Execute inline code
        if (mode == 'expression') {
          result = await client.executeExpression(code!);
        } else {
          result = await client.executeScript(code!);
        }
      }

      await client.disconnect();
      stopwatch.stop();

      if (result.success) {
        return InternalCommandResult.success(
          command: 'vscode',
          message: result.output.isNotEmpty ? result.output : 'Executed successfully',
          duration: stopwatch.elapsed,
        );
      } else {
        return InternalCommandResult.failure(
          command: 'vscode',
          error: result.error ?? 'VS Code bridge execution failed',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      await client.disconnect();
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'vscode',
        error: 'VS Code bridge error: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Executes :dartscript command.
  ///
  /// Executes Dart code locally via D4rt.
  ///
  /// Parameters:
  /// - `file`: Path to a .dart file to execute
  /// - `code`: Inline code to execute (if no file specified)
  /// - `mode`: 'script' (default) or 'expression'
  Future<InternalCommandResult> _executeDartscript(
    Map<String, String> parameters,
  ) async {
    final stopwatch = Stopwatch()..start();

    // Parse parameters
    final file = parameters['file'];
    final code = parameters['code'];
    final mode = parameters['mode'] ?? 'script';

    if (file == null && code == null) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'dartscript',
        error: 'Either file or code parameter is required\n'
            '  Usage: tom :dartscript -file=script.dart\n'
            '         tom :dartscript -code="print(\'hello\')"\n'
            '         tom :dartscript -file=script.dart -mode=expression\n'
            '  Or use default command:\n'
            '         tom script.dart\n'
            '         tom "print(\'hello\')"',
        duration: stopwatch.elapsed,
      );
    }

    if (config.dryRun) {
      stopwatch.stop();
      return InternalCommandResult.success(
        command: 'dartscript',
        message: '[dry-run] Would execute locally via D4rt:\n'
            '  File: ${file ?? "(inline code)"}\n'
            '  Mode: $mode',
        duration: stopwatch.elapsed,
      );
    }

    try {
      // Try to load workspace context for D4rt initialization
      // This provides access to tom.workspace, tom.projectInfo, etc.
      WorkspaceContext? context;
      try {
        context = WorkspaceContext.current ??
            await WorkspaceContext.load(config.workspacePath);
        // Ensure master files are generated so tom_master.yaml is up to date
        await context.ensureMasterFilesGenerated();
      } catch (_) {
        // Workspace loading is optional - scripts can still run without it
        // but won't have access to workspace-specific variables
      }

      // Create D4rt runner with workspace context if available
      final runner = D4rtRunner(
        config: D4rtRunnerConfig(
          workspacePath: config.workspacePath,
          workspace: context?.workspace,
          workspaceContext: context,
        ),
      );

      D4rtResult result;

      if (file != null) {
        // Execute file - wrap in $D4{} for D4rtRunner
        if (mode == 'expression') {
          final content = _readFileContent(file);
          if (content == null) {
            stopwatch.stop();
            return InternalCommandResult.failure(
              command: 'dartscript',
              error: 'File not found: $file',
              duration: stopwatch.elapsed,
            );
          }
          result = await runner.run('\$D4{$content}');
        } else {
          // Script mode - run as script file
          result = await runner.run('\$D4{$file}');
        }
      } else {
        // Execute inline code - wrap in $D4{} for D4rtRunner
        if (mode == 'expression') {
          result = await runner.run('\$D4{$code}');
        } else {
          // Multiline script syntax
          result = await runner.run('\$D4{\n$code}');
        }
      }

      stopwatch.stop();

      if (result.success) {
        return InternalCommandResult.success(
          command: 'dartscript',
          message: result.output.isNotEmpty ? result.output : 'Executed successfully',
          duration: stopwatch.elapsed,
        );
      } else {
        return InternalCommandResult.failure(
          command: 'dartscript',
          error: result.error ?? 'D4rt execution failed',
          duration: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      return InternalCommandResult.failure(
        command: 'dartscript',
        error: 'D4rt error: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Reads file content as a string.
  String? _readFileContent(String filePath) {
    // Try as-is first
    var file = File(filePath);
    if (file.existsSync()) {
      return file.readAsStringSync();
    }

    // Try relative to workspace
    file = File(p.join(config.workspacePath, filePath));
    if (file.existsSync()) {
      return file.readAsStringSync();
    }

    return null;
  }

  /// Loads a master file for an action.
  Future<TomMaster?> _loadMasterFile(String actionName) async {
    final fileName = 'tom_master_$actionName.yaml';
    final filePath = '${config.metadataDir}/$fileName';
    final file = File(filePath);

    if (!file.existsSync()) {
      return null;
    }

    try {
      final content = file.readAsStringSync();
      final yaml = loadYaml(content) as Map;
      return TomMaster.fromYaml(Map<String, dynamic>.from(yaml));
    } catch (e) {
      return null;
    }
  }

  /// Reads the package version from pubspec.yaml.
  Future<String> _readPackageVersion() async {
    // Try several locations where pubspec might be
    final candidates = [
      // If running from workspace, check tom_build_cli
      '${config.workspacePath}/tom_build_cli/pubspec.yaml',
      // Or check tom_build
      '${config.workspacePath}/tom_build/pubspec.yaml',
    ];

    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) {
        final content = await file.readAsString();
        final yaml = loadYaml(content) as YamlMap?;
        if (yaml != null && yaml.containsKey('version')) {
          return yaml['version'].toString();
        }
      }
    }

    return 'unknown';
  }
}

// =============================================================================
// ACTION COUNTER MANAGER
// =============================================================================

/// Manages the global action counter.
///
/// Per Section 6.4.3, the action counter:
/// - Is stored in `.tom_metadata/workspace_state.yaml`
/// - Is incremented before each action or internal command
/// - Can be reset with :reset-action-counter
/// - Can be used in version placeholders for dev builds
class ActionCounterManager {
  ActionCounterManager({
    required this.stateFilePath,
  });

  /// Path to the workspace state file.
  final String stateFilePath;

  /// Cached counter value.
  int? _cachedCounter;

  /// Gets the current action counter value.
  Future<int> get() async {
    if (_cachedCounter != null) {
      return _cachedCounter!;
    }

    final file = File(stateFilePath);
    if (!file.existsSync()) {
      _cachedCounter = 0;
      return 0;
    }

    try {
      final content = await file.readAsString();
      final yaml = loadYaml(content);
      if (yaml is Map) {
        _cachedCounter = (yaml['action-counter'] as int?) ?? 0;
        return _cachedCounter!;
      }
    } catch (e) {
      // Ignore parse errors, return 0
    }

    _cachedCounter = 0;
    return 0;
  }

  /// Increments the action counter.
  Future<int> increment() async {
    final current = await get();
    final newValue = current + 1;
    await _save(newValue);
    _cachedCounter = newValue;
    return newValue;
  }

  /// Resets the action counter to 0.
  Future<void> reset() async {
    await _save(0);
    _cachedCounter = 0;
  }

  /// Sets the action counter to a specific value.
  Future<void> set(int value) async {
    await _save(value);
    _cachedCounter = value;
  }

  /// Saves the counter value to the state file.
  Future<void> _save(int value) async {
    final file = File(stateFilePath);
    final dir = file.parent;

    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    // Read existing state and update counter
    Map<String, dynamic> state = {};
    if (file.existsSync()) {
      try {
        final content = await file.readAsString();
        final yaml = loadYaml(content);
        if (yaml is Map) {
          state = Map<String, dynamic>.from(yaml);
        }
      } catch (e) {
        // Ignore parse errors
      }
    }

    state['action-counter'] = value;

    // Write as YAML
    final buffer = StringBuffer();
    buffer.writeln('# Tom workspace state');
    buffer.writeln('# Auto-generated - do not edit manually');
    buffer.writeln();
    for (final entry in state.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }

    await file.writeAsString(buffer.toString());
  }
}
