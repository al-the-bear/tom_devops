/// Configuration merging utilities for Tom CLI.
///
/// Provides deep merge functionality for combining configuration layers
/// from workspace, group, and project levels.
library;

// =============================================================================
// CONFIG MERGER
// =============================================================================

/// Merges multiple configuration layers following the Tom merge sequence.
///
/// Merge order (later overrides earlier):
/// 1. Auto-detected values
/// 2. Project-type defaults
/// 3. Group overrides
/// 4. Workspace defaults (project-info:)
/// 5. Project overrides (tom_project.yaml)
/// 6. Global CLI parameters
/// 7. Group/Project CLI parameters
class ConfigMerger {
  /// Creates a new ConfigMerger.
  ConfigMerger();

  /// Deep merges [override] into [base], returning a new map.
  ///
  /// - Nested maps are merged recursively
  /// - Scalars from override replace base values
  /// - Lists are replaced entirely (not concatenated)
  /// - Keys only in override are added to result
  /// - Keys only in base are preserved
  Map<String, dynamic> deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    // Start with a deep copy of base to avoid mutations
    final result = <String, dynamic>{};
    for (final entry in base.entries) {
      result[entry.key] = _deepCopy(entry.value);
    }

    for (final entry in override.entries) {
      final key = entry.key;
      final overrideValue = entry.value;
      final baseValue = result[key];

      if (overrideValue is Map<String, dynamic> &&
          baseValue is Map<String, dynamic>) {
        // Recursively merge nested maps
        result[key] = deepMerge(baseValue, overrideValue);
      } else {
        // Override scalars and lists
        result[key] = _deepCopy(overrideValue);
      }
    }

    return result;
  }

  /// Merges a list of configurations in order.
  ///
  /// Later configurations override earlier ones.
  Map<String, dynamic> mergeAll(List<Map<String, dynamic>> configs) {
    if (configs.isEmpty) return {};
    if (configs.length == 1) return Map<String, dynamic>.from(configs.first);

    var result = <String, dynamic>{};
    for (final config in configs) {
      result = deepMerge(result, config);
    }
    return result;
  }

  /// Merges project configuration following the full merge sequence.
  ///
  /// Parameters:
  /// - [autoDetected]: Values from project file analysis
  /// - [projectTypeDefaults]: Defaults for this project type
  /// - [groupOverrides]: Overrides from group membership
  /// - [workspaceDefaults]: project-info settings from workspace
  /// - [projectOverrides]: Settings from tom_project.yaml
  /// - [globalCliParams]: Global CLI parameters
  /// - [targetCliParams]: Project/group specific CLI parameters
  Map<String, dynamic> mergeProjectConfig({
    Map<String, dynamic>? autoDetected,
    Map<String, dynamic>? projectTypeDefaults,
    Map<String, dynamic>? groupOverrides,
    Map<String, dynamic>? workspaceDefaults,
    Map<String, dynamic>? projectOverrides,
    Map<String, dynamic>? globalCliParams,
    Map<String, dynamic>? targetCliParams,
  }) {
    final layers = [
      if (autoDetected != null) autoDetected,
      if (projectTypeDefaults != null) projectTypeDefaults,
      if (groupOverrides != null) groupOverrides,
      if (workspaceDefaults != null) workspaceDefaults,
      if (projectOverrides != null) projectOverrides,
      if (globalCliParams != null) globalCliParams,
      if (targetCliParams != null) targetCliParams,
    ];

    return mergeAll(layers);
  }

  /// Creates a deep copy of a value.
  dynamic _deepCopy(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (e) => MapEntry(e.key.toString(), _deepCopy(e.value)),
        ),
      );
    }

    if (value is List) {
      return value.map(_deepCopy).toList();
    }

    // Primitives are immutable
    return value;
  }
}

// =============================================================================
// MERGE UTILITIES
// =============================================================================

/// Utility functions for common merge operations.

/// Merges two string lists, removing duplicates while preserving order.
List<String> mergeStringLists(List<String>? base, List<String>? override) {
  if (base == null && override == null) return [];
  if (base == null) return List.from(override!);
  if (override == null) return List.from(base);

  final result = List<String>.from(base);
  for (final item in override) {
    if (!result.contains(item)) {
      result.add(item);
    }
  }
  return result;
}

/// Merges two dependency maps, with override taking precedence.
Map<String, String> mergeDeps(
  Map<String, String>? base,
  Map<String, String>? override,
) {
  if (base == null && override == null) return {};
  if (base == null) return Map.from(override!);
  if (override == null) return Map.from(base);

  return {...base, ...override};
}
