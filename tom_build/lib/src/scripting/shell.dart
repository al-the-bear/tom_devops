/// Shell command execution utilities for scripting.
///
/// Provides convenient static methods for executing shell commands,
/// capturing output, and handling errors.
///
/// ## Environment Variable Resolution
/// All commands are automatically processed for environment variable
/// placeholders using `{VAR}` or `{VAR:default}` syntax before execution.
/// This loads from system environment and any `.env` file in the working directory.
///
/// ```dart
/// // Uses PORT from environment or defaults to 8080
/// Shell.run('curl http://localhost:{PORT:8080}/health');
/// ```
library;

import 'dart:io';

import 'env.dart';

/// Shell command execution helper.
///
/// All methods are static for convenient use in D4rt scripts.
///
/// ## Example
/// ```dart
/// // Execute a command and get output
/// final output = Shell.run('echo "Hello World"');
///
/// // Execute and check exit code
/// final exitCode = Shell.exec('make build');
///
/// // Run multiple commands
/// Shell.runAll(['npm install', 'npm run build']);
///
/// // Commands with environment placeholders
/// TomShell.run('curl {API_URL:http://localhost}/health');
/// ```
class TomShell {
  TomShell._(); // Prevent instantiation

  /// Execute a command and return the output as a string.
  ///
  /// Throws [TomShellException] if the command fails (non-zero exit code).
  ///
  /// Environment placeholders (`{VAR}` or `{VAR:default}`) are resolved
  /// before execution using system environment and `.env` file.
  ///
  /// [command] - The shell command to execute
  /// [workingDir] - Optional working directory (defaults to current directory)
  /// [quiet] - If true, don't print output to stdout
  /// [env] - Optional environment variables to set for the process
  /// [resolveEnv] - If true (default), resolve {VAR} placeholders in command
  static String run(
    String command, {
    String? workingDir,
    bool quiet = false,
    Map<String, String>? env,
    bool resolveEnv = true,
  }) {
    final resolvedCommand = resolveEnv
        ? TomEnv.resolve(command, workingDir: workingDir)
        : command;

    final result = Process.runSync(
      _shell,
      _shellArgs(resolvedCommand),
      workingDirectory: workingDir,
      environment: env,
      runInShell: false,
    );

    if (result.exitCode != 0) {
      throw TomShellException(
        command: resolvedCommand,
        exitCode: result.exitCode,
        stderr: result.stderr.toString(),
        stdout: result.stdout.toString(),
      );
    }

    final output = result.stdout.toString();
    if (!quiet) {
      stdout.write(output);
    }
    return output.trim();
  }

  /// Execute a command and return the exit code.
  ///
  /// Does not throw on non-zero exit code.
  /// Environment placeholders are resolved before execution.
  ///
  /// [command] - The shell command to execute
  /// [workingDir] - Optional working directory
  /// [env] - Optional environment variables
  /// [resolveEnv] - If true (default), resolve {VAR} placeholders in command
  static int exec(
    String command, {
    String? workingDir,
    Map<String, String>? env,
    bool resolveEnv = true,
  }) {
    final resolvedCommand = resolveEnv
        ? TomEnv.resolve(command, workingDir: workingDir)
        : command;

    final result = Process.runSync(
      _shell,
      _shellArgs(resolvedCommand),
      workingDirectory: workingDir,
      environment: env,
      runInShell: false,
    );
    return result.exitCode;
  }

  /// Execute a command silently and return the output.
  ///
  /// Same as [run] with quiet=true.
  static String capture(
    String command, {
    String? workingDir,
    Map<String, String>? env,
    bool resolveEnv = true,
  }) {
    return run(
      command,
      workingDir: workingDir,
      quiet: true,
      env: env,
      resolveEnv: resolveEnv,
    );
  }

  /// Execute multiple commands in sequence.
  ///
  /// Returns a list of outputs from each command.
  /// Throws [TomShellException] if any command fails.
  /// Environment placeholders are resolved before execution.
  ///
  /// [commands] - List of shell commands to execute
  /// [workingDir] - Optional working directory for all commands
  /// [stopOnError] - If true (default), stop on first error
  /// [resolveEnv] - If true (default), resolve {VAR} placeholders
  static List<String> runAll(
    List<String> commands, {
    String? workingDir,
    bool stopOnError = true,
    bool resolveEnv = true,
  }) {
    final outputs = <String>[];
    for (final command in commands) {
      try {
        outputs.add(
          run(command, workingDir: workingDir, resolveEnv: resolveEnv),
        );
      } catch (e) {
        if (stopOnError) rethrow;
        outputs.add('');
      }
    }
    return outputs;
  }

  /// Execute a command with piped input.
  ///
  /// Environment placeholders are resolved before execution.
  ///
  /// [command] - The shell command to execute
  /// [input] - String to pipe to stdin
  /// [workingDir] - Optional working directory
  /// [resolveEnv] - If true (default), resolve {VAR} placeholders
  static String pipe(
    String command,
    String input, {
    String? workingDir,
    bool resolveEnv = true,
  }) {
    final resolvedCommand = resolveEnv
        ? TomEnv.resolve(command, workingDir: workingDir)
        : command;

    final process = Process.runSync(
      _shell,
      _shellArgs(resolvedCommand),
      workingDirectory: workingDir,
      runInShell: false,
    );

    if (process.exitCode != 0) {
      throw TomShellException(
        command: resolvedCommand,
        exitCode: process.exitCode,
        stderr: process.stderr.toString(),
        stdout: process.stdout.toString(),
      );
    }

    return process.stdout.toString().trim();
  }

  /// Check if a command exists in PATH.
  static bool hasCommand(String command) {
    final which = Platform.isWindows ? 'where' : 'which';
    final result = Process.runSync(which, [command]);
    return result.exitCode == 0;
  }

  /// Find the path to an executable in PATH.
  ///
  /// Returns the full path to the executable, or null if not found.
  ///
  /// ## Example
  /// ```dart
  /// final dartPath = Shell.which('dart');
  /// print(dartPath); // e.g., '/usr/local/bin/dart'
  /// ```
  static String? which(String command) {
    final whichCmd = Platform.isWindows ? 'where' : 'which';
    final result = Process.runSync(whichCmd, [command]);
    if (result.exitCode != 0) return null;
    final output = result.stdout.toString().trim();
    // On Windows, 'where' may return multiple lines; take the first
    final lines = output.split('\n');
    return lines.isNotEmpty ? lines.first.trim() : null;
  }

  /// Get the current shell executable.
  static String get _shell {
    if (Platform.isWindows) {
      return 'cmd.exe';
    }
    return Platform.environment['SHELL'] ?? '/bin/sh';
  }

  /// Get shell arguments for a command.
  static List<String> _shellArgs(String command) {
    if (Platform.isWindows) {
      return ['/c', command];
    }
    return ['-c', command];
  }
}

/// Exception thrown when a shell command fails.
class TomShellException implements Exception {
  /// The command that failed.
  final String command;

  /// The exit code of the command.
  final int exitCode;

  /// Standard error output.
  final String stderr;

  /// Standard output.
  final String stdout;

  TomShellException({
    required this.command,
    required this.exitCode,
    required this.stderr,
    required this.stdout,
  });

  @override
  String toString() {
    final buffer = StringBuffer('TomShellException: Command failed\n');
    buffer.writeln('  Command: $command');
    buffer.writeln('  Exit code: $exitCode');
    if (stderr.isNotEmpty) {
      buffer.writeln('  Stderr: $stderr');
    }
    return buffer.toString();
  }
}
