/// Environment variable utilities for scripting.
///
/// Provides convenient static methods for environment variable
/// access, manipulation, and placeholder resolution.
library;

import 'dart:io';

/// Environment variable helper.
///
/// All methods are static for convenient use in D4rt scripts.
///
/// ## Placeholder Syntax
/// Supports `{VAR}` and `{VAR:default}` syntax for string interpolation:
/// ```dart
/// final cmd = Env.resolve('echo {MESSAGE:Hello}');
/// // If MESSAGE is set to "Hi", returns "echo Hi"
/// // If MESSAGE is not set, returns "echo Hello"
/// ```
///
/// ## Example
/// ```dart
/// // Get environment variable
/// final home = Env.get('HOME');
///
/// // Get with default
/// final port = Env.get('PORT', '8080');
///
/// // Check if set
/// if (Env.has('DEBUG')) { ... }
///
/// // Get required (throws if not set)
/// final apiKey = Env.require('API_KEY');
///
/// // Resolve placeholders in strings
/// final resolved = TomEnv.resolve('Server: {HOST:localhost}:{PORT:8080}');
/// ```
class TomEnv {
  TomEnv._(); // Prevent instantiation

  // ===========================================================================
  // .env file loading
  // ===========================================================================

  /// Cached environment variables (system + .env file overrides).
  static Map<String, String>? _cachedEnv;

  /// Regex for placeholder syntax: {VAR} or {VAR:default}
  static final _placeholderPattern = RegExp(r'\{([^:}]+)(?::([^}]*))?\}');

  /// Loads environment variables from system and optional .env file.
  ///
  /// The .env file in [directory] (or current directory if null) overrides
  /// system environment variables. Results are cached.
  ///
  /// Call [reload] to refresh the cache.
  static Map<String, String> load([String? directory]) {
    if (_cachedEnv != null) return _cachedEnv!;

    // Start with system environment
    final env = Map<String, String>.from(Platform.environment);

    // Load .env file if it exists
    final dir = directory ?? Directory.current.path;
    final envFile = File('$dir/.env');
    if (envFile.existsSync()) {
      _loadEnvFile(envFile, env);
    }

    _cachedEnv = env;
    return env;
  }

  /// Reloads environment variables from system and .env file.
  ///
  /// Clears the cache and reloads from the specified directory.
  static Map<String, String> reload([String? directory]) {
    _cachedEnv = null;
    return load(directory);
  }

  /// Parses a .env file and adds entries to the environment map.
  static void _loadEnvFile(File file, Map<String, String> env) {
    final lines = file.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();

      // Skip empty lines and comments
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      // Parse KEY=VALUE or KEY="VALUE" or KEY='VALUE'
      final equalsIndex = trimmed.indexOf('=');
      if (equalsIndex == -1) continue;

      final key = trimmed.substring(0, equalsIndex).trim();
      var value = trimmed.substring(equalsIndex + 1).trim();

      // Remove quotes if present
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }

      // Handle escape sequences in double-quoted strings
      if (trimmed.substring(equalsIndex + 1).trim().startsWith('"')) {
        value = value
            .replaceAll(r'\n', '\n')
            .replaceAll(r'\t', '\t')
            .replaceAll(r'\\', '\\');
      }

      env[key] = value;
    }
  }

  /// Loads a specific .env file and merges with current environment.
  static Map<String, String> loadFile(String path) {
    final env = Map<String, String>.from(Platform.environment);
    final file = File(path);
    if (file.existsSync()) {
      _loadEnvFile(file, env);
    }
    return env;
  }

  // ===========================================================================
  // Placeholder resolution
  // ===========================================================================

  /// Resolves environment placeholders in a string.
  ///
  /// Syntax: `{VAR}` or `{VAR:default}`
  ///
  /// Uses the cached environment (system + .env file).
  /// Call [load] first to ensure .env is loaded from a specific directory.
  ///
  /// ## Example
  /// ```dart
  /// final cmd = Env.resolve('curl {API_URL:http://localhost}/health');
  /// ```
  static String resolve(String text, {String? workingDir}) {
    final env = _cachedEnv ?? load(workingDir);
    return resolveWith(text, env);
  }

  /// Resolves environment placeholders using a specific environment map.
  ///
  /// Syntax: `{VAR}` or `{VAR:default}`
  static String resolveWith(String text, Map<String, String> environment) {
    return text.replaceAllMapped(_placeholderPattern, (match) {
      final varName = match.group(1)!;
      final defaultValue = match.group(2);

      if (environment.containsKey(varName)) {
        return environment[varName]!;
      } else if (defaultValue != null) {
        return defaultValue;
      } else {
        // Keep the placeholder if no env var and no default
        return match.group(0)!;
      }
    });
  }

  /// Resolves placeholders in all string values of a map.
  ///
  /// Modifies the map in place and returns it.
  static Map<String, dynamic> resolveMap(
    Map<String, dynamic> map, {
    String? workingDir,
  }) {
    final env = _cachedEnv ?? load(workingDir);
    return resolveMapWith(map, env);
  }

  /// Resolves placeholders in all string values using a specific environment.
  static Map<String, dynamic> resolveMapWith(
    Map<String, dynamic> map,
    Map<String, String> environment,
  ) {
    _traverseAndResolve(map, environment);
    return map;
  }

  /// Recursively traverses and resolves placeholders in a map.
  static void _traverseAndResolve(
    Map<String, dynamic> map,
    Map<String, String> env,
  ) {
    final entries = List.of(map.entries);
    for (final entry in entries) {
      final value = entry.value;
      if (value is String) {
        map[entry.key] = resolveWith(value, env);
      } else if (value is Map<String, dynamic>) {
        _traverseAndResolve(value, env);
      } else if (value is List) {
        _traverseAndResolveListInPlace(value, env);
      }
    }
  }

  /// Recursively traverses and resolves placeholders in a list in-place.
  static void _traverseAndResolveListInPlace(
    List<dynamic> list,
    Map<String, String> env,
  ) {
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is String) {
        list[i] = resolveWith(item, env);
      } else if (item is Map<String, dynamic>) {
        _traverseAndResolve(item, env);
      } else if (item is List) {
        _traverseAndResolveListInPlace(item, env);
      }
    }
  }

  // ===========================================================================
  // Basic environment access
  // ===========================================================================

  /// Get an environment variable value.
  ///
  /// Returns [defaultValue] if the variable is not set.
  static String? get(String name, [String? defaultValue]) {
    return Platform.environment[name] ?? defaultValue;
  }

  /// Get an environment variable, throwing if not set.
  static String require(String name, {String? message}) {
    final value = Platform.environment[name];
    if (value == null) {
      throw TomEnvironmentException(
        message ?? 'Required environment variable "$name" is not set',
      );
    }
    return value;
  }

  /// Check if an environment variable is set.
  static bool has(String name) {
    return Platform.environment.containsKey(name);
  }

  /// Check if an environment variable is set and not empty.
  static bool isSet(String name) {
    final value = Platform.environment[name];
    return value != null && value.isNotEmpty;
  }

  /// Get all environment variables.
  static Map<String, String> all() {
    return Map.unmodifiable(Platform.environment);
  }

  /// Get environment variables matching a prefix.
  ///
  /// Optionally strips the prefix from returned keys.
  static Map<String, String> withPrefix(String prefix, {bool strip = false}) {
    final result = <String, String>{};
    for (final entry in Platform.environment.entries) {
      if (entry.key.startsWith(prefix)) {
        final key = strip ? entry.key.substring(prefix.length) : entry.key;
        result[key] = entry.value;
      }
    }
    return result;
  }

  /// Get environment variable as integer.
  static int? getInt(String name, [int? defaultValue]) {
    final value = Platform.environment[name];
    if (value == null) return defaultValue;
    return int.tryParse(value) ?? defaultValue;
  }

  /// Get environment variable as boolean.
  ///
  /// Recognizes: true/false, yes/no, 1/0, on/off (case-insensitive).
  static bool getBool(String name, [bool defaultValue = false]) {
    final value = Platform.environment[name]?.toLowerCase();
    if (value == null) return defaultValue;

    const trueValues = {'true', 'yes', '1', 'on'};
    const falseValues = {'false', 'no', '0', 'off'};

    if (trueValues.contains(value)) return true;
    if (falseValues.contains(value)) return false;
    return defaultValue;
  }

  /// Get environment variable as list.
  ///
  /// Splits by [separator] (default: comma or colon based on platform).
  static List<String> getList(String name, {String? separator}) {
    final value = Platform.environment[name];
    if (value == null || value.isEmpty) return [];

    final sep = separator ?? (Platform.isWindows ? ';' : ':');
    return value.split(sep).where((s) => s.isNotEmpty).toList();
  }

  // --- Common environment variables ---

  /// Get HOME directory.
  static String? get home =>
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

  /// Get PATH as list.
  static List<String> get path => getList('PATH');

  /// Get current shell.
  static String? get shell => Platform.environment['SHELL'];

  /// Get username.
  static String? get user =>
      Platform.environment['USER'] ?? Platform.environment['USERNAME'];

  /// Get TEMP directory.
  static String? get temp =>
      Platform.environment['TMPDIR'] ??
      Platform.environment['TEMP'] ??
      Platform.environment['TMP'];

  /// Get current working directory (from PWD or Directory.current).
  static String get cwd =>
      Platform.environment['PWD'] ?? Directory.current.path;

  /// Check if running in CI environment.
  static bool get isCI =>
      has('CI') ||
      has('CONTINUOUS_INTEGRATION') ||
      has('GITHUB_ACTIONS') ||
      has('GITLAB_CI') ||
      has('CIRCLECI') ||
      has('TRAVIS');

  /// Check if running in debug/development mode.
  static bool get isDev =>
      getBool('DEBUG') ||
      getBool('DEV') ||
      get('NODE_ENV') == 'development' ||
      get('DART_ENV') == 'development';

  /// Check if running in production mode.
  static bool get isProd =>
      getBool('PRODUCTION') ||
      get('NODE_ENV') == 'production' ||
      get('DART_ENV') == 'production';

  // --- Platform info ---

  /// Get operating system name.
  static String get os => Platform.operatingSystem;

  /// Get operating system version.
  static String get osVersion => Platform.operatingSystemVersion;

  /// Get number of processors.
  static int get processors => Platform.numberOfProcessors;

  /// Get Dart version.
  static String get dartVersion => Platform.version;

  /// Get hostname.
  static String get hostname => Platform.localHostname;

  /// Check if running on macOS.
  static bool get isMacOS => Platform.isMacOS;

  /// Check if running on Linux.
  static bool get isLinux => Platform.isLinux;

  /// Check if running on Windows.
  static bool get isWindows => Platform.isWindows;

  // --- Expand variables ---

  /// Expand environment variables in a string.
  ///
  /// Supports both `$VAR` and `${VAR}` syntax.
  static String expand(String text) {
    return text.replaceAllMapped(
      RegExp(r'\$\{([^}]+)\}|\$([A-Za-z_][A-Za-z0-9_]*)'),
      (match) {
        final varName = match.group(1) ?? match.group(2);
        return Platform.environment[varName] ?? '';
      },
    );
  }

  /// Expand environment variables with defaults.
  ///
  /// Supports `${VAR:-default}` syntax.
  static String expandWithDefaults(String text) {
    return text.replaceAllMapped(
      RegExp(r'\$\{([^}:]+)(?::-([^}]*))?\}|\$([A-Za-z_][A-Za-z0-9_]*)'),
      (match) {
        final varName = match.group(1) ?? match.group(3);
        final defaultValue = match.group(2) ?? '';
        final value = Platform.environment[varName];
        return value?.isNotEmpty == true ? value! : defaultValue;
      },
    );
  }
}

/// Exception thrown when a required environment variable is missing.
class TomEnvironmentException implements Exception {
  /// Creates an environment exception with the given message.
  const TomEnvironmentException(this.message);

  /// The exception message.
  final String message;

  @override
  String toString() => 'TomEnvironmentException: $message';
}
