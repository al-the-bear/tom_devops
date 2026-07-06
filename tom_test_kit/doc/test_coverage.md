# Tom Test Kit — Test Coverage

This document maps every testkit feature area to its test file, test count, and
regression handle (test-ID prefix), and enumerates every individual test as an
`ID / Feature / Status / How to Test` row per area, so critical flows have clear
coverage and stable regression checks. It mirrors the coverage documents for
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

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-ENT-1 | should include ID and description when ID is present | ✅ | `dart test --name 'TK-ENT-1'` |
| TK-ENT-2 | should omit ID prefix when ID is null | ✅ | `dart test --name 'TK-ENT-2'` |
| TK-ENT-3 | should include creation date when present | ✅ | `dart test --name 'TK-ENT-3'` |
| TK-ENT-4 | should omit date when creationDate is null | ✅ | `dart test --name 'TK-ENT-4'` |
| TK-ENT-5 | should return creationDate when present | ✅ | `dart test --name 'TK-ENT-5'` |
| TK-ENT-6 | should return far-future date when creationDate is null | ✅ | `dart test --name 'TK-ENT-6'` |
| TK-ENT-7 | should default to OK | ✅ | `dart test --name 'TK-ENT-7'` |
| TK-ENT-8 | should store group path when provided | ✅ | `dart test --name 'TK-ENT-8'` |
| TK-ENT-9 | should include date and FAIL marker | ✅ | `dart test --name 'TK-ENT-9'` |
| TK-ENT-10 | should omit FAIL marker when expectation is OK | ✅ | `dart test --name 'TK-ENT-10'` |

## 2. Test run model

**Test file:** `test/model/test_run_test.dart` — **ID prefix `TK-RUN`**

Covers the `TestRun` aggregate: per-run pass/fail/skip tallies, timestamp
handling, and baseline-column association.

**How to test:** `dart test test/model/test_run_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-RUN-1 | should have correct labels | ✅ | `dart test --name 'TK-RUN-1'` |
| TK-RUN-2 | should include Baseline prefix when isBaseline is true | ✅ | `dart test --name 'TK-RUN-2'` |
| TK-RUN-3 | should omit prefix when isBaseline is false | ✅ | `dart test --name 'TK-RUN-3'` |
| TK-RUN-4 | should store and retrieve a result | ✅ | `dart test --name 'TK-RUN-4'` |
| TK-RUN-5 | should return absent for unknown test | ✅ | `dart test --name 'TK-RUN-5'` |
| TK-RUN-6 | should accept pre-populated results map | ✅ | `dart test --name 'TK-RUN-6'` |
| TK-RUN-7 | regression (X/OK) should be highest priority | ✅ | `dart test --name 'TK-RUN-7'` |
| TK-RUN-8 | expected failure (X/X) should be priority 1 | ✅ | `dart test --name 'TK-RUN-8'` |
| TK-RUN-9 | progress (OK/X) should be priority 2 | ✅ | `dart test --name 'TK-RUN-9'` |
| TK-RUN-10 | healthy (OK/OK) should be priority 3 | ✅ | `dart test --name 'TK-RUN-10'` |
| TK-RUN-11 | skip should be priority 4 | ✅ | `dart test --name 'TK-RUN-11'` |
| TK-RUN-12 | absent should be priority 5 | ✅ | `dart test --name 'TK-RUN-12'` |
| TK-RUN-13 | should format as result/expectation | ✅ | `dart test --name 'TK-RUN-13'` |
| TK-RUN-14 | should compute sort priority from entry and result | ✅ | `dart test --name 'TK-RUN-14'` |

## 3. Tracking file model

**Test file:** `test/model/tracking_file_test.dart` — **ID prefix `TK-TRK`**

Covers the baseline CSV tracking-file model: adding result columns, header
formatting, and row ordering.

**How to test:** `dart test test/model/tracking_file_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-TRK-1 | should create tracking file with entries and one run | ✅ | `dart test --name 'TK-TRK-1'` |
| TK-TRK-2 | should append a run and merge new entries | ✅ | `dart test --name 'TK-TRK-2'` |
| TK-TRK-3 | should mark missing tests as absent in new run | ✅ | `dart test --name 'TK-TRK-3'` |
| TK-TRK-4 | should sort regressions before healthy tests | ✅ | `dart test --name 'TK-TRK-4'` |
| TK-TRK-5 | should sort by creation date within same priority group | ✅ | `dart test --name 'TK-TRK-5'` |
| TK-TRK-6 | should write and reload a baseline tracking file | ✅ | `dart test --name 'TK-TRK-6'` |
| TK-TRK-7 | should preserve results across round-trip | ✅ | `dart test --name 'TK-TRK-7'` |
| TK-TRK-8 | should preserve multiple runs across round-trip | ✅ | `dart test --name 'TK-TRK-8'` |
| TK-TRK-9 | should return null for non-existent file | ✅ | `dart test --name 'TK-TRK-9'` |

## 4. Dart test-output parser

**Test file:** `test/parser/dart_test_parser_test.dart` — **ID prefix `TK-DTP`**

Parses `dart test` JSON output into `TestRun`/`TestEntry` models, including
passed/failed/skipped classification and description extraction.

**How to test:** `dart test test/parser/dart_test_parser_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-DTP-1 | should parse a passing test from JSON events | ✅ | `dart test --name 'TK-DTP-1'` |
| TK-DTP-2 | should parse a failing test | ✅ | `dart test --name 'TK-DTP-2'` |
| TK-DTP-3 | should parse a skipped test | ✅ | `dart test --name 'TK-DTP-3'` |
| TK-DTP-4 | should skip "loading" tests | ✅ | `dart test --name 'TK-DTP-4'` |
| TK-DTP-5 | should skip hidden tests | ✅ | `dart test --name 'TK-DTP-5'` |
| TK-DTP-6 | should handle multiple tests mixed pass/fail | ✅ | `dart test --name 'TK-DTP-6'` |
| TK-DTP-7 | should skip non-JSON lines gracefully | ✅ | `dart test --name 'TK-DTP-7'` |
| TK-DTP-8 | should handle empty input | ✅ | `dart test --name 'TK-DTP-8'` |
| TK-DTP-9 | should extract single group and strip from name | ✅ | `dart test --name 'TK-DTP-9'` |
| TK-DTP-10 | should extract nested groups with > separator | ✅ | `dart test --name 'TK-DTP-10'` |
| TK-DTP-11 | should handle test with only root group (no groups) | ✅ | `dart test --name 'TK-DTP-11'` |
| TK-DTP-12 | runInShellForHost matches the host platform | ✅ | `dart test --name 'TK-DTP-12'` |
| TK-DTP-13 | buildLaunchError is clear and actionable | ✅ | `dart test --name 'TK-DTP-13'` |
| TK-DTP-14 | buildLaunchError mentions dart.bat on Windows | ✅ | `dart test --name 'TK-DTP-14'` |

## 5. Test-description parser

**Test file:** `test/parser/test_description_parser_test.dart` — **ID prefix `TK-TDP`**

Parses the `ID: description [date] (result)` naming convention into structured
ID / description / date / result fields.

**How to test:** `dart test test/parser/test_description_parser_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-TDP-1 | should extract ID before first colon | ✅ | `dart test --name 'TK-TDP-1'` |
| TK-TDP-2 | should extract creation date [YYYY-MM-DD HH:MM] | ✅ | `dart test --name 'TK-TDP-2'` |
| TK-TDP-3 | should extract FAIL expectation | ✅ | `dart test --name 'TK-TDP-3'` |
| TK-TDP-4 | should extract PASS expectation as OK | ✅ | `dart test --name 'TK-TDP-4'` |
| TK-TDP-5 | should default expectation to OK when absent | ✅ | `dart test --name 'TK-TDP-5'` |
| TK-TDP-6 | should parse full description with all components | ✅ | `dart test --name 'TK-TDP-6'` |
| TK-TDP-7 | should preserve fullDescription as-is | ✅ | `dart test --name 'TK-TDP-7'` |
| TK-TDP-8 | should handle description without any metadata | ✅ | `dart test --name 'TK-TDP-8'` |
| TK-TDP-9 | should store suite when provided | ✅ | `dart test --name 'TK-TDP-9'` |
| TK-TDP-10 | should handle ID-only description (no extra text) | ✅ | `dart test --name 'TK-TDP-10'` |

## 6. `:basediff` command

**Test file:** `test/tracking/basediff_command_test.dart` — **ID prefix `TK-BDIF`**

Diffs the current run against the chosen baseline; verifies regression / fix
detection and exit semantics.

**How to test:** `dart test test/tracking/basediff_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-BDIF-1 | returns false when no baseline file exists | ✅ | `dart test --name 'TK-BDIF-1'` |
| TK-BDIF-2 | returns true for single-run file (no diff) | ✅ | `dart test --name 'TK-BDIF-2'` |
| TK-BDIF-3 | returns true for multi-run file with diffs | ✅ | `dart test --name 'TK-BDIF-3'` |
| TK-BDIF-4 | writes CSV diff output to file | ✅ | `dart test --name 'TK-BDIF-4'` |
| TK-BDIF-5 | writes Markdown diff output to file | ✅ | `dart test --name 'TK-BDIF-5'` |
| TK-BDIF-6 | report path without full flag writes markdown report | ✅ | `dart test --name 'TK-BDIF-6'` |
| TK-BDIF-7 | writes JSON diff output to file | ✅ | `dart test --name 'TK-BDIF-7'` |

## 7. `:crossref` command

**Test file:** `test/tracking/crossref_command_test.dart` — **ID prefix `TK-XREF`**

Cross-references test IDs against issue links.

**How to test:** `dart test test/tracking/crossref_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-XREF-1 | returns false when no baseline file exists | ✅ | `dart test --name 'TK-XREF-1'` |
| TK-XREF-2 | returns true for tracking file without suite info | ✅ | `dart test --name 'TK-XREF-2'` |
| TK-XREF-3 | writes CSV cross-reference to file | ✅ | `dart test --name 'TK-XREF-3'` |
| TK-XREF-4 | returns true with verbose flag | ✅ | `dart test --name 'TK-XREF-4'` |
| TK-XREF-5 | writes JSON cross-reference to file | ✅ | `dart test --name 'TK-XREF-5'` |

## 8. `:diff` command

**Test file:** `test/tracking/diff_command_test.dart` — **ID prefix `TK-DIF`**

Compares two named runs and renders the change set.

**How to test:** `dart test test/tracking/diff_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-DIF-1 | returns false when no baseline file exists | ✅ | `dart test --name 'TK-DIF-1'` |
| TK-DIF-2 | returns true when comparing two valid timestamps | ✅ | `dart test --name 'TK-DIF-2'` |
| TK-DIF-3 | returns false for invalid timestamp | ✅ | `dart test --name 'TK-DIF-3'` |
| TK-DIF-4 | succeeds with single timestamp (vs latest) | ✅ | `dart test --name 'TK-DIF-4'` |
| TK-DIF-5 | writes CSV diff output to file | ✅ | `dart test --name 'TK-DIF-5'` |
| TK-DIF-6 | accepts space-format timestamps | ✅ | `dart test --name 'TK-DIF-6'` |

## 9. Diff helper

**Test file:** `test/tracking/diff_helper_test.dart` — **ID prefix `TK-DIFH`**

Shared diff computation used by the diff-family commands (regression / fix /
new / removed classification).

**How to test:** `dart test test/tracking/diff_helper_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-DIFH-1 | returns empty list when runs are identical | ✅ | `dart test --name 'TK-DIFH-1'` |
| TK-DIFH-2 | detects regression (OK → FAIL) | ✅ | `dart test --name 'TK-DIFH-2'` |
| TK-DIFH-3 | detects fix (FAIL → OK) | ✅ | `dart test --name 'TK-DIFH-3'` |
| TK-DIFH-4 | sorts regressions before fixes | ✅ | `dart test --name 'TK-DIFH-4'` |
| TK-DIFH-5 | finds run by MM-DD_HHMM format | ✅ | `dart test --name 'TK-DIFH-5'` |
| TK-DIFH-6 | finds run by MM-DD HH:MM format | ✅ | `dart test --name 'TK-DIFH-6'` |
| TK-DIFH-7 | returns null for non-matching timestamp | ✅ | `dart test --name 'TK-DIFH-7'` |
| TK-DIFH-8 | writes diff rows to CSV file | ✅ | `dart test --name 'TK-DIFH-8'` |
| TK-DIFH-9 | writes empty diff with no rows | ✅ | `dart test --name 'TK-DIFH-9'` |
| TK-DIFH-10 | changeLabel reflects regression/fix/other | ✅ | `dart test --name 'TK-DIFH-10'` |

## 10. `:flaky` command

**Test file:** `test/tracking/flaky_command_test.dart` — **ID prefix `TK-FLKY`**

Detects tests that alternate pass/fail across runs.

**How to test:** `dart test test/tracking/flaky_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-FLKY-1 | returns false when no baseline file exists | ✅ | `dart test --name 'TK-FLKY-1'` |
| TK-FLKY-2 | returns true with message when only 1 run | ✅ | `dart test --name 'TK-FLKY-2'` |
| TK-FLKY-3 | detects flaky tests in multi-run tracking | ✅ | `dart test --name 'TK-FLKY-3'` |
| TK-FLKY-4 | returns true with no flaky tests for stable data | ✅ | `dart test --name 'TK-FLKY-4'` |
| TK-FLKY-5 | writes CSV output to file | ✅ | `dart test --name 'TK-FLKY-5'` |
| TK-FLKY-6 | writes JSON output to file | ✅ | `dart test --name 'TK-FLKY-6'` |

## 11. `:history` command

**Test file:** `test/tracking/history_command_test.dart` — **ID prefix `TK-HIST`**

Renders a per-test pass/fail history across baseline columns.

**How to test:** `dart test test/tracking/history_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-HIST-1 | returns false when no baseline file exists | ✅ | `dart test --name 'TK-HIST-1'` |
| TK-HIST-2 | returns true for exact ID match | ✅ | `dart test --name 'TK-HIST-2'` |
| TK-HIST-3 | returns true for substring match on description | ✅ | `dart test --name 'TK-HIST-3'` |
| TK-HIST-4 | returns false for no matching tests | ✅ | `dart test --name 'TK-HIST-4'` |
| TK-HIST-5 | returns true for case-insensitive ID match | ✅ | `dart test --name 'TK-HIST-5'` |
| TK-HIST-6 | returns true for group name match | ✅ | `dart test --name 'TK-HIST-6'` |
| TK-HIST-7 | writes CSV output to file | ✅ | `dart test --name 'TK-HIST-7'` |

## 12. `:lastdiff` command

**Test file:** `test/tracking/lastdiff_command_test.dart` — **ID prefix `TK-LDIF`**

Diffs the most recent run against the previous one.

**How to test:** `dart test test/tracking/lastdiff_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-LDIF-1 | returns false when no baseline file exists | ✅ | `dart test --name 'TK-LDIF-1'` |
| TK-LDIF-2 | returns true for single-run file (no diff) | ✅ | `dart test --name 'TK-LDIF-2'` |
| TK-LDIF-3 | returns true for multi-run and detects diffs | ✅ | `dart test --name 'TK-LDIF-3'` |
| TK-LDIF-4 | writes CSV output to file | ✅ | `dart test --name 'TK-LDIF-4'` |
| TK-LDIF-5 | report option generates markdown report | ✅ | `dart test --name 'TK-LDIF-5'` |

## 13. `:reset` command

**Test file:** `test/tracking/reset_command_test.dart` — **ID prefix `TK-RST`**

Resets baseline tracking state.

**How to test:** `dart test test/tracking/reset_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-RST-1 | returns true when no doc directory exists | ✅ | `dart test --name 'TK-RST-1'` |
| TK-RST-2 | returns true when testlog directory is empty | ✅ | `dart test --name 'TK-RST-2'` |
| TK-RST-3 | deletes baseline CSV files | ✅ | `dart test --name 'TK-RST-3'` |
| TK-RST-4 | deletes last_testrun.json | ✅ | `dart test --name 'TK-RST-4'` |
| TK-RST-5 | deletes both baseline CSV and last_testrun.json | ✅ | `dart test --name 'TK-RST-5'` |
| TK-RST-6 | preserves non-tracking files in testlog/ | ✅ | `dart test --name 'TK-RST-6'` |

## 14. `:runs` command

**Test file:** `test/tracking/runs_command_test.dart` — **ID prefix `TK-RUNS`**

Lists recorded runs / baseline columns.

**How to test:** `dart test test/tracking/runs_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-RUNS-1 | returns false when no baseline file exists | ✅ | `dart test --name 'TK-RUNS-1'` |
| TK-RUNS-2 | returns true for single-run tracking file | ✅ | `dart test --name 'TK-RUNS-2'` |
| TK-RUNS-3 | returns true for multi-run tracking file | ✅ | `dart test --name 'TK-RUNS-3'` |
| TK-RUNS-4 | writes CSV output to file | ✅ | `dart test --name 'TK-RUNS-4'` |
| TK-RUNS-5 | writes JSON output to file | ✅ | `dart test --name 'TK-RUNS-5'` |

## 15. `:status` command

**Test file:** `test/tracking/status_command_test.dart` — **ID prefix `TK-STAT`**

Summarizes the current pass/fail/skip status of the latest run.

**How to test:** `dart test test/tracking/status_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-STAT-1 | returns false when no baseline file exists | ✅ | `dart test --name 'TK-STAT-1'` |
| TK-STAT-2 | returns true for single-run tracking file | ✅ | `dart test --name 'TK-STAT-2'` |
| TK-STAT-3 | returns true for multi-run tracking file | ✅ | `dart test --name 'TK-STAT-3'` |
| TK-STAT-4 | returns true with verbose flag | ✅ | `dart test --name 'TK-STAT-4'` |
| TK-STAT-5 | returns true for tracking with no runs | ✅ | `dart test --name 'TK-STAT-5'` |

## 16. `:test` command

**Test file:** `test/tracking/test_command_test.dart` — **ID prefix `TK-TST`**

End-to-end `:test` flow: run `dart test`, parse output, append a result column
to the latest baseline.

**How to test:** `dart test test/tracking/test_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-TST-1 | returns false when no tracking file exists | ✅ | `dart test --name 'TK-TST-1'` |
| TK-TST-2 | returns true with --baseline when no tracking file exists | ✅ | `dart test --name 'TK-TST-2'` |
| TK-TST-3 | updates tracking file with new run results | ✅ | `dart test --name 'TK-TST-3'` |
| TK-TST-4 | --no-update runs tests without updating baseline | ✅ | `dart test --name 'TK-TST-4'` |
| TK-TST-5 | --no-update prints summary with counts | ✅ | `dart test --name 'TK-TST-5'` |
| TK-TST-6 | --no-update shows unexpected when FAIL expectation passes | ✅ | `dart test --name 'TK-TST-6'` |
| TK-TST-7 | --no-update shows expected when FAIL expectation fails | ✅ | `dart test --name 'TK-TST-7'` |
| TK-TST-8 | --failed filters to only failed tests from last run | ✅ | `dart test --name 'TK-TST-8'` |
| TK-TST-9 | respects --test-args for filtering | ✅ | `dart test --name 'TK-TST-9'` |
| TK-TST-10 | adds comment to run when specified | ✅ | `dart test --name 'TK-TST-10'` |

## 17. `:trim` command

**Test file:** `test/tracking/trim_command_test.dart` — **ID prefix `TK-TRIM`**

Trims old baseline columns / runs to a configured retention window.

**How to test:** `dart test test/tracking/trim_command_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-TRIM-1 | returns false when no baseline file exists | ✅ | `dart test --name 'TK-TRIM-1'` |
| TK-TRIM-2 | returns false for keepCount < 1 | ✅ | `dart test --name 'TK-TRIM-2'` |
| TK-TRIM-3 | does nothing when runs <= keepCount | ✅ | `dart test --name 'TK-TRIM-3'` |
| TK-TRIM-4 | trims to keepCount, preserving baseline | ✅ | `dart test --name 'TK-TRIM-4'` |
| TK-TRIM-5 | trims with keepCount=1 preserves baseline and last run | ✅ | `dart test --name 'TK-TRIM-5'` |
| TK-TRIM-6 | preserves run count after trim | ✅ | `dart test --name 'TK-TRIM-6'` |
| TK-TRIM-7 | with verbose flag shows file information | ✅ | `dart test --name 'TK-TRIM-7'` |
| TK-TRIM-8 | file is updated on disk after trim | ✅ | `dart test --name 'TK-TRIM-8'` |

## 18. File helpers

**Test file:** `test/util/file_helpers_test.dart` — **ID prefix `TK-FIL`**

Baseline-file discovery (latest-by-name), path resolution, and I/O helpers.

**How to test:** `dart test test/util/file_helpers_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-FIL-1 | should create path with MMDD_HHMM timestamp | ✅ | `dart test --name 'TK-FIL-1'` |
| TK-FIL-2 | should zero-pad month and day | ✅ | `dart test --name 'TK-FIL-2'` |
| TK-FIL-3 | should return null when testlog/ does not exist | ✅ | `dart test --name 'TK-FIL-3'` |
| TK-FIL-4 | should return null when no baseline files exist | ✅ | `dart test --name 'TK-FIL-4'` |
| TK-FIL-5 | should return the latest baseline file by name sort | ✅ | `dart test --name 'TK-FIL-5'` |

## 19. Format helpers

**Test file:** `test/util/format_helpers_test.dart` — **ID prefix `TK-FMT`**

Result-cell formatting (`OK/OK`, `X/OK`, `--/OK`) and console rendering.

**How to test:** `dart test test/util/format_helpers_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-FMT-1 | should zero-pad single digit | ✅ | `dart test --name 'TK-FMT-1'` |
| TK-FMT-2 | should not pad two-digit number | ✅ | `dart test --name 'TK-FMT-2'` |
| TK-FMT-3 | should zero-pad zero | ✅ | `dart test --name 'TK-FMT-3'` |
| TK-FMT-4 | should handle three-digit number without truncating | ✅ | `dart test --name 'TK-FMT-4'` |
| TK-FMT-5 | should escape pipe characters | ✅ | `dart test --name 'TK-FMT-5'` |
| TK-FMT-6 | should return unchanged text without pipes | ✅ | `dart test --name 'TK-FMT-6'` |
| TK-FMT-7 | should format as MMDD_HHMM | ✅ | `dart test --name 'TK-FMT-7'` |

## 20. Markdown table parser

**Test file:** `test/util/markdown_table_test.dart` — **ID prefix `TK-MDT`**

Splits/renders markdown table rows (escaped-pipe handling), parses baseline
headers, and classifies result cells.

**How to test:** `dart test test/util/markdown_table_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-MDT-1 | should split a simple row into cells | ✅ | `dart test --name 'TK-MDT-1'` |
| TK-MDT-2 | should handle escaped pipes within cells | ✅ | `dart test --name 'TK-MDT-2'` |
| TK-MDT-3 | should return empty list for non-table line | ✅ | `dart test --name 'TK-MDT-3'` |
| TK-MDT-4 | should return empty list for empty string | ✅ | `dart test --name 'TK-MDT-4'` |
| TK-MDT-5 | should handle single-cell row | ✅ | `dart test --name 'TK-MDT-5'` |
| TK-MDT-6 | should parse Baseline header | ✅ | `dart test --name 'TK-MDT-6'` |
| TK-MDT-7 | should parse non-baseline header | ✅ | `dart test --name 'TK-MDT-7'` |
| TK-MDT-8 | should return null for invalid header | ✅ | `dart test --name 'TK-MDT-8'` |
| TK-MDT-9 | should return null for empty string | ✅ | `dart test --name 'TK-MDT-9'` |
| TK-MDT-10 | should parse OK/OK as ok | ✅ | `dart test --name 'TK-MDT-10'` |
| TK-MDT-11 | should parse X/OK as fail | ✅ | `dart test --name 'TK-MDT-11'` |
| TK-MDT-12 | should parse -/OK as skip | ✅ | `dart test --name 'TK-MDT-12'` |
| TK-MDT-13 | should parse --/OK as absent | ✅ | `dart test --name 'TK-MDT-13'` |
| TK-MDT-14 | should return absent for unknown cell | ✅ | `dart test --name 'TK-MDT-14'` |
| TK-MDT-15 | should parse full label with ID, date, and expectation | ✅ | `dart test --name 'TK-MDT-15'` |
| TK-MDT-16 | should parse label without ID | ✅ | `dart test --name 'TK-MDT-16'` |
| TK-MDT-17 | should parse label with ID but no date or expectation | ✅ | `dart test --name 'TK-MDT-17'` |
| TK-MDT-18 | should default expectation to OK when PASS is specified | ✅ | `dart test --name 'TK-MDT-18'` |
| TK-MDT-19 | should parse ID, groups, and description columns | ✅ | `dart test --name 'TK-MDT-19'` |
| TK-MDT-20 | should handle empty ID and groups | ✅ | `dart test --name 'TK-MDT-20'` |
| TK-MDT-21 | should extract date and FAIL from description | ✅ | `dart test --name 'TK-MDT-21'` |

## 21. Output formatter

**Test file:** `test/util/output_formatter_test.dart` — **ID prefix `TK-OFMT`**

`OutputFormat`/`OutputSpec` parsing (incl. the `text`→`plain` and
`markdown`→`md` aliases and the first-colon `<format>:<file>` split) and
per-format table rendering. See the cross-tool
[CLI Output Formats contract](../../../basics/tom_build_base/doc/cli_output_formats.md).

**How to test:** `dart test test/util/output_formatter_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-OFMT-1 | tryParse returns correct formats | ✅ | `dart test --name 'TK-OFMT-1'` |
| TK-OFMT-2 | tryParse is case-insensitive | ✅ | `dart test --name 'TK-OFMT-2'` |
| TK-OFMT-3 | tryParse returns null for invalid format | ✅ | `dart test --name 'TK-OFMT-3'` |
| TK-OFMT-15 | tryParse accepts the cross-tool "text" alias for plain | ✅ | `dart test --name 'TK-OFMT-15'` |
| TK-OFMT-4 | tryParse with format only | ✅ | `dart test --name 'TK-OFMT-4'` |
| TK-OFMT-5 | tryParse with format and file path | ✅ | `dart test --name 'TK-OFMT-5'` |
| TK-OFMT-6 | tryParse returns null for invalid format | ✅ | `dart test --name 'TK-OFMT-6'` |
| TK-OFMT-7 | tryParse with colon but empty file path | ✅ | `dart test --name 'TK-OFMT-7'` |
| TK-OFMT-8 | defaultSpec is plain to stdout | ✅ | `dart test --name 'TK-OFMT-8'` |
| TK-OFMT-9 | tryParse with markdown alias | ✅ | `dart test --name 'TK-OFMT-9'` |
| TK-OFMT-10 | writes CSV to file | ✅ | `dart test --name 'TK-OFMT-10'` |
| TK-OFMT-11 | writes JSON to file | ✅ | `dart test --name 'TK-OFMT-11'` |
| TK-OFMT-12 | writes Markdown to file | ✅ | `dart test --name 'TK-OFMT-12'` |
| TK-OFMT-13 | writes plain text to file | ✅ | `dart test --name 'TK-OFMT-13'` |
| TK-OFMT-14 | creates parent directories for output file | ✅ | `dart test --name 'TK-OFMT-14'` |

## 22. v2 CLI tool wiring

**Test file:** `test/v2/testkit_tool_test.dart` — **ID prefix `TK-CLI`**

Verifies the v2 `ToolDefinition`/`ToolRunner` wiring (commands, options,
help/version) built on `tom_build_base`.

**How to test:** `dart test test/v2/testkit_tool_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| TK-CLI-1 | Tool has correct name and mode | ✅ | `dart test --name 'TK-CLI-1'` |
| TK-CLI-2 | Tool has expected commands | ✅ | `dart test --name 'TK-CLI-2'` |
| TK-CLI-NEG01 | Tool definition does not register macro/define | ✅ | `dart test --name 'TK-CLI-NEG01'` |
