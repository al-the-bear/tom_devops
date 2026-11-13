# Test Tracking — Concept and Workflow

This document defines the test tracking concept supported by Tom Test Kit's `testkit` CLI. It describes the test-code-fix cycle, test description conventions, and how each command supports the workflow.

---

## Table of Contents

1. [Overview](#overview)
2. [Test Description Convention](#test-description-convention)
3. [The Test-Code-Fix Cycle](#the-test-code-fix-cycle)
4. [Tracking File](#tracking-file)
5. [Command Reference (Quick)](#command-reference-quick)
6. [Full Command Reference](#full-command-reference)
7. [Flutter Packages](#flutter-packages)
8. [Line Coverage](#line-coverage)
9. [Exit Code](#exit-code)
10. [Other Languages](#other-languages)

---

## Overview

`testkit` provides automated test result tracking across multiple runs of `dart test` (`flutter test` for Flutter packages, see [Flutter Packages](#flutter-packages); the other languages' runners, see [Other Languages](#other-languages)). It captures structured JSON test output, parses test descriptions for metadata (IDs, creation dates, expected outcomes), and maintains a persistent CSV tracking file that shows how test results evolve over time.

The core idea is that test descriptions carry structured metadata that enables:

- **Identification** — Each test has a unique ID for cross-referencing
- **Expectation management** — Tests declare whether they are expected to pass or fail
- **Temporal tracking** — Creation dates enable sorting and age analysis
- **Regression detection** — Comparing runs reveals new failures vs. known issues

---

## Test Description Convention

Test descriptions follow a structured naming convention:

```dart
test('I-BUG-14a: Records with named fields should return native record [2026-02-10 08:00] (FAIL)', () {
  // test code
});
```

### Format

```
<ID>: <description> [<creation date>] (<expected result>)
```

| Component | Required | Format | Description |
|-----------|----------|--------|-------------|
| ID | Optional | `PREFIX-CATEGORY-number` | Unique test identifier |
| Description | Required | Free text | What the test validates |
| Creation date | Optional | `YYYY-MM-DD HH:MM` | When the test was created |
| Expected result | Optional | `PASS` or `FAIL` | Expected outcome; defaults to `PASS` if absent |

### ID Conventions

Projects define their own ID prefixes and categories. Common patterns:

- `I-BUG-n` — Interpreter bugs
- `G-CB-n` — Generator callback tests
- `T-REG-n` — Regression tests

The tool does not enforce ID formats — it extracts whatever text precedes the first colon as the ID.

### Expected Result

The expected result in parentheses at the end of the description tells the tracker whether a failure is expected:

- `(PASS)` or absent — Test is expected to succeed
- `(FAIL)` — Test is a known limitation or open bug; failure is expected

This distinction is critical for sorting and reporting: an unexpected failure (expected PASS but got FAIL) is a **regression** and ranks higher in the output than an expected failure.

---

## The Test-Code-Fix Cycle

The test-code-fix cycle is the core development workflow that testkit supports.

### Phase 1: Establish Baseline

Before starting work, capture the current state of all tests. This creates a reference point for measuring progress.

```bash
testkit :baseline                       # Run dart test, create baseline file
testkit :baseline -c "before refactor"  # With a comment label
```

### Phase 2: Write Code / Write Tests

Make changes to the codebase — implement features, fix bugs, add tests. New tests should follow the test description convention with creation dates and expected outcomes.

### Phase 3: Run Tests and Track

After changes, run tests and append results to the tracking file. Each run adds a column so you can see how results change over time.

```bash
testkit :test                           # Run dart test, append results column
testkit :test -c "fixed parser bug"     # Run with comment label
```

### Phase 4: Analyze Results

Use the analysis commands to understand what changed:

```bash
testkit :status                         # Quick summary: counts, regressions, fixes
testkit :basediff                       # What changed since baseline?
testkit :lastdiff                       # What changed since the previous run?
testkit :history TK-RUN-5               # How did a specific test evolve?
testkit :flaky                          # Which tests are non-deterministic?
```

### Phase 5: Fix and Iterate

Fix regressions and bugs, then repeat Phase 3–4 until satisfied.

### Phase 6: Manage Tracking Files

When the tracking file grows too large, trim old runs. When starting a new development cycle, reset and create a fresh baseline.

```bash
testkit :trim 5                         # Keep only last 5 runs + baseline
testkit :reset                          # Delete all tracking files, start fresh
```

### Phase 7: Generate Reports

Generate reports for documentation or code review:

```bash
testkit :basediff --report=progress.md           # Markdown report (baseline → latest)
testkit :lastdiff --full --report=lastdiff.md    # With error details
testkit :basediff --output csv:results.csv       # Export as CSV
```

---

## Tracking File

### File Location and Naming

Tracking files are stored in the project's `testlog/` directory — a folder next
to `doc/` that is **fully gitignored**. Test artifacts are never versioned;
`doc/` holds hand-authored documentation only.

- **Baseline CSV:** `testlog/baseline_<MMDD_HHMM>.csv`
- **Raw JSON output:** `testlog/last_testrun.json` (overwritten each run)

When multiple baseline files exist, testkit automatically uses the most recent one (sorted alphabetically by filename, which orders by timestamp). You can override this with `--baseline-file=<path>`.

### CSV Format

The tracking file is a CSV with metadata rows and a data grid:

```
ID,Groups,Description,Creation Date,Suite,Expectation,Baseline [02-10 14:30],[02-10 15:45],[02-11 09:00]
TK-1,parser,parses JSON,2026-02-10 08:00,test/parser_test.dart,OK,OK/OK,OK/OK,X/OK
TK-2,,known limitation,2026-02-10 08:00,test/edge_test.dart,X,X/X,X/X,X/X
```

Each column after the metadata columns represents a test run. The first run column is the baseline.

### Result Format

Each result cell uses the format: `<result>/<expectation>`

| Value | Meaning |
|-------|---------|
| `OK` | Test passed |
| `X` | Test failed |
| `-` | Test was skipped |
| `--` | Test was not present in this run |

| Expectation | Source | Meaning |
|-------------|--------|---------|
| `OK` | No annotation or `(PASS)` | Test is expected to pass |
| `X` | `(FAIL)` in description | Test is a known failure |

### Result/Expectation Combinations

| Cell | Interpretation |
|------|----------------|
| `OK/OK` | Passed as expected — healthy |
| `X/OK` | Failed unexpectedly — **regression** |
| `X/X` | Failed as expected — known issue |
| `OK/X` | Passed unexpectedly — **progress** (bug may be fixed) |
| `-/OK` | Skipped — needs attention |
| `-/X` | Skipped known failure — acceptable |
| `--/OK` | Not present in this run |

### Sorting Order

Rows in the tracking file are sorted by priority based on the **latest run**:

1. **Failed (unexpected)** — `X/OK` — Regressions come first
2. **Failed (expected)** — `X/X` — Known issues
3. **Passed (unexpected)** — `OK/X` — Potential fixes to verify
4. **Passed (expected)** — `OK/OK` — Healthy tests
5. **Skipped** — `-/*` — Last
6. **Absent** — `--/*` — Not present

Within each group, tests are sorted by creation date (oldest first). Tests without a creation date sort after dated tests.

### Column Timestamps

Run column headers use the compact format `MM-DD HH:MM`:

```
Baseline [02-10 14:30],[02-10 15:45],[02-11 09:00]
```

Comments, if provided via `-c`, appear in the column header. A run measured with `--coverage` carries its line coverage there too, before the comment: `[11-13 22:00] cov:1234/1520 after fix` (see [Line Coverage](#line-coverage)).

---

## Command Reference (Quick)

| Command | Description |
|---------|-------------|
| `:baseline` | Run `dart test`, create a new baseline tracking file |
| `:test` | Run `dart test`, append results to the existing tracking file |
| `:runs` | List all run timestamps in the tracking file |
| `:status` | Quick summary: pass/fail counts, regressions, fixes |
| `:basediff` | Diff baseline vs latest run |
| `:lastdiff` | Diff previous run vs latest run |
| `:diff <ts> [<ts2>]` | Diff two arbitrary runs by timestamp |
| `:history <search>` | Show all results for a test across runs |
| `:flaky` | List tests with inconsistent results across runs |
| `:crossreference` | Map tests to source files (aliases: `:crossref`, `:xref`) |
| `:trim <n>` | Remove old runs, keeping last N (baseline always preserved) |
| `:reset` | Delete all tracking files in testlog/ |
| `:fuzz` | Run the package's fuzz campaigns (`fuzz/*_fuzz.dart`, tom_fuzz); exits 1 when a target failed |
| `:mutations` | Catalogued mutation sweep (`tool/mutations.yaml`): killed / survived / invalid, report and `--min-killed` gate |

All commands support project traversal options for multi-project operation. Run `testkit help` for the overview or `testkit help <command>` for per-command details.

---

## Full Command Reference

### :baseline

Creates a new baseline tracking file by running `dart test` and capturing all test results. This becomes the reference point for comparing future test runs.

**Process:**
1. Checks that the pub cache can supply every package the project has locked,
   and stops naming them if it cannot (see below)
2. Runs `dart test --reporter json` to capture structured output
3. Saves raw JSON to `testlog/last_testrun.json`
4. Parses test descriptions for IDs, creation dates, and expected outcomes
5. Creates `testlog/baseline_<MMDD_HHMM>.csv` with metadata columns and one result column
6. Sorts tests by the standard sorting order

**A locked package the pub cache cannot supply stops the run.** It is not a
resolution error — `dart pub get` reports success, because the lock is
satisfiable — so without this check it arrives as `Undefined name` at every use
site and reads as an API renamed upstream. testkit stats every hosted lock entry
first and names what is missing, with the path and the repair.

**A run that measured nothing writes no baseline.** If no test ran, or a test
file failed to load (an import that does not resolve, a compile error), the
command writes no CSV, prints why — the files that failed to load with the
runner's error, or the exit code and the text `dart test` printed — and exits
non-zero. A baseline is what every later run is compared with; one that is
empty, or silently missing a file's tests, would carry that loss into every
comparison after it. The raw output is still saved to `testlog/last_testrun.json`.

**A failing test is recorded and fails the command.** The baseline is written
with the failing test as `X`, and the command exits 1 (see
[Exit Code](#exit-code)).

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --comment=<text>` | Short label shown in the baseline column header |
| `--file=<path>` | Output file path (overrides default `testlog/baseline_<ts>.csv`) |
| `--coverage` | Measure line coverage: `coverage/lcov.info`, and the percentage in the column header ([Line Coverage](#line-coverage)) |
| `--test-args=<args>` | Additional arguments passed to `dart test` |

**Examples:**
```bash
testkit :baseline                            # Baseline current project
testkit :baseline -c "v2.0 release"          # Baseline with comment
testkit :baseline --test-args="--tags e2e"   # Only include e2e tests
testkit :baseline -r                         # Baseline all subprojects
```

---

### :test

Runs `dart test` and appends a new result column to the most recent tracking file.

**Process:**
1. Finds the most recent `baseline_*.csv` file in the project's `testlog/` directory
2. Checks that the pub cache can supply every package the project has locked
3. Runs `dart test --reporter json` to capture structured output
4. Saves raw JSON to `testlog/last_testrun.json`
5. Parses results and appends a new column with timestamp header
6. New tests (not in the tracking file) are added as new rows
7. Missing tests (in tracking file but not in run) are marked as absent (`--`)
8. Re-sorts rows by the standard sorting order based on the latest results

**Runs that cannot be trusted fail.** A run in which no test ran records no
column and exits non-zero. A run in which a test file failed to load records
the tests that did run — their results are real — then names the file that did
not load and exits non-zero, so its missing tests are never mistaken for a
smaller suite. A failing test is recorded as `X`, and the command exits 1, as
`dart test` does (see [Exit Code](#exit-code)).

**Options:**

| Option | Description |
|--------|-------------|
| `-c, --comment=<text>` | Short label shown in the run column header |
| `--file=<path>` | Tracking file to update (instead of most recent) |
| `--baseline` | Create baseline if no tracking file exists |
| `--no-update` | Run tests and print summary without updating baseline |
| `--coverage` | Measure line coverage: `coverage/lcov.info`, and the percentage in the run's column header ([Line Coverage](#line-coverage)) |
| `--test-args=<args>` | Additional arguments passed to `dart test` |

**Test args:** Arguments are passed through to `dart test`. testkit always adds `--reporter json` internally. Forbidden args (will be rejected): `--reporter`, `--file-reporter`, `--pause-after-load`, `--debug`.

Common dart test options:

| dart test option | Description |
|------------------|-------------|
| `-n, --name=<regex>` | Filter tests by name (regex) |
| `-N, --plain-name=<text>` | Filter tests by plain-text name |
| `-t, --tags=<tags>` | Run only tests with specified tags |
| `-x, --exclude-tags=<tags>` | Exclude tests with specified tags |
| `--fail-fast` | Stop after first failure |
| `--timeout=<duration>` | Test timeout (e.g. `15s`, `2x`, `none`) |

**Examples:**
```bash
testkit :test                                # Append run to latest baseline
testkit :test -c "after refactor"            # Run with comment
testkit :test --baseline                     # Create baseline if missing
testkit :test --test-args="--name parser"    # Only run parser tests
testkit :test --no-update                    # Run tests, show summary without updating
```

---

### :runs

Lists all run timestamps in the tracking file. Use these timestamps with `:diff`.

**Output columns:** `#` (index), Timestamp, Type (baseline/run), Comment

**Options:**

| Option | Description |
|--------|-------------|
| `--output=<spec>` | Output format: `plain`, `csv`, `json`, `md` or `<format>:<filename>` |

**Example output:**
```
Runs in baseline_0210_1430.csv

#  Timestamp    Type      Comment
-  -----------  --------  ----------------
1  02-10 14:30  baseline  initial
2  02-10 15:45  run       after refactor
3  02-11 09:00  run       fixed parser bug
```

---

### :status

Shows a quick summary of the current tracking state without running tests.

**Output includes:**
- File path and number of runs
- Total tests, pass/fail/skip/absent counts from the latest run
- Regressions and fixes since baseline (if ≥2 runs exist)
- Regressions and fixes since the previous run (if ≥2 runs exist)

A regression is a test that was OK in the older run but X in the newer run. A fix is the reverse.

**Example output:**
```
  File: testlog/baseline_0210_1430.csv
  Runs: 3
  Tests: 87 (82 passed, 3 failed, 2 skipped)

  Since baseline:
    Regressions: 1
    Fixes:       4

  Since last run:
    Regressions: 0
    Fixes:       2
```

---

### :basediff

Shows all tests that changed between the baseline (first run) and the latest run. Useful for seeing overall progress since tracking began.

**Process:**
1. Loads the tracking file
2. Computes differences between the first and last run columns
3. Sorts by priority: regressions first, then other changes, then fixes
4. Outputs a table with change labels

**Options:**

| Option | Description |
|--------|-------------|
| `--output=<spec>` | Output format: `plain`, `csv`, `json`, `md` or `<format>:<filename>` |
| `--full` | Include error messages and stack traces from `last_testrun.json` |
| `--report=<file>` | Generate a detailed Markdown report (mutually exclusive with `--output`) |

**Change labels:**

| Label | Meaning |
|-------|---------|
| `REGRESSION` | Was passing, now failing |
| `FIXED` | Was failing, now passing |
| `REMOVED` | Test no longer present |
| `NEW` | Test appeared since baseline |
| `- → OK`, `OK → -`, etc. | Other status changes |

**Examples:**
```bash
testkit :basediff                            # Show changes since baseline
testkit :basediff --full                     # Include error details
testkit :basediff --report=progress.md       # Write Markdown report
testkit :basediff --output csv:changes.csv   # Export as CSV
```

---

### :lastdiff

Shows all tests that changed between the second-to-last run and the most recent run. Useful for seeing what changed in the last test cycle.

Same options and output format as `:basediff`. Requires at least 2 runs.

**Examples:**
```bash
testkit :lastdiff                        # Changes since previous run
testkit :lastdiff --full                 # Include error details
testkit :lastdiff --output md            # Output as Markdown
```

---

### :diff

Compares two arbitrary runs by timestamp. Use `:runs` to see available timestamps.

**Usage:**
```
testkit :diff <timestamp>              # Compare that run vs latest
testkit :diff <timestamp1> <timestamp2>  # Compare two specific runs
```

**Timestamp formats:** `MM-DD_HHMM`, `MM-DD HH:MM`. These match the timestamps shown by `:runs`.

Same options as `:basediff` (`--output`, `--full`, `--report`).

**Examples:**
```bash
testkit :diff 02-10_1430                     # Compare 02-10 14:30 vs latest
testkit :diff 02-10_1430 02-11_0900          # Compare two specific runs
testkit :diff "02-10 14:30" --full           # With error details
```

---

### :history

Shows all results for one or more tests across all runs, making it easy to track regressions and fixes over time.

**Usage:**
```
testkit :history <search>
```

The search term is matched case-insensitively against:
- **Test ID** (e.g., `TK-RUN-5`) — an exact ID match returns only that test
- **Test description** text
- **Group path**
- **Full test path** (groups + description combined)

If multiple tests match, all are shown in the same table.

**Options:**

| Option | Description |
|--------|-------------|
| `--output=<spec>` | Output format: `plain`, `csv`, `json`, `md` or `<format>:<filename>` |

**Example output:**
```
History: test A

Test          B 02-10 14:30  02-11 10:00  02-12 16:45
------------  -------------  -----------  -----------
TK-A: test A  OK/OK          X/OK         OK/OK
```

**Examples:**
```bash
testkit :history TK-RUN-5                # By exact test ID
testkit :history "parse JSON"            # By description substring
testkit :history parser                  # All tests matching "parser"
testkit :history TK-RUN --output csv     # Export as CSV
```

---

### :flaky

Lists tests with inconsistent results across runs — tests that sometimes pass and sometimes fail. Useful for identifying non-deterministic or environment-sensitive tests.

Requires at least 2 runs. Only considers OK and X results (skip and absent are ignored for flakiness).

**Output columns:** ID, Description, Pass count, Fail count, Flips, Fail Rate%

A **flip** is a transition between OK and X in consecutive runs (e.g., OK→X or X→OK). More flips indicate higher flakiness. Tests are sorted by flip count (most flaky first).

**Options:**

| Option | Description |
|--------|-------------|
| `--output=<spec>` | Output format: `plain`, `csv`, `json`, `md` or `<format>:<filename>` |

**Examples:**
```bash
testkit :flaky                           # Show flaky tests
testkit :flaky --output json             # Export as JSON
testkit :flaky -r                        # Check all subprojects
```

---

### :crossreference

Maps each test in the tracking file to its source file and line number. Useful for navigating from tracking results back to code.

**Aliases:** `:crossref`, `:xref`

**Process:** Searches the source file (recorded during test execution as the test suite path) for the test description string to find the line number.

**Output columns:** ID, Group, Description, Source File, Line, Link

**Options:**

| Option | Description |
|--------|-------------|
| `--output=<spec>` | Output format: `plain`, `csv`, `json`, `md` or `<format>:<filename>` |

**Examples:**
```bash
testkit :crossreference                  # Map tests to source
testkit :xref --output csv:xref.csv      # Export as CSV
testkit :crossref --output md:xref.md    # Export as Markdown
```

---

### :trim

Removes old run columns from the tracking file, keeping only the last N runs. The baseline (first run) is **always preserved** regardless of N.

**Usage:**
```
testkit :trim <n>
```

Where `<n>` is the number of most recent runs to keep. The baseline is always included, so the file will contain baseline + last N-1 non-baseline runs (= N total columns). Runs in between are removed. Prompts for confirmation unless `--force` is used.

**Options:**

| Option | Description |
|--------|-------------|
| `--force` | Skip the confirmation prompt |

**Examples:**
```bash
testkit :trim 5                          # Keep baseline + last 4 runs
testkit :trim 3 --force                  # Trim without confirmation
testkit :trim 10 -r                      # Trim all subprojects
```

---

### :reset

Deletes all tracking files from the project's `testlog/` directory. This removes all `baseline_*.csv` files and `last_testrun.json`. Other files in `testlog/` are preserved. Prompts for confirmation unless `--force` is used.

**Options:**

| Option | Description |
|--------|-------------|
| `--force` | Skip the confirmation prompt |

**Examples:**
```bash
testkit :reset                           # Delete with confirmation
testkit :reset --force                   # Delete without prompt
testkit :reset -r                        # Reset all subprojects
```

---

### :fuzz

Runs the package's fuzz campaigns: every `fuzz/*_fuzz.dart` file, each a `main` calling
[tom_fuzz](https://pub.dev/packages/tom_fuzz)'s `fuzzMain` with the package's fuzz targets. Each campaign runs as
`dart run <file>` in the package and shows its own report as it runs; testkit reads the reports back, prints the totals
and exits 1 when a target failed, or a campaign ended without a report. A package without a campaign file is skipped
by name.

The short, fixed-seed run belongs in the unit suite instead (tom_fuzz's `fuzzTest`); `:fuzz` is the long campaign a
person starts.

**Options:**

| Option | Description |
|--------|-------------|
| `-n, --iterations=<count>` | Inputs per target (default 100000 without `--duration`) |
| `-d, --duration=<seconds>` | Seconds per target |
| `--seed=<n>` | Seed of the mutations (default from the clock; each report names its seed) |
| `-t, --target=<name>` | Only these targets |
| `--campaign=<name>` | Only campaign files whose name contains this |
| `--timeout-ms=<ms>`, `--memory-mb=<mb>` | Bounds per input (2000 ms, 512 MB) |
| `--report=<path>` | Write all reports as one JSON list |
| `--no-coverage` | Do not measure coverage (no VM service) |

Failures are saved as the input plus a description (seed, iteration, error, stack trace) under
`fuzz/corpus/<target>/failures/`, where the next run replays them first.

**Coverage.** Each target runs in a process of its own. A target that names coverage libraries
(`FuzzCampaignTarget(..., coverage: ['package:my_app/src/saml/'])`, tom_fuzz 0.2.0) runs under the VM service, paused on
exit; testkit collects the line coverage of those libraries (package:coverage) before letting it go, and the report
gives it (`coverage: 85.7 % (6/7 lines) of package:my_app/src/saml/`, and `coveredLines` / `coverableLines` in the
JSON). Hits from the fuzzer's worker isolates count, killed ones included. Only lines the VM records (calls, function
entries) count. A target that names no library, a campaign on an older tom_fuzz (no `--describe`; it runs whole) or
`--no-coverage` reports `not measured`.

**Examples:**
```bash
testkit :fuzz --duration 600                         # ten minutes per target
testkit :fuzz --iterations 1000000 --seed 42 --target saml_response
testkit :fuzz --report ztmp/fuzz_report.json         # gate evidence
```

---

### :mutations

A catalogued mutation sweep (alias `:mutate`): break each recorded behaviour of the package on purpose and see whether
the tests that name it notice. A test that *names* a behaviour is not one that *pins* it; a mutation the named tests
still pass is a behaviour the suite does not test.

**The catalogue** is committed in the package, `tool/mutations.yaml` by default. Module, then one entry per behaviour:
the smallest `find`/`replace` edit that removes the promise, and the test files that must fail.

```yaml
cache:
  - behaviour: a read promotes the entry to most-recently-used
    file: lib/src/cache/server_cache.dart
    find: "        if (_first != entry) {"
    replace: "        if (false) {"
    tests: test/cache_test.dart test/cache_lru_test.dart
    requires: db
```

The file is read line by line, not as YAML: an unindented `name:` starts a module, `- ` an entry, every other line is
`key: value` split at the first `: ` (so an unquoted value may contain `: `); a double-quoted value has its escapes
decoded (`\n`, `\t`, `\"`); `tests` and `requires` are space-separated.

**Preconditions.** A behaviour covered only by tests that self-skip without a database or a service names it in
`requires:`; the package declares each in `tool/mutation_requirements.yaml`, with one check:

```yaml
db:
  description: the MariaDB the db-tagged suites need
  tcp: 127.0.0.1:3309        # or env: NAME, file: path, command: shell line (exit 0 within 10 s)
```

An entry whose precondition is not met is **skipped**, not run: its suites would self-skip, pass, and report the
mutation as surviving. A `requires:` the file does not declare stops the sweep.

**What the sweep does, in order:**

1. Every `find` of the selected modules must occur in its file exactly once; every drifted entry is named, and nothing
   runs until the catalogue is fixed.
2. The named tests run once unmutated (`dart test -j 1`, `flutter test` for a Flutter package). A red baseline stops
   the sweep: a red suite would call every mutation killed.
3. Each entry: the edit is applied, its tests run, and the file is restored whatever happens, a timeout, an error,
   SIGINT and SIGTERM included. A run past `--timeout` is stopped with its whole process tree (the test VMs `dart test`
   started) and counts as **killed (hung)**: the suite noticed.
4. Verdicts: **killed** (the tests failed), **survived** (they passed), **invalid** (the mutant does not compile: it
   fails every test without asking anything of them, so the entry has to be rewritten), **skipped**.

**The report** is written to `testlog/mutations_<MMDD_HHMM>.json` and `.md`: killed, survived, invalid and skipped per
module, the kill rate (killed / run), and every survivor and invalid mutant with its behaviour; the survivors are also
printed with their edit.

**Exit code and gate.** Without `--min-killed` every survivor and invalid mutant fails the run, and the exit code is
their number (1 when the sweep stopped early; capped at 125). With `--min-killed <percent>` the run passes when the kill
rate reaches the threshold, and fails when no mutation ran (NOT MEASURED).

**Options:**

| Option | Description |
|--------|-------------|
| `<module> ...`, `--module=<name>` | Modules to sweep (default all) |
| `--list` | List the selected entries and run nothing |
| `--min-killed=<percent>` | Pass when at least this percentage of the mutations run was killed |
| `--timeout=<seconds>` | Time bound of one test run (default 600) |
| `--catalogue=<path>`, `--requirements=<path>` | Other files than `tool/mutations.yaml` / `tool/mutation_requirements.yaml` |
| `--report=<path>` | Report path without extension (default `testlog/mutations_<MMDD_HHMM>`) |

**Examples:**
```bash
testkit :mutations --list
testkit :mutations cache endpoints
testkit :mutations --min-killed 80          # the gate: at least 80 % killed
```

Run it by hand from the repository; a sweep runs the named tests once per mutation, so a large catalogue takes a while.

---

## Flutter Packages

Flutter packages use the same commands as Dart packages: `testkit :baseline`,
`testkit :test` and every analysis command work on them unchanged.

**Detection.** testkit runs `flutter test` for a package whose `pubspec.yaml`
declares the Flutter SDK, and `dart test` for every other package:

```yaml
dependencies:
  flutter:
    sdk: flutter
```

That is the signal the Flutter tooling itself uses. `flutter` as a hosted
dependency, or `flutter_test` in `dev_dependencies` alone, does not count; a
missing or unreadable pubspec falls back to `dart test`. With `-v` testkit
prints the command it runs (`Running: flutter test --reporter json ...`).

**Same protocol, same tracking.** `flutter test --reporter json` emits the
package:test JSON protocol `dart test` does, so the parser, the
`testlog/baseline_<MMDD_HHMM>.csv` tracking file, `testlog/last_testrun.json`,
the test description convention and the exit code are identical. Widget tests
are recorded like any other test.

**Running it.** The Flutter SDK must be on `PATH` (`flutter.bat` on Windows);
when the launcher is missing, testkit says so and exits 1. `flutter test`
resolves the package itself, so a stale `.dart_tool/` is repaired by `flutter
pub get`, not `dart pub get`.

**`--test-args` are passed to `flutter test`**, which accepts most of the
`dart test` options but not all:

| Options | `dart test` | `flutter test` |
|---------|-------------|----------------|
| `--name`, `--plain-name`, `--tags`, `--exclude-tags`, `--timeout`, `--concurrency`, `--fail-fast`, `--run-skipped`, `--total-shards` / `--shard-index`, `--test-randomize-ordering-seed`, `--coverage` | yes | yes |
| `--platform`, `--compiler`, `--chain-stack-traces` | yes | no |
| `--update-goldens`, `--dart-define`, `--device-id`, `--flavor` | no | yes |

The options testkit rejects (`--reporter`, `--file-reporter`,
`--pause-after-load`, `--debug`) are rejected for both runners.

## Line Coverage

`--coverage` on `:baseline` and `:test` measures the run's line coverage:

```bash
testkit :baseline --coverage            # baseline with its coverage
testkit :test --coverage -c "after fix" # run column with its coverage
testkit -s . -r :test --coverage        # every project of the workspace
```

- **Dart packages** run `dart test --coverage-path=coverage/lcov.info`; this
  needs package:test 1.27.0 or later in the project's lock. With an older one
  testkit says so and runs the tests without coverage.
- **Flutter packages** run `flutter test --coverage
  --coverage-path=coverage/lcov.info`.
- A project with another runner (a `testkit:` section, a `test:` step, a
  language default) runs without coverage, with a note.

The lcov report is written to `coverage/lcov.info` in the project (a report
left by an earlier run is deleted first); add `coverage/` to the project's
`.gitignore`; testkit notes it when git would track the file. The run's
covered and coverable lines (summed over the report: lcov's `LH` / `LF`) are
printed (`Line coverage: 81.2% (1234/1520 lines)`) and kept in the run's
column header as `cov:<covered>/<coverable>`, so they stay with the tracking
file:

```
Baseline [11-13 22:00] cov:1234/1520,[11-13 23:10] cov:1240/1520 after fix
```

`:status` shows the latest measured coverage (and the baseline's), `:runs` a
*Line coverage* column and `:history` a *Line coverage* row, whenever a run
measured it. A run without `--coverage` records none.

---

## Exit Code

`:baseline` and `:test` exit with the verdict of the run, as `dart test` does,
so a script can tell a red suite from a green one by the exit code alone:

| Exit code | Meaning |
|-----------|---------|
| `0` | Every test passed (an `--failed` / `--mismatched` run with nothing to re-run included) |
| `1` | A test failed, no test ran, a test file failed to load, or the command could not run (no tracking file, an unreadable tracking file, a pub cache that cannot supply the lock) |

A failing test does not stop the tracking: its run is still recorded (`:test`)
or its baseline still written (`:baseline`), and stderr names the reason,
e.g. `[<project>] 1 test failed.`. A test whose description expects a failure
(`(FAIL)`) is a failing test here too: the expectation steers the `X/X` result,
not the exit code. Over several projects the process exits 1 when any project's
run failed.

## Common Options

These options are available on every command:

| Option | Description |
|--------|-------------|
| `-v, --verbose` | Enable verbose output (shows file paths, extra details) |
| `-l, --list` | List projects that would be processed, without running the command |
| `-h, --help` | Show help for this command |
| `--baseline-file=<path>` | Use a specific baseline file instead of the most recent |

---

## Output Formats

Several commands accept `--output=<spec>` to control the output format and destination:

```
--output=plain               # Plain text table to stdout (default)
--output=csv                 # CSV to stdout
--output=json                # JSON to stdout
--output=md                  # Markdown to stdout
--output=csv:results.csv     # CSV to file
--output=json:data.json      # JSON to file
--output=md:report.md        # Markdown to file
```

The `--report=<file>` option (on diff commands) generates a detailed Markdown report with error messages and stack traces, which is different from `--output=md` (which outputs just the diff table).

---

## Project Traversal

testkit supports multi-project operation through the standard tom_build_base navigation system. This lets you run any command across multiple projects in a workspace (every language testkit can run; see [Other Languages](#other-languages)).

### Default Behavior

By default, testkit operates on **the current directory only** (non-recursive). It checks if the current directory is a testable project (has both `pubspec.yaml` and a `test/` directory). If so, the command runs on that project.

### Traversal Options

| Option | Description |
|--------|-------------|
| `-s, --scan=<path>` | Scan a directory for projects (default: `.`) |
| `-r, --recursive` | Also scan inside projects for nested projects (e.g. `test/` fixtures); folders without a `pubspec.yaml` are always scanned |
| `-R, --root[=<path>]` | Workspace mode: detect or specify workspace root, scan recursively |
| `-p, --project=<pattern>` | Process projects matching a glob pattern |
| `-b, --build-order` | Process in dependency order (default: on) |
| `-i, --include=<pattern>` | Include only projects matching pattern |
| `-o, --exclude=<pattern>` | Exclude projects matching pattern |

### Inside a Project

When running inside a project directory (the most common case), testkit:

1. Verifies the directory has `pubspec.yaml` and `test/`
2. Looks for the tracking file in `testlog/` (the most recent `baseline_*.csv`)
3. Runs the command on that single project

```bash
cd my_package
testkit :status          # Status for my_package only
```

### Workspace Tree Traversal

Use `-R` to scan an entire workspace, or `-r` to recurse from the current location:

```bash
# From the workspace root — process ALL projects with test/ directories
testkit :status -R

# From a subdirectory — recurse into child projects
cd packages/
testkit :status -r

# Scan a specific directory
testkit :status -s packages/core

# Only specific projects
testkit :status -p "tom_*"

# Exclude projects
testkit :status -R --exclude="*_example"
```

A project is considered **testable** if it has both:
- A `pubspec.yaml` file
- A `test/` directory

Projects with a `.skip` file are always skipped during traversal.

### Listing Projects

Use `-l` to preview which projects would be processed without running the command:

```bash
testkit :test -R -l      # List all workspace projects that would be tested
```

### Multi-Project Output

When processing multiple projects, testkit prints each project path as a header, followed by the command output. A summary is printed at the end:

```
packages/core:
  File: testlog/baseline_0210_1430.csv
  Runs: 3
  Tests: 45 (42 passed, 3 failed)

packages/utils:
  File: testlog/baseline_0210_1430.csv
  Runs: 2
  Tests: 23 (23 passed, 0 failed)

testkit: Processed 2 project(s)
```

Each project has its own independent tracking file in its own `testlog/` directory.

---

## TUI Mode

testkit includes an interactive TUI (terminal user interface) mode:

```bash
testkit --tui                    # Launch TUI for current project
testkit --tui -R                 # Launch with workspace root
```

The TUI provides a full-screen dashboard for running baselines and tests interactively.

---

## Help System

```bash
testkit help                     # Overview of all commands
testkit help <command>           # Detailed help for a specific command
testkit help baseline            # Example: detailed :baseline help
testkit help crossreference      # Aliases work too: crossref, xref
testkit --help                   # Same as testkit help
testkit version                  # Show version information
```

---

## Related Documentation

- [CLI Tools Navigation Guide](../../../basics/tom_build_base/doc/cli_tools_navigation.md) — Standard navigation options
- [Build Base User Guide](../../../basics/tom_build_base/doc/build_base_user_guide.md) — Configuration and project discovery

## Other Languages

testkit tracks the tests of every project it can run, not only Dart and
Flutter packages: Go, Rust, Python, Java, JavaScript, TypeScript, C and C++.
The tracking file, the result format, `:lastdiff`, `:status`, `:history`,
`:flaky`, `:trim` and `:reset` are the same; only how the tests run differs.

### Which runner

The runner of a project is the first that applies:

| # | Source | Runner | Report |
| - | ------ | ------ | ------ |
| 1 | `testkit:` section of `buildkit.yaml` | its `command:` | its `report:` (default `testkit`), at `report-path:` or `{report}` |
| 2 | Dart or Flutter project | `dart test` / `flutter test` | package:test JSON |
| 3 | `test:` step of `buildkit.yaml` | the step's command(s) | testkit line protocol in `$TESTKIT_REPORT` |
| 4 | Go | `go test -json ./...` | `go-json` on the output |
| 4 | Rust | `cargo test --no-fail-fast` | `libtest` text on the output |
| 4 | Python | `python3 -m pytest -q --junitxml={report}` | `junit` |
| 4 | Java, Maven | `mvn -B test` | `junit`, `target/surefire-reports/TEST-*.xml` |
| 4 | Java, Gradle | `./gradlew test` (or `gradle test`) | `junit`, `build/test-results/test/*.xml` |
| 4 | JavaScript / TypeScript with jest | `npx jest --json --outputFile={report}` | `jest-json` |
| 4 | JavaScript | `node --test --test-reporter=junit --test-reporter-destination={report}` | `junit` |

C, C++ and TypeScript without jest have no default: such a project needs a
`test:` step or a `testkit:` section, and testkit says so. A `--dry-run` names
the runner each project gets.

```yaml
# buildkit.yaml — a CMake project with CTest
testkit:
  command: ctest --test-dir build --output-junit {report}
  report: junit
```

`{report}` is replaced by the (quoted) path of the report file testkit hands
the command, `testlog/last_testrun_report.<xml|json|jsonl>`; the same path is
in the environment as `TESTKIT_REPORT`. A report file left by an earlier run is
deleted first, so a run that writes none records nothing. `--test-args` are
appended to the command.

### The line protocol

A project that tests through its own script (the SOM runtimes'
`run_tests.sh`) writes one line per test to the file `$TESTKIT_REPORT` names:

```json
{"test": "tests/parser_test.py", "result": "ok"}
{"test": "examples/a_typed_access.py", "result": "fail", "group": "samples"}
```

| Field | Meaning |
| ----- | ------- |
| `test` | The test's name: its key in the tracking file. An `ID: description` name is read like a Dart test name. |
| `result` | `ok` (or `pass`), `skip`, anything else is a failure. |
| `suite`, `group` | Optional: the file and the group (`Groups` column; the suite when no group is given). |

A line that is not such an object is ignored, so the script may write nothing
else there. In bash:

```bash
tk_result() { # <test name> <exit code>
  if [ -n "${TESTKIT_REPORT:-}" ]; then
    local result=ok
    [ "$2" -eq 0 ] || result=fail
    printf '{"test":"%s","result":"%s"}\n' "$1" "$result" >>"$TESTKIT_REPORT"
  fi
}
python3 tests/parser_test.py; tk_result tests/parser_test.py $?
```

### What is recorded

- **Names.** A test is keyed by its name as the runner reports it (`TestParse/empty`,
  `parser::tests::empty`, `test_empty`). A name reported in two groups
  (the same test name in two packages, classes or files) is written
  `<group> > <name>` for each, so the two stay apart. A test reported twice in
  one group (a retry) is recorded once, with its last result.
- **Groups.** The package (Go), the test binary (Rust: `unittests src/lib.rs`,
  `tests/api.rs`, `doc-tests <crate>`), the class (`classname` in JUnit
  reports; the `<testsuite>` names for `node --test`, whose classname is the
  constant `test`), the describe blocks (jest).
- **Load failures.** A Go package whose build failed and a jest test file that
  failed before any test ran are load failures, as a Dart test file that does
  not load: the run is incomplete, `:baseline` writes nothing and `:test`
  records what ran and fails.
- **Exit code.** A run whose command exits with an error although no reported
  test failed (a script whose build step failed before its tests reported) is
  incomplete in the same way.
- **No test.** A run that reports no test records nothing; the message quotes
  the last lines of the runner's output.
- **Selection.** Only `dart test` selects single tests by name: `--failed` and
  `--mismatched` run every test of another runner (and say so), and all their
  results are recorded.
