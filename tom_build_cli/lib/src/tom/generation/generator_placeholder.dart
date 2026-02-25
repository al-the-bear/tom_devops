/// Generator placeholder resolution for Tom configuration files.
///
/// Resolves `$GEN{path.*.field;separator}` generator placeholders that produce
/// lists of values from configuration data.
///
/// ## Features
///
/// - Basic generator syntax: `$GEN{projects.*.name;,}`
/// - Filtered generators: `$GEN{projects.[type=dart_package].name;,}`
/// - Regex pattern matching in filters
/// - Multiple filter conditions (AND logic)
///
/// ## Usage
///
/// ```dart
/// final resolver = GeneratorPlaceholderResolver();
/// final result = resolver.resolve(
///   content: 'Projects: $GEN{projects.*.name;, }',
///   context: {
///     'projects': [
///       {'name': 'core'},
///       {'name': 'build'},
///     ]
///   },
/// );
/// // result.value == 'Projects: core, build'
/// ```
library;

/// Result of generator placeholder resolution.
class GeneratorResult {
  /// The resolved content with all generator placeholders replaced.
  final dynamic value;

  /// Whether all generator placeholders were resolved successfully.
  final bool fullyResolved;

  /// List of unresolved generator placeholders (if any).
  final List<String> unresolvedGenerators;

  const GeneratorResult({
    required this.value,
    required this.fullyResolved,
    this.unresolvedGenerators = const [],
  });
}

/// Exception thrown when generator placeholder resolution fails.
class GeneratorResolutionException implements Exception {
  /// Error message describing the resolution failure.
  final String message;

  /// The generator placeholder that caused the error.
  final String? generator;

  /// Creates a generator resolution exception.
  const GeneratorResolutionException(this.message, {this.generator});

  @override
  String toString() => generator != null
      ? 'GeneratorResolutionException: $message (generator: $generator)'
      : 'GeneratorResolutionException: $message';
}

/// Resolves `$GEN{path.*.field;separator}` generator placeholders.
///
/// Generator placeholders produce lists of values from configuration data.
/// They are resolved right before files are written to disk, as the data
/// must be complete for correct resolution.
class GeneratorPlaceholderResolver {
  /// Pattern for matching $GEN{path.*.field;separator} or $GEN{path.[filter].field;sep}
  /// Groups: 1 = path/filter/field expression, 2 = separator
  static final RegExp _generatorPattern = RegExp(
    r'\$GEN\{([^;{}]+);([^}]*)\}',
  );

  /// Resolves all `$GEN{...}` generator placeholders in the given content.
  ///
  /// [content] can be a String, Map, or List. Maps and Lists are processed
  /// recursively.
  ///
  /// [context] is a Map containing the data to generate values from.
  ///
  /// [throwOnUnresolved] if true, throws an exception if generators remain
  /// unresolved. If false, returns the partial result.
  ///
  /// Returns a [GeneratorResult] containing the resolved value and metadata.
  GeneratorResult resolve({
    required dynamic content,
    required Map<String, dynamic> context,
    bool throwOnUnresolved = true,
  }) {
    if (content == null) {
      return const GeneratorResult(value: null, fullyResolved: true);
    }

    if (content is String) {
      return _resolveString(content, context, throwOnUnresolved);
    }

    if (content is Map) {
      return _resolveMap(content, context, throwOnUnresolved);
    }

    if (content is List) {
      return _resolveList(content, context, throwOnUnresolved);
    }

    // Non-string primitives - no generators
    return GeneratorResult(value: content, fullyResolved: true);
  }

  /// Resolves generators in a string.
  GeneratorResult _resolveString(
    String content,
    Map<String, dynamic> context,
    bool throwOnUnresolved,
  ) {
    final unresolved = <String>[];
    var result = content;

    result = result.replaceAllMapped(_generatorPattern, (match) {
      final expression = match.group(1)!;
      final separator = match.group(2)!;

      try {
        final values = _resolveGenerator(expression, context);
        return values.join(separator);
      } on GeneratorResolutionException {
        if (throwOnUnresolved) rethrow;
        unresolved.add(match.group(0)!);
        return match.group(0)!;
      }
    });

    return GeneratorResult(
      value: result,
      fullyResolved: unresolved.isEmpty,
      unresolvedGenerators: unresolved,
    );
  }

  /// Resolves generators in a map.
  GeneratorResult _resolveMap(
    Map content,
    Map<String, dynamic> context,
    bool throwOnUnresolved,
  ) {
    final result = <String, dynamic>{};
    final allUnresolved = <String>[];
    var allResolved = true;

    for (final entry in content.entries) {
      final keyResult = resolve(
        content: entry.key.toString(),
        context: context,
        throwOnUnresolved: throwOnUnresolved,
      );
      final valueResult = resolve(
        content: entry.value,
        context: context,
        throwOnUnresolved: throwOnUnresolved,
      );

      result[keyResult.value as String] = valueResult.value;

      if (!keyResult.fullyResolved) {
        allResolved = false;
        allUnresolved.addAll(keyResult.unresolvedGenerators);
      }
      if (!valueResult.fullyResolved) {
        allResolved = false;
        allUnresolved.addAll(valueResult.unresolvedGenerators);
      }
    }

    return GeneratorResult(
      value: result,
      fullyResolved: allResolved,
      unresolvedGenerators: allUnresolved,
    );
  }

  /// Resolves generators in a list.
  GeneratorResult _resolveList(
    List content,
    Map<String, dynamic> context,
    bool throwOnUnresolved,
  ) {
    final result = <dynamic>[];
    final allUnresolved = <String>[];
    var allResolved = true;

    for (final item in content) {
      final itemResult = resolve(
        content: item,
        context: context,
        throwOnUnresolved: throwOnUnresolved,
      );
      result.add(itemResult.value);

      if (!itemResult.fullyResolved) {
        allResolved = false;
        allUnresolved.addAll(itemResult.unresolvedGenerators);
      }
    }

    return GeneratorResult(
      value: result,
      fullyResolved: allResolved,
      unresolvedGenerators: allUnresolved,
    );
  }

  /// Resolves a generator expression and returns the list of values.
  ///
  /// Expression format: `path.*.field` or `path.[filter].field`
  List<String> _resolveGenerator(String expression, Map<String, dynamic> context) {
    // Parse the expression into parts
    final parts = _parseExpression(expression);

    // Navigate to the collection
    dynamic current = context;
    var wildcardIndex = -1;

    for (var i = 0; i < parts.length; i++) {
      final part = parts[i];

      if (part == '*' || part.startsWith('[')) {
        wildcardIndex = i;
        break;
      }

      current = _navigatePath(current, part);
      if (current == null) {
        throw GeneratorResolutionException(
          'Path not found: ${parts.sublist(0, i + 1).join(".")}',
          generator: '{{$expression}}',
        );
      }
    }

    if (wildcardIndex == -1) {
      throw GeneratorResolutionException(
        'No wildcard (*) or filter ([...]) found in expression',
        generator: '{{$expression}}',
      );
    }

    // Get the collection to iterate
    if (current is! List && current is! Map) {
      throw GeneratorResolutionException(
        'Expected collection at path, got ${current.runtimeType}',
        generator: '{{$expression}}',
      );
    }

    // Get the wildcard/filter part and remaining path
    final wildcardPart = parts[wildcardIndex];
    final remainingPath = parts.sublist(wildcardIndex + 1);

    // Get items from collection
    List<dynamic> items;
    if (current is List) {
      items = current;
    } else if (current is Map) {
      items = current.values.toList();
    } else {
      items = [];
    }

    // Apply filter if present
    if (wildcardPart.startsWith('[')) {
      final filterExpr = wildcardPart.substring(1, wildcardPart.length - 1);
      items = _applyFilter(items, filterExpr);
    }

    // Extract field values from each item
    final values = <String>[];
    for (final item in items) {
      final value = _extractField(item, remainingPath);
      if (value != null) {
        values.add(value.toString());
      }
    }

    return values;
  }

  /// Parses an expression into parts, handling filter brackets.
  List<String> _parseExpression(String expression) {
    final parts = <String>[];
    final buffer = StringBuffer();
    var bracketDepth = 0;

    for (var i = 0; i < expression.length; i++) {
      final char = expression[i];

      if (char == '[') {
        bracketDepth++;
        buffer.write(char);
      } else if (char == ']') {
        bracketDepth--;
        buffer.write(char);
      } else if (char == '.' && bracketDepth == 0) {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(char);
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    return parts;
  }

  /// Navigates a single path segment.
  dynamic _navigatePath(dynamic current, String part) {
    if (current == null) return null;

    if (current is Map) {
      // Try exact key first
      if (current.containsKey(part)) {
        return current[part];
      }
      // Try hyphen/underscore conversion
      final hyphenated = part.replaceAll('_', '-');
      final underscored = part.replaceAll('-', '_');
      if (current.containsKey(hyphenated)) {
        return current[hyphenated];
      }
      if (current.containsKey(underscored)) {
        return current[underscored];
      }
      return null;
    }

    if (current is List) {
      final index = int.tryParse(part);
      if (index != null && index >= 0 && index < current.length) {
        return current[index];
      }
      return null;
    }

    return null;
  }

  /// Applies a filter expression to a list of items.
  ///
  /// Filter format: `attr=value` or `attr=value,attr2=value2`
  List<dynamic> _applyFilter(List<dynamic> items, String filterExpr) {
    final conditions = _parseFilterConditions(filterExpr);

    return items.where((item) {
      if (item is! Map) return false;

      // All conditions must match (AND logic)
      for (final condition in conditions) {
        final attr = condition.attribute;
        final pattern = condition.pattern;
        final isRegex = condition.isRegex;

        // Get the value from the item
        final value = _navigatePath(item, attr);
        if (value == null) return false;

        final valueStr = value.toString();

        if (isRegex) {
          final regex = RegExp(pattern);
          if (!regex.hasMatch(valueStr)) return false;
        } else {
          if (valueStr != pattern) return false;
        }
      }

      return true;
    }).toList();
  }

  /// Parses filter conditions from a filter expression.
  List<_FilterCondition> _parseFilterConditions(String filterExpr) {
    final conditions = <_FilterCondition>[];

    // Split by comma, but handle escaped commas
    final parts = filterExpr.split(',');

    for (final part in parts) {
      final eqIndex = part.indexOf('=');
      if (eqIndex == -1) continue;

      final attr = part.substring(0, eqIndex).trim();
      final value = part.substring(eqIndex + 1).trim();

      // Check if it's a regex pattern (starts with ^ or ends with $)
      final isRegex = value.startsWith('^') || value.endsWith(r'$');

      conditions.add(_FilterCondition(
        attribute: attr,
        pattern: value,
        isRegex: isRegex,
      ));
    }

    return conditions;
  }

  /// Extracts a field value from an item following a path.
  dynamic _extractField(dynamic item, List<String> path) {
    if (path.isEmpty) return item;

    dynamic current = item;
    for (final part in path) {
      current = _navigatePath(current, part);
      if (current == null) return null;
    }
    return current;
  }
}

/// A filter condition for matching items.
class _FilterCondition {
  final String attribute;
  final String pattern;
  final bool isRegex;

  const _FilterCondition({
    required this.attribute,
    required this.pattern,
    required this.isRegex,
  });
}
