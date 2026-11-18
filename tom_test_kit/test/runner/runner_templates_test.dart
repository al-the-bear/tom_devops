/// Test-runner templates: testkit's language defaults are named templates;
/// the workspace (`testkit: runners:` in `buildkit_master.yaml`) and a
/// project (`testkit: runners:` in `buildkit.yaml`) add or change templates;
/// a project picks one with `testkit: runner:`; detection tries the
/// project's, the workspace's, then the built-in templates in order; and a
/// template's `filter:` lets `--failed` / `--mismatched` select tests by name.
///
/// Test IDs: TK-RT-1..13.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

void main() {
  late Directory ws;
  late String project;
  late FsFolder folder;

  setUp(() {
    ws = Directory(
      Directory.systemTemp.createTempSync('tk_rt_').resolveSymbolicLinksSync(),
    );
    project = p.join(ws.path, 'pkg');
    Directory(project).createSync();
    folder = FsFolder(path: project);
    File(p.join(ws.path, 'buildkit_master.yaml')).writeAsStringSync('');
  });
  tearDown(() => ws.deleteSync(recursive: true));

  void write(String rel, String text) => File(p.join(ws.path, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);

  CommandRunner runner(List<RunFolder> natures) {
    final r = ProjectTestRunner.resolve(project, natures);
    expect(
      r,
      isA<CommandRunner>(),
      reason: r is RunnerUnavailable ? r.reason : null,
    );
    return r as CommandRunner;
  }

  test('TK-RT-1: every language default is a named built-in template; all '
      'but jasmine, the javac runners and sbt select tests by name '
      '[2026-11-18]', () {
    expect(builtInRunnerTemplates.map((t) => t.name), [
      'npm-test-jest',
      'jest',
      'vitest',
      'mocha',
      'ava',
      'jasmine',
      'node-test',
      'node-tsx',
      'node-ts-node',
      'pytest',
      'pytest-doctest',
      'nose2',
      'tox',
      'nox',
      'unittest',
      'unittest-doctest',
      'junit-console',
      'testng',
      'maven-verify',
      'maven',
      'gradle',
      'sbt2',
      'sbt',
      'go-test',
      'cargo-test',
    ]);
    final filtered = {
      for (final t in builtInRunnerTemplates)
        if (t.filter != null) t.name,
    };
    expect(
      builtInRunnerTemplates.map((t) => t.name).toSet().difference(filtered),
      {'jasmine', 'junit-console', 'testng', 'sbt2', 'sbt'},
    );
    // Every built-in is detected, except the doctest variants a project
    // names.
    expect(
      {
        for (final t in builtInRunnerTemplates)
          if (t.applies == null) t.name,
      },
      {'pytest-doctest', 'unittest-doctest'},
    );
    write('pkg/gradlew', '');
    write('pkg/build.gradle', '');
    final gradle = runner([
      JavaFolder(
        folder,
        buildTool: JavaBuildTool.gradle,
        projectFile: 'build.gradle',
      ),
    ]);
    expect(
      gradle.command,
      './gradlew testkitTests --init-script {script:gradle-testkit}',
    );
    expect(gradle.origin, 'runner gradle, built-in');
    expect(gradle.selectsTestsByName, isTrue);
  });

  test('TK-RT-2: the name filters of the built-ins [2026-11-18]', () {
    List<String> args(String name, List<String> names) => builtInRunnerTemplates
        .firstWhere((t) => t.name == name)
        .filter!
        .argsFor(names);
    expect(args('go-test', ['TestA', 'TestB/sub', 'TestB/other']), [
      '-run',
      r'^(TestA|TestB)$',
    ]);
    expect(args('pytest', ['test_x[1]', 'test_x[2]', 'test_y']), [
      '-k',
      'test_x or test_y',
    ]);
    expect(args('cargo-test', ['a::b', 'c']), ['--', '--exact', 'a::b', 'c']);
    expect(args('jest', ['adds 1+2']), ['-t', r'(adds 1\+2)$']);
    expect(args('node-test', ['a', 'b']), ['--test-name-pattern', r'(a|b)$']);
    expect(args('go-test', []), isEmpty);
  });

  test('TK-RT-3: runner: picks a template by name; the section changes its '
      'fields; an unknown name is refused naming the templates '
      '[2026-11-18]', () {
    write('pkg/buildkit.yaml', 'testkit:\n  runner: pytest\n');
    final picked = runner(const []);
    expect(
      picked.command,
      '${projectPythonCommand(project)} -m pytest -q '
      '--continue-on-collection-errors '
      '--junitxml={report}',
    );
    expect(picked.origin, 'runner pytest, built-in, picked in buildkit.yaml');
    expect(picked.selectsTestsByName, isTrue);

    write(
      'pkg/buildkit.yaml',
      'testkit:\n  runner: pytest\n'
          '  command: uv run pytest -q --junitxml={report}\n',
    );
    final changed = runner(const []);
    expect(changed.command, 'uv run pytest -q --junitxml={report}');
    expect(changed.format, ReportFormat.junit, reason: 'kept from pytest');
    expect(changed.filter, isNotNull, reason: 'kept from pytest');

    write('pkg/buildkit.yaml', 'testkit:\n  runner: nope\n');
    final refused = ProjectTestRunner.resolve(project, const []);
    expect(refused, isA<RunnerUnavailable>());
    expect(
      (refused as RunnerUnavailable).reason,
      allOf(contains('unknown runner "nope"'), contains('pytest')),
    );
  });

  test('TK-RT-4: the workspace adds a template (detected before the '
      'built-ins) and changes a built-in in its place [2026-11-18]', () {
    write('buildkit_master.yaml', '''
testkit:
  runners:
    pytest-uv:
      command: uv run pytest -q --junitxml={report}
      report: junit
      applies: {nature: python, files: [uv.lock]}
    go-test:
      command: gotestsum --jsonfile {report}
''');
    final python = [PythonFolder(folder, projectFile: 'pyproject.toml')];
    expect(runner(python).origin, 'runner unittest, built-in');
    write('pkg/uv.lock', '');
    final uv = runner(python);
    expect(uv.origin, 'runner pytest-uv, buildkit_master.yaml');
    expect(uv.selectsTestsByName, isFalse, reason: 'it declares no filter');

    final go = runner([GoFolder(folder, modulePath: 'example.com/a')]);
    expect(go.command, 'gotestsum --jsonfile {report}');
    expect(go.origin, 'runner go-test, buildkit_master.yaml');
    expect(go.format, ReportFormat.goJson, reason: 'kept from the built-in');
  });

  test('TK-RT-5: a project\'s own templates come first and change the '
      'workspace\'s; runners: alone names no runner [2026-11-18]', () {
    write('buildkit_master.yaml', '''
testkit:
  runners:
    ctest:
      command: ctest --test-dir build --output-junit {report}
      report: junit
      applies: {nature: [c, cpp], contains: {CMakeLists.txt: enable_testing}}
''');
    final c = [
      CFolder(
        folder,
        buildSystem: NativeBuildSystem.cmake,
        projectFile: 'CMakeLists.txt',
      ),
    ];
    write('pkg/CMakeLists.txt', 'project(x)\n');
    expect(
      ProjectTestRunner.resolve(project, c),
      isA<RunnerUnavailable>(),
      reason: 'no enable_testing',
    );
    write('pkg/CMakeLists.txt', 'project(x)\nenable_testing()\n');
    expect(runner(c).origin, 'runner ctest, buildkit_master.yaml');

    write('pkg/buildkit.yaml', '''
testkit:
  runners:
    ctest:
      command: ctest --test-dir out --output-junit {report}
''');
    final own = runner(c);
    expect(own.command, 'ctest --test-dir out --output-junit {report}');
    expect(own.origin, 'runner ctest, buildkit.yaml');
    expect(own.format, ReportFormat.junit, reason: 'kept from the workspace');
  });

  test('TK-RT-6: a dependency in package.json, and the TypeScript without '
      'jest message [2026-11-18]', () {
    write('buildkit_master.yaml', '''
testkit:
  runners:
    vitest:
      command: npx vitest run --reporter=junit --outputFile={report}
      report: junit
      filter: {args: [-t, "({names})"]}
      applies: {nature: [typescript, javascript], dependency: vitest}
''');
    final ts = [TypeScriptFolder(folder)];
    final none = ProjectTestRunner.resolve(project, ts);
    expect((none as RunnerUnavailable).reason, contains('without jest'));
    write('pkg/package.json', '{"devDependencies": {"vitest": "^2.0.0"}}');
    final vitest = runner(ts);
    expect(vitest.origin, 'runner vitest, buildkit_master.yaml');
    expect(vitest.selectArgs(['a.b']), ['-t', r'(a\.b)']);
  });

  test('TK-RT-7: a template that is not well-formed is refused with the '
      'reason [2026-11-18]', () {
    for (final (yaml, reason) in [
      ('x: {command: y, applies: {nature: cobol}}', 'unknown nature cobol'),
      ('x: {command: y, filter: {args: [-k]}}', 'must hold {names}'),
      ('x: {report: junit}', 'needs a command'),
      ('x: {command: y, report: xunit}', 'unknown report "xunit"'),
      ('x: {command: y, applies: {}}', 'applies: needs'),
    ]) {
      write('pkg/buildkit.yaml', 'testkit:\n  runners:\n    $yaml\n');
      final r = ProjectTestRunner.resolve(project, const []);
      expect(r, isA<RunnerUnavailable>(), reason: yaml);
      expect(
        (r as RunnerUnavailable).reason,
        allOf(contains('runner x (buildkit.yaml)'), contains(reason)),
      );
    }
  });

  group('TK-RT-8: --failed selects by name through a template', () {
    setUp(() {
      // A template from the workspace whose command is a script: it records
      // the arguments it was given, then reports t1 in two suites (so the
      // tracking file qualifies them) and t2; RESULT decides pkg_b's t1.
      write('buildkit_master.yaml', r'''
testkit:
  runners:
    script:
      command: sh ./run_tests.sh
      filter: {args: [--only, "{name}"], regex: false}
      applies: {nature: c}
''');
      write('pkg/run_tests.sh', r'''
: > args.txt; for a in "$@"; do printf '%s\n' "$a" >> args.txt; done
tk() { printf '{"test":"%s","suite":"%s","result":"%s"}\n' "$1" "$2" "$3" >> "$TESTKIT_REPORT"; }
tk t1 pkg_a ok
tk t1 pkg_b "${RESULT:-ok}"
tk t2 pkg_a ok
''');
    });

    final natures = <RunFolder>[];
    setUp(
      () => natures
        ..clear()
        ..add(
          CFolder(
            folder,
            buildSystem: NativeBuildSystem.make,
            projectFile: 'Makefile',
          ),
        ),
    );

    String args() => File(p.join(project, 'args.txt')).readAsStringSync();

    test('TK-RT-8: the failed test is selected by its name, without the '
        'suite the tracking file put before it [2026-11-18]', () async {
      final r = runner(natures);
      expect(r.origin, 'runner script, buildkit_master.yaml');
      final failing = CommandRunner(
        command: 'RESULT=fail sh ./run_tests.sh',
        format: ReportFormat.testkit,
        filter: r.filter,
        origin: 'test',
      );
      // A baseline with a failing test records it and reports the failure.
      await BaselineCommand.run(projectPath: project, runner: failing);
      final keys = TrackingFile.load(
        findLatestTrackingFile(project)!,
      )!.entries.keys.toSet();
      expect(keys, {'pkg_a > t1', 'pkg_b > t1', 't2'});

      await TestCommand.run(projectPath: project, runner: r, failedOnly: true);
      expect(args(), '--only\nt1\n');
    });

    test('TK-RT-9: without a failed test nothing runs; a template without a '
        'filter runs every test [2026-11-18]', () async {
      final r = runner(natures);
      await BaselineCommand.run(projectPath: project, runner: r);
      File(p.join(project, 'args.txt')).deleteSync();
      expect(
        await TestCommand.run(
          projectPath: project,
          runner: r,
          failedOnly: true,
        ),
        isTrue,
      );
      expect(File(p.join(project, 'args.txt')).existsSync(), isFalse);

      final unfiltered = CommandRunner(
        command: 'RESULT=fail sh ./run_tests.sh',
        format: ReportFormat.testkit,
        origin: 'test',
      );
      await TestCommand.run(projectPath: project, runner: unfiltered);
      await TestCommand.run(
        projectPath: project,
        runner: unfiltered,
        failedOnly: true,
      );
      expect(args(), '', reason: 'every test runs, no arguments');
    });
  });

  test('TK-RT-10: a template naming report: tap records per-test results, '
      'from the output or from the report file [2026-11-18]', () async {
    final bats = File(
      p.join('test', 'fixtures', 'reports', 'bats_tap.txt'),
    ).absolute.path;
    write('buildkit_master.yaml', '''
testkit:
  runners:
    bats:
      command: cat "$bats"
      report: tap
      filter: {args: [--filter, "^({names})\$"]}
      applies: {nature: c, files: [test/*.bats]}
    bats-file:
      command: cp "$bats" {report}
      report: tap
''');
    write('pkg/test/math.bats', '');
    final natures = [
      CFolder(
        folder,
        buildSystem: NativeBuildSystem.make,
        projectFile: 'Makefile',
      ),
    ];
    final fromOutput = runner(natures);
    expect(fromOutput.origin, 'runner bats, buildkit_master.yaml');
    expect(fromOutput.format, ReportFormat.tap);
    final expected = {
      'addition works': TestResult.ok,
      'subtraction is wrong': TestResult.fail,
      'not ready yet': TestResult.skip,
      'plain skip': TestResult.skip,
    };
    expect((await fromOutput.run(projectPath: project))!.run.results, expected);

    write('pkg/buildkit.yaml', 'testkit:\n  runner: bats-file\n');
    final fromFile = runner(natures);
    final results = (await fromFile.run(projectPath: project))!;
    expect(results.run.results, expected);
    expect(
      File(p.join(project, 'testlog', 'last_testrun_report.tap')).existsSync(),
      isTrue,
    );
  });

  group('the JavaScript / TypeScript runners', () {
    final js = <RunFolder>[];
    final ts = <RunFolder>[];
    setUp(() {
      js
        ..clear()
        ..add(JavaScriptFolder(folder));
      ts
        ..clear()
        ..add(TypeScriptFolder(folder));
    });

    void packageJson(Map<String, String> devDependencies, {String? test}) =>
        write(
          'pkg/package.json',
          jsonEncode({
            'name': 'p',
            if (test != null) 'scripts': {'test': test},
            'devDependencies': devDependencies,
          }),
        );

    test('TK-RT-11: each runner is picked from package.json [2026-11-18]', () {
      for (final (deps, testScript, natures, expected) in [
        ({'jest': '*'}, 'jest --ci', js, 'npm-test-jest'),
        ({'jest': '*', 'ts-jest': '*'}, 'npx jest', ts, 'npm-test-jest'),
        ({'jest': '*', 'ts-jest': '*'}, 'tsc && node x.js', ts, 'jest'),
        ({'jest': '*'}, null, js, 'jest'),
        ({'vitest': '*'}, 'vitest', ts, 'vitest'),
        ({'mocha': '*'}, 'mocha', js, 'mocha'),
        ({'ava': '*'}, 'ava', js, 'ava'),
        ({'jasmine': '*', 'jasmine-reporters': '*'}, 'jasmine', js, 'jasmine'),
        ({'tsx': '*', 'typescript': '*'}, null, ts, 'node-tsx'),
        ({'ts-node': '*', 'typescript': '*'}, null, ts, 'node-ts-node'),
        (<String, String>{}, null, js, 'node-test'),
      ]) {
        packageJson(deps, test: testScript);
        expect(
          runner(natures).origin,
          'runner $expected, built-in',
          reason: '$deps, test: $testScript',
        );
      }
      // jasmine without jasmine-reporters writes no report testkit reads.
      packageJson({'jasmine': '*'});
      expect(runner(js).origin, 'runner node-test, built-in');
      packageJson({'typescript': '*'});
      expect(ProjectTestRunner.resolve(project, ts), isA<RunnerUnavailable>());
    });

    test('TK-RT-12: each runner records per-test results from its recorded '
        'report [2026-11-18]', () async {
      String fixture(String name) =>
          File(p.join('test', 'fixtures', 'reports', 'js', name)).absolute.path;
      // The template's own format and report place; its command replaced by
      // one that puts the recorded report where the runner writes it.
      for (final (template, report, copyTo, expected) in [
        (
          'npm-test-jest',
          'npm_jest.json',
          '{report}',
          {
            'adds': TestResult.ok,
            'subtracts wrongly': TestResult.fail,
            'skipped one': TestResult.skip,
            'multiplies': TestResult.ok,
          },
        ),
        (
          'jest',
          'ts_jest.json',
          '{report}',
          {
            'adds': TestResult.ok,
            'subtracts wrongly': TestResult.fail,
            'skipped one': TestResult.skip,
            'multiplies': TestResult.ok,
          },
        ),
        (
          'vitest',
          'vitest_junit.xml',
          '{report}',
          {
            'math > adds': TestResult.ok,
            'math > subtracts wrongly': TestResult.fail,
            'math > skipped one': TestResult.skip,
            'math > nested > multiplies': TestResult.ok,
          },
        ),
        (
          'mocha',
          'mocha.json',
          '{report}',
          {
            'adds': TestResult.ok,
            'subtracts wrongly': TestResult.fail,
            'skipped one': TestResult.skip,
            'multiplies': TestResult.ok,
          },
        ),
        (
          'ava',
          'ava_tap.txt',
          null,
          {
            'skipped one': TestResult.skip,
            'later': TestResult.skip,
            'math adds': TestResult.ok,
            'math subtracts wrongly': TestResult.fail,
          },
        ),
        (
          'jasmine',
          'jasmine_junit.xml',
          'junitresults.xml',
          {
            'adds': TestResult.ok,
            'subtracts wrongly': TestResult.fail,
            'skipped one': TestResult.skip,
            'multiplies': TestResult.ok,
          },
        ),
        (
          'node-tsx',
          'tsx_junit.xml',
          '{report}',
          {
            'adds': TestResult.ok,
            'subtracts wrongly': TestResult.fail,
            'skipped one': TestResult.skip,
            'multiplies': TestResult.ok,
          },
        ),
        (
          'node-ts-node',
          'tsnode_junit.xml',
          '{report}',
          {
            'adds': TestResult.ok,
            'subtracts wrongly': TestResult.fail,
            'skipped one': TestResult.skip,
            'multiplies': TestResult.ok,
          },
        ),
      ]) {
        final t = builtInRunnerTemplates.firstWhere((t) => t.name == template);
        final runner = CommandRunner(
          command: copyTo == null
              ? 'cat "${fixture(report)}"'
              : 'cp "${fixture(report)}" $copyTo',
          format: t.format,
          reportPath: t.reportPath,
          origin: 'test',
        );
        final results = (await runner.run(projectPath: project))!;
        expect(results.run.results, expected, reason: template);
      }
    });

    test('TK-RT-13: the name filters of the JavaScript runners '
        '[2026-11-18]', () {
      List<String> args(String name, List<String> names) =>
          builtInRunnerTemplates
              .firstWhere((t) => t.name == name)
              .filter!
              .argsFor(names);
      expect(args('vitest', ['math > adds', 'math > nested > multiplies']), [
        '-t',
        r'(adds|multiplies)$',
      ]);
      expect(args('mocha', ['adds']), ['--grep', r'(adds)$']);
      expect(args('ava', ['math adds', 'later']), [
        '--match',
        'math adds',
        '--match',
        'later',
      ]);
      expect(args('npm-test-jest', ['adds']), ['-t', r'(adds)$']);
      expect(args('node-tsx', ['adds']), ['--test-name-pattern', r'(adds)$']);
    });
  });
}
