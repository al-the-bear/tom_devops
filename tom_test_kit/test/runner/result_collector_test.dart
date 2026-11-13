/// The collector that turns reported tests into a run's results.
///
/// Test IDs: TK-RCL-1..4.
library;

import 'package:test/test.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

TestRunResults _build(ResultCollector c) =>
    c.build(rawOutput: const ['out'], rawOutputName: 'raw.txt', exitCode: 0);

void main() {
  test('TK-RCL-1: counts per result; the raw output and its name are kept', () {
    final c = ResultCollector()
      ..add(const ReportedTest(name: 'a', result: TestResult.ok))
      ..add(const ReportedTest(name: 'b', result: TestResult.fail))
      ..add(const ReportedTest(name: 'c', result: TestResult.skip));
    final r = _build(c);
    expect(
      (r.totalTests, r.passedTests, r.failedTests, r.skippedTests),
      (3, 1, 1, 1),
    );
    expect(r.rawOutput, ['out']);
    expect(r.rawOutputName, 'raw.txt');
    expect(r.runProblem, isNull);
  });

  test('TK-RCL-2: a name reported in two groups is qualified by its group, '
      'and by its suite without one', () {
    final c = ResultCollector()
      ..add(const ReportedTest(name: 't', groups: 'g1', result: TestResult.ok))
      ..add(const ReportedTest(name: 't', suite: 's2', result: TestResult.fail))
      ..add(const ReportedTest(name: 'u', groups: 'g1', result: TestResult.ok));
    final r = _build(c);
    expect(r.run.results.keys.toSet(), {'g1 > t', 's2 > t', 'u'});
    expect(r.entries, hasLength(3));
  });

  test('TK-RCL-3: a test reported twice in one group (a retry) is one entry '
      'with its last result; no test is a run problem', () {
    final c = ResultCollector()
      ..add(const ReportedTest(name: 't', groups: 'g', result: TestResult.fail))
      ..add(const ReportedTest(name: 't', groups: 'g', result: TestResult.ok));
    final r = _build(c);
    expect(r.entries, hasLength(1));
    expect((r.totalTests, r.passedTests, r.failedTests), (1, 1, 0));
    expect(_build(ResultCollector()).runProblem, contains('No test ran'));
  });

  test('TK-RCL-4: an exit code other than 0 with no failing test is a run '
      'problem naming the raw output; with a failing test it is not', () {
    final passing = ResultCollector()
      ..add(const ReportedTest(name: 'a', result: TestResult.ok));
    final r = passing.build(
      rawOutput: const [],
      rawOutputName: 'last_testrun.txt',
      exitCode: 1,
    );
    expect(r.runProblem, contains('exited with code 1'));
    expect(r.runProblem, contains('testlog/last_testrun.txt'));
    final failing = ResultCollector()
      ..add(const ReportedTest(name: 'a', result: TestResult.fail));
    expect(
      failing
          .build(rawOutput: const [], rawOutputName: 'x', exitCode: 1)
          .runProblem,
      isNull,
    );
  });
}
