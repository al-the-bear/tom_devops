// The workspace's build actions (tom_workspace.yaml) against the project
// types the workspace analyzer assigns.
//
// - `build`: the whole build of a project. Dart and Flutter run buildkit's
//   chain, which does only what the project's buildkit.yaml configures
//   (pub get, build_runner, d4rtgen, versioner, native compilation);
//   JavaScript/TypeScript run their package script; Java its build_jar.sh;
//   Python has nothing to build.
// - `pubget`, `builder_runner`, `bin_release`: single buildkit steps, for
//   Dart and Flutter projects only.
//
// BA-1..6 read tom_workspace.yaml; BA-20 discovers this workspace READ-ONLY
// (~1 min) and checks every tracked project can run its build.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

const _buildkitBuild =
    'buildkit --nested :pubget :runner :d4rtgen :versioner :compiler';
const _extensionBuild = 'npm run compile';
const _packageBuild = 'npm run build --if-present';
const _javaBuild = './build_jar.sh';

late final Directory _workspaceRoot;
late final Map<String, ActionDef> _actions;

void main() {
  setUpAll(() {
    _workspaceRoot = _findWorkspaceRoot();
    _actions = TomWorkspace.fromYaml(_readYamlMap(
      p.join(_workspaceRoot.path, 'tom_workspace.yaml'),
    )).actions;
  });

  group('the build action', () {
    test('BA-1: Dart and Flutter projects run the buildkit chain (default)',
        () {
      final build = _actions['build']!;
      expect(_commands(build.defaultConfig), [_buildkitBuild]);
      for (final type in WorkspaceAnalyzer.dartProjectTypes) {
        expect(build.typeConfigs, isNot(contains(type)), reason: type);
      }
    });

    test('BA-2: extensions compile, other JS/TS packages run their build '
        'script', () {
      final build = _actions['build']!;
      expect(_commands(build.typeConfigs['vscode_extension']),
          [_extensionBuild]);
      for (final type in WorkspaceAnalyzer.javascriptProjectTypes
          .where((t) => t != 'vscode_extension')) {
        expect(_commands(build.typeConfigs[type]), [_packageBuild],
            reason: type);
      }
    });

    test('BA-3: Java builds its jar, Python is skipped', () {
      final build = _actions['build']!;
      expect(_commands(build.typeConfigs['java']), [_javaBuild]);
      expect(build.skipTypes,
          unorderedEquals(WorkspaceAnalyzer.pythonProjectTypes));
      expect(build.appliesToTypes, isNull);
    });

    test('BA-4: every non-Dart type has exactly one of: a config, a skip',
        () {
      final build = _actions['build']!;
      final configured = build.typeConfigs.keys.toSet();
      final skipped = build.skipTypes!.toSet();
      expect(configured.intersection(skipped), isEmpty);
      expect(
        configured.union(skipped),
        WorkspaceAnalyzer.projectTypes
            .difference(WorkspaceAnalyzer.dartProjectTypes),
      );
    });
  });

  group('Dart-only build steps', () {
    for (final (rule, action, command) in [
      ('BA-5', 'pubget', 'buildkit --nested :pubget'),
      ('BA-6', 'builder_runner', 'buildkit --nested :runner'),
      ('BA-7', 'bin_release', 'buildkit --nested :compiler'),
    ]) {
      test('$rule: $action runs `$command` for Dart and Flutter only', () {
        final def = _actions[action]!;
        expect(_commands(def.defaultConfig), [command]);
        expect(def.typeConfigs, isEmpty);
        expect(def.appliesToTypes,
            unorderedEquals(WorkspaceAnalyzer.dartProjectTypes));
        expect(def.skipTypes, isNull);
      });
    }
  });

  group('live workspace (read-only)', () {
    test(
      'BA-20: every tracked project can run its build',
      () async {
        final tracked = _trackedProjectFolders(_workspaceRoot);
        final build = _actions['build']!;
        final projects =
            await WorkspaceAnalyzer(_workspaceRoot.path).discoverProjects();
        final failures = <String>[];
        for (final project in projects) {
          final relative = p
              .split(p.relative(project.path, from: _workspaceRoot.path))
              .join('/');
          if (!tracked.contains(relative)) continue;
          if (build.skipTypes!.contains(project.type)) continue;
          final command = _projectBuild(project.path) ??
              _commands(build.typeConfigs[project.type] ??
                      build.defaultConfig)
                  .single;
          final problem = _cannotRun(command, project.path);
          if (problem != null) {
            failures.add('$relative (${project.type}): $problem');
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

/// The project's own `actions.build` command from tom_project.yaml, if any.
String? _projectBuild(String projectPath) {
  final file = p.join(projectPath, 'tom_project.yaml');
  if (!File(file).existsSync()) return null;
  final project = TomProject.fromYaml('p', _readYamlMap(file));
  final build = project.actions['build'];
  return build == null ? null : _commands(build.defaultConfig).single;
}

/// Why [command] cannot build the project at [projectPath], or null.
String? _cannotRun(String command, String projectPath) {
  bool has(String file) => File(p.join(projectPath, file)).existsSync();
  Map<String, dynamic> scripts() =>
      (jsonDecode(File(p.join(projectPath, 'package.json')).readAsStringSync())
              as Map<String, dynamic>)['scripts'] as Map<String, dynamic>? ??
          const {};

  switch (command) {
    case _buildkitBuild:
      return has('pubspec.yaml') ? null : 'buildkit needs a pubspec.yaml';
    case _extensionBuild:
      return scripts().containsKey('compile')
          ? null
          : 'package.json has no `compile` script';
    case _packageBuild:
      // A TypeScript package always has something to compile: without a
      // `build` script --if-present would skip it silently.
      if (has('tsconfig.json') && !scripts().containsKey('build')) {
        return 'TypeScript package without a `build` script';
      }
      return null;
    case _javaBuild:
      return has('build_jar.sh') ? null : 'no build_jar.sh';
  }
  return null;
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

/// Workspace-relative folders holding a tracked manifest (submodules
/// included).
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
