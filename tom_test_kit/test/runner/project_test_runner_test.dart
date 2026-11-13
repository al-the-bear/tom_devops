/// Which runner testkit picks for a project, and a whole baseline / test
/// cycle through a project's own test script.
///
/// Test IDs: TK-PTR-1..13.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

void main() {
  late Directory project;
  late FsFolder folder;

  setUp(() {
    project = Directory.systemTemp.createTempSync('tk_ptr_');
    project = Directory(project.resolveSymbolicLinksSync());
    folder = FsFolder(path: project.path);
  });
  tearDown(() => project.deleteSync(recursive: true));

  void write(String rel, String text) => File(p.join(project.path, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);

  ProjectTestRunner resolve(List<RunFolder> natures) =>
      ProjectTestRunner.resolve(project.path, natures);

  CommandRunner commandRunner(List<RunFolder> natures) {
    final r = resolve(natures);
    expect(r, isA<CommandRunner>());
    return r as CommandRunner;
  }

  group('TK-PTR-1: language defaults', () {
    test('TK-PTR-1: go, rust, python, java (maven, gradle), javascript', () {
      final go = commandRunner([GoFolder(folder, modulePath: 'example.com/a')]);
      expect(
        (go.command, go.format),
        ('go test -json ./...', ReportFormat.goJson),
      );
      final rust = commandRunner([RustFolder(folder)]);
      expect(
        (rust.command, rust.format),
        ('cargo test --no-fail-fast', ReportFormat.libtest),
      );
      final py = commandRunner([
        PythonFolder(folder, projectFile: 'pyproject.toml'),
      ]);
      expect(py.command, 'python3 -m pytest -q --junitxml={report}');
      expect(py.format, ReportFormat.junit);
      final mvn = commandRunner([
        JavaFolder(
          folder,
          buildTool: JavaBuildTool.maven,
          projectFile: 'pom.xml',
        ),
      ]);
      expect(mvn.command, 'mvn -B test');
      expect(mvn.reportPath, 'target/surefire-reports/TEST-*.xml');
      final gradle = commandRunner([
        JavaFolder(
          folder,
          buildTool: JavaBuildTool.gradle,
          projectFile: 'build.gradle',
        ),
      ]);
      expect(gradle.command, 'gradle test');
      expect(gradle.reportPath, 'build/test-results/test/*.xml');
      final js = commandRunner([JavaScriptFolder(folder)]);
      expect(js.command, contains('node --test --test-reporter=junit'));
      expect(js.origin, 'default (javascript)');
    });
  });

  test('TK-PTR-2: jest in package.json picks jest --json, for JavaScript '
      'and TypeScript', () {
    write('package.json', '{"devDependencies": {"jest": "^29.0.0"}}');
    for (final nature in [JavaScriptFolder(folder), TypeScriptFolder(folder)]) {
      final r = commandRunner([nature]);
      expect(r.command, 'npx jest --json --outputFile={report}');
      expect(r.format, ReportFormat.jestJson);
    }
  });

  test('TK-PTR-3: C, C++ and TypeScript without jest have no default and say '
      'what to configure', () {
    for (final nature in <RunFolder>[
      CFolder(
        folder,
        buildSystem: NativeBuildSystem.make,
        projectFile: 'Makefile',
      ),
      CppFolder(
        folder,
        buildSystem: NativeBuildSystem.make,
        projectFile: 'Makefile',
      ),
      TypeScriptFolder(folder),
    ]) {
      final r = resolve([nature]);
      expect(r, isA<RunnerUnavailable>());
      expect((r as RunnerUnavailable).reason, contains('TESTKIT_REPORT'));
    }
    expect(resolve(const []), isA<RunnerUnavailable>());
  });

  test('TK-PTR-4: a Dart project runs dart test, even with a test: step', () {
    write('buildkit.yaml', 'test: ./run_tests.sh\n');
    expect(
      resolve([DartProjectFolder(folder, projectName: 'x')]),
      isA<DartRunner>(),
    );
  });

  test('TK-PTR-5: the test: step of buildkit.yaml (one command or a list) is '
      'a script speaking the line protocol', () {
    write('buildkit.yaml', 'test: ./run_tests.sh\n');
    final one = commandRunner([
      CFolder(
        folder,
        buildSystem: NativeBuildSystem.make,
        projectFile: 'Makefile',
      ),
    ]);
    expect(
      (one.command, one.format, one.origin),
      ('./run_tests.sh', ReportFormat.testkit, 'buildkit.yaml test:'),
    );
    write('buildkit.yaml', 'test:\n  - make\n  - ./run_tests.sh\n');
    expect(commandRunner([GoFolder(folder)]).command, 'make && ./run_tests.sh');
  });

  test('TK-PTR-6: a testkit: section wins over everything, Dart included', () {
    write('buildkit.yaml', '''
test: ./run_tests.sh
testkit:
  command: ctest --output-junit build/ctest.xml
  report: junit
  report-path: build/ctest.xml
''');
    final r = commandRunner([DartProjectFolder(folder, projectName: 'x')]);
    expect(r.command, 'ctest --output-junit build/ctest.xml');
    expect(r.format, ReportFormat.junit);
    expect(r.reportPath, 'build/ctest.xml');
    expect(r.origin, 'buildkit.yaml testkit:');
  });

  test('TK-PTR-7: a testkit: section without command, or with an unknown '
      'report, is refused with the reason', () {
    write('buildkit.yaml', 'testkit:\n  report: junit\n');
    expect(
      (resolve(const []) as RunnerUnavailable).reason,
      contains('needs a command'),
    );
    write('buildkit.yaml', 'testkit:\n  command: x\n  report: tap\n');
    expect(
      (resolve(const []) as RunnerUnavailable).reason,
      contains('unknown report "tap"'),
    );
  });

  group('TK-PTR-8: a whole cycle through a test script', () {
    // The script writes one line per step, as the SOM runtimes' scripts do;
    // RESULT_B decides whether step b passes.
    setUp(() {
      write('buildkit.yaml', 'test: sh ./run_tests.sh\n');
      write('run_tests.sh', r'''
tk() { [ -n "${TESTKIT_REPORT:-}" ] && printf '{"test":"%s","result":"%s"}\n' "$1" "$2" >> "$TESTKIT_REPORT"; return 0; }
echo "== a =="; tk "tests/a_test.sh" ok
echo "== b =="; tk "tests/b_test.sh" "${RESULT_B:-ok}"
[ "${RESULT_B:-ok}" = ok ]
''');
    });

    final natures = <RunFolder>[];
    setUp(() {
      natures
        ..clear()
        ..add(
          CFolder(
            folder,
            buildSystem: NativeBuildSystem.make,
            projectFile: 'Makefile',
          ),
        );
    });

    test('TK-PTR-8: :baseline records each step; the report and the output '
        'are kept in testlog/', () async {
      final ok = await BaselineCommand.run(
        projectPath: project.path,
        runner: ProjectTestRunner.resolve(project.path, natures),
      );
      expect(ok, isTrue);
      final tracking = TrackingFile.load(
        findLatestTrackingFile(project.path)!,
      )!;
      expect(tracking.entries.keys.toSet(), {
        'tests/a_test.sh',
        'tests/b_test.sh',
      });
      expect(
        File(
          p.join(project.path, 'testlog', 'last_testrun_report.jsonl'),
        ).readAsLinesSync(),
        hasLength(2),
      );
      expect(
        File(
          p.join(project.path, 'testlog', 'last_testrun.txt'),
        ).readAsStringSync(),
        contains('== b =='),
      );
    });

    test(
      'TK-PTR-9: :test appends a column; a regression shows in the '
      'tracking file, the run fails, and the keys survive the round trip',
      () async {
        final runner = ProjectTestRunner.resolve(project.path, natures);
        expect(
          await BaselineCommand.run(projectPath: project.path, runner: runner),
          isTrue,
        );
        // A failing step: the script's exit code says so as well.
        final failing = CommandRunner(
          command: 'RESULT_B=fail sh ./run_tests.sh',
          format: ReportFormat.testkit,
          origin: 'test',
        );
        expect(
          await TestCommand.run(projectPath: project.path, runner: failing),
          isFalse,
        );
        final file = findLatestTrackingFile(project.path)!;
        final tracking = TrackingFile.load(file)!;
        expect(tracking.runs, hasLength(2));
        expect(tracking.entries, hasLength(2), reason: 'no test duplicated');
        expect(
          tracking.runs.last.getResult('tests/b_test.sh'),
          TestResult.fail,
        );
        expect(tracking.runs.last.getResult('tests/a_test.sh'), TestResult.ok);
      },
    );

    test(
      'TK-PTR-10: --failed with a script runs every test and says so',
      () async {
        final runner = ProjectTestRunner.resolve(project.path, natures);
        await BaselineCommand.run(projectPath: project.path, runner: runner);
        final ok = await TestCommand.run(
          projectPath: project.path,
          runner: runner,
          failedOnly: true,
        );
        expect(ok, isTrue);
        expect(
          TrackingFile.load(findLatestTrackingFile(project.path)!)!.runs,
          hasLength(2),
        );
      },
    );
  });

  test('TK-PTR-11: a script that writes no report records nothing and quotes '
      'its output', () async {
    write('buildkit.yaml', 'test: echo "compiled nothing"; exit 2\n');
    final runner = ProjectTestRunner.resolve(project.path, [GoFolder(folder)]);
    final results = await runner.run(projectPath: project.path);
    expect(results, isNotNull);
    expect(results!.totalTests, 0);
    expect(results.runProblem, contains('No test ran'));
    expect(results.runProblem, contains('compiled nothing'));
    expect(results.runProblem, contains('exited with code 2'));
    expect(
      await BaselineCommand.run(projectPath: project.path, runner: runner),
      isFalse,
    );
    expect(findLatestTrackingFile(project.path), isNull);
  });

  test('TK-PTR-12: a junit report at report-path is read; a report left by '
      'an earlier run is deleted first', () async {
    final fixture = File(
      p.join('test', 'fixtures', 'reports', 'pytest_junit.xml'),
    ).absolute.path;
    write('build/old.xml', '<testsuite><testcase name="stale"/></testsuite>');
    final runner = CommandRunner(
      command: 'mkdir -p build && cp "$fixture" build/run.xml',
      format: ReportFormat.junit,
      reportPath: 'build/*.xml',
      origin: 'test',
    );
    final results = (await runner.run(projectPath: project.path))!;
    expect(results.run.results.keys, isNot(contains('stale')));
    expect(results.totalTests, 5);
    // {report}: the command writes testkit's own report file.
    final viaPlaceholder = CommandRunner(
      command: 'cp "$fixture" {report}',
      format: ReportFormat.junit,
      origin: 'test',
    );
    expect(
      (await viaPlaceholder.run(projectPath: project.path))!.totalTests,
      5,
    );
  });

  test('TK-PTR-13: a relative project path (as a traversal hands it) and a '
      'script that changes directory still meet at the report file', () async {
    write('sub/run.sh', r'''
cd "$(dirname "$0")"
printf '{"test":"t","result":"ok"}\n' >> "$TESTKIT_REPORT"
''');
    final previous = Directory.current;
    Directory.current = project.parent;
    try {
      final relative = p.relative(project.path, from: project.parent.path);
      final runner = CommandRunner(
        command: 'sh sub/run.sh',
        format: ReportFormat.testkit,
        origin: 'test',
      );
      final results = (await runner.run(projectPath: './$relative'))!;
      expect(results.run.results, {'t': TestResult.ok});
    } finally {
      Directory.current = previous;
    }
  });
}
