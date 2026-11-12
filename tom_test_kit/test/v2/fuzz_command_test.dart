@Timeout(Duration(minutes: 4))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

/// Test IDs: TK-FUZ-1 through TK-FUZ-4
///
/// `testkit :fuzz` runs a package's fuzz campaigns (tom_fuzz, ccla5) and
/// fails when a target failed. Run through the real executable on a temporary
/// package that takes tom_fuzz from pub.dev.
void main() {
  final testkit = p.join(Directory.current.path, 'bin', 'testkit.dart');
  late Directory project;

  const campaign = r'''
import 'dart:convert';
import 'dart:typed_data';

import 'package:tom_fuzz/tom_fuzz.dart';

/// Crashes on a NUL byte, rejects lines without `=`.
void keyValue(Uint8List input) {
  final text = utf8.decode(input, allowMalformed: true);
  for (final line in const LineSplitter().convert(text)) {
    if (line.isEmpty) continue;
    if (line.indexOf('=') <= 0) throw FormatException('no key', line);
    if (line.contains('\u0000')) throw StateError('NUL');
  }
}

void json(Uint8List input) => jsonDecode(utf8.decode(input));

Future<void> main(List<String> args) => fuzzMain(args, [
  FuzzCampaignTarget(
    FuzzTarget('key_value', keyValue, rejects: rejectsFormatException),
  ),
  FuzzCampaignTarget(
    FuzzTarget('json', json, rejects: rejectsFormatException),
    mutators: const [ByteMutator(), JsonMutator()],
  ),
]);
''';

  Future<void> createProject({required bool withCampaign}) async {
    File(p.join(project.path, 'pubspec.yaml')).writeAsStringSync('''
name: fuzz_probe
version: 0.0.1
environment:
  sdk: ^3.10.0
dev_dependencies:
  tom_fuzz: ^0.1.1
''');
    Directory(p.join(project.path, 'lib')).createSync();
    if (withCampaign) {
      final corpus = p.join(project.path, 'fuzz', 'corpus');
      Directory(p.join(corpus, 'key_value')).createSync(recursive: true);
      Directory(p.join(corpus, 'json')).createSync(recursive: true);
      File(
        p.join(corpus, 'key_value', 'a.txt'),
      ).writeAsStringSync('a=1\nb=2\n');
      File(p.join(corpus, 'json', 'a.json')).writeAsStringSync('{"a":[1,2]}');
      File(
        p.join(project.path, 'fuzz', 'parsers_fuzz.dart'),
      ).writeAsStringSync(campaign);
    }
    final got = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: project.path);
    if (got.exitCode != 0) throw StateError('pub get: ${got.stderr}');
  }

  Future<ProcessResult> fuzz(List<String> args) => Process.run('dart', [
    'run',
    testkit,
    ':fuzz',
    ...args,
  ], workingDirectory: project.path);

  setUp(() => project = Directory.systemTemp.createTempSync('tk_fuzz_'));
  tearDown(() => project.deleteSync(recursive: true));

  test(
    'TK-FUZ-1: a failing target fails the run and its input is saved',
    () async {
      await createProject(withCampaign: true);
      final r = await fuzz(['--iterations', '3000', '--seed', '1']);
      final out = '${r.stdout}${r.stderr}';
      expect(r.exitCode, 1, reason: out);
      expect(out, contains('key_value: 1 failure(s)'));
      expect(out, contains('json: clean'));
      final failures = Directory(
        p.join(project.path, 'fuzz', 'corpus', 'key_value', 'failures'),
      );
      expect(
        failures.listSync().map((f) => p.extension(f.path)),
        containsAll(['.input', '.json']),
      );
    },
  );

  test(
    'TK-FUZ-2: a clean run exits 0 and writes the combined report',
    () async {
      await createProject(withCampaign: true);
      final report = p.join(project.path, 'out', 'fuzz.json');
      final r = await fuzz([
        '--iterations',
        '300',
        '--seed',
        '1',
        '--target',
        'json',
        '--report',
        report,
      ]);
      expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
      final reports = jsonDecode(File(report).readAsStringSync()) as List;
      expect(reports.single['target'], 'json');
      expect(reports.single['inputsRun'], 300);
    },
  );

  test('TK-FUZ-3: a project without a campaign is skipped by name', () async {
    await createProject(withCampaign: false);
    final r = await fuzz(const []);
    expect(r.exitCode, 0, reason: '${r.stdout}${r.stderr}');
    expect('${r.stdout}', contains('no fuzz campaign'));
  });

  test('TK-FUZ-4: the limits become fuzzMain arguments', () {
    expect(
      FuzzCommand.campaignArgs(
        iterations: 10,
        durationSeconds: 5,
        seed: 3,
        targets: ['a', 'b'],
        timeoutMs: 100,
        memoryMb: 64,
      ),
      [
        '--iterations', '10', '--duration', '5', '--seed', '3', //
        '--target', 'a', '--target', 'b', //
        '--timeout-ms', '100', '--memory-mb', '64',
      ],
    );
    expect(FuzzCommand.campaignArgs(), isEmpty);
  });
}
