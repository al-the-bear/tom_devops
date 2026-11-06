// The workspace's run and watch actions (tom_workspace.yaml), the action
// filter that lets a project opt in to a skipped action, and the Flutter app
// detection `run` depends on.
//
// - `run`: development mode. Flutter apps (the default) `flutter run` (debug,
//   hot reload); JavaScript/TypeScript packages their `start` script. Every
//   other type has no common entry point (a console package has several
//   executables, all needing arguments) and runs only when its own
//   tom_project.yaml defines `actions.run`.
// - `watch`: rebuild on change. Dart and Flutter run build_runner in watch
//   mode (projects with a build.yaml); JavaScript/TypeScript their `watch`
//   script; Java and Python have none.
//
// RA-1..6 read tom_workspace.yaml; RA-10..14 are unit and scratch-workspace
// tests; RA-20 discovers this workspace READ-ONLY (~1 min).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

const _flutterRun = 'flutter run';
const _npmStart = 'npm run start --if-present';
const _dartWatch = 'buildkit --nested :runner --command=watch';
const _npmWatch = 'npm run watch --if-present';

late final Directory _workspaceRoot;
late final Map<String, dynamic> _rawActions;
late final Map<String, ActionDef> _actions;

void main() {
  setUpAll(() {
    _workspaceRoot = _findWorkspaceRoot();
    final yaml = _readYamlMap(p.join(_workspaceRoot.path, 'tom_workspace.yaml'));
    _rawActions = yaml['actions'] as Map<String, dynamic>;
    _actions = TomWorkspace.fromYaml(yaml).actions;
  });

  group('the run action', () {
    test('RA-1: Flutter apps run with flutter run (the default)', () {
      expect(_commands(_actions['run']!.defaultConfig), [_flutterRun]);
    });

    test('RA-2: JavaScript/TypeScript packages run their start script', () {
      final run = _actions['run']!;
      for (final type in WorkspaceAnalyzer.javascriptProjectTypes
          .where((t) => t != 'vscode_extension')) {
        expect(_commands(run.typeConfigs[type]), [_npmStart], reason: type);
      }
    });

    test('RA-3: every other type is skipped (opt in per project)', () {
      final run = _actions['run']!;
      expect(
        run.skipTypes,
        unorderedEquals({
          'dart_package',
          'dart_console',
          'vscode_extension',
          ...WorkspaceAnalyzer.javaProjectTypes,
          ...WorkspaceAnalyzer.pythonProjectTypes,
        }),
      );
      // Each type: the default (flutter_app only), a config, or a skip.
      final covered = {
        'flutter_app',
        ...run.typeConfigs.keys,
        ...run.skipTypes!,
      };
      expect(covered, WorkspaceAnalyzer.projectTypes);
      expect(run.typeConfigs.keys.toSet().intersection(run.skipTypes!.toSet()),
          isEmpty);
    });
  });

  group('the watch action', () {
    test('RA-4: Dart and Flutter watch with build_runner (the default)', () {
      final watch = _actions['watch']!;
      expect(_commands(watch.defaultConfig), [_dartWatch]);
      for (final type in WorkspaceAnalyzer.dartProjectTypes) {
        expect(watch.typeConfigs, isNot(contains(type)), reason: type);
      }
    });

    test('RA-5: JavaScript/TypeScript run their watch script', () {
      final watch = _actions['watch']!;
      for (final type in WorkspaceAnalyzer.javascriptProjectTypes) {
        expect(_commands(watch.typeConfigs[type]), [_npmWatch], reason: type);
      }
    });

    test('RA-6: Java and Python are skipped', () {
      expect(
        _actions['watch']!.skipTypes,
        unorderedEquals({
          ...WorkspaceAnalyzer.javaProjectTypes,
          ...WorkspaceAnalyzer.pythonProjectTypes,
        }),
      );
    });
  });

  group('action filter', () {
    test('RA-10: skip-types and applies-to-types decide by type', () {
      expect(_runs('run', 'flutter_app'), isTrue);
      expect(_runs('run', 'dart_console'), isFalse);
      expect(_runs('pubget', 'dart_package'), isTrue);
      expect(_runs('pubget', 'java'), isFalse);
      expect(_runs('test', 'java'), isTrue);
    });

    test('RA-11: a project\'s own action definition runs despite the filter',
        () {
      expect(
        WorkspaceAnalyzer.runsAction(
          'run',
          _rawActions['run'],
          projectType: 'dart_console',
          projectActions: <String, dynamic>{
            'run': {
              'default': {
                'commands': ['dart run bin/server.dart'],
              },
            },
          },
        ),
        isTrue,
      );
    });

    test('RA-12: the analyzer writes an opted-in project into '
        'tom_master_<action>.yaml', () async {
      final scratch = (Directory('testlog')..createSync())
          .createTempSync('run_action_');
      addTearDown(() => scratch.deleteSync(recursive: true));
      void write(String relative, String content) => File(
            p.join(scratch.path, relative),
          )
            ..parent.createSync(recursive: true)
            ..writeAsStringSync(content);
      write('ws.code-workspace', '{"folders": [{"path": "."}]}');
      write('tom_workspace.yaml', '''
actions:
  run:
    skip-types: [dart_console]
    default:
      commands: [flutter run]
''');
      for (final name in ['server', 'tool']) {
        write('$name/pubspec.yaml', 'name: $name\n');
        write('$name/bin/$name.dart', 'void main() {}\n');
        write('$name/lib/$name.dart', '\n');
      }
      write('server/tom_project.yaml', '''
actions:
  run:
    default:
      commands: [dart run bin/server.dart]
''');

      await WorkspaceAnalyzer(scratch.path).analyze();

      final master = _readYamlMap(
        p.join(scratch.path, '.tom_metadata', 'tom_master_run.yaml'),
      );
      expect((master['projects'] as Map).keys, ['server']);
    });

    test('RA-13: a Flutter app is a Flutter package with lib/main.dart',
        () async {
      final scratch = (Directory('testlog')..createSync())
          .createTempSync('flutter_type_');
      addTearDown(() => scratch.deleteSync(recursive: true));
      void write(String relative, String content) => File(
            p.join(scratch.path, relative),
          )
            ..parent.createSync(recursive: true)
            ..writeAsStringSync(content);
      const flutterPubspec =
          'dependencies:\n  flutter:\n    sdk: flutter\n';
      write('ws.code-workspace', '{"folders": [{"path": "."}]}');
      write('app/pubspec.yaml', 'name: app\n$flutterPubspec');
      write('app/lib/main.dart', 'void main() {}\n');
      write('app/lib/src/widgets.dart', '\n');
      write('widgets/pubspec.yaml', 'name: widgets\n$flutterPubspec');
      write('widgets/lib/widgets.dart', '\n');
      write('tested/pubspec.yaml',
          'name: tested\ndev_dependencies:\n  flutter_test:\n    sdk: flutter\n');
      write('tested/lib/main.dart', 'void main() {}\n');

      final types = {
        for (final project
            in await WorkspaceAnalyzer(scratch.path).discoverProjects())
          project.name: project.type,
      };

      expect(types, {
        'app': 'flutter_app',
        'widgets': 'dart_package',
        // A flutter_test dev dependency does not make an app.
        'tested': 'dart_package',
      });
    });
  });

  group('live workspace (read-only)', () {
    test(
      'RA-20: every tracked project that runs has its entry point',
      () async {
        final tracked = _trackedProjectFolders(_workspaceRoot);
        final projects =
            await WorkspaceAnalyzer(_workspaceRoot.path).discoverProjects();
        final failures = <String>[];
        for (final project in projects) {
          final relative = p
              .split(p.relative(project.path, from: _workspaceRoot.path))
              .join('/');
          if (!tracked.contains(relative)) continue;
          if (!_runs('run', project.type, projectPath: project.path)) {
            continue;
          }
          if (project.type == 'flutter_app' &&
              !File(p.join(project.path, 'lib', 'main.dart')).existsSync()) {
            failures.add('$relative: flutter_app without lib/main.dart');
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

bool _runs(String action, String type, {String? projectPath}) {
  Map<String, dynamic>? projectActions;
  if (projectPath != null) {
    final file = File(p.join(projectPath, 'tom_project.yaml'));
    if (file.existsSync()) {
      projectActions =
          _readYamlMap(file.path)['actions'] as Map<String, dynamic>?;
    }
  }
  return WorkspaceAnalyzer.runsAction(
    action,
    _rawActions[action],
    projectType: type,
    projectActions: projectActions,
  );
}

List<String> _commands(ActionConfig? config) =>
    [for (final c in config?.commands ?? const []) c.toString()];

Directory _findWorkspaceRoot() {
  var dir = Directory.current.absolute;
  while (!File(p.join(dir.path, 'tom_workspace.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('No tom_workspace.yaml above ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir;
}

Map<String, dynamic> _readYamlMap(String file) =>
    _plain(loadYaml(File(file).readAsStringSync())) as Map<String, dynamic>;

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

Set<String> _trackedProjectFolders(Directory root) {
  const manifests = [
    'pubspec.yaml',
    'package.json',
    'pom.xml',
    'build.gradle',
    'build.gradle.kts',
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'environment.yml',
  ];
  final result = Process.runSync(
    'git',
    [
      'ls-files',
      '--recurse-submodules',
      '--',
      for (final m in manifests) ...[m, '*/$m'],
    ],
    workingDirectory: root.path,
  );
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return const LineSplitter()
      .convert(result.stdout as String)
      .where((f) => f.isNotEmpty)
      .map(p.posix.dirname)
      .toSet();
}
