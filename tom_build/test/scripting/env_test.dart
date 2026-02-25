/// Tests for Env scripting helper.
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/scripting.dart';

void main() {
  group('Env', () {
    // Store original directory for tests that change directories
    late String originalDir;
    late Directory tempDir;

    setUp(() {
      originalDir = Directory.current.path;
      tempDir = Directory.systemTemp.createTempSync('env_test_');
      // Clear the env cache before each test
      TomEnv.reload();
    });

    tearDown(() {
      Directory.current = originalDir;
      tempDir.deleteSync(recursive: true);
      // Clear cache after tests
      TomEnv.reload();
    });

    group('.env file loading', () {
      test('load() returns system environment when no .env file', () {
        // Use reload to load fresh from tempDir (which has no .env)
        final env = TomEnv.reload(tempDir.path);
        expect(env, isNotEmpty);
        expect(env['PATH'] ?? env['Path'], isNotNull);
      });

      test('load() parses simple KEY=VALUE format', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
TEST_KEY=test_value
ANOTHER_KEY=another_value
''');

        // Use reload to ensure fresh load from tempDir
        final env = TomEnv.reload(tempDir.path);
        expect(env['TEST_KEY'], 'test_value');
        expect(env['ANOTHER_KEY'], 'another_value');
      });

      test('load() handles quoted values', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
DOUBLE_QUOTED="value with spaces"
SINGLE_QUOTED='single quoted'
''');

        final env = TomEnv.reload(tempDir.path);
        expect(env['DOUBLE_QUOTED'], 'value with spaces');
        expect(env['SINGLE_QUOTED'], 'single quoted');
      });

      test('load() handles escape sequences in double quotes', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync(r'''
MULTILINE="line1\nline2"
TABBED="col1\tcol2"
''');

        final env = TomEnv.reload(tempDir.path);
        expect(env['MULTILINE'], 'line1\nline2');
        expect(env['TABBED'], 'col1\tcol2');
      });

      test('load() skips comments and empty lines', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
# This is a comment
KEY1=value1

# Another comment
KEY2=value2
''');

        final env = TomEnv.reload(tempDir.path);
        expect(env['KEY1'], 'value1');
        expect(env['KEY2'], 'value2');
        expect(env.containsKey('# This is a comment'), isFalse);
      });

      test('load() caches results', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('CACHED_KEY=original');

        // First load with reload to establish the cache for this directory
        final env1 = TomEnv.reload(tempDir.path);
        expect(env1['CACHED_KEY'], 'original');

        // Modify file
        envFile.writeAsStringSync('CACHED_KEY=modified');

        // Should still return cached value (using load which uses cache)
        final env2 = TomEnv.load(tempDir.path);
        expect(env2['CACHED_KEY'], 'original');
      });

      test('reload() clears cache and reloads', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('RELOAD_KEY=original');

        TomEnv.reload(tempDir.path);

        // Modify file
        envFile.writeAsStringSync('RELOAD_KEY=modified');

        // Reload should get new value
        final env = TomEnv.reload(tempDir.path);
        expect(env['RELOAD_KEY'], 'modified');
      });

      test('loadFile() loads from specific path', () {
        final customEnv = File('${tempDir.path}/custom.env');
        customEnv.writeAsStringSync('CUSTOM_KEY=custom_value');

        final env = TomEnv.loadFile(customEnv.path);
        expect(env['CUSTOM_KEY'], 'custom_value');
      });
    });

    group('resolve()', () {
      test('resolves simple placeholders', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('MSG=Hello');

        TomEnv.reload(tempDir.path);
        final result = TomEnv.resolve('Say: {MSG}');
        expect(result, 'Say: Hello');
      });

      test('resolves placeholders with defaults', () {
        TomEnv.reload(tempDir.path);
        final result = TomEnv.resolve('Port: {MISSING_PORT:8080}');
        expect(result, 'Port: 8080');
      });

      test('keeps placeholder when no env and no default', () {
        TomEnv.reload(tempDir.path);
        final result = TomEnv.resolve('Key: {MISSING_NO_DEFAULT}');
        expect(result, 'Key: {MISSING_NO_DEFAULT}');
      });

      test('resolves multiple placeholders', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('''
HOST=localhost
PORT=3000
''');

        TomEnv.reload(tempDir.path);
        final result = TomEnv.resolve('http://{HOST}:{PORT}/api');
        expect(result, 'http://localhost:3000/api');
      });

      test('uses workingDir to find .env', () {
        final subDir = Directory('${tempDir.path}/subdir')..createSync();
        final envFile = File('${subDir.path}/.env');
        envFile.writeAsStringSync('SUBDIR_KEY=subdir_value');

        // reload with subDir to load its .env file
        TomEnv.reload(subDir.path);
        final result = TomEnv.resolve('{SUBDIR_KEY}');
        expect(result, 'subdir_value');
      });
    });

    group('resolveWith()', () {
      test('resolves with explicit environment', () {
        final result = TomEnv.resolveWith('Hello {NAME}!', {'NAME': 'World'});
        expect(result, 'Hello World!');
      });

      test('uses default when var missing from explicit env', () {
        final result = TomEnv.resolveWith('Port: {PORT:9000}', {});
        expect(result, 'Port: 9000');
      });
    });

    group('resolveMap()', () {
      test('resolves all string values in map', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('DB_HOST=db.example.com');

        TomEnv.reload(tempDir.path);
        final map = {'host': '{DB_HOST}', 'port': 5432, 'ssl': true};
        final result = TomEnv.resolveMap(map);
        expect(result['host'], 'db.example.com');
        expect(result['port'], 5432);
        expect(result['ssl'], true);
      });

      test('resolves nested maps', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('API_KEY=secret123');

        TomEnv.reload(tempDir.path);
        final map = {
          'database': {'connection': '{DB_URL:postgres://localhost}'},
          'api': {'key': '{API_KEY}'},
        };
        final result = TomEnv.resolveMap(map);
        expect(result['database']['connection'], 'postgres://localhost');
        expect(result['api']['key'], 'secret123');
      });

      test('resolves lists', () {
        final envFile = File('${tempDir.path}/.env');
        envFile.writeAsStringSync('BASE_URL=https://api.example.com');

        TomEnv.reload(tempDir.path);
        final map = {
          'urls': ['{BASE_URL}/v1', '{BASE_URL}/v2'],
        };
        final result = TomEnv.resolveMap(map);
        expect(result['urls'], [
          'https://api.example.com/v1',
          'https://api.example.com/v2',
        ]);
      });
    });

    group('resolveMapWith()', () {
      test('resolves with explicit environment', () {
        final env = {'USER': 'admin', 'PASS': 'secret'};
        final map = {
          'credentials': {'username': '{USER}', 'password': '{PASS}'},
        };
        final result = TomEnv.resolveMapWith(map, env);
        expect(result['credentials']['username'], 'admin');
        expect(result['credentials']['password'], 'secret');
      });
    });

    group('get()', () {
      test('returns environment variable value', () {
        // PATH should exist on all platforms
        final path = TomEnv.get('PATH') ?? TomEnv.get('Path');
        expect(path, isNotNull);
      });

      test('returns default when not set', () {
        expect(TomEnv.get('NONEXISTENT_VAR_12345'), isNull);
        expect(TomEnv.get('NONEXISTENT_VAR_12345', 'default'), 'default');
      });
    });

    group('require()', () {
      test('throws when variable not set', () {
        expect(
          () => TomEnv.require('NONEXISTENT_REQUIRED_VAR'),
          throwsA(isA<TomEnvironmentException>()),
        );
      });

      test('throws with custom message', () {
        expect(
          () => TomEnv.require('NONEXISTENT', message: 'Custom message'),
          throwsA(
            predicate<TomEnvironmentException>(
              (e) => e.message == 'Custom message',
            ),
          ),
        );
      });
    });

    group('has()', () {
      test('returns true for existing variable', () {
        expect(TomEnv.has('PATH') || TomEnv.has('Path'), isTrue);
      });

      test('returns false for missing variable', () {
        expect(TomEnv.has('NONEXISTENT_HAS_VAR'), isFalse);
      });
    });

    group('isSet()', () {
      test('returns false for missing variable', () {
        expect(TomEnv.isSet('NONEXISTENT_ISSET_VAR'), isFalse);
      });
    });

    group('all()', () {
      test('returns all environment variables', () {
        final all = TomEnv.all();
        expect(all, isNotEmpty);
        expect(all['PATH'] ?? all['Path'], isNotNull);
      });

      test('returns unmodifiable map', () {
        final all = TomEnv.all();
        expect(() => all['NEW_VAR'] = 'value', throwsUnsupportedError);
      });
    });

    group('withPrefix()', () {
      test('returns variables matching prefix', () {
        // Most systems have multiple PATH-related vars
        final pathVars = TomEnv.withPrefix('PATH');
        // May or may not have matches depending on system
        expect(pathVars, isA<Map<String, String>>());
      });
    });

    group('getInt()', () {
      test('returns default for non-existent variable', () {
        expect(TomEnv.getInt('NONEXISTENT_INT'), isNull);
        expect(TomEnv.getInt('NONEXISTENT_INT', 42), 42);
      });
    });

    group('getBool()', () {
      test('returns default for non-existent variable', () {
        expect(TomEnv.getBool('NONEXISTENT_BOOL'), isFalse);
        expect(TomEnv.getBool('NONEXISTENT_BOOL', true), isTrue);
      });
    });

    group('getList()', () {
      test('returns PATH as list', () {
        final pathList = TomEnv.path;
        expect(pathList, isNotEmpty);
      });

      test('returns empty list for missing variable', () {
        expect(TomEnv.getList('NONEXISTENT_LIST'), isEmpty);
      });
    });

    group('common variables', () {
      test('home returns user home directory', () {
        final home = TomEnv.home;
        expect(home, isNotNull);
        expect(Directory(home!).existsSync(), isTrue);
      });

      test('user returns current username', () {
        final user = TomEnv.user;
        expect(user, isNotNull);
        expect(user, isNotEmpty);
      });

      test('cwd returns current working directory', () {
        expect(TomEnv.cwd, isNotEmpty);
      });

      test('shell returns shell path on Unix', () {
        if (!Platform.isWindows) {
          final shell = TomEnv.shell;
          expect(shell, isNotNull);
        }
      });
    });

    group('platform info', () {
      test('os returns operating system name', () {
        expect(TomEnv.os, isNotEmpty);
        expect(['macos', 'linux', 'windows'], contains(TomEnv.os));
      });

      test('processors returns positive number', () {
        expect(TomEnv.processors, greaterThan(0));
      });

      test('hostname returns non-empty string', () {
        expect(TomEnv.hostname, isNotEmpty);
      });

      test('platform checks are consistent', () {
        final checks = [TomEnv.isMacOS, TomEnv.isLinux, TomEnv.isWindows];
        expect(checks.where((c) => c).length, 1);
      });
    });

    group('expand()', () {
      test('expands \$VAR syntax', () {
        // Use a variable that exists
        final home =
            Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
        if (home != null) {
          final result = TomEnv.expand(r'Home: $HOME');
          // Either expanded or kept as-is on Windows
          expect(result, anyOf(contains(home), equals(r'Home: ')));
        }
      });
    });

    group('expandWithDefaults()', () {
      test('expands \${VAR:-default} syntax', () {
        final result = TomEnv.expandWithDefaults(r'Port: ${MISSING:-8080}');
        expect(result, 'Port: 8080');
      });
    });

    group('environment detection', () {
      test('isCI returns boolean', () {
        expect(TomEnv.isCI, isA<bool>());
      });

      test('isDev returns boolean', () {
        expect(TomEnv.isDev, isA<bool>());
      });

      test('isProd returns boolean', () {
        expect(TomEnv.isProd, isA<bool>());
      });
    });
  });
}
