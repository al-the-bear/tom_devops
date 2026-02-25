/// Mode block processing for Tom CLI.
///
/// Handles parsing and processing of mode blocks (@@@mode...@@@endmode)
/// in tom_project.yaml and .tomplate files.
library;

// =============================================================================
// MODE PROCESSOR
// =============================================================================

/// Processes mode blocks in YAML/template content.
///
/// Mode blocks have the syntax:
/// ```yaml
/// @@@mode <condition>
/// content
/// @@@mode <other_condition>
/// other content
/// @@@mode default
/// fallback content
/// @@@endmode
/// ```
class ModeProcessor {
  /// Creates a new ModeProcessor.
  ModeProcessor();

  /// Processes mode blocks in content, keeping only matching blocks.
  ///
  /// Parameters:
  /// - [content]: The content with mode blocks
  /// - [activeModes]: Set of currently active mode names
  /// - [modeTypeValues]: Map of mode-type to active value (e.g., {'environment': 'prod'})
  ///
  /// Returns the content with only matching mode blocks included.
  String processContent(
    String content,
    Set<String> activeModes, {
    Map<String, String> modeTypeValues = const {},
  }) {
    final blocks = _parseBlocks(content);
    if (blocks.isEmpty) return content;

    final buffer = StringBuffer();
    var lastEnd = 0;

    for (final block in blocks) {
      // Add content before this block
      buffer.write(content.substring(lastEnd, block.startOffset));

      // Find the matching section
      final matchingContent = _findMatchingSection(
        block,
        activeModes,
        modeTypeValues,
      );

      if (matchingContent != null) {
        buffer.write(matchingContent);
      }

      lastEnd = block.endOffset;
    }

    // Add remaining content after last block
    buffer.write(content.substring(lastEnd));

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Block parsing
  // ---------------------------------------------------------------------------

  static final _modeStartPattern = RegExp(
    r'^(\s*)@@@mode\s+(.+)$',
    multiLine: true,
  );
  static final _modeEndPattern = RegExp(
    r'^(\s*)@@@endmode\s*$',
    multiLine: true,
  );

  /// Parses all mode blocks in the content.
  List<_ModeBlock> _parseBlocks(String content) {
    final blocks = <_ModeBlock>[];
    final startMatches = _modeStartPattern.allMatches(content).toList();
    final endMatches = _modeEndPattern.allMatches(content).toList();

    if (startMatches.isEmpty) return blocks;

    var endIndex = 0;

    for (var i = 0; i < startMatches.length; i++) {
      final startMatch = startMatches[i];

      // Check if this is the start of a new block (not a section within)
      if (i == 0 || startMatch.start >= blocks.last.endOffset) {
        // Find the matching @@@endmode
        while (endIndex < endMatches.length &&
            endMatches[endIndex].start < startMatch.end) {
          endIndex++;
        }

        if (endIndex >= endMatches.length) {
          // No matching endmode found, skip
          continue;
        }

        // Find all sections within this block
        final sections = <_ModeSection>[];
        final indent = startMatch.group(1) ?? '';

        for (var j = i; j < startMatches.length; j++) {
          final sectionMatch = startMatches[j];

          // Check if this section is within our block
          if (sectionMatch.start >= endMatches[endIndex].start) {
            break;
          }

          // Parse the condition
          final condition = sectionMatch.group(2)?.trim() ?? '';

          // Find the end of this section (next @@@mode or @@@endmode)
          int sectionEnd;
          if (j + 1 < startMatches.length &&
              startMatches[j + 1].start < endMatches[endIndex].start) {
            sectionEnd = startMatches[j + 1].start;
          } else {
            sectionEnd = endMatches[endIndex].start;
          }

          sections.add(_ModeSection(
            condition: condition,
            content: content.substring(sectionMatch.end, sectionEnd),
            indent: indent,
          ));
        }

        blocks.add(_ModeBlock(
          startOffset: startMatch.start,
          endOffset: endMatches[endIndex].end,
          sections: sections,
        ));

        endIndex++;
      }
    }

    return blocks;
  }

  /// Finds the content of the first matching section in a block.
  String? _findMatchingSection(
    _ModeBlock block,
    Set<String> activeModes,
    Map<String, String> modeTypeValues,
  ) {
    _ModeSection? defaultSection;

    for (final section in block.sections) {
      if (section.condition == 'default') {
        defaultSection = section;
        continue;
      }

      if (_matchesCondition(section.condition, activeModes, modeTypeValues)) {
        return _stripIndent(section.content, section.indent);
      }
    }

    // Fall back to default if no match
    if (defaultSection != null) {
      return _stripIndent(defaultSection.content, defaultSection.indent);
    }

    return null;
  }

  /// Checks if a condition matches the current mode state.
  ///
  /// Condition formats:
  /// - `mode1,mode2` - matches if ANY mode is active (OR)
  /// - `:mode-type=value` - matches if mode type has specific value
  bool _matchesCondition(
    String condition,
    Set<String> activeModes,
    Map<String, String> modeTypeValues,
  ) {
    // Check for typed mode condition (:mode-type=value)
    if (condition.startsWith(':')) {
      return _matchesTypedCondition(condition.substring(1), modeTypeValues);
    }

    // Simple mode list (comma-separated OR)
    final modes = condition.split(',').map((s) => s.trim()).toList();
    return modes.any((mode) => activeModes.contains(mode));
  }

  /// Matches a typed condition like `environment=prod`.
  bool _matchesTypedCondition(
    String condition,
    Map<String, String> modeTypeValues,
  ) {
    final parts = condition.split('=');
    if (parts.length != 2) return false;

    final modeType = parts[0].trim();
    final expectedValue = parts[1].trim();
    final actualValue = modeTypeValues[modeType];

    return actualValue == expectedValue;
  }

  /// Removes leading indent from content lines.
  String _stripIndent(String content, String indent) {
    if (indent.isEmpty) return content;

    final lines = content.split('\n');
    final stripped = lines.map((line) {
      if (line.startsWith(indent)) {
        return line.substring(indent.length);
      }
      return line;
    }).toList();

    return stripped.join('\n');
  }
}

// =============================================================================
// INTERNAL TYPES
// =============================================================================

/// A complete mode block from @@@mode to @@@endmode.
class _ModeBlock {
  const _ModeBlock({
    required this.startOffset,
    required this.endOffset,
    required this.sections,
  });

  final int startOffset;
  final int endOffset;
  final List<_ModeSection> sections;
}

/// A single section within a mode block.
class _ModeSection {
  const _ModeSection({
    required this.condition,
    required this.content,
    required this.indent,
  });

  final String condition;
  final String content;
  final String indent;
}
