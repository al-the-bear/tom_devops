/// Mode resolution for Tom CLI.
///
/// Resolves mode values for actions based on action-mode-configuration
/// and mode type definitions.
library;

import 'package:tom_build/tom_build.dart';

// =============================================================================
// MODE RESOLVER
// =============================================================================

/// Resolves active modes for a given action.
///
/// Uses the action-mode-configuration to determine which modes are active
/// for a specific action, falling back to the default configuration.
class ModeResolver {
  /// Creates a new ModeResolver.
  ModeResolver();

  /// Resolves all active modes for an action.
  ///
  /// Returns:
  /// - [ResolvedModes] containing the active mode names and mode type values
  ///
  /// Parameters:
  /// - [actionName]: The action being executed (e.g., 'build', 'test')
  /// - [workspaceModes]: The workspace-modes configuration
  /// - [modeDefinitions]: Map of mode-type to ModeDefinitions
  /// - [cliOverrides]: Mode overrides from command line (e.g., {'environment': 'prod'})
  ResolvedModes resolve({
    required String actionName,
    WorkspaceModes? workspaceModes,
    Map<String, ModeDefinitions>? modeDefinitions,
    Map<String, String> cliOverrides = const {},
  }) {
    if (workspaceModes == null) {
      return ResolvedModes(
        activeModes: {},
        modeTypeValues: cliOverrides,
        impliedModes: {},
      );
    }

    // Get action's mode configuration or fall back to default
    final amc = workspaceModes.actionModeConfiguration;
    final actionEntry = amc?.entries[actionName] ?? amc?.entries['default'];

    // Start with action's mode type values
    final modeTypeValues = <String, String>{};
    if (actionEntry != null) {
      modeTypeValues.addAll(actionEntry.modes);
    }

    // Apply CLI overrides (highest priority)
    modeTypeValues.addAll(cliOverrides);

    // Collect active mode names
    final activeModes = <String>{};
    final impliedModes = <String>{};

    // Add mode type values as active modes
    activeModes.addAll(modeTypeValues.values);

    // Resolve implied modes from mode type configurations
    for (final entry in modeTypeValues.entries) {
      final modeType = entry.key;
      final modeValue = entry.value;

      // Look up in mode type config (key is modeType without '-modes' suffix)
      final modeTypeConfig = workspaceModes.modeTypeConfigs[modeType];
      if (modeTypeConfig != null) {
        final modeEntry = modeTypeConfig.entries[modeValue];
        if (modeEntry != null) {
          for (final implied in modeEntry.modes) {
            activeModes.add(implied);
            impliedModes.add(implied);
          }
        }
      }
    }

    // Resolve supported mode presets
    for (final supported in workspaceModes.supported) {
      if (activeModes.contains(supported.name)) {
        for (final implied in supported.implies) {
          activeModes.add(implied);
          impliedModes.add(implied);
        }
      }
    }

    return ResolvedModes(
      activeModes: activeModes,
      modeTypeValues: modeTypeValues,
      impliedModes: impliedModes,
    );
  }

  /// Resolves mode definitions for all active modes.
  ///
  /// Returns a map of property name to value, merged from all active mode
  /// definitions (later modes override earlier).
  Map<String, dynamic> resolveModeProperties({
    required ResolvedModes resolved,
    required Map<String, ModeDefinitions>? modeDefinitions,
  }) {
    if (modeDefinitions == null) return {};

    final properties = <String, dynamic>{};

    // For each mode type with an active value
    for (final entry in resolved.modeTypeValues.entries) {
      final modeType = entry.key;
      final modeValue = entry.value;

      final defs = modeDefinitions[modeType];
      if (defs != null) {
        final modeDef = defs.definitions[modeValue];
        if (modeDef != null) {
          // Merge properties (later overrides earlier)
          properties.addAll(modeDef.properties);
        }
      }
    }

    return properties;
  }

  /// Gets the default mode value for a mode type.
  String? getDefaultMode(String modeType, WorkspaceModes? workspaceModes) {
    if (workspaceModes == null) return null;

    final modeTypeConfig = workspaceModes.modeTypeConfigs['$modeType-modes'];
    return modeTypeConfig?.defaultMode;
  }
}

// =============================================================================
// RESOLVED MODES
// =============================================================================

/// Result of mode resolution.
class ResolvedModes {
  /// Creates a new ResolvedModes.
  const ResolvedModes({
    required this.activeModes,
    required this.modeTypeValues,
    required this.impliedModes,
  });

  /// All active mode names (including implied modes).
  final Set<String> activeModes;

  /// Map of mode-type to active value (e.g., {'environment': 'prod'}).
  final Map<String, String> modeTypeValues;

  /// Modes that were implied by other modes (subset of activeModes).
  final Set<String> impliedModes;

  /// Returns true if the given mode is active.
  bool isActive(String mode) => activeModes.contains(mode);

  /// Returns the value for a specific mode type.
  String? getModeValue(String modeType) => modeTypeValues[modeType];

  @override
  String toString() {
    return 'ResolvedModes(active: $activeModes, types: $modeTypeValues)';
  }
}
