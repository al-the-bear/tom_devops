import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_md2latex/tom_md2latex.dart';

/// Command-line tool to convert Markdown files to LaTeX and optionally PDF.
///
/// Usage:
/// ```
/// dart run tom_md2latex:md2latex <input> [options]
/// dart run tom_md2latex:md2latex docs/README.md
/// dart run tom_md2latex:md2latex docs/README.md --pdf
/// dart run tom_md2latex:md2latex docs/README.md -o output/
/// ```
Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    _printUsage();
    exit(1);
  }

  // Handle --help
  if (arguments.contains('--help') || arguments.contains('-h')) {
    _printUsage();
    return;
  }

  // Parse arguments
  final positionalArgs = arguments
      .where((arg) => !arg.startsWith('-'))
      .toList();
  final flags = arguments.where((arg) => arg.startsWith('-')).toList();

  if (positionalArgs.isEmpty) {
    print('Error: Input file or directory is required');
    _printUsage();
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

  // Parse options
  final generatePreamble = !flags.contains('--no-preamble');
  final detectAscii = !flags.contains('--no-ascii');
  final generateToc = !flags.contains('--no-toc');
  final generatePdf = flags.contains('--pdf');
  final deleteTex = flags.contains('--no-tex');

  // Parse document class
  var documentClass = 'article';
  for (final flag in flags) {
    if (flag.startsWith('--document-class=')) {
      documentClass = flag.substring('--document-class='.length);
    }
  }

  // Parse author
  String? author;
  for (final flag in flags) {
    if (flag.startsWith('--author=')) {
      author = flag.substring('--author='.length);
    }
  }

  // Parse TOC depth (default: 3)
  var tocDepth = 3;
  for (final flag in flags) {
    if (flag.startsWith('--toc-depth=')) {
      final value = int.tryParse(flag.substring('--toc-depth='.length));
      if (value != null && value >= 1 && value <= 5) {
        tocDepth = value;
      } else {
        print('Warning: --toc-depth must be 1-5, using default (3)');
      }
    }
  }

  if (!FileSystemEntity.isFileSync(inputPath) &&
      !FileSystemEntity.isDirectorySync(inputPath)) {
    print('Error: Input path not found: $inputPath');
    exit(1);
  }

  final parserOptions = MarkdownParserOptions(detectAsciiDiagrams: detectAscii);

  final options = MdLatexConverterOptions(
    generatePreamble: generatePreamble,
    documentClass: documentClass,
    author: author,
    generateToc: generateToc,
    tocDepth: tocDepth,
    parserOptions: parserOptions,
  );

  print('Markdown to LaTeX Converter');
  print('===========================');
  print('Input: $inputPath');
  print('Output: $outputDir');
  print('Options:');
  print('  Document class: $documentClass');
  print('  Generate preamble: $generatePreamble');
  print('  Detect ASCII diagrams: $detectAscii');
  print('  Generate TOC: $generateToc');
  print('  TOC depth: $tocDepth');
  print('  Generate PDF: $generatePdf');
  if (author != null) print('  Author: $author');
  print('');

  final converter = MdLatexConverter(inputPath, options: options);
  final result = await converter.convertAll(outputDir: outputDir);

  // Print results
  _printResults(result);

  if (!result.isSuccess) {
    exit(1);
  }

  // Generate PDF if requested
  if (generatePdf && result.converted.isNotEmpty) {
    print('');
    print('Generating PDF...');

    for (final file in result.converted) {
      final texPath = file.outputPath;
      final texDir = p.dirname(texPath);
      final texName = p.basenameWithoutExtension(texPath);

      // Run xelatex twice for proper cross-references
      for (var pass = 1; pass <= 2; pass++) {
        print('  XeLaTeX pass $pass for $texName...');
        final xelatexResult = await Process.run('xelatex', [
          '-interaction=nonstopmode',
          texPath,
        ], workingDirectory: texDir);

        if (xelatexResult.exitCode != 0 && pass == 2) {
          print(
            '  Warning: XeLaTeX returned exit code ${xelatexResult.exitCode}',
          );
          // Don't fail - PDF may still be usable
        }
      }

      final pdfPath = p.join(texDir, '$texName.pdf');
      if (File(pdfPath).existsSync()) {
        print('  Generated: $pdfPath');

        // Remove .tex file if --no-tex is specified
        if (deleteTex) {
          final texFile = File(texPath);
          if (texFile.existsSync()) {
            await texFile.delete();
          }

          // Also clean up auxiliary files when deleting .tex
          final auxExtensions = ['.aux', '.log', '.out', '.toc'];
          for (final ext in auxExtensions) {
            final auxFile = File(p.join(texDir, '$texName$ext'));
            if (auxFile.existsSync()) {
              await auxFile.delete();
            }
          }
        }
      } else {
        print('  ERROR: PDF not generated for $texName');
      }
    }

    print('');
    print('PDF generation complete.');
  }
}

void _printResults(MdLatexConverterResult result) {
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

void _printUsage() {
  print('''
Markdown to LaTeX/PDF Converter

Converts markdown files to LaTeX format with support for:
  - Standard markdown elements (headings, lists, tables, code blocks)
  - ASCII diagrams (auto-detected, rendered in monospace font)
  - Block quotes with framed styling
  - Syntax-highlighted code blocks using listings package
  - Configurable table of contents
  - PDF generation via XeLaTeX

Usage:
  dart run tom_md2latex:md2latex <input> [options]

Arguments:
  <input>       Input markdown file or directory

Options:
  -h, --help              Show this help message
  -o, --output=DIR        Output directory (default: same as input file)
  --pdf                   Also generate PDF using XeLaTeX
  --no-tex                Delete .tex file after generating PDF
  --no-preamble           Do not generate LaTeX preamble (for inclusion in other docs)
  --document-class=CLASS  LaTeX document class (default: article)
  --author=NAME           Document author for document metadata
  --no-ascii              Disable ASCII diagram detection
  --no-toc                Disable table of contents generation
  --toc-depth=N           TOC depth 1-5 (default: 3)
                          1=sections, 2=subsections, 3=subsubsections,
                          4=paragraphs, 5=subparagraphs

Frontmatter Options:
  The following YAML frontmatter options are supported:
    title: "Document Title"
    author: "Author Name"
    date: "2024-01-01"
    toc: true              # Generate table of contents
    toc-depth: 3           # TOC depth (1-5)

Examples:
  # Convert to LaTeX (same folder as input)
  dart run tom_md2latex:md2latex README.md

  # Convert to PDF (same folder as input)
  dart run tom_md2latex:md2latex README.md --pdf

  # Convert to specific output directory
  dart run tom_md2latex:md2latex README.md -o=output/

  # Convert to PDF and delete .tex file
  dart run tom_md2latex:md2latex README.md --pdf --no-tex

  # Convert with custom document class
  dart run tom_md2latex:md2latex README.md --document-class=report

  # Convert with deep TOC (all heading levels)
  dart run tom_md2latex:md2latex README.md --toc-depth=5

LaTeX Dependencies (for PDF generation):
  Required: XeLaTeX (from TeX Live or similar)
  Required packages:
  - fontspec (Unicode fonts)
  - listings (code blocks)
  - framed (block quotes, ASCII diagrams)
  - booktabs (tables)
  - fancyvrb (verbatim environments)
  - graphicx (images)
  - hyperref (links)
  - xcolor (colors)
''');
}
