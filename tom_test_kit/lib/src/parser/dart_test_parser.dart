import 'dart:convert';
import 'dart:io';

import 'package:tom_build_base/tom_build_base.dart';

import '../model/test_entry.dart';
import '../model/test_run.dart';
import 'test_description_parser.dart';

/// Parsed results from a `dart test --reporter json` run.
class DartTestResults {
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

  /// Raw JSON lines from `dart test --reporter json` output.
  final List<String> rawJsonLines;

  DartTestResults({
    required this.entries,
    required this.run,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.skippedTests,
    List<String>? rawJsonLines,
  }) : rawJsonLines = rawJsonLines ?? [];
}

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

  /// Whether the `dart` process must be launched through a shell.
  ///
  /// On Windows the Dart SDK launcher is `dart.bat`, which `Process.start`
  /// cannot resolve directly — it must be invoked via the shell. On POSIX
  /// hosts no shell is needed. Both the spawn and its regression test read
  /// this single source of truth so the Windows fix cannot drift.
  static final bool runInShellForHost = Platform.isWindows;

  /// Builds a clear, actionable error message for a failed `dart` launch.
  ///
  /// [error] is the object thrown by the process API — typically a
  /// [ProcessException] when the SDK is not on `PATH`. The message points the
  /// user at the likely cause instead of leaving testkit to exit silently.
  static String buildLaunchError(Object error) {
    final buffer = StringBuffer()
      ..writeln('Error: could not launch `dart` to run tests.')
      ..writeln('Is the Dart/Flutter SDK installed and on your PATH?');
    if (Platform.isWindows) {
      buffer.writeln(
        'On Windows the launcher is `dart.bat`; testkit invokes it through '
        'the shell, so make sure the SDK `bin` folder is on PATH.',
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

  /// Runs `dart test --reporter json` in the given directory and parses output.
  ///
  /// [projectPath] is the working directory for `dart test`.
  /// [additionalArgs] are extra arguments to pass to `dart test`.
  /// [verbose] enables diagnostic output.
  static Future<DartTestResults?> runAndParse({
    required String projectPath,
    List<String> additionalArgs = const [],
    bool verbose = false,
  }) async {
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

    final args = ['test', '--reporter', 'json', ...additionalArgs];

    if (verbose) {
      print('  Running: dart ${args.join(' ')}');
      print('  In: $projectPath');
    }

    // Route process execution through tom_build_base so `dart`/`dart.bat`
    // resolves on every host (runInShell on Windows) and a spawn failure
    // surfaces a clear error instead of a swallowed exception / silent exit 0.
    final ProcessRunResult procResult;
    try {
      procResult = await ProcessRunner.run(
        'dart',
        args,
        workingDirectory: projectPath,
        runInShell: runInShellForHost,
      );
    } on ProcessException catch (e) {
      stderr.writeln(buildLaunchError(e));
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
      stderr.writeln('dart test exited with code $exitCode');
      if (stderrLines.isNotEmpty) {
        for (final line in stderrLines) {
          stderr.writeln('  $line');
        }
      }
      return null;
    }

    final result = parseJsonOutput(stdoutLines, verbose: verbose);
    return DartTestResults(
      entries: result.entries,
      run: result.run,
      totalTests: result.totalTests,
      passedTests: result.passedTests,
      failedTests: result.failedTests,
      skippedTests: result.skippedTests,
      rawJsonLines: stdoutLines,
    );
  }

  /// Parses `dart test --reporter json` output lines.
  static DartTestResults parseJsonOutput(
    List<String> lines, {
    bool verbose = false,
  }) {
    final timestamp = DateTime.now();
    final run = TestRun(timestamp: timestamp);
    final entries = <TestEntry>[];

    // Track test info by ID
    final testNames = <int, String>{}; // testID -> name
    final testSuites = <int, String>{}; // suiteID -> path
    final testSuiteMap = <int, int>{}; // testID -> suiteID
    final groupNames = <int, String>{}; // groupID -> name
    final testGroupMap = <int, List<int>>{}; // testID -> groupIDs

    var passCount = 0;
    var failCount = 0;
    var skipCount = 0;

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      Map<String, dynamic> json;
      try {
        json = jsonDecode(line) as Map<String, dynamic>;
      } catch (_) {
        continue; // Skip non-JSON lines
      }

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

        case 'testDone':
          final testId = json['testID'] as int?;
          if (testId == null) continue;

          final name = testNames[testId];
          if (name == null || name.isEmpty) continue;

          // Skip internal "loading" tests
          if (name.startsWith('loading ')) continue;

          final resultStr = json['result'] as String? ?? '';
          final skipped = json['skipped'] as bool? ?? false;
          final hidden = json['hidden'] as bool? ?? false;

          if (hidden) continue;

          TestResult result;
          if (skipped) {
            result = TestResult.skip;
            skipCount++;
          } else if (resultStr == 'success') {
            result = TestResult.ok;
            passCount++;
          } else {
            result = TestResult.fail;
            failCount++;
          }

          final suitePath = testSuites[testSuiteMap[testId]];
          final gids = testGroupMap[testId] ?? [];
          final (strippedName, groups) = extractGroups(
            testName: name,
            groupIds: gids,
            groupNames: groupNames,
          );
          final entry = TestDescriptionParser.parse(strippedName,
              suite: suitePath, groups: groups);
          entries.add(entry);
          run.setResult(entry.fullDescription, result);
      }
    }

    return DartTestResults(
      entries: entries,
      run: run,
      totalTests: passCount + failCount + skipCount,
      passedTests: passCount,
      failedTests: failCount,
      skippedTests: skipCount,
    );
  }
}
