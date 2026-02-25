import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/mode/mode_resolver.dart';
import 'package:tom_build_cli/src/tom/template/tomplate_parser.dart';
import 'package:tom_build_cli/src/tom/template/tomplate_processor.dart';

void main() {
  group('TomplateParser', () {
    late TomplateParser parser;

    setUp(() {
      parser = TomplateParser();
    });

    group('parseContent', () {
      test('parses simple template', () {
        const content = 'name: \$VAL{project.name}';
        final result = parser.parseContent(content, 'test.yaml.tomplate');

        expect(result.sourcePath, equals('test.yaml.tomplate'));
        expect(result.targetPath, endsWith('test.yaml'));
        expect(result.content, equals(content));
        expect(result.placeholders, hasLength(1));
      });

      test('detects value reference placeholders', () {
        const content = '''
name: \$VAL{project.name}
version: \$VAL{version:-1.0.0}
''';
        final result = parser.parseContent(content, 'test.yaml.tomplate');

        final placeholders = result.getPlaceholdersOfType(
          PlaceholderType.valueReference,
        );
        expect(placeholders, hasLength(2));
        expect(placeholders[0].key, equals('project.name'));
        expect(placeholders[1].key, equals('version'));
        expect(placeholders[1].defaultValue, equals('1.0.0'));
      });

      test('detects environment placeholders', () {
        const content = r'''
host: $ENV{HOST:-localhost}
port: $ENV{PORT}
''';
        final result = parser.parseContent(content, 'test.yaml.tomplate');

        final placeholders = result.getPlaceholdersOfType(
          PlaceholderType.environment,
        );
        expect(placeholders, hasLength(2));
        expect(placeholders[0].key, equals('HOST'));
        expect(placeholders[0].defaultValue, equals('localhost'));
        expect(placeholders[1].key, equals('PORT'));
      });

      test('detects D4rt expression placeholders', () {
        const content = r'''
result: $D4{calculateValue()}
fallback: $D4{getValue():-default}
''';
        final result = parser.parseContent(content, 'test.yaml.tomplate');

        final placeholders = result.getPlaceholdersOfType(
          PlaceholderType.d4rtExpression,
        );
        expect(placeholders, hasLength(2));
        expect(placeholders[0].key, equals('calculateValue()'));
        expect(placeholders[1].defaultValue, equals('default'));
      });

      test('detects generator placeholders', () {
        const content = r'''
all_projects: $GEN{projects.*.name;,}
''';
        final result = parser.parseContent(content, 'test.yaml.tomplate');

        final placeholders = result.getPlaceholdersOfType(
          PlaceholderType.generator,
        );
        expect(placeholders, hasLength(1));
        expect(placeholders[0].key, contains('projects.*.name'));
      });

      test('detects mode blocks', () {
        const content = '''
@@@mode development
key: dev_value
@@@endmode
''';
        final result = parser.parseContent(content, 'test.yaml.tomplate');
        expect(result.hasModeBlocks, isTrue);
      });

      test('handles template naming pattern: file.ext.tomplate', () {
        final result = parser.parseContent('', 'pubspec.yaml.tomplate');
        expect(result.targetPath, endsWith('pubspec.yaml'));
      });

      test('handles template naming pattern: file.tomplate.ext', () {
        final result = parser.parseContent('', 'pubspec.tomplate.yaml');
        expect(result.targetPath, endsWith('pubspec.yaml'));
      });
    });
  });

  group('TomplateProcessor', () {
    late TomplateProcessor processor;
    late TomplateParser parser;

    setUp(() {
      processor = TomplateProcessor();
      parser = TomplateParser();
    });

    group('process', () {
      test('resolves value reference placeholders', () {
        final template = parser.parseContent(
          'name: \$VAL{project.name}',
          'test.yaml.tomplate',
        );

        final context = {
          'project': {'name': 'tom_build'},
        };

        final result = processor.process(template: template, context: context);
        expect(result.content, equals('name: tom_build'));
      });

      test('uses default value when key not found', () {
        final template = parser.parseContent(
          'version: \$VAL{version:-1.0.0}',
          'test.yaml.tomplate',
        );

        final result = processor.process(template: template, context: {});
        expect(result.content, equals('version: 1.0.0'));
      });

      test('resolves nested key paths', () {
        final template = parser.parseContent(
          'sdk: \$VAL{environment.sdk}',
          'test.yaml.tomplate',
        );

        final context = {
          'environment': {'sdk': '>=3.0.0 <4.0.0'},
        };

        final result = processor.process(template: template, context: context);
        expect(result.content, equals('sdk: >=3.0.0 <4.0.0'));
      });

      test('handles recursive placeholder resolution', () {
        final template = parser.parseContent(
          'path: \$VAL{paths.base}/\$VAL{paths.sub}',
          'test.yaml.tomplate',
        );

        final context = {
          'paths': {
            'base': '/home',
            'sub': 'user',
          },
        };

        final result = processor.process(template: template, context: context);
        expect(result.content, equals('path: /home/user'));
      });

      test('preserves escaped placeholders', () {
        final template = parser.parseContent(
          r'deferred: \$VAL{later.resolve}',
          'test.yaml.tomplate',
        );

        final result = processor.process(template: template, context: {});
        expect(result.content, contains(r'$VAL{later.resolve}'));
      });

      test('processes mode blocks with resolvedModes', () {
        final template = parser.parseContent(
          '''
@@@mode development
env: dev
@@@mode production
env: prod
@@@endmode
''',
          'test.yaml.tomplate',
        );

        final resolvedModes = ResolvedModes(
          activeModes: {'development'},
          modeTypeValues: {},
          impliedModes: {},
        );

        final result = processor.process(
          template: template,
          resolvedModes: resolvedModes,
        );
        expect(result.content, contains('env: dev'));
        expect(result.content, isNot(contains('env: prod')));
      });

      test('resolves environment placeholders when requested', () {
        final template = parser.parseContent(
          r'host: $ENV{TEST_HOST:-localhost}',
          'test.yaml.tomplate',
        );

        final result = processor.process(
          template: template,
          resolveEnvironment: true,
          environment: {'TEST_HOST': 'example.com'},
        );
        expect(result.content, equals('host: example.com'));
      });

      test('uses environment default when variable not set', () {
        final template = parser.parseContent(
          r'host: $ENV{UNDEFINED_VAR:-fallback}',
          'test.yaml.tomplate',
        );

        final result = processor.process(
          template: template,
          resolveEnvironment: true,
          environment: {},
        );
        expect(result.content, equals('host: fallback'));
      });
    });
  });
}
