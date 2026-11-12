import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Test IDs: TK-EXIT-1, TK-EXIT-2
///
/// The process exit code of `testkit :test` / `:baseline` is the verdict of
/// the run (vstkx1): 1 when a test failed, 0 when every test passed — the
/// convention `dart test` follows. Scripts rely on it, so it is pinned on the
/// real executable rather than on the executors alone.
void main() {
  final testkit = p.join(Directory.current.path, 'bin', 'testkit.dart');
  late Directory project;

  Future<void> createProject({required bool failing}) async {
    File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync('''
name: exit_code_probe
version: 0.0.1
environment:
  sdk: ^3.0.0
dev_dependencies:
  test: ^1.24.0
''');
    Directory(p.join(project.path, 'test')).createSync();
    File(p.join(project.path, 'test', 'probe_test.dart')).writeAsStringSync(
      "import 'package:test/test.dart';\n"
      'void main() {\n'
      "  test('P-1: passes', () => expect(1, 1));\n"
      "${failing ? "  test('P-2: fails', () => fail('red'));\n" : ''}"
      '}\n',
    );
    final got = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: project.path);
    if (got.exitCode != 0) throw StateError('pub get: ${got.stderr}');
  }

  Future<ProcessResult> runTestkit(String command) => Process.run('dart', [
    'run',
    testkit,
    command,
  ], workingDirectory: project.path);

  setUp(() {
    project = Directory.systemTemp.createTempSync('tk_exit_code_');
  });

  tearDown(() => project.deleteSync(recursive: true));

  test('TK-EXIT-1: a failing test makes :baseline and :test exit 1', () async {
    await createProject(failing: true);

    final baseline = await runTestkit(':baseline');
    expect(
      baseline.exitCode,
      1,
      reason: '${baseline.stdout}${baseline.stderr}',
    );

    final run = await runTestkit(':test');
    expect(run.exitCode, 1, reason: '${run.stdout}${run.stderr}');
    expect('${run.stderr}', contains('1 test failed'));
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('TK-EXIT-2: an all-green run of :baseline and :test exits 0', () async {
    await createProject(failing: false);

    final baseline = await runTestkit(':baseline');
    expect(
      baseline.exitCode,
      0,
      reason: '${baseline.stdout}${baseline.stderr}',
    );

    final run = await runTestkit(':test');
    expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
  }, timeout: const Timeout(Duration(minutes: 4)));
}
