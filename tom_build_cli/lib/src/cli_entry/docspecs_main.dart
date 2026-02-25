/// DocSpecs CLI entry point.
///
/// Validates and scans DocSpec markdown documents.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_build/doc_specs.dart';

/// Main entry point for docspecs CLI.
Future<void> docSpecsMain(List<String> arguments) async {
  if (arguments.isEmpty) {
    printDocSpecsUsage();
    exit(1);
  }

  final args = _parseArgs(arguments);

  if (args.help) {
    printDocSpecsUsage();
    return;
  }

  final command = args.command.toLowerCase();

  try {
    switch (command) {
      case 'validate':
        await _validate(args);
      case 'scan':
        await _scan(args);
      case 'list-schemas':
        _listSchemas(args);
      default:
        stderr.writeln('Unknown command: $command');
        stderr.writeln('Use: validate, scan, or list-schemas');
        exit(1);
    }
  } on _SchemaNotFoundException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(2);
  } on _FileNotFoundException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exit(3);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

/// Custom exception for schema not found.
class _SchemaNotFoundException implements Exception {
  final String message;
  _SchemaNotFoundException(this.message);
}

/// Custom exception for file not found.
class _FileNotFoundException implements Exception {
  final String message;
  _FileNotFoundException(this.message);
}

/// Parsed command-line arguments.
class _Args {
  final String command;
  final List<String> paths;
  final String targetDir;
  final String? schema;
  final String format;
  final bool quiet;
  final bool overwrite;
  final bool recursive;
  final bool noAi;
  final bool help;

  _Args({
    required this.command,
    required this.paths,
    required this.targetDir,
    this.schema,
    required this.format,
    required this.quiet,
    required this.overwrite,
    required this.recursive,
    required this.noAi,
    required this.help,
  });
}

/// Parses command-line arguments.
_Args _parseArgs(List<String> arguments) {
  String command = '';
  final paths = <String>[];
  String targetDir = Directory.current.path;
  String? schema;
  String format = 'json';
  bool quiet = false;
  bool overwrite = false;
  bool recursive = false;
  bool noAi = false;
  bool help = false;

  for (final arg in arguments) {
    if (arg == '-help' || arg == '--help' || arg == '-h') {
      help = true;
    } else if (arg.startsWith('-target=')) {
      targetDir = arg.substring('-target='.length);
    } else if (arg.startsWith('-schema=')) {
      schema = arg.substring('-schema='.length);
    } else if (arg.startsWith('-format=')) {
      format = arg.substring('-format='.length).toLowerCase();
    } else if (arg == '-quiet') {
      quiet = true;
    } else if (arg == '-overwrite') {
      overwrite = true;
    } else if (arg == '--recursive') {
      recursive = true;
    } else if (arg == '--no-ai') {
      noAi = true;
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
    schema: schema,
    format: format,
    quiet: quiet,
    overwrite: overwrite,
    recursive: recursive,
    noAi: noAi,
    help: help,
  );
}

/// Validates documents against their schemas.
Future<void> _validate(_Args args) async {
  final files = await _resolveFiles(args.paths, args.recursive);

  if (files.isEmpty) {
    if (!args.quiet) {
      stderr.writeln('No .docspec.md files found');
    }
    exit(3);
  }

  var hasErrors = false;
  var validCount = 0;
  var invalidCount = 0;

  for (final filePath in files) {
    try {
      final doc = await DocSpecs.scanDocument(
        filePath: filePath,
        schemaId: args.schema,
      );

      if (doc.isValid) {
        validCount++;
        if (!args.quiet) {
          print('✓ ${_relativePath(filePath)}');
        }
      } else {
        invalidCount++;
        hasErrors = true;
        if (!args.quiet) {
          print('✗ ${_relativePath(filePath)}');
          for (final error in doc.validationErrors) {
            print('    $error');
          }
        }
      }
    } on _SchemaNotFoundException {
      rethrow;
    } catch (e) {
      invalidCount++;
      hasErrors = true;
      if (!args.quiet) {
        print('✗ ${_relativePath(filePath)}');
        print('    Error: $e');
      }
    }
  }

  if (!args.quiet) {
    print('');
    print('Results: $validCount valid, $invalidCount invalid');
  }

  if (hasErrors) {
    exit(1);
  }
}

/// Scans documents and outputs as JSON/YAML.
Future<void> _scan(_Args args) async {
  final files = await _resolveFiles(args.paths, args.recursive);

  if (files.isEmpty) {
    if (!args.quiet) {
      stderr.writeln('No .docspec.md files found');
    }
    exit(3);
  }

  await _ensureDirectory(args.targetDir);
  final usedNames = <String, int>{};

  for (final filePath in files) {
    try {
      final doc = await DocSpecs.scanDocument(
        filePath: filePath,
        schemaId: args.schema,
      );

      await _writeDocument(
        doc,
        args.targetDir,
        args.format,
        args.overwrite,
        usedNames,
      );

      if (!args.quiet) {
        print('Scanned: ${_relativePath(filePath)}');
      }
    } on _SchemaNotFoundException {
      rethrow;
    } catch (e) {
      if (!args.quiet) {
        stderr.writeln('Error scanning ${_relativePath(filePath)}: $e');
      }
    }
  }

  if (!args.quiet) {
    print('');
    print('Total: ${files.length} documents');
  }
}

/// Lists available schemas.
void _listSchemas(_Args args) {
  final schemas = DocSpecs.listSchemasSync();

  if (schemas.isEmpty) {
    if (!args.quiet) {
      print('No schemas found');
    }
    return;
  }

  if (!args.quiet) {
    print('Available schemas:');
    print('');
  }

  // Group by source for cleaner output
  final bySource = <SchemaSource, List<SchemaInfo>>{};
  for (final schema in schemas) {
    bySource.putIfAbsent(schema.source, () => []).add(schema);
  }

  for (final source in [
    SchemaSource.local,
    SchemaSource.user,
    SchemaSource.builtin,
  ]) {
    final group = bySource[source];
    if (group == null || group.isEmpty) continue;

    for (final schema in group) {
      final sourceLabel = _sourceLabel(schema.source);
      final pathDisplay = schema.source == SchemaSource.builtin
          ? '(built-in)'
          : _relativePath(schema.path);

      print('  ${schema.fullId.padRight(24)} [$sourceLabel]  $pathDisplay');
    }
  }
}

/// Resolves file paths, expanding directories and globs.
Future<List<String>> _resolveFiles(List<String> paths, bool recursive) async {
  final files = <String>{};

  if (paths.isEmpty && recursive) {
    // If no paths and recursive, scan current directory
    paths = [Directory.current.path];
  }

  for (final path in paths) {
    final resolved = _resolvePath(path);

    if (await FileSystemEntity.isDirectory(resolved)) {
      if (recursive) {
        // Recursively find all .docspec.md files
        await for (final entity in Directory(resolved).list(recursive: true)) {
          if (entity is File && entity.path.endsWith('.docspec.md')) {
            files.add(entity.path);
          }
        }
      } else {
        // Non-recursive: just files in this directory
        await for (final entity in Directory(resolved).list()) {
          if (entity is File && entity.path.endsWith('.docspec.md')) {
            files.add(entity.path);
          }
        }
      }
    } else if (await File(resolved).exists()) {
      files.add(resolved);
    } else {
      // Check if it's a glob pattern
      if (path.contains('*')) {
        final dir = p.dirname(resolved);
        final pattern = p.basename(path);
        final regex = _globToRegex(pattern);

        if (await Directory(dir).exists()) {
          await for (final entity in Directory(dir).list()) {
            if (entity is File && regex.hasMatch(p.basename(entity.path))) {
              files.add(entity.path);
            }
          }
        }
      } else {
        throw _FileNotFoundException('File not found: $path');
      }
    }
  }

  final result = files.toList()..sort();
  return result;
}

/// Converts a simple glob pattern to regex.
RegExp _globToRegex(String pattern) {
  final escaped = pattern
      .replaceAll('.', r'\.')
      .replaceAll('*', '.*')
      .replaceAll('?', '.');
  return RegExp('^$escaped\$');
}

/// Writes a document to JSON/YAML file.
Future<void> _writeDocument(
  SpecDoc doc,
  String targetDir,
  String format,
  bool overwrite,
  Map<String, int> usedNames,
) async {
  await _ensureDirectory(targetDir);

  final basename = p.basenameWithoutExtension(
    doc.filename.endsWith('.docspec.md')
        ? doc.filename.substring(
            0,
            doc.filename.length - '.docspec.md'.length + '.md'.length,
          )
        : doc.filename,
  );

  var outputName = '$basename.$format';

  // Handle name conflicts
  if (!overwrite) {
    final key = basename.toLowerCase();
    if (usedNames.containsKey(key)) {
      usedNames[key] = usedNames[key]! + 1;
      outputName = '${basename}_${usedNames[key]}.$format';
    } else {
      usedNames[key] = 1;

      // Check if file already exists
      var outputPath = p.join(targetDir, outputName);
      var suffix = 2;
      while (File(outputPath).existsSync()) {
        outputName = '${basename}_$suffix.$format';
        outputPath = p.join(targetDir, outputName);
        suffix++;
      }
    }
  }

  final outputPath = p.join(targetDir, outputName);
  final content = format == 'yaml'
      ? _toYaml(doc.toJson())
      : const JsonEncoder.withIndent('  ').convert(doc.toJson());

  await File(outputPath).writeAsString(content);
}

/// Simple YAML serializer for basic structures.
String _toYaml(Map<String, dynamic> json, [int indent = 0]) {
  final buffer = StringBuffer();
  final prefix = '  ' * indent;

  for (final entry in json.entries) {
    buffer.write('$prefix${entry.key}:');

    final value = entry.value;
    if (value == null) {
      buffer.writeln(' null');
    } else if (value is Map<String, dynamic>) {
      buffer.writeln();
      buffer.write(_toYaml(value, indent + 1));
    } else if (value is List) {
      if (value.isEmpty) {
        buffer.writeln(' []');
      } else {
        buffer.writeln();
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            buffer.writeln('$prefix  -');
            buffer.write(_toYaml(item, indent + 2));
          } else {
            buffer.writeln('$prefix  - ${_yamlValue(item)}');
          }
        }
      }
    } else {
      buffer.writeln(' ${_yamlValue(value)}');
    }
  }

  return buffer.toString();
}

/// Formats a value for YAML output.
String _yamlValue(dynamic value) {
  if (value is String) {
    if (value.contains('\n') || value.contains(':') || value.contains('#')) {
      return '"${value.replaceAll('"', r'\"').replaceAll('\n', r'\n')}"';
    }
    return value;
  }
  return value.toString();
}

/// Returns a source label for display.
String _sourceLabel(SchemaSource source) {
  switch (source) {
    case SchemaSource.local:
      return 'local';
    case SchemaSource.user:
      return 'user';
    case SchemaSource.builtin:
      return 'builtin';
  }
}

/// Resolves a path to absolute.
String _resolvePath(String path) {
  if (p.isAbsolute(path)) {
    return p.normalize(path);
  }
  return p.normalize(p.join(Directory.current.path, path));
}

/// Returns a relative path for display.
String _relativePath(String path) {
  final relative = p.relative(path, from: Directory.current.path);
  return relative.startsWith('..') ? path : relative;
}

/// Ensures a directory exists.
Future<void> _ensureDirectory(String dir) async {
  final directory = Directory(dir);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

/// Prints usage information.
void printDocSpecsUsage() {
  print('''
DocSpecs - Validate and scan DocSpec markdown documents

Usage:
  docspecs <command> [arguments] [options]

Commands:
  validate <files...>    Validate documents against their schemas
  scan <files...>        Scan documents and output as JSON/YAML
  list-schemas           List available schema definitions

Options:
  -target=<folder>       Output folder (default: current directory)
  -schema=<id>           Override schema (ignore document declaration)
  -format=json|yaml      Output format for scan (default: json)
  -quiet                 Suppress output except errors
  -overwrite             Overwrite existing files without renaming
  --recursive            Scan directories recursively for .docspec.md files
  --no-ai                Disable AI validation prompts
  -help                  Show this help message

Examples:
  # Validate all docspec documents in current directory
  docspecs validate *.docspec.md

  # Validate all docspec documents recursively
  docspecs validate --recursive

  # Validate documents in a specific folder recursively
  docspecs validate ./docs --recursive

  # Scan and export to JSON
  docspecs scan quest_overview.docspec.md -target=./output

  # Scan with YAML output format
  docspecs scan spec.docspec.md -format=yaml

  # Validate with specific schema override
  docspecs validate spec.docspec.md -schema=quest-overview/1.0

  # List all available schemas
  docspecs list-schemas

Exit Codes:
  0 - Success (all documents valid)
  1 - Validation errors found
  2 - Schema not found
  3 - File not found
''');
}
