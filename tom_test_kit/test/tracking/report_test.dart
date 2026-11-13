import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_test_kit/src/v2/testkit_executors.dart';
import 'package:tom_test_kit/src/v2/testkit_tool.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

/// `:report`: one table of the latest results of every project the
/// traversal visits; a project without `testlog/` is not measured.
///
/// Test IDs: TK-REP-1..6.
void main() {
  late Directory root;

  setUp(() {
    root = Directory(
      Directory.systemTemp
          .createTempSync('tk_report_')
          .resolveSymbolicLinksSync(),
    );
  });
  tearDown(() => root.deleteSync(recursive: true));

  /// A Dart package at [name] under the root.
  String package(String name) {
    final dir = p.join(root.path, name);
    File(p.join(dir, 'pubspec.yaml'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('name: ${p.basename(name)}\n');
    return dir;
  }

  /// Three runs over four tests: `a` regresses, `c` flips, `d` is skipped.
  Future<void> track(String dir) async {
    final entries = [
      for (final t in ['a', 'b', 'c', 'd']) TestDescriptionParser.parse(t),
    ];
    TestRun run(DateTime at, List<TestResult> results, {LineCoverage? cov}) =>
        TestRun(
          timestamp: at,
          coverage: cov,
          results: {
            for (var i = 0; i < 4; i++) entries[i].fullDescription: results[i],
          },
        );
    const ok = TestResult.ok, x = TestResult.fail, s = TestResult.skip;
    final tracking = TrackingFile.fromBaseline(
      entries,
      run(DateTime(2026, 11, 10, 9), [ok, ok, x, s]),
    );
    tracking.addRun(run(DateTime(2026, 11, 12, 9), [x, ok, ok, s]), entries);
    tracking.addRun(
      run(DateTime(2026, 11, 13, 21, 50), [
        x,
        ok,
        x,
        s,
      ], cov: const LineCoverage(covered: 30, coverable: 40)),
      entries,
    );
    await tracking.write(p.join(dir, 'testlog', 'baseline_1110_0900.csv'));
  }

  test('TK-REP-1: a project without testlog is not measured, never clean '
      '[2026-11-13]', () {
    final row = ProjectReport.read(package('bare'), project: 'bare');
    expect(row.measured, isFalse);
    expect(row.state, ReportState.notMeasured);
    expect(row.cells, ['bare', 'not measured', '', '', '', '', '', '', '']);
    expect(row.toJson()['passed'], isNull);
  });

  test('TK-REP-2: the latest run\'s counts, regressions against the '
      'baseline, flaky tests and coverage [2026-11-13]', () async {
    final dir = package('tracked');
    await track(dir);
    final row = ProjectReport.read(dir, project: 'tracked');
    expect(row.state, ReportState.regressed);
    expect((row.runs, row.passed, row.failed, row.skipped), (3, 1, 2, 1));
    expect(row.regressions, 1, reason: 'a: OK in the baseline, X now');
    expect(row.flaky, 2, reason: 'a and c passed and failed');
    expect(row.coverage, const LineCoverage(covered: 30, coverable: 40));
    expect(row.trackingFile, p.join('testlog', 'baseline_1110_0900.csv'));
    expect(row.cells[2], matches(RegExp(r'^\d{4}-11-13 21:50$')));
    expect(row.cells.skip(3), ['1', '2', '1', '1', '2', '75.0%']);
  });

  test('TK-REP-3: the table, its summary line, Markdown and JSON '
      '[2026-11-13]', () async {
    final dir = package('tracked');
    await track(dir);
    final report = WorkspaceReport([
      ProjectReport.read(dir, project: 'tracked'),
      const ProjectReport.notMeasured('bare'),
    ]);
    const summary =
        '2 projects: 0 green, 0 failing, 1 regressed, 1 not measured';
    expect(report.summary, summary);

    final plain = report.toPlain().split('\n');
    expect(plain.first, startsWith('Project'));
    expect(plain.where((l) => l.startsWith('tracked ')), hasLength(1));
    expect(
      plain.where((l) => l.startsWith('bare ')).single,
      contains('not measured'),
    );
    expect(plain.last, summary);

    final md = report.toMarkdown();
    expect(md, contains('| Project | State | Last run |'));
    expect(md, contains('| bare | not measured |'));

    final json = jsonDecode(report.toJson()) as Map<String, dynamic>;
    final projects = (json['projects'] as List).cast<Map<String, dynamic>>();
    expect(projects.map((r) => r['state']), ['regressed', 'not measured']);
    expect(projects.first['regressions'], 1);
    expect(projects.last['passed'], isNull);
  });

  test('TK-REP-4: --output takes a .md / .json file or md:/json:, never a '
      'file inside doc/ [2026-11-13]', () async {
    expect(ReportCommand.parseOutput('r.md')!.format, OutputFormat.md);
    expect(ReportCommand.parseOutput('json:r.txt')!.format, OutputFormat.json);
    expect(ReportCommand.parseOutput('r.txt'), isNull);
    expect(ReportCommand.parseOutput('csv:r.csv'), isNull);
    expect(ReportCommand.parseOutput('md'), isNull, reason: 'no file');

    const report = WorkspaceReport([ProjectReport.notMeasured('bare')]);
    final out = StringBuffer();
    final mdFile = p.join(root.path, 'out', 'report.md');
    expect(await ReportCommand.emit(report, output: mdFile, sink: out), isNull);
    expect(
      File(mdFile).readAsStringSync(),
      contains('| bare | not measured |'),
    );

    final jsonFile = p.join(root.path, 'report.json');
    expect(
      await ReportCommand.emit(report, output: jsonFile, sink: out),
      isNull,
    );
    expect(jsonDecode(File(jsonFile).readAsStringSync()), isA<Map>());

    final inDoc = p.join(root.path, 'pkg', 'doc', 'report.md');
    expect(
      await ReportCommand.emit(report, output: inDoc, sink: out),
      contains('doc/'),
    );
    expect(File(inDoc).existsSync(), isFalse);
    expect(
      await ReportCommand.emit(report, output: 'report.txt', sink: out),
      contains('.md or .json'),
    );
  });

  group('the command', () {
    late StringBuffer table;

    Future<ToolResult> run(List<String> args) {
      final executors = createTestkitExecutors()
        ..['report'] = ReportExecutor(output: table = StringBuffer());
      return ToolRunner(
        tool: testkitTool,
        executors: executors,
        output: StringBuffer(),
      ).run(['-R', root.path, '-s', root.path, '-r', ...args]);
    }

    setUp(() {
      File(p.join(root.path, 'buildkit_master.yaml')).writeAsStringSync('');
    });

    test('TK-REP-5: one table over every project, sorted by path, the '
        'untracked one not measured; nothing is written into the projects '
        '[2026-11-13]', () async {
      await track(package('group/b_tracked'));
      // a_bare depends on b_tracked, so the traversal (build order) visits
      // b_tracked first; the table is sorted by path.
      final bare = package('group/a_bare');
      File(p.join(bare, 'pubspec.yaml')).writeAsStringSync(
        'name: a_bare\ndependencies:\n  b_tracked:\n    path: ../b_tracked\n',
      );

      final result = await run([':report']);
      expect(result.success, isTrue);
      final lines = table.toString().split('\n');
      final bareRow = lines.indexWhere((l) => l.contains('a_bare'));
      final trackedRow = lines.indexWhere((l) => l.contains('b_tracked'));
      expect(bareRow, lessThan(trackedRow), reason: 'sorted by path');
      expect(lines[bareRow], contains('not measured'));
      expect(lines[trackedRow], contains('regressed'));
      expect(
        lines,
        contains('2 projects: 0 green, 0 failing, 1 regressed, 1 not measured'),
      );
      expect(Directory(p.join(bare, 'testlog')).existsSync(), isFalse);
    });

    test('TK-REP-6: --output writes the file; a doc/ target fails the run '
        '[2026-11-13]', () async {
      package('only');
      final out = p.join(root.path, 'reports', 'r.json');
      expect((await run([':report', '--output', out])).success, isTrue);
      final json = jsonDecode(File(out).readAsStringSync()) as Map;
      expect((json['projects'] as List).single['state'], 'not measured');

      final doc = p.join(root.path, 'doc', 'r.md');
      final result = await run([':report', '--output', doc]);
      expect(result.success, isFalse);
      expect(File(doc).existsSync(), isFalse);
    });
  });
}
