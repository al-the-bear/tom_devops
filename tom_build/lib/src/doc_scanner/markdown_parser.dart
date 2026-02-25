/// Internal markdown parser for DocScanner.
///
/// Handles parsing of headlines, ID extraction, and section hierarchy building.
library;

/// A parsed headline from markdown.
class ParsedHeadline {
  /// The headline level (1-6 for # through ######).
  final int level;

  /// The line number in the source file (1-based).
  final int lineNumber;

  /// The raw headline line from markdown (without the # markers).
  final String rawHeadline;

  /// The extracted ID from `[id]` or `<!--[id]-->`.
  final String? explicitId;

  /// The headline text (without markers, ID, and metadata).
  final String text;

  /// Key-value metadata fields parsed from the headline.
  ///
  /// Parsed from `key=value` pairs in HTML comments or text around the ID.
  /// Example: `## <!--[my_id] type=api version=2--> Title` produces
  /// `{'type': 'api', 'version': '2'}`.
  final Map<String, String> fields;

  const ParsedHeadline({
    required this.level,
    required this.lineNumber,
    required this.rawHeadline,
    this.explicitId,
    required this.text,
    this.fields = const {},
  });
}

/// Parses markdown content into structured sections.
class MarkdownParser {
  /// Pattern to match headlines: # through ######
  static final _headlinePattern = RegExp(r'^(#{1,6})\s+(.*)$');

  /// Pattern to extract HTML comment with optional content: <!--...-->
  static final _htmlCommentPattern = RegExp(r'<!--\s*(.*?)\s*-->');

  /// Pattern to extract ID from square brackets: [id]
  static final _squareBracketIdPattern = RegExp(r'\[([^\]]+)\]');

  /// Pattern to parse key=value pairs (supports quoted values)
  /// Matches: key=value, key="quoted value", key='quoted value'
  static final _keyValuePattern = RegExp(r'(\w+)=(?:"([^"]+)"|' r"'([^']+)'" r'|(\S+))');

  /// Parses a markdown string and returns parsed headlines with their positions.
  static List<(ParsedHeadline, int startLine, int endLine)> parseHeadlines(
    String content,
  ) {
    final lines = content.split('\n');
    final headlines = <(ParsedHeadline, int, int)>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _headlinePattern.firstMatch(line);

      if (match != null) {
        final level = match.group(1)!.length;
        final fullLine = line.trimRight(); // The complete headline line
        final headlineContent = match.group(2)!.trim();
        var headlineText = headlineContent;
        String? explicitId;
        final fields = <String, String>{};

        // Check for HTML comment
        final htmlMatch = _htmlCommentPattern.firstMatch(headlineText);
        String? commentContent;
        String textOutsideComment = headlineText;

        if (htmlMatch != null) {
          commentContent = htmlMatch.group(1)!;
          textOutsideComment =
              headlineText.replaceFirst(_htmlCommentPattern, '').trim();

          // Check for [id] inside the comment
          final idInComment = _squareBracketIdPattern.firstMatch(commentContent);
          if (idInComment != null) {
            explicitId = idInComment.group(1);
            // Parse key=value from remaining comment content
            final remainingComment =
                commentContent.replaceFirst(_squareBracketIdPattern, '').trim();
            _parseKeyValuePairs(remainingComment, fields);
          } else {
            // No ID in comment - parse entire comment for key=value pairs
            _parseKeyValuePairs(commentContent, fields);
          }
        }

        // If no ID found in comment, check for [id] outside comment
        if (explicitId == null) {
          final idOutside = _squareBracketIdPattern.firstMatch(textOutsideComment);
          if (idOutside != null) {
            explicitId = idOutside.group(1);
            textOutsideComment =
                textOutsideComment.replaceFirst(_squareBracketIdPattern, '').trim();
          }
        }

        // Parse any key=value pairs from text outside comment (if no comment, this is all text)
        if (htmlMatch == null) {
          // No HTML comment - check for key=value after removing [id]
          _parseKeyValuePairs(textOutsideComment, fields);
          // Clean the headline text by removing key=value pairs
          headlineText = _removeKeyValuePairs(textOutsideComment);
        } else {
          headlineText = textOutsideComment;
        }

        headlines.add((
          ParsedHeadline(
            level: level,
            lineNumber: i + 1, // 1-based
            rawHeadline: fullLine,
            explicitId: explicitId,
            text: headlineText,
            fields: fields,
          ),
          i,
          -1, // Will be filled in later
        ));
      }
    }

    // Calculate end lines
    final result = <(ParsedHeadline, int, int)>[];
    for (var i = 0; i < headlines.length; i++) {
      final (headline, startLine, _) = headlines[i];
      final endLine = i + 1 < headlines.length
          ? headlines[i + 1].$2 - 1
          : lines.length - 1;
      result.add((headline, startLine, endLine));
    }

    return result;
  }

  /// Parses key=value pairs from a string and adds them to the fields map.
  /// Supports: key=value, key="quoted value", key='quoted value'
  static void _parseKeyValuePairs(String text, Map<String, String> fields) {
    for (final match in _keyValuePattern.allMatches(text)) {
      final key = match.group(1)!;
      // Check groups in order: double-quoted, single-quoted, unquoted
      final value = match.group(2) ?? match.group(3) ?? match.group(4) ?? '';
      fields[key] = value;
    }
  }

  /// Removes key=value pairs from text, leaving only the actual headline text.
  static String _removeKeyValuePairs(String text) {
    return text.replaceAll(_keyValuePattern, '').trim();
  }

  /// Extracts text content between headlines.
  static String extractText(
    String content,
    int startLine,
    int endLine,
  ) {
    final lines = content.split('\n');

    // Start from the line after the headline
    final textStartLine = startLine + 1;
    if (textStartLine > endLine || textStartLine >= lines.length) {
      return '';
    }

    final textLines = lines.sublist(textStartLine, endLine + 1);
    return textLines.join('\n').trim();
  }

  /// Generates an ID from headline text.
  ///
  /// Rules:
  /// - If text is a single word, lowercase it
  /// - Otherwise, use parent ID + index
  static String generateId(String text, String? parentId, int index) {
    final trimmed = text.trim();

    // Single word: lowercase it
    if (!trimmed.contains(' ') && trimmed.isNotEmpty) {
      return trimmed.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    }

    // Multiple words or empty: use parent.index pattern
    if (parentId != null && parentId.isNotEmpty) {
      return '$parentId.$index';
    }

    // Fallback: convert to snake_case
    return trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  /// Calculates the maximum hierarchy depth from headlines.
  static int calculateMaxDepth(
      List<(ParsedHeadline, int startLine, int endLine)> headlines) {
    if (headlines.isEmpty) return 0;
    return headlines.map((h) => h.$1.level).reduce((a, b) => a > b ? a : b);
  }
}
