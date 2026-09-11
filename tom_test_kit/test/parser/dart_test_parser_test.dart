import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

/// Test IDs: TK-DTP-1 through TK-DTP-24
void main() {
  group('DartTestParser', () {
    group('parseJsonOutput', () {
      test('TK-DTP-1: should parse a passing test from JSON events', () {
        final lines = _makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _groupEvent(1, '', suiteId: 0),
          _testStartEvent(2, 'should pass', suiteId: 0, groupIds: [1]),
          _testDoneEvent(2, result: 'success'),
        ]);

        final results = DartTestParser.parseJsonOutput(lines);
        expect(results.totalTests, equals(1));
        expect(results.passedTests, equals(1));
        expect(results.failedTests, equals(0));
        expect(results.entries, hasLength(1));
        expect(results.entries.first.fullDescription, equals('should pass'));
        expect(results.entries.first.groups, isNull);
      });

      test('TK-DTP-2: should parse a failing test', () {
        final lines = _makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _groupEvent(1, '', suiteId: 0),
          _testStartEvent(2, 'should fail', suiteId: 0, groupIds: [1]),
          _testDoneEvent(2, result: 'failure'),
        ]);

        final results = DartTestParser.parseJsonOutput(lines);
        expect(results.failedTests, equals(1));
        expect(results.run.getResult('should fail'), equals(TestResult.fail));
      });

      test('TK-DTP-3: should parse a skipped test', () {
        final lines = _makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _groupEvent(1, '', suiteId: 0),
          _testStartEvent(2, 'should skip', suiteId: 0, groupIds: [1]),
          _testDoneEvent(2, result: 'success', skipped: true),
        ]);

        final results = DartTestParser.parseJsonOutput(lines);
        expect(results.skippedTests, equals(1));
        expect(results.run.getResult('should skip'), equals(TestResult.skip));
      });

      test('TK-DTP-4: should skip "loading" tests', () {
        final lines = _makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _testStartEvent(1, 'loading test/my_test.dart',
              suiteId: 0, groupIds: []),
          _testDoneEvent(1, result: 'success', hidden: true),
          _groupEvent(2, '', suiteId: 0),
          _testStartEvent(3, 'real test', suiteId: 0, groupIds: [2]),
          _testDoneEvent(3, result: 'success'),
        ]);

        final results = DartTestParser.parseJsonOutput(lines);
        expect(results.totalTests, equals(1));
        expect(results.entries.first.fullDescription, equals('real test'));
      });

      test('TK-DTP-5: should skip hidden tests', () {
        final lines = _makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _groupEvent(1, '', suiteId: 0),
          _testStartEvent(2, 'hidden test', suiteId: 0, groupIds: [1]),
          _testDoneEvent(2, result: 'success', hidden: true),
        ]);

        final results = DartTestParser.parseJsonOutput(lines);
        expect(results.totalTests, equals(0));
      });

      test('TK-DTP-6: should handle multiple tests mixed pass/fail', () {
        final lines = _makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _groupEvent(1, '', suiteId: 0),
          _testStartEvent(2, 'test A', suiteId: 0, groupIds: [1]),
          _testDoneEvent(2, result: 'success'),
          _testStartEvent(3, 'test B', suiteId: 0, groupIds: [1]),
          _testDoneEvent(3, result: 'failure'),
          _testStartEvent(4, 'test C', suiteId: 0, groupIds: [1]),
          _testDoneEvent(4, result: 'success', skipped: true),
        ]);

        final results = DartTestParser.parseJsonOutput(lines);
        expect(results.totalTests, equals(3));
        expect(results.passedTests, equals(1));
        expect(results.failedTests, equals(1));
        expect(results.skippedTests, equals(1));
      });

      test('TK-DTP-7: should skip non-JSON lines gracefully', () {
        final lines = [
          'Some random text',
          '',
          jsonEncode(_suiteEvent(0, 'test/my_test.dart')),
          jsonEncode(_groupEvent(1, '', suiteId: 0)),
          'Another non-json line',
          jsonEncode(_testStartEvent(2, 'test', suiteId: 0, groupIds: [1])),
          jsonEncode(_testDoneEvent(2, result: 'success')),
        ];

        final results = DartTestParser.parseJsonOutput(lines);
        expect(results.totalTests, equals(1));
      });

      test('TK-DTP-8: should handle empty input', () {
        final results = DartTestParser.parseJsonOutput([]);
        expect(results.totalTests, equals(0));
        expect(results.entries, isEmpty);
      });

      test('TK-DTP-9: should extract single group and strip from name', () {
        final lines = _makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _groupEvent(1, '', suiteId: 0),
          _groupEvent(2, 'padTwo', suiteId: 0),
          _testStartEvent(
              3, 'padTwo TK-FMT-1: should zero-pad single digit',
              suiteId: 0, groupIds: [1, 2]),
          _testDoneEvent(3, result: 'success'),
        ]);

        final results = DartTestParser.parseJsonOutput(lines);
        expect(results.entries, hasLength(1));
        final entry = results.entries.first;
        expect(entry.groups, equals('padTwo'));
        expect(entry.id, equals('TK-FMT-1'));
        expect(entry.description, equals('should zero-pad single digit'));
        expect(entry.fullDescription,
            equals('TK-FMT-1: should zero-pad single digit'));
      });

      test('TK-DTP-10: should extract nested groups with > separator', () {
        final lines = _makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _groupEvent(1, '', suiteId: 0),
          _groupEvent(2, 'DartTestParser', suiteId: 0),
          _groupEvent(3, 'DartTestParser parseJsonOutput', suiteId: 0),
          _testStartEvent(
              4, 'DartTestParser parseJsonOutput TK-DTP-1: should parse',
              suiteId: 0, groupIds: [1, 2, 3]),
          _testDoneEvent(4, result: 'success'),
        ]);

        final results = DartTestParser.parseJsonOutput(lines);
        final entry = results.entries.first;
        expect(entry.groups, equals('DartTestParser > parseJsonOutput'));
        expect(entry.id, equals('TK-DTP-1'));
        expect(entry.description, equals('should parse'));
      });

      test('TK-DTP-11: should handle test with only root group (no groups)',
          () {
        final lines = _makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _groupEvent(1, '', suiteId: 0),
          _testStartEvent(2, 'TK-1: bare test', suiteId: 0, groupIds: [1]),
          _testDoneEvent(2, result: 'success'),
        ]);

        final results = DartTestParser.parseJsonOutput(lines);
        final entry = results.entries.first;
        expect(entry.groups, isNull);
        expect(entry.id, equals('TK-1'));
        expect(entry.description, equals('bare test'));
        expect(entry.fullDescription, equals('TK-1: bare test'));
      });
    });

    group('process execution', () {
      test('TK-DTP-12: runInShellForHost matches the host platform', () {
        // The Windows Dart SDK launcher is `dart.bat`, which Process.start
        // cannot resolve unless invoked through a shell. This guard keeps the
        // shell decision tied to the host so the Windows fix cannot regress.
        expect(DartTestParser.runInShellForHost, equals(Platform.isWindows));
      });

      test('TK-DTP-13: buildLaunchError is clear and actionable', () {
        final message = DartTestParser.buildLaunchError(
          'dart',
          const ProcessException('dart', ['test'], 'not found', 2),
        );
        // Names the executable, points at PATH, and surfaces the cause so the
        // user gets an actionable error instead of a silent exit 0.
        expect(message, contains('dart'));
        expect(message.toLowerCase(), contains('path'));
        expect(message, contains('not found'));
      });

      test('TK-DTP-14: buildLaunchError mentions dart.bat on Windows', () {
        final message = DartTestParser.buildLaunchError(
          'dart',
          const ProcessException('dart', ['test']),
        );
        if (Platform.isWindows) {
          expect(message, contains('dart.bat'));
        }
      });

      test('TK-DTP-15: buildLaunchError names the flutter launcher', () {
        final message = DartTestParser.buildLaunchError(
          'flutter',
          const ProcessException('flutter', ['test'], 'not found', 2),
        );
        expect(message, contains('flutter'));
        if (Platform.isWindows) {
          expect(message, contains('flutter.bat'));
        }
      });
    });

    // A run that measured nothing must never read as a green run. These pin
    // how the parser tells the ways a run can come back empty apart.
    group('runs that cannot be recorded', () {
      /// The events `dart test --reporter json` emits for a test file whose
      /// imports cannot be resolved, reduced to the fields the parser reads.
      List<Map<String, dynamic>> failedLoad(int id, String path) => [
            _suiteEvent(id, path),
            _testStartEvent(id + 100, 'loading $path',
                suiteId: id, groupIds: []),
            {
              'type': 'error',
              'testID': id + 100,
              'error': 'Failed to load "$path":\n'
                  "Couldn't resolve the package 'does_not_exist' in "
                  "'package:does_not_exist/x.dart'.",
              'stackTrace': 'package:test_core/... VMPlatform._compileToKernel',
              'isFailure': false,
            },
            _testDoneEvent(id + 100, result: 'error'),
          ];

      test(
          'TK-DTP-16: a test file that fails to load is a load failure, '
          'not a test and not nothing', () {
        final results = DartTestParser.parseJsonOutput(
          _makeJsonLines(failedLoad(0, 'test/a_test.dart')),
        );

        expect(results.totalTests, equals(0));
        expect(results.loadFailures, hasLength(1));
        expect(results.loadFailures.single.suitePath, 'test/a_test.dart');
        expect(
          results.loadFailures.single.message,
          contains("Couldn't resolve the package 'does_not_exist'"),
        );
        expect(
          results.loadFailures.single.message,
          isNot(contains('VMPlatform')),
          reason: 'the message is the error, not its stack trace',
        );
      });

      test('TK-DTP-17: a file that loaded records no load failure', () {
        final results = DartTestParser.parseJsonOutput(_makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _testStartEvent(1, 'loading test/my_test.dart',
              suiteId: 0, groupIds: []),
          _testDoneEvent(1, result: 'success', hidden: true),
          _testStartEvent(2, 'real test', suiteId: 0, groupIds: []),
          _testDoneEvent(2, result: 'success'),
        ]));

        expect(results.loadFailures, isEmpty);
        expect(results.runProblem, isNull);
      });

      test(
          'TK-DTP-18: a run whose tests all failed still has no problem — '
          'failing tests are results', () {
        final results = DartTestParser.parseJsonOutput(_makeJsonLines([
          _suiteEvent(0, 'test/my_test.dart'),
          _testStartEvent(1, 'broken', suiteId: 0, groupIds: []),
          _testDoneEvent(1, result: 'failure'),
        ]));

        expect(results.runProblem, isNull);
      });

      test(
          'TK-DTP-19: zero tests because every file failed to load says so '
          'and names the file', () {
        final results = DartTestParser.parseJsonOutput(
          _makeJsonLines(failedLoad(0, 'test/a_test.dart')),
        );

        final problem = results.runProblem;
        expect(problem, isNotNull);
        expect(problem, contains('No test ran'));
        expect(problem, contains('failed to load'));
        expect(problem, contains('test/a_test.dart'));
        expect(problem, contains("Couldn't resolve the package"));
      });

      test(
          'TK-DTP-20: zero tests with nothing failing to load is still a '
          'problem, not an empty success', () {
        final results = DartTestParser.parseJsonOutput(const []);

        final problem = results.runProblem;
        expect(problem, isNotNull);
        expect(problem, contains('No test ran'));
        expect(problem, isNot(contains('failed to load')));
      });

      test(
          'TK-DTP-21: one file failing to load while another runs names the '
          'missing file', () {
        final results = DartTestParser.parseJsonOutput(_makeJsonLines([
          ...failedLoad(0, 'test/broken_test.dart'),
          _suiteEvent(1, 'test/fine_test.dart'),
          _testStartEvent(2, 'fine', suiteId: 1, groupIds: []),
          _testDoneEvent(2, result: 'success'),
        ]));

        expect(results.totalTests, equals(1));
        final problem = results.runProblem;
        expect(problem, isNotNull);
        expect(problem, contains('test/broken_test.dart'));
        expect(problem, contains('missing from this run'));
      });

      test(
          'TK-DTP-22: exit code 79 is reported as "no tests matched", with '
          "the runner's own line", () {
        final message = DartTestParser.describeRunnerExit(
          executable: 'dart',
          exitCode: 79,
          stdoutLines: [
            '{"type":"start"}',
            'No tests match regular expression "nomatch".',
          ],
          stderrLines: const [],
        );

        expect(message, contains('79'));
        expect(message.toLowerCase(), contains('no tests'));
        expect(message, contains('No tests match regular expression'));
        expect(message, isNot(contains('"type"')),
            reason: 'JSON protocol events are not diagnostics');
      });

      test(
          'TK-DTP-23: any other early exit carries its code and the text the '
          'runner printed on stdout and stderr', () {
        final message = DartTestParser.describeRunnerExit(
          executable: 'dart',
          exitCode: 65,
          stdoutLines: ['Because fb depends on missing_pkg ... failed.'],
          stderrLines: ['stderr detail'],
        );

        expect(message, contains('65'));
        expect(message, contains('Because fb depends on missing_pkg'));
        expect(message, contains('stderr detail'));
      });

      test(
          'TK-DTP-24: a line the runner printed on both stdout and stderr is '
          'reported once', () {
        // Pub prints a failed resolution to both streams.
        const said = 'Because fb depends on missing_pkg ... failed.';
        final message = DartTestParser.describeRunnerExit(
          executable: 'dart',
          exitCode: 65,
          stdoutLines: [said],
          stderrLines: [said],
        );

        expect(said.allMatches(message).length, 1);
      });
    });
  });
}

// --- JSON event helpers ---

List<String> _makeJsonLines(List<Map<String, dynamic>> events) {
  return events.map((e) => jsonEncode(e)).toList();
}

Map<String, dynamic> _suiteEvent(int id, String path) => {
      'type': 'suite',
      'suite': {'id': id, 'path': path},
    };

Map<String, dynamic> _groupEvent(int id, String name, {required int suiteId}) =>
    {
      'type': 'group',
      'group': {'id': id, 'name': name, 'suiteID': suiteId},
    };

Map<String, dynamic> _testStartEvent(
  int id,
  String name, {
  required int suiteId,
  required List<int> groupIds,
}) =>
    {
      'type': 'testStart',
      'test': {
        'id': id,
        'name': name,
        'suiteID': suiteId,
        'groupIDs': groupIds,
      },
    };

Map<String, dynamic> _testDoneEvent(
  int testId, {
  required String result,
  bool skipped = false,
  bool hidden = false,
}) =>
    {
      'type': 'testDone',
      'testID': testId,
      'result': result,
      'skipped': skipped,
      'hidden': hidden,
    };
