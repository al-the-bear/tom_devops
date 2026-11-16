/// `issuekit :run-tests` without `--github` runs testkit locally, so it needs
/// neither a GitHub token nor the `issuekit:` section; `--github` still does.
///
/// Test IDs: IK-RTCLI-1..2.
@TestOn('vm')
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final _issuekit = p.join(Directory.current.path, 'bin', 'issuekit.dart');

void main() {
  late Directory root;
  late Map<String, String> env;

  setUp(() {
    root = Directory(
      Directory.systemTemp
          .createTempSync('ik_run_tests_')
          .resolveSymbolicLinksSync(),
    );
    File(p.join(root.path, 'buildkit_master.yaml')).writeAsStringSync('');
    env = Map.of(Platform.environment)
      ..remove('GITHUB_TOKEN')
      ..remove('GH_TOKEN')
      ..['TOM_WORKSPACE_ROOT'] = root.path;
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<ProcessResult> issuekit(List<String> args) => Process.run(
    'dart',
    ['run', _issuekit, ...args],
    workingDirectory: root.path,
    environment: env,
    includeParentEnvironment: false,
  );

  test('IK-RTCLI-1: a local :run-tests needs no token and no issuekit '
      'section [2026-11-17]', () async {
    final r = await issuekit([':run-tests', '-n']);
    final out = '${r.stdout}${r.stderr}';
    expect(r.exitCode, 0, reason: out);
    expect(out, contains('[DRY RUN] Would run testkit -R ${root.path} :test'));
    expect(out, isNot(contains('No GitHub token')));
  });

  test('IK-RTCLI-2: :run-tests --github still needs the token [2026-11-17]',
      () async {
    final r = await issuekit([':run-tests', '--github', '-n']);
    final out = '${r.stdout}${r.stderr}';
    expect(r.exitCode, isNot(0), reason: out);
    expect(out, contains('No GitHub token'));
  });
}
