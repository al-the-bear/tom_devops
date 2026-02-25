/// Parser for mode template files.
///
/// Template syntax:
/// ```
/// @@@mode dev
/// content for dev mode
/// @@@mode release
/// content for release mode
/// @@@endmode
/// ```
class TemplateParser {
  /// The raw template content.
  final String content;

  /// Marker prefix for mode directives.
  static const String markerPrefix = '@@@';

  /// Pattern for mode start: @@@mode <name> or @@@mode <name1>, <name2>
  /// Allows optional leading whitespace (spaces or tabs).
  static final RegExp modeStartPattern =
      RegExp(r'^[ \t]*@@@mode\s+(.+)$', multiLine: true);

  /// Pattern for mode end: @@@endmode
  /// Allows optional leading whitespace (spaces or tabs).
  static final RegExp modeEndPattern =
      RegExp(r'^[ \t]*@@@endmode\s*$', multiLine: true);

  TemplateParser(this.content);

  /// Parses the template and returns a structured representation.
  ParsedTemplate parse() {
    final segments = <TemplateSegment>[];
    final allBlocks = <ModeBlock>[];
    final lines = content.split('\n');

    var textBuffer = StringBuffer();
    List<ModeBlock>? currentBlockGroup;
    String? currentModes;
    var blockContentBuffer = StringBuffer();
    var inModeBlock = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineWithNewline = i < lines.length - 1 ? '$line\n' : line;

      // Check for @@@mode start
      final modeMatch = modeStartPattern.firstMatch(line);
      if (modeMatch != null) {
        if (!inModeBlock) {
          // Starting a new mode block group
          // First, save any accumulated text
          if (textBuffer.isNotEmpty) {
            segments.add(TextSegment(textBuffer.toString()));
            textBuffer = StringBuffer();
          }
          currentBlockGroup = [];
          inModeBlock = true;
        } else {
          // Already in a mode block, save current block and start new one
          if (currentModes != null) {
            final block = ModeBlock(
              modes: _parseModes(currentModes),
              content: blockContentBuffer.toString(),
            );
            currentBlockGroup!.add(block);
            allBlocks.add(block);
            blockContentBuffer = StringBuffer();
          }
        }
        currentModes = modeMatch.group(1)!.trim();
        continue;
      }

      // Check for @@@endmode
      if (modeEndPattern.hasMatch(line)) {
        if (inModeBlock && currentModes != null) {
          // Save the current block
          final block = ModeBlock(
            modes: _parseModes(currentModes),
            content: blockContentBuffer.toString(),
          );
          currentBlockGroup!.add(block);
          allBlocks.add(block);

          // Add the block group to segments
          segments.add(ModeBlockGroup(currentBlockGroup));

          // Reset state
          blockContentBuffer = StringBuffer();
          currentModes = null;
          currentBlockGroup = null;
          inModeBlock = false;
        }
        continue;
      }

      // Regular content
      if (inModeBlock) {
        blockContentBuffer.write(lineWithNewline);
      } else {
        textBuffer.write(lineWithNewline);
      }
    }

    // Handle any remaining text
    if (textBuffer.isNotEmpty) {
      segments.add(TextSegment(textBuffer.toString()));
    }

    // Handle unclosed mode block (error case, but be lenient)
    if (inModeBlock && currentModes != null && currentBlockGroup != null) {
      final block = ModeBlock(
        modes: _parseModes(currentModes),
        content: blockContentBuffer.toString(),
      );
      currentBlockGroup.add(block);
      allBlocks.add(block);
      segments.add(ModeBlockGroup(currentBlockGroup));
    }

    return ParsedTemplate(
      segments: segments,
      blocks: allBlocks,
    );
  }

  /// Parses comma-separated mode names.
  List<String> _parseModes(String modesStr) {
    return modesStr
        .split(',')
        .map((m) => m.trim().toLowerCase())
        .where((m) => m.isNotEmpty)
        .toList();
  }
}

/// A parsed template containing segments of text and mode blocks.
class ParsedTemplate {
  /// Ordered list of segments (text and mode block groups).
  final List<TemplateSegment> segments;

  /// All mode blocks found in the template.
  final List<ModeBlock> blocks;

  ParsedTemplate({
    required this.segments,
    required this.blocks,
  });

  /// Returns all unique modes defined in this template.
  Set<String> get definedModes {
    final modes = <String>{};
    for (final block in blocks) {
      modes.addAll(block.modes);
    }
    return modes;
  }
}

/// Base class for template segments.
abstract class TemplateSegment {}

/// A segment of plain text (outside any mode block).
class TextSegment extends TemplateSegment {
  final String content;
  TextSegment(this.content);
}

/// A group of mode blocks (alternatives for the same location).
class ModeBlockGroup extends TemplateSegment {
  final List<ModeBlock> blocks;
  ModeBlockGroup(this.blocks);
}

/// A single mode block with its content.
class ModeBlock {
  /// The modes this block applies to.
  final List<String> modes;

  /// The content of this block.
  final String content;

  ModeBlock({
    required this.modes,
    required this.content,
  });

  @override
  String toString() => 'ModeBlock(modes: $modes, content: ${content.length} chars)';
}
