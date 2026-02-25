/// Edge case and error handling tests for WorkspaceAnalyzer.
///
/// Tests cover:
/// 1. Empty sections
/// 2. Null values
/// 3. Missing files
/// 4. Invalid YAML
/// 5. Boundary conditions

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Edge Cases and Error Handling', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_edge_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // =========================================================================
    // Empty sections
    // =========================================================================
    group('empty sections', () {
      test('empty actions section in workspace', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
actions: {}
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        // Should not throw
        expect(analyzer.projects.length, equals(1));
      });

      test('empty mode-definitions in workspace', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
deployment-mode-definitions: {}
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.length, equals(1));
      });

      test('empty cross-compilation in workspace', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
cross-compilation: {}
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.length, equals(1));
      });

      test('empty project tom_project.yaml', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_project.yaml')).writeAsStringSync('');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.length, equals(1));
      });
    });

    // =========================================================================
    // Null and missing values
    // =========================================================================
    group('null and missing values', () {
      test('null action in project removes it', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
actions:
  build:
    default:
      commands: [build]
  test:
    default:
      commands: [test]
''');
        File(path.join(tempDir.path, 'tom_project.yaml')).writeAsStringSync('''
actions:
  build: null
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;

        // build should be null, test should exist
        expect(actions['build'], isNull);
        expect(actions['test'], isNotNull);
      });

      test('null mode in project removes it', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
deployment-mode-definitions:
  kubernetes:
    replicas: 2
  docker:
    image: app
''');
        File(path.join(tempDir.path, 'tom_project.yaml')).writeAsStringSync('''
deployment-mode-definitions:
  kubernetes: null
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final modes = project['deployment-mode-definitions'] as YamlMap;

        expect(modes['kubernetes'], isNull);
        expect(modes['docker'], isNotNull);
      });

      test('workspace without tom_workspace.yaml uses defaults', () async {
        _createDartPackageNoWorkspace(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.length, equals(1));
      });
    });

    // =========================================================================
    // Minimal workspace
    // =========================================================================
    group('minimal workspace', () {
      test('minimal workspace with just name', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: minimal
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.length, equals(1));
        expect(analyzer.workspaceSettings['name'], equals('minimal'));
      });

      test('single project workspace', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final projects = yaml['projects'] as YamlMap;
        
        expect(projects.length, equals(1));
      });
    });

    // =========================================================================
    // Large values
    // =========================================================================
    group('large values', () {
      test('many targets in cross-compilation', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
cross-compilation:
  all-targets:
    - darwin-x64
    - darwin-arm64
    - linux-x64
    - linux-arm64
    - linux-riscv64
    - win32-x64
    - win32-arm64
    - android-arm
    - android-arm64
    - ios-arm64
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final allTargets = crossComp['all-targets'] as YamlList;

        expect(allTargets.length, equals(10));
      });

      test('many actions', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
actions:
  build:
    default:
      commands: [build]
  test:
    default:
      commands: [test]
  lint:
    default:
      commands: [lint]
  format:
    default:
      commands: [format]
  analyze:
    default:
      commands: [analyze]
  compile:
    default:
      commands: [compile]
  run:
    default:
      commands: [run]
  deploy:
    default:
      commands: [deploy]
  publish:
    default:
      commands: [publish]
  clean:
    default:
      commands: [clean]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;

        expect(actions.length, equals(10));
      });

      test('all mode types defined', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
environment-mode-definitions:
  local:
    port: 3000
execution-mode-definitions:
  debug:
    optimization: none
deployment-mode-definitions:
  kubernetes:
    replicas: 2
cloud-provider-mode-definitions:
  aws:
    region: us-east-1
publishing-mode-definitions:
  pub-dev:
    dry-run: true
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);

        expect(project.containsKey('environment-mode-definitions'), isTrue);
        expect(project.containsKey('execution-mode-definitions'), isTrue);
        expect(project.containsKey('deployment-mode-definitions'), isTrue);
        expect(project.containsKey('cloud-provider-mode-definitions'), isTrue);
        expect(project.containsKey('publishing-mode-definitions'), isTrue);
      });
    });

    // =========================================================================
    // Special characters
    // =========================================================================
    group('special characters', () {
      test('commands with special characters', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
actions:
  build:
    default:
      commands:
        - echo "Hello World"
        - 'dart run --define=DEBUG=true'
        - test -f ./output && echo "exists"
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final commands = (project['actions'] as YamlMap)['build']['default']['commands'] as YamlList;

        expect(commands.length, equals(3));
      });

      test('variables in output path', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
cross-compilation:
  all-targets: [darwin-x64]
  output-dir: 'bin/\${target}/\${version}/'
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        // Just verify it doesn't crash with variables
        expect(analyzer.projects.length, equals(1));
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

void _createDartPackageNoWorkspace(String basePath, {String name = 'test_package'}) {
  Directory(path.join(basePath, 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'pubspec.yaml')).writeAsStringSync('''
name: $name
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'lib', '$name.dart')).writeAsStringSync('// Lib');
}

YamlMap _loadMasterYaml(String basePath) {
  final masterFile = File(path.join(basePath, '.tom_metadata', 'tom_master.yaml'));
  return loadYaml(masterFile.readAsStringSync()) as YamlMap;
}

YamlMap _getFirstProject(YamlMap yaml) {
  final projects = yaml['projects'] as YamlMap;
  return projects.values.first as YamlMap;
}
