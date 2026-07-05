# Tom Issue Kit — Test Coverage

This document maps every issuekit feature area to its test file, test count, and
regression handle (test-ID prefix), so critical flows have clear coverage and
stable regression checks. It mirrors the coverage documents for
[buildkit](../../../basics/tom_build_kit/doc/test_coverage.md) and
[tom_build_base](../../../basics/tom_build_base/doc/test_coverage.md).

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

## 2. Executor integration

**Test file:** `test/integration/executor_integration_test.dart` — **ID prefix `IK-INT`**

End-to-end integration across executors: workspace scan (`IK-INT-WS`,
`IK-INT-SCN`), parameter resolution (`IK-INT-PRM`), validation (`IK-INT-VAL`),
and aggregation (`IK-INT-AGG`) using stubbed services.

**How to test:** `dart test test/integration/executor_integration_test.dart`.

## 3. Issue service

**Test file:** `test/services/issue_service_test.dart` — **ID prefixes `IK-INIT`,
`IK-ANZ`, `IK-ASN`, `IK-CLS`, `IK-EDT`, `IK-EXP`, `IK-IMP`, `IK-LINK`**

Covers the full issue lifecycle service: init, analyze, assign, close, edit,
export, import, and test-link operations against the GitHub issue tracker.

**How to test:** `dart test test/services/issue_service_test.dart`.

## 4. Test scanner service

**Test file:** `test/services/test_scanner_test.dart` — **ID prefixes `IK-SCN`,
`IK-SCN-BL`, `IK-SCN-ISS`, `IK-SCN-PB`**

Scans test files for IDs and issue linkage; associates scanned tests with
baseline (`-BL`), issues (`-ISS`), and pubspec (`-PB`) context.

**How to test:** `dart test test/services/test_scanner_test.dart`.

## 5. Output formatter

**Test file:** `test/util/output_formatter_test.dart` — **ID prefix `IK-FMT`**

`OutputFormat`/`OutputSpec` parsing (incl. the `text`→`plain` and
`markdown`→`md` aliases and the first-colon `<format>:<file>` split) and
per-format rendering. See the cross-tool
[CLI Output Formats contract](../../../basics/tom_build_base/doc/cli_output_formats.md).

**How to test:** `dart test test/util/output_formatter_test.dart`.

## 6. v2 command executors

**Test file:** `test/v2/executor_test.dart` — **ID prefix `IK-EXE-*`**

The largest suite: one executor per issuekit command (analyze `IK-EXE-ANZ`,
assign `IK-EXE-ASN`, close `IK-EXE-CLS`, edit `IK-EXE-EDT`, export `IK-EXE-EXP`,
import `IK-EXE-IMP`, init `IK-EXE-INIT`, reopen `IK-EXE-ROP`, …) plus the
`createIssuekitExecutors` factory (`IK-EXE-FAC`). Verifies command→executor
wiring, argument handling, and `ItemResult` outcomes.

**How to test:** `dart test test/v2/executor_test.dart`.

## 7. v2 CLI tool wiring

**Test file:** `test/v2/issuekit_tool_test.dart` — **ID prefixes `IK-CLI`,
`IK-CLI-NEG`**

Verifies the v2 `ToolDefinition`/`ToolRunner` wiring (commands, options,
help/version) built on `tom_build_base`, including negative/argument-error
cases (`IK-CLI-NEG`).

**How to test:** `dart test test/v2/issuekit_tool_test.dart`.

## 8. v2 traversal executors

**Test file:** `test/v2/traversal_executor_test.dart` — **ID prefix `IK-EXE-*`**

Traversal-mode executors that operate across scanned projects: aggregation
(`IK-EXE-AGG`), parameter resolution (`IK-EXE-PRM`), scan (`IK-EXE-SCN`), show
(`IK-EXE-SHW`), sync (`IK-EXE-SYN`), test-linkage (`IK-EXE-TST`), and validation
(`IK-EXE-VAL`).

**How to test:** `dart test test/v2/traversal_executor_test.dart`.
