/// Comprehensive tests for action variants and action inheritance.
///
/// Tests cover:
/// 1. Action variant selection (default, type-specific, applies-to-types)
/// 2. Multiple actions inheritance
/// 3. Action properties (commands, skip-types, etc.)
/// 4. Per-action file generation for different project types

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Action Variants Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_action_variants_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // =========================================================================
    // Action variant selection
    // =========================================================================
    group('action variant selection', () {
      test('default variant is always present', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands: [dart analyze]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;
        final build = actions['build'] as YamlMap;

        expect(build.containsKey('default'), isTrue);
        expect((build['default'] as YamlMap)['commands'], contains('dart analyze'));
      });

      test('type-specific variant (dart_package)', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands: [echo default]
    dart_package:
      commands: [dart pub get, dart analyze]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;
        final build = actions['build'] as YamlMap;

        expect(build.containsKey('default'), isTrue);
        expect(build.containsKey('dart_package'), isTrue);
      });

      test('multiple type-specific variants', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands: [echo default]
    dart_package:
      commands: [dart pub get]
    dart_console:
      commands: [dart compile exe]
    flutter_app:
      commands: [flutter build]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;
        final build = actions['build'] as YamlMap;

        expect(build.containsKey('default'), isTrue);
        expect(build.containsKey('dart_package'), isTrue);
        expect(build.containsKey('dart_console'), isTrue);
        expect(build.containsKey('flutter_app'), isTrue);
      });
    });

    // =========================================================================
    // applies-to-types property
    // =========================================================================
    group('applies-to-types property', () {
      test('action with applies-to-types restriction', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  compile:
    applies-to-types: [dart_console, dart_server]
    default:
      commands: [dart compile exe]
      output: bin/
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;
        final compile = actions['compile'] as YamlMap;

        expect(compile['applies-to-types'], isNotNull);
        final appliesToTypes = compile['applies-to-types'] as YamlList;
        expect(appliesToTypes, contains('dart_console'));
        expect(appliesToTypes, contains('dart_server'));
      });

      test('action without applies-to-types applies to all', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands: [dart analyze]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;
        final build = actions['build'] as YamlMap;

        // No applies-to-types means applies to all
        expect(build.containsKey('applies-to-types'), isFalse);
      });
    });

    // =========================================================================
    // skip-types property
    // =========================================================================
    group('skip-types property', () {
      test('action with skip-types', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    skip-types: [flutter_plugin]
    default:
      commands: [dart analyze]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;
        final build = actions['build'] as YamlMap;

        expect(build['skip-types'], isNotNull);
        final skipTypes = build['skip-types'] as YamlList;
        expect(skipTypes, contains('flutter_plugin'));
      });
    });

    // =========================================================================
    // Multiple actions
    // =========================================================================
    group('multiple actions', () {
      test('workspace defines build, test, run, deploy actions', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands: [dart analyze]
  test:
    default:
      commands: [dart test]
  run:
    default:
      commands: [dart run]
  deploy:
    default:
      commands: [echo deploying]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;

        expect(actions.containsKey('build'), isTrue);
        expect(actions.containsKey('test'), isTrue);
        expect(actions.containsKey('run'), isTrue);
        expect(actions.containsKey('deploy'), isTrue);
      });

      test('project overrides one action, inherits others', () async {
        _createWorkspaceWithActionsAndOverride(tempDir.path,
          workspaceActions: '''
actions:
  build:
    default:
      commands: [dart analyze]
  test:
    default:
      commands: [dart test]
  deploy:
    default:
      commands: [echo deploy]
''',
          projectActions: '''
actions:
  build:
    default:
      commands: [custom build]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;

        // build is overridden
        final build = actions['build'] as YamlMap;
        expect((build['default'] as YamlMap)['commands'], contains('custom build'));

        // test and deploy are inherited
        expect(actions.containsKey('test'), isTrue);
        expect(actions.containsKey('deploy'), isTrue);
        final test = actions['test'] as YamlMap;
        expect((test['default'] as YamlMap)['commands'], contains('dart test'));
      });

      test('project overrides multiple actions', () async {
        _createWorkspaceWithActionsAndOverride(tempDir.path,
          workspaceActions: '''
actions:
  build:
    default:
      commands: [ws build]
  test:
    default:
      commands: [ws test]
  deploy:
    default:
      commands: [ws deploy]
''',
          projectActions: '''
actions:
  build:
    default:
      commands: [proj build]
  test:
    default:
      commands: [proj test]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;

        // build and test are overridden
        expect((actions['build'] as YamlMap)['default']['commands'], 
            contains('proj build'));
        expect((actions['test'] as YamlMap)['default']['commands'], 
            contains('proj test'));

        // deploy is inherited
        expect((actions['deploy'] as YamlMap)['default']['commands'], 
            contains('ws deploy'));
      });
    });

    // =========================================================================
    // Action properties
    // =========================================================================
    group('action properties', () {
      test('commands is a list', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands:
        - dart pub get
        - dart analyze
        - dart format --set-exit-if-changed .
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final commands = (project['actions'] as YamlMap)['build']['default']['commands'] as YamlList;

        expect(commands.length, equals(3));
        expect(commands[0], equals('dart pub get'));
        expect(commands[1], equals('dart analyze'));
      });

      test('output property', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  compile:
    default:
      commands: [dart compile exe]
      output: bin/\${name}
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final compile = (project['actions'] as YamlMap)['compile'] as YamlMap;

        expect(compile['default']['output'], contains('bin/'));
      });

      test('working-dir property', () async {
        _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands: [make build]
      working-dir: native/
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final build = (project['actions'] as YamlMap)['build'] as YamlMap;

        expect(build['default']['working-dir'], equals('native/'));
      });
    });

    // =========================================================================
    // Project adds new action
    // =========================================================================
    group('project adds new action', () {
      test('project defines action not in workspace', () async {
        _createWorkspaceWithActionsAndOverride(tempDir.path,
          workspaceActions: '''
actions:
  build:
    default:
      commands: [dart analyze]
''',
          projectActions: '''
actions:
  custom-action:
    default:
      commands: [custom command]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final actions = project['actions'] as YamlMap;

        // Both actions should be present
        expect(actions.containsKey('build'), isTrue);
        expect(actions.containsKey('custom-action'), isTrue);
      });
    });
  });

  // ===========================================================================
  // Per-Action File Tests
  // ===========================================================================
  group('Per-Action File Generation', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_per_action_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('generates tom_master_build.yaml when build action exists', () async {
      _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands: [dart analyze]
''');

      final analyzer = WorkspaceAnalyzer(tempDir.path);
      await analyzer.analyze();

      final buildFile = File(path.join(
          tempDir.path, '.tom_metadata', 'tom_master_build.yaml'));
      expect(buildFile.existsSync(), isTrue);

      final yaml = loadYaml(buildFile.readAsStringSync()) as YamlMap;
      expect(yaml['action'], equals('build'));
    });

    test('generates tom_master_test.yaml when test action exists', () async {
      _createWorkspaceWithActions(tempDir.path, '''
actions:
  test:
    default:
      commands: [dart test]
''');

      final analyzer = WorkspaceAnalyzer(tempDir.path);
      await analyzer.analyze();

      final testFile = File(path.join(
          tempDir.path, '.tom_metadata', 'tom_master_test.yaml'));
      expect(testFile.existsSync(), isTrue);

      final yaml = loadYaml(testFile.readAsStringSync()) as YamlMap;
      expect(yaml['action'], equals('test'));
    });

    test('generates file for custom action', () async {
      _createWorkspaceWithActions(tempDir.path, '''
actions:
  custom-action:
    default:
      commands: [echo custom]
''');

      final analyzer = WorkspaceAnalyzer(tempDir.path);
      await analyzer.analyze();

      final customFile = File(path.join(
          tempDir.path, '.tom_metadata', 'tom_master_custom-action.yaml'));
      expect(customFile.existsSync(), isTrue);

      final yaml = loadYaml(customFile.readAsStringSync()) as YamlMap;
      expect(yaml['action'], equals('custom-action'));
    });

    test('each per-action file has merged project config', () async {
      _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands: [dart analyze]
deployment-mode-definitions:
  kubernetes:
    replicas: 2
''');

      final analyzer = WorkspaceAnalyzer(tempDir.path);
      await analyzer.analyze();

      final buildFile = File(path.join(
          tempDir.path, '.tom_metadata', 'tom_master_build.yaml'));
      final yaml = loadYaml(buildFile.readAsStringSync()) as YamlMap;
      final project = _getFirstProject(yaml);

      // Should have deployment modes even in build file
      expect(project.containsKey('deployment-mode-definitions'), isTrue);
    });

    test('multiple actions generate multiple files', () async {
      _createWorkspaceWithActions(tempDir.path, '''
actions:
  build:
    default:
      commands: [dart analyze]
  test:
    default:
      commands: [dart test]
  compile:
    default:
      commands: [dart compile]
  run:
    default:
      commands: [dart run]
  deploy:
    default:
      commands: [echo deploy]
''');

      final analyzer = WorkspaceAnalyzer(tempDir.path);
      await analyzer.analyze();

      final metadataDir = Directory(path.join(tempDir.path, '.tom_metadata'));
      final actionFiles = metadataDir.listSync()
          .whereType<File>()
          .where((f) => path.basename(f.path).startsWith('tom_master_'))
          .toList();

      expect(actionFiles.length, equals(5));
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
}

void _createWorkspaceWithActions(String basePath, String actionDefinitions) {
  _createDartPackage(basePath);
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
$actionDefinitions
''');
}

void _createWorkspaceWithActionsAndOverride(
  String basePath, {
  required String workspaceActions,
  required String projectActions,
}) {
  _createDartPackage(basePath);
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
$workspaceActions
''');
  File(path.join(basePath, 'tom_project.yaml')).writeAsStringSync(projectActions);
}

YamlMap _loadMasterYaml(String basePath) {
  final masterFile = File(path.join(basePath, '.tom_metadata', 'tom_master.yaml'));
  return loadYaml(masterFile.readAsStringSync()) as YamlMap;
}

YamlMap _getFirstProject(YamlMap yaml) {
  final projects = yaml['projects'] as YamlMap;
  return projects.values.first as YamlMap;
}
