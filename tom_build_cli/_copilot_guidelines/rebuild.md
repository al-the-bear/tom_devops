# Tom Build Tools - Rebuild Guideline

## Compiling Binaries

Pre-compiled binaries are generated into `<workspace-root>/bin/<operating-system>/`.

### Linux (Ubuntu)

Use the provided shell script:

```bash
cd tom_build_tools
./bin/compile_linux.sh
```

This compiles all tools to `bin/ubuntu/`.

### macOS

```bash
cd tom_build_tools
mkdir -p bin/macos
dart pub get
for tool in md_latex_converter md_pdf_converter mode_switcher reflection_generator tom_build_tools ws_analyzer ws_analyzer_all; do
    dart compile exe bin/$tool.dart -o bin/macos/$tool
done
```

### Windows

```powershell
cd tom_build_tools
mkdir -p bin\windows
dart pub get
foreach ($tool in @("md_latex_converter", "md_pdf_converter", "mode_switcher", "reflection_generator", "tom_build_tools", "ws_analyzer", "ws_analyzer_all")) {
    dart compile exe bin\$tool.dart -o bin\windows\$tool.exe
}
```

## Available Tools

| Tool                   | Prefix | Description                                        |
| ---------------------- | ------ | -------------------------------------------------- |
| `ws_analyzer`          | `wa-`  | Workspace analyzer (excludes zom_* test projects)  |
| `ws_analyzer_all`      | `wa-`  | Workspace analyzer (includes all projects)         |
| `reflection_generator` | `rc-`  | Generates reflection code                          |
| `md_pdf_converter`     | `mpc-` | Converts Markdown to PDF                           |
| `md_latex_converter`   | `mlc-` | Converts Markdown to LaTeX                         |
| `mode_switcher`        | `ms-`  | Switches between development modes                 |
| `tom_build_tools`      | -      | Main CLI entry point                               |

## CLI Parameter Conventions

All tools use prefixed named parameters to avoid conflicts when composing tools:

```bash
# Workspace analyzer with wa- prefix
dart bin/ws_analyzer.dart wa-path=/path/to/workspace wa-include-tests

# Mode switcher with ms- prefix
dart bin/mode_switcher.dart ms-mode=development ms-path=.. ms-dry-run

# Mode switcher can run analyzer first
dart bin/mode_switcher.dart ms-analyze ms-mode=production
```

Legacy positional arguments and `--flag` style options are still supported for backward compatibility.
