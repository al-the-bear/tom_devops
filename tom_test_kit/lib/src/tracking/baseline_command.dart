import 'dart:io';

import 'package:path/path.dart' as p;

import '../model/test_run.dart';
import '../model/tracking_file.dart';
import '../parser/dart_test_parser.dart';
import '../util/file_helpers.dart';

/// Implements the `:baseline` subcommand.
///
/// Runs the test suite (`dart test`, or `flutter test` for Flutter packages)
/// and creates a new baseline tracking file.
class BaselineCommand {
  /// Runs the baseline command for a single project.
  ///
  /// [projectPath] is the project directory (must contain pubspec.yaml).
  /// [outputPath] overrides the default output location.
  /// [testArgs] are additional arguments passed to `dart test`.
  /// [verbose] enables diagnostic output.
  ///
  /// Returns true on success, false on failure — including a run in which no
  /// test ran or a test file failed to load, for which nothing is written.
  static Future<bool> run({
    required String projectPath,
    String? outputPath,
    List<String> testArgs = const [],
    bool verbose = false,
    String? comment,
  }) async {
    // Run dart test
    final results = await DartTestParser.runAndParse(
      projectPath: projectPath,
      additionalArgs: testArgs,
      verbose: verbose,
    );

    if (results == null) {
      stderr.writeln('[$projectPath] Failed to run dart test.');
      return false;
    }

    // Save raw JSON output for inspection
    await saveLastTestRunJson(projectPath, results.rawJsonLines);

    // A baseline is the reference every later run is compared with. One that
    // is empty, or missing a file that did not load, would pass that loss on
    // to each of them as "not in baseline" — so none is written.
    final problem = results.runProblem;
    if (problem != null) {
      stderr.writeln('[$projectPath] Baseline not written. $problem');
      return false;
    }

    // Create baseline run (copy results into a run marked as baseline)
    final baselineRun = TestRun(
      timestamp: results.run.timestamp,
      isBaseline: true,
      comment: comment,
      results: Map.of(results.run.results),
    );

    // Create tracking file
    final tracking = TrackingFile.fromBaseline(results.entries, baselineRun);

    // Determine output path
    final resolvedOutput = outputPath ?? defaultBaselinePath(projectPath);

    // Write the file
    await tracking.write(resolvedOutput);

    // Print summary
    final relativePath = p.relative(resolvedOutput, from: projectPath);
    print('  Created: $relativePath');
    print('  Tests: ${results.totalTests} '
        '(${results.passedTests} passed, '
        '${results.failedTests} failed'
        '${results.skippedTests > 0 ? ', ${results.skippedTests} skipped' : ''})');

    return true;
  }
}
