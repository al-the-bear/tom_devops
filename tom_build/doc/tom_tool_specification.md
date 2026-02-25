# Tom CLI Specification

Comprehensive specification for the Tom CLI workspace build and management tool.

**Version:** 1.1.0
**Last Updated:** 2026-01-14

---

## Contents

1. [Overview](#1-overview)
2. [Terminology](#2-terminology)
3. [Configuration Files](#3-configuration-files)
4. [Mode System](#4-mode-system)
5. [Processing Pipeline](#5-processing-pipeline)
6. [Command Line Interface](#6-command-line-interface)
7. [Auto-Detection](#7-auto-detection)
8. [Object Model](#8-object-model)
9. [Error Handling](#9-error-handling)
10. [Examples](#10-examples)
11. [D4rt Integration](#11-d4rt-integration)

---

## 1. Overview

### 1.1 Purpose

Tom CLI is a workspace build and management tool that:

- Discovers and analyzes projects in a workspace
- Generates configuration metadata from YAML files
- Executes build, test, deploy, and publish actions
- Supports conditional configuration via a mode system
- Provides template processing for dynamic file generation

### 1.2 Architecture Summary

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                              TOM CLI ARCHITECTURE                           │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   User Input    │     │   Workspace     │     │   Generated     │
│                 │     │   Analyzer      │     │   Output        │
│ • CLI commands  │ ──► │                 │ ──► │                 │
│ • YAML configs  │     │ • Discovery     │     │ • tom_master_*  │
│ • .tomplate     │     │ • Generation    │     │ • Target files  │
│   files         │     │ • Execution     │     │ • Build outputs │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### 1.3 Key Capabilities

| Capability | Description |
| ---------- | ----------- |
| Project Discovery | Auto-detect project types from manifest files |
| Configuration Merging | Layered configuration with workspace, group, and project levels |
| Mode System | Conditional configuration based on environment, execution, deployment |
| Template Processing | `.tomplate` files with placeholder resolution and mode blocks |
| Action Execution | Shell commands, D4rt scripts, and reflection-based methods |
| Dependency Ordering | Topological sort of project build order |

---

## 2. Terminology

| Term | Definition |
| ---- | ---------- |
| **Action** | A named operation (build, test, deploy, publish) with associated commands |
| **Action Mode Configuration** | Mode type selections for a specific action (environment, execution, etc.) |
| **Cross-Compilation** | Building executables for different target platforms from a single host |
| **D4rt** | Dart interpreter used for dynamic script execution |
| **Deep Merge** | Recursive merging where nested maps are combined, scalars are replaced |
| **Feature Flags** | Boolean indicators of project capabilities (has-reflection, publishable, etc.) |
| **Generator Placeholder** | Placeholder that produces lists from data (`$GEN{path.*.field;sep}`) |
| **Group** | Named collection of projects for batch operations |
| **Manifest File** | Project definition file (pubspec.yaml, package.json, pyproject.toml, etc.) |
| **Master File** | Generated `tom_master_<action>.yaml` containing resolved configuration |
| **Metadata File** | Project-type-specific configuration file (e.g., pubspec.yaml for Dart) |
| **Mode** | Named configuration variant (e.g., development, production) |
| **Mode Block** | Conditional YAML section activated by specific modes (`@@@mode...@@@endmode`) |
| **Mode Definition** | Configuration attributes for a mode (in `<mode-type>-mode-definitions`) |
| **Mode Type** | Category of modes (environment, execution, deployment, etc.) |
| **Pipeline** | Predefined sequence of actions with parameters |
| **Placeholder** | Dynamic value reference (`$VAL{...}`, `$ENV{...}`, `$D4{...}`, `$GEN{...}`) |
| **Project** | Directory with a manifest file (pubspec.yaml, package.json, etc.) |
| **Project Info** | Per-project configuration in `project-info:` section of tom_workspace.yaml |
| **Project Type** | Classification of project (dart_package, flutter_app, typescript_node, etc.) |
| **Tomplate** | Template file (`.tomplate`) processed to generate target file |
| **Workspace** | Root directory containing projects and `tom_workspace.yaml` |
| **Workspace Analyzer** | Component that discovers projects and generates master files |

---

## 3. Configuration Files

### 3.1 File Hierarchy

| File | Location | Purpose | Editable | Mode Processing |
| ---- | -------- | ------- | -------- | --------------- |
| `tom_workspace.yaml` | Workspace root | Workspace-level settings and defaults | Yes | No |
| `tom_project.yaml` | Project folder | Project-specific overrides | Yes | Yes |
| `tom_master.yaml` | `.tom_metadata/` | Generic master for Copilot/tooling | No | N/A |
| `tom_master_<action>.yaml` | `.tom_metadata/` | Action-specific resolved config | No | N/A |

### 3.2 tom_workspace.yaml Schema

**Location:** `{workspace_root}/tom_workspace.yaml`

**Purpose:** Defines workspace-level settings, mode definitions, project defaults, and groupings.

**Note:** No mode processing is applied to this file.

#### 3.2.1 Complete Field Reference

| Field | Type | Required | Default | Description |
| ----- | ---- | -------- | ------- | ----------- |
| `imports` | `List<String>` | No | `[]` | YAML files to merge (later overrides earlier) |
| `workspace-modes` | `WorkspaceModes` | No | — | Mode definitions and action-mode-configuration |
| `project-types` | `Map<String, ProjectTypeDef>` | No | Built-in | Project type definitions with metadata files |
| `actions` | `Map<String, ActionDef>` | Yes | — | Action definitions with commands |
| `binaries` | `String` | No | `bin/` | Binary output folder |
| `cross-compilation` | `CrossCompilation` | No | — | Cross-compilation targets and build-on rules |
| `groups` | `Map<String, GroupDef>` | No | `{}` | Project groupings with overrides |
| `environment-mode-definitions` | `Map<String, EnvironmentModeDef>` | No | — | Environment mode configurations |
| `execution-mode-definitions` | `Map<String, ExecutionModeDef>` | No | — | Execution mode configurations |
| `deployment-mode-definitions` | `Map<String, DeploymentModeDef>` | No | — | Deployment mode configurations |
| `cloud-provider-mode-definitions` | `Map<String, CloudProviderModeDef>` | No | — | Cloud provider configurations |
| `publishing-mode-definitions` | `Map<String, PublishingModeDef>` | No | — | Publishing/release configurations |
| `project-info` | `Map<String, ProjectInfo>` | No | `{}` | Per-project default settings |
| `deps` | `Map<String, String>` | No | `{}` | Dependency version constraints |
| `deps-dev` | `Map<String, String>` | No | `{}` | Dev dependency versions |
| `version-settings` | `VersionSettings` | No | — | Version management settings |
| `pipelines` | `Map<String, Pipeline>` | No | `{}` | Pipeline definitions |
| `<custom-tag>` | `Any` | No | — | Any additional tags are passed through to tom_master*.yaml |

**Note on Custom Tags:** Users may add any additional top-level tags to `tom_workspace.yaml`. These will be included in the generated `tom_master*.yaml` files and can be referenced in placeholders and scripts.

#### 3.2.1a project-types Structure

Defines project types and their associated metadata files:

```yaml
project-types:
  dart_package:
    name: Dart Package
    description: A publishable Dart library
    metadata-files:
      pubspec-yaml: pubspec.yaml
      build-yaml: build.yaml
    project-info-overrides:           # Optional: applied to all projects of this type
      features:
        publishable: true
  
  flutter_app:
    name: Flutter Application
    description: A Flutter mobile/web application
    metadata-files:
      pubspec-yaml: pubspec.yaml
      analysis-options: analysis_options.yaml
    project-info-overrides:
      features:
        has-assets: true
  
  typescript_node:
    name: TypeScript Node.js
    description: A TypeScript Node.js project
    metadata-files:
      package-json: package.json
      tsconfig-json: tsconfig.json
```

**Note:** The `project-info-overrides:` content is merged with individual project information when assembling the project sections in `tom_master*.yaml` files. This is similar to the `project-info-overrides:` in group definitions.

**Metadata File Keys:** The key (e.g., `pubspec-yaml`) is used in `tom_project.yaml` to reference the parsed content of that file. JSON files are automatically converted to YAML format when included.

**Required Configuration:** The `project-types:` section with `metadata-files:` definitions is **required** for all project types used in the workspace. Each project type must explicitly define which metadata files should be parsed and included.

**Project Type Detection:** Project type detection remains **hard-coded** in the current implementation. The detection logic is isolated in a separate module to enable future configuration via `project-types:` rules. See Section 7.1 for detection rules.

#### 3.2.2 Import Path Resolution

Import paths are resolved as follows:

| Path Format | Resolution | Example |
| ----------- | ---------- | ------- |
| `filename.yaml` | Relative to containing file | `shared.yaml` in same directory |
| `subdir/file.yaml` | Relative path from containing file | `./subdir/file.yaml` |
| `~/filename.yaml` | Relative to workspace root | Always from `tom_workspace.yaml` location |

#### 3.2.3 YAML Deep Merge Semantics

When merging YAML configurations (imports, workspace-to-project), **deep merge** is used:

```yaml
# Base
config:
  a: 1
  b: 2

# Override
config:
  b: 3
  c: 4

# Result (deep merge)
config:
  a: 1    # Preserved from base
  b: 3    # Overridden
  c: 4    # Added from override
```

**Merge Rules:**

1. Maps are deep-merged recursively
2. Later values override earlier values for same keys
3. Lists are replaced entirely (not concatenated)
4. Scalar values are replaced

**List Operations:** To control list merging, use special keys:

| Key | Effect | Example |
| --- | ------ | ------- |
| `$replace` | Replace entire list | `items: { $replace: [new] }` |
| `$append` | Append to existing | `items: { $append: [more] }` |
| `$prepend` | Prepend to existing | `items: { $prepend: [first] }` |
| `$remove` | Remove items | `items: { $remove: [unwanted] }` |

**YAML List Operations Examples:**

```yaml
# Base file (tom_workspace.yaml)
actions:
  build:
    skip-types: [dart_package, flutter_app]

# Override file (tom_workspace_local.yaml)
actions:
  build:
    skip-types: { $append: [typescript_node] }

# Result after merge:
actions:
  build:
    skip-types: [dart_package, flutter_app, typescript_node]
```

```yaml
# Replace entire list
skip-types: { $replace: [node_cli] }
# Result: skip-types: [node_cli]

# Prepend to list
skip-types: { $prepend: [vscode_extension] }
# Result: skip-types: [vscode_extension, dart_package, flutter_app]

# Remove from list
skip-types: { $remove: [flutter_app] }
# Result: skip-types: [dart_package]
```

**Implementation Reference:**

The deep merge implementation is in the `little_things` module of `tom_core_kernel`. This implementation handles standard deep merge operations and should be extended to support the list operations (`$append`, `$prepend`, `$replace`, `$remove`) specified above.

See [_ai/replies/260113_merging_and_classes.md](../../_ai/replies/260113_merging_and_classes.md) for architectural guidance on using Maps during generation vs Object Model during execution.

**Implementation Verification:**

- [ ] Deep merge with recursive map handling
- [ ] List operations: $replace, $append, $prepend, $remove
- [ ] Later values override earlier values
- [ ] Code location: `config/config_merger.dart`
- [ ] Tests: `test/config/config_merger_test.dart`

#### 3.2.4 workspace-modes Structure

```yaml
workspace-modes:
  # REQUIRED: Declares all mode types used in this workspace
  mode-types: [environment, execution, cloud-provider, deployment, publishing]
  
  supported:                          # Named mode presets
    - name: <mode_name>
      description: <description>
      implies: [<other_modes>]        # Modes automatically enabled
  
  # For each mode type in mode-types, define a <mode-type>-modes block:
  
  environment-modes:                  # Environment mode type
    default: <mode_name>
    <mode_name>:
      description: <description>
      modes: [<implied_modes>]        # Supported modes enabled for this value
  
  execution-modes:                    # Execution mode type
    default: <mode_name>
    <mode_name>:
      description: <description>
      modes: [<implied_modes>]
  
  cloud-provider-modes:               # Cloud provider mode type
    default: <provider_name>
    <provider_name>:
      description: <description>
      modes: [<implied_modes>]
  
  deployment-modes:                   # Deployment mode type
    default: <mode_name>
    <mode_name>:
      description: <description>
      modes: [<implied_modes>]
  
  publishing-modes:                   # Publishing mode type
    default: <mode_name>
    <mode_name>:
      description: <description>
      modes: [<implied_modes>]
  
  # REQUIRED: Action mode configuration - defines mode selections per action
  action-mode-configuration:          # Renamed from action-modes
    default:                          # Fallback values for all mode types
      environment: <mode_name>
      execution: <mode_name>
      cloud-provider: <provider_name>
      deployment: <mode_name>
      publishing: <mode_name>
    <action_name>:                    # e.g., build, deploy_prod
      description: <description>
      environment: <mode_name>
      execution: <mode_name>
      cloud-provider: <provider_name>
      deployment: <mode_name>
      publishing: <mode_name>
```

**Validation Rules:**

1. Every mode type in `mode-types` must have a corresponding `<mode-type>-modes` block
2. Every mode name used in `<mode-type>-modes` must be defined in `<mode-type>-mode-definitions`
3. Every action in `action-mode-configuration` must be defined in the `actions` block
4. `action-mode-configuration.default` must define a value for each mode type in `mode-types`
5. Every mode name referenced in `action-mode-configuration` must be a valid mode defined in the corresponding `<mode-type>-modes` block

All consistency checks are performed after configuration files are fully assembled but **before** any commands or actions are executed. If validation fails, Tom aborts with clear error messages. For VS Code linting integration, see [workspace_metadata_linting.md](workspace_metadata_linting.md).

#### 3.2.5 actions Structure

```yaml
actions:
  <action_name>:
    # Project filtering (MUTUALLY EXCLUSIVE - use only skip OR applies-to)
    skip: [<project_names>]           # Projects to skip
    skip-types: [<project_types>]     # Project types to skip
    applies-to: [<project_names>]     # Only include these projects
    applies-to-types: [<project_types>] # Only include these types
    
    # Pre/Post hooks (optional, executed once per action run)
    pre-<action_name>:                # Commands before any project is processed
      - <command>
    post-<action_name>:               # Commands after all projects are processed
      - <command>
    
    default:                          # REQUIRED: default for all project types
      commands:
        - <command>
      <custom-tag>: <value>
    
    <project_type>:                   # Override for specific project type
      commands:
        - <command>
      output: <directory>
```

**Pre/Post Action Hooks:**

- `pre-<action_name>:` - Commands executed **once** before the action is applied to any project
- `post-<action_name>:` - Commands executed **once** after all projects have been processed

These are known tags (not custom tags) and are processed automatically by Tom.

**Project Filtering Constraint:**

Only **one** filtering strategy is allowed per action:

| Strategy | Tags Used | Effect |
| -------- | --------- | ------ |
| Skip | `skip:` and/or `skip-types:` | Process all except listed |
| Applies-to | `applies-to:` and/or `applies-to-types:` | Process only listed |

**Error:** Using both skip and applies-to tags together results in an error:

```text
Error: Action [build] uses both skip and applies-to filtering
  File: [~/tom_workspace.yaml]
  Resolution: Use either skip/skip-types OR applies-to/applies-to-types, not both
```

**Action Definition Constraint:** Each action in `action-mode-configuration` MUST have a corresponding entry in `actions` with at least a `default` definition.

#### 3.2.6 groups Structure

```yaml
groups:
  <group_name>:
    description: <description>
    projects: [<project_names>]
    project-info-overrides:           # Applied to all projects in group
      <any_project_setting>: <value>
```

**Note:** The `project-info-overrides:` content is merged with individual project information when assembling the project sections in `tom_master*.yaml` files.

#### 3.2.7 Mode Type Definitions

For each mode type in `mode-types`, a corresponding `<mode-type>-mode-definitions` block must exist at the top level of `tom_workspace.yaml`. These define the configuration attributes for each mode.

**Naming Pattern:** `<mode-type>-mode-definitions` (e.g., `execution-mode-definitions`, `deployment-mode-definitions`)

**Default Inheritance:** The `default` key in each definitions block provides base values that are **deep-merged** with individual mode definitions. Nested maps are merged recursively; scalars and lists are replaced.

```yaml
# Environment mode definitions
environment-mode-definitions:
  default:                            # Base values for all environment modes
    description: Default environment
  local:
    description: Local development environment
    working-dir: .
    variables:
      DEBUG: "true"
  prod:
    description: Production environment
    variables:
      DEBUG: "false"
      LOG_LEVEL: "warn"

# Execution mode definitions
execution-mode-definitions:
  default:                            # Base values for all execution modes
    working-dir: .
  local:
    description: Run directly on host
  docker:
    description: Run in container
    image: dart:stable
    volumes: []
    ports: []
  cloud:
    description: Run on cloud platform
    provider: aws

# Deployment mode definitions
deployment-mode-definitions:
  default:
    strategy: rolling
  none:
    description: No deployment
  docker-compose:
    description: Docker Compose deployment
    compose-file: docker-compose.yml
  kubernetes:
    description: Kubernetes deployment
    namespace: default
    replicas: 1

# Cloud provider mode definitions
cloud-provider-mode-definitions:
  default:
    region: us-east-1
  aws:
    name: Amazon Web Services
    region: "$ENV{AWS_REGION}"
    account-id: "$ENV{AWS_ACCOUNT_ID}"
  gcp:
    name: Google Cloud Platform
    project-id: "$ENV{GCP_PROJECT_ID}"
  azure:
    name: Microsoft Azure
    subscription-id: "$ENV{AZURE_SUBSCRIPTION_ID}"

# Publishing mode definitions
publishing-mode-definitions:
  default:
    changelog: CHANGELOG.md
  development:
    description: Development builds
    publish: false
  release:
    description: Production release
    publish: true
    tag-prefix: v
  pub-dev:
    description: Publish to pub.dev
    publish: true
    repository: pub.dev
```

**Validation:** If a mode is referenced in `<mode-type>-modes` but not defined in `<mode-type>-mode-definitions`, the tool MUST report an error and fail (fail-fast).

### 3.3 tom_project.yaml Schema

**Location:** `{project_folder}/tom_project.yaml` (or `tom_project.yaml.tomplate` or `tom_project.tomplate.yaml`)

**Purpose:** Project-specific configuration that overrides workspace defaults.

**IMPORTANT - Optional File:** This file is **completely optional**. When a project does not have a `tom_project.yaml` file:

1. **Auto-detection** provides project type, name, and basic metadata from manifest files (pubspec.yaml, package.json, etc.)
2. **Workspace fallbacks** are used for all configuration - the project inherits from `tom_workspace.yaml`
3. **Actions are copied** from `tom_workspace.yaml` to ensure the project has all action definitions
4. **Mode definitions** from workspace level are used as-is

This enables minimal configuration for simple projects while allowing full customization when needed.

**Note:** Mode processing IS applied to this file. The `.tomplate.yaml` extension is preferred for better editor support (YAML syntax highlighting and validation).

#### 3.3.1 Complete Field Reference

**Parity with tom_workspace.yaml:** Most fields that appear in `tom_workspace.yaml` can also be specified at project level to override workspace defaults. This enables flexible project-specific customization.

**Mode Definitions:** The `workspace-modes:` section in `tom_workspace.yaml` declares which mode types exist. Any mode type declared there may have a corresponding `<mode-type>-mode-definitions` section in `tom_project.yaml`. These project-level definitions are **completely optional** and override workspace defaults when present.

| Field | Type | Required | Default | Description |
| ----- | ---- | -------- | ------- | ----------- |
| `build-after` | `List<String>` | No | `[]` | Default build dependencies |
| `action-order` | `Map<String, List>` | No | `{}` | Action-specific ordering |
| `features` | `Map<String, bool>` | No | Auto | Feature flag overrides |
| `actions` | `Map<String, ActionDef>` | No | `{}` | Action overrides (same structure as workspace) |
| `binaries` | `String` | No | Inherit | Binary output folder |
| `executables` | `List<ExecutableDef>` | No | Auto | Source files to compile |
| `cross-compilation` | `CrossCompilation` | No | Inherit | Cross-compilation overrides |
| `environment-mode-definitions` | `Map<String, EnvironmentModeDef>` | No | `{}` | Environment mode overrides |
| `execution-mode-definitions` | `Map<String, ExecutionModeDef>` | No | `{}` | Execution mode overrides |
| `deployment-mode-definitions` | `Map<String, DeploymentModeDef>` | No | `{}` | Deployment mode overrides |
| `cloud-provider-mode-definitions` | `Map<String, CloudProviderModeDef>` | No | `{}` | Cloud provider overrides |
| `publishing-mode-definitions` | `Map<String, PublishingModeDef>` | No | `{}` | Publishing mode overrides |
| `action-mode-definitions` | `Map<String, ActionModeDef>` | No | `{}` | Per-action mode overrides |
| `<metadata-key>` | `Map<String, dynamic>` | No | Auto | Parsed metadata file content (e.g., `pubspec-yaml`) |
| `<custom-tag>` | `Any` | No | — | Any additional tags are passed through |

**Note on Custom Tags:** Users may add any additional tags beyond those listed above. These are not a special section called "custom-settings" but simply any additional YAML tags that will be included in the generated `tom_master*.yaml` files and can be referenced in placeholders and scripts. This applies to both `tom_workspace.yaml` and `tom_project.yaml`.

**Note on Mode Definitions:** Project-level `<mode-type>-mode-definitions` deep-merge with workspace-level definitions. The project values override workspace defaults for matching keys.

#### 3.3.1a executables Structure

Specifies source files to compile and their output names:

```yaml
executables:
  - source: bin/server.dart
    output: server
  - source: bin/cli.dart
    output: tom-cli
```

When not specified, executables are auto-detected from `bin/` directory (Dart) or `src/` directory (other languages).

#### 3.3.2 action-mode-definitions Structure

Override action-mode-configuration for this project's tomplate processing:

```yaml
action-mode-definitions:
  default:                          # REQUIRED: fallback for unspecified actions
    environment: local
    execution: local
    cloud-provider: aws
    deployment: none
    publishing: development
  
  build:
    environment: local
    execution: docker
  
  deploy:
    environment: prod
    execution: cloud
    cloud-provider: gcp
    deployment: kubernetes
    publishing: release
```

**Merge Behavior:** Action-specific entries deep-merge with the `default` entry. Only specify values that differ from the default.

#### 3.3.3 Special Values

| Value | Context | Effect |
| ----- | ------- | ------ |
| `null` | Any field | Removes/unsets the field (does not inherit from parent) |
| `<mode-type>-mode-definitions.<mode>: null` | Mode definitions | Disables a mode for this project |

**Features Configuration:**

Feature flags (`features.<name>`) accept `true` or `false` values:

```yaml
features:
  has-reflection: true    # Force enable (even if not auto-detected)
  has-tests: false         # Force disable (even if auto-detected)
  publishable: false       # Override auto-detection
```

This is standard boolean configuration, not a special value system.

**Non-Inheritable Fields:**

`build-after` and `action-order` cannot be inherited through the merge hierarchy. They are always project-specific. However, they can be overridden via command-line parameters.

#### 3.3.4 action-order Semantics

`<action>-after:` REPLACES `build-after:` for that specific action:

```yaml
build-after:
  - project_b           # Default for all actions

action-order:
  deploy-after:
    - project_c         # Only project_c before deploy (NOT project_b)
```

#### 3.3.5 Metadata File Content

The `project-types:` definition in `tom_workspace.yaml` specifies which metadata files can be included. The key from `metadata-files:` is used as the field name:

```yaml
# Given this project-types definition:
project-types:
  dart_package:
    metadata-files:
      pubspec-yaml: pubspec.yaml

# In tom_project.yaml, the parsed pubspec.yaml appears as:
pubspec-yaml:
  name: my_package
  version: 1.0.0
  dependencies:
    path: ^1.9.0
```

**Note:** `pubspec-yaml` is only valid for Dart projects. Other project types use different metadata keys (e.g., `package-json` for Node.js projects). JSON files are automatically converted to YAML format.

### 3.4 tom_master Files

**Location:** `.tom_metadata/`

**Files Generated:**

| File | Purpose |
| ---- | ------- |
| `tom_master.yaml` | Generic master (all defaults) for Copilot/tooling queries |
| `tom_master_<action>.yaml` | Action-specific resolved configuration |
| `tom_master_<action>_<mode-type>-<value>.yaml` | Mode-variant specific |

**Naming Pattern:** `tom_master_<action>[_<mode-type>-<value>]*.yaml`

**Key Characteristics:**

| Aspect | Input Files | tom_master_*.yaml |
| ------ | ----------- | ----------------- |
| Editability | User-editable | Generated (read-only) |
| Placeholders | `$VAL{...}`, `$ENV{...}`, `$D4{...}`, `$GEN{...}` | `$VAL{...}` resolved; others preserved |
| Build order | Dependencies declared | Topologically sorted |

#### 3.4.1 tom_master.yaml Structure

The `tom_master*.yaml` files contain fully resolved workspace and project configuration. The structure mirrors `tom_workspace.yaml` with computed fields added:

```yaml
# === METADATA ===
scan-timestamp: "<ISO 8601 timestamp>"

# === WORKSPACE CONFIGURATION (from tom_workspace.yaml) ===

name: <workspace_name>
binaries: <binary_output_folder>
operating-systems: [macos, linux, windows]
mobile-platforms: [android, ios]

# Project type definitions
project-types:
  <type_name>:
    name: <display_name>
    description: <description>
    metadata-files:
      <tag>: <filename>
    project-info-overrides:             # Default settings for all projects of this type
      <setting>: <value>

# Workspace modes configuration (same structure as tom_workspace.yaml)
workspace-modes:
  mode-types: [<mode_type_names>]
  
  supported:
    - name: <mode_name>
      description: <description>
      implies: [<other_modes>]
  
  <mode-type>-modes:                    # e.g., environment-modes, execution-modes
    default: <default_mode>
    <mode_name>:
      description: <description>
      modes: [<implied_supported_modes>]
      # ... mode-specific properties
  
  action-mode-configuration:
    default:
      <mode_type>: <mode_name>
    <action_or_config_name>:
      description: <description>
      <mode_type>: <mode_name>

# Cross-compilation settings
cross-compilation:
  all-targets: [<target_names>]
  build-on:
    <host_target>:
      targets: [<target_names>]

# Action definitions
actions:
  <action_name>:
    name: <action_name>
    description: <description>
    skip-types: [<project_types>]       # Optional
    applies-to-types: [<project_types>] # Optional (mutually exclusive with skip-types)
    default:
      pre-commands: [<commands>]
      commands: [<commands>]
      post-commands: [<commands>]
    <project_type>:                     # Type-specific override
      commands: [<commands>]

# Group definitions
groups:
  <group_name>:
    name: <group_name>
    description: <description>
    projects: [<project_names>]
    project-info-overrides:
      <setting>: <value>

# Mode type definitions (same structure as tom_workspace.yaml)
<mode-type>-mode-definitions:           # e.g., environment-mode-definitions
  default:
    <property>: <value>
  <mode_name>:
    description: <description>
    <property>: <value>

# Pipelines
pipelines:
  <pipeline_name>:
    global-parameters: [<parameters>]
    projects:
      - name: <project_name>
    actions:
      - action: <action_name>

# Project info (per-project settings from workspace)
project-info:
  <project_name>:
    <setting>: <value>

# Dependencies
deps:
  <package>: <version>

deps-dev:
  <package>: <version>

# Version settings
version-settings:
  prerelease-tag: <tag>
  auto-increment: <bool>
  min-dev-build: <number>
  action-counter: <number>

# Custom tags (integrated at top level)
<custom_tag>: <value>

# === COMPUTED FIELDS (generated by Tom) ===

# Build order (calculated from build-after dependencies)
build-order: [<project_names_in_order>]

# Action order (calculated from action-order dependencies)
action-order:
  <action_name>: [<project_names_in_order>]

# === PROJECTS (with full computed details) ===

projects:
  <project_name>:
    name: <project_name>
    type: <project_type>
    description: <description>
    
    # Build ordering
    build-after: [<project_names>]
    action-order:
      <action>-after: [<project_names>]
    
    # Features (auto-detected)
    features:
      publishable: <bool>
      has-tests: <bool>
      has-examples: <bool>
      has-build-runner: <bool>
      has-docker: <bool>
      # ... other feature flags
    
    # Mode definitions (final state after processing all levels)
    <mode-type>-mode-definitions:
      <mode_name>:
        description: <description>
        <property>: <value>
    
    # Cross-compilation (project override if present)
    cross-compilation:
      all-targets: [<target_names>]
      build-on:
        <host_target>:
          targets: [<target_names>]
    
    # Actions (merged with workspace defaults)
    actions:
      <action_name>:
        name: <action_name>
        default:
          pre-commands: [<commands>]
          commands: [<commands>]
          post-commands: [<commands>]
    
    # Auto-detected source structure
    package-module:
      name: <module_name>
      library-file: <path>
      source-folders: [<paths>]
    
    parts:
      <part_name>:
        name: <part_name>
        library-file: <path>
        modules:
          <module_name>:
            name: <module_name>
            library-file: <path>
    
    # Discovered files
    tests: [<paths>]
    examples: [<paths>]
    docs: [<paths>]
    copilot-guidelines: [<paths>]
    binaries: [<paths>]
    
    # Metadata files (as direct tags)
    pubspec-yaml:                       # For Dart projects
      name: <package_name>
      version: <version>
      description: <description>
      environment:
        sdk: <sdk_version>
      dependencies: {...}
      dev_dependencies: {...}
    
    package-json:                       # For Node/VS Code projects
      name: <package_name>
      version: <version>
      # ...
    
    # Executables
    executables:
      - source: <path>
        output: <name>
    
    # Custom tags (integrated at project level)
    <custom_tag>: <value>
```

**Note:** The `build-on:` keys must match entries in `all-targets`. This is a consistency check.

**Compact Output Note:** To reduce redundancy and improve readability, project sections **omit** the following fields when they are identical to the workspace-level definitions:

- `cross-compilation` - omitted if identical to workspace `cross-compilation`
- `<mode-type>-mode-definitions` - omitted per mode-type if identical to workspace definitions
- `actions` - omitted if identical to workspace `actions`

This means project sections only contain these fields when they have project-specific overrides that differ from the workspace defaults.

#### 3.4.2 Mode-Variant File Generation

Mode-variant specific files (`tom_master_<action>_<mode-type>-<value>.yaml`) are generated when:

1. **Explicit Request:** User specifies mode overrides on command line:

   ```bash
   tom -environment=prod -execution=docker :build
   ```

   This generates `tom_master_build_environment-prod_execution-docker.yaml`.

2. **Mode Type Override Parameters:**

   | Parameter | Effect |
   | --------- | ------ |
   | `-environment=<mode>` | Override environment mode type |
   | `-execution=<mode>` | Override execution mode type |
   | `-cloud-provider=<mode>` | Override cloud provider mode type |
   | `-deployment=<mode>` | Override deployment mode type |
   | `-publishing=<mode>` | Override publishing mode type |

3. **File Naming Convention:**

   Mode overrides are appended to the filename in alphabetical order by mode type:

   ```text
   tom_master_<action>_<type1>-<value1>_<type2>-<value2>.yaml
   ```

   Example: `tom_master_build_deployment-kubernetes_environment-prod.yaml`

4. **Default File:** When no overrides are specified, only `tom_master_<action>.yaml` is generated with the action's default modes from `action-mode-configuration`.

### 3.5 Template Files (.tomplate)

Template files enable dynamic file generation with mode blocks and placeholders.

#### 3.5.1 Naming Patterns (Both Supported)

| Pattern | Example | Generates |
| ------- | ------- | --------- |
| `<filename>.<ext>.tomplate` | `pubspec.yaml.tomplate` | `pubspec.yaml` |
| `<filename>.tomplate.<ext>` | `pubspec.tomplate.yaml` | `pubspec.yaml` |

#### 3.5.2 Processing Flows

**Generation Timing:**

Files are generated when Tom processes commands or when explicitly triggered with `tom :analyze`:

| Flow | Trigger | What Happens |
| ---- | ------- | ------------ |
| Initial Generation | `tom :analyze` | All `tom_master*.yaml` files are created |
| Pre-Action Processing | Before each action | `tom_master_<action>.yaml` re-processed with current context |

**Multi-Action Commands:**

When a command specifies multiple actions (e.g., `tom :build :publish`):

1. Before `:build` runs: `tom_master_build.yaml` is processed with placeholder resolution for build context
2. Before `:publish` runs: `tom_master_publish.yaml` is processed with placeholder resolution for publish context

Each action gets its own correctly-contextualized master file processing.

**In-Memory Processing:**

Tomplate processing may also occur as an **in-memory operation** for generating `tom_master*.yaml` content. In this case:

- The tomplate is processed but the target file is NOT written to disk
- The result is used only for constructing the project section in `tom_master*.yaml`
- This applies to metadata file tomplates (e.g., `pubspec.yaml.tomplate` for Dart projects)
- **Important:** `tom_project.yaml` files are considered to contain tomplate syntax implicitly (without requiring the `.tomplate` extension). They are processed during `tom_master*.yaml` generation only, not during action execution.

**Target File Generation:**

Target files (the actual output files like `pubspec.yaml`) are generated **every time an action is executed** on a project:

1. Load the tomplate file
2. Apply mode block processing with current action context
3. Resolve placeholders
4. Write the target file to disk
5. Execute the action commands

**Important:** Edit `.tomplate` files, not generated files. Generated files are overwritten before each action.

---

## 4. Mode System

### 4.1 Mode Types

**Note:** Mode types are **user-defined** in the `workspace-modes:` block of `tom_workspace.yaml`. There is no fixed list of mode types. The following are common examples:

| Type | Purpose | Example Values |
| ---- | ------- | -------------- |
| `environment` | Deployment environment | local, int, prod |
| `execution` | How the app runs | local, docker, cloud |
| `cloud-provider` | Cloud platform | aws, gcp, azure |
| `deployment` | Deployment strategy | none, docker-compose, kubernetes |
| `publishing` | Release stage | development, release |

**Defining Mode Types:**

```yaml
workspace-modes:
  mode-types: [environment, execution, cloud-provider, deployment, publishing]
```

You can define any mode types appropriate for your workflow. Each mode type declared here must have corresponding `<mode-type>-modes` and `<mode-type>-mode-definitions` sections.

### 4.2 Mode Block Syntax

Mode blocks enable conditional content in `tom_project.yaml` and `.tomplate` files.

#### 4.2.1 Variant 1: Global Mode Matching

Match against active mode list:

```yaml
@@@mode development
build_runner:
  path: ../build/build_runner
@@@mode production
build_runner: ^2.10.4
@@@mode default
build_runner: ^2.10.4
@@@endmode
```

**The `default` Block:** `@@@mode default` means this section is used if none of the other conditions apply. It acts as a fallback when no other mode matches.

#### 4.2.2 Variant 2: Mode Type with Mode List

Use `@@@mode.<type>` to match modes from a specific mode type's mode list:

```yaml
@@@mode.execution relative_build
build_runner:
  path: ../build/build_runner
@@@mode.execution dev_version
build_runner: ^3.0.0-dev.1
@@@mode default
build_runner: ^2.10.4
@@@endmode
```

**Mode Source:** The `@@@mode.<type> <name>` syntax checks against:

1. The `modes:` entries within each mode definition in `workspace-modes.<type>-modes:` section (implied modes)
2. Manually specified modes via command-line parameters

**Key Difference: `@@@mode` vs `@@@mode.<type>`**

| Syntax | Checks Against | Description |
| ------ | -------------- | ----------- |
| `@@@mode <name>` | Global mode list | Checks the combined mode list from all mode-types plus manually specified modes |
| `@@@mode.<type> <name>` | Mode type list | Checks only the `<type>-modes` section plus its `modes:` entries plus manual params |

**Manual Mode Specification:**

Modes can be specified manually on the command line and will be included in the mode list:

```bash
tom -modes=debug,verbose :build
```

These manually specified modes are checked by `@@@mode <name>` (global) and can be used for cross-cutting concerns not tied to a specific mode type.

**Mode Type Override:**

Mode types can be overridden directly using single-dash syntax:

```bash
tom -execution=local -environment=prod :build
```

**Example Comparison:**

```yaml
# Checks global mode list (all modes combined)
@@@mode relative_build
build_runner:
  path: ../build/build_runner
@@@mode dev_version
build_runner: ^3.0.0-dev.1
@@@mode default
build_runner: ^2.10.4
@@@endmode

# Checks only execution mode type list
@@@mode.execution relative_build
build_runner:
  path: ../build/build_runner
@@@mode.execution dev_version
build_runner: ^3.0.0-dev.1
@@@mode default
build_runner: ^2.10.4
@@@endmode
```

#### 4.2.3 Variant 3: Direct Mode Type Matching

Use `@@@<type>: <name>` for exact mode name match:

```yaml
@@@execution: local
working-dir: .
@@@execution: docker
image: my-app:latest
@@@mode default
working-dir: .
@@@endmode
```

#### 4.2.4 Mode Block Formatting Rules

| Format | Valid | Example |
| ------ | ----- | ------- |
| At line start | Yes | `@@@mode development` |
| Indented | Yes | (with leading spaces) |
| With comment prefix | Yes | `# @@@mode development` |

**Escaping:** Prefix with double backslash to prevent mode processing:

```text
\\@@@mode development   →   @@@mode development (literal in output)
```

**Implementation Verification:**

- [ ] All 3 mode block variants supported
- [ ] Comment prefix handling works
- [ ] Escaping with double backslash works
- [ ] Code location: `mode/mode_processor.dart`
- [ ] Tests: `test/mode/mode_processor_test.dart`

### 4.3 Mode Resolution Order

When an action starts, mode settings are resolved through a multi-step process:

#### 4.3.1 Step 1: Calculate Action Mode Configuration

```text
1. Start with action-mode-configuration.default
2. Merge in action-mode-configuration.<action>
3. Merge in action-mode-configuration from project-type settings (if project of that type)
4. Merge in action-mode-configuration from group settings (if project in group)
5. Merge in action-mode-configuration from project-info settings
6. Merge in action-mode-configuration from group/project CLI parameters
```

**Implementation Verification:**

- [ ] All 6 merge steps implemented in correct order
- [ ] Code location: `mode/mode_resolver.dart`
- [ ] Tests: `test/mode/mode_resolver_test.dart`

This produces the mode type selections (e.g., `environment: prod`, `execution: docker`).

#### 4.3.2 Step 2: Resolve Mode Type Definitions

For each mode type, resolve the configuration:

```text
For each mode-type in mode-types:
  1. Get <mode> = the value for this mode-type from Step 1
  2. Start with <mode-type>-mode-definitions.default from tom_workspace.yaml
  3. Merge in <mode-type>-mode-definitions.<mode> from tom_workspace.yaml
  4. Merge in <mode-type>-mode-definitions.<mode> from project-type settings (if exists)
  5. Merge in <mode-type>-mode-definitions.<mode> from group settings (if exists)
  6. Merge in <mode-type>-mode-definitions.<mode> from project-info (if exists)
  7. Merge in values from global CLI parameters (if exist)
  8. Merge in values from group/project CLI parameters (if exist)
```

This produces the global mode settings for processing `tom_project.yaml`.

#### 4.3.3 Step 3: Process tom_project.yaml

**IMPORTANT - Optional File:** The `tom_project.yaml` file is optional. When missing:

- **Auto-detection** provides project type, name, and metadata
- **All workspace actions** are copied directly to the project (ensuring all actions have definitions)
- **Mode definitions** from workspace are used as-is
- **Cross-compilation settings** from workspace are inherited

With resolved mode settings from Step 2:

```text
1. If tom_project.yaml exists:
   a. Apply mode block processing to tom_project.yaml
   b. The result should be valid YAML that can be loaded
   c. Extract cross-compilation, actions, and <mode-type>-mode-definitions
   d. Merge project-level settings for actions, cross-compilation and <mode-type>-mode-definitions
      with global values from step 2 to include them in step 4.
      
2. If tom_project.yaml does not exist:
   a. All workspace actions are copied to the project section as-is
   b. All workspace <mode-type>-mode-definitions are used without modification
   c. Workspace cross-compilation settings are inherited
   d. Only auto-detected information supplements the project configuration
```

**Important Merge Note:** For `actions`, `<mode-type>-mode-definitions`, and `cross-compilation`, merging happens at the **first level within each section** - individual entries are **replaced**, not deep-merged:

| Section | Merge Level | Example |
|---------|-------------|---------|
| `actions` | `actions.<action>` | If project defines `actions.build`, it completely replaces workspace `actions.build`. Other actions (test, deploy, etc.) are inherited from workspace. |
| `<mode-type>-mode-definitions` | `<mode-type>-mode-definitions.<mode>` | If project defines `deployment-mode-definitions.aws`, it completely replaces workspace `deployment-mode-definitions.aws`. Other modes (none, kubernetes, etc.) are inherited. |
| `cross-compilation` | `cross-compilation.build-on.<target>` | If project defines `cross-compilation.build-on.darwin-arm64`, it replaces that target's config. **Exception:** `all-targets` is always taken from workspace and cannot be overridden at project level. |

#### 4.3.4 Step 4: Process Tomplates and Build Project Section

```text
1. Process tomplates that are metadata files (e.g., pubspec.yaml for Dart)
2. Tomplate processing happens in memory (no files written yet)
3. Calculate the project section for tom_master_<action>.yaml:
   a. Start with auto-detected values (files, parts, modules, etc.)
   b. Merge in values from project type in tom_workspace.yaml
   c. Merge in values from project group in tom_workspace.yaml
   d. Merge in values from project-info in tom_workspace.yaml
   e. Merge in values from tom_project.yaml processing (Step 3)
   f. Merge in global CLI parameters
   g. Merge in group/project CLI parameters
   h. Add the entries for actions and <mode-type>-mode-definitions (override, no merge
      for these entries), cross-compilation should be deep merged
   i. **Compact output:** Omit cross-compilation, <mode-type>-mode-definitions, and
      actions from project section if they are identical to workspace-level definitions
```

#### 4.3.5 Default Mode Generation

For `tom_master.yaml` (the generic master file for IDEs and AI assistants):

- All modes are set to `default`
- The default mode settings can be specified in `tom_workspace.yaml` under:

```yaml
action-mode-configuration:
  default-action-modes:    # Used for tom_master.yaml generation
    environment: local
    execution: local
    cloud-provider: aws
    deployment: none
    publishing: development
```

---

## 5. Processing Pipeline

### 5.1 Three-Phase Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           WORKSPACE BUILD PROCESS                           │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
     ┌────────────────────────────────┼────────────────────────────────┐
     │                                │                                │
     ▼                                ▼                                ▼
┌─────────────────┐          ┌─────────────────┐          ┌─────────────────┐
│    Phase 1      │          │    Phase 2      │          │    Phase 3      │
│   Discovery     │   ──►    │   Generation    │   ──►    │   Execution     │
│                 │          │                 │          │                 │
│ • Scan files    │          │ • Process       │          │ • Load master   │
│ • Detect types  │          │   tom_project   │          │ • Resolve $ENV  │
│ • Find projects │          │ • Process       │          │   and $D4{...}  │
│                 │          │   tomplates     │          │ • Generate      │
│                 │          │ • Resolve $VAL  │          │   target files  │
│                 │          │ • Write master  │          │ • Run commands  │
└─────────────────┘          └─────────────────┘          └─────────────────┘
```

### 5.2 Phase 1: Discovery

#### 5.2.1 File Scanning

| File | Purpose |
| ---- | ------- |
| `tom_workspace.yaml` | Workspace-level configuration |
| Project folders | Directories with manifest files |
| `tom_project.yaml` | Project-specific overrides |
| `.tomplate` files | Template files |

#### 5.2.2 Project Detection

Projects are identified by manifest files. See **Section 7.1** for complete detection rules.

**Detection Summary:** A folder is identified as a project when it contains a recognized manifest file (`pubspec.yaml`, `package.json`, `pyproject.toml`, etc.).

#### 5.2.3 Configuration Merge Sequence

The merge sequence follows the mode resolution order from Section 4.3:

```text
1. Auto-detect        ──►  Values from project files (type, features, structure)
       │
       ▼
2. Project-type       ──►  From project-types: section in tom_workspace.yaml
       │
       ▼
3. Group overrides    ──►  From group definition in tom_workspace.yaml
       │
       ▼
4. Workspace defaults ──►  project-info: from tom_workspace.yaml
       │
       ▼
5. Project overrides  ──►  tom_project.yaml (highest file-based priority)
       │
       ▼
6. Global CLI params  ──►  Command-line global parameters
       │
       ▼
7. Group/Project params ─►  Command-line group/project parameters (highest priority)
```

**Note:** Project-level configuration (step 5) takes precedence over group-level (step 3) and project-type (step 2). Global CLI parameters apply to all projects, while group/project parameters apply to specific targets.

### 5.3 Phase 2: Generation

#### 5.3.1 Generation Flow

The generation flow follows the mode resolution order defined in **Section 4.3**:

```text
For each action in action-mode-configuration:
       │
       ▼
┌─────────────────┐
│ 1. Calculate    │ ──►  Mode settings per Section 4.3.1
│    action modes │
└─────────────────┘
       │
       ▼
┌─────────────────┐
│ 2. Resolve mode │ ──►  Type definitions per Section 4.3.2
│    definitions  │
└─────────────────┘
       │
       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. For each project:                                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│ a. Process tom_project.yaml (if exists) per Section 4.3.3                   │
│    - If missing: copy all workspace actions to project                      │
│ b. Process tomplates per Section 4.3.4                                      │
│ c. Apply merge sequence per Section 5.2.3                                   │
└─────────────────────────────────────────────────────────────────────────────┘
       │
       ▼
┌─────────────────┐
│ 4. Assemble     │ ──►  Combine all projects into master file
└─────────────────┘
       │
       ▼
┌─────────────────┐
│ 5. Resolve $VAL │ ──►  Replace value reference placeholders
└─────────────────┘
       │
       ▼
┌─────────────────┐
│ 6. Write master │ ──►  tom_master_<action>.yaml
└─────────────────┘
```

### 5.4 Phase 3: Execution

#### 5.4.1 Execution Flow

```text
tom :projects tom_build :build
       │
       ▼
┌─────────────────────────────────────────┐
│ 1. Load tom_master_build.yaml           │
│ 2. Find project: tom_build              │
│ 3. Resolve $ENV{...} placeholders       │
│ 4. Resolve $D4{...} expressions         │
│ 5. Convert .tomplate → target files     │
│ 6. Get action commands from project     │
│ 7. Execute each command                 │
└─────────────────────────────────────────┘
```

**Action Definition:** During Phase 2 (Generation), action definitions are fully merged and written to each project's section in `tom_master_<action>.yaml`. During execution, simply retrieve the action definition from the project's configuration in the master file—no additional merging is required.

**See Phase 2 Generation (Section 5.3.1)** for the action definition merge sequence that occurs during master file generation.

#### 5.4.2 Command Types (Execution Phase)

Commands are executed during the **Execution phase** after all placeholders have been resolved:

| Type | Syntax | Example |
| ---- | ------ | ------- |
| Shell command | String | `dart analyze lib` |
| Tom CLI | `tom: <args>` | `tom: build my_project` |
| VS Code Bridge | `VSCode: <script or code>` | `VSCode: scripts/deploy.dart` |
| D4rt Local | `D4: <script or code>` | `D4: scripts/build.dart` |
| Reflection call | `Class.method()` | `BuildTool.generate()` |

**Note:** D4rt placeholders (`$D4{}`, `$D4S{}`, `$D4M{}`) are resolved during the **Runtime phase** (see Section 5.5.1), not at execution time. Use `D4:` or `VSCode:` command syntax for explicit execution.

**D4rt Local Command Examples:**

```yaml
commands:
  - D4: scripts/deploy.dart          # Execute script file
  - D4: "buildProject(options)"      # Execute inline code
  - D4:9743: scripts/build.dart      # Custom port (reserved for future)
```

**VS Code Bridge Command Examples:**

```yaml
commands:
  - VSCode: scripts/deploy.dart
  - VSCode: "print('Hello from VS Code')"
  - VSCode:9743: scripts/build.dart  # Custom port
```

**Multiline D4rt Script Example (Runtime Placeholder):**

```yaml
custom-script: |
  $D4S
  import 'package:tom_build/tom.dart';
  
  void main() {
    final count = tom.projectInfo.values
        .where((p) => p.publishable == true)
        .length;
    print('Publishable projects: $count');
  }
```

**Multiline D4rt Method Example (Runtime Placeholder, returns value):**

```yaml
publishable-count: |
  $D4M
  var count = 0;
  for (final info in tom.projectInfo.values) {
    if (info.publishable == true) count++;
  }
  return count;
```

**Script File Path Resolution:**

- **Without path:** `$D4S{deploy.dart}` → resolves to `tom_scripts/lib/deploy.dart` (hard-coded default)
- **With path:** `$D4S{utils/deploy.dart}` → resolves to `tom_scripts/utils/deploy.dart` (relative to `tom_scripts/`)

**Import Resolution:** Once a script file is located, its execution uses the file's directory as the base for resolving imports specified inside the file.

**Import Resolution:** Once a script file is located, its execution uses the file's directory as the base for resolving imports specified inside the file.

### 5.5 Placeholder Processing

The Tom CLI uses two placeholder syntaxes: bracket syntax for generation-time resolution and `$PREFIX{...}` syntax for runtime-only resolution.

#### 5.5.1 Processing Stages

| Stage | When | What Happens |
| ----- | ---- | ------------ |
| Generation | Writing tom_master_*.yaml | `[[VAR]]`, `[{path}]` placeholders resolved |
| Runtime | After loading, before commands | `$VAL{...}`, `$ENV{...}`, `$D4{...}`, `$GEN{...}`, `[[...]]`, `[{...}]` placeholders resolved |
| Execution | Commands run one by one | `tom:`, `VSCode:`, `D4:`, shell, reflection commands executed |

#### 5.5.2 Placeholder Types

**Generation-Time Placeholders** (resolved during tom_master*.yaml construction AND at runtime):

| Type | Syntax | Description | Default Support |
| ---- | ------ | ----------- | --------------- |
| Environment | `[[VAR:-default]]` | Env vars from system | Yes |
| Data Path | `[{path.to.value:-default}]` | Config value lookup | Yes |

**Runtime-Only Placeholders** (resolved once before each action, NOT at generation time):

| Type | Syntax | Description | Default Support |
| ---- | ------ | ----------- | --------------- |
| Value Reference | `$VAL{key.path:-default}` | Config values | Yes |
| Environment | `$ENV{NAME:-default}` | Env vars | Yes |
| D4rt Expression | `$D4{expression}` | D4rt eval (single-line) | No |
| D4rt Script (inline) | `$D4S{file.dart}` | Script file reference | No |
| D4rt Script (multiline) | YAML block with `$D4S` prefix | Multiline script | No |
| D4rt Method (multiline) | YAML block with `$D4M` prefix | Multiline method returning value | No |
| Generator | `$GEN{path.*.field;sep}` | Generate lists from data | Yes |

**Syntax Design Rationale:**

- `[[...]]` and `[{...}]` are resolved at generation time so values are baked into tom_master*.yaml
- `$PREFIX{...}` are resolved fresh at runtime, allowing dynamic values per action execution
- Standard YAML - no escaping required
- Multiline code uses YAML's native block scalar syntax (`|` or `>`)

**Multiline Placeholder Examples:**

```yaml
# Multiline D4rt script (void, for side effects)
custom-script: |
  $D4S
  import 'package:tom_build/tom.dart';
  
  void main() {
    for (final name in tom.projectInfo.keys) {
      print('Project: $name');
    }
  }

# Multiline D4rt method (returns a value)
publishable-count: |
  $D4M
  var count = 0;
  for (final info in tom.projectInfo.values) {
    if (info.publishable == true) count++;
  }
  return count;

# Next tag - YAML parser knows block ended
next-tag: some-value
```

**Multiline Detection Rules:**

1. If a string value starts with `$D4S\n` → treat remainder as D4rt script
2. If a string value starts with `$D4M\n` → treat remainder as D4rt method
3. Use YAML `|` (literal) to preserve newlines in code
4. YAML indentation naturally defines block boundaries

**Implementation Verification:**

- [ ] All placeholder types supported
- [ ] Default value syntax (`:-default`) implemented
- [ ] Recursive resolution up to 10 levels
- [ ] Escaped placeholders preserved (`\$VAL{...}` → literal)
- [ ] Multiline D4rt script detection and execution
- [ ] Multiline D4rt method detection and execution
- [ ] Code location: `generation/placeholder_resolver.dart`, `template/tomplate_processor.dart`
- [ ] Tests: `test/generation/placeholder_resolver_test.dart`

#### 5.5.3 Generator Placeholders

Generator placeholders produce lists of values from `tom_master*.yaml` data:

**Important:** All placeholders refer to the structure of `tom_master*.yaml`. Generator placeholders can only be resolved **right before files are written to disk**, because during construction the data is not complete and would lead to errors and incomplete lists.

**Basic Syntax:**

```text
$GEN{<path>.*.<field>;<separator>}
```

**Examples:**

```yaml
# Generate comma-separated list of all project names
all_projects: "$GEN{projects.*.name;,}"
# Output: tom_core,tom_build,tom_tools

# Generate dash-separated list of project names
project_list: "$GEN{projects.*.name;-}"
# Output: tom_core-tom_build-tom_tools
```

**Filtered Generators:**

Use attribute matchers to filter which items are included:

```text
$GEN{<path>.[<attr>=<value>,...].<field>;<separator>}
```

**Filter Examples:**

```yaml
# Get all dart_package projects
dart_packages: "$GEN{projects.[type=dart_package].name;,}"

# Get projects matching name pattern (regex supported)
tom_projects: "$GEN{projects.[type=dart_package,name=^tom_.*$].name;-}"

# Multiple conditions (all must match)
core_packages: "$GEN{projects.[type=dart_package,publishable=true].name;,}"
```

**Attribute Matching Rules:**

| Syntax | Meaning |
| ------ | ------- |
| `attr=value` | Exact match |
| `attr=^pattern$` | Regex match |
| `attr=value1,attr2=value2` | Multiple conditions (AND logic) |

#### 5.5.4 Recursive Resolution

Placeholders resolve recursively with **maximum 10 levels**. If recursion exceeds 10 levels, an error is raised showing which placeholders remained unresolved after 10 replacement cycles.

#### 5.5.5 Escaping

Prefix with `\` to preserve placeholder syntax:

```yaml
deferred: \$VAL{project.name}    # Becomes literal $VAL{project.name}
literal_env: \$ENV{HOME}         # Becomes literal $ENV{HOME}
```

---

## 6. Command Line Interface

### 6.0 Naming Conventions

The Tom CLI adheres to the following naming conventions for command-line inputs:

- **Arguments**:
  - Do **NOT** start with a dash.
  - Used for positional values like project names, group names, input files, or action names.
  - Examples: `my_project`, `release_group`, `build`

- **Parameters**:
  - Start with a single dash (`-`).
  - Must have a value assigned immediate after an equals sign (`=`).
  - Syntax: `-key=value`
  - Examples: `-name=pipeline_one`, `-input=source.md`

- **Options**:
  - Start with a single dash (`-`) or double dash (`--`).
  - Are boolean flags with **NO** value assigned.
  - Examples: `-verbose`, `--dry-run`, `-force`

### 6.1 CLI Syntax

**Binary:** `tom`

#### 6.1.1 Project-Based Execution

```bash
tom [<global-params>] :projects <p1> [<p1-params>] <p2> ... :<action1> [<a1-params>] :<action2> ...
```

#### 6.1.2 Group-Based Execution

```bash
tom [<global-params>] :groups <g1> [<g1-params>] <g2> ... :<action1> [<a1-params>] :<action2> ...
```

#### 6.1.3 Global Execution

When neither `:projects` nor `:groups` is specified, the action runs on **all projects** in build order:

```bash
tom [<global-params>] :<action1> [<a1-params>] :<action2> ...
```

**Examples:**

```bash
tom :build                  # Build all projects in workspace
tom :test                   # Test all projects
tom --verbose :build :test  # Build and test all with verbose output
```

#### 6.1.4 Command Line Arguments Structure

| Component | Description |
| --------- | ----------- |
| `<global-params>` | Applied globally (before `:projects`/`:groups`) |
| `:projects`/`:groups` | Keyword indicating list follows |
| `<pN>`/`<gN>` | Project or group name |
| `<pN-params>` | Parameters for that project/group |
| `:<actionN>` | Action name (colon prefix) |
| `<aN-params>` | Parameters for that action |

**Constraint:** Project parameters and group parameters CANNOT be used together. Use `:projects` OR `:groups`, not both.

#### 6.1.5 CLI Startup Behavior

When the Tom CLI starts, it performs the following initialization sequence:

**1. Workspace Root Discovery:**

The CLI locates the workspace root by searching for `tom_workspace.yaml`:

1. Check current working directory for `tom_workspace.yaml`
2. If not found, check parent directory
3. Continue checking parent directories up to filesystem root
4. Once found, use that file's directory as workspace root
5. If not found, report error (unless running `:help` or `:version`)

```text
Error: No workspace found
  Searched: [/current/path] and parent directories
  Resolution: Navigate to a Tom workspace directory or create tom_workspace.yaml
```

**2. Global Configuration Loading:**

Once the workspace root is established:

1. Load and parse `tom_workspace.yaml` **once**
2. Cache the configuration globally for the CLI session
3. All subsequent operations use this cached configuration
4. The configuration is never reloaded during a single CLI invocation

This ensures consistent configuration across all actions and avoids redundant file I/O.

**3. Master File Generation:**

Before executing any workspace actions:

1. Run the workspace analyzer (equivalent to `:analyze`)
2. Generate all `tom_master_<action>.yaml` files for actions in `action-mode-configuration`
3. Generate the generic `tom_master.yaml` file
4. This happens **once** per CLI invocation, automatically
5. Internal commands like `:help`, `:version` skip this step

**4. Master File Requirement:**

Actions **cannot execute** without their corresponding master file:

- Action `:build` requires `tom_master_build.yaml`
- Action `:deploy` requires `tom_master_deploy.yaml`
- If a master file is missing after generation, the action is undefined

```text
Error: Master file not found for action [deploy]
  Searched: [.tom_metadata/tom_master_deploy.yaml]
  Fallback: [.tom_metadata/tom_master.yaml]
  Resolution: Run :analyze first to generate master files, 
  or add action [deploy] to action-mode-configuration in tom_workspace.yaml
```

### 6.2 Execution Examples

```bash
# Run action for all projects
tom :build

# Run for specific projects
tom :projects tom_build tom_tools :build

# Run with project parameters
tom :projects tom_uam_server --cloud-provider=gcp :build_prod

# Run multiple actions
tom :projects tom_build tom_tools :build :test

# Run for project groups
tom :groups dart-bridge :build
tom :groups uam --cloud-provider=aws :deploy_prod
```

### 6.3 Built-in Commands vs Workspace Actions

The colon (`:`) prefix is **required** for all Tom commands and actions:

```bash
tom :build      # Workspace action (from action-mode-configuration)
tom :analyze    # Internal command: workspace analyzer
tom :help       # Internal command: show help
```

**The `!` Prefix:**

The exclamation mark (`!`) is only needed when a workspace action has the same name as a built-in command:

```bash
# If there is an action "build" configured AND a built-in "build" command:
tom :build      # Runs the workspace action from action-mode-configuration
tom !build      # Runs the built-in command (bypasses workspace action)
```

**Examples:**

```bash
# Normal usage (colon required)
tom :analyze          # Run workspace analyzer
tom :build            # Run build action
tom :test             # Run test action

# Conflict resolution (if action exists with same name as built-in)
tom !analyze          # Force built-in analyzer (if :analyze action exists)
```

### 6.4 Internal Commands

Internal commands (prefixed with `:`) can be chained with actions on the command line.

#### 6.4.1 Command Reference

| Command | Prefix | Description |
| ------- | ------ | ----------- |
| `:analyze` | `wa-` | Run workspace analyzer, generate all `tom_master*.yaml` files |
| `:generate-bridges` | `gb-` | Generate D4rt BridgedClass implementations |
| `:generate-reflection` | `gr-` | Run reflection generator |
| `:md2pdf` | `mp-` | Convert markdown to PDF |
| `:md2latex` | `ml-` | Convert markdown to LaTeX |
| `:version-bump` | `vb-` | Increment versions for changed packages |
| `:prepper` | `wp-` | Run mode processing (tomplate preparation) manually |
| `:reset-action-counter` | — | Reset the global action counter |

**Implementation Status:**

| Command | Status |
| ------- | ------ |
| `:analyze` | Existing implementation needs adaptation for updated structure |
| `:generate-bridges` | New, needs implementation from scratch |
| `:generate-reflection` | Complete, needs adaptation for argument passing and project/group filtering |
| `:md2pdf` | Complete, needs adaptation for argument passing and project/group filtering |
| `:md2latex` | Complete, needs adaptation for argument passing and project/group filtering |
| `:version-bump` | New, needs implementation from scratch |
| `:prepper` | Existing implementation needs adaptation for mode-processing options |
| `:reset-action-counter` | New, needs implementation from scratch |

**Implementation Location:** These tools are implemented in `tom_build_tools` and `tom_reflection_generator` projects.

**Linting:** Configuration file linting is provided via a VS Code extension, not a CLI command. See [workspace_metadata_linting.md](workspace_metadata_linting.md) for extension development details.

**Meta-Commands:**

| Command | Description |
| ------- | ----------- |
| `:projects` | Limit scope to listed projects |
| `:groups` | Limit scope to listed groups |
| `:pipeline` | Run a named pipeline |

#### 6.4.2 :version-bump

Checks all publishable packages for changes and manages version increments.

**Purpose:** Update pub.dev with current development state to allow dependent projects to use the updated code in the packages they depend on.

**Behavior:**

1. At workspace action start, check all publishable packages for changes using git
2. Print visible warning listing projects that need version upgrades and republishing
3. When `:version-bump` is invoked:
   - Increment versions for changed packages
   - Commit changes to git (entire workspace committed)
   - Publish the updated packages

**Current Support:** Dart packages only (will be extended later)

**Scope:** Workspace-internal package dependencies only. Not for app store publishing or deployment.

**Usage Examples:**

```bash
# Check and bump all changed packages
tom :version-bump

# Bump, build, then publish
tom :version-bump :build :publish

# Bump specific projects only
tom :projects tom_core tom_build :version-bump

# Bump specific groups only
tom :groups dart_packages :version-bump

# Full workflow
tom :projects tom_core :version-bump :build :test :publish
```

**Note:** Even when using `:projects` or `:groups` to limit which packages are bumped, the entire workspace is committed to git.

#### 6.4.3 :reset-action-counter

Resets the global action counter used for versioning.

**State File:** The action counter is stored in `.tom_metadata/workspace_state.yaml`:

```yaml
# .tom_metadata/workspace_state.yaml
action-counter: 42
```

**Behavior:**

1. `:reset-action-counter` sets `action-counter` to `0`
2. Before any action or internal command executes, the counter is incremented
3. When multiple actions are specified (e.g., `tom :build :test`), the counter increments before each action
4. The counter value can be used in version placeholders for dev builds

**Usage:**

```bash
tom :reset-action-counter           # Reset to 0
tom :reset-action-counter :build    # Reset, then build (counter becomes 1)
```

#### 6.4.4 :generate-bridges

Generates D4rt `BridgedClass` implementations from Dart source files, enabling classes to be used in D4rt scripts.

**Purpose:** Automate the creation of BridgedClass registrations following the patterns established in `tom_core_dartscript`.

**Reference Files:**

- `tom_core_dartscript/lib/src/d4rt_helpers.dart` - Helper functions for type-safe argument handling
- `tom_core_dartscript/lib/src/tom_core/tombase/*_bridge.dart` - Sample bridge implementations
- `_copilot_guidelines/d4rt/d4rt_bridgedclass_guidelines.md` - Detailed bridging guidelines

**Parameters:**

| Parameter | Type | Description |
| --------- | ---- | ----------- |
| `-class` | String | Generate for a specific class name |
| `-file` | String/List | Generate for class(es) in specific file(s) |
| `-dir` | String/List | Generate for all classes in directory/directories |
| `-pattern` | String | Filter classes by name pattern (e.g., `Tom*`, `*Config`) |
| `-output` | String | Output file or directory for generated code |
| `-package` | String | Import path for `registerBridgedClass` (default: inferred from project) |
| `-helpers` | String | Import path for helper functions (default: `package:tom_core_dartscript/bridge_helpers.dart`) |
| `-readonly` | bool | Generate only getters, no setters (default: false) |
| `-skip-private` | bool | Skip private members (default: true) |

**Pattern Matching:**

| Pattern | Meaning |
| ------- | ------- |
| `Tom*` | Classes starting with "Tom" (beginsWith) |
| `*Config` | Classes ending with "Config" (endsWith) |
| `*Mode*` | Classes containing "Mode" (contains) |
| `TomProject` | Exact match |

**Generated Structure:**

For each source file, generates a corresponding `*_bridge.dart` file with:

1. Module bridge class with `bridgeClasses()` and `registerBridges()` methods
2. Private `_create*Bridge()` functions for each class
3. Proper use of helper functions from `d4rt_helpers.dart`

**Usage Examples:**

```bash
# Generate for a specific class
tom :generate-bridges -class=TomWorkspace -output=lib/dartscript/workspace_bridge.dart

# Generate for all classes in a file
tom :generate-bridges -file=lib/models/workspace.dart -output=lib/dartscript/

# Generate for all classes in a directory
tom :generate-bridges -dir=lib/models/ -output=lib/dartscript/

# Generate for multiple directories
tom :generate-bridges -dir=lib/config/,lib/models/ -output=lib/dartscript/

# Filter by pattern (only Tom* classes)
tom :generate-bridges -dir=lib/models/ -pattern=Tom* -output=lib/dartscript/

# Generate read-only bridges for config classes
tom :generate-bridges -dir=lib/config/ -pattern=*Config -readonly -output=lib/dartscript/config_bridge.dart

# Use with project context
tom :projects tom_build_tools :generate-bridges -dir=lib/tom_cli/ -pattern=Tom* -output=lib/dartscript/
```

**Behavior:**

1. Parse source Dart file(s) to extract class definitions
2. For each matching class, analyze:
   - Constructors (including named constructors)
   - Public getters and setters
   - Public methods with their parameter signatures
   - Static methods and getters
3. Generate BridgedClass definitions using helper functions
4. Create module bridge class with registration methods
5. Write output file(s)

**Error Handling:**

- Reports classes that cannot be bridged (e.g., generic classes, abstract classes without factories)
- Warns about methods with unsupported parameter types
- Lists skipped members with reasons

#### 6.4.5 Command Prefixes

When using global parameters with multiple commands, use prefixes to target specific commands:

```bash
tom -path=./bin -gr-path=. :analyze :generate-reflection
```

This sets `path` for analyzer to `./bin` and for reflection generator to `.`.

**Alternative (positional):**

```bash
tom :analyze -path=./bin :generate-reflection -path=.
```

### 6.5 Argument Prefixes

| Prefix | Target | Example |
| ------ | ------ | ------- |
| (none) | All tools | `-path=./output` |
| `wa-` | Workspace analyzer (`:analyze`) | `-wa-verbose=true` |
| `gr-` | Reflection generator (`:generate-reflection`) | `-gr-path=.` |
| `mp-` | Markdown to PDF (`:md2pdf`) | `-mp-output=./docs` |
| `ml-` | Markdown to LaTeX (`:md2latex`) | `-ml-template=article` |
| `vb-` | Version bump (`:version-bump`) | `-vb-dry-run=true` |
| `wp-` | Workspace prepper (`:prepper`) | `-wp-dry-run=true` |

**Note:** All arguments use a **single dash** (`-`), not double dash (`--`).

### 6.6 Pipelines

Pipelines execute sequences of actions as a single unit.

#### 6.6.1 Definition

```yaml
pipelines:
  ci:
    global-parameters:
      - --verbose
    projects:
      - name: tom_build
      - name: tom_tools
    actions:
      - action: analyze
      - action: test
      - action: build
```

#### 6.6.2 Execution

```bash
tom :pipeline ci        # Run CI pipeline
tom :pipeline release   # Run release pipeline
```

---

## 7. Auto-Detection

**Implementation Guidelines:**

The implementation should reuse as much existing code from `tom_build` and `tom_core_kernel` as possible:

- **Deep merge**: Use the `little_things` module from `tom_core_kernel`
- **Workspace analysis**: Use `tom_build/lib/src/analyzer/workspace_analyzer.dart`
- **Project structure**: Use existing detection logic in `tom_build`

Modification of existing functionality is acceptable as long as the public API surface remains backwards-compatible. Prefer extending existing classes and functions over creating parallel implementations.

Detection rules should be implemented in separate Dart files for extensibility.

### 7.1 Project Type Detection

**Implementation Note:** Project type detection is currently **hard-coded** in the implementation. The detection logic is isolated in a separate module (`project_detector.dart`) to enable future configuration via `project-types:` rules with custom detection patterns.

| Files Present | Detected Type |
| ------------- | ------------- |
| `pubspec.yaml` + `lib/src/` | `dart_package` |
| `pubspec.yaml` + `bin/` + `lib/` | `dart_cli` |
| `pubspec.yaml` + `sdk: flutter` | `flutter_app` |
| `package.json` + `engines.vscode` | `vscode_extension` |
| `package.json` + `tsconfig.json` + `react` | `typescript_react` |
| `package.json` + `tsconfig.json` | `typescript_node` |
| `package.json` + `bin` field | `node_cli` |
| `pyproject.toml` + `[tool.poetry]` | `python_poetry` |
| `pyproject.toml` + `uv.lock` | `python_uv` |
| `pyproject.toml` + `[project]` | `python_pip` |
| `environment.yml` | `python_conda` |
| `pom.xml` | `java` |
| `build.gradle` | `java` |

### 7.2 Feature Detection (Dart/Flutter)

**Implementation Note:** Feature detection is currently **hard-coded** in the implementation. The detection logic is isolated in a separate module (`feature_detector.dart`) to enable future configuration via feature definitions with custom detection rules.

| Feature | Detection Method |
| ------- | ---------------- |
| `has-reflection` | `.reflection.dart` or `.reflectable.dart` files present |
| `has-build-runner` | `build.yaml` exists and non-empty |
| `has-native-deps` | `ffi` in pubspec or `native/` directory |
| `has-assets` | `assets/` or `fonts/` directory |
| `publishable` | `publish_to: none` NOT in pubspec |
| `has-tests` | `test/` with non-boilerplate tests (file > 400 chars or multiple files) |
| `has-examples` | `example/` with non-boilerplate examples (file > 400 chars or multiple files) |
| `has-docker` | `Dockerfile` or `docker-compose.yml` |
| `has-ci` | `.github/workflows/` or CI config files |

**Non-boilerplate Detection:** A file is considered non-boilerplate if either:

- The file has more than 400 characters, OR
- There is more than one file in the directory

### 7.3 Source Structure Discovery

For Dart projects, see [project_structure.md](../../_copilot_guidelines/project_structure.md) for detailed source structure patterns.

**Implementation Reference:** The current implementation for Dart projects is in `tom_build/lib/src/analyzer/workspace_analyzer.dart`. This logic handles:

- Package module detection (`lib/*.dart`)
- Parts folder discovery (`lib/src/*/`)
- Module structure analysis
- Export file parsing

| Project Type | Package Module | Parts Location |
| ------------ | -------------- | -------------- |
| `dart_package` | `lib/*.dart` | `lib/src/*/` |
| `flutter_app` | `lib/*.dart` | `lib/*/` (excluding `src`) |
| `dart_cli` | — | `bin/`, `lib/` |
| `vscode_extension` | `src/*.ts` | `src/*/` |
| `typescript_node` | `src/*.ts` | `src/*/` |

---

## 8. Object Model

This section defines the Dart class structure for parsing and accessing configuration data. During **Generation** (Phase 2), configuration is processed as `Map<String, dynamic>` for generic merging. During **Execution** (Phase 3), `tom_master*.yaml` is parsed into typed objects.

**Implementation:** See [tom_build/lib/src/tom/file_object_model/file_object_model.dart](../../tom_build/lib/src/tom/file_object_model/file_object_model.dart)

### 8.1 Design Principles

1. **Type Safety:** Properties are strongly typed for Dart code
2. **Nullable Fields:** Optional fields are nullable
3. **Factory Constructors:** Classes provide `fromYaml(Map<String, dynamic>)` factory constructors
4. **Serialization:** Classes provide `toYaml()` methods for round-trip serialization
5. **Custom Tags:** Unrecognized YAML keys are preserved in `customTags` maps

### 8.2 Core Types

#### TomWorkspace

Base type for workspace configuration (used in `tom_workspace.yaml`):

```dart
class TomWorkspace {
  final String? name;
  final String? binaries;                              // Binary output folder path
  final List<String>? operatingSystems;                // [macos, linux, windows]
  final List<String>? mobilePlatforms;                 // [android, ios]
  final List<String>? imports;                         // YAML files to merge
  final WorkspaceModes? workspaceModes;
  final CrossCompilation? crossCompilation;
  final Map<String, GroupDef> groups;
  final Map<String, ProjectTypeDef> projectTypes;      // Project type definitions
  final Map<String, ActionDef> actions;                // Action definitions
  final Map<String, ModeDefinitions> modeDefinitions;  // Collected from *-mode-definitions
  final Map<String, Pipeline> pipelines;               // Pipeline definitions
  final Map<String, ProjectInfo> projectInfo;          // Per-project settings
  final Map<String, String> deps;                      // Dependency versions
  final Map<String, String> depsDev;                   // Dev dependency versions
  final VersionSettings? versionSettings;              // Version management
  final Map<String, dynamic> customTags;               // Passthrough for custom tags
  
  factory TomWorkspace.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

#### TomMaster

The root type for `tom_master*.yaml` files. Extends TomWorkspace with computed fields:

```dart
class TomMaster extends TomWorkspace {
  final String? scanTimestamp;                     // ISO 8601 format
  final Map<String, TomProject> projects;          // All projects with full details
  final List<String> buildOrder;                   // Calculated build dependency order
  final Map<String, List<String>> actionOrder;     // Calculated action execution order per action
  
  factory TomMaster.fromYaml(Map<String, dynamic> yaml);
  @override Map<String, dynamic> toYaml();
}
```

**Note:** `actionOrder` is computed from individual project `actionOrder` entries during generation. It provides the global execution order for each action across all projects.

#### TomProject

```dart
class TomProject {
  final String name;
  final String? type;                         // Project type string (e.g., "dart_package")
  final String? description;
  final String? binaries;                     // Project-specific binaries folder
  
  // Build ordering
  final List<String> buildAfter;
  final Map<String, List<String>> actionOrder;
  
  // Auto-detected features
  final Features? features;
  
  // Actions and modes
  final Map<String, ActionDef> actions;
  final Map<String, ModeDefinitions> modeDefinitions;  // Per mode-type definitions
  final CrossCompilation? crossCompilation;
  
  // Auto-detected source structure (for dart_package projects)
  final PackageModule? packageModule;         // Simple package without parts
  final Map<String, Part> parts;              // Source parts with modules
  
  // Discovered files (auto-detected by analyzer)
  final List<String>? tests;              // Test files/directories
  final List<String>? examples;           // Example files/directories
  final List<String>? docs;               // Documentation files
  final List<String>? copilotGuidelines;  // Copilot guideline files
  final List<String>? binaryFiles;        // Binary source files in bin/
  
  // Package metadata
  final Map<String, dynamic> metadataFiles;   // Parsed metadata (pubspec-yaml, etc.)
  final List<ExecutableDef> executables;      // Executable definitions
  final Map<String, dynamic>? actionModeDefinitions;
  
  // Passthrough
  final Map<String, dynamic> customTags;
  
  factory TomProject.fromYaml(String name, Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

### 8.3 Configuration Types

#### WorkspaceModes

```dart
class WorkspaceModes {
  final List<String> modeTypes;                           // Declared mode types
  final List<SupportedMode> supported;                    // Named mode presets
  final Map<String, ModeTypeConfig> modeTypeConfigs;      // e.g., environment-modes
  final ActionModeConfiguration? actionModeConfiguration;
  
  factory WorkspaceModes.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

class SupportedMode {
  final String name;
  final String? description;
  final List<String> implies;
  
  factory SupportedMode.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

class ModeTypeConfig {
  final String? defaultMode;
  final Map<String, ModeEntry> entries;
  
  factory ModeTypeConfig.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

class ModeEntry {
  final String? description;
  final List<String> modes;                   // Implied modes
  final Map<String, dynamic> properties;      // Additional properties
  
  factory ModeEntry.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

#### ModeDefinitions and ModeDef

```dart
/// Container for mode definitions of a single mode type
class ModeDefinitions {
  final Map<String, ModeDef> definitions;
  
  factory ModeDefinitions.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

/// A single mode definition
class ModeDef {
  final String name;                          // Mode name (e.g., "local", "docker")
  final String? description;
  final Map<String, dynamic> properties;      // All mode-specific properties
  
  factory ModeDef.fromYaml(String name, Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

**Note:** Mode definitions are freely configurable. All properties are stored in the generic `properties` map rather than typed subclasses.

#### ActionDef and ActionConfig

```dart
class ActionDef {
  final String name;                              // Action name (e.g., "build", "test")
  final String? description;
  final List<String>? skipTypes;                  // Project types to skip
  final List<String>? appliesToTypes;             // Project types to include
  final ActionConfig? defaultConfig;              // Default action configuration
  final Map<String, ActionConfig> typeConfigs;    // Per project-type overrides
  
  factory ActionDef.fromYaml(String name, Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

class ActionConfig {
  final List<String>? preCommands;            // Commands to run before main
  final List<String> commands;                // Main commands
  final List<String>? postCommands;           // Commands to run after main
  final Map<String, dynamic> customTags;      // All other properties
  
  factory ActionConfig.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

class ActionModeConfiguration {
  final Map<String, ActionModeEntry> entries;   // Includes 'default'
  
  factory ActionModeConfiguration.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

class ActionModeEntry {
  final String? description;
  final Map<String, String> modes;            // mode-type -> mode-value
  
  factory ActionModeEntry.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

#### GroupDef

```dart
class GroupDef {
  final String name;                              // Group name
  final String? description;
  final List<String> projects;
  final Map<String, dynamic>? projectInfoOverrides;
  
  factory GroupDef.fromYaml(String name, Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

#### ProjectTypeDef

```dart
class ProjectTypeDef {
  final String name;
  final String? description;
  final Map<String, String> metadataFiles;        // key -> filename
  final Map<String, dynamic>? projectInfoOverrides;
  
  factory ProjectTypeDef.fromYaml(String key, Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

### 8.4 Project Structure Types

#### Features

Features is a flexible set of auto-detected or overridden feature flags:

```dart
class Features {
  final Map<String, bool> flags;  // e.g., {'has-reflection': true, 'publishable': false}
  
  bool operator [](String key) => flags[key] ?? false;
  factory Features.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

**Common feature flags:** `has-reflection`, `has-build-runner`, `has-native-deps`, `has-assets`, `publishable`, `has-tests`, `has-examples`, `has-docker`, `has-ci`

#### CrossCompilation

```dart
class CrossCompilation {
  final List<String> allTargets;
  final Map<String, BuildOnTarget> buildOn;
  
  factory CrossCompilation.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

class BuildOnTarget {
  final List<String> targets;
  
  factory BuildOnTarget.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

#### Source Structure

```dart
/// Simple package module (for packages without parts)
class PackageModule {
  final String name;
  final String? libraryFile;              // e.g., lib/package_name.dart
  final List<String>? sourceFolders;      // e.g., ['lib/src']
  
  factory PackageModule.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

/// Part definition (for packages with parts)
class Part {
  final String name;
  final String? libraryFile;              // e.g., lib/src/data/data.dart
  final Map<String, Module> modules;
  
  factory Part.fromYaml(String name, Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

/// Module definition (within a part)
class Module {
  final String name;
  final String? libraryFile;              // e.g., lib/src/data/json_utils.dart
  
  factory Module.fromYaml(String name, Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

/// Executable definition
class ExecutableDef {
  final String source;                    // e.g., bin/my_cli.dart
  final String output;                    // e.g., my_cli
  
  factory ExecutableDef.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

### 8.5 Pipeline Types

```dart
class Pipeline {
  final String name;
  final List<String>? globalParameters;
  final List<PipelineProject> projects;
  final List<PipelineAction> actions;
  
  factory Pipeline.fromYaml(String name, Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

class PipelineProject {
  final String name;
  
  factory PipelineProject.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

class PipelineAction {
  final String action;
  
  factory PipelineAction.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

### 8.6 Additional Types

```dart
/// Project info entry
class ProjectInfo {
  final String name;
  final Map<String, dynamic> settings;
  
  factory ProjectInfo.fromYaml(String name, Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}

/// Version settings
class VersionSettings {
  final String? prereleaseTag;
  final bool? autoIncrement;
  final int? minDevBuild;
  final int? actionCounter;
  
  factory VersionSettings.fromYaml(Map<String, dynamic> yaml);
  Map<String, dynamic> toYaml();
}
```

### 8.7 Helper Functions

The Object Model includes utility functions for YAML processing:

```dart
/// Loads a YAML file and returns it as a clean Map
Map<String, dynamic> loadYamlFile(String path);

/// Converts a Map to YAML string format
String toYamlString(Map<String, dynamic> data, {int indent = 0});
```

### 8.8 Global Constants

```dart
/// Available project types (configurable, not an enum)
/// These are detected by project-types definitions or auto-detection
const List<String> defaultProjectTypes = [
  'dart_package',
  'dart_cli',
  'dart_server',
  'flutter_app',
  'vscode_extension',
  'typescript_node',
  'typescript_react',
  'node_cli',
  'python_poetry',
  'python_uv',
  'python_pip',
  'python_conda',
  'java',
  'unknown',
];
```

**Note:** Project types are strings, not enums, to allow user-defined types via `project-types:` configuration. The naming convention uses snake_case (e.g., `dart_package`, `flutter_app`).

---

## 9. Error Handling

### 9.1 Error Philosophy

Tom CLI follows a **fail-fast** approach with comprehensive error messages. All errors stop execution immediately with clear diagnostics.

All consistency checks are performed **after** configuration files are fully assembled but **before** any commands or actions are executed. If any generated `tom_master*.yaml` file is inconsistent, Tom aborts with clear error messages.

### 9.2 Validation Errors

Error messages follow a standard format with technical notation:

```text
Error: <description>
  File: [<file_path>]
  Line: [<line_number>]  (optional, when applicable)
  Resolution: <how to fix>
```

**Implementation Verification:**

- [ ] All errors use this standard format
- [ ] File path included when applicable
- [ ] Line number included when available
- [ ] Resolution suggestion provided
- [ ] Code location: `execution/output_formatter.dart:printError()`
- [ ] Tests: `test/execution/output_formatter_test.dart`

**Examples:**

```text
Error: Action [build] requires [default:] definition
  File: [~/tom_workspace.yaml]
  Resolution: Add a default: block inside actions.build:

Error: Action [deploy] has no corresponding entry in [actions:]
  File: [~/tom_workspace.yaml]
  Resolution: Add actions.deploy: with at least a default: definition

Error: Missing required block [actions:]
  File: [~/tom_workspace.yaml]
  Resolution: Add an actions: section with action definitions

Error: Invalid YAML syntax
  File: [tom_project.yaml]
  Line: [42]
  Resolution: Fix YAML syntax error: unexpected character ':'

Error: Project [unknown_project] not found
  Resolution: Check project name spelling or add project to workspace

Error: Action [build] uses both skip and applies-to filtering
  File: [~/tom_workspace.yaml]
  Resolution: Use either skip/skip-types OR applies-to/applies-to-types, not both
```

### 9.3 Circular Dependency Handling

When circular dependencies are detected:

1. **Error immediately** with clear message
2. **List the cycle** showing all projects involved
3. **Stop execution** - refuse to process

Example error:

```text
Error: Circular dependency detected
  Cycle: project_a → project_b → project_c → project_a
  Resolution: Remove one dependency to break the cycle
```

### 9.4 Placeholder Resolution Errors

When placeholder recursion exceeds 10 levels:

```text
Error: Placeholder recursion exceeded 10 levels
  File: [tom_uam_server/pubspec.yaml.tomplate]
  Unresolved: ${a}, ${b}
  Resolution: Check for circular placeholder references or missing definitions
```

### 9.5 Tomplate Processing Errors

When tomplate has syntax errors or produces invalid YAML:

1. **Error immediately**
2. **Show file path and line number**
3. **Include error context**

Example error:

```text
Error: Invalid YAML produced by tomplate
  File: [tom_uam_server/pubspec.yaml.tomplate]
  Line: [42]
  Error: Unexpected character ':' at position 15
  Context: "invalid: yaml: content"
```

### 9.6 Scope Conflict Errors

Only `:projects` OR `:groups` can be used per command, not both:

```text
Error: Cannot use both [:projects] and [:groups] in the same command
  Command: tom :groups uam :projects tom_build :build
  Resolution: Use either [:projects] OR [:groups], not both
```

---

## 10. Examples

### 10.1 Complete Workspace Configuration

```yaml
# tom_workspace.yaml

imports:
  - tom_workspace_local.yaml

# Project type definitions (required for all project types in workspace)
project-types:
  dart_package:
    name: Dart Package
    description: A publishable Dart library
    metadata-files:
      pubspec-yaml: pubspec.yaml
      build-yaml: build.yaml
  
  dart_console:
    name: Dart Console App
    description: A Dart command-line application
    metadata-files:
      pubspec-yaml: pubspec.yaml
  
  flutter_app:
    name: Flutter Application
    description: A Flutter mobile/web application
    metadata-files:
      pubspec-yaml: pubspec.yaml
  
  vscode_extension:
    name: VS Code Extension
    description: A Visual Studio Code extension
    metadata-files:
      package-json: package.json
      tsconfig-json: tsconfig.json

workspace-modes:
  mode-types: [environment, execution, cloud-provider, deployment, publishing]
  
  supported:
    - name: development
      description: Development mode
      implies: [relative_build]
    - name: production
      description: Production mode
  
  environment-modes:
    default: local
    local:
      description: Local development
      modes: [development]
    prod:
      description: Production
      modes: [production]
  
  execution-modes:
    default: local
    local:
      description: Run directly
    docker:
      description: Run in container
  
  cloud-provider-modes:
    default: aws
    aws:
      description: Amazon Web Services
    gcp:
      description: Google Cloud Platform
  
  deployment-modes:
    default: none
    none:
      description: No deployment
    docker-compose:
      description: Docker Compose
    kubernetes:
      description: Kubernetes
  
  publishing-modes:
    default: development
    development:
      description: Development builds
    release:
      description: Production releases
  
  action-mode-configuration:
    default:
      environment: local
      execution: local
      cloud-provider: aws
      deployment: none
      publishing: development
    build:
      description: Build for local
      environment: local
      execution: local
    build_prod:
      description: Build for production
      environment: prod
      execution: docker
      publishing: release
    deploy_prod:
      description: Deploy to production
      environment: prod
      execution: cloud
      deployment: kubernetes

binaries: bin/

cross-compilation:
  all-targets: [linux-x64, linux-arm64, darwin-x64, darwin-arm64, win32-x64]
  build-on:
    darwin-arm64:
      targets: [darwin-arm64]
    linux-x64:
      targets: [linux-x64, linux-arm64]

actions:
  build:
    default:
      pre-commands:
        - echo "Starting build..."
      commands:
        - dart analyze lib test
        - dart test
      post-commands:
        - echo "Build complete"
    dart_cli:
      commands:
        - dart analyze lib bin test
        - dart test
        - dart compile exe bin/main.dart
  deploy:
    skip-types: [dart_package]
    default:
      pre-commands:
        - echo "Preparing deployment..."
      commands:
        - docker-compose up -d
      post-commands:
        - echo "Deployment complete"

groups:
  uam:
    description: UAM application suite
    projects: [tom_uam_client, tom_uam_server, tom_uam_shared]
    project-info-overrides:
      cloud-provider: aws
      deployment: kubernetes

# Mode type definitions (outside workspace-modes)
environment-mode-definitions:
  default:
    description: Default environment
  local:
    description: Local development
    working-dir: .
    variables:
      DEBUG: "true"
  prod:
    description: Production environment
    variables:
      DEBUG: "false"

execution-mode-definitions:
  default:
    working-dir: .
  local:
    description: Run directly on host
  docker:
    description: Run in container
    image: dart:stable
  cloud:
    description: Run on cloud platform
    provider: aws

deployment-mode-definitions:
  default:
    strategy: rolling
  none:
    description: No deployment
  docker-compose:
    description: Docker Compose deployment
    compose-file: docker-compose.yml
  kubernetes:
    description: Kubernetes deployment
    namespace: default

cloud-provider-mode-definitions:
  default:
    region: us-east-1
  aws:
    name: Amazon Web Services
    region: "[[AWS_REGION]]"
    account-id: "[[AWS_ACCOUNT_ID]]"
  gcp:
    name: Google Cloud Platform
    project-id: "[[GCP_PROJECT_ID]]"

publishing-mode-definitions:
  default:
    changelog: CHANGELOG.md
  development:
    description: Development builds
    publish: false
  release:
    description: Production release
    publish: true
    tag-prefix: v

project-info:
  tom_build:
    cross-compilation:
      all-targets: [darwin-x64, darwin-arm64, linux-x64, win32-x64]
  tom_uam_server:
    action-mode-definitions:
      build:
        execution: docker
      deploy:
        deployment: kubernetes
        cloud-provider: aws

deps:
  sdk: ^3.10.4
  path: ^1.9.0
  yaml: ^3.1.2

deps-dev:
  test: ^1.28.0
  lints: ^6.0.0

version-settings:
  prerelease-tag: dev
  auto-increment: true
  min-dev-build: 1
  action-counter: 0             # Global counter, increments with each action

# Action Counter: The action-counter increments on every action execution,
# regardless of action type. When multiple actions are triggered in a single
# command line (e.g., tom :build :test), the counter increments before each
# action. Use :reset-action-counter to reset. The counter can be used for
# generating dev-version-numbers.

pipelines:
  ci:
    global-parameters: [--verbose]
    projects:
      - name: tom_build
      - name: tom_tools
    actions:
      - action: analyze
      - action: test
      - action: build
```

### 10.2 Generated tom_master.yaml

The `tom_master.yaml` file is generated by Tom during the Discovery phase. It combines workspace configuration with computed project data:

```yaml
# .tom_metadata/tom_master.yaml
# GENERATED FILE - DO NOT EDIT DIRECTLY
# Regenerate with: tom :generate-master

scan-timestamp: "2026-01-13T17:00:00Z"

# === WORKSPACE CONFIGURATION (from tom_workspace.yaml) ===

name: tom

binaries: bin/

operating-systems: [macos, linux, windows]
mobile-platforms: [android, ios]

# Project type definitions
project-types:
  dart_package:
    name: Dart Package
    description: A publishable Dart library
    metadata-files:
      pubspec-yaml: pubspec.yaml
      build-yaml: build.yaml
  dart_console:
    name: Dart Console App
    description: A Dart command-line application
    metadata-files:
      pubspec-yaml: pubspec.yaml
  flutter_app:
    name: Flutter Application
    description: A Flutter mobile/web application
    metadata-files:
      pubspec-yaml: pubspec.yaml
  vscode_extension:
    name: VS Code Extension
    description: A Visual Studio Code extension
    metadata-files:
      package-json: package.json

# Workspace modes configuration (same structure as tom_workspace.yaml)
workspace-modes:
  mode-types: [environment, execution, cloud-provider, deployment, publishing]
  
  supported:
    - name: development
      description: Development mode
      implies: [relative_build]
    - name: production
      description: Production mode
  
  environment-modes:
    default: local
    local:
      description: Local development
      modes: [development]
    prod:
      description: Production
      modes: [production]
  
  execution-modes:
    default: local
    local:
      description: Run directly
    docker:
      description: Run in container
  
  cloud-provider-modes:
    default: aws
    aws:
      description: Amazon Web Services
    gcp:
      description: Google Cloud Platform
  
  deployment-modes:
    default: none
    none:
      description: No deployment
    docker-compose:
      description: Docker Compose
    kubernetes:
      description: Kubernetes
  
  publishing-modes:
    default: development
    development:
      description: Development builds
    release:
      description: Production releases
  
  action-mode-configuration:
    default:
      environment: local
      execution: local
      cloud-provider: aws
      deployment: none
      publishing: development
    build:
      description: Build for local
      environment: local
      execution: local
    build_prod:
      description: Build for production
      environment: prod
      execution: docker
      publishing: release
    deploy_prod:
      description: Deploy to production
      environment: prod
      execution: cloud
      deployment: kubernetes

# Cross-compilation settings
cross-compilation:
  all-targets: [linux-x64, linux-arm64, darwin-x64, darwin-arm64, win32-x64]
  build-on:
    darwin-arm64:
      targets: [darwin-arm64]
    linux-x64:
      targets: [linux-x64, linux-arm64]

# Action definitions (with pre/post commands)
actions:
  build:
    name: build
    description: Build the project
    default:
      pre-commands:
        - echo "Starting build..."
      commands:
        - dart analyze lib test
        - dart test
      post-commands:
        - echo "Build complete"
    dart_console:
      commands:
        - dart analyze lib bin test
        - dart test
        - dart compile exe bin/main.dart
  deploy:
    name: deploy
    description: Deploy the project
    skip-types: [dart_package]
    default:
      pre-commands:
        - echo "Preparing deployment..."
      commands:
        - docker-compose up -d
      post-commands:
        - echo "Deployment complete"

# Group definitions
groups:
  uam:
    name: uam
    description: UAM application suite
    projects: [tom_uam_client, tom_uam_server, tom_uam_shared]
    project-info-overrides:
      cloud-provider: aws
      deployment: kubernetes

# Mode type definitions (same structure as tom_workspace.yaml)
environment-mode-definitions:
  default:
    description: Default environment
  local:
    description: Local development
    working-dir: .
    variables:
      DEBUG: "true"
  prod:
    description: Production environment
    variables:
      DEBUG: "false"

execution-mode-definitions:
  default:
    working-dir: .
  local:
    description: Run directly on host
  docker:
    description: Run in container
    image: dart:stable
  cloud:
    description: Run on cloud platform
    provider: aws

deployment-mode-definitions:
  default:
    strategy: rolling
  none:
    description: No deployment
  docker-compose:
    description: Docker Compose deployment
    compose-file: docker-compose.yml
  kubernetes:
    description: Kubernetes deployment
    namespace: default

cloud-provider-mode-definitions:
  default:
    region: us-east-1
  aws:
    name: Amazon Web Services
    region: "[[AWS_REGION]]"
    account-id: "[[AWS_ACCOUNT_ID]]"
  gcp:
    name: Google Cloud Platform
    project-id: "[[GCP_PROJECT_ID]]"

publishing-mode-definitions:
  default:
    changelog: CHANGELOG.md
  development:
    description: Development builds
    publish: false
  release:
    description: Production release
    publish: true
    tag-prefix: v

# Pipelines
pipelines:
  ci:
    global-parameters: [--verbose]
    projects:
      - name: tom_build
      - name: tom_tools
    actions:
      - action: analyze
      - action: test
      - action: build

# Project info (same structure as tom_workspace.yaml)
project-info:
  tom_build:
    cross-compilation:
      all-targets: [darwin-x64, darwin-arm64, linux-x64, win32-x64]
  tom_uam_server:
    action-mode-definitions:
      build:
        execution: docker
      deploy:
        deployment: kubernetes
        cloud-provider: aws

# Dependencies
deps:
  sdk: ^3.10.4
  path: ^1.9.0
  yaml: ^3.1.2

deps-dev:
  test: ^1.28.0
  lints: ^6.0.0

# Version settings
version-settings:
  prerelease-tag: dev
  auto-increment: true
  min-dev-build: 1
  action-counter: 42

# Custom tags (integrated at top level, not in a custom-tags block)
my-custom-setting: value
another-setting:
  nested: true

# === COMPUTED FIELDS (generated by Tom) ===

# Build order (calculated from build-after dependencies)
build-order:
  - tom_core_kernel
  - tom_build
  - tom_ai
  - tom_uam_shared
  - tom_uam_client
  - tom_uam_server

# Action order (calculated from action-order dependencies)
action-order:
  build:
    - tom_core_kernel
    - tom_build
    - tom_ai
    - tom_uam_shared
    - tom_uam_client
    - tom_uam_server
  deploy:
    - tom_uam_shared
    - tom_uam_server

# === PROJECTS (with full computed details) ===

projects:
  tom_core_kernel:
    name: tom_core_kernel
    type: dart_package
    description: Core kernel library
    
    # Build ordering
    build-after: []
    action-order: {}
    
    # Features (auto-detected)
    features:
      publishable: true
      has-tests: true
      has-examples: true
      has-build-runner: false
    
    # Mode definitions (final state after processing all levels)
    environment-mode-definitions:
      local:
        description: Local development
        working-dir: .
        variables:
          DEBUG: "true"
      prod:
        description: Production environment
        variables:
          DEBUG: "false"
    
    execution-mode-definitions:
      local:
        description: Run directly on host
      docker:
        description: Run in container
        image: dart:stable
    
    # Actions (merged with workspace defaults)
    actions:
      build:
        name: build
        default:
          pre-commands:
            - echo "Starting build..."
          commands:
            - dart analyze lib test
            - dart test
          post-commands:
            - echo "Build complete"
    
    # Auto-detected source structure
    package-module:
      name: tom_core_kernel
      library-file: lib/tom_core_kernel.dart
      source-folders: [lib/src]
    
    parts:
      core:
        name: core
        library-file: lib/src/core/core.dart
        modules:
          base:
            name: base
            library-file: lib/src/core/base/base.dart
    
    # Discovered files
    tests: [test/]
    examples: [example/]
    docs: [doc/]
    copilot-guidelines: []
    binaries: []
    
    # Metadata files (as direct tags, not inside metadata-files block)
    pubspec-yaml:
      name: tom_core_kernel
      version: 1.0.0
      description: Core kernel library
      environment:
        sdk: ^3.10.4
      dependencies:
        path: ^1.9.0
      dev_dependencies:
        test: ^1.28.0
    
    # Executables
    executables: []

  tom_uam_server:
    name: tom_uam_server
    type: dart_console
    description: UAM Server application
    
    # Build ordering
    build-after:
      - tom_uam_shared
      - tom_core_kernel
    action-order:
      deploy-after: [tom_uam_shared]
    
    # Features
    features:
      publishable: false
      has-tests: true
      has-examples: false
      has-docker: true
    
    # Mode definitions (final state - workspace merged with project overrides)
    environment-mode-definitions:
      local:
        description: Local development
        working-dir: .
        variables:
          DEBUG: "true"
      prod:
        description: Production environment
        variables:
          DEBUG: "false"
    
    execution-mode-definitions:
      local:
        description: Run directly on host
      docker:
        description: Docker container for server
        image: tom-uam-server
        dockerfile: Dockerfile
        compose-file: docker-compose.yml
    
    deployment-mode-definitions:
      kubernetes:
        dockerfile: Dockerfile
        target-platforms: [linux/amd64, linux/arm64]
    
    # Cross-compilation (project override)
    cross-compilation:
      all-targets: [linux-x64, linux-arm64]
      build-on:
        linux-x64:
          targets: [linux-x64, linux-arm64]
    
    # Actions (merged with pre/post commands)
    actions:
      build:
        name: build
        default:
          pre-commands:
            - echo "Building server..."
          commands:
            - dart analyze lib bin test
            - dart test
            - dart compile exe bin/server.dart -o bin/server
          post-commands:
            - echo "Server build complete"
      deploy:
        name: deploy
        default:
          pre-commands:
            - echo "Preparing server deployment..."
          commands:
            - docker-compose up -d
          post-commands:
            - echo "Server deployed"
    
    # Source structure
    package-module:
      name: tom_uam_server
      library-file: lib/tom_uam_server.dart
      source-folders: [lib/src]
    
    parts: {}
    
    # Discovered files
    tests: [test/]
    examples: []
    docs: []
    copilot-guidelines: []
    binaries: [bin/server.dart]
    
    # Metadata files (as direct tags)
    pubspec-yaml:
      name: tom_uam_server
      version: 1.0.0
      description: UAM Server application
    
    # Executables
    executables:
      - source: bin/server.dart
        output: server
    
    # Custom tags (integrated at project level)
    server-config:
      port: 8080
      max-connections: 100
```

### 10.3 Complete Project Configuration

```yaml
# tom_uam_server/tom_project.yaml

# Build dependencies (same structure as workspace)
build-after:
  - tom_uam_shared
  - tom_core_kernel

action-order:
  deploy-after: [tom_uam_shared]

# Features (override auto-detection)
features:
  publishable: false
  has-docker: true

# Cross-compilation (override workspace settings)
cross-compilation:
  all-targets: [linux-x64, linux-arm64]
  build-on:
    linux-x64:
      targets: [linux-x64, linux-arm64]

# Binary output folder
binaries: bin/

# Executables to compile (replaces compilation-targets)
executables:
  - source: bin/server.dart
    output: server

# Action-specific mode overrides
action-mode-definitions:
  build:
    environment: local
    execution: docker
    deployment: none
    publishing: development
  deploy:
    environment: prod
    execution: cloud
    cloud-provider: aws
    deployment: kubernetes
    publishing: release

# Mode type definition overrides (deep-merge with workspace)
execution-mode-definitions:
  docker:
    image: tom-uam-server
    dockerfile: Dockerfile
    compose-file: docker-compose.yml

deployment-mode-definitions:
  kubernetes:
    dockerfile: Dockerfile
    target-platforms: [linux/amd64, linux/arm64]

# Action overrides (same structure as workspace)
actions:
  build:
    default:
      pre-commands:
        - echo "Building server..."
      commands:
        - dart analyze lib bin test
        - dart test
        - dart compile exe bin/server.dart -o bin/server
      post-commands:
        - echo "Server build complete"
  deploy:
    default:
      pre-commands:
        - echo "Deploying server..."
      commands:
        - docker-compose up -d
      post-commands:
        - echo "Server deployed"

# Metadata file content (auto-inserted from pubspec.yaml)
pubspec-yaml:
  name: tom_uam_server
  version: 1.0.0
  homepage: https://github.com/example/tom_uam_server

# Custom tags (passed through to tom_master*.yaml)
server-config:
  port: 8080
  max-connections: 100
```

### 10.4 Tomplate with Mode Blocks

```yaml
# pubspec.yaml.tomplate

name: ${project.name}
version: ${project.version}

environment:
  sdk: ${deps.sdk}

dependencies:
  path: ${deps.path}
  yaml: ${deps.yaml}
  
@@@mode development
  tom_core:
    path: ../tom_core
@@@mode production
  tom_core: ^1.0.0
@@@mode default
  tom_core: ^1.0.0
@@@endmode

dev_dependencies:
  test: ${deps-dev.test}
  lints: ${deps-dev.lints}
```

### 10.5 Common CLI Workflows

```bash
# Development workflow
tom :build                            # Build all projects
tom :test                             # Run all tests
tom :projects tom_build :build :test  # Build and test specific project

# Production workflow
tom :build_prod                       # Build for production
tom :deploy_prod                      # Deploy to production

# Group operations
tom :groups uam :build                # Build UAM group
tom :groups uam -cloud-provider=gcp :deploy_prod  # Deploy with override

# Pipeline execution
tom :pipeline ci                      # Run CI pipeline
tom :pipeline release                 # Run release pipeline

# Analyzer
tom :analyze                          # Regenerate master files
tom :analyze -include-tests           # Include zom_* test projects
```

---

## 11. D4rt Integration

### 11.1 Overview

D4rt is a Dart interpreter that enables dynamic script execution within Tom CLI. It provides:

- **Expression evaluation** in placeholders (`{{expression}}`)
- **Method execution** for complex logic (`{(){...}}`)
- **Script file execution** for reusable automation

### 11.2 Configuration

D4rt integration is configured in `tom_workspace.yaml`:

```yaml
d4rt:
  # Whether D4rt scripting is enabled
  enabled: true

  # Import path for bridged classes (automatically imported in scripts)
  import-path: package:tom_build/tom.dart

  # Script search paths (relative to workspace root)
  script-paths:
    - tom_scripts/lib/
    - _scripts/
```

### 11.3 Global Context Object

When D4rt scripts execute, they have access to a global `tom` object that provides workspace context:

#### 11.3.1 TomContext Properties

| Property | Type | Description |
| -------- | ---- | ----------- |
| `tom.workspace` | `TomWorkspace` | Parsed tom_workspace.yaml content |
| `tom.workspaceContext` | `WorkspaceContext` | Runtime workspace context |
| `tom.project` | `TomProject?` | Current project (if in project context) |
| `tom.projectInfo` | `Map<String, ProjectInfo>` | All project configurations |
| `tom.groups` | `Map<String, GroupDef>` | Group definitions |
| `tom.actions` | `Map<String, ActionDef>` | Action definitions |
| `tom.deps` | `Map<String, String>` | Dependency version constraints |
| `tom.depsDev` | `Map<String, String>` | Dev dependency versions |
| `tom.workspaceModes` | `WorkspaceModes?` | Mode system configuration |
| `tom.env` | `Map<String, String>` | Environment variables |
| `tom.cwd` | `String` | Current working directory |

#### 11.3.2 TomContext Methods

| Method | Return Type | Description |
| ------ | ----------- | ----------- |
| `tom.getProjectInfo(name)` | `ProjectInfo?` | Get project by name |
| `tom.getGroup(name)` | `GroupDef?` | Get group by name |
| `tom.getAction(name)` | `ActionDef?` | Get action by name |
| `tom.getDep(name)` | `String?` | Get dependency version |
| `tom.getCustomTag<T>(tag)` | `T?` | Get custom workspace tag |

### 11.4 D4rt Syntax Types

#### 11.4.1 Expressions

Simple expressions evaluated inline. Use for accessing values:

```yaml
# In placeholders
description: "{{tom.workspace.name}} - {{tom.projectInfo.length}} projects"

# In tom_workspace.yaml d4rt section
expressions:
  workspace-name: "{{tom.workspace.name}}"
  all-projects: "{{tom.projectInfo.keys.join(', ')}}"
  analyzer-version: "{{tom.deps['analyzer'] ?? 'not set'}}"
```

#### 11.4.2 Methods

Multi-line code blocks for complex logic:

```yaml
methods:
  publishable-count: |
    {(){
      var count = 0;
      for (final info in tom.projectInfo.values) {
        if (info.publishable == true) count++;
      }
      return count;
    }}
  
  group-projects: |
    {(){
      final group = tom.groups['tom-framework'];
      return group?.projects?.join(', ') ?? 'none';
    }}
```

#### 11.4.3 Script Files

External script files for reusable automation:

```yaml
# Reference scripts from script-paths
scripts:
  custom-build: custom_build.dart
  analyze-workspace: workspace/analyze.dart
```

Script file example (`tom_scripts/lib/custom_build.dart`):

```dart
import 'package:tom_build/tom.dart';

void main() {
  // Access workspace context
  final workspace = tom.workspace;
  print('Building ${workspace.name}');
  
  // Iterate projects
  for (final entry in tom.projectInfo.entries) {
    final name = entry.key;
    final info = entry.value;
    
    if (info.publishable == true) {
      Shell.run('dart pub publish --dry-run', workingDirectory: name);
    }
  }
}
```

### 11.5 D4rt Instance API

Programmatic D4rt usage in Dart code:

```dart
import 'package:tom_build/tom.dart';

// Create instance with workspace context
final d4rt = D4rtInstance.create(
  workspace: workspace,
  workspaceContext: context,
  currentProject: project,  // Optional
);

// Prepare for script execution (loads imports)
await d4rt.prepareForScripts();

// Evaluate expressions
final name = await d4rt.evaluate('tom.workspace.name');
final count = await d4rt.evaluate('tom.projectInfo.length');

// Execute script content
await d4rt.executeScript('''
import 'package:tom_build/tom.dart';

void main() {
  print('Workspace: \${tom.workspace.name}');
}
''');

// Clean up
d4rt.dispose();
```

### 11.6 Bridged Classes

The following classes are bridged for D4rt access:

| Class | Purpose |
| ----- | ------- |
| `TomWorkspace` | Workspace configuration |
| `TomProject` | Project configuration |
| `WorkspaceContext` | Runtime context |
| `ProjectInfo` | Project metadata |
| `GroupDef` | Group definition |
| `ActionDef` | Action definition |
| `Shell` | Shell command execution |
| `FileParser` | File parsing utilities |
| `TomContext` | Global context (via `tom` variable) |

### 11.7 Shell Command Execution

Execute shell commands from D4rt scripts:

```dart
// Run command and get result
final result = Shell.run('dart pub get');
print('Exit code: ${result.exitCode}');
print('Output: ${result.stdout}');

// Run in specific directory
Shell.run('dart test', workingDirectory: 'tom_build');

// Run with environment
Shell.run('npm install', environment: {'NODE_ENV': 'production'});
```

### 11.8 Best Practices

1. **Use expressions for simple values** — keep `{{...}}` placeholders simple
2. **Use methods for logic** — multi-step operations belong in `{(){...}}`
3. **Use scripts for reusable code** — complex automation in separate files
4. **Always handle nulls** — use `??` for default values
5. **Access context via `tom`** — don't create new instances
6. **Call `prepareForScripts()`** — before using `evaluate()` for complex expressions

---

## Appendix A: Best Practices

### Configuration Organization

1. **Use `tom_workspace.yaml`** for workspace-wide defaults and shared settings
2. **Use `tom_project.yaml`** only for project-specific overrides
3. **Keep structure consistent** — use same field names in workspace and project files
4. **Use imports** to organize large configurations into logical files

### File Management

1. **Never edit `tom_master_*.yaml`** — these are regenerated automatically
2. **Edit `.tomplate` files** instead of generated target files
3. **Add generated files to `.gitignore`** when using `.tomplate` files
4. **Run `tom :analyze`** after structural changes to regenerate master files

### Dependency Management

1. **Use `${deps.name}`** for centralized version management
2. **Use `build-after`** to declare workspace project dependencies
3. **Override features** when auto-detection is incorrect

### Security

1. **Use `[[...]]` for secrets** — resolved at runtime, not stored in master files
2. **Use `{{...}}` for dynamic values** — platform detection, computed values

### Mode System

1. **Keep mode types minimal** — only define what you actually need
2. **Use `default` in mode-definitions** — provides sensible fallbacks
3. **Use action-mode-definitions in projects** — for project-specific mode overrides

---

## Appendix B: Testability Requirements

**Note:** This section will be expanded as implementation details are finalized.

**Testing Guidelines:**

- For general unit testing patterns, see [_copilot_guidelines/unit_tests.md](../../_copilot_guidelines/unit_tests.md)
- For test file creation rules, see [_copilot_guidelines/tests.md](../../_copilot_guidelines/tests.md)
- For build tools testing with `zom_` test projects, see [_copilot_guidelines/tests_buildtools.md](../../_copilot_guidelines/tests_buildtools.md)

### Unit Tests Required

| Component | Test Coverage |
| --------- | ------------- |
| YAML Parser | All field types, nested structures, defaults, deep merge, list operations |
| Mode Resolver | All three syntax variants, edge cases, default handling |
| Placeholder Resolver | All types, recursion, escaping, generator placeholders |
| Project Detector | All project types, edge cases |
| Feature Detector | All features, non-boilerplate detection |
| Topological Sort | Linear, branching, circular detection |
| CLI Parser | All syntax patterns, prefix handling, error cases |
| Argument Hierarchy | Global, command-specific, group, project parameters |
| Configuration Merger | Merge order, list operations, scalar replacement |

### Integration Tests Required

| Scenario | Validation |
| -------- | ---------- |
| Full workspace analyze | Master files generated correctly |
| Action execution | Commands run in correct order, pre/post hooks work |
| Mode switching | Different outputs per action |
| Tomplate processing | Target files generated correctly |
| Error propagation | All error types produce correct messages |
| Multi-action commands | Each action gets correct context |
| Generator placeholders | Lists generated correctly with filters |

### Test Workspace Setup

Use `zom_` prefixed test projects for build tools testing. See [_copilot_guidelines/tests_buildtools.md](../../_copilot_guidelines/tests_buildtools.md) for complete guidelines on test project setup and naming conventions.
