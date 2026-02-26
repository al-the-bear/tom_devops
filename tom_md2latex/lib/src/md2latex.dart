import 'dart:io';

import 'md_latex_converter.dart';

/// Static convenience API for Markdown to LaTeX conversion.
///
/// Provides simple one-call static methods for common conversion tasks,
/// wrapping [MdLatexConverter] for script-friendly usage.
///
/// ## Example
///
/// ```dart
/// // Convert a single file
/// final result = await Md2Latex.convertFile(
///   inputPath: 'doc.md',
///   outputPath: 'doc.tex',
/// );
///
/// // Convert a markdown string to LaTeX
/// final latex = Md2Latex.convertString(markdown: '# Hello\nWorld');
///
/// // Convert all markdown files in a directory
/// final result = await Md2Latex.convertDirectory(
///   inputDir: 'docs/',
///   outputDir: 'output/',
/// );
/// ```
class Md2Latex {
  Md2Latex._();

  /// Converts a markdown string to a LaTeX string.
  ///
  /// Returns the LaTeX output as a string. By default generates a full
  /// document with preamble; set [generatePreamble] to `false` for a
  /// fragment.
  static String convertString({
    required String markdown,
    String documentClass = 'article',
    String? author,
    bool generatePreamble = true,
    bool generateToc = false,
    int tocDepth = 3,
  }) {
    final converter = MdLatexConverter(
      '',
      options: MdLatexConverterOptions(
        documentClass: documentClass,
        author: author,
        generatePreamble: generatePreamble,
        generateToc: generateToc,
        tocDepth: tocDepth,
      ),
    );
    return converter.convert(markdown);
  }

  /// Converts a single markdown file and writes the LaTeX output.
  ///
  /// If [outputPath] is not given, the output file is written to the same
  /// directory as the input with a `.tex` extension.
  ///
  /// Returns the [ConvertedFile] with source and output paths.
  static Future<ConvertedFile> convertFile({
    required String inputPath,
    String? outputPath,
    String documentClass = 'article',
    String? author,
    bool generatePreamble = true,
    bool generateToc = true,
    int tocDepth = 3,
  }) async {
    final file = File(inputPath);
    if (!file.existsSync()) {
      throw ArgumentError('File does not exist: $inputPath');
    }

    final converter = MdLatexConverter(
      inputPath,
      options: MdLatexConverterOptions(
        documentClass: documentClass,
        author: author,
        generatePreamble: generatePreamble,
        generateToc: generateToc,
        tocDepth: tocDepth,
      ),
    );

    final outPath = outputPath ??
        inputPath.replaceAll(RegExp(r'\.md$'), '.tex');

    final outDir = File(outPath).parent.path;
    return converter.convertFile(file, outputDir: outDir);
  }

  /// Reads a markdown file and returns the LaTeX string without writing.
  ///
  /// Useful for scripts that want to process the LaTeX output further
  /// before writing.
  static Future<String> convertFileToString({
    required String inputPath,
    String documentClass = 'article',
    String? author,
    bool generatePreamble = true,
    bool generateToc = false,
    int tocDepth = 3,
  }) async {
    final file = File(inputPath);
    if (!file.existsSync()) {
      throw ArgumentError('File does not exist: $inputPath');
    }

    final content = await file.readAsString();
    return convertString(
      markdown: content,
      documentClass: documentClass,
      author: author,
      generatePreamble: generatePreamble,
      generateToc: generateToc,
      tocDepth: tocDepth,
    );
  }

  /// Synchronously reads a markdown file and returns the LaTeX string.
  static String convertFileToStringSync({
    required String inputPath,
    String documentClass = 'article',
    String? author,
    bool generatePreamble = true,
    bool generateToc = false,
    int tocDepth = 3,
  }) {
    final file = File(inputPath);
    if (!file.existsSync()) {
      throw ArgumentError('File does not exist: $inputPath');
    }

    final content = file.readAsStringSync();
    return convertString(
      markdown: content,
      documentClass: documentClass,
      author: author,
      generatePreamble: generatePreamble,
      generateToc: generateToc,
      tocDepth: tocDepth,
    );
  }

  /// Converts all markdown files in [inputDir] and writes LaTeX output
  /// to [outputDir].
  ///
  /// Returns a [MdLatexConverterResult] with conversion statistics.
  static Future<MdLatexConverterResult> convertDirectory({
    required String inputDir,
    required String outputDir,
    String documentClass = 'article',
    String? author,
    bool generatePreamble = true,
    bool generateToc = true,
    int tocDepth = 3,
    List<String> excludePatterns = const ['.git', 'node_modules', '.dart_tool'],
  }) async {
    final converter = MdLatexConverter(
      inputDir,
      options: MdLatexConverterOptions(
        documentClass: documentClass,
        author: author,
        generatePreamble: generatePreamble,
        generateToc: generateToc,
        tocDepth: tocDepth,
        excludePatterns: excludePatterns,
      ),
    );
    return converter.convertAll(outputDir: outputDir);
  }

  /// Parses a markdown string and returns the structured elements.
  ///
  /// Useful for inspecting the parsed structure before conversion.
  static ParsedMarkdown parse(
    String markdown, {
    MarkdownParserOptions options = const MarkdownParserOptions(),
  }) {
    return MarkdownParser(markdown, options: options).parse();
  }
}
