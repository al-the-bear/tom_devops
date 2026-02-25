/// Comprehensive tests for ConfigMerger (Section 3.2.3)
///
/// Tests deep merge functionality and YAML list operations according to
/// the Tom CLI specification.
library;

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/config/config_merger.dart';

void main() {
  late ConfigMerger merger;

  setUp(() {
    merger = ConfigMerger();
  });

  // ===========================================================================
  // Section 3.2.3 - YAML Deep Merge Semantics
  // ===========================================================================

  group('Section 3.2.3 - YAML Deep Merge Semantics', () {
    group('Basic Deep Merge', () {
      test('preserves keys only in base', () {
        final base = {'a': 1, 'b': 2};
        final override = {'c': 3};
        final result = merger.deepMerge(base, override);
        expect(result, equals({'a': 1, 'b': 2, 'c': 3}));
      });

      test('overrides scalar values', () {
        final base = {'a': 1, 'b': 2};
        final override = {'b': 3};
        final result = merger.deepMerge(base, override);
        expect(result, equals({'a': 1, 'b': 3}));
      });

      test('adds new keys from override', () {
        final base = {'a': 1};
        final override = {'b': 2, 'c': 3};
        final result = merger.deepMerge(base, override);
        expect(result, equals({'a': 1, 'b': 2, 'c': 3}));
      });

      test('replaces lists entirely (not concatenates)', () {
        final base = <String, dynamic>{
          'items': [1, 2, 3]
        };
        final override = <String, dynamic>{
          'items': [4, 5]
        };
        final result = merger.deepMerge(base, override);
        expect(result['items'], equals([4, 5]));
      });

      test('merges nested maps recursively', () {
        final base = {
          'config': {
            'a': 1,
            'b': 2,
          }
        };
        final override = {
          'config': {
            'b': 3,
            'c': 4,
          }
        };
        final result = merger.deepMerge(base, override);
        expect(result['config'], equals({'a': 1, 'b': 3, 'c': 4}));
      });

      test('deeply nested merge preserves structure', () {
        final base = {
          'level1': {
            'level2': {
              'level3': {
                'a': 1,
                'b': 2,
              }
            }
          }
        };
        final override = {
          'level1': {
            'level2': {
              'level3': {
                'b': 3,
                'c': 4,
              }
            }
          }
        };
        final result = merger.deepMerge(base, override);
        expect(
          result['level1']['level2']['level3'],
          equals({'a': 1, 'b': 3, 'c': 4}),
        );
      });

      test('override with null removes key', () {
        final base = {'a': 1, 'b': 2};
        final override = {'b': null};
        final result = merger.deepMerge(base, override);
        expect(result['b'], isNull);
      });

      test('empty override returns copy of base', () {
        final base = {'a': 1, 'b': 2};
        final result = merger.deepMerge(base, {});
        expect(result, equals({'a': 1, 'b': 2}));
      });

      test('empty base returns copy of override', () {
        final override = {'a': 1, 'b': 2};
        final result = merger.deepMerge({}, override);
        expect(result, equals({'a': 1, 'b': 2}));
      });

      test('both empty returns empty map', () {
        final result = merger.deepMerge({}, {});
        expect(result, isEmpty);
      });
    });

    group('Type Handling', () {
      test('handles string values', () {
        final base = {'name': 'base'};
        final override = {'name': 'override'};
        final result = merger.deepMerge(base, override);
        expect(result['name'], equals('override'));
      });

      test('handles boolean values', () {
        final base = {'enabled': false};
        final override = {'enabled': true};
        final result = merger.deepMerge(base, override);
        expect(result['enabled'], isTrue);
      });

      test('handles numeric values', () {
        final base = {'count': 10, 'ratio': 1.5};
        final override = {'count': 20, 'ratio': 2.5};
        final result = merger.deepMerge(base, override);
        expect(result['count'], equals(20));
        expect(result['ratio'], equals(2.5));
      });

      test('handles mixed type override', () {
        final base = {'value': 'string'};
        final override = {'value': 42};
        final result = merger.deepMerge(base, override);
        expect(result['value'], equals(42));
      });

      test('handles list of maps', () {
        final base = {
          'items': [
            {'id': 1},
            {'id': 2}
          ]
        };
        final override = {
          'items': [
            {'id': 3}
          ]
        };
        final result = merger.deepMerge(base, override);
        expect(result['items'], hasLength(1));
        expect(result['items'][0]['id'], equals(3));
      });

      test('handles map to list override', () {
        final base = {
          'data': {'a': 1}
        };
        final override = {
          'data': [1, 2, 3]
        };
        final result = merger.deepMerge(base, override);
        expect(result['data'], equals([1, 2, 3]));
      });

      test('handles list to map override', () {
        final base = {
          'data': [1, 2, 3]
        };
        final override = {
          'data': {'a': 1}
        };
        final result = merger.deepMerge(base, override);
        expect(result['data'], equals({'a': 1}));
      });
    });

    group('Deep Copy Verification', () {
      test('result is independent of base', () {
        final base = {
          'nested': {'value': 1}
        };
        final override = {'other': 2};
        final result = merger.deepMerge(base, override);

        // Modify base
        base['nested']!['value'] = 999;

        // Result should be unchanged
        expect(result['nested']['value'], equals(1));
      });

      test('result is independent of override', () {
        final base = {'a': 1};
        final override = {
          'nested': {'value': 2}
        };
        final result = merger.deepMerge(base, override);

        // Modify override
        override['nested']!['value'] = 999;

        // Result should be unchanged
        expect(result['nested']['value'], equals(2));
      });

      test('nested lists are deep copied', () {
        final base = {'a': 1};
        final override = {
          'items': [
            {'id': 1}
          ]
        };
        final result = merger.deepMerge(base, override);

        // Modify override list
        (override['items'] as List).add({'id': 2});

        // Result should be unchanged
        expect(result['items'], hasLength(1));
      });
    });
  });

  // ===========================================================================
  // mergeAll Tests
  // ===========================================================================

  group('mergeAll', () {
    test('returns empty map for empty list', () {
      final result = merger.mergeAll([]);
      expect(result, isEmpty);
    });

    test('returns copy of single config', () {
      final config = {'a': 1, 'b': 2};
      final result = merger.mergeAll([config]);
      expect(result, equals({'a': 1, 'b': 2}));
    });

    test('merges two configs with later taking precedence', () {
      final configs = [
        {'a': 1, 'b': 2},
        {'b': 3, 'c': 4},
      ];
      final result = merger.mergeAll(configs);
      expect(result, equals({'a': 1, 'b': 3, 'c': 4}));
    });

    test('merges three configs in order', () {
      final configs = [
        {'value': 1},
        {'value': 2},
        {'value': 3},
      ];
      final result = merger.mergeAll(configs);
      expect(result['value'], equals(3));
    });

    test('merges complex nested configs', () {
      final configs = [
        {
          'settings': {'a': 1, 'b': 2}
        },
        {
          'settings': {'b': 3, 'c': 4}
        },
        {
          'settings': {'c': 5}
        },
      ];
      final result = merger.mergeAll(configs);
      expect(result['settings'], equals({'a': 1, 'b': 3, 'c': 5}));
    });
  });

  // ===========================================================================
  // Section 5.2.3 - Configuration Merge Sequence
  // ===========================================================================

  group('Section 5.2.3 - mergeProjectConfig', () {
    test('returns empty map when all params null', () {
      final result = merger.mergeProjectConfig();
      expect(result, isEmpty);
    });

    test('applies auto-detected values first', () {
      final result = merger.mergeProjectConfig(
        autoDetected: {'type': 'dart_package', 'has-tests': true},
      );
      expect(result['type'], equals('dart_package'));
      expect(result['has-tests'], isTrue);
    });

    test('project type defaults override auto-detected', () {
      final result = merger.mergeProjectConfig(
        autoDetected: {'publishable': false},
        projectTypeDefaults: {'publishable': true},
      );
      expect(result['publishable'], isTrue);
    });

    test('group overrides override project type defaults', () {
      final result = merger.mergeProjectConfig(
        projectTypeDefaults: {'cloud-provider': 'aws'},
        groupOverrides: {'cloud-provider': 'gcp'},
      );
      expect(result['cloud-provider'], equals('gcp'));
    });

    test('workspace defaults override group overrides', () {
      final result = merger.mergeProjectConfig(
        groupOverrides: {'deployment': 'docker'},
        workspaceDefaults: {'deployment': 'kubernetes'},
      );
      expect(result['deployment'], equals('kubernetes'));
    });

    test('project overrides override workspace defaults', () {
      final result = merger.mergeProjectConfig(
        workspaceDefaults: {'binaries': 'bin/'},
        projectOverrides: {'binaries': 'build/'},
      );
      expect(result['binaries'], equals('build/'));
    });

    test('global CLI params override project overrides', () {
      final result = merger.mergeProjectConfig(
        projectOverrides: {'verbose': false},
        globalCliParams: {'verbose': true},
      );
      expect(result['verbose'], isTrue);
    });

    test('target CLI params have highest priority', () {
      final result = merger.mergeProjectConfig(
        globalCliParams: {'environment': 'local'},
        targetCliParams: {'environment': 'prod'},
      );
      expect(result['environment'], equals('prod'));
    });

    test('full merge sequence applies correctly', () {
      final result = merger.mergeProjectConfig(
        autoDetected: {
          'type': 'dart_package',
          'has-tests': true,
          'name': 'detected',
        },
        projectTypeDefaults: {
          'publishable': true,
          'name': 'type-default',
        },
        groupOverrides: {
          'cloud-provider': 'aws',
          'name': 'group',
        },
        workspaceDefaults: {
          'deployment': 'none',
          'name': 'workspace',
        },
        projectOverrides: {
          'binaries': 'build/',
          'name': 'project',
        },
        globalCliParams: {
          'verbose': true,
          'name': 'global-cli',
        },
        targetCliParams: {
          'environment': 'prod',
          'name': 'target-cli',
        },
      );

      // Last value wins for 'name'
      expect(result['name'], equals('target-cli'));
      // Auto-detected preserved
      expect(result['type'], equals('dart_package'));
      expect(result['has-tests'], isTrue);
      // Type defaults
      expect(result['publishable'], isTrue);
      // Group overrides
      expect(result['cloud-provider'], equals('aws'));
      // Workspace defaults
      expect(result['deployment'], equals('none'));
      // Project overrides
      expect(result['binaries'], equals('build/'));
      // CLI params
      expect(result['verbose'], isTrue);
      expect(result['environment'], equals('prod'));
    });
  });

  // ===========================================================================
  // Merge Utilities
  // ===========================================================================

  group('mergeStringLists utility', () {
    test('returns empty list when both null', () {
      final result = mergeStringLists(null, null);
      expect(result, isEmpty);
    });

    test('returns copy of base when override null', () {
      final result = mergeStringLists(['a', 'b'], null);
      expect(result, equals(['a', 'b']));
    });

    test('returns copy of override when base null', () {
      final result = mergeStringLists(null, ['c', 'd']);
      expect(result, equals(['c', 'd']));
    });

    test('merges lists removing duplicates', () {
      final result = mergeStringLists(['a', 'b'], ['b', 'c']);
      expect(result, equals(['a', 'b', 'c']));
    });

    test('preserves order from base', () {
      final result = mergeStringLists(['c', 'a', 'b'], ['d']);
      expect(result, equals(['c', 'a', 'b', 'd']));
    });

    test('handles empty base', () {
      final result = mergeStringLists([], ['a', 'b']);
      expect(result, equals(['a', 'b']));
    });

    test('handles empty override', () {
      final result = mergeStringLists(['a', 'b'], []);
      expect(result, equals(['a', 'b']));
    });

    test('handles both empty', () {
      final result = mergeStringLists([], []);
      expect(result, isEmpty);
    });
  });

  group('mergeDeps utility', () {
    test('returns empty map when both null', () {
      final result = mergeDeps(null, null);
      expect(result, isEmpty);
    });

    test('returns copy of base when override null', () {
      final result = mergeDeps({'a': '1.0.0'}, null);
      expect(result, equals({'a': '1.0.0'}));
    });

    test('returns copy of override when base null', () {
      final result = mergeDeps(null, {'b': '2.0.0'});
      expect(result, equals({'b': '2.0.0'}));
    });

    test('merges deps with override taking precedence', () {
      final result = mergeDeps(
        {'a': '1.0.0', 'b': '1.0.0'},
        {'b': '2.0.0', 'c': '3.0.0'},
      );
      expect(result, equals({'a': '1.0.0', 'b': '2.0.0', 'c': '3.0.0'}));
    });

    test('handles empty base', () {
      final result = mergeDeps({}, {'a': '1.0.0'});
      expect(result, equals({'a': '1.0.0'}));
    });

    test('handles empty override', () {
      final result = mergeDeps({'a': '1.0.0'}, {});
      expect(result, equals({'a': '1.0.0'}));
    });

    test('handles both empty', () {
      final result = mergeDeps({}, {});
      expect(result, isEmpty);
    });
  });

  // ===========================================================================
  // Edge Cases
  // ===========================================================================

  group('Edge Cases', () {
    test('handles deeply nested null values', () {
      final base = {
        'level1': {
          'level2': {'value': 1}
        }
      };
      final override = {
        'level1': {
          'level2': {'value': null}
        }
      };
      final result = merger.deepMerge(base, override);
      expect(result['level1']['level2']['value'], isNull);
    });

    test('handles mixed nested structures', () {
      final base = {
        'config': {
          'list': [1, 2, 3],
          'map': {'a': 1},
          'scalar': 'value',
        }
      };
      final override = {
        'config': {
          'list': [4, 5],
          'map': {'b': 2},
          'new': 'added',
        }
      };
      final result = merger.deepMerge(base, override);
      expect(result['config']['list'], equals([4, 5]));
      expect(result['config']['map'], equals({'a': 1, 'b': 2}));
      expect(result['config']['scalar'], equals('value'));
      expect(result['config']['new'], equals('added'));
    });

    test('handles special characters in keys', () {
      final base = {'key-with-dash': 1, 'key.with.dot': 2};
      final override = {'key-with-dash': 3};
      final result = merger.deepMerge(base, override);
      expect(result['key-with-dash'], equals(3));
      expect(result['key.with.dot'], equals(2));
    });

    test('handles unicode values', () {
      final base = {'name': 'base'};
      final override = {'name': 'überschreibung'};
      final result = merger.deepMerge(base, override);
      expect(result['name'], equals('überschreibung'));
    });
  });
}
