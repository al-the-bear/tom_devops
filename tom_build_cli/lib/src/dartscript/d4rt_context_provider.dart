/// D4rt Context Provider Abstraction.
///
/// Provides pluggable context injection for D4rt script execution.
/// This abstraction allows D4rt to be used in various contexts:
/// - Action execution (with project, action, workspace)
/// - Template processing (with workspace, modes)
/// - Standalone usage (with custom map)
library;

import 'package:tom_build/tom_build.dart';
import '../tom/cli/workspace_context.dart';
import '../tom/mode/mode_resolver.dart';
import 'bridge_configuration.dart';

// Re-export BridgeConfiguration
export 'bridge_configuration.dart' show BridgeConfiguration, BridgeModuleRegistry;

// =============================================================================
// D4RT CONTEXT PROVIDER INTERFACE
// =============================================================================

/// Abstract provider for D4rt execution context.
///
/// Implementations provide context data for different use cases.
/// The context map is injected into D4rt before script execution.
///
/// ## Usage
///
/// ```dart
/// // For action execution
/// final provider = ActionContextProvider(
///   workspacePath: '/path/to/workspace',
///   projectName: 'my_project',
///   actionName: 'build',
/// );
///
/// // For template processing
/// final provider = TemplateContextProvider(
///   workspace: workspace,
///   resolvedModes: modes,
/// );
///
/// // For standalone/custom usage
/// final provider = StandaloneContextProvider({
///   'customKey': 'customValue',
/// });
/// ```
abstract interface class D4rtContextProvider {
  /// Get the context map to inject into D4rt.
  ///
  /// These values will be available in D4rt scripts via zone values.
  Map<String, dynamic> getContext();

  /// Get the import path for bridged classes.
  ///
  /// This is automatically imported in D4rt scripts.
  /// Defaults to 'package:tom_build/tom.dart'.
  String get importPath;

  /// Get the bridge configuration for additional bridges.
  ///
  /// Override to add custom bridges beyond the standard ones.
  BridgeConfiguration? getBridgeConfiguration();

  /// Whether to initialize the global `tom` context object.
  ///
  /// When true, the global `tom` object is initialized with workspace data.
  /// This should be true for action execution contexts.
  bool get initializeTomContext;

  /// The workspace to use for tom context initialization.
  ///
  /// Only used when [initializeTomContext] is true.
  TomWorkspace? get workspace;

  /// The workspace context to use for tom context initialization.
  ///
  /// Only used when [initializeTomContext] is true.
  WorkspaceContext? get workspaceContext;

  /// The current project for tom context initialization.
  ///
  /// Only used when [initializeTomContext] is true.
  TomProject? get currentProject;

  /// The workspace path for tom context initialization.
  ///
  /// Only used when [initializeTomContext] is true.
  String? get workspacePath;
}

/// Mixin providing default implementations for [D4rtContextProvider].
mixin D4rtContextProviderDefaults implements D4rtContextProvider {
  @override
  String get importPath => 'package:tom_build/tom.dart';

  @override
  BridgeConfiguration? getBridgeConfiguration() => null;

  @override
  bool get initializeTomContext => false;

  @override
  TomWorkspace? get workspace => null;

  @override
  WorkspaceContext? get workspaceContext => null;

  @override
  TomProject? get currentProject => null;

  @override
  String? get workspacePath => null;
}

// =============================================================================
// ACTION CONTEXT PROVIDER
// =============================================================================

/// Context provider for action execution.
///
/// Provides full context for action execution including:
/// - Workspace and project information
/// - Action name and parameters
/// - Global `tom` object initialization
///
/// ## Usage
///
/// ```dart
/// final provider = ActionContextProvider(
///   workspacePath: '/path/to/workspace',
///   projectName: 'my_project',
///   actionName: 'build',
///   workspace: workspace,
///   project: project,
/// );
/// ```
class ActionContextProvider
    with D4rtContextProviderDefaults
    implements D4rtContextProvider {
  /// Path to the workspace root.
  @override
  final String workspacePath;

  /// Name of the current project.
  final String projectName;

  /// Name of the current action.
  final String actionName;

  /// Parsed workspace configuration.
  @override
  final TomWorkspace? workspace;

  /// Current project configuration.
  @override
  final TomProject? currentProject;

  /// Runtime workspace context.
  @override
  final WorkspaceContext? workspaceContext;

  /// Additional context variables.
  final Map<String, dynamic> additionalContext;

  /// Bridge configuration for additional bridges.
  final BridgeConfiguration? _bridgeConfiguration;

  /// Creates an action context provider.
  ActionContextProvider({
    required this.workspacePath,
    required this.projectName,
    required this.actionName,
    this.workspace,
    this.currentProject,
    this.workspaceContext,
    this.additionalContext = const {},
    BridgeConfiguration? bridgeConfiguration,
  }) : _bridgeConfiguration = bridgeConfiguration;

  @override
  Map<String, dynamic> getContext() => {
        'workspacePath': workspacePath,
        'projectName': projectName,
        'actionName': actionName,
        if (workspace != null) 'workspace': workspace!.toYaml(),
        if (currentProject != null) 'project': currentProject!.toYaml(),
        ...additionalContext,
      };

  @override
  bool get initializeTomContext => true;

  @override
  BridgeConfiguration? getBridgeConfiguration() => _bridgeConfiguration;
}

// =============================================================================
// TEMPLATE CONTEXT PROVIDER
// =============================================================================

/// Context provider for template processing.
///
/// Provides context for Tomplate `$D4{}` placeholder resolution:
/// - Workspace configuration
/// - Project configuration
/// - Resolved modes
///
/// ## Usage
///
/// ```dart
/// final provider = TemplateContextProvider(
///   workspace: workspace,
///   project: project,
///   resolvedModes: modes,
/// );
/// ```
class TemplateContextProvider
    with D4rtContextProviderDefaults
    implements D4rtContextProvider {
  /// Parsed workspace configuration.
  @override
  final TomWorkspace? workspace;

  /// Current project configuration.
  @override
  TomProject? get currentProject => project;

  /// Current project configuration (alias for currentProject).
  final TomProject? project;

  /// Resolved mode state.
  final ResolvedModes? resolvedModes;

  /// Optional workspace path.
  @override
  final String? workspacePath;

  /// Creates a template context provider.
  TemplateContextProvider({
    this.workspace,
    this.project,
    this.resolvedModes,
    this.workspacePath,
  });

  @override
  Map<String, dynamic> getContext() => {
        if (workspace != null) 'workspace': workspace!.toYaml(),
        if (project != null) 'project': project!.toYaml(),
        if (resolvedModes != null)
          'modes': resolvedModes!.activeModes.toList(),
        if (resolvedModes != null)
          'modeTypeValues': resolvedModes!.modeTypeValues,
      };

  @override
  bool get initializeTomContext => workspace != null;
}

// =============================================================================
// STANDALONE CONTEXT PROVIDER
// =============================================================================

/// Context provider for standalone/custom usage.
///
/// Provides a simple way to inject arbitrary context into D4rt
/// without requiring workspace or action context.
///
/// ## Usage
///
/// ```dart
/// final provider = StandaloneContextProvider({
///   'customKey': 'customValue',
///   'config': {'setting': true},
/// });
/// ```
class StandaloneContextProvider
    with D4rtContextProviderDefaults
    implements D4rtContextProvider {
  /// Custom context map.
  final Map<String, dynamic> customContext;

  /// Bridge configuration for additional bridges.
  final BridgeConfiguration? _bridgeConfiguration;

  /// Custom import path.
  final String _importPath;

  /// Creates a standalone context provider.
  StandaloneContextProvider(
    this.customContext, {
    BridgeConfiguration? bridgeConfiguration,
    String? importPath,
  })  : _bridgeConfiguration = bridgeConfiguration,
        _importPath = importPath ?? 'package:tom_build/tom.dart';

  @override
  Map<String, dynamic> getContext() => customContext;

  @override
  BridgeConfiguration? getBridgeConfiguration() => _bridgeConfiguration;

  @override
  String get importPath => _importPath;
}

// =============================================================================
// COMPOSITE CONTEXT PROVIDER
// =============================================================================

/// Context provider that combines multiple providers.
///
/// Useful when you need context from multiple sources.
/// Later providers override earlier ones for duplicate keys.
///
/// ## Usage
///
/// ```dart
/// final provider = CompositeContextProvider([
///   TemplateContextProvider(workspace: workspace),
///   StandaloneContextProvider({'override': 'value'}),
/// ]);
/// ```
class CompositeContextProvider
    with D4rtContextProviderDefaults
    implements D4rtContextProvider {
  /// List of providers to combine.
  final List<D4rtContextProvider> providers;

  /// Creates a composite context provider.
  CompositeContextProvider(this.providers);

  @override
  Map<String, dynamic> getContext() {
    final combined = <String, dynamic>{};
    for (final provider in providers) {
      combined.addAll(provider.getContext());
    }
    return combined;
  }

  @override
  BridgeConfiguration? getBridgeConfiguration() {
    // Combine all bridge configurations
    final configs = providers
        .map((p) => p.getBridgeConfiguration())
        .whereType<BridgeConfiguration>()
        .toList();
    if (configs.isEmpty) return null;
    if (configs.length == 1) return configs.first;
    
    // Merge all configurations
    return BridgeConfiguration(
      bridgeModules: configs.expand((c) => c.bridgeModules).toList(),
      additionalClasses: configs.expand((c) => c.additionalClasses).toList(),
      additionalClassImportPath: configs
          .map((c) => c.additionalClassImportPath)
          .whereType<String>()
          .firstOrNull,
    );
  }

  @override
  bool get initializeTomContext =>
      providers.any((p) => p.initializeTomContext);

  @override
  TomWorkspace? get workspace =>
      providers.map((p) => p.workspace).whereType<TomWorkspace>().firstOrNull;

  @override
  WorkspaceContext? get workspaceContext => providers
      .map((p) => p.workspaceContext)
      .whereType<WorkspaceContext>()
      .firstOrNull;

  @override
  TomProject? get currentProject =>
      providers.map((p) => p.currentProject).whereType<TomProject>().firstOrNull;

  @override
  String? get workspacePath =>
      providers.map((p) => p.workspacePath).whereType<String>().firstOrNull;
}
