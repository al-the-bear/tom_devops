# Tom Build

> Tom Build is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [../LICENSE.md](../LICENSE.md).

Build tools and workspace analyzer for the Tom framework.

`tom_build` is the library that *understands the monorepo*. It walks a
Dart/Flutter workspace, detects what each folder is (a Dart package, a Flutter
app, a server, a test project), works out the order packages must be built in,
and writes a single machine-readable description of the whole workspace to
`.tom_metadata/tom_master.yaml`. Every other Tom devops tool — `buildkit`,
`testkit`, `issuekit`, the `tom` CLI — reads that file instead of re-scanning
the disk. `tom_build` also ships the **scripting helpers** (`TomShell`,
`TomFs`, `TomGlob`, …) that D4rt build scripts use, the **file object model**
that parses `tom_workspace.yaml` / `tom_project.yaml`, and a programmatic
**reflection-generator runner**.

---

## Overview

A Tom workspace is a tree of many Dart packages, Flutter apps and server
projects spread across nested git repositories. Tools that operate on the
workspace — building, testing, publishing, deploying — all need the same
foundational facts:

- **What projects exist**, where they live, and what type each one is.
- **How they depend on each other**, so they can be built in a safe order.
- **What capabilities each one has** (tests, examples, reflection, build_runner,
  docker, assets) so a tool can decide what to do with it.

Re-deriving those facts on every invocation is slow and inconsistent. `tom_build`
derives them **once**, in the `WorkspaceAnalyzer`, and writes the result to
`.tom_metadata/tom_master.yaml`. That file is the *single source of truth* for
workspace structure; the rest of the toolchain consumes it through the
lightweight `WorkspaceInfo` / `ToolContext` readers.

The package has four cooperating concerns:

| Concern | Entry type | What it does |
| ------- | ---------- | ------------ |
| **Workspace analysis** | `WorkspaceAnalyzer` | Scans the workspace, detects natures, computes build order, writes `tom_master.yaml`. |
| **Metadata reading** | `WorkspaceInfo`, `ToolContext` | Loads the generated metadata back into typed objects for consuming tools. |
| **File object model** | `WorkspaceParser`, `TomMaster`, `TomProject` | Parses `tom_workspace.yaml` / `tom_project.yaml` into a rich configuration model (modes, actions, pipelines). |
| **Scripting helpers** | `TomShell`, `TomFs`, `TomGlob`, … | Shell-script-like static helpers for D4rt-based build scripts. |

A fifth, smaller concern — driving the reflection generator from code — is
exposed through `ReflectionGeneratorRunner`.

`tom_build` depends only on the analyzer toolchain and the core Tom packages; it
deliberately does **not** depend on `tom_build_cli`, so the analyzer binary can
run with a minimal dependency closure.

---

## Installation

`tom_build` is a **workspace-internal package** (`publish_to: none`). It is not
published to pub.dev — it lives inside the Tom devops repository and is consumed
in place by the other tools in this repo, which reference it as a workspace
member. There is no `dart pub add tom_build`, and you should **never** add a
manual `path:` override to reach it from outside the workspace; tools that need
it already declare it as a workspace dependency.

Inside the workspace you typically use `tom_build` in one of two ways:

1. **As a command** — run the bundled `workspace_analyzer` binary (see
   [Quick start](#quick-start)).
2. **As a library** — import it from another package in the same workspace:

   ```dart
   import 'package:tom_build/tom_build.dart';        // analyzer, FOM, tools
   import 'package:tom_build/scripting.dart';        // scripting helpers only
   ```

**SDK requirement:** Dart `^3.10.4`. The analyzer uses the `analyzer`,
`dart_style`, `yaml` and `pub_semver` packages; the core dependencies
(`tom_core_kernel`, `tom_core_server`, `tom_dist_ledger`, `tom_process_monitor`)
are resolved as workspace members.

---

## Features

### Workspace analysis

| Capability | Description |
| ---------- | ----------- |
| Project discovery | Recursively scans the workspace, skipping ignored folders, and identifies every Dart/Flutter project. |
| Nature detection | Classifies each project (package, Flutter app, server, CLI tool, test project). |
| Build-order resolution | Derives a dependency-respecting build order across all projects. |
| Capability flags | Records which projects have tests, examples, reflection, build_runner, docker, assets. |
| Parts & modules | Captures sub-package structure (`PartInfo`, `ModuleInfo`) for multi-module projects. |
| Test-project filtering | Excludes `zom_*` test projects by default; `AnalyzerOptions.all` includes them. |
| Metadata emission | Writes `.tom_metadata/tom_master.yaml` plus per-action master files. |

### Metadata reading

| Type | Responsibility |
| ---- | -------------- |
| `WorkspaceInfo` | Typed view of `tom_master.yaml`: `buildOrder`, `projects`, `groups`, `workspaceModes`, `settings`. |
| `WorkspaceProject` | One project entry from the metadata (name, type, capabilities). |
| `WorkspaceGroup` | A named group of projects. |
| `ToolContext` | Process-wide singleton that loads and caches `WorkspaceInfo` plus platform info. |
| `PlatformInfo` | Detected OS / CPU architecture and the derived cross-compile target list. |

### File object model

| Type | Responsibility |
| ---- | -------------- |
| `WorkspaceParser` | Parses a workspace directory into a `TomMaster`. |
| `TomWorkspace` | Base configuration from `tom_workspace.yaml` (modes, actions, project types, versions). |
| `TomMaster` | The full workspace model (`TomWorkspace` + discovered projects). |
| `TomProject` | One project's `tom_project.yaml` / pubspec-derived configuration. |
| `ModeDefinitions`, `ActionDef`, `Pipeline` | The mode / action / pipeline configuration model used by the build tools. |

### Scripting helpers (`package:tom_build/scripting.dart`)

All helpers are static-method classes, designed to read cleanly inside D4rt
build scripts but equally usable from plain Dart.

| Helper | What it covers |
| ------ | -------------- |
| `TomShell` | `run`, `exec`, `capture`, `runAll`, `pipe`, `hasCommand`, `which`. |
| `TomFs` | `read`, `readLines`, `tryRead`, `write`, `append`, byte variants. |
| `TomPth` | `join`, `dirname`, `basename`, `basenameNoExt`, `extension`, `split`, `absolute`. |
| `TomGlob` | `find`, `findFiles`, `findDirs`, `matches`, `filter`, `exclude`. |
| `TomText` | `template`, `indent`, `dedent`, `wrap`, `truncate`, `lines`. |
| `TomEnv` | `load`, `reload`, `loadFile`, `resolve`, `get` — `.env` and process env. |
| `TomMaps`, `ScriptYaml`, `TomZoned`, `TomWs` | Map merging, YAML loading, zone values, workspace-metadata access. |

### Reflection generation

| Type | Responsibility |
| ---- | -------------- |
| `ReflectionGeneratorRunner` | Drives the reflection generator for a project from code (`generate`, `build`). |
| `ReflectionGeneratorRunnerOptions` | Generator options (target, mode, flags). |
| `ReflectionGeneratorRunnerResult` | Outcome (`success`, `message`, `error`, `stackTrace`). |

---

## Quick start

Generate workspace metadata with the bundled binary. Run it from the
`tom_build` package directory; by default it analyzes the **parent** directory
(the workspace root):

```bash
# From tom_ai/devops/tom_build
dart run bin/workspace_analyzer.dart wa-path=/path/to/workspace
```

```text
Analyzing workspace: /path/to/workspace
Note: Excluding test projects (zom_*). Use wa-include-tests to include them.

Workspace analysis complete!
Metadata written to: /path/to/workspace/.tom_metadata
```

The same thing programmatically:

```dart
import 'package:tom_build/tom_build.dart';

Future<void> main() async {
  final analyzer = WorkspaceAnalyzer(
    '/path/to/workspace',
    options: AnalyzerOptions.production, // excludes zom_* test projects
  );
  await analyzer.analyze();
  print('Metadata written to .tom_metadata/tom_master.yaml');
  // Metadata written to .tom_metadata/tom_master.yaml
}
```

---

## Example projects

| Where | Demonstrates |
| ----- | ------------ |
| [`bin/workspace_analyzer.dart`](bin/workspace_analyzer.dart) | The minimal, dependency-light entry point that drives `WorkspaceAnalyzer`. |
| [`test/`](test/) | 256 tests covering the analyzer, scripting helpers, file object model and file-structure detection — each is a runnable usage example. |
| [`tom_build_kit_sample`](../tom_devops_samples/tom_build_kit_sample/) | The build framework exercised end to end through `buildkit` *(planned — forward reference until the samples build-out lands)*. |

`tom_build` itself has no dedicated standalone sample package; the analyzer
binary and the test suite are the canonical runnable examples, and the
build-framework workflow is demonstrated by the buildkit sample above.

---

## Usage

### Running the analyzer (CLI)

The `workspace_analyzer` binary accepts both `wa-`-prefixed and legacy options:

```bash
# Analyze an explicit workspace path
dart run bin/workspace_analyzer.dart wa-path=/path/to/workspace

# Include the zom_* test projects
dart run bin/workspace_analyzer.dart wa-path=. wa-include-tests

# Legacy positional + flag form
dart run bin/workspace_analyzer.dart /path/to/workspace --include-tests

# Help
dart run bin/workspace_analyzer.dart --help
```

| Option | Meaning |
| ------ | ------- |
| `wa-path=<path>` | Workspace root to analyze (default: parent of the current directory). |
| `wa-include-tests` | Include `zom_*` test projects in the output. |
| `--include-tests` | Legacy alias for `wa-include-tests`. |
| `[path]` (positional) | Legacy way to pass the workspace path. |
| `--help`, `-h` | Show usage. |

### Programmatic analysis

`AnalyzerOptions` controls whether test projects are included. Three forms:

```dart
import 'package:tom_build/tom_build.dart';

Future<void> main() async {
  // Production: exclude zom_* test projects (the default)
  await WorkspaceAnalyzer('.', options: AnalyzerOptions.production).analyze();

  // All: include test projects
  await WorkspaceAnalyzer('.', options: AnalyzerOptions.all).analyze();

  // Explicit
  await WorkspaceAnalyzer(
    '.',
    options: const AnalyzerOptions(includeTestProjects: true),
  ).analyze();
}
```

### What the analyzer produces

`analyze()` writes `.tom_metadata/tom_master.yaml` — a single file describing the
whole workspace. Its most-used top-level keys:

| Key | Contents |
| --- | -------- |
| `name` | Workspace name. |
| `operating-systems` / `mobile-platforms` | Target platforms detected for the workspace. |
| `workspace-modes` | Mode definitions (environment, execution, deployment, …). |
| `project-types` | The recognised project-type catalogue. |
| `actions` | Action definitions used by the build tools. |
| `groups` | Named project groups. |
| `build-order` | The full dependency-respecting build order, as a flat list. |
| `projects` | Per-project entries: `type`, `description`, `build-after`, `features`, and the embedded `pubspec`. |

A trimmed excerpt of one project entry shows the capability flags the analyzer
derives for every project:

```yaml
build-order: [tom_basics, tom_build_base, tom_build_common, tom_build_kit, ...]

projects:
  tom_build:
    name: Tom Build
    type: dart_console
    description: "Build tools and workspace analyzer for the Tom framework."
    build-after: [tom_core_kernel, tom_core_server, ...]
    features:
      has-reflection: false
      has-build-runner: false
      has-native-deps: false
      has-assets: false
      publishable: false
      has-tests: true
      has-examples: false
      has-docker: false
      has-ci: false
```

| Feature flag | True when the project… |
| ------------ | ---------------------- |
| `has-tests` | has a `test/` directory with test files. |
| `has-examples` | has an `example/` directory. |
| `has-reflection` | uses Tom reflection (reflectable). |
| `has-build-runner` | declares a `build_runner` dev dependency. |
| `has-native-deps` | has native/FFI dependencies. |
| `has-assets` | declares Flutter assets. |
| `has-docker` | ships a `Dockerfile`. |
| `has-ci` | has CI configuration. |
| `publishable` | is intended for publication (not `publish_to: none`). |

`build-after` records each project's upstream dependencies; the analyzer
topologically flattens those relationships into the single `build-order` list
that the tools iterate.

### Reading generated metadata

Consuming tools rarely re-run the analyzer; they read the metadata it produced.
`ToolContext.load` reads `.tom_metadata/tom_master.yaml` once and caches a typed
`WorkspaceInfo`:

```dart
import 'package:tom_build/tom_build.dart';

Future<void> main() async {
  final context = await ToolContext.load(workspacePath: '/path/to/workspace');
  final ws = context.workspaceInfo;

  print(ws.buildOrder.first);     // e.g. tom_basics  (first to build)
  print(ws.projects.length);      // e.g. 142         (projects discovered)
  print(context.platform.os);     // e.g. OperatingSystem.linux
}
```

Once loaded, `ToolContext.current` returns the cached instance anywhere in the
process — no parameter threading required:

```dart
final order = ToolContext.current.workspaceInfo.buildOrder;
for (final name in order) {
  print('build $name');
}
```

If you only have the YAML in hand, build a `WorkspaceInfo` directly:

```dart
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

void main() {
  final yaml = loadYaml(yamlString) as YamlMap;
  final ws = WorkspaceInfo.fromYaml(yaml);
  print(ws.buildOrder); // [tom_basics, tom_build_base, ...]
}
```

### Parsing the file object model

When you need the *configuration* model (modes, actions, pipelines, project
types) rather than the analyzer's discovery summary, use `WorkspaceParser`:

```dart
import 'package:tom_build/tom_build.dart';

void main() {
  final master = WorkspaceParser('/path/to/workspace').parse();

  print(master.projects.length);   // discovered TomProject entries
  for (final project in master.projects.values) {
    print('${project.name}: ${project.type}');
    // tom_build: dart-package
  }
}
```

`TomMaster` extends `TomWorkspace`, so the parsed result also carries the
workspace-level mode/action/pipeline definitions read from `tom_workspace.yaml`.

### Scripting helpers

The `scripting.dart` barrel gives D4rt build scripts (and ordinary Dart) a
familiar shell-like vocabulary. Import only what you need:

```dart
import 'package:tom_build/scripting.dart';

void main() {
  // Find and process files
  final files = TomGlob.findFiles('lib/**/*.dart');
  for (final file in files) {
    final content = TomFs.read(file);
    final stamped = TomText.template(content, {'version': '1.0.0'});
    TomFs.write(file, stamped);
  }

  // Run a command and check the result
  final out = TomShell.capture('dart', ['--version']);
  print(out.contains('Dart')); // true

  // Guard on tool availability
  if (TomShell.hasCommand('flutter')) {
    TomShell.exec('flutter', ['pub', 'get']);
  }
}
```

Path manipulation and environment access follow the same static-method style:

```dart
import 'package:tom_build/scripting.dart';

void main() {
  final libDir = TomPth.join('packages', 'tom_build', 'lib');
  print(TomPth.basename(libDir)); // lib

  final env = TomEnv.load();                 // reads .env + process env
  final user = TomEnv.get('USER', 'nobody'); // with default
  print(user);
}
```

### Driving the reflection generator

`ReflectionGeneratorRunner` wraps the reflection generator so build tools can
regenerate a project's reflection data programmatically:

```dart
import 'package:tom_build/tom_build.dart';

Future<void> main() async {
  final runner = ReflectionGeneratorRunner(
    '/path/to/workspace/some_project',
    workspacePath: '/path/to/workspace',
  );

  final result = await runner.generate(target: 'lib/', all: true);
  print(result.success); // true
  if (!result.success) {
    print(result.error);
  }
}
```

Use `runner.build()` instead to honour the project's `build.yaml` configuration.

---

## Architecture

The package is organised around the four concerns introduced above. The
analyzer is the producer; everything else either reads what it produced or
operates alongside it.

```
                         tom_workspace.yaml
                         tom_project.yaml (per project)
                                 │
                                 ▼
   ┌──────────────────────────────────────────────────────┐
   │                  WorkspaceAnalyzer                     │
   │  scan ─► detect nature ─► resolve build order ─►       │
   │  collect capabilities ─► emit metadata                 │
   └───────────────────────────┬──────────────────────────┘
                               │ writes
                               ▼
                  .tom_metadata/tom_master.yaml
                               │ read by
              ┌────────────────┼─────────────────┐
              ▼                ▼                  ▼
        WorkspaceInfo     ToolContext        File object model
        (typed view)      (singleton +       (WorkspaceParser →
                          platform info)      TomMaster/TomProject)
              │                │                  │
              └────────────────┴──────────────────┘
                               │ consumed by
                               ▼
              buildkit · testkit · issuekit · tom CLI

      Scripting helpers (TomShell/TomFs/TomGlob/…) run alongside,
      inside D4rt build scripts.
```

### Key types

| Type | Responsibility |
| ---- | -------------- |
| `WorkspaceAnalyzer` | Scans a workspace and writes `tom_master.yaml`; the producer of all metadata. |
| `AnalyzerOptions` | Controls analysis (`includeTestProjects`); presets `production` / `all`. |
| `ProjectInfo` / `PartInfo` / `ModuleInfo` | The analyzer's in-memory model of a discovered project and its sub-structure. |
| `WorkspaceInfo` | Typed reader over the generated metadata (`buildOrder`, `projects`, `groups`). |
| `ToolContext` | Process-wide cache of `WorkspaceInfo` + `PlatformInfo`; `load` / `current` / `reload`. |
| `PlatformInfo` | OS / CPU-architecture detection and cross-compile target derivation. |
| `WorkspaceParser` | Parses raw YAML config into the `TomMaster` configuration model. |
| `TomWorkspace` / `TomMaster` / `TomProject` | The configuration object model (modes, actions, pipelines, project types). |
| `TomContext` | The global `tom` object exposed to D4rt scripts. |
| `TomShell` / `TomFs` / `TomGlob` / `TomText` / `TomPth` / `TomEnv` | Static scripting helpers for build scripts. |
| `ReflectionGeneratorRunner` | Programmatic front end to the reflection generator. |

---

## Ecosystem

`tom_build` sits below the CLI tools and above the core Tom packages. It is the
analysis engine the devops toolchain is built on, while staying free of any
dependency on the CLI layer itself.

```
              tom CLI · buildkit · testkit · issuekit   (tom_build_cli + kits)
                                 │ read metadata via
                                 ▼
                            ┌──────────┐
                            │ tom_build│   ← you are here
                            └────┬─────┘
                                 │ builds on
        ┌──────────────┬─────────┼──────────────┬──────────────────┐
        ▼              ▼         ▼               ▼                  ▼
  tom_core_kernel  tom_core   tom_dist_     tom_process_      analyzer /
                   _server    ledger        monitor          dart_style / yaml
```

The shared CLI framework — `tom_build_base` — lives in the basics layer
([`tom_ai/basics/tom_build_base`](../../basics/tom_build_base/)). `tom_build`
provides workspace understanding; `tom_build_base` provides the CLI plumbing
(arg parsing, help, traversal, pipelines). The tools combine the two.

---

## Further documentation

In-package guides under [`doc/`](doc/):

| Document | What's there |
| -------- | ------------ |
| [`doc/tom_user_reference.md`](doc/tom_user_reference.md) | Quick reference for the Tom workspace build tool — the everyday command surface. |
| [`doc/tom_tool_specification.md`](doc/tom_tool_specification.md) | Comprehensive specification of the Tom CLI build and management model. |
| [`doc/placeholders_d4rt_guide.md`](doc/placeholders_d4rt_guide.md) | The placeholder syntax and D4rt scripting integration, with implementation detail. |
| [`doc/restructuring.md`](doc/restructuring.md) | Package-restructuring analysis and rationale for the current module layout. |

Related packages (don't duplicate — follow the link):

| Package | Relationship |
| ------- | ------------ |
| [`tom_build_cli`](../tom_build_cli/) | The `tom` command surface; the CLI layer that drives `tom_build`. |
| [`tom_build_kit`](../tom_build_kit/) | The `buildkit` orchestrator that reads `tom_master.yaml` to run pipelines. |
| [`tom_build_base`](../../basics/tom_build_base/) | The shared CLI / build framework every Tom tool builds on. |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 1.0.0 (`publish_to: none` — workspace-internal)
- **SDK:** Dart `^3.10.4`
- **Tests:** 256 tests across `test/analyzer`, `test/scripting`, `test/tom` and
  `test/file_structure`.
- **Binary:** `workspace_analyzer`.

---

## License

See [../LICENSE.md](../LICENSE.md); each package in this repository carries its
own license terms.
