/// Tomplate file processing for Tom CLI.
///
/// Processes .tomplate files by applying mode blocks and
/// resolving placeholders to generate target files.
///
/// ## Placeholder Types
///
/// | Type | Syntax | Stage |
/// |------|--------|-------|
/// | Environment (bracket) | `[[VAR:-default]]` | Generation & Execution |
/// | Data Path | `[{path.to.value:-default}]` | Generation & Execution |
/// | Value Reference | `$VAL{key.path:-default}` | Execution only |
/// | Environment | `$ENV{NAME:-default}` | Execution only |
/// | D4rt Expression | `$D4{expression}` | Execution only |
/// | Generator | `$GEN{path.*.field;sep}` | Execution only |
library;

import 'dart:io';

import '../mode/mode_processor.dart';
import '../mode/mode_resolver.dart';
import 'tomplate_parser.dart';

// =============================================================================
// TOMPLATE PROCESSOR
// =============================================================================

/// Processes .tomplate files to generate target files.
///
/// Processing flow:
/// 1. Apply mode block processing
/// 2. Resolve [[VAR]] environment placeholders (during generation)
/// 3. Resolve [{path}] data path placeholders (during generation)
/// 4. Preserve $VAL{}, $ENV{}, $D4{}, $GEN{} placeholders for runtime resolution
/// 5. Write target file to disk
class TomplateProcessor {
  /// Creates a new TomplateProcessor.
  TomplateProcessor({
    ModeProcessor? modeProcessor,
  }) : _modeProcessor = modeProcessor ?? ModeProcessor();

  final ModeProcessor _modeProcessor;

  /// Processes a template file and returns the processed content.
  ///
  /// This performs:
  /// - Mode block processing (if [resolvedModes] is provided)
  /// - [[VAR]] environment placeholder resolution (generation time)
  /// - [{path}] data path placeholder resolution (if [context] is provided)
  ///
  /// Note: $VAL{}, $ENV{}, $D4{}, $GEN{} placeholders are preserved for runtime.
  ///
  /// Parameters:
  /// - [template]: The parsed template file
  /// - [resolvedModes]: Resolved mode state for mode block processing
  /// - [context]: Configuration context for [{...}] placeholder resolution
  /// - [environment]: Environment variables for [[...]] resolution
  TomplateResult process({
    required TomplateFile template,
    ResolvedModes? resolvedModes,
    Map<String, dynamic>? context,
    bool resolveEnvironment = false,
    Map<String, String>? environment,
    bool resolveGenerators = true,
  }) {
    var content = template.content;

    // Step 1: Apply mode block processing
    if (template.hasModeBlocks && resolvedModes != null) {
      content = _modeProcessor.processContent(
        content,
        resolvedModes.activeModes,
        modeTypeValues: resolvedModes.modeTypeValues,
      );
    }

    // Step 2: Resolve [[VAR]] environment placeholders (generation time)
    content = _resolveBracketEnv(content, environment ?? Platform.environment);

    // Step 3: Resolve [{path}] data path placeholders (generation time)
    if (context != null) {
      content = _resolveBracketData(content, context);
    }

    // Note: $VAL{}, $ENV{}, $D4{}, $GEN{} are NOT resolved here
    // They are preserved for runtime resolution before action execution

    return TomplateResult(
      sourcePath: template.sourcePath,
      targetPath: template.targetPath,
      content: content,
    );
  }

  /// Writes a processed template to its target file.
  void writeToFile(TomplateResult processed) {
    final file = File(processed.targetPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(processed.content);
  }

  /// Processes a template and writes the result to disk.
  void processAndWrite({
    required TomplateFile template,
    ResolvedModes? resolvedModes,
    Map<String, dynamic>? context,
    bool resolveEnvironment = false,
    Map<String, String>? environment,
  }) {
    final processed = process(
      template: template,
      resolvedModes: resolvedModes,
      context: context,
      resolveEnvironment: resolveEnvironment,
      environment: environment,
    );
    writeToFile(processed);
  }

  // ---------------------------------------------------------------------------
  // Placeholder resolution (generation time)
  // ---------------------------------------------------------------------------

  /// Pattern for [[VAR]] or [[VAR:-default]] environment placeholders.
  static final _bracketEnvPattern = RegExp(r'\[\[([^\]:-]+)(?::-([^\]]*))?\]\]');

  /// Pattern for [{path}] or [{path:-default}] data placeholders.
  static final _bracketDataPattern = RegExp(r'\[\{([^}:-]+)(?::-([^}]*))?\}\]');

  /// Resolves [[VAR:-default]] environment placeholders.
  String _resolveBracketEnv(String content, Map<String, String> environment) {
    return content.replaceAllMapped(_bracketEnvPattern, (match) {
      final varName = match.group(1)!;
      final defaultValue = match.group(2);

      final value = environment[varName];
      if (value != null && value.isNotEmpty) {
        return value;
      } else if (defaultValue != null) {
        return defaultValue;
      }

      // Leave unresolved if no value and no default
      return match.group(0)!;
    });
  }

  /// Resolves [{path.to.value:-default}] data path placeholders.
  String _resolveBracketData(
    String content,
    Map<String, dynamic> context, {
    int depth = 0,
  }) {
    if (depth >= 10) {
      return content;
    }

    var hasReplacements = false;
    final result = content.replaceAllMapped(_bracketDataPattern, (match) {
      final keyPath = match.group(1)!;
      final defaultValue = match.group(2);

      final value = _resolveKeyPath(keyPath, context);
      if (value != null) {
        hasReplacements = true;
        return value.toString();
      } else if (defaultValue != null) {
        hasReplacements = true;
        return defaultValue;
      }

      // Keep unresolved for next iteration
      return match.group(0)!;
    });

    // Recursively resolve if we made replacements (for nested placeholders)
    if (hasReplacements) {
      return _resolveBracketData(result, context, depth: depth + 1);
    }

    return result;
  }

  /// Resolves a dot-separated key path in a context map.
  dynamic _resolveKeyPath(String keyPath, Map<String, dynamic> context) {
    final parts = keyPath.split('.');
    dynamic current = context;

    for (final part in parts) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current;
  }
}

// =============================================================================
// PROCESSED TEMPLATE
// =============================================================================

/// Result of processing a tomplate file.
///
/// Note: This is different from `TomplateResult` in ws_prepper.dart,
/// which is for the older workspace preparer system.
class TomplateResult {
  /// Creates a new TomplateResult.
  const TomplateResult({
    required this.sourcePath,
    required this.targetPath,
    required this.content,
  });

  /// Path to the source .tomplate file.
  final String sourcePath;

  /// Path where the generated file will be/was written.
  final String targetPath;

  /// Processed content ready to be written.
  final String content;
}

// =============================================================================
// EXCEPTIONS
// =============================================================================

/// Exception thrown when placeholder resolution fails.
class PlaceholderResolutionException implements Exception {
  /// Creates a new PlaceholderResolutionException.
  const PlaceholderResolutionException(this.message, {this.unresolved});

  /// Error message.
  final String message;

  /// Unresolved placeholder text.
  final String? unresolved;

  @override
  String toString() {
    final buffer = StringBuffer('Error: $message');
    if (unresolved != null) {
      buffer.writeln('\n  Unresolved: $unresolved');
    }
    return buffer.toString();
  }
}
