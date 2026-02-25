# Tom Build Package Restructuring Analysis

## Overview

This document analyzes the `tom_build` package to identify which classes should:

1. **Remain CLI-internal** - Used only by Tom CLI, not useful for DartScript users
2. **Be scriptable** - Useful for DartScript users, should be exposed via D4rt bridges
3. **Need splitting** - Classes that have both CLI-internal parts and scriptable utilities

## Current Package Structure

```
lib/src/
├── analyzer/              # WorkspaceAnalyzer
├── d4rt_bridges/          # Generated D4rt bridges (73 classes bridged)
├── dartscript/            # D4rt CLI initialization
├── doc_scanner/           # Document scanning
├── doc_specs/             # Document spec validation
├── md_latex_converter/    # Markdown to LaTeX
├── md_pdf_converter/      # Markdown to PDF
├── reflection_generator/  # Reflection generator wrapper
├── scripting/             # Shell-script-like utilities
├── tom/                   # Core Tom CLI code
│   ├── cli/               # Argument parsing, git, versioning
│   ├── config/            # Config loading/merging
│   ├── execution/         # Action/command execution
│   ├── file_object_model/ # YAML object models
│   ├── generation/        # Master file generation
│   ├── mode/              # Mode block processing
│   └── template/          # Tomplate processing
├── tools/                 # CLI tools support
└── ws_prepper/            # Workspace preparation
```

## Current Barrel Exports

| Barrel File | Purpose | Current Exports |
|-------------|---------|-----------------|
| `tom_build.dart` | Main (exports everything) | All sub-barrels |
| `scripting.dart` | Scripting utilities | Shell, Fs, Glob, Text, Env, Pth, Yaml, Maps, Workspace, Zoned |
| `tom.dart` | Tom CLI context | TomContext, Shell, Fs, Yaml, Glob, Pth, Env, Text, Maps, Workspace |
| `docscanner.dart` | Document scanning | DocScanner, Document, Section, DocumentFolder |
| `doc_specs.dart` | Document specs | DocSpecs, SpecDoc, schema classes |
| `dartscript.dart` | D4rt bridges | AllBridge, all generated bridges |

---

## Class Categorization

### Category 1: Already Scriptable (KEEP)

These classes are already designed for DartScript use with static methods and are properly bridged:

| Class | Location | Purpose | Notes |
|-------|----------|---------|-------|
| `Shell` | scripting/shell.dart | Shell command execution | Static methods, excellent for scripting |
| `Fs` | scripting/fs.dart | Filesystem operations | Static methods, essential for scripting |
| `Pth` | scripting/path.dart | Path manipulation | Static methods, wraps dart:io/package:path |
| `Glob` | scripting/glob.dart | Glob pattern matching | Static methods, file finding |
| `Text` | scripting/text.dart | Text processing | Static methods, templates, indent, wrap |
| `Env` | scripting/env.dart | Environment variables | Static methods, .env loading, placeholders |
| `Yaml` | scripting/yaml.dart | YAML loading | Static methods, env variable substitution |
| `Maps` | scripting/maps.dart | Map utilities | Static methods, merging, traversal |
| `Zoned` | scripting/zone.dart | Zone value access | Static methods, zone utilities |
| `Workspace` | scripting/workspace.dart | Workspace info access | Static methods, project/group access |
| `DocScanner` | doc_scanner/doc_scanner.dart | Markdown scanning | Static methods, useful for scripts |
| `DocSpecs` | doc_specs/doc_specs.dart | Schema validation | Static methods, useful for scripts |
| `MdPdfConverter` | md_pdf_converter/ | Markdown to PDF | Instance-based, useful for scripts |
| `MdLatexConverter` | md_latex_converter/ | Markdown to LaTeX | Instance-based, useful for scripts |

**Recommendation:** ✅ Keep as-is. These are well-designed for scripting.

---

### Category 2: Scriptable but Underutilized (ENHANCE)

These classes could be useful for scripting but may need better exposure:

| Class | Location | Purpose | Recommendation |
|-------|----------|---------|----------------|
| `WorkspaceAnalyzer` | analyzer/ | Analyzes workspace structure | ⚡ Useful for scripts that need project info. Already bridged. Could add convenience static methods. |
| `ReflectionGeneratorRunner` | reflection_generator/ | Runs reflection generation | ⚡ Useful for build scripts. Already bridged. |
| `TomContext` (`tom` global) | tom/tom_context.dart | Global context object | ⚡ Already exposed as `tom` global. Good design. |
| `WorkspaceInfo` | tools/workspace_info.dart | Workspace metadata | ⚡ Accessed via `Workspace.info`. Well exposed. |
| `PlatformInfo` | tools/tool_context.dart | Platform detection | ⚡ Accessed via `Workspace.platform`. Well exposed. |

**Recommendation:** ✅ These are well-positioned. Minor enhancements possible.

---

### Category 3: CLI-Internal (DO NOT BRIDGE)

These classes are specific to Tom CLI implementation and have no value for DartScript users:

| Class | Location | Purpose | Why Not Scriptable |
|-------|----------|---------|-------------------|
| `TomCli` | tom/cli/tom_cli.dart | Main CLI entry point | Only for CLI bootstrap |
| `ArgumentParser` | tom/cli/argument_parser.dart | Parses CLI arguments | CLI-specific parsing |
| `ParsedArguments` | tom/cli/argument_parser.dart | Parsed CLI args | CLI-specific data structure |
| `ActionInvocation` | tom/cli/argument_parser.dart | Single action invoke | CLI execution model |
| `InternalCommands` | tom/cli/internal_commands.dart | :analyze, :pipeline, etc. | CLI command registry |
| `WorkspaceContext` | tom/cli/workspace_context.dart | Runtime workspace state | CLI runtime state |
| `ActionExecutor` | tom/execution/action_executor.dart | Executes workspace actions | CLI-specific orchestration |
| `D4rtRunner` | tom/execution/d4rt_runner.dart | Executes D4rt in actions | CLI D4rt integration |
| `CommandRunner` | tom/execution/command_runner.dart | Runs shell commands | Use `Shell` instead for scripts |
| `VsCodeBridgeClient` | tom/execution/vscode_bridge_client.dart | VS Code communication | CLI-specific integration |
| `OutputFormatter` | tom/execution/output_formatter.dart | CLI output formatting | CLI display logic |
| `ConfigLoader` | tom/config/config_loader.dart | Loads tom_workspace.yaml | Use `Yaml` for scripts |
| `ConfigMerger` | tom/config/config_merger.dart | Merges configurations | CLI config resolution |
| `MasterGenerator` | tom/generation/master_generator.dart | Generates tom_master*.yaml | CLI-specific generation |
| `PlaceholderResolver` | tom/generation/placeholder_resolver.dart | Resolves placeholders | CLI placeholder system |
| `BuildOrder` | tom/generation/build_order.dart | Computes build order | CLI build orchestration |
| `ModeProcessor` | tom/mode/mode_processor.dart | Processes @@@mode blocks | CLI mode system |
| `ModeResolver` | tom/mode/mode_resolver.dart | Resolves active modes | CLI mode system |
| `TomplateProcessor` | tom/template/tomplate_processor.dart | Processes .tomplate files | CLI template system |
| `TomplateParser` | tom/template/tomplate_parser.dart | Parses .tomplate files | CLI template system |
| `WsPrepper` | ws_prepper/ws_prepper.dart | Prepares workspace templates | CLI :prepper command |
| `TomRunner` | tools/tom_runner.dart | Runs tom commands | CLI command execution |
| `TomCommandParser` | tools/tom_command_parser.dart | Parses tom commands | CLI parsing |
| `Pipeline` | tools/pipeline.dart | Pipeline execution | CLI pipeline system |

**Recommendation:** ❌ Do not bridge. These are implementation details of Tom CLI.

---

### Category 4: Data Models (SCRIPTABLE READ-ONLY)

These are YAML data models that scripts may need to read but not construct:

| Class | Location | Purpose | Recommendation |
|-------|----------|---------|----------------|
| `TomWorkspace` | tom/file_object_model/ | Workspace config | ⚡ Read via `tom.workspace`. Bridged. |
| `TomProject` | tom/file_object_model/ | Project config | ⚡ Read via `tom.project`. Bridged. |
| `ProjectEntry` | tom/file_object_model/ | Project info entry | ⚡ Read via `tom.projectInfo`. Bridged. |
| `GroupDef` | tom/file_object_model/ | Group definition | ⚡ Read via `tom.groups`. Bridged. |
| `ActionDef` | tom/file_object_model/ | Action definition | ⚠️ Consider bridging for introspection |
| `ModeDef` | tom/file_object_model/ | Mode definition | ⚠️ Consider bridging for introspection |
| `Document` | doc_scanner/models/ | Parsed document | ✅ Already bridged |
| `Section` | doc_scanner/models/ | Document section | ✅ Already bridged |
| `SpecDoc` | doc_specs/models/ | Validated spec doc | ✅ Already bridged |

**Recommendation:** ✅ Most already bridged. Consider `ActionDef`/`ModeDef` for introspection.

---

### Category 5: Utilities That Could Be Split (CONSIDER)

These classes have mixed responsibilities:

| Class | Issue | Scriptable Part | CLI-Internal Part |
|-------|-------|-----------------|-------------------|
| `GitHelper` | Git operations useful for scripts | `getChangedFiles()`, `hasProjectChanges()`, `isGitRepository()` | Integration with VersionBumper |
| `VersionBumper` | Version bumping useful for scripts | `bumpVersion()`, `BumpType` | CLI command integration |
| `ToolContext` | Platform info useful, context loading CLI-specific | `PlatformInfo` (already exposed) | `loadContext()`, singleton pattern |

**Recommendation:** 
- `GitHelper` - ⚡ **Consider bridging** - Git operations are useful for build scripts
- `VersionBumper` - ⚡ **Consider bridging** - Version bumping useful for release scripts
- `ToolContext` - ✅ Already split well via `Workspace.platform`

---

## Proposed Package Split

### Option A: Two Packages (Recommended)

Split `tom_build` into:

1. **`tom_cli`** - The Tom CLI tool (not scriptable)
   - All `tom/cli/`, `tom/config/`, `tom/execution/`, `tom/generation/`, `tom/mode/`, `tom/template/`
   - `ws_prepper/`
   - `tools/` (TomRunner, Pipeline, etc.)
   - CLI entry point and argument handling

2. **`tom_scripting`** (or keep as `tom_build` for scripts)
   - All `scripting/` classes
   - `doc_scanner/`, `doc_specs/`
   - `md_pdf_converter/`, `md_latex_converter/`
   - `analyzer/` (WorkspaceAnalyzer)
   - `dartscript/` and `d4rt_bridges/`
   - Data models for reading (`tom/file_object_model/`)

### Option B: Single Package with Clear Boundaries

Keep as `tom_build` but:

1. **Don't bridge CLI-internal classes** (Category 3)
2. **Keep current bridges** for scriptable classes
3. **Add bridges** for `GitHelper`, `VersionBumper`
4. **Document clearly** which classes are for CLI vs scripts

---

## Classes Missing from D4rt Bridges (Should Add)

Based on the analysis, these classes should be considered for bridging:

| Class | Reason | Priority |
|-------|--------|----------|
| `GitHelper` | Git operations useful in build scripts | Medium |
| `VersionBumper` | Version management useful in release scripts | Medium |
| `ActionDef` | Allows scripts to introspect available actions | Low |
| `ModeDef` | Allows scripts to introspect available modes | Low |

---

## Classes Currently Bridged That Could Be Removed

The `d4rt_bridges/tom_build_bridges.dart` file shows 73+ bridged classes. Some may be overbridged:

| Bridged Class | Assessment |
|---------------|------------|
| `ConfigLoader` | ❌ Remove - CLI internal |
| `ConfigMerger` | ❌ Remove - CLI internal |
| `MasterGenerator*` | ❌ Remove - CLI internal |
| `ActionExecutor*` | ❌ Remove - CLI internal |
| `ModeProcessor` | ❌ Remove - CLI internal |
| `TomplateProcessor` | ❌ Remove - CLI internal |

**Note:** Need to verify which classes are actually bridged vs just imported.

---

## Summary Recommendations

### Immediate Actions (No Package Split)

1. ✅ **Keep current scriptable classes** - They're well-designed
2. ⚡ **Add `GitHelper` bridge** - Useful for build scripts
3. ⚡ **Add `VersionBumper` bridge** - Useful for release scripts
4. ❌ **Don't bridge CLI-internal classes** - Verify d4rt_bridges content
5. 📚 **Document clearly** in README which classes are for scripting

### Future Consideration (Package Split)

If the package grows significantly:

1. Extract `tom_cli` as separate package
2. Rename remaining to `tom_scripting` or keep as `tom_build`
3. `tom_cli` depends on `tom_scripting` for scripting utilities

---

## Appendix: D4rt Bridge Audit Needed

The `tom_build_bridges.dart` file is 9667 lines with 73+ bridged classes. A full audit should:

1. List all currently bridged classes
2. Compare against Category 3 (CLI-internal) list
3. Remove bridges for CLI-internal classes
4. Ensure all Category 1 classes are bridged

This would reduce bridge complexity and make clear what's scriptable.
