// Every test sweeps a real package: `dart test` runs once per mutation.
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

/// Test IDs: TK-MUT-1 through TK-MUT-10
///
/// The catalogued mutation sweep (`testkit :mutations`, ccla6) on a fixture
/// package whose tests pin some behaviours and not others.
const _calc = r'''
int add(int a, int b) => a + b;

int clampPositive(int x) => x < 0 ? 0 : x;

String greet(String name) => 'hi $name';

int countdown(int n) {
  var steps = 0;
  while (n > 0) {
    n--;
    steps++;
  }
  return steps;
}
''';

const _calcTest = '''
import 'package:calc/calc.dart';
import 'package:test/test.dart';

void main() {
  test('add', () => expect(add(2, 3), 5));
  test('clamp', () => expect(clampPositive(-4), 0));
  test('countdown', () => expect(countdown(3), 3));
}
''';

const _killed = '''
  - behaviour: add adds
    file: lib/calc.dart
    find: "a + b"
    replace: "a - b"
    tests: test/calc_test.dart
''';

const _survives = r'''
  - behaviour: greet says hi
    file: lib/calc.dart
    find: "'hi $name'"
    replace: "'bye $name'"
    tests: test/calc_test.dart
''';

const _invalid = '''
  - behaviour: a mutant that is not Dart
    file: lib/calc.dart
    find: "int add(int a, int b)"
    replace: "int add(int a, int b"
    tests: test/calc_test.dart
''';

void main() {
  late Directory project;
  final lines = <String>[];

  setUp(() async {
    lines.clear();
    final base = Directory(p.join(Directory.current.path, '.dart_tool'))
      ..createSync(recursive: true);
    project = base.createTempSync('tk_mutations_');
    void write(String path, String text) => File(p.join(project.path, path))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(text);
    write('pubspec.yaml', '''
name: calc
environment:
  sdk: ^3.0.0
dev_dependencies:
  test: ^1.24.0
''');
    write('lib/calc.dart', _calc);
    write('test/calc_test.dart', _calcTest);
    final got = await Process.run('dart', [
      'pub',
      'get',
      '--offline',
    ], workingDirectory: project.path);
    if (got.exitCode != 0) {
      final online = await Process.run('dart', [
        'pub',
        'get',
      ], workingDirectory: project.path);
      if (online.exitCode != 0) fail('pub get: ${online.stderr}');
    }
  });
  tearDown(() => project.deleteSync(recursive: true));

  void catalogue(String body, {String? requirements}) {
    File(p.join(project.path, 'tool', 'mutations.yaml'))
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('math:\n$body');
    if (requirements != null) {
      File(
        p.join(project.path, 'tool', 'mutation_requirements.yaml'),
      ).writeAsStringSync(requirements);
    }
  }

  Future<MutationsOutcome> sweep({
    List<String> modules = const [],
    double? minKilled,
    Duration? timeout,
    bool list = false,
  }) => MutationsCommand.run(
    projectPath: project.path,
    modules: modules,
    minKilled: minKilled,
    timeout: timeout,
    listOnly: list,
    log: lines.add,
  );

  String calcNow() =>
      File(p.join(project.path, 'lib', 'calc.dart')).readAsStringSync();

  test('TK-MUT-1: killed, surviving and invalid mutants, the file restored, '
      'the report written', () async {
    catalogue('$_killed$_survives$_invalid');
    final outcome = await sweep();
    final r = outcome.result!;
    expect(r.outcomes.map((o) => o.verdict), [
      MutationVerdict.killed,
      MutationVerdict.survived,
      MutationVerdict.invalid,
    ]);
    expect(outcome.passed, isFalse);
    expect(outcome.exitCode, 2, reason: 'surviving + invalid');
    expect(calcNow(), _calc, reason: 'the file is restored');
    expect(lines.join('\n'), contains('survived -- math: greet says hi'));

    final reports = Directory(
      p.join(project.path, 'testlog'),
    ).listSync().map((f) => p.basename(f.path)).toList();
    final json = reports.singleWhere((n) => n.endsWith('.json'));
    expect(reports, contains(json.replaceFirst('.json', '.md')));
    final data =
        jsonDecode(
              File(p.join(project.path, 'testlog', json)).readAsStringSync(),
            )
            as Map;
    expect(data['modules']['math']['survived'], 1);
    expect(data['killRate'], closeTo(33.3, 0.1));
  });

  test(
    'TK-MUT-2: a drifted `find` stops the sweep before anything runs',
    () async {
      catalogue('''
$_killed
  - behaviour: a behaviour that moved
    file: lib/calc.dart
    find: "return steps * 2;"
    replace: "return 0;"
    tests: test/calc_test.dart
''');
      final outcome = await sweep();
      expect(outcome.passed, isFalse);
      expect(outcome.exitCode, 1);
      expect(outcome.result!.error, contains('a behaviour that moved'));
      expect(outcome.result!.error, contains('matches 0 times'));
      expect(outcome.result!.outcomes, isEmpty);
      expect(lines.join('\n'), isNot(contains('baseline:')));
    },
  );

  test(
    'TK-MUT-3: a red baseline aborts: it would call every mutation killed',
    () async {
      catalogue(_survives);
      File(p.join(project.path, 'test', 'calc_test.dart')).writeAsStringSync(
        _calcTest.replaceFirst('expect(add(2, 3), 5)', 'expect(add(2, 3), 6)'),
      );
      final outcome = await sweep();
      expect(outcome.passed, isFalse);
      expect(outcome.result!.error, contains('red before any mutation'));
      expect(outcome.result!.outcomes, isEmpty);
    },
  );

  test('TK-MUT-4: an entry whose precondition is missing is skipped, not '
      'reported surviving', () async {
    final closed = await ServerSocket.bind('127.0.0.1', 0);
    final port = closed.port;
    await closed.close();
    catalogue(
      '$_killed${_survives.replaceFirst('    tests:', '    requires: db\n    tests:')}',
      requirements: 'db:\n  description: a database\n  tcp: 127.0.0.1:$port\n',
    );
    final outcome = await sweep();
    final r = outcome.result!;
    expect(r.outcomes.map((o) => o.verdict), [
      MutationVerdict.killed,
      MutationVerdict.skipped,
    ]);
    expect(r.outcomes.last.reason, contains('nothing listens'));
    expect(outcome.passed, isTrue, reason: 'the skipped entry is no survivor');
  });

  test('TK-MUT-5: a `requires:` nobody declared is an error', () async {
    catalogue(
      _survives.replaceFirst('    tests:', '    requires: queue\n    tests:'),
    );
    final outcome = await sweep();
    expect(outcome.result!.error, contains('`queue`'));
    expect(outcome.exitCode, 1);
  });

  test('TK-MUT-6: --min-killed passes the gate at the threshold', () async {
    catalogue('$_killed$_survives');
    final low = await sweep(minKilled: 50);
    expect(low.passed, isTrue, reason: low.message);
    final high = await sweep(minKilled: 60);
    expect(high.passed, isFalse);
    expect(high.exitCode, 1, reason: 'surviving + invalid');
  });

  test('TK-MUT-7: a run past the time bound is killed (hung) and the file '
      'restored', () async {
    catalogue('''
  - behaviour: countdown terminates
    file: lib/calc.dart
    find: "    n--;"
    replace: "    n += 0;"
    tests: test/calc_test.dart
''');
    // The bound covers the unmutated baseline too, so it must leave that
    // room under a loaded machine; the mutant loops for ever either way.
    final outcome = await sweep(timeout: const Duration(seconds: 20));
    expect(outcome.result!.error, isNull, reason: lines.join('\n'));
    expect(outcome.result!.outcomes.single.verdict, MutationVerdict.hung);
    expect(outcome.passed, isTrue, reason: 'a hang is the suite noticing');
    expect(calcNow(), _calc);
  });

  test('TK-MUT-8: --list names the entries and runs nothing', () async {
    catalogue('$_killed$_survives');
    final outcome = await sweep(list: true);
    expect(outcome.passed, isTrue);
    expect(
      lines,
      containsAll(['math (2)', '    add adds', '    greet says hi']),
    );
    expect(Directory(p.join(project.path, 'testlog')).existsSync(), isFalse);
  });

  test(
    'TK-MUT-9: the testkit process exits with surviving + invalid',
    () async {
      catalogue('$_killed$_survives$_invalid');
      final r = await Process.run('dart', [
        'run',
        p.join(Directory.current.path, 'bin', 'testkit.dart'),
        ':mutations',
      ], workingDirectory: project.path);
      expect(r.exitCode, 2, reason: '${r.stdout}${r.stderr}');
    },
  );

  test('TK-MUT-10: the catalogue is read line by line, as the tom_core '
      'script reads it', () {
    final c = MutationCatalogue.parse(r'''
# a comment
cache:
  - behaviour: a read: then a write keeps both
    file: lib/a.dart
    find: "  if (x) {\n    y();\t// \"z\""
    replace:
    tests: test/a_test.dart   test/b_test.dart
    requires: db queue

endpoints:
  - behaviour: plain
    file: lib/b.dart
    find: return 1;
    replace: return 2;
    tests: test/b_test.dart
''');
    final a = c.modules['cache']!.single;
    expect(a.behaviour, 'a read: then a write keeps both');
    expect(a.find, '  if (x) {\n    y();\t// "z"');
    expect(a.replace, '');
    expect(a.tests, ['test/a_test.dart', 'test/b_test.dart']);
    expect(a.requires, ['db', 'queue']);
    expect(c.modules.keys, ['cache', 'endpoints']);
    expect(c.modules['endpoints']!.single.find, 'return 1;');
    expect(
      () => MutationCatalogue.parse('  - behaviour: orphan\n'),
      throwsA(isA<MutationConfigError>()),
    );
  });
}
