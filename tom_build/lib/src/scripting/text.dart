/// Text processing utilities for scripting.
///
/// Provides convenient static methods for text manipulation,
/// common in shell scripts and build tools.
library;

/// Text processing helper.
///
/// All methods are static for convenient use in D4rt scripts.
///
/// ## Example
/// ```dart
/// // Template replacement
/// final result = TomText.template(
///   'Hello {{name}}!',
///   {'name': 'World'},
/// );
///
/// // Indentation
/// final indented = TomText.indent(code, 2);
///
/// // Line processing
/// final filtered = TomText.filterLines(log, (l) => l.contains('ERROR'));
/// ```
class TomText {
  TomText._(); // Prevent instantiation

  /// Replace placeholders in a template string.
  ///
  /// Default delimiters are `{{` and `}}`.
  static String template(
    String text,
    Map<String, dynamic> values, {
    String open = '{{',
    String close = '}}',
  }) {
    var result = text;
    for (final entry in values.entries) {
      result = result.replaceAll(
        '$open${entry.key}$close',
        entry.value?.toString() ?? '',
      );
    }
    return result;
  }

  /// Indent each line of text.
  static String indent(String text, int spaces, {String char = ' '}) {
    final prefix = char * spaces;
    return text.split('\n').map((l) => l.isEmpty ? l : '$prefix$l').join('\n');
  }

  /// Remove indentation from text.
  ///
  /// Removes the minimum common leading whitespace from all lines.
  static String dedent(String text) {
    final lines = text.split('\n');

    // Find minimum indentation (ignoring empty lines)
    var minIndent = 999999;
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final leadingSpaces = line.length - line.trimLeft().length;
      if (leadingSpaces < minIndent) minIndent = leadingSpaces;
    }

    if (minIndent == 999999) return text;

    // Remove that indentation
    return lines
        .map((l) {
          if (l.trim().isEmpty) return '';
          return l.length > minIndent ? l.substring(minIndent) : l;
        })
        .join('\n');
  }

  /// Wrap text to specified width.
  static String wrap(String text, int width, {String lineBreak = '\n'}) {
    final words = text.split(RegExp(r'\s+'));
    final lines = <String>[];
    var currentLine = StringBuffer();

    for (final word in words) {
      if (currentLine.isEmpty) {
        currentLine.write(word);
      } else if (currentLine.length + 1 + word.length <= width) {
        currentLine.write(' $word');
      } else {
        lines.add(currentLine.toString());
        currentLine = StringBuffer(word);
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine.toString());
    }

    return lines.join(lineBreak);
  }

  /// Truncate text with ellipsis.
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - suffix.length)}$suffix';
  }

  /// Split text into lines.
  static List<String> lines(String text) => text.split('\n');

  /// Join lines into text.
  static String joinLines(List<String> lines, {String separator = '\n'}) =>
      lines.join(separator);

  /// Filter lines matching a predicate.
  static String filterLines(String text, bool Function(String) predicate) {
    return text.split('\n').where(predicate).join('\n');
  }

  /// Map over lines.
  static String mapLines(String text, String Function(String) mapper) {
    return text.split('\n').map(mapper).join('\n');
  }

  /// Get first N lines.
  static String head(String text, int n) {
    final allLines = text.split('\n');
    return allLines.take(n).join('\n');
  }

  /// Get last N lines.
  static String tail(String text, int n) {
    final allLines = text.split('\n');
    final startIndex = allLines.length > n ? allLines.length - n : 0;
    return allLines.sublist(startIndex).join('\n');
  }

  /// Count lines.
  static int lineCount(String text) => text.split('\n').length;

  /// Count words.
  static int wordCount(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  /// Count characters (excluding whitespace).
  static int charCount(String text, {bool excludeWhitespace = true}) {
    if (excludeWhitespace) {
      return text.replaceAll(RegExp(r'\s'), '').length;
    }
    return text.length;
  }

  /// Extract content between delimiters.
  static String? between(String text, String start, String end) {
    final startIdx = text.indexOf(start);
    if (startIdx == -1) return null;
    final endIdx = text.indexOf(end, startIdx + start.length);
    if (endIdx == -1) return null;
    return text.substring(startIdx + start.length, endIdx);
  }

  /// Extract all content between delimiters.
  static List<String> allBetween(String text, String start, String end) {
    final results = <String>[];
    var searchStart = 0;

    while (true) {
      final startIdx = text.indexOf(start, searchStart);
      if (startIdx == -1) break;
      final endIdx = text.indexOf(end, startIdx + start.length);
      if (endIdx == -1) break;
      results.add(text.substring(startIdx + start.length, endIdx));
      searchStart = endIdx + end.length;
    }

    return results;
  }

  /// Convert to slug (URL-friendly).
  static String slug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  /// Convert to camelCase.
  static String camelCase(String text) {
    final words = text.split(RegExp(r'[\s_-]+'));
    if (words.isEmpty) return '';
    return words.first.toLowerCase() +
        words.skip(1).map((w) => _capitalize(w)).join();
  }

  /// Convert to PascalCase.
  static String pascalCase(String text) {
    return text.split(RegExp(r'[\s_-]+')).map((w) => _capitalize(w)).join();
  }

  /// Convert to snake_case.
  static String snakeCase(String text) {
    return text
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]}_${m[2]}')
        .toLowerCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
  }

  /// Convert to kebab-case.
  static String kebabCase(String text) {
    return snakeCase(text).replaceAll('_', '-');
  }

  /// Capitalize first letter.
  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Title case (capitalize each word).
  static String titleCase(String text) {
    return text.split(' ').map((w) => _capitalize(w)).join(' ');
  }

  /// Pad left with character.
  static String padLeft(String text, int width, {String char = ' '}) {
    return text.padLeft(width, char);
  }

  /// Pad right with character.
  static String padRight(String text, int width, {String char = ' '}) {
    return text.padRight(width, char);
  }

  /// Center text.
  static String center(String text, int width, {String char = ' '}) {
    final padding = width - text.length;
    if (padding <= 0) return text;
    final leftPad = padding ~/ 2;
    final rightPad = padding - leftPad;
    return '${char * leftPad}$text${char * rightPad}';
  }

  /// Remove blank lines.
  static String removeBlankLines(String text) {
    return text.split('\n').where((l) => l.trim().isNotEmpty).join('\n');
  }

  /// Collapse multiple blank lines into single.
  static String collapseBlankLines(String text) {
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  /// Trim each line.
  static String trimLines(String text) {
    return text.split('\n').map((l) => l.trim()).join('\n');
  }

  /// Check if text contains all patterns.
  static bool containsAll(String text, List<String> patterns) {
    return patterns.every((p) => text.contains(p));
  }

  /// Check if text contains any pattern.
  static bool containsAny(String text, List<String> patterns) {
    return patterns.any((p) => text.contains(p));
  }

  /// Replace multiple patterns.
  static String replaceAll(String text, Map<String, String> replacements) {
    var result = text;
    for (final entry in replacements.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  // ===========================================================================
  // Escape utilities
  // ===========================================================================

  /// Escape HTML special characters.
  ///
  /// Escapes: & < > " '
  static String escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Unescape HTML entities.
  static String unescapeHtml(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  /// Escape JSON string special characters.
  ///
  /// Escapes: \ " and control characters
  static String escapeJson(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// Escape regex special characters.
  ///
  /// Makes text safe to use as a literal in a regex pattern.
  static String escapeRegex(String text) {
    return text.replaceAllMapped(
      RegExp(r'[.\^$*+?{}\[\]|()\\]'),
      (m) => '\\${m[0]}',
    );
  }

  /// Escape shell special characters.
  ///
  /// Wraps in single quotes and escapes any single quotes in the text.
  /// Safe for use in shell commands.
  static String escapeShell(String text) {
    // Replace single quotes with '\'' (end quote, escaped quote, start quote)
    final escaped = text.replaceAll("'", "'\\\"'\\\"'");
    return "'$escaped'";
  }
}
