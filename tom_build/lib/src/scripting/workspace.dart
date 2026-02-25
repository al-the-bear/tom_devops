/// Workspace utilities for scripting.
///
/// Provides convenient static methods for accessing workspace metadata
/// and tool context information.
library;

import '../tools/tool_context.dart';

export '../tools/tool_context.dart'
    show PlatformInfo, OperatingSystem, CpuArchitecture;
export '../tools/workspace_info.dart'
    show WorkspaceInfo, WorkspaceGroup, WorkspaceProject, MetadataModes, MetadataMode;

/// Workspace helper for D4rt scripts.
///
/// Provides simplified access to workspace metadata, projects, and
/// platform information through static methods.
///
/// ## Example
/// ```dart
/// // Get workspace root path
/// final root = TomWs.path;
///
/// // Check if a project exists
/// if (TomWs.hasProject('tom_core')) {
///   final project = TomWs.project('tom_core');
///   print('Found project: ${project.name}');
/// }
///
/// // Get all projects in a group
/// final buildTools = TomWs.projectsInGroup('Build');
///
/// // Get platform info
/// print('Running on ${TomWs.platform.os}');
/// ```
class TomWs {
  TomWs._(); // Prevent instantiation

  // ===========================================================================
  // Context access
  // ===========================================================================

  /// Returns the current ToolContext.
  ///
  /// Throws if the context has not been loaded.
  static ToolContext get context => ToolContext.current;

  /// Returns the WorkspaceInfo.
  static WorkspaceInfo get info => context.workspaceInfo;

  /// Returns the workspace root path.
  static String get path => context.workspacePath;

  /// Returns platform information.
  static PlatformInfo get platform => context.platformInfo;

  // ===========================================================================
  // Project access
  // ===========================================================================

  /// Returns all projects in the workspace as a list.
  static List<WorkspaceProject> get projects => info.projects.values.toList();

  /// Returns the projects map.
  static Map<String, WorkspaceProject> get projectsMap => info.projects;

  /// Returns all groups in the workspace as a list.
  static List<WorkspaceGroup> get groups => info.groups.values.toList();

  /// Returns the groups map.
  static Map<String, WorkspaceGroup> get groupsMap => info.groups;

  /// Returns the workspace name.
  static String? get name => info.name;

  /// Returns the workspace build order.
  static List<String> get buildOrder => info.buildOrder;

  /// Finds a project by name.
  ///
  /// Returns `null` if not found.
  static WorkspaceProject? project(String name) => info.projects[name];

  /// Checks if a project exists.
  static bool hasProject(String name) => info.projects.containsKey(name);

  /// Returns all projects in a group.
  static List<WorkspaceProject> projectsInGroup(String groupName) {
    final group = info.groups[groupName];
    if (group == null) return [];
    return group.projects
        .map((name) => info.projects[name])
        .whereType<WorkspaceProject>()
        .toList();
  }

  /// Finds a group by name.
  ///
  /// Returns `null` if not found.
  static WorkspaceGroup? group(String name) => info.groups[name];

  /// Checks if a group exists.
  static bool hasGroup(String name) => info.groups.containsKey(name);

  /// Returns project names for all projects.
  static List<String> get projectNames => info.projects.keys.toList();

  /// Returns group names for all groups.
  static List<String> get groupNames => info.groups.keys.toList();

  // ===========================================================================
  // Filtering
  // ===========================================================================

  /// Returns projects matching a predicate.
  static List<WorkspaceProject> where(bool Function(WorkspaceProject) test) {
    return projects.where(test).toList();
  }

  /// Returns projects of a specific type.
  static List<WorkspaceProject> ofType(String type) {
    return projects.where((p) => p.type == type).toList();
  }

  /// Returns Dart package projects.
  static List<WorkspaceProject> get dartPackages =>
      projects.where((p) => p.type == 'dart_package').toList();

  /// Returns Flutter app projects.
  static List<WorkspaceProject> get flutterApps =>
      projects.where((p) => p.type == 'flutter_app').toList();

  /// Returns Dart server projects.
  static List<WorkspaceProject> get dartServers =>
      projects.where((p) => p.type == 'dart_server').toList();

  /// Returns VS Code extension projects.
  static List<WorkspaceProject> get vscodeExtensions =>
      projects.where((p) => p.type == 'vscode_extension').toList();

  // ===========================================================================
  // Platform checks
  // ===========================================================================

  /// Returns `true` if running on macOS.
  static bool get isMacOS => platform.os == OperatingSystem.macos;

  /// Returns `true` if running on Linux.
  static bool get isLinux => platform.os == OperatingSystem.linux;

  /// Returns `true` if running on Windows.
  static bool get isWindows => platform.os == OperatingSystem.windows;

  /// Returns the operating system name.
  static String get osName => platform.os.name;

  /// Returns the CPU architecture name.
  static String get arch => platform.architecture.name;

  // ===========================================================================
  // Context management
  // ===========================================================================

  /// Loads or reloads the tool context.
  ///
  /// Call this after workspace changes to refresh metadata.
  static Future<void> reload() => ToolContext.reload();

  /// Checks if the context has been loaded.
  static bool get isLoaded {
    try {
      // Attempt to access the context
      ToolContext.current;
      return true;
    } catch (_) {
      return false;
    }
  }
}
