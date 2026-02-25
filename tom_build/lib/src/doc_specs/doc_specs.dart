import 'dart:io';

import 'package:path/path.dart' as path;

import '../doc_scanner/doc_scanner.dart';
import '../doc_scanner/models/document_folder.dart';
import 'doc_specs_factory.dart';
import 'models/schema/doc_spec_schema.dart';
import 'models/schema/schema_info.dart';
import 'models/spec_doc.dart';
import 'schema/schema_loader.dart';
import 'validation/validator.dart';

/// DocSpecs - Document schema validation system.
///
/// Provides static methods to scan, validate, and access structured markdown
/// documents against defined schemas. Extends DocScanner with schema definitions
/// and typed section access.
///
/// ## Example
///
/// ```dart
/// // Scan and validate a document
/// final doc = await DocSpecs.scanDocument(path: 'quest_overview.docspec.md');
///
/// if (!doc.isValid) {
///   print('Validation errors: ${doc.validationErrors}');
/// }
///
/// // Access typed sections
/// final todos = doc.getSpecSectionType('todo').getAll();
/// for (final todo in todos) {
///   print('TODO: ${todo.id}');
/// }
///
/// // List available schemas
/// final schemas = DocSpecs.listSchemas(documentPath: 'docs/');
/// for (final schema in schemas) {
///   print('Schema: ${schema.fullId}');
/// }
/// ```
class DocSpecs {
  /// Private constructor to prevent instantiation.
  DocSpecs._();

  /// Load and validate a single document (async).
  ///
  /// The schema is determined from:
  /// 1. The [schemaId] parameter if provided
  /// 2. The document's `schema` field in the first headline
  static Future<SpecDoc> scanDocument({
    required String filePath,
    String? schemaId,
    String? workspaceRoot,
  }) async {
    final absolutePath = _toAbsolutePath(filePath);
    final wsRoot = workspaceRoot ?? Directory.current.path;

    // Read document to extract schema ID
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw ArgumentError('Document not found: $absolutePath');
    }

    // Determine schema ID
    final effectiveSchemaId = schemaId ?? await _extractSchemaId(absolutePath);

    // Load schema
    DocSpecSchema? schema;
    if (effectiveSchemaId != null) {
      schema = await SchemaResolver.resolve(
        schemaId: effectiveSchemaId,
        documentPath: absolutePath,
        workspaceRoot: wsRoot,
      );
    }

    // Create factory with schema
    final factory = DocSpecsFactory(schema: schema);

    // Scan document using DocScanner
    final doc = await DocScanner.scanDocument(
      filepath: absolutePath,
      workspaceRoot: wsRoot,
      factory: factory,
    );

    // Cast to SpecDoc and validate
    final specDoc = doc as SpecDoc;

    if (schema != null) {
      final validator = DocSpecsValidator(schema: schema);
      final errors = validator.validate(specDoc);
      specDoc.validationErrors.addAll(errors.map((e) => e.toString()));
    }

    return specDoc;
  }

  /// Load and validate a single document (sync).
  static SpecDoc scanDocumentSync({
    required String filePath,
    String? schemaId,
    String? workspaceRoot,
  }) {
    final absolutePath = _toAbsolutePath(filePath);
    final wsRoot = workspaceRoot ?? Directory.current.path;

    // Read document to extract schema ID
    final file = File(absolutePath);
    if (!file.existsSync()) {
      throw ArgumentError('Document not found: $absolutePath');
    }

    // Determine schema ID
    final effectiveSchemaId = schemaId ?? _extractSchemaIdSync(absolutePath);

    // Load schema
    DocSpecSchema? schema;
    if (effectiveSchemaId != null) {
      schema = SchemaResolver.resolveSync(
        schemaId: effectiveSchemaId,
        documentPath: absolutePath,
        workspaceRoot: wsRoot,
      );
    }

    // Create factory with schema
    final factory = DocSpecsFactory(schema: schema);

    // Scan document using DocScanner
    final doc = DocScanner.scanDocumentSync(
      filepath: absolutePath,
      workspaceRoot: wsRoot,
      factory: factory,
    );

    // Cast to SpecDoc and validate
    final specDoc = doc as SpecDoc;

    if (schema != null) {
      final validator = DocSpecsValidator(schema: schema);
      final errors = validator.validate(specDoc);
      specDoc.validationErrors.addAll(errors.map((e) => e.toString()));
    }

    return specDoc;
  }

  /// Load and validate multiple documents (async).
  static Future<List<SpecDoc>> scanDocuments({
    required List<String> filePaths,
    String? workspaceRoot,
  }) async {
    final results = <SpecDoc>[];
    for (final filePath in filePaths) {
      results.add(await scanDocument(
        filePath: filePath,
        workspaceRoot: workspaceRoot,
      ));
    }
    return results;
  }

  /// Load and validate multiple documents (sync).
  static List<SpecDoc> scanDocumentsSync({
    required List<String> filePaths,
    String? workspaceRoot,
  }) {
    final results = <SpecDoc>[];
    for (final filePath in filePaths) {
      results.add(scanDocumentSync(
        filePath: filePath,
        workspaceRoot: workspaceRoot,
      ));
    }
    return results;
  }

  /// Scan a directory tree (async).
  ///
  /// Returns a [DocumentFolder] with [SpecDoc] instances.
  static Future<DocumentFolder> scanTree({
    required String dirPath,
    String? workspaceRoot,
  }) async {
    // Note: DocScanner.scanTree creates Documents, not SpecDocs
    // We need to re-scan each .docspec.md file with our factory
    final absolutePath = _toAbsolutePath(dirPath);
    final wsRoot = workspaceRoot ?? Directory.current.path;

    return DocScanner.scanTree(
      path: absolutePath,
      workspaceRoot: wsRoot,
    );
  }

  /// Scan a directory tree (sync).
  static DocumentFolder scanTreeSync({
    required String dirPath,
    String? workspaceRoot,
  }) {
    final absolutePath = _toAbsolutePath(dirPath);
    final wsRoot = workspaceRoot ?? Directory.current.path;

    return DocScanner.scanTreeSync(
      path: absolutePath,
      workspaceRoot: wsRoot,
    );
  }

  /// Load a schema definition by ID.
  ///
  /// The [schemaId] can be:
  /// - Full ID with version: `quest-overview-1.0`
  /// - ID with version separator: `quest-overview/1.0`
  static Future<DocSpecSchema> loadSchema({
    required String schemaId,
    String? documentPath,
    String? workspaceRoot,
  }) async {
    final schema = await SchemaResolver.resolve(
      schemaId: schemaId,
      documentPath: documentPath,
      workspaceRoot: workspaceRoot,
    );

    if (schema == null) {
      throw ArgumentError('Schema not found: $schemaId');
    }

    return schema;
  }

  /// Load a schema definition synchronously.
  static DocSpecSchema loadSchemaSync({
    required String schemaId,
    String? documentPath,
    String? workspaceRoot,
  }) {
    final schema = SchemaResolver.resolveSync(
      schemaId: schemaId,
      documentPath: documentPath,
      workspaceRoot: workspaceRoot,
    );

    if (schema == null) {
      throw ArgumentError('Schema not found: $schemaId');
    }

    return schema;
  }

  /// Validate a document against its declared schema.
  ///
  /// Returns a list of validation error messages.
  static List<String> validate(SpecDoc doc, {DocSpecSchema? schema}) {
    if (schema == null) {
      return ['No schema provided for validation'];
    }

    final validator = DocSpecsValidator(schema: schema);
    final errors = validator.validate(doc);
    return errors.map((e) => e.toString()).toList();
  }

  /// List all available schemas from all locations.
  static Future<List<SchemaInfo>> listSchemas({
    String? documentPath,
    String? workspaceRoot,
  }) {
    return SchemaDiscovery.listSchemas(
      documentPath: documentPath,
      workspaceRoot: workspaceRoot,
    );
  }

  /// List schemas synchronously.
  static List<SchemaInfo> listSchemasSync({
    String? documentPath,
    String? workspaceRoot,
  }) {
    return SchemaDiscovery.listSchemasSync(
      documentPath: documentPath,
      workspaceRoot: workspaceRoot,
    );
  }

  /// List schemas from a specific location only.
  static Future<List<SchemaInfo>> listSchemasIn({required String dirPath}) {
    return SchemaDiscovery.listSchemasIn(dirPath);
  }

  /// List schemas from a specific location synchronously.
  static List<SchemaInfo> listSchemasInSync({required String dirPath}) {
    return SchemaDiscovery.listSchemasInSync(dirPath);
  }

  /// Converts a path to absolute if relative.
  static String _toAbsolutePath(String filePath) {
    if (path.isAbsolute(filePath)) return filePath;
    return path.join(Directory.current.path, filePath);
  }

  /// Extracts schema ID from document's first headline (async).
  static Future<String?> _extractSchemaId(String filePath) async {
    final file = File(filePath);
    final lines = await file.readAsLines();
    return _parseSchemaIdFromLines(lines);
  }

  /// Extracts schema ID from document's first headline (sync).
  static String? _extractSchemaIdSync(String filePath) {
    final file = File(filePath);
    final lines = file.readAsLinesSync();
    return _parseSchemaIdFromLines(lines);
  }

  /// Parses schema ID from document lines.
  static String? _parseSchemaIdFromLines(List<String> lines) {
    // Find first headline
    for (final line in lines) {
      if (line.startsWith('#')) {
        // Look for schema field: <!-- schema=xxx -->
        final schemaPattern = RegExp(r'schema\s*=\s*([^\s>]+)');
        final match = schemaPattern.firstMatch(line);
        if (match != null) {
          return match.group(1);
        }
        // Only check first headline
        return null;
      }
    }
    return null;
  }
}
