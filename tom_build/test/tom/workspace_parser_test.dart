import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/src/tom/file_object_model/file_object_model.dart';
import 'package:tom_build/src/tom/file_object_model/workspace_parser.dart';

void main() {
  final fixtureDir = 'fixture/workspaces/basic_test';

  group('WorkspaceParser', () {
    late TomMaster master;

    setUpAll(() {
      // Ensure fixture exists
      expect(Directory(fixtureDir).existsSync(), isTrue,
          reason: 'Fixture directory should exist');

      // Parse workspace
      final parser = WorkspaceParser(fixtureDir);
      master = parser.parse();
    });

    test('parses workspace name from tom_workspace.yaml', () {
      expect(master.name, equals('basic_test'));
    });

    test('discovers all projects', () {
      expect(master.projects.keys, containsAll([
        'core_lib',
        'utils_lib',
        'my_cli',
        'my_server',
      ]));
    });

    group('Project types', () {
      test('core_lib is dart_package', () {
        expect(master.projects['core_lib']?.type, equals('dart_package'));
      });

      test('utils_lib is dart_package', () {
        expect(master.projects['utils_lib']?.type, equals('dart_package'));
      });

      test('my_cli is dart_cli', () {
        expect(master.projects['my_cli']?.type, equals('dart_cli'));
      });

      test('my_server is dart_server', () {
        expect(master.projects['my_server']?.type, equals('dart_server'));
      });
    });

    group('core_lib (dart_package with parts)', () {
      late TomProject project;

      setUpAll(() {
        project = master.projects['core_lib']!;
      });

      test('has parts', () {
        expect(project.parts.keys, containsAll(['data', 'models']));
      });

      test('data part has modules', () {
        final dataPart = project.parts['data']!;
        expect(dataPart.modules.keys, containsAll(['json_utils', 'serialization']));
      });

      test('models part has modules', () {
        final modelsPart = project.parts['models']!;
        expect(modelsPart.modules.keys, containsAll(['user', 'config']));
      });

      test('has tests', () {
        expect(project.tests, isNotNull);
        expect(project.tests, isNotEmpty);
        // Should find test files in test/ folder
        expect(project.tests!.any((t) => t.contains('user_test.dart')), isTrue);
        expect(project.tests!.any((t) => t.contains('json_utils_test.dart')), isTrue);
      });

      test('has examples', () {
        expect(project.examples, isNotNull);
        expect(project.examples, isNotEmpty);
        expect(project.examples!.any((e) => e.contains('basic_usage.dart')), isTrue);
      });

      test('has docs', () {
        expect(project.docs, isNotNull);
        expect(project.docs, isNotEmpty);
        expect(project.docs!.any((d) => d.contains('README.md')), isTrue);
      });

      test('has copilot-guidelines', () {
        expect(project.copilotGuidelines, isNotNull);
        expect(project.copilotGuidelines, isNotEmpty);
        expect(project.copilotGuidelines!.any((g) => g.contains('coding.md')), isTrue);
      });

      test('should NOT have package-module (has parts instead)', () {
        expect(project.packageModule, isNull);
      });
    });

    group('utils_lib (dart_package without parts)', () {
      late TomProject project;

      setUpAll(() {
        project = master.projects['utils_lib']!;
      });

      test('has package-module', () {
        expect(project.packageModule, isNotNull);
        expect(project.packageModule!.name, equals('utils_lib'));
      });

      test('should NOT have parts (uses package-module instead)', () {
        expect(project.parts, isEmpty);
      });

      test('has tests', () {
        expect(project.tests, isNotNull);
        expect(project.tests!.any((t) => t.contains('string_utils_test.dart')), isTrue);
      });
    });

    group('my_cli (dart_cli)', () {
      late TomProject project;

      setUpAll(() {
        project = master.projects['my_cli']!;
      });

      test('has binary files', () {
        expect(project.binaryFiles, isNotNull);
        expect(project.binaryFiles, isNotEmpty);
        expect(project.binaryFiles!.any((b) => b.contains('my_cli.dart')), isTrue);
      });

      test('has executables', () {
        expect(project.executables, isNotEmpty);
        expect(project.executables.any((e) => e.source.contains('my_cli.dart')), isTrue);
      });

      test('has tests', () {
        expect(project.tests, isNotNull);
        expect(project.tests!.any((t) => t.contains('cli_test.dart')), isTrue);
      });

      test('should NOT have parts', () {
        expect(project.parts, isEmpty);
      });

      test('should NOT have package-module', () {
        expect(project.packageModule, isNull);
      });
    });

    group('my_server (dart_server)', () {
      late TomProject project;

      setUpAll(() {
        project = master.projects['my_server']!;
      });

      test('has executables', () {
        expect(project.executables, isNotEmpty);
        expect(project.executables.any((e) => e.source.contains('server.dart')), isTrue);
      });

      test('has tests', () {
        expect(project.tests, isNotNull);
        expect(project.tests!.any((t) => t.contains('server_test.dart')), isTrue);
        expect(project.tests!.any((t) => t.contains('user_handler_test.dart')), isTrue);
      });

      test('has docs', () {
        expect(project.docs, isNotNull);
        expect(project.docs!.any((d) => d.contains('README.md')), isTrue);
      });
    });

    group('Build order', () {
      test('produces valid build order', () {
        expect(master.buildOrder, isNotEmpty);
        // All projects should be in build order
        expect(master.buildOrder, containsAll(master.projects.keys));
      });

      test('respects build-after dependencies', () {
        // my_cli depends on core_lib, so core_lib should come before my_cli
        final coreIndex = master.buildOrder.indexOf('core_lib');
        final cliIndex = master.buildOrder.indexOf('my_cli');
        expect(coreIndex, lessThan(cliIndex));
      });
    });

    group('Scan timestamp', () {
      test('has scan timestamp', () {
        expect(master.scanTimestamp, isNotNull);
        expect(master.scanTimestamp, isNotEmpty);
      });
    });
  });
}
