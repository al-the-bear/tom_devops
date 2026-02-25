/// Workspace Information Models
///
/// Data classes representing the workspace structure from `.tom_metadata/tom_master.yaml`.
/// These classes provide a typed interface to workspace metadata for all tools.
library;

import 'package:yaml/yaml.dart';

/// Represents the complete workspace information from `.tom_metadata/tom_master.yaml`.
class WorkspaceInfo {
  /// Workspace name (typically the root folder name).
  final String? name;

  /// Workspace-level settings.
  final Map<String, dynamic> settings;

  /// Workspace modes configuration.
  final MetadataModes? workspaceModes;

  /// Project groups.
  final Map<String, WorkspaceGroup> groups;

  /// Build order (project names in order of dependencies).
  final List<String> buildOrder;

  /// All projects in the workspace.
  final Map<String, WorkspaceProject> projects;

  WorkspaceInfo({
    this.name,
    this.settings = const {},
    this.workspaceModes,
    this.groups = const {},
    this.buildOrder = const [],
    this.projects = const {},
  });

  /// Creates a WorkspaceInfo from parsed YAML.
  /// 
  /// The YAML structure should have workspace settings at the top level
  /// (not nested under a 'workspace:' key), per the tom_master.yaml specification.
  factory WorkspaceInfo.fromYaml(YamlMap yaml) {
    // Check if yaml is empty
    if (yaml.isEmpty) {
      return WorkspaceInfo();
    }

    // Parse workspace modes
    MetadataModes? modes;
    final modesYaml = yaml['workspace-modes'] as YamlMap?;
    if (modesYaml != null) {
      modes = MetadataModes.fromYaml(modesYaml);
    }

    // Parse groups
    final groups = <String, WorkspaceGroup>{};
    final groupsYaml = yaml['groups'] as YamlMap?;
    if (groupsYaml != null) {
      for (final entry in groupsYaml.entries) {
        final name = entry.key as String;
        final data = entry.value as YamlMap?;
        if (data != null) {
          groups[name] = WorkspaceGroup.fromYaml(name, data);
        }
      }
    }

    // Parse build order
    final buildOrder = <String>[];
    final buildOrderYaml = yaml['build-order'] as YamlList?;
    if (buildOrderYaml != null) {
      buildOrder.addAll(buildOrderYaml.cast<String>());
    }

    // Parse projects
    final projects = <String, WorkspaceProject>{};
    final projectsYaml = yaml['projects'] as YamlMap?;
    if (projectsYaml != null) {
      for (final entry in projectsYaml.entries) {
        final name = entry.key as String;
        final data = entry.value as YamlMap?;
        if (data != null) {
          projects[name] = WorkspaceProject.fromYaml(name, data);
        }
      }
    }

    // Parse settings (everything not explicitly parsed above)
    final settings = <String, dynamic>{};
    for (final entry in yaml.entries) {
      final key = entry.key as String;
      if (!['name', 'workspace-modes', 'groups', 'build-order', 'projects'].contains(key)) {
        settings[key] = _convertYamlValue(entry.value);
      }
    }

    return WorkspaceInfo(
      name: yaml['name'] as String?,
      settings: settings,
      workspaceModes: modes,
      groups: groups,
      buildOrder: buildOrder,
      projects: projects,
    );
  }
}

/// Workspace modes configuration for metadata.
///
/// Note: This is different from `WorkspaceModes` in file_object_model.dart,
/// which is part of the Tom CLI configuration system.
class MetadataModes {
  /// List of supported modes.
  final List<MetadataMode> supportedModes;

  /// Default mode name.
  final String? defaultMode;

  MetadataModes({
    this.supportedModes = const [],
    this.defaultMode,
  });

  factory MetadataModes.fromYaml(YamlMap yaml) {
    final supportedModes = <MetadataMode>[];
    final supportedYaml = yaml['supported'] as YamlList?;

    if (supportedYaml != null) {
      for (final modeYaml in supportedYaml) {
        if (modeYaml is YamlMap) {
          supportedModes.add(MetadataMode.fromYaml(modeYaml));
        } else if (modeYaml is String) {
          supportedModes.add(MetadataMode(name: modeYaml));
        }
      }
    }

    return MetadataModes(
      supportedModes: supportedModes,
      defaultMode: yaml['default'] as String?,
    );
  }
}

/// A single metadata mode definition.
class MetadataMode {
  /// The mode name.
  final String name;

  /// Modes that are implied when this mode is used.
  final List<String> implies;

  /// Optional description of the mode.
  final String? description;

  MetadataMode({
    required this.name,
    this.implies = const [],
    this.description,
  });

  factory MetadataMode.fromYaml(YamlMap yaml) {
    final implies = <String>[];
    final impliesYaml = yaml['implies'];
    if (impliesYaml is YamlList) {
      implies.addAll(impliesYaml.cast<String>());
    } else if (impliesYaml is String) {
      implies.add(impliesYaml);
    }

    return MetadataMode(
      name: yaml['name'] as String? ?? '',
      implies: implies,
      description: yaml['description'] as String?,
    );
  }
}

/// A project group definition.
class WorkspaceGroup {
  /// Group name.
  final String name;

  /// Group description.
  final String? description;

  /// Project names in this group.
  final List<String> projects;

  WorkspaceGroup({
    required this.name,
    this.description,
    this.projects = const [],
  });

  factory WorkspaceGroup.fromYaml(String name, YamlMap yaml) {
    final projects = <String>[];
    final projectsYaml = yaml['projects'] as YamlList?;
    if (projectsYaml != null) {
      projects.addAll(projectsYaml.cast<String>());
    }

    return WorkspaceGroup(
      name: name,
      description: yaml['description'] as String?,
      projects: projects,
    );
  }
}

/// A project in the workspace.
class WorkspaceProject {
  /// Project name (folder name).
  final String name;

  /// Display name.
  final String? displayName;

  /// Project name from manifest.
  final String? projectName;

  /// Project type (dart_package, flutter_app, etc).
  final String? type;

  /// Description.
  final String? description;

  /// Build dependencies.
  final List<String> buildAfter;

  /// Feature flags.
  final Map<String, bool> features;

  /// Build configuration.
  final Map<String, dynamic> build;

  /// Run configuration.
  final Map<String, dynamic> run;

  /// Deploy configuration.
  final Map<String, dynamic> deploy;

  /// Binaries list.
  final List<String> binaries;

  /// Documentation files.
  final List<String> docs;

  /// Test files.
  final List<String> tests;

  /// Example files.
  final List<String> examples;

  /// Copilot guidelines files.
  final List<String> copilotGuidelines;

  WorkspaceProject({
    required this.name,
    this.displayName,
    this.projectName,
    this.type,
    this.description,
    this.buildAfter = const [],
    this.features = const {},
    this.build = const {},
    this.run = const {},
    this.deploy = const {},
    this.binaries = const [],
    this.docs = const [],
    this.tests = const [],
    this.examples = const [],
    this.copilotGuidelines = const [],
  });

  factory WorkspaceProject.fromYaml(String name, YamlMap yaml) {
    return WorkspaceProject(
      name: name,
      displayName: yaml['name'] as String?, // In output, 'name:' is the display name
      projectName: yaml['projectName'] as String?, // Original project name from manifest
      type: yaml['type'] as String?,
      description: yaml['description'] as String?,
      buildAfter: _yamlListToStrings(yaml['build-after']),
      features: _yamlMapToBoolMap(yaml['features']),
      build: _yamlMapToMap(yaml['build']),
      run: _yamlMapToMap(yaml['run']),
      deploy: _yamlMapToMap(yaml['deploy']),
      binaries: _yamlListToStrings(yaml['binaries']),
      docs: _yamlListToStrings(yaml['docs']),
      tests: _yamlListToStrings(yaml['tests']),
      examples: _yamlListToStrings(yaml['examples']),
      copilotGuidelines: _yamlListToStrings(yaml['copilot-guidelines']),
    );
  }
}

// Helper functions for YAML conversion

List<String> _yamlListToStrings(dynamic value) {
  if (value == null) return [];
  if (value is YamlList) {
    return value.cast<String>().toList();
  }
  if (value is List) {
    return value.cast<String>().toList();
  }
  return [];
}

Map<String, bool> _yamlMapToBoolMap(dynamic value) {
  if (value == null) return {};
  if (value is YamlMap) {
    return Map.fromEntries(
      value.entries.map((e) => MapEntry(e.key as String, e.value as bool)),
    );
  }
  return {};
}

Map<String, dynamic> _yamlMapToMap(dynamic value) {
  if (value == null) return {};
  if (value is YamlMap) {
    return _convertYamlValue(value) as Map<String, dynamic>;
  }
  return {};
}

/// Recursively converts YAML values to Dart types.
dynamic _convertYamlValue(dynamic value) {
  if (value is YamlMap) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map((e) => MapEntry(e.key as String, _convertYamlValue(e.value))),
    );
  }
  if (value is YamlList) {
    return value.map(_convertYamlValue).toList();
  }
  return value;
}
