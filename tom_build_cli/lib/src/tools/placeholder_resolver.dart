/// Placeholder Resolution System
///
/// Resolves placeholders in strings with values from:
/// - tom_master.yaml metadata (e.g., `[{packages.tom_core.version:-fallback}]`)
/// - Environment variables (e.g., `[[HOME]]`)
/// - D4rt expressions (e.g., `[{ return 1 + 1; }]`)
///
/// Supports:
/// - Simple placeholders: `[{path.to.value}]`
/// - Default values: `[{path.to.value:-default}]`
/// - Generator patterns: `[{packages.*.version:,}]` (comma-separated list)
/// - Complex filters: `[{packages.[publishable:true, name:tom_*].version:,}]`
/// - D4rt expressions: `[{ ... }]` or `[(){...}]`
/// - Environment variables: `[[ENV_VAR_NAME]]`
library;

import 'dart:io';
import 'package:yaml/yaml.dart';

import '../dartscript/d4rt_instance.dart';

/// Pattern for placeholder syntax: [{path.to.value:-default}]
/// Uses a more permissive pattern to handle nested braces in D4rt expressions.
final _placeholderPattern = RegExp(r'\[\{(.+?)\}\]');

/// Pattern for environment variable syntax: [[ENV_VAR_NAME]]
final _envVarPattern = RegExp(r'\[\[([^\]]+)\]\]');

/// Represents a packages block entry.
class PackageInfo {
  /// Package name.
  final String name;

  /// Package version.
  final String? version;

  /// Whether the package is publishable.
  final bool publishable;

  /// Last change commit hash.
  final String? lastChangeCommit;

  /// Additional metadata.
  final Map<String, dynamic> metadata;

  const PackageInfo({
    required this.name,
    this.version,
    this.publishable = true,
    this.lastChangeCommit,
    this.metadata = const {},
  });

  /// Creates from YAML map.
  factory PackageInfo.fromYaml(String name, YamlMap yaml) {
    return PackageInfo(
      name: name,
      version: yaml['version'] as String?,
      publishable: yaml['publishable'] as bool? ?? true,
      lastChangeCommit: yaml['last_change_commit'] as String?,
      metadata: Map<String, dynamic>.from(yaml),
    );
  }

  /// Gets a metadata value by key.
  dynamic operator [](String key) {
    switch (key) {
      case 'name':
        return name;
      case 'version':
        return version;
      case 'publishable':
        return publishable;
      case 'last_change_commit':
        return lastChangeCommit;
      default:
        return metadata[key];
    }
  }

  /// Converts to YAML-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'publishable': publishable,
      if (lastChangeCommit != null) 'last_change_commit': lastChangeCommit,
      ...metadata,
    };
  }
}

/// Callback type for D4rt expression evaluation.
@Deprecated('Use D4rtInstance directly instead')
typedef D4rtEvaluator = Future<dynamic> Function(String expression);

/// Placeholder resolver for tom workspace data.
class TomPlaceholderResolver {
  /// The root data map (from tom_master.yaml or tom_workspace.yaml).
  final Map<String, dynamic> data;

  /// Environment variables (including .env overrides).
  final Map<String, String> environment;

  /// Optional D4rt instance for expression blocks.
  final D4rtInstance? d4rt;

  /// Creates a resolver with the given data.
  TomPlaceholderResolver({
    required this.data,
    Map<String, String>? environment,
    this.d4rt,
  }) : environment = environment ?? Platform.environment;

  /// Resolves all placeholders in a string.
  ///
  /// Resolves in order:
  /// 1. Environment variables `[[NAME]]`
  /// 2. Data placeholders `[{path.to.value}]`
  Future<String> resolve(String input) async {
    var result = input;

    // First resolve environment variables
    result = _resolveEnvVars(result);

    // Then resolve data placeholders
    result = await _resolvePlaceholders(result);

    return result;
  }

  /// Resolves environment variables in the format [[VAR_NAME]].
  String _resolveEnvVars(String input) {
    return input.replaceAllMapped(_envVarPattern, (match) {
      final varName = match.group(1)!;
      return environment[varName] ?? '';
    });
  }

  /// Resolves data placeholders in the format [{path.to.value:-default}].
  Future<String> _resolvePlaceholders(String input) async {
    final buffer = StringBuffer();
    var lastEnd = 0;

    for (final match in _placeholderPattern.allMatches(input)) {
      buffer.write(input.substring(lastEnd, match.start));

      final content = match.group(1)!;
      final resolved = await _resolvePlaceholder(content);
      buffer.write(resolved);

      lastEnd = match.end;
    }

    buffer.write(input.substring(lastEnd));
    return buffer.toString();
  }

  /// Resolves a single placeholder content.
  Future<String> _resolvePlaceholder(String content) async {
    // Check for D4rt expression: starts with { or (){
    if (content.startsWith('{') && content.endsWith('}')) {
      return await _evaluateD4rtExpression(
        content.substring(1, content.length - 1),
      );
    }
    if (content.startsWith('(){') && content.endsWith('}')) {
      return await _evaluateD4rtExpression(content);
    }

    // Parse the placeholder: path.to.value:-default:separator
    final parts = _parsePlaceholderParts(content);
    final path = parts.path;
    final defaultValue = parts.defaultValue;
    final separator = parts.separator;

    // Check for filter pattern first (contains [filter])
    // This must be checked before generator pattern since filters can contain *
    if (path.contains('[') && path.contains(']')) {
      return _resolveFilterPattern(path, separator, defaultValue);
    }

    // Check for generator pattern (contains *)
    if (path.contains('*')) {
      return _resolveGeneratorPattern(path, separator, defaultValue);
    }

    // Simple path resolution
    final value = _resolvePath(path);
    if (value == null) {
      return defaultValue ?? '';
    }

    return value.toString();
  }

  /// Parses placeholder parts: path:-default:separator
  _PlaceholderParts _parsePlaceholderParts(String content) {
    // Split by :- for default value, then by : for separator
    String path;
    String? defaultValue;
    String? separator;

    final defaultSplit = content.split(':-');
    path = defaultSplit[0];

    if (defaultSplit.length > 1) {
      // Check if there's a separator after the default
      final rest = defaultSplit.sublist(1).join(':-');
      final sepIndex = rest.lastIndexOf(':');
      if (sepIndex > 0 && sepIndex < rest.length - 1) {
        defaultValue = rest.substring(0, sepIndex);
        separator = rest.substring(sepIndex + 1);
      } else {
        defaultValue = rest;
      }
    } else {
      // Check for just separator at end of path
      final sepMatch = RegExp(r':([^:]+)$').firstMatch(path);
      if (sepMatch != null) {
        separator = sepMatch.group(1);
        path = path.substring(0, sepMatch.start);
      }
    }

    return _PlaceholderParts(
      path: path,
      defaultValue: defaultValue,
      separator: separator,
    );
  }

  /// Resolves a path like "packages.tom_core.version" to a value.
  dynamic _resolvePath(String path) {
    final segments = path.split('.');
    dynamic current = data;

    for (final segment in segments) {
      if (current == null) return null;

      if (current is Map) {
        current = current[segment];
      } else if (current is YamlMap) {
        current = current[segment];
      } else if (current is List && int.tryParse(segment) != null) {
        final index = int.parse(segment);
        if (index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }

    return current;
  }

  /// Resolves a generator pattern like "packages.*.version".
  String _resolveGeneratorPattern(
    String pattern,
    String? separator,
    String? defaultValue,
  ) {
    final sep = separator ?? ',';
    final segments = pattern.split('.');
    final starIndex = segments.indexOf('*');

    if (starIndex < 0) return defaultValue ?? '';

    // Get the parent collection
    final parentPath = segments.sublist(0, starIndex).join('.');
    final parent = _resolvePath(parentPath);

    if (parent == null) return defaultValue ?? '';

    final results = <String>[];

    if (parent is Map) {
      final remainingPath = segments.sublist(starIndex + 1).join('.');

      for (final entry in parent.entries) {
        final itemPath = remainingPath.isEmpty
            ? entry.value
            : _resolvePathInObject(entry.value, remainingPath);

        if (itemPath != null) {
          results.add(itemPath.toString());
        }
      }
    } else if (parent is YamlMap) {
      final remainingPath = segments.sublist(starIndex + 1).join('.');

      for (final entry in parent.entries) {
        final itemPath = remainingPath.isEmpty
            ? entry.value
            : _resolvePathInObject(entry.value, remainingPath);

        if (itemPath != null) {
          results.add(itemPath.toString());
        }
      }
    }

    return results.isEmpty ? (defaultValue ?? '') : results.join(sep);
  }

  /// Resolves a filter pattern like "packages.[publishable:true].version".
  String _resolveFilterPattern(
    String pattern,
    String? separator,
    String? defaultValue,
  ) {
    final sep = separator ?? ',';

    // Parse the pattern to extract collection path, filter, and value path
    final filterMatch = RegExp(
      r'(.+)\.\[([^\]]+)\]\.?(.*)',
    ).firstMatch(pattern);
    if (filterMatch == null) return defaultValue ?? '';

    final collectionPath = filterMatch.group(1)!;
    final filterSpec = filterMatch.group(2)!;
    final valuePath = filterMatch.group(3) ?? '';

    // Get the collection
    final collection = _resolvePath(collectionPath);
    if (collection == null) return defaultValue ?? '';

    // Parse the filter
    final filters = _parseFilters(filterSpec);

    final results = <String>[];

    if (collection is Map || collection is YamlMap) {
      final entries = collection is Map
          ? collection.entries
          : (collection as YamlMap).entries;

      for (final entry in entries) {
        final itemName = entry.key.toString();
        final item = entry.value;

        if (_matchesFilters(itemName, item, filters)) {
          final value = valuePath.isEmpty
              ? item
              : _resolvePathInObject(item, valuePath);
          if (value != null) {
            results.add(value.toString());
          }
        }
      }
    }

    return results.isEmpty ? (defaultValue ?? '') : results.join(sep);
  }

  /// Parses filter specifications like "publishable:true, name:tom_*".
  Map<String, String> _parseFilters(String filterSpec) {
    final filters = <String, String>{};
    final parts = filterSpec.split(',').map((s) => s.trim());

    for (final part in parts) {
      final colonIndex = part.indexOf(':');
      if (colonIndex > 0) {
        final key = part.substring(0, colonIndex).trim();
        final value = part.substring(colonIndex + 1).trim();
        filters[key] = value;
      }
    }

    return filters;
  }

  /// Checks if an item matches the given filters.
  bool _matchesFilters(String name, dynamic item, Map<String, String> filters) {
    for (final filter in filters.entries) {
      final key = filter.key;
      final pattern = filter.value;

      dynamic value;
      if (key == 'name') {
        value = name;
      } else if (item is Map) {
        value = item[key];
      } else if (item is YamlMap) {
        value = item[key];
      } else {
        continue;
      }

      if (!_matchesPattern(value, pattern)) {
        return false;
      }
    }

    return true;
  }

  /// Checks if a value matches a pattern (supports * wildcards).
  bool _matchesPattern(dynamic value, String pattern) {
    final valueStr = value?.toString() ?? '';

    if (pattern.contains('*')) {
      // Convert glob pattern to regex
      final regexPattern = pattern.replaceAll('.', r'\.').replaceAll('*', '.*');
      return RegExp('^$regexPattern\$').hasMatch(valueStr);
    }

    // Direct comparison
    if (pattern == 'true') return value == true || value == 'true';
    if (pattern == 'false') return value == false || value == 'false';

    return valueStr == pattern;
  }

  /// Resolves a path within an object.
  dynamic _resolvePathInObject(dynamic obj, String path) {
    if (path.isEmpty) return obj;

    final segments = path.split('.');
    dynamic current = obj;

    for (final segment in segments) {
      if (current == null) return null;

      if (current is Map) {
        current = current[segment];
      } else if (current is YamlMap) {
        current = current[segment];
      } else {
        return null;
      }
    }

    return current;
  }

  /// Evaluates a D4rt expression.
  Future<String> _evaluateD4rtExpression(String expression) async {
    if (d4rt == null) {
      return '[D4rt not available]';
    }

    try {
      final result = await d4rt!.evaluate(expression);
      return result?.toString() ?? '';
    } catch (e) {
      return '[D4rt error: $e]';
    }
  }
}

/// Parsed placeholder parts.
class _PlaceholderParts {
  final String path;
  final String? defaultValue;
  final String? separator;

  const _PlaceholderParts({
    required this.path,
    this.defaultValue,
    this.separator,
  });
}

/// Loads .env file and merges with system environment.
Map<String, String> loadEnvironmentWithDotEnv([String? dotEnvPath]) {
  final env = Map<String, String>.from(Platform.environment);

  final envFile = File(dotEnvPath ?? '.env');
  if (envFile.existsSync()) {
    final lines = envFile.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final eqIndex = trimmed.indexOf('=');
      if (eqIndex > 0) {
        final key = trimmed.substring(0, eqIndex).trim();
        var value = trimmed.substring(eqIndex + 1).trim();

        // Remove quotes if present
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }

        env[key] = value;
      }
    }
  }

  return env;
}
