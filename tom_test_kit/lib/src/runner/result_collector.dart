/// Turns the per-test results a runner reported into [TestRunResults].
library;

import '../model/test_entry.dart';
import '../model/test_run.dart';
import '../model/test_run_results.dart';
import '../parser/test_description_parser.dart';

/// One test's result as a runner reported it.
class ReportedTest {
  /// The test's name as the runner gives it (`TestParse/empty`,
  /// `parser::tests::empty`, `tests/foo_test.py`).
  final String name;

  /// The file, package or test binary the test belongs to, if known.
  final String? suite;

  /// The test's group path for the tracking table (`Groups` column), if any.
  final String? groups;

  /// Passed, failed or skipped.
  final TestResult result;

  const ReportedTest({
    required this.name,
    required this.result,
    this.suite,
    this.groups,
  });
}

/// Collects a run's reported tests and load failures, then builds its
/// [TestRunResults].
///
/// A tracking file keys every test by its description, so two tests reported
/// under the same name (the same test name in two packages or files) would
/// overwrite each other. [build] keeps them apart: each name reported more
/// than once is written `<groups or suite> > <name>`.
class ResultCollector {
  final _tests = <ReportedTest>[];

  /// Test files or packages that did not load or compile.
  final loadFailures = <LoadFailure>[];

  /// Adds one reported test.
  void add(ReportedTest test) => _tests.add(test);

  /// Adds a file or package that did not load, so none of its tests ran.
  void addLoadFailure(String suitePath, String message) =>
      loadFailures.add(LoadFailure(suitePath: suitePath, message: message));

  /// The number of tests added so far.
  int get length => _tests.length;

  /// The run's results. [rawOutput] is kept as `testlog/<rawOutputName>`;
  /// [diagnostic] is added to the run problem when no test was reported.
  TestRunResults build({
    required List<String> rawOutput,
    required String rawOutputName,
    required int exitCode,
    String? diagnostic,
  }) {
    final run = TestRun(timestamp: DateTime.now());
    final entries = <TestEntry>[];
    final nameCounts = <String, int>{};
    for (final t in _tests) {
      nameCounts[t.name] = (nameCounts[t.name] ?? 0) + 1;
    }

    for (final t in _tests) {
      final qualifier = t.groups ?? t.suite;
      final key = (nameCounts[t.name]! > 1 && qualifier != null)
          ? '$qualifier > ${t.name}'
          : t.name;
      // A runner that reports the same test twice (a retried test) keeps one
      // entry with its last result.
      if (!run.results.containsKey(key)) {
        entries.add(
          TestDescriptionParser.parse(key, suite: t.suite, groups: t.groups),
        );
      }
      run.setResult(key, t.result);
    }
    final results = run.results.values;
    final passed = results.where((r) => r == TestResult.ok).length;
    final failed = results.where((r) => r == TestResult.fail).length;
    final skipped = results.where((r) => r == TestResult.skip).length;

    return TestRunResults(
      entries: entries,
      run: run,
      totalTests: passed + failed + skipped,
      passedTests: passed,
      failedTests: failed,
      skippedTests: skipped,
      rawOutput: rawOutput,
      rawOutputName: rawOutputName,
      loadFailures: List.of(loadFailures),
      exitCode: exitCode,
      diagnostic: diagnostic,
    );
  }
}
