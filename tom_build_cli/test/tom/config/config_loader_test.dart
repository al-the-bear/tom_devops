import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/config/config_loader.dart';

void main() {
  group('ConfigLoader', () {
    late ConfigLoader loader;
    late Directory tempDir;

    setUp(() {
      loader = ConfigLoader();
      tempDir = Directory.systemTemp.createTempSync('config_loader_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('loadWorkspaceConfig', () {
      test('returns null when file does not exist', () {
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result, isNull);
      });

      test('loads minimal workspace config', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    default:
      commands:
        - dart compile exe
''');

        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result, isNotNull);
        expect(result!.actions, contains('build'));
      });

      test('loads workspace with all sections', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
name: test_workspace
binaries: bin/

workspace-modes:
  mode-types: [environment, execution]
  supported:
    - name: development
      implies: [debug, verbose]

environment-mode-definitions:
  local:
    description: Local development

actions:
  build:
    default:
      commands:
        - dart compile exe

groups:
  core:
    projects:
      - tom_core
      - tom_build

project-info:
  tom_core:
    description: Core library

deps:
  http: ^1.0.0

custom_tag: custom_value
''');

        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result, isNotNull);
        expect(result!.name, equals('test_workspace'));
        expect(result.binaries, equals('bin/'));
        expect(result.workspaceModes, isNotNull);
        expect(result.modeDefinitions, contains('environment'));
        expect(result.actions, contains('build'));
        expect(result.groups, contains('core'));
        expect(result.projectInfo, contains('tom_core'));
        expect(result.deps, contains('http'));
        expect(result.customTags, contains('custom_tag'));
      });

      test('throws ConfigLoadException on invalid YAML', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    - invalid: [syntax
''');

        expect(
          () => loader.loadWorkspaceConfig(tempDir.path),
          throwsA(isA<ConfigLoadException>()),
        );
      });
    });

    group('loadProjectConfig', () {
      test('returns null when file does not exist', () {
        final result = loader.loadProjectConfig(tempDir.path, 'test_project');
        expect(result, isNull);
      });

      test('loads project config with basic fields', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
description: Test project
build-after:
  - tom_core
''');

        final result = loader.loadProjectConfig(tempDir.path, 'test_project');
        expect(result, isNotNull);
        expect(result!.name, equals('test_project'));
        expect(result.type, equals('dart_package'));
        expect(result.description, equals('Test project'));
        expect(result.buildAfter, contains('tom_core'));
      });

      test('loads project with features', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
features:
  has-tests: true
  publishable: false
''');

        final result = loader.loadProjectConfig(tempDir.path, 'test_project');
        expect(result, isNotNull);
        expect(result!.features, isNotNull);
        expect(result.features!['has-tests'], isTrue);
        expect(result.features!['publishable'], isFalse);
      });
    });

    group('loadYamlFile', () {
      test('loads YAML file as Map', () {
        _createFile(tempDir, 'test.yaml', '''
key1: value1
key2:
  nested: value2
list:
  - item1
  - item2
''');

        final result = loader.loadYamlFile(path.join(tempDir.path, 'test.yaml'));
        expect(result['key1'], equals('value1'));
        expect(result['key2'], isA<Map>());
        expect(result['key2']['nested'], equals('value2'));
        expect(result['list'], isA<List>());
      });

      test('throws ConfigLoadException when file not found', () {
        expect(
          () => loader.loadYamlFile(path.join(tempDir.path, 'nonexistent.yaml')),
          throwsA(isA<ConfigLoadException>()),
        );
      });
    });

    group('loadWorkspaceWithImports', () {
      test('merges imported files', () {
        // Create base config
        _createFile(tempDir, 'base.yaml', '''
actions:
  build:
    default:
      commands:
        - echo base
deps:
  http: ^1.0.0
''');

        // Create workspace that imports base
        _createFile(tempDir, 'tom_workspace.yaml', '''
imports:
  - base.yaml
actions:
  build:
    default:
      commands:
        - echo workspace
deps:
  path: ^1.8.0
''');

        final result = loader.loadWorkspaceWithImports(tempDir.path);
        expect(result, isNotNull);
        // Workspace overrides base
        expect(result!.deps, contains('http'));
        expect(result.deps, contains('path'));
      });
    });
  });
}

/// Helper to create a file in the temp directory.
void _createFile(Directory dir, String name, String content) {
  final file = File(path.join(dir.path, name));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}
