/// Configuration loading utilities for Tom CLI.
///
/// This module provides functionality to load and parse YAML configuration
/// files (tom_workspace.yaml, tom_project.yaml).
library;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'package:tom_build/tom_build.dart';

// =============================================================================
// CONFIG LOADER
// =============================================================================

/// Loads and parses Tom configuration files.
///
/// Handles loading of:
/// - tom_workspace.yaml (workspace-level configuration)
/// - tom_project.yaml (project-level configuration)
/// - Imported YAML files specified in imports: lists
class ConfigLoader {
  /// Creates a new ConfigLoader.
  ConfigLoader();

  /// Loads a tom_workspace.yaml file from the given directory.
  ///
  /// Returns null if the file doesn't exist.
  /// Throws [ConfigLoadException] if the file is invalid.
  TomWorkspace? loadWorkspaceConfig(String workspaceDir) {
    final filePath = path.join(workspaceDir, 'tom_workspace.yaml');
    final file = File(filePath);

    if (!file.existsSync()) {
      return null;
    }

    try {
      final content = file.readAsStringSync();
      final yaml = _parseYaml(content, filePath);
      return TomWorkspace.fromYaml(yaml);
    } on YamlException catch (e) {
      throw ConfigLoadException(
        message: 'Invalid YAML syntax',
        filePath: filePath,
        line: e.span?.start.line,
        resolution: 'Fix YAML syntax error: ${e.message}',
      );
    }
  }

  /// Loads a tom_project.yaml file from the given directory.
  ///
  /// Returns null if the file doesn't exist.
  /// Mode blocks (@@@mode...@@@endmode) are preserved as raw content
  /// for later processing by ModeProcessor.
  TomProject? loadProjectConfig(String projectDir, String projectName) {
    final filePath = path.join(projectDir, 'tom_project.yaml');
    final file = File(filePath);

    if (!file.existsSync()) {
      return null;
    }

    try {
      final content = file.readAsStringSync();
      final yaml = _parseYaml(content, filePath);
      return TomProject.fromYaml(projectName, yaml);
    } on YamlException catch (e) {
      throw ConfigLoadException(
        message: 'Invalid YAML syntax',
        filePath: filePath,
        line: e.span?.start.line,
        resolution: 'Fix YAML syntax error: ${e.message}',
      );
    }
  }

  /// Loads a generic YAML file and returns it as a Map.
  ///
  /// Used for loading imported configuration files.
  Map<String, dynamic> loadYamlFile(String filePath) {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw ConfigLoadException(
        message: 'File not found',
        filePath: filePath,
        resolution: 'Ensure the file exists at the specified path',
      );
    }

    try {
      final content = file.readAsStringSync();
      return _parseYaml(content, filePath);
    } on YamlException catch (e) {
      throw ConfigLoadException(
        message: 'Invalid YAML syntax',
        filePath: filePath,
        line: e.span?.start.line,
        resolution: 'Fix YAML syntax error: ${e.message}',
      );
    }
  }

  /// Loads workspace config with all imports merged.
  ///
  /// Imports are processed in order, with later files overriding earlier ones.
  /// The workspace file itself has the highest priority.
  TomWorkspace? loadWorkspaceWithImports(String workspaceDir) {
    final workspace = loadWorkspaceConfig(workspaceDir);
    if (workspace == null) return null;

    final imports = workspace.imports ?? [];
    if (imports.isEmpty) return workspace;

    // Load and merge imports
    var mergedYaml = <String, dynamic>{};
    for (final importPath in imports) {
      final resolvedPath = _resolveImportPath(workspaceDir, importPath);
      final importedYaml = loadYamlFile(resolvedPath);
      mergedYaml = _deepMerge(mergedYaml, importedYaml);
    }

    // Merge workspace on top (highest priority)
    final workspaceFile = path.join(workspaceDir, 'tom_workspace.yaml');
    final workspaceYaml = loadYamlFile(workspaceFile);
    mergedYaml = _deepMerge(mergedYaml, workspaceYaml);

    return TomWorkspace.fromYaml(mergedYaml);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Parses YAML content into a clean Map.
  Map<String, dynamic> _parseYaml(String content, String filePath) {
    final yaml = loadYaml(content);
    return _makeCleanMap(yaml);
  }

  /// Converts a YamlMap to a regular Map<String, dynamic>.
  Map<String, dynamic> _makeCleanMap(dynamic data) {
    if (data == null) return {};
    if (data is! Map) return {};

    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key.toString();
      result[key] = _cleanValue(entry.value);
    }
    return result;
  }

  /// Cleans a value for Map/List representation.
  dynamic _cleanValue(dynamic value) {
    if (value == null) return null;
    if (value is Map) return _makeCleanMap(value);
    if (value is List) return value.map(_cleanValue).toList();
    if (value is YamlList) return value.map(_cleanValue).toList();
    return value;
  }

  /// Resolves an import path relative to the workspace directory.
  String _resolveImportPath(String workspaceDir, String importPath) {
    if (path.isAbsolute(importPath)) {
      return importPath;
    }
    return path.normalize(path.join(workspaceDir, importPath));
  }

  /// Deep merges two maps.
  ///
  /// Override values replace base values for scalars.
  /// Maps are merged recursively.
  /// Lists are replaced (not concatenated).
  Map<String, dynamic> _deepMerge(
    Map<String, dynamic> base,
    Map<String, dynamic> override,
  ) {
    final result = Map<String, dynamic>.from(base);

    for (final entry in override.entries) {
      final key = entry.key;
      final overrideValue = entry.value;
      final baseValue = result[key];

      if (overrideValue is Map<String, dynamic> &&
          baseValue is Map<String, dynamic>) {
        // Recursively merge maps
        result[key] = _deepMerge(baseValue, overrideValue);
      } else {
        // Override scalars and lists
        result[key] = overrideValue;
      }
    }

    return result;
  }
}

// =============================================================================
// EXCEPTIONS
// =============================================================================

/// Exception thrown when configuration loading fails.
class ConfigLoadException implements Exception {
  /// Creates a new ConfigLoadException.
  const ConfigLoadException({
    required this.message,
    required this.filePath,
    this.line,
    required this.resolution,
  });

  /// Error description.
  final String message;

  /// Path to the file that caused the error.
  final String filePath;

  /// Line number where the error occurred (if applicable).
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

    buffer.writeln('  Resolution: $resolution');

    return buffer.toString();
  }
}
