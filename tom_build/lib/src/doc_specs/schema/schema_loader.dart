import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import '../models/schema/doc_spec_schema.dart';
import '../models/schema/schema_info.dart';

/// Parses schema filenames to extract id and version.
///
/// Schema files must follow the naming convention:
/// `<schema-name>-<major>.<minor>.docspec-schema.yaml`
class SchemaFilenameParser {
  /// Regex pattern for schema filenames.
  static final _filenamePattern = RegExp(
    r'^(.+)-(\d+\.\d+)\.docspec-schema\.ya?ml$',
  );

  /// Parses a schema filename and returns the id and version.
  ///
  /// Returns null if the filename doesn't match the expected pattern.
  static ({String id, String version})? parse(String filename) {
    final match = _filenamePattern.firstMatch(filename);
    if (match == null) return null;

    return (
      id: match.group(1)!,
      version: match.group(2)!,
    );
  }
}

/// Loads DocSpec schemas from YAML files.
class SchemaLoader {
  /// Loads a schema from a file path.
  ///
  /// The schema id and version are extracted from the filename.
  static Future<DocSpecSchema> load(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw ArgumentError('Schema file not found: $filePath');
    }

    final content = await file.readAsString();
    return _parseSchema(content, filePath);
  }

  /// Loads a schema from a file path synchronously.
  static DocSpecSchema loadSync(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw ArgumentError('Schema file not found: $filePath');
    }

    final content = file.readAsStringSync();
    return _parseSchema(content, filePath);
  }

  /// Parses schema content and extracts metadata from filename.
  static DocSpecSchema _parseSchema(String content, String filePath) {
    final filename = path.basename(filePath);
    final parsed = SchemaFilenameParser.parse(filename);

    if (parsed == null) {
      throw ArgumentError(
        'Invalid schema filename: $filename. '
        'Expected format: <name>-<major>.<minor>.docspec-schema.yaml',
      );
    }

    final yaml = loadYaml(content) as Map;
    final yamlMap = Map<String, dynamic>.from(yaml);

    return DocSpecSchema.fromYaml(
      yamlMap,
      id: parsed.id,
      version: parsed.version,
    );
  }
}

/// Resolves schemas from multiple locations.
class SchemaResolver {
  /// Standard schema file extension patterns.
  static const schemaExtensions = [
    '.docspec-schema.yaml',
    '.docspec-schema.yml',
  ];

  /// Resolves a schema by ID.
  ///
  /// Search order:
  /// 1. Local `.docspec-schemas/` folders (walk up from [documentPath])
  /// 2. User schemas in `~/.tom/docspec-schemas/`
  /// 3. Built-in schemas (placeholder)
  ///
  /// The [schemaId] can be:
  /// - Full ID with version: `quest-overview-1.0`
  /// - ID with version separator: `quest-overview/1.0`
  static Future<DocSpecSchema?> resolve({
    required String schemaId,
    String? documentPath,
    String? workspaceRoot,
  }) async {
    final normalized = _normalizeSchemaId(schemaId);

    // Search local folders
    if (documentPath != null) {
      final localSchema = await _searchLocalFolders(
        normalized,
        documentPath,
        workspaceRoot,
      );
      if (localSchema != null) return localSchema;
    }

    // Search user folder
    final userSchema = await _searchUserFolder(normalized);
    if (userSchema != null) return userSchema;

    // Built-in schemas (placeholder)
    return null;
  }

  /// Resolves a schema synchronously.
  static DocSpecSchema? resolveSync({
    required String schemaId,
    String? documentPath,
    String? workspaceRoot,
  }) {
    final normalized = _normalizeSchemaId(schemaId);

    // Search local folders
    if (documentPath != null) {
      final localSchema = _searchLocalFoldersSync(
        normalized,
        documentPath,
        workspaceRoot,
      );
      if (localSchema != null) return localSchema;
    }

    // Search user folder
    final userSchema = _searchUserFolderSync(normalized);
    if (userSchema != null) return userSchema;

    // Built-in schemas (placeholder)
    return null;
  }

  /// Normalizes schema ID to filename format (e.g., "quest-overview-1.0").
  static String _normalizeSchemaId(String schemaId) {
    // Convert "id/version" to "id-version"
    return schemaId.replaceAll('/', '-');
  }

  /// Searches local `.docspec-schemas/` folders walking up from document path.
  static Future<DocSpecSchema?> _searchLocalFolders(
    String schemaId,
    String documentPath,
    String? workspaceRoot,
  ) async {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaPath = await _findSchemaInFolder(
        path.join(currentDir, '.docspec-schemas'),
        schemaId,
      );
      if (schemaPath != null) {
        return SchemaLoader.load(schemaPath);
      }

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }

    return null;
  }

  /// Searches local folders synchronously.
  static DocSpecSchema? _searchLocalFoldersSync(
    String schemaId,
    String documentPath,
    String? workspaceRoot,
  ) {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaPath = _findSchemaInFolderSync(
        path.join(currentDir, '.docspec-schemas'),
        schemaId,
      );
      if (schemaPath != null) {
        return SchemaLoader.loadSync(schemaPath);
      }

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }

    return null;
  }

  /// Searches the user schema folder.
  static Future<DocSpecSchema?> _searchUserFolder(String schemaId) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return null;

    final userSchemaDir = path.join(home, '.tom', 'docspec-schemas');
    final schemaPath = await _findSchemaInFolder(userSchemaDir, schemaId);
    if (schemaPath != null) {
      return SchemaLoader.load(schemaPath);
    }

    return null;
  }

  /// Searches user folder synchronously.
  static DocSpecSchema? _searchUserFolderSync(String schemaId) {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return null;

    final userSchemaDir = path.join(home, '.tom', 'docspec-schemas');
    final schemaPath = _findSchemaInFolderSync(userSchemaDir, schemaId);
    if (schemaPath != null) {
      return SchemaLoader.loadSync(schemaPath);
    }

    return null;
  }

  /// Finds a schema file in a folder (checks both direct and subfolder).
  static Future<String?> _findSchemaInFolder(
    String folderPath,
    String schemaId,
  ) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return null;

    // Extract schema name (without version) for subfolder check
    final parts = schemaId.split('-');
    final versionIdx = parts.lastIndexWhere(
      (p) => RegExp(r'^\d+\.\d+$').hasMatch(p),
    );
    final schemaName = versionIdx > 0 ? parts.sublist(0, versionIdx).join('-') : schemaId;

    // Check in subfolder first (e.g., .docspec-schemas/quest-overview/)
    for (final ext in schemaExtensions) {
      final subfolderPath = path.join(folderPath, schemaName, '$schemaId$ext');
      if (await File(subfolderPath).exists()) {
        return subfolderPath;
      }
    }

    // Check directly in folder
    for (final ext in schemaExtensions) {
      final directPath = path.join(folderPath, '$schemaId$ext');
      if (await File(directPath).exists()) {
        return directPath;
      }
    }

    return null;
  }

  /// Finds schema file synchronously.
  static String? _findSchemaInFolderSync(
    String folderPath,
    String schemaId,
  ) {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return null;

    // Extract schema name (without version) for subfolder check
    final parts = schemaId.split('-');
    final versionIdx = parts.lastIndexWhere(
      (p) => RegExp(r'^\d+\.\d+$').hasMatch(p),
    );
    final schemaName = versionIdx > 0 ? parts.sublist(0, versionIdx).join('-') : schemaId;

    // Check in subfolder first
    for (final ext in schemaExtensions) {
      final subfolderPath = path.join(folderPath, schemaName, '$schemaId$ext');
      if (File(subfolderPath).existsSync()) {
        return subfolderPath;
      }
    }

    // Check directly in folder
    for (final ext in schemaExtensions) {
      final directPath = path.join(folderPath, '$schemaId$ext');
      if (File(directPath).existsSync()) {
        return directPath;
      }
    }

    return null;
  }
}

/// Discovers available schemas across all locations.
class SchemaDiscovery {
  /// Lists all available schemas from all locations.
  ///
  /// Returns schemas in priority order (local > user > builtin).
  /// Duplicates are removed, keeping the highest priority version.
  static Future<List<SchemaInfo>> listSchemas({
    String? documentPath,
    String? workspaceRoot,
  }) async {
    final schemas = <String, SchemaInfo>{}; // fullId -> info

    // Search local folders
    if (documentPath != null) {
      await _discoverLocalSchemas(
        schemas,
        documentPath,
        workspaceRoot,
      );
    }

    // Search user folder
    await _discoverUserSchemas(schemas);

    // Built-in schemas (placeholder)

    return schemas.values.toList();
  }

  /// Lists schemas synchronously.
  static List<SchemaInfo> listSchemasSync({
    String? documentPath,
    String? workspaceRoot,
  }) {
    final schemas = <String, SchemaInfo>{};

    if (documentPath != null) {
      _discoverLocalSchemasSync(schemas, documentPath, workspaceRoot);
    }

    _discoverUserSchemasSync(schemas);

    return schemas.values.toList();
  }

  /// Lists schemas from a specific folder.
  static Future<List<SchemaInfo>> listSchemasIn(String folderPath) async {
    final schemas = <SchemaInfo>[];
    await _discoverInFolder(schemas, folderPath, SchemaSource.local);
    return schemas;
  }

  /// Lists schemas from a specific folder synchronously.
  static List<SchemaInfo> listSchemasInSync(String folderPath) {
    final schemas = <SchemaInfo>[];
    _discoverInFolderSync(schemas, folderPath, SchemaSource.local);
    return schemas;
  }

  static Future<void> _discoverLocalSchemas(
    Map<String, SchemaInfo> schemas,
    String documentPath,
    String? workspaceRoot,
  ) async {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaDir = path.join(currentDir, '.docspec-schemas');
      final temp = <SchemaInfo>[];
      await _discoverInFolder(temp, schemaDir, SchemaSource.local);

      for (final info in temp) {
        schemas.putIfAbsent(info.fullId, () => info);
      }

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }
  }

  static void _discoverLocalSchemasSync(
    Map<String, SchemaInfo> schemas,
    String documentPath,
    String? workspaceRoot,
  ) {
    var currentDir = path.dirname(documentPath);
    final stopAt = workspaceRoot ?? path.rootPrefix(documentPath);

    while (currentDir.length >= stopAt.length) {
      final schemaDir = path.join(currentDir, '.docspec-schemas');
      final temp = <SchemaInfo>[];
      _discoverInFolderSync(temp, schemaDir, SchemaSource.local);

      for (final info in temp) {
        schemas.putIfAbsent(info.fullId, () => info);
      }

      final parent = path.dirname(currentDir);
      if (parent == currentDir) break;
      currentDir = parent;
    }
  }

  static Future<void> _discoverUserSchemas(
    Map<String, SchemaInfo> schemas,
  ) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return;

    final userSchemaDir = path.join(home, '.tom', 'docspec-schemas');
    final temp = <SchemaInfo>[];
    await _discoverInFolder(temp, userSchemaDir, SchemaSource.user);

    for (final info in temp) {
      schemas.putIfAbsent(info.fullId, () => info);
    }
  }

  static void _discoverUserSchemasSync(Map<String, SchemaInfo> schemas) {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return;

    final userSchemaDir = path.join(home, '.tom', 'docspec-schemas');
    final temp = <SchemaInfo>[];
    _discoverInFolderSync(temp, userSchemaDir, SchemaSource.user);

    for (final info in temp) {
      schemas.putIfAbsent(info.fullId, () => info);
    }
  }

  static Future<void> _discoverInFolder(
    List<SchemaInfo> schemas,
    String folderPath,
    SchemaSource source,
  ) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) return;

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final filename = path.basename(entity.path);
        final parsed = SchemaFilenameParser.parse(filename);
        if (parsed != null) {
          schemas.add(SchemaInfo(
            id: parsed.id,
            version: parsed.version,
            path: entity.path,
            source: source,
          ));
        }
      }
    }
  }

  static void _discoverInFolderSync(
    List<SchemaInfo> schemas,
    String folderPath,
    SchemaSource source,
  ) {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        final filename = path.basename(entity.path);
        final parsed = SchemaFilenameParser.parse(filename);
        if (parsed != null) {
          schemas.add(SchemaInfo(
            id: parsed.id,
            version: parsed.version,
            path: entity.path,
            source: source,
          ));
        }
      }
    }
  }
}
