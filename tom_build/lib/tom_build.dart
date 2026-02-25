/// Tom Build - Build tools and workspace analyzer for the Tom framework.
///
/// Provides workspace analysis, metadata generation, and build utilities.
/// This is the main barrel file that exports all public APIs.
///
/// ## Module Barrels
///
/// For specific functionality, you can also import individual module barrels:
/// - `package:tom_build/scripting.dart` - Scripting utilities (Shell, Fs, Pth, etc.)
/// - `package:tom_build/doc_scanner.dart` - Document scanning
/// - `package:tom_build/doc_specs.dart` - Document schema validation
///
/// For CLI-specific functionality, use `package:tom_build_cli/tom_build_cli.dart`.
library;

// =============================================================================
// ANALYZER
// =============================================================================
export 'src/analyzer/workspace_analyzer.dart';

// =============================================================================
// DOC SCANNER
// =============================================================================
export 'src/doc_scanner/doc_scanner.dart';
export 'src/doc_scanner/doc_scanner_factory.dart';
export 'src/doc_scanner/markdown_parser.dart';
export 'src/doc_scanner/models/document.dart';
export 'src/doc_scanner/models/document_folder.dart';
export 'src/doc_scanner/models/section.dart';

// =============================================================================
// DOC SPECS
// =============================================================================
export 'src/doc_specs/doc_specs.dart';
export 'src/doc_specs/doc_specs_factory.dart';
export 'src/doc_specs/models/schema/doc_spec_schema.dart';
export 'src/doc_specs/models/schema/document_structure.dart';
export 'src/doc_specs/models/schema/form_type_def.dart';
export 'src/doc_specs/models/schema/schema_info.dart';
export 'src/doc_specs/models/schema/section_type_def.dart';
export 'src/doc_specs/models/spec_doc.dart';
export 'src/doc_specs/models/spec_section.dart';
export 'src/doc_specs/models/spec_section_type.dart';
export 'src/doc_specs/schema/schema_loader.dart';
export 'src/doc_specs/validation/validation_error.dart';
export 'src/doc_specs/validation/validator.dart';

// =============================================================================
// MD LATEX CONVERTER
// =============================================================================
export 'src/md_latex_converter/latex_macros.dart';
// Hide MarkdownParser - conflicts with doc_scanner
export 'src/md_latex_converter/markdown_parser.dart' hide MarkdownParser;
export 'src/md_latex_converter/md_latex_converter.dart' hide MarkdownParser;

// =============================================================================
// MD PDF CONVERTER
// =============================================================================
// Hide MdPdfConverterOptions - uses external PDF types, use PdfConverterOptionsWrapper instead
export 'src/md_pdf_converter/md_pdf_converter.dart' hide MdPdfConverterOptions;
export 'src/md_pdf_converter/pdf_options_wrapper.dart';

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
