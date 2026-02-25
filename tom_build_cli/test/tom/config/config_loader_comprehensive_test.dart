/// Comprehensive tests for ConfigLoader (Section 3.2, 3.3)
///
/// Tests the loading and parsing of tom_workspace.yaml and tom_project.yaml
/// files according to the Tom CLI specification.
library;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/config/config_loader.dart';

void main() {
  late ConfigLoader loader;
  late Directory tempDir;

  setUp(() {
    loader = ConfigLoader();
    tempDir = Directory.systemTemp.createTempSync('config_loader_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ===========================================================================
  // Section 3.2 - tom_workspace.yaml Schema
  // ===========================================================================

  group('Section 3.2 - tom_workspace.yaml Schema', () {
    group('3.2.1 - Complete Field Reference', () {
      test('loads empty actions map when not specified', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
name: empty_workspace
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result, isNotNull);
        expect(result!.actions, isEmpty);
      });

      test('loads imports field as List<String>', () {
        _createFile(tempDir, 'tom_workspace.yaml', """
imports:
  - base.yaml
  - shared.yaml
actions:
  build:
    default:
      commands: []
""");
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.imports, equals(['base.yaml', 'shared.yaml']));
      });

      test('loads workspace-modes structure', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
workspace-modes:
  mode-types: [environment, execution]
  supported:
    - name: development
      description: Dev mode
      implies: [debug]
  environment-modes:
    default: local
    local:
      description: Local dev
      modes: [development]
  execution-modes:
    default: local
    local:
      description: Direct run
  action-mode-configuration:
    default:
      environment: local
      execution: local
    build:
      environment: local
      execution: local

actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.workspaceModes, isNotNull);
        expect(result.workspaceModes!.modeTypes, contains('environment'));
        expect(result.workspaceModes!.modeTypes, contains('execution'));
      });

      test('loads binaries field', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
binaries: custom/bin/
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.binaries, equals('custom/bin/'));
      });

      test('loads cross-compilation structure', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
cross-compilation:
  all-targets: [linux-x64, darwin-arm64, win32-x64]
  build-on:
    linux-x64:
      targets: [linux-x64]
    darwin-arm64:
      targets: [darwin-arm64]
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.crossCompilation, isNotNull);
        expect(
          result.crossCompilation!.allTargets,
          containsAll(['linux-x64', 'darwin-arm64', 'win32-x64']),
        );
      });

      test('loads groups structure', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
groups:
  core:
    description: Core libraries
    projects: [tom_core, tom_build]
  tools:
    projects: [tom_tools]
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.groups, hasLength(2));
        expect(result.groups['core']!.projects, contains('tom_core'));
        expect(result.groups['core']!.description, equals('Core libraries'));
      });

      test('loads environment-mode-definitions', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
environment-mode-definitions:
  default:
    description: Default env
  local:
    description: Local development
    working-dir: .
    variables:
      DEBUG: "true"
  prod:
    description: Production
    variables:
      DEBUG: "false"
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.modeDefinitions, contains('environment'));
      });

      test('loads execution-mode-definitions', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
execution-mode-definitions:
  default:
    working-dir: .
  local:
    description: Run directly
  docker:
    description: Run in container
    image: dart:stable
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.modeDefinitions, contains('execution'));
      });

      test('loads deployment-mode-definitions', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
deployment-mode-definitions:
  none:
    description: No deployment
  kubernetes:
    description: K8s deployment
    namespace: default
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.modeDefinitions, contains('deployment'));
      });

      test('loads cloud-provider-mode-definitions', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
cloud-provider-mode-definitions:
  default:
    region: us-east-1
  aws:
    name: Amazon Web Services
  gcp:
    name: Google Cloud
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.modeDefinitions, contains('cloud-provider'));
      });

      test('loads publishing-mode-definitions', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
publishing-mode-definitions:
  development:
    description: Dev builds
    publish: false
  release:
    description: Production release
    publish: true
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.modeDefinitions, contains('publishing'));
      });

      test('loads project-info structure', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
project-info:
  tom_core:
    description: Core library
    features:
      has-reflection: true
  tom_build:
    cross-compilation:
      all-targets: [linux-x64]
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.projectInfo, hasLength(2));
        expect(result.projectInfo, contains('tom_core'));
        expect(result.projectInfo, contains('tom_build'));
      });

      test('loads deps structure', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
deps:
  sdk: ">=3.0.0 <4.0.0"
  path: ^1.9.0
  yaml: ^3.1.2
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.deps, hasLength(3));
        expect(result.deps['sdk'], equals('>=3.0.0 <4.0.0'));
        expect(result.deps['path'], equals('^1.9.0'));
      });

      test('loads deps-dev structure', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
deps-dev:
  test: ^1.28.0
  lints: ^6.0.0
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.depsDev, hasLength(2));
        expect(result.depsDev['test'], equals('^1.28.0'));
      });

      test('loads version-settings structure', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
version-settings:
  prerelease-tag: dev
  auto-increment: true
  min-dev-build: 1
  action-counter: 42
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.versionSettings, isNotNull);
        expect(result.versionSettings!.prereleaseTag, equals('dev'));
        expect(result.versionSettings!.autoIncrement, isTrue);
        expect(result.versionSettings!.minDevBuild, equals(1));
        expect(result.versionSettings!.actionCounter, equals(42));
      });

      test('loads pipelines structure', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
pipelines:
  ci:
    global-parameters: [--verbose]
    projects:
      - name: tom_build
    actions:
      - action: test
      - action: build
  release:
    actions:
      - action: publish
actions:
  build:
    default:
      commands: []
  test:
    default:
      commands: []
  publish:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.pipelines, hasLength(2));
        expect(result.pipelines, contains('ci'));
        expect(result.pipelines, contains('release'));
      });

      test('loads custom tags passthrough', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
custom-setting: custom-value
my-config:
  nested: true
  list: [a, b, c]
another-custom: 42
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.customTags, contains('custom-setting'));
        expect(result.customTags['custom-setting'], equals('custom-value'));
        expect(result.customTags, contains('my-config'));
        expect(result.customTags['my-config']['nested'], isTrue);
        expect(result.customTags, contains('another-custom'));
        expect(result.customTags['another-custom'], equals(42));
      });
    });

    group('3.2.1a - project-types Structure', () {
      test('loads project-types with metadata-files', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
project-types:
  dart_package:
    name: Dart Package
    description: A publishable Dart library
    metadata-files:
      pubspec-yaml: pubspec.yaml
      build-yaml: build.yaml
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.projectTypes, contains('dart_package'));
        expect(result.projectTypes['dart_package']!.name, equals('Dart Package'));
        expect(
          result.projectTypes['dart_package']!.metadataFiles,
          contains('pubspec-yaml'),
        );
      });

      test('loads project-types with project-info-overrides', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
project-types:
  flutter_app:
    name: Flutter App
    metadata-files:
      pubspec-yaml: pubspec.yaml
    project-info-overrides:
      features:
        has-assets: true
        publishable: false
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        final flutter = result!.projectTypes['flutter_app']!;
        expect(flutter.projectInfoOverrides, isNotNull);
        expect(
          flutter.projectInfoOverrides!['features']['has-assets'],
          isTrue,
        );
      });

      test('loads multiple project types', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
project-types:
  dart_package:
    name: Dart Package
    metadata-files:
      pubspec-yaml: pubspec.yaml
  dart_cli:
    name: Dart CLI
    metadata-files:
      pubspec-yaml: pubspec.yaml
  flutter_app:
    name: Flutter App
    metadata-files:
      pubspec-yaml: pubspec.yaml
  vscode_extension:
    name: VS Code Extension
    metadata-files:
      package-json: package.json
      tsconfig-json: tsconfig.json
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.projectTypes, hasLength(4));
        expect(result.projectTypes, contains('dart_package'));
        expect(result.projectTypes, contains('dart_cli'));
        expect(result.projectTypes, contains('flutter_app'));
        expect(result.projectTypes, contains('vscode_extension'));
      });
    });

    group('3.2.4 - workspace-modes Structure', () {
      test('loads mode-types list', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
workspace-modes:
  mode-types: [environment, execution, cloud-provider, deployment, publishing]
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.workspaceModes!.modeTypes, hasLength(5));
        expect(result.workspaceModes!.modeTypes, contains('environment'));
        expect(result.workspaceModes!.modeTypes, contains('cloud-provider'));
      });

      test('loads supported modes with implies', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
workspace-modes:
  mode-types: [environment]
  supported:
    - name: development
      description: Development mode
      implies: [debug, verbose, relative_build]
    - name: production
      description: Production mode
      implies: [optimized]
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.workspaceModes!.supported, hasLength(2));
        expect(result.workspaceModes!.supported[0].name, equals('development'));
        expect(
          result.workspaceModes!.supported[0].implies,
          contains('debug'),
        );
      });

      test('loads mode-type-modes with default and entries', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
workspace-modes:
  mode-types: [environment]
  environment-modes:
    default: local
    local:
      description: Local development
      modes: [development]
    int:
      description: Integration
      modes: [development]
    prod:
      description: Production
      modes: [production]
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        final envModes = result!.workspaceModes!.modeTypeConfigs['environment'];
        expect(envModes, isNotNull);
        expect(envModes!.defaultMode, equals('local'));
        expect(envModes.entries, hasLength(3));
        expect(envModes.entries['local']!.modes, contains('development'));
      });

      test('loads action-mode-configuration with default and actions', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
workspace-modes:
  mode-types: [environment, execution]
  action-mode-configuration:
    default:
      environment: local
      execution: local
    build:
      description: Build for local
      environment: local
      execution: local
    deploy:
      description: Deploy to prod
      environment: prod
      execution: cloud
actions:
  build:
    default:
      commands: []
  deploy:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        final amc = result!.workspaceModes!.actionModeConfiguration;
        expect(amc, isNotNull);
        expect(amc!.entries, contains('default'));
        expect(amc.entries, contains('build'));
        expect(amc.entries, contains('deploy'));
        expect(amc.entries['deploy']!.modes['environment'], equals('prod'));
      });
    });

    group('3.2.5 - actions Structure', () {
      test('loads action with default configuration', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    default:
      commands:
        - dart analyze
        - dart test
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.actions['build']!.defaultConfig, isNotNull);
        expect(
          result.actions['build']!.defaultConfig!.commands,
          contains('dart analyze'),
        );
      });

      test('loads action with skip-types', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  deploy:
    skip-types: [dart_package, flutter_app]
    default:
      commands:
        - deploy.sh
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(
          result!.actions['deploy']!.skipTypes,
          contains('dart_package'),
        );
        expect(
          result.actions['deploy']!.skipTypes,
          contains('flutter_app'),
        );
      });

      test('loads action with applies-to-types', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  publish:
    applies-to-types: [dart_package]
    default:
      commands:
        - dart pub publish
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(
          result!.actions['publish']!.appliesToTypes,
          contains('dart_package'),
        );
      });

      test('loads action with pre and post commands', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    default:
      pre-commands:
        - echo "Pre-build"
      commands:
        - dart compile exe
      post-commands:
        - echo "Post-build"
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        final config = result!.actions['build']!.defaultConfig!;
        expect(config.preCommands, contains('echo "Pre-build"'));
        expect(config.postCommands, contains('echo "Post-build"'));
      });

      test('loads action with project-type specific configuration', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    default:
      commands:
        - dart analyze
    dart_cli:
      commands:
        - dart analyze lib bin
        - dart compile exe
    flutter_app:
      commands:
        - flutter build
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.actions['build']!.typeConfigs, hasLength(2));
        expect(result.actions['build']!.typeConfigs, contains('dart_cli'));
        expect(result.actions['build']!.typeConfigs, contains('flutter_app'));
      });

      test('loads action with custom tags', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    default:
      commands:
        - dart compile exe
      output: dist/
      parallel: true
      timeout: 300
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        final config = result!.actions['build']!.defaultConfig!;
        expect(config.customTags, contains('output'));
        expect(config.customTags['output'], equals('dist/'));
        expect(config.customTags['parallel'], isTrue);
        expect(config.customTags['timeout'], equals(300));
      });

      test('loads multiple actions', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    default:
      commands:
        - dart compile exe
  test:
    default:
      commands:
        - dart test
  deploy:
    skip-types: [dart_package]
    default:
      commands:
        - deploy.sh
  publish:
    applies-to-types: [dart_package]
    default:
      commands:
        - dart pub publish
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.actions, hasLength(4));
        expect(result.actions, contains('build'));
        expect(result.actions, contains('test'));
        expect(result.actions, contains('deploy'));
        expect(result.actions, contains('publish'));
      });
    });

    group('3.2.6 - groups Structure', () {
      test('loads group with projects list', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
groups:
  core:
    projects: [tom_core, tom_build, tom_tools]
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.groups['core']!.projects, hasLength(3));
        expect(result.groups['core']!.projects, contains('tom_core'));
      });

      test('loads group with description', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
groups:
  uam:
    description: UAM application suite
    projects: [tom_uam_client, tom_uam_server]
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(
          result!.groups['uam']!.description,
          equals('UAM application suite'),
        );
      });

      test('loads group with project-info-overrides', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
groups:
  uam:
    projects: [tom_uam_server]
    project-info-overrides:
      cloud-provider: aws
      deployment: kubernetes
      features:
        has-docker: true
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        final overrides = result!.groups['uam']!.projectInfoOverrides;
        expect(overrides, isNotNull);
        expect(overrides!['cloud-provider'], equals('aws'));
        expect(overrides['deployment'], equals('kubernetes'));
      });
    });

    group('3.2.7 - Mode Type Definitions', () {
      test('loads default in mode definitions', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
environment-mode-definitions:
  default:
    description: Default environment
    working-dir: .
  local:
    description: Local dev
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        final envDefs = result!.modeDefinitions['environment'];
        expect(envDefs, isNotNull);
        expect(envDefs!.definitions, contains('default'));
        expect(
          envDefs.definitions['default']!.properties['working-dir'],
          equals('.'),
        );
      });

      test('loads all mode type definitions', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
environment-mode-definitions:
  local:
    description: Local
    
execution-mode-definitions:
  docker:
    image: dart:stable
    
deployment-mode-definitions:
  kubernetes:
    namespace: default
    
cloud-provider-mode-definitions:
  aws:
    region: us-east-1
    
publishing-mode-definitions:
  release:
    publish: true

actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        expect(result!.modeDefinitions, hasLength(5));
        expect(result.modeDefinitions, contains('environment'));
        expect(result.modeDefinitions, contains('execution'));
        expect(result.modeDefinitions, contains('deployment'));
        expect(result.modeDefinitions, contains('cloud-provider'));
        expect(result.modeDefinitions, contains('publishing'));
      });

      test('mode definitions contain properties map', () {
        _createFile(tempDir, 'tom_workspace.yaml', '''
execution-mode-definitions:
  docker:
    description: Run in container
    image: dart:stable
    volumes:
      - ./data:/data
    ports:
      - 8080:8080
    environment:
      DEBUG: "true"
actions:
  build:
    default:
      commands: []
''');
        final result = loader.loadWorkspaceConfig(tempDir.path);
        final execDefs = result!.modeDefinitions['execution'];
        final docker = execDefs!.definitions['docker']!;
        expect(docker.properties['image'], equals('dart:stable'));
        expect(docker.properties['volumes'], isA<List>());
        expect(docker.properties['ports'], isA<List>());
        expect(docker.properties['environment'], isA<Map>());
      });
    });
  });

  // ===========================================================================
  // Section 3.2.2 - Import Path Resolution
  // ===========================================================================

  group('Section 3.2.2 - Import Path Resolution', () {
    test('resolves relative path from same directory', () {
      _createFile(tempDir, 'base.yaml', '''
deps:
  imported: ^1.0.0
''');
      _createFile(tempDir, 'tom_workspace.yaml', '''
imports:
  - base.yaml
actions:
  build:
    default:
      commands: []
''');
      final result = loader.loadWorkspaceWithImports(tempDir.path);
      expect(result!.deps, contains('imported'));
    });

    test('resolves relative path from subdirectory', () {
      _createSubdir(tempDir, 'shared');
      _createFile(tempDir, 'shared/modes.yaml', '''
environment-mode-definitions:
  staging:
    description: Staging env
''');
      _createFile(tempDir, 'tom_workspace.yaml', '''
imports:
  - shared/modes.yaml
actions:
  build:
    default:
      commands: []
''');
      final result = loader.loadWorkspaceWithImports(tempDir.path);
      expect(result!.modeDefinitions, contains('environment'));
    });

    test('merges imports with workspace taking priority', () {
      _createFile(tempDir, 'base.yaml', '''
binaries: base/bin/
deps:
  base_dep: ^1.0.0
  shared_dep: ^1.0.0
''');
      _createFile(tempDir, 'tom_workspace.yaml', '''
imports:
  - base.yaml
binaries: workspace/bin/
deps:
  workspace_dep: ^2.0.0
  shared_dep: ^2.0.0
actions:
  build:
    default:
      commands: []
''');
      final result = loader.loadWorkspaceWithImports(tempDir.path);
      // Workspace value overrides base
      expect(result!.binaries, equals('workspace/bin/'));
      // Both deps present, shared_dep from workspace
      expect(result.deps, contains('base_dep'));
      expect(result.deps, contains('workspace_dep'));
      expect(result.deps['shared_dep'], equals('^2.0.0'));
    });

    test('processes multiple imports in order', () {
      _createFile(tempDir, 'first.yaml', '''
deps:
  first: ^1.0.0
  common: ^1.0.0
''');
      _createFile(tempDir, 'second.yaml', '''
deps:
  second: ^2.0.0
  common: ^2.0.0
''');
      _createFile(tempDir, 'tom_workspace.yaml', '''
imports:
  - first.yaml
  - second.yaml
deps:
  workspace: ^3.0.0
actions:
  build:
    default:
      commands: []
''');
      final result = loader.loadWorkspaceWithImports(tempDir.path);
      expect(result!.deps['first'], equals('^1.0.0'));
      expect(result.deps['second'], equals('^2.0.0'));
      // second.yaml overrides first.yaml
      expect(result.deps['common'], equals('^2.0.0'));
    });
  });

  // ===========================================================================
  // Section 3.3 - tom_project.yaml Schema
  // ===========================================================================

  group('Section 3.3 - tom_project.yaml Schema', () {
    group('3.3.1 - Complete Field Reference', () {
      test('loads build-after list', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
build-after:
  - tom_core
  - tom_core_kernel
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.buildAfter, contains('tom_core'));
        expect(result.buildAfter, contains('tom_core_kernel'));
      });

      test('loads action-order structure', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
action-order:
  deploy-after:
    - tom_shared
  test-after:
    - tom_core
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.actionOrder, contains('deploy-after'));
        expect(
          result.actionOrder['deploy-after'],
          contains('tom_shared'),
        );
      });

      test('loads features map', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
features:
  has-reflection: true
  has-tests: true
  publishable: false
  has-docker: true
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.features, isNotNull);
        expect(result.features!['has-reflection'], isTrue);
        expect(result.features!['publishable'], isFalse);
      });

      test('loads project actions override', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_cli
actions:
  build:
    default:
      pre-commands:
        - echo "Project pre-build"
      commands:
        - dart compile exe bin/main.dart
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.actions, contains('build'));
        expect(
          result.actions['build']!.defaultConfig!.preCommands,
          isNotNull,
        );
      });

      test('loads binaries folder', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_cli
binaries: build/output/
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.binaries, equals('build/output/'));
      });

      test('loads executables list', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_cli
executables:
  - source: bin/main.dart
    output: my_cli
  - source: bin/server.dart
    output: server
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.executables, hasLength(2));
        expect(result.executables[0].source, equals('bin/main.dart'));
        expect(result.executables[0].output, equals('my_cli'));
      });

      test('loads cross-compilation override', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_cli
cross-compilation:
  all-targets: [linux-x64, darwin-arm64]
  build-on:
    linux-x64:
      targets: [linux-x64]
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.crossCompilation, isNotNull);
        expect(
          result.crossCompilation!.allTargets,
          containsAll(['linux-x64', 'darwin-arm64']),
        );
      });

      test('loads project mode definitions override', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
execution-mode-definitions:
  docker:
    image: project-specific:latest
    dockerfile: Dockerfile
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.modeDefinitions, contains('execution'));
      });

      test('loads custom tags in project', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
custom-project-setting: value
my-config:
  port: 8080
  debug: true
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.customTags, contains('custom-project-setting'));
        expect(result.customTags['my-config']['port'], equals(8080));
      });
    });

    group('3.3.2 - action-mode-definitions Structure', () {
      test('loads action-mode-definitions with default', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
action-mode-definitions:
  default:
    environment: local
    execution: local
    deployment: none
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.actionModeDefinitions, isNotNull);
        expect(result.actionModeDefinitions, contains('default'));
      });

      test('loads action-specific mode definitions', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_cli
action-mode-definitions:
  default:
    environment: local
  build:
    environment: local
    execution: docker
  deploy:
    environment: prod
    execution: cloud
    deployment: kubernetes
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.actionModeDefinitions, contains('build'));
        expect(result.actionModeDefinitions, contains('deploy'));
      });
    });

    group('3.3.3 - Special Values', () {
      test('handles null value to unset field', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
binaries: null
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        expect(result!.binaries, isNull);
      });

      test('handles null feature to disable', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
features:
  has-tests: null
  publishable: false
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        // Null feature is interpreted as false (disabled)
        expect(result!.features!['has-tests'], isFalse);
        expect(result.features!['publishable'], isFalse);
      });
    });

    group('3.3.4 - action-order Semantics', () {
      test('action-order replaces build-after for specific action', () {
        _createFile(tempDir, 'tom_project.yaml', '''
type: dart_package
build-after:
  - project_a
  - project_b
action-order:
  deploy-after:
    - project_c
''');
        final result = loader.loadProjectConfig(tempDir.path, 'test');
        // build-after is the default
        expect(result!.buildAfter, containsAll(['project_a', 'project_b']));
        // deploy-after is separate
        expect(result.actionOrder['deploy-after'], contains('project_c'));
        expect(result.actionOrder['deploy-after'], isNot(contains('project_a')));
      });
    });
  });

  // ===========================================================================
  // Error Handling Tests
  // ===========================================================================

  group('Error Handling', () {
    test('returns null when workspace file does not exist', () {
      final result = loader.loadWorkspaceConfig(tempDir.path);
      expect(result, isNull);
    });

    test('returns null when project file does not exist', () {
      final result = loader.loadProjectConfig(tempDir.path, 'test');
      expect(result, isNull);
    });

    test('throws ConfigLoadException on invalid YAML syntax', () {
      _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    - invalid: [syntax
''');
      expect(
        () => loader.loadWorkspaceConfig(tempDir.path),
        throwsA(isA<ConfigLoadException>()),
      );
    });

    test('throws ConfigLoadException when imported file not found', () {
      _createFile(tempDir, 'tom_workspace.yaml', '''
imports:
  - nonexistent.yaml
actions:
  build:
    default:
      commands: []
''');
      expect(
        () => loader.loadWorkspaceWithImports(tempDir.path),
        throwsA(isA<ConfigLoadException>()),
      );
    });

    test('ConfigLoadException contains file path', () {
      _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    - invalid: [syntax
''');
      try {
        loader.loadWorkspaceConfig(tempDir.path);
        fail('Should have thrown');
      } on ConfigLoadException catch (e) {
        expect(e.filePath, contains('tom_workspace.yaml'));
      }
    });

    test('ConfigLoadException contains resolution message', () {
      _createFile(tempDir, 'tom_workspace.yaml', '''
actions:
  build:
    - invalid: [syntax
''');
      try {
        loader.loadWorkspaceConfig(tempDir.path);
        fail('Should have thrown');
      } on ConfigLoadException catch (e) {
        expect(e.resolution, isNotEmpty);
      }
    });
  });
}

// =============================================================================
// Test Helpers
// =============================================================================

void _createFile(Directory dir, String name, String content) {
  final file = File(path.join(dir.path, name));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

void _createSubdir(Directory dir, String name) {
  Directory(path.join(dir.path, name)).createSync(recursive: true);
}
