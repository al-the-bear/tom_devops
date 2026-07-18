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
        // Use a known directory instead of temp (which has /private prefix on
        // macOS). `pwd` on POSIX and cmd's `cd` builtin on Windows both print
        // the current directory in the platform's native path syntax — which
        // is what `workingDir` (from the environment) is expressed in.
        final homeDir = Platform.isWindows
            ? (Platform.environment['USERPROFILE'] ?? r'C:\')
            : (Platform.environment['HOME'] ?? '/');
        final command = Platform.isWindows ? 'cd' : 'pwd';
        final result =
            TomShell.run(command, workingDir: homeDir, quiet: true);

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

    group('pipe', () {
      // cmd.exe ships neither `cat` nor `tr`, so the fixtures below select the
      // native equivalent per platform. `findstr /r "^"` matches the start of
      // every line, i.e. a verbatim passthrough (the POSIX `cat`); `sort` reads
      // and orders stdin. Windows commands emit CRLF, so multi-line output is
      // normalized before comparison.
      final passthrough = Platform.isWindows ? 'findstr /r "^"' : 'cat';

      String norm(String value) => value.replaceAll('\r\n', '\n');

      test('feeds input to the command stdin', () {
        final result = TomShell.pipe(passthrough, 'hello');

        expect(norm(result), 'hello');
      });

      test('preserves multi-line input', () {
        final result = TomShell.pipe(passthrough, 'a\nb\nc');

        expect(norm(result), 'a\nb\nc');
      });

      test('binds stdin to the head of a pipeline', () {
        // The whole command must receive the piped input, not just its last
        // segment. On POSIX `cat` reads stdin and `tr` upcases the stream; on
        // Windows the head `sort` reads stdin and orders the lines. Either way
        // the transforming stage sits at the head, so a correct result proves
        // the redirect binds to the pipeline head rather than its tail.
        if (Platform.isWindows) {
          final result = TomShell.pipe('sort | findstr /r "^"', 'b\na\nc');

          expect(norm(result), 'a\nb\nc');
        } else {
          final result = TomShell.pipe('cat | tr a-z A-Z', 'hello');

          expect(result, 'HELLO');
        }
      });

      test('input is data, never interpreted by the shell', () {
        // Shell metacharacters in the input must survive verbatim (they are fed
        // via stdin, not spliced into the command line). The payload is loaded
        // with metacharacters hostile to the host shell.
        final payload = Platform.isWindows
            ? r'%PATH% & echo pwned | whoami'
            : r'$HOME `whoami` ; rm -rf /';
        final result = TomShell.pipe(passthrough, payload);

        expect(norm(result), payload);
      });

      test('throws TomShellException on non-zero exit', () {
        final failing =
            Platform.isWindows ? 'findstr /r "^" & exit 1' : 'cat; exit 1';
        expect(
          () => TomShell.pipe(failing, 'x'),
          throwsA(isA<TomShellException>()),
        );
      });
    });
  });
}
