/// Workspace context and discovery utilities for Tom CLI.
///
/// Provides:
/// - Workspace root discovery (walk up directories to find tom_workspace.yaml)
/// - Global workspace configuration caching
/// - Project discovery within the workspace
///
/// Implements tom_tool_specification.md Section 6.1.5.
library;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../config/config_loader.dart';
import 'package:tom_build/tom_build.dart';
import '../generation/master_generator.dart';

// =============================================================================
// WORKSPACE DISCOVERY
// =============================================================================

/// Result of workspace discovery.
class WorkspaceDiscoveryResult {
  /// The path to the workspace root (directory containing tom_workspace.yaml).
  final String? workspacePath;

  /// Whether a workspace was found.
  final bool found;

  /// Error message if discovery failed.
  final String? error;

  const WorkspaceDiscoveryResult._({
    this.workspacePath,
    required this.found,
    this.error,
  });

  /// Creates a successful result.
  factory WorkspaceDiscoveryResult.found(String workspacePath) {
    return WorkspaceDiscoveryResult._(
      workspacePath: workspacePath,
      found: true,
    );
  }

  /// Creates a not-found result.
  factory WorkspaceDiscoveryResult.notFound(String searchStart) {
    return WorkspaceDiscoveryResult._(
      found: false,
      error: 'No Tom workspace found\n'
          '  Searched from: [$searchStart] to filesystem root\n'
          '  Looking for: tom_workspace.yaml\n'
          '  Resolution: Navigate to a Tom workspace directory or create tom_workspace.yaml',
    );
  }
}

/// Discovers the workspace root by walking up the directory tree.
///
/// Starts from [startPath] and walks up parent directories until
/// `tom_workspace.yaml` is found or the filesystem root is reached.
///
/// Per tom_tool_specification.md Section 6.1.5:
/// - Start from current directory
/// - Walk up to filesystem root
/// - Stop when tom_workspace.yaml is found
/// - Error if root reached without finding workspace
WorkspaceDiscoveryResult discoverWorkspace(String startPath) {
  var current = Directory(startPath).absolute;

  while (true) {
    final configFile = File(path.join(current.path, 'tom_workspace.yaml'));
    if (configFile.existsSync()) {
      return WorkspaceDiscoveryResult.found(current.path);
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      // Reached filesystem root
      return WorkspaceDiscoveryResult.notFound(startPath);
    }
    current = parent;
  }
}

// =============================================================================
// WORKSPACE CONTEXT
// =============================================================================

/// Global workspace context providing cached configuration access.
///
/// Per tom_tool_specification.md Section 6.1.5:
/// - Load configuration once at startup
/// - Cache for entire CLI session
/// - Provide global access to all components
class WorkspaceContext {
  /// Singleton instance.
  static WorkspaceContext? _instance;

  /// Cached workspace path.
  static String? _cachedPath;

  /// The workspace root path.
  final String workspacePath;

  /// The loaded workspace configuration.
  final TomWorkspace workspace;

  /// Discovered projects in the workspace.
  final Map<String, TomProject> projects;

  /// Whether master files have been generated this session.
  bool _masterFilesGenerated = false;

  /// Private constructor.
  WorkspaceContext._({
    required this.workspacePath,
    required this.workspace,
    required this.projects,
  });

  /// Gets the singleton instance, loading if necessary.
  ///
  /// If [workspacePath] is provided and differs from cached path,
  /// a fresh context is loaded.
  static Future<WorkspaceContext> load(String workspacePath) async {
    if (_instance != null && _cachedPath == workspacePath) {
      return _instance!;
    }

    // Load workspace configuration
    final loader = ConfigLoader();
    final workspace = loader.loadWorkspaceWithImports(workspacePath);
    if (workspace == null) {
      throw WorkspaceContextException(
        'Failed to load workspace configuration\n'
        '  File: [${path.join(workspacePath, 'tom_workspace.yaml')}]\n'
        '  Resolution: Ensure tom_workspace.yaml exists and is valid YAML',
      );
    }

    // Discover projects
    final projects = await discoverProjects(workspacePath, workspace);

    _cachedPath = workspacePath;
    _instance = WorkspaceContext._(
      workspacePath: workspacePath,
      workspace: workspace,
      projects: projects,
    );

    return _instance!;
  }

  /// Gets the current context if already loaded.
  ///
  /// Returns null if no context has been loaded yet.
  static WorkspaceContext? get current => _instance;

  /// Resets the cached context.
  ///
  /// Useful for testing or when workspace changes.
  static void reset() {
    _instance = null;
    _cachedPath = null;
  }

  /// Gets the metadata directory path.
  String get metadataPath => path.join(workspacePath, '.tom_metadata');

  /// Gets the workspace state file path.
  String get stateFilePath => path.join(metadataPath, 'workspace_state.yaml');

  /// Whether master files have been generated this session.
  bool get masterFilesGenerated => _masterFilesGenerated;

  /// Marks master files as generated.
  void markMasterFilesGenerated() {
    _masterFilesGenerated = true;
  }

  /// Generates master files if not already done this session.
  ///
  /// Returns true if generation was performed or already done.
  Future<MasterGenerationSummary> ensureMasterFilesGenerated() async {
    if (_masterFilesGenerated) {
      return MasterGenerationSummary(
        success: true,
        message: 'Master files already generated this session',
        filesGenerated: 0,
      );
    }

    final generator = MasterGenerator(
      workspace: workspace,
      projects: projects,
      config: MasterGeneratorConfig(workspacePath: workspacePath),
    );

    // Generate generic master
    final masterResult = generator.generateAndWriteMaster();
    if (!masterResult.success) {
      return MasterGenerationSummary(
        success: false,
        message: masterResult.error ?? 'Failed to generate tom_master.yaml',
        filesGenerated: 0,
      );
    }

    // Generate action-specific masters
    final actionResults = generator.generateAndWriteAllActionMasters();
    final failures = actionResults.where((r) => !r.success).toList();

    if (failures.isNotEmpty) {
      return MasterGenerationSummary(
        success: false,
        message: 'Failed to generate some action masters: '
            '${failures.map((f) => f.error).join(', ')}',
        filesGenerated: actionResults.length - failures.length + 1,
      );
    }

    _masterFilesGenerated = true;
    return MasterGenerationSummary(
      success: true,
      message: 'Generated ${actionResults.length + 1} master files',
      filesGenerated: actionResults.length + 1,
    );
  }

  /// Gets actions defined in the workspace.
  Map<String, ActionDef> get actions => workspace.actions;

  /// Gets pipelines defined in the workspace.
  Map<String, Pipeline> get pipelines => workspace.pipelines;

  /// Gets groups defined in the workspace.
  Map<String, GroupDef> get groups => workspace.groups;

  /// Gets project names in build order.
  List<String> get projectsInBuildOrder {
    // Simple topological sort based on build-after
    final sorted = <String>[];
    final visited = <String>{};
    final visiting = <String>{};

    void visit(String name) {
      if (visited.contains(name)) return;
      if (visiting.contains(name)) {
        // Circular dependency - just add and continue
        sorted.add(name);
        visited.add(name);
        return;
      }

      visiting.add(name);
      final project = projects[name];
      if (project != null) {
        for (final dep in project.buildAfter) {
          if (projects.containsKey(dep)) {
            visit(dep);
          }
        }
      }
      visiting.remove(name);
      visited.add(name);
      sorted.add(name);
    }

    for (final name in projects.keys) {
      visit(name);
    }

    return sorted;
  }

  /// Gets projects in a specific group.
  List<String> getProjectsInGroup(String groupName) {
    final group = groups[groupName];
    if (group == null) return [];

    return projects.keys
        .where((name) => group.projects.contains(name))
        .toList();
  }
}

/// Summary of master file generation.
class MasterGenerationSummary {
  final bool success;
  final String message;
  final int filesGenerated;

  const MasterGenerationSummary({
    required this.success,
    required this.message,
    required this.filesGenerated,
  });
}

/// Exception thrown when workspace context operations fail.
class WorkspaceContextException implements Exception {
  final String message;

  const WorkspaceContextException(this.message);

  @override
  String toString() => message;
}

// =============================================================================
// PROJECT DISCOVERY
// =============================================================================

/// Discovers projects within a workspace.
///
/// Looks for:
/// 1. Projects listed in workspace's project-info section
/// 2. Directories containing pubspec.yaml (Dart/Flutter projects)
/// 3. Directories containing package.json (Node.js projects)
/// 4. Directories containing pyproject.toml or setup.py (Python projects)
Future<Map<String, TomProject>> discoverProjects(
  String workspacePath,
  TomWorkspace workspace,
) async {
  final projects = <String, TomProject>{};
  final loader = ConfigLoader();

  // First, process explicitly listed projects from project-info
  for (final entry in workspace.projectInfo.entries) {
    final projectName = entry.key;
    final projectEntry = entry.value;

    // Get path from settings or use project name as folder
    final projectPath = (projectEntry.settings['path'] as String?) ?? projectName;
    final fullPath = path.join(workspacePath, projectPath);

    if (!Directory(fullPath).existsSync()) {
      continue; // Skip non-existent projects
    }

    // Try to load tom_project.yaml
    final projectConfig = loader.loadProjectConfig(fullPath, projectName);
    if (projectConfig != null) {
      projects[projectName] = projectConfig;
    } else {
      // Create project from auto-detection and project-info
      projects[projectName] = await _autoDetectProject(
        fullPath,
        projectName,
        workspace,
        projectEntry.settings,
      );
    }
  }

  // Then, discover additional projects not in project-info
  final workspaceDir = Directory(workspacePath);
  await for (final entity in workspaceDir.list(followLinks: false)) {
    if (entity is! Directory) continue;

    final dirName = path.basename(entity.path);

    // Skip hidden directories, metadata, and already discovered
    if (dirName.startsWith('.') || dirName.startsWith('_')) continue;
    if (projects.containsKey(dirName)) continue;

    // Check for project markers
    final hasPubspec =
        File(path.join(entity.path, 'pubspec.yaml')).existsSync();
    final hasPackageJson =
        File(path.join(entity.path, 'package.json')).existsSync();
    final hasPyproject =
        File(path.join(entity.path, 'pyproject.toml')).existsSync();
    final hasSetupPy = File(path.join(entity.path, 'setup.py')).existsSync();

    if (!hasPubspec && !hasPackageJson && !hasPyproject && !hasSetupPy) {
      continue; // Not a project directory
    }

    // Try to load tom_project.yaml
    final projectConfig = loader.loadProjectConfig(entity.path, dirName);
    if (projectConfig != null) {
      projects[dirName] = projectConfig;
    } else {
      // Auto-detect project type
      projects[dirName] = await _autoDetectProject(
        entity.path,
        dirName,
        workspace,
        null,
      );
    }
  }

  return projects;
}

/// Auto-detects project configuration from directory contents.
Future<TomProject> _autoDetectProject(
  String projectPath,
  String projectName,
  TomWorkspace workspace,
  Map<String, dynamic>? projectInfoSettings,
) async {
  String projectType = 'unknown';
  String? description;
  List<String> buildAfter = [];

  // Detect from pubspec.yaml
  final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
  if (pubspecFile.existsSync()) {
    try {
      final content = pubspecFile.readAsStringSync();
      final pubspec = _parseYamlSafe(content);

      description = pubspec['description'] as String?;

      // Determine Dart project type
      final hasDependencyFlutter = pubspec['dependencies'] is Map &&
          (pubspec['dependencies'] as Map).containsKey('flutter');
      final hasDevFlutter = pubspec['dev_dependencies'] is Map &&
          (pubspec['dev_dependencies'] as Map).containsKey('flutter_test');

      if (hasDependencyFlutter || hasDevFlutter) {
        // Check for Flutter app vs package
        final hasAndroid =
            Directory(path.join(projectPath, 'android')).existsSync();
        final hasIos = Directory(path.join(projectPath, 'ios')).existsSync();
        final hasWeb = Directory(path.join(projectPath, 'web')).existsSync();
        projectType = (hasAndroid || hasIos || hasWeb)
            ? 'flutter_app'
            : 'flutter_package';
      } else {
        // Check for Dart console vs package
        final hasBin = Directory(path.join(projectPath, 'bin')).existsSync();
        projectType = hasBin ? 'dart_console' : 'dart_package';
      }

      // Extract build-after from dependencies
      final deps = pubspec['dependencies'] as Map? ?? {};
      for (final dep in deps.keys) {
        if (dep is String && deps[dep] is Map) {
          final depConfig = deps[dep] as Map;
          if (depConfig.containsKey('path')) {
            // Local path dependency - add to build-after
            final depPath = depConfig['path'] as String;
            final depName = path.basename(path.normalize(
              path.join(projectPath, depPath),
            ));
            buildAfter.add(depName);
          }
        }
      }
    } catch (_) {
      // Ignore parse errors
    }
  }

  // Detect from package.json
  final packageJsonFile = File(path.join(projectPath, 'package.json'));
  if (packageJsonFile.existsSync() && projectType == 'unknown') {
    try {
      final content = packageJsonFile.readAsStringSync();
      // Simple detection based on content patterns
      if (content.contains('"typescript"') || content.contains('.ts"')) {
        projectType = 'typescript';
      } else if (content.contains('"react"')) {
        projectType = 'javascript_react';
      } else if (content.contains('"vue"')) {
        projectType = 'javascript_vue';
      } else {
        projectType = 'javascript';
      }
    } catch (_) {
      // Ignore parse errors
    }
  }

  // Detect from pyproject.toml
  final pyprojectFile = File(path.join(projectPath, 'pyproject.toml'));
  if (pyprojectFile.existsSync() && projectType == 'unknown') {
    try {
      final content = pyprojectFile.readAsStringSync();
      if (content.contains('[tool.poetry]')) {
        projectType = 'python_poetry';
      } else if (content.contains('[tool.uv]')) {
        projectType = 'python_uv';
      } else {
        projectType = 'python';
      }
    } catch (_) {
      // Ignore parse errors
    }
  }

  // Apply project-info overrides
  if (projectInfoSettings != null) {
    if (projectInfoSettings['type'] != null) {
      projectType = projectInfoSettings['type'] as String;
    }
    if (projectInfoSettings['description'] != null) {
      description = projectInfoSettings['description'] as String;
    }
    if (projectInfoSettings['build-after'] is List) {
      buildAfter = (projectInfoSettings['build-after'] as List)
          .map((e) => e.toString())
          .toList();
    }
  }

  // Inherit actions from workspace
  final actions = Map<String, ActionDef>.from(workspace.actions);

  return TomProject(
    name: projectName,
    type: projectType,
    description: description,
    buildAfter: buildAfter,
    actions: actions,
    // Other fields default to empty/null
    actionOrder: const {},
    modeDefinitions: const {},
    customTags: const {},
  );
}

/// Safely parses YAML content, returning empty map on error.
Map<String, dynamic> _parseYamlSafe(String content) {
  try {
    final yaml = loadYaml(content);
    if (yaml is YamlMap) {
      return _convertYamlMap(yaml);
    }
    if (yaml is Map) {
      return Map<String, dynamic>.from(
        yaml.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
  } catch (_) {
    // Ignore
  }
  return {};
}

/// Converts a YamlMap to Map<String, dynamic>.
Map<String, dynamic> _convertYamlMap(YamlMap yamlMap) {
  final result = <String, dynamic>{};
  for (final entry in yamlMap.entries) {
    final key = entry.key.toString();
    final value = entry.value;
    if (value is YamlMap) {
      result[key] = _convertYamlMap(value);
    } else if (value is YamlList) {
      result[key] = value.toList();
    } else {
      result[key] = value;
    }
  }
  return result;
}
