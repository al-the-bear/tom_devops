/// The Go and Rust runner templates: ginkgo and gotestsum beside `go test`,
/// cargo-nextest and libtest's JSON (nightly) beside `cargo test`, the
/// `{go-tool:<name>}` and `{cargo-workspace}` placeholders, and the cargo
/// readers' grouping in a Cargo workspace.
///
/// TK-GR-3 reads the reports gotestsum 1.13 and ginkgo 2.34 (Go 1.26), cargo
/// 1.96 (`cargo test --workspace`, its text and libtest's JSON) and
/// cargo-nextest 0.9 (JUnit and `--message-format libtest-json`) wrote for
/// small projects (`test/fixtures/reports/gorust/`, paths removed).
///
/// Test IDs: TK-GR-1..6.
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

void main() {
  late Directory root;
  late String project;
  late FsFolder folder;

  setUp(() {
    root = Directory(
      Directory.systemTemp.createTempSync('tk_gr_').resolveSymbolicLinksSync(),
    );
    project = p.join(root.path, 'pkg');
    Directory(project).createSync();
    folder = FsFolder(path: project);
  });
  tearDown(() => root.deleteSync(recursive: true));

  void write(String rel, String text) => File(p.join(project, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);

  void delete(String rel) => File(p.join(project, rel)).deleteSync();

  String fixture(String name) =>
      File(p.join('test', 'fixtures', 'reports', 'gorust', name)).absolute.path;

  RunnerTemplate template(String name) =>
      builtInRunnerTemplates.firstWhere((t) => t.name == name);

  CommandRunner runner(List<RunFolder> natures) {
    final r = ProjectTestRunner.resolve(project, natures);
    expect(
      r,
      isA<CommandRunner>(),
      reason: r is RunnerUnavailable ? r.reason : null,
    );
    return r as CommandRunner;
  }

  List<RunFolder> go() => [GoFolder(folder, modulePath: 'example.com/pkg')];
  List<RunFolder> rust() => [RustFolder(folder)];

  test('TK-GR-1: ginkgo, gotestsum, cargo-nextest and cargo-test-json are '
      'picked from the project\'s files [2026-11-18]', () {
    write('go.mod', 'module example.com/pkg\n\ngo 1.24\n');
    expect(runner(go()).origin, 'runner go-test, built-in');
    // A gotestsum that is only required (indirectly) is no tool.
    write(
      'go.mod',
      'module example.com/pkg\n\nrequire gotest.tools/gotestsum v1.13.0 '
          '// indirect\n',
    );
    expect(runner(go()).origin, 'runner go-test, built-in');
    for (final goMod in [
      'module example.com/pkg\n\ntool gotest.tools/gotestsum\n',
      'module example.com/pkg\n\ntool (\n\tgotest.tools/gotestsum\n)\n',
    ]) {
      write('go.mod', goMod);
      expect(runner(go()).origin, 'runner gotestsum, built-in', reason: goMod);
    }
    write('go.mod', 'module example.com/pkg\n');
    write('Makefile', 'test:\n\tgotestsum --junitfile out.xml ./...\n');
    expect(runner(go()).origin, 'runner gotestsum, built-in');
    write(
      'go.mod',
      'module example.com/pkg\n\nrequire github.com/onsi/ginkgo/v2 v2.34.0\n',
    );
    expect(runner(go()).origin, 'runner ginkgo, built-in');

    write('Cargo.toml', '[package]\nname = "pkg"\n');
    expect(runner(rust()).origin, 'runner cargo-test, built-in');
    write('rust-toolchain.toml', '[toolchain]\nchannel = "stable"\n');
    expect(runner(rust()).origin, 'runner cargo-test, built-in');
    write(
      'rust-toolchain.toml',
      '[toolchain]\nchannel = "nightly-2026-11-01"\n',
    );
    expect(runner(rust()).origin, 'runner cargo-test-json, built-in');
    delete('rust-toolchain.toml');
    write('rust-toolchain', 'nightly\n');
    expect(runner(rust()).origin, 'runner cargo-test-json, built-in');
    write('.config/nextest.toml', '[profile.default]\nretries = 0\n');
    expect(runner(rust()).origin, 'runner cargo-nextest, built-in');
  });

  test('TK-GR-2: {go-tool:<name>} is the module\'s tool, else the PATH\'s; '
      '{cargo-workspace} is --workspace for a workspace [2026-11-18]', () {
    expect(projectGoToolCommand(project, 'gotestsum'), 'gotestsum');
    write('go.mod', 'module example.com/pkg\n\ntool gotest.tools/gotestsum\n');
    expect(projectGoToolCommand(project, 'gotestsum'), 'go tool gotestsum');
    expect(projectGoToolCommand(project, 'ginkgo'), 'ginkgo');
    write(
      'go.mod',
      'module example.com/pkg\n\ntool (\n'
          '\tgithub.com/onsi/ginkgo/v2/ginkgo // the CLI\n'
          '\tgotest.tools/gotestsum\n)\n'
          'require github.com/onsi/ginkgo/v2 v2.34.0\n',
    );
    expect(projectGoToolCommand(project, 'ginkgo'), 'go tool ginkgo');
    expect(
      runner(go()).command,
      'go tool ginkgo -r --keep-going --junit-report={report}',
    );

    write('Cargo.toml', '[package]\nname = "pkg"\n');
    expect(projectCargoWorkspaceFlag(project), '');
    expect(runner(rust()).command, 'cargo test --no-fail-fast');
    write(
      'Cargo.toml',
      '[package]\nname = "pkg"\n\n[workspace] # all of them\n'
          'members = ["alpha", "beta"]\n',
    );
    expect(projectCargoWorkspaceFlag(project), '--workspace');
    expect(runner(rust()).command, 'cargo test --workspace --no-fail-fast');
    // A `[workspace.<key>]` table declares the workspace too; a member's
    // `version.workspace = true` does not.
    write('Cargo.toml', '[workspace.package]\nversion = "1.0.0"\n');
    expect(projectCargoWorkspaceFlag(project), '--workspace');
    write(
      'Cargo.toml',
      '[package]\nname = "alpha"\nversion.workspace = true\n',
    );
    expect(projectCargoWorkspaceFlag(project), '');
  });

  test('TK-GR-3: gotestsum, ginkgo, cargo-nextest, cargo test and libtest\'s '
      'JSON record per-test results from their recorded reports; a Cargo '
      'workspace\'s binaries stay apart [2026-11-18]', () async {
    Future<Map<String, TestResult>> recorded(
      String name,
      String file, {
      String? into,
    }) async {
      final t = template(name);
      final command = t.format.isFile
          ? (into == null
                ? 'cp "${fixture(file)}" {report}'
                : 'mkdir -p ${p.dirname(into)} && cp "${fixture(file)}" $into')
          : 'cat "${fixture(file)}"';
      final results = (await CommandRunner(
        command: command,
        format: t.format,
        reportPath: t.reportPath,
        origin: 'test',
      ).run(projectPath: project))!;
      return results.run.results;
    }

    expect(await recorded('gotestsum', 'gotestsum_junit.xml'), {
      'example.com/gop/calc > TestAdd': TestResult.ok,
      'example.com/gop/strs > TestAdd': TestResult.ok,
      'TestSubtractWrongly': TestResult.fail,
      'TestTable': TestResult.fail,
      'TestTable/small': TestResult.ok,
      'TestTable/wrong': TestResult.fail,
      'TestLater': TestResult.skip,
      // A package that does not build.
      'TestMain': TestResult.fail,
    });
    expect(await recorded('ginkgo', 'ginkgo_junit.xml'), {
      '[It] Book with pages counts them': TestResult.ok,
      '[It] Book with pages fails on purpose': TestResult.fail,
      '[It] Book is not ready': TestResult.skip,
      '[It] Book is pending': TestResult.skip,
    });
    // nextest's JUnit leaves ignored tests out.
    expect(
      await recorded(
        'cargo-nextest',
        'nextest_junit.xml',
        into: 'target/nextest/testkit/junit.xml',
      ),
      {
        'alpha > tests::adds': TestResult.ok,
        'beta > tests::adds': TestResult.ok,
        'tests::subtracts_wrongly': TestResult.fail,
        'api_adds': TestResult.ok,
        'tests::root_is_one': TestResult.ok,
      },
    );
    const cargo = {
      'unittests src/lib.rs (alpha) > tests::adds': TestResult.ok,
      'unittests src/lib.rs (beta) > tests::adds': TestResult.ok,
      'tests::subtracts_wrongly': TestResult.fail,
      'tests::later': TestResult.skip,
      'api_adds': TestResult.ok,
      'tests::root_is_one': TestResult.ok,
      'alpha/src/lib.rs - add (line 3)': TestResult.ok,
    };
    expect(await recorded('cargo-test', 'cargo_test_workspace.txt'), cargo);
    expect(await recorded('cargo-test-json', 'cargo_test_json.txt'), cargo);
    expect(await recorded('cargo-test-json', 'nextest_libtest_json.txt'), {
      'alpha::alpha > tests::adds': TestResult.ok,
      'beta::beta > tests::adds': TestResult.ok,
      'tests::subtracts_wrongly': TestResult.fail,
      'tests::later': TestResult.skip,
      'api_adds': TestResult.ok,
      'tests::root_is_one': TestResult.ok,
    });
  });

  test('TK-GR-4: a single crate keeps the groups cargo prints '
      '[2026-11-18]', () {
    final collector = ResultCollector();
    parseLibtestOutput([
      '     Running unittests src/lib.rs (target/debug/deps/one-0123456789abcdef)',
      'test tests::adds ... ok',
      '     Running tests/api.rs (target\\debug\\deps\\api-0123456789abcdef.exe)',
      'test tests::adds ... FAILED',
    ], collector);
    final run = collector
        .build(rawOutput: const [], rawOutputName: 'x', exitCode: 1)
        .run;
    expect(run.results, {
      'unittests src/lib.rs > tests::adds': TestResult.ok,
      'tests/api.rs > tests::adds': TestResult.fail,
    });
  });

  test('TK-GR-5: the name filters: go test / gotestsum -run, cargo test and '
      'nextest --exact, the nightly template after its own -- '
      '[2026-11-18]', () {
    List<String> args(String name, List<String> names) =>
        template(name).filter!.argsFor(names);
    for (final go in ['go-test', 'gotestsum']) {
      expect(args(go, ['TestA', 'TestTable/wrong', 'TestTable/small']), [
        '-run',
        r'^(TestA|TestTable)$',
      ], reason: go);
    }
    for (final cargo in ['cargo-test', 'cargo-nextest']) {
      expect(args(cargo, ['tests::adds', 'api_adds']), [
        '--',
        '--exact',
        'tests::adds',
        'api_adds',
      ], reason: cargo);
    }
    expect(template('cargo-test-json').command, endsWith('--format json'));
    expect(args('cargo-test-json', ['tests::adds']), [
      '--exact',
      'tests::adds',
    ]);
    expect(template('ginkgo').filter, isNull);

    // Build tags and -race: the project changes go-test's command; its
    // report and filter stay.
    write('go.mod', 'module example.com/pkg\n');
    write(
      'buildkit.yaml',
      'testkit:\n  runner: go-test\n'
          '  command: go test -json -race -tags integration ./...\n',
    );
    final tagged = runner(go());
    expect(tagged.command, 'go test -json -race -tags integration ./...');
    expect(tagged.format, ReportFormat.goJson);
    expect(tagged.selectArgs(['TestA']), ['-run', r'^(TestA)$']);
  });

  test('TK-GR-6: the cargo-nextest template writes its bundled tool config '
      '[2026-11-18]', () async {
    final t = template('cargo-nextest');
    expect(
      t.command,
      'cargo nextest run {cargo-workspace} --no-fail-fast '
      '--tool-config-file testkit:{script:nextest-testkit} --profile testkit',
    );
    await CommandRunner(
      command: t.command
          .replaceAll('cargo nextest run {cargo-workspace}', 'echo')
          .replaceAll('testkit:', ''),
      format: t.format,
      reportPath: t.reportPath,
      origin: 'test',
    ).run(projectPath: project);
    final config = File(
      p.join(project, 'testlog', 'testkit_nextest-testkit.toml'),
    );
    expect(
      config.readAsStringSync(),
      allOf(contains('[profile.testkit.junit]'), contains('junit.xml')),
    );
  });
}
