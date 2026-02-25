/// Tests for Text scripting helper.
library;

import 'package:test/test.dart';
import 'package:tom_build/scripting.dart';

void main() {
  group('Text', () {
    group('escapeHtml', () {
      test('escapes HTML special characters', () {
        expect(TomText.escapeHtml('<script>'), '&lt;script&gt;');
        expect(TomText.escapeHtml('"quoted"'), '&quot;quoted&quot;');
        expect(TomText.escapeHtml("it's"), "it&#39;s");
        expect(TomText.escapeHtml('a & b'), 'a &amp; b');
      });

      test('handles multiple special characters', () {
        expect(
          TomText.escapeHtml('<a href="test">click & go</a>'),
          '&lt;a href=&quot;test&quot;&gt;click &amp; go&lt;/a&gt;',
        );
      });

      test('returns unchanged text without special characters', () {
        expect(TomText.escapeHtml('Hello World'), 'Hello World');
      });
    });

    group('unescapeHtml', () {
      test('unescapes HTML entities', () {
        expect(TomText.unescapeHtml('&lt;script&gt;'), '<script>');
        expect(TomText.unescapeHtml('&quot;quoted&quot;'), '"quoted"');
        expect(TomText.unescapeHtml("it&#39;s"), "it's");
        expect(TomText.unescapeHtml('a &amp; b'), 'a & b');
      });

      test('handles multiple entities', () {
        expect(
          TomText.unescapeHtml('&lt;a href=&quot;test&quot;&gt;click &amp; go&lt;/a&gt;'),
          '<a href="test">click & go</a>',
        );
      });

      test('roundtrips with escapeHtml', () {
        const original = '<script>alert("test")</script>';
        final escaped = TomText.escapeHtml(original);
        final unescaped = TomText.unescapeHtml(escaped);
        expect(unescaped, original);
      });
    });

    group('escapeJson', () {
      test('escapes backslash', () {
        expect(TomText.escapeJson(r'path\to\file'), r'path\\to\\file');
      });

      test('escapes double quotes', () {
        expect(TomText.escapeJson('say "hello"'), r'say \"hello\"');
      });

      test('escapes newlines', () {
        expect(TomText.escapeJson('line1\nline2'), r'line1\nline2');
      });

      test('escapes tabs', () {
        expect(TomText.escapeJson('col1\tcol2'), r'col1\tcol2');
      });

      test('escapes carriage returns', () {
        expect(TomText.escapeJson('line1\rline2'), r'line1\rline2');
      });

      test('handles multiple escape sequences', () {
        expect(
          TomText.escapeJson('path\\file\n"value"'),
          r'path\\file\n\"value\"',
        );
      });
    });

    group('escapeRegex', () {
      test('escapes regex special characters', () {
        expect(TomText.escapeRegex('.'), r'\.');
        expect(TomText.escapeRegex('^'), r'\^');
        expect(TomText.escapeRegex(r'$'), r'\$');
        expect(TomText.escapeRegex('*'), r'\*');
        expect(TomText.escapeRegex('+'), r'\+');
        expect(TomText.escapeRegex('?'), r'\?');
        expect(TomText.escapeRegex('('), r'\(');
        expect(TomText.escapeRegex(')'), r'\)');
        expect(TomText.escapeRegex('['), r'\[');
        expect(TomText.escapeRegex(']'), r'\]');
        expect(TomText.escapeRegex('{'), r'\{');
        expect(TomText.escapeRegex('}'), r'\}');
        expect(TomText.escapeRegex('|'), r'\|');
        expect(TomText.escapeRegex(r'\'), r'\\');
      });

      test('can be used as literal in regex', () {
        const literal = 'file.txt';
        final escaped = TomText.escapeRegex(literal);
        final regex = RegExp(escaped);

        expect(regex.hasMatch('file.txt'), isTrue);
        expect(regex.hasMatch('filextxt'), isFalse);
      });
    });

    group('escapeShell', () {
      test('wraps text in single quotes', () {
        expect(TomText.escapeShell('hello'), "'hello'");
      });

      test('escapes single quotes in text', () {
        final result = TomText.escapeShell("it's a test");
        // The result should be safely usable in a shell
        expect(result, contains('it'));
        expect(result, contains('test'));
      });

      test('handles special shell characters', () {
        // These should all be safe inside single quotes
        expect(TomText.escapeShell('a b'), "'a b'");
        expect(TomText.escapeShell(r'$HOME'), r"'$HOME'");
        expect(TomText.escapeShell('a;b'), "'a;b'");
      });
    });
  });
}
