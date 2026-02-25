/// Comprehensive tests for TomplateProcessor (Section 5)
///
/// Tests tomplate file processing according to the Tom CLI specification.
library;

import 'dart:io';
import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/template/tomplate_parser.dart';
import 'package:tom_build_cli/src/tom/template/tomplate_processor.dart';
import 'package:tom_build_cli/src/tom/mode/mode_resolver.dart';

void main() {
  late TomplateProcessor processor;
  late TomplateParser parser;
  late Directory tempDir;

  setUp(() {
    processor = TomplateProcessor();
    parser = TomplateParser();
    tempDir = Directory.systemTemp.createTempSync('tomplate_proc_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ===========================================================================
  // Section 5.3 - Value Reference Resolution
  // ===========================================================================

  group('Section 5.3 - Value Reference Resolution', () {
    group('5.3.1 - Simple Key Resolution', () {
      test(r'resolves simple $VAL{key}', () {
        const content = r'name: $VAL{name}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {'name': 'my_package'},
        );

        expect(result.content, equals('name: my_package'));
      });

      test(r'resolves multiple $VAL{key} placeholders', () {
        const content = r'name: $VAL{name}, version: $VAL{version}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {'name': 'app', 'version': '2.0.0'},
        );

        expect(result.content, equals('name: app, version: 2.0.0'));
      });
    });

    group('5.3.2 - Nested Key Path Resolution', () {
      test(r'resolves nested $VAL{a.b.c} paths', () {
        const content = r'host: $VAL{database.connection.host}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {
            'database': {
              'connection': {'host': 'localhost'},
            },
          },
        );

        expect(result.content, equals('host: localhost'));
      });

      test(r'resolves deeply nested paths', () {
        const content = r'value: $VAL{a.b.c.d.e}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {
            'a': {
              'b': {
                'c': {
                  'd': {'e': 'deep_value'},
                },
              },
            },
          },
        );

        expect(result.content, equals('value: deep_value'));
      });
    });

    group('5.3.3 - Default Values', () {
      test(r'uses default when key not found', () {
        const content = r'version: $VAL{version:-1.0.0}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {},
        );

        expect(result.content, equals('version: 1.0.0'));
      });

      test(r'uses resolved value over default', () {
        const content = r'version: $VAL{version:-1.0.0}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {'version': '2.5.0'},
        );

        expect(result.content, equals('version: 2.5.0'));
      });

      test(r'uses empty default when specified as $VAL{key:-}', () {
        const content = r'value: $VAL{missing:-}end';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {},
        );

        expect(result.content, equals('value: end'));
      });

      test(r'handles complex default values', () {
        const content = r'url: $VAL{api_url:-https://api.example.com/v1}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {},
        );

        expect(result.content, equals('url: https://api.example.com/v1'));
      });
    });

    group('5.3.4 - Recursive Resolution', () {
      test('resolves nested placeholders in values', () {
        const content = r'url: $VAL{full_url}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {
            r'full_url': r'$VAL{protocol}://$VAL{host}:$VAL{port}',
            'protocol': 'https',
            'host': 'example.com',
            'port': '443',
          },
        );

        expect(result.content, equals('url: https://example.com:443'));
      });

      test('throws on excessive recursion', () {
        const content = r'$VAL{recursive}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(
          () => processor.process(
            template: template,
            context: {r'recursive': r'$VAL{recursive}'},
          ),
          throwsA(isA<PlaceholderResolutionException>()),
        );
      });
    });

    group('5.3.5 - Value Types', () {
      test('handles string values', () {
        const content = r'$VAL{value}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {'value': 'string'},
        );

        expect(result.content, equals('string'));
      });

      test('handles integer values', () {
        const content = r'$VAL{value}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {'value': 42},
        );

        expect(result.content, equals('42'));
      });

      test('handles boolean values', () {
        const content = r'$VAL{value}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {'value': true},
        );

        expect(result.content, equals('true'));
      });

      test('handles double values', () {
        const content = r'$VAL{value}';
        final template = parser.parseContent(content, 'test.tomplate');

        final result = processor.process(
          template: template,
          context: {'value': 3.14},
        );

        expect(result.content, equals('3.14'));
      });
    });
  });

  // ===========================================================================
  // Section 5.4 - Environment Variable Resolution
  // ===========================================================================

  group('Section 5.4 - Environment Variable Resolution', () {
    test('resolves environment variables from provided map', () {
      const content = r'key: $ENV{API_KEY}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolveEnvironment: true,
        environment: {'API_KEY': 'secret123'},
      );

      expect(result.content, equals('key: secret123'));
    });

    test('uses default when environment variable not set', () {
      const content = r'port: $ENV{PORT:-8080}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolveEnvironment: true,
        environment: {},
      );

      expect(result.content, equals('port: 8080'));
    });

    test('does not resolve when resolveEnvironment is false', () {
      const content = r'key: $ENV{API_KEY}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolveEnvironment: false,
        environment: {'API_KEY': 'secret'},
      );

      expect(result.content, equals(r'key: $ENV{API_KEY}'));
    });

    test('resolves multiple environment variables', () {
      const content = r'''
host: $ENV{DB_HOST:-localhost}
port: $ENV{DB_PORT:-5432}
''';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolveEnvironment: true,
        environment: {
          'DB_HOST': 'prod-db.example.com',
        },
      );

      expect(result.content, contains('host: prod-db.example.com'));
      expect(result.content, contains('port: 5432'));
    });

    test('leaves unresolved when no default and not in environment', () {
      const content = r'key: $ENV{MISSING_VAR}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolveEnvironment: true,
        environment: {},
      );

      expect(result.content, equals(r'key: $ENV{MISSING_VAR}'));
    });
  });

  // ===========================================================================
  // Section 5.5 - Generator Placeholder Resolution
  // ===========================================================================

  group('Section 5.5 - Generator Placeholder Resolution', () {
    test('resolves generator placeholders with wildcard', () {
      const content = r'all: $GEN{items.*.name;,}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        context: {
          'items': [
            {'name': 'a'},
            {'name': 'b'},
            {'name': 'c'},
          ],
        },
      );

      expect(result.content, equals('all: a,b,c'));
    });

    test('resolves generator with custom separator', () {
      const content = r'list: $GEN{projects.*.name; | }';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        context: {
          'projects': [
            {'name': 'core'},
            {'name': 'utils'},
            {'name': 'app'},
          ],
        },
      );

      expect(result.content, equals('list: core | utils | app'));
    });

    test('resolves generator with filter', () {
      const content = r'dart: $GEN{projects.[type=dart].name;,}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        context: {
          'projects': [
            {'name': 'flutter_app', 'type': 'flutter'},
            {'name': 'dart_lib', 'type': 'dart'},
            {'name': 'dart_cli', 'type': 'dart'},
          ],
        },
      );

      expect(result.content, equals('dart: dart_lib,dart_cli'));
    });

    test('resolves generator from map values', () {
      const content = r'names: $GEN{deps.*.;,}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        context: {
          'deps': {
            'http': '^1.0.0',
            'path': '^2.0.0',
          },
        },
      );

      // Values from map
      expect(result.content, contains('^1.0.0'));
      expect(result.content, contains('^2.0.0'));
    });

    test('resolves multiple generators in content', () {
      const content = r'a: $GEN{items.*.name;,} b: $GEN{items.*.id;-}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        context: {
          'items': [
            {'name': 'x', 'id': '1'},
            {'name': 'y', 'id': '2'},
          ],
        },
      );

      expect(result.content, equals('a: x,y b: 1-2'));
    });

    test('leaves unresolved generator when path not found', () {
      const content = r'missing: $GEN{nonexistent.*.name;,}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        context: {},
      );

      // Should leave unresolved when not throwing
      expect(result.content, equals(r'missing: $GEN{nonexistent.*.name;,}'));
    });

    test('can disable generator resolution', () {
      const content = r'all: $GEN{items.*.name;,}';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        context: {
          'items': [
            {'name': 'a'},
          ],
        },
        resolveGenerators: false,
      );

      expect(result.content, equals(r'all: $GEN{items.*.name;,}'));
    });
  });

  // ===========================================================================
  // Mode Block Processing
  // ===========================================================================

  group('Mode Block Processing', () {
    test('processes mode blocks with resolved modes', () {
      const content = '''
@@@mode development
debug: true
@@@mode production
debug: false
@@@endmode
''';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolvedModes: const ResolvedModes(
          activeModes: {'development'},
          modeTypeValues: {},
          impliedModes: {},
        ),
      );

      expect(result.content, contains('debug: true'));
      expect(result.content, isNot(contains('debug: false')));
    });

    test('uses mode type values for typed conditions', () {
      const content = '''
@@@mode :environment=prod
server: production
@@@mode default
server: development
@@@endmode
''';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolvedModes: const ResolvedModes(
          activeModes: {},
          modeTypeValues: {'environment': 'prod'},
          impliedModes: {},
        ),
      );

      expect(result.content, contains('server: production'));
    });

    test('does not process mode blocks when resolvedModes is null', () {
      const content = '''
@@@mode development
dev: true
@@@endmode
''';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolvedModes: null,
      );

      expect(result.content, contains('@@@mode'));
    });
  });

  // ===========================================================================
  // Combined Processing
  // ===========================================================================

  group('Combined Processing', () {
    test('processes mode blocks then value references', () {
      const content = r'''
@@@mode development
url: $VAL{dev_url}
@@@mode production
url: $VAL{prod_url}
@@@endmode
''';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolvedModes: const ResolvedModes(
          activeModes: {'development'},
          modeTypeValues: {},
          impliedModes: {},
        ),
        context: {
          'dev_url': 'http://localhost:8080',
          'prod_url': 'https://api.example.com',
        },
      );

      expect(result.content, contains('url: http://localhost:8080'));
    });

    test('full pipeline: modes + values + environment', () {
      const content = r'''
@@@mode production
api_key: $ENV{PROD_API_KEY}
url: $VAL{prod_url}
@@@mode development
api_key: $ENV{DEV_API_KEY:-dev-key}
url: $VAL{dev_url:-http://localhost}
@@@endmode
''';
      final template = parser.parseContent(content, 'test.tomplate');

      final result = processor.process(
        template: template,
        resolvedModes: const ResolvedModes(
          activeModes: {'production'},
          modeTypeValues: {},
          impliedModes: {},
        ),
        context: {
          'prod_url': 'https://api.example.com',
        },
        resolveEnvironment: true,
        environment: {
          'PROD_API_KEY': 'secret-prod-key',
        },
      );

      expect(result.content, contains('api_key: secret-prod-key'));
      expect(result.content, contains('url: https://api.example.com'));
    });
  });

  // ===========================================================================
  // File Operations
  // ===========================================================================

  group('File Operations', () {
    test('writes processed template to target path', () {
      const content = r'name: $VAL{name}';
      final sourcePath = '${tempDir.path}/test.yaml.tomplate';
      final template = parser.parseContent(content, sourcePath);

      final processed = processor.process(
        template: template,
        context: {'name': 'my_app'},
      );

      processor.writeToFile(processed);

      final targetFile = File(processed.targetPath);
      expect(targetFile.existsSync(), isTrue);
      expect(targetFile.readAsStringSync(), equals('name: my_app'));
    });

    test('creates parent directories if needed', () {
      const content = 'value: test';
      final sourcePath = '${tempDir.path}/sub/dir/test.yaml.tomplate';
      final template = parser.parseContent(content, sourcePath);

      final processed = processor.process(template: template);
      processor.writeToFile(processed);

      final targetFile = File(processed.targetPath);
      expect(targetFile.existsSync(), isTrue);
    });

    test('processAndWrite combines process and write', () {
      const content = r'version: $VAL{version}';
      final sourcePath = '${tempDir.path}/pubspec.yaml.tomplate';
      final template = parser.parseContent(content, sourcePath);

      processor.processAndWrite(
        template: template,
        context: {'version': '1.0.0'},
      );

      final targetFile = File('${tempDir.path}/pubspec.yaml');
      expect(targetFile.existsSync(), isTrue);
      expect(targetFile.readAsStringSync(), equals('version: 1.0.0'));
    });
  });

  // ===========================================================================
  // ProcessedTemplate
  // ===========================================================================

  group('ProcessedTemplate', () {
    test('preserves source and target paths', () {
      const content = 'test';
      final template = parser.parseContent(
        content,
        '/project/file.yaml.tomplate',
      );

      final processed = processor.process(template: template);

      expect(processed.sourcePath, equals('/project/file.yaml.tomplate'));
      expect(processed.targetPath, equals('/project/file.yaml'));
    });

    test('content is processed result', () {
      const content = r'$VAL{value}';
      final template = parser.parseContent(content, 'test.tomplate');

      final processed = processor.process(
        template: template,
        context: {'value': 'resolved'},
      );

      expect(processed.content, equals('resolved'));
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('handles empty template', () {
      final template = parser.parseContent('', 'test.tomplate');
      final processed = processor.process(template: template);
      expect(processed.content, isEmpty);
    });

    test('handles template with no placeholders', () {
      const content = 'plain text content';
      final template = parser.parseContent(content, 'test.tomplate');
      final processed = processor.process(template: template);
      expect(processed.content, equals('plain text content'));
    });

    test('preserves unresolved placeholders', () {
      const content = r'$VAL{known} $VAL{unknown}';
      final template = parser.parseContent(content, 'test.tomplate');

      final processed = processor.process(
        template: template,
        context: {'known': 'value'},
      );

      expect(processed.content, equals(r'value $VAL{unknown}'));
    });

    test('handles null context gracefully', () {
      const content = r'$VAL{value:-default}';
      final template = parser.parseContent(content, 'test.tomplate');

      final processed = processor.process(
        template: template,
        context: null,
      );

      // Without context, placeholders remain unresolved
      expect(processed.content, contains(r'$VAL{value:-default}'));
    });

    test('handles context with null values', () {
      const content = r'$VAL{value:-fallback}';
      final template = parser.parseContent(content, 'test.tomplate');

      final processed = processor.process(
        template: template,
        context: {'value': null},
      );

      expect(processed.content, equals('fallback'));
    });

    test('handles escaped placeholders', () {
      // Escaped placeholders use single backslash: \$VAL{...}
      // This gets converted back to $VAL{...} after processing
      // In Dart raw string r'\$VAL{...}' equals the literal text \$VAL{...}
      const content = r'\$VAL{literal}';
      final template = parser.parseContent(content, 'test.tomplate');

      final processed = processor.process(
        template: template,
        context: {'literal': 'should_not_appear'},
      );

      // The \$VAL{ becomes $VAL{ (literal, not resolved)
      expect(processed.content, equals(r'$VAL{literal}'));
    });

    test('handles very long content', () {
      final content = List.generate(1000, (i) => 'line $i: \$VAL{value}').join(
        '\n',
      );
      final template = parser.parseContent(content, 'test.tomplate');

      final processed = processor.process(
        template: template,
        context: {'value': 'x'},
      );

      expect(processed.content.split('\n').length, equals(1000));
    });
  });

  // ===========================================================================
  // Real-World Scenarios
  // ===========================================================================

  group('Real-World Scenarios', () {
    test('pubspec.yaml.tomplate processing', () {
      const content = r'''
name: $VAL{project.name}
version: $VAL{project.version:-1.0.0}
description: $VAL{project.description:-A Dart package}

environment:
  sdk: $VAL{sdk.constraint:-^3.0.0}

dependencies:
@@@mode development
  some_package:
    path: $VAL{deps.some_package.path}
@@@mode production
  some_package: $VAL{deps.some_package.version}
@@@endmode

dev_dependencies:
  test: $VAL{deps.test:-any}
''';
      final template = parser.parseContent(content, 'pubspec.yaml.tomplate');

      final processed = processor.process(
        template: template,
        resolvedModes: const ResolvedModes(
          activeModes: {'development'},
          modeTypeValues: {},
          impliedModes: {},
        ),
        context: {
          'project': {
            'name': 'my_app',
            'version': '2.0.0',
            'description': 'My application',
          },
          'sdk': {'constraint': '^3.2.0'},
          'deps': {
            'some_package': {
              'path': '../some_package',
              'version': '^1.0.0',
            },
            'test': '^1.24.0',
          },
        },
      );

      expect(processed.content, contains('name: my_app'));
      expect(processed.content, contains('version: 2.0.0'));
      expect(processed.content, contains('sdk: ^3.2.0'));
      expect(processed.content, contains('path: ../some_package'));
      expect(processed.content, contains('test: ^1.24.0'));
    });

    test('Dockerfile.tomplate processing', () {
      const content = r'''
@@@mode :environment=prod
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
EXPOSE $ENV{PORT:-8080}
CMD ["/app/bin/server"]
@@@mode default
FROM dart:stable

WORKDIR /app
COPY . .
RUN dart pub get

EXPOSE $ENV{PORT:-8080}
CMD ["dart", "run", "bin/server.dart"]
@@@endmode
''';
      final template = parser.parseContent(content, 'Dockerfile.tomplate');

      final processed = processor.process(
        template: template,
        resolvedModes: const ResolvedModes(
          activeModes: {},
          modeTypeValues: {'environment': 'prod'},
          impliedModes: {},
        ),
        resolveEnvironment: true,
        environment: {'PORT': '3000'},
      );

      expect(processed.content, contains('dart compile exe'));
      expect(processed.content, contains('FROM scratch'));
      expect(processed.content, contains('EXPOSE 3000'));
    });
  });
}
