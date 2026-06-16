# Tom Build CLI

> Tom Build CLI is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [../LICENSE.md](../LICENSE.md).

CLI implementation for the Tom build system.

`tom_build_cli` is the package behind the **`tom`** command — the primary
entry point for managing and building a Tom workspace. It does two distinct
jobs from a single binary: it runs **Tom workspace commands** (actions like
`:analyze`, `:build`, `:test` and internal `!` commands), and it hosts
**TomD4rt** — an interactive Dart REPL / script runner that bridges the Tom
scripting API into D4rt. Which job runs is decided per-invocation by looking at
the arguments. The package also ships a small family of focused secondary
binaries (workspace analyzer, workspace prepper, reflection generator) and the
`Tom` scripting API that D4rt build scripts call.

---

## Overview

`tom_build_cli` sits one layer above [`tom_build`](../tom_build/): where
`tom_build` *understands* the workspace (scanning, metadata, the file object
model), `tom_build_cli` *drives* it from the command line. It adds argument
parsing, configuration loading and merging, action execution, output
formatting, and the TomD4rt REPL.

The `tom` binary is a **mode dispatcher**. On every invocation it inspects the
arguments and chooses one of two execution modes:

| Mode | Chosen when | What runs |
| ---- | ----------- | --------- |
| **Tom command** | any argument starts with `:` or `!` | `TomCli().run(args)` — execute workspace actions / internal commands and exit. |
| **TomD4rt** | no `:` / `!` argument is present | `runTomD4rt(args)` — start the REPL, run a script, or replay a session. |

That single rule (`determineExecutionMode`) is the whole top-level contract:
`tom :analyze` runs the analyzer action and exits; `tom script.dart` runs a
D4rt script; bare `tom` opens the interactive REPL.

Internally the package is organised into cooperating concerns:

| Concern | Representative types | What it does |
| ------- | -------------------- | ------------ |
| **Mode dispatch** | `TomExecutionMode`, `determineExecutionMode` | Picks command mode vs TomD4rt mode from the args. |
| **Command execution** | `TomCli`, `TomCliConfig`, `TomCliResult` | Parses args, loads config, runs actions/commands, returns a typed result. |
| **TomD4rt REPL** | `TomD4rtRepl`, `runTomD4rt` | Interactive Dart interpreter with Tom command support. |
| **Scripting API** | `Tom` | Static façade D4rt scripts use to drive the workspace. |
| **Config & generation** | config loader/merger, master generator, placeholder resolver | Loads `tom_workspace.yaml`, merges modes, generates metadata. |
| **Mode templates** | `WsPrepper`, mode processor/resolver | Prepares the workspace for a mode (e.g. `development`, `production`). |

`tom_build_cli` builds on `tom_build` (workspace understanding) and
`tom_d4rt_dcli` (the D4rt CLI base it extends), and bridges the VS Code
scripting API for remote execution.

---

## Installation

`tom_build_cli` is a **workspace-internal package** (`publish_to: none`). It is
not published to pub.dev — it lives inside the Tom devops repository and is
consumed in place. There is no `dart pub add tom_build_cli`, and you should
**never** add a manual `path:` override to reach it from outside the workspace.

Inside the workspace you use it in one of two ways:

1. **As the `tom` command** — run the binary directly:

   ```bash
   # From tom_ai/devops/tom_build_cli
   dart pub get
   dart run bin/tom.dart :analyze
   ```

   For day-to-day use the binary is AOT-compiled and put on `PATH` (see
   [`bin/compile_linux.sh`](bin/compile_linux.sh)); thereafter `tom` is invoked
   directly from any directory in the workspace.

2. **As a library** — import it from another package in the same workspace:

   ```dart
   import 'package:tom_build_cli/tom_build_cli.dart'; // TomCli, REPL, config
   import 'package:tom_build_cli/tom_cli_api.dart';   // the Tom scripting API
   ```

**SDK requirement:** Dart `^3.10.4`. Key dependencies: `tom_build` (workspace
analysis), `tom_d4rt` / `tom_d4rt_dcli` (the D4rt CLI base; `>=1.1.6` carries
the AOT-compatible duplicate-export fix), `tom_vscode_scripting_api` (bridge
client), and the core Tom packages.

---

## Features

### Execution modes

| Mode | Trigger | Behaviour |
| ---- | ------- | --------- |
| Tom command | `:action` / `!command` argument | Run actions / internal commands, print the result, exit with its code. |
| TomD4rt REPL | bare `tom` | Interactive Dart interpreter with `:` workspace commands and `.` bridge commands. |
| TomD4rt script | `tom file.dart` | Execute a D4rt script with the Tom scripting API available. |
| TomD4rt replay | `tom file.d4rt` | Replay a recorded REPL session. |

### Command surface (Tom command mode)

| Form | Example | Meaning |
| ---- | ------- | ------- |
| Action | `tom :analyze` | Run a workspace action defined in `tom_workspace.yaml`. |
| Action (project) | `tom :build tom_build` | Run an action scoped to one project. |
| Internal command | `tom !help` | Run a built-in command (not a workspace action). |

### Tom scripting API (`package:tom_build_cli/tom_cli_api.dart`)

The static `Tom` class is the façade D4rt scripts use to drive the workspace.

| Member | Purpose |
| ------ | ------- |
| `Tom.runAction(name, …)` | Run a single workspace action. |
| `Tom.runActions([…])` | Run several actions in sequence. |
| `Tom.analyze()` | Shortcut for `runAction('analyze')`. |
| `Tom.build([project])` | Run the build action, optionally scoped to a project. |
| `Tom.test([project])` | Run the test action, optionally scoped. |
| `Tom.workspace` / `Tom.project` | The loaded workspace / current-project configuration. |
| `Tom.projectInfo` / `Tom.actions` / `Tom.groups` | Metadata maps from `tom_master.yaml`. |
| `Tom.cwd` / `Tom.env` | Current directory and environment map. |

### Secondary binaries

Besides `tom`, the package ships focused single-purpose entry points:

| Binary | Purpose |
| ------ | ------- |
| [`bin/ws_analyzer.dart`](bin/ws_analyzer.dart) | Run the workspace analyzer in production mode (excludes `zom_*` test projects). |
| [`bin/ws_analyzer_all.dart`](bin/ws_analyzer_all.dart) | Run the analyzer including all projects (test projects too). |
| [`bin/ws_prepper.dart`](bin/ws_prepper.dart) | Prepare the workspace for a mode by processing mode templates. |
| [`bin/reflection_generator.dart`](bin/reflection_generator.dart) | Thin front end to the `tom_reflection_generator` CLI. |
| [`bin/test_bridge.dart`](bin/test_bridge.dart) | Smoke test for the VS Code bridge client. |

### Config, generation & modes

| Capability | Description |
| ---------- | ----------- |
| Config loading & merging | Reads `tom_workspace.yaml`, merges mode and action definitions. |
| Master generation | Generates `.tom_metadata` master files and the build order. |
| Placeholder resolution | Resolves `$ENV{…}` / `$VAL{…}` placeholders in action commands. |
| Mode preparation | `WsPrepper` applies mode templates (e.g. switch to `development`). |
| VS Code bridge | Execute Dart in a running VS Code instance via `VSCodeBridgeClient`. |

---

## Quick start

Run a workspace action and exit (Tom command mode — note the leading `:`):

```bash
# From tom_ai/devops/tom_build_cli
dart run bin/tom.dart :analyze
```

```text
Analyzing workspace...
Workspace analysis complete! Metadata written to .tom_metadata/tom_master.yaml
```

Open the interactive TomD4rt REPL (no `:` argument → TomD4rt mode):

```bash
dart run bin/tom.dart
```

```text
tom ~> print(1 + 2)
3
tom ~> :analyze
Workspace analysis complete!
tom ~> .vscode example.dart   # execute via the VS Code bridge
```

---

## Example projects

| Where | Demonstrates |
| ----- | ------------ |
| [`bin/tom.dart`](bin/tom.dart) | The mode-dispatch entry point — the canonical example of the two-mode contract. |
| [`bin/test_bridge.dart`](bin/test_bridge.dart) | A runnable VS Code bridge client session against a live editor. |
| [`test/`](test/) | 1193 tests covering parsing, config merge, action variants, cross-compilation, the analyzer and ws_prepper — each is a runnable usage example. |
| [`tom_build_kit_sample`](../tom_devops_samples/tom_build_kit_sample/) | The build framework exercised through `buildkit` *(planned — forward reference until the samples build-out lands)*. |

`tom_build_cli` has no dedicated standalone sample package; the `tom` binary,
the secondary binaries and the large test suite are the canonical runnable
examples.

---

## Usage

### Tom command mode

Any argument beginning with `:` (an action) or `!` (an internal command) puts
`tom` in command mode. It runs the requested work and exits with the command's
exit code:

```bash
# Run a workspace action
dart run bin/tom.dart :analyze

# Run an action scoped to one project
dart run bin/tom.dart :build tom_build

# Run an internal (non-action) command
dart run bin/tom.dart !help
```

### TomD4rt mode (REPL and scripts)

With no `:` / `!` argument, `tom` forwards to TomD4rt. Bare `tom` opens the
REPL; passing a file runs it:

```bash
# Interactive REPL
dart run bin/tom.dart

# Execute a D4rt script (the Tom scripting API is in scope)
dart run bin/tom.dart build_steps.d4rt.dart

# Replay a recorded session
dart run bin/tom.dart session.d4rt
```

Inside the REPL you mix Dart, `:` workspace commands and `.` bridge commands:

```text
tom ~> :analyze              # run the analyzer action
tom ~> :build tom_build      # build one project
tom ~> print("hello")        # plain Dart
tom ~> .vscode file.dart     # execute via the VS Code bridge
```

### The Tom scripting API

In a D4rt script, drive the workspace through the static `Tom` class:

```dart
import 'package:tom_build_cli/tom_cli_api.dart';

Future<void> main() async {
  // Run a single action
  final result = await Tom.runAction('analyze');
  print(result.exitCode); // 0

  // Run several actions in order
  await Tom.runActions(['analyze', 'build']);

  // Convenience shortcuts
  await Tom.build('tom_build_cli');
  await Tom.test();

  // Read workspace state
  print(Tom.cwd);           // current working directory
  print(Tom.actions.keys);  // available action names
}
```

### Driving the CLI programmatically

`TomCli` is the type behind command mode; embed it directly when you need its
typed `TomCliResult` rather than the process exit code:

```dart
import 'package:tom_build_cli/tom_build_cli.dart';

Future<void> main() async {
  final cli = TomCli(config: TomCliConfig(workspacePath: '.'));
  final result = await cli.run([':analyze']);

  print(result.exitCode);           // 0 on success
  if (result.message != null) {
    print(result.message);
  }
  for (final action in result.actionResults) {
    print(action);                  // per-action execution detail
  }
}
```

`TomCliResult` carries the outcome (`exitCode`, `message`, `error`) plus the
per-action (`actionResults`) and per-command (`commandResults`) detail, built
through its `success` / `failure` factories.

### Workspace analyzer binaries

Two thin analyzer entry points wrap `tom_build`'s `WorkspaceAnalyzer` with a
sensible default for the test-project filter:

```bash
# Production: exclude zom_* test projects
dart run bin/ws_analyzer.dart wa-path=/path/to/workspace

# All: include test projects
dart run bin/ws_analyzer_all.dart /path/to/workspace
```

Both accept the `wa-`-prefixed options documented for the analyzer
(`wa-path=`, `wa-include-tests`) and the legacy positional / `--include-tests`
forms.

### Workspace prepper

`ws_prepper` applies a workspace **mode** by processing its mode templates —
useful when switching a workspace between, say, `development` and `production`:

```bash
# Apply a mode
dart run tom_build_cli:ws_prepper wp-mode=development wp-path=/workspace

# Combine several mode dimensions
dart run tom_build_cli:ws_prepper wp-mode=dev,local,debug wp-dry-run

# List the templates that would be processed / available modes
dart run tom_build_cli:ws_prepper wp-list wp-path=.
dart run tom_build_cli:ws_prepper wp-modes
```

| Option | Meaning |
| ------ | ------- |
| `wp-mode=<m[,m…]>` | The mode(s) to apply. |
| `wp-path=<path>` | Workspace path. |
| `wp-dry-run` | Show what would change without writing. |
| `wp-list` | List the mode templates found. |
| `wp-modes` | List the available modes. |

### Reflection generator front end

`bin/reflection_generator.dart` is a one-line delegate to the
`tom_reflection_generator` CLI, so the reflection generator is reachable through
the same `tom_build_cli` binary set:

```bash
dart run bin/reflection_generator.dart generate lib/
```

---

## Architecture

The `tom` binary is a thin dispatcher; the real work lives in `TomCli` (command
mode) and `TomD4rtRepl` (script/REPL mode).

```
                         tom <args>
                             │
                ┌────────────┴─────────────┐
                │  determineExecutionMode   │
                │  any ':' or '!' argument? │
                └─────┬───────────────┬─────┘
                yes   │               │   no
                      ▼               ▼
              ┌──────────────┐  ┌──────────────┐
              │   TomCli     │  │ runTomD4rt   │
              │  .run(args)  │  │ TomD4rtRepl  │
              └──────┬───────┘  └──────┬───────┘
                     │                 │
        ┌────────────┼──────────┐      │ Tom scripting API
        ▼            ▼          ▼      ▼
   config loader  action     master   Tom (static façade)
   + merger       executor   generator
        │            │          │
        └────────────┴──────────┴──► reads/writes via tom_build
                                      (.tom_metadata/tom_master.yaml)
```

### Key types

| Type | Responsibility |
| ---- | -------------- |
| `TomExecutionMode` / `determineExecutionMode` | The two-mode contract and the argument rule that selects between them. |
| `TomCli` | Command-mode driver: parse → load config → execute → result. |
| `TomCliConfig` | CLI configuration (workspace path and run options). |
| `TomCliResult` | Typed outcome (`exitCode`, `message`, `error`, `actionResults`, `commandResults`). |
| `TomD4rtRepl` / `runTomD4rt` | The TomD4rt REPL / script runner. |
| `Tom` | Static scripting façade for D4rt scripts (`runAction`, `build`, `analyze`, …). |
| `WsPrepper` | Applies workspace mode templates. |
| `VSCodeBridgeClient` | Executes Dart in a running VS Code instance (re-exported). |

---

## Ecosystem

`tom_build_cli` extends the D4rt CLI base and builds on `tom_build`. It is the
CLI layer the workspace's `tom` command is made of.

```
                       tom (command)        buildkit / testkit / issuekit
                             │                        │
                             ▼                        │ (separate kits, same
                    ┌──────────────┐                  │  tom_build_base base)
                    │ tom_build_cli│  ← you are here  │
                    └──────┬───────┘                  │
              builds on    │   extends                │
        ┌──────────────────┼───────────────┐          │
        ▼                  ▼               ▼          ▼
   tom_build         tom_d4rt_dcli   tom_vscode_   (core: tom_core_kernel,
   (workspace        (D4rt CLI base) scripting_api  tom_core_server, …)
    analysis)                        (bridge client)
```

The shared CLI framework `tom_build_base` lives in the basics layer
([`tom_ai/basics/tom_build_base`](../../basics/tom_build_base/)); the kit tools
(`buildkit`, `testkit`, `issuekit`) build on it directly, while `tom` is built
on `tom_build_cli` + `tom_d4rt_dcli`.

---

## Further documentation

In-package guides under [`doc/`](doc/):

| Document | What's there |
| -------- | ------------ |
| [`doc/tom_cli_usage.md`](doc/tom_cli_usage.md) | Supplementary usage guide for the `tom` CLI (commands, modes, examples). |

The authoritative command reference for the whole Tom CLI lives in the devops
repo's `tom_build` docs — see
[`tom_build/doc/tom_user_reference.md`](../tom_build/doc/tom_user_reference.md)
and [`tom_build/doc/tom_tool_specification.md`](../tom_build/doc/tom_tool_specification.md).

Related packages (don't duplicate — follow the link):

| Package | Relationship |
| ------- | ------------ |
| [`tom_build`](../tom_build/) | Workspace analysis + file object model that `tom` drives. |
| [`tom_build_kit`](../tom_build_kit/) | The `buildkit` orchestrator — pipelines over the same metadata. |
| [`tom_build_base`](../../basics/tom_build_base/) | The shared CLI / build framework the kit tools build on. |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 1.0.0 (`publish_to: none` — workspace-internal)
- **SDK:** Dart `^3.10.4`
- **Tests:** 1193 tests across parser, config-merge, action-variant,
  cross-compilation, analyzer and ws_prepper suites.
- **Binaries:** `tom` (primary) plus `ws_analyzer`, `ws_analyzer_all`,
  `ws_prepper`, `reflection_generator`, `test_bridge`.

---

## License

See [../LICENSE.md](../LICENSE.md); each package in this repository carries its
own license terms.
