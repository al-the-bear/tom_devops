/// Zone utilities for scripting.
///
/// Provides convenient static methods for accessing values from the current Dart Zone.
library;

import 'dart:async' as async;

/// Zone value access helper.
///
/// All methods are static for convenient use in D4rt scripts.
///
/// ## Example
/// ```dart
/// // Access typed value from current zone
/// final config = TomZoned.get<AppConfig>();
///
/// // Access value by name
/// final logger = TomZoned.get<TomLogger>('logger');
///
/// // Run code with zone values
/// TomZoned.run({'key': 'value'}, () {
///   final v = TomZoned.get<String>('key');
/// });
/// ```
class TomZoned {
  TomZoned._(); // Prevent instantiation

  /// Retrieves a typed value from the current Dart Zone.
  ///
  /// If [name] is provided, uses it as the zone key.
  /// If [name] is null, uses type [T] as the zone key.
  ///
  /// Returns `null` if no value of type [T] exists in the current zone.
  ///
  /// ## Example
  /// ```dart
  /// // Access by type (key is the Type itself)
  /// final config = TomZoned.get<AppConfig>();
  ///
  /// // Access by name (key is the string name)
  /// final logger = TomZoned.get<TomLogger>('logger');
  /// ```
  static T? get<T>([String? name]) {
    final key = name ?? T;
    final zoneItem = async.Zone.current[key];
    if (zoneItem != null && zoneItem is T) {
      return zoneItem;
    }
    return null;
  }

  /// Retrieves a value from the current zone by key.
  ///
  /// Unlike [get], this returns the raw value without type checking.
  static Object? getByKey(Object key) {
    return async.Zone.current[key];
  }

  /// Runs a function in a new zone with the specified values.
  ///
  /// The [values] map keys can be any object (typically Type or String).
  ///
  /// ## Example
  /// ```dart
  /// TomZoned.run({AppConfig: config, 'debug': true}, () {
  ///   final cfg = TomZoned.get<AppConfig>();
  ///   final debug = TomZoned.get<bool>('debug');
  /// });
  /// ```
  static R run<R>(Map<Object, Object?> values, R Function() body) {
    return async.runZoned(body, zoneValues: values);
  }

  /// Runs an async function in a new zone with the specified values.
  static Future<R> runAsync<R>(
    Map<Object, Object?> values,
    Future<R> Function() body,
  ) {
    return async.runZoned(body, zoneValues: values);
  }

  /// Runs a function with error handling in a new zone.
  ///
  /// Errors are caught and transformed using [onError].
  static R runGuarded<R>(
    R Function() body, {
    required void Function(Object error, StackTrace stack) onError,
    Map<Object, Object?>? values,
  }) {
    return async.runZonedGuarded(body, onError, zoneValues: values) as R;
  }

  /// Gets the current zone for inspection.
  static async.Zone get current => async.Zone.current;

  /// Gets the root zone.
  static async.Zone get root => async.Zone.root;

  /// Checks if a value exists in the current zone for the given key.
  static bool has(Object key) {
    return async.Zone.current[key] != null;
  }

  /// Checks if a typed value exists in the current zone.
  static bool hasType<T>() {
    return async.Zone.current[T] != null;
  }
}
