import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/src/tom/file_object_model/file_object_model.dart';

void main() {
  final fixtureDir =
      'fixture/project_structure_file_samples';
  final resultDir = '$fixtureDir/results';

  setUpAll(() {
    // Ensure result directory exists
    Directory(resultDir).createSync(recursive: true);
  });

  group('File Structure Model Serialization', () {
    test('tom_workspace.yaml round-trip', () {
      final inputPath = '$fixtureDir/tom_workspace.yaml';

      // Load and parse
      final yaml = loadYamlFile(inputPath);
      final workspace = TomWorkspace.fromYaml(yaml);

      // Serialize back
      final resultYaml = workspace.toYaml();
      final resultString = toYamlString(resultYaml);

      // Write result
      final resultPath = '$resultDir/tom_workspace.result.yaml';
      File(resultPath).writeAsStringSync(resultString);

      // Compare structure
      expect(resultYaml['name'], equals(yaml['name']));
      expect(resultYaml['binaries'], equals(yaml['binaries']));

      // Verify key structures exist
      expect(workspace.workspaceModes, isNotNull);
      expect(workspace.projectTypes, isNotEmpty);
      expect(workspace.actions, isNotEmpty);
      expect(workspace.groups, isNotEmpty);
      expect(workspace.modeDefinitions, isNotEmpty);

      print('Workspace serialization written to: $resultPath');
    });

    test('tom_project.yaml round-trip', () {
      final inputPath = '$fixtureDir/tom_project.yaml';

      // Load and parse
      final yaml = loadYamlFile(inputPath);
      final project = TomProject.fromYaml('test_project', yaml);

      // Serialize back
      final resultYaml = project.toYaml();
      final resultString = toYamlString(resultYaml);

      // Write result
      final resultPath = '$resultDir/tom_project.result.yaml';
      File(resultPath).writeAsStringSync(resultString);

      // Verify key structures
      expect(project.buildAfter, isNotEmpty);
      expect(project.features, isNotNull);
      expect(project.crossCompilation, isNotNull);
      expect(project.executables, isNotEmpty);
      expect(project.metadataFiles, isNotEmpty);

      print('Project serialization written to: $resultPath');
    });

    test('tom_master.yaml round-trip', () {
      final inputPath = '$fixtureDir/tom_master.yaml';

      // Load and parse
      final yaml = loadYamlFile(inputPath);
      final master = TomMaster.fromYaml(yaml);

      // Serialize back
      final resultYaml = master.toYaml();
      final resultString = toYamlString(resultYaml);

      // Write result
      final resultPath = '$resultDir/tom_master.result.yaml';
      File(resultPath).writeAsStringSync(resultString);

      // Verify key structures
      expect(master.scanTimestamp, isNotNull);
      expect(master.projects, isNotEmpty);
      expect(master.buildOrder, isNotEmpty);
      expect(master.actionOrder, isNotEmpty);

      // Workspace parts
      expect(master.workspaceModes, isNotNull);
      expect(master.projectTypes, isNotEmpty);
      expect(master.actions, isNotEmpty);
      expect(master.groups, isNotEmpty);

      print('Master serialization written to: $resultPath');
    });

    test('detailed tom_workspace.yaml parsing', () {
      final inputPath = '$fixtureDir/tom_workspace.yaml';
      final yaml = loadYamlFile(inputPath);
      final workspace = TomWorkspace.fromYaml(yaml);

      // Test workspace modes structure
      expect(workspace.workspaceModes!.modeTypes, contains('environment'));
      expect(workspace.workspaceModes!.modeTypes, contains('execution'));
      expect(workspace.workspaceModes!.supported.length, greaterThan(0));

      // Test mode type configs
      final envModes = workspace.workspaceModes!.modeTypeConfigs['environment'];
      expect(envModes, isNotNull);
      expect(envModes!.defaultMode, equals('local'));

      // Test project types (uses hyphens not underscores)
      expect(workspace.projectTypes.containsKey('dart-package'), isTrue);
      expect(workspace.projectTypes.containsKey('dart-console'), isTrue);

      // Test actions
      expect(workspace.actions.containsKey('build'), isTrue);
      expect(workspace.actions.containsKey('deploy'), isTrue);
      final deployAction = workspace.actions['deploy']!;
      expect(deployAction.skipTypes, contains('dart_package'));

      // Test groups
      expect(workspace.groups.containsKey('uam'), isTrue);
      final uamGroup = workspace.groups['uam']!;
      expect(uamGroup.projects, contains('tom_uam_server'));

      // Test mode definitions
      expect(workspace.modeDefinitions.containsKey('environment'), isTrue);
      final envDefs = workspace.modeDefinitions['environment']!;
      expect(envDefs.definitions.containsKey('local'), isTrue);

      // Test pipelines
      expect(workspace.pipelines.containsKey('ci'), isTrue);

      // Test project-info
      expect(workspace.projectInfo.containsKey('tom_build'), isTrue);

      // Test deps
      expect(workspace.deps, isNotEmpty);

      // Test version-settings
      expect(workspace.versionSettings, isNotNull);
      expect(workspace.versionSettings!.prereleaseTag, equals('dev'));
    });

    test('detailed tom_project.yaml parsing', () {
      final inputPath = '$fixtureDir/tom_project.yaml';
      final yaml = loadYamlFile(inputPath);
      final project = TomProject.fromYaml('tom_example', yaml);

      // Test build-after
      expect(project.buildAfter, contains('tom_uam_shared'));
      expect(project.buildAfter, contains('tom_core_kernel'));

      // Test action-order
      expect(project.actionOrder.containsKey('deploy-after'), isTrue);
      expect(project.actionOrder['deploy-after'], contains('tom_uam_shared'));

      // Test features
      expect(project.features!['publishable'], isFalse);
      expect(project.features!['has-docker'], isTrue);

      // Test cross-compilation
      expect(project.crossCompilation, isNotNull);
      expect(project.crossCompilation!.allTargets, contains('linux-x64'));

      // Test executables
      expect(project.executables.length, greaterThan(0));
      final exe = project.executables.first;
      expect(exe.source, equals('bin/server.dart'));

      // Test action-mode-definitions
      expect(project.actionModeDefinitions, isNotNull);

      // Test mode definitions (execution and deployment, not build/environment)
      expect(project.modeDefinitions.containsKey('execution'), isTrue);
      expect(project.modeDefinitions.containsKey('deployment'), isTrue);

      // Test metadata files
      expect(project.metadataFiles.containsKey('pubspec-yaml'), isTrue);

      // Test actions override
      expect(project.actions.containsKey('build'), isTrue);
    });

    test('detailed tom_master.yaml parsing', () {
      final inputPath = '$fixtureDir/tom_master.yaml';
      final yaml = loadYamlFile(inputPath);
      final master = TomMaster.fromYaml(yaml);

      // Test scan-timestamp (actual value from fixture)
      expect(master.scanTimestamp, equals('2026-01-13T17:00:00Z'));

      // Test workspace-level fields
      expect(master.name, equals('tom'));
      expect(master.binaries, equals('bin/'));
      expect(master.operatingSystems, contains('linux'));

      // Test build-order
      expect(master.buildOrder, isNotEmpty);
      expect(master.buildOrder.first, equals('tom_core_kernel'));

      // Test action-order
      expect(master.actionOrder.containsKey('build'), isTrue);
      expect(master.actionOrder['build']!.first, equals('tom_core_kernel'));

      // Test projects
      expect(master.projects.containsKey('tom_core_kernel'), isTrue);
      expect(master.projects.containsKey('tom_uam_server'), isTrue);

      final tomCoreKernel = master.projects['tom_core_kernel']!;
      expect(tomCoreKernel.type, equals('dart-package'));
      expect(tomCoreKernel.features, isNotNull);
      expect(tomCoreKernel.features!['publishable'], isTrue);

      // Test metadata files in project
      expect(tomCoreKernel.metadataFiles.containsKey('pubspec-yaml'), isTrue);

      // Test tom_uam_server project
      final tomUamServer = master.projects['tom_uam_server']!;
      expect(tomUamServer.type, equals('dart-console'));
      expect(tomUamServer.executables, isNotEmpty);
      expect(tomUamServer.features, isNotNull);
      expect(tomUamServer.features!['has-docker'], isTrue);
    });
  });
}
