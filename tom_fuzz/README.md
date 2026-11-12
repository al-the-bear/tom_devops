# Tom Fuzz

A fuzzing harness for Dart parsers of untrusted input: SAML and XML documents,
JWT and JWKS, JSON imports, filter languages, anything a server reads from
outside. Dart has no standard fuzzer; this one is small and sits in an ordinary
`dart test` suite.

- **Targets:** a function taking bytes (or text), plus the errors that count as
  the parser's declared rejection.
- **Corpus:** seed inputs from a folder, mutated at byte level (bit flips,
  interesting values, insert/delete/duplicate ranges, splicing) and at
  structure level through pluggable mutators (JSON and XML included).
- **Findings:** any other error, a run that does not finish within the time
  bound (the worker isolate is killed and started again), and resident-memory
  growth past a bound.
- **Reproducible:** every run has a seed; each failure is saved as the input
  plus a description (seed, iteration, error, stack trace), replaying it is one
  call, and a saved input in the corpus folder is run first on every run, so a
  failure becomes a regression case.
- **Two modes:** a short fixed-seed run in the unit suite (`fuzzTest`), and a
  long campaign by iterations or wall time, started by a person, ending with a
  report.

## Install

```yaml
dev_dependencies:
  tom_fuzz: ^0.1.0
```

## A target

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:tom_fuzz/tom_fuzz.dart';

/// Top-level: targets run in a worker isolate.
void semverTarget(Uint8List input) =>
    parseVersion(utf8.decode(input, allowMalformed: true));

const semver = FuzzTarget(
  'semver',
  semverTarget,
  rejects: rejectsFormatException, // the parser's declared rejection
);
```

`FuzzTarget.text` hands the parser a string instead (malformed UTF-8 decoded
leniently), and `rejectsAny<A, B, C>` accepts several rejection types.

## In the unit suite

```dart
import 'package:tom_fuzz/fuzz_test.dart';

void main() {
  fuzzTest('semver survives fuzzing', semver, iterations: 300, seed: 1);
}
```

The test runs the seeds in `fuzz/corpus/semver/` and 300 mutations of them with
seed 1 — the same inputs on every run, in well under a second for most parsers —
and fails with the report when an input breaks the target. Failures are saved
under `.dart_tool/tom_fuzz/failures/`; copy a saved `.input` into the corpus
folder to keep it as a regression case.

## A campaign

A campaign file `fuzz/<name>_fuzz.dart` lists the package's targets:

```dart
Future<void> main(List<String> args) => fuzzMain(args, [
  FuzzCampaignTarget(semver, coverage: ['package:my_app/src/semver.dart']),
  FuzzCampaignTarget(
    samlResponse,
    mutators: [ByteMutator(), XmlMutator()],
    coverage: ['package:my_app/src/saml/'],
  ),
]);
```

`coverage:` names the libraries whose line coverage the report gives, as URI prefixes (a folder or one library).

Run it from the package root, by hand:

```text
dart run fuzz/parsers_fuzz.dart --duration 600          # ten minutes per target
dart run fuzz/parsers_fuzz.dart --iterations 1000000 --seed 42 --target semver
testkit :fuzz --duration 600                             # every campaign file of the package
```

| Option | Meaning |
| --- | --- |
| `--iterations N`, `--duration S` | Stop after N inputs or S seconds per target (default 100000 inputs) |
| `--seed N` | The seed of the mutations (default from the clock; the report names it) |
| `--target NAME` | Only these targets |
| `--timeout-ms MS`, `--memory-mb MB` | Bounds per input (2000 ms, 512 MB) |
| `--failures DIR` | Where failures are saved (default `fuzz/corpus/<target>/failures/`, replayed by the next run) |
| `--report FILE` | Write the reports as JSON |
| `--list` | List the targets |
| `--describe` | Print the targets and their coverage libraries as JSON (what testkit reads) |

The report gives the inputs run, how many were accepted and rejected, and each
distinct failure with its saved input:

```text
key_value: 1 failure(s) — 3000 inputs (accepted 1638, rejected 1298) in 0.2 s, seed 1
  coverage: not measured
  crash: StateError: Bad state: NUL in key reached the map (x64) -> fuzz/corpus/key_value/failures/key_value-caf1bfce.input
```

The campaign exits 1 when a target failed.

**Coverage.** tom_fuzz itself does not measure coverage, so a campaign run
directly reports `coverage: not measured`. `testkit :fuzz` runs each target of
a campaign in its own process under the VM service and fills in the line
coverage of the libraries the target names:

```text
semver: clean — 20000 inputs (accepted 2448, rejected 17552) in 0.6 s, seed 7
  coverage: 92.3 % (12/13 lines) of package:my_app/src/semver.dart
```

The figure counts the lines the VM can record (calls and function entries); a
line holding only `return 1;` has no coverable position and does not count.

## Replaying a failure

```dart
final outcome = await Fuzzer(semver).replay('fuzz/corpus/semver/failures/semver-1a2b3c4d.input');
// Accepted, Rejected or Broke(failure) — Broke until the bug is fixed.
```

## Structure mutators

A `Mutator` returns a mutated copy of an input, or null when it does not apply.
`JsonMutator` decodes JSON and replaces, removes, duplicates or deeply nests a
node; `XmlMutator` removes, duplicates or nests an element or adds hostile
content (entities, a DOCTYPE, unbalanced tags). Write your own for other
formats and pass it in `mutators:`.

## Limits

- Targets run in a worker isolate: they must be top-level or static functions,
  or closures over sendable state.
- The memory bound reads the process's resident memory around an input, so it
  is approximate; it catches inputs that make a parser allocate far beyond
  their size.
- Run campaigns by hand from the repository; nothing here is scheduled.

## License

BSD 3-Clause; see `LICENSE`.
