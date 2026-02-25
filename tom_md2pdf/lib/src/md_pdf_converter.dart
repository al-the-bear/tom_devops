import 'dart:io';

import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';
import 'package:path/path.dart' as path;
import 'package:pdf/widgets.dart' as pw;

/// Markdown to PDF converter using htmltopdfwidgets.
///
/// Converts Markdown files directly to PDF format without requiring
/// LaTeX or external tools.
///
/// ## Example
///
/// ```dart
/// final converter = MdPdfConverter('/path/to/docs');
/// final result = await converter.convertAll(outputDir: '/path/to/output');
/// print('Converted ${result.converted.length} files');
/// ```
class MdPdfConverter {
  /// The root directory or file to scan for markdown files.
  final String sourcePath;

  /// Options for the converter.
  final MdPdfConverterOptions options;

  /// Creates a new converter for the given source path.
  MdPdfConverter(this.sourcePath, {MdPdfConverterOptions? options})
    : options = options ?? MdPdfConverterOptions();

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

    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
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

  /// Converts all markdown files in the source path to PDF.
  ///
  /// Returns a [MdPdfConverterResult] with conversion statistics.
  Future<MdPdfConverterResult> convertAll({String? outputDir}) async {
    final files = await findMarkdownFiles();
    final result = MdPdfConverterResult();

    for (final file in files) {
      try {
        final converted = await convertFile(file, outputDir: outputDir);
        result.converted.add(converted);
      } catch (e, st) {
        result.errors.add(
          PdfConversionError(
            sourcePath: file.path,
            message: e.toString(),
            stackTrace: st,
          ),
        );
      }
    }

    return result;
  }

  /// Converts a single markdown file to PDF.
  Future<PdfConvertedFile> convertFile(File file, {String? outputDir}) async {
    final markdown = await file.readAsString();
    final outputDirectory = outputDir ?? path.dirname(file.path);

    // Ensure output directory exists
    final outDir = Directory(outputDirectory);
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }

    // Generate output filename
    final baseName = path.basenameWithoutExtension(file.path);
    final outputPath = path.join(outputDirectory, '$baseName.pdf');

    // Convert markdown to PDF widgets
    final pdfWidgets = await HTMLToPdf().convertMarkdown(
      markdown,
      defaultFontSize: options.fontSize,
      defaultFontFamily: options.fontFamily,
      tagStyle: options.tagStyle,
    );

    // Create PDF document
    final document = pw.Document(
      title: options.title ?? baseName,
      author: options.author,
      creator: 'Tom Build - MdPdfConverter',
    );

    // Add pages with the converted widgets
    document.addPage(
      pw.MultiPage(
        pageFormat: options.pageFormat,
        margin: options.margin,
        build: (context) => pdfWidgets,
        header: options.headerBuilder,
        footer: options.footerBuilder,
      ),
    );

    // Save PDF
    final pdfBytes = await document.save();
    await File(outputPath).writeAsBytes(pdfBytes);

    return PdfConvertedFile(sourcePath: file.path, outputPath: outputPath);
  }

  /// Converts a markdown string to PDF bytes.
  Future<List<int>> convertString(String markdown, {String? title}) async {
    // Convert markdown to PDF widgets
    final pdfWidgets = await HTMLToPdf().convertMarkdown(
      markdown,
      defaultFontSize: options.fontSize,
      defaultFontFamily: options.fontFamily,
      tagStyle: options.tagStyle,
    );

    // Create PDF document
    final document = pw.Document(
      title: title ?? options.title,
      author: options.author,
      creator: 'Tom Build - MdPdfConverter',
    );

    // Add pages with the converted widgets
    document.addPage(
      pw.MultiPage(
        pageFormat: options.pageFormat,
        margin: options.margin,
        build: (context) => pdfWidgets,
        header: options.headerBuilder,
        footer: options.footerBuilder,
      ),
    );

    return document.save();
  }
}

/// Options for the markdown to PDF converter.
class MdPdfConverterOptions {
  /// Document title.
  final String? title;

  /// Document author.
  final String? author;

  /// Page format (default: A4).
  final PdfPageFormat pageFormat;

  /// Page margins.
  final pw.EdgeInsets margin;

  /// Default font size in points (default: 12).
  final double fontSize;

  /// Default font family (default: Roboto).
  final String fontFamily;

  /// Custom HTML tag styling (paragraph margins, heading styles, etc.).
  final HtmlTagStyle tagStyle;

  /// Patterns of files/directories to exclude.
  final List<String> excludePatterns;

  /// Optional header builder for each page.
  final pw.Widget Function(pw.Context)? headerBuilder;

  /// Optional footer builder for each page.
  final pw.Widget Function(pw.Context)? footerBuilder;

  /// Creates converter options.
  MdPdfConverterOptions({
    this.title,
    this.author,
    this.pageFormat = PdfPageFormat.a4,
    this.margin = const pw.EdgeInsets.all(72), // 1 inch = 72 points
    this.fontSize = 12.0,
    this.fontFamily = 'Roboto',
    this.tagStyle = const HtmlTagStyle(),
    this.excludePatterns = const ['node_modules', '.git', 'build'],
    this.headerBuilder,
    this.footerBuilder,
  });
}

/// Result of a conversion operation.
class MdPdfConverterResult {
  /// Successfully converted files.
  final List<PdfConvertedFile> converted = [];

  /// Errors encountered during conversion.
  final List<PdfConversionError> errors = [];

  /// Whether all conversions succeeded.
  bool get isSuccess => errors.isEmpty;
}

/// Information about a converted file.
class PdfConvertedFile {
  /// Path to the source markdown file.
  final String sourcePath;

  /// Path to the output PDF file.
  final String outputPath;

  /// Creates a converted file record.
  PdfConvertedFile({required this.sourcePath, required this.outputPath});
}

/// Error during conversion.
class PdfConversionError {
  /// Path to the source file that failed.
  final String sourcePath;

  /// Error message.
  final String message;

  /// Stack trace if available.
  final StackTrace? stackTrace;

  /// Creates a conversion error.
  PdfConversionError({
    required this.sourcePath,
    required this.message,
    this.stackTrace,
  });

  @override
  String toString() => '$sourcePath: $message';
}
