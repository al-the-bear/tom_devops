/// The short, fixed-seed fuzz run as an ordinary `package:test` test.
library;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'tom_fuzz.dart';

/// Registers a test running [target] over [corpusDirectory] (default
/// `fuzz/corpus/<target name>`) and [iterations] mutations with a fixed
/// [seed], failing with the report when an input breaks it.
///
/// Failures are saved under `.dart_tool/tom_fuzz/failures/` (or
/// [failureDirectory]); move a saved input into the corpus folder to keep it
/// as a regression case.
void fuzzTest(
  String description,
  FuzzTarget target, {
  int iterations = 300,
  int seed = 1,
  String? corpusDirectory,
  List<Mutator> mutators = const [ByteMutator()],
  Duration inputTimeout = const Duration(seconds: 2),
  String? failureDirectory,
  Timeout? timeout,
}) {
  test(description, () async {
    final report = await Fuzzer(
      target,
      corpus: Corpus.directory(
        corpusDirectory ?? p.join('fuzz', 'corpus', target.name),
      ),
      mutators: mutators,
      timeout: inputTimeout,
      failureDirectory:
          failureDirectory ?? p.join('.dart_tool', 'tom_fuzz', 'failures'),
    ).run(iterations: iterations, seed: seed);
    if (!report.clean) fail(report.toText());
  }, timeout: timeout ?? const Timeout(Duration(minutes: 2)));
}
