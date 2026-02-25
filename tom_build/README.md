# Tom Build

Core library for Tom CLI workspace automation, action execution, and D4rt scripting.

## Features

- **Action Execution** - Run workspace actions with project filtering and command execution
- **Placeholder Resolution** - Dynamic string substitution with multiple placeholder types
- **D4rt Integration** - Dart expression and script execution via D4rt interpreter
- **VS Code Bridge** - Remote execution via VS Code Bridge
- **Workspace Model** - Parse and manage `tom_workspace.yaml` and `tom_project.yaml`
- **Shell Integration** - Execute shell commands with environment management

## Getting Started

```bash
dart pub add tom_build
```

## Usage

```dart
import 'package:tom_build/tom_build.dart';

void main() async {
  // Access workspace analyzer
  final analyzer = WorkspaceAnalyzer('.');
  
  // Use placeholder resolution
  final result = await replacePlaceholders(
    'Hello $ENV{USER}, version $VAL{version}',
  );
}
```

## Documentation

| Document | Description |
|----------|-------------|
| [doc/tom_user_reference.md](../doc/tom_user_reference.md) | Complete Tom CLI reference |
| [doc/placeholders_d4rt_guide.md](doc/placeholders_d4rt_guide.md) | Placeholder and D4rt system details |
| [tom_cli_documents.md](tom_cli_documents.md) | Index of all Tom CLI documentation |

## Project Structure

```text
tom_build/
├── bin/                    # CLI entrypoints
├── lib/
│   ├── src/
│   │   ├── tom/            # Core Tom CLI functionality
│   │   ├── dartscript/     # D4rt integration
│   │   ├── scripting/      # Shell and script execution
│   │   └── tools/          # Placeholder resolution
│   └── tom_build.dart      # Main export
├── test/                   # Unit tests
└── doc/                   # Documentation
```

## Related Packages

- `tom_build_tools` - CLI tools (workspace analyzer, mode switcher)
- `tom_vscode_bridge` - VS Code VS Code Bridge
- `tom_core_dartscript` - D4rt interpreter

## License

See LICENSE file in workspace root.
