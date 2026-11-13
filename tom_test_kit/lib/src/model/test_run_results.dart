import 'dart:convert';

import 'test_run.dart';
import 'test_entry.dart';

/// The file in `testlog/` that keeps a `dart test` run's JSON events.
const lastTestRunJsonName = 'last_testrun.json';

/// A test file (or package) the runner could not load — its tests never ran.
///
/// `dart test` reports it as a pseudo-test named `loading <path>` whose result
/// is `error`, which is how a file whose imports do not resolve shows up; `go
/// test` as a package whose build failed; jest as a test file that failed
/// before any of its tests. The run's exit code is then the same as a run
/// whose tests merely failed, so this record is the only thing that tells the
/// two apart.
class LoadFailure {
  /// The test file or package, as the runner names it (e.g.
  /// `test/foo_test.dart`).
  final String suitePath;

  /// The runner's error, without its stack trace.
  final String message;

  const LoadFailure({required this.suitePath, required this.message});
}

/// The results of one test run, whichever runner produced them: the tests
/// with their results, the counts, the files that did not load and the
/// runner's raw output.
class TestRunResults {
  /// All test entries found in the run.
  final List<TestEntry> entries;

  /// The test run with results.
  final TestRun run;

  /// Total number of tests.
  final int totalTests;

  /// Number of passed tests.
  final int passedTests;

  /// Number of failed tests.
  final int failedTests;

  /// Number of skipped tests.
  final int skippedTests;

  /// The runner's raw output (for `dart test`, its JSON event lines), kept in
  /// `testlog/<rawOutputName>` for inspection.
  final List<String> rawOutput;

  /// The file name the raw output is kept under in `testlog/`.
  final String rawOutputName;

  /// What the runner said when it reported no test (the tail of its output),
  /// added to [runProblem]; null when there is nothing to add.
  final String? diagnostic;

  /// Test files that failed to load, so none of their tests ran.
  final List<LoadFailure> loadFailures;

  /// The test runner's exit code.
  final int exitCode;

  TestRunResults({
    required this.entries,
    required this.run,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.skippedTests,
    List<String>? rawOutput,
    this.rawOutputName = lastTestRunJsonName,
    this.loadFailures = const [],
    this.exitCode = 0,
    this.diagnostic,
  }) : rawOutput = rawOutput ?? [];

  /// Why this run cannot be trusted as a complete record, or null when it can.
  ///
  /// Failing tests are results and are not a problem. What is: a run in which
  /// no test ran at all — there is no case in which "0 tests passed" is the
  /// answer the caller wanted — and a run missing the tests of a file that did
  /// not load, which would otherwise look like a smaller suite; and a runner
  /// that exited with an error although every test it reported passed (a
  /// test script whose build step failed before its tests reported).
  String? get runProblem {
    final failures = loadFailures.map(_describeLoadFailure).join('\n');
    if (totalTests == 0) {
      if (loadFailures.isNotEmpty) {
        return 'No test ran: ${loadFailures.length} test file(s) failed to '
            'load.\n$failures';
      }
      final said = diagnostic == null ? '' : '\n$diagnostic';
      return 'No test ran: the runner finished (exit code $exitCode) without '
          'reporting a single test. Either no test file declares one, or the '
          'arguments filtered every test out.$said';
    }
    if (loadFailures.isNotEmpty) {
      return '${loadFailures.length} test file(s) failed to load, so their '
          'tests are missing from this run.\n$failures';
    }
    if (exitCode != 0 && failedTests == 0) {
      return 'The runner exited with code $exitCode although no reported test '
          'failed: something it ran did not report a result (its output is '
          'in testlog/$rawOutputName).';
    }
    return null;
  }

  static String _describeLoadFailure(LoadFailure failure) {
    final lines = const LineSplitter()
        .convert(failure.message)
        .where((l) => l.trim().isNotEmpty)
        .take(4)
        .map((l) => '      $l')
        .join('\n');
    return '  ${failure.suitePath}:\n$lines';
  }
}
