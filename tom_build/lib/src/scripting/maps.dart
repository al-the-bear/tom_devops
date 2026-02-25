/// Map processing utilities for scripting.
///
/// Provides convenient static methods for map merging, traversal, and
/// value access.
library;

/// Map processing helper.
///
/// All methods are static for convenient use in D4rt scripts.
///
/// ## Example
/// ```dart
/// // Merge maps (later overrides earlier)
/// final merged = TomMaps.mergeOneSided(base, overrides);
///
/// // Traverse and process all values
/// TomMaps.traverse(config, (key, value) => ...);
/// ```
class TomMaps {
  TomMaps._(); // Prevent instantiation

  // ===========================================================================
  // Merge operations
  // ===========================================================================

  /// Merges [source] into [target] recursively.
  ///
  /// Values from [source] override [target]. Nested maps are merged
  /// recursively. Lists are replaced, not concatenated.
  ///
  /// Returns [target] for chaining.
  static Map<String, dynamic> mergeOneSided(
    Map<String, dynamic> target,
    Map<String, dynamic> source,
  ) {
    for (final entry in source.entries) {
      final key = entry.key;
      final sourceValue = entry.value;
      final targetValue = target[key];

      if (targetValue is Map<String, dynamic> &&
          sourceValue is Map<String, dynamic>) {
        // Both are maps, merge recursively
        mergeOneSided(targetValue, sourceValue);
      } else {
        // Replace target value with source value
        target[key] = _deepCopy(sourceValue);
      }
    }
    return target;
  }

  /// Creates a merged copy without modifying originals.
  ///
  /// Values from [overrides] override [base].
  static Map<String, dynamic> merge(
    Map<String, dynamic> base,
    Map<String, dynamic> overrides,
  ) {
    final result = _deepCopy(base) as Map<String, dynamic>;
    return mergeOneSided(result, overrides);
  }

  /// Merges multiple maps in order (later overrides earlier).
  static Map<String, dynamic> mergeAll(List<Map<String, dynamic>> maps) {
    final result = <String, dynamic>{};
    for (final map in maps) {
      mergeOneSided(result, map);
    }
    return result;
  }

  // ===========================================================================
  // Traversal operations
  // ===========================================================================

  /// Traverses a map tree and processes each leaf value.
  ///
  /// The [processor] function receives:
  /// - [key]: The dot-separated path to the value (e.g., "database.host")
  /// - [value]: The current value (can be any type including nested maps)
  ///
  /// If [processor] returns non-null, the value is replaced.
  /// Returns the modified map.
  static Map<String, dynamic> traverse(
    Map<String, dynamic> map,
    dynamic Function(String key, dynamic value) processor, {
    String prefix = '',
  }) {
    final entries = List.of(
      map.entries,
    ); // Copy to avoid concurrent modification
    for (final entry in entries) {
      final key = entry.key;
      final fullKey = prefix.isEmpty ? key : '$prefix.$key';
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        traverse(value, processor, prefix: fullKey);
      } else if (value is List) {
        map[key] = _traverseList(value, processor, fullKey);
      } else {
        final newValue = processor(fullKey, value);
        if (newValue != null) {
          map[key] = newValue;
        }
      }
    }
    return map;
  }

  /// Traverses a list and processes each element.
  static List<dynamic> _traverseList(
    List<dynamic> list,
    dynamic Function(String key, dynamic value) processor,
    String prefix,
  ) {
    final result = <dynamic>[];
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      final fullKey = '$prefix[$i]';

      if (item is Map<String, dynamic>) {
        result.add(traverse(item, processor, prefix: fullKey));
      } else if (item is List) {
        result.add(_traverseList(item, processor, fullKey));
      } else {
        final newValue = processor(fullKey, item);
        result.add(newValue ?? item);
      }
    }
    return result;
  }

  /// Collects all leaf values with their dot-separated keys.
  ///
  /// Nested maps are flattened with dot notation (e.g., "a.b.c").
  /// List elements use bracket notation (e.g., "items[0]").
  ///
  /// ## Example
  /// ```dart
  /// final nested = {'a': {'b': 1, 'c': 2}, 'd': 3};
  /// final flat = TomMaps.flatten(nested);
  /// // Result: {'a.b': 1, 'a.c': 2, 'd': 3}
  /// ```
  static Map<String, dynamic> flatten(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    _flattenRecursive(map, '', result);
    return result;
  }

  /// Recursive helper for flatten.
  static void _flattenRecursive(
    dynamic value,
    String prefix,
    Map<String, dynamic> result,
  ) {
    if (value is Map<String, dynamic>) {
      for (final entry in value.entries) {
        final newKey = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
        _flattenRecursive(entry.value, newKey, result);
      }
    } else if (value is Map) {
      // Handle non-String keyed maps by converting keys to strings
      for (final entry in value.entries) {
        final keyStr = entry.key.toString();
        final newKey = prefix.isEmpty ? keyStr : '$prefix.$keyStr';
        _flattenRecursive(entry.value, newKey, result);
      }
    } else if (value is List) {
      for (var i = 0; i < value.length; i++) {
        _flattenRecursive(value[i], '$prefix[$i]', result);
      }
    } else {
      // Leaf value
      result[prefix] = value;
    }
  }

  /// Converts a flattened map back into a nested structure.
  ///
  /// Dot notation keys become nested maps (e.g., "a.b" -> {a: {b: value}}).
  /// Bracket notation keys become list indices (e.g., "items[0]" -> {items: [value]}).
  ///
  /// ## Example
  /// ```dart
  /// final flat = {'a.b': 1, 'a.c': 2, 'd': 3};
  /// final nested = TomMaps.unflatten(flat);
  /// // Result: {'a': {'b': 1, 'c': 2}, 'd': 3}
  ///
  /// final withList = {'items[0]': 'a', 'items[1]': 'b'};
  /// final nestedList = TomMaps.unflatten(withList);
  /// // Result: {'items': ['a', 'b']}
  /// ```
  static Map<String, dynamic> unflatten(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    
    for (final entry in map.entries) {
      _setNestedValue(result, entry.key, entry.value);
    }
    
    // Convert any placeholder maps for lists into actual lists
    _convertListPlaceholders(result);
    
    return result;
  }

  /// Sets a nested value using a dot/bracket separated path.
  static void _setNestedValue(
    Map<String, dynamic> root,
    String path,
    dynamic value,
  ) {
    final segments = _parsePath(path);
    dynamic current = root;
    
    for (var i = 0; i < segments.length - 1; i++) {
      final segment = segments[i];
      final nextSegment = segments[i + 1];
      
      if (segment.isIndex) {
        // Current is a list placeholder map
        final listMap = current as Map<String, dynamic>;
        final indexKey = '_\$idx_${segment.index}';
        
        if (!listMap.containsKey(indexKey)) {
          // Next segment determines if we need a map or list placeholder
          listMap[indexKey] = nextSegment.isIndex
              ? <String, dynamic>{'_\$isList': true}
              : <String, dynamic>{};
        }
        current = listMap[indexKey];
      } else {
        // Current is a map
        final map = current as Map<String, dynamic>;
        
        if (!map.containsKey(segment.key)) {
          // Next segment determines if we need a map or list placeholder
          map[segment.key] = nextSegment.isIndex
              ? <String, dynamic>{'_\$isList': true}
              : <String, dynamic>{};
        }
        current = map[segment.key];
      }
    }
    
    // Set the final value
    final lastSegment = segments.last;
    if (lastSegment.isIndex) {
      final listMap = current as Map<String, dynamic>;
      listMap['_\$idx_${lastSegment.index}'] = value;
    } else {
      final map = current as Map<String, dynamic>;
      map[lastSegment.key] = value;
    }
  }

  /// Parses a path like "a.b[0].c" into segments.
  static List<_PathSegment> _parsePath(String path) {
    final segments = <_PathSegment>[];
    final buffer = StringBuffer();
    
    for (var i = 0; i < path.length; i++) {
      final char = path[i];
      
      if (char == '.') {
        if (buffer.isNotEmpty) {
          segments.add(_PathSegment.key(buffer.toString()));
          buffer.clear();
        }
      } else if (char == '[') {
        if (buffer.isNotEmpty) {
          segments.add(_PathSegment.key(buffer.toString()));
          buffer.clear();
        }
        // Find closing bracket
        final endBracket = path.indexOf(']', i);
        if (endBracket == -1) {
          throw FormatException('Unclosed bracket in path: $path');
        }
        final indexStr = path.substring(i + 1, endBracket);
        final index = int.tryParse(indexStr);
        if (index == null) {
          throw FormatException('Invalid list index in path: $path');
        }
        segments.add(_PathSegment.index(index));
        i = endBracket;
      } else {
        buffer.write(char);
      }
    }
    
    if (buffer.isNotEmpty) {
      segments.add(_PathSegment.key(buffer.toString()));
    }
    
    return segments;
  }

  /// Recursively converts list placeholder maps into actual lists.
  static void _convertListPlaceholders(Map<String, dynamic> map) {
    final keys = map.keys.toList();
    
    for (final key in keys) {
      final value = map[key];
      
      if (value is Map<String, dynamic>) {
        if (value.containsKey('_\$isList')) {
          // This is a list placeholder - convert to list
          map[key] = _placeholderToList(value);
        } else {
          // Regular nested map - recurse
          _convertListPlaceholders(value);
        }
      }
    }
  }

  /// Converts a list placeholder map to an actual list.
  static List<dynamic> _placeholderToList(Map<String, dynamic> placeholder) {
    final indices = <int, dynamic>{};
    
    for (final entry in placeholder.entries) {
      if (entry.key.startsWith('_\$idx_')) {
        final index = int.parse(entry.key.substring(6));
        var value = entry.value;
        
        // Recursively convert nested placeholders
        if (value is Map<String, dynamic>) {
          if (value.containsKey('_\$isList')) {
            value = _placeholderToList(value);
          } else {
            _convertListPlaceholders(value);
          }
        }
        
        indices[index] = value;
      }
    }
    
    if (indices.isEmpty) return [];
    
    // Create list with proper size
    final maxIndex = indices.keys.reduce((a, b) => a > b ? a : b);
    final result = List<dynamic>.filled(maxIndex + 1, null);
    
    for (final entry in indices.entries) {
      result[entry.key] = entry.value;
    }
    
    return result;
  }

  // ===========================================================================
  // Value access utilities
  // ===========================================================================

  /// Gets a nested value using a dot-separated path.
  ///
  /// Returns `null` if any part of the path doesn't exist.
  ///
  /// ## Example
  /// ```dart
  /// final host = TomMaps.get(config, 'database.host');
  /// ```
  static T? get<T>(Map<String, dynamic> map, String path) {
    final parts = path.split('.');
    dynamic current = map;

    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(part)) return null;
        current = current[part];
      } else {
        return null;
      }
    }

    return current is T ? current : null;
  }

  /// Gets a nested value or returns a default.
  static T getOr<T>(Map<String, dynamic> map, String path, T defaultValue) {
    return get<T>(map, path) ?? defaultValue;
  }

  /// Sets a nested value using a dot-separated path.
  ///
  /// Creates intermediate maps as needed.
  static void set(Map<String, dynamic> map, String path, dynamic value) {
    final parts = path.split('.');
    var current = map;

    for (var i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (current[part] is! Map<String, dynamic>) {
        current[part] = <String, dynamic>{};
      }
      current = current[part] as Map<String, dynamic>;
    }

    current[parts.last] = value;
  }

  /// Checks if a path exists in the map.
  static bool has(Map<String, dynamic> map, String path) {
    final parts = path.split('.');
    dynamic current = map;

    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        if (!current.containsKey(part)) return false;
        current = current[part];
      } else {
        return false;
      }
    }
    return true;
  }

  /// Removes a nested value using a dot-separated path.
  ///
  /// Returns the removed value, or null if path didn't exist.
  static dynamic remove(Map<String, dynamic> map, String path) {
    final parts = path.split('.');
    dynamic current = map;

    for (var i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }

    if (current is Map<String, dynamic>) {
      return current.remove(parts.last);
    }
    return null;
  }

  // ===========================================================================
  // Utility functions
  // ===========================================================================

  /// Deep copies a value (maps, lists, and primitives).
  static dynamic _deepCopy(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((k, v) => MapEntry(k, _deepCopy(v)));
    }
    if (value is Map) {
      return Map.fromEntries(
        value.entries.map((e) => MapEntry(e.key, _deepCopy(e.value))),
      );
    }
    if (value is List) {
      return value.map(_deepCopy).toList();
    }
    // Primitives are immutable, return as-is
    return value;
  }

  /// Creates a deep copy of a map.
  static Map<String, dynamic> copy(Map<String, dynamic> map) {
    return _deepCopy(map) as Map<String, dynamic>;
  }

  /// Converts any Map to Map<String, dynamic>.
  ///
  /// Useful after JSON/YAML parsing when types might be loose.
  static Map<String, dynamic> clean(Map<dynamic, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.key is String) {
        result[entry.key as String] = _cleanValue(entry.value);
      }
    }
    return result;
  }

  /// Cleans a value recursively.
  static dynamic _cleanValue(dynamic value) {
    if (value is Map) {
      return clean(value);
    }
    if (value is List) {
      return value.map(_cleanValue).toList();
    }
    return value;
  }

  // ===========================================================================
  // Selection utilities
  // ===========================================================================

  /// Returns a new map with only the specified keys.
  ///
  /// Keys that don't exist in the source map are ignored.
  ///
  /// ## Example
  /// ```dart
  /// final user = {'id': 1, 'name': 'John', 'email': 'john@example.com', 'password': 'secret'};
  /// final public = TomMaps.pick(user, ['id', 'name', 'email']);
  /// // {'id': 1, 'name': 'John', 'email': 'john@example.com'}
  /// ```
  static Map<String, dynamic> pick(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final result = <String, dynamic>{};
    for (final key in keys) {
      if (map.containsKey(key)) {
        result[key] = map[key];
      }
    }
    return result;
  }

  /// Returns a new map with the specified keys removed.
  ///
  /// Keys that don't exist in the source map are ignored.
  ///
  /// ## Example
  /// ```dart
  /// final user = {'id': 1, 'name': 'John', 'password': 'secret'};
  /// final safe = TomMaps.omit(user, ['password']);
  /// // {'id': 1, 'name': 'John'}
  /// ```
  static Map<String, dynamic> omit(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final keySet = keys.toSet();
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (!keySet.contains(entry.key)) {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}

/// Represents a segment of a flattened path.
///
/// Can be either a map key (string) or a list index (integer).
class _PathSegment {
  final String? _key;
  final int? _index;

  const _PathSegment.key(String key)
      : _key = key,
        _index = null;

  const _PathSegment.index(int index)
      : _key = null,
        _index = index;

  bool get isIndex => _index != null;
  String get key => _key!;
  int get index => _index!;
}
