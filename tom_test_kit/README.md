# Tom Test Kit

> Tom Test Kit is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [LICENSE](LICENSE).

Test result tracking tool for Dart projects.

`tom_test_kit` is the `testkit` CLI: it runs your `dart test` suite, records the
results into a CSV **tracking file**, and compares runs over time so you can see
at a glance what regressed, what got fixed, and what is flaky. It is one of the
three Tom CLI "kits" built on [`tom_build_base`](../../basics/tom_build_base/)
(alongside [`buildkit`](../tom_build_kit/) and [`issuekit`](../tom_issue_kit/)),
and it ships an optional full-screen **TUI** dashboard.

---

## Overview

Plain `dart test` answers one question — *do the tests pass right now?*
`testkit` answers the more useful one — *what changed since last time?* It does
that by persisting every run as a column in a CSV baseline and diffing columns:

| Concern | What testkit adds over `dart test` |
| ------- | ---------------------------------- |
| **Tracking** | Each run becomes a result column in `testlog/baseline_<MMDD_HHMM>.csv`; history accumulates across runs. |
| **Regression detection** | A run is compared against the baseline, so new failures (`X/OK`) and new fixes (`OK/X`) stand out. |
| **Structured naming** | Test descriptions of the form `ID: description [date] (result)` are parsed into ID / groups / expectation columns. |
| **Flake surfacing** | Tests whose result oscillates across runs are listed by `:flaky`. |
| **Workspace scale** | Project traversal runs the suite across many packages in one invocation. |
| **Interactive mode** | A `utopia_tui` dashboard (`--tui`) runs tests and watches progress live. |

### How a run flows

```
   testkit :test
        │ ToolRunner (tom_build_base v2) dispatches the :test executor
        ▼
   dart test --reporter json   ─▶  DartTestParser  ─▶  TestRun
        │                                                  │
        │ append a result column to the most recent        ▼
        ▼ testlog/baseline_<MMDD_HHMM>.csv             TrackingFile (CSV)
   diff vs. baseline ─▶ regressions / fixes summary
```

The `testlog/` folder (baselines + the raw `last_testrun.json`) is **gitignored**
— it is per-developer run state, not source. Hand-authored docs live in `doc/`.

---

## Installation

`tom_test_kit` is a **workspace-internal package** (`publish_to: none`). It is
not published to pub.dev; it is built as the `testkit` executable (with a `tk`
symlink on Unix) and put on `PATH` by the Tom toolchain build:

```bash
# Run from source during development …
dart run tom_test_kit:testkit :status

# … or use the compiled binary once the toolchain is built.
testkit :status
tk :status            # `tk` is the Unix symlink alias
```

**SDK requirement:** Dart `^3.10.4`. **Dart dependencies:**
[`tom_build_base`](../../basics/tom_build_base/) `^2.6.25` (the v2 CLI
framework — a normal **hosted** dependency, no path override),
[`args`](https://pub.dev/packages/args),
[`path`](https://pub.dev/packages/path), and
[`utopia_tui`](https://pub.dev/packages/utopia_tui) `^1.1.0` (the TUI runtime).

---

## Quick start

```bash
# 1. Create the first baseline (runs the suite, writes a CSV column).
testkit :baseline -c "v0.1 start"
# → testlog/baseline_0617_0930.csv

# 2. Make changes, then record another run (appends a column, diffs it).
testkit :test
# Regressions: 0   Fixes: 1   Pass: 142   Fail: 0

# 3. See where things stand at any time.
testkit :status

# 4. Compare the baseline against the latest run.
testkit :basediff
```

Every command runs against the **most recent** baseline in `testlog/`, so the
day-to-day loop is just `testkit :test` after each change.

---

## Example projects

| Location | What it shows |
| -------- | ------------- |
| [`bin/testkit.dart`](bin/testkit.dart) | The CLI entry point — argument parsing, `--tui` dispatch, and the v2 `ToolRunner` wiring. |
| [`test/`](test/) | The package's own 22-file test suite (model, parser, tracking, util, v2). |
| `../tom_devops_samples/tom_test_kit_sample/` | A runnable baseline → test → diff walkthrough on a small fixture project — see the [samples learning path](../README.md). *(forward reference — added later in this quest.)* |

---

## Usage

### Reading a result cell

Every result column shows `<current>/<baseline>` per test, so a single glance
tells you both the latest outcome and whether it changed:

| Cell | Meaning |
| ---- | ------- |
| `OK/OK` | Passed, and was passing in the baseline. |
| `X/OK` | **Regression** — now failing, was passing. |
| `OK/X` | **Fix** — now passing, was failing. |
| `X/X` | Known failure — failing in both. |
| `-/OK` | Skipped this run. |
| `--/OK` | Absent this run (filtered out / not collected). |

`X` = FAIL, `OK` = PASSED, `-` = SKIP. The same legend is printed in
`testkit --help`.

### Commands

Commands are invoked with a leading colon (`testkit :test`). They fall into
three groups.

**Run commands** — execute `dart test` and write results:

| Command | Description |
| ------- | ----------- |
| `:baseline` | Run the suite and create a **new** baseline tracking file. |
| `:test` | Run the suite and **append** a result column to the most recent baseline. |

**Analysis commands** — read-only, operate on the tracking file:

| Command | Description |
| ------- | ----------- |
| `:runs` | List the run timestamps recorded in the tracking file. |
| `:status` | Quick pass/fail summary with regression/fix counts. |
| `:basediff` | Diff the baseline column against the latest run. |
| `:lastdiff` | Diff the previous run against the latest run. |
| `:diff <ts> [ts]` | Diff two arbitrary runs by timestamp. |
| `:history <query>` | Show every result for a matching test across all runs. |
| `:flaky` | List tests whose results are inconsistent across runs. |
| `:crossreference` | Map tests to their source files. *(aliases: `:crossref`, `:xref`)* |

**Maintenance commands**:

| Command | Description |
| ------- | ----------- |
| `:trim <n>` | Keep only the last `n` runs in the tracking file. |
| `:reset` | Delete all tracking files (`--force` skips confirmation). |

### Common options

| Option | Applies to | Effect |
| ------ | ---------- | ------ |
| `-c`, `--comment=TEXT` | `:baseline`, `:test` | Short label shown in the column header. |
| `--test-args=ARGS` | `:baseline`, `:test` | Extra arguments forwarded to `dart test` (e.g. `--test-args="--tags e2e"`). |
| `--no-update` | `:test` | Run tests and print the summary **without** writing a column. |
| `--failed` | `:test` | Re-run only the tests that failed last run (`X/OK`, `X/X`). |
| `--mismatched` | `:test` | Re-run only tests that don't match their expectation (`X/OK`, `OK/X`). |
| `--baseline` | `:test` | Create a baseline first if no tracking file exists. |
| `--file=PATH` | `:baseline`, `:test` | Use a specific tracking file instead of the most recent. |
| `--output=FORMAT` | analysis/diff | Output as `plain`, `csv`, `json`, or `md` (or `<format>:<filename>`). |
| `--baseline-file=PATH` | analysis/diff | Read against a specific baseline file. |
| `--full` / `--report=FILE` | diff | Include `last_testrun.json` detail / write a Markdown report. |

Examples:

```bash
testkit :baseline -c "v2.0 release"
testkit :test --failed                       # iterate on just the red tests
testkit :test --test-args="--name parser"    # narrow the suite
testkit :diff 0211_1430 0212_0900            # compare two timestamps
testkit :history "parser"                    # one test across all runs
testkit :basediff --output=md:report.md      # write a Markdown diff
```

### Project traversal

Every command declares `worksWithNatures: {DartProjectFolder}` and supports
project traversal, so a single invocation can run across many packages in a
workspace (each gets its own `testlog/`):

```bash
testkit :test -r          # recurse into every Dart project under the cwd
```

### TUI mode

Pass the global `--tui` flag to launch the full-screen dashboard (built on
`utopia_tui`) instead of running a one-shot command:

```bash
testkit --tui
```

The dashboard registers `baseline` and `test` commands by default and streams
their progress into an output panel. The TUI is **extensible** — new commands
register through `TuiCommandRegistry`, and external CLI tools can be wrapped via
`ExternalToolAdapter`. See [`doc/tom_test_tui.md`](doc/tom_test_tui.md).

### Library use

The tracking model and parsers are exported, so the same logic is usable
programmatically — for instance to read a baseline in a build script:

```dart
import 'package:tom_test_kit/tom_test_kit.dart';

void main() {
  // Parse a dart-test JSON report into a structured run.
  final run = DartTestParser().parseFile('testlog/last_testrun.json');
  print('Passed: ${run.passed.length}, failed: ${run.failed.length}');
}
```

---

## Architecture

```
        bin/testkit.dart
              │ --tui? ──────────────▶ TestKitTuiApp (utopia_tui)
              ▼ otherwise                    │ TuiCommandRegistry
        ToolRunner (tom_build_base v2)        ▼
              │ dispatches by :command    BaselineTuiCommand / TestTuiCommand
              ▼
        createTestkitExecutors()
              │
   ┌──────────┼───────────────┬─────────────────┐
   ▼          ▼               ▼                 ▼
 baseline   test         status/diff/…       trim/reset
   │          │ dart test --reporter json
   ▼          ▼
 DartTestParser ─▶ TestRun ─▶ TrackingFile (CSV)  ◀─ OutputFormatter
                                                       (plain/csv/json/md)
```

### Key types

| Type | Role |
| ---- | ---- |
| `testkitTool` | The `ToolDefinition` — declares the 12 commands, options, `--tui` global flag, help topics, and result-format footer. |
| `createTestkitExecutors()` | Builds the `CommandExecutor` set the v2 `ToolRunner` dispatches to. |
| `TestRun` / `TestEntry` | A single run and one test's result within it. |
| `TrackingFile` | The CSV baseline model — runs as columns, tests as rows. |
| `DartTestParser` | Parses `dart test --reporter json` output into a `TestRun`. |
| `TestDescriptionParser` | Extracts `ID: description [date] (result)` structure from test names. |
| `OutputFormatter` / `OutputSpec` | Renders analysis/diff output as plain, CSV, JSON, or Markdown. |
| `TestKitTuiApp` | The `utopia_tui` dashboard app. |
| `TuiCommandRegistry` / `TuiCommand` | Registration surface for TUI commands. |
| `ExternalToolAdapter` | Wraps an external CLI as a TUI command. |

---

## Ecosystem

```
        testkit  buildkit  issuekit   (the three Tom CLI kits)
            │        │         │
            └────────┴────┬────┘
                          ▼
                  tom_build_base  (v2 CLI framework: ToolRunner,
                          │         ToolDefinition, executors)
        ┌─────────────────┴───────────────┐
        ▼                                  ▼
    dart test  ──json──▶  testkit     utopia_tui (TUI runtime)
```

`testkit` shares its argument parsing, help formatting, project traversal, and
run-summary rendering with the other kits through `tom_build_base`; its own job
is the test-tracking model on top.

---

## Further documentation

| Document | What it covers |
| -------- | -------------- |
| [`doc/test_tracking.md`](doc/test_tracking.md) | The test-tracking concept and workflow — the test-code-fix cycle, description conventions, and how each command supports it. |
| [`doc/tom_test_tui.md`](doc/tom_test_tui.md) | The TUI concept — the dashboard, command registry, and extension points. |

## Related packages

| Package | Relationship |
| ------- | ------------ |
| [`tom_build_base`](../../basics/tom_build_base/) | The shared v2 CLI framework `testkit` is built on. |
| [`tom_build_kit`](../tom_build_kit/) | The `buildkit` build orchestrator — sibling kit. |
| [`tom_issue_kit`](../tom_issue_kit/) | The `issuekit` issue-lifecycle CLI — sibling kit. |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 0.1.0 (`publish_to: none` — workspace-internal)
- **SDK:** Dart `^3.10.4`
- **Dart dependencies:** `tom_build_base ^2.6.25` (hosted), `args`, `path`, `utopia_tui ^1.1.0`.
- **Executable:** `testkit` (`bin/testkit.dart`); `tk` symlink on Unix.
- **Commands:** 12 (`:baseline`, `:test`, `:runs`, `:status`, `:basediff`, `:lastdiff`, `:diff`, `:history`, `:flaky`, `:crossreference`, `:trim`, `:reset`) + `--tui` mode.
- **Tests:** 22 test files (model, parser, tracking, util, v2).

---

## License

See [LICENSE](LICENSE); each package in this repository carries its own license
terms.
