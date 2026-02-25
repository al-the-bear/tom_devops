/// Configuration validation for Tom CLI.
///
/// Validates workspace and project configurations according to the
/// specification requirements.
library;

import 'package:tom_build/tom_build.dart';

// =============================================================================
// VALIDATION RESULT
// =============================================================================

/// Result of a validation operation.
class ValidationResult {
  /// Creates a successful validation result.
  ValidationResult.success()
      : isValid = true,
        errors = const [];

  /// Creates a failed validation result.
  ValidationResult.failure(this.errors) : isValid = false;

  /// Whether the configuration is valid.
  final bool isValid;

  /// List of validation errors (empty if valid).
  final List<ConfigValidationError> errors;

  /// Returns all error messages formatted for display.
  String formatErrors() {
    return errors.map((e) => e.toString()).join('\n');
  }
}

/// A single configuration validation error.
///
/// Note: This is different from `ConfigValidationError` in tom_doc_specs/validation/,
/// which is for document schema validation.
class ConfigValidationError {
  /// Creates a new ConfigValidationError.
  const ConfigValidationError({
    required this.message,
    required this.filePath,
    this.line,
    required this.resolution,
  });

  /// Error description.
  final String message;

  /// Path to the file containing the error.
  final String filePath;

  /// Line number (if applicable).
  final int? line;

  /// Suggested resolution.
  final String resolution;

  @override
  String toString() {
    final buffer = StringBuffer()
      ..writeln('Error: $message')
      ..writeln('  File: [$filePath]');

    if (line != null) {
      buffer.writeln('  Line: [$line]');
    }

    buffer.write('  Resolution: $resolution');

    return buffer.toString();
  }
}

// =============================================================================
// CONFIG VALIDATOR
// =============================================================================

/// Validates Tom configuration files.
class ConfigValidator {
  /// Creates a new ConfigValidator.
  ConfigValidator();

  /// Validates a TomWorkspace configuration.
  ///
  /// Checks:
  /// - actions: section is present
  /// - Each action has a default: configuration
  /// - action-mode-configuration actions match actions: keys
  /// - build-on keys match all-targets entries
  ValidationResult validateWorkspace(TomWorkspace workspace, String filePath) {
    final errors = <ConfigValidationError>[];

    // Check actions section is present
    if (workspace.actions.isEmpty) {
      errors.add(ConfigValidationError(
        message: 'Missing required block [actions:]',
        filePath: filePath,
        resolution: 'Add an actions: section with action definitions',
      ));
    }

    // Check each action has a default configuration
    for (final action in workspace.actions.entries) {
      if (action.value.defaultConfig == null) {
        errors.add(ConfigValidationError(
          message: 'Action [${action.key}] requires [default:] definition',
          filePath: filePath,
          resolution:
              'Add a default: block inside actions.${action.key}:',
        ));
      }
    }

    // Validate action-mode-configuration references valid actions
    final amc = workspace.workspaceModes?.actionModeConfiguration;
    if (amc != null) {
      for (final entry in amc.entries.entries) {
        if (entry.key != 'default' && !workspace.actions.containsKey(entry.key)) {
          errors.add(ConfigValidationError(
            message:
                'Action [${entry.key}] in action-mode-configuration not found in [actions:]',
            filePath: filePath,
            resolution:
                'Add actions.${entry.key}: or remove from action-mode-configuration',
          ));
        }
      }
    }

    // Validate cross-compilation build-on references
    _validateCrossCompilation(
      workspace.crossCompilation,
      filePath,
      errors,
    );

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  /// Validates a TomProject configuration.
  ValidationResult validateProject(TomProject project, String filePath) {
    final errors = <ConfigValidationError>[];

    // Validate cross-compilation if present
    _validateCrossCompilation(
      project.crossCompilation,
      filePath,
      errors,
    );

    // Note: Action order references can't be validated here because we need
    // the full workspace context. This is checked in validateMaster().

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  /// Validates a TomMaster file after generation.
  ///
  /// Performs cross-project validations:
  /// - No duplicate project names
  /// - All build-after references are valid
  /// - All action-order references are valid
  /// - No circular dependencies
  ValidationResult validateMaster(TomMaster master, String filePath) {
    final errors = <ConfigValidationError>[];
    final projectNames = master.projects.keys.toSet();

    // Check for build-after references to non-existent projects
    for (final project in master.projects.values) {
      for (final dep in project.buildAfter) {
        if (!projectNames.contains(dep)) {
          errors.add(ConfigValidationError(
            message: 'Project [${project.name}] references unknown project [$dep] in build-after',
            filePath: filePath,
            resolution: 'Ensure [$dep] exists or remove from build-after',
          ));
        }
      }

      // Check action-order references
      for (final entry in project.actionOrder.entries) {
        for (final dep in entry.value) {
          if (!projectNames.contains(dep)) {
            errors.add(ConfigValidationError(
              message: 'Project [${project.name}] references unknown project [$dep] in ${entry.key}',
              filePath: filePath,
              resolution: 'Ensure [$dep] exists or remove from ${entry.key}',
            ));
          }
        }
      }
    }

    // Check for circular dependencies
    final cycleError = _detectCycles(master.projects);
    if (cycleError != null) {
      errors.add(ConfigValidationError(
        message: 'Circular dependency detected',
        filePath: filePath,
        resolution: cycleError,
      ));
    }

    return errors.isEmpty
        ? ValidationResult.success()
        : ValidationResult.failure(errors);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _validateCrossCompilation(
    CrossCompilation? crossCompilation,
    String filePath,
    List<ConfigValidationError> errors,
  ) {
    if (crossCompilation == null) return;

    final allTargets = crossCompilation.allTargets.toSet();

    for (final entry in crossCompilation.buildOn.entries) {
      // Check that the host target exists
      if (!allTargets.contains(entry.key)) {
        errors.add(ConfigValidationError(
          message: 'build-on key [${entry.key}] not found in all-targets',
          filePath: filePath,
          resolution: 'Add [${entry.key}] to all-targets or use valid target',
        ));
      }

      // Check that all referenced targets exist
      for (final target in entry.value.targets) {
        if (!allTargets.contains(target)) {
          errors.add(ConfigValidationError(
            message:
                'build-on[${entry.key}] references unknown target [$target]',
            filePath: filePath,
            resolution: 'Add [$target] to all-targets or use valid target',
          ));
        }
      }
    }
  }

  /// Detects circular dependencies in project build-after relationships.
  ///
  /// Returns an error message describing the cycle, or null if no cycle found.
  String? _detectCycles(Map<String, TomProject> projects) {
    final visited = <String>{};
    final recursionStack = <String>[];

    for (final projectName in projects.keys) {
      final cycle = _dfs(projectName, projects, visited, recursionStack);
      if (cycle != null) {
        return 'Cycle: ${cycle.join(' → ')}\n  Resolution: Remove one dependency to break the cycle';
      }
    }

    return null;
  }

  /// Depth-first search for cycle detection.
  List<String>? _dfs(
    String current,
    Map<String, TomProject> projects,
    Set<String> visited,
    List<String> recursionStack,
  ) {
    if (recursionStack.contains(current)) {
      // Found a cycle
      final cycleStart = recursionStack.indexOf(current);
      return [...recursionStack.sublist(cycleStart), current];
    }

    if (visited.contains(current)) {
      return null;
    }

    visited.add(current);
    recursionStack.add(current);

    final project = projects[current];
    if (project != null) {
      for (final dep in project.buildAfter) {
        final cycle = _dfs(dep, projects, visited, recursionStack);
        if (cycle != null) return cycle;
      }
    }

    recursionStack.removeLast();
    return null;
  }
}
