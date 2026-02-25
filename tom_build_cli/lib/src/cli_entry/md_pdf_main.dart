/// Markdown to PDF Converter CLI entry point.
library;

import 'dart:io';

import 'package:htmltopdfwidgets/htmltopdfwidgets.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:tom_build/src/md_pdf_converter/md_pdf_converter.dart';

/// Main entry point for md_pdf_converter CLI.
Future<void> mdPdfMain(List<String> arguments) async {
  if (arguments.isEmpty) {
    printMdPdfUsage();
    exit(1);
  }

  // Handle --help
  if (arguments.contains('--help') || arguments.contains('-h')) {
    printMdPdfUsage();
    return;
  }

  // Parse arguments
  final positionalArgs =
      arguments.where((arg) => !arg.startsWith('-')).toList();
  final flags = arguments.where((arg) => arg.startsWith('-')).toList();

  if (positionalArgs.isEmpty) {
    print('Error: Input file or directory is required');
    printMdPdfUsage();
    exit(1);
  }

  final inputPath = positionalArgs[0];

  // Parse output directory (optional, defaults to same folder as input)
  String? outputDir;
  for (final flag in flags) {
    if (flag.startsWith('-o=')) {
      outputDir = flag.substring('-o='.length);
    } else if (flag.startsWith('--output=')) {
      outputDir = flag.substring('--output='.length);
    }
  }

  // Default to same folder as input file
  if (outputDir == null) {
    if (FileSystemEntity.isFileSync(inputPath)) {
      outputDir = p.dirname(inputPath);
    } else {
      outputDir = inputPath;
    }
  }

  // Parse title
  String? title;
  for (final flag in flags) {
    if (flag.startsWith('--title=')) {
      title = flag.substring('--title='.length);
    }
  }

  // Parse author
  String? author;
  for (final flag in flags) {
    if (flag.startsWith('--author=')) {
      author = flag.substring('--author='.length);
    }
  }

  // Parse page format
  var pageFormat = PdfPageFormat.a4;
  for (final flag in flags) {
    if (flag.startsWith('--format=')) {
      final format = flag.substring('--format='.length).toLowerCase();
      switch (format) {
        case 'letter':
          pageFormat = PdfPageFormat.letter;
        case 'legal':
          pageFormat = PdfPageFormat.legal;
        case 'a3':
          pageFormat = PdfPageFormat.a3;
        case 'a5':
          pageFormat = PdfPageFormat.a5;
        default:
          pageFormat = PdfPageFormat.a4;
      }
    }
  }

  // Parse margin
  var margin = const pw.EdgeInsets.all(72); // 1 inch default
  for (final flag in flags) {
    if (flag.startsWith('--margin=')) {
      final value = double.tryParse(flag.substring('--margin='.length));
      if (value != null) {
        margin = pw.EdgeInsets.all(value);
      }
    }
  }

  // Parse font size
  var fontSize = 12.0;
  for (final flag in flags) {
    if (flag.startsWith('--font-size=')) {
      final value = double.tryParse(flag.substring('--font-size='.length));
      if (value != null) {
        fontSize = value;
      }
    }
  }

  if (!FileSystemEntity.isFileSync(inputPath) &&
      !FileSystemEntity.isDirectorySync(inputPath)) {
    print('Error: Input path not found: $inputPath');
    exit(1);
  }

  // Add page numbers if requested
  pw.Widget Function(pw.Context)? footerBuilder;
  if (flags.contains('--page-numbers')) {
    footerBuilder = (pw.Context context) {
      return pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      );
    };
  }

  // Build tagStyle based on flags
  final noDefaultStyles = flags.contains('--no-default-styles');
  final tagStyle = HtmlTagStyle(
    useDefaultStyles: !noDefaultStyles,
    paragraphMargin: const pw.EdgeInsets.only(bottom: 8),
  );

  final options = MdPdfConverterOptions(
    title: title,
    author: author,
    pageFormat: pageFormat,
    margin: margin,
    fontSize: fontSize,
    tagStyle: tagStyle,
    footerBuilder: footerBuilder,
  );

  print('Markdown to PDF Converter');
  print('=========================');
  print('Input: $inputPath');
  print('Output: $outputDir');
  print('Options:');
  print('  Page format: ${_formatName(pageFormat)}');
  print('  Margin: ${margin.left}pt');
  print('  Font size: ${fontSize}pt');
  if (title != null) print('  Title: $title');
  if (author != null) print('  Author: $author');
  if (flags.contains('--page-numbers')) print('  Page numbers: enabled');
  print('');

  final converter = MdPdfConverter(inputPath, options: options);
  final result = await converter.convertAll(outputDir: outputDir);

  // Print results
  _printResults(result);

  if (!result.isSuccess) {
    exit(1);
  }
}

String _formatName(PdfPageFormat format) {
  if (format == PdfPageFormat.a4) return 'A4';
  if (format == PdfPageFormat.a3) return 'A3';
  if (format == PdfPageFormat.a5) return 'A5';
  if (format == PdfPageFormat.letter) return 'Letter';
  if (format == PdfPageFormat.legal) return 'Legal';
  return 'Custom';
}

void _printResults(MdPdfConverterResult result) {
  if (result.converted.isEmpty && result.errors.isEmpty) {
    print('No markdown files found to convert.');
    return;
  }

  for (final file in result.converted) {
    print('Converted: ${file.sourcePath}');
    print('       -> ${file.outputPath}');
  }

  for (final error in result.errors) {
    print('ERROR: $error');
  }

  print('');
  print('Summary:');
  print('  Files converted: ${result.converted.length}');
  if (result.errors.isNotEmpty) {
    print('  Errors: ${result.errors.length}');
  }
}

/// Prints usage information.
void printMdPdfUsage() {
  print('''
Markdown to PDF Converter

Converts markdown files directly to PDF format using the htmltopdfwidgets
package. No LaTeX installation required.

Supports:
  - Standard markdown elements (headings, lists, tables, code blocks)
  - Inline formatting (bold, italic, code)
  - Links and images
  - Block quotes
  - Multiple page formats

Usage:
  md2pdf <input> [options]

Arguments:
  <input>       Input markdown file or directory

Options:
  -h, --help              Show this help message
  -o, --output=DIR        Output directory (default: same as input file)
  --title=TITLE           Document title
  --author=NAME           Document author
  --format=FORMAT         Page format: a4, a3, a5, letter, legal (default: a4)
  --margin=POINTS         Page margin in points (default: 72 = 1 inch)
  --font-size=POINTS      Font size in points (default: 12)
  --page-numbers          Add page numbers to footer

Examples:
  # Convert to PDF (same folder as input)
  md2pdf README.md

  # Convert to specific output directory
  md2pdf README.md -o=output/

  # Convert with custom options
  md2pdf README.md --format=letter --author="John Doe"

  # Convert with page numbers
  md2pdf README.md --page-numbers

  # Convert entire directory
  md2pdf docs/
''');
}
