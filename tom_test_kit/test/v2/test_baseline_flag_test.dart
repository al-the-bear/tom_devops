/// `testkit :test --baseline`, from the command line to `createBaseline`.
///
/// The flag was declared, and `TestCommand.run` handled `createBaseline`
/// correctly (TK-TST-2), yet `testkit :test --baseline` still refused with the
/// message that recommends it. The break was between the two: an option
/// written after the command lands in the per-command options, and the
/// executor read only the global ones. Nothing tested that seam, because every
/// test called `TestCommand.run` with the argument already set. These tests
/// parse a real command line with the tool's own definition and hand it to the
/// executor, which is the path a user's shell takes.
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_test_kit/src/v2/testkit_executors.dart';
import 'package:tom_test_kit/src/v2/testkit_tool.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

CliArgs _parse(List<String> argv) =>
    CliArgParser(toolDefinition: testkitTool).parse(argv);

CommandContext _contextFor(String path) => CommandContext(
  fsFolder: FsFolder(path: path),
  natures: const [],
  executionRoot: path,
);

void main() {
  group('TK-BLF-1: the flag reaches the executor [2026-09-30]', () {
    for (final argv in const [
      [':test', '--baseline', '--dry-run'],
      ['--dry-run', ':test', '--baseline'],
    ]) {
      test('TK-BLF-1: ${argv.join(' ')} asks for a baseline', () async {
        final result = await TestExecutor().execute(
          _contextFor(Directory.systemTemp.path),
          _parse(argv),
        );
        // The dry run reports the flags it resolved through the same reads
        // that feed `createBaseline`, so a flag lost on the way shows here.
        expect(result.message, contains('--baseline'));
      });
    }

    test('TK-BLF-2: without the flag, no baseline is asked for', () async {
      final result = await TestExecutor().execute(
        _contextFor(Directory.systemTemp.path),
        _parse(const [':test', '--dry-run']),
      );
      expect(result.message, isNot(contains('--baseline')));
    });
  });

  group('TK-BLF-3: a project with no tracking file [2026-09-30]', () {
    late Directory project;

    setUp(() async {
      project = Directory.systemTemp.createTempSync('tk_baseline_flag_');
      File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync('''
name: baseline_flag_probe
version: 0.0.1
environment:
  sdk: ^3.0.0
dev_dependencies:
  test: ^1.24.0
''');
      Directory(p.join(project.path, 'test')).createSync();
      File(p.join(project.path, 'test', 'probe_test.dart')).writeAsStringSync(
        "import 'package:test/test.dart';\n"
        "void main() { test('P-1: passes', () => expect(1, 1)); }\n",
      );
      final got = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: project.path);
      if (got.exitCode != 0) throw StateError('pub get: ${got.stderr}');
    });

    tearDown(() => project.deleteSync(recursive: true));

    test(
      'TK-BLF-3: :test --baseline creates the baseline and succeeds',
      () async {
        final result = await TestExecutor().execute(
          _contextFor(project.path),
          _parse(const [':test', '--baseline']),
        );
        expect(result.success, isTrue, reason: result.error);
        expect(findLatestTrackingFile(project.path), isNotNull);
      },
    );

    test('TK-BLF-4: :test alone still refuses, as its message says', () async {
      final result = await TestExecutor().execute(
        _contextFor(project.path),
        _parse(const [':test']),
      );
      expect(result.success, isFalse);
      expect(findLatestTrackingFile(project.path), isNull);
    });
  });
}
