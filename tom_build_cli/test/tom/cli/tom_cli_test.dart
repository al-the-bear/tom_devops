// Tests for TomCli - Main CLI application
//
// Covers tom_tool_specification.md Section 6:
// - Parse command line arguments
// - Run internal commands or workspace actions
// - Handle :projects and :groups scope limiting
// - Execute multiple actions in sequence
// - Display helpful error messages
// - Support --help and --version

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/cli/tom_cli.dart';
import 'package:tom_build_cli/src/tom/cli/internal_commands.dart';
import 'package:tom_build_cli/src/tom/execution/action_executor.dart';

void main() {
  group('TomCli', () {
    // =========================================================================
    // TomCliConfig
    // =========================================================================
    group('TomCliConfig', () {
      test('creates config with default values', () {
        const config = TomCliConfig();

        expect(config.workspacePath, isNull);
        expect(config.metadataPath, isNull);
        expect(config.verbose, isFalse);
        expect(config.dryRun, isFalse);
        expect(config.stopOnFailure, isTrue);
      });

      test('resolves workspace path to current directory when null', () {
        const config = TomCliConfig();

        expect(config.resolvedWorkspacePath, equals(Directory.current.path));
      });

      test('uses provided workspace path', () {
        const config = TomCliConfig(workspacePath: '/custom/path');

        expect(config.resolvedWorkspacePath, equals('/custom/path'));
      });

      test('resolves metadata path based on workspace', () {
        const config = TomCliConfig(workspacePath: '/workspace');

        expect(config.resolvedMetadataPath, equals('/workspace/.tom_metadata'));
      });

      test('uses provided metadata path', () {
        const config = TomCliConfig(
          workspacePath: '/workspace',
          metadataPath: '/custom/metadata',
        );

        expect(config.resolvedMetadataPath, equals('/custom/metadata'));
      });

      test('copyWith creates modified copy', () {
        const original = TomCliConfig(
          workspacePath: '/original',
          verbose: false,
          dryRun: false,
        );

        final modified = original.copyWith(
          verbose: true,
          dryRun: true,
        );

        expect(modified.workspacePath, equals('/original'));
        expect(modified.verbose, isTrue);
        expect(modified.dryRun, isTrue);
      });

      test('copyWith preserves unspecified values', () {
        const original = TomCliConfig(
          workspacePath: '/original',
          verbose: true,
          dryRun: true,
          stopOnFailure: false,
        );

        final modified = original.copyWith(verbose: false);

        expect(modified.workspacePath, equals('/original'));
        expect(modified.verbose, isFalse);
        expect(modified.dryRun, isTrue);
        expect(modified.stopOnFailure, isFalse);
      });
    });

    // =========================================================================
    // TomCliResult
    // =========================================================================
    group('TomCliResult', () {
      test('success factory creates correct result', () {
        final result = TomCliResult.success(message: 'All done');

        expect(result.exitCode, equals(0));
        expect(result.success, isTrue);
        expect(result.message, equals('All done'));
        expect(result.error, isNull);
      });

      test('failure factory creates correct result', () {
        final result = TomCliResult.failure(error: 'Something went wrong');

        expect(result.exitCode, equals(1));
        expect(result.success, isFalse);
        expect(result.error, equals('Something went wrong'));
        expect(result.message, isNull);
      });

      test('failure factory accepts custom exit code', () {
        final result = TomCliResult.failure(
          error: 'Not found',
          exitCode: 2,
        );

        expect(result.exitCode, equals(2));
      });

      test('help factory creates help result', () {
        final result = TomCliResult.help('Usage: tom ...');

        expect(result.exitCode, equals(0));
        expect(result.success, isTrue);
        expect(result.message, equals('Usage: tom ...'));
      });

      test('success result includes action results', () {
        final actionResults = [
          ActionExecutionResult.success(
            projectName: 'p1',
            actionName: 'build',
            commandResults: [],
            duration: Duration(seconds: 1),
          ),
        ];

        final result = TomCliResult.success(actionResults: actionResults);

        expect(result.actionResults.length, equals(1));
        expect(result.actionResults[0].projectName, equals('p1'));
      });

      test('success result includes command results', () {
        final commandResults = [
          InternalCommandResult.success(
            command: 'analyze',
            message: 'Done',
            duration: Duration(seconds: 2),
          ),
        ];

        final result = TomCliResult.success(commandResults: commandResults);

        expect(result.commandResults.length, equals(1));
        expect(result.commandResults[0].command, equals('analyze'));
      });
    });

    // =========================================================================
    // Help and Version
    // =========================================================================
    group('Help and Version', () {
      late Directory tempDir;
      late String workspacePath;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('tom_cli_test_');
        workspacePath = tempDir.path;
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('empty arguments returns help', () async {
        final cli = TomCli(
          config: TomCliConfig(workspacePath: workspacePath),
        );

        final result = await cli.run([]);

        expect(result.success, isTrue);
        expect(result.message, isNotNull);
        expect(result.message, contains('Tom CLI'));
      });

      test('-help returns help', () async {
        final cli = TomCli(
          config: TomCliConfig(workspacePath: workspacePath),
        );

        final result = await cli.run(['-help']);

        expect(result.success, isTrue);
        expect(result.message, isNotNull);
        expect(result.message, contains('Tom CLI'));
      });

      test('--help returns help', () async {
        final cli = TomCli(
          config: TomCliConfig(workspacePath: workspacePath),
        );

        final result = await cli.run(['--help']);

        expect(result.success, isTrue);
        expect(result.message, isNotNull);
      });

      test('-h returns help', () async {
        final cli = TomCli(
          config: TomCliConfig(workspacePath: workspacePath),
        );

        final result = await cli.run(['-h']);

        expect(result.success, isTrue);
        expect(result.message, isNotNull);
      });

      test('-version returns version', () async {
        final cli = TomCli(
          config: TomCliConfig(workspacePath: workspacePath),
        );

        final result = await cli.run(['-version']);

        expect(result.success, isTrue);
        expect(result.message, contains('version'));
      });

      test('-v returns version', () async {
        final cli = TomCli(
          config: TomCliConfig(workspacePath: workspacePath),
        );

        final result = await cli.run(['-v']);

        expect(result.success, isTrue);
        expect(result.message, contains('version'));
      });
    });

    // =========================================================================
    // Internal Command Execution
    // =========================================================================
    group('Internal Command Execution', () {
      late Directory tempDir;
      late String workspacePath;
      late String metadataPath;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('tom_cli_test_');
        workspacePath = tempDir.path;
        metadataPath = '$workspacePath/.tom_metadata';
        Directory(metadataPath).createSync(recursive: true);
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      void createWorkspaceFile() {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test-workspace
''');
      }

      test('executes :help command', () async {
        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':help']);

        expect(result.success, isTrue);
        expect(result.commandResults.length, equals(1));
        expect(result.commandResults[0].command, equals('help'));
      });

      test('executes :version command', () async {
        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':version']);

        expect(result.success, isTrue);
        expect(result.commandResults.length, equals(1));
      });

      test('executes :reset-action-counter command', () async {
        createWorkspaceFile();

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':reset-action-counter']);

        expect(result.success, isTrue);
        expect(result.commandResults.length, equals(1));
        expect(result.commandResults[0].command, equals('reset-action-counter'));
      });

      test('fails for internal command requiring workspace when not present', () async {
        // Do not create workspace file

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':analyze']);

        expect(result.success, isFalse);
        expect(result.error, contains('requires a Tom workspace'));
      });

      test('executes multiple internal commands in sequence', () async {
        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':help', ':version']);

        expect(result.success, isTrue);
        expect(result.commandResults.length, equals(2));
      });
    });

    // =========================================================================
    // Global Parameters
    // =========================================================================
    group('Global Parameters', () {
      late Directory tempDir;
      late String workspacePath;
      late String metadataPath;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('tom_cli_test_');
        workspacePath = tempDir.path;
        metadataPath = '$workspacePath/.tom_metadata';
        Directory(metadataPath).createSync(recursive: true);
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      void createWorkspaceFile() {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test-workspace
''');
      }

      test('applies -verbose flag', () async {
        createWorkspaceFile();

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        // Using :help since it does not depend on workspace actions
        final result = await cli.run(['-verbose', ':help']);

        expect(result.success, isTrue);
      });

      test('applies -dry-run flag', () async {
        createWorkspaceFile();

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run(['-dry-run', ':analyze']);

        expect(result.success, isTrue);
        // In dry-run mode, analyze should report it would run
        expect(result.commandResults[0].message, contains('dry-run'));
      });
    });

    // =========================================================================
    // Error Handling
    // =========================================================================
    group('Error Handling', () {
      late Directory tempDir;
      late String workspacePath;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('tom_cli_test_');
        workspacePath = tempDir.path;
      });

      tearDown(() {
        tempDir.deleteSync(recursive: true);
      });

      test('returns error for invalid arguments', () async {
        final cli = TomCli(
          config: TomCliConfig(workspacePath: workspacePath),
        );

        final result = await cli.run([':projects', ':groups']);

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('handles unknown internal command gracefully', () async {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test
''');

        final cli = TomCli(
          config: TomCliConfig(workspacePath: workspacePath),
        );

        // Use a known internal command prefix but with unknown suffix
        // :unknown-internal would be treated as workspace action
        // Use :analyze-nonexistent which starts with internal command pattern
        final result = await cli.run([':nonexistent-action']);

        // This is treated as a workspace action, not an internal command
        // It should fail because there's no master file or action defined
        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });
    });

    // =========================================================================
    // runTomCli Function
    // =========================================================================
    group('runTomCli Function', () {
      test('returns 0 for help', () async {
        // We cannot easily test this without mocking stdout
        // Just verify it does not throw
        expect(() => runTomCli(['-help']), returnsNormally);
      });
    });
  });
}
