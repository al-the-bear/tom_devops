/// DocSpecs - Document schema validation for structured markdown.
///
/// This library provides schema definitions and validation for markdown
/// documents, extending DocScanner with typed section access.
///
/// ## Example
///
/// ```dart
/// import 'package:tom_build/doc_specs.dart';
///
/// void main() async {
///   final doc = await DocSpecs.scanDocument(path: 'quest_overview.docspec.md');
///
///   if (!doc.isValid) {
///     print('Errors: ${doc.validationErrors}');
///   }
///
///   // Access sections by type
///   final todos = doc.getSpecSectionType('todo').getAll();
///   for (final todo in todos) {
///     print('TODO: ${todo.id}');
///   }
/// }
/// ```
library;

// Main API
export 'src/doc_specs/doc_specs.dart';
export 'src/doc_specs/doc_specs_factory.dart';

// Re-export Section and Document from doc_scanner (used by SpecSection and SpecDoc)
export 'src/doc_scanner/models/section.dart' show Section;
export 'src/doc_scanner/models/document.dart' show Document;

// Models
export 'src/doc_specs/models/spec_section.dart';
export 'src/doc_specs/models/spec_doc.dart';
export 'src/doc_specs/models/spec_section_type.dart';

// Schema models
export 'src/doc_specs/models/schema/doc_spec_schema.dart';
export 'src/doc_specs/models/schema/section_type_def.dart';
export 'src/doc_specs/models/schema/document_structure.dart';
export 'src/doc_specs/models/schema/form_type_def.dart';
export 'src/doc_specs/models/schema/schema_info.dart';

// Schema loading
export 'src/doc_specs/schema/schema_loader.dart';

// Validation
export 'src/doc_specs/validation/validation_error.dart';
export 'src/doc_specs/validation/validator.dart';
