/// Tom CLI Runner
///
/// Executes parsed tom commands in sequence, supporting:
/// - Multiple commands in a single invocation
/// - Global parameters inherited by all commands
/// - Pipeline execution from tom_workspace.yaml
library;

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:tom_build/tom_build.dart';
import '../ws_prepper/ws_prepper.dart';
import 'tom_command_parser.dart';
import 'pipeline.dart';

/// Result of running a tom command.
class TomRunResult {
  /// Whether the execution was successful.
  final bool success;

  /// The command that was executed.
  final String command;

  /// Output message.
  final String message;

  /// Error message if not successful.
  final String? error;

  /// Duration of execution.
  final Duration duration;

  const TomRunResult({
    required this.success,
    required this.command,
    required this.message,
    this.error,
    required this.duration,
  });

  @override
  String toString() {
    final status = success ? '✓' : '✗';
    final durationMs = duration.inMilliseconds;
    return '$status $command (${durationMs}ms): $message${error != null ? '\n  Error: $error' : ''}';
  }
}

/// Aggregated result of running multiple commands.
class TomRunResults {
  /// Results for each command executed.
  final List<TomRunResult> results;

  /// Whether all commands succeeded.
  bool get success => results.every((r) => r.success);

  /// Total execution time.
  Duration get totalDuration =>
      results.fold(Duration.zero, (sum, r) => sum + r.duration);

  const TomRunResults(this.results);

  @override
  String toString() {
    final buffer = StringBuffer();
    for (final result in results) {
      buffer.writeln(result);
    }
    buffer.writeln('\nTotal: ${results.length} commands, ${totalDuration.inMilliseconds}ms');
    buffer.writeln('Status: ${success ? 'All succeeded' : 'Some failed'}');
    return buffer.toString();
  }
}

/// Runner for tom CLI commands.
class TomRunner {
  /// The workspace root path.
  final String workspacePath;

  /// Whether to run in verbose mode.
  final bool verbose;

  /// Whether to run in dry-run mode.
  final bool dryRun;

  /// Output sink for messages.
  final StringSink output;

  /// Creates a runner for the given workspace.
  TomRunner({
    required this.workspacePath,
    this.verbose = false,
    this.dryRun = false,
    StringSink? output,
  }) : output = output ?? stdout;

  /// Runs all commands in a parsed tom command.
  Future<TomRunResults> run(ParsedTomCommand parsed) async {
    final results = <TomRunResult>[];
    final parser = TomCommandParser();

    for (final cmd in parsed.commands) {
      // Merge global params/flags with command-specific ones
      final mergedCmd = parser.mergeWithGlobals(
        cmd,
        parsed.globalParams,
        parsed.globalFlags,
      );

      if (verbose) {
        output.writeln('Executing: ${mergedCmd.name}');
        if (mergedCmd.params.isNotEmpty) {
          output.writeln('  Params: ${mergedCmd.params}');
        }
      }

      final result = await _executeCommand(mergedCmd);
      results.add(result);

      if (!result.success) {
        output.writeln('Command failed: ${result.command}');
        if (result.error != null) {
          output.writeln('  Error: ${result.error}');
        }
        // Continue executing remaining commands unless we want to stop on failure
      }
    }

    return TomRunResults(results);
  }

  /// Executes a single command.
  Future<TomRunResult> _executeCommand(ParsedCommand cmd) async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await switch (cmd.name) {
        'ws_analyzer' => _runWsAnalyzer(cmd),
        'ws_prepper' => _runWsPrepper(cmd),
        'ws_versioner' => _runWsVersioner(cmd),
        'ws_publisher' => _runWsPublisher(cmd),
        'reflection_generator' => _runReflectionGenerator(cmd),
        'pipeline' || 'run' => _runPipeline(cmd),
        'help' => _runHelp(cmd),
        'version' => _runVersion(cmd),
        _ => throw UnsupportedError('Unknown command: ${cmd.name}'),
      };

      stopwatch.stop();
      return TomRunResult(
        success: true,
        command: cmd.name,
        message: result,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return TomRunResult(
        success: false,
        command: cmd.name,
        message: 'Failed',
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Runs a pipeline by name.
  Future<String> _runPipeline(ParsedCommand cmd) async {
    final pipelineName = cmd.get('name', cmd.positionalArgs.firstOrNull ?? '');
    
    if (pipelineName.isEmpty) {
      // List available pipelines
      final loader = PipelineLoader(workspacePath);
      final names = await loader.listPipelineNames();
      
      if (names.isEmpty) {
        return 'No pipelines defined in tom_workspace.yaml';
      }
      
      return 'Available pipelines:\n${names.map((n) => '  - $n').join('\n')}';
    }

    final pipelineRunner = PipelineRunner(
      workspacePath: workspacePath,
      verbose: verbose,
      dryRun: dryRun,
      output: output,
    );

    final result = await pipelineRunner.runPipeline(pipelineName);
    return result.success
        ? 'Pipeline ${result.pipeline.name} completed successfully'
        : 'Pipeline ${result.pipeline.name} failed';
  }

  /// Runs the workspace analyzer.
  Future<String> _runWsAnalyzer(ParsedCommand cmd) async {
    final wsPath = cmd.get('path', workspacePath);
    final analyzer = WorkspaceAnalyzer(wsPath);
    
    if (dryRun || cmd.dryRun) {
      return 'Dry run: Would analyze workspace at $wsPath';
    }

    await analyzer.analyze();
    return 'Analyzed workspace: $wsPath (${analyzer.projects.length} projects)';
  }

  /// Runs the workspace preparer.
  Future<String> _runWsPrepper(ParsedCommand cmd) async {
    final mode = cmd.get('mode', 'dev');
    final wsPath = cmd.get('path', workspacePath);
    
    final prepper = WsPrepper(
      wsPath,
      options: WsPrepperOptions(dryRun: dryRun || cmd.dryRun),
    );

    final result = await prepper.processAll(mode);
    return 'Processed ${result.processed.length} templates for mode: $mode';
  }

  /// Runs the workspace versioner (placeholder).
  Future<String> _runWsVersioner(ParsedCommand cmd) async {
    // TODO: Implement workspace versioner
    return 'Versioner not yet implemented';
  }

  /// Runs the workspace publisher (placeholder).
  Future<String> _runWsPublisher(ParsedCommand cmd) async {
    // TODO: Implement workspace publisher
    return 'Publisher not yet implemented';
  }

  /// Runs the reflection generator.
  ///
  /// Converts ParsedCommand to CLI args and runs via shell to avoid
  /// direct analyzer dependency.
  Future<String> _runReflectionGenerator(ParsedCommand cmd) async {
    final args = _buildReflectionGeneratorArgs(cmd);
    
    if (verbose) {
      stdout.writeln('Running reflection generator with args: $args');
    }
    
    ProcessResult result;
    
    // Try to run from local workspace first
    final generatorPath = p.join(p.dirname(workspacePath), 'tom_reflection_generator');
    
    if (Directory(generatorPath).existsSync()) {
      // Run from local package
      result = await Process.run(
        'dart',
        ['run', 'bin/reflection_generator.dart', ...args],
        workingDirectory: generatorPath,
      );
    } else {
      // Try to run as pub.dev package
      result = await Process.run(
        'dart',
        ['run', 'tom_reflection_generator:reflection_generator', ...args],
        workingDirectory: workspacePath,
      );
    }
    
    if (result.exitCode != 0) {
      throw Exception('Reflection generator failed: ${result.stderr}');
    }
    
    return 'Reflection generator completed: ${result.stdout}';
  }

  /// Builds CLI args for the reflection generator from a ParsedCommand.
  List<String> _buildReflectionGeneratorArgs(ParsedCommand cmd) {
    final args = <String>[];
    
    // Add flags
    if (cmd.flags.contains('all')) args.add('--all');
    if (cmd.flags.contains('clean')) args.add('--clean');
    if (cmd.flags.contains('force')) args.add('--force');
    if (cmd.verbose) args.add('--verbose');
    if (cmd.dryRun) args.add('--dry-run');
    if (cmd.help) args.add('--help');
    
    // Add named parameters as options
    for (final entry in cmd.params.entries) {
      switch (entry.key) {
        case 'target':
          args.addAll(['--target', entry.value]);
        case 'output':
          args.addAll(['--output', entry.value]);
        case 'config':
          args.addAll(['--config', entry.value]);
        case 'package':
          args.addAll(['--package', entry.value]);
        case 'extension':
          args.addAll(['--extension', entry.value]);
        default:
          // Pass through unknown params
          args.addAll(['--${entry.key}', entry.value]);
      }
    }
    
    // Add positional arguments (file/glob patterns)
    args.addAll(cmd.positionalArgs);
    
    return args;
  }

  /// Shows help.
  Future<String> _runHelp(ParsedCommand cmd) async {
    return '''
tom - Tom Build Tools CLI

Usage:
  tom [global options] command [command options] [command2 [options]] ...

Global Options:
  --verbose, -v    Enable verbose output
  --dry-run        Don't make any changes
  --help, -h       Show this help

Global Parameters:
  path=<path>      Workspace path (default: current directory)

Commands:
  ws_analyzer      Analyze workspace structure
  ws_prepper       Process template files for a mode
  ws_versioner     Manage package versions
  ws_publisher     Publish packages
  pipeline         Run a named pipeline from tom_workspace.yaml
  run              Alias for pipeline
  help             Show this help
  version          Show version

Pipeline Command:
  tom pipeline name=<pipeline-name>   Run a specific pipeline
  tom run <pipeline-name>             Shorthand syntax
  tom pipeline                        List available pipelines

Examples:
  tom ws_analyzer
  tom --verbose ws_prepper mode=dev
  tom ws_analyzer ws_prepper mode=release
  tom path=/my/workspace ws_analyzer ws_prepper mode=dev
  tom run release                     Run the 'release' pipeline
  tom pipeline name=deploy            Run the 'deploy' pipeline
''';
  }

  /// Shows version.
  Future<String> _runVersion(ParsedCommand cmd) async {
    return 'tom version 1.0.0';
  }
}

/// Runs the tom CLI with the given arguments.
Future<void> runTomCli(List<String> args) async {
  final parsed = parseTomCommand(args);

  if (parsed.help || !parsed.hasCommands) {
    print(await TomRunner(workspacePath: Directory.current.path)._runHelp(
      const ParsedCommand(name: 'help'),
    ));
    return;
  }

  final workspacePath = parsed.get('path', Directory.current.path);
  final runner = TomRunner(
    workspacePath: workspacePath,
    verbose: parsed.verbose,
    dryRun: parsed.dryRun,
  );

  final results = await runner.run(parsed);
  print(results);

  if (!results.success) {
    exit(1);
  }
}
