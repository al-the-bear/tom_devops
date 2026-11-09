## 1.0.9

- **`WorkspaceAnalyzer.findWorkspaceRoot(start)`**: the nearest directory at or
  above `start` holding `tom_workspace.yaml`, or null. `workspace_analyzer`
  without `wa-path=` analyzes that workspace and refuses (exit 64) when there
  is none; it used to take the parent of the current directory and write
  `.tom_metadata/` there, which left stray `.tom_metadata/` folders in the tree
  (`_scripts/`, `tom_ai/`) that root walks took for the workspace. Tests
  WA-ROOT-1..3.
- Removed the stray, tracked `.tom_metadata/workspace_state.yaml` (empty).

## 1.0.8

- **`tom_d4rt_generator >=1.58.0`** (was `>=1.15.3`): the first release on
  `tom_analyzer_shared` 0.13.0. Its summary cache keeps no truncated bundle
  (0.12.0) and no longer deletes a bundle a concurrent run links against
  (0.13.0); both bugs silently dropped types from generated bridges. The floor
  also rules out the analyzer-10 `tom_reflection_generator` line (1.8.x).

## 1.0.7

- **`DependencyScheduler`** runs a job per project in parallel while keeping
  the dependency order: a project starts once every project it waits for has
  succeeded, at most `concurrency` at a time; dependents of a failure are
  skipped (transitively), `stopOnFailure` starts nothing new after the first
  failure, a dependency cycle is refused before anything runs, and results
  come back in the given order. For the Tom CLI's multi-project actions.
- **`TomProject.dependenciesFor(action)`**: the `<action>-after` entry of
  `action-order` when given, else `build-after`.

## 1.0.6

- **`WorkspaceConfigCheck.runOn(discovered)`** checks an already discovered
  project list, so one discovery serves several checks; `run()` uses it.
- Tests: the live-workspace checks moved into one file,
  `test/config/live_workspace_test.dart` (LW-1..5), which discovers once.
  Each action test file used to scan the whole tree itself, and the
  concurrent scans timed out together on a busy disk. Shared helpers and the
  action commands live in `test/config/support/workspace_support.dart`.
- New `test/config/docs_action_test.dart` for the workspace docs action.

## 1.0.5

- **`WorkspaceAnalyzer.runsAction`:** a project whose tom_project.yaml
  defines an action runs it even when the workspace action's `skip-types` /
  `applies-to-types` leave its type out; `tom_master_<action>.yaml` uses it.
- **Flutter app detection:** `flutter_app` is a package that depends on the
  Flutter SDK (under `dependencies`, read from the parsed pubspec) and has
  `lib/main.dart`. Apps with a `lib/src/` were typed `dart_package`, Flutter
  libraries and packages with only a `flutter_test` dev dependency
  `flutter_app`.

## 1.0.4

- **Project type families as constants:** `WorkspaceAnalyzer.dartProjectTypes`,
  `javascriptProjectTypes`, `javaProjectTypes`, `pythonProjectTypes` and their
  union `projectTypes`.
- **A folder is a project exactly when a type is detected.** Discovery and
  detection disagreed: `setup.py` / `setup.cfg` gave a type but did not make a
  folder a project, `requirements.txt` made a project with no type.
- **A tool-only `pyproject.toml` no longer makes a project Python.** It
  counts only when it declares a package (`[project]`, `[build-system]` or a
  packager's `[tool.*]` table); a Node project with ruff/pytest settings is a
  JavaScript project again.

## 1.0.3

- **`WorkspaceConfigCheck`** checks a workspace's project configuration
  beyond the schemas: complete and unique `project_id` / `name`, ordering
  references, `project-info` keys and paths, group members, and every project
  in exactly one group (rules PC-1..4, WC-1..4; reference §7). Read-only.
- **`WorkspaceAnalyzer.discoverProjects()`** finds the projects without
  analyzing them or writing metadata; `analyze()` starts with it.

## 1.0.2

- **`TomWorkspace.knownKeys` and `TomProject.knownKeys`** expose the top-level
  keys the parser reads. `binary-files` was read by `TomProject.fromYaml` but
  missing from its known keys, so it was also carried as a custom tag; it no
  longer is.
- **Configuration reference and JSON Schemas.**
  `doc/tom_configuration_reference.md` lists every key of `tom_workspace.yaml`
  and `tom_project.yaml` with its reader; the schemas are in the workspace at
  `.tom/json-schema/tom_build/`. `test/config/config_schema_test.dart` keeps
  schemas, parser, reference and the workspace's own files in step.
- `tom_project.yaml` names this package's real executable
  (`bin/workspace_analyzer.dart`) in the `source` / `output` form the parser
  reads.

## 1.0.1

- **`TomShell.pipe` now actually feeds `input` to the command's stdin.** The
  previous implementation called `Process.runSync`, which offers no stdin
  channel, so the `input` argument was silently discarded — `pipe('cat',
  'hello')` returned `''` instead of `'hello'`. `input` is now written to a
  temp file and redirected into the command's stdin inside the shell, with the
  command wrapped in a subshell so the redirection binds to the whole command
  (including the head of a pipeline, e.g. `pipe('cat | tr a-z A-Z', 'hello')`
  → `'HELLO'`). Delivering `input` as file data (never on the command line)
  keeps shell metacharacters in it inert.

## 1.0.0

- Initial version.
