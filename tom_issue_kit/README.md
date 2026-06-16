# Tom Issue Kit

> Tom Issue Kit is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [LICENSE](LICENSE).

Issue tracking CLI for the Tom Framework.

`issuekit` bridges the gap between **discovering a problem** and **confirming it
is fixed**. It uses GitHub Issues as the database, links issues to reproduction
tests by an ID convention, and synchronises issue state with real Dart test
results — so an issue cannot be called *resolved* until the test that reproduces
it actually passes.

It is one of the Tom CLI kits, built on [`tom_build_base`](../../basics/tom_build_base/)
(the v2 CLI framework) and [`tom_github_api`](../tom_github_api/) (the GitHub
REST client).

---

## Overview

`testkit` tells you *what* failed. `issuekit` tells you *why* it matters, *where*
it belongs, *what* to do about it, and — critically — **whether the fix actually
resolved the original problem**. It fills the space that neither `testkit` nor
`buildkit` covers:

| Tool | Scope |
| ---- | ----- |
| [`testkit`](../tom_test_kit/) | Runs Dart tests, tracks results over time, detects regressions. |
| [`buildkit`](../tom_build_kit/) | Builds, analyzes, and manages projects. |
| **`issuekit`** | Records discovered problems, tracks them as test entries, orchestrates their lifecycle across GitHub repos, and synchronises states with Dart test results. |

### The three layers

The tool operates across three kinds of repository, kept deliberately distinct:

| Layer | Repository | Purpose |
| ----- | ---------- | ------- |
| **@issues** | `tom_issues` (public) | Problem intake — reporters (or Copilot) file issues here. |
| **@tests** | `tom_tests` (private) | Test entries with project/module metadata, consolidated baselines, regression tracking, nightly snapshots. |
| **@code** | project repos | The actual code and the `test()` calls (Dart tests) that exercise the reported behaviour. |

A **convention-based link** ties the three together: a Dart test whose ID
encodes an issue number is discovered by `issuekit :scan`, so traceability comes
from naming, not from a brittle external mapping.

---

## Installation

`issuekit` is a **workspace-internal CLI** (`publish_to: none`). It is not
published to pub.dev; it is built in place from this package and run as the
`issuekit` executable. Build it with `buildkit` (or `dart compile exe
bin/issuekit.dart`) and put the result on your `PATH`.

```bash
issuekit --help            # command list and global options
issuekit version           # full version string
```

A short shell alias keeps day-to-day use terse:

```bash
alias ik=issuekit
```

**SDK requirement:** Dart `^3.10.4`. **Dependencies:** `tom_build_base: ^2.6.25`
(hosted, the v2 CLI framework) and `tom_github_api` (the GitHub REST client).

### Configuration

`issuekit` reads its configuration from two files; no flags are needed once they
are in place:

```yaml
# tom_workspace.yaml (workspace root)
issue_tracking:
  issues_repo: al-the-bear/tom_issues   # @issues intake
  tests_repo:  al-the-bear/tom_tests    # @tests tracking

github_auth:
  token_file: ~/.tom/github_token       # or rely on GITHUB_TOKEN
```

```yaml
# tom_project.yaml (each project root)
project_id: tom_d4rt
```

The GitHub token is resolved (via `tom_github_api`) from `github_auth`, the
`GITHUB_TOKEN` environment variable, or `~/.tom/github_token`. Help and version
run without a token; every other command requires one and a valid
`issue_tracking` block.

---

## Quick start

```bash
# File a problem — lands in tom_issues as NEW.
issuekit :new "Parser crashes on empty input" --severity high --tags "parser,crash"

# Record analysis and the target project — moves NEW → ANALYZED.
issuekit :analyze 42 --root-cause "Missing null check" --project tom_d4rt --module parser

# Assign it — creates a stub test ID, moves to ASSIGNED.
issuekit :assign 42 --project tom_d4rt --module parser

# After writing the reproduction test in the project, scan finds it by ID.
issuekit :scan 42

# Sync issue states against the latest test results (regressions reopen).
issuekit :sync --dry-run
```

Every command prints a shared end-of-run summary (from `tom_build_base`) so
errors and skips are reported consistently across the kits.

---

## Example projects

| Location | What it shows |
| -------- | ------------- |
| [`bin/issuekit.dart`](bin/issuekit.dart) | The CLI entry point — config load, token/issue-tracking validation, v2 `ToolRunner` wiring. |
| [`test/`](test/) | 383 tests across config / services / v2 executors / output formatting, run against a fake filesystem and a mock GitHub client. |
| `../tom_devops_samples/tom_issue_kit_sample/` | A worked issue-lifecycle walkthrough — see the [samples learning path](../README.md). *(forward reference — added later in this quest.)* |

---

## Usage

The CLI is **multi-command**: every operation is a `:command` (built on the
`tom_build_base` v2 framework). Run `issuekit help <command>` for per-command
detail. Commands fall into four groups.

### Global options

```
issuekit --help            # show all commands
issuekit --version         # version string
issuekit help <command>    # detailed help for one command
issuekit help pipelines    # framework help topics
```

Most query/export commands accept `--output <format>` where `<format>` is
`plain` (default), `csv`, `json`, `md`, or `<format>:<filename>` to write a file.

### 1. Issue management — the lifecycle

These commands drive an issue through its states:

```
NEW ──analyze──▶ ANALYZED ──assign──▶ ASSIGNED ──testing──▶ TESTING
                                                                │
                                                             verify
                                                                ▼
        CLOSED ◀──close── RESOLVED ◀──resolve── VERIFYING
                              ▲
                           reopen (from any closed/resolved state)
```

| Command | Effect |
| ------- | ------ |
| `:new "<title>"` | Create an issue in `tom_issues` (state NEW; `--project` pre-assigns straight to ASSIGNED). Options: `--severity`, `--context`, `--expected`, `--symptom`, `--tags`, `--project`, `--reporter`. |
| `:edit <n>` | Edit an existing issue's fields (`--title`, `--severity`, `--context`, `--expected`, `--symptom`, `--tags`, `--project`, `--module`, `--assignee`). |
| `:analyze <n>` | Record analysis → ANALYZED (`--root-cause`, `--project`, `--module`, `--note`). |
| `:assign <n>` | Assign to a project → ASSIGNED, creating a stub test ID (`--project` required, `--module`, `--assignee`). |
| `:testing <n>` | Mark that a reproduction test has been created → TESTING. |
| `:verify <n>` | Check linked tests pass → VERIFYING if all green. |
| `:resolve <n>` | Confirm the original problem is fixed → RESOLVED (`--fix`, `--note`). |
| `:close <n>` | Close and archive a resolved issue → CLOSED. |
| `:reopen <n>` | Reopen a closed/resolved issue (`--note`). |

```bash
issuekit :new "Memory leak in server" --severity critical
issuekit :analyze 42 --root-cause "Unclosed stream" --project tom_core_server
issuekit :verify 42
issuekit :resolve 42 --fix "Close the stream on dispose"
```

### 2. Discovery and querying

| Command | Effect |
| ------- | ------ |
| `:list` | List issues with filters (`--state`, `--severity`, `--project`, `--tags`, `--reporter`, `--all`, `--sort`, `--output`, `--repo issues\|tests`). |
| `:show <n>` | Show full details of one issue. |
| `:search "<query>"` | Full-text search (`--repo`, `--output`). |
| `:scan [<n>]` | Scan the workspace for tests linked to issues by ID convention (`--project`, `--state`, `--missing-tests`, `--output`). |
| `:summary` | Dashboard of counts by state, severity and project (`--output`). |

```bash
issuekit :list --state new
issuekit :list --reporter copilot --output md:open.md
issuekit :scan --missing-tests
issuekit :summary --output=md:summary.md
```

### 3. Test management

| Command | Effect |
| ------- | ------ |
| `:promote <test-id> --issue <n>` | Promote a regular test to issue-linked (inserts the issue number; `--dry-run`). |
| `:validate` | Check test-ID uniqueness across the workspace (`--project`, `--fix`). |
| `:link <n> --test-id <id>` | Explicitly link a non-standard test to an issue (`--test-file`, `--note`). |

```bash
issuekit :promote D4-PAR-15 --issue 42 --dry-run
issuekit :validate --project tom_d4rt
```

### 4. Workflow integration

| Command | Effect |
| ------- | ------ |
| `:sync` | Sync issue states with test results — detect fixes and regressions (`--auto` applies transitions, `--project`, `--dry-run`). |
| `:aggregate` | Aggregate `testkit` baselines into the `tom_tests` consolidated view (`--output`). |
| `:export` | Export issues as CSV/JSON/Markdown (`--output` required; `--state`, `--severity`, `--project`, `--tags`, `--all`, `--repo`). |
| `:import <file>` | Import issues from a file (`--dry-run`, `--repo`). |
| `:init` | Initialise repos for tracking — labels and templates (`--repo issues\|tests\|both`, `--force`). |
| `:snapshot` | Export issues to timestamped JSON for backup (`--issues-only`, `--tests-only`, `--output`). |
| `:run-tests` | Trigger the nightly test workflow in `tom_tests` via the GitHub API (`--wait`). |

```bash
issuekit :sync --auto
issuekit :export --state testing --output=json:testing.json
issuekit :init --repo both
```

### Project traversal

Commands that work against code — `:testing`, `:verify`, `:show`, `:scan`,
`:promote`, `:validate`, `:sync`, `:aggregate` — support project traversal
(`worksWithNatures: {DartProjectFolder}`): point `issuekit` at the workspace and
it walks the Dart projects, applying the command per project. The remaining
commands act directly on the GitHub trackers and do not traverse.

### Library use

The same operations are available programmatically — `bin/issuekit.dart` is a
thin wrapper over `IssueService`:

```dart
import 'package:tom_github_api/tom_github_api.dart';
import 'package:tom_issue_kit/tom_issue_kit.dart';

final config = await IssueKitConfig.load(Directory.current.path);
final client = GitHubApiClient(token: config.token!);
final service = IssueService(
  client: client,
  issuesRepo: config.issueTracking!.issuesRepo,
  testsRepo: config.issueTracking!.testsRepo,
);
try {
  final issues = await service.listIssues(); // typed GitHubIssue list
  print('${issues.length} open issues');
} finally {
  service.close();
}
```

---

## Architecture

```
        bin/issuekit.dart
              │ loads IssueKitConfig, resolves token, builds IssueService
              ▼
        ToolRunner  (tom_build_base v2)
              │ dispatches issuekitTool's :commands to …
              ▼
        createIssuekitExecutors(service)   ← CommandExecutor per command
              │ calls
              ▼
        IssueService                       ← lifecycle / linking / sync logic
              │ uses
              ▼
        GitHubApiClient (tom_github_api) ──▶ GitHub REST API v3
```

The CLI shell, argument parsing, help and traversal come from
`tom_build_base`'s v2 framework; the GitHub transport comes from
`tom_github_api`; everything issue-specific lives in `IssueService` and the
per-command executors.

### Key types

| Type | Role |
| ---- | ---- |
| `issuekitTool` | The `ToolDefinition` — declares all 24 `:commands`, their options and help topics. |
| `createIssuekitExecutors` | Builds the `CommandExecutor` map (one per command) bound to an `IssueService`. |
| `IssueService` | High-level issue operations — create / update / analyze / assign / verify / resolve / sync, label management, lifecycle transitions. |
| `IssueKitConfig` | Workspace configuration loaded from `tom_workspace.yaml`; exposes `token`, `issueTracking`, `isValid`. |
| `IssueTrackingConfig` | The `issues_repo` / `tests_repo` slugs. |
| `ProjectConfig` | Per-project `project_id` from `tom_project.yaml`. |
| `GitHubAuthConfig` | Token resolution (explicit / `GITHUB_TOKEN` / `~/.tom/github_token`). |
| `OutputFormatter` | Renders results as plain / csv / json / md (or to a file). |

---

## Ecosystem

```
                       issuekit  (this package)
                    ┌──────┴───────┐
                    ▼              ▼
            tom_build_base    tom_github_api
            (v2 CLI fw)       (GitHub REST v3)
                                   │
                                   ▼
                              GitHub Issues
                          tom_issues · tom_tests

        sibling kits:  testkit (results)   buildkit (build)
```

`issuekit` sits alongside `testkit` and `buildkit` as a peer CLI kit; all three
share the `tom_build_base` framework, and `issuekit` additionally drives the
GitHub trackers through `tom_github_api`.

---

## Further documentation

| Document | What it covers |
| -------- | -------------- |
| [`doc/issue_tracking.md`](doc/issue_tracking.md) | The concept and workflow — three-repository architecture, ID scheme, full issue lifecycle, convention-based test linking, regression detection. |
| [`doc/issuekit_command_reference.md`](doc/issuekit_command_reference.md) | The complete command reference — every `:command`, its options and examples. |
| [`doc/issuekit_implementation_todos.md`](doc/issuekit_implementation_todos.md) | Implementation status and remaining work for the CLI. |

### Related packages

| Package | Relationship |
| ------- | ------------ |
| [`tom_github_api`](../tom_github_api/) | The GitHub REST client `issuekit` uses for all tracker operations. |
| [`tom_build_base`](../../basics/tom_build_base/) | The shared v2 CLI framework (arg parsing, help, traversal, run summary). |
| [`tom_test_kit`](../tom_test_kit/) | The `testkit` CLI — produces the test results `issuekit :sync` consumes. |
| [`tom_build_kit`](../tom_build_kit/) | The `buildkit` orchestrator — the sibling build kit. |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 1.0.0 (`publish_to: none` — workspace-internal)
- **SDK:** Dart `^3.10.4`
- **Dependencies:** `tom_build_base: ^2.6.25` (hosted), `tom_github_api`
  (workspace), `path`.
- **Binary:** `issuekit`.
- **Commands:** 24 (`:new … :run-tests`) across issue management, discovery,
  test management and workflow integration.
- **Tests:** 383.

---

## License

See [LICENSE](LICENSE); each package in this repository carries its own license
terms.
