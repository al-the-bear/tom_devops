import 'dart:io';

import 'md_pdf_converter.dart';
import 'pdf_options_wrapper.dart';

/// Static convenience API for Markdown to PDF conversion.
///
/// Provides simple one-call static methods for common conversion tasks,
/// wrapping [MdPdfConverter] for script-friendly usage. All options use
/// simple types (strings, numbers) so they are easily bridgeable to D4rt.
///
/// ## Example
///
/// ```dart
/// // Convert a single file
/// await Md2Pdf.convertFile(
///   inputPath: 'doc.md',
///   outputPath: 'doc.pdf',
/// );
///
/// // Convert a markdown string to PDF bytes
/// final bytes = await Md2Pdf.convertString(markdown: '# Hello\nWorld');
/// File('output.pdf').writeAsBytesSync(bytes);
///
/// // Convert all markdown files in a directory
/// final result = await Md2Pdf.convertDirectory(
///   inputDir: 'docs/',
///   outputDir: 'output/',
/// );
/// ```
class Md2Pdf {
  Md2Pdf._();

  /// Converts a markdown string to PDF bytes.
  ///
  /// Returns the PDF document as a byte list. Write to a file with
  /// `File(path).writeAsBytesSync(bytes)`.
  static Future<List<int>> convertString({
    required String markdown,
    String? title,
    String? author,
    String pageFormat = 'a4',
    double fontSize = 12.0,
    String fontFamily = 'Roboto',
    PageMargins margins = const PageMargins.all(72),
  }) async {
    final options = PdfConverterOptionsWrapper(
      title: title,
      author: author,
      pageFormat: pageFormat,
      fontSize: fontSize,
      fontFamily: fontFamily,
      margins: margins,
    ).toOptions();

    final converter = MdPdfConverter('', options: options);
    return converter.convertString(markdown, title: title);
  }

  /// Converts a single markdown file to PDF.
  ///
  /// If [outputPath] is not given, the output file is placed next to the
  /// input file with a `.pdf` extension.
  ///
  /// Returns the [PdfConvertedFile] with source and output paths.
  static Future<PdfConvertedFile> convertFile({
    required String inputPath,
    String? outputPath,
    String? title,
    String? author,
    String pageFormat = 'a4',
    double fontSize = 12.0,
    String fontFamily = 'Roboto',
    PageMargins margins = const PageMargins.all(72),
  }) async {
    final file = File(inputPath);
    if (!file.existsSync()) {
      throw ArgumentError('File does not exist: $inputPath');
    }

    final options = PdfConverterOptionsWrapper(
      title: title,
      author: author,
      pageFormat: pageFormat,
      fontSize: fontSize,
      fontFamily: fontFamily,
      margins: margins,
    ).toOptions();

    final converter = MdPdfConverter(inputPath, options: options);

    final outPath =
        outputPath ?? inputPath.replaceAll(RegExp(r'\.md$'), '.pdf');
    final outDir = File(outPath).parent.path;

    return converter.convertFile(file, outputDir: outDir);
  }

  /// Reads a markdown file and returns the PDF bytes without writing.
  ///
  /// Useful for scripts that want to stream or post-process the PDF bytes
  /// before writing to disk.
  static Future<List<int>> convertFileToBytes({
    required String inputPath,
    String? title,
    String? author,
    String pageFormat = 'a4',
    double fontSize = 12.0,
    String fontFamily = 'Roboto',
    PageMargins margins = const PageMargins.all(72),
  }) async {
    final file = File(inputPath);
    if (!file.existsSync()) {
      throw ArgumentError('File does not exist: $inputPath');
    }

    final content = await file.readAsString();
    return convertString(
      markdown: content,
      title: title,
      author: author,
      pageFormat: pageFormat,
      fontSize: fontSize,
      fontFamily: fontFamily,
      margins: margins,
    );
  }

  /// Converts all markdown files in [inputDir] to PDF, writing output
  /// to [outputDir].
  ///
  /// Returns a [MdPdfConverterResult] with conversion statistics.
  static Future<MdPdfConverterResult> convertDirectory({
    required String inputDir,
    String? outputDir,
    String? title,
    String? author,
    String pageFormat = 'a4',
    double fontSize = 12.0,
    String fontFamily = 'Roboto',
    PageMargins margins = const PageMargins.all(72),
    List<String> excludePatterns = const ['node_modules', '.git', 'build'],
  }) async {
    final options = PdfConverterOptionsWrapper(
      title: title,
      author: author,
      pageFormat: pageFormat,
      fontSize: fontSize,
      fontFamily: fontFamily,
      margins: margins,
      excludePatterns: excludePatterns,
    ).toOptions();

    final converter = MdPdfConverter(inputDir, options: options);
    return converter.convertAll(outputDir: outputDir);
  }

  /// Converts a single markdown file to PDF and writes it to [outputPath].
  ///
  /// This is a simpler variant of [convertFile] that just writes the file
  /// and returns `true` on success. Throws on failure.
  static Future<bool> convertFileAndSave({
    required String inputPath,
    required String outputPath,
    String? title,
    String? author,
    String pageFormat = 'a4',
    double fontSize = 12.0,
    String fontFamily = 'Roboto',
    PageMargins margins = const PageMargins.all(72),
  }) async {
    final bytes = await convertFileToBytes(
      inputPath: inputPath,
      title: title,
      author: author,
      pageFormat: pageFormat,
      fontSize: fontSize,
      fontFamily: fontFamily,
      margins: margins,
    );

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  }
}
