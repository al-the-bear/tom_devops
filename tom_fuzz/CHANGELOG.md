## 0.1.0

First release: a fuzzing harness for Dart parsers of untrusted input.

- `FuzzTarget` (bytes or text) with a declared rejection (`rejectsFormatException`, `rejectsAny`).
- `Corpus` from a folder; saved failures in it replay first on every run.
- `ByteMutator`, `JsonMutator`, `XmlMutator`, and the `Mutator` interface for others.
- `Fuzzer`: seeded runs by iterations or wall time in a worker isolate, with a
  per-input time bound (the worker is killed and restarted) and a resident-memory
  bound; distinct failures saved as input plus description; `replay`.
- `fuzzTest` (`package:tom_fuzz/fuzz_test.dart`): the short fixed-seed run as a test.
- `fuzzMain`: the entry of a campaign file, with a text and JSON report; testkit's
  `:fuzz` command runs campaign files.
