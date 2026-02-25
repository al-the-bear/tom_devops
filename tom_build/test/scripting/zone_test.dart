/// Tests for Zone scripting helper.
library;

import 'dart:async' as async;

import 'package:test/test.dart';
import 'package:tom_build/scripting.dart';

void main() {
  group('Zone', () {
    group('get<T>', () {
      test('returns value by type key', () {
        async.runZoned(() {
          final result = TomZoned.get<String>();
          expect(result, 'test value');
        }, zoneValues: {String: 'test value'});
      });

      test('returns value by name key', () {
        async.runZoned(() {
          final result = TomZoned.get<String>('myKey');
          expect(result, 'named value');
        }, zoneValues: {'myKey': 'named value'});
      });

      test('returns null when key not found', () {
        final result = TomZoned.get<String>('nonexistent');
        expect(result, isNull);
      });

      test('returns null when type does not match', () {
        async.runZoned(() {
          final result = TomZoned.get<int>('myKey');
          expect(result, isNull);
        }, zoneValues: {'myKey': 'string value'});
      });
    });

    group('getByKey', () {
      test('returns value by any key', () {
        async.runZoned(() {
          expect(TomZoned.getByKey('stringKey'), 'string value');
          expect(TomZoned.getByKey(42), 'int key value');
        }, zoneValues: {'stringKey': 'string value', 42: 'int key value'});
      });

      test('returns null for missing key', () {
        expect(TomZoned.getByKey('missing'), isNull);
      });
    });

    group('has', () {
      test('returns true when key exists', () {
        async.runZoned(() {
          expect(TomZoned.has('exists'), isTrue);
        }, zoneValues: {'exists': 'value'});
      });

      test('returns false when key does not exist', () {
        expect(TomZoned.has('missing'), isFalse);
      });
    });

    group('hasType<T>', () {
      test('returns true when type key exists', () {
        async.runZoned(() {
          expect(TomZoned.hasType<String>(), isTrue);
        }, zoneValues: {String: 'typed value'});
      });

      test('returns false when type key does not exist', () {
        expect(TomZoned.hasType<DateTime>(), isFalse);
      });
    });

    group('run', () {
      test('executes body with zone values', () {
        final result = TomZoned.run({'key': 'value'}, () {
          return TomZoned.get<String>('key');
        });
        expect(result, 'value');
      });

      test('supports nested runs', () {
        TomZoned.run({'outer': 'outer-value'}, () {
          TomZoned.run({'inner': 'inner-value'}, () {
            expect(TomZoned.get<String>('outer'), 'outer-value');
            expect(TomZoned.get<String>('inner'), 'inner-value');
          });
        });
      });

      test('inner zone can override outer values', () {
        TomZoned.run({'key': 'outer'}, () {
          TomZoned.run({'key': 'inner'}, () {
            expect(TomZoned.get<String>('key'), 'inner');
          });
          expect(TomZoned.get<String>('key'), 'outer');
        });
      });
    });

    group('runAsync', () {
      test('executes async body with zone values', () async {
        final result = await TomZoned.runAsync({'key': 'async-value'}, () async {
          await Future.delayed(Duration.zero);
          return TomZoned.get<String>('key');
        });
        expect(result, 'async-value');
      });
    });

    group('runGuarded', () {
      test('provides zone values in guarded zone', () {
        String? capturedValue;

        TomZoned.runGuarded(
          () {
            capturedValue = TomZoned.get<String>('key');
          },
          onError: (_, __) {},
          values: {'key': 'guarded-value'},
        );

        expect(capturedValue, 'guarded-value');
      });
    });

    group('current and root', () {
      test('current returns current zone', () {
        expect(TomZoned.current, isNotNull);
        expect(TomZoned.current, isA<async.Zone>());
      });

      test('root returns root zone', () {
        expect(TomZoned.root, isNotNull);
        expect(TomZoned.root, async.Zone.root);
      });
    });
  });
}
