// Wrapper for tom_reflection_generator package.
//
// Runs the reflection generator via shell to avoid pulling in analyzer
// as a direct dependency, enabling standalone binary compilation.

import 'dart:io';

import 'package:path/path.dart' as p;

/// Wrapper for the tom_reflection_generator package.
///
/// Runs reflection generation via shell command to avoid direct
/// analyzer dependency.
///
/// ## Example
///
/// ```dart
/// final generator = ReflectionGeneratorRunner('/path/to/project');
/// await generator.generate(target: 'lib/', all: true);
/// ```
class ReflectionGeneratorRunner {
  /// The project directory to run the generator in.
  final String projectPath;

  /// Options for the generator.
  final ReflectionGeneratorRunnerOptions options;

  /// The workspace path (parent of projects).
  final String? workspacePath;

  /// Creates a new reflection generator runner for the given project.
  ReflectionGeneratorRunner(
    this.projectPath, {
    ReflectionGeneratorRunnerOptions? options,
    this.workspacePath,
  }) : options = options ?? const ReflectionGeneratorRunnerOptions();

  /// Runs the reflection generator in generate mode.
  ///
  /// [target] - The file or directory to process (defaults to 'lib/').
  /// [all] - Whether to process all files in the target.
  Future<ReflectionGeneratorRunnerResult> generate({
    String target = 'lib/',
    bool all = false,
  }) async {
    final args = _buildArgs('generate', target: target, all: all);
    return _run(args);
  }

  /// Runs the reflection generator in build mode.
  ///
  /// Uses the build.yaml configuration in the project.
  /// [configFile] - Optional custom configuration file path.
  Future<ReflectionGeneratorRunnerResult> build({String? configFile}) async {
    final args = _buildArgs('build', configFile: configFile);
    return _run(args);
  }

  /// Builds command-line arguments for the generator.
  List<String> _buildArgs(
    String command, {
    String? target,
    bool all = false,
    String? configFile,
  }) {
    final args = <String>[command];

    if (target != null) {
      args.add(target);
    }

    if (all) {
      args.add('--all');
    }

    if (options.verbose) {
      args.add('--verbose');
    }

    if (options.packageName != null) {
      args.addAll(['--package', options.packageName!]);
    }

    if (options.extension != null) {
      args.addAll(['--extension', options.extension!]);
    }

    if (configFile != null) {
      args.addAll(['--config', configFile]);
    }

    return args;
  }

  /// Runs the generator with the given arguments via shell.
  Future<ReflectionGeneratorRunnerResult> _run(List<String> args) async {
    try {
      ProcessResult result;

      // Try to run from local workspace first
      final wsPath = workspacePath ?? p.dirname(projectPath);
      final generatorPath = p.join(wsPath, 'tom_reflection_generator');

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
          workingDirectory: projectPath,
        );
      }

      if (result.exitCode != 0) {
        return ReflectionGeneratorRunnerResult(
          success: false,
          projectPath: projectPath,
          error: 'Exit code ${result.exitCode}: ${result.stderr}',
        );
      }

      return ReflectionGeneratorRunnerResult(
        success: true,
        projectPath: projectPath,
        message: 'Reflection generation completed: ${result.stdout}',
      );
    } catch (e, stack) {
      return ReflectionGeneratorRunnerResult(
        success: false,
        projectPath: projectPath,
        error: e.toString(),
        stackTrace: stack,
      );
    }
  }
}

/// Options for the reflection generator runner.
class ReflectionGeneratorRunnerOptions {
  /// Whether to show verbose output.
  final bool verbose;

  /// The package name to use for generated files.
  final String? packageName;

  /// The file extension for generated files (default: '.reflection.dart').
  final String? extension;

  const ReflectionGeneratorRunnerOptions({
    this.verbose = false,
    this.packageName,
    this.extension,
  });
}

/// Result of a reflection generation operation.
class ReflectionGeneratorRunnerResult {
  /// Whether the generation succeeded.
  final bool success;

  /// The project path that was processed.
  final String projectPath;

  /// Success message if succeeded.
  final String? message;

  /// Error message if failed.
  final String? error;

  /// Stack trace if failed.
  final StackTrace? stackTrace;

  const ReflectionGeneratorRunnerResult({
    required this.success,
    required this.projectPath,
    this.message,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    if (success) {
      return '✓ $projectPath: ${message ?? 'OK'}';
    } else {
      return '✗ $projectPath: ${error ?? 'FAILED'}';
    }
  }
}
