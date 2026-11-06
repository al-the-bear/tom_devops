// The workspace's `test` action (tom_workspace.yaml) against the project
// types the workspace analyzer assigns, and the detection those types come
// from.
//
// TA-1..4 read tom_workspace.yaml; TA-10..13 detect types in a scratch
// workspace under testlog/; TA-20 discovers this workspace READ-ONLY (~1 min)
// and checks every tracked project resolves to a runner for its type.
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

const _testkitCommand = 'testkit --nested :test --baseline';
const _npmCommand = 'npm test';
const _scriptCommand = './run_tests.sh';

late final Directory _workspaceRoot;
late final ActionDef _testAction;

void main() {
  setUpAll(() {
    _workspaceRoot = _findWorkspaceRoot();
    final yaml = _plain(loadYaml(
      File(p.join(_workspaceRoot.path, 'tom_workspace.yaml'))
          .readAsStringSync(),
    )) as Map<String, dynamic>;
    _testAction = TomWorkspace.fromYaml(yaml).actions['test']!;
  });

  group('the test action', () {
    test('TA-1: Dart and Flutter projects run testkit (the default)', () {
      expect(_commands(_testAction.defaultConfig), [_testkitCommand]);
      for (final type in WorkspaceAnalyzer.dartProjectTypes) {
        expect(_testAction.typeConfigs, isNot(contains(type)),
            reason: '$type must take the testkit default');
      }
    });

    test('TA-2: JavaScript and TypeScript projects run npm test', () {
      for (final type in WorkspaceAnalyzer.javascriptProjectTypes) {
        expect(_commands(_testAction.typeConfigs[type]), [_npmCommand],
            reason: type);
      }
    });

    test('TA-3: Java and Python projects run their run_tests.sh', () {
      for (final type in [
        ...WorkspaceAnalyzer.javaProjectTypes,
        ...WorkspaceAnalyzer.pythonProjectTypes,
      ]) {
        expect(_commands(_testAction.typeConfigs[type]), [_scriptCommand],
            reason: type);
      }
    });

    test('TA-4: the action filters no types and names no unknown type', () {
      expect(_testAction.skipTypes, isNull);
      expect(_testAction.appliesToTypes, isNull);
      expect(
        _testAction.typeConfigs.keys.toSet(),
        everyElement(isIn(WorkspaceAnalyzer.projectTypes)),
      );
    });
  });

  group('type detection', () {
    late Directory scratch;

    setUp(() {
      final testlog = Directory('testlog')..createSync();
      scratch = testlog.createTempSync('test_action_');
      File(p.join(scratch.path, 'ws.code-workspace'))
          .writeAsStringSync('{"folders": [{"path": "."}]}');
    });

    tearDown(() => scratch.deleteSync(recursive: true));

    void write(String relative, String content) {
      File(p.join(scratch.path, relative))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    Future<Map<String, String>> typesByFolder() async {
      final projects =
          await WorkspaceAnalyzer(scratch.path).discoverProjects();
      return {for (final project in projects) project.name: project.type};
    }

    test('TA-10: a pyproject.toml with only tool settings does not make a '
        'Node project Python', () async {
      write('node_tool/package.json', '{"name": "node_tool"}');
      write('node_tool/pyproject.toml',
          '[tool.ruff]\nline-length = 100\n\n[tool.pytest.ini_options]\n');
      expect((await typesByFolder())['node_tool'],
          isIn(WorkspaceAnalyzer.javascriptProjectTypes));
    });

    test('TA-11: a pyproject.toml declaring a package is Python', () async {
      write('py_project/pyproject.toml', '[project]\nname = "py_project"\n');
      write('py_build/pyproject.toml',
          '[build-system]\nrequires = ["setuptools"]\n');
      write('py_poetry/pyproject.toml', '[tool.poetry]\nname = "x"\n');
      final types = await typesByFolder();
      for (final folder in ['py_project', 'py_build', 'py_poetry']) {
        expect(types[folder], isIn(WorkspaceAnalyzer.pythonProjectTypes),
            reason: folder);
      }
    });

    test('TA-12: a tool-only pyproject.toml without package.json is no '
        'project type', () async {
      write('lint_only/pyproject.toml', '[tool.ruff]\n');
      expect(await typesByFolder(), isNot(contains('lint_only')));
    });

    test('TA-13: setup.py still makes a Python project', () async {
      write('legacy/setup.py', 'from setuptools import setup\nsetup()\n');
      expect((await typesByFolder())['legacy'],
          isIn(WorkspaceAnalyzer.pythonProjectTypes));
    });
  });

  group('live workspace (read-only)', () {
    test(
      'TA-20: every tracked project resolves to the runner of its type',
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
          if (!WorkspaceAnalyzer.projectTypes.contains(project.type)) {
            failures.add('$relative: unknown type ${project.type}');
            continue;
          }
          final config =
              _testAction.typeConfigs[project.type] ?? _testAction.defaultConfig;
          final command = _commands(config).single;
          if (command == _testkitCommand &&
              !File(p.join(project.path, 'pubspec.yaml')).existsSync()) {
            failures.add('$relative (${project.type}): testkit needs a '
                'pubspec.yaml');
          }
          if (command == _npmCommand &&
              !File(p.join(project.path, 'package.json')).existsSync()) {
            failures.add('$relative (${project.type}): npm test needs a '
                'package.json');
          }
          if (command == _scriptCommand &&
              !File(p.join(project.path, 'run_tests.sh')).existsSync()) {
            failures.add('$relative (${project.type}): no run_tests.sh');
          }
        }
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
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
