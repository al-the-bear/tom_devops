import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/generation/placeholder_resolver.dart';

void main() {
  group('PlaceholderResolver', () {
    late PlaceholderResolver resolver;

    setUp(() {
      resolver = PlaceholderResolver();
    });

    group('Basic resolution', () {
      test(r'resolves simple $VAL{key} placeholder', () {
        final result = resolver.resolve(
          content: r'Hello $VAL{name}',
          context: {'name': 'World'},
        );
        expect(result.value, 'Hello World');
        expect(result.fullyResolved, isTrue);
      });

      test('resolves multiple placeholders in same string', () {
        final result = resolver.resolve(
          content: r'$VAL{greeting} $VAL{name}!',
          context: {'greeting': 'Hello', 'name': 'World'},
        );
        expect(result.value, 'Hello World!');
        expect(result.fullyResolved, isTrue);
      });

      test(r'resolves nested path $VAL{a.b.c}', () {
        final result = resolver.resolve(
          content: r'Version: $VAL{project.settings.version}',
          context: {
            'project': {
              'settings': {'version': '1.0.0'}
            }
          },
        );
        expect(result.value, 'Version: 1.0.0');
        expect(result.fullyResolved, isTrue);
      });

      test('resolves deeply nested paths', () {
        final result = resolver.resolve(
          content: r'$VAL{a.b.c.d.e}',
          context: {
            'a': {
              'b': {
                'c': {
                  'd': {'e': 'deep-value'}
                }
              }
            }
          },
        );
        expect(result.value, 'deep-value');
        expect(result.fullyResolved, isTrue);
      });

      test('preserves text without placeholders', () {
        final result = resolver.resolve(
          content: 'No placeholders here',
          context: {'ignored': 'value'},
        );
        expect(result.value, 'No placeholders here');
        expect(result.fullyResolved, isTrue);
      });

      test('resolves integer values', () {
        final result = resolver.resolve(
          content: r'Count: $VAL{count}',
          context: {'count': 42},
        );
        expect(result.value, 'Count: 42');
      });

      test('resolves boolean values', () {
        final result = resolver.resolve(
          content: r'Enabled: $VAL{enabled}',
          context: {'enabled': true},
        );
        expect(result.value, 'Enabled: true');
      });

      test('resolves double values', () {
        final result = resolver.resolve(
          content: r'Price: $VAL{price}',
          context: {'price': 19.99},
        );
        expect(result.value, 'Price: 19.99');
      });
    });

    group('Default values', () {
      test('uses default when key not found', () {
        final result = resolver.resolve(
          content: r'Version: $VAL{version:-1.0.0}',
          context: {},
        );
        expect(result.value, 'Version: 1.0.0');
        expect(result.fullyResolved, isTrue);
      });

      test('uses resolved value when key exists', () {
        final result = resolver.resolve(
          content: r'Version: $VAL{version:-1.0.0}',
          context: {'version': '2.0.0'},
        );
        expect(result.value, 'Version: 2.0.0');
      });

      test('handles empty default value', () {
        final result = resolver.resolve(
          content: r'Value: $VAL{missing:-}',
          context: {},
        );
        expect(result.value, 'Value: ');
        expect(result.fullyResolved, isTrue);
      });

      test('handles default with special characters', () {
        final result = resolver.resolve(
          content: r'URL: $VAL{url:-https://example.com/path?q=1}',
          context: {},
        );
        expect(result.value, 'URL: https://example.com/path?q=1');
      });

      test('uses default for partial path not found', () {
        final result = resolver.resolve(
          content: r'Name: $VAL{project.name:-unknown}',
          context: {'project': {}},
        );
        expect(result.value, 'Name: unknown');
      });
    });

    group('Map resolution', () {
      test('resolves placeholders in map values', () {
        final result = resolver.resolve(
          content: {
            'greeting': r'Hello $VAL{name}',
            'farewell': r'Goodbye $VAL{name}',
          },
          context: {'name': 'World'},
        );
        expect(result.value, {
          'greeting': 'Hello World',
          'farewell': 'Goodbye World',
        });
        expect(result.fullyResolved, isTrue);
      });

      test('resolves placeholders in map keys', () {
        final result = resolver.resolve(
          content: {r'$VAL{prefix}_key': 'value'},
          context: {'prefix': 'my'},
        );
        expect(result.value, {'my_key': 'value'});
      });

      test('resolves nested maps', () {
        final result = resolver.resolve(
          content: {
            'outer': {
              'inner': r'$VAL{value}'
            }
          },
          context: {'value': 'resolved'},
        );
        expect(result.value, {
          'outer': {'inner': 'resolved'}
        });
      });

      test('handles empty maps', () {
        final result = resolver.resolve(
          content: <String, dynamic>{},
          context: {'ignored': 'value'},
        );
        expect(result.value, <String, dynamic>{});
        expect(result.fullyResolved, isTrue);
      });
    });

    group('List resolution', () {
      test('resolves placeholders in list items', () {
        final result = resolver.resolve(
          content: [r'$VAL{a}', r'$VAL{b}', r'$VAL{c}'],
          context: {'a': '1', 'b': '2', 'c': '3'},
        );
        expect(result.value, ['1', '2', '3']);
        expect(result.fullyResolved, isTrue);
      });

      test('resolves mixed list types', () {
        final result = resolver.resolve(
          content: [r'$VAL{name}', 42, true, null],
          context: {'name': 'test'},
        );
        expect(result.value, ['test', 42, true, null]);
      });

      test('resolves nested lists', () {
        final result = resolver.resolve(
          content: [
            [r'$VAL{a}', r'$VAL{b}'],
            [r'$VAL{c}']
          ],
          context: {'a': '1', 'b': '2', 'c': '3'},
        );
        expect(result.value, [
          ['1', '2'],
          ['3']
        ]);
      });

      test('handles empty lists', () {
        final result = resolver.resolve(
          content: <dynamic>[],
          context: {'ignored': 'value'},
        );
        expect(result.value, <dynamic>[]);
        expect(result.fullyResolved, isTrue);
      });
    });

    group('Recursive resolution', () {
      test('resolves placeholder that resolves to another placeholder', () {
        final result = resolver.resolve(
          content: r'$VAL{ref}',
          context: {
            'ref': r'$VAL{actual}',
            'actual': 'final-value',
          },
        );
        expect(result.value, 'final-value');
        expect(result.fullyResolved, isTrue);
        // 3 iterations: resolve ref -> actual, resolve actual -> value, verify no more
        expect(result.iterations, 3);
      });

      test('resolves multi-level recursion', () {
        final result = resolver.resolve(
          content: r'$VAL{level1}',
          context: {
            'level1': r'$VAL{level2}',
            'level2': r'$VAL{level3}',
            'level3': 'deep-value',
          },
        );
        expect(result.value, 'deep-value');
        // 4 iterations: level1->level2, level2->level3, level3->value, verify
        expect(result.iterations, 4);
      });

      test('resolves up to 10 levels', () {
        final context = <String, dynamic>{};
        for (var i = 1; i <= 9; i++) {
          context['level$i'] = '\$VAL{level${i + 1}}';
        }
        context['level10'] = 'final';

        final result = resolver.resolve(
          content: r'$VAL{level1}',
          context: context,
        );
        expect(result.value, 'final');
        expect(result.iterations, lessThanOrEqualTo(10));
      });

      test('throws on circular reference', () {
        expect(
          () => resolver.resolve(
            content: r'$VAL{a}',
            context: {
              'a': r'$VAL{b}',
              'b': r'$VAL{a}',
            },
          ),
          throwsA(isA<GeneratorPlaceholderException>()),
        );
      });

      test('throws on self-reference', () {
        expect(
          () => resolver.resolve(
            content: r'$VAL{self}',
            context: {'self': r'$VAL{self}'},
          ),
          throwsA(isA<GeneratorPlaceholderException>()),
        );
      });

      test('throws after max iterations with unresolved', () {
        final context = <String, dynamic>{};
        for (var i = 1; i <= 15; i++) {
          context['level$i'] = '\$VAL{level${i + 1}}';
        }
        // No final value - level16 doesn't exist

        expect(
          () => resolver.resolve(
            content: r'$VAL{level1}',
            context: context,
          ),
          throwsA(isA<GeneratorPlaceholderException>()
              .having((e) => e.iterations, 'iterations', 10)),
        );
      });
    });

    group('Escaped placeholders', () {
      test('preserves escaped placeholder syntax', () {
        final result = resolver.resolve(
          content: r'Literal: \$VAL{not.resolved}',
          context: {'not': {'resolved': 'ignored'}},
        );
        expect(result.value, r'Literal: $VAL{not.resolved}');
        expect(result.fullyResolved, isTrue);
      });

      test('resolves unescaped while preserving escaped', () {
        final result = resolver.resolve(
          content: r'Value: $VAL{name}, Literal: \$VAL{name}',
          context: {'name': 'test'},
        );
        expect(result.value, r'Value: test, Literal: $VAL{name}');
      });

      test('handles multiple escaped placeholders', () {
        final result = resolver.resolve(
          content: r'\$VAL{a} and \$VAL{b}',
          context: {},
        );
        expect(result.value, r'$VAL{a} and $VAL{b}');
      });

      test('handles escaped in maps', () {
        final result = resolver.resolve(
          content: {r'key': r'\$VAL{literal}'},
          context: {},
        );
        expect(result.value, {r'key': r'$VAL{literal}'});
      });

      test('handles escaped in lists', () {
        final result = resolver.resolve(
          content: [r'\$VAL{a}', r'\$VAL{b}'],
          context: {},
        );
        expect(result.value, [r'$VAL{a}', r'$VAL{b}']);
      });
    });

    group('Unresolved handling', () {
      test('throws on unresolved placeholder by default', () {
        expect(
          () => resolver.resolve(
            content: r'$VAL{missing.key}',
            context: {},
          ),
          throwsA(isA<GeneratorPlaceholderException>()
              .having((e) => e.unresolvedPlaceholders, 'unresolved',
                  contains(r'$VAL{missing.key}'))),
        );
      });

      test('returns partial result when throwOnUnresolved is false', () {
        final result = resolver.resolve(
          content: r'Prefix $VAL{missing.key} Suffix',
          context: {},
          throwOnUnresolved: false,
        );
        expect(result.value, r'Prefix $VAL{missing.key} Suffix');
        expect(result.fullyResolved, isFalse);
        expect(result.unresolvedPlaceholders, contains(r'$VAL{missing.key}'));
      });

      test('resolves some and reports unresolved', () {
        final result = resolver.resolve(
          content: r'$VAL{found} and $VAL{missing}',
          context: {'found': 'resolved'},
          throwOnUnresolved: false,
        );
        expect(result.value, r'resolved and $VAL{missing}');
        expect(result.fullyResolved, isFalse);
        expect(result.unresolvedPlaceholders, [r'$VAL{missing}']);
      });
    });

    group('Path resolution variants', () {
      test('handles hyphenated keys', () {
        final result = resolver.resolve(
          content: r'$VAL{project-name}',
          context: {'project-name': 'my-project'},
        );
        expect(result.value, 'my-project');
      });

      test('handles underscored keys mapped to hyphens', () {
        final result = resolver.resolve(
          content: r'$VAL{project_name}',
          context: {'project-name': 'my-project'},
        );
        expect(result.value, 'my-project');
      });

      test('handles hyphens mapped to underscores', () {
        final result = resolver.resolve(
          content: r'$VAL{project-name}',
          context: {'project_name': 'my-project'},
        );
        expect(result.value, 'my-project');
      });

      test('prefers exact match over conversion', () {
        final result = resolver.resolve(
          content: r'$VAL{project_name}',
          context: {
            'project_name': 'exact-match',
            'project-name': 'converted-match',
          },
        );
        expect(result.value, 'exact-match');
      });

      test('handles list index access', () {
        final result = resolver.resolve(
          content: r'First: $VAL{items.0}, Second: $VAL{items.1}',
          context: {
            'items': ['first', 'second', 'third']
          },
        );
        expect(result.value, 'First: first, Second: second');
      });

      test('handles nested list access', () {
        final result = resolver.resolve(
          content: r'$VAL{matrix.0.1}',
          context: {
            'matrix': [
              ['a', 'b', 'c'],
              ['d', 'e', 'f'],
            ]
          },
        );
        expect(result.value, 'b');
      });
    });

    group('Edge cases', () {
      test('handles null content', () {
        final result = resolver.resolve(
          content: null,
          context: {},
        );
        expect(result.value, isNull);
        expect(result.fullyResolved, isTrue);
      });

      test('handles empty string', () {
        final result = resolver.resolve(
          content: '',
          context: {},
        );
        expect(result.value, '');
        expect(result.fullyResolved, isTrue);
      });

      test('handles placeholder-only string', () {
        final result = resolver.resolve(
          content: r'$VAL{value}',
          context: {'value': 'result'},
        );
        expect(result.value, 'result');
      });

      test('handles context with null values', () {
        final result = resolver.resolve(
          content: r'$VAL{nullable:-default}',
          context: {'nullable': null},
        );
        // null is found, so we use default
        expect(result.value, 'default');
      });

      test('handles adjacent placeholders', () {
        final result = resolver.resolve(
          content: r'$VAL{a}$VAL{b}$VAL{c}',
          context: {'a': 'A', 'b': 'B', 'c': 'C'},
        );
        expect(result.value, 'ABC');
      });

      test('handles placeholder at start', () {
        final result = resolver.resolve(
          content: r'$VAL{prefix}-suffix',
          context: {'prefix': 'start'},
        );
        expect(result.value, 'start-suffix');
      });

      test('handles placeholder at end', () {
        final result = resolver.resolve(
          content: r'prefix-$VAL{suffix}',
          context: {'suffix': 'end'},
        );
        expect(result.value, 'prefix-end');
      });

      test('handles non-string map keys', () {
        // While unusual, should handle gracefully
        final result = resolver.resolve(
          content: {123: r'$VAL{value}'},
          context: {'value': 'test'},
        );
        expect(result.value, {'123': 'test'});
      });
    });

    group('Complex scenarios', () {
      test('resolves real-world configuration', () {
        final result = resolver.resolve(
          content: {
            'name': r'$VAL{project.name}',
            'version': r'$VAL{project.version:-0.0.1}',
            'environment': {
              'sdk': r'>=$VAL{dart.min-sdk} <$VAL{dart.max-sdk}',
            },
            'dependencies': {
              r'$VAL{dep.name}': r'^$VAL{dep.version}',
            },
          },
          context: {
            'project': {
              'name': 'my_package',
              'version': '1.0.0',
            },
            'dart': {
              'min-sdk': '3.0.0',
              'max-sdk': '4.0.0',
            },
            'dep': {
              'name': 'http',
              'version': '1.1.0',
            },
          },
        );
        expect(result.value, {
          'name': 'my_package',
          'version': '1.0.0',
          'environment': {
            'sdk': '>=3.0.0 <4.0.0',
          },
          'dependencies': {
            'http': '^1.1.0',
          },
        });
      });

      test('resolves with tom_workspace style context', () {
        final result = resolver.resolve(
          content: r'$VAL{workspace.name} - $VAL{project.type}',
          context: {
            'workspace': {
              'name': 'tom_workspace',
              'binaries': 'bin/',
            },
            'project': {
              'name': 'tom_core',
              'type': 'dart_package',
            },
          },
        );
        expect(result.value, 'tom_workspace - dart_package');
      });

      test('resolves build configuration', () {
        final result = resolver.resolve(
          content: {
            'command': r'dart $VAL{action.command} --$VAL{environment}',
            'args': [
              r'--project=$VAL{project.name}',
              r'--output=$VAL{output.dir:-build}',
            ],
          },
          context: {
            'action': {'command': 'build'},
            'environment': 'production',
            'project': {'name': 'my_app'},
          },
        );
        expect(result.value, {
          'command': 'dart build --production',
          'args': [
            '--project=my_app',
            '--output=build',
          ],
        });
      });
    });

    group('Iteration tracking', () {
      test('reports single iteration for simple resolution', () {
        final result = resolver.resolve(
          content: r'$VAL{name}',
          context: {'name': 'value'},
        );
        // 2 iterations: resolve name -> value, verify no more placeholders
        expect(result.iterations, 2);
      });

      test('reports correct iterations for recursive', () {
        final result = resolver.resolve(
          content: r'$VAL{a}',
          context: {
            'a': r'$VAL{b}',
            'b': r'$VAL{c}',
            'c': 'final',
          },
        );
        // 4 iterations: a->b, b->c, c->final, verify
        expect(result.iterations, 4);
      });

      test('reports iterations in exception', () {
        try {
          resolver.resolve(
            content: r'$VAL{circular}',
            context: {'circular': r'$VAL{circular}'},
          );
          fail('Should throw');
        } on GeneratorPlaceholderException catch (e) {
          expect(e.iterations, greaterThan(0));
          expect(e.message, contains('No progress made'));
        }
      });
    });
  });
}
