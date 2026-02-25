/// Definition for for-each registry linking.
class ForEachDef {
  /// Section type of registry entries to iterate over.
  final String sectionType;

  /// Field name in registry entries that identifies each subsection.
  final String key;

  /// Creates a new ForEachDef.
  const ForEachDef({
    required this.sectionType,
    required this.key,
  });

  /// Creates a ForEachDef from a YAML map.
  factory ForEachDef.fromYaml(Map<String, dynamic> yaml) {
    return ForEachDef(
      sectionType: yaml['section-type'] as String,
      key: yaml['key'] as String,
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      'section-type': sectionType,
      'key': key,
    };
  }
}

/// Definition of an expected section in the document.
class SectionDef {
  /// Reference to section type.
  final String sectionType;

  /// Override key for API access (default: section name).
  final String? accessKey;

  /// Whether this section is optional (default: false).
  final bool? optional;

  /// AI prompt to validate this section.
  final String? validationPrompt;

  /// AI prompt to validate all subsections of this section.
  final String? subsectionValidationPrompt;

  /// Link to registry section for generating subsections.
  final ForEachDef? forEach;

  /// Creates a new SectionDef.
  const SectionDef({
    required this.sectionType,
    this.accessKey,
    this.optional,
    this.validationPrompt,
    this.subsectionValidationPrompt,
    this.forEach,
  });

  /// Creates a SectionDef from a YAML map.
  factory SectionDef.fromYaml(Map<String, dynamic> yaml) {
    ForEachDef? forEach;
    if (yaml['for-each'] != null) {
      forEach = ForEachDef.fromYaml(yaml['for-each'] as Map<String, dynamic>);
    }

    return SectionDef(
      sectionType: yaml['section-type'] as String,
      accessKey: yaml['access-key'] as String?,
      optional: yaml['optional'] as bool?,
      validationPrompt: yaml['validation-prompt'] as String?,
      subsectionValidationPrompt:
          yaml['subsection-validation-prompt'] as String?,
      forEach: forEach,
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      'section-type': sectionType,
      if (accessKey != null) 'access-key': accessKey,
      if (optional != null) 'optional': optional,
      if (validationPrompt != null) 'validation-prompt': validationPrompt,
      if (subsectionValidationPrompt != null)
        'subsection-validation-prompt': subsectionValidationPrompt,
      if (forEach != null) 'for-each': forEach!.toYaml(),
    };
  }
}

/// Definition for subsection declarations (top-level block).
class SubsectionDef {
  /// Reference to section type.
  final String sectionType;

  /// Whether this subsection is required (default: false).
  final bool? required;

  /// Position constraint: relative, any, first, last (default: relative).
  final String? position;

  /// Creates a new SubsectionDef.
  const SubsectionDef({
    required this.sectionType,
    this.required,
    this.position,
  });

  /// Creates a SubsectionDef from a YAML map.
  factory SubsectionDef.fromYaml(Map<String, dynamic> yaml) {
    return SubsectionDef(
      sectionType: yaml['section-type'] as String,
      required: yaml['required'] as bool?,
      position: yaml['position'] as String?,
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      'section-type': sectionType,
      if (required != null) 'required': required,
      if (position != null) 'position': position,
    };
  }
}

/// Document structure definition.
class DocumentStructure {
  /// Expected top-level sections.
  final Map<String, SectionDef> sections;

  /// Creates a new DocumentStructure.
  const DocumentStructure({
    required this.sections,
  });

  /// Creates a DocumentStructure from a YAML map.
  factory DocumentStructure.fromYaml(Map<String, dynamic> yaml) {
    final sectionsYaml = yaml['sections'] as Map<String, dynamic>?;
    final sections = <String, SectionDef>{};

    if (sectionsYaml != null) {
      for (final entry in sectionsYaml.entries) {
        sections[entry.key] =
            SectionDef.fromYaml(entry.value as Map<String, dynamic>);
      }
    }

    return DocumentStructure(sections: sections);
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      'sections': {
        for (final entry in sections.entries) entry.key: entry.value.toYaml(),
      },
    };
  }
}
