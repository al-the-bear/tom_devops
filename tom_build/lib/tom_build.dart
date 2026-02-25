/// Tom Build - Build tools and workspace analyzer for the Tom framework.
///
/// Provides workspace analysis, metadata generation, and build utilities.
/// This is the main barrel file that exports all public APIs.
///
/// ## Module Barrels
///
/// For specific functionality, you can also import individual module barrels:
/// - `package:tom_build/scripting.dart` - Scripting utilities (Shell, Fs, Pth, etc.)
///
/// For document scanning and schema validation, use the separate packages:
/// - `package:tom_doc_scanner` - Document scanning
/// - `package:tom_doc_specs` - Document schema validation
///
/// For CLI-specific functionality, use `package:tom_build_cli/tom_build_cli.dart`.
library;

// =============================================================================
// ANALYZER
// =============================================================================
export 'src/analyzer/workspace_analyzer.dart';

// =============================================================================
// REFLECTION GENERATOR
// =============================================================================
export 'src/reflection_generator/reflection_generator.dart';

// =============================================================================
// SCRIPTING UTILITIES
// =============================================================================
export 'src/scripting/env.dart';
export 'src/scripting/fs.dart';
export 'src/scripting/glob.dart';
export 'src/scripting/maps.dart';
export 'src/scripting/path.dart';
export 'src/scripting/shell.dart';
export 'src/scripting/text.dart';
export 'src/scripting/workspace.dart';
export 'src/scripting/yaml.dart';
export 'src/scripting/zone.dart';

// =============================================================================
// TOM FILE OBJECT MODEL & CONTEXT
// =============================================================================
// File Object Model - Data models for workspace/project configuration
export 'src/tom/file_object_model/file_object_model.dart';
export 'src/tom/file_object_model/workspace_parser.dart';
// Context - The global `tom` object for scripts
export 'src/tom/tom_context.dart';

// =============================================================================
// TOOLS - Workspace info and platform detection
// =============================================================================
export 'src/tools/tool_context.dart';
export 'src/tools/workspace_info.dart';
