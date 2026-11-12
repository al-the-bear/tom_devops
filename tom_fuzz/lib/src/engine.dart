import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'corpus.dart';
import 'mutators.dart';
import 'target.dart';

/// How an input broke the target.
enum FailureKind {
  /// An error other than the declared rejection.
  crash,

  /// The run did not finish within the time bound; the worker was killed.
  timeout,

  /// The run grew the process's resident memory past the bound.
  memory,
}

/// One input that broke the target, with what is needed to reproduce it.
class FuzzFailure {
  /// How it broke.
  final FailureKind kind;

  /// The input.
  final Uint8List input;

  /// The run's seed and the iteration that produced the input (0 for a seed
  /// replayed as it is).
  final int seed;

  /// The iteration that produced [input].
  final int iteration;

  /// The error's type (`timeout` / `memory` for those kinds).
  final String errorType;

  /// The error's text.
  final String error;

  /// The stack trace, empty for a timeout.
  final String stackTrace;

  /// How often an input broke the target the same way during the run.
  final int occurrences;

  /// Where [save] wrote the input, once it has.
  final String? savedAs;

  /// Creates a failure.
  FuzzFailure({
    required this.kind,
    required this.input,
    required this.seed,
    required this.iteration,
    required this.errorType,
    required this.error,
    required this.stackTrace,
    this.occurrences = 1,
    this.savedAs,
  });

  /// What makes two failures the same: kind, error type and the first frame
  /// of the trace.
  String get signature {
    final frame = stackTrace
        .split('\n')
        .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    return '${kind.name}|$errorType|${frame.trim()}';
  }

  /// A short stable id for file names.
  String get id {
    var h = 0x811c9dc5;
    for (final c in [...utf8.encode(signature), ...input.take(4096)]) {
      h = ((h ^ c) * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  FuzzFailure _with({int? occurrences, String? savedAs}) => FuzzFailure(
    kind: kind,
    input: input,
    seed: seed,
    iteration: iteration,
    errorType: errorType,
    error: error,
    stackTrace: stackTrace,
    occurrences: occurrences ?? this.occurrences,
    savedAs: savedAs ?? this.savedAs,
  );

  /// Writes the input as `<target>-<id>.input` into [directory] and its
  /// description beside it (`.failure.json`: kind, seed, iteration, error,
  /// stack trace). Returns the failure with [savedAs] set.
  FuzzFailure save(String directory, String target) {
    Directory(directory).createSync(recursive: true);
    final base = p.join(directory, '$target-$id');
    File('$base.input').writeAsBytesSync(input);
    File('$base$kFailureSuffix').writeAsStringSync(
      const JsonEncoder.withIndent(
        '  ',
      ).convert({...toJson(), 'input': '$target-$id.input'}),
    );
    return _with(savedAs: '$base.input');
  }

  /// The failure as JSON (without the input bytes).
  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'seed': seed,
    'iteration': iteration,
    'errorType': errorType,
    'error': error,
    'stackTrace': stackTrace,
    'occurrences': occurrences,
    'inputLength': input.length,
    'savedAs': ?savedAs,
  };

  /// Reads [toJson] back; the input is empty unless [input] is given.
  factory FuzzFailure.fromJson(Map<String, Object?> json, [Uint8List? input]) =>
      FuzzFailure(
        kind: FailureKind.values.byName(json['kind'] as String),
        input: input ?? Uint8List(0),
        seed: json['seed'] as int,
        iteration: json['iteration'] as int,
        errorType: json['errorType'] as String,
        error: json['error'] as String,
        stackTrace: json['stackTrace'] as String,
        occurrences: json['occurrences'] as int? ?? 1,
        savedAs: json['savedAs'] as String?,
      );

  @override
  String toString() =>
      '${kind.name}: $errorType: ${error.split('\n').first}'
      '${occurrences > 1 ? ' (x$occurrences)' : ''}'
      '${savedAs == null ? '' : ' -> $savedAs'}';
}

/// What a run did.
class FuzzReport {
  /// The target's name.
  final String target;

  /// The seed the run's mutations came from.
  final int seed;

  /// Inputs run, seeds included.
  final int inputsRun;

  /// Inputs the target accepted.
  final int accepted;

  /// Inputs the target rejected the declared way.
  final int rejected;

  /// How long the run took.
  final Duration elapsed;

  /// The distinct failures, first input of each kept.
  final List<FuzzFailure> failures;

  /// The libraries whose line coverage the report gives: URI prefixes
  /// (`package:my_app/src/saml/`), as the campaign target names them.
  final List<String> coverageLibraries;

  /// Lines of [coverageLibraries] the run reached, when coverage was
  /// measured. tom_fuzz does not measure it itself: testkit's `:fuzz` runs the
  /// campaign under the VM service and fills this in.
  final int? coveredLines;

  /// Lines of [coverageLibraries] that can be covered, when measured.
  final int? coverableLines;

  /// Creates a report.
  FuzzReport({
    required this.target,
    required this.seed,
    required this.inputsRun,
    required this.accepted,
    required this.rejected,
    required this.elapsed,
    required this.failures,
    this.coverageLibraries = const [],
    this.coveredLines,
    this.coverableLines,
  });

  /// Covered / coverable lines (0..1), or null when not measured.
  double? get coverage =>
      coveredLines == null || coverableLines == null || coverableLines == 0
      ? null
      : coveredLines! / coverableLines!;

  /// This report with its coverage measured.
  FuzzReport withCoverage({required int covered, required int coverable}) =>
      FuzzReport(
        target: target,
        seed: seed,
        inputsRun: inputsRun,
        accepted: accepted,
        rejected: rejected,
        elapsed: elapsed,
        failures: failures,
        coverageLibraries: coverageLibraries,
        coveredLines: covered,
        coverableLines: coverable,
      );

  /// The coverage line of [toText]: the figure, or why there is none.
  String get coverageText {
    if (coverage != null) {
      return '${(coverage! * 100).toStringAsFixed(1)} % '
          '($coveredLines/$coverableLines lines) of '
          '${coverageLibraries.join(', ')}';
    }
    if (coverableLines == 0) {
      return 'not measured: no coverable line in '
          '${coverageLibraries.join(', ')}';
    }
    return coverageLibraries.isEmpty
        ? 'not measured (the target names no library)'
        : 'not measured (run it through testkit :fuzz)';
  }

  /// No failure.
  bool get clean => failures.isEmpty;

  /// The report as JSON.
  Map<String, Object?> toJson() => {
    'target': target,
    'seed': seed,
    'inputsRun': inputsRun,
    'accepted': accepted,
    'rejected': rejected,
    'elapsedMs': elapsed.inMilliseconds,
    'coverage': coverage,
    'coverageLibraries': coverageLibraries,
    'coveredLines': coveredLines,
    'coverableLines': coverableLines,
    'failures': [for (final f in failures) f.toJson()],
  };

  /// Reads [toJson] back.
  factory FuzzReport.fromJson(Map<String, Object?> json) => FuzzReport(
    target: json['target'] as String,
    seed: json['seed'] as int,
    inputsRun: json['inputsRun'] as int,
    accepted: json['accepted'] as int,
    rejected: json['rejected'] as int,
    elapsed: Duration(milliseconds: json['elapsedMs'] as int),
    coverageLibraries: [
      for (final l in (json['coverageLibraries'] as List?) ?? const []) '$l',
    ],
    coveredLines: json['coveredLines'] as int?,
    coverableLines: json['coverableLines'] as int?,
    failures: [
      for (final f in json['failures'] as List)
        FuzzFailure.fromJson((f as Map).cast<String, Object?>()),
    ],
  );

  /// A human-readable summary.
  String toText() {
    final b = StringBuffer()
      ..writeln(
        '$target: ${clean ? 'clean' : '${failures.length} failure(s)'} — '
        '$inputsRun inputs (accepted $accepted, rejected $rejected) in '
        '${(elapsed.inMilliseconds / 1000).toStringAsFixed(1)} s, seed $seed',
      )
      ..writeln('  coverage: $coverageText');
    for (final f in failures) {
      b.writeln('  $f');
    }
    return b.toString().trimRight();
  }
}

/// The outcome of one input.
sealed class FuzzOutcome {
  const FuzzOutcome();
}

/// The target accepted the input.
class Accepted extends FuzzOutcome {
  /// Creates the outcome.
  const Accepted();
}

/// The target rejected the input the declared way.
class Rejected extends FuzzOutcome {
  /// The rejection's type.
  final String errorType;

  /// Creates the outcome.
  const Rejected(this.errorType);
}

/// The input broke the target.
class Broke extends FuzzOutcome {
  /// The failure (seed and iteration as the caller gave them).
  final FuzzFailure failure;

  /// Creates the outcome.
  const Broke(this.failure);
}

/// Runs a [FuzzTarget] over a corpus and its mutations.
class Fuzzer {
  /// The target.
  final FuzzTarget target;

  /// The seeds.
  final Corpus corpus;

  /// The mutators; [ByteMutator] alone by default.
  final List<Mutator> mutators;

  /// How long one input may run before the worker is killed.
  final Duration timeout;

  /// How much one input may grow the process's resident memory.
  final int memoryLimitBytes;

  /// Where failures are saved (none when null).
  final String? failureDirectory;

  /// Creates a fuzzer.
  Fuzzer(
    this.target, {
    Corpus? corpus,
    this.mutators = const [ByteMutator()],
    this.timeout = const Duration(seconds: 2),
    this.memoryLimitBytes = 512 * 1024 * 1024,
    this.failureDirectory,
  }) : corpus = corpus ?? Corpus(const []);

  /// Runs every seed as it is, then mutations, until [iterations] inputs
  /// were run or [duration] passed (whichever comes first; at least one must
  /// be given). The same [seed], corpus and mutators give the same inputs.
  Future<FuzzReport> run({
    int? iterations,
    Duration? duration,
    int? seed,
  }) async {
    if (iterations == null && duration == null) {
      throw ArgumentError('give iterations, duration or both');
    }
    final runSeed = seed ?? DateTime.now().microsecondsSinceEpoch & 0x7FFFFFFF;
    final random = Random(runSeed);
    final stopwatch = Stopwatch()..start();
    final seeds = [for (final e in corpus.entries) e.bytes];
    final failures = <String, FuzzFailure>{};
    var run = 0, accepted = 0, rejected = 0;
    final worker = _Worker(target, memoryLimitBytes);
    bool more() =>
        (iterations == null || run < iterations) &&
        (duration == null || stopwatch.elapsed < duration);
    try {
      var nextSeed = 0;
      while (more()) {
        final Uint8List input;
        if (nextSeed < seeds.length) {
          input = seeds[nextSeed++];
        } else {
          input = _mutate(
            seeds.isEmpty ? Uint8List(0) : seeds[random.nextInt(seeds.length)],
            random,
            seeds,
          );
        }
        final outcome = await worker.run(input, timeout, runSeed, run);
        run++;
        switch (outcome) {
          case Accepted():
            accepted++;
          case Rejected():
            rejected++;
          case Broke(:final failure):
            final known = failures[failure.signature];
            failures[failure.signature] = known == null
                ? failure
                : known._with(occurrences: known.occurrences + 1);
        }
      }
    } finally {
      worker.close();
    }
    var list = failures.values.toList();
    if (failureDirectory != null) {
      list = [for (final f in list) f.save(failureDirectory!, target.name)];
    }
    return FuzzReport(
      target: target.name,
      seed: runSeed,
      inputsRun: run,
      accepted: accepted,
      rejected: rejected,
      elapsed: stopwatch.elapsed,
      failures: list,
    );
  }

  Uint8List _mutate(Uint8List start, Random random, List<Uint8List> seeds) {
    var current = start;
    final rounds = 1 + random.nextInt(4);
    for (var i = 0; i < rounds; i++) {
      Uint8List? next;
      for (
        var tries = 0;
        tries < mutators.length * 2 && next == null;
        tries++
      ) {
        final mutator = mutators[random.nextInt(mutators.length)];
        try {
          next = mutator.mutate(current, random, seeds);
        } catch (_) {
          // A mutator that breaks on an input does not apply to it; the
          // run goes on with another.
          next = null;
        }
      }
      current = next ?? const ByteMutator().mutate(current, random, seeds)!;
    }
    return current;
  }

  /// Runs one [input] (a saved failure's, say) and tells what happened.
  Future<FuzzOutcome> runInput(Uint8List input) async {
    final worker = _Worker(target, memoryLimitBytes);
    try {
      return await worker.run(input, timeout, 0, 0);
    } finally {
      worker.close();
    }
  }

  /// Replays the input saved at [path] (a `.input` file, or its
  /// `.failure.json`) and tells what happens now.
  Future<FuzzOutcome> replay(String path) {
    final input = path.endsWith(kFailureSuffix)
        ? '${path.substring(0, path.length - kFailureSuffix.length)}.input'
        : path;
    return runInput(File(input).readAsBytesSync());
  }
}

/// A worker isolate running the target one input at a time; killed and
/// started again after a timeout.
class _Worker {
  final FuzzTarget target;
  final int memoryLimit;
  Isolate? _isolate;
  SendPort? _send;
  ReceivePort? _receive;
  StreamIterator<Object?>? _replies;

  _Worker(this.target, this.memoryLimit);

  Future<void> _start() async {
    final receive = ReceivePort();
    _receive = receive;
    _replies = StreamIterator(receive);
    _isolate = await Isolate.spawn(_workerMain, (
      receive.sendPort,
      target,
      memoryLimit,
    ), errorsAreFatal: false);
    await _replies!.moveNext();
    _send = _replies!.current as SendPort;
  }

  Future<FuzzOutcome> run(
    Uint8List input,
    Duration timeout,
    int seed,
    int iteration,
  ) async {
    if (_isolate == null) await _start();
    _send!.send(input);
    final bool got;
    try {
      got = await _replies!.moveNext().timeout(timeout);
    } on TimeoutException {
      close();
      return Broke(
        FuzzFailure(
          kind: FailureKind.timeout,
          input: input,
          seed: seed,
          iteration: iteration,
          errorType: 'timeout',
          error: 'no result within ${timeout.inMilliseconds} ms',
          stackTrace: '',
        ),
      );
    }
    if (!got) {
      close();
      throw StateError('the fuzz worker isolate ended unexpectedly');
    }
    final reply = _replies!.current as List;
    return switch (reply[0] as String) {
      'ok' => const Accepted(),
      'rejected' => Rejected(reply[1] as String),
      final kind => Broke(
        FuzzFailure(
          kind: kind == 'memory' ? FailureKind.memory : FailureKind.crash,
          input: input,
          seed: seed,
          iteration: iteration,
          errorType: reply[1] as String,
          error: reply[2] as String,
          stackTrace: reply[3] as String,
        ),
      ),
    };
  }

  void close() {
    _isolate?.kill(priority: Isolate.immediate);
    _receive?.close();
    _isolate = null;
    _send = null;
    _receive = null;
    _replies = null;
  }
}

Future<void> _workerMain((SendPort, FuzzTarget, int) message) async {
  final (reply, target, memoryLimit) = message;
  final inbox = ReceivePort();
  reply.send(inbox.sendPort);
  await for (final input in inbox) {
    final before = ProcessInfo.currentRss;
    try {
      await target.run(input as Uint8List);
      final growth = ProcessInfo.currentRss - before;
      reply.send(
        growth > memoryLimit
            ? [
                'memory',
                'memory',
                'resident memory grew by ${growth ~/ (1024 * 1024)} MB '
                    '(bound ${memoryLimit ~/ (1024 * 1024)} MB)',
                '',
              ]
            : ['ok'],
      );
    } catch (error, stack) {
      if (error is OutOfMemoryError) {
        reply.send(['memory', 'OutOfMemoryError', '$error', '$stack']);
      } else if (target.rejects(error)) {
        reply.send(['rejected', error.runtimeType.toString()]);
      } else {
        reply.send(['crash', error.runtimeType.toString(), '$error', '$stack']);
      }
    }
  }
}
