/// Test-runner templates: testkit's language defaults are named templates;
/// the workspace (`testkit: runners:` in `buildkit_master.yaml`) and a
/// project (`testkit: runners:` in `buildkit.yaml`) add or change templates;
/// a project picks one with `testkit: runner:`; detection tries the
/// project's, the workspace's, then the built-in templates in order; and a
/// template's `filter:` lets `--failed` / `--mismatched` select tests by name.
///
/// Test IDs: TK-RT-1..9.
library;

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

  test('TK-RT-1: every language default is a named built-in template; '
      'go, cargo, pytest, jest and node --test select tests by name, Maven '
      'and Gradle do not [2026-11-18]', () {
    expect(builtInRunnerTemplates.map((t) => t.name), [
      'jest',
      'node-test',
      'pytest',
      'maven',
      'gradle-wrapper',
      'gradle',
      'go-test',
      'cargo-test',
    ]);
    final filtered = {
      for (final t in builtInRunnerTemplates)
        if (t.filter != null) t.name,
    };
    expect(filtered, {'jest', 'node-test', 'pytest', 'go-test', 'cargo-test'});
    expect(builtInRunnerTemplates.every((t) => t.applies != null), isTrue);
    write('pkg/gradlew', '');
    final gradle = runner([
      JavaFolder(
        folder,
        buildTool: JavaBuildTool.gradle,
        projectFile: 'build.gradle',
      ),
    ]);
    expect(gradle.command, './gradlew test');
    expect(gradle.origin, 'runner gradle-wrapper, built-in');
    expect(gradle.selectsTestsByName, isFalse);
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
    expect(picked.command, 'python3 -m pytest -q --junitxml={report}');
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
    expect(runner(python).origin, 'runner pytest, built-in');
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
      ('x: {command: y, report: tap}', 'unknown report "tap"'),
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
}
