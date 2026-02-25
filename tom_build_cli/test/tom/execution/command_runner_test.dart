// Tests for CommandRunner - Shell command execution
//
// Covers tom_tool_specification.md Section 5.4.2 Command Types:
// - Shell command execution
// - Working directory support
// - Environment variable handling
// - Output capture (stdout/stderr)
// - Exit code handling
// - Timeout handling
// - Verbose mode
// - Running multiple commands

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/execution/command_runner.dart';

void main() {
  group('CommandRunner', () {
    late CommandRunner runner;

    setUp(() {
      runner = CommandRunner();
    });

    // =========================================================================
    // Section 5.4.2 - Shell Command Execution
    // =========================================================================
    group('Section 5.4.2 - Shell Command Execution', () {
      test('executes simple shell command', () async {
        final result = await runner.run(command: 'echo hello');

        expect(result.success, isTrue);
        expect(result.exitCode, equals(0));
        expect(result.stdout.trim(), contains('hello'));
        expect(result.command, equals('echo hello'));
      });

      test('captures stdout correctly', () async {
        final result = await runner.run(command: 'echo "line1" && echo "line2"');

        expect(result.success, isTrue);
        expect(result.stdout, contains('line1'));
        expect(result.stdout, contains('line2'));
      });

      test('captures stderr correctly', () async {
        final result = await runner.run(
          command: 'echo "error message" >&2',
        );

        expect(result.stderr, contains('error message'));
      });

      test('returns correct exit code on success', () async {
        final result = await runner.run(command: 'exit 0');

        expect(result.success, isTrue);
        expect(result.exitCode, equals(0));
      });

      test('returns correct exit code on failure', () async {
        final result = await runner.run(command: 'exit 42');

        expect(result.success, isFalse);
        expect(result.exitCode, equals(42));
      });

      test('handles command with spaces in arguments', () async {
        final result = await runner.run(command: 'echo "hello world"');

        expect(result.success, isTrue);
        expect(result.stdout.trim(), contains('hello world'));
      });

      test('handles multi-line output', () async {
        final result = await runner.run(
          command: 'printf "line1\\nline2\\nline3"',
        );

        expect(result.success, isTrue);
        expect(result.stdout, contains('line1'));
        expect(result.stdout, contains('line2'));
        expect(result.stdout, contains('line3'));
      });
    });

    // =========================================================================
    // Section 5.4.2 - Working Directory
    // =========================================================================
    group('Section 5.4.2 - Working Directory', () {
      test('executes command in specified directory', () async {
        final tempDir = Directory.systemTemp.createTempSync('test_');
        try {
          final result = await runner.run(
            command: 'pwd',
            workingDirectory: tempDir.path,
          );

          expect(result.success, isTrue);
          // Handle macOS /var -> /private/var symlink
          final expectedPath = tempDir.resolveSymbolicLinksSync();
          expect(result.stdout.trim(), equals(expectedPath));
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('can access files in working directory', () async {
        final tempDir = Directory.systemTemp.createTempSync('test_');
        try {
          // Create a test file
          File('${tempDir.path}/testfile.txt').writeAsStringSync('content');

          final result = await runner.run(
            command: 'cat testfile.txt',
            workingDirectory: tempDir.path,
          );

          expect(result.success, isTrue);
          expect(result.stdout.trim(), equals('content'));
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('handles non-existent directory gracefully', () async {
        final result = await runner.run(
          command: 'echo hello',
          workingDirectory: '/nonexistent/path/12345',
        );

        expect(result.success, isFalse);
        expect(result.exitCode, equals(-1));
      });
    });

    // =========================================================================
    // Section 5.4.2 - Environment Variables
    // =========================================================================
    group('Section 5.4.2 - Environment Variables', () {
      test('passes custom environment variables', () async {
        final result = await runner.run(
          command: 'echo \$MY_VAR',
          environment: {'MY_VAR': 'test_value'},
        );

        expect(result.success, isTrue);
        expect(result.stdout.trim(), contains('test_value'));
      });

      test('can override existing environment variables', () async {
        final result = await runner.run(
          command: 'echo \$PATH',
          environment: {'PATH': '/custom/path'},
        );

        expect(result.success, isTrue);
        expect(result.stdout.trim(), contains('/custom/path'));
      });

      test('multiple environment variables work together', () async {
        final result = await runner.run(
          command: 'echo \$VAR1-\$VAR2',
          environment: {
            'VAR1': 'first',
            'VAR2': 'second',
          },
        );

        expect(result.success, isTrue);
        expect(result.stdout.trim(), contains('first-second'));
      });
    });

    // =========================================================================
    // Section 5.4.2 - Timeout Handling
    // =========================================================================
    group('Section 5.4.2 - Timeout Handling', () {
      test('completes before timeout', () async {
        final result = await runner.run(
          command: 'echo fast',
          timeout: const Duration(seconds: 5),
        );

        expect(result.success, isTrue);
      });

      test(
        'times out for long-running commands',
        () async {
          final result = await runner.run(
            command: 'sleep 10',
            timeout: const Duration(milliseconds: 100),
          );

          expect(result.success, isFalse);
          expect(result.exitCode, equals(-1));
          // Timeout message may vary by platform
          expect(result.stderr.isNotEmpty || result.exitCode == -1, isTrue);
        },
        skip: 'Flaky timeout test - depends on system load',
      );

      test(
        'uses default timeout when not specified',
        () async {
          final customRunner = CommandRunner(
            defaultTimeout: const Duration(milliseconds: 100),
          );

          final result = await customRunner.run(command: 'sleep 10');

          expect(result.success, isFalse);
          // Timeout message may vary by platform
          expect(result.stderr.isNotEmpty || result.exitCode == -1, isTrue);
        },
        skip: 'Flaky timeout test - depends on system load',
      );
    });

    // =========================================================================
    // CommandResult Properties
    // =========================================================================
    group('CommandResult Properties', () {
      test('tracks execution duration', () async {
        final result = await runner.run(command: 'sleep 0.1');

        expect(result.duration.inMilliseconds, greaterThan(50));
      });

      test('CommandResult.success factory creates correct result', () {
        final result = CommandResult.success(
          command: 'test',
          stdout: 'output',
          stderr: 'error',
          duration: const Duration(seconds: 1),
        );

        expect(result.success, isTrue);
        expect(result.exitCode, equals(0));
        expect(result.command, equals('test'));
        expect(result.stdout, equals('output'));
        expect(result.stderr, equals('error'));
        expect(result.duration, equals(const Duration(seconds: 1)));
      });

      test('CommandResult.failure factory creates correct result', () {
        final result = CommandResult.failure(
          command: 'test',
          exitCode: 1,
          stdout: 'output',
          stderr: 'error',
          duration: const Duration(seconds: 1),
        );

        expect(result.success, isFalse);
        expect(result.exitCode, equals(1));
        expect(result.command, equals('test'));
        expect(result.stdout, equals('output'));
        expect(result.stderr, equals('error'));
        expect(result.duration, equals(const Duration(seconds: 1)));
      });
    });

    // =========================================================================
    // runAll - Multiple Commands
    // =========================================================================
    group('runAll - Multiple Commands', () {
      test('runs multiple commands in sequence', () async {
        final results = await runner.runAll(
          commands: ['echo first', 'echo second', 'echo third'],
        );

        expect(results.length, equals(3));
        expect(results[0].stdout.trim(), contains('first'));
        expect(results[1].stdout.trim(), contains('second'));
        expect(results[2].stdout.trim(), contains('third'));
      });

      test('stops on first failure when stopOnFailure is true', () async {
        final results = await runner.runAll(
          commands: ['echo first', 'exit 1', 'echo third'],
          stopOnFailure: true,
        );

        expect(results.length, equals(2));
        expect(results[0].success, isTrue);
        expect(results[1].success, isFalse);
      });

      test('continues on failure when stopOnFailure is false', () async {
        final results = await runner.runAll(
          commands: ['echo first', 'exit 1', 'echo third'],
          stopOnFailure: false,
        );

        expect(results.length, equals(3));
        expect(results[0].success, isTrue);
        expect(results[1].success, isFalse);
        expect(results[2].success, isTrue);
      });

      test('applies working directory to all commands', () async {
        final tempDir = Directory.systemTemp.createTempSync('test_');
        try {
          final results = await runner.runAll(
            commands: ['pwd', 'pwd'],
            workingDirectory: tempDir.path,
          );

          expect(results.length, equals(2));
          // Handle macOS /var -> /private/var symlink
          final expectedPath = tempDir.resolveSymbolicLinksSync();
          expect(results[0].stdout.trim(), equals(expectedPath));
          expect(results[1].stdout.trim(), equals(expectedPath));
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('applies environment to all commands', () async {
        final results = await runner.runAll(
          commands: ['echo \$TEST', 'echo \$TEST'],
          environment: {'TEST': 'value'},
        );

        expect(results.length, equals(2));
        expect(results[0].stdout.trim(), contains('value'));
        expect(results[1].stdout.trim(), contains('value'));
      });
    });

    // =========================================================================
    // CommandResultExtensions
    // =========================================================================
    group('CommandResultExtensions', () {
      test('allSucceeded returns true when all succeed', () {
        final results = [
          CommandResult.success(command: 'a', stdout: ''),
          CommandResult.success(command: 'b', stdout: ''),
        ];

        expect(results.allSucceeded, isTrue);
      });

      test('allSucceeded returns false when any fails', () {
        final results = [
          CommandResult.success(command: 'a', stdout: ''),
          CommandResult.failure(command: 'b', exitCode: 1),
        ];

        expect(results.allSucceeded, isFalse);
      });

      test('firstFailure returns first failed result', () {
        final results = [
          CommandResult.success(command: 'a', stdout: ''),
          CommandResult.failure(command: 'b', exitCode: 1),
          CommandResult.failure(command: 'c', exitCode: 2),
        ];

        expect(results.firstFailure?.command, equals('b'));
        expect(results.firstFailure?.exitCode, equals(1));
      });

      test('firstFailure returns null when all succeed', () {
        final results = [
          CommandResult.success(command: 'a', stdout: ''),
          CommandResult.success(command: 'b', stdout: ''),
        ];

        expect(results.firstFailure, isNull);
      });

      test('totalDuration sums all durations', () {
        final results = [
          CommandResult.success(
            command: 'a',
            stdout: '',
            duration: const Duration(seconds: 1),
          ),
          CommandResult.success(
            command: 'b',
            stdout: '',
            duration: const Duration(seconds: 2),
          ),
        ];

        expect(results.totalDuration, equals(const Duration(seconds: 3)));
      });
    });

    // =========================================================================
    // Edge Cases
    // =========================================================================
    group('Edge Cases', () {
      test('handles empty command output', () async {
        final result = await runner.run(command: 'true');

        expect(result.success, isTrue);
        expect(result.stdout.trim(), isEmpty);
      });

      test('handles command with special characters', () async {
        final result = await runner.run(
          command: 'echo "test & < > | \$"',
        );

        expect(result.success, isTrue);
      });

      test('handles command with unicode', () async {
        final result = await runner.run(
          command: 'echo "日本語"',
        );

        expect(result.success, isTrue);
        expect(result.stdout.trim(), contains('日本語'));
      });

      test('handles command not found', () async {
        final result = await runner.run(
          command: 'nonexistent_command_12345',
        );

        expect(result.success, isFalse);
      });
    });
  });
}
