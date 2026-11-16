/// issuekit's commands that visit no projects (`:list`, `:show`, `:init`,
/// ...) report through the messages of the [ToolResult] they return; the
/// shared run summary prints only skips, failures and a footer, so those
/// messages were never shown: `issuekit :list` printed "Done. No errors." over
/// a repository with issues. Every executor the factory hands out now prints
/// the messages of its successful results, once, in order.
///
/// Test IDs: IK-OUT-1..4.
@TestOn('vm')
library;

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart'
    hide ListExecutor, SyncExecutor;
import 'package:tom_issue_kit/src/v2/issuekit_executors.dart';

import '../helpers/fixtures.dart';

class _Results extends CommandExecutor {
  _Results(this.result);
  final ToolResult result;

  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async =>
      ItemResult.success(path: context.path, name: context.name);

  @override
  Future<ToolResult> executeWithoutTraversal(CliArgs args) async => result;
}

Future<List<String>> _printed(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  test('IK-OUT-1: the messages of successful results are printed, in order; '
      'skips, failures and empty messages are left to the summary '
      '[2026-11-16]', () async {
    final executor = ResultPrintingExecutor(
      _Results(
        ToolResult(
          success: false,
          processedCount: 4,
          itemResults: [
            ItemResult.success(path: 'r', name: '#1', message: '#1  first'),
            ItemResult.success(path: 'r', name: '#2', message: '#2  second'),
            ItemResult.success(path: 'r', name: '#3'),
            ItemResult.skipped(path: 'r', name: '#4', message: 'skip me'),
            ItemResult.failure(path: 'r', name: '#5', error: 'boom'),
          ],
        ),
      ),
    );
    late ToolResult result;
    final lines = await _printed(
      () async => result = await executor.executeWithoutTraversal(CliArgs()),
    );
    expect(lines, ['#1  first', '#2  second']);
    expect(result.itemResults, hasLength(5), reason: 'the result is unchanged');
  });

  test('IK-OUT-2: `:list` prints a row per issue [2026-11-16]', () async {
    final service = MockIssueService();
    when(
      () => service.listIssues(
        state: any(named: 'state'),
        severity: any(named: 'severity'),
        project: any(named: 'project'),
        tags: any(named: 'tags'),
        reporter: any(named: 'reporter'),
        includeAll: any(named: 'includeAll'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer(
      (_) async => [
        createTestIssue(number: 7, title: 'Parser drops the last token'),
      ],
    );
    final list = createIssuekitExecutors(service: service)['list']!;
    final lines = await _printed(() => list.executeWithoutTraversal(CliArgs()));
    expect(lines, hasLength(1));
    expect(lines.single, contains('#7'));
    expect(lines.single, contains('Parser drops the last token'));
  });

  test('IK-OUT-3: every executor of the factory prints its results and '
      'still is the command\'s executor [2026-11-16]', () {
    final executors = createIssuekitExecutors(service: MockIssueService());
    for (final MapEntry(key: name, value: e) in executors.entries) {
      expect(e, isA<ResultPrintingExecutor>(), reason: name);
    }
    expect(
      (executors['list']! as ResultPrintingExecutor).inner,
      isA<ListExecutor>(),
    );
  });

  test('IK-OUT-4: a `:list` that finds nothing says so [2026-11-16]', () async {
    final service = MockIssueService();
    when(
      () => service.listIssues(
        state: any(named: 'state'),
        severity: any(named: 'severity'),
        project: any(named: 'project'),
        tags: any(named: 'tags'),
        reporter: any(named: 'reporter'),
        includeAll: any(named: 'includeAll'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => []);
    final list = createIssuekitExecutors(service: service)['list']!;
    final lines = await _printed(() => list.executeWithoutTraversal(CliArgs()));
    expect(lines, ['No issues match.']);
  });
}
