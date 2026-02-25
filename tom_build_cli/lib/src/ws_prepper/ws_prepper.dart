import 'dart:io';

import 'template_parser.dart';

export 'template_parser.dart' show ModeBlock, ParsedTemplate;

/// Workspace preparer for processing template files based on active mode.
///
/// Scans a workspace for `.tomplate` files and generates the target files 
/// by including only the content for the specified mode.
///
/// Template syntax:
/// ```
/// @@@mode dev
/// content for dev mode
/// @@@mode release
/// content for release mode
/// @@@mode default
/// fallback content if no mode matches
/// @@@endmode
/// ```
class WsPrepper {
  /// The root directory to scan for templates.
  final String workspacePath;

  /// Options for the workspace preparer.
  final WsPrepperOptions options;

  /// Creates a new workspace preparer for the given workspace.
  WsPrepper(this.workspacePath, {WsPrepperOptions? options})
      : options = options ?? WsPrepperOptions();

  /// Finds all `.tomplate` files in the workspace.
  Future<List<File>> findTemplates() async {
    final templates = <File>[];
    final dir = Directory(workspacePath);

    if (!dir.existsSync()) {
      return templates;
    }

    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.tomplate')) {
        // Skip excluded directories
        if (_shouldExclude(entity.path)) continue;
        templates.add(entity);
      }
    }

    return templates;
  }

  /// Processes all templates in the workspace for the given mode.
  ///
  /// Returns a [WsPrepperResult] containing information about processed files.
  Future<WsPrepperResult> processAll(String mode) async {
    final templates = await findTemplates();
    final result = WsPrepperResult(mode: mode);

    for (final template in templates) {
      try {
        final processResult = await processTemplate(template, mode);
        result.processed.add(processResult);
      } catch (e) {
        result.errors.add(WsPrepperError(
          templatePath: template.path,
          message: e.toString(),
        ));
      }
    }

    return result;
  }

  /// Processes a single template file for the given mode.
  ///
  /// Returns the path of the generated file.
  Future<PreparedTemplate> processTemplate(File template, String mode) async {
    final content = await template.readAsString();
    final parser = TemplateParser(content);
    final parsed = parser.parse();

    final output = generateOutput(parsed, mode);
    final outputPath = _getOutputPath(template.path);

    if (!options.dryRun) {
      final outputFile = File(outputPath);
      await outputFile.writeAsString(output);
    }

    return PreparedTemplate(
      templatePath: template.path,
      outputPath: outputPath,
      mode: mode,
      blocksFound: parsed.blocks.length,
      dryRun: options.dryRun,
    );
  }

  /// Generates output content for the given mode(s).
  ///
  /// If [mode] contains comma-separated values (e.g., "dev,local,debug"),
  /// they are processed in order. For each mode block, the last matching
  /// mode in the list wins.
  String generateOutput(ParsedTemplate parsed, String mode) {
    // Parse comma-separated modes into a list
    final modes = mode
        .split(',')
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty)
        .toList();

    final buffer = StringBuffer();

    for (final segment in parsed.segments) {
      if (segment is TextSegment) {
        buffer.write(segment.content);
      } else if (segment is ModeBlockGroup) {
        final matchingBlock = _findMatchingBlock(segment.blocks, modes);
        if (matchingBlock != null) {
          buffer.write(matchingBlock.content);
        }
      }
    }

    return buffer.toString();
  }

  /// Finds the matching block for the given modes.
  ///
  /// When multiple modes are provided, they are processed in order.
  /// The last matching mode in the list wins. For example, if modes
  /// are ["dev", "local"] and a block has both "dev" and "local",
  /// the "local" block content will be used.
  ModeBlock? _findMatchingBlock(List<ModeBlock> blocks, List<String> modes) {
    ModeBlock? result;

    // Process modes in order - last match wins
    for (final mode in modes) {
      for (final block in blocks) {
        if (block.modes.contains(mode)) {
          result = block;
          // Don't break - continue to find later matches
        }
      }
    }

    // If no match found, look for default
    if (result == null) {
      for (final block in blocks) {
        if (block.modes.contains('default')) {
          return block;
        }
      }
    }

    return result;
  }

  /// Gets the output path by removing `.tomplate` extension.
  String _getOutputPath(String templatePath) {
    if (templatePath.endsWith('.tomplate')) {
      return templatePath.substring(
          0, templatePath.length - '.tomplate'.length);
    }
    return templatePath;
  }

  /// Checks if a path should be excluded from processing.
  bool _shouldExclude(String path) {
    for (final pattern in options.excludePatterns) {
      if (path.contains(pattern)) {
        return true;
      }
    }
    return false;
  }
}

/// Options for the workspace preparer.
class WsPrepperOptions {
  /// If true, don't write files, just report what would be done.
  final bool dryRun;

  /// Directory patterns to exclude from scanning.
  final List<String> excludePatterns;

  WsPrepperOptions({
    this.dryRun = false,
    List<String>? excludePatterns,
  }) : excludePatterns = excludePatterns ??
            [
              '.dart_tool',
              '.git',
              '/build/',
              'node_modules/',
            ];
}

/// Result of processing all templates.
class WsPrepperResult {
  /// The mode that was applied.
  final String mode;

  /// Successfully processed templates.
  final List<PreparedTemplate> processed;

  /// Errors encountered during processing.
  final List<WsPrepperError> errors;

  WsPrepperResult({
    required this.mode,
    List<PreparedTemplate>? processed,
    List<WsPrepperError>? errors,
  })  : processed = processed ?? [],
        errors = errors ?? [];

  /// Whether all templates were processed successfully.
  bool get success => errors.isEmpty;

  /// Total number of templates found.
  int get totalTemplates => processed.length + errors.length;
}

/// Information about a processed template.
class PreparedTemplate {
  /// Path to the template file.
  final String templatePath;

  /// Path to the generated output file.
  final String outputPath;

  /// The mode that was applied.
  final String mode;

  /// Number of mode blocks found in the template.
  final int blocksFound;

  /// Whether this was a dry run (no file written).
  final bool dryRun;

  PreparedTemplate({
    required this.templatePath,
    required this.outputPath,
    required this.mode,
    required this.blocksFound,
    this.dryRun = false,
  });

  @override
  String toString() {
    final action = dryRun ? 'Would generate' : 'Generated';
    return '$action: $outputPath (from template, $blocksFound mode blocks)';
  }
}

/// Error encountered during template processing.
class WsPrepperError {
  /// Path to the template file that caused the error.
  final String templatePath;

  /// Error message.
  final String message;

  WsPrepperError({
    required this.templatePath,
    required this.message,
  });

  @override
  String toString() => 'Error processing $templatePath: $message';
}
