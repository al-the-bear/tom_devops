/// Comprehensive tests for TomplateParser (Section 5)
///
/// Tests tomplate file parsing according to the Tom CLI specification.
library;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/template/tomplate_parser.dart';

void main() {
  late TomplateParser parser;
  late Directory tempDir;

  setUp(() {
    parser = TomplateParser();
    tempDir = Directory.systemTemp.createTempSync('tomplate_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ===========================================================================
  // Section 5.1 - Tomplate Naming Patterns
  // ===========================================================================

  group('Section 5.1 - Tomplate Naming Patterns', () {
    group('5.1.1 - Pattern 1: filename.ext.tomplate', () {
      test('pubspec.yaml.tomplate -> pubspec.yaml', () {
        final sourcePath = '/project/pubspec.yaml.tomplate';
        final template = parser.parseContent('content', sourcePath);
        expect(template.targetPath, equals('/project/pubspec.yaml'));
      });

      test('Dockerfile.tomplate -> Dockerfile', () {
        final sourcePath = '/project/Dockerfile.tomplate';
        final template = parser.parseContent('content', sourcePath);
        expect(template.targetPath, equals('/project/Dockerfile'));
      });

      test('config.json.tomplate -> config.json', () {
        final sourcePath = '/project/config.json.tomplate';
        final template = parser.parseContent('content', sourcePath);
        expect(template.targetPath, equals('/project/config.json'));
      });

      test('.gitignore.tomplate -> .gitignore', () {
        final sourcePath = '/project/.gitignore.tomplate';
        final template = parser.parseContent('content', sourcePath);
        expect(template.targetPath, equals('/project/.gitignore'));
      });

      test('handles nested directories', () {
        final sourcePath = '/project/lib/src/config.dart.tomplate';
        final template = parser.parseContent('content', sourcePath);
        expect(template.targetPath, equals('/project/lib/src/config.dart'));
      });
    });

    group('5.1.2 - Pattern 2: filename.tomplate.ext', () {
      test('pubspec.tomplate.yaml -> pubspec.yaml', () {
        final sourcePath = '/project/pubspec.tomplate.yaml';
        final template = parser.parseContent('content', sourcePath);
        expect(template.targetPath, equals('/project/pubspec.yaml'));
      });

      test('Dockerfile.tomplate.prod -> Dockerfile.prod', () {
        final sourcePath = '/project/Dockerfile.tomplate.prod';
        final template = parser.parseContent('content', sourcePath);
        expect(template.targetPath, equals('/project/Dockerfile.prod'));
      });

      test('config.tomplate.json -> config.json', () {
        final sourcePath = '/project/config.tomplate.json';
        final template = parser.parseContent('content', sourcePath);
        expect(template.targetPath, equals('/project/config.json'));
      });
    });
  });

  // ===========================================================================
  // Section 5.2 - Placeholder Types
  // ===========================================================================

  group('Section 5.2 - Placeholder Types', () {
    group('5.2.1 - Value Reference Placeholders', () {
      test(r'parses simple $VAL{key}', () {
        const content = r'name: $VAL{project.name}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders.length, equals(1));
        expect(template.placeholders[0].type, PlaceholderType.valueReference);
        expect(template.placeholders[0].key, equals('project.name'));
        expect(template.placeholders[0].defaultValue, isNull);
      });

      test(r'parses $VAL{key:-default} with default value', () {
        const content = r'version: $VAL{version:-1.0.0}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders.length, equals(1));
        expect(template.placeholders[0].key, equals('version'));
        expect(template.placeholders[0].defaultValue, equals('1.0.0'));
      });

      test(r'parses nested key paths $VAL{a.b.c}', () {
        const content = r'value: $VAL{config.database.host}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders[0].key, equals('config.database.host'));
      });

      test('parses multiple value references', () {
        const content = r'''
name: $VAL{project.name}
version: $VAL{project.version:-1.0.0}
description: $VAL{project.description:-A package}
''';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders.length, equals(3));
        expect(
          template.placeholders.map((p) => p.key),
          containsAll([
            'project.name',
            'project.version',
            'project.description',
          ]),
        );
      });
    });

    group('5.2.2 - Environment Placeholders', () {
      test(r'parses simple $ENV{ENV_VAR}', () {
        const content = r'api_key: $ENV{API_KEY}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders.length, equals(1));
        expect(template.placeholders[0].type, PlaceholderType.environment);
        expect(template.placeholders[0].key, equals('API_KEY'));
      });

      test(r'parses $ENV{ENV_VAR:-default}', () {
        const content = r'port: $ENV{PORT:-8080}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders[0].key, equals('PORT'));
        expect(template.placeholders[0].defaultValue, equals('8080'));
      });

      test('parses multiple environment variables', () {
        const content = r'''
host: $ENV{DB_HOST:-localhost}
port: $ENV{DB_PORT:-5432}
user: $ENV{DB_USER}
''';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders.length, equals(3));
        expect(
          template.placeholders.map((p) => p.key),
          containsAll(['DB_HOST', 'DB_PORT', 'DB_USER']),
        );
      });
    });

    group('5.2.3 - D4rt Expression Placeholders', () {
      test(r'parses simple $D4{expression}', () {
        const content = r'computed: $D4{1 + 2}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders.length, equals(1));
        expect(template.placeholders[0].type, PlaceholderType.d4rtExpression);
        expect(template.placeholders[0].key, equals('1 + 2'));
      });

      test(r'parses $D4{expression:-default}', () {
        const content = r'result: $D4{getValue():-fallback}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders[0].key, equals('getValue()'));
        expect(template.placeholders[0].defaultValue, equals('fallback'));
      });
    });

    group('5.2.4 - Generator Placeholders', () {
      test(r'parses generator pattern $GEN{path.*;separator}', () {
        const content = r'$GEN{projects.*.name;,}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders.length, equals(1));
        expect(template.placeholders[0].type, PlaceholderType.generator);
        expect(template.placeholders[0].key, equals('projects.*.name;,'));
      });

      test('parses generator with newline separator', () {
        const content = r'$GEN{items.*.value;\n}';
        final template = parser.parseContent(content, 'test.tomplate');

        expect(template.placeholders[0].type, PlaceholderType.generator);
      });
    });

    group('Mixed Placeholder Types', () {
      test('parses multiple placeholder types in same content', () {
        const content = r'''
name: $VAL{project.name}
api_key: $ENV{API_KEY:-dev-key}
computed: $D4{1 + 1}
list: $GEN{items.*.name;, }
''';
        final template = parser.parseContent(content, 'test.tomplate');

        final types = template.placeholders.map((p) => p.type).toSet();
        expect(types, contains(PlaceholderType.valueReference));
        expect(types, contains(PlaceholderType.environment));
        expect(types, contains(PlaceholderType.d4rtExpression));
        expect(types, contains(PlaceholderType.generator));
      });
    });
  });

  // ===========================================================================
  // Mode Block Detection
  // ===========================================================================

  group('Mode Block Detection', () {
    test('detects mode blocks in content', () {
      const content = '''
before
@@@mode development
dev: true
@@@endmode
after
''';
      final template = parser.parseContent(content, 'test.tomplate');
      expect(template.hasModeBlocks, isTrue);
    });

    test('no mode blocks when @@@mode not present', () {
      const content = '''
simple: content
no_modes: here
''';
      final template = parser.parseContent(content, 'test.tomplate');
      expect(template.hasModeBlocks, isFalse);
    });

    test('detects @@@mode anywhere in content', () {
      const content = '''
header: value

nested:
  @@@mode production
  prod: true
  @@@endmode
''';
      final template = parser.parseContent(content, 'test.tomplate');
      expect(template.hasModeBlocks, isTrue);
    });
  });

  // ===========================================================================
  // TomplateFile API
  // ===========================================================================

  group('TomplateFile API', () {
    test('getPlaceholdersOfType filters correctly', () {
      const content = r'''
$VAL{value1}
$ENV{ENV1}
$VAL{value2}
$D4{expr}
$ENV{ENV2}
''';
      final template = parser.parseContent(content, 'test.tomplate');

      final valueRefs = template.getPlaceholdersOfType(
        PlaceholderType.valueReference,
      );
      expect(valueRefs.length, equals(2));

      final envVars = template.getPlaceholdersOfType(
        PlaceholderType.environment,
      );
      expect(envVars.length, equals(2));

      final expressions = template.getPlaceholdersOfType(
        PlaceholderType.d4rtExpression,
      );
      expect(expressions.length, equals(1));
    });

    test('hasPlaceholders returns true when placeholders exist', () {
      const content = r'$VAL{value}';
      final template = parser.parseContent(content, 'test.tomplate');
      expect(template.hasPlaceholders, isTrue);
    });

    test('hasPlaceholders returns false when no placeholders', () {
      const content = 'plain text content';
      final template = parser.parseContent(content, 'test.tomplate');
      expect(template.hasPlaceholders, isFalse);
    });
  });

  // ===========================================================================
  // File Discovery
  // ===========================================================================

  group('File Discovery', () {
    test('finds .tomplate files in directory', () {
      // Create test files
      File(path.join(tempDir.path, 'file1.yaml.tomplate'))
          .writeAsStringSync('content1');
      File(path.join(tempDir.path, 'file2.json.tomplate'))
          .writeAsStringSync('content2');
      File(path.join(tempDir.path, 'regular.yaml'))
          .writeAsStringSync('regular');

      final templates = parser.findTemplates(tempDir.path);

      expect(templates.length, equals(2));
      expect(
        templates.map((t) => path.basename(t.sourcePath)),
        containsAll(['file1.yaml.tomplate', 'file2.json.tomplate']),
      );
    });

    test('finds files in nested directories', () {
      // Create nested structure
      Directory(path.join(tempDir.path, 'sub')).createSync();
      File(path.join(tempDir.path, 'root.tomplate'))
          .writeAsStringSync('root');
      File(path.join(tempDir.path, 'sub', 'nested.tomplate'))
          .writeAsStringSync('nested');

      final templates = parser.findTemplates(tempDir.path);

      expect(templates.length, equals(2));
    });

    test('finds files with .tomplate. pattern', () {
      File(path.join(tempDir.path, 'file.tomplate.yaml'))
          .writeAsStringSync('content');

      final templates = parser.findTemplates(tempDir.path);

      expect(templates.length, equals(1));
      expect(templates[0].targetPath, contains('file.yaml'));
    });

    test('returns empty list for non-existent directory', () {
      final templates = parser.findTemplates('/non/existent/path');
      expect(templates, isEmpty);
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('handles empty content', () {
      final template = parser.parseContent('', 'test.tomplate');
      expect(template.content, isEmpty);
      expect(template.placeholders, isEmpty);
      expect(template.hasModeBlocks, isFalse);
    });

    test('handles content with only placeholders', () {
      const content = r'$VAL{a}$ENV{B}$GEN{c}';
      final template = parser.parseContent(content, 'test.tomplate');
      expect(template.placeholders.length, equals(3));
    });

    test('handles very long key paths', () {
      const content = r'$VAL{a.b.c.d.e.f.g.h.i.j}';
      final template = parser.parseContent(content, 'test.tomplate');
      expect(template.placeholders[0].key, equals('a.b.c.d.e.f.g.h.i.j'));
    });

    test('handles special characters in default values', () {
      const content = r'$VAL{key:-https://example.com?foo=bar&baz=qux}';
      final template = parser.parseContent(content, 'test.tomplate');
      expect(
        template.placeholders[0].defaultValue,
        equals('https://example.com?foo=bar&baz=qux'),
      );
    });

    test('handles empty default value', () {
      const content = r'$VAL{key:-}';
      final template = parser.parseContent(content, 'test.tomplate');
      expect(template.placeholders[0].defaultValue, equals(''));
    });

    test('placeholder offsets are correct', () {
      const content = r'prefix $VAL{key1} middle $VAL{key2} suffix';
      final template = parser.parseContent(content, 'test.tomplate');

      expect(template.placeholders[0].offset, equals(7));
      // Second placeholder starts after 'prefix $VAL{key1} middle ' (25 chars)
      expect(template.placeholders[1].offset, equals(25));
    });

    test('PlaceholderInfo toString provides useful output', () {
      const content = r'$VAL{my.key}';
      final template = parser.parseContent(content, 'test.tomplate');
      final str = template.placeholders[0].toString();
      expect(str, contains('valueReference'));
      expect(str, contains('my.key'));
    });
  });
}
