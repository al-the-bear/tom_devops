## 0.2.0

### Added — line coverage of the libraries a target names

`FuzzCampaignTarget(coverage: ['package:my_app/src/saml/'])` names the
libraries whose line coverage the campaign report gives; `fuzzMain --describe`
prints the targets with them as JSON. `FuzzReport` carries
`coverageLibraries`, `coveredLines` and `coverableLines` (with `coverage` as
their ratio and `withCoverage`), replacing the bare `coverage` number, which
was never set. tom_fuzz does not measure coverage itself; testkit's `:fuzz`
runs each target under the VM service and fills it in. Tests TF-15, TF-16.

## 0.1.1

### Fixed — a mutator can no longer end a run

`JsonMutator` threw when the tree it had built could not be encoded again (a
byte mutation had turned a number into `1e309`, which decodes to Infinity) or
was nested deeper than the decoder recurses, and the exception ended the whole
campaign without a report. It now leaves such inputs to other mutators, and the
fuzzer treats any mutator that throws as not applying to that input. Tests
TF-13, TF-14.

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
