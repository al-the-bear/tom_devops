/// The report readers of the non-Dart runners, on real and representative
/// reports in `test/fixtures/reports/`.
///
/// `go_test.jsonl`, `cargo_test.txt`, `node_junit.xml`, `node_test_tap.txt`
/// (node 22 `--test-reporter=tap`), `bats_tap.txt` and `bats_tap13.txt` (bats
/// 1.13 `--tap` and `--formatter tap13`) are real outputs (paths replaced);
/// `pytest_junit.xml`, `surefire/` and `jest.json` follow those tools'
/// formats.
///
/// Test IDs: TK-RPT-1..13.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

String _fixture(String name) =>
    File(p.join('test', 'fixtures', 'reports', name)).readAsStringSync();

List<String> _lines(String name) =>
    File(p.join('test', 'fixtures', 'reports', name)).readAsLinesSync();

TestRunResults _build(ResultCollector c) =>
    c.build(rawOutput: const [], rawOutputName: 'x', exitCode: 1);

Map<String, TestResult> _byName(TestRunResults r) => r.run.results;

void main() {
  test('TK-RPT-1: go test -json: every test and subtest, grouped by package; '
      'a package whose build failed is a load failure with the compiler '
      'output', () {
    final c = ResultCollector();
    parseGoTestJson(_lines('go_test.jsonl'), c);
    final r = _build(c);
    final results = _byName(r);
    // TestPass exists in two packages: each is qualified by its package.
    expect(results['example.com/tkgo > TestPass'], TestResult.ok);
    expect(results['example.com/tkgo/sub > TestPass'], TestResult.ok);
    expect(results['TestFail'], TestResult.fail);
    expect(results['TestSkip'], TestResult.skip);
    expect(results['TestTable/empty'], TestResult.ok);
    expect(results['TestTable/full'], TestResult.ok);
    expect(results['TestTable'], TestResult.ok);
    expect((r.passedTests, r.failedTests, r.skippedTests), (5, 1, 1));
    expect(r.loadFailures, hasLength(1));
    expect(r.loadFailures.single.suitePath, 'example.com/tkgo/broken');
    expect(
      r.loadFailures.single.message,
      contains('undefined: undefinedThing'),
    );
    expect(r.runProblem, contains('failed to load'));
    final entry = r.entries.firstWhere((e) => e.fullDescription == 'TestFail');
    expect(entry.groups, 'example.com/tkgo');
  });

  test('TK-RPT-2: cargo test (libtest text): unit, integration and doc tests, '
      'grouped by the test binary; ignored is skipped', () {
    final c = ResultCollector();
    parseLibtestOutput(_lines('cargo_test.txt'), c);
    final r = _build(c);
    final results = _byName(r);
    expect(results['tests::passes'], TestResult.ok);
    expect(results['tests::fails'], TestResult.fail);
    expect(results['tests::later'], TestResult.skip);
    expect(results['passes'], TestResult.ok);
    expect(results['src/lib.rs - inc (line 3)'], TestResult.ok);
    expect(r.totalTests, 5);
    final unit = r.entries.firstWhere(
      (e) => e.fullDescription == 'tests::passes',
    );
    expect(unit.groups, 'unittests src/lib.rs');
    expect(unit.id, isNull, reason: '`tests::` is a path, not an ID');
    expect(
      r.entries.firstWhere((e) => e.fullDescription == 'passes').groups,
      'tests/api.rs',
    );
  });

  test('TK-RPT-3: pytest JUnit XML: grouped by classname; failure and error '
      'fail, skipped skips', () {
    final c = ResultCollector();
    parseJunitXml(_fixture('pytest_junit.xml'), c);
    final r = _build(c);
    final results = _byName(r);
    expect(results['test_empty'], TestResult.ok);
    expect(results['test_nested[deep]'], TestResult.ok);
    expect(results['test_broken'], TestResult.fail);
    expect(results['test_later'], TestResult.skip);
    expect(results['test_fixture'], TestResult.fail);
    expect(
      r.entries.firstWhere((e) => e.fullDescription == 'test_empty').groups,
      'tests.test_parser',
    );
  });

  test('TK-RPT-4: surefire XML, one file per class: the same method name in '
      'two classes stays two tests', () {
    final c = ResultCollector();
    for (final name in [
      'surefire/TEST-com.example.ParserTest.xml',
      'surefire/TEST-com.example.WriterTest.xml',
    ]) {
      parseJunitXml(_fixture(name), c);
    }
    final results = _byName(_build(c));
    expect(results['com.example.ParserTest > parsesEmpty'], TestResult.ok);
    expect(results['com.example.WriterTest > parsesEmpty'], TestResult.ok);
    expect(results['parsesNested'], TestResult.fail);
    expect(results['parsesLater'], TestResult.skip);
  });

  test('TK-RPT-5: node --test JUnit: the constant classname "test" is no '
      'group; a describe block is', () {
    final c = ResultCollector();
    parseJunitXml(_fixture('node_junit.xml'), c);
    final r = _build(c);
    final results = _byName(r);
    expect(results['adds'], TestResult.ok);
    expect(results['fails'], TestResult.fail);
    expect(results['later'], TestResult.skip);
    expect(results['parses empty'], TestResult.ok);
    expect(
      r.entries.firstWhere((e) => e.fullDescription == 'adds').groups,
      isNull,
    );
    expect(
      r.entries.firstWhere((e) => e.fullDescription == 'parses empty').groups,
      'parser',
    );
  });

  test('TK-RPT-6: a report that is not XML is a FormatException', () {
    expect(
      () => parseJunitXml('not <xml', ResultCollector()),
      throwsFormatException,
    );
  });

  test('TK-RPT-7: jest --json: assertions grouped by describe blocks; a file '
      'that failed to run is a load failure', () {
    final c = ResultCollector();
    parseJestJson(_fixture('jest.json'), c);
    final r = _build(c);
    final results = _byName(r);
    expect(results['parser > parses empty'], TestResult.ok);
    expect(results['writer > parses empty'], TestResult.ok);
    expect(results['parses deep'], TestResult.fail);
    expect(results['later'], TestResult.skip);
    expect(r.loadFailures.single.suitePath, '/project/tests/broken.test.js');
    expect(r.loadFailures.single.message, contains('SyntaxError'));
    expect(
      () => parseJestJson('{"x": 1}', ResultCollector()),
      throwsFormatException,
    );
  });

  test('TK-RPT-8: testkit line protocol: ok / pass, fail, skip; lines that '
      'are not a result are skipped; an ID in the name is read', () {
    final c = ResultCollector();
    parseTestkitLines(_lines('testkit_report.jsonl'), c);
    final r = _build(c);
    final results = _byName(r);
    expect(results, {
      'conformance harness': TestResult.ok,
      'tests/foo_test.py': TestResult.fail,
      'sample: a_typed_access': TestResult.skip,
      'TK-SCR-1: with an ID': TestResult.ok,
    });
    final withId = r.entries.firstWhere((e) => e.id == 'TK-SCR-1');
    expect(withId.description, 'with an ID');
    expect(withId.groups, 'tests/bar_test.py', reason: 'suite as group');
    expect(
      r.entries
          .firstWhere((e) => e.fullDescription.startsWith('sample'))
          .groups,
      'samples',
    );
  });

  test('TK-RPT-9: ReportFormat names', () {
    expect(ReportFormat.values.map((f) => f.configName), [
      'testkit',
      'go-json',
      'libtest',
      'junit',
      'jest-json',
      'tap',
    ]);
    expect(ReportFormat.byConfigName('junit'), ReportFormat.junit);
    expect(ReportFormat.byConfigName('tap'), ReportFormat.tap);
    expect(ReportFormat.byConfigName('xunit'), isNull);
  });

  test('TK-RPT-10: TAP from node --test: subtests grouped by the suites '
      'that close them (which are no tests), SKIP skipped, a failing TODO '
      'an expected failure, YAML blocks skipped [2026-11-18]', () {
    final c = ResultCollector();
    parseTapOutput(_lines('node_test_tap.txt'), c);
    final r = _build(c);
    expect(_byName(r), {
      'adds': TestResult.ok,
      'subtracts wrongly': TestResult.fail,
      'multiplies': TestResult.ok,
      'top level passes': TestResult.ok,
      'skipped one': TestResult.skip,
      'todo failing': TestResult.skip,
      'todo passing': TestResult.ok,
    });
    final groups = {for (final e in r.entries) e.fullDescription: e.groups};
    expect(groups['adds'], 'math');
    expect(groups['multiplies'], 'math > nested');
    expect(groups['top level passes'], isNull);
    expect(r.loadFailures, isEmpty, reason: 'every plan matches');
  });

  test('TK-RPT-11: TAP from bats (--tap and --formatter tap13): no dash '
      'before the description, a lowercase skip, not ok with SKIP '
      '[2026-11-18]', () {
    for (final file in ['bats_tap.txt', 'bats_tap13.txt']) {
      final c = ResultCollector();
      parseTapOutput(_lines(file), c);
      final r = _build(c);
      expect(_byName(r), {
        'addition works': TestResult.ok,
        'subtraction is wrong': TestResult.fail,
        'not ready yet': TestResult.skip,
        'plain skip': TestResult.skip,
      }, reason: file);
      expect(r.loadFailures, isEmpty, reason: file);
    }
  });

  test('TK-RPT-12: Bail out! and a plan that does not match are load '
      'failures; the tests read before them are kept [2026-11-18]', () {
    final c = ResultCollector();
    parseTapOutput(const [
      'TAP version 14',
      '1..3',
      'ok 1 - first',
      'not ok 2 - second',
      'Bail out! database unavailable',
    ], c);
    final r = _build(c);
    expect(_byName(r), {'first': TestResult.ok, 'second': TestResult.fail});
    expect(r.loadFailures.map((f) => f.message), [
      'Bail out! database unavailable',
      'the plan 1..3 announced 3 test(s), 2 reported',
    ]);
    expect(r.runProblem, contains('Bail out! database unavailable'));
  });

  test('TK-RPT-13: TAP 14 subtests without a Subtest comment; a group that '
      'fails with every subtest passing is recorded; points without a '
      'description; an escaped # [2026-11-18]', () {
    final c = ResultCollector();
    parseTapOutput(const [
      'TAP version 14',
      '    ok 1 - inner a',
      '    ok 2 - inner b',
      '    1..2',
      'not ok 1 - outer',
      '  ---',
      '  message: after hook failed',
      '  ...',
      'ok 2',
      r'ok 3 - issue \#12 fixed # skip flaky',
      'ok 4 - plan comes last',
      '1..4',
    ], c);
    final r = _build(c);
    expect(_byName(r), {
      'inner a': TestResult.ok,
      'inner b': TestResult.ok,
      'outer': TestResult.fail,
      'test 2': TestResult.ok,
      'issue #12 fixed': TestResult.skip,
      'plan comes last': TestResult.ok,
    });
    expect(
      r.entries.firstWhere((e) => e.fullDescription == 'inner a').groups,
      'outer',
    );
    expect(r.loadFailures, isEmpty);
  });
}
