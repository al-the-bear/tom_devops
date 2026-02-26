// Tests for D4rt execution with Tools bridges.
//
// These tests verify that:
// 1. Tools classes can be instantiated via D4rt scripts
// 2. Properties and methods work correctly through the bridge
// 3. The bridges are correctly registered with the barrel file import
//
// The test pattern:
// - Create a D4rtInstance and register bridges
// - Execute D4rt scripts that use Tools classes
// - Verify the results match expected values

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

import 'tools_bridge_test.reflection.dart' as reflection;

void main() {
  // Initialize reflection for TomCoreKernelBridge global variables
  reflection.initializeReflection();

  group('Tools Bridge Tests', () {
    late D4rtInstance d4rt;
    late String workspacePath;

    setUp(() async {
      d4rt = D4rtInstance.create();
      workspacePath = Directory.current.parent.path;

      // Bridges are already registered by D4rtInstance.create()

      // Initialize with imports so evaluate() can access the classes
      await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

void main() {
  // Imports are now available for eval()
}
''');
    });

    tearDown(() {
      d4rt.dispose();
      // Clean up ToolContext if loaded
      ToolContext.clear();
    });

    // =========================================================================
    // WorkspaceInfo Bridge Tests
    // =========================================================================

    group('WorkspaceInfo bridge', () {
      test('can create WorkspaceInfo instance', () async {
        final result = await d4rt.evaluate('WorkspaceInfo()');
        expect(result, isA<WorkspaceInfo>());
      });

      test('can create WorkspaceInfo with name param', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

WorkspaceInfo? globalWsInfo;

void main() {
  globalWsInfo = WorkspaceInfo(name: 'test_workspace');
}
''');
        final result = await d4rt.evaluate('globalWsInfo');
        expect(result, isA<WorkspaceInfo>());
        final wsInfo = result as WorkspaceInfo;
        expect(wsInfo.name, equals('test_workspace'));
      });

      test('WorkspaceInfo properties are accessible (via D4rt)', () async {
        // Now using D4rt - coercion helpers fix the List type issue
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

WorkspaceInfo? globalWsInfo;

void main() {
  globalWsInfo = WorkspaceInfo(
    name: 'my_ws',
    buildOrder: ['project1', 'project2'],
  );
}
''');
        final result = await d4rt.evaluate('globalWsInfo');
        expect(result, isA<WorkspaceInfo>());
        final wsInfo = result as WorkspaceInfo;
        expect(wsInfo.name, equals('my_ws'));
        expect(wsInfo.buildOrder, equals(['project1', 'project2']));
      });

      test('WorkspaceInfo with settings map (via D4rt)', () async {
        // Test Map parameter through D4rt
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

WorkspaceInfo? globalWsInfo;

void main() {
  globalWsInfo = WorkspaceInfo(
    name: 'configured_ws',
    settings: {'version': '1.0.0', 'debug': true},
  );
}
''');
        final result = await d4rt.evaluate('globalWsInfo');
        expect(result, isA<WorkspaceInfo>());
        final wsInfo = result as WorkspaceInfo;
        expect(wsInfo.name, equals('configured_ws'));
        expect(wsInfo.settings['version'], equals('1.0.0'));
        expect(wsInfo.settings['debug'], isTrue);
      });
    });

    // =========================================================================
    // MetadataModes Bridge Tests
    // =========================================================================

    group('MetadataModes bridge', () {
      test('can create MetadataModes instance', () async {
        final result = await d4rt.evaluate('MetadataModes()');
        expect(result, isA<MetadataModes>());
      });

      test('can create MetadataModes with defaultMode', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

MetadataModes? globalModes;

void main() {
  globalModes = MetadataModes(defaultMode: 'development');
}
''');
        final result = await d4rt.evaluate('globalModes');
        expect(result, isA<MetadataModes>());
        final modes = result as MetadataModes;
        expect(modes.defaultMode, equals('development'));
      });
    });

    // =========================================================================
    // MetadataMode Bridge Tests
    // =========================================================================

    group('MetadataMode bridge', () {
      test('can create MetadataMode instance', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

MetadataMode? globalMode;

void main() {
  globalMode = MetadataMode(name: 'development', description: 'Development mode');
}
''');
        final result = await d4rt.evaluate('globalMode');
        expect(result, isA<MetadataMode>());
        final mode = result as MetadataMode;
        expect(mode.name, equals('development'));
        expect(mode.description, equals('Development mode'));
      });

      test('MetadataMode with implies (via D4rt)', () async {
        // Now using D4rt - coercion helpers fix the List type issue
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

MetadataMode? globalMode;

void main() {
  globalMode = MetadataMode(
    name: 'development',
    implies: ['debug', 'test'],
  );
}
''');
        final result = await d4rt.evaluate('globalMode');
        expect(result, isA<MetadataMode>());
        final mode = result as MetadataMode;
        expect(mode.implies, equals(['debug', 'test']));
      });
    });

    // =========================================================================
    // WorkspaceGroup Bridge Tests
    // =========================================================================

    group('WorkspaceGroup bridge', () {
      test('can create WorkspaceGroup instance', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

WorkspaceGroup? globalGroup;

void main() {
  globalGroup = WorkspaceGroup(name: 'core', description: 'Core packages');
}
''');
        final result = await d4rt.evaluate('globalGroup');
        expect(result, isA<WorkspaceGroup>());
        final group = result as WorkspaceGroup;
        expect(group.name, equals('core'));
        expect(group.description, equals('Core packages'));
      });

      test('WorkspaceGroup with projects (via D4rt)', () async {
        // Now using D4rt - coercion helpers fix the List type issue
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

WorkspaceGroup? globalGroup;

void main() {
  globalGroup = WorkspaceGroup(
    name: 'core',
    projects: ['proj1', 'proj2'],
  );
}
''');
        final result = await d4rt.evaluate('globalGroup');
        expect(result, isA<WorkspaceGroup>());
        final group = result as WorkspaceGroup;
        expect(group.projects, equals(['proj1', 'proj2']));
      });
    });

    // =========================================================================
    // WorkspaceProject Bridge Tests
    // =========================================================================

    group('WorkspaceProject bridge', () {
      test('can create WorkspaceProject instance', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

WorkspaceProject? globalProj;

void main() {
  globalProj = WorkspaceProject(
    name: 'my_project',
    type: 'dart_package',
    description: 'My test project',
  );
}
''');
        final result = await d4rt.evaluate('globalProj');
        expect(result, isA<WorkspaceProject>());
        final proj = result as WorkspaceProject;
        expect(proj.name, equals('my_project'));
        expect(proj.type, equals('dart_package'));
        expect(proj.description, equals('My test project'));
      });

      test('WorkspaceProject with List and Map (via D4rt)', () async {
        // Now using D4rt - coercion helpers fix both List and Map type issues
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

WorkspaceProject? globalProj;

void main() {
  globalProj = WorkspaceProject(
    name: 'test_proj',
    buildAfter: ['dep1', 'dep2'],
    features: {'reflection': true, 'testing': false},
  );
}
''');
        final result = await d4rt.evaluate('globalProj');
        expect(result, isA<WorkspaceProject>());
        final proj = result as WorkspaceProject;
        expect(proj.buildAfter, equals(['dep1', 'dep2']));
        expect(proj.features, equals({'reflection': true, 'testing': false}));
      });

      test('WorkspaceProject with all collection params (via D4rt)', () async {
        // Test all List and Map parameters
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

WorkspaceProject? globalProj;

void main() {
  globalProj = WorkspaceProject(
    name: 'full_project',
    type: 'dart_package',
    buildAfter: ['core', 'utils'],
    features: {'reflection': true},
    build: {'output': 'dist'},
    run: {'port': 8080},
    deploy: {'target': 'cloud'},
    binaries: ['main', 'cli'],
    docs: ['README.md', 'API.md'],
    tests: ['unit', 'integration'],
    examples: ['basic', 'advanced'],
    copilotGuidelines: ['coding.md', 'testing.md'],
  );
}
''');
        final result = await d4rt.evaluate('globalProj');
        expect(result, isA<WorkspaceProject>());
        final proj = result as WorkspaceProject;
        expect(proj.buildAfter, equals(['core', 'utils']));
        expect(proj.features, equals({'reflection': true}));
        expect(proj.build, equals({'output': 'dist'}));
        expect(proj.run, equals({'port': 8080}));
        expect(proj.deploy, equals({'target': 'cloud'}));
        expect(proj.binaries, equals(['main', 'cli']));
        expect(proj.docs, equals(['README.md', 'API.md']));
        expect(proj.tests, equals(['unit', 'integration']));
        expect(proj.examples, equals(['basic', 'advanced']));
        expect(proj.copilotGuidelines, equals(['coding.md', 'testing.md']));
      });
    });

    // =========================================================================
    // TomRunResult Bridge Tests
    // NOTE: Skipped - TomRunResult is not bridged in tom_dartscript_bridges
    // =========================================================================

    group('TomRunResult bridge', skip: 'Class not bridged', () {
      test('can create TomRunResult instance', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

TomRunResult? globalResult;

void main() {
  globalResult = TomRunResult(
    success: true,
    command: 'build',
    message: 'Build completed',
    duration: Duration(seconds: 5),
  );
}
''');
        final result = await d4rt.evaluate('globalResult');
        expect(result, isA<TomRunResult>());
        final runResult = result as TomRunResult;
        expect(runResult.success, isTrue);
        expect(runResult.command, equals('build'));
        expect(runResult.message, equals('Build completed'));
        expect(runResult.duration, equals(const Duration(seconds: 5)));
      });

      test('can access TomRunResult.error property', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

TomRunResult? failedResult;

void main() {
  failedResult = TomRunResult(
    success: false,
    command: 'test',
    message: 'Test failed',
    error: 'Assertion error',
    duration: Duration(milliseconds: 100),
  );
}
''');
        final result = await d4rt.evaluate('failedResult');
        final runResult = result as TomRunResult;
        expect(runResult.success, isFalse);
        expect(runResult.error, equals('Assertion error'));
      });
    });

    // =========================================================================
    // TomRunResults Bridge Tests
    // =========================================================================

    group('TomRunResults bridge', skip: 'Class not bridged', () {
      test('TomRunResults can be created (via D4rt)', () async {
        // Now using D4rt - coercion helpers fix the List type issue
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

TomRunResults? globalResults;

void main() {
  final r1 = TomRunResult(
    success: true,
    command: 'cmd1',
    message: 'ok',
    duration: Duration(seconds: 1),
  );
  final r2 = TomRunResult(
    success: true,
    command: 'cmd2',
    message: 'ok',
    duration: Duration(seconds: 2),
  );
  globalResults = TomRunResults([r1, r2]);
}
''');
        final result = await d4rt.evaluate('globalResults');
        expect(result, isA<TomRunResults>());
        final results = result as TomRunResults;
        expect(results.success, isTrue);
        expect(results.results.length, equals(2));
        expect(results.totalDuration, equals(const Duration(seconds: 3)));
      });

      test('TomRunResults with failed results (via D4rt)', () async {
        // Test failure detection through D4rt
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

TomRunResults? globalResults;

void main() {
  final r1 = TomRunResult(
    success: true,
    command: 'cmd1',
    message: 'ok',
    duration: Duration(seconds: 1),
  );
  final r2 = TomRunResult(
    success: false,
    command: 'cmd2',
    message: 'failed',
    duration: Duration(seconds: 2),
  );
  globalResults = TomRunResults([r1, r2]);
}
''');
        final result = await d4rt.evaluate('globalResults');
        expect(result, isA<TomRunResults>());
        final results = result as TomRunResults;
        expect(results.success, isFalse); // Should be false because one failed
        expect(results.results.length, equals(2));
      });
    });

    // =========================================================================
    // TomRunner Bridge Tests
    // =========================================================================

    group('TomRunner bridge', skip: 'Class not bridged', () {
      test('can create TomRunner instance', () async {
        final result = await d4rt.evaluate(
          "TomRunner(workspacePath: '$workspacePath', verbose: false, dryRun: true)",
        );
        expect(result, isA<TomRunner>());
        final runner = result as TomRunner;
        expect(runner.workspacePath, equals(workspacePath));
        expect(runner.verbose, isFalse);
        expect(runner.dryRun, isTrue);
      });
    });

    // =========================================================================
    // PipelineDefinition Bridge Tests
    // =========================================================================

    group('PipelineDefinition bridge', skip: 'Class not bridged', () {
      test('PipelineDefinition can be created (via D4rt)', () async {
        // Now using D4rt - coercion helpers fix the List type issue
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

PipelineDefinition? globalPipeline;

void main() {
  globalPipeline = PipelineDefinition(
    name: 'build_all',
    commands: ['build tom_core', 'build tom_tools'],
  );
}
''');
        final result = await d4rt.evaluate('globalPipeline');
        expect(result, isA<PipelineDefinition>());
        final pipeline = result as PipelineDefinition;
        expect(pipeline.name, equals('build_all'));
        expect(pipeline.commands.length, equals(2));
      });

      test('PipelineDefinition.parseCommands works (via D4rt)', () async {
        // Now using D4rt - test method call on bridged instance
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

PipelineDefinition? globalPipeline;
List<List<String>>? parsedCommands;

void main() {
  globalPipeline = PipelineDefinition(
    name: 'test',
    commands: ['build proj1', 'test proj2'],
  );
  parsedCommands = globalPipeline!.parseCommands();
}
''');
        final result = await d4rt.evaluate('parsedCommands');
        expect(result, isA<List>());
        final parsed = result as List;
        expect(parsed.length, equals(2));
      });
    });

    // =========================================================================
    // PipelineResult Bridge Tests
    // =========================================================================

    group('PipelineResult bridge', skip: 'Class not bridged', () {
      test('PipelineResult can be created (via D4rt)', () async {
        // Now using D4rt - coercion helpers fix the List type issue
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

PipelineResult? globalPipelineResult;

void main() {
  final pipeline = PipelineDefinition(
    name: 'test',
    commands: ['cmd1'],
  );
  final runResult = TomRunResult(
    success: true,
    command: 'cmd1',
    message: 'ok',
    duration: Duration(seconds: 1),
  );
  final runResults = TomRunResults([runResult]);
  globalPipelineResult = PipelineResult(
    pipeline: pipeline,
    commandResults: [runResults],
  );
}
''');
        final result = await d4rt.evaluate('globalPipelineResult');
        expect(result, isA<PipelineResult>());
        final pipelineResult = result as PipelineResult;
        expect(pipelineResult.success, isTrue);
        expect(pipelineResult.pipeline.name, equals('test'));
      });
    });

    // =========================================================================
    // PipelineLoader Bridge Tests
    // =========================================================================

    group('PipelineLoader bridge', skip: 'Class not bridged', () {
      test('can create PipelineLoader instance', () async {
        final result = await d4rt.evaluate("PipelineLoader('$workspacePath')");
        expect(result, isA<PipelineLoader>());
        final loader = result as PipelineLoader;
        expect(loader.workspacePath, equals(workspacePath));
      });

      test('can call PipelineLoader.loadPipelines', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

Map? loadedPipelines;

void main() {
  final loader = PipelineLoader('$workspacePath');
  loadedPipelines = loader.loadPipelines();
}
''');
        final result = await d4rt.evaluate('loadedPipelines');
        expect(result, isA<Map>());
      });
    });

    // =========================================================================
    // PipelineRunner Bridge Tests
    // =========================================================================

    group('PipelineRunner bridge', skip: 'Class not bridged', () {
      test('can create PipelineRunner instance', () async {
        final result = await d4rt.evaluate(
          "PipelineRunner(workspacePath: '$workspacePath', dryRun: true)",
        );
        expect(result, isA<PipelineRunner>());
        final runner = result as PipelineRunner;
        expect(runner.workspacePath, equals(workspacePath));
        expect(runner.dryRun, isTrue);
      });
    });

    // =========================================================================
    // ToolPrefix Bridge Tests
    // =========================================================================

    group('ToolPrefix bridge', skip: 'Class not bridged', () {
      test('ToolPrefix static values are correct (via D4rt)', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

String? wsPrepper;
String? workspaceAnalyzer;
String? reflectionGenerator;

void main() {
  wsPrepper = ToolPrefix.wsPrepper;
  workspaceAnalyzer = ToolPrefix.workspaceAnalyzer;
  reflectionGenerator = ToolPrefix.reflectionGenerator;
}
''');
        expect(await d4rt.evaluate('wsPrepper'), equals('wp-'));
        expect(await d4rt.evaluate('workspaceAnalyzer'), equals('wa-'));
        expect(await d4rt.evaluate('reflectionGenerator'), equals('rc-'));
      });
    });

    // =========================================================================
    // CliArgs Bridge Tests
    // =========================================================================

    group('CliArgs bridge', skip: 'Class not bridged', () {
      test('CliArgs can be created (via D4rt)', () async {
        // Now using D4rt - coercion helpers fix the List type issue
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

CliArgs? globalArgs;

void main() {
  globalArgs = CliArgs('build', ['proj1', '--verbose', '-n=5']);
}
''');
        final result = await d4rt.evaluate('globalArgs');
        expect(result, isA<CliArgs>());
        final args = result as CliArgs;
        expect(args.prefix, equals('build'));
        expect(args.positionalArgs, contains('proj1'));
        expect(args.verbose, isTrue);
      });

      test('CliArgs methods work (via D4rt)', () async {
        // Now using D4rt - test method calls on bridged instance
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

CliArgs? globalArgs;
int? countValue;
bool? hasFlag;

void main() {
  globalArgs = CliArgs('test', ['--count=42', '--flag']);
  countValue = globalArgs!.getInt('count');
  hasFlag = globalArgs!.hasFlag('flag');
}
''');
        final countResult = await d4rt.evaluate('countValue');
        expect(countResult, equals(42));
        final flagResult = await d4rt.evaluate('hasFlag');
        expect(flagResult, isTrue);
      });

      test('CliArgs get and hasFlag work (via D4rt)', () async {
        // Test additional CliArgs methods - hasFlag is for --flag style, getBool is for --flag=true style
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

CliArgs? globalArgs;
String? nameValue;
bool? flagValue;

void main() {
  globalArgs = CliArgs('config', ['--name=myproject', '--debug']);
  nameValue = globalArgs!.get('name');
  flagValue = globalArgs!.hasFlag('debug');
}
''');
        final nameResult = await d4rt.evaluate('nameValue');
        expect(nameResult, equals('myproject'));
        final flagResult = await d4rt.evaluate('flagValue');
        expect(flagResult, isTrue);
      });
    });

    // =========================================================================
    // PlatformInfo Bridge Tests
    // =========================================================================

    group('PlatformInfo bridge', () {
      test('can create PlatformInfo.detect', () async {
        final result = await d4rt.evaluate('PlatformInfo.detect()');
        expect(result, isA<PlatformInfo>());
        final info = result as PlatformInfo;
        // os and architecture are enums, not strings
        expect(info.os, isA<OperatingSystem>());
        expect(info.architecture, isA<CpuArchitecture>());
      });

      test('can access PlatformInfo properties', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

PlatformInfo? platformInfo;

void main() {
  platformInfo = PlatformInfo.detect();
}
''');
        final result = await d4rt.evaluate('platformInfo');
        final info = result as PlatformInfo;
        expect(info.platform, isNotEmpty);
        expect(info.dartTargetPlatforms, isA<List>());
      });

      test('can call PlatformInfo.canBuildFor', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

bool? canBuild;

void main() {
  final info = PlatformInfo.detect();
  canBuild = info.canBuildFor('linux-x64');
}
''');
        final result = await d4rt.evaluate('canBuild');
        expect(result, isA<bool>());
      });
    });

    // =========================================================================
    // ToolContext Bridge Tests
    // =========================================================================

    group('ToolContext bridge', skip: 'Class not bridged', () {
      test('can call ToolContext.load', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

ToolContext? globalContext;

void main() {
  globalContext = ToolContext.load(workspacePath: '$workspacePath');
}
''');
        final result = await d4rt.evaluate('globalContext');
        expect(result, isA<ToolContext>());
      });

      test('ToolContext.isInitialized works (via D4rt)', () async {
        // Clear context first
        ToolContext.clear();

        // Test before load via D4rt
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

bool? beforeLoad;

void main() {
  beforeLoad = ToolContext.isInitialized;
}
''');
        expect(await d4rt.evaluate('beforeLoad'), isFalse);

        // Load via native, then test via D4rt
        await ToolContext.load(workspacePath: workspacePath);

        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

bool? afterLoad;

void main() {
  afterLoad = ToolContext.isInitialized;
}
''');
        expect(await d4rt.evaluate('afterLoad'), isTrue);
      });

      test('ToolContext.current works (via D4rt)', () async {
        await ToolContext.load(workspacePath: workspacePath);
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

ToolContext? ctx;
String? path;

void main() {
  ctx = ToolContext.current;
  path = ctx!.workspacePath;
}
''');
        final ctx = await d4rt.evaluate('ctx');
        expect(ctx, isA<ToolContext>());
        expect(await d4rt.evaluate('path'), equals(workspacePath));
      });

      test('can access ToolContext properties (via D4rt)', () async {
        await ToolContext.load(workspacePath: workspacePath);
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

OperatingSystem? os;
CpuArchitecture? architecture;

void main() {
  final ctx = ToolContext.current;
  os = ctx.os;
  architecture = ctx.architecture;
}
''');
        expect(await d4rt.evaluate('os'), isA<OperatingSystem>());
        expect(await d4rt.evaluate('architecture'), isA<CpuArchitecture>());
      });
    });

    // =========================================================================
    // ToolContextException Bridge Tests
    // =========================================================================

    group('ToolContextException bridge', skip: 'Class not bridged', () {
      test('can create ToolContextException instance', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

ToolContextException? globalException;

void main() {
  globalException = ToolContextException('Test error message');
}
''');
        final result = await d4rt.evaluate('globalException');
        expect(result, isA<ToolContextException>());
        final exc = result as ToolContextException;
        expect(exc.message, equals('Test error message'));
      });

      test('can call ToolContextException.toString', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

String? excString;

void main() {
  final exc = ToolContextException('Error!');
  excString = exc.toString();
}
''');
        final result = await d4rt.evaluate('excString');
        expect(result, isA<String>());
        expect(result as String, contains('Error!'));
      });
    });

    // =========================================================================
    // ModeValidationResult Bridge Tests
    // =========================================================================

    group('ModeValidationResult bridge', () {
      test('ModeValidationResult.success works (via D4rt)', () async {
        // Now using D4rt - coercion helpers fix the List type issue
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

ModeValidationResult? globalValidation;

void main() {
  globalValidation = ModeValidationResult.success(['development', 'debug']);
}
''');
        final result = await d4rt.evaluate('globalValidation');
        expect(result, isA<ModeValidationResult>());
        final validation = result as ModeValidationResult;
        expect(validation.isValid, isTrue);
        expect(validation.resolvedModes, equals(['development', 'debug']));
      });

      test('can create ModeValidationResult.error', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

ModeValidationResult? errorResult;

void main() {
  errorResult = ModeValidationResult.error('Invalid mode: foo');
}
''');
        final result = await d4rt.evaluate('errorResult');
        expect(result, isA<ModeValidationResult>());
        final validation = result as ModeValidationResult;
        expect(validation.isValid, isFalse);
        expect(validation.errorMessage, equals('Invalid mode: foo'));
      });
    });
  });

  // ===========================================================================
  // Bridge Registration Verification
  // ===========================================================================

  group('Tools Bridge Registration Verification', () {
    test('all Tools bridges are registered', () {
      final instance = D4rtInstance.create();
      expect(instance.isInitialized, isTrue);

      // Verify interpreter.getConfiguration() returns classes
      final config = instance.interpreter.getConfiguration();
      final classes = config.imports.expand((i) => i.classes).toList();
      expect(classes.length, greaterThanOrEqualTo(18));

      instance.dispose();
    });

    test('bridge class names match expected list', () {
      final instance = D4rtInstance.create();

      // Core tools classes that must be present (from tom_build_bridges)
      final expectedCoreClasses = [
        'WorkspaceInfo',
        'WorkspaceAnalyzer',
        'ProjectInfo',
        'ToolContext',
      ];

      final config = instance.interpreter.getConfiguration();
      final actualClasses = config.imports
          .expand((i) => i.classes)
          .map((c) => c.name)
          .toList();

      // Verify core classes are present
      for (final expected in expectedCoreClasses) {
        expect(actualClasses, contains(expected));
      }

      instance.dispose();
    });
  });
}
