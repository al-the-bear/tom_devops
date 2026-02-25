/// Tests for Yaml scripting helper.
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/scripting.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('yaml_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('Yaml', () {
    group('parse', () {
      test('parses simple YAML map', () {
        final result = ScriptYaml.parse('''
name: test
version: 1.0.0
''');
        expect(result, {'name': 'test', 'version': '1.0.0'});
      });

      test('parses nested YAML', () {
        final result = ScriptYaml.parse('''
database:
  host: localhost
  port: 5432
''');
        expect(result['database'], isA<Map<String, dynamic>>());
        expect(result['database']['host'], 'localhost');
        expect(result['database']['port'], 5432);
      });

      test('returns empty map for empty YAML', () {
        final result = ScriptYaml.parse('');
        expect(result, isEmpty);
      });

      test('throws on non-map root', () {
        expect(
          () => ScriptYaml.parse('- item1\n- item2'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('parseList', () {
      test('parses YAML list', () {
        final result = ScriptYaml.parseList('''
- item1
- item2
- item3
''');
        expect(result, ['item1', 'item2', 'item3']);
      });

      test('returns empty list for empty YAML', () {
        final result = ScriptYaml.parseList('');
        expect(result, isEmpty);
      });

      test('throws on non-list root', () {
        expect(
          () => ScriptYaml.parseList('key: value'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('parseAny', () {
      test('parses map', () {
        final result = ScriptYaml.parseAny('key: value');
        expect(result, {'key': 'value'});
      });

      test('parses list', () {
        final result = ScriptYaml.parseAny('- a\n- b');
        expect(result, ['a', 'b']);
      });

      test('parses scalar', () {
        expect(ScriptYaml.parseAny('hello'), 'hello');
        expect(ScriptYaml.parseAny('42'), 42);
        expect(ScriptYaml.parseAny('true'), true);
      });
    });

    group('load', () {
      test('loads YAML file', () {
        final file = File('${tempDir.path}/test.yaml');
        file.writeAsStringSync('''
name: test-project
version: 2.0.0
''');

        final result = ScriptYaml.load(file.path);
        expect(result['name'], 'test-project');
        expect(result['version'], '2.0.0');
      });

      test('loads nested YAML file', () {
        final file = File('${tempDir.path}/nested.yaml');
        file.writeAsStringSync('''
server:
  host: example.com
  ports:
    - 80
    - 443
''');

        final result = ScriptYaml.load(file.path);
        expect(result['server']['host'], 'example.com');
        expect(result['server']['ports'], [80, 443]);
      });
    });

    group('loadWithEnv', () {
      test('substitutes environment variables', () {
        final file = File('${tempDir.path}/env.yaml');
        file.writeAsStringSync(r'''
database:
  host: "{TEST_DB_HOST:localhost}"
  user: "{TEST_DB_USER}"
''');

        final result = ScriptYaml.loadWithEnv(
          file.path,
          environment: {
            'TEST_DB_HOST': 'production.db.com',
            'TEST_DB_USER': 'admin',
          },
        );

        expect(result['database']['host'], 'production.db.com');
        expect(result['database']['user'], 'admin');
      });

      test('uses default values when env var missing', () {
        final file = File('${tempDir.path}/defaults.yaml');
        file.writeAsStringSync(r'''
config:
  port: "{MISSING_PORT:8080}"
  debug: "{MISSING_DEBUG:false}"
''');

        final result = ScriptYaml.loadWithEnv(file.path, environment: {});

        expect(result['config']['port'], '8080');
        expect(result['config']['debug'], 'false');
      });
    });

    group('loadList', () {
      test('loads YAML list from file', () {
        final file = File('${tempDir.path}/list.yaml');
        file.writeAsStringSync('''
- first
- second
- third
''');

        final result = ScriptYaml.loadList(file.path);
        expect(result, ['first', 'second', 'third']);
      });
    });

    group('loadAny', () {
      test('loads any YAML value from file', () {
        final mapFile = File('${tempDir.path}/map.yaml');
        mapFile.writeAsStringSync('key: value');

        final listFile = File('${tempDir.path}/list.yaml');
        listFile.writeAsStringSync('- item');

        expect(ScriptYaml.loadAny(mapFile.path), {'key': 'value'});
        expect(ScriptYaml.loadAny(listFile.path), ['item']);
      });
    });

    group('loadAndMerge', () {
      test('merges multiple YAML files', () {
        final base = File('${tempDir.path}/base.yaml');
        base.writeAsStringSync('''
name: base
settings:
  debug: false
  timeout: 30
''');

        final override = File('${tempDir.path}/override.yaml');
        override.writeAsStringSync('''
settings:
  debug: true
  maxRetries: 3
''');

        final result = ScriptYaml.loadAndMerge([base.path, override.path]);

        expect(result['name'], 'base');
        expect(result['settings']['debug'], true);
        expect(result['settings']['timeout'], 30);
        expect(result['settings']['maxRetries'], 3);
      });

      test('skips non-existent files', () {
        final existing = File('${tempDir.path}/exists.yaml');
        existing.writeAsStringSync('key: value');

        final result = ScriptYaml.loadAndMerge([
          existing.path,
          '${tempDir.path}/does-not-exist.yaml',
        ]);

        expect(result, {'key': 'value'});
      });
    });

    group('loadAndMergeWithEnv', () {
      test('merges and substitutes env vars', () {
        final file = File('${tempDir.path}/config.yaml');
        file.writeAsStringSync(r'''
api:
  url: "{API_URL:http://localhost}"
''');

        final result = ScriptYaml.loadAndMergeWithEnv(
          [file.path],
          environment: {'API_URL': 'https://api.example.com'},
        );

        expect(result['api']['url'], 'https://api.example.com');
      });
    });

    group('isValidFile', () {
      test('returns true for valid YAML file', () {
        final file = File('${tempDir.path}/valid.yaml');
        file.writeAsStringSync('key: value');

        expect(ScriptYaml.isValidFile(file.path), isTrue);
      });

      test('returns false for non-existent file', () {
        expect(ScriptYaml.isValidFile('${tempDir.path}/missing.yaml'), isFalse);
      });

      test('returns false for invalid YAML', () {
        final file = File('${tempDir.path}/invalid.yaml');
        file.writeAsStringSync('{ invalid yaml content');

        expect(ScriptYaml.isValidFile(file.path), isFalse);
      });
    });
  });
}
