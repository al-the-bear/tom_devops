import 'document_structure.dart';
import 'form_type_def.dart';
import 'section_type_def.dart';

/// A DocSpecs schema definition.
///
/// Represents a parsed `.docspec-schema.yaml` file containing section type
/// definitions, document structure, form types, and custom tags.
///
/// ## Example
///
/// ```dart
/// final schema = DocSpecs.loadSchema(schemaId: 'quest-overview-1.0');
/// print('Schema: ${schema.id} v${schema.version}');
///
/// for (final type in schema.sectionTypes.keys) {
///   print('Section type: $type');
/// }
/// ```
class DocSpecSchema {
  /// Schema identifier (parsed from filename).
  final String id;

  /// Schema version (parsed from filename).
  final String version;

  /// Section type definitions.
  final Map<String, SectionTypeDef> sectionTypes;

  /// Document structure definition.
  final DocumentStructure document;

  /// Form type definitions for structured text validation.
  final Map<String, FormTypeDef>? formTypes;

  /// Top-level subsection declarations keyed by section name.
  final Map<String, Map<String, SubsectionDef>>? subsectionDeclarations;

  /// Arbitrary custom tags defined in the schema.
  final Map<String, dynamic> customTags;

  /// Creates a new DocSpecSchema.
  const DocSpecSchema({
    required this.id,
    required this.version,
    required this.sectionTypes,
    required this.document,
    this.formTypes,
    this.subsectionDeclarations,
    this.customTags = const {},
  });

  /// Full schema ID with version (e.g., "quest-overview/1.0").
  String get fullId => '$id/$version';

  /// Schema ID with version in filename format (e.g., "quest-overview-1.0").
  String get filenameId => '$id-$version';

  /// Creates a DocSpecSchema from YAML content.
  ///
  /// The [id] and [version] are typically extracted from the filename.
  factory DocSpecSchema.fromYaml(
    Map<String, dynamic> yaml, {
    required String id,
    required String version,
  }) {
    // Known schema keys
    const knownKeys = {
      'section-types',
      'document',
      'form-types',
    };

    // Parse section types
    final sectionTypesYaml = yaml['section-types'] as Map<String, dynamic>?;
    final sectionTypes = <String, SectionTypeDef>{};
    if (sectionTypesYaml != null) {
      for (final entry in sectionTypesYaml.entries) {
        sectionTypes[entry.key] = SectionTypeDef.fromYaml(
          entry.key,
          entry.value as Map<String, dynamic>,
        );
      }
    }

    // Parse document structure
    final documentYaml = yaml['document'] as Map<String, dynamic>?;
    final document = documentYaml != null
        ? DocumentStructure.fromYaml(documentYaml)
        : const DocumentStructure(sections: {});

    // Parse form types
    Map<String, FormTypeDef>? formTypes;
    final formTypesYaml = yaml['form-types'] as Map<String, dynamic>?;
    if (formTypesYaml != null) {
      formTypes = {};
      for (final entry in formTypesYaml.entries) {
        formTypes[entry.key] = FormTypeDef.fromYaml(
          entry.key,
          entry.value as Map<String, dynamic>,
        );
      }
    }

    // Parse subsection declarations (top-level blocks that aren't known keys)
    Map<String, Map<String, SubsectionDef>>? subsectionDeclarations;
    final documentSectionNames =
        document.sections.keys.toSet();

    for (final entry in yaml.entries) {
      if (!knownKeys.contains(entry.key) &&
          documentSectionNames.contains(entry.key) &&
          entry.value is Map<String, dynamic>) {
        subsectionDeclarations ??= {};
        final sectionDecls = <String, SubsectionDef>{};
        final declYaml = entry.value as Map<String, dynamic>;

        for (final declEntry in declYaml.entries) {
          sectionDecls[declEntry.key] = SubsectionDef.fromYaml(
            declEntry.value as Map<String, dynamic>,
          );
        }

        subsectionDeclarations[entry.key] = sectionDecls;
      }
    }

    // Collect custom tags (anything not in known keys or subsection declarations)
    final customTags = <String, dynamic>{};
    for (final entry in yaml.entries) {
      if (!knownKeys.contains(entry.key) &&
          !documentSectionNames.contains(entry.key)) {
        customTags[entry.key] = entry.value;
      }
    }

    return DocSpecSchema(
      id: id,
      version: version,
      sectionTypes: sectionTypes,
      document: document,
      formTypes: formTypes,
      subsectionDeclarations: subsectionDeclarations,
      customTags: customTags,
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      ...customTags,
      'section-types': {
        for (final entry in sectionTypes.entries)
          entry.key: entry.value.toYaml(),
      },
      if (formTypes != null)
        'form-types': {
          for (final entry in formTypes!.entries)
            entry.key: entry.value.toYaml(),
        },
      'document': document.toYaml(),
      if (subsectionDeclarations != null)
        for (final entry in subsectionDeclarations!.entries)
          entry.key: {
            for (final subEntry in entry.value.entries)
              subEntry.key: subEntry.value.toYaml(),
          },
    };
  }

  @override
  String toString() => 'DocSpecSchema($fullId)';
}
