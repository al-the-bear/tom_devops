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
