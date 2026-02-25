import 'package:test/test.dart';
import 'package:tom_build/src/doc_scanner/doc_scanner_factory.dart';
import 'package:tom_build/src/doc_scanner/models/document.dart';
import 'package:tom_build/src/doc_scanner/models/section.dart';

void main() {
  group('DocScannerFactory', () {
    late DocScannerFactory factory;

    setUp(() {
      factory = const DocScannerFactory();
    });

    group('createSection', () {
      test('creates Section with all fields', () {
        final section = factory.createSection(
          index: 0,
          lineNumber: 1,
          rawHeadline: '## Test Section',
          name: 'Test Section',
          id: 'test_section',
          text: 'Some content',
          fields: {'key': 'value'},
          sections: null,
        );

        expect(section, isA<Section>());
        expect(section.index, equals(0));
        expect(section.lineNumber, equals(1));
        expect(section.rawHeadline, equals('## Test Section'));
        expect(section.name, equals('Test Section'));
        expect(section.id, equals('test_section'));
        expect(section.text, equals('Some content'));
        expect(section.fields['key'], equals('value'));
        expect(section.sections, isNull);
      });

      test('creates Section with nested sections', () {
        final child = factory.createSection(
          index: 0,
          lineNumber: 3,
          rawHeadline: '### Child',
          name: 'Child',
          id: 'child',
          text: '',
          fields: const {},
        );

        final parent = factory.createSection(
          index: 0,
          lineNumber: 1,
          rawHeadline: '## Parent',
          name: 'Parent',
          id: 'parent',
          text: 'Parent content',
          fields: const {},
          sections: [child],
        );

        expect(parent.sections, isNotNull);
        expect(parent.sections!.length, equals(1));
        expect(parent.sections!.first.name, equals('Child'));
      });
    });

    group('createDocument', () {
      test('creates Document with all fields', () {
        final doc = factory.createDocument(
          index: 0,
          lineNumber: 1,
          rawHeadline: '# Test Document',
          name: 'Test Document',
          id: 'test_document',
          text: 'Document content',
          fields: {'type': 'guide'},
          sections: null,
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

        expect(doc, isA<Document>());
        expect(doc.name, equals('Test Document'));
        expect(doc.id, equals('test_document'));
        expect(doc.filename, equals('doc.md'));
        expect(doc.project, equals('project'));
        expect(doc.hierarchyDepth, equals(2));
        expect(doc.fields['type'], equals('guide'));
      });

      test('creates Document with sections', () {
        final section = factory.createSection(
          index: 0,
          lineNumber: 3,
          rawHeadline: '## Section',
          name: 'Section',
          id: 'section',
          text: 'Section text',
          fields: const {},
        );

        final doc = factory.createDocument(
          index: 0,
          lineNumber: 1,
          rawHeadline: '# Doc',
          name: 'Doc',
          id: 'doc',
          text: '',
          fields: const {},
          sections: [section],
          filenameWithPath: '/doc.md',
          loadTimestamp: '2026-01-14T10:00:00.000Z',
          filename: 'doc.md',
          fullPath: '/',
          workspacePath: 'doc.md',
          project: '',
          projectPath: 'doc.md',
          workspaceRoot: '/',
          projectRoot: '/',
          hierarchyDepth: 2,
        );

        expect(doc.sections, isNotNull);
        expect(doc.sections!.length, equals(1));
        expect(doc.sections!.first.name, equals('Section'));
      });
    });

    group('custom factory', () {
      test('can extend factory to customize creation', () {
        final customFactory = _CustomFactory();

        final section = customFactory.createSection(
          index: 0,
          lineNumber: 1,
          rawHeadline: '## Test',
          name: 'Test',
          id: 'test',
          text: 'Content',
          fields: const {},
        );

        expect(section.name, equals('CUSTOM: Test'));
      });
    });
  });
}

/// Custom factory for testing extensibility.
class _CustomFactory extends DocScannerFactory {
  @override
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
    return super.createSection(
      index: index,
      lineNumber: lineNumber,
      rawHeadline: rawHeadline,
      name: 'CUSTOM: $name',
      id: id,
      text: text,
      fields: fields,
      sections: sections,
    );
  }
}
