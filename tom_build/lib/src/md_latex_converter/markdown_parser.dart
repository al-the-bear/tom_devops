/// Options for the markdown parser.
class MarkdownParserOptions {
  /// Whether to detect ASCII diagrams in code blocks.
  final bool detectAsciiDiagrams;

  /// Patterns that indicate an ASCII diagram (box drawing, etc.).
  final List<String> asciiDiagramPatterns;

  const MarkdownParserOptions({
    this.detectAsciiDiagrams = true,
    this.asciiDiagramPatterns = const [
      '├', '└', '│', '─', '┬', '┴', '┼', '┤', '┌', '┐', '┘', '┐',
      '+--', '|--', '\\--',
      '+-', '|-',
      '/---', '\\---',
      '[', ']', // Common in hierarchy diagrams
    ],
  });
}

/// Markdown parser that extracts structured elements.
class MarkdownParser {
  final String content;
  final MarkdownParserOptions options;

  MarkdownParser(this.content, {this.options = const MarkdownParserOptions()});

  /// Parses the markdown content into a structured representation.
  ParsedMarkdown parse() {
    // Strip HTML comments (including markdown-lint directives)
    final cleanedContent = content.replaceAll(
      RegExp(r'<!--[\s\S]*?-->', multiLine: true),
      '',
    );
    
    final elements = <MarkdownElement>[];
    final lines = cleanedContent.split('\n');
    String? title;
    String? author;
    String? date;
    bool generateToc = false;
    int? tocDepth;

    var i = 0;

    // Parse YAML frontmatter if present
    if (lines.isNotEmpty && lines[0].trim() == '---') {
      i = 1;
      while (i < lines.length && lines[i].trim() != '---') {
        final line = lines[i];
        final match = RegExp(r'^(\w+):\s*"?([^"]*)"?\s*$').firstMatch(line);
        if (match != null) {
          final key = match.group(1)!.toLowerCase();
          final value = match.group(2)!;
          switch (key) {
            case 'title':
              title = value;
              break;
            case 'author':
              author = value;
              break;
            case 'date':
              date = value;
              break;
            case 'toc':
              generateToc = value.toLowerCase() == 'true';
              break;
            case 'toc-depth':
            case 'tocdepth':
              tocDepth = int.tryParse(value);
              break;
          }
        }
        i++;
      }
      i++; // Skip closing ---
    }

    while (i < lines.length) {
      final line = lines[i];

      // Skip empty lines
      if (line.trim().isEmpty) {
        i++;
        continue;
      }

      // Heading
      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final text = headingMatch.group(2)!.trim();
        elements.add(HeadingElement(text, level));
        if (level == 1 && title == null) {
          title = text;
        }
        i++;
        continue;
      }

      // Fenced code block
      if (line.trimLeft().startsWith('```')) {
        final result = _parseCodeBlock(lines, i);
        elements.add(result.element);
        i = result.nextIndex;
        continue;
      }

      // Table
      if (_isTableStart(lines, i)) {
        final result = _parseTable(lines, i);
        elements.add(result.element);
        i = result.nextIndex;
        continue;
      }

      // Block quote
      if (line.trimLeft().startsWith('>')) {
        final result = _parseBlockQuote(lines, i);
        elements.add(result.element);
        i = result.nextIndex;
        continue;
      }

      // Unordered list
      if (RegExp(r'^\s*[-*+]\s+').hasMatch(line)) {
        final result = _parseUnorderedList(lines, i);
        elements.add(result.element);
        i = result.nextIndex;
        continue;
      }

      // Ordered list
      if (RegExp(r'^\s*\d+\.\s+').hasMatch(line)) {
        final result = _parseOrderedList(lines, i);
        elements.add(result.element);
        i = result.nextIndex;
        continue;
      }

      // Horizontal rule
      if (RegExp(r'^[-*_]{3,}\s*$').hasMatch(line.trim())) {
        elements.add(HorizontalRuleElement());
        i++;
        continue;
      }

      // Image (standalone line)
      final imageMatch = RegExp(r'^!\[([^\]]*)\]\(([^)]+)\)$').firstMatch(line.trim());
      if (imageMatch != null) {
        elements.add(ImageElement(
          altText: imageMatch.group(1) ?? '',
          url: imageMatch.group(2) ?? '',
        ));
        i++;
        continue;
      }

      // Paragraph (collect consecutive non-special lines)
      final result = _parseParagraph(lines, i);
      elements.add(result.element);
      i = result.nextIndex;
    }

    return ParsedMarkdown(
      title: title,
      author: author,
      date: date,
      generateToc: generateToc,
      tocDepth: tocDepth,
      elements: elements,
    );
  }

  _ParseResult<CodeBlockElement> _parseCodeBlock(List<String> lines, int startIndex) {
    final firstLine = lines[startIndex].trimLeft();
    final language = firstLine.substring(3).trim();
    final codeLines = <String>[];

    var i = startIndex + 1;
    while (i < lines.length) {
      final line = lines[i];
      if (line.trimLeft().startsWith('```')) {
        i++;
        break;
      }
      codeLines.add(line);
      i++;
    }

    final code = codeLines.join('\n');
    final isAsciiDiagram = options.detectAsciiDiagrams && _isAsciiDiagram(code);

    return _ParseResult(
      element: CodeBlockElement(
        code: code,
        language: language.isEmpty ? null : language,
        isAsciiDiagram: isAsciiDiagram,
      ),
      nextIndex: i,
    );
  }

  bool _isAsciiDiagram(String code) {
    // Only match if the code has Unicode box-drawing characters
    // or very specific tree-like patterns (not just any code with | or -)
    final hasBoxDrawingChars = RegExp(r'[│├└┌┐┘┬┴┼┤─]').hasMatch(code);
    if (hasBoxDrawingChars) {
      return true;
    }
    
    // Check for custom patterns
    for (final pattern in options.asciiDiagramPatterns) {
      if (code.contains(pattern)) {
        return true;
      }
    }
    
    // Check for explicit tree structure with multiple lines starting with | or +
    // Must have at least 3 lines that look like tree branches
    final lines = code.split('\n');
    int treeLikeLines = 0;
    for (final line in lines) {
      if (RegExp(r'^\s*[\|+][-─]+').hasMatch(line) || 
          RegExp(r'^\s*[\|+]\s+').hasMatch(line) ||
          RegExp(r'^\s*[\\`][-─]+').hasMatch(line)) {
        treeLikeLines++;
      }
    }
    return treeLikeLines >= 3;
  }

  bool _isTableStart(List<String> lines, int index) {
    if (index + 1 >= lines.length) return false;
    final line = lines[index];
    final nextLine = lines[index + 1];

    // A table starts with a line containing |, followed by a separator line
    if (!line.contains('|')) return false;
    return RegExp(r'^[\s|:-]+$').hasMatch(nextLine);
  }

  _ParseResult<TableElement> _parseTable(List<String> lines, int startIndex) {
    // Parse header row
    final headerLine = lines[startIndex];
    final headers = _parseTableRow(headerLine);

    // Parse alignment row
    final alignmentLine = lines[startIndex + 1];
    final alignments = _parseAlignments(alignmentLine);

    // Parse data rows
    final rows = <List<String>>[];
    var i = startIndex + 2;
    while (i < lines.length && lines[i].contains('|')) {
      rows.add(_parseTableRow(lines[i]));
      i++;
    }

    return _ParseResult(
      element: TableElement(
        headers: headers,
        rows: rows,
        alignments: alignments,
      ),
      nextIndex: i,
    );
  }

  List<String> _parseTableRow(String line) {
    return line
        .split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty)
        .toList();
  }

  List<String> _parseAlignments(String line) {
    return line.split('|')
        .map((cell) => cell.trim())
        .where((cell) => cell.isNotEmpty && RegExp(r'^:?-+:?$').hasMatch(cell))
        .map((cell) {
          if (cell.startsWith(':') && cell.endsWith(':')) {
            return 'center';
          } else if (cell.endsWith(':')) {
            return 'right';
          } else {
            return 'left';
          }
        }).toList();
  }

  _ParseResult<BlockQuoteElement> _parseBlockQuote(List<String> lines, int startIndex) {
    final quoteLines = <String>[];
    var i = startIndex;

    while (i < lines.length && lines[i].trimLeft().startsWith('>')) {
      final line = lines[i].trimLeft();
      quoteLines.add(line.substring(1).trimLeft()); // Remove > and leading space
      i++;
    }

    return _ParseResult(
      element: BlockQuoteElement(text: quoteLines.join('\n')),
      nextIndex: i,
    );
  }

  _ParseResult<UnorderedListElement> _parseUnorderedList(List<String> lines, int startIndex) {
    final items = <String>[];
    var i = startIndex;

    while (i < lines.length) {
      final match = RegExp(r'^\s*[-*+]\s+(.+)$').firstMatch(lines[i]);
      if (match != null) {
        items.add(match.group(1)!);
        i++;
      } else if (lines[i].trim().isEmpty) {
        // Allow blank lines within list
        i++;
      } else {
        break;
      }
    }

    return _ParseResult(
      element: UnorderedListElement(items: items),
      nextIndex: i,
    );
  }

  _ParseResult<OrderedListElement> _parseOrderedList(List<String> lines, int startIndex) {
    final items = <String>[];
    var i = startIndex;

    while (i < lines.length) {
      final match = RegExp(r'^\s*\d+\.\s+(.+)$').firstMatch(lines[i]);
      if (match != null) {
        items.add(match.group(1)!);
        i++;
      } else if (lines[i].trim().isEmpty) {
        i++;
      } else {
        break;
      }
    }

    return _ParseResult(
      element: OrderedListElement(items: items),
      nextIndex: i,
    );
  }

  _ParseResult<ParagraphElement> _parseParagraph(List<String> lines, int startIndex) {
    final paragraphLines = <String>[];
    var i = startIndex;

    while (i < lines.length) {
      final line = lines[i];

      // Stop on special lines
      if (line.trim().isEmpty ||
          line.trimLeft().startsWith('#') ||
          line.trimLeft().startsWith('```') ||
          line.trimLeft().startsWith('>') ||
          RegExp(r'^\s*[-*+]\s+').hasMatch(line) ||
          RegExp(r'^\s*\d+\.\s+').hasMatch(line) ||
          RegExp(r'^[-*_]{3,}\s*$').hasMatch(line.trim()) ||
          _isTableStart(lines, i)) {
        break;
      }

      paragraphLines.add(line);
      i++;
    }

    return _ParseResult(
      element: ParagraphElement(text: paragraphLines.join(' ')),
      nextIndex: i,
    );
  }
}

/// Result of parsing a section of markdown.
class _ParseResult<T extends MarkdownElement> {
  final T element;
  final int nextIndex;

  const _ParseResult({required this.element, required this.nextIndex});
}

/// Parsed markdown document.
class ParsedMarkdown {
  /// The document title (from frontmatter or first h1 heading).
  final String? title;

  /// Document author (from frontmatter).
  final String? author;

  /// Document date (from frontmatter).
  final String? date;

  /// Whether to generate table of contents (from frontmatter).
  final bool generateToc;

  /// Depth of table of contents (1-5, from frontmatter).
  final int? tocDepth;

  /// All parsed elements.
  final List<MarkdownElement> elements;

  const ParsedMarkdown({
    this.title,
    this.author,
    this.date,
    this.generateToc = false,
    this.tocDepth,
    required this.elements,
  });
}

/// Base class for markdown elements.
sealed class MarkdownElement {}

/// A heading element (h1-h6).
class HeadingElement extends MarkdownElement {
  final String text;
  final int level;

  HeadingElement(this.text, this.level);
}

/// A paragraph of text.
class ParagraphElement extends MarkdownElement {
  final String text;

  ParagraphElement({required this.text});
}

/// A fenced code block.
class CodeBlockElement extends MarkdownElement {
  final String code;
  final String? language;
  final bool isAsciiDiagram;

  CodeBlockElement({
    required this.code,
    this.language,
    this.isAsciiDiagram = false,
  });
}

/// Inline code span.
class InlineCodeElement extends MarkdownElement {
  final String code;

  InlineCodeElement({required this.code});
}

/// A table element.
class TableElement extends MarkdownElement {
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> alignments;

  TableElement({
    required this.headers,
    required this.rows,
    required this.alignments,
  });
}

/// An unordered (bullet) list.
class UnorderedListElement extends MarkdownElement {
  final List<String> items;

  UnorderedListElement({required this.items});
}

/// An ordered (numbered) list.
class OrderedListElement extends MarkdownElement {
  final List<String> items;

  OrderedListElement({required this.items});
}

/// A block quote.
class BlockQuoteElement extends MarkdownElement {
  final String text;

  BlockQuoteElement({required this.text});
}

/// A horizontal rule.
class HorizontalRuleElement extends MarkdownElement {}

/// A hyperlink.
class LinkElement extends MarkdownElement {
  final String text;
  final String url;

  LinkElement({required this.text, required this.url});
}

/// An image.
class ImageElement extends MarkdownElement {
  final String altText;
  final String url;

  ImageElement({required this.altText, required this.url});
}

/// Raw text that needs inline formatting processing.
class RawTextElement extends MarkdownElement {
  final String text;

  RawTextElement({required this.text});
}
