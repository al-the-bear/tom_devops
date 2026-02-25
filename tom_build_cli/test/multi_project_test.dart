/// Tests for multi-project workspace scenarios.
///
/// Tests cover:
/// 1. Multiple projects with different overrides
/// 2. Projects with dependencies (build-after)
/// 3. Project-specific inheritance
/// 4. Independent merge results per project

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Multi-Project Workspace Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_multi_proj_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // =========================================================================
    // Independent merge results
    // =========================================================================
    group('independent merge results', () {
      test('each project has independent actions', () async {
        _createMultiProjectWorkspace(tempDir.path, projectCount: 3);
        _addProjectOverride(tempDir.path, 'project_a', '''
actions:
  build:
    default:
      commands: [project-a-build]
''');
        _addProjectOverride(tempDir.path, 'project_b', '''
actions:
  build:
    default:
      commands: [project-b-build]
''');
        // project_c has no override

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final projects = yaml['projects'] as YamlMap;

        // Project A has custom build
        final projectA = projects['project_a'] as YamlMap;
        expect((projectA['actions'] as YamlMap)['build']['default']['commands'],
            contains('project-a-build'));

        // Project B has custom build
        final projectB = projects['project_b'] as YamlMap;
        expect((projectB['actions'] as YamlMap)['build']['default']['commands'],
            contains('project-b-build'));

        // Project C inherits workspace build
        final projectC = projects['project_c'] as YamlMap;
        expect((projectC['actions'] as YamlMap)['build']['default']['commands'],
            contains('workspace-build'));
      });

      test('each project has independent mode definitions', () async {
        _createMultiProjectWorkspace(tempDir.path, projectCount: 2);
        _addProjectOverride(tempDir.path, 'project_a', '''
deployment-mode-definitions:
  kubernetes:
    replicas: 10
''');
        // project_b has no override

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final projects = yaml['projects'] as YamlMap;

        // Project A has custom replicas
        final projectA = projects['project_a'] as YamlMap;
        final k8sA = (projectA['deployment-mode-definitions'] as YamlMap)['kubernetes'] as YamlMap;
        expect(k8sA['replicas'], equals(10));

        // Project B inherits workspace replicas
        final projectB = projects['project_b'] as YamlMap;
        final k8sB = (projectB['deployment-mode-definitions'] as YamlMap)['kubernetes'] as YamlMap;
        expect(k8sB['replicas'], equals(2));
      });

      test('each project has independent cross-compilation', () async {
        _createMultiProjectWorkspace(tempDir.path, projectCount: 2);
        _addProjectOverride(tempDir.path, 'project_a', '''
cross-compilation:
  build-on:
    darwin-x64:
      targets: [darwin-x64]
      custom: project-a
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final projects = yaml['projects'] as YamlMap;

        // Project A has custom darwin-x64
        final projectA = projects['project_a'] as YamlMap;
        final darwinA = (projectA['cross-compilation'] as YamlMap)['build-on']['darwin-x64'] as YamlMap;
        expect(darwinA['custom'], equals('project-a'));

        // Project B inherits workspace darwin-x64
        final projectB = projects['project_b'] as YamlMap;
        final darwinB = (projectB['cross-compilation'] as YamlMap)['build-on']['darwin-x64'] as YamlMap;
        expect(darwinB['targets'], contains('darwin-x64'));
        expect(darwinB['targets'], contains('linux-x64'));
      });
    });

    // =========================================================================
    // Build ordering
    // =========================================================================
    group('build ordering', () {
      test('projects are sorted alphabetically', () async {
        _createMultiProjectWorkspaceWithDeps(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        // Projects should be sorted alphabetically by name
        final names = analyzer.projects.map((p) => p.name).toList();
        expect(names, equals(['client', 'core', 'server']));
      });

      test('build-after dependencies are set correctly', () async {
        _createMultiProjectWorkspaceWithDeps(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        // Verify build-after info is set
        final client = analyzer.projects.firstWhere((p) => p.name == 'client');
        final server = analyzer.projects.firstWhere((p) => p.name == 'server');
        
        expect(client.buildAfter, contains('core'));
        expect(server.buildAfter, contains('core'));
      });

      test('project build-after is written to master', () async {
        _createMultiProjectWorkspaceWithDeps(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final projects = yaml['projects'] as YamlMap;

        final client = projects['client'] as YamlMap;
        expect(client['build-after'], contains('core'));

        final server = projects['server'] as YamlMap;
        expect(server['build-after'], contains('core'));
      });
    });

    // =========================================================================
    // Multiple project types
    // =========================================================================
    group('multiple project types', () {
      test('different project types get correct type', () async {
        _createMixedProjectWorkspace(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final projects = yaml['projects'] as YamlMap;

        expect((projects['my_package'] as YamlMap)['type'], equals('dart_package'));
        expect((projects['my_console'] as YamlMap)['type'], equals('dart_console'));
      });
    });

    // =========================================================================
    // Per-action files with multiple projects
    // =========================================================================
    group('per-action files with multiple projects', () {
      test('each per-action file contains all projects', () async {
        _createMultiProjectWorkspace(tempDir.path, projectCount: 3);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final buildFile = File(path.join(
            tempDir.path, '.tom_metadata', 'tom_master_build.yaml'));
        final yaml = loadYaml(buildFile.readAsStringSync()) as YamlMap;
        final projects = yaml['projects'] as YamlMap;

        expect(projects.containsKey('project_a'), isTrue);
        expect(projects.containsKey('project_b'), isTrue);
        expect(projects.containsKey('project_c'), isTrue);
      });

      test('project-specific overrides preserved in action files', () async {
        _createMultiProjectWorkspace(tempDir.path, projectCount: 2);
        _addProjectOverride(tempDir.path, 'project_a', '''
deployment-mode-definitions:
  kubernetes:
    replicas: 5
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final buildFile = File(path.join(
            tempDir.path, '.tom_metadata', 'tom_master_build.yaml'));
        final yaml = loadYaml(buildFile.readAsStringSync()) as YamlMap;
        final projects = yaml['projects'] as YamlMap;

        // Project A should have custom replicas even in build file
        final k8sA = (projects['project_a'] as YamlMap)['deployment-mode-definitions']['kubernetes'] as YamlMap;
        expect(k8sA['replicas'], equals(5));

        // Project B should have workspace replicas
        final k8sB = (projects['project_b'] as YamlMap)['deployment-mode-definitions']['kubernetes'] as YamlMap;
        expect(k8sB['replicas'], equals(2));
      });
    });
  });
}

// =============================================================================
// Helper Functions
// =============================================================================

void _createMultiProjectWorkspace(String basePath, {required int projectCount}) {
  for (var i = 0; i < projectCount; i++) {
    final name = String.fromCharCode('a'.codeUnitAt(0) + i);
    final projectName = 'project_$name';
    Directory(path.join(basePath, projectName, 'lib')).createSync(recursive: true);
    File(path.join(basePath, projectName, 'pubspec.yaml')).writeAsStringSync('''
name: $projectName
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
    File(path.join(basePath, projectName, 'lib', '$projectName.dart'))
        .writeAsStringSync('// Lib');
  }

  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
actions:
  build:
    default:
      commands: [workspace-build]
  test:
    default:
      commands: [workspace-test]
deployment-mode-definitions:
  none:
    description: None
  kubernetes:
    replicas: 2
cross-compilation:
  all-targets: [darwin-x64, linux-x64]
  build-on:
    darwin-x64:
      targets: [darwin-x64, linux-x64]
''');
}

void _addProjectOverride(String basePath, String projectName, String content) {
  File(path.join(basePath, projectName, 'tom_project.yaml'))
      .writeAsStringSync(content);
}

void _createMultiProjectWorkspaceWithDeps(String basePath) {
  // Core package (no dependencies)
  Directory(path.join(basePath, 'core', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'core', 'pubspec.yaml')).writeAsStringSync('''
name: core
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'core', 'lib', 'core.dart')).writeAsStringSync('// Core');

  // Client depends on core
  Directory(path.join(basePath, 'client', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'client', 'pubspec.yaml')).writeAsStringSync('''
name: client
version: 1.0.0
environment:
  sdk: ^3.0.0
dependencies:
  core:
    path: ../core
''');
  File(path.join(basePath, 'client', 'lib', 'client.dart')).writeAsStringSync('// Client');
  File(path.join(basePath, 'client', 'tom_project.yaml')).writeAsStringSync('''
build-after: [core]
''');

  // Server depends on core
  Directory(path.join(basePath, 'server', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'server', 'pubspec.yaml')).writeAsStringSync('''
name: server
version: 1.0.0
environment:
  sdk: ^3.0.0
dependencies:
  core:
    path: ../core
''');
  File(path.join(basePath, 'server', 'lib', 'server.dart')).writeAsStringSync('// Server');
  File(path.join(basePath, 'server', 'tom_project.yaml')).writeAsStringSync('''
build-after: [core]
''');

  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
''');
}

void _createMixedProjectWorkspace(String basePath) {
  // Dart package
  Directory(path.join(basePath, 'my_package', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'my_package', 'pubspec.yaml')).writeAsStringSync('''
name: my_package
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'my_package', 'lib', 'my_package.dart'))
      .writeAsStringSync('// Lib');

  // Dart console
  Directory(path.join(basePath, 'my_console', 'bin')).createSync(recursive: true);
  Directory(path.join(basePath, 'my_console', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'my_console', 'pubspec.yaml')).writeAsStringSync('''
name: my_console
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'my_console', 'bin', 'my_console.dart'))
      .writeAsStringSync('void main() {}');
  File(path.join(basePath, 'my_console', 'lib', 'my_console.dart'))
      .writeAsStringSync('// Lib');

  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
''');
}

YamlMap _loadMasterYaml(String basePath) {
  final masterFile = File(path.join(basePath, '.tom_metadata', 'tom_master.yaml'));
  return loadYaml(masterFile.readAsStringSync()) as YamlMap;
}
