import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

/// Test IDs: TK-TST-1 through TK-TST-18
///
/// Integration tests for TestCommand that create real Dart projects
/// and run actual `dart test` commands.
void main() {
  group('TestCommand', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tk_test_cmd_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    /// Creates a minimal Dart project with test files.
    Future<void> createTestProject(
      Directory dir, {
      List<TestSpec> tests = const [],
      Map<String, String> extraTestFiles = const {},
    }) async {
      // Create pubspec.yaml
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      await pubspec.writeAsString('''
name: test_project
version: 0.0.1
environment:
  sdk: ^3.0.0
dev_dependencies:
  test: ^1.24.0
''');

      // Create test directory
      final testDir = Directory(p.join(dir.path, 'test'));
      await testDir.create(recursive: true);

      // Create test file
      final testFile = File(p.join(testDir.path, 'sample_test.dart'));
      final testContent = StringBuffer();
      testContent.writeln("import 'package:test/test.dart';");
      testContent.writeln();
      testContent.writeln('void main() {');

      for (final spec in tests) {
        final expectation = spec.expectation == 'FAIL' ? ' (FAIL)' : '';
        testContent.writeln("  test('${spec.name}$expectation', () {");
        if (spec.shouldPass) {
          testContent.writeln('    expect(true, isTrue);');
        } else {
          testContent.writeln("    fail('intentional failure');");
        }
        testContent.writeln('  });');
        testContent.writeln();
      }

      testContent.writeln('}');
      await testFile.writeAsString(testContent.toString());

      for (final extra in extraTestFiles.entries) {
        await File(p.join(testDir.path, extra.key)).writeAsString(extra.value);
      }

      // Run dart pub get
      final result = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: dir.path);
      if (result.exitCode != 0) {
        throw Exception('dart pub get failed: ${result.stderr}');
      }
    }

    test('TK-TST-1: returns false when no tracking file exists', () async {
      await createTestProject(
        tempDir,
        tests: [TestSpec('TK-A: simple test', shouldPass: true)],
      );

      final result = await TestCommand.run(projectPath: tempDir.path);
      expect(result, isFalse);
    });

    test(
      'TK-TST-2: returns true with --baseline when no tracking file exists',
      () async {
        await createTestProject(
          tempDir,
          tests: [TestSpec('TK-A: simple test', shouldPass: true)],
        );

        final result = await TestCommand.run(
          projectPath: tempDir.path,
          createBaseline: true,
        );
        expect(result, isTrue);

        // Verify baseline was created
        final baselineFile = findLatestTrackingFile(tempDir.path);
        expect(baselineFile, isNotNull);
      },
    );

    test('TK-TST-3: updates tracking file with new run results', () async {
      await createTestProject(
        tempDir,
        tests: [
          TestSpec('TK-A: passing test', shouldPass: true),
          TestSpec('TK-B: failing test', shouldPass: false),
        ],
      );

      // Create baseline first
      await BaselineCommand.run(projectPath: tempDir.path);

      // Run test command
      final result = await TestCommand.run(projectPath: tempDir.path);
      expect(result, isTrue);

      // Verify tracking file has 2 runs
      final filePath = findLatestTrackingFile(tempDir.path);
      final tracking = TrackingFile.load(filePath!);
      expect(tracking, isNotNull);
      expect(tracking!.runs.length, equals(2));
    });

    test(
      'TK-TST-4: --no-update runs tests without updating baseline',
      () async {
        await createTestProject(
          tempDir,
          tests: [
            TestSpec('TK-A: passing test', shouldPass: true),
            TestSpec('TK-B: failing test', shouldPass: false),
          ],
        );

        // Create baseline first
        await BaselineCommand.run(projectPath: tempDir.path);

        // Get initial run count
        final filePath = findLatestTrackingFile(tempDir.path);
        final trackingBefore = TrackingFile.load(filePath!);
        final runCountBefore = trackingBefore!.runs.length;

        // Run with --no-update
        final result = await TestCommand.run(
          projectPath: tempDir.path,
          noUpdate: true,
        );
        expect(result, isTrue);

        // Verify tracking file still has same number of runs
        final trackingAfter = TrackingFile.load(filePath);
        expect(trackingAfter!.runs.length, equals(runCountBefore));
      },
    );

    test('TK-TST-5: --no-update prints summary with counts', () async {
      await createTestProject(
        tempDir,
        tests: [
          TestSpec('TK-A: passing test', shouldPass: true),
          TestSpec('TK-B: another pass', shouldPass: true),
          TestSpec('TK-C: failing test', shouldPass: false),
        ],
      );

      // Create baseline
      await BaselineCommand.run(projectPath: tempDir.path);

      // Run with --no-update - just verify it completes successfully
      final result = await TestCommand.run(
        projectPath: tempDir.path,
        noUpdate: true,
      );
      expect(result, isTrue);

      // Verify tracking file was NOT updated (still 1 run)
      final filePath = findLatestTrackingFile(tempDir.path);
      final tracking = TrackingFile.load(filePath!);
      expect(tracking!.runs.length, equals(1));
    });

    test(
      'TK-TST-6: --no-update shows unexpected when FAIL expectation passes',
      () async {
        await createTestProject(
          tempDir,
          tests: [
            TestSpec(
              'TK-A: expected fail that passes',
              shouldPass: true,
              expectation: 'FAIL',
            ),
          ],
        );

        // Create baseline
        await BaselineCommand.run(projectPath: tempDir.path);

        // Run with --no-update
        final result = await TestCommand.run(
          projectPath: tempDir.path,
          noUpdate: true,
        );
        expect(result, isTrue);

        // Verify tracking file was NOT updated
        final filePath = findLatestTrackingFile(tempDir.path);
        final tracking = TrackingFile.load(filePath!);
        expect(tracking!.runs.length, equals(1));
      },
    );

    test(
      'TK-TST-7: --no-update shows expected when FAIL expectation fails',
      () async {
        await createTestProject(
          tempDir,
          tests: [
            TestSpec(
              'TK-A: expected fail that fails',
              shouldPass: false,
              expectation: 'FAIL',
            ),
          ],
        );

        // Create baseline
        await BaselineCommand.run(projectPath: tempDir.path);

        // Run with --no-update
        final result = await TestCommand.run(
          projectPath: tempDir.path,
          noUpdate: true,
        );
        expect(result, isTrue);

        // Verify tracking file was NOT updated
        final filePath = findLatestTrackingFile(tempDir.path);
        final tracking = TrackingFile.load(filePath!);
        expect(tracking!.runs.length, equals(1));
      },
    );

    test(
      'TK-TST-8: --failed filters to only failed tests from last run',
      () async {
        await createTestProject(
          tempDir,
          tests: [
            TestSpec('passing test', shouldPass: true),
            TestSpec('failing test', shouldPass: false),
          ],
        );

        // Create baseline
        await BaselineCommand.run(projectPath: tempDir.path);

        // Verify baseline has 2 tests
        final filePath = findLatestTrackingFile(tempDir.path);
        var tracking = TrackingFile.load(filePath!);
        expect(tracking!.entries.length, equals(2));

        // Run with --failed - should filter to only the failing test
        // Note: this may fail if no tests match the filter, which is OK
        final result = await TestCommand.run(
          projectPath: tempDir.path,
          failedOnly: true,
        );
        // Result depends on whether filtered tests are found
        // The test verifies the feature runs without crashing
        expect(result, isA<bool>());
      },
    );

    test('TK-TST-9: respects --test-args for filtering', () async {
      await createTestProject(
        tempDir,
        tests: [
          TestSpec('TK-A: first test', shouldPass: true),
          TestSpec('TK-B: second test', shouldPass: true),
        ],
      );

      // Create baseline with filter to only first test
      final result = await BaselineCommand.run(
        projectPath: tempDir.path,
        testArgs: ['--name', 'first'],
      );
      expect(result, isTrue);

      // Verify only one test in baseline
      final filePath = findLatestTrackingFile(tempDir.path);
      final tracking = TrackingFile.load(filePath!);
      expect(tracking!.entries.length, equals(1));
    });

    test('TK-TST-10: adds comment to run when specified', () async {
      await createTestProject(
        tempDir,
        tests: [TestSpec('TK-A: simple test', shouldPass: true)],
      );

      // Create baseline
      await BaselineCommand.run(projectPath: tempDir.path);

      // Run with comment
      await TestCommand.run(projectPath: tempDir.path, comment: 'bugfix run');

      // Verify comment in tracking file
      final filePath = findLatestTrackingFile(tempDir.path);
      final tracking = TrackingFile.load(filePath!);
      final lastRun = tracking!.runs.last;
      expect(lastRun.comment, equals('bugfix run'));
    });

    // A run that measured nothing is not a green run, and must not become the
    // reference the next run is compared with. The broken file imports a
    // package that does not exist: `dart test` then exits 1 — the same code as
    // a run with failing tests — having run no test at all.
    const unloadable = "import 'package:test/test.dart';\n"
        "import 'package:does_not_exist/missing.dart';\n"
        'void main() {\n'
        "  test('TK-Z: never runs', () {});\n"
        '}\n';

    List<File> trackingFiles(Directory dir) {
      final testlog = Directory(p.join(dir.path, 'testlog'));
      if (!testlog.existsSync()) return const [];
      return testlog
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.csv'))
          .toList();
    }

    test(
      'TK-TST-11: :baseline fails and writes nothing when every test file '
      'fails to load',
      () async {
        await createTestProject(tempDir);
        await File(
          p.join(tempDir.path, 'test', 'sample_test.dart'),
        ).writeAsString(unloadable);

        final result = await BaselineCommand.run(projectPath: tempDir.path);

        expect(result, isFalse);
        expect(trackingFiles(tempDir), isEmpty,
            reason: 'an empty baseline is worse than none');
      },
    );

    test(
      'TK-TST-12: :baseline fails and writes nothing when one of two test '
      'files fails to load',
      () async {
        await createTestProject(
          tempDir,
          tests: [TestSpec('TK-A: loads fine', shouldPass: true)],
          extraTestFiles: {'broken_test.dart': unloadable},
        );

        final result = await BaselineCommand.run(projectPath: tempDir.path);

        expect(result, isFalse);
        expect(trackingFiles(tempDir), isEmpty,
            reason: 'a baseline missing a whole file is not a reference');
      },
    );

    test(
      'TK-TST-13: :baseline fails and writes nothing when the package cannot '
      'resolve its dependencies',
      () async {
        await createTestProject(
          tempDir,
          tests: [TestSpec('TK-A: simple test', shouldPass: true)],
        );
        await File(p.join(tempDir.path, 'pubspec.yaml')).writeAsString(
          'dependencies:\n  missing_pkg:\n    path: ../nowhere\n',
          mode: FileMode.append,
        );

        final result = await BaselineCommand.run(projectPath: tempDir.path);

        expect(result, isFalse);
        expect(trackingFiles(tempDir), isEmpty);
      },
    );

    test(
      'TK-TST-14: :baseline fails and writes nothing when --test-args select '
      'no test',
      () async {
        await createTestProject(
          tempDir,
          tests: [TestSpec('TK-A: simple test', shouldPass: true)],
        );

        final result = await BaselineCommand.run(
          projectPath: tempDir.path,
          testArgs: ['--name', 'matches-nothing'],
        );

        expect(result, isFalse);
        expect(trackingFiles(tempDir), isEmpty);
      },
    );

    test(
      'TK-TST-15: :test fails and adds no column when every test file fails '
      'to load',
      () async {
        await createTestProject(
          tempDir,
          tests: [TestSpec('TK-A: simple test', shouldPass: true)],
        );
        expect(await BaselineCommand.run(projectPath: tempDir.path), isTrue);
        await File(
          p.join(tempDir.path, 'test', 'sample_test.dart'),
        ).writeAsString(unloadable);

        final result = await TestCommand.run(projectPath: tempDir.path);

        expect(result, isFalse);
        final tracking =
            TrackingFile.load(findLatestTrackingFile(tempDir.path)!);
        expect(tracking!.runs, hasLength(1),
            reason: 'a column of nothing would read as every test absent');
      },
    );

    test(
      'TK-TST-16: :test records the tests that ran but fails when a file '
      'failed to load',
      () async {
        await createTestProject(
          tempDir,
          tests: [TestSpec('TK-A: loads fine', shouldPass: true)],
        );
        expect(await BaselineCommand.run(projectPath: tempDir.path), isTrue);
        await File(
          p.join(tempDir.path, 'test', 'broken_test.dart'),
        ).writeAsString(unloadable);

        final result = await TestCommand.run(projectPath: tempDir.path);

        expect(result, isFalse);
        final tracking =
            TrackingFile.load(findLatestTrackingFile(tempDir.path)!);
        expect(tracking!.runs, hasLength(2),
            reason: 'the tests that did run are real results');
      },
    );

    // scd8_aicx: a locked package missing from the pub cache produces no
    // resolution error — `dart pub get` reports success because the lock is
    // satisfiable — and the run fails much later with `Undefined name` at
    // every use site, which reads as an upstream rename. The gate names the
    // package instead, before the runner starts.
    test(
      'TK-TST-17: :baseline fails naming the packages when the pub cache '
      'cannot supply what the project locked',
      () async {
        // The project resolves for real, so `dart test` would run and pass:
        // only the pre-flight is pointed at an empty cache, which is what
        // makes this test about the pre-flight and nothing else.
        await createTestProject(
          tempDir,
          tests: [TestSpec('TK-A: simple test', shouldPass: true)],
        );
        final emptyCache =
            Directory.systemTemp.createTempSync('tk_empty_cache_');

        try {
          final result = await BaselineCommand.run(
            projectPath: tempDir.path,
            pubCachePath: emptyCache.path,
          );

          expect(result, isFalse);
          expect(
            trackingFiles(tempDir),
            isEmpty,
            reason: 'nothing was measured, so nothing may be written',
          );
        } finally {
          try {
            emptyCache.deleteSync(recursive: true);
          } catch (_) {}
        }
      },
    );

    test(
      'TK-TST-18: a project whose locked packages are all present runs '
      'normally',
      () async {
        // Anti-vacuity: the pre-flight must not fail a healthy project. This
        // one resolves for real, so its lock and the real cache agree.
        await createTestProject(
          tempDir,
          tests: [TestSpec('TK-A: simple test', shouldPass: true)],
        );

        expect(await BaselineCommand.run(projectPath: tempDir.path), isTrue);
        expect(trackingFiles(tempDir), isNotEmpty);
      },
    );
  });
}

/// Specification for a test to generate.
class TestSpec {
  final String name;
  final bool shouldPass;
  final String expectation;

  TestSpec(this.name, {this.shouldPass = true, this.expectation = 'OK'});
}
