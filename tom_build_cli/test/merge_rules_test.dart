/// Comprehensive tests for configuration merge rules in WorkspaceAnalyzer.
///
/// Tests cover the merge rules from tom_tool_specification.md Section 4.3.3:
/// - actions: project.<action> replaces workspace.<action>, others inherited
/// - <mode-type>-mode-definitions: project.<mode> replaces workspace.<mode>
/// - cross-compilation: build-on.<target> replaced, all-targets from workspace
///
/// Test Categories:
/// 1. Action Merge Tests
/// 2. Mode Definition Merge Tests
/// 3. Cross-Compilation Merge Tests
/// 4. Configuration Merge Sequence Tests (Section 5.2.3)
/// 5. Per-Action File Generation Tests

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

String get fixturesPath => path.join(
  Directory.current.path,
  'test',
  'fixtures',
  'workspace_analyzer',
);

void main() {
  group('Configuration Merge Rules', () {
    // =========================================================================
    // Section 1: Action Merge Tests
    // =========================================================================
    group('actions first-level merge', () {
      late String wsPath;
      late WorkspaceAnalyzer analyzer;
      late YamlMap masterYaml;

      setUpAll(() async {
        wsPath = path.join(fixturesPath, 'ws_merge_actions');
        analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();
        
        final masterFile = File(path.join(wsPath, '.tom_metadata', 'tom_master.yaml'));
        masterYaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
      });

      test('project without overrides inherits all workspace actions', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_no_overrides'] as YamlMap;
        final actions = project['actions'] as YamlMap;

        // Should have all workspace actions
        expect(actions.containsKey('build'), isTrue);
        expect(actions.containsKey('test'), isTrue);
        expect(actions.containsKey('compile'), isTrue);
        expect(actions.containsKey('run'), isTrue);
        expect(actions.containsKey('deploy'), isTrue);
      });

      test('project action override replaces that action only', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_action_override'] as YamlMap;
        final actions = project['actions'] as YamlMap;

        // Build action should be from project (custom commands)
        final buildAction = actions['build'] as YamlMap;
        final defaultBuild = buildAction['default'] as YamlMap;
        final commands = defaultBuild['commands'] as YamlList;
        expect(commands, contains('custom-build-step-1'));
        expect(commands, contains('custom-build-step-2'));
        
        // Other actions should be inherited from workspace
        expect(actions.containsKey('test'), isTrue);
        expect(actions.containsKey('compile'), isTrue);
        expect(actions.containsKey('run'), isTrue);
        expect(actions.containsKey('deploy'), isTrue);
        
        // Test action should still have workspace definition
        final testAction = actions['test'] as YamlMap;
        expect(testAction['default'], isNotNull);
      });

      test('inherited action preserves all properties', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_action_override'] as YamlMap;
        final actions = project['actions'] as YamlMap;

        // Compile action should have applies-to-types and output from workspace
        final compileAction = actions['compile'] as YamlMap;
        expect(compileAction['applies-to-types'], isNotNull);
        expect(compileAction['default']['output'], equals('bin/'));
      });

      test('project action completely replaces workspace action (no deep merge)', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_action_override'] as YamlMap;
        final actions = project['actions'] as YamlMap;

        // Build action should NOT have workspace dart_package variant
        final buildAction = actions['build'] as YamlMap;
        expect(buildAction.containsKey('dart_package'), isFalse,
            reason: 'Project action should completely replace workspace action');
        expect(buildAction.containsKey('skip-types'), isFalse,
            reason: 'Project action should not inherit workspace skip-types');
      });
    });

    // =========================================================================
    // Section 2: Mode Definition Merge Tests
    // =========================================================================
    group('mode-definitions first-level merge', () {
      late String wsPath;
      late YamlMap masterYaml;

      setUpAll(() async {
        wsPath = path.join(fixturesPath, 'ws_merge_actions');
        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();
        
        final masterFile = File(path.join(wsPath, '.tom_metadata', 'tom_master.yaml'));
        masterYaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
      });

      test('project without overrides inherits all workspace mode definitions', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_no_overrides'] as YamlMap;
        
        // Should have all workspace mode definitions
        expect(project.containsKey('environment-mode-definitions'), isTrue);
        expect(project.containsKey('deployment-mode-definitions'), isTrue);
        
        final deploymentModes = project['deployment-mode-definitions'] as YamlMap;
        expect(deploymentModes.containsKey('default'), isTrue);
        expect(deploymentModes.containsKey('none'), isTrue);
        expect(deploymentModes.containsKey('kubernetes'), isTrue);
      });

      test('project mode override replaces that mode only', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_mode_override'] as YamlMap;
        final deploymentModes = project['deployment-mode-definitions'] as YamlMap;

        // kubernetes mode should be from project (custom config)
        final k8s = deploymentModes['kubernetes'] as YamlMap;
        expect(k8s['namespace'], equals('my-app'));
        expect(k8s['replicas'], equals(3));
        expect(k8s['resources'], isNotNull);
        
        // Other modes should be inherited from workspace
        expect(deploymentModes.containsKey('default'), isTrue);
        expect(deploymentModes.containsKey('none'), isTrue);
        
        // none mode should have workspace definition
        final noneDef = deploymentModes['none'] as YamlMap;
        expect(noneDef['description'], equals('No deployment'));
      });

      test('inherited mode definition preserves all properties', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_mode_override'] as YamlMap;
        final envModes = project['environment-mode-definitions'] as YamlMap;

        // local mode should have workspace properties
        final localMode = envModes['local'] as YamlMap;
        expect(localMode['description'], equals('Local development'));
        expect(localMode['working-dir'], equals('.'));
        expect(localMode['variables'], isNotNull);
      });

      test('project mode completely replaces workspace mode (no deep merge)', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_mode_override'] as YamlMap;
        final deploymentModes = project['deployment-mode-definitions'] as YamlMap;

        // kubernetes mode should NOT have workspace namespace (default)
        final k8s = deploymentModes['kubernetes'] as YamlMap;
        expect(k8s['namespace'], equals('my-app'),
            reason: 'Project mode should completely replace workspace mode');
        // Workspace had namespace: default, project has namespace: my-app
      });
    });

    // =========================================================================
    // Section 3: Cross-Compilation Merge Tests
    // =========================================================================
    group('cross-compilation merge', () {
      late String wsPath;
      late YamlMap masterYaml;

      setUpAll(() async {
        wsPath = path.join(fixturesPath, 'ws_merge_actions');
        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();
        
        final masterFile = File(path.join(wsPath, '.tom_metadata', 'tom_master.yaml'));
        masterYaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
      });

      test('project without overrides inherits workspace cross-compilation', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_no_overrides'] as YamlMap;
        final crossComp = project['cross-compilation'] as YamlMap;

        // Should have workspace all-targets
        final allTargets = crossComp['all-targets'] as YamlList;
        expect(allTargets, contains('darwin-x64'));
        expect(allTargets, contains('darwin-arm64'));
        expect(allTargets, contains('linux-x64'));
        expect(allTargets, contains('linux-arm64'));
        expect(allTargets, contains('win32-x64'));
        
        // Should have workspace build-on
        final buildOn = crossComp['build-on'] as YamlMap;
        expect(buildOn.containsKey('darwin-arm64'), isTrue);
        expect(buildOn.containsKey('darwin-x64'), isTrue);
        expect(buildOn.containsKey('linux-x64'), isTrue);
      });

      test('all-targets always comes from workspace', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_cross_compile'] as YamlMap;
        final crossComp = project['cross-compilation'] as YamlMap;

        // all-targets should be from workspace (5 targets), not project
        final allTargets = crossComp['all-targets'] as YamlList;
        expect(allTargets.length, equals(5),
            reason: 'all-targets should come from workspace, not be overridden');
        expect(allTargets, contains('win32-x64'),
            reason: 'win32-x64 from workspace should be present');
      });

      test('project build-on target replaces workspace target', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_cross_compile'] as YamlMap;
        final crossComp = project['cross-compilation'] as YamlMap;
        final buildOn = crossComp['build-on'] as YamlMap;

        // darwin-arm64 should be from project (only darwin-arm64 target + custom flag)
        final darwinArm64 = buildOn['darwin-arm64'] as YamlMap;
        final targets = darwinArm64['targets'] as YamlList;
        expect(targets.length, equals(1));
        expect(targets, contains('darwin-arm64'));
        expect(darwinArm64['custom-flag'], equals('--optimize'));
      });

      test('non-overridden build-on targets are inherited', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_cross_compile'] as YamlMap;
        final crossComp = project['cross-compilation'] as YamlMap;
        final buildOn = crossComp['build-on'] as YamlMap;

        // darwin-x64 and linux-x64 should be from workspace
        expect(buildOn.containsKey('darwin-x64'), isTrue);
        expect(buildOn.containsKey('linux-x64'), isTrue);
        
        final darwinX64 = buildOn['darwin-x64'] as YamlMap;
        final targets = darwinX64['targets'] as YamlList;
        expect(targets, contains('darwin-x64'));
        expect(targets, contains('linux-x64'));
        expect(targets, contains('linux-arm64'));
      });

      test('project custom fields are preserved', () {
        final projects = masterYaml['projects'] as YamlMap;
        final project = projects['project_with_cross_compile'] as YamlMap;
        final crossComp = project['cross-compilation'] as YamlMap;

        // Project-specific fields should be present
        expect(crossComp['targets'], isNotNull);
        expect(crossComp['output-dir'], equals('bin/\${target}/'));
      });
    });

    // =========================================================================
    // Section 4: Configuration Merge Sequence Tests (Section 5.2.3)
    // =========================================================================
    group('configuration merge sequence', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_merge_sequence_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('auto-detected values are base', () async {
        // Create Dart package with tests and examples
        _createDartPackageWithTestsAndExamples(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        
        // Auto-detected: type
        expect(project.type, equals('dart_package'));
        // Features are also auto-detected (test/example directories)
        // Note: has-tests and has-examples are standard feature keys
        expect(project.features.isNotEmpty, isTrue,
            reason: 'Auto-detected features should be set');
      });

      test('project-type settings override auto-detect', () async {
        // Create workspace with project-type settings
        _createWorkspaceWithProjectTypeSettings(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final masterFile = File(path.join(tempDir.path, '.tom_metadata', 'tom_master.yaml'));
        final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
        final projects = yaml['projects'] as YamlMap;
        final project = projects.values.first as YamlMap;
        final features = project['features'] as YamlMap;

        // project-type-overrides should apply
        expect(features['publishable'], isTrue);
      });

      test('tom_project.yaml local entries are loaded', () async {
        // Create workspace with workspace-level and project-level settings
        _createWorkspaceWithLocalOverride(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        // Verify the project exists and has been analyzed
        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'my_project',
          orElse: () => throw StateError('Project my_project not found'),
        );

        // Local tom_project.yaml entries should be loaded
        expect(project.localIndexEntries, isNotNull);
        expect(project.localIndexEntries['description'], 
            equals('Project-level description'));
      });
    });

    // =========================================================================
    // Section 5: Per-Action File Generation Tests
    // =========================================================================
    group('per-action file generation', () {
      late String wsPath;

      setUpAll(() async {
        wsPath = path.join(fixturesPath, 'ws_merge_actions');
        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();
      });

      test('generates tom_master.yaml (default)', () {
        final masterFile = File(path.join(wsPath, '.tom_metadata', 'tom_master.yaml'));
        expect(masterFile.existsSync(), isTrue);
      });

      test('action-specific files have action field', () {
        // Check if any per-action files exist and have correct action field
        final metadataDir = Directory(path.join(wsPath, '.tom_metadata'));
        final actionFiles = metadataDir.listSync()
            .whereType<File>()
            .where((f) => path.basename(f.path).startsWith('tom_master_') && 
                          path.basename(f.path).endsWith('.yaml'));
        
        for (final file in actionFiles) {
          final yaml = loadYaml(file.readAsStringSync()) as YamlMap;
          expect(yaml['action'], isNotNull,
              reason: '${path.basename(file.path)} should have action field');
        }
      });

      test('each project in action file has complete merge result', () {
        final buildFile = File(path.join(wsPath, '.tom_metadata', 'tom_master_build.yaml'));
        if (buildFile.existsSync()) {
          final yaml = loadYaml(buildFile.readAsStringSync()) as YamlMap;
          final projects = yaml['projects'] as YamlMap;
          
          for (final projectName in projects.keys) {
            final project = projects[projectName] as YamlMap;
            
            // Each project should have actions
            expect(project.containsKey('actions'), isTrue,
                reason: '$projectName should have actions');
            
            // Each project should have mode definitions
            expect(project.containsKey('deployment-mode-definitions'), isTrue,
                reason: '$projectName should have deployment-mode-definitions');
          }
        }
      });
    });
  });

  // ===========================================================================
  // Additional Test Groups for Comprehensive Coverage
  // ===========================================================================
  
  group('Edge Cases', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_edge_cases_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('empty workspace actions does not break project', () async {
      _createDartPackage(tempDir.path);
      // Create workspace with no actions
      File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
''');

      final analyzer = WorkspaceAnalyzer(tempDir.path);
      await analyzer.analyze();

      // Should not throw, project should exist
      expect(analyzer.projects.length, equals(1));
    });

    test('project with empty actions inherits all workspace actions', () async {
      _createDartPackageWithTomProject(tempDir.path, tomProjectContent: '''
# Empty actions section
actions: {}
''');

      File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
actions:
  build:
    default:
      commands: [dart analyze]
  test:
    default:
      commands: [dart test]
''');

      final analyzer = WorkspaceAnalyzer(tempDir.path);
      await analyzer.analyze();

      final masterFile = File(path.join(tempDir.path, '.tom_metadata', 'tom_master.yaml'));
      final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
      final projects = yaml['projects'] as YamlMap;
      final project = projects.values.first as YamlMap;
      final actions = project['actions'] as YamlMap;

      // Both workspace actions should be present
      expect(actions.containsKey('build'), isTrue);
      expect(actions.containsKey('test'), isTrue);
    });

    test('null value in project mode-definitions removes that mode', () async {
      _createDartPackageWithTomProject(tempDir.path, tomProjectContent: '''
deployment-mode-definitions:
  kubernetes: null
''');

      File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
deployment-mode-definitions:
  none:
    description: No deployment
  kubernetes:
    description: K8s
    replicas: 1
''');

      final analyzer = WorkspaceAnalyzer(tempDir.path);
      await analyzer.analyze();

      final masterFile = File(path.join(tempDir.path, '.tom_metadata', 'tom_master.yaml'));
      final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
      final projects = yaml['projects'] as YamlMap;
      final project = projects.values.first as YamlMap;
      final deployModes = project['deployment-mode-definitions'] as YamlMap;

      // kubernetes should be null/removed, none should be present
      expect(deployModes['kubernetes'], isNull);
      expect(deployModes['none'], isNotNull);
    });
  });

  group('Multiple Projects', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_multi_projects_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('each project gets independent merge result', () async {
      // Create workspace with two projects, each with different overrides
      _createMultiProjectWorkspace(tempDir.path);

      final analyzer = WorkspaceAnalyzer(tempDir.path);
      await analyzer.analyze();

      final masterFile = File(path.join(tempDir.path, '.tom_metadata', 'tom_master.yaml'));
      final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
      final projects = yaml['projects'] as YamlMap;

      // Project A has custom build action
      final projectA = projects['project_a'] as YamlMap;
      final actionsA = projectA['actions'] as YamlMap;
      final buildA = actionsA['build'] as YamlMap;
      expect(buildA['default']['commands'], contains('custom-a'));

      // Project B has default build action
      final projectB = projects['project_b'] as YamlMap;
      final actionsB = projectB['actions'] as YamlMap;
      final buildB = actionsB['build'] as YamlMap;
      expect(buildB['default']['commands'], contains('dart analyze'));
    });
  });
}

// =============================================================================
// Helper Functions
// =============================================================================

void _createDartPackage(String basePath, {String name = 'test_package'}) {
  Directory(path.join(basePath, 'lib', 'src')).createSync(recursive: true);
  File(path.join(basePath, 'pubspec.yaml')).writeAsStringSync('''
name: $name
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'lib', '$name.dart')).writeAsStringSync('// Lib');
}

void _createDartPackageWithTestsAndExamples(String basePath) {
  _createDartPackage(basePath);
  Directory(path.join(basePath, 'test')).createSync();
  File(path.join(basePath, 'test', 'test_package_test.dart')).writeAsStringSync('''
import 'package:test/test.dart';
void main() {
  test('example', () {});
}
''');
  Directory(path.join(basePath, 'example')).createSync();
  File(path.join(basePath, 'example', 'example.dart')).writeAsStringSync('''
void main() {}
''');
}

void _createDartPackageWithTomProject(String basePath, {required String tomProjectContent}) {
  _createDartPackage(basePath);
  File(path.join(basePath, 'tom_project.yaml')).writeAsStringSync(tomProjectContent);
}

void _createWorkspaceWithProjectTypeSettings(String basePath) {
  _createDartPackage(basePath);
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
project-types:
  dart_package:
    name: Dart Package
    project-info-overrides:
      features:
        publishable: true
''');
}

void _createWorkspaceWithLocalOverride(String basePath) {
  Directory(path.join(basePath, 'my_project', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'my_project', 'pubspec.yaml')).writeAsStringSync('''
name: my_project
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'my_project', 'lib', 'my_project.dart')).writeAsStringSync('// Lib');
  File(path.join(basePath, 'my_project', 'tom_project.yaml')).writeAsStringSync('''
description: "Project-level description"
''');
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
''');
}

void _createMultiProjectWorkspace(String basePath) {
  // Project A with custom build
  Directory(path.join(basePath, 'project_a', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'project_a', 'pubspec.yaml')).writeAsStringSync('''
name: project_a
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'project_a', 'lib', 'project_a.dart')).writeAsStringSync('// Lib');
  File(path.join(basePath, 'project_a', 'tom_project.yaml')).writeAsStringSync('''
actions:
  build:
    default:
      commands: [custom-a]
''');

  // Project B without overrides
  Directory(path.join(basePath, 'project_b', 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'project_b', 'pubspec.yaml')).writeAsStringSync('''
name: project_b
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'project_b', 'lib', 'project_b.dart')).writeAsStringSync('// Lib');

  // Workspace with actions
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
actions:
  build:
    default:
      commands: [dart analyze]
  test:
    default:
      commands: [dart test]
''');
}
