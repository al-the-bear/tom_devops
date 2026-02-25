import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

void main() {
  group('PlaceholderResolver', () {
    test('resolves simple path', () async {
      final resolver = PlaceholderResolver(
        data: {
          'packages': {
            'tom_core': {'version': '1.0.0'},
          },
        },
      );

      final result = await resolver.resolve('[{packages.tom_core.version}]');
      expect(result, equals('1.0.0'));
    });

    test('resolves with default value', () async {
      final resolver = PlaceholderResolver(
        data: {'packages': {}},
      );

      final result = await resolver.resolve('[{packages.missing.version:-0.0.0}]');
      expect(result, equals('0.0.0'));
    });

    test('resolves environment variables', () async {
      final resolver = PlaceholderResolver(
        data: {},
        environment: {'MY_VAR': 'test-value'},
      );

      final result = await resolver.resolve('Value: [[MY_VAR]]');
      expect(result, equals('Value: test-value'));
    });

    test('resolves mixed placeholders and env vars', () async {
      final resolver = PlaceholderResolver(
        data: {
          'app': {'name': 'MyApp'},
        },
        environment: {'VERSION': '1.2.3'},
      );

      final result = await resolver.resolve('[{app.name}] v[[VERSION]]');
      expect(result, equals('MyApp v1.2.3'));
    });

    test('resolves generator pattern with wildcard', () async {
      final resolver = PlaceholderResolver(
        data: {
          'packages': {
            'tom_core': {'version': '1.0.0'},
            'tom_build': {'version': '2.0.0'},
            'tom_tools': {'version': '3.0.0'},
          },
        },
      );

      final result = await resolver.resolve('[{packages.*.version:,}]');
      // Order may vary, so check contains
      expect(result, contains('1.0.0'));
      expect(result, contains('2.0.0'));
      expect(result, contains('3.0.0'));
      expect(result.split(',').length, equals(3));
    });

    test('resolves generator pattern with custom separator', () async {
      final resolver = PlaceholderResolver(
        data: {
          'packages': {
            'a': {'version': '1.0'},
            'b': {'version': '2.0'},
          },
        },
      );

      final result = await resolver.resolve('[{packages.*.version: | }]');
      expect(result.contains(' | '), isTrue);
    });

    test('resolves filter pattern with boolean filter', () async {
      final resolver = PlaceholderResolver(
        data: {
          'packages': {
            'tom_core': {'version': '1.0.0', 'publishable': true},
            'tom_build': {'version': '2.0.0', 'publishable': true},
            'tom_client': {'version': '3.0.0', 'publishable': false},
          },
        },
      );

      final result = await resolver.resolve('[{packages.[publishable:true].version:,}]');
      expect(result, contains('1.0.0'));
      expect(result, contains('2.0.0'));
      expect(result, isNot(contains('3.0.0')));
    });

    test('resolves filter pattern with name wildcard', () async {
      final resolver = PlaceholderResolver(
        data: {
          'packages': {
            'tom_core': {'version': '1.0.0'},
            'tom_build': {'version': '2.0.0'},
            'other_pkg': {'version': '3.0.0'},
          },
        },
      );

      final result = await resolver.resolve('[{packages.[name:tom_*].version:,}]');
      expect(result, contains('1.0.0'));
      expect(result, contains('2.0.0'));
      expect(result, isNot(contains('3.0.0')));
    });

    test('resolves complex filter with multiple conditions', () async {
      final resolver = PlaceholderResolver(
        data: {
          'packages': {
            'tom_core': {'version': '1.0.0', 'publishable': true},
            'tom_build': {'version': '2.0.0', 'publishable': false},
            'other_pkg': {'version': '3.0.0', 'publishable': true},
          },
        },
      );

      final result = await resolver.resolve(
        '[{packages.[publishable:true, name:tom_*].version:,}]',
      );
      expect(result, equals('1.0.0'));
    });

    test('returns empty for missing path', () async {
      final resolver = PlaceholderResolver(data: {});

      final result = await resolver.resolve('[{missing.path}]');
      expect(result, equals(''));
    });

    test('preserves non-placeholder text', () async {
      final resolver = PlaceholderResolver(
        data: {'key': 'value'},
      );

      final result = await resolver.resolve('prefix [{key}] suffix');
      expect(result, equals('prefix value suffix'));
    });

    test('resolves nested paths', () async {
      final resolver = PlaceholderResolver(
        data: {
          'level1': {
            'level2': {
              'level3': {'value': 'deep'},
            },
          },
        },
      );

      final result = await resolver.resolve('[{level1.level2.level3.value}]');
      expect(result, equals('deep'));
    });

    test('evaluates D4rt expression when evaluator provided', () async {
      final resolver = PlaceholderResolver(
        data: {},
        d4rtEvaluator: (expr) async => 'evaluated: $expr',
      );

      final result = await resolver.resolve('[{{ return 1 + 1; }}]');
      expect(result, contains('evaluated'));
    });

    test('handles D4rt method expression', () async {
      final resolver = PlaceholderResolver(
        data: {},
        d4rtEvaluator: (expr) async {
          if (expr.startsWith('(){')) {
            return 'method-result';
          }
          return 'expr-result';
        },
      );

      final result = await resolver.resolve('[{(){ return "ok"; }}]');
      expect(result, equals('method-result'));
    });

    test('handles missing D4rt evaluator', () async {
      final resolver = PlaceholderResolver(data: {});

      final result = await resolver.resolve('[{{ return 1; }}]');
      expect(result, contains('D4rt not available'));
    });
  });

  group('PackageInfo', () {
    test('creates from constructor', () {
      const pkg = PackageInfo(
        name: 'tom_core',
        version: '1.0.0',
        publishable: true,
        lastChangeCommit: 'abc123',
      );

      expect(pkg.name, equals('tom_core'));
      expect(pkg.version, equals('1.0.0'));
      expect(pkg.publishable, isTrue);
      expect(pkg.lastChangeCommit, equals('abc123'));
    });

    test('access by key operator', () {
      const pkg = PackageInfo(
        name: 'tom_core',
        version: '1.0.0',
        publishable: true,
        metadata: {'custom': 'value'},
      );

      expect(pkg['name'], equals('tom_core'));
      expect(pkg['version'], equals('1.0.0'));
      expect(pkg['publishable'], isTrue);
      expect(pkg['custom'], equals('value'));
    });

    test('converts to map', () {
      const pkg = PackageInfo(
        name: 'tom_core',
        version: '1.0.0',
        publishable: true,
        lastChangeCommit: 'abc123',
      );

      final map = pkg.toMap();
      expect(map['version'], equals('1.0.0'));
      expect(map['publishable'], isTrue);
      expect(map['last_change_commit'], equals('abc123'));
    });
  });

  group('loadEnvironmentWithDotEnv', () {
    // Note: These tests don't create actual .env files to avoid side effects
    // In real usage, the function reads from .env file
    
    test('returns platform environment when no .env file', () {
      final env = loadEnvironmentWithDotEnv('/nonexistent/.env');
      // Should at least have PATH or HOME
      expect(env.isNotEmpty, isTrue);
    });
  });
}
