# tom_build_kit Sample — the traversal framework behind buildkit

`buildkit` is the workspace's build orchestrator: one command (`buildkit
:pubget`, `buildkit :compile`, `buildkit :publish`, …) sweeps across every Dart
project in the workspace, in dependency order, doing the same thing in each.
That sweep is not bespoke to buildkit. It is the **tom_build_base v2 CLI
framework** — a small set of building blocks (`BuildBase`, `ToolDefinition`,
`CommandExecutor`, `ToolRunner`) that any tool in the workspace is built from.

This sample teaches that framework from the bottom up, against a tiny fixture
workspace you can see in full, and then shows you the real `buildkit`
definition so the toy and the production tool line up. Everything runs
**offline and deterministically**: no network, no real `pub get`, no
subprocesses. Each example prints exactly the lines written next to it as
`// expected output`.

> New to the samples set? Start with `tom_github_api_sample` for the REST-client
> flagship; this sample is the build-tooling counterpart.

---

## Contents

| File | Concept |
| ---- | ------- |
| `example/fixture.dart` | Locates the bundled fixture workspace |
| `example/fixture_workspace/` | Three pubspec-only projects: `pkg_core ← pkg_data ← pkg_app` |
| `example/01_discover_projects.dart` | `BuildBase.findProjects` — what projects are here? |
| `example/02_build_order.dart` | `BuildBase.forEachDartProject` — dependency-first traversal |
| `example/03_inspect_natures.dart` | Reading metadata via `DartProjectFolder` |
| `example/04_filter_projects.dart` | `include` / `exclude` project filters |
| `example/05_author_a_tool.dart` | `ToolDefinition` + `CommandExecutor` + `ToolRunner` |
| `example/06_custom_command_options.dart` | Declaring and reading a command option |
| `example/07_inspect_buildkit_tool.dart` | Introspecting buildkit's real definition |
| `example/run_all_examples.dart` | Runs all seven; doubles as a smoke test |

---

## Why offline and deterministic

A build tool's natural habitat is "run a process in every project" — `dart pub
get`, `dart compile`, `dart pub publish`. Those are exactly the things you do
**not** want a teaching example to do: they hit the network, mutate your
machine, take minutes, and produce output that changes from run to run.

So this sample deliberately stops short of execution. It exercises everything
*up to* the point where buildkit would shell out:

- **discovery** — scanning a tree and recognising Dart projects;
- **ordering** — sorting those projects so dependencies come first;
- **inspection** — reading each project's pubspec-derived metadata;
- **filtering** — selecting a subset by name;
- **dispatch** — wiring a command to an executor and running it per project.

The "work" each example's command does is to append a name to an in-memory
list. That is enough to demonstrate the framework end to end while keeping the
output fixed. When you build a real tool, you swap that list-append for a
`Process.run` — and that single line is the only difference between this sample
and buildkit's `:pubget`.

### The fixture workspace

The fixture is three Dart projects that exist **only as `pubspec.yaml` files**:

```
example/fixture_workspace/
  pkg_core/pubspec.yaml   name: pkg_core  v1.0.0
  pkg_data/pubspec.yaml   name: pkg_data  v0.4.0   deps: pkg_core
  pkg_app/pubspec.yaml    name: pkg_app   v0.1.0   deps: pkg_data, publish_to: none
```

The dependency edges (`pkg_app → pkg_data → pkg_core`) are what the build-order
sorter reads. There are no `lib/` or `bin/` directories because the traversal
engine only ever reads `pubspec.yaml` — which also means there is nothing for
`pub get` to resolve and nothing for the analyzer to flag. (The sample's
`analysis_options.yaml` excludes the fixture tree for good measure.)

---

## Running the sample

From this directory:

```bash
dart pub get
dart run example/run_all_examples.dart
```

Expected tail:

```
7 passed, 0 failed
```

Run an individual example to see its output in isolation:

```bash
dart run example/02_build_order.dart
# Build order: pkg_core -> pkg_data -> pkg_app
```

The whole samples set (this one plus its siblings) runs from the parent folder:

```bash
cd ..
dart run run_all_examples.dart
```

---

## The four pieces of a tool

Everything buildkit does is assembled from four collaborators. The sample
introduces them in the order you meet them when building a tool.

### 1. `BuildBase` — traversal

`BuildBase` is the scanning engine. Its static helpers walk a directory tree,
detect the *nature* of each folder (Is it a Dart project? A git repo? A Flutter
app?), apply filters, sort the results, and invoke a callback per match.

```dart
await BuildBase.forEachDartProject(
  (ctx) async {
    print(ctx.name);
    return true; // true = processed OK, false = failed
  },
  scan: '/path/to/workspace',
);
```

`forEachDartProject` visits Dart projects in **build order** by default.
`findProjects` returns the list without running anything. `traverse` is the
fully-configurable form both are built on.

### 2. `CommandContext` — what the callback receives

Each invocation gets a `CommandContext`: the folder, its detected natures, and
the execution root. The useful accessors:

| Member | Meaning |
| ------ | ------- |
| `ctx.name` | Folder name (`pkg_core`) |
| `ctx.path` | Absolute path |
| `ctx.relativePath` | Path relative to the execution root |
| `ctx.isDartProject` | Has a `DartProjectFolder` nature (any subtype) |
| `ctx.getNature<DartProjectFolder>()` | The Dart metadata (throws if absent) |
| `ctx.tryGetNature<T>()` | Nullable variant |

### 3. `DartProjectFolder` — project metadata

The Dart nature carries what was read from the pubspec:

| Member | From pubspec |
| ------ | ------------ |
| `projectName` | `name:` |
| `version` | `version:` |
| `dependencies` / `devDependencies` | the dependency maps |
| `isPublishable` | has a version **and** is not `publish_to: none` |

Subtypes refine it: `DartConsoleFolder` (has `bin/`), `DartPackageFolder` (has
`lib/src/`), `FlutterProjectFolder` (depends on the Flutter SDK). A
pubspec-only project — like all three fixtures — is the base
`DartProjectFolder`.

> **Nature matching is hierarchy-aware where it counts.** `ctx.isDartProject`
> and `worksWithNatures: {DartProjectFolder}` match any subtype. Prefer them to
> exact `runtimeType` checks, which would miss a `DartConsoleFolder`.

### 4. `ToolDefinition` + `CommandExecutor` + `ToolRunner`

To turn traversal into a *command-line tool* you declare what it is, supply the
per-project logic, and hand both to a runner:

```dart
final tool = ToolDefinition(
  name: 'greetkit',
  description: 'Greets each Dart project',
  commands: const [
    CommandDefinition(
      name: 'greet',
      description: 'Print a greeting',
      worksWithNatures: {DartProjectFolder}, // scopes the command
    ),
  ],
);

final runner = ToolRunner(
  tool: tool,
  executors: {'greet': CallbackExecutor(onExecute: (ctx, args) async {
    return ItemResult.success(path: ctx.path, name: ctx.name);
  })},
  output: StringBuffer(), // capture the runner's progress lines
);

final result = await runner.run([':greet', '--scan', root, '--root', root]);
```

`ToolRunner` parses the argument list (`:greet` plus navigation flags), runs the
traversal, dispatches the matching executor per project, and returns a
`ToolResult` (`success`, `processedCount`, `itemResults`). The `output` sink is
injectable — pass a `StringBuffer` to capture, omit it to flow to stdout.

---

## The examples, one by one

### 01 — Discover projects

`BuildBase.findProjects(scan: …)` returns a `CommandContext` for every folder it
finds. We keep the Dart projects (`ctx.isDartProject`) and sort the names,
because **filesystem listing order is not guaranteed** — discovery tells you
*what* is there, not in what order to build it.

```
Discovered 3 Dart projects: pkg_app, pkg_core, pkg_data
```

### 02 — Build order

`forEachDartProject` sorts by dependency (build) order using a topological sort
of the intra-workspace dependency graph, with alphabetic tie-breaking for
determinism. `pkg_core` depends on nothing, `pkg_data` on `pkg_core`, `pkg_app`
on `pkg_data`:

```
Build order: pkg_core -> pkg_data -> pkg_app
```

This is the ordering every buildkit sweep uses — you never build a dependent
before its dependency.

### 03 — Inspect natures

Pull the `DartProjectFolder` off each context and read its pubspec-derived
fields. `pkg_app` is `publish_to: none`, so it reports `private`:

```
pkg_core v1.0.0 — publishable
pkg_data v0.4.0 — publishable
pkg_app v0.1.0 — private
```

### 04 — Filter projects

`exclude` drops projects by name; `include` keeps only the named ones. These map
to buildkit's `--exclude-projects` and `--project`/`-p`. Filtering runs after
nature detection (so it matches by package name) and before the callback (so
excluded projects are never touched):

```
Excluding pkg_app: pkg_core, pkg_data
Including only pkg_core: pkg_core
```

### 05 — Author a tool

The headline example: a complete one-command tool, `:greet`, built from a
`ToolDefinition`, a `CallbackExecutor`, and a `ToolRunner`. The runner's
progress output is captured into a `StringBuffer` so the example stays quiet and
deterministic; we report the `ToolResult` and the order projects were visited:

```
Succeeded: true
Projects processed: 3
Greeted in build order: pkg_core -> pkg_data -> pkg_app
```

`worksWithNatures: {DartProjectFolder}` on the command is load-bearing: a
command that declares **no** nature requirement is never invoked.

### 06 — Custom command options

A command can declare its own `OptionDefinition`s. A value option,
`--prefix=<text>`, is parsed per command and read back from
`args.commandArgs['label']?.options['prefix']`. Declaring the option (rather
than letting it fall through to `extraOptions`) is what tells the parser it
consumes a value and keeps it from colliding with a global flag. Run with and
without the flag to see the declared default apply:

```
With --prefix BUILD: BUILD:pkg_core, BUILD:pkg_data, BUILD:pkg_app
Default prefix: TOM:pkg_core, TOM:pkg_data, TOM:pkg_app
```

### 07 — Inspect the real buildkit tool

buildkit is just a (large) `ToolDefinition`. Because a definition is plain data,
we can introspect it with no build, no processes, no traversal — closing the
loop between the toy tool and the production one:

```
Tool: buildkit
Multi-command mode: true
Has :pubget command: true
Has :cleanup command: true
:pubget scoped to Dart projects: true
:pg resolves to: pubget
```

`:pubget` — the command this sample's quest is about — sits in buildkit's
command list scoped to `DartProjectFolder`, exactly like our `:greet`. `:pg` is
its alias, resolved by `findCommand`.

---

## The framework at a glance

| Type | Role |
| ---- | ---- |
| `BuildBase` | Static traversal entry points (`findProjects`, `forEachDartProject`, `forEachGitRepo`, `traverse`) |
| `ProjectTraversalInfo` | Traversal configuration (scan path, recursion, filters, build order) |
| `CommandContext` | Per-folder context handed to callbacks/executors |
| `DartProjectFolder` | Dart project nature (name, version, deps, `isPublishable`) and its subtypes |
| `ToolDefinition` | Declares a tool: name, version, mode, commands, global options |
| `CommandDefinition` | One command: name, aliases, options, nature requirements |
| `OptionDefinition` | One flag/value/multi option |
| `CommandExecutor` | Per-project logic; `CallbackExecutor` wraps a closure |
| `ToolRunner` | Parses args, traverses, dispatches; returns a `ToolResult` |
| `ToolResult` / `ItemResult` | Aggregate and per-item outcomes |

All of these are exported from `package:tom_build_base/tom_build_base_v2.dart`.

---

## How traversal targets the fixture

The examples point the traversal at the bundled fixture with two flags:

- `--scan <path>` — where to start scanning;
- `--root <path>` — the execution root, used for relative-path display.

`fixture.dart` derives that path from `Platform.script`, not the current
directory, so the output is identical whether an example is run directly,
through `run_all_examples.dart`, or by the top-level samples aggregator — in all
three cases the running script lives in `example/`.

When you build a real tool you usually pass neither flag: `ToolRunner` then
discovers the workspace root from the current directory and scans `.`.

---

## Going from sample to real tool

To turn `:greet` into something that actually builds, change one line — the body
of the executor:

```dart
CallbackExecutor(onExecute: (ctx, args) async {
  final r = await Process.run('dart', ['pub', 'get'],
      workingDirectory: ctx.path);
  return r.exitCode == 0
      ? ItemResult.success(path: ctx.path, name: ctx.name)
      : ItemResult.failure(path: ctx.path, name: ctx.name, error: r.stderr.toString());
});
```

That is, in essence, buildkit's `:pubget`. The framework already gave you
discovery, build-order sorting, filtering, argument parsing, nature scoping, and
result aggregation — all the parts that are tedious and easy to get wrong. For
the common "run a shell command per project" case the framework even ships a
ready-made `ShellExecutor`, so you write no executor at all.

---

## Layout

```
tom_build_kit_sample/
├── README.md                      ← this file
├── pubspec.yaml                   ← hosted tom_build_base, path tom_build_kit
├── analysis_options.yaml          ← shared lints; excludes the fixture tree
└── example/
    ├── fixture.dart               ← locates the fixture workspace
    ├── fixture_workspace/         ← pkg_core ← pkg_data ← pkg_app (pubspec-only)
    ├── 01_discover_projects.dart
    ├── 02_build_order.dart
    ├── 03_inspect_natures.dart
    ├── 04_filter_projects.dart
    ├── 05_author_a_tool.dart
    ├── 06_custom_command_options.dart
    ├── 07_inspect_buildkit_tool.dart
    └── run_all_examples.dart
```

---

## Related

- `../tom_github_api_sample/` — the REST-client flagship sample.
- `tom_build_base` — the framework these examples exercise.
- `tom_build_kit` — the `buildkit` tool introspected in example 07.
