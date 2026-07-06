# Tom Issue Kit — Test Coverage

This document maps every issuekit feature area to its test file, test count, and
regression handle (test-ID prefix), and enumerates every individual test as an
`ID / Feature / Status / How to Test` row per area, so critical flows have clear
coverage and stable regression checks. It mirrors the coverage documents for
[buildkit](../../../basics/tom_build_kit/doc/test_coverage.md) and
[tom_build_base](../../../basics/tom_build_base/doc/test_coverage.md).

> **Note on `IK-` prefixes:** the integration and scanner suites embed fixture
> test files whose bodies contain their own `test('<ID>: …')` declarations
> (e.g. `TA-*`, `VA-*`, `PR-*`). Those are scanner input data, **not** registered
> issuekit tests, so the per-test-ID tables below list only the real `IK-*`
> tests (308 total, matching `dart test`).

## Status Legend

- ✅ Test implemented and passing
- ⬜ Test not yet implemented

## How to run

```bash
cd tom_ai/devops/tom_issue_kit
dart test          # full suite (authoritative)
testkit :test      # tracked run against the latest baseline
```

The authoritative total below (**308 passing**) is the count reported by
`dart test`. Per-file counts are the tests executed from each suite; test IDs
follow the `IK-<AREA>-<n>` convention (e.g. `IK-EXE-ANZ-1`), which is the stable
handle for regression tracking.

---

## Overview

| # | Feature Area | Tests | Status | Test File | ID Prefix |
|---|-------------|-------|--------|-----------|-----------|
| 1 | [Configuration](#1-configuration) | 19 | 19✅ | `config/issuekit_config_test.dart` | `IK-CFG` |
| 2 | [Executor integration](#2-executor-integration) | 21 | 21✅ | `integration/executor_integration_test.dart` | `IK-INT` |
| 3 | [Issue service](#3-issue-service) | 41 | 41✅ | `services/issue_service_test.dart` | `IK-ANZ`/`IK-ASN`/… |
| 4 | [Test scanner service](#4-test-scanner-service) | 14 | 14✅ | `services/test_scanner_test.dart` | `IK-SCN` |
| 5 | [Output formatter](#5-output-formatter) | 23 | 23✅ | `util/output_formatter_test.dart` | `IK-FMT` |
| 6 | [v2 command executors](#6-v2-command-executors) | 105 | 105✅ | `v2/executor_test.dart` | `IK-EXE-*` |
| 7 | [v2 CLI tool wiring](#7-v2-cli-tool-wiring) | 12 | 12✅ | `v2/issuekit_tool_test.dart` | `IK-CLI` |
| 8 | [v2 traversal executors](#8-v2-traversal-executors) | 73 | 73✅ | `v2/traversal_executor_test.dart` | `IK-EXE-*` |
| — | **Total** | **308** | **308✅** | | |

---

## 1. Configuration

**Test file:** `test/config/issuekit_config_test.dart` — **ID prefix `IK-CFG`**

Covers `IssuekitConfig` loading/merging: repository resolution, GitHub token
sourcing, defaults, and validation of required fields.

**How to test:** `dart test test/config/issuekit_config_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| IK-CFG-1 | Parse valid config | ✅ | `dart test --name 'IK-CFG-1'` |
| IK-CFG-2 | Parse config with defaults | ✅ | `dart test --name 'IK-CFG-2'` |
| IK-CFG-3 | Return null for missing required fields | ✅ | `dart test --name 'IK-CFG-3'` |
| IK-CFG-4 | Extract owner and repo name from repo string | ✅ | `dart test --name 'IK-CFG-4'` |
| IK-CFG-5 | Owner and repo accessors on config | ✅ | `dart test --name 'IK-CFG-5'` |
| IK-CFG-6 | Parse valid project config | ✅ | `dart test --name 'IK-CFG-6'` |
| IK-CFG-7 | Return null for missing project_id | ✅ | `dart test --name 'IK-CFG-7'` |
| IK-CFG-8 | Validate project ID format | ✅ | `dart test --name 'IK-CFG-8'` |
| IK-CFG-9 | Resolve token from direct value | ✅ | `dart test --name 'IK-CFG-9'` |
| IK-CFG-10 | Resolve token from environment variable | ✅ | `dart test --name 'IK-CFG-10'` |
| IK-CFG-11 | Resolve token from file | ✅ | `dart test --name 'IK-CFG-11'` |
| IK-CFG-12 | Return null when no token available | ✅ | `dart test --name 'IK-CFG-12'` |
| IK-CFG-13 | Parse from map with defaults | ✅ | `dart test --name 'IK-CFG-13'` |
| IK-CFG-14 | Parse from map with custom values | ✅ | `dart test --name 'IK-CFG-14'` |
| IK-CFG-15 | isValid returns true when issueTracking is set | ✅ | `dart test --name 'IK-CFG-15'` |
| IK-CFG-16 | isValid returns false when issueTracking is null | ✅ | `dart test --name 'IK-CFG-16'` |
| IK-CFG-17 | Load from workspace directory | ✅ | `dart test --name 'IK-CFG-17'` |
| IK-CFG-18 | Load project config from project directory | ✅ | `dart test --name 'IK-CFG-18'` |
| IK-CFG-19 | Return null when project yaml missing | ✅ | `dart test --name 'IK-CFG-19'` |

## 2. Executor integration

**Test file:** `test/integration/executor_integration_test.dart` — **ID prefix `IK-INT`**

End-to-end integration across executors: workspace scan (`IK-INT-WS`,
`IK-INT-SCN`), parameter resolution (`IK-INT-PRM`), validation (`IK-INT-VAL`),
and aggregation (`IK-INT-AGG`) using stubbed services.

**How to test:** `dart test test/integration/executor_integration_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| IK-INT-SCN-1 | scans real test files for issue-linked tests | ✅ | `dart test --name 'IK-INT-SCN-1'` |
| IK-INT-SCN-2 | filters by issue number | ✅ | `dart test --name 'IK-INT-SCN-2'` |
| IK-INT-SCN-3 | handles tests across multiple files | ✅ | `dart test --name 'IK-INT-SCN-3'` |
| IK-INT-SCN-4 | returns empty for project with no issue-linked tests | ✅ | `dart test --name 'IK-INT-SCN-4'` |
| IK-INT-VAL-1 | validates project with no issues | ✅ | `dart test --name 'IK-INT-VAL-1'` |
| IK-INT-VAL-2 | detects duplicate test IDs | ✅ | `dart test --name 'IK-INT-VAL-2'` |
| IK-INT-VAL-3 | detects regular/promoted conflicts | ✅ | `dart test --name 'IK-INT-VAL-3'` |
| IK-INT-VAL-4 | --fix removes regular ID when promoted exists | ✅ | `dart test --name 'IK-INT-VAL-4'` |
| IK-INT-VAL-5 | --fix --dry-run does not modify files | ✅ | `dart test --name 'IK-INT-VAL-5'` |
| IK-INT-PRM-1 | promotes regular test ID to issue-linked | ✅ | `dart test --name 'IK-INT-PRM-1'` |
| IK-INT-PRM-2 | --dry-run shows preview without modifying | ✅ | `dart test --name 'IK-INT-PRM-2'` |
| IK-INT-PRM-3 | reports not found when test ID absent | ✅ | `dart test --name 'IK-INT-PRM-3'` |
| IK-INT-AGG-1 | aggregates tests from project | ✅ | `dart test --name 'IK-INT-AGG-1'` |
| IK-INT-AGG-2 | filters by issue number | ✅ | `dart test --name 'IK-INT-AGG-2'` |
| IK-INT-AGG-3 | detects regressions in baseline results | ✅ | `dart test --name 'IK-INT-AGG-3'` |
| IK-INT-AGG-4 | handles project with no tests | ✅ | `dart test --name 'IK-INT-AGG-4'` |
| IK-INT-WS-1 | scans multiple projects in workspace | ✅ | `dart test --name 'IK-INT-WS-1'` |
| IK-INT-WS-2 | validates each project independently | ✅ | `dart test --name 'IK-INT-WS-2'` |
| IK-INT-WS-3 | handles nested project directories | ✅ | `dart test --name 'IK-INT-WS-3'` |
| IK-INT-E2E-1 | scan → validate → promote workflow | ✅ | `dart test --name 'IK-INT-E2E-1'` |
| IK-INT-E2E-2 | detect conflict → fix workflow | ✅ | `dart test --name 'IK-INT-E2E-2'` |

## 3. Issue service

**Test file:** `test/services/issue_service_test.dart` — **ID prefixes `IK-INIT`,
`IK-ANZ`, `IK-ASN`, `IK-CLS`, `IK-EDT`, `IK-EXP`, `IK-IMP`, `IK-LINK`**

Covers the full issue lifecycle service: init, analyze, assign, close, edit,
export, import, and test-link operations against the GitHub issue tracker.

**How to test:** `dart test test/services/issue_service_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| IK-NEW-1 | creates issue with title only | ✅ | `dart test --name 'IK-NEW-1'` |
| IK-NEW-2 | creates issue with severity | ✅ | `dart test --name 'IK-NEW-2'` |
| IK-NEW-3 | creates issue with context and expected | ✅ | `dart test --name 'IK-NEW-3'` |
| IK-NEW-4 | creates issue with tags | ✅ | `dart test --name 'IK-NEW-4'` |
| IK-NEW-5 | creates issue with reporter | ✅ | `dart test --name 'IK-NEW-5'` |
| IK-NEW-6 | creates issue with --project skips to ASSIGNED | ✅ | `dart test --name 'IK-NEW-6'` |
| IK-SHW-1 | gets issue by number | ✅ | `dart test --name 'IK-SHW-1'` |
| IK-LST-1 | lists all open issues | ✅ | `dart test --name 'IK-LST-1'` |
| IK-LST-2 | lists issues by state | ✅ | `dart test --name 'IK-LST-2'` |
| IK-LST-3 | lists issues by severity | ✅ | `dart test --name 'IK-LST-3'` |
| IK-LST-4 | lists issues including closed | ✅ | `dart test --name 'IK-LST-4'` |
| IK-SRC-1 | searches issues by query | ✅ | `dart test --name 'IK-SRC-1'` |
| IK-SRC-2 | searches in tests repo | ✅ | `dart test --name 'IK-SRC-2'` |
| IK-CLS-1 | closes resolved issue | ✅ | `dart test --name 'IK-CLS-1'` |
| IK-CLS-2 | throws when issue is not resolved | ✅ | `dart test --name 'IK-CLS-2'` |
| IK-ROP-1 | reopens closed issue | ✅ | `dart test --name 'IK-ROP-1'` |
| IK-ROP-2 | reopens with note adds comment | ✅ | `dart test --name 'IK-ROP-2'` |
| IK-EDT-1 | updates issue title | ✅ | `dart test --name 'IK-EDT-1'` |
| IK-EDT-2 | updates issue severity | ✅ | `dart test --name 'IK-EDT-2'` |
| IK-ANZ-1 | analyze without project transitions to ANALYZED | ✅ | `dart test --name 'IK-ANZ-1'` |
| IK-ANZ-2 | analyze with project transitions to ASSIGNED and creates test entry | ✅ | `dart test --name 'IK-ANZ-2'` |
| IK-ANZ-3 | analysis comment contains root cause and note | ✅ | `dart test --name 'IK-ANZ-3'` |
| IK-ASN-1 | assigns issue to project and creates test entry | ✅ | `dart test --name 'IK-ASN-1'` |
| IK-ASN-2 | assign with module and assignee | ✅ | `dart test --name 'IK-ASN-2'` |
| IK-ASN-3 | test entry includes module label when specified | ✅ | `dart test --name 'IK-ASN-3'` |
| IK-RSV-1 | resolves verifying issue to RESOLVED | ✅ | `dart test --name 'IK-RSV-1'` |
| IK-RSV-2 | throws if issue is not in VERIFYING state | ✅ | `dart test --name 'IK-RSV-2'` |
| IK-RSV-3 | resolution comment contains fix and note | ✅ | `dart test --name 'IK-RSV-3'` |
| IK-SUM-1 | aggregates issues by state, severity, project | ✅ | `dart test --name 'IK-SUM-1'` |
| IK-SUM-2 | returns empty summary for no issues | ✅ | `dart test --name 'IK-SUM-2'` |
| IK-INIT-1 | creates labels in both repos | ✅ | `dart test --name 'IK-INIT-1'` |
| IK-INIT-2 | creates labels only in issues repo | ✅ | `dart test --name 'IK-INIT-2'` |
| IK-INIT-3 | skips existing labels without force | ✅ | `dart test --name 'IK-INIT-3'` |
| IK-LINK-1 | posts link comment with test ID | ✅ | `dart test --name 'IK-LINK-1'` |
| IK-EXP-1 | exports issues from issues repo | ✅ | `dart test --name 'IK-EXP-1'` |
| IK-EXP-2 | exports from tests repo with filters | ✅ | `dart test --name 'IK-EXP-2'` |
| IK-SNAP-1 | creates full snapshot of both repos | ✅ | `dart test --name 'IK-SNAP-1'` |
| IK-SNAP-2 | issues-only snapshot skips tests | ✅ | `dart test --name 'IK-SNAP-2'` |
| IK-RUNTESTS-1 | dispatches workflow | ✅ | `dart test --name 'IK-RUNTESTS-1'` |
| IK-IMP-1 | creates issues from entries | ✅ | `dart test --name 'IK-IMP-1'` |
| IK-IMP-2 | dry-run returns empty without creating | ✅ | `dart test --name 'IK-IMP-2'` |

## 4. Test scanner service

**Test file:** `test/services/test_scanner_test.dart` — **ID prefixes `IK-SCN`,
`IK-SCN-BL`, `IK-SCN-ISS`, `IK-SCN-PB`**

Scans test files for IDs and issue linkage; associates scanned tests with
baseline (`-BL`), issues (`-ISS`), and pubspec (`-PB`) context.

**How to test:** `dart test test/services/test_scanner_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| IK-SCN-1 | finds issue-linked test IDs in test files | ✅ | `dart test --name 'IK-SCN-1'` |
| IK-SCN-2 | finds regular (non-issue-linked) test IDs | ✅ | `dart test --name 'IK-SCN-2'` |
| IK-SCN-3 | returns empty when no test directory exists | ✅ | `dart test --name 'IK-SCN-3'` |
| IK-SCN-4 | scans recursively through test subdirectories | ✅ | `dart test --name 'IK-SCN-4'` |
| IK-SCN-5 | ignores non-test dart files | ✅ | `dart test --name 'IK-SCN-5'` |
| IK-SCN-6 | detects group-level test IDs | ✅ | `dart test --name 'IK-SCN-6'` |
| IK-SCN-ISS-1 | returns only tests matching the issue number | ✅ | `dart test --name 'IK-SCN-ISS-1'` |
| IK-SCN-ISS-2 | returns empty when no tests match issue | ✅ | `dart test --name 'IK-SCN-ISS-2'` |
| IK-SCN-BL-1 | reads the most recent baseline file | ✅ | `dart test --name 'IK-SCN-BL-1'` |
| IK-SCN-BL-2 | returns null when no baselines exist | ✅ | `dart test --name 'IK-SCN-BL-2'` |
| IK-SCN-BL-3 | returns null when doc directory does not exist | ✅ | `dart test --name 'IK-SCN-BL-3'` |
| IK-SCN-PB-1 | parses baseline CSV into ID-status map | ✅ | `dart test --name 'IK-SCN-PB-1'` |
| IK-SCN-PB-2 | handles quoted fields with commas | ✅ | `dart test --name 'IK-SCN-PB-2'` |
| IK-SCN-PB-3 | returns empty for minimal input | ✅ | `dart test --name 'IK-SCN-PB-3'` |

## 5. Output formatter

**Test file:** `test/util/output_formatter_test.dart` — **ID prefix `IK-FMT`**

`OutputFormat`/`OutputSpec` parsing (incl. the `text`→`plain` and
`markdown`→`md` aliases and the first-colon `<format>:<file>` split) and
per-format rendering. See the cross-tool
[CLI Output Formats contract](../../../basics/tom_build_base/doc/cli_output_formats.md).

**How to test:** `dart test test/util/output_formatter_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| IK-FMT-1 | Parse format without filename | ✅ | `dart test --name 'IK-FMT-1'` |
| IK-FMT-2 | Parse format with filename | ✅ | `dart test --name 'IK-FMT-2'` |
| IK-FMT-3 | Parse all format types | ✅ | `dart test --name 'IK-FMT-3'` |
| IK-FMT-4 | Return null for invalid format | ✅ | `dart test --name 'IK-FMT-4'` |
| IK-FMT-5 | Handle filename with colon | ✅ | `dart test --name 'IK-FMT-5'` |
| IK-FMT-6 | Format plain text table | ✅ | `dart test --name 'IK-FMT-6'` |
| IK-FMT-7 | Format table without headers | ✅ | `dart test --name 'IK-FMT-7'` |
| IK-FMT-8 | Handle empty table | ✅ | `dart test --name 'IK-FMT-8'` |
| IK-FMT-9 | Format CSV with headers | ✅ | `dart test --name 'IK-FMT-9'` |
| IK-FMT-10 | Escape CSV values with commas | ✅ | `dart test --name 'IK-FMT-10'` |
| IK-FMT-11 | Escape CSV values with quotes | ✅ | `dart test --name 'IK-FMT-11'` |
| IK-FMT-12 | Escape CSV values with newlines | ✅ | `dart test --name 'IK-FMT-12'` |
| IK-FMT-13 | Format JSON with pretty print | ✅ | `dart test --name 'IK-FMT-13'` |
| IK-FMT-14 | Format JSON compact | ✅ | `dart test --name 'IK-FMT-14'` |
| IK-FMT-15 | Format JSON list | ✅ | `dart test --name 'IK-FMT-15'` |
| IK-FMT-16 | Format Markdown table | ✅ | `dart test --name 'IK-FMT-16'` |
| IK-FMT-17 | Format Markdown with alignment | ✅ | `dart test --name 'IK-FMT-17'` |
| IK-FMT-18 | Escape pipe in Markdown cells | ✅ | `dart test --name 'IK-FMT-18'` |
| IK-FMT-19 | Parse severity strings | ✅ | `dart test --name 'IK-FMT-19'` |
| IK-FMT-20 | Severity display names | ✅ | `dart test --name 'IK-FMT-20'` |
| IK-FMT-21 | Parse issue state strings | ✅ | `dart test --name 'IK-FMT-21'` |
| IK-FMT-22 | Issue state label names | ✅ | `dart test --name 'IK-FMT-22'` |
| IK-FMT-23 | Issue state display names | ✅ | `dart test --name 'IK-FMT-23'` |

## 6. v2 command executors

**Test file:** `test/v2/executor_test.dart` — **ID prefix `IK-EXE-*`**

The largest suite: one executor per issuekit command (analyze `IK-EXE-ANZ`,
assign `IK-EXE-ASN`, close `IK-EXE-CLS`, edit `IK-EXE-EDT`, export `IK-EXE-EXP`,
import `IK-EXE-IMP`, init `IK-EXE-INIT`, reopen `IK-EXE-ROP`, …) plus the
`createIssuekitExecutors` factory (`IK-EXE-FAC`). Verifies command→executor
wiring, argument handling, and `ItemResult` outcomes.

**How to test:** `dart test test/v2/executor_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| IK-EXE-NEW-1 | creates issue with title only | ✅ | `dart test --name 'IK-EXE-NEW-1'` |
| IK-EXE-NEW-2 | creates issue with all options | ✅ | `dart test --name 'IK-EXE-NEW-2'` |
| IK-EXE-NEW-3 | fails when title is missing | ✅ | `dart test --name 'IK-EXE-NEW-3'` |
| IK-EXE-NEW-4 | handles service exception | ✅ | `dart test --name 'IK-EXE-NEW-4'` |
| IK-EXE-EDT-1 | updates issue title | ✅ | `dart test --name 'IK-EXE-EDT-1'` |
| IK-EXE-EDT-2 | updates multiple fields | ✅ | `dart test --name 'IK-EXE-EDT-2'` |
| IK-EXE-EDT-3 | fails when issue number missing | ✅ | `dart test --name 'IK-EXE-EDT-3'` |
| IK-EXE-EDT-4 | fails with non-numeric issue number | ✅ | `dart test --name 'IK-EXE-EDT-4'` |
| IK-EXE-SHW-1 | shows issue details | ✅ | `dart test --name 'IK-EXE-SHW-1'` |
| IK-EXE-SHW-2 | shows issue with no assignee | ✅ | `dart test --name 'IK-EXE-SHW-2'` |
| IK-EXE-SHW-3 | fails when issue number missing | ✅ | `dart test --name 'IK-EXE-SHW-3'` |
| IK-EXE-SHW-4 | handles API error | ✅ | `dart test --name 'IK-EXE-SHW-4'` |
| IK-EXE-LST-1 | lists all open issues with no filters | ✅ | `dart test --name 'IK-EXE-LST-1'` |
| IK-EXE-LST-2 | lists with state filter | ✅ | `dart test --name 'IK-EXE-LST-2'` |
| IK-EXE-LST-3 | lists with multiple filters | ✅ | `dart test --name 'IK-EXE-LST-3'` |
| IK-EXE-LST-4 | lists with --all flag | ✅ | `dart test --name 'IK-EXE-LST-4'` |
| IK-EXE-LST-5 | lists with tags filter | ✅ | `dart test --name 'IK-EXE-LST-5'` |
| IK-EXE-LST-6 | handles service error | ✅ | `dart test --name 'IK-EXE-LST-6'` |
| IK-EXE-SRC-1 | searches issues by query | ✅ | `dart test --name 'IK-EXE-SRC-1'` |
| IK-EXE-SRC-2 | searches in tests repo | ✅ | `dart test --name 'IK-EXE-SRC-2'` |
| IK-EXE-SRC-3 | fails when query is missing | ✅ | `dart test --name 'IK-EXE-SRC-3'` |
| IK-EXE-SRC-4 | returns empty results | ✅ | `dart test --name 'IK-EXE-SRC-4'` |
| IK-EXE-CLS-1 | closes resolved issue | ✅ | `dart test --name 'IK-EXE-CLS-1'` |
| IK-EXE-CLS-2 | fails when issue is not resolved | ✅ | `dart test --name 'IK-EXE-CLS-2'` |
| IK-EXE-CLS-3 | fails when issue number missing | ✅ | `dart test --name 'IK-EXE-CLS-3'` |
| IK-EXE-ROP-1 | reopens issue without note | ✅ | `dart test --name 'IK-EXE-ROP-1'` |
| IK-EXE-ROP-2 | reopens issue with note | ✅ | `dart test --name 'IK-EXE-ROP-2'` |
| IK-EXE-ROP-3 | fails when issue number missing | ✅ | `dart test --name 'IK-EXE-ROP-3'` |
| IK-EXE-ROP-4 | handles service error | ✅ | `dart test --name 'IK-EXE-ROP-4'` |
| IK-EXE-ANZ-1 | analyzes issue with root cause only (→ ANALYZED) | ✅ | `dart test --name 'IK-EXE-ANZ-1'` |
| IK-EXE-ANZ-2 | analyzes with project (→ ASSIGNED + test entry) | ✅ | `dart test --name 'IK-EXE-ANZ-2'` |
| IK-EXE-ANZ-3 | returns failure when issue number missing | ✅ | `dart test --name 'IK-EXE-ANZ-3'` |
| IK-EXE-ANZ-4 | returns failure on service exception | ✅ | `dart test --name 'IK-EXE-ANZ-4'` |
| IK-EXE-ASN-1 | assigns issue to project | ✅ | `dart test --name 'IK-EXE-ASN-1'` |
| IK-EXE-ASN-2 | assigns with module and assignee | ✅ | `dart test --name 'IK-EXE-ASN-2'` |
| IK-EXE-ASN-3 | returns failure when issue number missing | ✅ | `dart test --name 'IK-EXE-ASN-3'` |
| IK-EXE-ASN-4 | returns failure when --project missing | ✅ | `dart test --name 'IK-EXE-ASN-4'` |
| IK-EXE-ASN-5 | returns failure on service exception | ✅ | `dart test --name 'IK-EXE-ASN-5'` |
| IK-EXE-RSV-1 | resolves issue with fix description | ✅ | `dart test --name 'IK-EXE-RSV-1'` |
| IK-EXE-RSV-2 | resolves with fix and note | ✅ | `dart test --name 'IK-EXE-RSV-2'` |
| IK-EXE-RSV-3 | returns failure when issue number missing | ✅ | `dart test --name 'IK-EXE-RSV-3'` |
| IK-EXE-RSV-4 | returns failure when not in VERIFYING state | ✅ | `dart test --name 'IK-EXE-RSV-4'` |
| IK-EXE-SUM-1 | returns summary on success | ✅ | `dart test --name 'IK-EXE-SUM-1'` |
| IK-EXE-SUM-2 | returns failure on exception | ✅ | `dart test --name 'IK-EXE-SUM-2'` |
| IK-EXE-LNK-1 | links test on success | ✅ | `dart test --name 'IK-EXE-LNK-1'` |
| IK-EXE-LNK-2 | fails without issue number | ✅ | `dart test --name 'IK-EXE-LNK-2'` |
| IK-EXE-LNK-3 | fails without test-id | ✅ | `dart test --name 'IK-EXE-LNK-3'` |
| IK-EXE-LNK-4 | fails on service exception | ✅ | `dart test --name 'IK-EXE-LNK-4'` |
| IK-EXE-EXP-1 | exports issues and builds result | ✅ | `dart test --name 'IK-EXE-EXP-1'` |
| IK-EXE-EXP-2 | passes filters to service | ✅ | `dart test --name 'IK-EXE-EXP-2'` |
| IK-EXE-EXP-3 | fails on service exception | ✅ | `dart test --name 'IK-EXE-EXP-3'` |
| IK-EXE-IMP-1 | fails when file not found | ✅ | `dart test --name 'IK-EXE-IMP-1'` |
| IK-EXE-IMP-2 | fails without file path | ✅ | `dart test --name 'IK-EXE-IMP-2'` |
| IK-EXE-IMP-3 | reports dry-run in message | ✅ | `dart test --name 'IK-EXE-IMP-3'` |
| IK-EXE-INIT-1 | initializes labels on success | ✅ | `dart test --name 'IK-EXE-INIT-1'` |
| IK-EXE-INIT-2 | passes repo and force options | ✅ | `dart test --name 'IK-EXE-INIT-2'` |
| IK-EXE-INIT-3 | fails on service exception | ✅ | `dart test --name 'IK-EXE-INIT-3'` |
| IK-EXE-SNP-1 | creates snapshot on success | ✅ | `dart test --name 'IK-EXE-SNP-1'` |
| IK-EXE-SNP-2 | passes filter options | ✅ | `dart test --name 'IK-EXE-SNP-2'` |
| IK-EXE-SNP-3 | fails on service exception | ✅ | `dart test --name 'IK-EXE-SNP-3'` |
| IK-EXE-RT-1 | triggers workflow on success | ✅ | `dart test --name 'IK-EXE-RT-1'` |
| IK-EXE-RT-2 | passes wait option | ✅ | `dart test --name 'IK-EXE-RT-2'` |
| IK-EXE-RT-3 | fails on service exception | ✅ | `dart test --name 'IK-EXE-RT-3'` |
| IK-EXE-NEW-7 | generic Exception wraps in error message | ✅ | `dart test --name 'IK-EXE-NEW-7'` |
| IK-EXE-NEW-8 | result without test entry excludes Test entry text | ✅ | `dart test --name 'IK-EXE-NEW-8'` |
| IK-EXE-EDT-6 | handles IssueServiceException | ✅ | `dart test --name 'IK-EXE-EDT-6'` |
| IK-EXE-EDT-7 | handles generic Exception | ✅ | `dart test --name 'IK-EXE-EDT-7'` |
| IK-EXE-EDT-8 | edit with no field options still calls service | ✅ | `dart test --name 'IK-EXE-EDT-8'` |
| IK-EXE-SHW-10 | IssueServiceException uses direct message | ✅ | `dart test --name 'IK-EXE-SHW-10'` |
| IK-EXE-SHW-11 | output contains State/Created/Updated fields | ✅ | `dart test --name 'IK-EXE-SHW-11'` |
| IK-EXE-SRC-5 | handles IssueServiceException | ✅ | `dart test --name 'IK-EXE-SRC-5'` |
| IK-EXE-CLS-5 | non-numeric issue number fails | ✅ | `dart test --name 'IK-EXE-CLS-5'` |
| IK-EXE-ROP-6 | non-numeric issue number fails | ✅ | `dart test --name 'IK-EXE-ROP-6'` |
| IK-EXE-ANZ-7 | non-numeric issue number fails | ✅ | `dart test --name 'IK-EXE-ANZ-7'` |
| IK-EXE-SUM-3 | empty summary handles zero counts | ✅ | `dart test --name 'IK-EXE-SUM-3'` |
| IK-EXE-SUM-4 | no attention items omits attention section | ✅ | `dart test --name 'IK-EXE-SUM-4'` |
| IK-EXE-LNK-5 | --note option passed to service | ✅ | `dart test --name 'IK-EXE-LNK-5'` |
| IK-EXE-LNK-6 | non-numeric issue number fails | ✅ | `dart test --name 'IK-EXE-LNK-6'` |
| IK-EXE-LNK-7 | links without --test-file | ✅ | `dart test --name 'IK-EXE-LNK-7'` |
| IK-EXE-EXP-4 | --state filter passed to service | ✅ | `dart test --name 'IK-EXE-EXP-4'` |
| IK-EXE-EXP-5 | --tags with comma-separated parsing | ✅ | `dart test --name 'IK-EXE-EXP-5'` |
| IK-EXE-EXP-6 | empty export result | ✅ | `dart test --name 'IK-EXE-EXP-6'` |
| IK-EXE-EXP-7 | default options verified | ✅ | `dart test --name 'IK-EXE-EXP-7'` |
| IK-EXE-IMP-4 | successful import from JSON file | ✅ | `dart test --name 'IK-EXE-IMP-4'` |
| IK-EXE-IMP-6 | --repo option passed to service | ✅ | `dart test --name 'IK-EXE-IMP-6'` |
| IK-EXE-IMP-7 | IssueServiceException during import | ✅ | `dart test --name 'IK-EXE-IMP-7'` |
| IK-EXE-IMP-9 | empty JSON file imports zero entries | ✅ | `dart test --name 'IK-EXE-IMP-9'` |
| IK-EXE-INIT-4 | default options verified | ✅ | `dart test --name 'IK-EXE-INIT-4'` |
| IK-EXE-SNP-4 | tests-only filter | ✅ | `dart test --name 'IK-EXE-SNP-4'` |
| IK-EXE-SNP-5 | default options verified | ✅ | `dart test --name 'IK-EXE-SNP-5'` |
| IK-EXE-RT-4 | default wait=false verified | ✅ | `dart test --name 'IK-EXE-RT-4'` |
| IK-EXE-LST-7 | --reporter filter passed to service | ✅ | `dart test --name 'IK-EXE-LST-7'` |
| IK-EXE-LST-9 | IssueServiceException uses direct message | ✅ | `dart test --name 'IK-EXE-LST-9'` |
| IK-EXE-LST-10 | issue with no labels handled gracefully | ✅ | `dart test --name 'IK-EXE-LST-10'` |
| IK-EXE-NEW-5 | --project creates test entry and reports it | ✅ | `dart test --name 'IK-EXE-NEW-5'` |
| IK-EXE-NEW-6 | --reporter captures filer identity | ✅ | `dart test --name 'IK-EXE-NEW-6'` |
| IK-EXE-RSV-5 | resolves with both fix and note | ✅ | `dart test --name 'IK-EXE-RSV-5'` |
| IK-EXE-CLS-4 | handles API error on close | ✅ | `dart test --name 'IK-EXE-CLS-4'` |
| IK-EXE-EDT-5 | reassigns to different project | ✅ | `dart test --name 'IK-EXE-EDT-5'` |
| IK-EXE-ANZ-5 | analyze without --project moves to ANALYZED only | ✅ | `dart test --name 'IK-EXE-ANZ-5'` |
| IK-EXE-ANZ-6 | analyze with --project creates test entry | ✅ | `dart test --name 'IK-EXE-ANZ-6'` |
| IK-EXE-ROP-5 | reopened issue resets to NEW state | ✅ | `dart test --name 'IK-EXE-ROP-5'` |
| IK-EXE-FAC-1 | creates all executors matching commands | ✅ | `dart test --name 'IK-EXE-FAC-1'` |
| IK-EXE-FAC-2 | wired executors have correct types | ✅ | `dart test --name 'IK-EXE-FAC-2'` |
| IK-EXE-FAC-3 | traversal executors have correct types | ✅ | `dart test --name 'IK-EXE-FAC-3'` |

## 7. v2 CLI tool wiring

**Test file:** `test/v2/issuekit_tool_test.dart` — **ID prefixes `IK-CLI`,
`IK-CLI-NEG`**

Verifies the v2 `ToolDefinition`/`ToolRunner` wiring (commands, options,
help/version) built on `tom_build_base`, including negative/argument-error
cases (`IK-CLI-NEG`).

**How to test:** `dart test test/v2/issuekit_tool_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| IK-CLI-1 | Tool has correct name and version | ✅ | `dart test --name 'IK-CLI-1'` |
| IK-CLI-2 | Tool has all required commands | ✅ | `dart test --name 'IK-CLI-2'` |
| IK-CLI-3 | All commands have descriptions | ✅ | `dart test --name 'IK-CLI-3'` |
| IK-CLI-4 | Project traversal commands are marked correctly | ✅ | `dart test --name 'IK-CLI-4'` |
| IK-CLI-5 | Navigation features are configured correctly | ✅ | `dart test --name 'IK-CLI-5'` |
| IK-CLI-6 | :new command has required options | ✅ | `dart test --name 'IK-CLI-6'` |
| IK-CLI-7 | :list command has required options | ✅ | `dart test --name 'IK-CLI-7'` |
| IK-CLI-8 | :scan command has required options | ✅ | `dart test --name 'IK-CLI-8'` |
| IK-CLI-9 | :sync command has required options | ✅ | `dart test --name 'IK-CLI-9'` |
| IK-CLI-10 | All commands have executors | ✅ | `dart test --name 'IK-CLI-10'` |
| IK-CLI-11 | Executor count matches command count | ✅ | `dart test --name 'IK-CLI-11'` |
| IK-CLI-NEG01 | Tool definition does not register macro/define | ✅ | `dart test --name 'IK-CLI-NEG01'` |

## 8. v2 traversal executors

**Test file:** `test/v2/traversal_executor_test.dart` — **ID prefix `IK-EXE-*`**

Traversal-mode executors that operate across scanned projects: aggregation
(`IK-EXE-AGG`), parameter resolution (`IK-EXE-PRM`), scan (`IK-EXE-SCN`), show
(`IK-EXE-SHW`), sync (`IK-EXE-SYN`), test-linkage (`IK-EXE-TST`), and validation
(`IK-EXE-VAL`).

**How to test:** `dart test test/v2/traversal_executor_test.dart`.

| ID | Feature | Status | How to Test |
|----|---------|--------|-------------|
| IK-EXE-SCN-1 | finds issue-linked tests in project | ✅ | `dart test --name 'IK-EXE-SCN-1'` |
| IK-EXE-SCN-2 | filters by issue number | ✅ | `dart test --name 'IK-EXE-SCN-2'` |
| IK-EXE-SCN-3 | returns empty when no issue-linked tests | ✅ | `dart test --name 'IK-EXE-SCN-3'` |
| IK-EXE-SCN-4 | filters stubs with --missing-tests | ✅ | `dart test --name 'IK-EXE-SCN-4'` |
| IK-EXE-TST-1 | finds tests for given issue | ✅ | `dart test --name 'IK-EXE-TST-1'` |
| IK-EXE-TST-2 | returns empty when no tests for issue | ✅ | `dart test --name 'IK-EXE-TST-2'` |
| IK-EXE-TST-3 | fails when no issue number provided | ✅ | `dart test --name 'IK-EXE-TST-3'` |
| IK-EXE-TST-4 | rejects stubs, only accepts full test IDs | ✅ | `dart test --name 'IK-EXE-TST-4'` |
| IK-EXE-TST-5 | reports full tests and notes stubs | ✅ | `dart test --name 'IK-EXE-TST-5'` |
| IK-EXE-TST-6 | multiple full tests reported correctly | ✅ | `dart test --name 'IK-EXE-TST-6'` |
| IK-EXE-VRF-1 | verifies all tests pass | ✅ | `dart test --name 'IK-EXE-VRF-1'` |
| IK-EXE-VRF-2 | reports failures when tests fail | ✅ | `dart test --name 'IK-EXE-VRF-2'` |
| IK-EXE-VRF-3 | reports error when no baseline | ✅ | `dart test --name 'IK-EXE-VRF-3'` |
| IK-EXE-VRF-4 | returns empty when no tests for issue | ✅ | `dart test --name 'IK-EXE-VRF-4'` |
| IK-EXE-VRF-5 | fails when no issue number provided | ✅ | `dart test --name 'IK-EXE-VRF-5'` |
| IK-EXE-VRF-6 | reports NOT RUN when test not in baseline | ✅ | `dart test --name 'IK-EXE-VRF-6'` |
| IK-EXE-VRF-7 | reports mixed OK and failure statuses | ✅ | `dart test --name 'IK-EXE-VRF-7'` |
| IK-EXE-PRM-1 | promotes test ID with dry-run | ✅ | `dart test --name 'IK-EXE-PRM-1'` |
| IK-EXE-PRM-2 | applies rename to source file | ✅ | `dart test --name 'IK-EXE-PRM-2'` |
| IK-EXE-PRM-3 | reports not found in project | ✅ | `dart test --name 'IK-EXE-PRM-3'` |
| IK-EXE-PRM-4 | fails when missing test-id | ✅ | `dart test --name 'IK-EXE-PRM-4'` |
| IK-EXE-PRM-5 | fails when missing --issue | ✅ | `dart test --name 'IK-EXE-PRM-5'` |
| IK-EXE-PRM-6 | handles already-promoted test ID | ✅ | `dart test --name 'IK-EXE-PRM-6'` |
| IK-EXE-PRM-7 | handles multiple occurrences in file | ✅ | `dart test --name 'IK-EXE-PRM-7'` |
| IK-EXE-VAL-1 | validates clean project | ✅ | `dart test --name 'IK-EXE-VAL-1'` |
| IK-EXE-VAL-2 | detects duplicate project-specific IDs | ✅ | `dart test --name 'IK-EXE-VAL-2'` |
| IK-EXE-VAL-3 | detects regular+promoted conflict | ✅ | `dart test --name 'IK-EXE-VAL-3'` |
| IK-EXE-VAL-4 | returns empty for no tests | ✅ | `dart test --name 'IK-EXE-VAL-4'` |
| IK-EXE-VAL-5 | detects invalid issue references (Check 3) | ✅ | `dart test --name 'IK-EXE-VAL-5'` |
| IK-EXE-VAL-6 | reports both errors and warnings together | ✅ | `dart test --name 'IK-EXE-VAL-6'` |
| IK-EXE-VAL-7 | valid issue refs pass Check 3 | ✅ | `dart test --name 'IK-EXE-VAL-7'` |
| IK-EXE-VAL-8 | reports multiple duplicate groups separately | ✅ | `dart test --name 'IK-EXE-VAL-8'` |
| IK-EXE-VAL-9 | multiple conflicts reported separately | ✅ | `dart test --name 'IK-EXE-VAL-9'` |
| IK-EXE-VAL-10 | warnings-only does not cause failure | ✅ | `dart test --name 'IK-EXE-VAL-10'` |
| IK-EXE-VAL-11 | --fix with dry-run reports would-remove | ✅ | `dart test --name 'IK-EXE-VAL-11'` |
| IK-EXE-VAL-12 | --fix applies to source file | ✅ | `dart test --name 'IK-EXE-VAL-12'` |
| IK-EXE-VAL-13 | --fix without conflicts has no fixes | ✅ | `dart test --name 'IK-EXE-VAL-13'` |
| IK-EXE-SYN-1 | reports passing/failing/not-run | ✅ | `dart test --name 'IK-EXE-SYN-1'` |
| IK-EXE-SYN-2 | returns empty when no issue-linked tests | ✅ | `dart test --name 'IK-EXE-SYN-2'` |
| IK-EXE-SYN-3 | reports when no baseline | ✅ | `dart test --name 'IK-EXE-SYN-3'` |
| IK-EXE-SYN-4 | success when all issue-linked tests pass | ✅ | `dart test --name 'IK-EXE-SYN-4'` |
| IK-EXE-SYN-5 | identifies issues as VERIFYING candidates | ✅ | `dart test --name 'IK-EXE-SYN-5'` |
| IK-EXE-SYN-6 | detects regressions (OK→X) | ✅ | `dart test --name 'IK-EXE-SYN-6'` |
| IK-EXE-SYN-7 | groups multiple issues separately | ✅ | `dart test --name 'IK-EXE-SYN-7'` |
| IK-EXE-SYN-8 | skips stubs in per-issue grouping | ✅ | `dart test --name 'IK-EXE-SYN-8'` |
| IK-EXE-AGG-1 | aggregates issue-linked test results | ✅ | `dart test --name 'IK-EXE-AGG-1'` |
| IK-EXE-AGG-2 | returns empty when no issue-linked tests | ✅ | `dart test --name 'IK-EXE-AGG-2'` |
| IK-EXE-AGG-3 | handles missing baseline | ✅ | `dart test --name 'IK-EXE-AGG-3'` |
| IK-EXE-AGG-4 | produces CSV-formatted output with Project column | ✅ | `dart test --name 'IK-EXE-AGG-4'` |
| IK-EXE-AGG-5 | detects regressions in baseline | ✅ | `dart test --name 'IK-EXE-AGG-5'` |
| IK-EXE-AGG-6 | aggregates multiple tests with mixed statuses | ✅ | `dart test --name 'IK-EXE-AGG-6'` |
| IK-EXE-SHW-5 | scans project for linked tests with file paths | ✅ | `dart test --name 'IK-EXE-SHW-5'` |
| IK-EXE-SHW-6 | no tests found in project | ✅ | `dart test --name 'IK-EXE-SHW-6'` |
| IK-EXE-SHW-7 | shows baseline status per test | ✅ | `dart test --name 'IK-EXE-SHW-7'` |
| IK-EXE-SHW-8 | missing baseline shows NOT RUN | ✅ | `dart test --name 'IK-EXE-SHW-8'` |
| IK-EXE-SHW-9 | traversal fails without issue number | ✅ | `dart test --name 'IK-EXE-SHW-9'` |
| IK-EXE-TST-7 | non-numeric issue number fails | ✅ | `dart test --name 'IK-EXE-TST-7'` |
| IK-EXE-TST-8 | service.updateIssue failure handled gracefully | ✅ | `dart test --name 'IK-EXE-TST-8'` |
| IK-EXE-TST-9 | verifies service.updateIssue called with testing tag | ✅ | `dart test --name 'IK-EXE-TST-9'` |
| IK-EXE-VRF-8 | non-numeric issue number fails | ✅ | `dart test --name 'IK-EXE-VRF-8'` |
| IK-EXE-VRF-9 | service.updateIssue called with verifying on all-pass | ✅ | `dart test --name 'IK-EXE-VRF-9'` |
| IK-EXE-VRF-10 | service.updateIssue NOT called when some fail | ✅ | `dart test --name 'IK-EXE-VRF-10'` |
| IK-EXE-VRF-11 | service.updateIssue failure does not break result | ✅ | `dart test --name 'IK-EXE-VRF-11'` |
| IK-EXE-SYN-9 | --auto reopens on regression | ✅ | `dart test --name 'IK-EXE-SYN-9'` |
| IK-EXE-SYN-10 | --auto with --dry-run does not reopen | ✅ | `dart test --name 'IK-EXE-SYN-10'` |
| IK-EXE-SYN-11 | --auto with service failure continues gracefully | ✅ | `dart test --name 'IK-EXE-SYN-11'` |
| IK-EXE-SYN-12 | dry-run appends message note | ✅ | `dart test --name 'IK-EXE-SYN-12'` |
| IK-EXE-SYN-13 | --auto with all passing does not reopen | ✅ | `dart test --name 'IK-EXE-SYN-13'` |
| IK-EXE-SCN-5 | non-numeric issue number falls through to full scan | ✅ | `dart test --name 'IK-EXE-SCN-5'` |
| IK-EXE-SCN-6 | output contains relative file paths | ✅ | `dart test --name 'IK-EXE-SCN-6'` |
| IK-EXE-SCN-7 | output contains line numbers | ✅ | `dart test --name 'IK-EXE-SCN-7'` |
| IK-EXE-FAC-TRV-1 | factory accepts custom TestScanner | ✅ | `dart test --name 'IK-EXE-FAC-TRV-1'` |
| IK-EXE-FAC-TRV-2 | factory creates default TestScanner | ✅ | `dart test --name 'IK-EXE-FAC-TRV-2'` |
