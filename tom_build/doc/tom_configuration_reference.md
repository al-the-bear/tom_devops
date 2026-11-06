# Tom Configuration Reference

Every key of `tom_workspace.yaml` and `tom_project.yaml`: its type, its default, and what reads it. The two files configure the Tom CLI (`tom`) and the workspace analyzer. How the keys combine (modes, merging, generation of `tom_master*.yaml`) is in the [Tom tool specification](tom_tool_specification.md) §3–§5.

## Contents

- [1. Files, readers and schemas](#1-files-readers-and-schemas)
- [2. tom_workspace.yaml](#2-tom_workspaceyaml)
- [3. tom_project.yaml](#3-tom_projectyaml)
- [4. Shared blocks](#4-shared-blocks)
- [5. Specified but not read](#5-specified-but-not-read)
- [6. Readers that disagree](#6-readers-that-disagree)

---

## 1. Files, readers and schemas

| File | Location | Read by |
| ---- | -------- | ------- |
| `tom_workspace.yaml` | Workspace root | `TomWorkspace.fromYaml` (tom_build `file_object_model.dart`), the Tom CLI's `ConfigLoader` (imports) and `ConfigValidator`, the workspace analyzer |
| `tom_project.yaml` | Project folder; optional | `TomProject.fromYaml`, the workspace analyzer; `project_id` and `name` also by buildkit and issuekit, `license` by tom_package_scanner |

**Custom tags.** Both files are open: a top-level key this reference does not list is a custom tag. It is carried into the generated `tom_master*.yaml` and can be read from placeholders and D4rt scripts. The workspace's `d4rt:` block (spec §11.2) is such a tag.

**JSON Schemas.** The workspace holds a schema for each file, for editor validation and for the tests:

| Schema | Validates |
| ------ | --------- |
| `.tom/json-schema/tom_build/tom_workspace.schema.json` | `tom_workspace.yaml` |
| `.tom/json-schema/tom_build/tom_project.schema.json` | `tom_project.yaml`, and the workspace's `project-info` entries and `project-info-overrides` blocks |
| `.tom/json-schema/tom_build/tom_build_definitions.schema.json` | Shared blocks referenced by both (no document of its own) |

The schemas are open where the files are open (root, action configs, mode definitions) and closed where the parser reads a fixed shape (executables, version settings, groups, pipelines). A misspelled key inside a closed block is an error, not a silently ignored custom tag.

To validate while editing, add this to the workspace's VS Code settings (YAML extension):

```json
"yaml.schemas": {
  ".tom/json-schema/tom_build/tom_workspace.schema.json": "tom_workspace.yaml",
  ".tom/json-schema/tom_build/tom_project.schema.json": "**/tom_project.yaml"
}
```

`test/config/config_schema_test.dart` in this package keeps the schemas, the parser and this reference together. It checks that the schemas declare exactly the keys `TomWorkspace.knownKeys` and `TomProject.knownKeys` read, that every key has a row here, and that the workspace's own `tom_workspace.yaml` and every tracked `tom_project.yaml` outside test inputs validate. Run it from this package with `testkit :test`. It only reads files.

---

## 2. tom_workspace.yaml

No mode processing is applied to this file.

| Key | Type | Required | Default | Description |
| --- | ---- | -------- | ------- | ----------- |
| `name` | `String` | No | Root folder name | Workspace name |
| `imports` | `List<String>` | No | `[]` | YAML files deep-merged under this one, in order; later files win, this file wins over all. A path is relative to this file, or to the workspace root with `~/`. Lists are replaced, not concatenated. |
| `binaries` | `String` | No | `bin/` | Binary output folder |
| `operating-systems` | `List<String>` | No | — | Desktop and server operating systems built for, e.g. `[macos, linux, windows]` |
| `mobile-platforms` | `List<String>` | No | — | Mobile platforms built for, e.g. `[android, ios]` |
| `workspace-modes` | [WorkspaceModes](#21-workspace-modes) | No | — | Mode types, presets, mode values and the mode selection per action |
| `project-types` | `Map<String, ProjectType>` | No | — | Project type id → definition ([§2.2](#22-project-types)) |
| `actions` | `Map<String, Action>` | **Yes** | — | Action name → definition ([§4.1](#41-actions)); at least one, each with a `default` |
| `cross-compilation` | [CrossCompilation](#43-cross-compilation) | No | — | Targets and which host builds which |
| `groups` | `Map<String, Group>` | No | `{}` | Group name → projects ([§2.3](#23-groups)) |
| `pipelines` | `Map<String, Pipeline>` | No | `{}` | Pipeline name → projects and actions ([§2.4](#24-pipelines)) |
| `project-info` | `Map<String, Project>` | No | `{}` | Project name → settings deep-merged into that project; each entry has the `tom_project.yaml` shape |
| `deps` | `Map<String, String?>` | No | `{}` | Package → version constraint; `null` declares a package without one |
| `deps-dev` | `Map<String, String?>` | No | `{}` | Dev package → version constraint; `null` as for `deps` |
| `version-settings` | [VersionSettings](#25-version-settings) | No | — | Version numbering |
| `<mode-type>-mode-definitions` | [ModeDefinitions](#42-mode-definitions) | Per mode type | — | Attributes of each mode of one mode type, e.g. `execution-mode-definitions` |

The Tom CLI's `ConfigValidator` checks, before anything runs: `actions` is present, every action has a `default`, every action named in `action-mode-configuration` exists in `actions`, and every `cross-compilation.build-on` host and target is listed in `all-targets`.

### 2.1 workspace-modes

| Key | Type | Description |
| --- | ---- | ----------- |
| `mode-types` | `List<String>` | Mode types in use, e.g. `[environment, execution, cloud-provider, deployment, publishing]`. Each has a `<mode-type>-modes` block here and a `<mode-type>-mode-definitions` block at the root. |
| `supported` | `List<Preset>` | Named presets: `name` (required), `description`, `implies` (presets switched on with it) |
| `default` | `String` | The preset in effect when none is chosen |
| `<mode-type>-modes` | `Map` | The values of one mode type: `default` names the value used when none is selected; every other key is a value with `description`, `modes` (presets it switches on) and any further attributes, which are carried as its properties |
| `action-mode-configuration` | [ActionModeMap](#44-action-mode-maps) | Mode selection per action; `default` is the fallback and names a value for each mode type |

### 2.2 project-types

| Key | Type | Description |
| --- | ---- | ----------- |
| `name` | `String` | Display name; defaults to the type id |
| `description` | `String` | |
| `metadata-files` | `Map<String, String>` | Metadata key → file name, e.g. `pubspec-yaml: pubspec.yaml`. The parsed file appears under the key in the project ([§3](#3-tom_projectyaml)); JSON files are converted. |
| `project-info-overrides` | `Project` | Settings merged into every project of this type |

Project type detection itself is built in (spec §7.1); this block only describes the types.

### 2.3 groups

| Key | Type | Description |
| --- | ---- | ----------- |
| `name` | `String` | Defaults to the group's key |
| `description` | `String` | |
| `projects` | `List<String>` | Project names; `tom :groups <group> :<action>` runs the action on them |
| `project-info-overrides` | `Project` | Settings merged into every project of the group |

### 2.4 pipelines

| Key | Type | Description |
| --- | ---- | ----------- |
| `global-parameters` | `List<String>` | Parameters passed to every step |
| `projects` | `List<{name}>` | Projects, in order |
| `actions` | `List<{action}>` | Actions, in order |

### 2.5 version-settings

| Key | Type | Description |
| --- | ---- | ----------- |
| `prerelease-tag` | `String` | Pre-release suffix, e.g. `dev` |
| `auto-increment` | `bool` | Increment the build number automatically |
| `min-dev-build` | `int` | Lowest development build number |
| `action-counter` | `int` | Counter maintained by the Tom CLI; reset with `:reset-action-counter` |

No other key is read here.

---

## 3. tom_project.yaml

The file is optional: a project without one is auto-detected (type, name, metadata from `pubspec.yaml`, `package.json`, ...) and inherits everything from the workspace. Mode processing is applied to this file. **Any key may be `null`:** in a project, `null` unsets the field instead of inheriting it, and a mode set to `null` in `<mode-type>-mode-definitions` is disabled for the project.

| Key | Type | Default | Description |
| --- | ---- | ------- | ----------- |
| `project_id` | `String` | — | Short project id, e.g. `TB`. Selects the project in buildkit (`--project`) and identifies it in issuekit. |
| `name` | `String` | Folder name | Project name |
| `type` | `String` | Auto-detected | A key of the workspace's `project-types`, e.g. `dart_package` |
| `description` | `String` | From the manifest | |
| `license` | `String` | From `LICENSE` | SPDX id; read by tom_package_scanner when no license file says otherwise |
| `binaries` | `String` | Workspace's `binaries` | Binary output folder |
| `build-after` | `List<String>` | `[]` | Projects processed before this one, for every action. Not inherited. |
| `action-order` | `Map<String, List<String>>` | `{}` | `<action>-after` → projects processed before this one for that action, replacing `build-after` for it (spec §3.3.4). Not inherited. Parsed and checked for unknown projects; no build order uses it yet ([§5](#5-specified-but-not-read)). |
| `features` | `Map<String, bool>` | Auto-detected | Feature flags overriding detection, e.g. `publishable`, `has-tests`; `null` drops the override |
| `actions` | `Map<String, Action>` | Workspace's | Action overrides ([§4.1](#41-actions)); an action given here replaces the workspace's definition for this project. `default` is not required. |
| `cross-compilation` | [CrossCompilation](#43-cross-compilation) | Workspace's | |
| `executables` | `List<{source, output}>` | From `bin/` | Entry points to compile: `source` (e.g. `bin/server.dart`) and `output` (the executable name), both required |
| `package-module` | `{name, library-file, source-folders}` | Auto-detected | The package's main library |
| `parts` | `Map<String, Part>` | Auto-detected | Part name → `name`, `library-file`, `modules` (module name → `name`, `library-file`) |
| `tests` | `List<String>` | Auto-detected | Test folders |
| `examples` | `List<String>` | Auto-detected | Example folders |
| `docs` | `List<String>` | Auto-detected | Documentation folders |
| `copilot-guidelines` | `List<String>` | Auto-detected | Guideline files |
| `binary-files` | `List<String>` | — | Prebuilt binaries the project ships |
| `action-mode-definitions` | [ActionModeMap](#44-action-mode-maps) | Workspace's | Mode selection per action for this project's tomplate processing; entries deep-merge with `default` |
| `<mode-type>-mode-definitions` | [ModeDefinitions](#42-mode-definitions) | Workspace's | Deep-merged over the workspace's definitions |
| `<metadata-key>` | `Map` | Parsed file | A metadata key from `project-types.<type>.metadata-files`, e.g. `pubspec-yaml`; any key ending in `-yaml` or `-json` is read as one |

---

## 4. Shared blocks

### 4.1 actions

An action is a map. Its named keys are:

| Key | Type | Description |
| --- | ---- | ----------- |
| `name` | `String` | Defaults to the action's key |
| `description` | `String` | |
| `skip-types` | `List<String>` | Project types the action does not run for |
| `applies-to-types` | `List<String>` | Project types the action runs for exclusively |
| `default` | `ActionConfig` | The commands for every project type without its own entry |

Every other key is a project type id (e.g. `flutter_app`) whose `ActionConfig` replaces `default` for projects of that type. It must be a map.

An **ActionConfig** holds `pre-commands`, `commands` and `post-commands`, each a list of commands. Any other key is a custom tag, carried into `tom_master*.yaml`.

A **command** is a string or a map with exactly one key:

| Form | Runs |
| ---- | ---- |
| `dart pub get` | A shell command |
| `{shell: <command line>}` | A shell command |
| `{dartscript: <code>}` | D4rt code, locally, with `tom`, `project` and the scripting helpers in scope |
| `{vscode: <script>}` | A script through the VS Code bridge |
| `{tom: <:command>}` | A Tom CLI internal command, e.g. `:analyze` |

In a string, the prefixes `dartscript:`, `vscode:` and `tom:` (each followed by a space) and the placeholders `$D4{...}` and `$VSCODE{...}` select the same runners (spec §5.4.2).

```yaml
actions:
  test:
    description: Run tests
    default:
      commands:
        - dart test
    flutter_app:
      commands:
        - flutter test
```

### 4.2 Mode definitions

`<mode-type>-mode-definitions` maps a mode name to its attributes: `description` and any further keys, which are free-form (e.g. `working-dir`, `variables`, `image`). The `default` entry holds the values every mode of the type inherits by deep merge.

```yaml
execution-mode-definitions:
  default:
    working-dir: .
  docker:
    description: Run in container
    image: dart:stable
```

### 4.3 cross-compilation

| Key | Type | Description |
| --- | ---- | ----------- |
| `all-targets` | `List<String>` | Every target, e.g. `darwin-arm64`, `linux-x64`, `win32-x64` |
| `build-on` | `Map<String, {targets}>` | Host target → the targets it builds; host and targets must be in `all-targets` |

Further keys, here and in a `build-on` entry (e.g. `output-dir`), are carried into `tom_master*.yaml` by the workspace analyzer.

### 4.4 Action mode maps

`action-mode-configuration` (workspace) and `action-mode-definitions` (project) map an action name, or `default`, to a mode selection: `description` and mode type → mode name.

```yaml
action-mode-configuration:
  default:
    environment: local
    execution: local
  deploy_prod:
    description: Deploy to production
    environment: prod
    execution: cloud
```

---

## 5. Specified but not read

The [specification](tom_tool_specification.md) describes these; the parser does not read them, so writing them has no effect today. The schema rejects the ones that would otherwise be dropped without notice.

| Feature | Spec | Today |
| ------- | ---- | ----- |
| `skip:` / `applies-to:` (project names) on an action | §3.2.5 | Not read; a list under an action key is rejected by the schema |
| `pre-<action>:` / `post-<action>:` hooks on an action | §3.2.5 | Not read; rejected by the schema. Per project type, `pre-commands` / `post-commands` exist. |
| List operations `$replace`, `$append`, `$prepend`, `$remove` | §3.2.3 | Not implemented; merging replaces lists. Rejected by the schema where a list is expected. |
| Command options `sudo`, `timeout`, `workingDir` in a command map | `ActionExecutor` docs | Not read; rejected by the schema |
| Per-action ordering from `action-order` | §3.3.4 | Parsed and validated; the build order is computed from `build-after` only |

---

## 6. Readers that disagree

**Project `binaries`.** `TomProject` reads `binaries` as the binary output folder (a string). The workspace analyzer reads a project's `binaries` as a list of tool files and writes that list into `tom_master.yaml`; reading such a `tom_master.yaml` back through `TomMaster.fromYaml` fails on the list. The schema follows `TomProject` (a string) and points file lists to `binary-files`. Tracked in the build_tom quest (`aft_cfg-52_akfj-project-binaries-two-readers`).
