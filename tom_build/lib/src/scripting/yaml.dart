/// YAML loading utilities for scripting.
///
/// Provides convenient static methods for loading and processing YAML files.
///
/// ## Environment Variable Resolution
/// Use `loadWithEnv` to resolve `{VAR}` or `{VAR:default}` placeholders
/// in YAML values using system environment and `.env` file.
library;

import 'dart:io';

import 'package:yaml/yaml.dart';

import 'env.dart';
import 'maps.dart';

/// YAML file loading helper.
///
/// All methods are static for convenient use in D4rt scripts.
///
/// ## Example
/// ```dart
/// // Load a YAML file
/// final config = ScriptYaml.load('config.yaml');
///
/// // Load with environment variable substitution
/// final config = ScriptYaml.loadWithEnv('config.yaml');
///
/// // Parse YAML string
/// final data = ScriptYaml.parse('key: value');
/// ```
class ScriptYaml {
  ScriptYaml._(); // Prevent instantiation

  /// Loads a YAML file and returns it as a clean Map.
  ///
  /// Converts YAML types to standard Dart types.
  static Map<String, dynamic> load(String path) {
    final content = File(path).readAsStringSync();
    return parse(content);
  }

  /// Loads a YAML file with environment variable substitution.
  ///
  /// Supports placeholders using `{VAR_NAME}` or `{VAR_NAME:default}` syntax.
  /// Loads from system environment and `.env` file in the YAML file's directory.
  ///
  /// ## Example YAML with placeholders
  /// ```yaml
  /// database:
  ///   host: {DB_HOST:localhost}
  ///   port: {DB_PORT:3306}
  ///   user: {DB_USER}
  /// ```
  static Map<String, dynamic> loadWithEnv(
    String path, {
    Map<String, String>? environment,
  }) {
    final content = File(path).readAsStringSync();
    final data = parse(content);

    if (environment != null) {
      TomEnv.resolveMapWith(data, environment);
    } else {
      // Load env from the YAML file's directory
      final dir = File(path).parent.path;
      TomEnv.resolveMap(data, workingDir: dir);
    }

    return data;
  }

  /// Parses a YAML string and returns it as a clean Map.
  ///
  /// Converts YAML types to standard Dart types.
  static Map<String, dynamic> parse(String yamlContent) {
    final yamlData = loadYaml(yamlContent);
    if (yamlData == null) {
      return {};
    }
    if (yamlData is! YamlMap) {
      throw FormatException('YAML content must be a map at the root level');
    }
    return _cleanYamlMap(yamlData);
  }

  /// Parses a YAML string and returns a list.
  ///
  /// Throws if the root is not a list.
  static List<dynamic> parseList(String yamlContent) {
    final yamlData = loadYaml(yamlContent);
    if (yamlData == null) {
      return [];
    }
    if (yamlData is! YamlList) {
      throw FormatException('YAML content must be a list at the root level');
    }
    return _cleanYamlList(yamlData);
  }

  /// Parses YAML and returns the raw value (can be map, list, or scalar).
  static dynamic parseAny(String yamlContent) {
    final yamlData = loadYaml(yamlContent);
    return _cleanYamlValue(yamlData);
  }

  /// Loads a YAML file and returns raw parsed value.
  static dynamic loadAny(String path) {
    final content = File(path).readAsStringSync();
    return parseAny(content);
  }

  /// Loads a YAML file and returns it as a list.
  static List<dynamic> loadList(String path) {
    final content = File(path).readAsStringSync();
    return parseList(content);
  }

  /// Loads multiple YAML files and merges them.
  ///
  /// Later files override earlier files.
  static Map<String, dynamic> loadAndMerge(List<String> paths) {
    final result = <String, dynamic>{};
    for (final path in paths) {
      if (File(path).existsSync()) {
        final data = load(path);
        TomMaps.mergeOneSided(result, data);
      }
    }
    return result;
  }

  /// Loads multiple YAML files and merges with env substitution.
  ///
  /// Uses `{VAR}` or `{VAR:default}` placeholder syntax.
  static Map<String, dynamic> loadAndMergeWithEnv(
    List<String> paths, {
    Map<String, String>? environment,
  }) {
    final result = <String, dynamic>{};
    for (final path in paths) {
      if (File(path).existsSync()) {
        final data = loadWithEnv(path, environment: environment);
        TomMaps.mergeOneSided(result, data);
      }
    }
    return result;
  }

  /// Checks if a file exists and is valid YAML.
  static bool isValidFile(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return false;
      loadYaml(file.readAsStringSync());
      return true;
    } catch (_) {
      return false;
    }
  }

  // ===========================================================================
  // Internal YAML cleaning functions
  // ===========================================================================

  /// Converts YamlMap to standard Dart Map<String, dynamic>.
  static Map<String, dynamic> _cleanYamlMap(YamlMap yamlMap) {
    final result = <String, dynamic>{};
    for (final entry in yamlMap.entries) {
      if (entry.key is String) {
        result[entry.key as String] = _cleanYamlValue(entry.value);
      }
    }
    return result;
  }

  /// Converts YamlList to standard Dart List.
  static List<dynamic> _cleanYamlList(YamlList yamlList) {
    return yamlList.map(_cleanYamlValue).toList();
  }

  /// Recursively converts YAML values to standard Dart types.
  static dynamic _cleanYamlValue(dynamic value) {
    if (value is YamlMap) {
      return _cleanYamlMap(value);
    }
    if (value is YamlList) {
      return _cleanYamlList(value);
    }
    // Primitives (String, int, double, bool, null) pass through
    return value;
  }
}
