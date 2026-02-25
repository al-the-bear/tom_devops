/// Tests for Maps scripting helper.
library;

import 'package:test/test.dart';
import 'package:tom_build/scripting.dart';

void main() {
  group('Maps', () {
    group('mergeOneSided', () {
      test('merges flat maps', () {
        final target = {'a': 1, 'b': 2};
        final source = {'b': 3, 'c': 4};

        TomMaps.mergeOneSided(target, source);

        expect(target, {'a': 1, 'b': 3, 'c': 4});
      });

      test('merges nested maps recursively', () {
        final target = {
          'config': {'debug': false, 'timeout': 30},
        };
        final source = {
          'config': {'debug': true, 'retries': 3},
        };

        TomMaps.mergeOneSided(target, source);

        expect(target['config'], {'debug': true, 'timeout': 30, 'retries': 3});
      });

      test('replaces lists instead of merging them', () {
        final target = <String, dynamic>{
          'items': <dynamic>[1, 2, 3],
        };
        final source = <String, dynamic>{
          'items': <dynamic>[4, 5],
        };

        TomMaps.mergeOneSided(target, source);

        expect(target['items'], [4, 5]);
      });

      test('deep copies source values', () {
        final sourceNested = {'inner': 'value'};
        final source = {'nested': sourceNested};
        final target = <String, dynamic>{};

        TomMaps.mergeOneSided(target, source);
        sourceNested['inner'] = 'changed';

        expect(target['nested']['inner'], 'value');
      });
    });

    group('merge', () {
      test('creates new map without modifying originals', () {
        final base = {'a': 1};
        final overrides = {'b': 2};

        final result = TomMaps.merge(base, overrides);

        expect(result, {'a': 1, 'b': 2});
        expect(base, {'a': 1});
        expect(overrides, {'b': 2});
      });
    });

    group('mergeAll', () {
      test('merges multiple maps in order', () {
        final result = TomMaps.mergeAll([
          {'a': 1, 'b': 1},
          {'b': 2, 'c': 2},
          {'c': 3, 'd': 3},
        ]);

        expect(result, {'a': 1, 'b': 2, 'c': 3, 'd': 3});
      });
    });

    group('traverse', () {
      test('visits all leaf values', () {
        final visited = <String>[];
        final map = {
          'a': 1,
          'b': {'c': 2, 'd': 3},
        };

        TomMaps.traverse(map, (key, value) {
          visited.add('$key=$value');
          return null;
        });

        expect(visited, containsAll(['a=1', 'b.c=2', 'b.d=3']));
      });

      test('transforms values when processor returns non-null', () {
        final map = {'a': 'hello', 'b': 'world'};

        TomMaps.traverse(map, (key, value) {
          if (value is String) return value.toUpperCase();
          return null;
        });

        expect(map, {'a': 'HELLO', 'b': 'WORLD'});
      });

      test('traverses lists', () {
        final map = <String, dynamic>{
          'items': <dynamic>['a', 'b'],
        };

        TomMaps.traverse(map, (key, value) {
          if (value is String) return value.toUpperCase();
          return null;
        });

        expect(map['items'], ['A', 'B']);
      });
    });

    group('flatten', () {
      test('flattens nested map to dot notation', () {
        final map = {
          'a': 1,
          'b': {
            'c': 2,
            'd': {'e': 3},
          },
        };

        final result = TomMaps.flatten(map);

        expect(result, {'a': 1, 'b.c': 2, 'b.d.e': 3});
      });
    });

    group('get', () {
      test('gets value by dot path', () {
        final map = {
          'a': {
            'b': {'c': 'value'},
          },
        };

        expect(TomMaps.get(map, 'a.b.c'), 'value');
        expect(TomMaps.get(map, 'a.b'), {'c': 'value'});
        expect(TomMaps.get(map, 'a'), {
          'b': {'c': 'value'},
        });
      });

      test('returns null for missing path', () {
        final map = {'a': 1};

        expect(TomMaps.get(map, 'missing'), isNull);
        expect(TomMaps.get(map, 'a.b.c'), isNull);
      });

      test('handles type checking', () {
        final map = {'value': 42};

        expect(TomMaps.get<int>(map, 'value'), 42);
        expect(TomMaps.get<String>(map, 'value'), isNull);
      });
    });

    group('getOr', () {
      test('returns value when present', () {
        final map = {'key': 'value'};
        expect(TomMaps.getOr(map, 'key', 'default'), 'value');
      });

      test('returns default when missing', () {
        final map = <String, dynamic>{};
        expect(TomMaps.getOr(map, 'missing', 'default'), 'default');
      });
    });

    group('set', () {
      test('sets value at dot path', () {
        final map = <String, dynamic>{};

        TomMaps.set(map, 'a.b.c', 'value');

        expect(map['a']['b']['c'], 'value');
      });

      test('creates intermediate maps', () {
        final map = <String, dynamic>{};

        TomMaps.set(map, 'deep.nested.path', 42);

        expect(map['deep'], isA<Map<String, dynamic>>());
        expect(map['deep']['nested'], isA<Map<String, dynamic>>());
        expect(map['deep']['nested']['path'], 42);
      });

      test('overwrites existing values', () {
        final map = {'key': 'old'};

        TomMaps.set(map, 'key', 'new');

        expect(map['key'], 'new');
      });
    });

    group('has', () {
      test('returns true for existing path', () {
        final map = {
          'a': {'b': 1},
        };

        expect(TomMaps.has(map, 'a'), isTrue);
        expect(TomMaps.has(map, 'a.b'), isTrue);
      });

      test('returns false for missing path', () {
        final map = {'a': 1};

        expect(TomMaps.has(map, 'missing'), isFalse);
        expect(TomMaps.has(map, 'a.b'), isFalse);
      });
    });

    group('remove', () {
      test('removes value at path', () {
        final map = {
          'a': {'b': 1, 'c': 2},
        };

        final removed = TomMaps.remove(map, 'a.b');

        expect(removed, 1);
        expect(map['a'], {'c': 2});
      });

      test('returns null for missing path', () {
        final map = {'a': 1};
        expect(TomMaps.remove(map, 'missing'), isNull);
      });
    });

    group('copy', () {
      test('creates deep copy', () {
        final original = {
          'nested': {'value': 1},
          'list': [1, 2, 3],
        };

        final copy = TomMaps.copy(original);
        (copy['nested'] as Map)['value'] = 999;
        (copy['list'] as List).add(4);

        expect((original['nested'] as Map)['value'], 1);
        expect(original['list'], [1, 2, 3]);
      });
    });

    group('clean', () {
      test('converts loose map to Map<String, dynamic>', () {
        final loose = <dynamic, dynamic>{
          'string': 'value',
          123: 'ignored', // Non-string keys are filtered
          'nested': {'inner': 'value'},
        };

        final result = TomMaps.clean(loose);

        expect(result, isA<Map<String, dynamic>>());
        expect(result['string'], 'value');
        expect(result.containsKey('123'), isFalse);
        expect(result['nested'], isA<Map<String, dynamic>>());
      });
    });

    group('pick', () {
      test('returns map with only specified keys', () {
        final user = {
          'id': 1,
          'name': 'John',
          'email': 'john@example.com',
          'password': 'secret',
        };

        final result = TomMaps.pick(user, ['id', 'name', 'email']);

        expect(result, {'id': 1, 'name': 'John', 'email': 'john@example.com'});
        expect(result.containsKey('password'), isFalse);
      });

      test('ignores keys that do not exist', () {
        final map = {'a': 1, 'b': 2};

        final result = TomMaps.pick(map, ['a', 'c', 'd']);

        expect(result, {'a': 1});
      });

      test('returns empty map if no keys match', () {
        final map = {'a': 1};

        final result = TomMaps.pick(map, ['x', 'y']);

        expect(result, isEmpty);
      });
    });

    group('omit', () {
      test('returns map without specified keys', () {
        final user = {
          'id': 1,
          'name': 'John',
          'password': 'secret',
        };

        final result = TomMaps.omit(user, ['password']);

        expect(result, {'id': 1, 'name': 'John'});
        expect(result.containsKey('password'), isFalse);
      });

      test('ignores keys that do not exist', () {
        final map = {'a': 1, 'b': 2};

        final result = TomMaps.omit(map, ['c', 'd']);

        expect(result, {'a': 1, 'b': 2});
      });

      test('returns empty map if all keys are omitted', () {
        final map = {'a': 1, 'b': 2};

        final result = TomMaps.omit(map, ['a', 'b']);

        expect(result, isEmpty);
      });
    });
  });
}
