import 'spec_section.dart';

/// Provides access to all sections of a specific type across a document.
///
/// Groups sections by their parent section, allowing both flat access
/// to all sections of a type and hierarchical access by parent.
///
/// ## Example
///
/// ```dart
/// // Get all requirements across the document
/// final reqType = spec.getSpecSectionType('requirement');
///
/// // Flat list of all requirements
/// for (final req in reqType.getAll()) {
///   print('Requirement: ${req.id}');
/// }
///
/// // Grouped by parent section
/// for (final parent in reqType.sources) {
///   print('Parent: ${parent.id}');
///   for (final req in reqType.sections[parent]!) {
///     print('  - ${req.id}');
///   }
/// }
/// ```
class SpecSectionType {
  /// The type name.
  final String type;

  /// Sections grouped by parent section.
  ///
  /// Each key is a parent [SpecSection], and the value is a list
  /// of child sections of this type found under that parent.
  final Map<SpecSection, List<SpecSection>> sections;

  /// Creates a new SpecSectionType.
  const SpecSectionType({
    required this.type,
    required this.sections,
  });

  /// Creates an empty SpecSectionType for a given type name.
  factory SpecSectionType.empty(String type) {
    return SpecSectionType(type: type, sections: const {});
  }

  /// Get all sections of this type (flat list).
  ///
  /// Returns sections in the order they appear in the document
  /// (parents are visited in order, and their children are in order).
  List<SpecSection> getAll() {
    final result = <SpecSection>[];
    for (final children in sections.values) {
      result.addAll(children);
    }
    return result;
  }

  /// Get all parent sections containing this type.
  List<SpecSection> get sources => sections.keys.toList();

  /// Whether any sections of this type exist.
  bool get isEmpty => sections.isEmpty;

  /// Whether any sections of this type exist.
  bool get isNotEmpty => sections.isNotEmpty;

  /// Total count of sections of this type.
  int get length => sections.values.fold(0, (sum, list) => sum + list.length);

  @override
  String toString() => 'SpecSectionType(type: $type, count: $length)';
}
