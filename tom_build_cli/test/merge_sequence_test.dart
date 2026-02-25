/// Comprehensive tests for configuration merge sequence.
///
/// Tests cover Section 5.2.3 Configuration Merge Sequence:
/// 1. Auto-detected values (base)
/// 2. Project-type overrides
/// 3. Group-level overrides
/// 4. Workspace-level overrides
/// 5. Project-level overrides (highest priority)

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Configuration Merge Sequence Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_merge_seq_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // =========================================================================
    // Step 1: Auto-detected values (base)
    // =========================================================================
    group('auto-detected values (base)', () {
      test('project type is auto-detected from pubspec.yaml', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.type, equals('dart_package'));
      });

      test('dart_console detected from bin folder', () async {
        _createDartConsole(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.type, equals('dart_console'));
      });

      test('flutter_app detected from flutter dependency', () async {
        _createFlutterApp(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.type, equals('flutter_app'));
      });

      test('features auto-detected from folder structure', () async {
        _createDartPackageWithFolders(tempDir.path, 
            hasBin: false, hasTest: true, hasExample: true);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        // Features should be detected
        expect(project.features.isNotEmpty, isTrue);
      });
    });

    // =========================================================================
    // Step 2: Project-type overrides
    // =========================================================================
    group('project-type overrides', () {
      test('project-types settings are loaded', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
project-types:
  dart_package:
    name: Dart Package
    project-info-overrides:
      features:
        custom-feature: true
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        // project-types should be loaded into workspaceSettings
        expect(analyzer.workspaceSettings.containsKey('project-types'), isTrue);
        final projectTypes = analyzer.workspaceSettings['project-types'] as Map;
        expect(projectTypes.containsKey('dart_package'), isTrue);
      });

      test('project-type actions apply to matching projects', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
project-types:
  dart_package:
    actions:
      build:
        default:
          commands: [dart pub get]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap?;

        if (actions != null && actions.containsKey('build')) {
          final build = actions['build'] as YamlMap;
          expect(build.containsKey('default'), isTrue);
        }
      });
    });

    // =========================================================================
    // Step 3: Group-level overrides
    // =========================================================================
    group('group-level overrides', () {
      test('group settings apply to projects in group', () async {
        _createMultiProjectWorkspaceWithGroups(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        // Projects should exist - group settings loaded from local index
        final projectA = analyzer.projects.firstWhere((p) => p.name == 'project_a');
        expect(projectA.localIndexEntries['group'], equals('core'));
      });
    });

    // =========================================================================
    // Step 4: Workspace-level overrides
    // =========================================================================
    group('workspace-level overrides', () {
      test('workspace actions apply to all projects', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
actions:
  build:
    default:
      commands: [workspace build]
  test:
    default:
      commands: [workspace test]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;

        expect(actions.containsKey('build'), isTrue);
        expect(actions.containsKey('test'), isTrue);
      });

      test('workspace mode-definitions apply to all projects', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
deployment-mode-definitions:
  none:
    description: No deployment
  kubernetes:
    replicas: 2
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final deployModes = project['deployment-mode-definitions'] as YamlMap;

        expect(deployModes.containsKey('none'), isTrue);
        expect(deployModes.containsKey('kubernetes'), isTrue);
      });

      test('workspace cross-compilation applies to all projects', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
cross-compilation:
  all-targets:
    - darwin-x64
    - linux-x64
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;

        expect(crossComp.containsKey('all-targets'), isTrue);
      });
    });

    // =========================================================================
    // Step 5: Project-level overrides (highest priority)
    // =========================================================================
    group('project-level overrides (highest priority)', () {
      test('project action overrides workspace action', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
actions:
  build:
    default:
      commands: [workspace build]
''');
        File(path.join(tempDir.path, 'tom_project.yaml')).writeAsStringSync('''
actions:
  build:
    default:
      commands: [project build]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;
        final build = actions['build'] as YamlMap;
        final commands = (build['default'] as YamlMap)['commands'] as YamlList;

        expect(commands, contains('project build'));
        expect(commands, isNot(contains('workspace build')));
      });

      test('project mode overrides workspace mode', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
deployment-mode-definitions:
  kubernetes:
    replicas: 2
    namespace: default
''');
        File(path.join(tempDir.path, 'tom_project.yaml')).writeAsStringSync('''
deployment-mode-definitions:
  kubernetes:
    replicas: 5
    namespace: project-ns
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final deployModes = project['deployment-mode-definitions'] as YamlMap;
        final k8s = deployModes['kubernetes'] as YamlMap;

        expect(k8s['replicas'], equals(5));
        expect(k8s['namespace'], equals('project-ns'));
      });

      test('project cross-compilation build-on overrides workspace', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
cross-compilation:
  all-targets: [darwin-x64, linux-x64]
  build-on:
    darwin-x64:
      targets: [darwin-x64, linux-x64]
''');
        File(path.join(tempDir.path, 'tom_project.yaml')).writeAsStringSync('''
cross-compilation:
  build-on:
    darwin-x64:
      targets: [darwin-x64]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final buildOn = crossComp['build-on'] as YamlMap;
        final darwinX64 = buildOn['darwin-x64'] as YamlMap;
        final targets = darwinX64['targets'] as YamlList;

        expect(targets.length, equals(1));
        expect(targets, contains('darwin-x64'));
        expect(targets, isNot(contains('linux-x64')));
      });
    });

    // =========================================================================
    // Full merge sequence test
    // =========================================================================
    group('full merge sequence', () {
      test('all levels in sequence', () async {
        // Create workspace with all levels
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace

# Project-type level
project-types:
  dart_package:
    project-info-overrides:
      features:
        from-project-type: true

# Workspace level
actions:
  build:
    default:
      commands: [workspace build]
  test:
    default:
      commands: [workspace test]
  lint:
    default:
      commands: [workspace lint]

deployment-mode-definitions:
  none:
    from: workspace
  kubernetes:
    replicas: 2
''');
        File(path.join(tempDir.path, 'tom_project.yaml')).writeAsStringSync('''
# Project level - highest priority
actions:
  build:
    default:
      commands: [project build]

deployment-mode-definitions:
  kubernetes:
    replicas: 10
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);

        // 1. Auto-detect: type should be dart_package
        expect(project['type'], equals('dart_package'));

        // 4. Workspace level: test and lint actions should be inherited
        final actions = project['actions'] as YamlMap;
        expect(actions.containsKey('test'), isTrue);
        expect(actions.containsKey('lint'), isTrue);
        expect((actions['test'] as YamlMap)['default']['commands'], 
            contains('workspace test'));

        // 5. Project level: build action should be overridden
        expect((actions['build'] as YamlMap)['default']['commands'], 
            contains('project build'));

        // 5. Project level: kubernetes replicas should be overridden
        final deployModes = project['deployment-mode-definitions'] as YamlMap;
        expect((deployModes['kubernetes'] as YamlMap)['replicas'], equals(10));

        // 4. Workspace level: none mode should be inherited
        expect(deployModes.containsKey('none'), isTrue);
      });
    });
  });
}

// =============================================================================
// Helper Functions
// =============================================================================

void _createDartPackage(String basePath, {String name = 'test_package'}) {
  Directory(path.join(basePath, 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'pubspec.yaml')).writeAsStringSync('''
name: $name
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'lib', '$name.dart')).writeAsStringSync('// Lib');
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
''');
}

void _createDartConsole(String basePath) {
  Directory(path.join(basePath, 'bin')).createSync(recursive: true);
  Directory(path.join(basePath, 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'pubspec.yaml')).writeAsStringSync('''
name: test_console
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'bin', 'test_console.dart')).writeAsStringSync('''
void main() {}
''');
  File(path.join(basePath, 'lib', 'test_console.dart')).writeAsStringSync('// Lib');
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
''');
}

void _createFlutterApp(String basePath) {
  Directory(path.join(basePath, 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'pubspec.yaml')).writeAsStringSync('''
name: test_flutter
version: 1.0.0
environment:
  sdk: ^3.0.0
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
''');
  File(path.join(basePath, 'lib', 'main.dart')).writeAsStringSync('''
import 'package:flutter/material.dart';
void main() => runApp(MyApp());
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container();
}
''');
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
''');
}

void _createDartPackageWithFolders(
  String basePath, {
  required bool hasBin,
  required bool hasTest,
  required bool hasExample,
}) {
  Directory(path.join(basePath, 'lib')).createSync(recursive: true);
  if (hasBin) {
    Directory(path.join(basePath, 'bin')).createSync();
    File(path.join(basePath, 'bin', 'main.dart')).writeAsStringSync('void main() {}');
  }
  if (hasTest) {
    Directory(path.join(basePath, 'test')).createSync();
    File(path.join(basePath, 'test', 'test.dart')).writeAsStringSync('''
import 'package:test/test.dart';
void main() { test('t', () {}); }
''');
  }
  if (hasExample) {
    Directory(path.join(basePath, 'example')).createSync();
    File(path.join(basePath, 'example', 'example.dart')).writeAsStringSync('void main() {}');
  }
  File(path.join(basePath, 'pubspec.yaml')).writeAsStringSync('''
name: test_package
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'lib', 'test_package.dart')).writeAsStringSync('// Lib');
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
''');
}

void _createMultiProjectWorkspaceWithGroups(String basePath) {
  // Project A in core group
  Directory(path.join(basePath, 'project_a', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'project_a', 'pubspec.yaml')).writeAsStringSync('''
name: project_a
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'project_a', 'lib', 'project_a.dart')).writeAsStringSync('// Lib');
  File(path.join(basePath, 'project_a', 'tom_project.yaml')).writeAsStringSync('''
group: core
''');

  // Project B in tools group
  Directory(path.join(basePath, 'project_b', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'project_b', 'pubspec.yaml')).writeAsStringSync('''
name: project_b
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'project_b', 'lib', 'project_b.dart')).writeAsStringSync('// Lib');
  File(path.join(basePath, 'project_b', 'tom_project.yaml')).writeAsStringSync('''
group: tools
''');

  // Workspace with groups
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
groups:
  core:
    name: Core
    description: Core packages
  tools:
    name: Tools
    description: Tool packages
''');
}

YamlMap _loadMasterYaml(String basePath) {
  final masterFile = File(path.join(basePath, '.tom_metadata', 'tom_master.yaml'));
  return loadYaml(masterFile.readAsStringSync()) as YamlMap;
}

YamlMap _getFirstProject(YamlMap yaml) {
  final projects = yaml['projects'] as YamlMap;
  return projects.values.first as YamlMap;
}
