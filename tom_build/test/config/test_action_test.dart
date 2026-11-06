// The workspace's `test` action (tom_workspace.yaml) against the project
// types the workspace analyzer assigns, and the detection those types come
// from.
//
// TA-1..4 read tom_workspace.yaml; TA-10..13 detect types in a scratch
// workspace under testlog/. That every tracked project resolves to a runner
// is live_workspace_test.dart LW-2.
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'support/workspace_support.dart';

late final ActionDef _testAction;

void main() {
  setUpAll(() {
    _testAction = TomWorkspace.fromYaml(
      readWorkspaceYaml(findWorkspaceRoot()),
    ).actions['test']!;
  });

  group('the test action', () {
    test('TA-1: Dart and Flutter projects run testkit (the default)', () {
      expect(commandsOf(_testAction.defaultConfig), [testkitTest]);
      for (final type in WorkspaceAnalyzer.dartProjectTypes) {
        expect(
          _testAction.typeConfigs,
          isNot(contains(type)),
          reason: '$type must take the testkit default',
        );
      }
    });

    test('TA-2: JavaScript and TypeScript projects run npm test', () {
      for (final type in WorkspaceAnalyzer.javascriptProjectTypes) {
        expect(commandsOf(_testAction.typeConfigs[type]), [
          npmTest,
        ], reason: type);
      }
    });

    test('TA-3: Java and Python projects run their run_tests.sh', () {
      for (final type in [
        ...WorkspaceAnalyzer.javaProjectTypes,
        ...WorkspaceAnalyzer.pythonProjectTypes,
      ]) {
        expect(commandsOf(_testAction.typeConfigs[type]), [
          runTestsScript,
        ], reason: type);
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
      File(
        p.join(scratch.path, 'ws.code-workspace'),
      ).writeAsStringSync('{"folders": [{"path": "."}]}');
    });

    tearDown(() => scratch.deleteSync(recursive: true));

    void write(String relative, String content) {
      File(p.join(scratch.path, relative))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    Future<Map<String, String>> typesByFolder() async {
      final projects = await WorkspaceAnalyzer(scratch.path).discoverProjects();
      return {for (final project in projects) project.name: project.type};
    }

    test('TA-10: a pyproject.toml with only tool settings does not make a '
        'Node project Python', () async {
      write('node_tool/package.json', '{"name": "node_tool"}');
      write(
        'node_tool/pyproject.toml',
        '[tool.ruff]\nline-length = 100\n\n[tool.pytest.ini_options]\n',
      );
      expect(
        (await typesByFolder())['node_tool'],
        isIn(WorkspaceAnalyzer.javascriptProjectTypes),
      );
    });

    test('TA-11: a pyproject.toml declaring a package is Python', () async {
      write('py_project/pyproject.toml', '[project]\nname = "py_project"\n');
      write(
        'py_build/pyproject.toml',
        '[build-system]\nrequires = ["setuptools"]\n',
      );
      write('py_poetry/pyproject.toml', '[tool.poetry]\nname = "x"\n');
      final types = await typesByFolder();
      for (final folder in ['py_project', 'py_build', 'py_poetry']) {
        expect(
          types[folder],
          isIn(WorkspaceAnalyzer.pythonProjectTypes),
          reason: folder,
        );
      }
    });

    test('TA-12: a tool-only pyproject.toml without package.json is no '
        'project type', () async {
      write('lint_only/pyproject.toml', '[tool.ruff]\n');
      expect(await typesByFolder(), isNot(contains('lint_only')));
    });

    test('TA-13: setup.py still makes a Python project', () async {
      write('legacy/setup.py', 'from setuptools import setup\nsetup()\n');
      expect(
        (await typesByFolder())['legacy'],
        isIn(WorkspaceAnalyzer.pythonProjectTypes),
      );
    });
  });
}
