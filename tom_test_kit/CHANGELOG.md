## 1.10.0

### Added — `--coverage` on `:baseline` and `:test`

The run's line coverage: `dart test --coverage-path=coverage/lcov.info`
(package:test 1.27.0 or later; an older one is named and the tests run without
coverage) or `flutter test --coverage --coverage-path=coverage/lcov.info`.
The lcov report is `coverage/lcov.info` in the project (a note when git would
track it); the covered / coverable lines are printed and kept in the run's
column header as `cov:<covered>/<coverable>` (a testkit before 1.10.0 reads it
as part of the comment). `:status` shows the latest measured coverage and the
baseline's, `:runs` a *Line coverage* column, `:history` a *Line coverage*
row. Per project and in workspace mode. TK-COV-1..6;
doc/test_tracking.md, Line Coverage.

## 1.9.2

### Fixed — a test that writes without a trailing newline no longer loses the next result

A test that writes to stdout without a newline (an ESC `[K` erase, a progress
line rewritten after a `\r`) puts that text in front of `dart test`'s next JSON
event on the same line. testkit skipped every line that was not JSON as a
whole, so that event, often the test's own `testDone`, was lost and the
passing test was recorded as `--`. The line is now read from the first `{"`
from which the rest decodes (`decodeJsonEventLine`), in the parser and in the
TUI's baseline and test commands. TK-DTP-26, and TK-DTP-28 on output recorded
from a fixture package. Same-named tests (in two groups, or in two files
without a group) were already told apart in 1.9.0; TK-DTP-27 covers the files
case.

## 1.9.1

### Changed — on tom_build_base 2.27.0 and utopia_tui 2.0

- `tom_build_base: ^2.27.0`: testkit's output piped into something that stops
  reading (`testkit --version | head -1`) ends quietly instead of with an
  uncaught broken-pipe error.
- `utopia_tui: ^2.0.0`: tom_build_base 2.27.0 depends on `tom_dcli`, whose
  `dart_console` ^5.1 the 1.x TUI library (`dart_console` ^4) could not share;
  2.0 has no dependencies. The output panel paints its progress bar with
  `TuiProgressBar.paintSurface` (`TuiProgressBarView` is gone).

## 1.9.0

### Added — baselines for every language testkit can run

testkit runs and tracks the tests of Go, Rust, Python, Java, JavaScript,
TypeScript, C and C++ projects as well as Dart and Flutter packages. A
project's runner (`ProjectTestRunner`) is, in this order: a `testkit:`
section of its `buildkit.yaml` (`command:`, `report:`, `report-path:`), `dart
test` / `flutter test` for a Dart project, the `buildkit.yaml` `test:` step as
a script writing testkit's line protocol (one JSON object per test) to the
file `$TESTKIT_REPORT` names, or the language's runner: `go test -json ./...`,
`cargo test --no-fail-fast`, pytest `--junitxml`, Maven / Gradle surefire
reports, jest `--json`, `node --test` with the JUnit reporter. Readers for the
line protocol, go-json, libtest text, JUnit XML and jest JSON turn each into
result rows; a name reported in two groups is qualified by its group, a Go
package whose build failed and a jest file that did not run are load
failures. `{report}` in a command is the report file, kept as
`testlog/last_testrun_report.*`; the runner's output is
`testlog/last_testrun.txt`. `:baseline`, `:test`, `:runs`, `:status`,
`:basediff`, `:lastdiff`, `:diff`, `:history`, `:flaky`, `:trim` and `:reset`
work on every such nature; `--failed` / `--mismatched` run every test of a
runner other than `dart test`, which alone selects by name. A run whose
command exits with an error although no reported test failed is incomplete
(no baseline is written). Proven on the 18 SOM runtime packages. Tests
TK-RPT-1..9, TK-RCL-1..4, TK-PTR-1..13 on recorded reports. `glob`, `xml`
added.

### Changed

- `DartTestResults` is `TestRunResults` (`lib/src/model/test_run_results.dart`),
  its `rawJsonLines` `rawOutput` with `rawOutputName`; `saveLastTestRunJson`
  is `saveLastTestRunOutput`.
- `dart test` results go through the same collector: two tests of the same
  name in different groups were one tracking-file row (the key is the name
  without its groups) and overwrote each other; each is now keyed
  `<group> > <name>` (TK-DTP-25). tom_som_dart_runtime: 962 rows, was 941.
  Those tests show once as absent under their old key.
- A test name is read as `ID: description` only when spelled so: `a::b` and
  `case:x` keep their colon in the description (they did not survive a
  tracking file's round trip before).

## 1.8.0

### Added — `:fuzz` measures the coverage of a target's libraries

Each target of a campaign now runs in a process of its own. A target that
names coverage libraries (tom_fuzz 0.2.0, `FuzzCampaignTarget(coverage:
[...])`, read with `--describe`) runs under the VM service, paused on exit;
testkit collects their line coverage with package:coverage, prints it in place
of the campaign's `not measured`, and writes `coveredLines` /
`coverableLines` into the report. Worker-isolate hits count, killed workers
included. `--no-coverage` turns it off; a campaign on an older tom_fuzz runs
whole without coverage; a `--target` no campaign has fails the run; a failed
collection stops the paused campaign instead of waiting on it. Tests
TK-FUZ-5..8. `tom_fuzz: ^0.2.0`, `coverage: ^1.16.0`.

## 1.7.0

### Added — `:mutations`, the catalogued mutation sweep

The tom_core_server mutation sweep, made generic: a package's
`tool/mutations.yaml` (same line grammar; the 199 entries of tom_core_server's
catalogue read identically) is checked for drift before anything runs, the
named tests run once unmutated (a red baseline aborts), and each mutation is
applied, run (`flutter test` for a Flutter package) under a time bound that
kills the whole process tree, and restored whatever happens, signals
included. Verdicts killed, killed (hung), survived, invalid (the mutant does
not compile) and skipped (a `requires:` precondition from
`tool/mutation_requirements.yaml` — tcp, env, file or command — is not met).
Report in `testlog/mutations_<MMDD_HHMM>.json` / `.md`, survivors listed with
their behaviour, `--min-killed <percent>` gate, `--list`, module selection,
and an exit code of surviving + invalid (tom_build_base 2.22's per-item exit
code). Tests TK-MUT-1..9. `tom_build_base: >=2.22.1` (repeated `--module` /
`--target` options now reach the command whole).

## 1.6.0

### Added — `:fuzz`, the long fuzz campaign

Runs a package's fuzz campaigns (`fuzz/*_fuzz.dart`, each calling
[tom_fuzz](https://pub.dev/packages/tom_fuzz)'s `fuzzMain`) by iterations or
wall time, with a seed, target and campaign selection and per-input bounds;
reads each campaign's JSON report through tom_fuzz's `FuzzReport`, prints the
totals, writes the combined report with `--report`, and exits 1 when a target
failed or a campaign ended without a report. A package without a campaign is
skipped by name. Documented in `doc/test_tracking.md`; tests TK-FUZ-1..4.
`tom_fuzz: ^0.1.1`.

## 1.5.0

### Changed — one runner choice for every launch, from tom_build_base

`:baseline` and `:test` already ran `flutter test` for a Flutter package, but
the TUI's Test and Baseline commands still launched `dart test`, which cannot
resolve `package:flutter`. All four now launch through `TestRunner`: `flutter
test` for a Flutter package, `dart test` otherwise, through the shell on
Windows for `flutter.bat` as for `dart.bat`. The TUI's phase and exit
messages name the runner. The Flutter check is tom_build_base's
`isFlutterPackage` (2.20.0), the rule its nature detector uses; testkit's own
copy (`package_detection.dart`, `isFlutterPackage` /
`pubspecDeclaresFlutterSdk` exported from `tom_test_kit`) is removed and so is
`DartTestParser.runInShellForHost`. Tests TK-TRN-1..7, two of them running a
real Flutter package. `tom_build_base: >=2.20.0`.

## 1.4.0

### Changed — `:test` and `:baseline` exit 1 when a test failed

A run with a failing test exited 0 (`Done. No errors.`), so a script could not
tell a red suite from a green one by the exit code; only a run that could not
start exited 1. Both commands now exit 1 when any test failed, the convention
`dart test` follows, and name the count on stderr (`[<project>] 1 test
failed.`). The results are still recorded: `:test` appends its column and
`:baseline` writes its file before failing. A test expected to fail (`(FAIL)`)
counts as failed too. An all-green run exits 0, as does a `--failed` /
`--mismatched` run with nothing to re-run.

The help (`:test` / `:baseline` descriptions, an Exit Code footer) and
`doc/test_tracking.md` state it; TK-TST-19..21 and TK-EXIT-1/2 (the real
executable) pin it. TK-TST-3/4/5/7, which ran suites with failing tests and
expected success, now expect the failure.

## 1.3.0

### Fixed — an option written after the command name is no longer ignored

Every testkit option is declared on its commands, so writing one after the
command name — the form `CLAUDE.md` documents (`testkit :test
--test-args="..."`) and testkit's own help prints (`testkit :baseline
--test-args="--tags e2e"`) — routed it into `commandArgs`, which no executor
read. `testkit :baseline --test-args="--name nomatch"` ran the WHOLE suite and
reported on tests the caller never asked about; `-c label` lost the label.
Placed before the command, both worked. So the documented form was the broken
one, and the regression gate reported a false green.

The four option helpers now take the resolved options rather than `CliArgs`,
and each executor resolves its own command's options once with
`CliArgs.optionsFor` (tom_build_base 2.13.0), which merges both positions with
the per-command value winning.

Verified end to end: `testkit :baseline --test-args="--name zzz_nomatch"` now
launches `dart test --reporter json --name zzz_nomatch` and exits 79 having
selected no test, and `:baseline -c label` reaches the CSV column header.

The same defect made `testkit :test --baseline` refuse with the very message
that recommends it ("No tracking file found. Run :baseline first, or use
--baseline to create one."). It now creates the baseline and reports the run.
`test/v2/test_baseline_flag_test.dart` parses real command lines through the
tool definition and drives the executor, in both option positions — the seam
no earlier test crossed, since each called `TestCommand.run` with
`createBaseline` already set.

Requires tom_build_base >=2.13.0.

## 1.2.0

### Fixed — testkit declared it had no dry-run mode, while implementing one

`NavigationFeatures.dryRun` was false, but the baseline, test, trim and reset
executors each return a `[DRY RUN] Would ...` preview instead of writing. The
declaration was wrong.

That became load-bearing in tom_build_base 2.12.0, which refuses `-n` for a
tool declaring `dryRun: false`. With the old declaration, `testkit -n :test`
would have been rejected instead of reporting what it would do.

Requires tom_build_base >=2.12.0.

## 1.1.2

- **A locked package the pub cache cannot supply now stops the run and names
  it** (scd8_aicx). It is not a resolution error: the lock is satisfiable, so
  `dart pub get` reports success, and the failure arrives later as `Error:
  Undefined name '<Symbol>'` at every use site — which points at the file using
  the symbol and reads as an API renamed upstream. `:test` and `:baseline` now
  stat every hosted lock entry before launching the runner
  (`PubCacheIntegrity`, tom_build_base 2.9.0) and stop with the package, the
  path the cache should hold it at, and the repair.
  - `tom_build_base` floor raised to `>=2.9.0`.
  - `BaselineCommand.run` / `TestCommand.run` take `pubCachePath`, so a test
    can point the pre-flight at its own cache.

## 1.1.1

- **A run that measured nothing is no longer a green run** (scd7_aicx).
  `dart test` reports a test file it cannot load — an import that does not
  resolve, a compile error — as a pseudo-test `loading <file>` with result
  `error`, and exits 1, the same code as a run whose tests merely failed.
  The parser discarded those events, so a package whose every test file failed
  to load produced `Tests: 0 (0 passed, 0 failed)`, `:baseline ok`, exit 0 and
  an empty baseline CSV that the next run then diffed against. A file that
  failed to load alongside others vanished the same way.
  - `DartTestParser.parseJsonOutput` records each failed load as a
    `LoadFailure` (file and error text); `DartTestResults` carries it with the
    runner's `exitCode` and exposes `runProblem`, non-null for a run in which
    no test ran or a file failed to load.
  - `:baseline` writes no CSV for such a run, prints why and fails.
  - `:test` records no column for a run in which no test ran; for a partial
    load failure it records the tests that ran, then fails naming the file.
  - A runner that exits before reporting results (a dependency that does not
    resolve, exit 65; no test selected, exit 79) is reported with its exit code
    and the text it printed on stdout as well as stderr, once per line —
    previously only stderr, where exit 79 prints nothing.
  - Failing tests remain results: they are recorded and do not change the exit
    code.

## 1.1.0

- Add Flutter-package support: `:baseline` / `:test` now detect a Flutter
  package (Flutter SDK dependency in `pubspec.yaml`) and run
  `flutter test --reporter json` instead of `dart test --reporter json`. Both
  runners emit the identical package:test JSON protocol, so tracking is
  unchanged. Non-Flutter packages keep using `dart test`.
- `DartTestParser.buildLaunchError` now takes the executable name so launch
  errors name `flutter` vs `dart` (and `flutter.bat` vs `dart.bat` on Windows).

## 1.0.0

- Initial version.
