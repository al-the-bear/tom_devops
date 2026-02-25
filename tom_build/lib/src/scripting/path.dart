/// Path manipulation utilities for scripting.
///
/// Provides convenient static methods for path operations.
/// Wraps dart:io and package:path functionality.
library;

import 'dart:io';
import 'package:path/path.dart' as p;

/// Path manipulation helper.
///
/// All methods are static for convenient use in D4rt scripts.
///
/// ## Example
/// ```dart
/// // Join paths
/// final full = TomPth.join('src', 'lib', 'main.dart');
///
/// // Get parts
/// final dir = TomPth.dirname('/path/to/file.txt');  // '/path/to'
/// final name = TomPth.basename('/path/to/file.txt'); // 'file.txt'
/// final ext = TomPth.extension('file.txt');          // '.txt'
/// ```
class TomPth {
  TomPth._(); // Prevent instantiation

  // =========================================================================
  // Path Construction
  // =========================================================================

  /// Join path segments.
  static String join(
    String part1, [
    String? part2,
    String? part3,
    String? part4,
    String? part5,
    String? part6,
  ]) {
    return p.join(part1, part2, part3, part4, part5, part6);
  }

  /// Join a list of path segments.
  static String joinAll(List<String> parts) {
    return p.joinAll(parts);
  }

  // =========================================================================
  // Path Decomposition
  // =========================================================================

  /// Get directory name (parent path).
  static String dirname(String path) {
    return p.dirname(path);
  }

  /// Get base name (filename with extension).
  static String basename(String path) {
    return p.basename(path);
  }

  /// Get base name without extension.
  static String basenameNoExt(String path) {
    return p.basenameWithoutExtension(path);
  }

  /// Get file extension (including dot).
  static String extension(String path) {
    return p.extension(path);
  }

  /// Split path into segments.
  static List<String> split(String path) {
    return p.split(path);
  }

  // =========================================================================
  // Path Transformation
  // =========================================================================

  /// Make path absolute.
  static String absolute(String path) {
    return p.absolute(path);
  }

  /// Get relative path from [from] to [path].
  static String relative(String path, {String? from}) {
    return p.relative(path, from: from);
  }

  /// Normalize path (resolve . and ..).
  static String normalize(String path) {
    return p.normalize(path);
  }

  /// Canonicalize path (normalize + resolve symlinks).
  static String canonical(String path) {
    return p.canonicalize(path);
  }

  /// Change file extension.
  static String setExtension(String path, String extension) {
    return p.setExtension(path, extension);
  }

  /// Remove file extension.
  static String withoutExtension(String path) {
    return p.withoutExtension(path);
  }

  // =========================================================================
  // Path Queries
  // =========================================================================

  /// Check if path is absolute.
  static bool isAbsolute(String path) {
    return p.isAbsolute(path);
  }

  /// Check if path is relative.
  static bool isRelative(String path) {
    return p.isRelative(path);
  }

  /// Check if [child] is inside [parent].
  static bool isWithin(String parent, String child) {
    return p.isWithin(parent, child);
  }

  /// Check if two paths are equal (normalized).
  static bool equals(String path1, String path2) {
    return p.equals(path1, path2);
  }

  // =========================================================================
  // Special Paths
  // =========================================================================

  /// Get current working directory.
  static String get cwd => Directory.current.path;

  /// Get home directory.
  static String get home {
    if (Platform.isWindows) {
      return Platform.environment['USERPROFILE'] ?? '';
    }
    return Platform.environment['HOME'] ?? '';
  }

  /// Get temp directory.
  static String get temp => Directory.systemTemp.path;

  /// Get path separator for current platform.
  static String get separator => p.separator;

  /// Expand ~ to home directory.
  static String expandHome(String path) {
    if (path.startsWith('~/')) {
      return p.join(home, path.substring(2));
    }
    if (path == '~') {
      return home;
    }
    return path;
  }
}
