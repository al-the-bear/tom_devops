/// Tests for internal commands in Tom CLI.
///
/// Tests cover:
/// 1. Command registry and validation
/// 2. :generate-bridges command (delegates to tom_d4rt_generator)
/// 3. :version-bump command
/// 4. :reset-action-counter command
/// 5. :pipeline command
/// 6. Version reading

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/cli/internal_commands.dart';

void main() {
  group('Internal Commands Registry', () {
    test('all standard commands are registered', () {
      expect(InternalCommands.isInternalCommand('analyze'), isTrue);
      expect(InternalCommands.isInternalCommand('version-bump'), isTrue);
      expect(
        InternalCommands.isInternalCommand('reset-action-counter'),
        isTrue,
      );
      expect(InternalCommands.isInternalCommand('pipeline'), isTrue);
      expect(InternalCommands.isInternalCommand('generate-reflection'), isTrue);
      expect(InternalCommands.isInternalCommand('generate-bridges'), isTrue);
      expect(InternalCommands.isInternalCommand('prepper'), isTrue);
      expect(InternalCommands.isInternalCommand('help'), isTrue);
      expect(InternalCommands.isInternalCommand('version'), isTrue);
    });

    test('unknown commands are not registered', () {
      expect(InternalCommands.isInternalCommand('unknown'), isFalse);
      expect(InternalCommands.isInternalCommand('foo'), isFalse);
      expect(InternalCommands.isInternalCommand(''), isFalse);
    });

    test('command prefixes are correct', () {
      expect(InternalCommands.getPrefix('analyze'), equals('wa'));
      expect(InternalCommands.getPrefix('generate-reflection'), equals('gr'));
      expect(InternalCommands.getPrefix('generate-bridges'), equals('gb'));
      expect(InternalCommands.getPrefix('version-bump'), equals('vb'));
      expect(InternalCommands.getPrefix('prepper'), equals('wp'));
    });

    test('getCommandForPrefix returns correct command', () {
      expect(InternalCommands.getCommandForPrefix('wa'), equals('analyze'));
      expect(
        InternalCommands.getCommandForPrefix('gr'),
        equals('generate-reflection'),
      );
      expect(
        InternalCommands.getCommandForPrefix('gb'),
        equals('generate-bridges'),
      );
    });

    test('command info has correct workspace requirements', () {
      // Commands requiring workspace
      expect(InternalCommands.getCommand('analyze')?.requiresWorkspace, isTrue);
      expect(
        InternalCommands.getCommand('version-bump')?.requiresWorkspace,
        isTrue,
      );
      expect(
        InternalCommands.getCommand('pipeline')?.requiresWorkspace,
        isTrue,
      );
      expect(InternalCommands.getCommand('prepper')?.requiresWorkspace, isTrue);

      // Commands not requiring workspace
      expect(
        InternalCommands.getCommand('generate-bridges')?.requiresWorkspace,
        isFalse,
      );
      expect(InternalCommands.getCommand('help')?.requiresWorkspace, isFalse);
      expect(
        InternalCommands.getCommand('version')?.requiresWorkspace,
        isFalse,
      );
    });
  });

  group('InternalCommandExecutor', () {
    late Directory tempDir;
    late InternalCommandConfig config;
    late InternalCommandExecutor executor;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'test_internal_commands_',
      );
      config = InternalCommandConfig(
        workspacePath: tempDir.path,
        dryRun: true,
        verbose: false,
      );
      executor = InternalCommandExecutor(config: config);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('unknown command returns failure', () async {
      final result = await executor.execute(commandName: 'unknown');
      expect(result.success, isFalse);
      expect(result.error, contains('Unknown internal command'));
    });

    test(
      'command requiring workspace fails without tom_workspace.yaml',
      () async {
        final result = await executor.execute(commandName: 'analyze');
        expect(result.success, isFalse);
        expect(result.error, contains('requires a Tom workspace'));
      },
    );

    group('help command', () {
      test('returns success', () async {
        final result = await executor.execute(commandName: 'help');
        expect(result.success, isTrue);
        expect(result.message, isNotNull);
      });

      test('lists all commands', () async {
        final result = await executor.execute(commandName: 'help');
        expect(result.message, contains(':analyze'));
        expect(result.message, contains(':generate-bridges'));
      });
    });

    group('version command', () {
      test('returns success', () async {
        final result = await executor.execute(commandName: 'version');
        expect(result.success, isTrue);
        expect(result.message, contains('Tom CLI'));
      });
    });

    group('generate-bridges command', () {
      test('fails without input specification', () async {
        final result = await executor.execute(
          commandName: 'generate-bridges',
          parameters: {},
        );
        expect(result.success, isFalse);
        expect(result.error, contains('No input specified'));
      });

      test('fails without output specification', () async {
        final result = await executor.execute(
          commandName: 'generate-bridges',
          parameters: {'file': 'test.dart'},
        );
        expect(result.success, isFalse);
        expect(result.error, contains('Output path required'));
      });

      test('dry-run shows what would be generated', () async {
        final result = await executor.execute(
          commandName: 'generate-bridges',
          parameters: {
            'file': 'lib/test.dart',
            'output': 'lib/test_bridge.dart',
          },
        );
        expect(result.success, isTrue);
        expect(result.message, contains('[dry-run]'));
        expect(result.message, contains('File: lib/test.dart'));
        expect(result.message, contains('Output: lib/test_bridge.dart'));
      });

      test('dry-run with pattern shows pattern', () async {
        final result = await executor.execute(
          commandName: 'generate-bridges',
          parameters: {
            'dir': 'lib/',
            'pattern': 'Tom*',
            'output': 'lib/bridges/',
          },
        );
        expect(result.success, isTrue);
        expect(result.message, contains('Pattern: Tom*'));
      });
    });

    group('reset-action-counter command', () {
      test('resets counter successfully', () async {
        // Create metadata directory and workspace file
        final metadataDir = Directory(path.join(tempDir.path, '.tom_metadata'));
        await metadataDir.create();

        // Create tom_workspace.yaml since reset-action-counter requires workspace
        final wsFile = File(path.join(tempDir.path, 'tom_workspace.yaml'));
        await wsFile.writeAsString('name: test-workspace\n');

        final result = await executor.execute(
          commandName: 'reset-action-counter',
        );
        expect(result.success, isTrue);
        expect(result.message, contains('reset'));
      });
    });
  });

  // Note: BridgeGenerator tests removed as bridge generation is now
  // delegated to tom_d4rt_generator package to eliminate analyzer dependency
}
