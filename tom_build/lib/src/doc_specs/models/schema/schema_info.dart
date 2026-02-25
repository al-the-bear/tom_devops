/// Source location type for schemas.
enum SchemaSource {
  /// Schema found in local `.docspec-schemas/` folder.
  local,

  /// Schema found in user's `~/.tom/docspec-schemas/` folder.
  user,

  /// Built-in schema shipped with the package.
  builtin,
}

/// Summary information about an available schema.
class SchemaInfo {
  /// Schema identifier (e.g., "quest-overview").
  final String id;

  /// Schema version (e.g., "1.0").
  final String version;

  /// Path to the schema file.
  final String path;

  /// Source location type.
  final SchemaSource source;

  /// Creates a new SchemaInfo.
  const SchemaInfo({
    required this.id,
    required this.version,
    required this.path,
    required this.source,
  });

  /// Full schema ID with version (e.g., "quest-overview/1.0").
  String get fullId => '$id/$version';

  /// Schema ID with version in filename format (e.g., "quest-overview-1.0").
  String get filenameId => '$id-$version';

  @override
  String toString() => 'SchemaInfo($fullId, source: $source)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemaInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          version == other.version;

  @override
  int get hashCode => id.hashCode ^ version.hashCode;
}
