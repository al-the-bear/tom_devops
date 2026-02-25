# Tom CLI User Reference

Quick reference for Tom workspace build tool.

---

## 1. Command Line Syntax

```bash
tom [<global-params>] [:projects <p1> [<p1-params>] ...] :<action> [<action-params>] ...
tom [<global-params>] [:groups <g1> [<g1-params>] ...] :<action> [<action-params>] ...
tom [<global-params>] :<action> [<action-params>] ...    # All projects
```

### Naming Conventions

| Type | Format | Example |
|------|--------|---------|
| Arguments | No dash, positional | `my_project`, `build` |
| Parameters | Single dash + value | `-name=value` |
| Options | Single/double dash, boolean | `-verbose`, `--dry-run` |

### Examples

```bash
tom :build                              # Build all projects
tom :projects tom_build :build :test    # Build and test specific project
tom :groups dart-libs :build            # Build project group
tom --verbose -environment=prod :deploy # With global params
```

---

## 2. Internal Commands

| Command | Prefix | Description |
|---------|--------|-------------|
| `:analyze` | `wa-` | Generate `tom_master*.yaml` files |
| `:generate-bridges` | `gb-` | Generate D4rt BridgedClass implementations |
| `:generate-reflection` | `gr-` | Run reflection generator |
| `:md2pdf` | `mp-` | Convert markdown to PDF |
| `:md2latex` | `ml-` | Convert markdown to LaTeX |
| `:version-bump` | `vb-` | Increment versions for changed packages |
| `:prepper` | `wp-` | Run mode/tomplate processing |
| `:reset-action-counter` | — | Reset global action counter |
| `:pipeline` | — | Run named pipeline |
| `:vscode` | — | Execute Dart via VS Code VS Code Bridge |
| `:dartscript` | — | Execute Dart locally via D4rt (default) |
| `:help` | — | Show help |
| `:version` | — | Show version |

**Prefixes:** Use to target parameters: `tom -gr-path=. :generate-reflection`

**Bypass:** Use `!` to force built-in when action has same name: `tom !analyze`

### 2.1 DartScript Commands

Execute Dart code locally (`:dartscript`) or via VS Code (`:vscode`):

```bash
# Local execution via D4rt
tom :dartscript -file=script.dart           # Execute script file
tom :dartscript -code="print('hello')"      # Execute inline code
tom :dartscript -file=script.dart -mode=expression  # As expression

# VS Code bridge execution
tom :vscode -file=script.dart               # Execute via VS Code
tom :vscode -code="print('hello')"          # Inline code via VS Code
tom :vscode -port=9743 -file=script.dart    # Custom port
```

## 4. Placeholders

Placeholders are resolved at runtime (before command execution) or generation time.

| Syntax | Description | Example |
|--------|-------------|---------|
| `$VAL{path}` | Config value lookup | `$VAL{project.name}` |
| `$VAL{path:-default}` | Lookup with default | `$VAL{project.missing:-default}` |
| `$ENV{NAME}` | Environment variable | `$ENV{HOME}` |
| `$ENV{NAME:-default}` | Env var with default | `$ENV{API_KEY:-dev_key}` |
| `$D4{expr}` | D4rt expression | `$D4{version.major + 1}` |
| `$D4S{file.dart}` | D4rt script execution | `$D4S{scripts/my_script.dart}` |
| `$GEN{pattern}` | Generator pattern | `$GEN{projects.*.name;,}` |
| `[[VAR]]` | Generation-time Env Var | `[[HOME]]` |
| `[{path}]` | Generation-time Lookup | `[{packages.tom_core.version}]` |

**Note:** For advanced D4rt usage (multiline scripts, methods), see [tom_build/doc/placeholders_d4rt_guide.md](placeholders_d4rt_guide.md).

---

## 5. D4rt Integration

### 3.1 tom_workspace.yaml

Located at workspace root. Defines workspace-wide settings.

```yaml
# Imports (merged in order)
imports: [shared.yaml, ~/local.yaml]

# Mode system
workspace-modes:
  mode-types: [environment, execution, cloud-provider, deployment, publishing]
  
  environment-modes:
    default: local
    local: { description: "Local dev" }
    prod: { description: "Production" }
  
  action-mode-configuration:
    default: { environment: local, execution: local }
    build: { environment: local }
    deploy: { environment: prod, execution: docker }

# Actions (REQUIRED)
actions:
  build:
    skip-types: [flutter_app]           # OR applies-to-types (not both)
    pre-build: [echo "Starting..."]     # Pre-hook (once)
    post-build: [echo "Done"]           # Post-hook (once)
    default:
      commands: [dart analyze, dart test]
    dart_package:
      commands: [dart pub get, dart analyze]

# Project types
project-types:
  dart_package:
    metadata-files:
      pubspec-yaml: pubspec.yaml
  dart_console:
    metadata-files:
      pubspec-yaml: pubspec.yaml
  flutter_app:
    metadata-files:
      pubspec-yaml: pubspec.yaml
      analysis-options: analysis_options.yaml
  vscode_extension:
    metadata-files:
      package-json: package.json
  typescript_node:
    metadata-files:
      package-json: package.json

# Groups
groups:
  core:
    projects: [tom_core, tom_build]
    project-info-overrides: { features: { publishable: true } }

# Per-project settings
project-info:
  tom_build:
    build-after: [tom_core]

# Mode type definitions
environment-mode-definitions:
  local: { variables: { DEBUG: "true" } }
  prod: { variables: { DEBUG: "false" } }

execution-mode-definitions:
  local: { working-dir: . }
  docker: { image: dart:stable }

# Dependencies
deps:
  path: ^1.9.0
deps-dev:
  test: ^1.25.0

# Pipelines
pipelines:
  ci:
    projects: [{ name: tom_build }]
    actions: [{ action: test }, { action: build }]

# Cross-compilation
cross-compilation:
  all-targets: [darwin-arm64, linux-x64, win32-x64]
  build-on:
    darwin-arm64: { targets: [darwin-arm64, darwin-x64] }
```

### 3.2 tom_project.yaml

Located in project folder. Overrides workspace defaults.

```yaml
# Build ordering
build-after: [tom_core]
action-order:
  deploy-after: [tom_uam_server]

# Feature overrides
features:
  publishable: true
  has-tests: true

# Action overrides (replaces workspace definition for this action)
actions:
  build:
    default:
      commands: [custom build command]

# Executables
executables:
  - source: bin/server.dart
    output: server

# Mode overrides
action-mode-definitions:
  build: { environment: local, execution: docker }

environment-mode-definitions:
  local: { variables: { CUSTOM: "value" } }
```

### 3.3 Merge Rules

- **Maps:** Deep-merged recursively
- **Scalars:** Later overrides earlier
- **Lists:** Replaced entirely (use operators for control)

**List operators:**

```yaml
items: { $replace: [new] }    # Replace list
items: { $append: [more] }    # Append to list
items: { $prepend: [first] }  # Prepend to list
items: { $remove: [unwanted]} # Remove from list
```

---

## 4. Placeholders

Tom processes configuration through three phases, each with its own placeholder types:

### 4.1 Processing Phases

| Phase | When | Placeholders Resolved | Description |
|-------|------|----------------------|-------------|
| **Generation** | Writing tom_master*.yaml | `[[...]]`, `[{...}]` | YAML file construction |
| **Runtime** | After loading, before commands | `$VAL{...}`, `$ENV{...}`, `$D4{...}`, `$VSCODE{...}`, `$GEN{...}`, `[[...]]`, `[{...}]` | Placeholder replacement |
| **Execution** | Commands run one by one | Shell: `$ENV`/`${ENV}` (shell expansion) | `tom:`, `vscode:`, `dartscript:`, shell, reflection |

### 4.2 Generation-Time Placeholders

Resolved during tom_master*.yaml construction (and also at runtime):

| Type | Syntax | Description |
|------|--------|-------------|
| Environment | `[[VAR]]` or `[[VAR:-default]]` | Environment variable |
| Data Path | `[{path.to.value}]` or `[{path:-default}]` | Config value lookup |

**Example usage:**
```yaml
# Resolved at generation time AND runtime
cloud:
  region: "[[AWS_REGION:-us-east-1]]"
  account: "[[AWS_ACCOUNT_ID]]"
  
# Data path reference
version: "[{deps.path}]"
```

### 4.3 Runtime & Execution Placeholders

These placeholders are resolved after configuration loading, either when preparing the action or immediately before executing a command.

| Type | Syntax | Resolution Phase | Description |
|------|--------|------------------|-------------|
| Value Reference | `$VAL{key.path:-default}` | Runtime (Pre-Action) | Config value from workspace/project YAML |
| Generator | `$GEN{path.*.field;sep}` | Runtime (Pre-Action) | Generate list from tom_master*.yaml data |
| Environment | `$ENV{NAME:-default}` | Execution Time | Environment variable (resolved before command run) |

### 4.4 D4rt Local Placeholders (Execution Time)

Execute D4rt locally via the Tom CLI D4rt instance. These are resolved at **Execution Time** by the Action Runner.

| Type | Syntax | Detection |
|------|--------|----------|
| Expression | `$D4{expression}` | Default (no special markers) |
| Script file | `$D4{file.dart}` | Detected by `.dart` suffix |
| Multiline script | `$D4{\n<code>}` | Detected by leading newline |
| Multiline method | `$D4{\n(){<code>}}` | Detected by `\n(){` prefix |

**Note:** `${...}` inside D4rt code is Dart string interpolation, not a Tom placeholder.

### 4.5 VS Code Bridge Placeholders (Execution Time)

Execute D4rt in VS Code's VS Code Bridge (port 9742 default). Resolved at **Execution Time**.

| Type | Syntax | Detection |
|------|--------|----------|
| Expression | `$VSCODE{expression}` | Default (no special markers) |
| Script file | `$VSCODE{file.dart}` | Detected by `.dart` suffix |
| Multiline script | `$VSCODE{\n<code>}` | Detected by leading newline |
| Multiline method | `$VSCODE{\n(){<code>}}` | Detected by `\n(){` prefix |

**Custom port:** `$VSCODE:{9743}expression`, `$VSCODE:{9743}file.dart`

**Note:** `${...}` inside D4rt code is Dart string interpolation, not a Tom placeholder.

### 4.6 D4rt Placeholder Examples

**Inline expression:**
```yaml
value: "$D4{projectInfo.length}"
```

**Script file:**
```yaml
run: "$D4{scripts/deploy.dart}"
```

**Multiline script (void):**
```yaml
custom: |
  $D4{
  import 'package:tom_build/tom.dart';
  void main() {
    print('Projects: ${tom.projectInfo.length}');
  }
  }
```

**Multiline method (returns value):**
```yaml
count: |
  $D4{
  (){
  var count = 0;
  for (final p in tom.projectInfo.values) {
    if (p.publishable == true) count++;
  }
  return count;
  }
  }
```

### 4.7 Generator Placeholders

```yaml
# All project names
all: "$GEN{projects.*.name;,}"
# Output: tom_core,tom_build,tom_tools

# Filtered by attribute
dart_only: "$GEN{projects.[type=dart_package].name;,}"

# Multiple conditions
core: "$GEN{projects.[type=dart_package,name=^tom_.*$].name;-}"
```

**Filter syntax:** `[attr=value,attr2=^regex$]` (all must match)

### 4.7 Escaping

```yaml
literal: \$VAL{not.resolved}    # Preserved as $VAL{...}
```

---

## 5. Action Command Formats

Commands in `actions.<action>.<type>.commands` are executed during the **Execution phase** (after runtime placeholder resolution). Supported formats:

### 5.1 Shell Commands

```yaml
commands:
  - dart analyze lib
  - flutter build apk
```

### 5.2 D4rt Local Commands

Execute Dart code locally via D4rt:

| Format | Example |
|--------|---------|
| Script file | `dartscript: path/to/script.dart` |
| Script file (custom port) | `dartscript:9743: script.dart` |
| Inline code | `dartscript: print('Hello')` |
| Multiline code | YAML block scalar (see below) |
| Reflection call | `BuildTool.generate()` |

```yaml
commands:
  - dartscript: scripts/deploy.dart
  - dartscript: print('Hello')
  - dartscript: |
      print('hello');
      print('second line');
  - BuildTool.generate()
```

**Script wrapping:** Inline code is wrapped as an immediately-invoked function:
- Code prefixed with `((){` and suffixed with `;})();`
- If code already starts with `(){` and ends with `}`, only wrapped with `(` and `)()`

**Note:** D4rt placeholders (`$D4{}`, `$D4S{}`, `$D4M{}`) are resolved at **runtime** (see Section 4.3), not at execution time. Use `dartscript:` command syntax when you want explicit command execution.

### 5.3 VS Code Bridge Commands

Execute Dart code via VS Code's VS Code Bridge (port 9742 default):

| Format | Example |
|--------|--------|
| Script file | `vscode: path/to/script.dart` |
| Script file (custom port) | `vscode:9743: script.dart` |
| Inline code | `vscode: print('Hello')` |
| Multiline code | YAML block scalar (see below) |
| Inline code (custom port) | `vscode:9743: var x = 1; print(x)` |

```yaml
commands:
  - vscode: scripts/deploy.dart
  - vscode:9743: custom_scripts/build.dart
  - vscode: print('Build starting')
  - vscode: |
      print('hello');
      print('second line');
  - vscode: vscode.window.showInformationMessage('Build complete')
```

**Script wrapping:** Inline code is wrapped as an immediately-invoked function:
- Code prefixed with `((){` and suffixed with `;})();`, then sent to `eval(...)`
- If code already starts with `(){` and ends with `}`, only wrapped with `(` and `)()`

This applies to both single-line and multiline scripts for `vscode:` and `dartscript:`.

### 5.4 Tom CLI Commands (Recursive)

Execute Tom CLI directly without spawning shell:

```yaml
commands:
  - tom: :analyze
  - tom: :version
```

**Note:** Only internal commands (starting with `:`) are allowed. Action invocations are not permitted to prevent recursion. Use shell commands for recursive `tom` calls.

### 5.5 Available Context Objects

D4rt expressions and scripts have access to different context objects depending on the execution environment.

#### 5.5.1 Local D4rt Execution (`dartscript:` commands, `$D4{...}` placeholders)

The global `tom` object provides access to workspace and project data:

**Context Objects Summary:**

| Object | Type | Description |
|--------|------|-------------|
| `tom` | `TomContext` | Global context with workspace and project access |
| `tom.workspace` | `TomWorkspace` | Workspace configuration from `tom_workspace.yaml` |
| `tom.project` | `TomProject?` | Current project (null for pre/post-action) |
| `tom.projectInfo` | `Map<String, ProjectInfo>` | All project information |
| `tom.groups` | `Map<String, GroupDef>` | Group definitions |
| `tom.actions` | `Map<String, ActionDef>` | Action definitions |
| `tom.modeDefinitions` | `Map<String, ModeDefinitions>` | Mode definitions by mode type |
| `tom.workspacePath` | `String` | Workspace root directory |
| `tom.cwd` | `String` | Current working directory |
| `tom.env` | `Map<String, String>` | Environment variables |
| `env` | `Map<String, String>` | Shortcut to `tom.env` |
| `Shell` | Class | Static methods for command execution |

**`tom` Object Model:**

```
tom                          # TomContext - global context object
├── workspace                # TomWorkspace - workspace configuration
│   ├── name                 # Workspace name
│   ├── projectInfo          # Map<String, ProjectInfo> - all projects
│   ├── groups               # Map<String, GroupDef> - group definitions
│   ├── actions              # Map<String, ActionDef> - action definitions
│   ├── deps                 # Map<String, String> - dependency versions
│   ├── depsDev              # Map<String, String> - dev dependencies
│   ├── workspaceModes       # WorkspaceModes? - mode configuration
│   ├── modeDefinitions      # Map<String, ModeDefinitions> - mode definitions by type
│   ├── projectTypes         # Map<String, ProjectTypeDef> - type definitions
│   ├── pipelines            # Map<String, Pipeline> - pipeline definitions
│   └── customTags           # Map<String, dynamic> - custom YAML keys
├── project                  # TomProject? - current project (null if workspace-level)
│   ├── name                 # Project name
│   ├── path                 # Project path
│   ├── type                 # Project type
│   └── ...                  # Other project properties
├── workspacePath            # String - workspace root directory
├── cwd                      # String - current working directory
├── env                      # Map<String, String> - environment variables
├── projectInfo              # Map<String, ProjectInfo> - shortcut to workspace.projectInfo
├── groups                   # Map<String, GroupDef> - shortcut to workspace.groups
├── actions                  # Map<String, ActionDef> - shortcut to workspace.actions
├── modeDefinitions          # Map<String, ModeDefinitions> - shortcut to workspace.modeDefinitions
└── isInitialized            # bool - whether context is initialized
```

**Context by Execution Phase:**

| Phase | `tom.project` | Description |
|-------|---------------|-------------|
| Pre-action commands | `null` | Workspace-level, no specific project |
| Per-project commands | `TomProject` | Set to current project being processed |
| Post-action commands | `null` | Workspace-level, no specific project |

**D4rt Instance Lifecycle (Local):**
- A new D4rt instance is created once per action execution
- The instance is reused for all placeholder resolutions and commands within that action
- Before pre/post-action commands: `tom.project` is set to `null`
- Before per-project commands: `tom.project` is set to the current project
- After action completes: instance is disposed (left for garbage collection)
- Initialization script: See `tom_build/lib/src/dartscript/d4rt_cli_initialization.dart`

#### 5.5.2 VS Code Bridge Execution (`vscode:` commands, `$VSCODE{...}` placeholders)

VS Code bridge scripts have access to VS Code APIs, **not** the `tom` context:

**Context Objects Summary:**

| Object | Type | Description |
|--------|------|-------------|
| `vscode` | `VSCode` | Main VS Code API access object |
| `window` | `VSCodeWindow` | Shortcut to `VSCode.window` |
| `workspace` | `VSCodeWorkspace` | Shortcut to `VSCode.workspace` |
| `commands` | `VSCodeCommands` | Shortcut to `VSCode.commands` |
| `extensions` | `VSCodeExtensions` | Shortcut to `VSCode.extensions` |
| `lm` | `VSCodeLanguageModel` | Shortcut to `VSCode.lm` |
| `chat` | `VSCodeChat` | Shortcut to `VSCode.chat` |
| `helper` | `VsCodeHelper` | Helper utilities for common operations |

**Available APIs:**

| Object | Type | Description |
|--------|------|-------------|
| `VSCode.window` | `VSCodeWindow` | Window API (showMessage, activeEditor, etc.) |
| `VSCode.workspace` | `VSCodeWorkspace` | Workspace API (folders, configuration, etc.) |
| `VSCode.commands` | `VSCodeCommands` | Command execution |
| `VSCode.extensions` | `VSCodeExtensions` | Extension access |
| `VSCode.lm` | `VSCodeLanguageModel` | Language model API |
| `VSCode.chat` | `VSCodeChat` | Chat API |

**D4rt Instance Lifecycle (VS Code Bridge):**
- A single D4rt instance is created when `VSCodeBridgeServer` starts
- All bridges (VS Code API, TomCore, TomBuild) are registered once
- Initialization script sets up global variables (`vscode`, `window`, `workspace`, etc.)
- The same instance handles all scripts/expressions from both VS Code and Tom CLI
- Instance persists for the lifetime of the bridge server
- Initialization script: See `tom_vscode_bridge/lib/src/d4rt_initialization.dart`

**Important:** VS Code bridge scripts do NOT have access to `tom.workspace`, `tom.project`, or action context. They are designed for VS Code API interaction only.

#### 5.5.3 Scripting Helper Classes (`Env` & `Shell`)

D4rt scripts (local) have access to helper classes for system interaction.

**`Env` Class:**
| Method | Description |
|--------|-------------|
| `Env.get(name, [default])` | Get environment variable |
| `Env.resolve(str)` | Resolve `{VAR}` and `{VAR:default}` placeholders |
| `Env.expand(str)` | Expand `$VAR` and `${VAR}` placeholders |
| `Env.expandWithDefaults(str)` | Expand like shell with `${VAR:-default}` support |

**`Shell` Class:**
| Method | Description |
|--------|-------------|
| `Shell.run(cmd)` | Execute command and return stdout (throws on error) |
| `Shell.exec(cmd)` | Execute and return exit code |
| `Shell.runAll([cmds])` | Run sequence of commands |

**Note:** `Shell.run` automatically calls `Env.resolve()` on the command string, identifying `{VAR}` syntax. To use standard shell variables (`$VAR`), either use `Env.expand()` explicitly or rely on the underlying OS shell expansion.

#### 5.5.4 Accessing Action Configuration Programmatically

Actions defined in `tom_workspace.yaml` (see Section 3.1) are accessible via `tom.actions`:

```dart
// Get all action definitions
final actions = tom.actions; // Map<String, ActionDef>

// Get a specific action
final buildAction = tom.actions['build'];
if (buildAction != null) {
  print(buildAction.name);           // 'build'
  print(buildAction.skipTypes);      // ['flutter_app'] or null
  print(buildAction.appliesToTypes); // null (mutually exclusive with skipTypes)
  
  // Get default config for all project types
  final defaultConfig = buildAction.defaultConfig;
  if (defaultConfig != null) {
    print(defaultConfig.commands);     // ['dart analyze', 'dart test']
    print(defaultConfig.preCommands);  // Pre-action commands (once)
    print(defaultConfig.postCommands); // Post-action commands (once)
  }
  
  // Get type-specific config
  final dartConfig = buildAction.typeConfigs['dart_package'];
  if (dartConfig != null) {
    print(dartConfig.commands); // ['dart pub get', 'dart analyze']
  }
}
```

**ActionDef Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `name` | `String` | Action name (e.g., 'build', 'test') |
| `description` | `String?` | Optional description |
| `skipTypes` | `List<String>?` | Project types to skip |
| `appliesToTypes` | `List<String>?` | Only apply to these types (exclusive with skipTypes) |
| `defaultConfig` | `ActionConfig?` | Default config for all types |
| `typeConfigs` | `Map<String, ActionConfig>` | Per-project-type configs |

**ActionConfig Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `preCommands` | `List<String>?` | Commands run once before all projects |
| `commands` | `List<String>` | Commands run per project |
| `postCommands` | `List<String>?` | Commands run once after all projects |
| `customTags` | `Map<String, dynamic>` | Custom YAML keys |

---

## 6. Mode Block Syntax

For `.tomplate` files and `tom_project.yaml`:

### 6.1 Global Mode Match

```yaml
@@@mode development
setting: dev-value
@@@mode production
setting: prod-value
@@@mode default
setting: fallback
@@@endmode
```

### 6.2 Mode Type Match

```yaml
@@@mode.execution local
working-dir: .
@@@mode.execution docker
image: my-app:latest
@@@mode default
working-dir: .
@@@endmode
```

### 6.3 Direct Mode Type

```yaml
@@@execution: local
config: local-config
@@@execution: docker
config: docker-config
@@@endmode
```

### 6.4 Escaping

```yaml
\\@@@mode literal    # Preserved as @@@mode literal
```

---

## 7. Template Files (.tomplate)

**Naming:** `file.ext.tomplate` or `file.tomplate.ext`

Both generate `file.ext` with mode blocks and placeholders resolved.

**Processing:** Templates are processed before each action execution.

**Edit .tomplate files, not generated output.**

---

## 8. Generated Files

| File | Location | Purpose |
|------|----------|---------|
| `tom_master.yaml` | `.tom_metadata/` | Generic master for tooling |
| `tom_master_<action>.yaml` | `.tom_metadata/` | Action-specific config |
| `tom_master_<action>_<mode>.yaml` | `.tom_metadata/` | Mode-variant config |

**Do not edit.** These are regenerated automatically.
