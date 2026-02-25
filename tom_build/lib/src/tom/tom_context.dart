/// Tom Context - Global D4rt scripting context for Tom CLI.
///
/// This module provides a central `tom` object that is available in D4rt scripts
/// for accessing workspace data, executing commands, and managing configurations.
///
/// ## Usage in D4rt Scripts
///
/// ```dart
/// import 'package:tom_build/tom.dart';
///
/// void main() {
///   // Access workspace configuration
///   print(tom.workspace.name);
///   print(tom.projectInfo);
///   print(tom.groups);
///
///   // Access current project (if in project context)
///   print(tom.project?.name);
///
///   // Execute commands (using Shell static methods)
///   Shell.run('dart analyze');
///
///   // Access environment
///   print(tom.env['HOME']);
/// }
/// ```
library;
import 'dart:io';

import 'file_object_model/file_object_model.dart';

// Note: WorkspaceContext is CLI-internal (in tom_build_cli).
// This field uses Object? to avoid circular dependencies.

// =============================================================================
// TOM CONTEXT - GLOBAL D4RT SCRIPTING OBJECT
// =============================================================================

/// Global Tom context instance available in D4rt scripts.
///
/// This object provides access to workspace data, project information,
/// and utility functions for D4rt scripts. It is initialized before
/// any script execution and exposed via the barrel file.
///
/// **In D4rt scripts:**
/// ```dart
/// import 'package:tom_build/tom.dart';
///
/// // Access workspace
/// final wsName = tom.workspace.name;
/// final projects = tom.projects;
///
/// // Access current project (when running in project context)
/// final projectName = tom.project?.name;
///
/// // Run shell commands
/// tom.shell.run(command: 'dart analyze');
///
/// // Access environment variables
/// final home = tom.env['HOME'];
///
/// // Check current working directory
/// final cwd = tom.cwd;
/// ```
TomContext tom = TomContext._uninitialized();

/// Central context object for D4rt scripts in Tom CLI.
///
/// Provides unified access to:
/// - Workspace configuration (`tom.workspace`)
/// - Projects (`tom.projectInfo`)
/// - Groups (`tom.groups`)
/// - Current project (`tom.project`)
/// - Environment variables (`tom.env`)
/// - File system utilities
///
/// For shell commands, use the `Shell` static methods:
/// ```dart
/// Shell.run('dart analyze');
/// Shell.runAll(['dart analyze', 'dart test']);
/// ```
class TomContext {
  /// Returns the current global `tom` context.
  ///
  /// This static getter allows D4rt scripts to access the global `tom` instance
  /// via `TomContext.current` when the import-based `tom` variable is not
  /// available (D4rt cannot resolve top-level getters from imports).
  ///
  /// The returned context may be uninitialized if no workspace has been set up.
  /// Use `isInitialized` to check before accessing workspace properties.
  static TomContext get current => tom;

  /// The loaded workspace configuration.
  ///
  /// Contains all settings from `tom_workspace.yaml` including:
  /// - Mode definitions
  /// - Action definitions
  /// - Project types
  /// - Dependency versions
  final TomWorkspace? _workspace;

  /// The workspace context with runtime state.
  /// Type is Object? to avoid CLI dependency (actual type is WorkspaceContext from tom_build_cli).
  final Object? _workspaceContext;

  /// The current project (if operating in project context).
  final TomProject? _currentProject;

  /// The workspace root directory path.
  final String? _workspacePath;

  /// Whether this context has been properly initialized.
  final bool _initialized;

  /// Creates an uninitialized context.
  ///
  /// Used as the default value for the global `tom` variable before
  /// initialization. Accessing properties will throw helpful errors.
  TomContext._uninitialized()
      : _workspace = null,
        _workspaceContext = null,
        _currentProject = null,
        _workspacePath = null,
        _initialized = false;

  /// Creates a fully initialized Tom context.
  ///
  /// Called by D4rtInstance during script initialization.
  TomContext({
    required TomWorkspace workspace,
    Object? workspaceContext,
    TomProject? currentProject,
    String? workspacePath,
  })  : _workspace = workspace,
        _workspaceContext = workspaceContext,
        _currentProject = currentProject,
        _workspacePath = workspacePath ?? Directory.current.path,
        _initialized = true;

  /// Whether this context has been properly initialized.
  ///
  /// Returns `false` before D4rt initialization, `true` after.
  bool get isInitialized => _initialized;

  // ===========================================================================
  // WORKSPACE ACCESS
  // ===========================================================================

  /// The workspace configuration from `tom_workspace.yaml`.
  ///
  /// Throws [StateError] if accessed before initialization.
  TomWorkspace get workspace {
    _checkInitialized('workspace');
    return _workspace!;
  }

  /// The workspace context with runtime state.
  ///
  /// May be null if not running in a full workspace context.
  /// Actual type is WorkspaceContext from tom_build_cli.
  Object? get workspaceContext => _workspaceContext;

  /// The workspace root directory path.
  String get workspacePath {
    _checkInitialized('workspacePath');
    return _workspacePath!;
  }

  /// The current working directory.
  String get cwd => Directory.current.path;

  // ===========================================================================
  // PROJECT ACCESS
  // ===========================================================================

  /// The current project (if operating in project context).
  ///
  /// Returns `null` if not in a project-specific context.
  TomProject? get project => _currentProject;

  /// All projects defined in project-info.
  ///
  /// Returns a map of project name to [ProjectEntry].
  Map<String, ProjectEntry> get projectInfo {
    _checkInitialized('projectInfo');
    return _workspace!.projectInfo;
  }

  /// All group definitions from the workspace.
  Map<String, GroupDef> get groups {
    _checkInitialized('groups');
    return _workspace!.groups;
  }

  /// All action definitions from the workspace.
  Map<String, ActionDef> get actions {
    _checkInitialized('actions');
    return _workspace!.actions;
  }

  /// Mode definitions by mode type (e.g., 'environment', 'execution').
  ///
  /// Returns a map of mode type name to [ModeDefinitions].
  /// Example:
  /// ```dart
  /// final envModes = tom.modeDefinitions['environment'];
  /// final localDef = envModes?.definitions['local'];
  /// ```
  Map<String, ModeDefinitions> get modeDefinitions {
    _checkInitialized('modeDefinitions');
    return _workspace!.modeDefinitions;
  }

  // ===========================================================================
  // CONFIGURATION ACCESS
  // ===========================================================================

  /// Dependency version constraints from `deps:` section.
  Map<String, String> get deps {
    _checkInitialized('deps');
    return _workspace!.deps;
  }

  /// Dev dependency versions from `deps-dev:` section.
  Map<String, String> get depsDev {
    _checkInitialized('depsDev');
    return _workspace!.depsDev;
  }

  /// Workspace modes configuration.
  WorkspaceModes? get workspaceModes {
    _checkInitialized('workspaceModes');
    return _workspace!.workspaceModes;
  }

  /// Project type definitions.
  Map<String, ProjectTypeDef> get projectTypes {
    _checkInitialized('projectTypes');
    return _workspace!.projectTypes;
  }

  /// Pipeline definitions.
  Map<String, Pipeline> get pipelines {
    _checkInitialized('pipelines');
    return _workspace!.pipelines;
  }

  /// Custom tags (any non-standard keys in tom_workspace.yaml).
  Map<String, dynamic> get customTags {
    _checkInitialized('customTags');
    return _workspace!.customTags;
  }

  // ===========================================================================
  // ENVIRONMENT
  // ===========================================================================

  /// Environment variables map.
  ///
  /// Provides read access to all environment variables.
  /// Example:
  /// ```dart
  /// final home = tom.env['HOME'];
  /// final path = tom.env['PATH'];
  /// ```
  Map<String, String> get env => Platform.environment;

  // ===========================================================================
  // UTILITY METHODS
  // ===========================================================================

  /// Gets a project info by name.
  ///
  /// Returns `null` if the project doesn't exist.
  ProjectEntry? getProjectInfo(String name) {
    _checkInitialized('getProjectInfo');
    return _workspace!.projectInfo[name];
  }

  /// Gets a group definition by name.
  ///
  /// Returns `null` if the group doesn't exist.
  GroupDef? getGroup(String name) {
    _checkInitialized('getGroup');
    return _workspace!.groups[name];
  }

  /// Gets an action definition by name.
  ///
  /// Returns `null` if the action doesn't exist.
  ActionDef? getAction(String name) {
    _checkInitialized('getAction');
    return _workspace!.actions[name];
  }

  /// Gets a dependency version constraint.
  ///
  /// Returns `null` if the dependency isn't defined.
  String? getDep(String name) {
    _checkInitialized('getDep');
    return _workspace!.deps[name];
  }

  /// Gets a custom tag value.
  ///
  /// Returns `null` if the tag doesn't exist.
  dynamic getCustomTag(String key) {
    _checkInitialized('getCustomTag');
    return _workspace!.customTags[key];
  }

  // ===========================================================================
  // INTERNAL HELPERS
  // ===========================================================================

  void _checkInitialized(String property) {
    if (!_initialized) {
      throw StateError(
        'TomContext not initialized. Cannot access "$property". '
        'Make sure D4rt is properly initialized with workspace context.',
      );
    }
  }

  @override
  String toString() {
    if (!_initialized) {
      return 'TomContext(uninitialized)';
    }
    return 'TomContext(workspace: ${_workspace?.name}, '
        'project: ${_currentProject?.name}, '
        'cwd: $cwd)';
  }
}

// =============================================================================
// INITIALIZATION
// =============================================================================

/// Initializes the global `tom` context.
///
/// Called by D4rtInstance before executing scripts. This sets up the
/// global context so scripts can access workspace data via `tom.workspace`,
/// `tom.project`, etc.
///
/// Example:
/// ```dart
/// // During D4rt initialization
/// initializeTomContext(
///   workspace: loadedWorkspace,
///   workspacePath: '/path/to/workspace',
///   currentProject: currentProject,
/// );
///
/// // Now D4rt scripts can use:
/// // tom.workspace.name
/// // tom.project?.name
/// // tom.shell.run(...)
/// ```
void initializeTomContext({
  required TomWorkspace workspace,
  Object? workspaceContext,
  TomProject? currentProject,
  String? workspacePath,
}) {
  tom = TomContext(
    workspace: workspace,
    workspaceContext: workspaceContext,
    currentProject: currentProject,
    workspacePath: workspacePath,
  );
}

/// Resets the global `tom` context to uninitialized state.
///
/// Useful for testing or when switching workspaces.
void resetTomContext() {
  tom = TomContext._uninitialized();
}
