import 'document.dart';

/// A folder containing parsed documents and subfolders.
///
/// Represents a directory tree structure for organizing scanned documents.
/// Used by [DocScanner.scanTree] to return hierarchical results.
///
/// ## Example
///
/// ```dart
/// final folder = await DocScanner.scanTree(path: 'docs/');
/// print('Folder: ${folder.foldername}');
/// print('Documents: ${folder.documents.length}');
/// print('Subfolders: ${folder.folders.length}');
/// ```
class DocumentFolder {
  /// The name of this folder.
  final String foldername;

  /// Path relative to the workspace root.
  final String workspaceFolderPath;

  /// Absolute path to this folder.
  final String absoluteFolderPath;

  /// Documents directly in this folder.
  final List<Document> documents;

  /// Subfolders within this folder.
  final List<DocumentFolder> folders;

  /// Creates a new DocumentFolder.
  const DocumentFolder({
    required this.foldername,
    required this.workspaceFolderPath,
    required this.absoluteFolderPath,
    required this.documents,
    required this.folders,
  });

  /// Creates a DocumentFolder from a JSON map.
  factory DocumentFolder.fromJson(Map<String, dynamic> json) {
    return DocumentFolder(
      foldername: json['foldername'] as String,
      workspaceFolderPath: json['workspaceFolderPath'] as String,
      absoluteFolderPath: json['absoluteFolderPath'] as String,
      documents: (json['documents'] as List)
          .map((d) => Document.fromJson(d as Map<String, dynamic>))
          .toList(),
      folders: (json['folders'] as List)
          .map((f) => DocumentFolder.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts this folder to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'foldername': foldername,
      'workspaceFolderPath': workspaceFolderPath,
      'absoluteFolderPath': absoluteFolderPath,
      'documents': documents.map((d) => d.toJson()).toList(),
      'folders': folders.map((f) => f.toJson()).toList(),
    };
  }

  /// Returns all documents in this folder and all subfolders.
  List<Document> get allDocuments {
    final result = <Document>[...documents];
    for (final subfolder in folders) {
      result.addAll(subfolder.allDocuments);
    }
    return result;
  }

  @override
  String toString() =>
      'DocumentFolder(name: $foldername, documents: ${documents.length}, folders: ${folders.length})';
}
