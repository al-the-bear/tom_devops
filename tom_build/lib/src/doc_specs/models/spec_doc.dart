import '../../doc_scanner/models/document.dart';
import '../../doc_scanner/models/section.dart';
import 'spec_section.dart';
import 'spec_section_type.dart';

/// A document with schema validation and typed access.
///
/// Extends [Document] to provide DocSpecs-specific functionality including
/// schema validation, typed section access, and tag-based querying.
///
/// ## Example
///
/// ```dart
/// final spec = DocSpecs.scanDocument(path: 'quest_overview.docspec.md');
///
/// if (!spec.isValid) {
///   print('Validation errors: ${spec.validationErrors}');
/// }
///
/// // Access top-level sections
/// final overview = spec['overview'];
/// final processing = spec['processing']; // uses access-key
///
/// // Get all requirements
/// final allReqs = spec.getSpecSectionType('requirement').getAll();
///
/// // Get sections with a specific tag
/// final urgentItems = spec.getSectionsByTag('urgent');
/// ```
class SpecDoc extends Document {
  /// The schema name and version (e.g., "quest-overview-1.0").
  final String schemaId;

  /// Validation errors (empty if valid).
  final List<String> validationErrors;

  /// Section name to access-key mappings from schema.
  final Map<String, String> _accessKeys;

  /// Cached section type lookups.
  final Map<String, SpecSectionType> _sectionTypeCache = {};

  /// Creates a new SpecDoc.
  SpecDoc({
    required super.index,
    required super.lineNumber,
    required super.rawHeadline,
    required super.name,
    required super.id,
    required super.text,
    super.fields = const {},
    List<Section>? sections,
    required super.filenameWithPath,
    required super.loadTimestamp,
    required super.filename,
    required super.fullPath,
    required super.workspacePath,
    required super.project,
    required super.projectPath,
    required super.workspaceRoot,
    required super.projectRoot,
    required super.hierarchyDepth,
    this.schemaId = '',
    List<String>? validationErrors,
    Map<String, String>? accessKeys,
  })  : validationErrors = validationErrors ?? [],
        _accessKeys = accessKeys ?? const {},
        super(sections: sections);

  /// Creates a SpecDoc from a base Document with additional properties.
  factory SpecDoc.fromDocument(
    Document document, {
    String schemaId = '',
    List<String>? validationErrors,
    Map<String, String>? accessKeys,
  }) {
    return SpecDoc(
      index: document.index,
      lineNumber: document.lineNumber,
      rawHeadline: document.rawHeadline,
      name: document.name,
      id: document.id,
      text: document.text,
      fields: document.fields,
      sections: document.sections,
      filenameWithPath: document.filenameWithPath,
      loadTimestamp: document.loadTimestamp,
      filename: document.filename,
      fullPath: document.fullPath,
      workspacePath: document.workspacePath,
      project: document.project,
      projectPath: document.projectPath,
      workspaceRoot: document.workspaceRoot,
      projectRoot: document.projectRoot,
      hierarchyDepth: document.hierarchyDepth,
      schemaId: schemaId,
      validationErrors: validationErrors,
      accessKeys: accessKeys,
    );
  }

  /// Creates a SpecDoc from a JSON map.
  factory SpecDoc.fromJson(Map<String, dynamic> json) {
    return SpecDoc(
      index: json['index'] as int,
      lineNumber: json['lineNumber'] as int,
      rawHeadline: json['rawHeadline'] as String? ?? '',
      name: json['name'] as String,
      id: json['id'] as String,
      text: json['text'] as String,
      fields: json['fields'] != null
          ? Map<String, String>.from(json['fields'] as Map)
          : const {},
      sections: json['sections'] != null
          ? (json['sections'] as List)
              .map((s) => SpecSection.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      filenameWithPath: json['filenameWithPath'] as String,
      loadTimestamp: json['loadTimestamp'] as String,
      filename: json['filename'] as String,
      fullPath: json['fullPath'] as String,
      workspacePath: json['workspacePath'] as String,
      project: json['project'] as String,
      projectPath: json['projectPath'] as String,
      workspaceRoot: json['workspaceRoot'] as String,
      projectRoot: json['projectRoot'] as String,
      hierarchyDepth: json['hierarchyDepth'] as int,
      schemaId: json['schemaId'] as String? ?? '',
      validationErrors: json['validationErrors'] != null
          ? List<String>.from(json['validationErrors'] as List)
          : null,
      accessKeys: json['accessKeys'] != null
          ? Map<String, String>.from(json['accessKeys'] as Map)
          : null,
    );
  }

  /// Whether document is valid against schema.
  bool get isValid => validationErrors.isEmpty;

  /// Get a top-level section by name or access-key.
  ///
  /// Looks up the section by name first, then by access-key if configured
  /// in the schema.
  SpecSection? getSection(String sectionName) {
    if (sections == null) return null;

    // First, try direct match by section name
    for (final section in sections!) {
      if (section is SpecSection && section.id == sectionName) {
        return section;
      }
    }

    // Then, check access-keys
    final actualName = _accessKeys.entries
        .where((e) => e.value == sectionName)
        .map((e) => e.key)
        .firstOrNull;

    if (actualName != null) {
      for (final section in sections!) {
        if (section is SpecSection && section.id == actualName) {
          return section;
        }
      }
    }

    return null;
  }

  /// Shorthand for [getSection].
  SpecSection? operator [](String sectionName) => getSection(sectionName);

  /// Get all sections of a specific type across the document.
  ///
  /// Returns a [SpecSectionType] containing all sections of the given type,
  /// grouped by their parent section.
  SpecSectionType getSpecSectionType(String typeName) {
    // Check cache first
    if (_sectionTypeCache.containsKey(typeName)) {
      return _sectionTypeCache[typeName]!;
    }

    final result = <SpecSection, List<SpecSection>>{};

    void collectSections(SpecSection parent, List<Section>? children) {
      if (children == null) return;

      final matchingChildren = <SpecSection>[];
      for (final child in children) {
        if (child is SpecSection) {
          if (child.type == typeName) {
            matchingChildren.add(child);
          }
          // Recursively search subsections
          collectSections(child, child.sections);
        }
      }

      if (matchingChildren.isNotEmpty) {
        result[parent] = matchingChildren;
      }
    }

    // Search from document root
    if (sections != null) {
      for (final section in sections!) {
        if (section is SpecSection) {
          if (section.type == typeName) {
            // Top-level section matches - use document as pseudo-parent
            result.putIfAbsent(_createDocumentSection(), () => []).add(section);
          }
          collectSections(section, section.sections);
        }
      }
    }

    final sectionType = SpecSectionType(type: typeName, sections: result);
    _sectionTypeCache[typeName] = sectionType;
    return sectionType;
  }

  /// Get all sections with a specific tag, optionally filtered by section type.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get all urgent sections
  /// final urgent = spec.getSectionsByTag('urgent');
  ///
  /// // Get only urgent requirements
  /// final urgentReqs = spec.getSectionsByTag('urgent', 'requirement');
  /// ```
  List<SpecSection> getSectionsByTag(String tag, [String? typeName]) {
    final result = <SpecSection>[];

    void collectByTag(List<Section>? sectionList) {
      if (sectionList == null) return;

      for (final section in sectionList) {
        if (section is SpecSection) {
          final matchesTag = section.tags.contains(tag);
          final matchesType = typeName == null || section.type == typeName;

          if (matchesTag && matchesType) {
            result.add(section);
          }

          collectByTag(section.sections);
        }
      }
    }

    collectByTag(sections);
    return result;
  }

  /// Creates a pseudo-section representing the document for grouping purposes.
  SpecSection _createDocumentSection() {
    return SpecSection(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: text,
      fields: fields,
      type: null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'schemaId': schemaId,
      if (validationErrors.isNotEmpty) 'validationErrors': validationErrors,
      if (_accessKeys.isNotEmpty) 'accessKeys': _accessKeys,
    };
  }

  @override
  String toString() =>
      'SpecDoc(filename: $filename, schemaId: $schemaId, isValid: $isValid)';
}
