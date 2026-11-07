// This workspace, checked READ-ONLY: its project configuration and that every
// tracked project can run the workspace actions it is given.
//
// Discovery (WorkspaceAnalyzer.discoverProjects) walks the whole tree: about
// a minute on a quiet machine, several when other sessions keep the disk
// busy. It runs ONCE, in setUpAll, for every check here. When each check
// lived in its own action test file, the files' scans ran concurrently and
// timed out together under load.
//
// Only projects whose manifest git tracks count: discovery reads the disk, so
// it also finds folders only this machine has (gitignored copies, scratch
// clones). Nothing here writes a file.
@TestOn('vm')
@Timeout(Duration(minutes: 20))
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:tom_test_support/workspace_clone.dart';

import 'support/workspace_support.dart';

late final Directory _root;
late final Map<String, dynamic> _rawActions;
late final Map<String, ActionDef> _actions;
late final List<ProjectInfo> _discovered;
late final Set<String> _tracked;

/// The tracked projects, with their workspace-relative folder.
Iterable<(String, ProjectInfo)> get _projects sync* {
  for (final project in _discovered) {
    final relative = relativeProjectPath(_root, project.path);
    if (_tracked.contains(relative)) yield (relative, project);
  }
}

late final TomWorkspaceClone _clone;

void main() {
  setUpAll(() async {
    // The machine's workspace clone, never the live tree (aft_tclone-56).
    _clone = await holdWorkspaceClone();
    _root = _clone.root;
    final workspace = readWorkspaceYaml(_root);
    _rawActions = workspace['actions'] as Map<String, dynamic>;
    _actions = TomWorkspace.fromYaml(workspace).actions;
    _tracked = trackedProjectFolders(_root);
    _discovered = await WorkspaceAnalyzer(_root.path).discoverProjects();
  });

  tearDownAll(() => _clone.release());

  test('LW-1: the project configuration has no findings '
      '(WorkspaceConfigCheck)', () {
    final findings = WorkspaceConfigCheck(
      _root.path,
      includeProject: _tracked.contains,
    ).runOn(_discovered);
    expect(findings, isEmpty, reason: findings.join('\n'));
  });

  test('LW-2: every project resolves to the test runner of its type', () {
    final testAction = _actions['test']!;
    final failures = <String>[];
    for (final (relative, project) in _projects) {
      if (!WorkspaceAnalyzer.projectTypes.contains(project.type)) {
        failures.add('$relative: unknown type ${project.type}');
        continue;
      }
      final command = commandsOf(
        testAction.typeConfigs[project.type] ?? testAction.defaultConfig,
      ).single;
      final needs = {
        testkitTest: 'pubspec.yaml',
        npmTest: 'package.json',
        runTestsScript: 'run_tests.sh',
      }[command];
      if (needs != null && !_has(project, needs)) {
        failures.add('$relative (${project.type}): `$command` needs $needs');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('LW-3: every project can run its build', () {
    final build = _actions['build']!;
    final failures = <String>[];
    for (final (relative, project) in _projects) {
      if (build.skipTypes!.contains(project.type)) continue;
      final command =
          _ownCommand(project, 'build') ??
          commandsOf(
            build.typeConfigs[project.type] ?? build.defaultConfig,
          ).single;
      final problem = _cannotBuild(command, project);
      if (problem != null) {
        failures.add('$relative (${project.type}): $problem');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('LW-4: every project that runs has its entry point', () {
    final failures = <String>[];
    for (final (relative, project) in _projects) {
      final runs = WorkspaceAnalyzer.runsAction(
        'run',
        _rawActions['run'],
        projectType: project.type,
        projectActions: _ownActions(project),
      );
      if (runs &&
          project.type == 'flutter_app' &&
          !_has(project, p.join('lib', 'main.dart'))) {
        failures.add('$relative: flutter_app without lib/main.dart');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });

  test('LW-5: every project can run its clean', () {
    final clean = _actions['clean']!;
    final failures = <String>[];
    for (final (relative, project) in _projects) {
      final commands = commandsOf(
        clean.typeConfigs[project.type] ?? clean.defaultConfig,
      );
      for (final (command, needs) in [
        (buildkitCleanup, 'pubspec.yaml'),
        (tscClean, 'tsconfig.json'),
        (npmClean, 'package.json'),
      ]) {
        if (commands.contains(command) && !_has(project, needs)) {
          failures.add(
            '$relative (${project.type}): `$command` needs '
            '$needs',
          );
        }
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}

bool _has(ProjectInfo project, String file) =>
    File(p.join(project.path, file)).existsSync();

/// The project's own `actions:` from its tom_project.yaml, if any.
Map<String, dynamic>? _ownActions(ProjectInfo project) {
  final file = p.join(project.path, 'tom_project.yaml');
  if (!File(file).existsSync()) return null;
  return readYamlMap(file)['actions'] as Map<String, dynamic>?;
}

/// The project's own command for [action] from its tom_project.yaml, if any.
String? _ownCommand(ProjectInfo project, String action) {
  final own = _ownActions(project);
  if (own == null || !own.containsKey(action)) return null;
  final def = ActionDef.fromYaml(action, own[action] as Map<String, dynamic>);
  return commandsOf(def.defaultConfig).single;
}

/// Why [command] cannot build [project], or null.
String? _cannotBuild(String command, ProjectInfo project) {
  Map<String, dynamic> scripts() =>
      (jsonDecode(File(p.join(project.path, 'package.json')).readAsStringSync())
              as Map<String, dynamic>)['scripts']
          as Map<String, dynamic>? ??
      const {};

  switch (command) {
    case buildkitBuild:
      return _has(project, 'pubspec.yaml')
          ? null
          : 'buildkit needs a pubspec.yaml';
    case extensionBuild:
      return scripts().containsKey('compile')
          ? null
          : 'package.json has no `compile` script';
    case packageBuild:
      // A TypeScript package always has something to compile: without a
      // `build` script --if-present would skip it silently.
      if (_has(project, 'tsconfig.json') && !scripts().containsKey('build')) {
        return 'TypeScript package without a `build` script';
      }
      return null;
    case javaBuild:
      return _has(project, 'build_jar.sh') ? null : 'no build_jar.sh';
  }
  return null;
}
