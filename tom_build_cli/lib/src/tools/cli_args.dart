/// CLI Argument Parsing Utilities
///
/// Provides utilities for parsing prefixed named parameters in the style `prefix-name=value`.
/// This ensures tools can be composed without argument name conflicts.
library;

import 'dart:io';
import 'package:path/path.dart' as path;

/// Tool prefixes for named parameters.
class ToolPrefix {
  /// Workspace preparer prefix.
  static const wsPrepper = 'wp-';

  /// Workspace analyzer prefix.
  static const workspaceAnalyzer = 'wa-';

  /// Reflection generator prefix.
  static const reflectionGenerator = 'rc-';
}

/// Parsed CLI arguments with prefixed named parameters.
class CliArgs {
  /// The tool prefix to use for parsing (e.g., 'ms-', 'wa-').
  final String prefix;

  /// Raw arguments.
  final List<String> rawArgs;

  /// Named parameters (prefix stripped from keys).
  final Map<String, String> _namedParams = {};

  /// Boolean flags (prefix stripped from keys).
  final Set<String> _flags = {};

  /// Positional arguments (non-prefixed, non-flag arguments).
  final List<String> positionalArgs = [];

  /// Creates a CLI args parser for the given prefix.
  CliArgs(this.prefix, List<String> arguments)
    : rawArgs = List.unmodifiable(arguments) {
    _parse(arguments);
  }

  void _parse(List<String> arguments) {
    for (final arg in arguments) {
      // Check for prefixed named parameter: prefix-name=value
      if (arg.startsWith(prefix)) {
        final rest = arg.substring(prefix.length);
        final eqIndex = rest.indexOf('=');
        if (eqIndex > 0) {
          // Named parameter: prefix-name=value
          final key = rest.substring(0, eqIndex);
          final value = rest.substring(eqIndex + 1);
          _namedParams[key] = value;
        } else {
          // Boolean flag: prefix-flag
          _flags.add(rest);
        }
      }
      // Legacy --flag and --option=value support
      else if (arg.startsWith('--')) {
        final rest = arg.substring(2);
        final eqIndex = rest.indexOf('=');
        if (eqIndex > 0) {
          // --option=value
          final key = rest.substring(0, eqIndex);
          final value = rest.substring(eqIndex + 1);
          _namedParams[key] = value;
        } else {
          // --flag
          _flags.add(rest);
        }
      }
      // Single dash flags like -h, -v
      else if (arg.startsWith('-') && arg.length == 2) {
        _flags.add(arg.substring(1));
      }
      // Positional argument
      else if (!arg.startsWith('-')) {
        positionalArgs.add(arg);
      }
    }
  }

  /// Gets a named parameter value, or null if not present.
  String? operator [](String key) => _namedParams[key];

  /// Gets a named parameter value with a default.
  String get(String key, [String defaultValue = '']) =>
      _namedParams[key] ?? defaultValue;

  /// Gets a named parameter as an integer.
  int? getInt(String key) {
    final value = _namedParams[key];
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Gets a named parameter as a boolean.
  bool getBool(String key, [bool defaultValue = false]) {
    final value = _namedParams[key];
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }

  /// Checks if a flag is present.
  bool hasFlag(String key) => _flags.contains(key);

  /// Checks if a named parameter is present.
  bool has(String key) => _namedParams.containsKey(key);

  /// Gets all named parameters.
  Map<String, String> get namedParams => Map.unmodifiable(_namedParams);

  /// Gets all flags.
  Set<String> get flags => Set.unmodifiable(_flags);

  /// Convenience getters for common options.
  bool get help => hasFlag('help') || hasFlag('h');
  bool get dryRun => hasFlag('dry-run');
  bool get verbose => hasFlag('verbose') || hasFlag('v');

  /// Resolves a path - handles relative and absolute paths.
  String resolvePath(String pathArg) {
    if (pathArg.startsWith('/')) {
      return pathArg;
    }
    // Relative path - resolve from current directory
    return path.join(Directory.current.path, pathArg);
  }

  /// Gets the workspace path from a named parameter or positional arg.
  ///
  /// Checks for `path` named parameter first, then uses positional arg
  /// at the given index, defaulting to current directory.
  String getWorkspacePath({int positionalIndex = 0}) {
    // Check for named parameter
    final namedPath = _namedParams['path'];
    if (namedPath != null) {
      return resolvePath(namedPath);
    }

    // Check positional args
    if (positionalArgs.length > positionalIndex) {
      return resolvePath(positionalArgs[positionalIndex]);
    }

    // Default to current directory
    return Directory.current.path;
  }

  @override
  String toString() {
    final buffer = StringBuffer('CliArgs(prefix: $prefix)\n');
    buffer.writeln('  Named: $_namedParams');
    buffer.writeln('  Flags: $_flags');
    buffer.writeln('  Positional: $positionalArgs');
    return buffer.toString();
  }
}

/// Parses arguments with the workspace preparer prefix.
CliArgs parseWsPrepperArgs(List<String> args) =>
    CliArgs(ToolPrefix.wsPrepper, args);

/// Parses arguments with the workspace analyzer prefix.
CliArgs parseWorkspaceAnalyzerArgs(List<String> args) =>
    CliArgs(ToolPrefix.workspaceAnalyzer, args);

/// Parses arguments with the reflection generator prefix.
CliArgs parseReflectionGeneratorArgs(List<String> args) =>
    CliArgs(ToolPrefix.reflectionGenerator, args);
