/// SCF13 — an issuekit option means the same thing wherever it is written
/// relative to its command name.
///
/// tom_build_base's parser routes by position: an option before the command
/// lands in `CliArgs.extraOptions`, one after it in
/// `commandArgs[<command>].options`. issuekit's executors read only
/// `extraOptions`, so every one of its 27 options was silently ignored in the
/// TRAILING position — the form its own help and the workspace docs use.
/// `issuekit :list --state closed` listed issues in every state.
///
/// The executor tests beside this one build `CliArgs` by hand with
/// `extraOptions`, which is exactly the position that already worked, so they
/// could not see it. These cases go through the real parser.
@TestOn('vm')
library;

import 'dart:io';

import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart'
    hide ListExecutor, SyncExecutor;
import 'package:tom_issue_kit/src/v2/issuekit_executors.dart';
import 'package:tom_issue_kit/src/v2/issuekit_tool.dart';

import '../helpers/fixtures.dart';

CliArgs _parse(List<String> argv) =>
    CliArgParser(toolDefinition: issuekitTool).parse(argv);

void main() {
  late MockIssueService service;
  setUp(() => service = MockIssueService());

  void stubList() {
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
  }

  group('SCF13: options after the command name reach the executor', () {
    test('F-SCF13-1: `:list --state closed --severity high` filters by both '
        '[2026-09-29] (PASS)', () async {
      stubList();
      final args = _parse([':list', '--state', 'closed', '--severity', 'high']);
      expect(
        args.extraOptions['state'],
        isNull,
        reason: 'the fixture must exercise the trailing position',
      );
      await ListExecutor(service).executeWithoutTraversal(args);
      verify(
        () => service.listIssues(
          state: 'closed',
          severity: 'high',
          project: null,
          tags: null,
          reporter: null,
          includeAll: false,
          sort: null,
        ),
      ).called(1);
    });

    test('F-SCF13-2: the leading position still works, and per-command wins '
        'when both are given [2026-09-29] (PASS)', () async {
      stubList();
      await ListExecutor(
        service,
      ).executeWithoutTraversal(_parse(['--state', 'new', ':list']));
      verify(
        () => service.listIssues(
          state: 'new',
          severity: null,
          project: null,
          tags: null,
          reporter: null,
          includeAll: false,
          sort: null,
        ),
      ).called(1);

      stubList();
      await ListExecutor(service).executeWithoutTraversal(
        _parse(['--state', 'new', ':list', '--state', 'closed']),
      );
      verify(
        () => service.listIssues(
          state: 'closed',
          severity: null,
          project: null,
          tags: null,
          reporter: null,
          includeAll: false,
          sort: null,
        ),
      ).called(1);
    });

    test(
      'F-SCF13-4: `:search parser --repo tests` — a positional and a '
      'trailing option together, the documented shape [2026-09-29] (PASS)',
      () async {
        when(
          () => service.searchIssues(
            query: any(named: 'query'),
            repo: any(named: 'repo'),
          ),
        ).thenAnswer((_) async => createTestSearchResult(totalCount: 0));
        await SearchExecutor(service).executeWithoutTraversal(
          _parse([':search', 'parser', '--repo', 'tests']),
        );
        verify(
          () => service.searchIssues(query: 'parser', repo: 'tests'),
        ).called(1);
      },
    );

    test('F-SCF13-3: no executor reads `args.extraOptions` directly '
        '[2026-09-29] (PASS)', () {
      // The 27 options are read through 18 sites, most as
      // `final opts = args.extraOptions;` with the option named far below —
      // so a check for one command cannot vouch for the others. Every site
      // now goes through `CliArgs.optionsFor(<command>)`.
      final source = File(
        'lib/src/v2/issuekit_executors.dart',
      ).readAsStringSync();
      final direct = RegExp(r'args\.extraOptions').allMatches(source).length;
      expect(
        direct,
        0,
        reason:
            'read options with args.optionsFor(<command>) so the trailing '
            'position counts; extraOptions alone is only the leading one',
      );
    });
  });
}
