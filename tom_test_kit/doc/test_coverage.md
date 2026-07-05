# Tom Test Kit — Test Coverage

This document maps every testkit feature area to its test file, test count, and
regression handle (test-ID prefix), so critical flows have clear coverage and
stable regression checks. It mirrors the coverage documents for
[buildkit](../../../basics/tom_build_kit/doc/test_coverage.md) and
[tom_build_base](../../../basics/tom_build_base/doc/test_coverage.md).

## Status Legend

- ✅ Test implemented and passing
- ⬜ Test not yet implemented

## How to run

```bash
cd tom_ai/devops/tom_test_kit
dart test          # full suite (authoritative)
testkit :test      # tracked run against the latest baseline
```

The authoritative total below (**188 passing**) is the count reported by
`dart test`. Per-file counts are the tests executed from each suite; test IDs
follow the `TK-<AREA>-<n>` convention (e.g. `TK-MDT-1`), which is the stable
handle for regression tracking.

---

## Overview

| # | Feature Area | Tests | Status | Test File | ID Prefix |
|---|-------------|-------|--------|-----------|-----------|
| 1 | [Test entry model](#1-test-entry-model) | 10 | 10✅ | `model/test_entry_test.dart` | `TK-ENT` |
| 2 | [Test run model](#2-test-run-model) | 14 | 14✅ | `model/test_run_test.dart` | `TK-RUN` |
| 3 | [Tracking file model](#3-tracking-file-model) | 9 | 9✅ | `model/tracking_file_test.dart` | `TK-TRK` |
| 4 | [Dart test-output parser](#4-dart-test-output-parser) | 14 | 14✅ | `parser/dart_test_parser_test.dart` | `TK-DTP` |
| 5 | [Test-description parser](#5-test-description-parser) | 10 | 10✅ | `parser/test_description_parser_test.dart` | `TK-TDP` |
| 6 | [`:basediff` command](#6-basediff-command) | 7 | 7✅ | `tracking/basediff_command_test.dart` | `TK-BDIF` |
| 7 | [`:crossref` command](#7-crossref-command) | 5 | 5✅ | `tracking/crossref_command_test.dart` | `TK-XREF` |
| 8 | [`:diff` command](#8-diff-command) | 6 | 6✅ | `tracking/diff_command_test.dart` | `TK-DIF` |
| 9 | [Diff helper](#9-diff-helper) | 10 | 10✅ | `tracking/diff_helper_test.dart` | `TK-DIFH` |
| 10 | [`:flaky` command](#10-flaky-command) | 6 | 6✅ | `tracking/flaky_command_test.dart` | `TK-FLKY` |
| 11 | [`:history` command](#11-history-command) | 7 | 7✅ | `tracking/history_command_test.dart` | `TK-HIST` |
| 12 | [`:lastdiff` command](#12-lastdiff-command) | 5 | 5✅ | `tracking/lastdiff_command_test.dart` | `TK-LDIF` |
| 13 | [`:reset` command](#13-reset-command) | 6 | 6✅ | `tracking/reset_command_test.dart` | `TK-RST` |
| 14 | [`:runs` command](#14-runs-command) | 5 | 5✅ | `tracking/runs_command_test.dart` | `TK-RUNS` |
| 15 | [`:status` command](#15-status-command) | 5 | 5✅ | `tracking/status_command_test.dart` | `TK-STAT` |
| 16 | [`:test` command](#16-test-command) | 10 | 10✅ | `tracking/test_command_test.dart` | `TK-TST` |
| 17 | [`:trim` command](#17-trim-command) | 8 | 8✅ | `tracking/trim_command_test.dart` | `TK-TRIM` |
| 18 | [File helpers](#18-file-helpers) | 5 | 5✅ | `util/file_helpers_test.dart` | `TK-FIL` |
| 19 | [Format helpers](#19-format-helpers) | 7 | 7✅ | `util/format_helpers_test.dart` | `TK-FMT` |
| 20 | [Markdown table parser](#20-markdown-table-parser) | 21 | 21✅ | `util/markdown_table_test.dart` | `TK-MDT` |
| 21 | [Output formatter](#21-output-formatter) | 15 | 15✅ | `util/output_formatter_test.dart` | `TK-OFMT` |
| 22 | [v2 CLI tool wiring](#22-v2-cli-tool-wiring) | 3 | 3✅ | `v2/testkit_tool_test.dart` | `TK-CLI` |
| — | **Total** | **188** | **188✅** | | |

---

## 1. Test entry model

**Test file:** `test/model/test_entry_test.dart` — **ID prefix `TK-ENT`**

Covers the `TestEntry` value object: construction, result parsing
(`OK`/`X`/`-`/`--`), serialization round-trips, and equality.

**How to test:** `dart test test/model/test_entry_test.dart`.

## 2. Test run model

**Test file:** `test/model/test_run_test.dart` — **ID prefix `TK-RUN`**

Covers the `TestRun` aggregate: per-run pass/fail/skip tallies, timestamp
handling, and baseline-column association.

**How to test:** `dart test test/model/test_run_test.dart`.

## 3. Tracking file model

**Test file:** `test/model/tracking_file_test.dart` — **ID prefix `TK-TRK`**

Covers the baseline CSV tracking-file model: adding result columns, header
formatting, and row ordering.

**How to test:** `dart test test/model/tracking_file_test.dart`.

## 4. Dart test-output parser

**Test file:** `test/parser/dart_test_parser_test.dart` — **ID prefix `TK-DTP`**

Parses `dart test` JSON output into `TestRun`/`TestEntry` models, including
passed/failed/skipped classification and description extraction.

**How to test:** `dart test test/parser/dart_test_parser_test.dart`.

## 5. Test-description parser

**Test file:** `test/parser/test_description_parser_test.dart` — **ID prefix `TK-TDP`**

Parses the `ID: description [date] (result)` naming convention into structured
ID / description / date / result fields.

**How to test:** `dart test test/parser/test_description_parser_test.dart`.

## 6. `:basediff` command

**Test file:** `test/tracking/basediff_command_test.dart` — **ID prefix `TK-BDIF`**

Diffs the current run against the chosen baseline; verifies regression / fix
detection and exit semantics.

**How to test:** `dart test test/tracking/basediff_command_test.dart`.

## 7. `:crossref` command

**Test file:** `test/tracking/crossref_command_test.dart` — **ID prefix `TK-XREF`**

Cross-references test IDs against issue links.

**How to test:** `dart test test/tracking/crossref_command_test.dart`.

## 8. `:diff` command

**Test file:** `test/tracking/diff_command_test.dart` — **ID prefix `TK-DIF`**

Compares two named runs and renders the change set.

**How to test:** `dart test test/tracking/diff_command_test.dart`.

## 9. Diff helper

**Test file:** `test/tracking/diff_helper_test.dart` — **ID prefix `TK-DIFH`**

Shared diff computation used by the diff-family commands (regression / fix /
new / removed classification).

**How to test:** `dart test test/tracking/diff_helper_test.dart`.

## 10. `:flaky` command

**Test file:** `test/tracking/flaky_command_test.dart` — **ID prefix `TK-FLKY`**

Detects tests that alternate pass/fail across runs.

**How to test:** `dart test test/tracking/flaky_command_test.dart`.

## 11. `:history` command

**Test file:** `test/tracking/history_command_test.dart` — **ID prefix `TK-HIST`**

Renders a per-test pass/fail history across baseline columns.

**How to test:** `dart test test/tracking/history_command_test.dart`.

## 12. `:lastdiff` command

**Test file:** `test/tracking/lastdiff_command_test.dart` — **ID prefix `TK-LDIF`**

Diffs the most recent run against the previous one.

**How to test:** `dart test test/tracking/lastdiff_command_test.dart`.

## 13. `:reset` command

**Test file:** `test/tracking/reset_command_test.dart` — **ID prefix `TK-RST`**

Resets baseline tracking state.

**How to test:** `dart test test/tracking/reset_command_test.dart`.

## 14. `:runs` command

**Test file:** `test/tracking/runs_command_test.dart` — **ID prefix `TK-RUNS`**

Lists recorded runs / baseline columns.

**How to test:** `dart test test/tracking/runs_command_test.dart`.

## 15. `:status` command

**Test file:** `test/tracking/status_command_test.dart` — **ID prefix `TK-STAT`**

Summarizes the current pass/fail/skip status of the latest run.

**How to test:** `dart test test/tracking/status_command_test.dart`.

## 16. `:test` command

**Test file:** `test/tracking/test_command_test.dart` — **ID prefix `TK-TST`**

End-to-end `:test` flow: run `dart test`, parse output, append a result column
to the latest baseline.

**How to test:** `dart test test/tracking/test_command_test.dart`.

## 17. `:trim` command

**Test file:** `test/tracking/trim_command_test.dart` — **ID prefix `TK-TRIM`**

Trims old baseline columns / runs to a configured retention window.

**How to test:** `dart test test/tracking/trim_command_test.dart`.

## 18. File helpers

**Test file:** `test/util/file_helpers_test.dart` — **ID prefix `TK-FIL`**

Baseline-file discovery (latest-by-name), path resolution, and I/O helpers.

**How to test:** `dart test test/util/file_helpers_test.dart`.

## 19. Format helpers

**Test file:** `test/util/format_helpers_test.dart` — **ID prefix `TK-FMT`**

Result-cell formatting (`OK/OK`, `X/OK`, `--/OK`) and console rendering.

**How to test:** `dart test test/util/format_helpers_test.dart`.

## 20. Markdown table parser

**Test file:** `test/util/markdown_table_test.dart` — **ID prefix `TK-MDT`**

Splits/renders markdown table rows (escaped-pipe handling), parses baseline
headers, and classifies result cells.

**How to test:** `dart test test/util/markdown_table_test.dart`.

## 21. Output formatter

**Test file:** `test/util/output_formatter_test.dart` — **ID prefix `TK-OFMT`**

`OutputFormat`/`OutputSpec` parsing (incl. the `text`→`plain` and
`markdown`→`md` aliases and the first-colon `<format>:<file>` split) and
per-format table rendering. See the cross-tool
[CLI Output Formats contract](../../../basics/tom_build_base/doc/cli_output_formats.md).

**How to test:** `dart test test/util/output_formatter_test.dart`.

## 22. v2 CLI tool wiring

**Test file:** `test/v2/testkit_tool_test.dart` — **ID prefix `TK-CLI`**

Verifies the v2 `ToolDefinition`/`ToolRunner` wiring (commands, options,
help/version) built on `tom_build_base`.

**How to test:** `dart test test/v2/testkit_tool_test.dart`.
