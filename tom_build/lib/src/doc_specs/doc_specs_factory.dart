import '../doc_scanner/doc_scanner_factory.dart';
import '../doc_scanner/models/document.dart';
import '../doc_scanner/models/section.dart';
import 'models/spec_doc.dart';
import 'models/spec_section.dart';
import 'models/schema/doc_spec_schema.dart';

/// Factory for creating [SpecDoc] and [SpecSection] objects.
///
/// Extends [DocScannerFactory] to inject DocSpecs-specific functionality
/// during document parsing. The factory receives a schema and uses it to
/// resolve section types by prefix matching.
///
/// ## Example
///
/// ```dart
/// final schema = DocSpecs.loadSchema(schemaId: 'quest-overview-1.0');
/// final factory = DocSpecsFactory(schema: schema);
///
/// final doc = DocScanner.scanDocument(
///   filepath: 'quest_overview.md',
///   factory: factory,
/// ) as SpecDoc;
/// ```
class DocSpecsFactory extends DocScannerFactory {
  /// The schema used for section type resolution.
  final DocSpecSchema? schema;

  /// Access keys from the schema (section name -> access key).
  final Map<String, String> _accessKeys;

  /// Creates a new DocSpecsFactory.
  ///
  /// If [schema] is provided, section types will be resolved by prefix
  /// matching in YAML declaration order.
  DocSpecsFactory({this.schema}) : _accessKeys = _extractAccessKeys(schema);

  /// Extracts access keys from the schema's document structure.
  static Map<String, String> _extractAccessKeys(DocSpecSchema? schema) {
    if (schema?.document.sections == null) return const {};

    final keys = <String, String>{};
    for (final entry in schema!.document.sections.entries) {
      final accessKey = entry.value.accessKey;
      if (accessKey != null) {
        keys[entry.key] = accessKey;
      }
    }
    return keys;
  }

  @override
  Section createSection({
    required int index,
    required int lineNumber,
    required String rawHeadline,
    required String name,
    required String id,
    required String text,
    required Map<String, String> fields,
    List<Section>? sections,
  }) {
    // Determine section type by matching ID against prefix (YAML declaration order)
    String? sectionType;
    String? format;

    if (schema != null) {
      for (final entry in schema!.sectionTypes.entries) {
        final prefix = entry.value.prefix;
        if (prefix != null &&
            id.toLowerCase().startsWith(prefix.toLowerCase())) {
          sectionType = entry.key;
          format = entry.value.format;
          break;
        }
      }
    }

    // Parse tags from fields
    final tags =
        fields['tags']?.split(',').map((t) => t.trim()).toList() ?? <String>[];

    return SpecSection(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: text,
      fields: fields,
      sections: sections,
      type: sectionType,
      tags: tags,
      format: format,
    );
  }

  @override
  Document createDocument({
    required int index,
    required int lineNumber,
    required String rawHeadline,
    required String name,
    required String id,
    required String text,
    required Map<String, String> fields,
    List<Section>? sections,
    required String filenameWithPath,
    required String loadTimestamp,
    required String filename,
    required String fullPath,
    required String workspacePath,
    required String project,
    required String projectPath,
    required String workspaceRoot,
    required String projectRoot,
    required int hierarchyDepth,
  }) {
    return SpecDoc(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: text,
      fields: fields,
      sections: sections,
      filenameWithPath: filenameWithPath,
      loadTimestamp: loadTimestamp,
      filename: filename,
      fullPath: fullPath,
      workspacePath: workspacePath,
      project: project,
      projectPath: projectPath,
      workspaceRoot: workspaceRoot,
      projectRoot: projectRoot,
      hierarchyDepth: hierarchyDepth,
      schemaId: fields['schema'] ?? '',
      accessKeys: _accessKeys,
    );
  }
}
