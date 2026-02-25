// Integration tests for Tom CLI
//
// Tests the full pipeline from CLI input to execution output:
// - Workspace discovery and configuration loading
// - Command line argument parsing
// - Internal command and workspace action execution
// - Error handling and output formatting
//
// Reference: tom_tool_specification.md Sections 5, 6, 9

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/cli/tom_cli.dart';
import 'package:tom_build_cli/src/tom/config/config_loader.dart';
import 'package:tom_build_cli/src/tom/mode/mode_processor.dart';
import 'package:tom_build_cli/src/tom/template/tomplate_parser.dart';
import 'package:tom_build_cli/src/tom/template/tomplate_processor.dart';
import 'package:tom_build_cli/src/tom/execution/output_formatter.dart';
import 'package:tom_build_cli/src/tom/execution/action_executor.dart';
import 'package:tom_build_cli/src/tom/execution/command_runner.dart';

void main() {
  group('Tom CLI Integration Tests', () {
    late Directory tempDir;
    late String workspacePath;
    late String metadataPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tom_integration_test_');
      workspacePath = tempDir.path;
      metadataPath = '$workspacePath/.tom_metadata';
      Directory(metadataPath).createSync(recursive: true);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    // =========================================================================
    // Workspace Discovery and Configuration Loading
    // =========================================================================
    group('Workspace Discovery and Configuration', () {
      test('discovers workspace from tom_workspace.yaml', () async {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test-workspace
''');

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':help']);
        expect(result.success, isTrue);
      });

      test('fails gracefully when workspace not found', () async {
        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':analyze']);
        expect(result.success, isFalse);
        expect(result.error, contains('workspace'));
      });

      test('loads workspace with imports', () {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test-workspace
imports:
  - local_config.yaml
''');

        File('$workspacePath/local_config.yaml').writeAsStringSync('''
workspace-modes:
  mode-types: [environment]
''');

        final loader = ConfigLoader();
        final workspace = loader.loadWorkspaceConfig(workspacePath);

        expect(workspace, isNotNull);
        expect(workspace?.name, equals('test-workspace'));
      });

      test('loads workspace with project types', () {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: typed-workspace
project-types:
  dart_package:
    name: Dart Package
    description: A publishable Dart library
''');

        final loader = ConfigLoader();
        final workspace = loader.loadWorkspaceConfig(workspacePath);

        expect(workspace, isNotNull);
        expect(workspace!.projectTypes, isNotNull);
        expect(workspace.projectTypes['dart_package'], isNotNull);
      });
    });

    // =========================================================================
    // Mode Processing
    // =========================================================================
    group('Mode Processing', () {
      test('processes mode blocks in content', () {
        const content = '''
name: test
@@@mode development
debug: true
@@@endmode
@@@mode production
debug: false
@@@endmode
''';

        final processor = ModeProcessor();

        final devResult = processor.processContent(content, {'development'});
        expect(devResult, contains('debug: true'));
        expect(devResult, isNot(contains('debug: false')));

        final prodResult = processor.processContent(content, {'production'});
        expect(prodResult, contains('debug: false'));
        expect(prodResult, isNot(contains('debug: true')));
      });

      test('handles multiple mode blocks', () {
        const content = '''
@@@mode development
dev-settings:
  debug: true
@@@endmode
@@@mode verbose
log-level: debug
@@@endmode
''';

        final processor = ModeProcessor();
        final result = processor.processContent(content, {'development', 'verbose'});

        expect(result, contains('dev-settings:'));
        expect(result, contains('debug: true'));
        expect(result, contains('log-level: debug'));
      });
    });

    // =========================================================================
    // Template Processing
    // =========================================================================
    group('Template Processing', () {
      test('resolves simple placeholders', () {
        const templateContent = '''
name: \${project_name}
version: \${version}
''';

        final parser = TomplateParser();
        final parsed = parser.parseContent(templateContent, 'test.yaml.tomplate');
        final processor = TomplateProcessor();

        final result = processor.process(
          template: parsed,
          context: {'project_name': 'test', 'version': '1.0.0'},
        );

        expect(result.content, contains('name: test'));
        expect(result.content, contains('version: 1.0.0'));
      });

      test('resolves nested placeholders', () {
        const templateContent = '''
path: \${base_path}/\${sub_path}
''';

        final parser = TomplateParser();
        final parsed = parser.parseContent(templateContent, 'test.yaml.tomplate');
        final processor = TomplateProcessor();

        final result = processor.process(
          template: parsed,
          context: {'base_path': '/home', 'sub_path': 'user'},
        );

        expect(result.content, contains('path: /home/user'));
      });
    });

    // =========================================================================
    // CLI Command Execution
    // =========================================================================
    group('CLI Command Execution', () {
      test('executes :help command', () async {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test
''');

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':help']);

        expect(result.success, isTrue);
        expect(result.commandResults.length, equals(1));
      });

      test('executes :version command', () async {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test
''');

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':version']);
        expect(result.success, isTrue);
      });

      test('executes multiple commands in sequence', () async {
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

      test('dry-run mode indicates no actual execution', () async {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test
''');

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
            dryRun: true,
          ),
        );

        final result = await cli.run([':analyze']);

        expect(result.success, isTrue);
        expect(result.commandResults[0].message, contains('dry-run'));
      });

      test('verbose mode provides additional output', () async {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test
''');

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
            verbose: true,
          ),
        );

        final result = await cli.run([':help']);
        expect(result.success, isTrue);
      });
    });

    // =========================================================================
    // Error Handling
    // =========================================================================
    group('Error Handling', () {
      test('reports error for missing workspace file', () async {
        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':analyze']);

        expect(result.success, isFalse);
        expect(result.error, isNotNull);
      });

      test('reports error for conflicting scope arguments', () async {
        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':projects', 'p1', ':groups', 'g1']);
        expect(result.success, isFalse);
      });

      test('reports error for unknown workspace action', () async {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: test
''');

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':nonexistent-action']);
        expect(result.success, isFalse);
      });

      test('formats circular dependency error correctly', () {
        final buffer = StringBuffer();
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
          errorOutput: buffer,
        );

        formatter.printCircularDependencyError([
          'project_a',
          'project_b',
          'project_c',
          'project_a',
        ]);

        final output = buffer.toString();
        expect(output, contains('Circular dependency detected'));
        expect(output, contains('project_a → project_b → project_c → project_a'));
      });
    });

    // =========================================================================
    // Output Formatting
    // =========================================================================
    group('Output Formatting', () {
      test('formats action results for display', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, verbose: true),
        );

        final actionResult = ActionExecutionResult.success(
          projectName: 'test_project',
          actionName: 'build',
          commandResults: [
            CommandResult.success(
              command: 'dart analyze',
              stdout: 'No issues found',
              duration: const Duration(seconds: 2),
            ),
          ],
          duration: const Duration(seconds: 3),
        );

        final formatted = formatter.formatActionResult(actionResult);

        expect(formatted, contains('build'));
        expect(formatted, contains('test_project'));
        expect(formatted, contains('3.0s'));
      });

      test('formats summary for multiple results', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
        );

        final summary = formatter.formatSummary(
          actionResults: [
            ActionExecutionResult.success(
              projectName: 'p1',
              actionName: 'build',
              commandResults: [],
              duration: Duration.zero,
            ),
            ActionExecutionResult.failure(
              projectName: 'p2',
              actionName: 'build',
              error: 'Failed',
              duration: Duration.zero,
            ),
          ],
          commandResults: [],
          totalDuration: const Duration(seconds: 10),
        );

        expect(summary, contains('Summary'));
        expect(summary, contains('1 passed'));
        expect(summary, contains('1 failed'));
      });

      test('formats error per Section 9.2 format', () {
        const error = ErrorMessage(
          description: 'Action [build] requires [default:] definition',
          filePath: '~/tom_workspace.yaml',
          resolution: 'Add a default: block inside actions.build:',
        );

        final formatted = error.format();

        expect(formatted, contains('Error: Action [build] requires'));
        expect(formatted, contains('File: [~/tom_workspace.yaml]'));
        expect(formatted, contains('Resolution: Add a default: block'));
      });
    });

    // =========================================================================
    // Full Pipeline Integration
    // =========================================================================
    group('Full Pipeline Integration', () {
      test('complete workflow: workspace load -> cli execute', () async {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: integration-test
workspace-modes:
  mode-types: [environment]
  environment-modes:
    default: local
    local:
      description: Local dev
''');

        final cli = TomCli(
          config: TomCliConfig(
            workspacePath: workspacePath,
            metadataPath: metadataPath,
          ),
        );

        final result = await cli.run([':help']);
        expect(result.success, isTrue);
      });

      test('workspace with multiple projects and groups', () async {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: multi-project
groups:
  core:
    projects: [project_a, project_b]
  apps:
    projects: [project_c]
''');

        Directory('$workspacePath/project_a').createSync();
        Directory('$workspacePath/project_b').createSync();
        Directory('$workspacePath/project_c').createSync();

        File('$workspacePath/project_a/tom_project.yaml').writeAsStringSync('''
type: dart_package
''');
        File('$workspacePath/project_b/tom_project.yaml').writeAsStringSync('''
type: dart_package
build-after:
  - project_a
''');
        File('$workspacePath/project_c/tom_project.yaml').writeAsStringSync('''
type: flutter_app
build-after:
  - project_a
  - project_b
''');

        final loader = ConfigLoader();
        final workspace = loader.loadWorkspaceConfig(workspacePath);

        expect(workspace, isNotNull);
        final ws = workspace!;
        expect(ws.groups['core']?.projects, contains('project_a'));
        expect(ws.groups['core']?.projects, contains('project_b'));
      });

      test('template processing in workspace context', () {
        File('$workspacePath/tom_workspace.yaml').writeAsStringSync('''
name: template-test
''');

        const tomplate = '''
name: \${workspace_name}
description: Project in \${workspace_name}
''';

        final parser = TomplateParser();
        final parsed = parser.parseContent(tomplate, 'test.yaml.tomplate');
        final processor = TomplateProcessor();

        final result = processor.process(
          template: parsed,
          context: {'workspace_name': 'template-test'},
        );

        expect(result.content, contains('name: template-test'));
        expect(result.content, contains('Project in template-test'));
      });
    });
  });
}
