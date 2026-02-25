import 'package:test/test.dart';
import 'package:tom_build/src/doc_scanner/markdown_parser.dart';

void main() {
  group('MarkdownParser', () {
    group('parseHeadlines', () {
      test('parses simple headline', () {
        const content = '# Hello World';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.length, equals(1));
        expect(headlines.first.$1.level, equals(1));
        expect(headlines.first.$1.text, equals('Hello World'));
        expect(headlines.first.$1.lineNumber, equals(1));
      });

      test('parses multiple headline levels', () {
        const content = '''
# Level 1
## Level 2
### Level 3
#### Level 4
##### Level 5
###### Level 6
''';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.length, equals(6));
        expect(headlines[0].$1.level, equals(1));
        expect(headlines[1].$1.level, equals(2));
        expect(headlines[2].$1.level, equals(3));
        expect(headlines[3].$1.level, equals(4));
        expect(headlines[4].$1.level, equals(5));
        expect(headlines[5].$1.level, equals(6));
      });

      test('extracts ID from square brackets', () {
        const content = '## [my_id] My Section';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.first.$1.explicitId, equals('my_id'));
        expect(headlines.first.$1.text, equals('My Section'));
      });

      test('extracts ID from HTML comment', () {
        const content = '## <!--[section_id]--> Section Title';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.first.$1.explicitId, equals('section_id'));
        expect(headlines.first.$1.text, equals('Section Title'));
      });

      test('handles headline without ID', () {
        const content = '## Just a Title';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.first.$1.explicitId, isNull);
        expect(headlines.first.$1.text, equals('Just a Title'));
      });

      test('tracks line numbers correctly', () {
        const content = '''
Some text

# First

More text

## Second
''';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.length, equals(2));
        expect(headlines[0].$1.lineNumber, equals(3));
        expect(headlines[1].$1.lineNumber, equals(7));
      });

      test('handles empty content', () {
        const content = '';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines, isEmpty);
      });

      test('ignores lines that are not headlines', () {
        const content = '''
Not a headline
#Not a headline either (no space)
# Valid Headline
''';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.length, equals(1));
        expect(headlines.first.$1.text, equals('Valid Headline'));
      });

      test('preserves rawHeadline with all original content', () {
        const content = '## [my_id] My Section Title';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.first.$1.rawHeadline, equals('## [my_id] My Section Title'));
        expect(headlines.first.$1.text, equals('My Section Title'));
      });

      test('rawHeadline preserves HTML comments', () {
        const content = '## <!--[section_id]--> Section Title';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.first.$1.rawHeadline, equals('## <!--[section_id]--> Section Title'));
      });

      test('parses key=value pairs from HTML comment', () {
        const content = '## Section Title <!-- [my_id] type=guide version=1.0 -->';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.first.$1.explicitId, equals('my_id'));
        expect(headlines.first.$1.fields['type'], equals('guide'));
        expect(headlines.first.$1.fields['version'], equals('1.0'));
        expect(headlines.first.$1.text, equals('Section Title'));
      });

      test('parses quoted values in key=value pairs', () {
        const content = '## Title <!-- [id] description="A longer description" -->';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.first.$1.fields['description'], equals('A longer description'));
      });

      test('parses key=value pairs from text after ID', () {
        const content = '## [my_id] type=api status=draft Section Name';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.first.$1.explicitId, equals('my_id'));
        expect(headlines.first.$1.fields['type'], equals('api'));
        expect(headlines.first.$1.fields['status'], equals('draft'));
        expect(headlines.first.$1.text, equals('Section Name'));
      });

      test('fields is empty when no metadata present', () {
        const content = '## Simple Headline';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines.first.$1.fields, isEmpty);
      });

      test('handles mixed ID formats with fields', () {
        const content = '''
# <!--[doc_id] type=main--> Document Title
## [section_1] priority=high First Section
### Regular Subsection
''';
        final headlines = MarkdownParser.parseHeadlines(content);

        expect(headlines[0].$1.explicitId, equals('doc_id'));
        expect(headlines[0].$1.fields['type'], equals('main'));
        expect(headlines[1].$1.explicitId, equals('section_1'));
        expect(headlines[1].$1.fields['priority'], equals('high'));
        expect(headlines[2].$1.fields, isEmpty);
      });
    });

    group('extractText', () {
      test('extracts text between headlines', () {
        const content = '''
# Title
This is the content.
More content here.
## Next Section
''';
        final text = MarkdownParser.extractText(content, 0, 2);

        expect(text, equals('This is the content.\nMore content here.'));
      });

      test('returns empty for no content', () {
        const content = '''
# Title
## Next
''';
        final text = MarkdownParser.extractText(content, 0, 0);

        expect(text, isEmpty);
      });

      test('handles end of file', () {
        const content = '''
# Title
Final content.
''';
        final text = MarkdownParser.extractText(content, 0, 2);

        expect(text, equals('Final content.'));
      });
    });

    group('generateId', () {
      test('lowercases single word', () {
        expect(MarkdownParser.generateId('Introduction', null, 0),
            equals('introduction'));
      });

      test('uses parent.index for multiple words', () {
        expect(
            MarkdownParser.generateId('My Section Title', 'parent', 2),
            equals('parent.2'));
      });

      test('handles empty text with parent', () {
        expect(MarkdownParser.generateId('', 'doc', 0), equals('doc.0'));
      });

      test('converts to snake_case for multi-word without parent', () {
        expect(MarkdownParser.generateId('Hello World', null, 0),
            equals('hello_world'));
      });

      test('removes special characters from single word', () {
        expect(MarkdownParser.generateId("What's", null, 0), equals('what_s'));
      });
    });

    group('calculateMaxDepth', () {
      test('returns 0 for empty list', () {
        expect(MarkdownParser.calculateMaxDepth([]), equals(0));
      });

      test('returns max level', () {
        final headlines = [
          (
            const ParsedHeadline(
              level: 1,
              lineNumber: 1,
              text: 'A',
              rawHeadline: '# A',
              fields: {},
            ),
            0,
            1,
          ),
          (
            const ParsedHeadline(
              level: 3,
              lineNumber: 3,
              text: 'B',
              rawHeadline: '### B',
              fields: {},
            ),
            2,
            3,
          ),
          (
            const ParsedHeadline(
              level: 2,
              lineNumber: 5,
              text: 'C',
              rawHeadline: '## C',
              fields: {},
            ),
            4,
            5,
          ),
        ];

        expect(MarkdownParser.calculateMaxDepth(headlines), equals(3));
      });
    });
  });
}
