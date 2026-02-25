import 'section.dart';

/// A parsed markdown document with file location information.
///
/// Extends [Section] to represent the root of a document's section hierarchy
/// while also tracking file path information for workspace processing.
///
/// ## Example
///
/// ```dart
/// final doc = await DocScanner.scanDocument(filepath: 'docs/guide.md');
/// print('File: ${doc.filename}');
/// print('Project: ${doc.project}');
/// print('Depth: ${doc.hierarchyDepth}');
/// ```
class Document extends Section {
  /// Complete path to the file, including filename.
  final String filenameWithPath;

  /// ISO timestamp when the document was loaded.
  final String loadTimestamp;

  /// Just the filename without path.
  final String filename;

  /// Absolute directory where the file was loaded from.
  final String fullPath;

  /// Path relative to the workspace root.
  final String workspacePath;

  /// First folder in the workspace hierarchy (project name).
  final String project;

  /// Path relative to the project root.
  final String projectPath;

  /// Absolute path to the workspace root.
  final String workspaceRoot;

  /// Absolute path to the project folder.
  final String projectRoot;

  /// The deepest headline hierarchy level in the document.
  final int hierarchyDepth;

  /// Creates a new Document.
  const Document({
    required super.index,
    required super.lineNumber,
    required super.name,
    required super.id,
    required super.rawHeadline,
    required super.fields,
    required super.text,
    super.sections,
    required this.filenameWithPath,
    required this.loadTimestamp,
    required this.filename,
    required this.fullPath,
    required this.workspacePath,
    required this.project,
    required this.projectPath,
    required this.workspaceRoot,
    required this.projectRoot,
    required this.hierarchyDepth,
  });

  /// Creates a Document from a JSON map.
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      index: json['index'] as int,
      lineNumber: json['lineNumber'] as int,
      name: json['name'] as String,
      id: json['id'] as String,
      rawHeadline: (json['rawHeadline'] as String?) ?? '',
      fields: (json['fields'] as Map<String, dynamic>?)?.cast<String, String>() ?? const {},
      text: json['text'] as String,
      sections: json['sections'] != null
          ? (json['sections'] as List)
              .map((s) => Section.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      filenameWithPath: json['filenameWithPath'] as String,
      loadTimestamp: json['loadTimestamp'] as String,
      filename: json['filename'] as String,
      fullPath: json['fullPath'] as String,
      workspacePath: json['workspacePath'] as String,
      project: json['project'] as String,
      projectPath: json['projectPath'] as String,
      workspaceRoot: json['workspaceRoot'] as String,
      projectRoot: json['projectRoot'] as String,
      hierarchyDepth: json['hierarchyDepth'] as int,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'filenameWithPath': filenameWithPath,
      'loadTimestamp': loadTimestamp,
      'filename': filename,
      'fullPath': fullPath,
      'workspacePath': workspacePath,
      'project': project,
      'projectPath': projectPath,
      'workspaceRoot': workspaceRoot,
      'projectRoot': projectRoot,
      'hierarchyDepth': hierarchyDepth,
    };
  }

  @override
  String toString() =>
      'Document(filename: $filename, project: $project, depth: $hierarchyDepth)';
}
