// TF: the tom_fuzz harness, against parser fixtures whose behaviour is known.
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_fuzz/fuzz_test.dart';
import 'package:tom_fuzz/tom_fuzz.dart';

import 'fixtures/parsers.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

final _keyValueSeeds = Corpus([
  CorpusEntry('a', _b('alpha=1\nbeta=2\n')),
  CorpusEntry('b', _b('name=tom\n')),
]);

void main() {
  late Directory tmp;

  setUp(() {
    final base = Directory(p.join(Directory.current.path, '.dart_tool'))
      ..createSync(recursive: true);
    tmp = base.createTempSync('tom_fuzz_test_');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  const broken = FuzzTarget(
    'key_value',
    brokenKeyValue,
    rejects: rejectsFormat,
  );

  test('TF-1: the planted bug of a broken parser is found', () async {
    final report = await Fuzzer(
      broken,
      corpus: _keyValueSeeds,
    ).run(iterations: 3000, seed: 1);
    expect(report.inputsRun, 3000);
    final failure = report.failures.single;
    expect(failure.kind, FailureKind.crash);
    expect(failure.errorType, 'StateError');
    expect(failure.stackTrace, contains('brokenKeyValue'));
    expect(
      utf8.decode(failure.input, allowMalformed: true),
      contains('\u0000'),
    );
    expect(report.rejected, greaterThan(0), reason: 'declared rejections');
  });

  test('TF-2: a parser that only rejects the declared way is clean', () async {
    final report = await Fuzzer(
      const FuzzTarget('json', jsonTarget, rejects: rejectsFormat),
      corpus: Corpus([
        CorpusEntry('doc', _b('{"a":[1,2,{"b":"c"}],"d":null}')),
      ]),
      mutators: const [ByteMutator(), JsonMutator()],
    ).run(iterations: 400, seed: 7);
    expect(report.clean, isTrue, reason: report.toText());
    expect(report.accepted + report.rejected, 400);
    expect(report.accepted, greaterThan(0));
  });

  test(
    'TF-3: a run that does not finish is caught and the run goes on',
    () async {
      final report = await Fuzzer(
        const FuzzTarget('hang', hangsOnX, rejects: rejectsFormat),
        corpus: Corpus([CorpusEntry('x', _b('x')), CorpusEntry('y', _b('y'))]),
        timeout: const Duration(milliseconds: 300),
      ).run(iterations: 20, seed: 3);
      final timeouts = report.failures.where(
        (f) => f.kind == FailureKind.timeout,
      );
      expect(timeouts, isNotEmpty);
      expect(timeouts.first.iteration, 0, reason: 'the seed `x` hangs');
      expect(report.inputsRun, 20, reason: 'the worker is started again');
      expect(report.rejected, greaterThan(0));
    },
  );

  test(
    'TF-4: a saved failure replays, and as a seed it is a regression case',
    () async {
      final failures = p.join(tmp.path, 'corpus', 'failures');
      final report = await Fuzzer(
        broken,
        corpus: _keyValueSeeds,
        failureDirectory: failures,
      ).run(iterations: 3000, seed: 1);
      final saved = report.failures.single.savedAs!;
      expect(File(saved).existsSync(), isTrue);
      final description =
          jsonDecode(
                File(
                  saved.replaceFirst('.input', kFailureSuffix),
                ).readAsStringSync(),
              )
              as Map;
      expect(description['seed'], 1);
      expect(description['errorType'], 'StateError');
      expect(description['stackTrace'], contains('brokenKeyValue'));

      final replayed = await Fuzzer(broken).replay(saved);
      expect(replayed, isA<Broke>());
      expect((replayed as Broke).failure.errorType, 'StateError');

      // The saved input sits in the corpus folder: the next run starts with it.
      final again = await Fuzzer(
        broken,
        corpus: Corpus.directory(p.join(tmp.path, 'corpus')),
      ).run(iterations: 1, seed: 99);
      expect(again.failures.single.iteration, 0);
    },
  );

  test('TF-5: the same seed gives the same run', () async {
    Future<FuzzReport> run(int seed) =>
        Fuzzer(broken, corpus: _keyValueSeeds).run(iterations: 500, seed: seed);
    final a = await run(42), b = await run(42);
    expect(b.accepted, a.accepted);
    expect(b.rejected, a.rejected);
    expect(
      b.failures.map((f) => f.signature),
      a.failures.map((f) => f.signature),
    );
    expect(b.failures.map((f) => f.input), a.failures.map((f) => f.input));
  });

  test('TF-6: memory growth past the bound is a failure', () async {
    final report = await Fuzzer(
      const FuzzTarget('hoard', hoardsMemory, rejects: rejectsFormat),
      corpus: Corpus([CorpusEntry('one', _b('1'))]),
      memoryLimitBytes: 32 * 1024 * 1024,
      timeout: const Duration(seconds: 10),
    ).run(iterations: 2, seed: 1);
    expect(report.failures.single.kind, FailureKind.memory);
  });

  group('mutators', () {
    final random = Random(5);

    test('TF-7: JSON mutation keeps JSON and changes it; non-JSON is left', () {
      final input = _b('{"a":[1,2,3],"b":{"c":"d"}}');
      final outputs = [
        for (var i = 0; i < 50; i++)
          const JsonMutator().mutate(input, random, const [])!,
      ];
      for (final o in outputs) {
        jsonDecode(utf8.decode(o)); // still JSON
      }
      expect(
        outputs.where((o) => utf8.decode(o) != utf8.decode(input)),
        isNotEmpty,
      );
      expect(const JsonMutator().mutate(_b('<a/>'), random, const []), isNull);
    });

    test('TF-8: XML mutation works on elements; text without one is left', () {
      final input = _b('<r><a x="1">t</a><b/></r>');
      final outputs = {
        for (var i = 0; i < 50; i++)
          utf8.decode(const XmlMutator().mutate(input, random, const [])!),
      };
      expect(outputs.length, greaterThan(5));
      expect(
        const XmlMutator().mutate(_b('{"a":1}'), random, const []),
        isNull,
      );
    });

    test('TF-13: JSON that cannot be encoded again is left, not thrown', () {
      // `1e309` decodes to Infinity, which jsonEncode refuses.
      for (var i = 0; i < 50; i++) {
        expect(
          const JsonMutator().mutate(
            _b('[1e309, {"a": 1e309}]'),
            random,
            const [],
          ),
          isNull,
        );
      }
    });

    test('TF-9: byte mutation always yields bytes, even from empty', () {
      for (var i = 0; i < 200; i++) {
        expect(
          const ByteMutator().mutate(Uint8List(0), random, [_b('seed')]),
          isNotNull,
        );
      }
    });
  });

  test('TF-14: a mutator that throws does not end the run', () async {
    final report = await Fuzzer(
      const FuzzTarget('json', jsonTarget, rejects: rejectsFormat),
      corpus: Corpus([CorpusEntry('doc', _b('[1]'))]),
      mutators: const [_ThrowingMutator(), ByteMutator()],
    ).run(iterations: 200, seed: 2);
    expect(report.inputsRun, 200);
    expect(report.clean, isTrue, reason: report.toText());
  });

  test(
    'TF-10: a text target sees malformed UTF-8 decoded, not a crash',
    () async {
      final seen = await Fuzzer(
        FuzzTarget.text('text', _textTarget, rejects: rejectsFormat),
      ).runInput(Uint8List.fromList([0xFF, 0xFE, 0x41]));
      expect(seen, isA<Accepted>());
    },
  );

  test(
    'TF-11: the campaign runs from the command line and writes a report',
    () async {
      final report = p.join(tmp.path, 'report.json');
      final result = await Process.run('dart', [
        'run',
        'test/fixtures/campaign.dart',
        '--iterations',
        '3000',
        '--seed',
        '1',
        '--failures',
        p.join(tmp.path, 'failures'),
        '--report',
        report,
      ]);
      expect(result.exitCode, 1, reason: '${result.stdout}${result.stderr}');
      expect('${result.stdout}', contains('key_value: 1 failure(s)'));
      expect('${result.stdout}', contains('json: clean'));
      final reports = [
        for (final r in jsonDecode(File(report).readAsStringSync()) as List)
          FuzzReport.fromJson((r as Map).cast()),
      ];
      expect(reports.map((r) => r.target), ['key_value', 'json']);
      expect(reports.first.failures.single.savedAs, isNotNull);

      final listed = await Process.run('dart', [
        'run',
        'test/fixtures/campaign.dart',
        '--list',
      ]);
      expect('${listed.stdout}'.trim().split('\n'), ['key_value', 'json']);
    },
  );

  // The short mode as it sits in a unit suite.
  fuzzTest(
    'TF-12: fuzzTest runs a fixed-seed run as a test',
    const FuzzTarget('json', jsonTarget, rejects: rejectsFormat),
    corpusDirectory: p.join('test', 'fixtures', 'corpus', 'json'),
    mutators: const [ByteMutator(), JsonMutator()],
    iterations: 200,
  );
}

void _textTarget(String input) {
  if (!input.contains('�')) throw StateError('not decoded leniently');
}

class _ThrowingMutator implements Mutator {
  const _ThrowingMutator();

  @override
  String get name => 'throws';

  @override
  Uint8List? mutate(Uint8List input, Random random, List<Uint8List> corpus) =>
      throw StateError('a broken mutator');
}
