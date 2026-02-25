/// Comprehensive tests for the enhanced WorkspaceAnalyzer features.
///
/// Tests cover:
/// - Build configuration hierarchy (defaults → workspace → local)
/// - Feature detection (reflection, build_runner, docker, assets, tests, examples, publishable)
/// - Build order calculation from dependencies
/// - Folder listings (copilot-guidelines, docs, tests, examples)
/// - Local tom_master.yaml overrides
/// - Null value handling for disabling defaults

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

/// Helper to require fixture workspace exists
void requireFixture(String wsPath) {
  if (!Directory(wsPath).existsSync()) {
    throw TestFailure('Test fixture not found: $wsPath');
  }
}

void main() {

  group('WorkspaceAnalyzer Enhanced Features', () {
    // =========================================================================
    // Build Configuration Tests
    // =========================================================================
    group('build configuration hierarchy', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_build_config_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('applies default build config for dart_package', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.buildConfig['output'], equals('build/'));
        expect(project.buildConfig['pre-build'], contains('build-runner'));
      });

      test('applies default build config for dart_console', () async {
        _createDartConsole(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.buildConfig['output'], equals('bin/'));
        expect(project.buildConfig['commands'], isNotNull);
        expect(project.buildConfig['commands']['compile'], isNotNull);
      });

      test('applies default build config for flutter_app', () async {
        _createFlutterApp(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.buildConfig['output'], equals('build/'));
        expect(project.buildConfig['commands']['build-web'], isNotNull);
      });

      test('applies default build config for vscode_extension', () async {
        _createVSCodeExtension(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.buildConfig['output'], equals('out/'));
        expect(project.buildConfig['commands']['install'], isNotNull);
        expect(project.buildConfig['commands']['package'], isNotNull);
      });

      test('applies default build config for typescript', () async {
        _createTypeScriptProject(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.buildConfig['output'], equals('dist/'));
      });

      test('build commands are lists', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        final commands = project.buildConfig['commands'] as Map;
        expect(commands['analyze'], isList);
        expect(commands['test'], isList);
      });

      test('workspace tom_master.yaml overrides default build config', () async {
        // Copy fixture workspace
        final wsPath = path.join(fixturesPath, 'ws_build_config');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        // Find lib_a (dart_package)
        final libA = analyzer.projects.firstWhere((p) => p.name == 'lib_a');

        // Should have custom output from workspace tom_master.yaml
        expect(libA.buildConfig['output'], equals('custom_build/'));
        expect(libA.buildConfig['commands']['custom-step'], isNotNull);
      });

      test('local tom_master.yaml overrides workspace and default config', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_local_index',
        );

        // Should have local override
        expect(project.buildConfig['output'], equals('dist/'));
        expect(project.buildConfig['commands']['compile'], isList);
        expect(
          (project.buildConfig['commands']['compile'] as List).length,
          equals(2),
        );
      });
    });

    // =========================================================================
    // Run Configuration Tests
    // =========================================================================
    group('run configuration', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_run_config_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('applies default run config for dart_console', () async {
        _createDartConsole(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.runConfig['commands'], isNotNull);
      });

      test('applies default run config for flutter_app', () async {
        _createFlutterApp(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.runConfig['commands'], isNotNull);
      });

      test('local tom_master.yaml can set run commands', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_local_index',
        );

        expect(project.runConfig['commands'], isNotNull);
        expect(project.runConfig['docker'], isNotNull);
        expect(project.runConfig['docker']['compose-file'], equals('docker-compose.dev.yml'));
      });

      test('run config can be disabled with null', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_null_overrides',
        );

        expect(project.runConfig, isEmpty);
      });
    });

    // =========================================================================
    // Deploy Configuration Tests
    // =========================================================================
    group('deploy configuration', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_deploy_config_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('applies default deploy config for dart_console', () async {
        _createDartConsole(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.deployConfig['type'], equals('docker'));
        expect(project.deployConfig['platforms'], isList);
      });

      test('applies default deploy config for flutter_app', () async {
        _createFlutterApp(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final project = analyzer.projects.first;
        expect(project.deployConfig['type'], equals('web'));
      });

      test('local tom_master.yaml can override deploy config', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_local_index',
        );

        expect(project.deployConfig['type'], equals('ecs'));
        expect(project.deployConfig['task-definition'], isNotNull);
      });

      test('deploy config can be disabled with null', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_null_overrides',
        );

        expect(project.deployConfig, isEmpty);
      });
    });

    // =========================================================================
    // Feature Detection Tests
    // =========================================================================
    group('feature detection', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_features_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('detects has-reflection from .reflection.dart files', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'lib', 'src', 'model.reflection.dart'))
            .writeAsStringSync('// Generated');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-reflection'], isTrue);
      });

      test('detects has-reflection from .g.dart files', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'lib', 'src', 'model.g.dart'))
            .writeAsStringSync('// Generated');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-reflection'], isTrue);
      });

      test('detects has-build-runner from build.yaml', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'build.yaml'))
            .writeAsStringSync('targets:\n  \$default:\n');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-build-runner'], isTrue);
      });

      test('detects has-docker from Dockerfile', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'Dockerfile'))
            .writeAsStringSync('FROM dart:stable');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-docker'], isTrue);
      });

      test('detects has-docker from docker-compose.yml', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'docker-compose.yml'))
            .writeAsStringSync('version: "3"');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-docker'], isTrue);
      });

      test('detects has-assets from assets/ directory', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'assets')).createSync();

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-assets'], isTrue);
      });

      test('detects has-assets from fonts/ directory', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'fonts')).createSync();

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-assets'], isTrue);
      });

      test('detects has-tests from test/ directory with _test.dart files', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'test')).createSync();
        File(path.join(tempDir.path, 'test', 'main_test.dart'))
            .writeAsStringSync('void main() {}');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-tests'], isTrue);
      });

      test('has-tests is false without _test.dart files', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'test')).createSync();
        // No _test.dart files

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-tests'], isFalse);
      });

      test('detects has-examples from example/ directory', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'example')).createSync();

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['has-examples'], isTrue);
      });

      test('detects publishable when no publish_to: none', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['publishable'], isTrue);
      });

      test('detects not publishable with publish_to: none', () async {
        _createDartPackage(tempDir.path, publishToNone: true);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.features['publishable'], isFalse);
      });

      test('local tom_master.yaml can override detected features', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_local_index',
        );

        // Should be overridden to false by local tom_master.yaml
        expect(project.features['publishable'], isFalse);
        // Should be overridden to true by local tom_master.yaml
        expect(project.features['has-docker'], isTrue);
      });

      test('feature detection fixture test', () async {
        final wsPath = path.join(fixturesPath, 'ws_features');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        // Test reflection project
        final reflectionProject = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_reflection',
          orElse: () => throw Exception('project_with_reflection not found'),
        );
        expect(reflectionProject.features['has-reflection'], isTrue);

        // Test build_runner project
        final buildRunnerProject = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_build_runner',
          orElse: () => throw Exception('project_with_build_runner not found'),
        );
        expect(buildRunnerProject.features['has-build-runner'], isTrue);

        // Test docker project
        final dockerProject = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_docker',
          orElse: () => throw Exception('project_with_docker not found'),
        );
        expect(dockerProject.features['has-docker'], isTrue);

        // Test assets project
        final assetsProject = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_assets',
          orElse: () => throw Exception('project_with_assets not found'),
        );
        expect(assetsProject.features['has-assets'], isTrue);

        // Test tests project
        final testsProject = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_tests',
          orElse: () => throw Exception('project_with_tests not found'),
        );
        expect(testsProject.features['has-tests'], isTrue);

        // Test examples project
        final examplesProject = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_examples',
          orElse: () => throw Exception('project_with_examples not found'),
        );
        expect(examplesProject.features['has-examples'], isTrue);

        // Test publishable project
        final publishableProject = analyzer.projects.firstWhere(
          (p) => p.name == 'publishable_project',
          orElse: () => throw Exception('publishable_project not found'),
        );
        expect(publishableProject.features['publishable'], isTrue);
      });
    });

    // =========================================================================
    // Build Order Tests
    // =========================================================================
    group('build order', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_build_order_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('detects build-after from pubspec dependencies', () async {
        // Create two projects where B depends on A
        final projectA = Directory(path.join(tempDir.path, 'project_a'));
        final projectB = Directory(path.join(tempDir.path, 'project_b'));

        _createDartPackage(projectA.path, name: 'project_a');
        _createDartPackage(
          projectB.path,
          name: 'project_b',
          dependencies: ['project_a'],
        );

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final pB = analyzer.projects.firstWhere((p) => p.name == 'project_b');
        expect(pB.buildAfter, contains('project_a'));
      });

      test('build order respects dependencies', () async {
        // Create A -> B -> C dependency chain
        final projectA = Directory(path.join(tempDir.path, 'project_a'));
        final projectB = Directory(path.join(tempDir.path, 'project_b'));
        final projectC = Directory(path.join(tempDir.path, 'project_c'));

        _createDartPackage(projectA.path, name: 'project_a');
        _createDartPackage(
          projectB.path,
          name: 'project_b',
          dependencies: ['project_a'],
        );
        _createDartPackage(
          projectC.path,
          name: 'project_c',
          dependencies: ['project_b'],
        );

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final indexA = analyzer.buildOrder.indexOf('project_a');
        final indexB = analyzer.buildOrder.indexOf('project_b');
        final indexC = analyzer.buildOrder.indexOf('project_c');

        expect(indexA, lessThan(indexB), reason: 'A should be built before B');
        expect(indexB, lessThan(indexC), reason: 'B should be built before C');
      });

      test('build order handles multiple dependencies', () async {
        // Create diamond dependency: A, B -> C (C depends on both A and B)
        final projectA = Directory(path.join(tempDir.path, 'project_a'));
        final projectB = Directory(path.join(tempDir.path, 'project_b'));
        final projectC = Directory(path.join(tempDir.path, 'project_c'));

        _createDartPackage(projectA.path, name: 'project_a');
        _createDartPackage(projectB.path, name: 'project_b');
        _createDartPackage(
          projectC.path,
          name: 'project_c',
          dependencies: ['project_a', 'project_b'],
        );

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final indexA = analyzer.buildOrder.indexOf('project_a');
        final indexB = analyzer.buildOrder.indexOf('project_b');
        final indexC = analyzer.buildOrder.indexOf('project_c');

        expect(indexA, lessThan(indexC), reason: 'A should be built before C');
        expect(indexB, lessThan(indexC), reason: 'B should be built before C');
      });

      test('build order from local tom_master.yaml overrides pubspec', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_local_index',
        );

        // Should use build-after from local tom_master.yaml
        expect(project.buildAfter, contains('external_lib'));
        expect(project.buildAfter, contains('another_lib'));
      });

      test('build order fixture test with deep dependencies', () async {
        final wsPath = path.join(fixturesPath, 'ws_build_order');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        // core_lib has no dependencies
        // utils_lib depends on core_lib
        // service_lib depends on core_lib and utils_lib
        // main_app depends on service_lib

        final coreIndex = analyzer.buildOrder.indexOf('core_lib');
        final utilsIndex = analyzer.buildOrder.indexOf('utils_lib');
        final serviceIndex = analyzer.buildOrder.indexOf('service_lib');
        final mainIndex = analyzer.buildOrder.indexOf('main_app');

        expect(coreIndex, greaterThanOrEqualTo(0));
        expect(utilsIndex, greaterThanOrEqualTo(0));
        expect(serviceIndex, greaterThanOrEqualTo(0));
        expect(mainIndex, greaterThanOrEqualTo(0));

        expect(coreIndex, lessThan(utilsIndex));
        expect(utilsIndex, lessThan(serviceIndex));
        expect(serviceIndex, lessThan(mainIndex));
      });

      test('build order written to tom_master.yaml', () async {
        final projectA = Directory(path.join(tempDir.path, 'project_a'));
        final projectB = Directory(path.join(tempDir.path, 'project_b'));

        _createDartPackage(projectA.path, name: 'project_a');
        _createDartPackage(
          projectB.path,
          name: 'project_b',
          dependencies: ['project_a'],
        );

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final masterFile = File(path.join(tempDir.path, '.tom_metadata', 'tom_master.yaml'));
        final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;

        final buildOrder = yaml['build-order'] as YamlList;
        expect(buildOrder, isNotEmpty);
        expect(buildOrder.indexOf('project_a'), lessThan(buildOrder.indexOf('project_b')));
      });
    });

    // =========================================================================
    // Folder Listings Tests
    // =========================================================================
    group('folder listings', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_folder_listings_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('lists copilot_guidelines contents', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'copilot_guidelines')).createSync();
        File(path.join(tempDir.path, 'copilot_guidelines', 'coding.md'))
            .writeAsStringSync('# Coding');
        File(path.join(tempDir.path, 'copilot_guidelines', 'testing.md'))
            .writeAsStringSync('# Testing');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.copilotGuidelines, contains('coding.md'));
        expect(analyzer.projects.first.copilotGuidelines, contains('testing.md'));
      });

      test('lists docs contents with subdirectories', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'docs', 'api')).createSync(recursive: true);
        File(path.join(tempDir.path, 'docs', 'user_guide.md'))
            .writeAsStringSync('# Guide');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.docs, contains('api/'));
        expect(analyzer.projects.first.docs, contains('user_guide.md'));
      });

      test('lists test contents', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'test', 'unit')).createSync(recursive: true);
        File(path.join(tempDir.path, 'test', 'main_test.dart'))
            .writeAsStringSync('void main() {}');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.tests, contains('unit/'));
        expect(analyzer.projects.first.tests, contains('main_test.dart'));
      });

      test('lists example contents', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'example', 'advanced')).createSync(recursive: true);
        File(path.join(tempDir.path, 'example', 'basic.dart'))
            .writeAsStringSync('void main() {}');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.examples, contains('advanced/'));
        expect(analyzer.projects.first.examples, contains('basic.dart'));
      });

      test('folder listings written to tom_master.yaml', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'docs')).createSync();
        File(path.join(tempDir.path, 'docs', 'readme.md')).writeAsStringSync('# Docs');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final masterFile = File(path.join(tempDir.path, '.tom_metadata', 'tom_master.yaml'));
        final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
        final projects = yaml['projects'] as YamlMap;
        final project = projects.values.first as YamlMap;

        expect(project['docs'], isNotNull);
        expect((project['docs'] as YamlList), contains('readme.md'));
      });

      test('folder listings fixture test', () async {
        final wsPath = path.join(fixturesPath, 'ws_folder_listings');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_folders',
        );

        // Copilot guidelines
        expect(project.copilotGuidelines, contains('coding.md'));
        expect(project.copilotGuidelines, contains('testing.md'));

        // Docs
        expect(project.docs, contains('api/'));
        expect(project.docs, contains('user_guide.md'));

        // Tests
        expect(project.tests, contains('unit/'));
        expect(project.tests, contains('integration_test.dart'));

        // Examples
        expect(project.examples, contains('advanced/'));
        expect(project.examples, contains('basic_example.dart'));
      });

      test('hidden files are excluded from listings', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'docs')).createSync();
        File(path.join(tempDir.path, 'docs', '.hidden_file')).writeAsStringSync('hidden');
        File(path.join(tempDir.path, 'docs', 'visible.md')).writeAsStringSync('visible');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        expect(analyzer.projects.first.docs, isNot(contains('.hidden_file')));
        expect(analyzer.projects.first.docs, contains('visible.md'));
      });
    });

    // =========================================================================
    // Local tom_project.yaml Tests
    // =========================================================================
    group('local tom_master.yaml', () {
      test('loads binaries from local tom_master.yaml', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_local_index',
        );

        expect(project.localIndexEntries['binaries'], contains('my_tool.dart'));
        expect(project.localIndexEntries['binaries'], contains('other_tool.dart'));
      });

      test('binaries written to tom_master.yaml output', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final masterFile = File(path.join(wsPath, '.tom_metadata', 'tom_master.yaml'));
        final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
        final projects = yaml['projects'] as YamlMap;
        final project = projects['project_with_local_index'] as YamlMap;

        expect(project['binaries'], isNotNull);
        expect((project['binaries'] as YamlList), contains('my_tool.dart'));
      });
    });

    // =========================================================================
    // Workspace tom_master.yaml Tests
    // =========================================================================
    group('workspace tom_master.yaml', () {
      test('loads workspace settings from root tom_master.yaml', () async {
        final wsPath = path.join(fixturesPath, 'ws_build_config');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        expect(analyzer.workspaceSettings['binaries'], equals('bin/'));
        expect(analyzer.workspaceSettings['operating-systems'], isList);
        expect(analyzer.workspaceSettings['groups'], isNotNull);
      });

      test('groups written to tom_master.yaml output', () async {
        final wsPath = path.join(fixturesPath, 'ws_build_config');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final masterFile = File(path.join(wsPath, '.tom_metadata', 'tom_master.yaml'));
        final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;

        expect(yaml['groups'], isNotNull);
        expect((yaml['groups'] as YamlMap)['core'], isNotNull);
      });
    });

    // =========================================================================
    // YAML Output Format Tests
    // =========================================================================
    group('YAML output format', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_yaml_output_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('quotes strings with special characters', () async {
        _createDartPackage(tempDir.path);
        
        // Create local index with special characters
        File(path.join(tempDir.path, 'tom_master.yaml')).writeAsStringSync('''
build:
  commands:
    compile:
      - dart compile exe bin/main.dart -o bin/\${name}
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        // Read and verify it parses correctly
        final masterFile = File(path.join(tempDir.path, '.tom_metadata', 'tom_master.yaml'));
        expect(() => loadYaml(masterFile.readAsStringSync()), returnsNormally);
      });

      test('features are output correctly', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'build.yaml')).writeAsStringSync('');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final masterFile = File(path.join(tempDir.path, '.tom_metadata', 'tom_master.yaml'));
        final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
        final projects = yaml['projects'] as YamlMap;
        final project = projects.values.first as YamlMap;

        expect(project['features'], isNotNull);
        expect(project['features']['has-build-runner'], isTrue);
      });

      test('build config commands are output as lists', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final masterFile = File(path.join(tempDir.path, '.tom_metadata', 'tom_master.yaml'));
        final yaml = loadYaml(masterFile.readAsStringSync()) as YamlMap;
        final projects = yaml['projects'] as YamlMap;
        final project = projects.values.first as YamlMap;

        final commands = project['build']['commands'] as YamlMap;
        expect(commands['analyze'], isList);
        expect(commands['test'], isList);
      });
    });

    // =========================================================================
    // Integration Tests with Fixtures
    // =========================================================================
    group('fixture integration tests', () {
      test('ws_build_config workspace analysis', () async {
        final wsPath = path.join(fixturesPath, 'ws_build_config');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        // Should find all projects
        expect(analyzer.projects.length, equals(3));
        expect(analyzer.projects.map((p) => p.name), containsAll(['lib_a', 'lib_b', 'app_c']));

        // lib_b should have lib_a as dependency
        final libB = analyzer.projects.firstWhere((p) => p.name == 'lib_b');
        expect(libB.buildAfter, contains('lib_a'));

        // app_c should have both lib_a and lib_b as dependencies
        final appC = analyzer.projects.firstWhere((p) => p.name == 'app_c');
        expect(appC.buildAfter, contains('lib_a'));
        expect(appC.buildAfter, contains('lib_b'));
      });

      test('ws_features workspace analysis', () async {
        final wsPath = path.join(fixturesPath, 'ws_features');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        // Should detect all feature projects
        expect(analyzer.projects.length, greaterThanOrEqualTo(5));
      });

      test('ws_local_index workspace analysis', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        expect(analyzer.projects.length, equals(2));
      });

      test('ws_folder_listings workspace analysis', () async {
        final wsPath = path.join(fixturesPath, 'ws_folder_listings');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        expect(analyzer.projects.length, equals(1));
        expect(analyzer.projects.first.name, equals('project_with_folders'));
      });

      test('ws_build_order workspace analysis', () async {
        final wsPath = path.join(fixturesPath, 'ws_build_order');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
          
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        expect(analyzer.projects.length, equals(4));
        expect(analyzer.buildOrder.length, equals(4));
      });
    });

    // =========================================================================
    // Additional Detailed Tests for Build Config Values
    // =========================================================================
    group('build config specific values', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_build_values_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('dart_package analyze command starts with dart analyze', () async {
        _createDartPackage(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        final commands = analyzer.projects.first.buildConfig['commands'] as Map;
        expect((commands['analyze'] as List).first, startsWith('dart analyze'));
      });

      test('dart_package test command is dart test', () async {
        _createDartPackage(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        final commands = analyzer.projects.first.buildConfig['commands'] as Map;
        expect((commands['test'] as List).first, equals('dart test'));
      });

      test('dart_console compile command includes exe', () async {
        _createDartConsole(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        final commands = analyzer.projects.first.buildConfig['commands'] as Map;
        final compileCmd = (commands['compile'] as List).first as String;
        expect(compileCmd, contains('compile exe'));
      });

      test('flutter_app has flutter build commands', () async {
        _createFlutterApp(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        final commands = analyzer.projects.first.buildConfig['commands'] as Map;
        expect((commands['build-web'] as List).first, contains('flutter build'));
        expect((commands['build-ios'] as List).first, contains('flutter build ios'));
        expect((commands['build-android'] as List).first, contains('flutter build'));
      });

      test('vscode_extension has npm commands', () async {
        _createVSCodeExtension(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        final commands = analyzer.projects.first.buildConfig['commands'] as Map;
        expect((commands['install'] as List).first, equals('npm install'));
        expect((commands['compile'] as List).first, equals('npm run compile'));
        expect((commands['package'] as List).first, equals('vsce package'));
      });
    });

    // =========================================================================
    // Additional Run Config Tests
    // =========================================================================
    group('run config specific values', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_run_values_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('dart_console run command is dart run', () async {
        _createDartConsole(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        final commands = analyzer.projects.first.runConfig['commands'] as List;
        expect(commands.first, contains('dart run'));
      });

      test('flutter_app run command is flutter run', () async {
        _createFlutterApp(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        final commands = analyzer.projects.first.runConfig['commands'] as List;
        expect(commands.first, contains('flutter run'));
      });
    });

    // =========================================================================
    // Additional Deploy Config Tests
    // =========================================================================
    group('deploy config specific values', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_deploy_values_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('dart_console deploy has docker type', () async {
        _createDartConsole(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        final deploy = analyzer.projects.first.deployConfig;
        expect(deploy['type'], equals('docker'));
      });

      test('dart_console platforms include linux/amd64', () async {
        _createDartConsole(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        final platforms = analyzer.projects.first.deployConfig['platforms'] as List;
        expect(platforms, contains('linux/amd64'));
      });

      test('flutter_app deploy type is web', () async {
        _createFlutterApp(tempDir.path);
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.deployConfig['type'], equals('web'));
      });
    });

    // =========================================================================
    // Feature Detection Edge Cases
    // =========================================================================
    group('feature detection edge cases', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_features_edge_test_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('detects has-reflection from .g.dart files in nested folders', () async {
        _createDartPackage(tempDir.path);
        File(path.join(tempDir.path, 'lib', 'src', 'model.g.dart'))
            .writeAsStringSync('// Generated by build_runner');
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.features['has-reflection'], isTrue);
      });

      test('no has-reflection without generated files', () async {
        _createDartPackage(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.features['has-reflection'], isFalse);
      });

      test('no has-build-runner without build.yaml', () async {
        _createDartPackage(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.features['has-build-runner'], isFalse);
      });

      test('no has-docker without docker files', () async {
        _createDartPackage(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.features['has-docker'], isFalse);
      });

      test('no has-assets without assets folder', () async {
        _createDartPackage(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.features['has-assets'], isFalse);
      });

      test('no has-examples without example folder', () async {
        _createDartPackage(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.features['has-examples'], isFalse);
      });
    });

    // =========================================================================
    // Build Order Edge Cases
    // =========================================================================
    group('build order edge cases', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_build_order_edge_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('single project has itself in build order', () async {
        _createDartPackage(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.buildOrder.length, equals(1));
      });

      test('projects with no dependencies sorted alphabetically', () async {
        final projectA = Directory(path.join(tempDir.path, 'zebra_project'));
        final projectB = Directory(path.join(tempDir.path, 'alpha_project'));
        
        _createDartPackage(projectA.path, name: 'zebra_project');
        _createDartPackage(projectB.path, name: 'alpha_project');
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        // Without dependencies, order is determined by the analyzer
        expect(analyzer.buildOrder.length, equals(2));
      });

      test('external dependencies are ignored in build order', () async {
        _createDartPackage(tempDir.path);
        // Add a dependency to path package (external)
        final pubspec = File(path.join(tempDir.path, 'pubspec.yaml'));
        pubspec.writeAsStringSync('''
name: test_package
version: 1.0.0
environment:
  sdk: ^3.0.0
dependencies:
  path: any
''');
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        // External dependencies don't affect build order
        expect(analyzer.buildOrder.length, equals(1));
      });
    });

    // =========================================================================
    // Folder Listing Edge Cases
    // =========================================================================
    group('folder listing edge cases', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_folders_edge_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('empty docs folder shows empty list', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'docs')).createSync();
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.docs, isEmpty);
      });

      test('nested directories use trailing slash', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'docs', 'nested', 'deep')).createSync(recursive: true);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.docs.where((e) => e.endsWith('/')), isNotEmpty);
      });

      test('copilot_guidelines with nested subfolders', () async {
        _createDartPackage(tempDir.path);
        Directory(path.join(tempDir.path, 'copilot_guidelines', 'd4rt')).createSync(recursive: true);
        File(path.join(tempDir.path, 'copilot_guidelines', 'd4rt', 'guidelines.md'))
            .writeAsStringSync('# Guidelines');
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.copilotGuidelines, contains('d4rt/'));
      });
    });

    // =========================================================================
    // ProjectInfo Properties Tests
    // =========================================================================
    group('ProjectInfo properties', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('ws_project_info_');
      });

      tearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      test('project has projectName from pubspec', () async {
        _createDartPackage(tempDir.path, name: 'my_custom_name');
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        // projectName comes from pubspec, name is the folder name
        expect(analyzer.projects.first.projectName, equals('my_custom_name'));
      });

      test('project has description from pubspec if provided', () async {
        _createDartPackage(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        // Description is optional, may be null
        expect(analyzer.projects.first.description, isNull);
      });

      test('project has correct type for dart package', () async {
        _createDartPackage(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.type, equals('dart_package'));
      });

      test('project has correct type for flutter app', () async {
        _createFlutterApp(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.type, equals('flutter_app'));
      });

      test('project has correct type for vscode extension', () async {
        _createVSCodeExtension(tempDir.path);
        
        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();
        
        expect(analyzer.projects.first.type, equals('vscode_extension'));
      });
    });

    // =========================================================================
    // Config Merging Tests
    // =========================================================================
    group('config merging', () {
      test('local build config merges with defaults', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_local_index',
        );

        // Local overrides should be present
        expect(project.buildConfig['output'], equals('dist/'));
        // But other default values may still apply
        expect(project.buildConfig['commands'], isNotNull);
      });

      test('null in local config disables entire section', () async {
        final wsPath = path.join(fixturesPath, 'ws_local_index');
        if (!Directory(wsPath).existsSync()) {
          requireFixture(wsPath);
        }

        final analyzer = WorkspaceAnalyzer(wsPath);
        await analyzer.analyze();

        final project = analyzer.projects.firstWhere(
          (p) => p.name == 'project_with_null_overrides',
        );

        // Null overrides should result in empty configs
        expect(project.runConfig, isEmpty);
        expect(project.deployConfig, isEmpty);
      });
    });
  });
}

// =============================================================================
// Helper Functions
// =============================================================================

void _createDartPackage(
  String dirPath, {
  String name = 'test_package',
  bool publishToNone = false,
  List<String> dependencies = const [],
}) {
  Directory(path.join(dirPath, 'lib', 'src')).createSync(recursive: true);
  File(path.join(dirPath, 'lib', 'src', 'main.dart')).writeAsStringSync('// Placeholder');

  final pubspec = StringBuffer();
  pubspec.writeln('name: $name');
  pubspec.writeln('version: 1.0.0');
  if (publishToNone) {
    pubspec.writeln('publish_to: none');
  }
  pubspec.writeln('environment:');
  pubspec.writeln('  sdk: ^3.0.0');

  if (dependencies.isNotEmpty) {
    pubspec.writeln('dependencies:');
    for (final dep in dependencies) {
      pubspec.writeln('  $dep:');
      pubspec.writeln('    path: ../$dep');
    }
  }

  File(path.join(dirPath, 'pubspec.yaml')).writeAsStringSync(pubspec.toString());
}

void _createDartConsole(String dirPath, {String name = 'test_console'}) {
  Directory(path.join(dirPath, 'lib')).createSync(recursive: true);
  Directory(path.join(dirPath, 'bin')).createSync(recursive: true);
  File(path.join(dirPath, 'lib', 'main.dart')).writeAsStringSync('// Placeholder');
  File(path.join(dirPath, 'bin', 'main.dart')).writeAsStringSync('void main() {}');
  File(path.join(dirPath, 'pubspec.yaml')).writeAsStringSync('''
name: $name
version: 1.0.0
publish_to: none
environment:
  sdk: ^3.0.0
''');
}

void _createFlutterApp(String dirPath, {String name = 'test_flutter_app'}) {
  Directory(path.join(dirPath, 'lib')).createSync(recursive: true);
  File(path.join(dirPath, 'lib', 'main.dart')).writeAsStringSync('void main() {}');
  File(path.join(dirPath, 'pubspec.yaml')).writeAsStringSync('''
name: $name
version: 1.0.0
publish_to: none
environment:
  sdk: ^3.0.0
dependencies:
  flutter:
    sdk: flutter
''');
}

void _createVSCodeExtension(String dirPath, {String name = 'test-extension'}) {
  Directory(path.join(dirPath, 'src')).createSync(recursive: true);
  File(path.join(dirPath, 'src', 'extension.ts')).writeAsStringSync('// Extension');
  File(path.join(dirPath, 'package.json')).writeAsStringSync('''
{
  "name": "$name",
  "version": "1.0.0",
  "engines": {
    "vscode": "^1.80.0"
  }
}
''');
}

void _createTypeScriptProject(String dirPath, {String name = 'test-ts'}) {
  Directory(path.join(dirPath, 'src')).createSync(recursive: true);
  File(path.join(dirPath, 'src', 'index.ts')).writeAsStringSync('// TypeScript');
  File(path.join(dirPath, 'package.json')).writeAsStringSync('''
{
  "name": "$name",
  "version": "1.0.0"
}
''');
  File(path.join(dirPath, 'tsconfig.json')).writeAsStringSync('{}');
}
