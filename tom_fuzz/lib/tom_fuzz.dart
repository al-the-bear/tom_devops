/// A fuzzing harness for Dart parsers of untrusted input.
///
/// Define a [FuzzTarget], run it with a [Fuzzer] (or `fuzzTest` from
/// `package:tom_fuzz/fuzz_test.dart` in the unit suite), and start long
/// campaigns from a `fuzz/<name>_fuzz.dart` file whose `main` calls
/// [fuzzMain] — testkit's `:fuzz` command runs them.
library;

export 'src/cli.dart';
export 'src/corpus.dart';
export 'src/engine.dart';
export 'src/mutators.dart';
export 'src/target.dart';
