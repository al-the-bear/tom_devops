/// Placeholder resolution for Tom configuration files.
///
/// Resolves `$VAL{key.path}` value references in configuration data.
/// Supports default values with `$VAL{key:-default}` syntax.
///
/// ## Placeholder Resolution (Runtime Phase)
///
/// This resolver handles the Runtime phase (after YAML loading, before command
/// execution). All `$...{}` placeholders are resolved here:
///
/// | Type | Syntax | Description |
/// |------|--------|-------------|
/// | Value Reference | `$VAL{key.path:-default}` | Config value lookup |
/// | Environment | `$ENV{NAME:-default}` | Environment variable |
/// | D4rt Expression | `$D4{expression}` | D4rt evaluation |
/// | D4rt Script | `$D4S{file.dart}` | Script file execution |
/// | D4rt Script (multiline) | `$D4S\n<code>` | Inline script |
/// | D4rt Method (multiline) | `$D4M\n<code>` | Method returning value |
/// | Generator | `$GEN{path.*.field;sep}` | Path expansion |
///
/// Note: `[[...]]` and `[{...}]` placeholders are resolved at Generation time
/// (when writing tom_master*.yaml files) AND at Runtime.
///
/// ## Features
///
/// - Path-based value lookup (e.g., `$VAL{project.name}`)
/// - Default values (e.g., `$VAL{project.version:-1.0.0}`)
/// - Recursive resolution up to 10 levels
/// - Escaped placeholder preservation (`\$VAL{...}`)
///
/// ## Usage
///
/// ```dart
/// final resolver = PlaceholderResolver();
/// final result = resolver.resolve(
///   content: 'Project: $VAL{project.name}',
///   context: {'project': {'name': 'MyApp'}},
/// );
/// // result.value == 'Project: MyApp'
/// ```
library;

/// Result of placeholder resolution.
class PlaceholderResult {
  /// The resolved content with all placeholders replaced.
  final dynamic value;

  /// Whether all placeholders were resolved successfully.
  final bool fullyResolved;

  /// List of unresolved placeholders (if any).
  final List<String> unresolvedPlaceholders;

  /// Number of resolution iterations performed.
  final int iterations;

  const PlaceholderResult({
    required this.value,
    required this.fullyResolved,
    this.unresolvedPlaceholders = const [],
    this.iterations = 0,
  });
}

/// Exception thrown when placeholder resolution fails.
class GeneratorPlaceholderException implements Exception {
  /// Error message describing the resolution failure.
  final String message;

  /// List of placeholders that could not be resolved.
  final List<String> unresolvedPlaceholders;

  /// Number of iterations attempted before failure.
  final int iterations;

  /// Creates a placeholder resolution exception.
  const GeneratorPlaceholderException({
    required this.message,
    required this.unresolvedPlaceholders,
    required this.iterations,
  });

  @override
  String toString() => 'GeneratorPlaceholderException: $message\n'
      'Unresolved placeholders: ${unresolvedPlaceholders.join(", ")}\n'
      'Iterations: $iterations';
}

/// Resolves `$VAL{key.path}` placeholders in configuration data.
///
/// The resolver performs recursive resolution up to 10 levels deep.
/// If placeholders remain unresolved after 10 iterations, an error is thrown.
class PlaceholderResolver {
  /// Maximum recursion depth for placeholder resolution.
  static const int maxIterations = 10;

  /// Pattern for matching $VAL{key.path} or $VAL{key.path:-default} placeholders.
  /// Groups: 1 = full match, 2 = key path, 3 = default value (optional)
  static final RegExp _placeholderPattern = RegExp(
    r'(?<!\\)\$VAL\{([^}:]+)(?::-([^}]*))?\}',
  );

  /// Pattern for matching escaped placeholders (\$VAL{...}).
  static final RegExp _escapedPattern = RegExp(r'\\(\$VAL\{[^}]+\})');

  /// Resolves all `${key.path}` placeholders in the given content.
  ///
  /// [content] can be a String, Map, or List. Maps and Lists are processed
  /// recursively.
  ///
  /// [context] is a Map containing the data to resolve placeholders against.
  /// Keys in placeholders are dot-separated paths into this context.
  ///
  /// [throwOnUnresolved] if true, throws an exception if placeholders remain
  /// unresolved after max iterations. If false, returns the partial result.
  ///
  /// Returns a [PlaceholderResult] containing the resolved value and metadata.
  PlaceholderResult resolve({
    required dynamic content,
    required Map<String, dynamic> context,
    bool throwOnUnresolved = true,
  }) {
    var current = content;
    var iterations = 0;
    var previousContent = '';

    while (iterations < maxIterations) {
      iterations++;

      // Check if there are any placeholders remaining
      final remaining = _findPlaceholders(current);
      if (remaining.isEmpty) {
        // No placeholders - done!
        final unescaped = _unescapePlaceholders(current);
        return PlaceholderResult(
          value: unescaped,
          fullyResolved: true,
          iterations: iterations,
        );
      }

      // Resolve one pass
      final result = _resolveOnce(current, context);
      current = result.value;

      // Check if we made progress (content changed)
      final currentStr = current.toString();
      if (currentStr == previousContent) {
        // No progress - stuck with unresolved placeholders
        if (throwOnUnresolved) {
          throw GeneratorPlaceholderException(
            message: 'Failed to resolve all placeholders after $iterations '
                'iterations. No progress made.',
            unresolvedPlaceholders: remaining,
            iterations: iterations,
          );
        }
        final unescaped = _unescapePlaceholders(current);
        return PlaceholderResult(
          value: unescaped,
          fullyResolved: false,
          unresolvedPlaceholders: remaining,
          iterations: iterations,
        );
      }

      previousContent = currentStr;
    }

    // Max iterations reached
    final unresolved = _findPlaceholders(current);
    if (throwOnUnresolved && unresolved.isNotEmpty) {
      throw GeneratorPlaceholderException(
        message: 'Maximum recursion depth ($maxIterations) exceeded',
        unresolvedPlaceholders: unresolved,
        iterations: iterations,
      );
    }

    final unescaped = _unescapePlaceholders(current);
    return PlaceholderResult(
      value: unescaped,
      fullyResolved: unresolved.isEmpty,
      unresolvedPlaceholders: unresolved,
      iterations: iterations,
    );
  }

  /// Performs one pass of placeholder resolution.
  PlaceholderResult _resolveOnce(dynamic content, Map<String, dynamic> context) {
    if (content == null) {
      return const PlaceholderResult(value: null, fullyResolved: true);
    }

    if (content is String) {
      return _resolveString(content, context);
    }

    if (content is Map) {
      return _resolveMap(content, context);
    }

    if (content is List) {
      return _resolveList(content, context);
    }

    // Non-string primitives (int, double, bool) - no placeholders
    return PlaceholderResult(value: content, fullyResolved: true);
  }

  /// Resolves placeholders in a string.
  PlaceholderResult _resolveString(String content, Map<String, dynamic> context) {
    final unresolved = <String>[];
    var result = content;

    result = result.replaceAllMapped(_placeholderPattern, (match) {
      final keyPath = match.group(1)!;
      final defaultValue = match.group(2);

      final resolved = _resolvePath(keyPath, context);
      if (resolved != null) {
        return resolved.toString();
      }

      if (defaultValue != null) {
        return defaultValue;
      }

      // Unresolved - keep the placeholder
      unresolved.add('\$VAL{$keyPath}');
      return match.group(0)!;
    });

    return PlaceholderResult(
      value: result,
      fullyResolved: unresolved.isEmpty,
      unresolvedPlaceholders: unresolved,
    );
  }

  /// Resolves placeholders in a map.
  PlaceholderResult _resolveMap(Map content, Map<String, dynamic> context) {
    final result = <String, dynamic>{};
    final allUnresolved = <String>[];
    var allResolved = true;

    for (final entry in content.entries) {
      final keyResult = _resolveOnce(entry.key.toString(), context);
      final valueResult = _resolveOnce(entry.value, context);

      result[keyResult.value as String] = valueResult.value;

      if (!keyResult.fullyResolved) {
        allResolved = false;
        allUnresolved.addAll(keyResult.unresolvedPlaceholders);
      }
      if (!valueResult.fullyResolved) {
        allResolved = false;
        allUnresolved.addAll(valueResult.unresolvedPlaceholders);
      }
    }

    return PlaceholderResult(
      value: result,
      fullyResolved: allResolved,
      unresolvedPlaceholders: allUnresolved,
    );
  }

  /// Resolves placeholders in a list.
  PlaceholderResult _resolveList(List content, Map<String, dynamic> context) {
    final result = <dynamic>[];
    final allUnresolved = <String>[];
    var allResolved = true;

    for (final item in content) {
      final itemResult = _resolveOnce(item, context);
      result.add(itemResult.value);

      if (!itemResult.fullyResolved) {
        allResolved = false;
        allUnresolved.addAll(itemResult.unresolvedPlaceholders);
      }
    }

    return PlaceholderResult(
      value: result,
      fullyResolved: allResolved,
      unresolvedPlaceholders: allUnresolved,
    );
  }

  /// Resolves a dot-separated path against the context.
  ///
  /// Example: `project.settings.name` looks up context['project']['settings']['name']
  dynamic _resolvePath(String path, Map<String, dynamic> context) {
    final parts = path.split('.');
    dynamic current = context;

    for (final part in parts) {
      if (current == null) return null;

      if (current is Map) {
        // Try hyphenated version first (YAML convention), then as-is
        if (current.containsKey(part)) {
          current = current[part];
        } else {
          // Try with hyphens converted to underscores and vice versa
          final hyphenated = part.replaceAll('_', '-');
          final underscored = part.replaceAll('-', '_');

          if (current.containsKey(hyphenated)) {
            current = current[hyphenated];
          } else if (current.containsKey(underscored)) {
            current = current[underscored];
          } else {
            return null;
          }
        }
      } else if (current is List) {
        // Support numeric indices
        final index = int.tryParse(part);
        if (index != null && index >= 0 && index < current.length) {
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

  /// Finds all unresolved placeholders in content.
  List<String> _findPlaceholders(dynamic content) {
    if (content == null) return [];

    if (content is String) {
      return _placeholderPattern.allMatches(content).map((m) => m.group(0)!).toList();
    }

    if (content is Map) {
      final result = <String>[];
      for (final entry in content.entries) {
        result.addAll(_findPlaceholders(entry.key));
        result.addAll(_findPlaceholders(entry.value));
      }
      return result;
    }

    if (content is List) {
      final result = <String>[];
      for (final item in content) {
        result.addAll(_findPlaceholders(item));
      }
      return result;
    }

    return [];
  }

  /// Unescapes escaped placeholders (\\${...} -> ${...}).
  dynamic _unescapePlaceholders(dynamic content) {
    if (content == null) return null;

    if (content is String) {
      return content.replaceAllMapped(_escapedPattern, (match) => match.group(1)!);
    }

    if (content is Map) {
      return content.map((key, value) => MapEntry(
            _unescapePlaceholders(key),
            _unescapePlaceholders(value),
          ));
    }

    if (content is List) {
      return content.map(_unescapePlaceholders).toList();
    }

    return content;
  }
}
