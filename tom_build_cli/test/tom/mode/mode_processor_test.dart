import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/mode/mode_processor.dart';

void main() {
  group('ModeProcessor', () {
    late ModeProcessor processor;

    setUp(() {
      processor = ModeProcessor();
    });

    group('processContent', () {
      test('returns content unchanged when no mode blocks', () {
        const content = '''
key: value
nested:
  inner: data
''';
        final result = processor.processContent(content, {'development'});
        expect(result, equals(content));
      });

      test('includes matching mode block content', () {
        const content = '''
before
@@@mode development
dev_key: dev_value
@@@endmode
after
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('dev_key: dev_value'));
        expect(result, contains('before'));
        expect(result, contains('after'));
      });

      test('excludes non-matching mode block content', () {
        const content = '''
before
@@@mode production
prod_key: prod_value
@@@endmode
after
''';
        final result = processor.processContent(content, {'development'});
        expect(result, isNot(contains('prod_key')));
        expect(result, contains('before'));
        expect(result, contains('after'));
      });

      test('handles multiple mode sections with first match wins', () {
        const content = '''
@@@mode development
key: dev_value
@@@mode production
key: prod_value
@@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('dev_value'));
        expect(result, isNot(contains('prod_value')));
      });

      test('uses default when no mode matches', () {
        const content = '''
@@@mode development
key: dev_value
@@@mode default
key: default_value
@@@endmode
''';
        final result = processor.processContent(content, {'staging'});
        expect(result, contains('default_value'));
        expect(result, isNot(contains('dev_value')));
      });

      test('handles comma-separated OR conditions', () {
        const content = '''
@@@mode development,staging
key: dev_or_staging
@@@mode production
key: prod_value
@@@endmode
''';
        final devResult = processor.processContent(content, {'development'});
        expect(devResult, contains('dev_or_staging'));

        final stagingResult = processor.processContent(content, {'staging'});
        expect(stagingResult, contains('dev_or_staging'));

        final prodResult = processor.processContent(content, {'production'});
        expect(prodResult, contains('prod_value'));
      });

      test('handles typed mode conditions', () {
        const content = '''
@@@mode :environment=prod
key: prod_env
@@@mode default
key: other_env
@@@endmode
''';
        final result = processor.processContent(
          content,
          {},
          modeTypeValues: {'environment': 'prod'},
        );
        expect(result, contains('prod_env'));
      });

      test('handles multiple mode blocks', () {
        const content = '''
@@@mode development
dev1: value1
@@@endmode

middle_content: here

@@@mode development
dev2: value2
@@@mode production
prod: value
@@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('dev1: value1'));
        expect(result, contains('dev2: value2'));
        expect(result, contains('middle_content: here'));
        expect(result, isNot(contains('prod: value')));
      });

      test('preserves content before and after mode blocks', () {
        const content = '''
# Header comment
before: content

@@@mode development
dev: value
@@@endmode

after: content
# Footer comment
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('# Header comment'));
        expect(result, contains('before: content'));
        expect(result, contains('dev: value'));
        expect(result, contains('after: content'));
        expect(result, contains('# Footer comment'));
      });

      test('handles nested YAML in mode blocks', () {
        const content = '''
@@@mode development
dependencies:
  path: ../local_dep
  build_runner: any
@@@mode production
dependencies:
  path: ^1.0.0
  build_runner: ^2.0.0
@@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result, contains('path: ../local_dep'));
        expect(result, contains('build_runner: any'));
      });

      test('returns empty content when no match and no default', () {
        const content = '''
@@@mode production
prod_only: value
@@@endmode
''';
        final result = processor.processContent(content, {'development'});
        expect(result.trim(), isEmpty);
      });
    });
  });
}
