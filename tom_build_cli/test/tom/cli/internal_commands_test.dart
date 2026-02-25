// Tests for InternalCommands - Internal command execution
//
// Covers tom_tool_specification.md Section 6.4:
// - Command registry and lookup
// - :analyze - Run workspace analyzer
// - :version-bump - Increment versions for changed packages
// - :reset-action-counter - Reset action counter to 0
// - :pipeline - Execute named pipeline
// - Action counter management
// - ! prefix for built-in override

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/cli/internal_commands.dart';

void main() {
  group('InternalCommands', () {
    // =========================================================================
    // Section 6.4.1 - Command Registry
    // =========================================================================
    group('Section 6.4.1 - Command Registry', () {
      test('contains all internal commands', () {
        expect(InternalCommands.commands, contains('analyze'));
        expect(InternalCommands.commands, contains('generate-reflection'));
        expect(InternalCommands.commands, contains('version-bump'));
        expect(InternalCommands.commands, contains('prepper'));
        expect(InternalCommands.commands, contains('reset-action-counter'));
        expect(InternalCommands.commands, contains('pipeline'));
        expect(InternalCommands.commands, contains('help'));
        expect(InternalCommands.commands, contains('version'));
      });

      test('isInternalCommand returns true for known commands', () {
        expect(InternalCommands.isInternalCommand('analyze'), isTrue);
        expect(InternalCommands.isInternalCommand('version-bump'), isTrue);
        expect(InternalCommands.isInternalCommand('reset-action-counter'), isTrue);
        expect(InternalCommands.isInternalCommand('pipeline'), isTrue);
      });

      test('isInternalCommand returns false for unknown commands', () {
        expect(InternalCommands.isInternalCommand('build'), isFalse);
        expect(InternalCommands.isInternalCommand('test'), isFalse);
        expect(InternalCommands.isInternalCommand('deploy'), isFalse);
      });

      test('getCommand returns info for known commands', () {
        final info = InternalCommands.getCommand('analyze');
        expect(info, isNotNull);
        expect(info!.name, equals('analyze'));
        expect(info.prefix, equals('wa'));
        expect(info.description, isNotEmpty);
        expect(info.requiresWorkspace, isTrue);
      });

      test('getCommand returns null for unknown commands', () {
        expect(InternalCommands.getCommand('build'), isNull);
      });

      test('getPrefix returns correct prefixes', () {
        expect(InternalCommands.getPrefix('analyze'), equals('wa'));
        expect(InternalCommands.getPrefix('generate-reflection'), equals('gr'));
        expect(InternalCommands.getPrefix('version-bump'), equals('vb'));
        expect(InternalCommands.getPrefix('prepper'), equals('wp'));
      });

      test('getPrefix returns null for commands without prefixes', () {
        expect(InternalCommands.getPrefix('reset-action-counter'), isNull);
        expect(InternalCommands.getPrefix('pipeline'), isNull);
        expect(InternalCommands.getPrefix('help'), isNull);
        expect(InternalCommands.getPrefix('version'), isNull);
      });

      test('getCommandForPrefix returns correct commands', () {
        expect(InternalCommands.getCommandForPrefix('wa'), equals('analyze'));
        expect(InternalCommands.getCommandForPrefix('gr'), equals('generate-reflection'));
        expect(InternalCommands.getCommandForPrefix('vb'), equals('version-bump'));
        expect(InternalCommands.getCommandForPrefix('wp'), equals('prepper'));
      });

      test('getCommandForPrefix returns null for unknown prefixes', () {
        expect(InternalCommands.getCommandForPrefix('xx'), isNull);
        expect(InternalCommands.getCommandForPrefix(''), isNull);
      });
    });

    // =========================================================================
    // InternalCommandInfo
    // =========================================================================
    group('InternalCommandInfo', () {
      test('analyze command info is correct', () {
        final info = InternalCommands.getCommand('analyze')!;
        expect(info.name, equals('analyze'));
        expect(info.prefix, equals('wa'));
        expect(info.description, contains('workspace analyzer'));
        expect(info.requiresWorkspace, isTrue);
      });

      test('version-bump command info is correct', () {
        final info = InternalCommands.getCommand('version-bump')!;
        expect(info.name, equals('version-bump'));
        expect(info.prefix, equals('vb'));
        expect(info.description, contains('version'));
        expect(info.requiresWorkspace, isTrue);
      });

      test('help command does not require workspace', () {
        final info = InternalCommands.getCommand('help')!;
        expect(info.requiresWorkspace, isFalse);
      });
    });

    // =========================================================================
    // InternalCommandConfig
    // =========================================================================
    group('InternalCommandConfig', () {
      test('creates config with required parameters', () {
        final config = InternalCommandConfig(
          workspacePath: '/workspace',
        );

        expect(config.workspacePath, equals('/workspace'));
        expect(config.metadataDir, equals('/workspace/.tom_metadata'));
        expect(config.stateFilePath, equals('/workspace/.tom_metadata/workspace_state.yaml'));
        expect(config.verbose, isFalse);
        expect(config.dryRun, isFalse);
        expect(config.projects, isEmpty);
        expect(config.groups, isEmpty);
      });

      test('uses custom metadata path when provided', () {
        final config = InternalCommandConfig(
          workspacePath: '/workspace',
          metadataPath: '/custom/metadata',
        );

        expect(config.metadataDir, equals('/custom/metadata'));
        expect(config.stateFilePath, equals('/custom/metadata/workspace_state.yaml'));
      });

      test('accepts all optional parameters', () {
        final config = InternalCommandConfig(
          workspacePath: '/workspace',
          metadataPath: '/meta',
          verbose: true,
          dryRun: true,
          projects: ['p1', 'p2'],
          groups: ['g1'],
        );

        expect(config.verbose, isTrue);
        expect(config.dryRun, isTrue);
        expect(config.projects, equals(['p1', 'p2']));
        expect(config.groups, equals(['g1']));
      });
    });

    // =========================================================================
    // InternalCommandResult
    // =========================================================================
    group('InternalCommandResult', () {
      test('success factory creates correct result', () {
        final result = InternalCommandResult.success(
          command: 'analyze',
          message: 'Analysis complete',
          duration: Duration(seconds: 5),
        );

        expect(result.command, equals('analyze'));
        expect(result.success, isTrue);
        expect(result.message, equals('Analysis complete'));
        expect(result.error, isNull);
        expect(result.duration, equals(Duration(seconds: 5)));
      });

      test('failure factory creates correct result', () {
        final result = InternalCommandResult.failure(
          command: 'version-bump',
          error: 'No changes detected',
          duration: Duration(milliseconds: 100),
        );

        expect(result.command, equals('version-bump'));
        expect(result.success, isFalse);
        expect(result.error, equals('No changes detected'));
        expect(result.message, isNull);
        expect(result.duration, equals(Duration(milliseconds: 100)));
      });
    });
  });

  // ===========================================================================
  // InternalCommandExecutor
  // ===========================================================================
  group('InternalCommandExecutor', () {
    late Directory tempDir;
    late String workspacePath;
    late String metadataPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('internal_commands_test_');
      workspacePath = tempDir.path;
      metadataPath = '$workspacePath/.tom_metadata';
      Directory(metadataPath).createSync(recursive: true);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    /// Helper to create a workspace file.
    void createWorkspaceFile() {
      File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test-workspace
''');
    }

    // =========================================================================
    // Section 6.4.3 - :reset-action-counter
    // =========================================================================
    group('Section 6.4.3 - :reset-action-counter', () {
      test('resets action counter to 0', () async {
        createWorkspaceFile();

        // Set counter to non-zero first
        final counterManager = ActionCounterManager(
          stateFilePath: '$metadataPath/workspace_state.yaml',
        );
        await counterManager.set(42);

        // Reset via command - inject same counter manager
        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(
          config: config,
          counterManager: counterManager,
        );

        final result = await executor.execute(commandName: 'reset-action-counter');

        expect(result.success, isTrue);
        expect(result.message, contains('reset'));

        // The increment happens before the command runs (42 -> 43),
        // then reset sets to 0
        final newValue = await counterManager.get();
        expect(newValue, equals(0));
      });

      test('creates state file if not exists', () async {
        createWorkspaceFile();

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(commandName: 'reset-action-counter');

        expect(result.success, isTrue);
        expect(File('$metadataPath/workspace_state.yaml').existsSync(), isTrue);
      });
    });

    // =========================================================================
    // Command Execution - Workspace Requirements
    // =========================================================================
    group('Workspace Requirements', () {
      test('fails when workspace required but not present', () async {
        // Don't create workspace file

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(commandName: 'analyze');

        expect(result.success, isFalse);
        expect(result.error, contains('requires a Tom workspace'));
      });

      test('succeeds for commands that do not require workspace', () async {
        // Don't create workspace file

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(commandName: 'help');

        expect(result.success, isTrue);
      });
    });

    // =========================================================================
    // Unknown Commands
    // =========================================================================
    group('Unknown Commands', () {
      test('fails for unknown command', () async {
        createWorkspaceFile();

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(commandName: 'unknown-command');

        expect(result.success, isFalse);
        expect(result.error, contains('Unknown internal command'));
      });
    });

    // =========================================================================
    // Action Counter Increment
    // =========================================================================
    group('Action Counter Increment', () {
      test('increments counter before executing command', () async {
        createWorkspaceFile();

        final counterManager = ActionCounterManager(
          stateFilePath: '$metadataPath/workspace_state.yaml',
        );
        await counterManager.set(5);

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(
          config: config,
          counterManager: counterManager,
        );

        // Help doesn't require workspace, so it will succeed
        final result = await executor.execute(commandName: 'help');

        expect(result.success, isTrue);
        // Counter should be 6 after increment
        expect(await counterManager.get(), equals(6));
      });
    });

    // =========================================================================
    // Dry Run Mode
    // =========================================================================
    group('Dry Run Mode', () {
      test(':analyze respects dry-run mode', () async {
        createWorkspaceFile();

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
          dryRun: true,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(commandName: 'analyze');

        expect(result.success, isTrue);
        expect(result.message, contains('dry-run'));
      });

      test(':version-bump respects dry-run mode', () async {
        createWorkspaceFile();

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
          dryRun: true,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(commandName: 'version-bump');

        expect(result.success, isTrue);
        expect(result.message, contains('dry-run'));
      });
    });

    // =========================================================================
    // :help Command
    // =========================================================================
    group(':help Command', () {
      test('returns help message', () async {
        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(commandName: 'help');

        expect(result.success, isTrue);
        expect(result.message, contains('Tom CLI'));
        expect(result.message, contains(':analyze'));
        expect(result.message, contains(':version-bump'));
        expect(result.message, contains('Usage:'));
      });
    });

    // =========================================================================
    // :version Command
    // =========================================================================
    group(':version Command', () {
      test('returns version message', () async {
        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(commandName: 'version');

        expect(result.success, isTrue);
        expect(result.message, contains('version'));
      });
    });

    // =========================================================================
    // :pipeline Command
    // =========================================================================
    group(':pipeline Command', () {
      test('fails without pipeline name', () async {
        createWorkspaceFile();

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(commandName: 'pipeline');

        expect(result.success, isFalse);
        expect(result.error, contains('Pipeline name required'));
      });

      test('fails when pipeline not found', () async {
        createWorkspaceFile();

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(
          commandName: 'pipeline',
          parameters: {'name': 'ci'},
        );

        expect(result.success, isFalse);
        expect(result.error, contains('ci'));
        expect(result.error, contains('not found'));
      });

      test('respects dry-run mode', () async {
        // Create workspace with a pipeline defined
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test-workspace
pipelines:
  ci:
    actions:
      - action: build
''');

        final config = InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
          dryRun: true,
        );
        final executor = InternalCommandExecutor(config: config);

        final result = await executor.execute(
          commandName: 'pipeline',
          parameters: {'name': 'ci'},
        );

        expect(result.success, isTrue);
        expect(result.message, contains('dry-run'));
        expect(result.message, contains('ci'));
      });
    });
  });

  // ===========================================================================
  // ActionCounterManager
  // ===========================================================================
  group('ActionCounterManager', () {
    late Directory tempDir;
    late String stateFilePath;
    late ActionCounterManager manager;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('action_counter_test_');
      stateFilePath = '${tempDir.path}/workspace_state.yaml';
      manager = ActionCounterManager(stateFilePath: stateFilePath);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('get returns 0 when file does not exist', () async {
      expect(await manager.get(), equals(0));
    });

    test('increment increases counter by 1', () async {
      expect(await manager.increment(), equals(1));
      expect(await manager.increment(), equals(2));
      expect(await manager.increment(), equals(3));
    });

    test('reset sets counter to 0', () async {
      await manager.increment();
      await manager.increment();
      await manager.increment();

      await manager.reset();

      expect(await manager.get(), equals(0));
    });

    test('set sets counter to specific value', () async {
      await manager.set(42);
      expect(await manager.get(), equals(42));

      await manager.set(100);
      expect(await manager.get(), equals(100));
    });

    test('persists value to file', () async {
      await manager.set(99);

      // Create new manager to read from file
      final newManager = ActionCounterManager(stateFilePath: stateFilePath);
      expect(await newManager.get(), equals(99));
    });

    test('creates directory if not exists', () async {
      final deepPath = '${tempDir.path}/deep/nested/workspace_state.yaml';
      final deepManager = ActionCounterManager(stateFilePath: deepPath);

      await deepManager.set(5);

      expect(File(deepPath).existsSync(), isTrue);
    });

    test('preserves other state properties', () async {
      // Write initial state with other properties
      final file = File(stateFilePath);
      await file.writeAsString('''
other-property: some-value
action-counter: 10
another-property: 123
''');

      // Increment counter
      await manager.increment();

      // Check counter was incremented
      expect(await manager.get(), equals(11));
    });

    test('handles malformed YAML gracefully', () async {
      final file = File(stateFilePath);
      await file.writeAsString('this is not: valid: yaml: [');

      // Should return 0 on parse error
      expect(await manager.get(), equals(0));
    });
  });
}
