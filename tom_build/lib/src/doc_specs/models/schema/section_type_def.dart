/// Pattern validation definition for section IDs or text.
///
/// Used in `pattern-check-id` and `pattern-check-text` schema properties.
class PatternCheckDef {
  /// Regex pattern that values must match.
  final String pattern;

  /// Error message shown when pattern check fails.
  final String errorMessage;

  /// Creates a new PatternCheckDef.
  const PatternCheckDef({
    required this.pattern,
    required this.errorMessage,
  });

  /// Creates a PatternCheckDef from a YAML map.
  factory PatternCheckDef.fromYaml(Map<String, dynamic> yaml) {
    return PatternCheckDef(
      pattern: yaml['pattern'] as String,
      errorMessage: yaml['error-message'] as String? ?? 'Pattern check failed',
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      'pattern': pattern,
      'error-message': errorMessage,
    };
  }
}

/// Constraint for child sections within a section type.
class SubsectionConstraint {
  /// Reference to section type name.
  final String typeName;

  /// Max count of this child type (null = infinite).
  final int? maxCount;

  /// Minimum required children of this type.
  final int? minCount;

  /// Shorthand for minCount: 1.
  final bool? required;

  /// Creates a new SubsectionConstraint.
  const SubsectionConstraint({
    required this.typeName,
    this.maxCount,
    this.minCount,
    this.required,
  });

  /// Creates a SubsectionConstraint from a YAML map.
  factory SubsectionConstraint.fromYaml(
      String typeName, Map<String, dynamic> yaml) {
    final maxCountValue = yaml['max-count'];
    int? maxCount;
    if (maxCountValue != null && maxCountValue != 'infinite') {
      maxCount = maxCountValue as int;
    }

    return SubsectionConstraint(
      typeName: typeName,
      maxCount: maxCount,
      minCount: yaml['min-count'] as int?,
      required: yaml['required'] as bool?,
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      if (maxCount != null) 'max-count': maxCount else 'max-count': 'infinite',
      if (minCount != null) 'min-count': minCount,
      if (required != null) 'required': required,
    };
  }
}

/// Definition of a section type from the schema.
class SectionTypeDef {
  /// Type name (key in section-types).
  final String name;

  /// ID prefix for sections of this type.
  final String? prefix;

  /// Max occurrences in entire document (null = unlimited).
  final int? maxCountInDocument;

  /// Max nesting depth (null = unlimited, 0 = no children).
  final int? maxSubsectionLevels;

  /// Allowed child section types with their constraints.
  final Map<String, SubsectionConstraint>? subsectionTypes;

  /// Regex pattern check for valid section IDs.
  final PatternCheckDef? patternCheckId;

  /// Regex pattern check for section text content.
  final PatternCheckDef? patternCheckText;

  /// Format specification (code block language or form-type reference).
  final String? format;

  /// Section must have non-empty text content.
  final bool? textRequired;

  /// Minimum character count for text content.
  final int? minTextLength;

  /// Maximum character count for text content.
  final int? maxTextLength;

  /// Human-readable description for tooling/docs.
  final String? description;

  /// Whitelist of valid tags for this section type (null = any tag allowed).
  final List<String>? allowedTags;

  /// AI prompt to validate section content.
  final String? validationPrompt;

  /// Field names that must be present in section text.
  final List<String>? requiredFields;

  /// Creates a new SectionTypeDef.
  const SectionTypeDef({
    required this.name,
    this.prefix,
    this.maxCountInDocument,
    this.maxSubsectionLevels,
    this.subsectionTypes,
    this.patternCheckId,
    this.patternCheckText,
    this.format,
    this.textRequired,
    this.minTextLength,
    this.maxTextLength,
    this.description,
    this.allowedTags,
    this.validationPrompt,
    this.requiredFields,
  });

  /// Creates a SectionTypeDef from a YAML map.
  factory SectionTypeDef.fromYaml(String name, Map<String, dynamic> yaml) {
    // Parse subsection types
    Map<String, SubsectionConstraint>? subsectionTypes;
    if (yaml['subsection-types'] != null) {
      final subsectionYaml = yaml['subsection-types'] as Map<String, dynamic>;
      subsectionTypes = {};
      for (final entry in subsectionYaml.entries) {
        subsectionTypes[entry.key] = SubsectionConstraint.fromYaml(
          entry.key,
          entry.value as Map<String, dynamic>,
        );
      }
    }

    // Parse pattern checks
    PatternCheckDef? patternCheckId;
    if (yaml['pattern-check-id'] != null) {
      patternCheckId = PatternCheckDef.fromYaml(
        yaml['pattern-check-id'] as Map<String, dynamic>,
      );
    }

    PatternCheckDef? patternCheckText;
    if (yaml['pattern-check-text'] != null) {
      patternCheckText = PatternCheckDef.fromYaml(
        yaml['pattern-check-text'] as Map<String, dynamic>,
      );
    }

    // Parse allowed tags
    List<String>? allowedTags;
    if (yaml['allowed-tags'] != null) {
      allowedTags = List<String>.from(yaml['allowed-tags'] as List);
    }

    // Parse required fields
    List<String>? requiredFields;
    if (yaml['required-fields'] != null) {
      requiredFields = List<String>.from(yaml['required-fields'] as List);
    }

    return SectionTypeDef(
      name: name,
      prefix: yaml['prefix'] as String?,
      maxCountInDocument: yaml['max-count-in-document'] as int?,
      maxSubsectionLevels: yaml['max-subsection-levels'] as int?,
      subsectionTypes: subsectionTypes,
      patternCheckId: patternCheckId,
      patternCheckText: patternCheckText,
      format: yaml['format'] as String?,
      textRequired: yaml['text-required'] as bool?,
      minTextLength: yaml['min-text-length'] as int?,
      maxTextLength: yaml['max-text-length'] as int?,
      description: yaml['description'] as String?,
      allowedTags: allowedTags,
      validationPrompt: yaml['validation-prompt'] as String?,
      requiredFields: requiredFields,
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      if (prefix != null) 'prefix': prefix,
      if (maxCountInDocument != null)
        'max-count-in-document': maxCountInDocument,
      if (maxSubsectionLevels != null)
        'max-subsection-levels': maxSubsectionLevels,
      if (subsectionTypes != null)
        'subsection-types': {
          for (final entry in subsectionTypes!.entries)
            entry.key: entry.value.toYaml(),
        },
      if (patternCheckId != null) 'pattern-check-id': patternCheckId!.toYaml(),
      if (patternCheckText != null)
        'pattern-check-text': patternCheckText!.toYaml(),
      if (format != null) 'format': format,
      if (textRequired != null) 'text-required': textRequired,
      if (minTextLength != null) 'min-text-length': minTextLength,
      if (maxTextLength != null) 'max-text-length': maxTextLength,
      if (description != null) 'description': description,
      if (allowedTags != null) 'allowed-tags': allowedTags,
      if (validationPrompt != null) 'validation-prompt': validationPrompt,
      if (requiredFields != null) 'required-fields': requiredFields,
    };
  }
}
