/// Command execution for Tom CLI.
///
/// Handles running shell commands with proper error handling
/// and output capture.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// =============================================================================
// COMMAND RUNNER
// =============================================================================

/// Result of running a command.
class CommandResult {
  /// The command that was executed.
  final String command;

  /// Whether the command succeeded (exit code 0).
  final bool success;

  /// The exit code.
  final int exitCode;

  /// Standard output.
  final String stdout;

  /// Standard error.
  final String stderr;

  /// Duration of execution.
  final Duration duration;

  const CommandResult._({
    required this.command,
    required this.success,
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.duration,
  });

  /// Creates a successful result.
  factory CommandResult.success({
    required String command,
    required String stdout,
    String stderr = '',
    Duration duration = Duration.zero,
  }) {
    return CommandResult._(
      command: command,
      success: true,
      exitCode: 0,
      stdout: stdout,
      stderr: stderr,
      duration: duration,
    );
  }

  /// Creates a failed result.
  factory CommandResult.failure({
    required String command,
    required int exitCode,
    String stdout = '',
    String stderr = '',
    Duration duration = Duration.zero,
  }) {
    return CommandResult._(
      command: command,
      success: false,
      exitCode: exitCode,
      stdout: stdout,
      stderr: stderr,
      duration: duration,
    );
  }
}

/// Runs shell commands.
class CommandRunner {
  /// Creates a command runner.
  CommandRunner({
    this.shell = true,
    this.defaultTimeout = const Duration(minutes: 5),
  });

  /// Whether to run commands through a shell.
  final bool shell;

  /// Default timeout for commands.
  final Duration defaultTimeout;

  /// Runs a command and returns the result.
  ///
  /// Parameters:
  /// - [command]: The command to run
  /// - [workingDirectory]: The directory to run in
  /// - [environment]: Environment variables
  /// - [verbose]: Whether to print output in real-time
  /// - [timeout]: Maximum execution time
  Future<CommandResult> run({
    required String command,
    String? workingDirectory,
    Map<String, String>? environment,
    bool verbose = false,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final process = await Process.start(
        shell ? _getShell() : command.split(' ').first,
        shell ? _getShellArgs(command) : command.split(' ').skip(1).toList(),
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: false,
      );

      final stdoutBuffer = StringBuffer();
      final stderrBuffer = StringBuffer();

      // Handle stdout
      final stdoutFuture = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
        stdoutBuffer.writeln(line);
        if (verbose) {
          // ignore: avoid_print
          print(line);
        }
      });

      // Handle stderr
      final stderrFuture = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .forEach((line) {
        stderrBuffer.writeln(line);
        if (verbose) {
          // ignore: avoid_print
          print(line);
        }
      });

      // Wait for completion with timeout
      final exitCode = await process.exitCode.timeout(
        timeout ?? defaultTimeout,
        onTimeout: () {
          process.kill(ProcessSignal.sigterm);
          return -1;
        },
      );

      // Wait for streams to complete (important for capturing all output)
      await Future.wait([stdoutFuture, stderrFuture]);
      stopwatch.stop();

      if (exitCode == 0) {
        return CommandResult.success(
          command: command,
          stdout: stdoutBuffer.toString(),
          stderr: stderrBuffer.toString(),
          duration: stopwatch.elapsed,
        );
      } else {
        return CommandResult.failure(
          command: command,
          exitCode: exitCode,
          stdout: stdoutBuffer.toString(),
          stderr: stderrBuffer.toString(),
          duration: stopwatch.elapsed,
        );
      }
    } on TimeoutException {
      stopwatch.stop();
      return CommandResult.failure(
        command: command,
        exitCode: -1,
        stderr: 'Command timed out after ${(timeout ?? defaultTimeout).inSeconds}s',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return CommandResult.failure(
        command: command,
        exitCode: -1,
        stderr: 'Failed to run command: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Runs multiple commands in sequence.
  ///
  /// Returns all results. Stops on first failure if [stopOnFailure] is true.
  Future<List<CommandResult>> runAll({
    required List<String> commands,
    String? workingDirectory,
    Map<String, String>? environment,
    bool verbose = false,
    bool stopOnFailure = true,
  }) async {
    final results = <CommandResult>[];

    for (final command in commands) {
      final result = await run(
        command: command,
        workingDirectory: workingDirectory,
        environment: environment,
        verbose: verbose,
      );
      results.add(result);

      if (!result.success && stopOnFailure) {
        break;
      }
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Platform-specific helpers
  // ---------------------------------------------------------------------------

  /// Gets the appropriate shell for the current platform.
  String _getShell() {
    if (Platform.isWindows) {
      return 'cmd';
    }
    return Platform.environment['SHELL'] ?? '/bin/sh';
  }

  /// Gets shell arguments for the command.
  List<String> _getShellArgs(String command) {
    if (Platform.isWindows) {
      return ['/c', command];
    }
    return ['-c', command];
  }
}

// =============================================================================
// HELPERS
// =============================================================================

/// Extension methods for command results.
extension CommandResultExtensions on List<CommandResult> {
  /// Whether all commands succeeded.
  bool get allSucceeded => every((r) => r.success);

  /// Gets the first failed result, or null if all succeeded.
  CommandResult? get firstFailure {
    for (final result in this) {
      if (!result.success) return result;
    }
    return null;
  }

  /// Total duration of all commands.
  Duration get totalDuration {
    return fold(Duration.zero, (sum, r) => sum + r.duration);
  }
}
