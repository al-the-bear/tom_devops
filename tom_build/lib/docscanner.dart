/// DocScanner - Parses markdown files into structured data.
///
/// This library provides tools to scan markdown documents and convert
/// their headline structure into a traversable tree of sections.
///
/// ## Usage
///
/// ```dart
/// import 'package:tom_build/docscanner.dart';
///
/// // Scan a single document
/// final doc = await DocScanner.scanDocument(filepath: 'README.md');
/// print(doc.name);
///
/// // Scan with a custom factory
/// final customDoc = await DocScanner.scanDocument(
///   filepath: 'README.md',
///   factory: MyCustomFactory(),
/// );
/// ```
///
/// ## D4rt Bridge
///
/// To use DocScanner in D4rt scripts, register the bridges:
///
/// ```dart
/// import 'package:tom_build/docscanner.dart';
/// import 'package:tom_d4rt/d4rt.dart';
///
/// final interpreter = D4rt();
/// DocScannerBridge.registerAllBridges(interpreter);
/// ```
///
/// ## Classes
///
/// - [DocScanner] - Main API for scanning documents
/// - [DocScannerFactory] - Factory for customizing Document/Section creation
/// - [Document] - A parsed markdown document
/// - [Section] - A section within a document
/// - [DocumentFolder] - A folder containing documents and subfolders
library;

export 'src/doc_scanner/doc_scanner.dart' show DocScanner;
export 'src/doc_scanner/doc_scanner_factory.dart' show DocScannerFactory;
export 'src/doc_scanner/markdown_parser.dart' show ParsedHeadline, MarkdownParser;
export 'src/doc_scanner/models/document.dart' show Document;
export 'src/doc_scanner/models/document_folder.dart' show DocumentFolder;
export 'src/doc_scanner/models/section.dart' show Section;
