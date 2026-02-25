import 'models/document.dart';
import 'models/section.dart';

/// Factory for creating [Document] and [Section] objects.
///
/// This factory encapsulates the creation of DocScanner model objects,
/// allowing users to customize object creation when using DocScanner
/// via package import.
///
/// ## Example
///
/// ```dart
/// // Using the default factory
/// final scanner = DocScanner();
///
/// // Using a custom factory
/// class MyDocScannerFactory extends DocScannerFactory {
///   @override
///   Section createSection({
///     required int index,
///     required int lineNumber,
///     required String rawHeadline,
///     required String name,
///     required String id,
///     required String text,
///     required Map<String, String> fields,
///     List<Section>? sections,
///   }) {
///     // Custom section creation logic
///     return super.createSection(
///       index: index,
///       lineNumber: lineNumber,
///       rawHeadline: rawHeadline,
///       name: name,
///       id: id,
///       text: text,
///       fields: fields,
///       sections: sections,
///     );
///   }
/// }
///
/// final scanner = DocScanner(factory: MyDocScannerFactory());
/// ```
class DocScannerFactory {
  /// Creates a new [DocScannerFactory].
  const DocScannerFactory();

  /// Creates a [Section] with the given parameters.
  Section createSection({
    required int index,
    required int lineNumber,
    required String rawHeadline,
    required String name,
    required String id,
    required String text,
    required Map<String, String> fields,
    List<Section>? sections,
  }) {
    return Section(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: text,
      fields: fields,
      sections: sections,
    );
  }

  /// Creates a [Document] with the given parameters.
  Document createDocument({
    required int index,
    required int lineNumber,
    required String rawHeadline,
    required String name,
    required String id,
    required String text,
    required Map<String, String> fields,
    List<Section>? sections,
    required String filenameWithPath,
    required String loadTimestamp,
    required String filename,
    required String fullPath,
    required String workspacePath,
    required String project,
    required String projectPath,
    required String workspaceRoot,
    required String projectRoot,
    required int hierarchyDepth,
  }) {
    return Document(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: name,
      id: id,
      text: text,
      fields: fields,
      sections: sections,
      filenameWithPath: filenameWithPath,
      loadTimestamp: loadTimestamp,
      filename: filename,
      fullPath: fullPath,
      workspacePath: workspacePath,
      project: project,
      projectPath: projectPath,
      workspaceRoot: workspaceRoot,
      projectRoot: projectRoot,
      hierarchyDepth: hierarchyDepth,
    );
  }
}
