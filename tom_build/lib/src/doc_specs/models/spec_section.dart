import '../../doc_scanner/models/section.dart';

/// A section with schema type information.
///
/// Extends [Section] with DocSpecs-specific properties like type, tags,
/// and format. Provides methods for form field extraction and subsection access.
///
/// ## Example
///
/// ```dart
/// final section = spec['requirements']?.getSubsections().first as SpecSection;
/// print('Type: ${section.type}');
/// print('Tags: ${section.tags}');
///
/// // Access form fields
/// final method = section.getFormField('method');
/// final preamble = section.preamble;
/// ```
class SpecSection extends Section {
  /// The section type from the schema (determined by prefix matching).
  final String? type;

  /// Tags parsed from fields['tags'] (comma-separated in document).
  final List<String> tags;

  /// Format specification from schema (code block language or form type).
  final String? format;

  /// Cached form fields extracted from text.
  Map<String, String>? _formFields;

  /// Cached preamble text.
  String? _preamble;

  /// Whether form fields have been parsed.
  bool _formFieldsParsed = false;

  /// Creates a new SpecSection.
  SpecSection({
    required super.index,
    required super.lineNumber,
    required super.rawHeadline,
    required super.name,
    required super.id,
    required super.text,
    super.fields = const {},
    List<Section>? sections,
    this.type,
    List<String>? tags,
    this.format,
  })  : tags = tags ?? const [],
        super(sections: sections);

  /// Creates a SpecSection from a base Section with additional properties.
  factory SpecSection.fromSection(
    Section section, {
    String? type,
    List<String>? tags,
    String? format,
  }) {
    return SpecSection(
      index: section.index,
      lineNumber: section.lineNumber,
      rawHeadline: section.rawHeadline,
      name: section.name,
      id: section.id,
      text: section.text,
      fields: section.fields,
      sections: section.sections,
      type: type,
      tags: tags,
      format: format,
    );
  }

  /// Creates a SpecSection from a JSON map.
  factory SpecSection.fromJson(Map<String, dynamic> json) {
    return SpecSection(
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
      type: json['type'] as String?,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : const [],
      format: json['format'] as String?,
    );
  }

  /// Get a form field value from section text.
  ///
  /// Returns null if field not found.
  /// Equivalent to `${text[fieldname]}` placeholder syntax.
  ///
  /// ## Example
  ///
  /// Given section text:
  /// ```
  /// Description: This is the description.
  /// Method: POST
  /// Path: /api/v1/users
  /// ```
  ///
  /// ```dart
  /// section.getFormField('method'); // Returns 'POST'
  /// section.getFormField('path');   // Returns '/api/v1/users'
  /// ```
  String? getFormField(String fieldname) {
    _parseFormFields();
    return _formFields?[fieldname.toLowerCase()];
  }

  /// Get the preamble text (text before first field).
  ///
  /// Equivalent to `${text[]}` placeholder syntax.
  /// Returns null if no preamble exists.
  String? get preamble {
    _parseFormFields();
    return _preamble;
  }

  /// Get all direct subsections of a specific type.
  ///
  /// Returns an empty list if no subsections match.
  List<SpecSection> getSubsectionsByType(String typeName) {
    if (sections == null) return [];
    return sections!
        .whereType<SpecSection>()
        .where((s) => s.type == typeName)
        .toList();
  }

  /// Get all direct subsections as SpecSection instances.
  ///
  /// Returns an empty list if no subsections exist.
  List<SpecSection> getSubsections() {
    if (sections == null) return [];
    return sections!.whereType<SpecSection>().toList();
  }

  /// Parses form fields from the text content.
  ///
  /// Form syntax: `Fieldname: value`
  /// - Field names are case-insensitive
  /// - Values continue until next field line
  /// - Text before first field is the preamble
  void _parseFormFields() {
    if (_formFieldsParsed) return;
    _formFieldsParsed = true;

    if (text.isEmpty) {
      _formFields = {};
      _preamble = null;
      return;
    }

    final fields = <String, String>{};
    final lines = text.split('\n');
    final fieldPattern = RegExp(r'^([A-Za-z][A-Za-z0-9_-]*)\s*:\s*(.*)$');

    String? currentField;
    final currentValue = StringBuffer();
    final preambleBuffer = StringBuffer();
    var foundFirstField = false;

    for (final line in lines) {
      final match = fieldPattern.firstMatch(line);

      if (match != null) {
        // Save previous field if any
        if (currentField != null) {
          fields[currentField] = currentValue.toString().trim();
          currentValue.clear();
        }

        // Start new field
        foundFirstField = true;
        currentField = match.group(1)!.toLowerCase();
        currentValue.write(match.group(2));
      } else if (foundFirstField && currentField != null) {
        // Continue current field value
        if (currentValue.isNotEmpty) {
          currentValue.write('\n');
        }
        currentValue.write(line);
      } else {
        // Preamble text (before first field)
        if (preambleBuffer.isNotEmpty) {
          preambleBuffer.write('\n');
        }
        preambleBuffer.write(line);
      }
    }

    // Save last field
    if (currentField != null) {
      fields[currentField] = currentValue.toString().trim();
    }

    _formFields = fields;
    final preambleText = preambleBuffer.toString().trim();
    _preamble = preambleText.isEmpty ? null : preambleText;
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      if (type != null) 'type': type,
      if (tags.isNotEmpty) 'tags': tags,
      if (format != null) 'format': format,
    };
  }

  @override
  String toString() =>
      'SpecSection(name: $name, id: $id, type: $type, tags: $tags)';
}
