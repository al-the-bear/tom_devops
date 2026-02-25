import 'dart:io';

import 'package:path/path.dart' as path;

import 'latex_macros.dart';
import 'markdown_parser.dart';

export 'latex_macros.dart';
export 'markdown_parser.dart';

/// Markdown to LaTeX converter.
///
/// Converts Markdown files to LaTeX format with support for:
/// - Headings (with proper section hierarchy)
/// - Code blocks (with syntax highlighting via listings)
/// - Tables (with booktabs)
/// - ASCII hierarchy diagrams (preserved in verbatim)
/// - Links and references
/// - Lists (ordered and unordered)
/// - Inline formatting (bold, italic, code)
///
/// ## Example
///
/// ```dart
/// final converter = MdLatexConverter('/path/to/docs');
/// final result = await converter.convertAll(outputDir: '/path/to/output');
/// print('Converted ${result.converted.length} files');
/// ```
class MdLatexConverter {
  /// The root directory to scan for markdown files.
  final String sourcePath;

  /// Options for the converter.
  final MdLatexConverterOptions options;

  /// Creates a new converter for the given source path.
  MdLatexConverter(this.sourcePath, {MdLatexConverterOptions? options})
      : options = options ?? MdLatexConverterOptions();

  /// Finds all `.md` files in the source path.
  Future<List<File>> findMarkdownFiles() async {
    final files = <File>[];
    final source = FileSystemEntity.isDirectorySync(sourcePath)
        ? Directory(sourcePath)
        : null;

    if (source == null) {
      // Single file mode
      final file = File(sourcePath);
      if (file.existsSync() && sourcePath.endsWith('.md')) {
        files.add(file);
      }
      return files;
    }

    await for (final entity in source.list(recursive: true, followLinks: false)) {
      if (entity is File && entity.path.endsWith('.md')) {
        if (_shouldExclude(entity.path)) continue;
        files.add(entity);
      }
    }

    return files;
  }

  bool _shouldExclude(String filePath) {
    for (final pattern in options.excludePatterns) {
      if (filePath.contains(pattern)) return true;
    }
    return false;
  }

  /// Converts all markdown files in the source path.
  ///
  /// Returns a [MdLatexConverterResult] with conversion statistics.
  Future<MdLatexConverterResult> convertAll({
    required String outputDir,
  }) async {
    final files = await findMarkdownFiles();
    final result = MdLatexConverterResult();
    final outDir = Directory(outputDir);

    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }

    for (final file in files) {
      try {
        final converted = await convertFile(file, outputDir: outputDir);
        result.converted.add(converted);
      } catch (e, st) {
        result.errors.add(ConversionError(
          sourcePath: file.path,
          message: e.toString(),
          stackTrace: st,
        ));
      }
    }

    return result;
  }

  /// Converts a single markdown file to LaTeX.
  Future<ConvertedFile> convertFile(
    File file, {
    required String outputDir,
  }) async {
    final content = await file.readAsString();
    final parser = MarkdownParser(content, options: options.parserOptions);
    final parsed = parser.parse();

    final latex = _generateLatex(parsed);

    // Calculate output path
    String outputPath;
    if (FileSystemEntity.isFileSync(sourcePath)) {
      // Single file mode - use the filename directly
      final fileName = path.basename(file.path).replaceAll('.md', '.tex');
      outputPath = path.join(outputDir, fileName);
    } else {
      // Directory mode - preserve relative path structure
      final relativePath = path.relative(file.path, from: sourcePath);
      outputPath = path.join(
        outputDir,
        relativePath.replaceAll('.md', '.tex'),
      );
    }

    // Ensure output directory exists
    final outputFile = File(outputPath);
    await outputFile.parent.create(recursive: true);
    await outputFile.writeAsString(latex);

    return ConvertedFile(
      sourcePath: file.path,
      outputPath: outputPath,
      parsed: parsed,
    );
  }

  /// Converts markdown content to LaTeX string.
  String convert(String markdownContent) {
    final parser = MarkdownParser(markdownContent, options: options.parserOptions);
    final parsed = parser.parse();
    return _generateLatex(parsed);
  }

  /// Counter for generating unique heading labels.
  int _headingCounter = 0;

  String _generateLatex(ParsedMarkdown parsed) {
    final buffer = StringBuffer();
    _headingCounter = 0; // Reset counter for each document

    if (options.generatePreamble) {
      // Use frontmatter values if available, otherwise fall back to options
      final title = parsed.title;
      final author = parsed.author ?? options.author;
      final date = parsed.date;
      // Use frontmatter tocDepth if set, otherwise use options
      final tocDepth = parsed.tocDepth ?? options.tocDepth;
      
      buffer.writeln(LatexMacros.preamble(
        documentClass: options.documentClass,
        title: title,
        author: author,
        date: date,
        tocDepth: tocDepth,
      ));
      buffer.writeln(LatexMacros.beginDocument());
      if (title != null) {
        buffer.writeln(LatexMacros.makeTitle());
      }
      // Use frontmatter toc setting, otherwise fall back to options.generateToc
      final shouldGenerateToc = parsed.generateToc || options.generateToc;
      if (shouldGenerateToc) {
        buffer.writeln('\\tableofcontents');
        buffer.writeln('\\newpage');
        buffer.writeln();
      }
    }

    for (final element in parsed.elements) {
      buffer.writeln(_elementToLatex(element));
    }

    if (options.generatePreamble) {
      buffer.writeln(LatexMacros.endDocument());
    }

    return buffer.toString();
  }

  String _elementToLatex(MarkdownElement element) {
    switch (element) {
      case HeadingElement():
        _headingCounter++;
        return LatexMacros.heading(
          element.text,
          element.level,
          label: 'sec:$_headingCounter',
          numbered: options.generateToc,
        );
      case ParagraphElement():
        return LatexMacros.paragraph(_processInlineFormatting(element.text));
      case CodeBlockElement():
        if (element.isAsciiDiagram) {
          return LatexMacros.asciiDiagram(element.code);
        }
        return LatexMacros.codeBlock(element.code, language: element.language);
      case InlineCodeElement():
        return LatexMacros.inlineCode(element.code);
      case TableElement():
        return LatexMacros.table(element.headers, element.rows, element.alignments);
      case UnorderedListElement():
        return LatexMacros.unorderedList(
          element.items.map((i) => _processInlineFormatting(i)).toList(),
        );
      case OrderedListElement():
        return LatexMacros.orderedList(
          element.items.map((i) => _processInlineFormatting(i)).toList(),
        );
      case BlockQuoteElement():
        return LatexMacros.blockQuote(_processInlineFormatting(element.text));
      case HorizontalRuleElement():
        return LatexMacros.horizontalRule();
      case LinkElement():
        return LatexMacros.link(element.text, element.url);
      case ImageElement():
        return LatexMacros.image(element.altText, element.url);
      case RawTextElement():
        return _processInlineFormatting(element.text);
    }
  }

  String _processInlineFormatting(String text) {
    var result = text;

    // Step 0: Unescape markdown-escaped angle brackets \< and \>
    result = result.replaceAll(r'\<', '<');
    result = result.replaceAll(r'\>', '>');

    // Step 1: Extract and preserve inline code (backticks) BEFORE any processing
    // Replace with placeholders
    final codeBlocks = <String>[];
    result = result.replaceAllMapped(
      RegExp(r'`([^`]+)`'),
      (m) {
        final code = m.group(1) ?? '';
        codeBlocks.add(code);
        return '\x00CODE${codeBlocks.length - 1}\x00';
      },
    );

    // Step 2: Preserve LaTeX commands like \newpage
    final latexCommands = <String>[];
    result = result.replaceAllMapped(
      RegExp(r'\\(newpage|clearpage|pagebreak|\\)'),
      (m) {
        latexCommands.add('\\${m.group(1)}');
        return '\x00LATEX${latexCommands.length - 1}\x00';
      },
    );

    // Step 3: Process bold BEFORE escaping: **text** or __text__
    // Extract bold content and process it
    final boldBlocks = <String>[];
    result = result.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*|__(.+?)__'),
      (m) {
        final content = m.group(1) ?? m.group(2) ?? '';
        boldBlocks.add(content);
        return '\x00BOLD${boldBlocks.length - 1}\x00';
      },
    );

    // Step 4: Process italic BEFORE escaping: *text* or _text_
    final italicBlocks = <String>[];
    result = result.replaceAllMapped(
      RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)|(?<!_)_([^_]+)_(?!_)'),
      (m) {
        final content = m.group(1) ?? m.group(2) ?? '';
        italicBlocks.add(content);
        return '\x00ITALIC${italicBlocks.length - 1}\x00';
      },
    );

    // Step 4.5: Process links BEFORE escaping: [text](url)
    final linkBlocks = <(String, String)>[];
    result = result.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (m) {
        final text = m.group(1) ?? '';
        final url = m.group(2) ?? '';
        linkBlocks.add((text, url));
        return '\x00LINK${linkBlocks.length - 1}\x00';
      },
    );

    // Step 5: Escape LaTeX special characters in remaining text
    result = LatexMacros.escapeText(result);

    // Step 6: Restore bold with proper LaTeX formatting
    result = result.replaceAllMapped(
      RegExp(r'\x00BOLD(\d+)\x00'),
      (m) {
        final idx = int.parse(m.group(1)!);
        return LatexMacros.bold(LatexMacros.escapeText(boldBlocks[idx]));
      },
    );

    // Step 7: Restore italic with proper LaTeX formatting
    result = result.replaceAllMapped(
      RegExp(r'\x00ITALIC(\d+)\x00'),
      (m) {
        final idx = int.parse(m.group(1)!);
        return LatexMacros.italic(LatexMacros.escapeText(italicBlocks[idx]));
      },
    );

    // Step 8: Restore inline code with proper LaTeX formatting
    result = result.replaceAllMapped(
      RegExp(r'\x00CODE(\d+)\x00'),
      (m) {
        final idx = int.parse(m.group(1)!);
        return LatexMacros.inlineCode(codeBlocks[idx]);
      },
    );

    // Step 9: Restore LaTeX commands
    result = result.replaceAllMapped(
      RegExp(r'\x00LATEX(\d+)\x00'),
      (m) {
        final idx = int.parse(m.group(1)!);
        return latexCommands[idx];
      },
    );

    // Step 10: Restore links with proper LaTeX formatting
    result = result.replaceAllMapped(
      RegExp(r'\x00LINK(\d+)\x00'),
      (m) {
        final idx = int.parse(m.group(1)!);
        final (text, url) = linkBlocks[idx];
        return LatexMacros.link(text, url);
      },
    );

    return result;
  }
}

/// Options for the Markdown to LaTeX converter.
class MdLatexConverterOptions {
  /// Patterns to exclude from conversion.
  final List<String> excludePatterns;

  /// Whether to generate a full LaTeX document with preamble.
  final bool generatePreamble;

  /// The document class to use (article, report, book).
  final String documentClass;

  /// The author for the document metadata.
  final String? author;

  /// Whether to generate table of contents (can be overridden by frontmatter).
  final bool generateToc;

  /// Depth of table of contents (1-5). 1=sections, 2=subsections, etc.
  /// Can be overridden by frontmatter.
  final int tocDepth;

  /// Options for the markdown parser.
  final MarkdownParserOptions parserOptions;

  const MdLatexConverterOptions({
    this.excludePatterns = const ['.git', 'node_modules', '.dart_tool'],
    this.generatePreamble = true,
    this.documentClass = 'article',
    this.author,
    this.generateToc = true,
    this.tocDepth = 3,
    this.parserOptions = const MarkdownParserOptions(),
  });
}

/// Result of a conversion operation.
class MdLatexConverterResult {
  /// Successfully converted files.
  final List<ConvertedFile> converted = [];

  /// Errors encountered during conversion.
  final List<ConversionError> errors = [];

  /// Whether the conversion was successful (no errors).
  bool get isSuccess => errors.isEmpty;

  /// Total number of files processed.
  int get totalProcessed => converted.length + errors.length;
}

/// Information about a successfully converted file.
class ConvertedFile {
  /// Path to the source markdown file.
  final String sourcePath;

  /// Path to the generated LaTeX file.
  final String outputPath;

  /// The parsed markdown structure.
  final ParsedMarkdown parsed;

  const ConvertedFile({
    required this.sourcePath,
    required this.outputPath,
    required this.parsed,
  });
}

/// Error information for a failed conversion.
class ConversionError {
  /// Path to the source file that failed.
  final String sourcePath;

  /// Error message.
  final String message;

  /// Stack trace if available.
  final StackTrace? stackTrace;

  const ConversionError({
    required this.sourcePath,
    required this.message,
    this.stackTrace,
  });

  @override
  String toString() => 'ConversionError: $sourcePath - $message';
}
