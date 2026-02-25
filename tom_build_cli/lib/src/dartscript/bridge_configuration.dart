/// Bridge configuration for D4rt instances.
///
/// Provides a way to configure which bridges are registered with a D4rt
/// interpreter without using function type parameters.
library;

import 'package:tom_d4rt/d4rt.dart';

/// Configuration for registering bridges with a D4rt interpreter.
///
/// This class replaces the `List<BridgeRegistrar>` parameter pattern,
/// providing a bridgeable way to configure additional bridges.
///
/// ## Usage
///
/// ```dart
/// // Create a configuration with bridge modules
/// final config = BridgeConfiguration(
///   bridgeModules: ['tom_build', 'my_custom'],
/// );
///
/// // Or with additional bridged classes
/// final config = BridgeConfiguration(
///   additionalClasses: [
///     myCustomBridgedClass,
///     anotherBridgedClass,
///   ],
///   additionalClassImportPath: 'package:my_app/bridges.dart',
/// );
///
/// // Apply to an interpreter
/// config.apply(interpreter);
/// ```
class BridgeConfiguration {
  /// Names of bridge modules to register.
  ///
  /// These correspond to registered bridge module names that can be
  /// looked up from a registry.
  final List<String> bridgeModules;

  /// Additional bridged classes to register directly.
  final List<BridgedClass> additionalClasses;

  /// Import path to use when registering additional classes.
  ///
  /// Required when [additionalClasses] is not empty.
  final String? additionalClassImportPath;

  /// Creates a bridge configuration.
  ///
  /// - [bridgeModules]: Names of bridge modules to register
  /// - [additionalClasses]: Direct bridged class instances to register
  /// - [additionalClassImportPath]: Import path for additional classes
  const BridgeConfiguration({
    this.bridgeModules = const [],
    this.additionalClasses = const [],
    this.additionalClassImportPath,
  });

  /// An empty configuration with no bridges.
  static const empty = BridgeConfiguration();

  /// Applies this configuration to a D4rt interpreter.
  ///
  /// Registers all configured bridge modules and additional classes.
  void apply(D4rt interpreter) {
    // Register bridge modules by name
    for (final moduleName in bridgeModules) {
      final registrar = BridgeModuleRegistry.get(moduleName);
      if (registrar != null) {
        registrar(interpreter);
      }
    }

    // Register additional classes directly
    if (additionalClasses.isNotEmpty) {
      final importPath = additionalClassImportPath ?? 'package:app/bridges.dart';
      for (final bridgedClass in additionalClasses) {
        interpreter.registerBridgedClass(bridgedClass, importPath);
      }
    }
  }

  /// Creates a new configuration with additional modules.
  BridgeConfiguration withModules(List<String> modules) {
    return BridgeConfiguration(
      bridgeModules: [...bridgeModules, ...modules],
      additionalClasses: additionalClasses,
      additionalClassImportPath: additionalClassImportPath,
    );
  }

  /// Creates a new configuration with additional classes.
  BridgeConfiguration withClasses(
    List<BridgedClass> classes, {
    String? importPath,
  }) {
    return BridgeConfiguration(
      bridgeModules: bridgeModules,
      additionalClasses: [...additionalClasses, ...classes],
      additionalClassImportPath: importPath ?? additionalClassImportPath,
    );
  }
}

/// Registry for bridge modules.
///
/// Bridge modules are registered by name and can be applied to D4rt
/// interpreters by referencing the name.
///
/// ## Usage
///
/// ```dart
/// // At app startup, register bridge modules
/// BridgeModuleRegistry.register('tom_build', (interpreter) {
///   TomBuildBridge.registerAllBridges(interpreter);
/// });
///
/// // Later, apply by name
/// final registrar = BridgeModuleRegistry.get('tom_build');
/// registrar?.call(interpreter);
/// ```
class BridgeModuleRegistry {
  static final Map<String, void Function(D4rt)> _registry = {};

  /// Registers a bridge module by name.
  ///
  /// The [registrar] function will be called with the interpreter
  /// when [apply] is called with this module name.
  static void register(String name, void Function(D4rt) registrar) {
    _registry[name] = registrar;
  }

  /// Gets the registrar for a module by name.
  ///
  /// Returns null if the module is not registered.
  static void Function(D4rt)? get(String name) {
    return _registry[name];
  }

  /// Checks if a module is registered.
  static bool isRegistered(String name) {
    return _registry.containsKey(name);
  }

  /// Gets all registered module names.
  static List<String> get registeredModules => _registry.keys.toList();

  /// Clears all registered modules.
  ///
  /// Primarily for testing purposes.
  static void clear() {
    _registry.clear();
  }
}
