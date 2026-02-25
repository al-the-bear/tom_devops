/// Master file generation for Tom workspace.
///
/// Generates `tom_master.yaml` and `tom_master_<action>.yaml` files
/// that contain fully resolved workspace and project configuration.
///
/// ## Features
///
/// - Generates generic `tom_master.yaml` for tooling/IDE queries
/// - Generates action-specific `tom_master_<action>.yaml` files
/// - Resolves `[[...]]` and `[{...}]` placeholders during generation
/// - Preserves `$VAL{}`, `$ENV{}`, `$D4{}`, `$GEN{}` for runtime resolution
/// - Computes `build-order` and `action-order` from dependencies
/// - Includes scan timestamp in ISO 8601 format
///
/// ## Usage
///
/// ```dart
/// final generator = MasterGenerator(
///   workspace: loadedWorkspace,
///   projects: discoveredProjects,
/// );
/// final master = generator.generateMaster();
/// final buildMaster = generator.generateActionMaster('build');
/// ```
library;

import 'dart:io';

import '../config/config_merger.dart';
import 'package:tom_build/tom_build.dart';
import '../mode/mode_resolver.dart';
import 'build_order.dart';

/// Configuration for master file generation.
class MasterGeneratorConfig {
  /// Path to the workspace root directory.
  final String workspacePath;

  /// Path to output directory for generated files (default: .tom_metadata/).
  final String? outputPath;

  /// Whether to resolve ${} placeholders during generation.
  final bool resolvePlaceholders;

  /// Whether to process mode blocks in project files.
  final bool processModeBlocks;

  /// Creates master generator configuration.
  const MasterGeneratorConfig({
    required this.workspacePath,
    this.outputPath,
    this.resolvePlaceholders = true,
    this.processModeBlocks = true,
  });

  /// Gets the output directory path.
  String get outputDir => outputPath ?? '$workspacePath/.tom_metadata';
}

/// Result of master file generation.
class MasterGenerationResult {
  /// The generated master data as a map.
  final Map<String, dynamic> data;

  /// The path where the file was written (if written).
  final String? outputPath;

  /// Whether generation was successful.
  final bool success;

  /// Error message if generation failed.
  final String? error;

  const MasterGenerationResult._({
    required this.data,
    this.outputPath,
    required this.success,
    this.error,
  });

  /// Creates a successful result.
  factory MasterGenerationResult.success(Map<String, dynamic> data, {String? outputPath}) {
    return MasterGenerationResult._(
      data: data,
      outputPath: outputPath,
      success: true,
    );
  }

  /// Creates an error result.
  factory MasterGenerationResult.error(String message) {
    return MasterGenerationResult._(
      data: const {},
      success: false,
      error: message,
    );
  }
}

/// Generates tom_master*.yaml files for a workspace.
class MasterGenerator {
  /// The loaded workspace configuration.
  final TomWorkspace workspace;

  /// The discovered projects in the workspace.
  final Map<String, TomProject> projects;

  /// Generator configuration.
  final MasterGeneratorConfig config;

  /// Creates a master generator.
  MasterGenerator({
    required this.workspace,
    required this.projects,
    required this.config,
  });

  // Internal helpers
  final _merger = ConfigMerger();
  final _modeResolver = ModeResolver();
  final _buildOrderCalculator = BuildOrderCalculator();

  /// Generates the generic tom_master.yaml.
  ///
  /// Uses default mode values from workspace-modes.default-action-modes
  /// or action-mode-configuration.default.
  TomMaster generateMaster() {
    final timestamp = DateTime.now().toUtc().toIso8601String();

    // Calculate build order
    final buildOrder = _calculateBuildOrder();

    // Calculate action orders
    final actionOrder = _calculateActionOrders();

    // Process projects with default modes
    final defaultModes = _getDefaultModes();
    final processedProjects = _processProjects(defaultModes);

    return TomMaster(
      // Metadata
      scanTimestamp: timestamp,

      // Workspace configuration
      name: workspace.name,
      binaries: workspace.binaries,
      operatingSystems: workspace.operatingSystems,
      mobilePlatforms: workspace.mobilePlatforms,
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
      customTags: workspace.customTags,

      // Computed fields
      buildOrder: buildOrder,
      actionOrder: actionOrder,
      projects: processedProjects,
    );
  }

  /// Generates an action-specific tom_master_<action>.yaml.
  ///
  /// Resolves modes based on action-mode-configuration for the given action.
  TomMaster generateActionMaster(String action) {
    final timestamp = DateTime.now().toUtc().toIso8601String();

    // Calculate build order
    final buildOrder = _calculateBuildOrder();

    // Calculate action order for this specific action
    final actionOrder = _calculateActionOrders();

    // Get modes for this action
    final modes = _getModes(action);
    final processedProjects = _processProjects(modes);

    return TomMaster(
      // Metadata
      scanTimestamp: timestamp,

      // Workspace configuration
      name: workspace.name,
      binaries: workspace.binaries,
      operatingSystems: workspace.operatingSystems,
      mobilePlatforms: workspace.mobilePlatforms,
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
      customTags: workspace.customTags,

      // Computed fields
      buildOrder: buildOrder,
      actionOrder: actionOrder,
      projects: processedProjects,
    );
  }

  /// Generates and writes the generic tom_master.yaml.
  MasterGenerationResult generateAndWriteMaster() {
    try {
      final master = generateMaster();
      final data = master.toYaml();

      // Resolve placeholders if enabled
      final resolvedData = config.resolvePlaceholders
          ? _resolvePlaceholders(data)
          : data;

      // Write to file
      final outputDir = Directory(config.outputDir);
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      final outputPath = '${config.outputDir}/tom_master.yaml';
      final yamlContent = toYamlString(resolvedData);
      File(outputPath).writeAsStringSync(yamlContent);

      return MasterGenerationResult.success(resolvedData, outputPath: outputPath);
    } catch (e) {
      return MasterGenerationResult.error(e.toString());
    }
  }

  /// Generates and writes an action-specific tom_master_<action>.yaml.
  MasterGenerationResult generateAndWriteActionMaster(String action) {
    try {
      final master = generateActionMaster(action);
      final data = master.toYaml();

      // Resolve placeholders if enabled
      final resolvedData = config.resolvePlaceholders
          ? _resolvePlaceholders(data)
          : data;

      // Write to file
      final outputDir = Directory(config.outputDir);
      if (!outputDir.existsSync()) {
        outputDir.createSync(recursive: true);
      }

      final outputPath = '${config.outputDir}/tom_master_$action.yaml';
      final yamlContent = toYamlString(resolvedData);
      File(outputPath).writeAsStringSync(yamlContent);

      return MasterGenerationResult.success(resolvedData, outputPath: outputPath);
    } catch (e) {
      return MasterGenerationResult.error(e.toString());
    }
  }

  /// Generates all action-specific master files.
  List<MasterGenerationResult> generateAndWriteAllActionMasters() {
    final results = <MasterGenerationResult>[];

    // Get all actions from action-mode-configuration
    final actionModeConfig = workspace.workspaceModes?.actionModeConfiguration;
    if (actionModeConfig != null) {
      for (final actionName in actionModeConfig.entries.keys) {
        if (actionName == 'default') continue; // Skip 'default'
        results.add(generateAndWriteActionMaster(actionName));
      }

      // Also generate for actions defined in workspace.actions
      for (final actionName in workspace.actions.keys) {
        if (!actionModeConfig.entries.containsKey(actionName)) {
          results.add(generateAndWriteActionMaster(actionName));
        }
      }
    } else {
      // No action-mode-configuration, generate for all actions
      for (final actionName in workspace.actions.keys) {
        results.add(generateAndWriteActionMaster(actionName));
      }
    }

    return results;
  }

  /// Calculates the build order for all projects.
  List<String> _calculateBuildOrder() {
    final buildProjects = <String, BuildOrderProject>{};

    for (final project in projects.values) {
      buildProjects[project.name] = BuildOrderProject(
        name: project.name,
        buildAfter: project.buildAfter,
      );
    }

    try {
      return _buildOrderCalculator.calculateBuildOrder(buildProjects);
    } on CircularDependencyException {
      // Return alphabetically sorted as fallback
      return projects.keys.toList()..sort();
    }
  }

  /// Calculates action orders for all actions.
  Map<String, List<String>> _calculateActionOrders() {
    final result = <String, List<String>>{};

    // Get all action names
    final actionNames = <String>{
      ...workspace.actions.keys,
      ...(workspace.workspaceModes?.actionModeConfiguration?.entries.keys ?? []),
    };

    for (final actionName in actionNames) {
      if (actionName == 'default') continue;

      // Collect action-specific dependencies
      final actionDeps = <String, List<String>>{};
      for (final project in projects.values) {
        final projectActionOrder = project.actionOrder;
        final afterKey = '$actionName-after';
        if (projectActionOrder.containsKey(afterKey)) {
          actionDeps[project.name] = projectActionOrder[afterKey]!;
        }
      }

      // Calculate action-specific order
      final buildProjects = <String, BuildOrderProject>{};
      for (final project in projects.values) {
        buildProjects[project.name] = BuildOrderProject(
          name: project.name,
          buildAfter: project.buildAfter,
        );
      }

      try {
        result[actionName] = _buildOrderCalculator.calculateActionOrder(
          projects: buildProjects,
          action: actionName,
          actionDeps: actionDeps,
        );
      } on CircularDependencyException {
        result[actionName] = projects.keys.toList()..sort();
      }
    }

    return result;
  }

  /// Gets the default modes for generic master generation.
  Set<String> _getDefaultModes() {
    final modes = <String>{};

    // Try to get from default-action-modes or action-mode-configuration.default
    final defaultEntry =
        workspace.workspaceModes?.actionModeConfiguration?.entries['default'];

    if (defaultEntry != null) {
      // Add all mode values from the default configuration
      for (final modeValue in defaultEntry.modes.values) {
        modes.add(modeValue);
      }
    }

    return modes;
  }

  /// Gets modes for a specific action.
  Set<String> _getModes(String action) {
    final result = _modeResolver.resolve(
      actionName: action,
      workspaceModes: workspace.workspaceModes,
    );

    final modes = <String>{};
    for (final entry in result.modeTypeValues.entries) {
      modes.add(entry.value);
    }

    return modes;
  }

  /// Processes projects with the given mode context.
  Map<String, TomProject> _processProjects(Set<String> modes) {
    final result = <String, TomProject>{};

    for (final entry in projects.entries) {
      final projectName = entry.key;
      final project = entry.value;

      // Merge with workspace-level project-info
      var mergedProject = project;
      final projectEntry = workspace.projectInfo[projectName];
      if (projectEntry != null) {
        mergedProject = _mergeProjectEntry(project, projectEntry);
      }

      mergedProject = _mergeWorkspaceActions(mergedProject);

      // Process mode blocks in project's YAML if needed
      if (config.processModeBlocks) {
        // Note: Mode blocks are typically in raw YAML, which requires
        // reloading. For now, we just return the merged project.
        // Full mode block processing would require access to raw YAML.
      }

      result[projectName] = mergedProject;
    }

    return result;
  }

  /// Merges project-info overrides into a project.
  TomProject _mergeProjectEntry(TomProject project, ProjectEntry info) {
    // Create a map for merging
    final projectMap = project.toYaml();
    final infoMap = info.toYaml();

    // Deep merge
    final merged = _merger.deepMerge(projectMap, infoMap);

    // Reconstruct project from merged map
    return TomProject.fromYaml(project.name, merged);
  }

  /// Merges workspace actions into project if not defined.
  TomProject _mergeWorkspaceActions(TomProject project) {
    if (workspace.actions.isEmpty) return project;

    final projectMap = project.toYaml();
    // Use Map<String, dynamic> explicitly to allow modification
    final actionsMap = Map<String, dynamic>.from(projectMap['actions'] as Map? ?? {});

    for (final entry in workspace.actions.entries) {
      final actionName = entry.key;
      // If project has action, keep it
      if (actionsMap.containsKey(actionName)) continue;

      final actionDef = entry.value;
      ActionConfig? resolvedConfig;

      // 1. Try type-specific config
      if (project.type != null && actionDef.typeConfigs.containsKey(project.type)) {
        resolvedConfig = actionDef.typeConfigs[project.type];
      } 
      // 2. Fallback to default
      else {
        resolvedConfig = actionDef.defaultConfig;
      }

      if (resolvedConfig != null) {
        // Add action def to project
        actionsMap[actionName] = {
          'name': actionName,
          'description': actionDef.description,
          'default': resolvedConfig.toYaml(),
        };
      }
    }

    projectMap['actions'] = actionsMap;
    final newProject = TomProject.fromYaml(project.name, projectMap);
    return newProject;
  }

  // ---------------------------------------------------------------------------
  // Placeholder resolution (generation time: [[...]] and [{...}] only)
  // ---------------------------------------------------------------------------

  /// Pattern for [[VAR]] or [[VAR:-default]] environment placeholders.
  static final _bracketEnvPattern = RegExp(r'\[\[([^\]:-]+)(?::-([^\]]*))?\]\]');

  /// Pattern for [{path}] or [{path:-default}] data placeholders.
  static final _bracketDataPattern = RegExp(r'\[\{([^}:-]+)(?::-([^}]*))?\}\]');

  /// Resolves [[...]] and [{...}] placeholders in the generated data.
  ///
  /// Note: $VAL{}, $ENV{}, $D4{}, $GEN{} are preserved for runtime resolution.
  Map<String, dynamic> _resolvePlaceholders(Map<String, dynamic> data) {
    try {
      return _resolveInMap(data, data);
    } catch (e) {
      // Return original data if resolution fails
      return data;
    }
  }

  /// Recursively resolves placeholders in a map.
  Map<String, dynamic> _resolveInMap(
    Map<String, dynamic> map,
    Map<String, dynamic> context,
  ) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      result[entry.key] = _resolveValue(entry.value, context);
    }
    return result;
  }

  /// Resolves placeholders in a value.
  dynamic _resolveValue(dynamic value, Map<String, dynamic> context) {
    if (value is String) {
      return _resolveString(value, context);
    } else if (value is Map<String, dynamic>) {
      return _resolveInMap(value, context);
    } else if (value is Map) {
      return _resolveInMap(Map<String, dynamic>.from(value), context);
    } else if (value is List) {
      return value.map((e) => _resolveValue(e, context)).toList();
    }
    return value;
  }

  /// Resolves [[...]] and [{...}] placeholders in a string.
  String _resolveString(String content, Map<String, dynamic> context) {
    var result = content;

    // Step 1: Resolve [[VAR:-default]] environment placeholders
    result = result.replaceAllMapped(_bracketEnvPattern, (match) {
      final varName = match.group(1)!;
      final defaultValue = match.group(2);

      final value = Platform.environment[varName];
      if (value != null && value.isNotEmpty) {
        return value;
      } else if (defaultValue != null) {
        return defaultValue;
      }
      // Leave unresolved
      return match.group(0)!;
    });

    // Step 2: Resolve [{path:-default}] data placeholders
    result = result.replaceAllMapped(_bracketDataPattern, (match) {
      final keyPath = match.group(1)!;
      final defaultValue = match.group(2);

      final value = _resolveKeyPath(keyPath, context);
      if (value != null) {
        return value.toString();
      } else if (defaultValue != null) {
        return defaultValue;
      }
      // Leave unresolved
      return match.group(0)!;
    });

    return result;
  }

  /// Resolves a dot-separated key path in a context map.
  dynamic _resolveKeyPath(String keyPath, Map<String, dynamic> context) {
    final parts = keyPath.split('.');
    dynamic current = context;

    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }
}
