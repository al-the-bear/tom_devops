// The workspace's clean action (tom_workspace.yaml) against the project
// types the workspace analyzer assigns: it removes what a build generated.
//
// - Dart (the default): buildkit's :cleanup, which deletes the files the
//   project's buildkit.yaml `cleanup:` list names (and skips itself without
//   one). Flutter apps also `flutter clean` (build/, .dart_tool/).
// - TypeScript and VS Code extensions: their `clean` script if any, then
//   `tsc --build --clean`, which deletes exactly what tsc built.
// - Plain JavaScript: their `clean` script if any (nothing is compiled).
// - Java: build/ (Gradle, build_jar.sh) and target/ (Maven).
// - Python: build/ and *.egg-info (setuptools).
//
// CL-1..5 read tom_workspace.yaml; CL-20 discovers this workspace READ-ONLY
// (~1 min) and checks every tracked project can run its clean.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

const _buildkitCleanup = 'buildkit --nested :cleanup';
const _flutterClean = 'flutter clean';
const _npmClean = 'npm run clean --if-present';
const _tscClean = 'npx --no-install tsc --build --clean';
const _javaClean = 'rm -rf build target';
const _pythonClean = 'rm -rf build *.egg-info';

/// JavaScript/TypeScript types compiled by tsc (detected with a
/// tsconfig.json; extensions are TypeScript in this workspace).
const _typescriptTypes = {
  'vscode_extension',
  'typescript_node',
  'typescript_react',
  'typescript_vue',
  'typescript',
};

late final Directory _workspaceRoot;
late final ActionDef _clean;

void main() {
  setUpAll(() {
    _workspaceRoot = _findWorkspaceRoot();
    _clean = TomWorkspace.fromYaml(_readYamlMap(
      p.join(_workspaceRoot.path, 'tom_workspace.yaml'),
    )).actions['clean']!;
  });

  test('CL-1: Dart projects run buildkit :cleanup (the default)', () {
    expect(_commands(_clean.defaultConfig), [_buildkitCleanup]);
    for (final type in WorkspaceAnalyzer.dartProjectTypes
        .where((t) => t != 'flutter_app')) {
      expect(_clean.typeConfigs, isNot(contains(type)), reason: type);
    }
  });

  test('CL-2: Flutter apps also run flutter clean', () {
    expect(_commands(_clean.typeConfigs['flutter_app']),
        [_buildkitCleanup, _flutterClean]);
  });

  test('CL-3: TypeScript removes tsc output, plain JavaScript only its '
      'clean script', () {
    for (final type in WorkspaceAnalyzer.javascriptProjectTypes) {
      expect(
        _commands(_clean.typeConfigs[type]),
        _typescriptTypes.contains(type) ? [_npmClean, _tscClean] : [_npmClean],
        reason: type,
      );
    }
  });

  test('CL-4: Java and Python remove their build folders', () {
    expect(_commands(_clean.typeConfigs['java']), [_javaClean]);
    for (final type in WorkspaceAnalyzer.pythonProjectTypes) {
      expect(_commands(_clean.typeConfigs[type]), [_pythonClean],
          reason: type);
    }
  });

  test('CL-5: every type is handled; nothing is filtered out', () {
    expect(_clean.skipTypes, isNull);
    expect(_clean.appliesToTypes, isNull);
    expect(
      {...WorkspaceAnalyzer.dartProjectTypes, ..._clean.typeConfigs.keys},
      WorkspaceAnalyzer.projectTypes,
    );
  });

  test(
    'CL-20: every tracked project can run its clean',
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
        bool has(String file) => File(p.join(project.path, file)).existsSync();
        final commands = _commands(
            _clean.typeConfigs[project.type] ?? _clean.defaultConfig);
        if (commands.contains(_buildkitCleanup) && !has('pubspec.yaml')) {
          failures.add('$relative: buildkit needs a pubspec.yaml');
        }
        if (commands.contains(_tscClean) && !has('tsconfig.json')) {
          failures.add('$relative (${project.type}): tsc --build --clean '
              'needs a tsconfig.json');
        }
        if (commands.contains(_npmClean) && !has('package.json')) {
          failures.add('$relative: npm needs a package.json');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
    timeout: const Timeout(Duration(minutes: 5)),
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
