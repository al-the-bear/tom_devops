/// DocScanner CLI entry point.
///
/// Re-exports the main function from the bin file.
/// This wrapper allows the CLI to be called from other packages.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_build/docscanner.dart';

/// Main entry point for doc_scanner CLI.
Future<void> docScannerMain(List<String> arguments) async {
  if (arguments.isEmpty) {
    printDocScannerUsage();
    exit(1);
  }

  final args = _parseArgs(arguments);

  if (args.help) {
    printDocScannerUsage();
    return;
  }

  final command = args.command.toLowerCase();

  try {
    switch (command) {
      case 'scandocument':
        await _scanDocument(args);
      case 'scandocuments':
        await _scanDocuments(args);
      case 'scantree':
        await _scanTree(args);
      default:
        stderr.writeln('Unknown command: $command');
        stderr.writeln('Use: scandocument, scandocuments, or scantree');
        exit(1);
    }
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

/// Parsed command-line arguments.
class _Args {
  final String command;
  final List<String> paths;
  final String targetDir;
  final bool flat;
  final bool overwrite;
  final bool help;

  _Args({
    required this.command,
    required this.paths,
    required this.targetDir,
    required this.flat,
    required this.overwrite,
    required this.help,
  });
}

/// Parses command-line arguments.
_Args _parseArgs(List<String> arguments) {
  String command = '';
  final paths = <String>[];
  String targetDir = Directory.current.path;
  bool flat = false;
  bool overwrite = false;
  bool help = false;

  for (final arg in arguments) {
    if (arg == '-help' || arg == '--help' || arg == '-h') {
      help = true;
    } else if (arg.startsWith('-target=')) {
      targetDir = arg.substring('-target='.length);
    } else if (arg == '-flat') {
      flat = true;
    } else if (arg == '-overwrite') {
      overwrite = true;
    } else if (command.isEmpty && !arg.startsWith('-')) {
      command = arg;
    } else if (!arg.startsWith('-')) {
      paths.add(arg);
    }
  }

  // Resolve target directory to absolute path
  if (!p.isAbsolute(targetDir)) {
    targetDir = p.normalize(p.join(Directory.current.path, targetDir));
  }

  return _Args(
    command: command,
    paths: paths,
    targetDir: targetDir,
    flat: flat,
    overwrite: overwrite,
    help: help,
  );
}

/// Scans a single document.
Future<void> _scanDocument(_Args args) async {
  if (args.paths.isEmpty) {
    throw ArgumentError('scandocument requires a file path');
  }

  final filepath = _resolvePath(args.paths.first);
  final doc = await DocScanner.scanDocument(filepath: filepath);
  await _writeDocument(doc, args.targetDir, args.overwrite, {});
  print('Scanned: ${doc.filename} -> ${_outputFilename(doc.filename)}');
}

/// Scans multiple documents.
Future<void> _scanDocuments(_Args args) async {
  if (args.paths.isEmpty) {
    throw ArgumentError('scandocuments requires at least one file path');
  }

  // Resolve all paths and check for duplicates
  final resolvedPaths = <String>{};
  final uniquePaths = <String>[];

  for (final path in args.paths) {
    final resolved = _resolvePath(path);
    if (resolvedPaths.contains(resolved)) {
      stderr.writeln('Warning: Duplicate file ignored: $path');
      continue;
    }
    resolvedPaths.add(resolved);
    uniquePaths.add(resolved);
  }

  final docs = await DocScanner.scanDocuments(filepaths: uniquePaths);
  final usedNames = <String, int>{};

  for (final doc in docs) {
    await _writeDocument(doc, args.targetDir, args.overwrite, usedNames);
    print('Scanned: ${doc.filename}');
  }

  print('Total: ${docs.length} documents');
}

/// Scans a directory tree.
Future<void> _scanTree(_Args args) async {
  if (args.paths.isEmpty) {
    throw ArgumentError('scantree requires a folder path');
  }

  final folderPath = _resolvePath(args.paths.first);
  final folder = await DocScanner.scanTree(path: folderPath);

  await _ensureDirectory(args.targetDir);

  if (args.flat) {
    // Flatten all documents
    final allDocs = folder.allDocuments;
    final usedNames = <String, int>{};

    for (final doc in allDocs) {
      await _writeDocument(doc, args.targetDir, args.overwrite, usedNames);
    }

    print('Total: ${allDocs.length} documents (flattened)');
  } else {
    // Preserve directory structure
    await _writeFolderTree(folder, args.targetDir, args.overwrite);
    print('Total: ${folder.allDocuments.length} documents');
  }
}

/// Writes a folder tree preserving structure.
Future<void> _writeFolderTree(
  DocumentFolder folder,
  String targetDir,
  bool overwrite,
) async {
  await _ensureDirectory(targetDir);
  final usedNames = <String, int>{};

  // Write documents in current folder
  for (final doc in folder.documents) {
    await _writeDocument(doc, targetDir, overwrite, usedNames);
  }

  // Recursively write subfolders
  for (final subfolder in folder.folders) {
    final subTargetDir = p.join(targetDir, subfolder.foldername);
    await _writeFolderTree(subfolder, subTargetDir, overwrite);
  }
}

/// Writes a document to JSON file.
Future<void> _writeDocument(
  Document doc,
  String targetDir,
  bool overwrite,
  Map<String, int> usedNames,
) async {
  await _ensureDirectory(targetDir);

  final basename = p.basenameWithoutExtension(doc.filename);
  var outputName = _outputFilename(doc.filename);

  // Handle name conflicts
  if (!overwrite) {
    final key = basename.toLowerCase();
    if (usedNames.containsKey(key)) {
      usedNames[key] = usedNames[key]! + 1;
      outputName =
          '${basename}_${doc.workspacePath.replaceAll(p.separator, '_').replaceAll('/', '_')}.json';

      // Check if that name also exists
      final outputPath = p.join(targetDir, outputName);
      if (File(outputPath).existsSync()) {
        outputName = '${basename}_${usedNames[key]}.json';
      }
    } else {
      usedNames[key] = 1;

      // Check if file already exists in target
      var outputPath = p.join(targetDir, outputName);
      var suffix = 2;
      while (File(outputPath).existsSync()) {
        outputName = '${basename}_$suffix.json';
        outputPath = p.join(targetDir, outputName);
        suffix++;
      }
    }
  }

  final outputPath = p.join(targetDir, outputName);
  final json = const JsonEncoder.withIndent('  ').convert(doc.toJson());
  await File(outputPath).writeAsString(json);
}

/// Converts markdown filename to JSON filename.
String _outputFilename(String mdFilename) {
  final basename = p.basenameWithoutExtension(mdFilename);
  return '$basename.json';
}

/// Resolves a path to absolute.
String _resolvePath(String path) {
  if (p.isAbsolute(path)) {
    return p.normalize(path);
  }
  return p.normalize(p.join(Directory.current.path, path));
}

/// Ensures a directory exists.
Future<void> _ensureDirectory(String dir) async {
  final directory = Directory(dir);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

/// Prints usage information.
void printDocScannerUsage() {
  print('''
DocScanner - Convert markdown files to structured JSON

Usage:
  doc_scanner <command> [arguments] [options]

Commands:
  scandocument <file>         Scan a single markdown file
  scandocuments <files...>    Scan multiple markdown files
  scantree <folder>           Scan a directory tree recursively

Options:
  -target=<folder>    Output directory (default: current directory)
  -flat               Flatten directory structure (scantree only)
  -overwrite          Overwrite existing files without renaming
  -help               Show this help message

Examples:
  doc_scanner scandocument README.md
  doc_scanner scandocument docs/guide.md -target=output
  doc_scanner scandocuments doc1.md doc2.md doc3.md
  doc_scanner scantree docs/ -target=json-output
  doc_scanner scantree docs/ -flat -target=all-json
  doc_scanner scantree . -overwrite

Output:
  Each markdown file is converted to a JSON file with the same base name.
  The JSON structure contains:
    - name: Document/section title
    - id: Unique identifier (from [id] markers or auto-generated)
    - text: Content between headlines
    - sections: Nested subsections
    - File path information (for documents)
''');
}
