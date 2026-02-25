/// Pipeline Support for Tom CLI
///
/// Provides pipeline parsing and execution for predefined workflows
/// defined in tom_workspace.yaml.
///
/// Pipeline syntax in tom_workspace.yaml:
/// ```yaml
/// pipelines:
///   analyze:
///     - ws_analyzer
///   dev:
///     - ws_analyzer
///     - ws_prepper mode=dev
///   release:
///     - ws_analyzer
///     - ws_versioner --release
///     - ws_prepper mode=production
/// ```
///
/// Multi-line commands use standard YAML folded block scalar (>):
/// ```yaml
///   dev:
///     - >
///       ws_prepper
///       mode=dev
///       skipTests=true
/// ```
library;

import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as path;
import 'tom_command_parser.dart';
import 'tom_runner.dart';

/// Represents a pipeline definition.
class PipelineDefinition {
  /// The name of the pipeline.
  final String name;

  /// The commands to execute in sequence.
  final List<String> commands;

  const PipelineDefinition({
    required this.name,
    required this.commands,
  });

  /// Creates from YAML entry.
  /// 
  /// Supports standard YAML syntax including:
  /// - Simple list entries: `- ws_analyzer`
  /// - Folded block scalars for multi-line: `- > \n ws_prepper \n mode=dev`
  factory PipelineDefinition.fromYaml(String name, dynamic yaml) {
    if (yaml is YamlList) {
      final commands = <String>[];

      for (final item in yaml) {
        // Get the string value (YAML library handles multiline folding)
        var command = item.toString().trim();
        
        // Normalize whitespace - folded blocks may have newlines that should be spaces
        command = command.replaceAll(RegExp(r'\s+'), ' ').trim();
        
        if (command.isNotEmpty) {
          commands.add(command);
        }
      }

      return PipelineDefinition(name: name, commands: commands);
    }

    return PipelineDefinition(name: name, commands: []);
  }

  /// Parses all commands into tom command arguments.
  List<ParsedTomCommand> parseCommands() {
    return commands.map((cmd) {
      // If command starts with 'tom ', strip it
      var normalizedCmd = cmd;
      if (normalizedCmd.startsWith('tom ')) {
        normalizedCmd = normalizedCmd.substring(4);
      }

      // Split into arguments
      final args = _splitArgs(normalizedCmd);
      return parseTomCommand(args);
    }).toList();
  }

  /// Splits a command string into arguments, handling quoted strings.
  static List<String> _splitArgs(String command) {
    final args = <String>[];
    final buffer = StringBuffer();
    var inQuote = false;
    String? quoteChar;

    for (var i = 0; i < command.length; i++) {
      final char = command[i];

      if (inQuote) {
        if (char == quoteChar) {
          inQuote = false;
          args.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(char);
        }
      } else if (char == '"' || char == "'") {
        inQuote = true;
        quoteChar = char;
      } else if (char == ' ' || char == '\t' || char == '\n') {
        if (buffer.isNotEmpty) {
          args.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      args.add(buffer.toString());
    }

    return args;
  }

  @override
  String toString() => 'Pipeline($name): ${commands.length} commands';
}

/// Result of running a pipeline.
class PipelineResult {
  /// The pipeline that was executed.
  final PipelineDefinition pipeline;

  /// Results for each command.
  final List<TomRunResults> commandResults;

  /// Whether all commands succeeded.
  bool get success => commandResults.every((r) => r.success);

  /// Total execution time.
  Duration get totalDuration =>
      commandResults.fold(Duration.zero, (sum, r) => sum + r.totalDuration);

  const PipelineResult({
    required this.pipeline,
    required this.commandResults,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Pipeline: ${pipeline.name}');
    buffer.writeln('Commands: ${pipeline.commands.length}');
    buffer.writeln('Duration: ${totalDuration.inMilliseconds}ms');
    buffer.writeln('Status: ${success ? 'Success' : 'Failed'}');
    return buffer.toString();
  }
}

/// Loads pipelines from tom_workspace.yaml.
class PipelineLoader {
  /// The workspace root path.
  final String workspacePath;

  PipelineLoader(this.workspacePath);

  /// Loads all pipelines from tom_workspace.yaml.
  Future<Map<String, PipelineDefinition>> loadPipelines() async {
    final pipelines = <String, PipelineDefinition>{};

    final workspaceFile = File(path.join(workspacePath, 'tom_workspace.yaml'));
    if (!workspaceFile.existsSync()) {
      return pipelines;
    }

    try {
      final content = await workspaceFile.readAsString();
      final yaml = loadYaml(content) as YamlMap?;

      if (yaml == null) return pipelines;

      final pipelinesYaml = yaml['pipelines'];
      if (pipelinesYaml is YamlMap) {
        for (final entry in pipelinesYaml.entries) {
          final name = entry.key.toString();
          pipelines[name] = PipelineDefinition.fromYaml(name, entry.value);
        }
      }
    } catch (e) {
      // Ignore parse errors
    }

    return pipelines;
  }

  /// Gets a specific pipeline by name.
  Future<PipelineDefinition?> getPipeline(String name) async {
    final pipelines = await loadPipelines();
    return pipelines[name];
  }

  /// Lists available pipeline names.
  Future<List<String>> listPipelineNames() async {
    final pipelines = await loadPipelines();
    return pipelines.keys.toList()..sort();
  }
}

/// Executes pipelines.
class PipelineRunner {
  /// The workspace root path.
  final String workspacePath;

  /// Whether to run in verbose mode.
  final bool verbose;

  /// Whether to run in dry-run mode.
  final bool dryRun;

  /// Output sink for messages.
  final StringSink output;

  PipelineRunner({
    required this.workspacePath,
    this.verbose = false,
    this.dryRun = false,
    StringSink? output,
  }) : output = output ?? stdout;

  /// Runs a pipeline by name.
  Future<PipelineResult> runPipeline(String name) async {
    final loader = PipelineLoader(workspacePath);
    final pipeline = await loader.getPipeline(name);

    if (pipeline == null) {
      throw ArgumentError('Pipeline not found: $name');
    }

    return await execute(pipeline);
  }

  /// Executes a pipeline definition.
  Future<PipelineResult> execute(PipelineDefinition pipeline) async {
    if (verbose) {
      output.writeln('Running pipeline: ${pipeline.name}');
      output.writeln('Commands: ${pipeline.commands.length}');
    }

    final results = <TomRunResults>[];
    final runner = TomRunner(
      workspacePath: workspacePath,
      verbose: verbose,
      dryRun: dryRun,
      output: output,
    );

    for (var i = 0; i < pipeline.commands.length; i++) {
      final command = pipeline.commands[i];

      if (verbose) {
        output.writeln('\n[${i + 1}/${pipeline.commands.length}] $command');
      }

      // Parse and run the command
      var normalizedCmd = command;
      if (normalizedCmd.startsWith('tom ')) {
        normalizedCmd = normalizedCmd.substring(4);
      }

      final args = PipelineDefinition._splitArgs(normalizedCmd);
      final parsed = parseTomCommand(args);

      final result = await runner.run(parsed);
      results.add(result);

      // Stop on failure
      if (!result.success) {
        if (verbose) {
          output.writeln('Pipeline stopped due to command failure');
        }
        break;
      }
    }

    return PipelineResult(pipeline: pipeline, commandResults: results);
  }
}

/// Adds pipeline command to the tom CLI.
extension PipelineCommands on TomRunner {
  /// Runs a pipeline command.
  Future<String> runPipeline(ParsedCommand cmd) async {
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
}
