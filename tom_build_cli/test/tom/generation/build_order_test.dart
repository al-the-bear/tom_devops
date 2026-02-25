import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/generation/build_order.dart';

void main() {
  group('BuildOrderCalculator', () {
    late BuildOrderCalculator calculator;

    setUp(() {
      calculator = BuildOrderCalculator();
    });

    group('Basic build order', () {
      test('handles empty project list', () {
        final order = calculator.calculateBuildOrder({});
        expect(order, isEmpty);
      });

      test('handles single project', () {
        final order = calculator.calculateBuildOrder({
          'core': const BuildOrderProject(name: 'core'),
        });
        expect(order, ['core']);
      });

      test('handles projects with no dependencies', () {
        final order = calculator.calculateBuildOrder({
          'a': const BuildOrderProject(name: 'a'),
          'b': const BuildOrderProject(name: 'b'),
          'c': const BuildOrderProject(name: 'c'),
        });
        // Should be alphabetically sorted for deterministic order
        expect(order, ['a', 'b', 'c']);
      });

      test('orders project after its dependency', () {
        final order = calculator.calculateBuildOrder({
          'app': const BuildOrderProject(name: 'app', buildAfter: ['core']),
          'core': const BuildOrderProject(name: 'core'),
        });
        expect(order.indexOf('core'), lessThan(order.indexOf('app')));
        expect(order, ['core', 'app']);
      });

      test('handles chain of dependencies', () {
        final order = calculator.calculateBuildOrder({
          'c': const BuildOrderProject(name: 'c', buildAfter: ['b']),
          'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
          'a': const BuildOrderProject(name: 'a'),
        });
        expect(order, ['a', 'b', 'c']);
      });

      test('handles multiple dependencies', () {
        final order = calculator.calculateBuildOrder({
          'app': const BuildOrderProject(name: 'app', buildAfter: ['core', 'utils']),
          'core': const BuildOrderProject(name: 'core'),
          'utils': const BuildOrderProject(name: 'utils'),
        });
        expect(order.indexOf('core'), lessThan(order.indexOf('app')));
        expect(order.indexOf('utils'), lessThan(order.indexOf('app')));
      });

      test('handles diamond dependency', () {
        // Diamond: a -> b, a -> c, b -> d, c -> d
        final order = calculator.calculateBuildOrder({
          'd': const BuildOrderProject(name: 'd', buildAfter: ['b', 'c']),
          'c': const BuildOrderProject(name: 'c', buildAfter: ['a']),
          'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
          'a': const BuildOrderProject(name: 'a'),
        });
        expect(order.indexOf('a'), lessThan(order.indexOf('b')));
        expect(order.indexOf('a'), lessThan(order.indexOf('c')));
        expect(order.indexOf('b'), lessThan(order.indexOf('d')));
        expect(order.indexOf('c'), lessThan(order.indexOf('d')));
      });

      test('maintains stable ordering for same-level projects', () {
        // Multiple runs should give same result
        for (var i = 0; i < 5; i++) {
          final order = calculator.calculateBuildOrder({
            'z': const BuildOrderProject(name: 'z'),
            'a': const BuildOrderProject(name: 'a'),
            'm': const BuildOrderProject(name: 'm'),
          });
          expect(order, ['a', 'm', 'z']); // Alphabetically sorted
        }
      });
    });

    group('Circular dependency detection', () {
      test('detects simple cycle', () {
        expect(
          () => calculator.calculateBuildOrder({
            'a': const BuildOrderProject(name: 'a', buildAfter: ['b']),
            'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
          }),
          throwsA(isA<CircularDependencyException>()),
        );
      });

      test('detects self-reference', () {
        expect(
          () => calculator.calculateBuildOrder({
            'a': const BuildOrderProject(name: 'a', buildAfter: ['a']),
          }),
          throwsA(isA<CircularDependencyException>()),
        );
      });

      test('detects longer cycle', () {
        expect(
          () => calculator.calculateBuildOrder({
            'a': const BuildOrderProject(name: 'a', buildAfter: ['c']),
            'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
            'c': const BuildOrderProject(name: 'c', buildAfter: ['b']),
          }),
          throwsA(isA<CircularDependencyException>()),
        );
      });

      test('includes cycle path in exception', () {
        try {
          calculator.calculateBuildOrder({
            'a': const BuildOrderProject(name: 'a', buildAfter: ['b']),
            'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
          });
          fail('Should throw');
        } on CircularDependencyException catch (e) {
          expect(e.cyclePath, isNotEmpty);
          expect(e.message, contains('Circular'));
        }
      });

      test('detects unknown dependency', () {
        expect(
          () => calculator.calculateBuildOrder({
            'a': const BuildOrderProject(name: 'a', buildAfter: ['nonexistent']),
          }),
          throwsA(isA<CircularDependencyException>()
              .having((e) => e.message, 'message', contains('unknown'))),
        );
      });
    });

    group('Safe calculation', () {
      test('returns success result for valid order', () {
        final result = calculator.calculateBuildOrderSafe({
          'a': const BuildOrderProject(name: 'a'),
          'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
        });
        expect(result.success, isTrue);
        expect(result.order, ['a', 'b']);
        expect(result.error, isNull);
      });

      test('returns error result for cycle', () {
        final result = calculator.calculateBuildOrderSafe({
          'a': const BuildOrderProject(name: 'a', buildAfter: ['b']),
          'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
        });
        expect(result.success, isFalse);
        expect(result.order, isEmpty);
        expect(result.error, isNotNull);
        expect(result.circularPath, isNotNull);
      });
    });

    group('Action-specific order', () {
      test('uses base order when no action deps', () {
        final order = calculator.calculateActionOrder(
          projects: {
            'a': const BuildOrderProject(name: 'a'),
            'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
          },
          action: 'build',
        );
        expect(order, ['a', 'b']);
      });

      test('merges action-specific dependencies', () {
        final order = calculator.calculateActionOrder(
          projects: {
            'a': const BuildOrderProject(name: 'a'),
            'b': const BuildOrderProject(name: 'b'),
            'c': const BuildOrderProject(name: 'c'),
          },
          action: 'test',
          actionDeps: {
            'c': ['a', 'b'], // c needs a and b for testing
          },
        );
        expect(order.indexOf('a'), lessThan(order.indexOf('c')));
        expect(order.indexOf('b'), lessThan(order.indexOf('c')));
      });

      test('combines base and action dependencies', () {
        final order = calculator.calculateActionOrder(
          projects: {
            'a': const BuildOrderProject(name: 'a'),
            'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
            'c': const BuildOrderProject(name: 'c'),
          },
          action: 'deploy',
          actionDeps: {
            'c': ['b'], // c needs b for deploy
          },
        );
        // b needs a (base), c needs b (action)
        expect(order, ['a', 'b', 'c']);
      });
    });

    group('Dependency validation', () {
      test('returns empty list for valid dependencies', () {
        final errors = calculator.validateDependencies({
          'a': const BuildOrderProject(name: 'a'),
          'b': const BuildOrderProject(name: 'b', buildAfter: ['a']),
        });
        expect(errors, isEmpty);
      });

      test('reports missing dependencies', () {
        final errors = calculator.validateDependencies({
          'a': const BuildOrderProject(name: 'a', buildAfter: ['missing']),
        });
        expect(errors, hasLength(1));
        expect(errors.first, contains('missing'));
      });

      test('reports multiple missing dependencies', () {
        final errors = calculator.validateDependencies({
          'a': const BuildOrderProject(name: 'a', buildAfter: ['x', 'y']),
          'b': const BuildOrderProject(name: 'b', buildAfter: ['z']),
        });
        expect(errors, hasLength(3));
      });
    });

    group('fromProjectConfigs', () {
      test('creates projects from config maps', () {
        final projects = BuildOrderCalculator.fromProjectConfigs({
          'core': {'name': 'core'},
          'app': {
            'name': 'app',
            'build-after': ['core']
          },
        });
        expect(projects['core']!.buildAfter, isEmpty);
        expect(projects['app']!.buildAfter, ['core']);
      });

      test('handles missing build-after', () {
        final projects = BuildOrderCalculator.fromProjectConfigs({
          'project': {'name': 'project', 'version': '1.0.0'},
        });
        expect(projects['project']!.buildAfter, isEmpty);
      });

      test('handles empty build-after list', () {
        final projects = BuildOrderCalculator.fromProjectConfigs({
          'project': {
            'name': 'project',
            'build-after': <String>[]
          },
        });
        expect(projects['project']!.buildAfter, isEmpty);
      });
    });

    group('Complex scenarios', () {
      test('handles real workspace structure', () {
        final order = calculator.calculateBuildOrder({
          'tom_core': const BuildOrderProject(name: 'tom_core'),
          'tom_core_kernel': const BuildOrderProject(
            name: 'tom_core_kernel',
            buildAfter: ['tom_core'],
          ),
          'tom_core_client': const BuildOrderProject(
            name: 'tom_core_client',
            buildAfter: ['tom_core_kernel'],
          ),
          'tom_core_server': const BuildOrderProject(
            name: 'tom_core_server',
            buildAfter: ['tom_core_kernel'],
          ),
          'tom_build': const BuildOrderProject(
            name: 'tom_build',
            buildAfter: ['tom_core'],
          ),
          'tom_uam_shared': const BuildOrderProject(
            name: 'tom_uam_shared',
            buildAfter: ['tom_core_kernel'],
          ),
          'tom_uam_client': const BuildOrderProject(
            name: 'tom_uam_client',
            buildAfter: ['tom_uam_shared', 'tom_core_client'],
          ),
          'tom_uam_server': const BuildOrderProject(
            name: 'tom_uam_server',
            buildAfter: ['tom_uam_shared', 'tom_core_server'],
          ),
        });

        // Verify ordering constraints
        expect(order.indexOf('tom_core'), lessThan(order.indexOf('tom_core_kernel')));
        expect(order.indexOf('tom_core_kernel'), lessThan(order.indexOf('tom_core_client')));
        expect(order.indexOf('tom_core_kernel'), lessThan(order.indexOf('tom_core_server')));
        expect(order.indexOf('tom_uam_shared'), lessThan(order.indexOf('tom_uam_client')));
        expect(order.indexOf('tom_uam_shared'), lessThan(order.indexOf('tom_uam_server')));
      });

      test('handles many independent projects', () {
        final projects = <String, BuildOrderProject>{};
        for (var i = 0; i < 50; i++) {
          projects['project_$i'] = BuildOrderProject(name: 'project_$i');
        }
        final order = calculator.calculateBuildOrder(projects);
        expect(order, hasLength(50));
      });

      test('handles deep dependency chain', () {
        final projects = <String, BuildOrderProject>{};
        for (var i = 0; i < 20; i++) {
          projects['level_$i'] = BuildOrderProject(
            name: 'level_$i',
            buildAfter: i > 0 ? ['level_${i - 1}'] : [],
          );
        }
        final order = calculator.calculateBuildOrder(projects);
        for (var i = 0; i < 19; i++) {
          expect(
            order.indexOf('level_$i'),
            lessThan(order.indexOf('level_${i + 1}')),
          );
        }
      });
    });
  });
}
