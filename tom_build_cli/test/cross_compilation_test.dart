/// Comprehensive tests for cross-compilation configuration merge.
///
/// Tests cover:
/// 1. all-targets always from workspace
/// 2. build-on.<target> first-level merge
/// 3. Project-specific cross-compilation fields
/// 4. Multiple build-on targets

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Cross-Compilation Merge Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_cross_comp_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // =========================================================================
    // all-targets from workspace
    // =========================================================================
    group('all-targets from workspace', () {
      test('workspace all-targets is used', () async {
        _createWorkspaceWithCrossCompilation(tempDir.path, '''
cross-compilation:
  all-targets:
    - darwin-x64
    - darwin-arm64
    - linux-x64
    - linux-arm64
    - win32-x64
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final allTargets = crossComp['all-targets'] as YamlList;

        expect(allTargets.length, equals(5));
        expect(allTargets, contains('darwin-x64'));
        expect(allTargets, contains('darwin-arm64'));
        expect(allTargets, contains('linux-x64'));
        expect(allTargets, contains('linux-arm64'));
        expect(allTargets, contains('win32-x64'));
      });

      test('project cannot override all-targets', () async {
        _createWorkspaceWithCrossCompilationOverride(tempDir.path,
          workspace: '''
cross-compilation:
  all-targets:
    - darwin-x64
    - darwin-arm64
    - linux-x64
''',
          project: '''
cross-compilation:
  all-targets:
    - only-this-one
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final allTargets = crossComp['all-targets'] as YamlList;

        // Should still have workspace targets, not project override
        expect(allTargets.length, equals(3));
        expect(allTargets, contains('darwin-x64'));
        expect(allTargets, isNot(contains('only-this-one')));
      });

      test('project all-targets is ignored', () async {
        _createWorkspaceWithCrossCompilationOverride(tempDir.path,
          workspace: '''
cross-compilation:
  all-targets: [darwin-x64, linux-x64]
''',
          project: '''
cross-compilation:
  all-targets: [custom-platform]
  targets: [darwin-x64]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;

        // all-targets from workspace
        final allTargets = crossComp['all-targets'] as YamlList;
        expect(allTargets, contains('darwin-x64'));
        expect(allTargets, contains('linux-x64'));
        expect(allTargets, isNot(contains('custom-platform')));

        // targets from project
        expect(crossComp['targets'], isNotNull);
      });
    });

    // =========================================================================
    // build-on first-level merge
    // =========================================================================
    group('build-on first-level merge', () {
      test('workspace build-on is inherited', () async {
        _createWorkspaceWithCrossCompilation(tempDir.path, '''
cross-compilation:
  all-targets: [darwin-x64, linux-x64]
  build-on:
    darwin-x64:
      targets: [darwin-x64, linux-x64]
    linux-x64:
      targets: [linux-x64]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final buildOn = crossComp['build-on'] as YamlMap;

        expect(buildOn.containsKey('darwin-x64'), isTrue);
        expect(buildOn.containsKey('linux-x64'), isTrue);
      });

      test('project build-on target replaces workspace target', () async {
        _createWorkspaceWithCrossCompilationOverride(tempDir.path,
          workspace: '''
cross-compilation:
  all-targets: [darwin-x64, darwin-arm64, linux-x64]
  build-on:
    darwin-x64:
      targets: [darwin-x64, linux-x64]
      flags: --workspace-flag
''',
          project: '''
cross-compilation:
  build-on:
    darwin-x64:
      targets: [darwin-x64]
      flags: --project-flag
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final buildOn = crossComp['build-on'] as YamlMap;
        final darwinX64 = buildOn['darwin-x64'] as YamlMap;

        // Should be project's version
        final targets = darwinX64['targets'] as YamlList;
        expect(targets.length, equals(1));
        expect(targets, contains('darwin-x64'));
        expect(darwinX64['flags'], equals('--project-flag'));
      });

      test('non-overridden build-on targets are inherited', () async {
        _createWorkspaceWithCrossCompilationOverride(tempDir.path,
          workspace: '''
cross-compilation:
  all-targets: [darwin-x64, darwin-arm64, linux-x64]
  build-on:
    darwin-x64:
      targets: [darwin-x64]
    darwin-arm64:
      targets: [darwin-arm64]
    linux-x64:
      targets: [linux-x64]
''',
          project: '''
cross-compilation:
  build-on:
    darwin-arm64:
      targets: [darwin-arm64, darwin-x64]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final buildOn = crossComp['build-on'] as YamlMap;

        // darwin-arm64 is overridden
        final darwinArm64 = buildOn['darwin-arm64'] as YamlMap;
        final darwinArm64Targets = darwinArm64['targets'] as YamlList;
        expect(darwinArm64Targets.length, equals(2));

        // darwin-x64 and linux-x64 are inherited
        expect(buildOn.containsKey('darwin-x64'), isTrue);
        expect(buildOn.containsKey('linux-x64'), isTrue);
        final darwinX64 = buildOn['darwin-x64'] as YamlMap;
        final darwinX64Targets = darwinX64['targets'] as YamlList;
        expect(darwinX64Targets.length, equals(1));
      });

      test('project can add new build-on target', () async {
        _createWorkspaceWithCrossCompilationOverride(tempDir.path,
          workspace: '''
cross-compilation:
  all-targets: [darwin-x64, linux-x64, linux-arm64]
  build-on:
    darwin-x64:
      targets: [darwin-x64]
''',
          project: '''
cross-compilation:
  build-on:
    linux-x64:
      targets: [linux-x64, linux-arm64]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final buildOn = crossComp['build-on'] as YamlMap;

        // Both should exist
        expect(buildOn.containsKey('darwin-x64'), isTrue);
        expect(buildOn.containsKey('linux-x64'), isTrue);

        final linuxX64 = buildOn['linux-x64'] as YamlMap;
        final linuxTargets = linuxX64['targets'] as YamlList;
        expect(linuxTargets.length, equals(2));
      });
    });

    // =========================================================================
    // Project-specific fields
    // =========================================================================
    group('project-specific fields', () {
      test('project targets field', () async {
        _createWorkspaceWithCrossCompilationOverride(tempDir.path,
          workspace: '''
cross-compilation:
  all-targets: [darwin-x64, darwin-arm64, linux-x64]
''',
          project: '''
cross-compilation:
  targets: [darwin-x64, darwin-arm64]
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;

        expect(crossComp['targets'], isNotNull);
        final targets = crossComp['targets'] as YamlList;
        expect(targets.length, equals(2));
      });

      test('project output-dir field', () async {
        _createWorkspaceWithCrossCompilationOverride(tempDir.path,
          workspace: '''
cross-compilation:
  all-targets: [darwin-x64]
''',
          project: '''
cross-compilation:
  output-dir: build/\${target}/
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;

        expect(crossComp['output-dir'], contains('build/'));
      });

      test('project custom field preserved', () async {
        _createWorkspaceWithCrossCompilationOverride(tempDir.path,
          workspace: '''
cross-compilation:
  all-targets: [darwin-x64]
''',
          project: '''
cross-compilation:
  custom-project-field: custom-value
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;

        expect(crossComp['custom-project-field'], equals('custom-value'));
      });
    });

    // =========================================================================
    // Build-on target properties
    // =========================================================================
    group('build-on target properties', () {
      test('build-on target has targets list', () async {
        _createWorkspaceWithCrossCompilation(tempDir.path, '''
cross-compilation:
  all-targets: [darwin-x64, darwin-arm64]
  build-on:
    darwin-arm64:
      targets:
        - darwin-arm64
        - darwin-x64
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final buildOn = crossComp['build-on'] as YamlMap;
        final darwinArm64 = buildOn['darwin-arm64'] as YamlMap;
        final targets = darwinArm64['targets'] as YamlList;

        expect(targets.length, equals(2));
        expect(targets[0], equals('darwin-arm64'));
        expect(targets[1], equals('darwin-x64'));
      });

      test('build-on target with custom flags', () async {
        _createWorkspaceWithCrossCompilation(tempDir.path, '''
cross-compilation:
  all-targets: [darwin-x64]
  build-on:
    darwin-x64:
      targets: [darwin-x64]
      flags: --extra-cflags=-O3
      environment:
        CC: clang
        CXX: clang++
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final crossComp = project['cross-compilation'] as YamlMap;
        final buildOn = crossComp['build-on'] as YamlMap;
        final darwinX64 = buildOn['darwin-x64'] as YamlMap;

        expect(darwinX64['flags'], equals('--extra-cflags=-O3'));
        expect(darwinX64['environment'], isNotNull);
      });
    });

    // =========================================================================
    // No cross-compilation section
    // =========================================================================
    group('no cross-compilation', () {
      test('workspace without cross-compilation', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);

        // Should not have cross-compilation section or it should be empty/null
        final crossComp = project['cross-compilation'];
        if (crossComp != null) {
          expect((crossComp as YamlMap).isEmpty, isTrue);
        }
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
}

void _createWorkspaceWithCrossCompilation(String basePath, String crossComp) {
  _createDartPackage(basePath);
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
$crossComp
''');
}

void _createWorkspaceWithCrossCompilationOverride(
  String basePath, {
  required String workspace,
  required String project,
}) {
  _createDartPackage(basePath);
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
$workspace
''');
  File(path.join(basePath, 'tom_project.yaml')).writeAsStringSync(project);
}

YamlMap _loadMasterYaml(String basePath) {
  final masterFile = File(path.join(basePath, '.tom_metadata', 'tom_master.yaml'));
  return loadYaml(masterFile.readAsStringSync()) as YamlMap;
}

YamlMap _getFirstProject(YamlMap yaml) {
  final projects = yaml['projects'] as YamlMap;
  return projects.values.first as YamlMap;
}
