// The JSON Schemas of tom_workspace.yaml and tom_project.yaml
// (`<workspace>/.tom/json-schema/tom_build/`) against the parser they describe,
// the reference that documents them, and the files this workspace holds.
//
// The schemas are editor-validation documents: open at the root (unknown keys
// are custom tags) and strict where the parser reads a fixed shape. They are
// only worth having while they say what TomWorkspace.fromYaml /
// TomProject.fromYaml read — CS-2 and CS-3 pin the top-level keys to the
// model's `knownKeys`, CS-4 pins the reference doc to the schemas.
//
// The live-workspace tests (CS-20..) only READ files: safe while other sessions
// work in the workspace.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:json_schema/json_schema.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:tom_test_support/workspace_clone.dart';
import 'package:yaml/yaml.dart';

import 'support/workspace_support.dart' show holdWorkspaceClone;

/// Top-level tom_project.yaml keys read by tools other than TomProject.
const Map<String, String> _otherToolProjectKeys = {
  'project_id': 'buildkit (tom_build_base NatureDetector), issuekit',
  'license': 'tom_package_scanner',
};

/// Path segments that mark a test input: such files belong to their own
/// suites and may describe invalid or not-yet-implemented input on purpose.
const _testInputSegments = {'test', 'test_fixtures', 'fixture', 'fixtures'};

late final Directory _workspaceRoot;
late final Directory _schemaDir;
late final JsonSchema _workspaceSchema;
late final JsonSchema _projectSchema;

late final TomWorkspaceClone _clone;

void main() {
  setUpAll(() async {
    // The machine's workspace clone, never the live tree (aft_tclone-56).
    _clone = await holdWorkspaceClone();
    _workspaceRoot = _clone.root;
    _schemaDir = Directory(
      p.join(_workspaceRoot.path, '.tom', 'json-schema', 'tom_build'),
    );
    _workspaceSchema = _compile('tom_workspace.schema.json');
    _projectSchema = _compile('tom_project.schema.json');
  });

  tearDownAll(() => _clone.release());

  group('schema files', () {
    test('CS-1: every schema is a draft-07 schema that compiles', () {
      final files = _schemaDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.schema.json'))
          .toList();
      expect(files, hasLength(3));
      for (final file in files) {
        final json = _readJson(p.basename(file.path));
        expect(
          json[r'$schema'],
          'http://json-schema.org/draft-07/schema#',
          reason: file.path,
        );
        expect(() => _compile(p.basename(file.path)), returnsNormally);
      }
    });

    test('CS-2: tom_workspace schema declares exactly the model keys', () {
      final declared = _topLevelKeys('tom_workspace.schema.json');
      expect(declared, unorderedEquals(TomWorkspace.knownKeys));
    });

    test('CS-3: tom_project schema declares the model keys and the keys '
        'other tools read', () {
      final declared = _topLevelKeys('tom_project.schema.json');
      expect(
        declared,
        unorderedEquals({
          ...TomProject.knownKeys,
          ..._otherToolProjectKeys.keys,
        }),
      );
    });

    test('CS-4: the configuration reference documents every top-level key', () {
      final reference = File(
        p.join('doc', 'tom_configuration_reference.md'),
      ).readAsStringSync();
      final keys = {
        ..._topLevelKeys('tom_workspace.schema.json'),
        ..._topLevelKeys('tom_project.schema.json'),
      };
      final missing =
          keys.where((k) => !reference.contains('| `$k` |')).toList()..sort();
      expect(missing, isEmpty, reason: 'keys without a reference row');
    });
  });

  group('accepted shapes', () {
    test('CS-22: the user reference examples validate', () {
      final reference = File(
        p.join('doc', 'tom_user_reference.md'),
      ).readAsStringSync();
      _expectValid(
        _workspaceSchema,
        _plain(
          loadYaml(_yamlBlockAfter(reference, '### 3.1 tom_workspace.yaml')),
        ),
      );
      _expectValid(
        _projectSchema,
        _plain(
          loadYaml(_yamlBlockAfter(reference, '### 3.2 tom_project.yaml')),
        ),
      );
    });

    test('CS-5: the all-attributes fixture validates', () {
      final dir = p.join('fixture', 'all_attributes');
      _expectValid(
        _workspaceSchema,
        _readYaml(p.join(dir, 'tom_workspace.yaml')),
      );
      _expectValid(_projectSchema, _readYaml(p.join(dir, 'tom_project.yaml')));
    });

    test('CS-6: custom tags are allowed at the root of both files', () {
      _expectValid(_workspaceSchema, {
        ..._minimalWorkspace(),
        'd4rt': {'enabled': true},
      });
      _expectValid(_projectSchema, {
        'custom-project-tag': 'x',
        'nested-custom': {'key': 'value'},
      });
    });

    test('CS-7: null unsets any project field', () {
      _expectValid(_projectSchema, {
        'binaries': null,
        'build-after': null,
        'features': {'has-tests': null},
        'execution-mode-definitions': {'docker': null},
      });
    });

    test('CS-8: commands are strings or single-runner maps', () {
      _expectValid(_workspaceSchema, {
        'actions': {
          'build': {
            'default': {
              'commands': [
                'dart compile exe bin/main.dart',
                {'shell': 'echo ok'},
                {'dartscript': 'print(1);'},
                {'vscode': 'script.dart'},
                {'tom': ':analyze'},
              ],
            },
          },
        },
      });
    });

    test('CS-9: a project type key holds that type\'s action config', () {
      _expectValid(_workspaceSchema, {
        'actions': {
          'test': {
            'default': {
              'commands': ['dart test'],
            },
            'flutter_app': {
              'commands': ['flutter test'],
            },
          },
        },
      });
    });
  });

  group('rejected shapes', () {
    test('CS-10: executables need source and output', () {
      _expectInvalid(_projectSchema, {
        'executables': [
          {'name': 'tom', 'path': 'bin/tom.dart'},
        ],
      });
    });

    test('CS-11: a workspace action needs a default', () {
      _expectInvalid(_workspaceSchema, {
        'actions': {
          'build': {'description': 'no default'},
        },
      });
    });

    test('CS-12: a workspace needs at least one action', () {
      _expectInvalid(_workspaceSchema, {'name': 'ws'});
      _expectInvalid(_workspaceSchema, {'actions': <String, dynamic>{}});
    });

    test('CS-13: an action key that is not a map is rejected', () {
      // `skip:` and `pre-<action>:` lists are not read by the parser; they
      // would be dropped silently.
      _expectInvalid(_workspaceSchema, {
        'actions': {
          'build': {
            'default': {'commands': <String>[]},
            'pre-build': ['echo hook'],
          },
        },
      });
    });

    test('CS-14: a command map names exactly one runner', () {
      for (final command in [
        {'shell': 'a', 'dartscript': 'b'},
        {'sudo': true},
        <String, dynamic>{},
      ]) {
        _expectInvalid(_workspaceSchema, {
          'actions': {
            'build': {
              'default': {
                'commands': [command],
              },
            },
          },
        });
      }
    });

    test('CS-15: feature flags are booleans', () {
      _expectInvalid(_projectSchema, {
        'features': {'publishable': 'yes'},
      });
    });

    test('CS-16: version-settings keys are fixed', () {
      _expectInvalid(_workspaceSchema, {
        ..._minimalWorkspace(),
        'version-settings': {'prerelease_tag': 'dev'},
      });
    });

    test('CS-17: project binaries is the output folder, not a file list', () {
      _expectInvalid(_projectSchema, {
        'binaries': ['tool.dart'],
      });
    });

    test('CS-18: project-info entries take the tom_project.yaml shape', () {
      _expectInvalid(_workspaceSchema, {
        ..._minimalWorkspace(),
        'project-info': {
          'my_project': {
            'features': {'publishable': 'yes'},
          },
        },
      });
    });
  });

  group('model', () {
    test('CS-19: binary-files is read, not carried as a custom tag', () {
      final project = TomProject.fromYaml('p', {
        'binary-files': ['bin/tool.exe'],
      });
      expect(project.binaryFiles, ['bin/tool.exe']);
      expect(project.customTags, isNot(contains('binary-files')));
    });
  });

  group('live workspace (read-only)', () {
    test('CS-20: tom_workspace.yaml validates', () {
      _expectValid(
        _workspaceSchema,
        _readYaml(p.join(_workspaceRoot.path, 'tom_workspace.yaml')),
      );
    });

    test('CS-21: every tracked tom_project.yaml outside test inputs '
        'validates', () {
      final files = _trackedProjectFiles();
      expect(files, isNotEmpty);
      final failures = <String>[];
      for (final file in files) {
        final results = _projectSchema.validate(
          _readYaml(p.join(_workspaceRoot.path, file)),
        );
        if (!results.isValid) {
          failures.add('$file: ${results.errors.join('; ')}');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  });
}

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------

Map<String, dynamic> _readJson(String schemaFile) =>
    jsonDecode(File(p.join(_schemaDir.path, schemaFile)).readAsStringSync())
        as Map<String, dynamic>;

JsonSchema _compile(String schemaFile) => JsonSchema.create(
  _readJson(schemaFile),
  // The schemas reference each other by file name relative to their
  // `$id`; resolve those from the schema folder, never the network.
  refProvider: RefProvider.sync(
    (ref) => _readJson(Uri.parse(ref).pathSegments.last),
  ),
);

Set<String> _topLevelKeys(String schemaFile) =>
    (_readJson(schemaFile)['properties'] as Map<String, dynamic>).keys.toSet();

/// The first fenced `yaml` block after [heading] in [markdown].
String _yamlBlockAfter(String markdown, String heading) {
  final start = markdown.indexOf(heading);
  expect(start, isNot(-1), reason: 'heading $heading');
  final open = markdown.indexOf('```yaml\n', start) + '```yaml\n'.length;
  return markdown.substring(open, markdown.indexOf('```', open));
}

Map<String, dynamic> _minimalWorkspace() => {
  'actions': {
    'build': {
      'default': {
        'commands': ['true'],
      },
    },
  },
};

Object? _readYaml(String path) =>
    _plain(loadYaml(File(path).readAsStringSync()));

/// YAML nodes as plain maps and lists, which the validator walks.
Object? _plain(Object? node) {
  if (node is YamlMap) {
    return {
      for (final entry in node.entries)
        entry.key.toString(): _plain(entry.value),
    };
  }
  if (node is YamlList) return [for (final item in node) _plain(item)];
  return node;
}

void _expectValid(JsonSchema schema, Object? instance) {
  final results = schema.validate(instance);
  expect(results.isValid, isTrue, reason: results.errors.join('\n'));
}

void _expectInvalid(JsonSchema schema, Object? instance) {
  expect(schema.validate(instance).isValid, isFalse, reason: '$instance');
}

/// The workspace's tracked tom_project.yaml files (submodules included),
/// workspace-relative, without test inputs.
List<String> _trackedProjectFiles() {
  final result = Process.runSync('git', [
    'ls-files',
    '--recurse-submodules',
    '--',
    'tom_project.yaml',
    '*/tom_project.yaml',
  ], workingDirectory: _workspaceRoot.path);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return const LineSplitter()
      .convert(result.stdout as String)
      .where((f) => f.isNotEmpty)
      .where((f) => !p.split(f).any(_testInputSegments.contains))
      .toList();
}
