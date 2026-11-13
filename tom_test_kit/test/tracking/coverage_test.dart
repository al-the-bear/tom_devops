import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

/// `--coverage` on `:test` / `:baseline`: the lcov report, the run's line
/// coverage in its column header, and both runners (`dart test`,
/// `flutter test`) measuring it.
///
/// Test IDs: TK-COV-1..6.
void main() {
  group('LineCoverage', () {
    test('TK-COV-1: an lcov report is summed from LH/LF, or from DA records '
        'where a file has none', () {
      const lcov = '''
SF:lib/a.dart
DA:1,1
DA:2,0
LF:2
LH:1
end_of_record
SF:lib/b.dart
DA:1,3
DA:2,1
DA:3,0
end_of_record
''';
      final coverage = LineCoverage.parseLcov(lcov)!;
      expect((coverage.covered, coverage.coverable), (3, 5));
      expect(coverage.describe(), '60.0% (3/5 lines)');
      expect(LineCoverage.parseLcov(''), isNull);
    });

    test('TK-COV-2: the run column header keeps the coverage, before the '
        'comment, and a tracking file round-trips it', () async {
      final run = TestRun(
        timestamp: DateTime(2026, 11, 13, 21, 50),
        comment: 'after the fix',
        coverage: const LineCoverage(covered: 1234, coverable: 1520),
      );
      expect(run.columnHeader, '[11-13 21:50] cov:1234/1520 after the fix');

      final parsed = parseColumnHeader(run.columnHeader)!;
      expect(
        parsed.coverage,
        const LineCoverage(covered: 1234, coverable: 1520),
      );
      expect(parsed.comment, 'after the fix');

      final plain = parseColumnHeader('Baseline [11-13 21:50] just a note')!;
      expect((plain.coverage, plain.comment), (null, 'just a note'));

      final dir = Directory.systemTemp.createTempSync('tk_cov_rt_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = p.join(dir.path, 'baseline.csv');
      final entry = TestDescriptionParser.parse('t');
      await TrackingFile.fromBaseline([entry], run).write(file);
      final loaded = TrackingFile.load(file)!;
      expect(loaded.runs.single.coverage, run.coverage);
      expect(loaded.runs.single.comment, 'after the fix');
    });
  });

  group('runner arguments', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('tk_cov_args_'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('TK-COV-3: dart test --coverage-path; flutter test --coverage '
        '--coverage-path', () {
      File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('name: x\n');
      expect(
        TestRunner.forPackage(
          dir.path,
          windows: false,
        ).argsFor(const ['--name', 'x'], coveragePath: '/p/coverage/lcov.info'),
        [
          'test',
          '--reporter',
          'json',
          '--coverage-path=/p/coverage/lcov.info',
          '--name',
          'x',
        ],
      );
      File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync(
        'name: x\ndependencies:\n  flutter:\n    sdk: flutter\n',
      );
      expect(
        TestRunner.forPackage(
          dir.path,
          windows: false,
        ).argsFor(const [], coveragePath: '/c.info'),
        ['test', '--reporter', 'json', '--coverage', '--coverage-path=/c.info'],
      );
    });

    test('TK-COV-4: a package:test before 1.27.0 cannot write lcov, and '
        'says so', () {
      String lock(String version) =>
          'packages:\n  test:\n    dependency: "direct dev"\n'
          '    description:\n      name: test\n'
          '    source: hosted\n    version: "$version"\n';
      File(p.join(dir.path, 'pubspec.lock')).writeAsStringSync(lock('1.26.3'));
      expect(
        DartTestParser.coverageUnsupportedReason(dir.path),
        contains('1.26.3'),
      );
      File(p.join(dir.path, 'pubspec.lock')).writeAsStringSync(lock('1.31.2'));
      expect(DartTestParser.coverageUnsupportedReason(dir.path), isNull);
    });
  });

  group('both runners', () {
    late Directory project;
    setUp(() => project = Directory.systemTemp.createTempSync('tk_cov_run_'));
    tearDown(() => project.deleteSync(recursive: true));

    /// A package whose test calls one of two library functions, so its line
    /// coverage is partial.
    Future<void> createPackage({required bool flutter}) async {
      File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync(
        flutter
            ? 'name: cov_probe\nenvironment:\n  sdk: ^3.0.0\n'
                  'dependencies:\n  flutter:\n    sdk: flutter\n'
                  'dev_dependencies:\n  flutter_test:\n    sdk: flutter\n'
            : 'name: cov_probe\nenvironment:\n  sdk: ^3.0.0\n'
                  'dev_dependencies:\n  test: ^1.27.0\n',
      );
      File(p.join(project.path, 'lib', 'cov_probe.dart'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          'int add(int a, int b) {\n  return a + b;\n}\n\n'
          'int sub(int a, int b) {\n  final d = a - b;\n  return d;\n}\n',
        );
      final testImport = flutter
          ? 'package:flutter_test/flutter_test.dart'
          : 'package:test/test.dart';
      File(p.join(project.path, 'test', 'cov_probe_test.dart'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          "import '$testImport';\n"
          "import 'package:cov_probe/cov_probe.dart';\n"
          'void main() {\n'
          "  test('C-1: add', () => expect(add(1, 2), 3));\n"
          '}\n',
        );
      final tool = flutter ? 'flutter' : 'dart';
      var got = await Process.run(tool, [
        'pub',
        'get',
        '--offline',
      ], workingDirectory: project.path);
      if (got.exitCode != 0) {
        got = await Process.run(tool, [
          'pub',
          'get',
        ], workingDirectory: project.path);
      }
      if (got.exitCode != 0) throw StateError('pub get: ${got.stderr}');
    }

    Future<void> runBoth() async {
      final lcov = File(p.join(project.path, 'coverage', 'lcov.info'));

      expect(
        await BaselineCommand.run(projectPath: project.path, coverage: true),
        isTrue,
      );
      expect(lcov.existsSync(), isTrue, reason: 'coverage/lcov.info');
      var tracking = TrackingFile.load(findLatestTrackingFile(project.path)!)!;
      final baselineCoverage = tracking.runs.single.coverage!;
      expect(baselineCoverage.covered, greaterThan(0));
      expect(
        baselineCoverage.covered,
        lessThan(baselineCoverage.coverable),
        reason: 'sub() is not called by the test',
      );

      expect(
        await TestCommand.run(projectPath: project.path, coverage: true),
        isTrue,
      );
      tracking = TrackingFile.load(findLatestTrackingFile(project.path)!)!;
      expect(tracking.runs, hasLength(2));
      expect(tracking.runs.last.coverage, baselineCoverage);

      // Without --coverage the run records none.
      expect(await TestCommand.run(projectPath: project.path), isTrue);
      tracking = TrackingFile.load(findLatestTrackingFile(project.path)!)!;
      expect(tracking.runs.last.coverage, isNull);
    }

    test(
      'TK-COV-5: dart test writes lcov; the coverage is kept per run',
      () async {
        await createPackage(flutter: false);
        await runBoth();
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    test(
      'TK-COV-6: flutter test writes lcov; the coverage is kept per run',
      () async {
        await createPackage(flutter: true);
        await runBoth();
      },
      timeout: const Timeout(Duration(minutes: 6)),
    );
  });
}
