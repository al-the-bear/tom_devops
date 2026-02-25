import 'package:test/test.dart';
import 'package:tom_build/src/doc_scanner/models/section.dart';

void main() {
  group('Section', () {
    test('creates section with all fields', () {
      const section = Section(
        index: 0,
        lineNumber: 1,
        name: 'Test Section',
        id: 'test_section',
        rawHeadline: '# Test Section',
        fields: {},
        text: 'Some content',
        sections: null,
      );

      expect(section.index, equals(0));
      expect(section.lineNumber, equals(1));
      expect(section.name, equals('Test Section'));
      expect(section.id, equals('test_section'));
      expect(section.rawHeadline, equals('# Test Section'));
      expect(section.fields, isEmpty);
      expect(section.text, equals('Some content'));
      expect(section.sections, isNull);
    });

    test('creates section with nested sections', () {
      const child = Section(
        index: 0,
        lineNumber: 3,
        name: 'Child',
        id: 'child',
        rawHeadline: '## Child',
        fields: {},
        text: '',
      );

      const parent = Section(
        index: 0,
        lineNumber: 1,
        name: 'Parent',
        id: 'parent',
        rawHeadline: '# Parent',
        fields: {},
        text: 'Parent content',
        sections: [child],
      );

      expect(parent.sections, isNotNull);
      expect(parent.sections!.length, equals(1));
      expect(parent.sections!.first.name, equals('Child'));
    });

    test('creates section with metadata fields', () {
      const section = Section(
        index: 0,
        lineNumber: 1,
        name: 'Test Section',
        id: 'test_section',
        rawHeadline: '# Test Section <!-- [test_section] type=guide version=1.0 -->',
        fields: {'type': 'guide', 'version': '1.0'},
        text: 'Some content',
      );

      expect(section.fields['type'], equals('guide'));
      expect(section.fields['version'], equals('1.0'));
    });

    group('JSON serialization', () {
      test('toJson converts section to map', () {
        const section = Section(
          index: 1,
          lineNumber: 5,
          name: 'My Section',
          id: 'my_section',
          rawHeadline: '## My Section',
          fields: {'key': 'value'},
          text: 'Content here',
        );

        final json = section.toJson();

        expect(json['index'], equals(1));
        expect(json['lineNumber'], equals(5));
        expect(json['name'], equals('My Section'));
        expect(json['id'], equals('my_section'));
        expect(json['rawHeadline'], equals('## My Section'));
        expect(json['fields'], equals({'key': 'value'}));
        expect(json['text'], equals('Content here'));
        expect(json.containsKey('sections'), isFalse);
      });

      test('toJson includes sections when present', () {
        const section = Section(
          index: 0,
          lineNumber: 1,
          name: 'Parent',
          id: 'parent',
          rawHeadline: '# Parent',
          fields: {},
          text: '',
          sections: [
            Section(
              index: 0,
              lineNumber: 2,
              name: 'Child',
              id: 'child',
              rawHeadline: '## Child',
              fields: {},
              text: 'Child content',
            ),
          ],
        );

        final json = section.toJson();

        expect(json.containsKey('sections'), isTrue);
        expect(json['sections'], isList);
        expect((json['sections'] as List).length, equals(1));
      });

      test('fromJson creates section from map', () {
        final json = {
          'index': 2,
          'lineNumber': 10,
          'name': 'From JSON',
          'id': 'from_json',
          'rawHeadline': '## From JSON',
          'fields': {'meta': 'data'},
          'text': 'Loaded content',
        };

        final section = Section.fromJson(json);

        expect(section.index, equals(2));
        expect(section.lineNumber, equals(10));
        expect(section.name, equals('From JSON'));
        expect(section.id, equals('from_json'));
        expect(section.rawHeadline, equals('## From JSON'));
        expect(section.fields['meta'], equals('data'));
        expect(section.text, equals('Loaded content'));
        expect(section.sections, isNull);
      });

      test('fromJson handles nested sections', () {
        final json = {
          'index': 0,
          'lineNumber': 1,
          'name': 'Parent',
          'id': 'parent',
          'rawHeadline': '# Parent',
          'fields': <String, dynamic>{},
          'text': '',
          'sections': [
            {
              'index': 0,
              'lineNumber': 2,
              'name': 'Child',
              'id': 'child',
              'rawHeadline': '## Child',
              'fields': <String, dynamic>{},
              'text': 'Child text',
            },
          ],
        };

        final section = Section.fromJson(json);

        expect(section.sections, isNotNull);
        expect(section.sections!.length, equals(1));
        expect(section.sections!.first.name, equals('Child'));
      });

      test('fromJson handles missing rawHeadline and fields', () {
        final json = {
          'index': 0,
          'lineNumber': 1,
          'name': 'Legacy',
          'id': 'legacy',
          'text': 'Old format',
        };

        final section = Section.fromJson(json);

        expect(section.rawHeadline, equals(''));
        expect(section.fields, isEmpty);
      });

      test('roundtrip preserves data', () {
        const original = Section(
          index: 0,
          lineNumber: 1,
          name: 'Test',
          id: 'test',
          rawHeadline: '# Test <!-- [test] category=unit -->',
          fields: {'category': 'unit'},
          text: 'Content',
          sections: [
            Section(
              index: 0,
              lineNumber: 3,
              name: 'Sub',
              id: 'sub',
              rawHeadline: '## Sub',
              fields: {},
              text: 'Sub content',
            ),
          ],
        );

        final json = original.toJson();
        final restored = Section.fromJson(json);

        expect(restored.name, equals(original.name));
        expect(restored.id, equals(original.id));
        expect(restored.rawHeadline, equals(original.rawHeadline));
        expect(restored.fields, equals(original.fields));
        expect(restored.sections!.length, equals(original.sections!.length));
      });
    });
  });
}
