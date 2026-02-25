// ignore_for_file: avoid_print

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

void main() {
  group('PipelineDefinition', () {
    test('creates pipeline with name and commands', () {
      final pipeline = PipelineDefinition(
        name: 'test',
        commands: ['step1', 'step2'],
      );

      expect(pipeline.name, 'test');
      expect(pipeline.commands, ['step1', 'step2']);
    });

    test('creates pipeline from YAML list', () {
      final yaml = ['ws_analyzer', 'ws_publisher'];
      // Using mocked YamlList-like behavior
      final pipeline = PipelineDefinition(
        name: 'deploy',
        commands: yaml,
      );

      expect(pipeline.name, 'deploy');
      expect(pipeline.commands, ['ws_analyzer', 'ws_publisher']);
    });

    test('parseCommands strips tom prefix', () {
      final pipeline = PipelineDefinition(
        name: 'test',
        commands: ['tom ws_analyzer', 'ws_prepper mode=dev'],
      );

      final parsed = pipeline.parseCommands();
      expect(parsed.length, 2);
      expect(parsed[0].commands.first.name, 'ws_analyzer');
      expect(parsed[1].commands.first.name, 'ws_prepper');
    });

    test('parseCommands handles multi-command lines', () {
      final pipeline = PipelineDefinition(
        name: 'test',
        commands: ['ws_analyzer ws_prepper mode=dev'],
      );

      final parsed = pipeline.parseCommands();
      expect(parsed.length, 1);
      expect(parsed[0].commands.length, 2);
    });

    test('toString shows pipeline info', () {
      final pipeline = PipelineDefinition(
        name: 'release',
        commands: ['cmd1', 'cmd2', 'cmd3'],
      );

      expect(pipeline.toString(), contains('release'));
      expect(pipeline.toString(), contains('3'));
    });
  });

  group('PipelineLoader', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pipeline_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('loads pipelines from tom_workspace.yaml', () async {
      final workspaceYaml = File('${tempDir.path}/tom_workspace.yaml');
      workspaceYaml.writeAsStringSync('''
mode: dev

pipelines:
  release:
    - ws_analyzer
    - ws_versioner version=patch
    - ws_publisher
  test:
    - ws_analyzer --verbose
''');

      final loader = PipelineLoader(tempDir.path);
      final pipelines = await loader.loadPipelines();

      expect(pipelines.length, 2);
      expect(pipelines['release']!.name, 'release');
      expect(pipelines['release']!.commands.length, 3);
      expect(pipelines['test']!.name, 'test');
      expect(pipelines['test']!.commands.length, 1);
    });

    test('loads pipelines with YAML folded block multiline commands', () async {
      final workspaceYaml = File('${tempDir.path}/tom_workspace.yaml');
      workspaceYaml.writeAsStringSync('''
pipelines:
  multiline:
    - ws_analyzer
    - >
      ws_prepper
      mode=release
      skipTests=true
    - ws_publisher
''');

      final loader = PipelineLoader(tempDir.path);
      final pipelines = await loader.loadPipelines();

      expect(pipelines['multiline']!.commands.length, 3);
      expect(pipelines['multiline']!.commands[0], 'ws_analyzer');
      // Folded block should join lines with spaces
      expect(pipelines['multiline']!.commands[1], 'ws_prepper mode=release skipTests=true');
      expect(pipelines['multiline']!.commands[2], 'ws_publisher');
    });

    test('returns empty map when no pipelines defined', () async {
      final workspaceYaml = File('${tempDir.path}/tom_workspace.yaml');
      workspaceYaml.writeAsStringSync('''
mode: dev
''');

      final loader = PipelineLoader(tempDir.path);
      final pipelines = await loader.loadPipelines();

      expect(pipelines, isEmpty);
    });

    test('returns empty map when workspace.yaml does not exist', () async {
      final loader = PipelineLoader(tempDir.path);
      final pipelines = await loader.loadPipelines();

      expect(pipelines, isEmpty);
    });

    test('getPipeline returns specific pipeline by name', () async {
      final workspaceYaml = File('${tempDir.path}/tom_workspace.yaml');
      workspaceYaml.writeAsStringSync('''
pipelines:
  deploy:
    - ws_analyzer
    - ws_publisher
''');

      final loader = PipelineLoader(tempDir.path);
      final pipeline = await loader.getPipeline('deploy');

      expect(pipeline, isNotNull);
      expect(pipeline!.name, 'deploy');
      expect(pipeline.commands.length, 2);
    });

    test('getPipeline returns null for non-existent pipeline', () async {
      final workspaceYaml = File('${tempDir.path}/tom_workspace.yaml');
      workspaceYaml.writeAsStringSync('''
pipelines:
  deploy:
    - ws_analyzer
''');

      final loader = PipelineLoader(tempDir.path);
      final pipeline = await loader.getPipeline('nonexistent');

      expect(pipeline, isNull);
    });

    test('listPipelineNames returns sorted names', () async {
      final workspaceYaml = File('${tempDir.path}/tom_workspace.yaml');
      workspaceYaml.writeAsStringSync('''
pipelines:
  gamma:
    - step1
  alpha:
    - step2
  beta:
    - step3
''');

      final loader = PipelineLoader(tempDir.path);
      final names = await loader.listPipelineNames();

      expect(names, ['alpha', 'beta', 'gamma']);
    });
  });

  group('PipelineRunner', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('pipeline_runner_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('runs pipeline with dry run enabled', () async {
      final workspaceYaml = File('${tempDir.path}/tom_workspace.yaml');
      workspaceYaml.writeAsStringSync('''
pipelines:
  test:
    - help
''');

      final output = StringBuffer();
      final runner = PipelineRunner(
        workspacePath: tempDir.path,
        dryRun: true,
        verbose: true,
        output: output,
      );

      final result = await runner.runPipeline('test');

      expect(result.pipeline.name, 'test');
    });

    test('fails when pipeline not found', () async {
      final workspaceYaml = File('${tempDir.path}/tom_workspace.yaml');
      workspaceYaml.writeAsStringSync('''
pipelines:
  existing:
    - step1
''');

      final runner = PipelineRunner(
        workspacePath: tempDir.path,
        dryRun: true,
      );

      expect(
        () => runner.runPipeline('nonexistent'),
        throwsArgumentError,
      );
    });

    test('execute runs pipeline definition', () async {
      final output = StringBuffer();
      final runner = PipelineRunner(
        workspacePath: tempDir.path,
        dryRun: true,
        verbose: true,
        output: output,
      );

      final pipeline = PipelineDefinition(
        name: 'custom',
        commands: ['help', 'version'],
      );

      final result = await runner.execute(pipeline);

      expect(result.pipeline.name, 'custom');
      expect(result.commandResults.length, 2);
    });
  });

  group('PipelineResult', () {
    test('success is true when all commands succeed', () {
      final pipeline = PipelineDefinition(name: 'test', commands: ['step1']);
      final result = PipelineResult(
        pipeline: pipeline,
        commandResults: [
          TomRunResults([
            TomRunResult(
              success: true,
              command: 'step1',
              message: 'Done',
              duration: Duration(seconds: 1),
            ),
          ]),
        ],
      );

      expect(result.success, isTrue);
      expect(result.totalDuration, Duration(seconds: 1));
    });

    test('success is false when any command fails', () {
      final pipeline = PipelineDefinition(name: 'test', commands: ['step1']);
      final result = PipelineResult(
        pipeline: pipeline,
        commandResults: [
          TomRunResults([
            TomRunResult(
              success: false,
              command: 'step1',
              message: 'Failed',
              error: 'Step failed',
              duration: Duration(seconds: 1),
            ),
          ]),
        ],
      );

      expect(result.success, isFalse);
    });

    test('toString shows pipeline summary', () {
      final pipeline = PipelineDefinition(name: 'deploy', commands: ['a', 'b']);
      final result = PipelineResult(
        pipeline: pipeline,
        commandResults: [],
      );

      final str = result.toString();
      expect(str, contains('deploy'));
      expect(str, contains('2'));
    });
  });
}
