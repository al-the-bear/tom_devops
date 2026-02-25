# Tom CLI Usage Documentation

> **Note:** This is supplementary documentation. The authoritative reference is [doc/tom_user_reference.md](../../doc/tom_user_reference.md).

The Tom CLI (`tom`) is the primary tool for managing and building Tom workspaces.

## Command Structure

```bash
tom [<global-params>] [:projects <p1> [<p1-params>] ...] :<action> [<action-params>] ...
tom [<global-params>] [:groups <g1> [<g1-params>] ...] :<action> [<action-params>] ...
tom [<global-params>] :<action> [<action-params>] ...    # All projects
```

## Naming Conventions

| Type | Format | Example |
|------|--------|---------|
| Arguments | No dash, positional | `my_project`, `build` |
| Parameters | Single dash + value | `-name=value` |
| Options | Single/double dash, boolean | `-verbose`, `--dry-run` |

## Global Options

| Option | Description |
|--------|-------------|
| `-verbose`, `--verbose` | Enable verbose output logging |
| `-dry-run`, `--dry-run` | Run in dry-run mode (print what would happen) |
| `-help`, `--help`, `-h` | Show help information |
| `-version`, `--version`, `-v` | Show version information |

## Internal Commands

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

### Prefixes

Use prefixes to target parameters to specific commands:

```bash
tom -gr-path=. :generate-reflection
tom -wa-verbose :analyze
```

### Bypass

Use `!` to force built-in command when action has same name:

```bash
tom !analyze    # Forces built-in :analyze even if 'analyze' action exists
```

## DartScript Commands

Execute Dart code locally (`:dartscript`) or via VS Code (`:vscode`):

```bash
# Local execution via D4rt
tom :dartscript -file=script.dart           # Execute script file
tom :dartscript -code="print('hello')"      # Execute inline code

# VS Code bridge execution
tom :vscode -file=script.dart               # Execute via VS Code
tom :vscode -code="print('hello')"          # Inline code via VS Code
tom :vscode -port=9743 -file=script.dart    # Custom port
```

**Default Command:** If no command is specified, `:dartscript` is used:

```bash
tom script.dart                     # Same as tom :dartscript -file=script.dart
tom "print('hello')"                # Same as tom :dartscript -code="print('hello')"
```

## Workspace Actions

Run any action defined in `tom_workspace.yaml`:

```bash
tom :build                            # Run build action on all projects
tom :projects app_client :build       # Build specific project
tom :groups backend :test             # Test project group
tom :build :test                      # Chain multiple actions
```

## Examples

```bash
# Basic usage
tom :build                              # Build all projects
tom :projects tom_build :build :test    # Build and test specific project
tom :groups dart-libs :build            # Build project group
tom --verbose -environment=prod :deploy # With global params

# DartScript execution
tom script.dart                         # Run script file
tom :vscode script.dart                 # Run via VS Code bridge
```

---

*See [doc/tom_user_reference.md](../../doc/tom_user_reference.md) for complete reference.*
