import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/generation/generator_placeholder.dart';

void main() {
  group('GeneratorPlaceholderResolver', () {
    late GeneratorPlaceholderResolver resolver;

    setUp(() {
      resolver = GeneratorPlaceholderResolver();
    });

    group('Basic generator resolution', () {
      test('generates comma-separated list of names', () {
        final result = resolver.resolve(
          content: r'$GEN{projects.*.name;,}',
          context: {
            'projects': [
              {'name': 'core'},
              {'name': 'build'},
              {'name': 'tools'},
            ]
          },
        );
        expect(result.value, 'core,build,tools');
        expect(result.fullyResolved, isTrue);
      });

      test('generates dash-separated list', () {
        final result = resolver.resolve(
          content: r'$GEN{items.*.id;-}',
          context: {
            'items': [
              {'id': 'a'},
              {'id': 'b'},
              {'id': 'c'},
            ]
          },
        );
        expect(result.value, 'a-b-c');
      });

      test('generates space-separated list', () {
        final result = resolver.resolve(
          content: r'$GEN{words.*.text; }',
          context: {
            'words': [
              {'text': 'hello'},
              {'text': 'world'},
            ]
          },
        );
        expect(result.value, 'hello world');
      });

      test('generates with empty separator', () {
        final result = resolver.resolve(
          content: r'$GEN{chars.*.c;}',
          context: {
            'chars': [
              {'c': 'a'},
              {'c': 'b'},
              {'c': 'c'},
            ]
          },
        );
        expect(result.value, 'abc');
      });

      test('generates newline-separated list', () {
        final result = resolver.resolve(
          content: r'$GEN{lines.*.text;\n}',
          context: {
            'lines': [
              {'text': 'line1'},
              {'text': 'line2'},
            ]
          },
        );
        expect(result.value, r'line1\nline2');
      });

      test('handles empty collection', () {
        final result = resolver.resolve(
          content: r'$GEN{empty.*.name;,}',
          context: {'empty': []},
        );
        expect(result.value, '');
        expect(result.fullyResolved, isTrue);
      });

      test('handles single item', () {
        final result = resolver.resolve(
          content: r'$GEN{single.*.value;,}',
          context: {
            'single': [
              {'value': 'only'}
            ]
          },
        );
        expect(result.value, 'only');
      });
    });

    group('Nested path resolution', () {
      test('navigates nested paths before wildcard', () {
        final result = resolver.resolve(
          content: r'$GEN{workspace.projects.*.name;,}',
          context: {
            'workspace': {
              'projects': [
                {'name': 'a'},
                {'name': 'b'},
              ]
            }
          },
        );
        expect(result.value, 'a,b');
      });

      test('extracts nested fields after wildcard', () {
        final result = resolver.resolve(
          content: r'$GEN{items.*.settings.theme;,}',
          context: {
            'items': [
              {
                'settings': {'theme': 'dark'}
              },
              {
                'settings': {'theme': 'light'}
              },
            ]
          },
        );
        expect(result.value, 'dark,light');
      });

      test('handles deeply nested extraction', () {
        final result = resolver.resolve(
          content: r'$GEN{data.items.*.config.env.name;|}',
          context: {
            'data': {
              'items': [
                {
                  'config': {
                    'env': {'name': 'dev'}
                  }
                },
                {
                  'config': {
                    'env': {'name': 'prod'}
                  }
                },
              ]
            }
          },
        );
        expect(result.value, 'dev|prod');
      });
    });

    group('Map collection iteration', () {
      test('iterates over map values', () {
        final result = resolver.resolve(
          content: r'$GEN{projects.*.description;, }',
          context: {
            'projects': {
              'core': {'description': 'Core library'},
              'build': {'description': 'Build tools'},
            }
          },
        );
        // Map iteration order may vary, so check for both possibilities
        expect(
          result.value,
          anyOf(
            'Core library, Build tools',
            'Build tools, Core library',
          ),
        );
      });
    });

    group('Filtered generators', () {
      test('filters by exact attribute match', () {
        final result = resolver.resolve(
          content: r'$GEN{projects.[type=dart_package].name;,}',
          context: {
            'projects': [
              {'name': 'core', 'type': 'dart_package'},
              {'name': 'app', 'type': 'flutter_app'},
              {'name': 'build', 'type': 'dart_package'},
            ]
          },
        );
        expect(result.value, 'core,build');
      });

      test('filters with no matches', () {
        final result = resolver.resolve(
          content: r'$GEN{items.[status=deleted].name;,}',
          context: {
            'items': [
              {'name': 'a', 'status': 'active'},
              {'name': 'b', 'status': 'pending'},
            ]
          },
        );
        expect(result.value, '');
      });

      test('filters with all matches', () {
        final result = resolver.resolve(
          content: r'$GEN{items.[active=true].name;,}',
          context: {
            'items': [
              {'name': 'a', 'active': true},
              {'name': 'b', 'active': true},
            ]
          },
        );
        expect(result.value, 'a,b');
      });

      test('filters by regex pattern', () {
        final result = resolver.resolve(
          content: r'$GEN{projects.[name=^tom_.*$].name;,}',
          context: {
            'projects': [
              {'name': 'tom_core'},
              {'name': 'other_pkg'},
              {'name': 'tom_build'},
            ]
          },
        );
        expect(result.value, 'tom_core,tom_build');
      });

      test('filters with multiple conditions (AND)', () {
        final result = resolver.resolve(
          content: r'$GEN{items.[type=dart,publishable=true].name;,}',
          context: {
            'items': [
              {'name': 'a', 'type': 'dart', 'publishable': true},
              {'name': 'b', 'type': 'dart', 'publishable': false},
              {'name': 'c', 'type': 'flutter', 'publishable': true},
            ]
          },
        );
        expect(result.value, 'a');
      });

      test('filters with partial regex', () {
        final result = resolver.resolve(
          content: r'$GEN{items.[name=^prefix].value;,}',
          context: {
            'items': [
              {'name': 'prefix_one', 'value': '1'},
              {'name': 'other', 'value': '2'},
              {'name': 'prefix_two', 'value': '3'},
            ]
          },
        );
        expect(result.value, '1,3');
      });
    });

    group('Multiple generators in content', () {
      test('resolves multiple generators in same string', () {
        final result = resolver.resolve(
          content: r'Packages: $GEN{pkgs.*.name;,} | Types: $GEN{types.*.id;-}',
          context: {
            'pkgs': [
              {'name': 'a'},
              {'name': 'b'},
            ],
            'types': [
              {'id': 'x'},
              {'id': 'y'},
            ]
          },
        );
        expect(result.value, 'Packages: a,b | Types: x-y');
      });

      test('handles generators with surrounding text', () {
        final result = resolver.resolve(
          content: r'prefix_$GEN{items.*.val;_}_suffix',
          context: {
            'items': [
              {'val': 'a'},
              {'val': 'b'},
            ]
          },
        );
        expect(result.value, 'prefix_a_b_suffix');
      });
    });

    group('Map resolution', () {
      test('resolves generators in map values', () {
        final result = resolver.resolve(
          content: {'deps': r'$GEN{deps.*.name;,}'},
          context: {
            'deps': [
              {'name': 'http'},
              {'name': 'json'},
            ]
          },
        );
        expect(result.value, {'deps': 'http,json'});
      });

      test('resolves generators in map keys', () {
        final result = resolver.resolve(
          content: {r'$GEN{key.*.name;_}': 'value'},
          context: {
            'key': [
              {'name': 'a'},
              {'name': 'b'},
            ]
          },
        );
        expect(result.value, {'a_b': 'value'});
      });

      test('resolves nested maps', () {
        final result = resolver.resolve(
          content: {
            'outer': {'inner': r'$GEN{items.*.x;,}'}
          },
          context: {
            'items': [
              {'x': '1'},
              {'x': '2'},
            ]
          },
        );
        expect(result.value, {
          'outer': {'inner': '1,2'}
        });
      });
    });

    group('List resolution', () {
      test('resolves generators in list items', () {
        final result = resolver.resolve(
          content: [r'$GEN{a.*.v;,}', r'$GEN{b.*.v;-}'],
          context: {
            'a': [
              {'v': '1'},
              {'v': '2'},
            ],
            'b': [
              {'v': 'x'},
              {'v': 'y'},
            ]
          },
        );
        expect(result.value, ['1,2', 'x-y']);
      });
    });

    group('Error handling', () {
      test('throws on path not found', () {
        expect(
          () => resolver.resolve(
            content: r'$GEN{nonexistent.*.name;,}',
            context: {},
          ),
          throwsA(isA<GeneratorResolutionException>()
              .having((e) => e.message, 'message', contains('Path not found'))),
        );
      });

      test('throws on missing wildcard', () {
        expect(
          () => resolver.resolve(
            content: r'$GEN{items.name;,}',
            context: {
              'items': {'name': 'test'}
            },
          ),
          throwsA(isA<GeneratorResolutionException>()
              .having((e) => e.message, 'message', contains('No wildcard'))),
        );
      });

      test('returns partial result when throwOnUnresolved is false', () {
        final result = resolver.resolve(
          content: r'Valid: $GEN{items.*.v;,} | Invalid: $GEN{missing.*.x;,}',
          context: {
            'items': [
              {'v': 'a'},
              {'v': 'b'},
            ]
          },
          throwOnUnresolved: false,
        );
        expect(result.value, r'Valid: a,b | Invalid: $GEN{missing.*.x;,}');
        expect(result.fullyResolved, isFalse);
        expect(result.unresolvedGenerators, contains(r'$GEN{missing.*.x;,}'));
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

      test('handles content without generators', () {
        final result = resolver.resolve(
          content: 'No generators here',
          context: {},
        );
        expect(result.value, 'No generators here');
        expect(result.fullyResolved, isTrue);
      });

      test('handles non-string primitives', () {
        final result = resolver.resolve(
          content: 42,
          context: {},
        );
        expect(result.value, 42);
        expect(result.fullyResolved, isTrue);
      });

      test('handles items with missing fields', () {
        final result = resolver.resolve(
          content: r'$GEN{items.*.name;,}',
          context: {
            'items': [
              {'name': 'first'},
              {'other': 'field'},
              {'name': 'third'},
            ]
          },
        );
        // Missing fields are skipped
        expect(result.value, 'first,third');
      });

      test('handles hyphenated path segments', () {
        final result = resolver.resolve(
          content: r'$GEN{project-info.*.project-name;,}',
          context: {
            'project-info': [
              {'project-name': 'a'},
              {'project-name': 'b'},
            ]
          },
        );
        expect(result.value, 'a,b');
      });

      test('handles underscore to hyphen conversion', () {
        final result = resolver.resolve(
          content: r'$GEN{project_info.*.project_name;,}',
          context: {
            'project-info': [
              {'project-name': 'a'},
              {'project-name': 'b'},
            ]
          },
        );
        expect(result.value, 'a,b');
      });
    });

    group('Real-world scenarios', () {
      test('generates project dependency list', () {
        final result = resolver.resolve(
          content: r'dependencies: [$GEN{projects.[type=dart_package].name;, }]',
          context: {
            'projects': [
              {'name': 'tom_core', 'type': 'dart_package'},
              {'name': 'tom_app', 'type': 'flutter_app'},
              {'name': 'tom_build', 'type': 'dart_package'},
            ]
          },
        );
        expect(result.value, 'dependencies: [tom_core, tom_build]');
      });

      test('generates build order script', () {
        final result = resolver.resolve(
          content: {
            'targets': r'$GEN{build-order.*.name;,}',
            'command': r'build $GEN{build-order.*.name; }',
          },
          context: {
            'build-order': [
              {'name': 'core'},
              {'name': 'common'},
              {'name': 'app'},
            ]
          },
        );
        expect(result.value, {
          'targets': 'core,common,app',
          'command': 'build core common app',
        });
      });

      test('generates package exports', () {
        final result = resolver.resolve(
          content: r"export 'src/$GEN{modules.*.path;.dart';\nexport 'src/}.dart';",
          context: {
            'modules': [
              {'path': 'core'},
              {'path': 'utils'},
              {'path': 'models'},
            ]
          },
        );
        expect(
          result.value,
          r"export 'src/core.dart';\nexport 'src/utils.dart';\nexport 'src/models.dart';",
        );
      });
    });
  });
}
