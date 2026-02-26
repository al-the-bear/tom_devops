import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

void main() {
  group('CliArgs', () {
    test('parses prefixed named parameters', () {
      final args = parseWsPrepperArgs([
        'wp-mode=development',
        'wp-path=/path/to/workspace',
        'wp-dry-run',
      ]);

      expect(args['mode'], equals('development'));
      expect(args['path'], equals('/path/to/workspace'));
      expect(args.hasFlag('dry-run'), isTrue);
      expect(args.positionalArgs, isEmpty);
    });

    test('parses legacy --flag style', () {
      final args = parseWsPrepperArgs([
        'development',
        '/path/to/workspace',
        '--dry-run',
        '--verbose',
      ]);

      expect(args.hasFlag('dry-run'), isTrue);
      expect(args.hasFlag('verbose'), isTrue);
      expect(
        args.positionalArgs,
        equals(['development', '/path/to/workspace']),
      );
    });

    test('parses mixed prefixed and legacy args', () {
      final args = parseWsPrepperArgs(['wp-mode=dev', '--dry-run', '/path']);

      expect(args['mode'], equals('dev'));
      expect(args.hasFlag('dry-run'), isTrue);
      expect(args.positionalArgs, equals(['/path']));
    });

    test('parses --option=value style', () {
      final args = parseWsPrepperArgs(['--output=/tmp/out', '--format=json']);

      expect(args['output'], equals('/tmp/out'));
      expect(args['format'], equals('json'));
    });

    test('parses workspace analyzer args', () {
      final args = parseWorkspaceAnalyzerArgs([
        'wa-path=/workspace',
        'wa-include-tests',
      ]);

      expect(args['path'], equals('/workspace'));
      expect(args.hasFlag('include-tests'), isTrue);
    });

    test('handles help flag', () {
      expect(parseWsPrepperArgs(['--help']).help, isTrue);
      expect(parseWsPrepperArgs(['-h']).help, isTrue);
      expect(parseWsPrepperArgs(['wp-mode=dev']).help, isFalse);
    });

    test('get method returns default value', () {
      final args = parseWsPrepperArgs(['wp-mode=dev']);

      expect(args.get('mode', 'default'), equals('dev'));
      expect(args.get('missing', 'fallback'), equals('fallback'));
    });

    test('getInt parses integer values', () {
      final args = parseWsPrepperArgs(['wp-count=42']);

      expect(args.getInt('count'), equals(42));
      expect(args.getInt('missing'), isNull);
    });

    test('getBool parses boolean values', () {
      final args = parseWsPrepperArgs([
        'wp-enabled=true',
        'wp-disabled=false',
        'wp-one=1',
      ]);

      expect(args.getBool('enabled'), isTrue);
      expect(args.getBool('disabled'), isFalse);
      expect(args.getBool('one'), isTrue);
      expect(args.getBool('missing', true), isTrue);
    });

    test('resolvePath handles relative and absolute paths', () {
      final args = parseWsPrepperArgs([]);
      final cwd = Directory.current.path;

      expect(args.resolvePath('/absolute/path'), equals('/absolute/path'));
      expect(
        args.resolvePath('relative/path'),
        equals(p.join(cwd, 'relative/path')),
      );
    });
  });

  group('WorkspaceInfo', () {
    test('parses workspace modes from YAML', () {
      final yaml = _parseYaml('''
name: test_workspace
workspace-modes:
  supported:
    - name: development
      implies: [relative_build]
      description: Dev mode
    - name: production
    - name: default
  default: default
''');
      final info = WorkspaceInfo.fromYaml(yaml);

      expect(info.workspaceModes, isNotNull);
      expect(info.workspaceModes!.supportedModes.length, equals(3));
      expect(info.workspaceModes!.defaultMode, equals('default'));

      final devMode = info.workspaceModes!.supportedModes.firstWhere(
        (m) => m.name == 'development',
      );
      expect(devMode.implies, equals(['relative_build']));
      expect(devMode.description, equals('Dev mode'));
    });

    test('parses groups from YAML', () {
      final yaml = _parseYaml('''
name: test
groups:
  core:
    description: Core packages
    projects: [pkg_a, pkg_b]
  utils:
    description: Utility packages
    projects: [util_a]
''');
      final info = WorkspaceInfo.fromYaml(yaml);

      expect(info.groups.length, equals(2));
      expect(info.groups['core']!.projects, equals(['pkg_a', 'pkg_b']));
      expect(info.groups['utils']!.description, equals('Utility packages'));
    });

    test('parses build order from YAML', () {
      final yaml = _parseYaml('''
name: test
build-order: [lib_a, lib_b, app_c]
''');
      final info = WorkspaceInfo.fromYaml(yaml);

      expect(info.buildOrder, equals(['lib_a', 'lib_b', 'app_c']));
    });

    test('parses projects from YAML', () {
      final yaml = _parseYaml('''
name: test
projects:
  my_project:
    name: My Project
    type: dart_package
    description: A test project
    build-after: [dep_a, dep_b]
    features:
      has-reflection: true
      publishable: false
''');
      final info = WorkspaceInfo.fromYaml(yaml);

      expect(info.projects.length, equals(1));
      final project = info.projects['my_project']!;
      expect(project.displayName, equals('My Project'));
      expect(project.type, equals('dart_package'));
      expect(project.buildAfter, equals(['dep_a', 'dep_b']));
      expect(project.features['has-reflection'], isTrue);
      expect(project.features['publishable'], isFalse);
    });

    test('handles empty workspace gracefully', () {
      final yaml = _parseYaml('name: empty');
      final info = WorkspaceInfo.fromYaml(yaml);

      expect(info.workspaceModes, isNull);
      expect(info.groups, isEmpty);
      expect(info.projects, isEmpty);
    });

    test('handles missing workspace section', () {
      final yaml = _parseYaml('other: value');
      final info = WorkspaceInfo.fromYaml(yaml);

      expect(info.name, isNull);
      expect(info.projects, isEmpty);
    });
  });

  group('WorkspaceModes', () {
    test('parses simple mode names', () {
      final yaml = _parseYaml('''
supported:
  - name: dev
  - name: prod
default: dev
''');
      final modes = WorkspaceModes.fromYaml(yaml);

      expect(modes.supportedModes.length, equals(2));
      expect(modes.supportedModes[0].name, equals('dev'));
      expect(modes.supportedModes[1].name, equals('prod'));
      expect(modes.defaultMode, equals('dev'));
    });

    test('parses mode with implies list', () {
      final yaml = _parseYaml('''
supported:
  - name: development
    implies: [relative_build, debug]
''');
      final modes = WorkspaceModes.fromYaml(yaml);

      expect(
        modes.supportedModes[0].implies,
        equals(['relative_build', 'debug']),
      );
    });

    test('parses mode with single implies value', () {
      final yaml = _parseYaml('''
supported:
  - name: development
    implies: relative_build
''');
      final modes = WorkspaceModes.fromYaml(yaml);

      expect(modes.supportedModes[0].implies, equals(['relative_build']));
    });
  });

  group('ToolContext', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tool_context_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      ToolContext.clear();
    });

    test('throws when metadata not found', () async {
      expect(
        () => ToolContext.load(workspacePath: tempDir.path),
        throwsA(isA<ToolContextException>()),
      );
    });

    test('loads context from valid metadata', () async {
      _createMetadataFile(tempDir.path, '''
name: test_workspace
workspace-modes:
  supported:
    - name: development
      implies: [relative_build]
    - name: production
    - name: default
  default: default
''');

      final context = await ToolContext.load(workspacePath: tempDir.path);

      expect(context.workspaceInfo.name, equals('test_workspace'));
      expect(context.workspaceInfo.workspaceModes, isNotNull);
      expect(ToolContext.isInitialized, isTrue);
    });

    test('validates modes correctly', () async {
      _createMetadataFile(tempDir.path, '''
name: test
workspace-modes:
  supported:
    - name: development
      implies: [relative_build]
    - name: relative_build
    - name: production
    - name: default
  default: default
''');

      final context = await ToolContext.load(workspacePath: tempDir.path);

      // Valid mode
      final validResult = context.validateModes(['development']);
      expect(validResult.isValid, isTrue);
      expect(validResult.resolvedModes, contains('relative_build'));
      expect(validResult.resolvedModes, contains('development'));

      // Invalid mode
      final invalidResult = context.validateModes(['invalid_mode']);
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errorMessage, contains('invalid_mode'));
    });

    test('resolves implied modes in correct order', () async {
      _createMetadataFile(tempDir.path, '''
name: test
workspace-modes:
  supported:
    - name: development
      implies: [relative_build]
    - name: relative_build
    - name: production
  default: default
''');

      final context = await ToolContext.load(workspacePath: tempDir.path);
      final result = context.validateModes(['development']);

      // Implied mode should come before the mode that implies it
      final relativeIndex = result.resolvedModes.indexOf('relative_build');
      final devIndex = result.resolvedModes.indexOf('development');
      expect(relativeIndex, lessThan(devIndex));
    });

    test('handles multiple modes with implications', () async {
      _createMetadataFile(tempDir.path, '''
name: test
workspace-modes:
  supported:
    - name: development
      implies: [debug]
    - name: debug
    - name: production
      implies: [optimized]
    - name: optimized
  default: default
''');

      final context = await ToolContext.load(workspacePath: tempDir.path);
      final result = context.validateModes(['development', 'production']);

      expect(result.isValid, isTrue);
      expect(
        result.resolvedModes,
        containsAll(['debug', 'development', 'optimized', 'production']),
      );
    });

    test('reload clears and reloads context', () async {
      _createMetadataFile(tempDir.path, '''
name: first_load
''');

      await ToolContext.load(workspacePath: tempDir.path);
      expect(ToolContext.current.workspaceInfo.name, equals('first_load'));

      // Update file
      _createMetadataFile(tempDir.path, '''
name: second_load
''');

      await ToolContext.reload(workspacePath: tempDir.path);
      expect(ToolContext.current.workspaceInfo.name, equals('second_load'));
    });

    test('current throws when not initialized', () {
      ToolContext.clear();
      expect(() => ToolContext.current, throwsStateError);
    });

    test('returns error when no workspace-modes section', () async {
      _createMetadataFile(tempDir.path, '''
name: test_no_modes
''');

      final context = await ToolContext.load(workspacePath: tempDir.path);
      final result = context.validateModes(['development']);

      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('No workspace-modes section'));
    });
  });

  group('ToolPrefix constants', () {
    test('has correct prefixes for all tools', () {
      expect(ToolPrefix.wsPrepper, equals('wp-'));
      expect(ToolPrefix.workspaceAnalyzer, equals('wa-'));
      expect(ToolPrefix.reflectionGenerator, equals('rc-'));
    });
  });
}

// Helper to parse YAML string
dynamic _parseYaml(String content) {
  return loadYaml(content);
}

// Helper to create metadata file in temp directory
void _createMetadataFile(String tempPath, String content) {
  final metadataDir = Directory(p.join(tempPath, '.tom_metadata'));
  if (!metadataDir.existsSync()) {
    metadataDir.createSync(recursive: true);
  }
  File(p.join(metadataDir.path, 'tom_master.yaml')).writeAsStringSync(content);
}
