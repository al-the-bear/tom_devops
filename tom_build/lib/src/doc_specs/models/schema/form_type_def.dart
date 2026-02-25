import 'section_type_def.dart';

/// Definition for a form field.
class FormFieldDef {
  /// Field name (used as "Fieldname: value" in text).
  final String fieldname;

  /// Whether field must be present (default: false).
  final bool? required;

  /// Optional pattern validation for field value.
  final PatternCheckDef? patternCheck;

  /// Creates a new FormFieldDef.
  const FormFieldDef({
    required this.fieldname,
    this.required,
    this.patternCheck,
  });

  /// Creates a FormFieldDef from a YAML map.
  factory FormFieldDef.fromYaml(Map<String, dynamic> yaml) {
    PatternCheckDef? patternCheck;
    if (yaml['pattern-check'] != null) {
      patternCheck =
          PatternCheckDef.fromYaml(yaml['pattern-check'] as Map<String, dynamic>);
    }

    return FormFieldDef(
      fieldname: yaml['fieldname'] as String,
      required: yaml['required'] as bool?,
      patternCheck: patternCheck,
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      'fieldname': fieldname,
      if (required != null) 'required': required,
      if (patternCheck != null) 'pattern-check': patternCheck!.toYaml(),
    };
  }
}

/// Definition for a form type.
class FormTypeDef {
  /// Form type name (key in form-types).
  final String name;

  /// List of field definitions.
  final List<FormFieldDef> fields;

  /// Creates a new FormTypeDef.
  const FormTypeDef({
    required this.name,
    required this.fields,
  });

  /// Creates a FormTypeDef from a YAML map.
  factory FormTypeDef.fromYaml(String name, Map<String, dynamic> yaml) {
    final fieldsYaml = yaml['fields'] as List?;
    final fields = <FormFieldDef>[];

    if (fieldsYaml != null) {
      for (final fieldYaml in fieldsYaml) {
        fields.add(FormFieldDef.fromYaml(fieldYaml as Map<String, dynamic>));
      }
    }

    return FormTypeDef(
      name: name,
      fields: fields,
    );
  }

  /// Converts to a YAML-compatible map.
  Map<String, dynamic> toYaml() {
    return {
      'fields': fields.map((f) => f.toYaml()).toList(),
    };
  }
}
