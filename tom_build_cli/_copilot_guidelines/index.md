# Tom Build CLI Project Guidelines

**Project:** `tom_build_cli`  
**Type:** CLI Tool

## Global Guidelines

| Document | Purpose |
|----------|---------|
| [Documentation Guidelines](/_copilot_guidelines/documentation_guidelines.md) | Where to place user docs vs development docs |

## Dart Guidelines

| Document | Purpose |
|----------|---------|
| [Coding Guidelines](/_copilot_guidelines/dart/coding_guidelines.md) | Naming conventions, error handling, patterns |
| [Unit Tests](/_copilot_guidelines/dart/unit_tests.md) | Test structure, matchers, mocking patterns |
| [Examples](/_copilot_guidelines/dart/examples.md) | Example file creation guidelines |

## Project-Specific Guidelines

| File | Description |
|------|-------------|
| [ai_build_architecture.md](ai_build_architecture.md) | AI-assisted build system architecture |
| [rebuild.md](rebuild.md) | Rebuild workflow and procedures |
| [vscode_integration.md](vscode_integration.md) | VS Code integration guidelines |

## Quick Reference

**Purpose:** Command-line interface for Tom build operations

**Key Components:**
- `bk` command — Main buildkit CLI entry point
- Pipeline execution and orchestration
- Workspace scanning and project discovery

**Documentation:**
- [README](../README.md) — Quick start guide

## Related Packages

- [tom_build_kit](../../xternal/tom_module_basics/tom_build_kit/) — Build tools (versioner, cleanup, compiler, etc.)
- [tom_build_base](../../xternal/tom_module_basics/tom_build_base/) — Shared CLI infrastructure
