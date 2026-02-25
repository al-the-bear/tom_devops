# Tom Build Tools

Command-line tools for workspace analysis, code generation, and build automation in the Tom Framework.

## Features

- **TomD4rt** - Integrated D4rt REPL with Tom workspace command support
- **Workspace Analyzer** - Scans the workspace and generates comprehensive metadata about all projects
- **AI Code Analyzer** - AI-powered code analysis tools
- **Mode Switcher** - Template-based code generation with conditional sections

## Getting Started

```bash
# Install dependencies
dart pub get

# Start TomD4rt REPL
dart run bin/tom.dart

# Execute a Tom command directly
dart run bin/tom.dart :analyze
```

## TomD4rt REPL

TomD4rt combines the D4rt interactive Dart interpreter with Tom workspace commands. You can:

- Execute Dart code interactively
- Run Tom workspace commands (`:analyze`, `:build`, `:test`)
- Use VS Code bridge integration
- Load and execute scripts

### Command Syntax

```bash
# Inside the REPL:
tom ~> :analyze         # Run workspace analyzer
tom ~> :build           # Build all projects
tom ~> print("hello")   # Execute Dart code
tom ~> .vscode file.dart # Execute via VS Code bridge
```

### Tom Scripting API

```dart
// In D4rt scripts, use the Tom class:
await Tom.runAction('analyze');
await Tom.build('tom_build_cli');
print(Tom.cwd);        // Current working directory
print(Tom.workspace);  // Workspace configuration
```

## Documentation

| Document                                                 | Description                                                               |
| -------------------------------------------------------- | ------------------------------------------------------------------------- |
| [doc/workspace_analyzer.md](doc/workspace_analyzer.md) | Complete Workspace Analyzer documentation with configuration and features |
| [doc/mode_switcher.md](doc/mode_switcher.md)           | Mode Switcher documentation for template-based code generation            |

## Workspace Analyzer

The Workspace Analyzer scans a workspace directory and generates a comprehensive `index.yaml` file in `.tom_metadata/` with:

- Project types and metadata
- Build dependencies and build order
- Auto-detected features (reflection, build_runner, docker, etc.)
- Build, run, and deploy configuration per project
- Folder listings (docs, tests, examples, _copilot_guidelines)

See [doc/workspace_analyzer.md](doc/workspace_analyzer.md) for full documentation.

## Project Structure

```text
tom_build_tools/
├── bin/                    # CLI entrypoints
│   └── analyze_workspace.dart
├── lib/                    # Library code (delegated to tom_build)
├── doc/                   # Documentation
│   └── workspace_analyzer.md
└── test/                   # Tests
    ├── workspace_analyzer_test.dart
    └── workspace_analyzer_enhanced_test.dart
```
