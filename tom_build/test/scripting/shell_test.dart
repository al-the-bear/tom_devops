/// Tests for Shell scripting helper.
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/scripting.dart';

void main() {
  group('Shell', () {
    group('which', () {
      test('finds dart executable', () {
        final path = TomShell.which('dart');

        expect(path, isNotNull);
        expect(path, isNotEmpty);
        expect(File(path!).existsSync(), isTrue);
      });

      test('returns null for non-existent command', () {
        final path = TomShell.which('this_command_surely_does_not_exist_12345');

        expect(path, isNull);
      });

      test('finds common commands', () {
        // At least one of these should exist on any system
        final commands = ['echo', 'ls', 'cat', 'pwd'];
        var foundAny = false;

        for (final cmd in commands) {
          if (TomShell.which(cmd) != null) {
            foundAny = true;
            break;
          }
        }

        expect(foundAny, isTrue);
      });
    });

    group('hasCommand', () {
      test('returns true for dart', () {
        expect(TomShell.hasCommand('dart'), isTrue);
      });

      test('returns false for non-existent command', () {
        expect(
          TomShell.hasCommand('this_command_surely_does_not_exist_12345'),
          isFalse,
        );
      });

      test('agrees with which', () {
        final hasDart = TomShell.hasCommand('dart');
        final whichDart = TomShell.which('dart');

        expect(hasDart, whichDart != null);
      });
    });

    group('run', () {
      test('executes command and returns output', () {
        final result = TomShell.run('echo hello', quiet: true);

        expect(result.trim(), 'hello');
      });

      test('throws TomShellException on failure', () {
        expect(
          () => TomShell.run('exit 1', quiet: true),
          throwsA(isA<TomShellException>()),
        );
      });

      test('captures stderr in exception', () {
        try {
          TomShell.run('echo error >&2 && exit 1', quiet: true);
          fail('Should have thrown');
        } on TomShellException catch (e) {
          expect(e.exitCode, 1);
          expect(e.stderr, contains('error'));
        }
      });

      test('respects working directory', () {
        // Use a known directory instead of temp (which has /private prefix on macOS)
        final homeDir = Platform.environment['HOME'] ?? '/';
        final result = TomShell.run('pwd', workingDir: homeDir, quiet: true);

        expect(result.trim(), equals(homeDir));
      });
    });

    group('exec', () {
      test('returns 0 for successful command', () {
        final exitCode = TomShell.exec('true');

        expect(exitCode, 0);
      });

      test('returns non-zero for failed command', () {
        final exitCode = TomShell.exec('false');

        expect(exitCode, isNot(0));
      });
    });

    group('capture', () {
      test('executes command silently', () {
        final result = TomShell.capture('echo silent');

        expect(result.trim(), 'silent');
      });
    });

    group('runAll', () {
      test('executes multiple commands', () {
        final results = TomShell.runAll(['echo one', 'echo two']);

        expect(results.length, 2);
        expect(results[0].trim(), 'one');
        expect(results[1].trim(), 'two');
      });

      test('stopOnError stops at first failure', () {
        expect(
          () => TomShell.runAll(
            ['echo ok', 'exit 1', 'echo never'],
            stopOnError: true,
          ),
          throwsA(isA<TomShellException>()),
        );
      });
    });
  });
}
