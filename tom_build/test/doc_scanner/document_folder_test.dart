import 'package:test/test.dart';
import 'package:tom_build/src/doc_scanner/models/document.dart';
import 'package:tom_build/src/doc_scanner/models/document_folder.dart';

void main() {
  group('DocumentFolder', () {
    test('creates folder with all fields', () {
      const folder = DocumentFolder(
        foldername: 'docs',
        workspaceFolderPath: 'project/docs',
        absoluteFolderPath: '/workspace/project/docs',
        documents: [],
        folders: [],
      );

      expect(folder.foldername, equals('docs'));
      expect(folder.workspaceFolderPath, equals('project/docs'));
      expect(folder.absoluteFolderPath, equals('/workspace/project/docs'));
      expect(folder.documents, isEmpty);
      expect(folder.folders, isEmpty);
    });

    test('allDocuments returns documents from current folder', () {
      final doc = Document(
        index: 0,
        lineNumber: 1,
        name: 'Test',
        id: 'test',
        rawHeadline: '# Test',
        fields: const {},
        text: '',
        filenameWithPath: '/test.md',
        loadTimestamp: '2026-01-14T10:00:00.000Z',
        filename: 'test.md',
        fullPath: '/',
        workspacePath: 'test.md',
        project: '',
        projectPath: 'test.md',
        workspaceRoot: '/',
        projectRoot: '/',
        hierarchyDepth: 1,
      );

      final folder = DocumentFolder(
        foldername: 'root',
        workspaceFolderPath: '',
        absoluteFolderPath: '/',
        documents: [doc],
        folders: [],
      );

      expect(folder.allDocuments.length, equals(1));
    });

    test('allDocuments includes documents from subfolders', () {
      final doc1 = Document(
        index: 0,
        lineNumber: 1,
        name: 'Root Doc',
        id: 'root_doc',
        rawHeadline: '# Root Doc',
        fields: const {},
        text: '',
        filenameWithPath: '/root.md',
        loadTimestamp: '2026-01-14T10:00:00.000Z',
        filename: 'root.md',
        fullPath: '/',
        workspacePath: 'root.md',
        project: '',
        projectPath: 'root.md',
        workspaceRoot: '/',
        projectRoot: '/',
        hierarchyDepth: 1,
      );

      final doc2 = Document(
        index: 0,
        lineNumber: 1,
        name: 'Sub Doc',
        id: 'sub_doc',
        rawHeadline: '# Sub Doc',
        fields: const {},
        text: '',
        filenameWithPath: '/sub/doc.md',
        loadTimestamp: '2026-01-14T10:00:00.000Z',
        filename: 'doc.md',
        fullPath: '/sub',
        workspacePath: 'sub/doc.md',
        project: '',
        projectPath: 'sub/doc.md',
        workspaceRoot: '/',
        projectRoot: '/',
        hierarchyDepth: 1,
      );

      final subfolder = DocumentFolder(
        foldername: 'sub',
        workspaceFolderPath: 'sub',
        absoluteFolderPath: '/sub',
        documents: [doc2],
        folders: [],
      );

      final root = DocumentFolder(
        foldername: 'root',
        workspaceFolderPath: '',
        absoluteFolderPath: '/',
        documents: [doc1],
        folders: [subfolder],
      );

      final allDocs = root.allDocuments;
      expect(allDocs.length, equals(2));
      expect(allDocs.map((d) => d.filename), containsAll(['root.md', 'doc.md']));
    });

    group('JSON serialization', () {
      test('toJson converts folder to map', () {
        const folder = DocumentFolder(
          foldername: 'docs',
          workspaceFolderPath: 'project/docs',
          absoluteFolderPath: '/ws/project/docs',
          documents: [],
          folders: [],
        );

        final json = folder.toJson();

        expect(json['foldername'], equals('docs'));
        expect(json['workspaceFolderPath'], equals('project/docs'));
        expect(json['absoluteFolderPath'], equals('/ws/project/docs'));
        expect(json['documents'], isEmpty);
        expect(json['folders'], isEmpty);
      });

      test('fromJson creates folder from map', () {
        final json = {
          'foldername': 'loaded',
          'workspaceFolderPath': 'path/loaded',
          'absoluteFolderPath': '/abs/path/loaded',
          'documents': <Map<String, dynamic>>[],
          'folders': <Map<String, dynamic>>[],
        };

        final folder = DocumentFolder.fromJson(json);

        expect(folder.foldername, equals('loaded'));
        expect(folder.workspaceFolderPath, equals('path/loaded'));
        expect(folder.absoluteFolderPath, equals('/abs/path/loaded'));
      });

      test('roundtrip preserves nested structure', () {
        final doc = Document(
          index: 0,
          lineNumber: 1,
          name: 'Doc',
          id: 'doc',
          rawHeadline: '# Doc',
          fields: const {},
          text: 'Content',
          filenameWithPath: '/doc.md',
          loadTimestamp: '2026-01-14T10:00:00.000Z',
          filename: 'doc.md',
          fullPath: '/',
          workspacePath: 'doc.md',
          project: '',
          projectPath: 'doc.md',
          workspaceRoot: '/',
          projectRoot: '/',
          hierarchyDepth: 1,
        );

        final subfolder = DocumentFolder(
          foldername: 'sub',
          workspaceFolderPath: 'sub',
          absoluteFolderPath: '/sub',
          documents: [],
          folders: [],
        );

        final original = DocumentFolder(
          foldername: 'root',
          workspaceFolderPath: '',
          absoluteFolderPath: '/',
          documents: [doc],
          folders: [subfolder],
        );

        final json = original.toJson();
        final restored = DocumentFolder.fromJson(json);

        expect(restored.foldername, equals(original.foldername));
        expect(restored.documents.length, equals(1));
        expect(restored.folders.length, equals(1));
        expect(restored.documents.first.name, equals('Doc'));
        expect(restored.folders.first.foldername, equals('sub'));
      });
    });
  });
}
