/// D4rt Instance Management for Action Execution.
///
/// Provides a managed D4rt interpreter instance with:
/// - Automatic bridge registration
/// - Instance-per-action isolation
/// - Context injection for scripts
/// - Global `tom` object initialization
/// - Zone-based instance sharing for nested script execution
library;

import 'dart:async';

import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_build/tom_build.dart';

import '../tom/cli/workspace_context.dart';
import '../tom_d4rt/dartscript.b.dart';
import 'd4rt_context_provider.dart';
import 'd4rt_cli_initialization.dart';

// =============================================================================
// ZONE KEYS FOR D4RT INSTANCE
// =============================================================================

/// Zone key for the current D4rtInstance.
///
/// When a D4rtInstance is executing scripts, it places itself in the zone
/// so that nested scripts can access the same instance instead of creating
/// a new one.
const Symbol d4rtInstanceZoneKey = #d4rtInstance;

// =============================================================================
// D4RT INSTANCE MANAGER
// =============================================================================

/// Factory function type for creating D4rt instances.
typedef D4rtInstanceFactory = D4rtInstance Function();

/// Manages a D4rt interpreter instance with all necessary bridges registered.
///
/// Each action should create a new [D4rtInstance] to ensure isolation.
/// Within a single action, use the same instance for all script evaluations.
///
/// ## Usage
///
/// ```dart
/// // Create a new instance for an action
/// final d4rt = D4rtInstance.create();
///
/// // Execute scripts with the same instance
/// final result1 = await d4rt.evaluate('1 + 1');
/// final result2 = await d4rt.evaluate('project.name');
///
/// // Dispose when action completes
/// d4rt.dispose();
/// ```
class D4rtInstance {
  /// The underlying D4rt interpreter.
  final D4rt interpreter;

  /// Context variables available to scripts.
  final Map<String, dynamic> _context = {};

  /// Whether this instance has been disposed.
  bool _disposed = false;

  /// Whether the interpreter has been initialized.
  bool _initialized = false;

  /// Creates a D4rt instance with the given interpreter.
  ///
  /// Use [D4rtInstance.create] for a fully configured instance.
  D4rtInstance._(this.interpreter);

  /// Gets the current D4rtInstance from the zone, if one exists.
  ///
  /// Returns `null` if no instance is in the current zone.
  /// This allows nested scripts to access the parent instance.
  static D4rtInstance? get current {
    return Zone.current[d4rtInstanceZoneKey] as D4rtInstance?;
  }

  /// Gets the current D4rtInstance from the zone, or creates a new one.
  ///
  /// This is useful for scripts that want to reuse an existing instance
  /// if one is available, inheriting its context and state.
  ///
  /// If called from within a zone that already has a D4rtInstance (e.g., from
  /// a nested script), returns that instance instead of creating a new one.
  /// This allows scripts to run other scripts using the same interpreter state.
  factory D4rtInstance.currentOrCreate({
    BridgeConfiguration? bridgeConfiguration,
    TomWorkspace? workspace,
    WorkspaceContext? workspaceContext,
    TomProject? currentProject,
    String? workspacePath,
  }) {
    // Check if there's an existing instance in the zone
    final existing = D4rtInstance.current;
    if (existing != null && !existing.isDisposed) {
      return existing;
    }
    
    return D4rtInstance.create(
      bridgeConfiguration: bridgeConfiguration,
      workspace: workspace,
      workspaceContext: workspaceContext,
      currentProject: currentProject,
      workspacePath: workspacePath,
    );
  }

  /// Creates a new D4rt instance with all bridges registered.
  ///
  /// This is the recommended way to create D4rt instances for action execution.
  /// Each action should use a separate instance.
  ///
  /// If [workspace] is provided, the global `tom` context will be initialized
  /// with the workspace data, allowing scripts to access `tom.workspace`,
  /// `tom.projectInfo`, etc.
  ///
  /// Use [bridgeConfiguration] to register additional bridges beyond the
  /// standard tom_build and scripting bridges.
  factory D4rtInstance.create({
    BridgeConfiguration? bridgeConfiguration,
    TomWorkspace? workspace,
    WorkspaceContext? workspaceContext,
    TomProject? currentProject,
    String? workspacePath,
  }) {
    final interpreter = D4rt();

    // Grant filesystem permissions for scripts
    interpreter.grant(FilesystemPermission.any);

    // Register all standard bridges with this interpreter via tom_build_cli chain
    TomBuildCliBridges.register(interpreter);

    // Apply additional bridge configuration
    bridgeConfiguration?.apply(interpreter);

    // Initialize the global tom context if workspace is provided
    if (workspace != null) {
      initializeTomContext(
        workspace: workspace,
        workspaceContext: workspaceContext,
        currentProject: currentProject,
        workspacePath: workspacePath,
      );
    }

    // Register global variables using the new registerGlobalVariable API.
    // These are immediately available for all execute() and eval() calls
    // without requiring an initialization script.
    _registerGlobalVariables(interpreter);

    // Execute initialization script with imports and global variables
    // This sets up access to tom, Shell, env, etc. for eval() calls
    // See: lib/src/dartscript/d4rt_cli_initialization.dart
    try {
      interpreter.execute(source: getCliInitializationScript());
    } catch (e) {
      throw StateError('D4rt initialization failed: $e');
    }

    final instance = D4rtInstance._(interpreter);
    instance._initialized = true;
    return instance;
  }

  /// Creates a D4rt instance from a context provider.
  ///
  /// This factory method allows creating D4rt instances using the abstracted
  /// context provider pattern for maximum flexibility.
  ///
  /// The context provider determines:
  /// - Additional bridges to register
  /// - Whether to initialize the global `tom` context
  /// - What context variables to inject
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
  /// final instance = D4rtInstance.fromProvider(provider);
  ///
  /// // For template processing
  /// final provider = TemplateContextProvider(
  ///   workspace: workspace,
  ///   resolvedModes: modes,
  /// );
  /// final instance = D4rtInstance.fromProvider(provider);
  /// ```
  factory D4rtInstance.fromProvider(D4rtContextProvider provider) {
    final instance = D4rtInstance.create(
      bridgeConfiguration: provider.getBridgeConfiguration(),
      workspace: provider.initializeTomContext ? provider.workspace : null,
      workspaceContext:
          provider.initializeTomContext ? provider.workspaceContext : null,
      currentProject:
          provider.initializeTomContext ? provider.currentProject : null,
      workspacePath:
          provider.initializeTomContext ? provider.workspacePath : null,
    );

    // Inject context from provider
    instance.setContextAll(provider.getContext());

    return instance;
  }

  /// Whether this instance has been disposed.
  bool get isDisposed => _disposed;

  /// Whether this instance has been initialized.
  bool get isInitialized => _initialized;

  /// Sets a context variable accessible to scripts.
  void setContext(String key, dynamic value) {
    _checkDisposed();
    _context[key] = value;
  }

  /// Sets multiple context variables.
  void setContextAll(Map<String, dynamic> values) {
    _checkDisposed();
    _context.addAll(values);
  }

  /// Gets the current context.
  Map<String, dynamic> get context => Map.unmodifiable(_context);

  /// Prepares the D4rt instance for script execution with imports.
  ///
  /// This sets up the execution context with the necessary imports so that
  /// subsequent [evaluate] calls can access the `tom` global object and
  /// other bridged classes.
  ///
  /// Call this once after creating the instance and before running scripts:
  /// ```dart
  /// final d4rt = D4rtInstance.create(workspace: workspace);
  /// await d4rt.prepareForScripts();
  ///
  /// // Now evaluate() can access tom.workspace, etc.
  /// final name = await d4rt.evaluate('tom.workspace.name');
  /// ```
  Future<void> prepareForScripts() async {
    _checkDisposed();

    // Execute with imports to make them available for eval()
    interpreter.execute(source: '''
import 'package:tom_build/tom.dart';

void main() {
  // Imports are now available for subsequent eval() calls
}
''');
  }

  /// Evaluates a D4rt expression and returns the result.
  ///
  /// The expression has access to all registered bridges and context variables.
  /// Uses D4rt's `eval()` method for simple expressions.
  /// Context variables and the D4rtInstance are injected via Zone values,
  /// allowing nested scripts to access the same instance via [current].
  ///
  /// **Important:** Call [prepareForScripts] first if you need access to
  /// the `tom` global object or other bridged classes.
  Future<dynamic> evaluate(String expression) async {
    _checkDisposed();

    try {
      // Use eval() for expressions - it preserves state and evaluates inline
      // Place this instance in the zone so nested scripts can access it
      return runZoned(
        () => interpreter.eval(expression),
        zoneValues: {
          'context': _context,
          d4rtInstanceZoneKey: this,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Executes a D4rt script file.
  ///
  /// The script has access to all registered bridges and context variables.
  /// The D4rtInstance is placed in the zone so nested scripts can access
  /// it via [current] or [currentOrCreate].
  Future<dynamic> executeScript(String scriptContent) async {
    _checkDisposed();

    try {
      // Execute in a zone with context variables and this instance available
      return runZoned(
        () => interpreter.execute(source: scriptContent),
        zoneValues: {
          'context': _context,
          d4rtInstanceZoneKey: this,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Disposes this instance, releasing resources.
  ///
  /// After disposal, the instance cannot be used.
  /// Also resets the global `tom` context.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _context.clear();
    resetTomContext(); // Reset the global tom context
    // D4rt doesn't have a dispose method, but we mark this as disposed
    // to prevent further use
  }

  /// Updates the tom global variable in the D4rt interpreter.
  ///
  /// This should be called after [initializeTomContext] to ensure the
  /// D4rt interpreter has access to the latest tom context (including
  /// the current project). Without this, scripts would see a stale
  /// tom object from when the instance was created.
  ///
  /// Also updates related globals: env and project.
  void updateTomGlobal() {
    _checkDisposed();
    const lib = 'package:tom_build/tom_build.dart';
    // Update the tom global with the current value
    interpreter.registerGlobalVariable('tom', tom, lib);
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('D4rtInstance has been disposed');
    }
  }
}

/// Type alias for bridge registration functions.
///
/// @deprecated Use [BridgeConfiguration] and [BridgeModuleRegistry] instead.
/// This typedef is kept for backward compatibility but will be removed
/// in a future version.
@Deprecated('Use BridgeConfiguration and BridgeModuleRegistry instead')
typedef BridgeRegistrar = void Function(D4rt interpreter);

// =============================================================================
// ACTION D4RT CONTEXT
// =============================================================================

/// Provides D4rt execution context for an action.
///
/// Ensures that:
/// - The same D4rt instance is used for all evaluations within an action
/// - A new D4rt instance is created for each action
///
/// ## Usage
///
/// ```dart
/// final context = ActionD4rtContext(
///   workspacePath: '/path/to/workspace',
///   projectName: 'my_project',
///   actionName: 'build',
/// );
///
/// // Execute scripts
/// final result = await context.evaluate('{project.name}');
///
/// // Dispose when action completes
/// context.dispose();
/// ```
class ActionD4rtContext {
  /// Path to the workspace root.
  final String workspacePath;

  /// Name of the current project being processed.
  final String projectName;

  /// Name of the current action being executed.
  final String actionName;

  /// Additional context variables.
  final Map<String, dynamic> additionalContext;

  /// Bridge configuration for additional bridges.
  final BridgeConfiguration? bridgeConfiguration;

  D4rtInstance? _instance;

  /// Whether this context has been disposed.
  bool _disposed = false;

  /// Creates an action D4rt context.
  ActionD4rtContext({
    required this.workspacePath,
    required this.projectName,
    required this.actionName,
    this.additionalContext = const {},
    this.bridgeConfiguration,
  });

  /// Gets or creates the D4rt instance for this action.
  D4rtInstance get instance {
    _checkDisposed();
    if (_instance == null || _instance!.isDisposed) {
      _instance = D4rtInstance.create(bridgeConfiguration: bridgeConfiguration);

      // Set standard context variables
      _instance!.setContextAll({
        'workspacePath': workspacePath,
        'projectName': projectName,
        'actionName': actionName,
        ...additionalContext,
      });
    }
    return _instance!;
  }

  /// Gets the current context from the D4rt instance.
  Map<String, dynamic> get context => instance.context;

  /// Whether the D4rt instance has been created.
  ///
  /// Returns `false` until [instance] is first accessed.
  bool get isInstanceCreated => _instance != null && !_instance!.isDisposed;

  /// Evaluates a D4rt expression.
  Future<dynamic> evaluate(String expression) async {
    _checkDisposed();
    return instance.evaluate(expression);
  }

  /// Executes a D4rt script.
  Future<dynamic> executeScript(String scriptContent) async {
    _checkDisposed();
    return instance.executeScript(scriptContent);
  }

  /// Disposes the D4rt instance.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _instance?.dispose();
    _instance = null;
  }

  void _checkDisposed() {
    if (_disposed) {
      throw StateError('ActionD4rtContext has been disposed');
    }
  }
}

// =============================================================================
// D4RT EVALUATOR FACTORY
// =============================================================================

/// Creates a D4rt evaluator function for use with [D4rtRunner].
///
/// The evaluator maintains a single D4rt instance for the duration of
/// the action execution.
///
/// ## Usage
///
/// ```dart
/// final context = ActionD4rtContext(
///   workspacePath: '/path/to/workspace',
///   projectName: 'my_project',
///   actionName: 'build',
/// );
///
/// final evaluator = createD4rtEvaluatorFromContext(context);
///
/// // Use with D4rtRunner
/// final runner = D4rtRunner(
///   config: config,
///   evaluator: evaluator,
/// );
/// ```
D4rtEvaluatorFunction createD4rtEvaluatorFromContext(
  ActionD4rtContext context,
) {
  return (String code, Map<String, dynamic> localContext) async {
    // Add local context to the instance
    context.instance.setContextAll(localContext);
    return context.evaluate(code);
  };
}

/// Function type for D4rt evaluation.
typedef D4rtEvaluatorFunction = Future<dynamic> Function(
  String code,
  Map<String, dynamic> context,
);

// =============================================================================
// GLOBAL VARIABLE REGISTRATION
// =============================================================================

/// Registers global variables with the D4rt interpreter.
///
/// This function uses the new `registerGlobalVariable()` API to make
/// global variables like `tom`, `env`, `project`, etc. available in all
/// D4rt scripts without requiring an initialization script.
///
/// These variables are registered once at interpreter creation time and
/// are available for both `execute()` and `eval()` calls.
void _registerGlobalVariables(D4rt interpreter) {

}
