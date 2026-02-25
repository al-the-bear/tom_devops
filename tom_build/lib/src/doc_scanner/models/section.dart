/// A section within a markdown document.
///
/// Represents a headline and its associated content in a markdown file.
/// Sections form a tree structure where each section can contain nested
/// subsections corresponding to lower-level headlines.
///
/// ## Example
///
/// Given the markdown:
/// ```markdown
/// # Main Title
/// Some content here.
/// ## <!--[sub] type=api--> Subsection
/// More content.
/// ```
///
/// This produces:
/// ```dart
/// Section(
///   index: 0,
///   name: 'Main Title',
///   id: 'main_title',
///   text: 'Some content here.',
///   lineNumber: 1,
///   rawHeadline: 'Main Title',
///   fields: {},
///   sections: [
///     Section(
///       index: 0,
///       name: 'Subsection',
///       id: 'sub',
///       text: 'More content.',
///       lineNumber: 3,
///       rawHeadline: '<!--[sub] type=api--> Subsection',
///       fields: {'type': 'api'},
///     ),
///   ],
/// )
/// ```
class Section {
  /// The zero-based index of this section among its siblings.
  final int index;

  /// The line number where this section's headline appears (1-based).
  final int lineNumber;

  /// The raw headline line from markdown (without # markers).
  final String rawHeadline;

  /// The headline text (without the `#` markers, ID, and metadata).
  final String name;

  /// The unique identifier for this section.
  ///
  /// Extracted from `[id]` or `<!--[id]-->` in the headline,
  /// or auto-generated from the headline text.
  final String id;

  /// The content text between this headline and the next headline.
  ///
  /// Empty string if there is no content.
  final String text;

  /// Key-value metadata fields parsed from the headline.
  ///
  /// Parsed from `key=value` pairs in HTML comments or text around the ID.
  final Map<String, String> fields;

  /// Nested subsections (lower-level headlines).
  ///
  /// Null if this section has no subsections.
  final List<Section>? sections;

  /// Creates a new section.
  const Section({
    required this.index,
    required this.lineNumber,
    required this.rawHeadline,
    required this.name,
    required this.id,
    required this.text,
    this.fields = const {},
    this.sections,
  });

  /// Creates a Section from a JSON map.
  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
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
              .map((s) => Section.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  /// Converts this section to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'lineNumber': lineNumber,
      'rawHeadline': rawHeadline,
      'name': name,
      'id': id,
      'text': text,
      if (fields.isNotEmpty) 'fields': fields,
      if (sections != null)
        'sections': sections!.map((s) => s.toJson()).toList(),
    };
  }

  @override
  String toString() => 'Section(name: $name, id: $id, index: $index)';
}
