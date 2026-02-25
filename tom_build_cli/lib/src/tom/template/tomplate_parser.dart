/// Tomplate file parsing for Tom CLI.
///
/// Parses .tomplate template files and identifies mode blocks
/// and placeholders for later processing.
library;

import 'dart:io';

import 'package:path/path.dart' as path;

// =============================================================================
// TOMPLATE PARSER
// =============================================================================

/// Parses .tomplate template files.
///
/// Supports two naming conventions:
/// - `filename.ext.tomplate` → generates `filename.ext`
/// - `filename.tomplate.ext` → generates `filename.ext`
class TomplateParser {
  /// Creates a new TomplateParser.
  TomplateParser();

  /// Finds all .tomplate files in a directory.
  List<TomplateFile> findTemplates(String directory) {
    final dir = Directory(directory);
    if (!dir.existsSync()) return [];

    final templates = <TomplateFile>[];

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        final filePath = entity.path;
        if (_isTomplate(filePath)) {
          templates.add(parseFile(filePath));
        }
      }
    }

    return templates;
  }

  /// Parses a single .tomplate file.
  TomplateFile parseFile(String filePath) {
    final file = File(filePath);
    final content = file.existsSync() ? file.readAsStringSync() : '';

    return TomplateFile(
      sourcePath: filePath,
      targetPath: _getTargetPath(filePath),
      content: content,
      placeholders: _findPlaceholders(content),
      hasModeBlocks: _hasModeBlocks(content),
    );
  }

  /// Parses tomplate content without reading from file.
  TomplateFile parseContent(String content, String sourcePath) {
    return TomplateFile(
      sourcePath: sourcePath,
      targetPath: _getTargetPath(sourcePath),
      content: content,
      placeholders: _findPlaceholders(content),
      hasModeBlocks: _hasModeBlocks(content),
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Checks if a file path is a .tomplate file.
  bool _isTomplate(String filePath) {
    final basename = path.basename(filePath);
    return basename.endsWith('.tomplate') || basename.contains('.tomplate.');
  }

  /// Gets the target file path for a .tomplate file.
  String _getTargetPath(String sourcePath) {
    final dir = path.dirname(sourcePath);
    final basename = path.basename(sourcePath);

    // Pattern 1: filename.ext.tomplate → filename.ext
    if (basename.endsWith('.tomplate')) {
      final targetName = basename.substring(0, basename.length - 9);
      return path.join(dir, targetName);
    }

    // Pattern 2: filename.tomplate.ext → filename.ext
    final tomplateDotIndex = basename.indexOf('.tomplate.');
    if (tomplateDotIndex != -1) {
      final beforeTomplate = basename.substring(0, tomplateDotIndex);
      final afterTomplate = basename.substring(tomplateDotIndex + 9);
      return path.join(dir, '$beforeTomplate$afterTomplate');
    }

    // Fallback: return as-is
    return sourcePath;
  }

  /// Finds all placeholders in content.
  List<PlaceholderInfo> _findPlaceholders(String content) {
    final placeholders = <PlaceholderInfo>[];

    // Value reference: $VAL{key.path:-default}
    for (final match in _valueRefPattern.allMatches(content)) {
      placeholders.add(PlaceholderInfo(
        type: PlaceholderType.valueReference,
        fullMatch: match.group(0)!,
        key: match.group(1)!,
        defaultValue: match.group(2),
        offset: match.start,
      ));
    }

    // Environment: $ENV{ENV_VAR:-default}
    for (final match in _envPattern.allMatches(content)) {
      placeholders.add(PlaceholderInfo(
        type: PlaceholderType.environment,
        fullMatch: match.group(0)!,
        key: match.group(1)!,
        defaultValue: match.group(2),
        offset: match.start,
      ));
    }

    // D4rt expression: $D4{expression:-default}
    for (final match in _d4rtPattern.allMatches(content)) {
      placeholders.add(PlaceholderInfo(
        type: PlaceholderType.d4rtExpression,
        fullMatch: match.group(0)!,
        key: match.group(1)!,
        defaultValue: match.group(2),
        offset: match.start,
      ));
    }

    // Generator: $GEN{path.*.field;separator}
    for (final match in _generatorPattern.allMatches(content)) {
      placeholders.add(PlaceholderInfo(
        type: PlaceholderType.generator,
        fullMatch: match.group(0)!,
        key: match.group(1)!,
        defaultValue: null, // Generators don't have defaults
        offset: match.start,
      ));
    }

    return placeholders;
  }

  /// Checks if content has mode blocks.
  bool _hasModeBlocks(String content) {
    return content.contains('@@@mode');
  }

  // Regex patterns for placeholders
  // Updated to use YAML-friendly $PREFIX{...} syntax
  static final _valueRefPattern = RegExp(r'\$VAL\{([^}:]+)(?::-([^}]*))?\}');
  static final _envPattern = RegExp(r'\$ENV\{([^}:]+)(?::-([^}]*))?\}');
  static final _d4rtPattern = RegExp(r'\$D4\{([^}:]+)(?::-([^}]*))?\}');
  static final _generatorPattern = RegExp(r'\$GEN\{([^}]+)\}');
}

// =============================================================================
// TOMPLATE FILE
// =============================================================================

/// Represents a parsed .tomplate file.
class TomplateFile {
  /// Creates a new TomplateFile.
  const TomplateFile({
    required this.sourcePath,
    required this.targetPath,
    required this.content,
    required this.placeholders,
    required this.hasModeBlocks,
  });

  /// Path to the .tomplate source file.
  final String sourcePath;

  /// Path where the generated file will be written.
  final String targetPath;

  /// Raw content of the template.
  final String content;

  /// List of placeholders found in the content.
  final List<PlaceholderInfo> placeholders;

  /// Whether the template contains mode blocks.
  final bool hasModeBlocks;

  /// Gets placeholders of a specific type.
  List<PlaceholderInfo> getPlaceholdersOfType(PlaceholderType type) {
    return placeholders.where((p) => p.type == type).toList();
  }

  /// Returns true if the template has any placeholders.
  bool get hasPlaceholders => placeholders.isNotEmpty;
}

// =============================================================================
// PLACEHOLDER INFO
// =============================================================================

/// Types of placeholders supported in templates.
enum PlaceholderType {
  /// Value reference: ${key.path:-default}
  valueReference,

  /// Environment variable: [[ENV_VAR:-default]]
  environment,

  /// D4rt expression: {{expression:-default}}
  d4rtExpression,

  /// Generator: {{path.*.field;separator}}
  generator,
}

/// Information about a placeholder in a template.
class PlaceholderInfo {
  /// Creates a new PlaceholderInfo.
  const PlaceholderInfo({
    required this.type,
    required this.fullMatch,
    required this.key,
    this.defaultValue,
    required this.offset,
  });

  /// Type of placeholder.
  final PlaceholderType type;

  /// Full matched string including delimiters.
  final String fullMatch;

  /// Key/expression inside the placeholder.
  final String key;

  /// Default value (if specified with :-).
  final String? defaultValue;

  /// Character offset in the content.
  final int offset;

  @override
  String toString() => 'Placeholder($type: $key)';
}
