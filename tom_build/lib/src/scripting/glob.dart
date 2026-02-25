/// Glob pattern matching utilities for scripting.
///
/// Provides convenient static methods for finding files using glob patterns.
library;

import 'dart:io';

/// Glob pattern matching helper.
///
/// All methods are static for convenient use in D4rt scripts.
///
/// ## Example
/// ```dart
/// // Find all Dart files
/// final dartFiles = TomGlob.find('**/*.dart');
///
/// // Find files matching pattern
/// final configs = TomGlob.find('**/config.{yaml,json}');
///
/// // Check if path matches
/// if (TomGlob.matches('src/main.dart', '**/*.dart')) { ... }
/// ```
class TomGlob {
  TomGlob._(); // Prevent instantiation

  /// Find files matching a glob pattern.
  ///
  /// Supports common glob syntax:
  /// - `*` matches any characters except path separator
  /// - `**` matches any characters including path separator
  /// - `?` matches single character
  /// - `[abc]` matches character class
  /// - `{a,b}` matches alternation
  ///
  /// [pattern] - Glob pattern to match
  /// [root] - Root directory to search from (defaults to current directory)
  /// [followLinks] - Whether to follow symbolic links
  static List<String> find(
    String pattern, {
    String? root,
    bool followLinks = true,
  }) {
    final baseDir = Directory(root ?? Directory.current.path);
    if (!baseDir.existsSync()) return [];

    final regex = _globToRegex(pattern);
    final results = <String>[];

    for (final entity in baseDir.listSync(
      recursive: true,
      followLinks: followLinks,
    )) {
      final relativePath = _relativePath(entity.path, baseDir.path);
      if (regex.hasMatch(relativePath)) {
        results.add(entity.path);
      }
    }

    return results;
  }

  /// Find files matching any of multiple patterns.
  static List<String> findAny(
    List<String> patterns, {
    String? root,
    bool followLinks = true,
  }) {
    final results = <String>{};
    for (final pattern in patterns) {
      results.addAll(find(pattern, root: root, followLinks: followLinks));
    }
    return results.toList();
  }

  /// Find only files (not directories) matching pattern.
  static List<String> findFiles(
    String pattern, {
    String? root,
  }) {
    return find(pattern, root: root)
        .where((p) => File(p).existsSync())
        .toList();
  }

  /// Find only directories matching pattern.
  static List<String> findDirs(
    String pattern, {
    String? root,
  }) {
    return find(pattern, root: root)
        .where((p) => Directory(p).existsSync())
        .toList();
  }

  /// Check if a path matches a glob pattern.
  static bool matches(String path, String pattern) {
    final regex = _globToRegex(pattern);
    return regex.hasMatch(path);
  }

  /// Check if a path matches any of multiple patterns.
  static bool matchesAny(String path, List<String> patterns) {
    return patterns.any((p) => matches(path, p));
  }

  /// Filter a list of paths by glob pattern.
  static List<String> filter(List<String> paths, String pattern) {
    final regex = _globToRegex(pattern);
    return paths.where((p) => regex.hasMatch(p)).toList();
  }

  /// Exclude paths matching pattern from list.
  static List<String> exclude(List<String> paths, String pattern) {
    final regex = _globToRegex(pattern);
    return paths.where((p) => !regex.hasMatch(p)).toList();
  }

  /// Convert glob pattern to regex.
  static RegExp _globToRegex(String pattern) {
    final buffer = StringBuffer('^');

    var i = 0;
    while (i < pattern.length) {
      final c = pattern[i];

      if (c == '*') {
        if (i + 1 < pattern.length && pattern[i + 1] == '*') {
          // ** matches everything including path separators
          buffer.write('.*');
          i += 2;
          // Skip trailing slash after **
          if (i < pattern.length && (pattern[i] == '/' || pattern[i] == r'\')) {
            i++;
          }
          continue;
        } else {
          // * matches everything except path separators
          buffer.write(r'[^/\\]*');
        }
      } else if (c == '?') {
        buffer.write(r'[^/\\]');
      } else if (c == '[') {
        // Character class
        buffer.write('[');
        i++;
        while (i < pattern.length && pattern[i] != ']') {
          buffer.write(pattern[i]);
          i++;
        }
        buffer.write(']');
      } else if (c == '{') {
        // Alternation
        buffer.write('(?:');
        i++;
        while (i < pattern.length && pattern[i] != '}') {
          if (pattern[i] == ',') {
            buffer.write('|');
          } else {
            buffer.write(RegExp.escape(pattern[i]));
          }
          i++;
        }
        buffer.write(')');
      } else if (c == '/' || c == r'\') {
        // Path separator - match both
        buffer.write(r'[/\\]');
      } else if (RegExp(r'[.+^${}()|[\]\\]').hasMatch(c)) {
        // Escape regex special characters
        buffer.write('\\$c');
      } else {
        buffer.write(c);
      }

      i++;
    }

    buffer.write(r'$');
    return RegExp(buffer.toString(), caseSensitive: !Platform.isWindows);
  }

  /// Get relative path.
  static String _relativePath(String path, String base) {
    if (path.startsWith(base)) {
      var relative = path.substring(base.length);
      if (relative.startsWith('/') || relative.startsWith(r'\')) {
        relative = relative.substring(1);
      }
      return relative;
    }
    return path;
  }
}
