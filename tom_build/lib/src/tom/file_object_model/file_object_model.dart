/// Tom File Structure Model
///
/// Classes representing the Object Model for tom_workspace.yaml,
/// tom_project.yaml, and tom_master.yaml files.
library;

import 'dart:io';
import 'package:yaml/yaml.dart';

// =============================================================================
// YAML Loading Utilities
// =============================================================================

/// Loads a YAML file and returns it as a clean Map.
Map<String, dynamic> loadYamlFile(String path) {
  final content = File(path).readAsStringSync();
  final yamlData = loadYaml(content);
  return makeCleanMap(yamlData);
}

/// Converts a YamlMap to a regular Map<String, dynamic>.
Map<String, dynamic> makeCleanMap(dynamic data) {
  if (data == null) return {};
  if (data is! Map) return {};

  final result = <String, dynamic>{};
  for (final entry in data.entries) {
    final key = entry.key.toString();
    result[key] = _cleanValue(entry.value);
  }
  return result;
}

/// Cleans a value for JSON/YAML serialization.
dynamic _cleanValue(dynamic value) {
  if (value == null) return null;
  if (value is Map) return makeCleanMap(value);
  if (value is List) return value.map(_cleanValue).toList();
  if (value is YamlList) return value.map(_cleanValue).toList();
  return value;
}

/// Converts a Map to YAML string.
String toYamlString(Map<String, dynamic> data, {int indent = 0}) {
  final buffer = StringBuffer();
  _writeYaml(buffer, data, indent);
  return buffer.toString();
}

void _writeYaml(StringBuffer buffer, dynamic value, int indent) {
  final prefix = '  ' * indent;

  if (value == null) {
    buffer.writeln('null');
  } else if (value is Map) {
    if (value.isEmpty) {
      buffer.writeln('{}');
    } else {
      for (final entry in value.entries) {
        buffer.write('$prefix${entry.key}:');
        if (entry.value is Map && (entry.value as Map).isNotEmpty) {
          buffer.writeln();
          _writeYaml(buffer, entry.value, indent + 1);
        } else if (entry.value is List && (entry.value as List).isNotEmpty) {
          buffer.writeln();
          _writeYaml(buffer, entry.value, indent + 1);
        } else if (entry.value == null) {
          buffer.writeln(' null');
        } else if (entry.value is String) {
          final str = entry.value as String;
          if (str.contains('\n')) {
            buffer.writeln(' |');
            for (final line in str.split('\n')) {
              buffer.writeln('$prefix  $line');
            }
          } else if (str.contains(':') ||
              str.contains('#') ||
              str.startsWith('[') ||
              str.startsWith('{') ||
              str.startsWith('"') ||
              str.startsWith("'")) {
            // Escape double quotes
            final escaped = str.replaceAll('"', r'\"');
            buffer.writeln(' "$escaped"');
          } else if (str.isEmpty || str.trim() != str) {
            buffer.writeln(' "$str"');
          } else {
            buffer.writeln(' $str');
          }
        } else {
          buffer.writeln(' ${entry.value}');
        }
      }
    }
  } else if (value is List) {
    if (value.isEmpty) {
      buffer.writeln('[]');
    } else {
      for (final item in value) {
        if (item is Map) {
          // Check if any value in the map contains newlines - if so, use block style
          final hasMultilineValue = item.values.any((v) => v is String && v.contains('\n'));
          
          // DEBUG: Print detection
          // print('DEBUG: Map item with ${item.keys.first}, hasMultiline=$hasMultilineValue');
          
          if (hasMultilineValue) {
            // Write as block-style map on same line as dash
            for (final entry in item.entries) {
              buffer.write('$prefix- ${entry.key}:');
              if (entry.value is String) {
                final str = entry.value as String;
                if (str.contains('\n')) {
                  buffer.writeln(' |');
                  for (final line in str.split('\n')) {
                    buffer.writeln('$prefix    $line');
                  }
                } else {
                  buffer.writeln(' $str');
                }
              } else if (entry.value is Map || entry.value is List) {
                buffer.writeln();
                _writeYaml(buffer, entry.value, indent + 2);
              } else {
                buffer.writeln(' ${entry.value}');
              }
            }
          } else {
            // Original behavior for maps without multiline values
            buffer.writeln('$prefix-');
            for (final entry in item.entries) {
              buffer.write('$prefix  ${entry.key}:');
              if (entry.value is Map || entry.value is List) {
                buffer.writeln();
                _writeYaml(buffer, entry.value, indent + 2);
              } else {
                // Handle string in map in list
                if (entry.value is String) {
                  final str = entry.value as String;
                  if (str.contains('\n')) {
                    buffer.writeln(' |');
                     for (final line in str.split('\n')) {
                      buffer.writeln('$prefix    $line');
                    }
                  } else if (str.contains(':') || str.contains('#') || str.startsWith('[') || str.startsWith('{')) {
                     final escaped = str.replaceAll('"', r'\"');
                     buffer.writeln(' "$escaped"');
                  } else {
                     buffer.writeln(' $str');
                  }
                } else {
                   buffer.writeln(' ${entry.value}');
                }
              }
            }
          }
        } else if (item is String) {
           final str = item;
            if (str.contains('\n')) {
              buffer.writeln('$prefix- |');
              for (final line in str.split('\n')) {
                 if (line.isNotEmpty) {
                    buffer.writeln('$prefix  $line');
                 } else {
                    buffer.writeln(); // Keep empty lines
                 }
              }
            } else {
               if (str.contains(':') || str.contains('#') || str.startsWith('[') || str.startsWith('{')) {
                   final escaped = str.replaceAll('"', r'\"');
                   buffer.writeln('$prefix- "$escaped"');
               } else {
                   buffer.writeln('$prefix- $str');
               }
            }
        } else {
          buffer.writeln('$prefix- $item');
        }
      }
    }
  } else {
    buffer.writeln(value);
  }
}


// =============================================================================
// CORE TYPES
// =============================================================================

/// Base type for workspace configuration (used in tom_workspace.yaml).
class TomWorkspace {
  final String? name;
  final String? binaries;
  final List<String>? operatingSystems;
  final List<String>? mobilePlatforms;
  final List<String>? imports;
  final WorkspaceModes? workspaceModes;
  final CrossCompilation? crossCompilation;
  final Map<String, GroupDef> groups;
  final Map<String, ProjectTypeDef> projectTypes;
  final Map<String, ActionDef> actions;
  final Map<String, ModeDefinitions> modeDefinitions;
  final Map<String, Pipeline> pipelines;
  final Map<String, ProjectEntry> projectInfo;
  final Map<String, String> deps;
  final Map<String, String> depsDev;
  final VersionSettings? versionSettings;
  final Map<String, dynamic> customTags;

  TomWorkspace({
    this.name,
    this.binaries,
    this.operatingSystems,
    this.mobilePlatforms,
    this.imports,
    this.workspaceModes,
    this.crossCompilation,
    this.groups = const {},
    this.projectTypes = const {},
    this.actions = const {},
    this.modeDefinitions = const {},
    this.pipelines = const {},
    this.projectInfo = const {},
    this.deps = const {},
    this.depsDev = const {},
    this.versionSettings,
    this.customTags = const {},
  });

  factory TomWorkspace.fromYaml(Map<String, dynamic> yaml) {
    // Known keys to extract
    final knownKeys = {
      'name',
      'binaries',
      'operating-systems',
      'mobile-platforms',
      'imports',
      'workspace-modes',
      'cross-compilation',
      'groups',
      'project-types',
      'actions',
      'pipelines',
      'project-info',
      'deps',
      'deps-dev',
      'version-settings',
    };

    // Mode definition keys
    final modeDefKeys = <String>{};
    for (final key in yaml.keys) {
      if (key.toString().endsWith('-mode-definitions')) {
        modeDefKeys.add(key.toString());
      }
    }

    // Custom tags are everything else
    final customTags = <String, dynamic>{};
    for (final entry in yaml.entries) {
      final key = entry.key.toString();
      if (!knownKeys.contains(key) && !modeDefKeys.contains(key)) {
        customTags[key] = entry.value;
      }
    }

    // Parse mode definitions
    final modeDefinitions = <String, ModeDefinitions>{};
    for (final key in modeDefKeys) {
      final modeType = key.replaceAll('-mode-definitions', '');
      modeDefinitions[modeType] = ModeDefinitions.fromYaml(
        yaml[key] as Map<String, dynamic>? ?? {},
      );
    }

    return TomWorkspace(
      name: yaml['name'] as String?,
      binaries: yaml['binaries'] as String?,
      operatingSystems: _parseStringList(yaml['operating-systems']),
      mobilePlatforms: _parseStringList(yaml['mobile-platforms']),
      imports: _parseStringList(yaml['imports']),
      workspaceModes: yaml['workspace-modes'] != null
          ? WorkspaceModes.fromYaml(yaml['workspace-modes'] as Map<String, dynamic>)
          : null,
      crossCompilation: yaml['cross-compilation'] != null
          ? CrossCompilation.fromYaml(yaml['cross-compilation'] as Map<String, dynamic>)
          : null,
      groups: _parseMap(yaml['groups'], (k, v) => GroupDef.fromYaml(k, v)),
      projectTypes: _parseMap(yaml['project-types'], (k, v) => ProjectTypeDef.fromYaml(k, v)),
      actions: _parseMap(yaml['actions'], (k, v) => ActionDef.fromYaml(k, v)),
      modeDefinitions: modeDefinitions,
      pipelines: _parseMap(yaml['pipelines'], (k, v) => Pipeline.fromYaml(k, v)),
      projectInfo: _parseMap(yaml['project-info'], (k, v) => ProjectEntry.fromYaml(k, v)),
      deps: _parseStringMap(yaml['deps']),
      depsDev: _parseStringMap(yaml['deps-dev']),
      versionSettings: yaml['version-settings'] != null
          ? VersionSettings.fromYaml(yaml['version-settings'] as Map<String, dynamic>)
          : null,
      customTags: customTags,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    if (name != null) result['name'] = name;
    if (binaries != null) result['binaries'] = binaries;
    if (operatingSystems != null) result['operating-systems'] = operatingSystems;
    if (mobilePlatforms != null) result['mobile-platforms'] = mobilePlatforms;
    if (imports != null) result['imports'] = imports;
    if (projectTypes.isNotEmpty) {
      result['project-types'] = projectTypes.map((k, v) => MapEntry(k, v.toYaml()));
    }
    if (workspaceModes != null) result['workspace-modes'] = workspaceModes!.toYaml();
    if (crossCompilation != null) result['cross-compilation'] = crossCompilation!.toYaml();
    if (actions.isNotEmpty) {
      result['actions'] = actions.map((k, v) => MapEntry(k, v.toYaml()));
    }
    if (groups.isNotEmpty) {
      result['groups'] = groups.map((k, v) => MapEntry(k, v.toYaml()));
    }

    // Mode definitions
    for (final entry in modeDefinitions.entries) {
      result['${entry.key}-mode-definitions'] = entry.value.toYaml();
    }

    if (pipelines.isNotEmpty) {
      result['pipelines'] = pipelines.map((k, v) => MapEntry(k, v.toYaml()));
    }
    if (projectInfo.isNotEmpty) {
      result['project-info'] = projectInfo.map((k, v) => MapEntry(k, v.toYaml()));
    }
    if (deps.isNotEmpty) result['deps'] = deps;
    if (depsDev.isNotEmpty) result['deps-dev'] = depsDev;
    if (versionSettings != null) result['version-settings'] = versionSettings!.toYaml();

    // Custom tags
    result.addAll(customTags);

    return result;
  }
}

/// The root type for tom_master*.yaml files. Extends TomWorkspace with computed fields.
class TomMaster extends TomWorkspace {
  final String? scanTimestamp;
  final Map<String, TomProject> projects;
  final List<String> buildOrder;
  final Map<String, List<String>> actionOrder;

  TomMaster({
    super.name,
    super.binaries,
    super.operatingSystems,
    super.mobilePlatforms,
    super.imports,
    super.workspaceModes,
    super.crossCompilation,
    super.groups,
    super.projectTypes,
    super.actions,
    super.modeDefinitions,
    super.pipelines,
    super.projectInfo,
    super.deps,
    super.depsDev,
    super.versionSettings,
    super.customTags,
    this.scanTimestamp,
    this.projects = const {},
    this.buildOrder = const [],
    this.actionOrder = const {},
  });

  factory TomMaster.fromYaml(Map<String, dynamic> yaml) {
    // First, parse as TomWorkspace
    final workspace = TomWorkspace.fromYaml(yaml);

    // Parse computed fields
    final projects = _parseMap(
      yaml['projects'],
      (k, v) => TomProject.fromYaml(k, v, defaultActions: workspace.actions),
    );

    final buildOrder = _parseStringList(yaml['build-order']) ?? [];

    final actionOrder = <String, List<String>>{};
    if (yaml['action-order'] is Map) {
      for (final entry in (yaml['action-order'] as Map).entries) {
        actionOrder[entry.key.toString()] = _parseStringList(entry.value) ?? [];
      }
    }

    // Remove computed fields from customTags
    final customTags = Map<String, dynamic>.from(workspace.customTags);
    customTags.remove('scan-timestamp');
    customTags.remove('projects');
    customTags.remove('build-order');
    customTags.remove('action-order');

    return TomMaster(
      name: workspace.name,
      binaries: workspace.binaries,
      operatingSystems: workspace.operatingSystems,
      mobilePlatforms: workspace.mobilePlatforms,
      imports: workspace.imports,
      workspaceModes: workspace.workspaceModes,
      crossCompilation: workspace.crossCompilation,
      groups: workspace.groups,
      projectTypes: workspace.projectTypes,
      actions: workspace.actions,
      modeDefinitions: workspace.modeDefinitions,
      pipelines: workspace.pipelines,
      projectInfo: workspace.projectInfo,
      deps: workspace.deps,
      depsDev: workspace.depsDev,
      versionSettings: workspace.versionSettings,
      customTags: customTags,
      scanTimestamp: yaml['scan-timestamp'] as String?,
      projects: projects,
      buildOrder: buildOrder,
      actionOrder: actionOrder,
    );
  }

  @override
  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    if (scanTimestamp != null) result['scan-timestamp'] = scanTimestamp;

    // Add workspace fields
    final workspaceYaml = super.toYaml();

    // Insert workspace fields after scan-timestamp
    for (final entry in workspaceYaml.entries) {
      result[entry.key] = entry.value;
    }

    // Add computed fields
    if (buildOrder.isNotEmpty) result['build-order'] = buildOrder;
    if (actionOrder.isNotEmpty) result['action-order'] = actionOrder;
    if (projects.isNotEmpty) {
      // Use toYamlCompact to exclude sections identical to workspace-level
      result['projects'] = projects.map((k, v) => MapEntry(
        k,
        v.toYamlCompact(
          workspaceCrossCompilation: crossCompilation,
          workspaceModeDefinitions: modeDefinitions,
          workspaceActions: actions,
        ),
      ));
    }

    return result;
  }
}

/// Project configuration from tom_project.yaml.
class TomProject {
  final String name;
  final String? type;
  final String? description;
  final String? binaries;
  final List<String> buildAfter;
  final Map<String, List<String>> actionOrder;
  final Features? features;
  final Map<String, ActionDef> actions;
  final Map<String, ModeDefinitions> modeDefinitions;
  final CrossCompilation? crossCompilation;
  final PackageModule? packageModule;
  final Map<String, Part> parts;
  final List<String>? tests;
  final List<String>? examples;
  final List<String>? docs;
  final List<String>? copilotGuidelines;
  final List<String>? binaryFiles;
  final List<ExecutableDef> executables;
  final Map<String, dynamic> metadataFiles;
  final Map<String, dynamic>? actionModeDefinitions;
  final Map<String, dynamic> customTags;

  TomProject({
    required this.name,
    this.type,
    this.description,
    this.binaries,
    this.buildAfter = const [],
    this.actionOrder = const {},
    this.features,
    this.actions = const {},
    this.modeDefinitions = const {},
    this.crossCompilation,
    this.packageModule,
    this.parts = const {},
    this.tests,
    this.examples,
    this.docs,
    this.copilotGuidelines,
    this.binaryFiles,
    this.executables = const [],
    this.metadataFiles = const {},
    this.actionModeDefinitions,
    this.customTags = const {},
  });

  factory TomProject.fromYaml(String name, Map<String, dynamic> yaml, {Map<String, ActionDef>? defaultActions}) {
    // Known keys
    final knownKeys = {
      'name',
      'type',
      'description',
      'binaries',
      'build-after',
      'action-order',
      'features',
      'actions',
      'cross-compilation',
      'package-module',
      'parts',
      'tests',
      'examples',
      'docs',
      'copilot-guidelines',
      'executables',
      'action-mode-definitions',
    };

    // Mode definition keys
    final modeDefKeys = <String>{};
    for (final key in yaml.keys) {
      if (key.toString().endsWith('-mode-definitions') &&
          key.toString() != 'action-mode-definitions') {
        modeDefKeys.add(key.toString());
      }
    }

    // Metadata file keys (like pubspec-yaml, package-json)
    final metadataFileKeys = <String>{};
    for (final key in yaml.keys) {
      final keyStr = key.toString();
      if (keyStr.endsWith('-yaml') || keyStr.endsWith('-json')) {
        metadataFileKeys.add(keyStr);
      }
    }

    // Custom tags
    final customTags = <String, dynamic>{};
    for (final entry in yaml.entries) {
      final key = entry.key.toString();
      if (!knownKeys.contains(key) &&
          !modeDefKeys.contains(key) &&
          !metadataFileKeys.contains(key)) {
        customTags[key] = entry.value;
      }
    }

    // Parse mode definitions
    final modeDefinitions = <String, ModeDefinitions>{};
    for (final key in modeDefKeys) {
      final modeType = key.replaceAll('-mode-definitions', '');
      modeDefinitions[modeType] = ModeDefinitions.fromYaml(
        yaml[key] as Map<String, dynamic>? ?? {},
      );
    }

    // Parse metadata files
    final metadataFiles = <String, dynamic>{};
    for (final key in metadataFileKeys) {
      metadataFiles[key] = yaml[key];
    }

    // Parse action order
    final actionOrder = <String, List<String>>{};
    if (yaml['action-order'] is Map) {
      for (final entry in (yaml['action-order'] as Map).entries) {
        actionOrder[entry.key.toString()] = _parseStringList(entry.value) ?? [];
      }
    }

    // Parse actions with fallback to defaults
    final parsedActions = _parseMap(yaml['actions'], (k, v) => ActionDef.fromYaml(k, v));
    final effectiveActions = parsedActions.isEmpty && defaultActions != null 
        ? defaultActions 
        : parsedActions;

    return TomProject(
      name: yaml['name'] as String? ?? name,
      type: yaml['type'] as String?,
      description: yaml['description'] as String?,
      binaries: yaml['binaries'] as String?,
      buildAfter: _parseStringList(yaml['build-after']) ?? [],
      actionOrder: actionOrder,
      features: yaml['features'] != null
          ? Features.fromYaml(yaml['features'] as Map<String, dynamic>)
          : null,
      actions: effectiveActions,
      modeDefinitions: modeDefinitions,
      crossCompilation: yaml['cross-compilation'] != null
          ? CrossCompilation.fromYaml(yaml['cross-compilation'] as Map<String, dynamic>)
          : null,
      packageModule: yaml['package-module'] != null
          ? PackageModule.fromYaml(yaml['package-module'] as Map<String, dynamic>)
          : null,
      parts: _parseMap(yaml['parts'], (k, v) => Part.fromYaml(k, v)),
      tests: _parseStringList(yaml['tests']),
      examples: _parseStringList(yaml['examples']),
      docs: _parseStringList(yaml['docs']),
      copilotGuidelines: _parseStringList(yaml['copilot-guidelines']),
      binaryFiles: _parseStringList(yaml['binary-files']),
      executables: _parseExecutables(yaml['executables']),
      metadataFiles: metadataFiles,
      actionModeDefinitions: yaml['action-mode-definitions'] as Map<String, dynamic>?,
      customTags: customTags,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    result['name'] = name;
    if (type != null) result['type'] = type;
    if (description != null) result['description'] = description;
    if (buildAfter.isNotEmpty) result['build-after'] = buildAfter;
    if (actionOrder.isNotEmpty) result['action-order'] = actionOrder;
    if (features != null) result['features'] = features!.toYaml();

    // Mode definitions
    for (final entry in modeDefinitions.entries) {
      result['${entry.key}-mode-definitions'] = entry.value.toYaml();
    }

    if (crossCompilation != null) result['cross-compilation'] = crossCompilation!.toYaml();
    if (actions.isNotEmpty) {
      result['actions'] = actions.map((k, v) => MapEntry(k, v.toYaml()));
    }
    if (packageModule != null) result['package-module'] = packageModule!.toYaml();
    if (parts.isNotEmpty) {
      result['parts'] = parts.map((k, v) => MapEntry(k, v.toYaml()));
    }
    if (tests != null && tests!.isNotEmpty) result['tests'] = tests;
    if (examples != null && examples!.isNotEmpty) result['examples'] = examples;
    if (docs != null && docs!.isNotEmpty) result['docs'] = docs;
    if (copilotGuidelines != null && copilotGuidelines!.isNotEmpty) {
      result['copilot-guidelines'] = copilotGuidelines;
    }
    if (binaries != null) result['binaries'] = binaries;
    if (binaryFiles != null && binaryFiles!.isNotEmpty) {
      result['binary-files'] = binaryFiles;
    }

    // Metadata files
    result.addAll(metadataFiles);

    if (executables.isNotEmpty) {
      result['executables'] = executables.map((e) => e.toYaml()).toList();
    }
    if (actionModeDefinitions != null) {
      result['action-mode-definitions'] = actionModeDefinitions;
    }

    // Custom tags
    result.addAll(customTags);

    return result;
  }

  /// Generates YAML output, excluding sections identical to workspace-level definitions.
  ///
  /// This produces a compact output where:
  /// - `cross-compilation` is only included if different from [workspaceCrossCompilation]
  /// - `<mode-type>-mode-definitions` are only included if different from [workspaceModeDefinitions]
  /// - `actions` is only included if different from [workspaceActions]
  ///
  /// Use this method when generating tom_master.yaml to avoid redundant data.
  Map<String, dynamic> toYamlCompact({
    CrossCompilation? workspaceCrossCompilation,
    Map<String, ModeDefinitions>? workspaceModeDefinitions,
    Map<String, ActionDef>? workspaceActions,
  }) {
    final result = <String, dynamic>{};

    result['name'] = name;
    if (type != null) result['type'] = type;
    if (description != null) result['description'] = description;
    if (buildAfter.isNotEmpty) result['build-after'] = buildAfter;
    if (actionOrder.isNotEmpty) result['action-order'] = actionOrder;
    if (features != null) result['features'] = features!.toYaml();

    // Mode definitions - only include if different from workspace
    for (final entry in modeDefinitions.entries) {
      final modeType = entry.key;
      final projectModeDefs = entry.value;
      final workspaceModeDefs = workspaceModeDefinitions?[modeType];

      if (!_areModeDefinitionsEqual(projectModeDefs, workspaceModeDefs)) {
        result['$modeType-mode-definitions'] = projectModeDefs.toYaml();
      }
    }

    // Cross-compilation - only include if different from workspace
    if (crossCompilation != null) {
      if (!_areCrossCompilationsEqual(crossCompilation, workspaceCrossCompilation)) {
        result['cross-compilation'] = crossCompilation!.toYaml();
      }
    }

    // Actions - only include if different from workspace
    if (actions.isNotEmpty) {
      if (!_areActionsEqual(actions, workspaceActions ?? {})) {
        result['actions'] = actions.map((k, v) => MapEntry(k, v.toYaml()));
      }
    }

    if (packageModule != null) result['package-module'] = packageModule!.toYaml();
    if (parts.isNotEmpty) {
      result['parts'] = parts.map((k, v) => MapEntry(k, v.toYaml()));
    }
    if (tests != null && tests!.isNotEmpty) result['tests'] = tests;
    if (examples != null && examples!.isNotEmpty) result['examples'] = examples;
    if (docs != null && docs!.isNotEmpty) result['docs'] = docs;
    if (copilotGuidelines != null && copilotGuidelines!.isNotEmpty) {
      result['copilot-guidelines'] = copilotGuidelines;
    }
    if (binaries != null) result['binaries'] = binaries;
    if (binaryFiles != null && binaryFiles!.isNotEmpty) {
      result['binary-files'] = binaryFiles;
    }

    // Metadata files
    result.addAll(metadataFiles);

    if (executables.isNotEmpty) {
      result['executables'] = executables.map((e) => e.toYaml()).toList();
    }
    if (actionModeDefinitions != null) {
      result['action-mode-definitions'] = actionModeDefinitions;
    }

    // Custom tags
    result.addAll(customTags);

    return result;
  }

  /// Compares two ModeDefinitions for equality.
  bool _areModeDefinitionsEqual(ModeDefinitions? a, ModeDefinitions? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    final aYaml = a.toYaml();
    final bYaml = b.toYaml();
    return _deepEquals(aYaml, bYaml);
  }

  /// Compares two CrossCompilation objects for equality.
  bool _areCrossCompilationsEqual(CrossCompilation? a, CrossCompilation? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    final aYaml = a.toYaml();
    final bYaml = b.toYaml();
    return _deepEquals(aYaml, bYaml);
  }

  /// Compares two action maps for equality.
  bool _areActionsEqual(Map<String, ActionDef> a, Map<String, ActionDef> b) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      final aYaml = a[key]!.toYaml();
      final bYaml = b[key]!.toYaml();
      if (!_deepEquals(aYaml, bYaml)) return false;
    }

    return true;
  }

  /// Deep equality comparison for YAML-like structures.
  bool _deepEquals(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_deepEquals(a[key], b[key])) return false;
      }
      return true;
    } else if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    } else {
      return a == b;
    }
  }
}

// =============================================================================
// CONFIGURATION TYPES
// =============================================================================

/// Workspace modes configuration.
class WorkspaceModes {
  final List<String> modeTypes;
  final List<SupportedMode> supported;
  final Map<String, ModeTypeConfig> modeTypeConfigs;
  final ActionModeConfiguration? actionModeConfiguration;
  final String? defaultMode;

  /// Alias for [supported] for backward compatibility.
  List<SupportedMode> get supportedModes => supported;

  WorkspaceModes({
    this.modeTypes = const [],
    this.supported = const [],
    this.modeTypeConfigs = const {},
    this.actionModeConfiguration,
    this.defaultMode,
  });

  factory WorkspaceModes.fromYaml(Map<String, dynamic> yaml) {
    final modeTypes = _parseStringList(yaml['mode-types']) ?? [];

    final supported = <SupportedMode>[];
    if (yaml['supported'] is List) {
      for (final item in yaml['supported'] as List) {
        if (item is Map) {
          supported.add(SupportedMode.fromYaml(makeCleanMap(item)));
        }
      }
    }

    // Parse mode type configs (e.g., environment-modes, execution-modes)
    final modeTypeConfigs = <String, ModeTypeConfig>{};
    for (final entry in yaml.entries) {
      final key = entry.key.toString();
      if (key.endsWith('-modes') && key != 'mode-types') {
        final modeType = key.replaceAll('-modes', '');
        if (entry.value is Map) {
          modeTypeConfigs[modeType] = ModeTypeConfig.fromYaml(
            makeCleanMap(entry.value),
          );
        }
      }
    }

    return WorkspaceModes(
      modeTypes: modeTypes,
      supported: supported,
      modeTypeConfigs: modeTypeConfigs,
      defaultMode: yaml['default'] as String?,
      actionModeConfiguration: yaml['action-mode-configuration'] != null
          ? ActionModeConfiguration.fromYaml(
              yaml['action-mode-configuration'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    if (modeTypes.isNotEmpty) result['mode-types'] = modeTypes;
    if (supported.isNotEmpty) {
      result['supported'] = supported.map((s) => s.toYaml()).toList();
    }

    // Mode type configs
    for (final entry in modeTypeConfigs.entries) {
      result['${entry.key}-modes'] = entry.value.toYaml();
    }

    if (actionModeConfiguration != null) {
      result['action-mode-configuration'] = actionModeConfiguration!.toYaml();
    }

    return result;
  }
}

/// A supported mode.
class SupportedMode {
  final String name;
  final String? description;
  final List<String> implies;

  SupportedMode({
    required this.name,
    this.description,
    this.implies = const [],
  });

  factory SupportedMode.fromYaml(Map<String, dynamic> yaml) {
    return SupportedMode(
      name: yaml['name'] as String? ?? '',
      description: yaml['description'] as String?,
      implies: _parseStringList(yaml['implies']) ?? [],
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{'name': name};
    if (description != null) result['description'] = description;
    if (implies.isNotEmpty) result['implies'] = implies;
    return result;
  }
}

/// Configuration for a mode type (e.g., environment-modes).
class ModeTypeConfig {
  final String? defaultMode;
  final Map<String, ModeEntry> entries;

  ModeTypeConfig({
    this.defaultMode,
    this.entries = const {},
  });

  factory ModeTypeConfig.fromYaml(Map<String, dynamic> yaml) {
    final entries = <String, ModeEntry>{};
    for (final entry in yaml.entries) {
      if (entry.key != 'default' && entry.value is Map) {
        entries[entry.key.toString()] = ModeEntry.fromYaml(
          makeCleanMap(entry.value),
        );
      }
    }

    return ModeTypeConfig(
      defaultMode: yaml['default'] as String?,
      entries: entries,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};
    if (defaultMode != null) result['default'] = defaultMode;
    for (final entry in entries.entries) {
      result[entry.key] = entry.value.toYaml();
    }
    return result;
  }
}

/// An entry in a mode type configuration.
class ModeEntry {
  final String? description;
  final List<String> modes;
  final Map<String, dynamic> properties;

  ModeEntry({
    this.description,
    this.modes = const [],
    this.properties = const {},
  });

  factory ModeEntry.fromYaml(Map<String, dynamic> yaml) {
    final properties = Map<String, dynamic>.from(yaml);
    properties.remove('description');
    properties.remove('modes');

    return ModeEntry(
      description: yaml['description'] as String?,
      modes: _parseStringList(yaml['modes']) ?? [],
      properties: properties,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};
    if (description != null) result['description'] = description;
    if (modes.isNotEmpty) result['modes'] = modes;
    result.addAll(properties);
    return result;
  }
}

/// Action mode configuration.
class ActionModeConfiguration {
  final Map<String, ActionModeEntry> entries;

  ActionModeConfiguration({this.entries = const {}});

  factory ActionModeConfiguration.fromYaml(Map<String, dynamic> yaml) {
    final entries = <String, ActionModeEntry>{};
    for (final entry in yaml.entries) {
      if (entry.value is Map) {
        entries[entry.key.toString()] = ActionModeEntry.fromYaml(
          makeCleanMap(entry.value),
        );
      }
    }
    return ActionModeConfiguration(entries: entries);
  }

  Map<String, dynamic> toYaml() {
    return entries.map((k, v) => MapEntry(k, v.toYaml()));
  }
}

/// An entry in action mode configuration.
class ActionModeEntry {
  final String? description;
  final Map<String, String> modes;

  ActionModeEntry({
    this.description,
    this.modes = const {},
  });

  factory ActionModeEntry.fromYaml(Map<String, dynamic> yaml) {
    final modes = <String, String>{};
    for (final entry in yaml.entries) {
      if (entry.key != 'description' && entry.value is String) {
        modes[entry.key.toString()] = entry.value as String;
      }
    }
    return ActionModeEntry(
      description: yaml['description'] as String?,
      modes: modes,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};
    if (description != null) result['description'] = description;
    result.addAll(modes);
    return result;
  }
}

/// Mode definitions for a mode type.
class ModeDefinitions {
  final Map<String, ModeDef> definitions;

  ModeDefinitions({this.definitions = const {}});

  factory ModeDefinitions.fromYaml(Map<String, dynamic> yaml) {
    final definitions = <String, ModeDef>{};
    for (final entry in yaml.entries) {
      if (entry.value is Map) {
        definitions[entry.key.toString()] = ModeDef.fromYaml(
          entry.key.toString(),
          makeCleanMap(entry.value),
        );
      }
    }
    return ModeDefinitions(definitions: definitions);
  }

  Map<String, dynamic> toYaml() {
    return definitions.map((k, v) => MapEntry(k, v.toYaml()));
  }
}

/// A mode definition.
class ModeDef {
  final String name;
  final String? description;
  final Map<String, dynamic> properties;

  ModeDef({
    required this.name,
    this.description,
    this.properties = const {},
  });

  factory ModeDef.fromYaml(String name, Map<String, dynamic> yaml) {
    final properties = Map<String, dynamic>.from(yaml);
    properties.remove('description');

    return ModeDef(
      name: name,
      description: yaml['description'] as String?,
      properties: properties,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};
    if (description != null) result['description'] = description;
    result.addAll(properties);
    return result;
  }
}

/// Action definition.
class ActionDef {
  final String name;
  final String? description;
  final List<String>? skipTypes;
  final List<String>? appliesToTypes;
  final ActionConfig? defaultConfig;
  final Map<String, ActionConfig> typeConfigs;

  ActionDef({
    required this.name,
    this.description,
    this.skipTypes,
    this.appliesToTypes,
    this.defaultConfig,
    this.typeConfigs = const {},
  });

  factory ActionDef.fromYaml(String name, Map<String, dynamic> yaml) {
    final typeConfigs = <String, ActionConfig>{};

    for (final entry in yaml.entries) {
      final key = entry.key.toString();
      if (key != 'name' &&
          key != 'description' &&
          key != 'skip-types' &&
          key != 'applies-to-types' &&
          key != 'default' &&
          entry.value is Map) {
        typeConfigs[key] = ActionConfig.fromYaml(makeCleanMap(entry.value));
      }
    }

    return ActionDef(
      name: yaml['name'] as String? ?? name,
      description: yaml['description'] as String?,
      skipTypes: _parseStringList(yaml['skip-types']),
      appliesToTypes: _parseStringList(yaml['applies-to-types']),
      defaultConfig: yaml['default'] != null
          ? ActionConfig.fromYaml(yaml['default'] as Map<String, dynamic>)
          : null,
      typeConfigs: typeConfigs,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    if (name.isNotEmpty) result['name'] = name;
    if (description != null) result['description'] = description;
    if (skipTypes != null && skipTypes!.isNotEmpty) result['skip-types'] = skipTypes;
    if (appliesToTypes != null && appliesToTypes!.isNotEmpty) {
      result['applies-to-types'] = appliesToTypes;
    }
    if (defaultConfig != null) result['default'] = defaultConfig!.toYaml();

    for (final entry in typeConfigs.entries) {
      result[entry.key] = entry.value.toYaml();
    }

    return result;
  }
}

/// Action configuration.
///
/// Commands are always strings. Command types are detected by prefix:
/// - `dartscript: <code>` - Execute D4rt code locally
/// - `vscode: <script.dart>` - Execute via VS Code bridge
/// - `tom: <:command>` - Execute Tom CLI internal command
/// - Other strings - Execute as shell command
///
/// For multiline dartscript commands in YAML, use block scalars:
/// ```yaml
/// commands:
///   - >
///     dartscript:
///     print("hello");
///     print("world");
/// ```
class ActionConfig {
  /// Pre-commands executed before main commands.
  /// Each command is a Map with one of: `shell`, `dartscript`, `vscode`, `tom` as key.
  /// Legacy string commands are also supported for backwards compatibility.
  final List<dynamic>? preCommands;

  /// Main commands for the action.
  /// Each command is a Map with one of: `shell`, `dartscript`, `vscode`, `tom` as key.
  /// Example: `{dartscript: 'print("hello")'}`
  /// Example: `{shell: 'dart pub get', sudo: true}`
  final List<dynamic> commands;

  /// Post-commands executed after main commands.
  final List<dynamic>? postCommands;

  final Map<String, dynamic> customTags;

  ActionConfig({
    this.preCommands,
    this.commands = const [],
    this.postCommands,
    this.customTags = const {},
  });

  factory ActionConfig.fromYaml(Map<String, dynamic> yaml) {
    final customTags = Map<String, dynamic>.from(yaml);
    customTags.remove('pre-commands');
    customTags.remove('commands');
    customTags.remove('post-commands');

    return ActionConfig(
      preCommands: _parseCommandList(yaml['pre-commands']),
      commands: _parseCommandList(yaml['commands']) ?? [],
      postCommands: _parseCommandList(yaml['post-commands']),
      customTags: customTags,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    if (preCommands != null && preCommands!.isNotEmpty) {
      result['pre-commands'] = preCommands;
    }
    if (commands.isNotEmpty) result['commands'] = commands;
    if (postCommands != null && postCommands!.isNotEmpty) {
      result['post-commands'] = postCommands;
    }
    result.addAll(customTags);

    return result;
  }
}

/// Group definition.
class GroupDef {
  final String name;
  final String? description;
  final List<String> projects;
  final Map<String, dynamic>? projectInfoOverrides;

  GroupDef({
    required this.name,
    this.description,
    this.projects = const [],
    this.projectInfoOverrides,
  });

  factory GroupDef.fromYaml(String name, Map<String, dynamic> yaml) {
    return GroupDef(
      name: yaml['name'] as String? ?? name,
      description: yaml['description'] as String?,
      projects: _parseStringList(yaml['projects']) ?? [],
      projectInfoOverrides: yaml['project-info-overrides'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    if (name.isNotEmpty) result['name'] = name;
    if (description != null) result['description'] = description;
    if (projects.isNotEmpty) result['projects'] = projects;
    if (projectInfoOverrides != null && projectInfoOverrides!.isNotEmpty) {
      result['project-info-overrides'] = projectInfoOverrides;
    }

    return result;
  }
}

/// Project type definition.
class ProjectTypeDef {
  final String name;
  final String? description;
  final Map<String, String> metadataFiles;
  final Map<String, dynamic>? projectInfoOverrides;

  ProjectTypeDef({
    required this.name,
    this.description,
    this.metadataFiles = const {},
    this.projectInfoOverrides,
  });

  factory ProjectTypeDef.fromYaml(String key, Map<String, dynamic> yaml) {
    return ProjectTypeDef(
      name: yaml['name'] as String? ?? key,
      description: yaml['description'] as String?,
      metadataFiles: _parseStringMap(yaml['metadata-files']),
      projectInfoOverrides: yaml['project-info-overrides'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    result['name'] = name;
    if (description != null) result['description'] = description;
    if (metadataFiles.isNotEmpty) result['metadata-files'] = metadataFiles;
    if (projectInfoOverrides != null && projectInfoOverrides!.isNotEmpty) {
      result['project-info-overrides'] = projectInfoOverrides;
    }

    return result;
  }
}

// =============================================================================
// PROJECT STRUCTURE TYPES
// =============================================================================

/// Features configuration.
class Features {
  final Map<String, bool> flags;

  Features({this.flags = const {}});

  factory Features.fromYaml(Map<String, dynamic> yaml) {
    final flags = <String, bool>{};
    for (final entry in yaml.entries) {
      if (entry.value is bool) {
        flags[entry.key.toString()] = entry.value as bool;
      }
    }
    return Features(flags: flags);
  }

  Map<String, dynamic> toYaml() => flags;

  bool operator [](String key) => flags[key] ?? false;
}

/// Cross-compilation configuration.
class CrossCompilation {
  final List<String> allTargets;
  final Map<String, BuildOnTarget> buildOn;

  CrossCompilation({
    this.allTargets = const [],
    this.buildOn = const {},
  });

  factory CrossCompilation.fromYaml(Map<String, dynamic> yaml) {
    final buildOn = <String, BuildOnTarget>{};
    if (yaml['build-on'] is Map) {
      for (final entry in (yaml['build-on'] as Map).entries) {
        if (entry.value is Map) {
          buildOn[entry.key.toString()] = BuildOnTarget.fromYaml(
            makeCleanMap(entry.value),
          );
        }
      }
    }

    return CrossCompilation(
      allTargets: _parseStringList(yaml['all-targets']) ?? [],
      buildOn: buildOn,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    if (allTargets.isNotEmpty) result['all-targets'] = allTargets;
    if (buildOn.isNotEmpty) {
      result['build-on'] = buildOn.map((k, v) => MapEntry(k, v.toYaml()));
    }

    return result;
  }
}

/// Build-on target configuration.
class BuildOnTarget {
  final List<String> targets;

  BuildOnTarget({this.targets = const []});

  factory BuildOnTarget.fromYaml(Map<String, dynamic> yaml) {
    return BuildOnTarget(
      targets: _parseStringList(yaml['targets']) ?? [],
    );
  }

  Map<String, dynamic> toYaml() {
    return {'targets': targets};
  }
}

/// Pipeline definition.
class Pipeline {
  final String name;
  final List<String>? globalParameters;
  final List<PipelineProject> projects;
  final List<PipelineAction> actions;

  Pipeline({
    required this.name,
    this.globalParameters,
    this.projects = const [],
    this.actions = const [],
  });

  factory Pipeline.fromYaml(String name, Map<String, dynamic> yaml) {
    final projects = <PipelineProject>[];
    if (yaml['projects'] is List) {
      for (final item in yaml['projects'] as List) {
        if (item is Map) {
          projects.add(PipelineProject.fromYaml(makeCleanMap(item)));
        }
      }
    }

    final actions = <PipelineAction>[];
    if (yaml['actions'] is List) {
      for (final item in yaml['actions'] as List) {
        if (item is Map) {
          actions.add(PipelineAction.fromYaml(makeCleanMap(item)));
        }
      }
    }

    return Pipeline(
      name: name,
      globalParameters: _parseStringList(yaml['global-parameters']),
      projects: projects,
      actions: actions,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    if (globalParameters != null && globalParameters!.isNotEmpty) {
      result['global-parameters'] = globalParameters;
    }
    if (projects.isNotEmpty) {
      result['projects'] = projects.map((p) => p.toYaml()).toList();
    }
    if (actions.isNotEmpty) {
      result['actions'] = actions.map((a) => a.toYaml()).toList();
    }

    return result;
  }
}

/// Pipeline project entry.
class PipelineProject {
  final String name;

  PipelineProject({required this.name});

  factory PipelineProject.fromYaml(Map<String, dynamic> yaml) {
    return PipelineProject(name: yaml['name'] as String? ?? '');
  }

  Map<String, dynamic> toYaml() => {'name': name};
}

/// Pipeline action entry.
class PipelineAction {
  final String action;

  PipelineAction({required this.action});

  factory PipelineAction.fromYaml(Map<String, dynamic> yaml) {
    return PipelineAction(action: yaml['action'] as String? ?? '');
  }

  Map<String, dynamic> toYaml() => {'action': action};
}

/// Project entry in the workspace configuration.
/// 
/// Note: This is different from `ProjectInfo` in workspace_analyzer.dart,
/// which contains comprehensive project metadata.
class ProjectEntry {
  final String name;
  final Map<String, dynamic> settings;

  ProjectEntry({
    required this.name,
    this.settings = const {},
  });

  factory ProjectEntry.fromYaml(String name, Map<String, dynamic> yaml) {
    return ProjectEntry(name: name, settings: yaml);
  }

  Map<String, dynamic> toYaml() => settings;
}

/// Version settings.
class VersionSettings {
  final String? prereleaseTag;
  final bool? autoIncrement;
  final int? minDevBuild;
  final int? actionCounter;

  VersionSettings({
    this.prereleaseTag,
    this.autoIncrement,
    this.minDevBuild,
    this.actionCounter,
  });

  factory VersionSettings.fromYaml(Map<String, dynamic> yaml) {
    return VersionSettings(
      prereleaseTag: yaml['prerelease-tag'] as String?,
      autoIncrement: yaml['auto-increment'] as bool?,
      minDevBuild: yaml['min-dev-build'] as int?,
      actionCounter: yaml['action-counter'] as int?,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{};

    if (prereleaseTag != null) result['prerelease-tag'] = prereleaseTag;
    if (autoIncrement != null) result['auto-increment'] = autoIncrement;
    if (minDevBuild != null) result['min-dev-build'] = minDevBuild;
    if (actionCounter != null) result['action-counter'] = actionCounter;

    return result;
  }
}

/// Package module.
class PackageModule {
  final String name;
  final String? libraryFile;
  final List<String>? sourceFolders;

  PackageModule({
    required this.name,
    this.libraryFile,
    this.sourceFolders,
  });

  factory PackageModule.fromYaml(Map<String, dynamic> yaml) {
    return PackageModule(
      name: yaml['name'] as String? ?? '',
      libraryFile: yaml['library-file'] as String?,
      sourceFolders: _parseStringList(yaml['source-folders']),
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{'name': name};
    if (libraryFile != null) result['library-file'] = libraryFile;
    if (sourceFolders != null) result['source-folders'] = sourceFolders;
    return result;
  }
}

/// Part definition.
class Part {
  final String name;
  final String? libraryFile;
  final Map<String, Module> modules;

  Part({
    required this.name,
    this.libraryFile,
    this.modules = const {},
  });

  factory Part.fromYaml(String name, Map<String, dynamic> yaml) {
    return Part(
      name: yaml['name'] as String? ?? name,
      libraryFile: yaml['library-file'] as String?,
      modules: _parseMap(yaml['modules'], (k, v) => Module.fromYaml(k, v)),
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{'name': name};
    if (libraryFile != null) result['library-file'] = libraryFile;
    if (modules.isNotEmpty) {
      result['modules'] = modules.map((k, v) => MapEntry(k, v.toYaml()));
    }
    return result;
  }
}

/// Module definition.
class Module {
  final String name;
  final String? libraryFile;

  Module({
    required this.name,
    this.libraryFile,
  });

  factory Module.fromYaml(String name, Map<String, dynamic> yaml) {
    return Module(
      name: yaml['name'] as String? ?? name,
      libraryFile: yaml['library-file'] as String?,
    );
  }

  Map<String, dynamic> toYaml() {
    final result = <String, dynamic>{'name': name};
    if (libraryFile != null) result['library-file'] = libraryFile;
    return result;
  }
}

/// Executable definition.
class ExecutableDef {
  final String source;
  final String output;

  ExecutableDef({
    required this.source,
    required this.output,
  });

  factory ExecutableDef.fromYaml(Map<String, dynamic> yaml) {
    return ExecutableDef(
      source: yaml['source'] as String? ?? '',
      output: yaml['output'] as String? ?? '',
    );
  }

  Map<String, dynamic> toYaml() {
    return {
      'source': source,
      'output': output,
    };
  }
}

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

List<String>? _parseStringList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return null;
}

/// Parses a command list, preserving map structure for typed commands.
///
/// Commands can be:
/// - Map: `{shell: 'dart pub get'}`, `{dartscript: 'print("hello")'}`
/// - String (legacy): `'dart pub get'` (treated as shell command)
///
/// Map commands support these keys:
/// - `shell`: Shell command to execute
/// - `dartscript`: D4rt code to execute  
/// - `vscode`: VS Code command to execute
/// - `tom`: Tom CLI internal command
///
/// Additional keys like `sudo`, `timeout`, `workingDir` may be added.
List<dynamic>? _parseCommandList(dynamic value) {
  if (value == null) return null;
  if (value is List) {
    return value.map((e) {
      if (e is Map) {
        // Preserve map structure for typed commands
        return makeCleanMap(e);
      }
      // Convert other types to string (legacy format)
      return e.toString();
    }).toList();
  }
  return null;
}

Map<String, String> _parseStringMap(dynamic value) {
  if (value == null) return {};
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
  return {};
}

Map<String, T> _parseMap<T>(
  dynamic value,
  T Function(String key, Map<String, dynamic> yaml) factory,
) {
  if (value == null) return {};
  if (value is Map) {
    final result = <String, T>{};
    for (final entry in value.entries) {
      if (entry.value is Map) {
        result[entry.key.toString()] = factory(
          entry.key.toString(),
          makeCleanMap(entry.value),
        );
      } else if (entry.value == null) {
        // Empty map
        result[entry.key.toString()] = factory(entry.key.toString(), {});
      }
    }
    return result;
  }
  return {};
}

List<ExecutableDef> _parseExecutables(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value
        .where((e) => e is Map)
        .map((e) => ExecutableDef.fromYaml(makeCleanMap(e)))
        .toList();
  }
  return [];
}
