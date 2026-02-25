import 'package:test/test.dart';
import 'package:tom_build/src/doc_scanner/models/document.dart';
import 'package:tom_build/src/doc_scanner/models/section.dart';

void main() {
  group('Document', () {
    test('creates document with all fields', () {
      const doc = Document(
        index: 0,
        lineNumber: 1,
        name: 'Test Document',
        id: 'test_document',
        rawHeadline: '# Test Document',
        fields: {},
        text: 'Document content',
        filenameWithPath: '/path/to/doc.md',
        loadTimestamp: '2026-01-14T10:00:00.000Z',
        filename: 'doc.md',
        fullPath: '/path/to',
        workspacePath: 'project/doc.md',
        project: 'project',
        projectPath: 'doc.md',
        workspaceRoot: '/workspace',
        projectRoot: '/workspace/project',
        hierarchyDepth: 2,
      );

      expect(doc.name, equals('Test Document'));
      expect(doc.filename, equals('doc.md'));
      expect(doc.project, equals('project'));
      expect(doc.hierarchyDepth, equals(2));
      expect(doc.rawHeadline, equals('# Test Document'));
      expect(doc.fields, isEmpty);
    });

    test('inherits from Section', () {
      const doc = Document(
        index: 0,
        lineNumber: 1,
        name: 'Test',
        id: 'test',
        rawHeadline: '# Test',
        fields: {},
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

      expect(doc, isA<Section>());
      expect(doc.index, equals(0));
      expect(doc.lineNumber, equals(1));
    });

    test('creates document with metadata fields', () {
      const doc = Document(
        index: 0,
        lineNumber: 1,
        name: 'Test',
        id: 'test',
        rawHeadline: '# Test <!-- [test] type=guide version=2.0 -->',
        fields: {'type': 'guide', 'version': '2.0'},
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

      expect(doc.fields['type'], equals('guide'));
      expect(doc.fields['version'], equals('2.0'));
    });

    group('JSON serialization', () {
      test('toJson includes all Document fields', () {
        const doc = Document(
          index: 0,
          lineNumber: 1,
          name: 'Test',
          id: 'test',
          rawHeadline: '# Test',
          fields: {'key': 'value'},
          text: 'Content',
          filenameWithPath: '/path/doc.md',
          loadTimestamp: '2026-01-14T10:00:00.000Z',
          filename: 'doc.md',
          fullPath: '/path',
          workspacePath: 'project/doc.md',
          project: 'project',
          projectPath: 'doc.md',
          workspaceRoot: '/workspace',
          projectRoot: '/workspace/project',
          hierarchyDepth: 3,
        );

        final json = doc.toJson();

        // Section fields
        expect(json['index'], equals(0));
        expect(json['name'], equals('Test'));
        expect(json['id'], equals('test'));
        expect(json['rawHeadline'], equals('# Test'));
        expect(json['fields'], equals({'key': 'value'}));
        expect(json['text'], equals('Content'));

        // Document fields
        expect(json['filenameWithPath'], equals('/path/doc.md'));
        expect(json['loadTimestamp'], equals('2026-01-14T10:00:00.000Z'));
        expect(json['filename'], equals('doc.md'));
        expect(json['fullPath'], equals('/path'));
        expect(json['workspacePath'], equals('project/doc.md'));
        expect(json['project'], equals('project'));
        expect(json['projectPath'], equals('doc.md'));
        expect(json['workspaceRoot'], equals('/workspace'));
        expect(json['projectRoot'], equals('/workspace/project'));
        expect(json['hierarchyDepth'], equals(3));
      });

      test('fromJson creates Document from map', () {
        final json = {
          'index': 0,
          'lineNumber': 1,
          'name': 'Loaded',
          'id': 'loaded',
          'rawHeadline': '# Loaded',
          'fields': {'meta': 'data'},
          'text': 'Loaded content',
          'filenameWithPath': '/loaded.md',
          'loadTimestamp': '2026-01-14T12:00:00.000Z',
          'filename': 'loaded.md',
          'fullPath': '/',
          'workspacePath': 'loaded.md',
          'project': 'test',
          'projectPath': 'loaded.md',
          'workspaceRoot': '/ws',
          'projectRoot': '/ws/test',
          'hierarchyDepth': 1,
        };

        final doc = Document.fromJson(json);

        expect(doc.name, equals('Loaded'));
        expect(doc.filename, equals('loaded.md'));
        expect(doc.project, equals('test'));
        expect(doc.hierarchyDepth, equals(1));
        expect(doc.rawHeadline, equals('# Loaded'));
        expect(doc.fields['meta'], equals('data'));
      });

      test('fromJson handles sections', () {
        final json = {
          'index': 0,
          'lineNumber': 1,
          'name': 'Doc',
          'id': 'doc',
          'rawHeadline': '# Doc',
          'fields': <String, dynamic>{},
          'text': '',
          'sections': [
            {
              'index': 0,
              'lineNumber': 3,
              'name': 'Section',
              'id': 'section',
              'rawHeadline': '## Section',
              'fields': <String, dynamic>{},
              'text': 'Section text',
            },
          ],
          'filenameWithPath': '/doc.md',
          'loadTimestamp': '2026-01-14T10:00:00.000Z',
          'filename': 'doc.md',
          'fullPath': '/',
          'workspacePath': 'doc.md',
          'project': '',
          'projectPath': 'doc.md',
          'workspaceRoot': '/',
          'projectRoot': '/',
          'hierarchyDepth': 2,
        };

        final doc = Document.fromJson(json);

        expect(doc.sections, isNotNull);
        expect(doc.sections!.length, equals(1));
        expect(doc.sections!.first.name, equals('Section'));
      });

      test('fromJson handles missing rawHeadline and fields', () {
        final json = {
          'index': 0,
          'lineNumber': 1,
          'name': 'Legacy',
          'id': 'legacy',
          'text': 'Old format',
          'filenameWithPath': '/legacy.md',
          'loadTimestamp': '2026-01-14T10:00:00.000Z',
          'filename': 'legacy.md',
          'fullPath': '/',
          'workspacePath': 'legacy.md',
          'project': '',
          'projectPath': 'legacy.md',
          'workspaceRoot': '/',
          'projectRoot': '/',
          'hierarchyDepth': 1,
        };

        final doc = Document.fromJson(json);

        expect(doc.rawHeadline, equals(''));
        expect(doc.fields, isEmpty);
      });

      test('roundtrip preserves data', () {
        const original = Document(
          index: 0,
          lineNumber: 1,
          name: 'Original',
          id: 'original',
          rawHeadline: '# Original <!-- [original] type=test -->',
          fields: {'type': 'test'},
          text: 'Content',
          filenameWithPath: '/path/original.md',
          loadTimestamp: '2026-01-14T10:00:00.000Z',
          filename: 'original.md',
          fullPath: '/path',
          workspacePath: 'proj/original.md',
          project: 'proj',
          projectPath: 'original.md',
          workspaceRoot: '/workspace',
          projectRoot: '/workspace/proj',
          hierarchyDepth: 2,
          sections: [
            Section(
              index: 0,
              lineNumber: 3,
              name: 'Child',
              id: 'child',
              rawHeadline: '## Child',
              fields: {},
              text: 'Child text',
            ),
          ],
        );

        final json = original.toJson();
        final restored = Document.fromJson(json);

        expect(restored.name, equals(original.name));
        expect(restored.filename, equals(original.filename));
        expect(restored.project, equals(original.project));
        expect(restored.hierarchyDepth, equals(original.hierarchyDepth));
        expect(restored.rawHeadline, equals(original.rawHeadline));
        expect(restored.fields, equals(original.fields));
        expect(restored.sections!.length, equals(original.sections!.length));
      });
    });
  });
}
