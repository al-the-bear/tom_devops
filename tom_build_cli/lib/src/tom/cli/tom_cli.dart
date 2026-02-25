// Tom CLI - Main command-line interface
//
// Implements tom_tool_specification.md Section 6:
// - Parse command line arguments
// - Run internal commands or workspace actions
// - Handle :projects and :groups scope limiting
// - Execute multiple actions in sequence
// - Display helpful error messages
// - Support --help and --version

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'argument_parser.dart';
import 'internal_commands.dart';
import 'workspace_context.dart';
import '../execution/action_executor.dart';
import 'package:tom_build/tom_build.dart';

// =============================================================================
// TOM CLI
// =============================================================================

/// Configuration for the Tom CLI.
class TomCliConfig {
  const TomCliConfig({
    this.workspacePath,
    this.metadataPath,
    this.verbose = false,
    this.dryRun = false,
    this.stopOnFailure = true,
  });

  /// Path to the workspace root. Defaults to current directory.
  final String? workspacePath;

  /// Path to the metadata directory. Defaults to .tom_metadata.
  final String? metadataPath;

  /// Whether to print verbose output.
  final bool verbose;

  /// Whether to run in dry-run mode (no changes).
  final bool dryRun;

  /// Whether to stop on first failure.
  final bool stopOnFailure;

  /// Gets the resolved workspace path.
  String get resolvedWorkspacePath {
    if (workspacePath != null) return workspacePath!;
    
    // Try to discover workspace root from current directory
    final result = discoverWorkspace(Directory.current.path);
    return result.workspacePath ?? Directory.current.path;
  }

  /// Gets the resolved metadata path.
  String get resolvedMetadataPath =>
      metadataPath ?? '$resolvedWorkspacePath/.tom_metadata';

  /// Creates a new config with the specified overrides.
  TomCliConfig copyWith({
    String? workspacePath,
    String? metadataPath,
    bool? verbose,
    bool? dryRun,
    bool? stopOnFailure,
  }) {
    return TomCliConfig(
      workspacePath: workspacePath ?? this.workspacePath,
      metadataPath: metadataPath ?? this.metadataPath,
      verbose: verbose ?? this.verbose,
      dryRun: dryRun ?? this.dryRun,
      stopOnFailure: stopOnFailure ?? this.stopOnFailure,
    );
  }
}

/// Result of running the Tom CLI.
class TomCliResult {
  const TomCliResult._({
    required this.exitCode,
    this.message,
    this.error,
    this.actionResults = const [],
    this.commandResults = const [],
  });

  /// Creates a successful result.
  factory TomCliResult.success({
    String? message,
    List<ActionExecutionResult> actionResults = const [],
    List<InternalCommandResult> commandResults = const [],
  }) {
    return TomCliResult._(
      exitCode: 0,
      message: message,
      actionResults: actionResults,
      commandResults: commandResults,
    );
  }

  /// Creates a failed result.
  factory TomCliResult.failure({
    required String error,
    int exitCode = 1,
    List<ActionExecutionResult> actionResults = const [],
    List<InternalCommandResult> commandResults = const [],
  }) {
    return TomCliResult._(
      exitCode: exitCode,
      error: error,
      actionResults: actionResults,
      commandResults: commandResults,
    );
  }

  /// Creates a help result.
  factory TomCliResult.help(String message) {
    return TomCliResult._(
      exitCode: 0,
      message: message,
    );
  }

  /// Exit code (0 = success, non-zero = failure).
  final int exitCode;

  /// Success message.
  final String? message;

  /// Error message.
  final String? error;

  /// Results from workspace action executions.
  final List<ActionExecutionResult> actionResults;

  /// Results from internal command executions.
  final List<InternalCommandResult> commandResults;

  /// Whether the result is successful.
  bool get success => exitCode == 0;
}

/// The Tom CLI application.
///
/// This is the main entry point for the `tom` command-line tool.
/// It parses arguments, runs internal commands and workspace actions,
/// and handles scope limiting with :projects and :groups.
class TomCli {
  TomCli({
    TomCliConfig? config,
    ArgumentParser? argumentParser,
    InternalCommandExecutor? commandExecutor,
    ActionExecutor? actionExecutor,
  })  : _config = config ?? const TomCliConfig(),
        _argumentParser = argumentParser ?? ArgumentParser(),
        _commandExecutor = commandExecutor,
        _actionExecutor = actionExecutor;

  final TomCliConfig _config;
  final ArgumentParser _argumentParser;
  final InternalCommandExecutor? _commandExecutor;
  final ActionExecutor? _actionExecutor;

  /// Runs the CLI with the given arguments.
  ///
  /// Returns a result with exit code and any output.
  Future<TomCliResult> run(List<String> args) async {
    try {
      // Parse arguments
      final parsed = _argumentParser.parse(args);

      // Update config from global parameters
      final effectiveConfig = _applyGlobalParameters(parsed);

      // Handle help request
      if (parsed.helpRequested) {
        final helpResult = await _getHelp(effectiveConfig);
        return TomCliResult.help(helpResult);
      }

      // Handle version request
      if (parsed.versionRequested) {
        return TomCliResult.help(await _getVersion());
      }

      // No actions to execute?
      if (parsed.actions.isEmpty) {
        final helpResult = await _getHelp(effectiveConfig);
        return TomCliResult.help(helpResult);
      }

      // Execute actions in sequence
      return await _executeActions(parsed, effectiveConfig);
    } on ArgumentError catch (e) {
      return TomCliResult.failure(error: e.message.toString());
    } catch (e) {
      return TomCliResult.failure(error: 'Unexpected error: $e');
    }
  }

  /// Applies global parameters to create effective config.
  TomCliConfig _applyGlobalParameters(ParsedArguments parsed) {
    return _config.copyWith(
      verbose: parsed.verbose || _config.verbose,
      dryRun: parsed.dryRun || _config.dryRun,
    );
  }

  /// Executes all actions from the parsed arguments.
  Future<TomCliResult> _executeActions(
    ParsedArguments parsed,
    TomCliConfig config,
  ) async {
    final actionResults = <ActionExecutionResult>[];
    final commandResults = <InternalCommandResult>[];

    // Check if any action requires the workspace
    bool requiresWorkspace = false;
    for (final action in parsed.actions) {
      if (!action.isInternalCommand && !action.bypassWorkspaceAction) {
        requiresWorkspace = true;
        break;
      }
      if (InternalCommands.getCommand(action.name)?.requiresWorkspace == true) {
        requiresWorkspace = true;
        break;
      }
    }

    // Ensure master files are generated if workspace is required
    if (requiresWorkspace) {
      try {
        final context = await WorkspaceContext.load(config.resolvedWorkspacePath);
        final genResult = await context.ensureMasterFilesGenerated();
        if (!genResult.success) {
          return TomCliResult.failure(
            error: genResult.message,
          );
        }
      } catch (e) {
        return TomCliResult.failure(error: 'Failed to prepare workspace: $e');
      }
    }

    for (final action in parsed.actions) {
      // Merge parameters for this action
      final parameters = parsed.getActionParameters(action.name);

      // Check if this is an internal command
      // Use bypassWorkspaceAction to force internal command execution
      if (action.isInternalCommand || action.bypassWorkspaceAction) {
        final result = await _executeInternalCommand(
          commandName: action.name,
          parameters: parameters,
          config: config,
        );
        commandResults.add(result);

        if (!result.success && config.stopOnFailure) {
          return TomCliResult.failure(
            error: result.error ?? 'Internal command :${action.name} failed',
            actionResults: actionResults,
            commandResults: commandResults,
          );
        }
      } else {
        // It's a workspace action
        final results = await _executeWorkspaceAction(
          actionName: action.name,
          parameters: parameters,
          parsed: parsed,
          config: config,
        );
        actionResults.addAll(results);

        // Check for failures
        final failure = results.firstWhere(
          (r) => !r.success,
          orElse: () => ActionExecutionResult.success(
            projectName: '',
            actionName: '',
            commandResults: [],
            duration: Duration.zero,
          ),
        );

        // A failure result from executing workspace action
        // Empty projectName failures are infrastructure errors (missing master file, etc.)
        if (!failure.success && config.stopOnFailure) {
          return TomCliResult.failure(
            error: failure.error ?? 'Action ${action.name} failed',
            actionResults: actionResults,
            commandResults: commandResults,
          );
        }
      }
    }

    return TomCliResult.success(
      message: _buildSuccessMessage(actionResults, commandResults),
      actionResults: actionResults,
      commandResults: commandResults,
    );
  }

  /// Executes an internal command.
  Future<InternalCommandResult> _executeInternalCommand({
    required String commandName,
    required Map<String, String> parameters,
    required TomCliConfig config,
  }) async {
    final executor = _commandExecutor ??
        InternalCommandExecutor(
          config: InternalCommandConfig(
            workspacePath: config.resolvedWorkspacePath,
            metadataPath: config.resolvedMetadataPath,
            verbose: config.verbose,
            dryRun: config.dryRun,
          ),
        );

    return await executor.execute(
      commandName: commandName,
      parameters: parameters,
    );
  }

  /// Executes a workspace action.
  Future<List<ActionExecutionResult>> _executeWorkspaceAction({
    required String actionName,
    required Map<String, String> parameters,
    required ParsedArguments parsed,
    required TomCliConfig config,
  }) async {
    final executor = _actionExecutor ??
        ActionExecutor(
          config: ActionExecutorConfig(
            workspacePath: config.resolvedWorkspacePath,
            metadataPath: config.resolvedMetadataPath,
            verbose: config.verbose,
            dryRun: config.dryRun,
          ),
        );

    // Determine which projects to run on
    final projects = await _resolveTargetProjects(parsed, config);

    if (projects.isEmpty) {
      // No scope limiting - run on all projects
      return await _executeActionOnAllProjects(executor, actionName, config);
    }

    // Run on specific projects
    return await executor.executeActionOnProjects(
      actionName: actionName,
      projectNames: projects,
      stopOnFailure: config.stopOnFailure,
    );
  }

  /// Resolves the target projects based on scope limiting.
  Future<List<String>> _resolveTargetProjects(
    ParsedArguments parsed,
    TomCliConfig config,
  ) async {
    // Direct project specification
    if (parsed.projects.isNotEmpty) {
      return parsed.projects;
    }

    // Group-based specification
    if (parsed.groups.isNotEmpty) {
      return await _resolveProjectsFromGroups(parsed.groups, config);
    }

    // No scope limiting
    return [];
  }

  /// Resolves projects from group names.
  Future<List<String>> _resolveProjectsFromGroups(
    List<String> groups,
    TomCliConfig config,
  ) async {
    // Load workspace config to get group definitions
    final workspaceFile = File('${config.resolvedWorkspacePath}/tom_workspace.yaml');
    if (!workspaceFile.existsSync()) {
      return [];
    }

    try {
      final content = workspaceFile.readAsStringSync();
      final yaml = loadYaml(content);
      if (yaml is! Map) return [];

      final workspace = TomWorkspace.fromYaml(makeCleanMap(yaml));
      final allProjects = <String>{};

      for (final groupName in groups) {
        final group = workspace.groups[groupName];
        if (group != null) {
          allProjects.addAll(group.projects);
        }
      }

      return allProjects.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  /// Executes an action on all projects in the workspace.
  Future<List<ActionExecutionResult>> _executeActionOnAllProjects(
    ActionExecutor executor,
    String actionName,
    TomCliConfig config,
  ) async {
    // Load master file to get all projects
    final masterFile = File('${config.resolvedMetadataPath}/tom_master_$actionName.yaml');
    if (!masterFile.existsSync()) {
      // Try the generic master file
      final genericMasterFile = File('${config.resolvedMetadataPath}/tom_master.yaml');
      if (!genericMasterFile.existsSync()) {
        return [
          ActionExecutionResult.failure(
            projectName: '',
            actionName: actionName,
            error: _formatMasterFileNotFoundError(actionName, masterFile.path, genericMasterFile.path),
            duration: Duration.zero,
          ),
        ];
      }
      return await _executeOnProjectsFromMaster(executor, actionName, genericMasterFile, config);
    }

    return await _executeOnProjectsFromMaster(executor, actionName, masterFile, config);
  }

  /// Executes an action on all projects from a master file.
  Future<List<ActionExecutionResult>> _executeOnProjectsFromMaster(
    ActionExecutor executor,
    String actionName,
    File masterFile,
    TomCliConfig config,
  ) async {
    try {
      final content = masterFile.readAsStringSync();
      final yaml = loadYaml(content);
      if (yaml is! Map) {
        return [
          ActionExecutionResult.failure(
            projectName: '',
            actionName: actionName,
            error: _formatInvalidMasterFileError(masterFile.path),
            duration: Duration.zero,
          ),
        ];
      }

      final master = TomMaster.fromYaml(makeCleanMap(yaml));
      final projects = master.projects.keys.toList();

      // Use build order if available
      if (master.buildOrder.isNotEmpty) {
        final orderedProjects = master.buildOrder.where(projects.contains).toList();
        final unorderedProjects = projects.where((p) => !orderedProjects.contains(p)).toList()..sort();
        orderedProjects.addAll(unorderedProjects);
        return await executor.executeActionOnProjects(
          actionName: actionName,
          projectNames: orderedProjects,
          stopOnFailure: config.stopOnFailure,
        );
      }

      return await executor.executeActionOnProjects(
        actionName: actionName,
        projectNames: projects,
        stopOnFailure: config.stopOnFailure,
      );
    } catch (e) {
      return [
        ActionExecutionResult.failure(
          projectName: '',
          actionName: actionName,
          error: _formatMasterFileLoadError(masterFile.path, e.toString()),
          duration: Duration.zero,
        ),
      ];
    }
  }

  /// Formats error message for master file not found.
  String _formatMasterFileNotFoundError(
    String actionName, 
    String actionMasterPath,
    String genericMasterPath,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Master file not found for action [$actionName]');
    buffer.writeln('  Searched: [$actionMasterPath]');
    buffer.writeln('  Fallback: [$genericMasterPath]');
    buffer.writeln('  Resolution: Run :analyze first to generate master files, ');
    buffer.write('or add action [$actionName] to action-mode-configuration in tom_workspace.yaml');
    return buffer.toString();
  }

  /// Formats error message for master file load failure.
  String _formatMasterFileLoadError(String filePath, String error) {
    final buffer = StringBuffer();
    buffer.writeln('Failed to load master file');
    buffer.writeln('  File: [$filePath]');
    buffer.writeln('  Error: $error');
    buffer.write('  Resolution: Verify the file is valid YAML and run :analyze to regenerate');
    return buffer.toString();
  }

  /// Formats error message for invalid master file format.
  String _formatInvalidMasterFileError(String filePath) {
    final buffer = StringBuffer();
    buffer.writeln('Invalid master file format');
    buffer.writeln('  File: [$filePath]');
    buffer.writeln('  Resolution: Run :analyze to regenerate the master file');
    return buffer.toString();
  }

  /// Builds a success message from results.
  String _buildSuccessMessage(
    List<ActionExecutionResult> actionResults,
    List<InternalCommandResult> commandResults,
  ) {
    final buffer = StringBuffer();

    // For :dartscript/:vscode commands, output was already printed to stdout
    // Don't duplicate it here, and skip the summary line for pipe compatibility
    final isDartscriptOnly = commandResults.length == 1 && 
        actionResults.isEmpty &&
        (commandResults.first.command == 'dartscript' || 
         commandResults.first.command == 'vscode');
    
    if (isDartscriptOnly) {
      // No summary message for pipe compatibility
      return '';
    }

    // Output from internal commands (e.g., :dartscript print output)
    for (final cmdResult in commandResults) {
      if (cmdResult.message != null && 
          cmdResult.message!.isNotEmpty &&
          cmdResult.message != 'Executed successfully') {
        buffer.writeln(cmdResult.message);
      }
    }

    if (commandResults.isNotEmpty) {
      buffer.writeln('Internal commands: ${commandResults.length} completed');
    }

    if (actionResults.isNotEmpty) {
      final succeeded = actionResults.where((r) => r.success).length;
      final failed = actionResults.where((r) => !r.success).length;
      buffer.writeln('Actions: $succeeded succeeded, $failed failed');
    }

    return buffer.toString().trim();
  }

  /// Gets help text.
  Future<String> _getHelp(TomCliConfig config) async {
    final executor = InternalCommandExecutor(
      config: InternalCommandConfig(
        workspacePath: config.resolvedWorkspacePath,
      ),
    );
    final result = await executor.execute(commandName: 'help');
    return result.message ?? 'Tom CLI - Workspace automation tool';
  }

  /// Gets version text.
  Future<String> _getVersion() async {
    // Read version from pubspec.yaml
    try {
      final pubspecFile = File('${Directory.current.path}/pubspec.yaml');
      if (pubspecFile.existsSync()) {
        final content = await pubspecFile.readAsString();
        final versionMatch = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(content);
        if (versionMatch != null) {
          return 'Tom CLI version ${versionMatch.group(1)?.trim()}';
        }
      }
      // Fallback: try to find the package's pubspec
      final packagePubspec = File('${Platform.script.resolve('../pubspec.yaml').toFilePath()}');
      if (packagePubspec.existsSync()) {
        final content = await packagePubspec.readAsString();
        final versionMatch = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(content);
        if (versionMatch != null) {
          return 'Tom CLI version ${versionMatch.group(1)?.trim()}';
        }
      }
    } catch (_) {
      // Ignore errors, return default version
    }
    return 'Tom CLI version 1.0.0';
  }
}

// =============================================================================
// MAIN ENTRY POINT
// =============================================================================

/// Runs the Tom CLI and returns the exit code.
///
/// This is the main entry point for the `tom` command.
/// Usage from bin/tom.dart:
/// ```dart
/// import 'package:tom_build/src/tom/cli/tom_cli.dart';
///
/// void main(List<String> args) async {
///   final exitCode = await runTomCli(args);
///   exit(exitCode);
/// }
/// ```
Future<int> runTomCli(List<String> args) async {
  final cli = TomCli();
  final result = await cli.run(args);

  if (result.message != null) {
    // ignore: avoid_print
    print(result.message);
  }

  if (result.error != null) {
    // ignore: avoid_print
    print('Error: ${result.error}');
  }

  return result.exitCode;
}
