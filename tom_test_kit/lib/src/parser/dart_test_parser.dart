import 'dart:convert';
import 'dart:io';

import 'package:tom_build_base/tom_build_base.dart';

import '../model/test_run.dart';
import '../model/test_run_results.dart';
import '../util/test_runner.dart';
import '../runner/result_collector.dart';
import 'json_event_line.dart';

/// Parses `dart test --reporter json` output into structured results.
class DartTestParser {
  /// Extracts group names and strips the group prefix from a test name.
  ///
  /// The dart test JSON reporter prepends the full group hierarchy to each
  /// test name. This method identifies the group prefix, strips it, and
  /// returns the individual group segments joined with ` > `.
  ///
  /// Returns a record of `(strippedName, groups)` where `groups` is null
  /// if the test has no named groups.
  static (String strippedName, String? groups) extractGroups({
    required String testName,
    required List<int> groupIds,
    required Map<int, String> groupNames,
  }) {
    // Find the innermost non-root group name (full accumulated path)
    String? innermostGroupName;
    for (final gid in groupIds.reversed) {
      final gname = groupNames[gid];
      if (gname != null && gname.isNotEmpty) {
        innermostGroupName = gname;
        break;
      }
    }

    if (innermostGroupName == null ||
        !testName.startsWith('$innermostGroupName ')) {
      return (testName, null);
    }

    // Strip group prefix from test name
    final strippedName = testName.substring(innermostGroupName.length + 1);

    // Build individual group segments for display (e.g., "A > B")
    final segments = <String>[];
    String prevName = '';
    for (final gid in groupIds) {
      final gname = groupNames[gid];
      if (gname != null && gname.isNotEmpty) {
        final segment = prevName.isEmpty
            ? gname
            : gname.substring(prevName.length).trim();
        if (segment.isNotEmpty) {
          segments.add(segment);
        }
        prevName = gname;
      }
    }

    return (strippedName, segments.isNotEmpty ? segments.join(' > ') : null);
  }

  /// Options that must not appear in additional args because they would
  /// break JSON output parsing or cause the process to hang.
  static const _forbiddenArgs = [
    '--reporter',
    '-r',
    '--file-reporter',
    '--pause-after-load',
    '--debug',
  ];

  /// Builds a clear, actionable error message for a failed launch of
  /// [executable] (`dart` or `flutter`).
  ///
  /// [error] is the object thrown by the process API — typically a
  /// [ProcessException] when the SDK is not on `PATH`. The message points the
  /// user at the likely cause instead of leaving testkit to exit silently.
  static String buildLaunchError(String executable, Object error) {
    final buffer = StringBuffer()
      ..writeln('Error: could not launch `$executable` to run tests.')
      ..writeln('Is the Dart/Flutter SDK installed and on your PATH?');
    if (Platform.isWindows) {
      buffer.writeln(
        'On Windows the launcher is `$executable.bat`; testkit invokes it '
        'through the shell, so make sure the SDK `bin` folder is on PATH.',
      );
    }
    buffer.write('Underlying error: $error');
    return buffer.toString();
  }

  /// Checks whether [args] contain any forbidden options.
  ///
  /// Returns the first forbidden option found, or null if all are safe.
  static String? findForbiddenArg(List<String> args) {
    for (final arg in args) {
      final normalized = arg.contains('=') ? arg.split('=').first : arg;
      for (final forbidden in _forbiddenArgs) {
        if (normalized == forbidden) return forbidden;
      }
    }
    return null;
  }

  /// Runs the test runner in the given directory and parses its JSON output.
  ///
  /// Flutter packages (those with a Flutter SDK dependency in `pubspec.yaml`)
  /// are run with `flutter test --reporter json`; all other packages with
  /// `dart test --reporter json`. Both emit the identical package:test JSON
  /// event protocol, so the parser is runner-agnostic — only the launcher
  /// differs. See [TestRunner].
  ///
  /// [projectPath] is the working directory for the test runner.
  /// [additionalArgs] are extra arguments to pass after `test`.
  /// [verbose] enables diagnostic output.
  static Future<TestRunResults?> runAndParse({
    required String projectPath,
    List<String> additionalArgs = const [],
    bool verbose = false,
    String? pubCachePath,
  }) async {
    // scd8_aicx: a locked package the pub cache cannot supply is not a
    // resolution error — the lock is satisfiable, so `dart pub get` reports
    // success — and the run fails later with `Undefined name` at every use
    // site, which reads as an upstream rename. One stat per dependency names
    // the package instead, before anything compiles.
    final cacheProblems = PubCacheIntegrity.checkProject(
      projectPath: projectPath,
      pubCachePath: pubCachePath,
    );
    if (cacheProblems.isNotEmpty) {
      stderr.writeln(
        PubCacheIntegrity.describe(cacheProblems, projectPath: projectPath),
      );
      return null;
    }

    // Validate that additional args don't contain forbidden options
    final forbidden = findForbiddenArg(additionalArgs);
    if (forbidden != null) {
      stderr.writeln('Error: "$forbidden" cannot be used in --test-args.');
      stderr.writeln('testkit requires --reporter json for result parsing.');
      if (forbidden == '--pause-after-load' || forbidden == '--debug') {
        stderr.writeln('$forbidden would prevent the process from completing.');
      }
      return null;
    }

    final runner = TestRunner.forPackage(projectPath);
    final executable = runner.executable;
    final args = runner.argsFor(additionalArgs);

    if (verbose) {
      print('  Running: $executable ${args.join(' ')}');
      print('  In: $projectPath');
    }

    // Route process execution through tom_build_base so the launcher
    // (`dart`/`dart.bat` or `flutter`/`flutter.bat`) resolves on every host
    // (runInShell on Windows) and a spawn failure surfaces a clear error
    // instead of a swallowed exception / silent exit 0.
    final ProcessRunResult procResult;
    try {
      procResult = await ProcessRunner.run(
        executable,
        args,
        workingDirectory: projectPath,
        runInShell: runner.runInShell,
      );
    } on ProcessException catch (e) {
      stderr.writeln(buildLaunchError(executable, e));
      return null;
    }

    final stdoutLines = const LineSplitter().convert(procResult.stdout);
    final stderrLines = const LineSplitter().convert(procResult.stderr);
    final exitCode = procResult.exitCode;

    if (verbose && stderrLines.isNotEmpty) {
      for (final line in stderrLines) {
        stderr.writeln('  [stderr] $line');
      }
    }

    // Exit code 1 is OK — means tests failed, but we still have results
    if (exitCode != 0 && exitCode != 1) {
      stderr.writeln(
        describeRunnerExit(
          executable: executable,
          exitCode: exitCode,
          stdoutLines: stdoutLines,
          stderrLines: stderrLines,
        ),
      );
      return null;
    }

    final result = parseJsonOutput(stdoutLines, verbose: verbose);
    return TestRunResults(
      entries: result.entries,
      run: result.run,
      totalTests: result.totalTests,
      passedTests: result.passedTests,
      failedTests: result.failedTests,
      skippedTests: result.skippedTests,
      rawOutput: stdoutLines,
      rawOutputName: lastTestRunJsonName,
      loadFailures: result.loadFailures,
      exitCode: exitCode,
    );
  }

  /// `package:test`'s exit code for a run in which no test was selected.
  static const noTestsRanExitCode = 79;

  /// Explains a runner that exited before reporting results.
  ///
  /// The runner's own explanation is often on stdout rather than stderr — a
  /// dependency that does not resolve, or `No tests match regular expression`
  /// — mixed in with the JSON protocol, so the non-JSON stdout lines are
  /// reported along with stderr.
  static String describeRunnerExit({
    required String executable,
    required int exitCode,
    required List<String> stdoutLines,
    required List<String> stderrLines,
  }) {
    final buffer = StringBuffer();
    if (exitCode == noTestsRanExitCode) {
      buffer.writeln(
        '`$executable test` found no tests to run (exit code $exitCode): '
        'no test file declares one, or the arguments filtered every test out.',
      );
    } else {
      buffer.writeln(
        '`$executable test` exited with code $exitCode before reporting '
        'any result.',
      );
    }
    // A Set keeps first-seen order and drops the repeats: pub prints a failed
    // resolution to both streams.
    final said = <String>{
      ...stdoutLines.where((l) => !_isJsonEvent(l)),
      ...stderrLines,
    }.where((l) => l.trim().isNotEmpty);
    for (final line in said) {
      buffer.writeln('  $line');
    }
    return buffer.toString().trimRight();
  }

  static bool _isJsonEvent(String line) => decodeJsonEventLine(line) != null;

  /// Parses `dart test --reporter json` output lines.
  static TestRunResults parseJsonOutput(
    List<String> lines, {
    bool verbose = false,
  }) {
    // The collector keys each test by its name without its groups (the
    // tracking file's key) and keeps apart two tests of the same name in
    // different groups, which would otherwise overwrite each other.
    final collector = ResultCollector();

    // Track test info by ID
    final testNames = <int, String>{}; // testID -> name
    final testSuites = <int, String>{}; // suiteID -> path
    final testSuiteMap = <int, int>{}; // testID -> suiteID
    final groupNames = <int, String>{}; // groupID -> name
    final testGroupMap = <int, List<int>>{}; // testID -> groupIDs

    final errorMessages = <int, List<String>>{}; // testID -> error texts

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      // A line without a JSON event is skipped; one with text glued in front
      // of its event (a print without a newline) still yields the event.
      final json = decodeJsonEventLine(line);
      if (json == null) continue;

      final type = json['type'] as String?;
      if (type == null) continue;

      switch (type) {
        case 'suite':
          final suite = json['suite'] as Map<String, dynamic>?;
          if (suite != null) {
            testSuites[suite['id'] as int] = suite['path'] as String? ?? '';
          }

        case 'group':
          final group = json['group'] as Map<String, dynamic>?;
          if (group != null) {
            groupNames[group['id'] as int] = group['name'] as String? ?? '';
          }

        case 'testStart':
          final test = json['test'] as Map<String, dynamic>?;
          if (test != null) {
            final testId = test['id'] as int;
            final name = test['name'] as String? ?? '';
            testNames[testId] = name;
            testSuiteMap[testId] = test['suiteID'] as int? ?? 0;
            final gids =
                (test['groupIDs'] as List<dynamic>?)?.cast<int>() ?? [];
            testGroupMap[testId] = gids;
          }

        case 'error':
          final testId = json['testID'] as int?;
          final error = json['error'] as String?;
          if (testId != null && error != null) {
            (errorMessages[testId] ??= []).add(error);
          }

        case 'testDone':
          final testId = json['testID'] as int?;
          if (testId == null) continue;

          final name = testNames[testId];
          if (name == null || name.isEmpty) continue;

          // "loading <file>" is the runner loading a test file, not a test.
          // It only matters when it fails: then none of that file's tests ran.
          if (name.startsWith('loading ')) {
            final loadResult = json['result'] as String? ?? '';
            if (loadResult != 'success') {
              collector.loadFailures.add(
                LoadFailure(
                  suitePath:
                      testSuites[testSuiteMap[testId]] ??
                      name.substring('loading '.length),
                  message: (errorMessages[testId] ?? const ['(no message)'])
                      .join('\n'),
                ),
              );
            }
            continue;
          }

          final resultStr = json['result'] as String? ?? '';
          final skipped = json['skipped'] as bool? ?? false;
          final hidden = json['hidden'] as bool? ?? false;

          if (hidden) continue;

          final result = skipped
              ? TestResult.skip
              : resultStr == 'success'
              ? TestResult.ok
              : TestResult.fail;

          final suitePath = testSuites[testSuiteMap[testId]];
          final gids = testGroupMap[testId] ?? [];
          final (strippedName, groups) = extractGroups(
            testName: name,
            groupIds: gids,
            groupNames: groupNames,
          );
          collector.add(
            ReportedTest(
              name: strippedName,
              suite: suitePath,
              groups: groups,
              result: result,
            ),
          );
      }
    }

    return collector.build(
      rawOutput: const [],
      rawOutputName: lastTestRunJsonName,
      exitCode: 0,
    );
  }
}
