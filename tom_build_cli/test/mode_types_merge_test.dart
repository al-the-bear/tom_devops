/// Comprehensive tests for all mode types in WorkspaceAnalyzer.
///
/// Tests cover first-level merge for all 5 mode types:
/// 1. environment-mode-definitions
/// 2. execution-mode-definitions
/// 3. deployment-mode-definitions
/// 4. cloud-provider-mode-definitions
/// 5. publishing-mode-definitions

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('Mode Type Merge Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_mode_types_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // =========================================================================
    // environment-mode-definitions tests
    // =========================================================================
    group('environment-mode-definitions', () {
      test('workspace defines local, staging, production modes', () async {
        _createWorkspaceWithModes(tempDir.path, '''
environment-mode-definitions:
  local:
    description: Local development
    working-dir: .
  staging:
    description: Staging environment
    working-dir: staging/
  production:
    description: Production environment
    working-dir: prod/
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final envModes = project['environment-mode-definitions'] as YamlMap;

        expect(envModes.length, equals(3));
        expect(envModes.containsKey('local'), isTrue);
        expect(envModes.containsKey('staging'), isTrue);
        expect(envModes.containsKey('production'), isTrue);
      });

      test('project overrides local mode only', () async {
        _createWorkspaceWithModesAndOverride(tempDir.path,
          workspaceModes: '''
environment-mode-definitions:
  local:
    description: Local development
    port: 3000
  staging:
    description: Staging
    port: 3001
''',
          projectModes: '''
environment-mode-definitions:
  local:
    description: Custom local
    port: 8080
    custom-flag: true
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final envModes = project['environment-mode-definitions'] as YamlMap;

        // local should be overridden
        final localMode = envModes['local'] as YamlMap;
        expect(localMode['port'], equals(8080));
        expect(localMode['custom-flag'], isTrue);
        expect(localMode['description'], equals('Custom local'));

        // staging should be inherited
        final stagingMode = envModes['staging'] as YamlMap;
        expect(stagingMode['port'], equals(3001));
      });

      test('environment mode with variables', () async {
        _createWorkspaceWithModes(tempDir.path, '''
environment-mode-definitions:
  local:
    variables:
      API_URL: http://localhost:3000
      DEBUG: "true"
  production:
    variables:
      API_URL: https://api.example.com
      DEBUG: "false"
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final envModes = project['environment-mode-definitions'] as YamlMap;

        final localVars = (envModes['local'] as YamlMap)['variables'] as YamlMap;
        expect(localVars['API_URL'], equals('http://localhost:3000'));
      });
    });

    // =========================================================================
    // execution-mode-definitions tests
    // =========================================================================
    group('execution-mode-definitions', () {
      test('workspace defines debug, release, profile modes', () async {
        _createWorkspaceWithModes(tempDir.path, '''
execution-mode-definitions:
  debug:
    description: Debug mode
    optimization: none
    asserts: true
  release:
    description: Release mode
    optimization: full
    asserts: false
  profile:
    description: Profile mode
    optimization: partial
    asserts: false
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final execModes = project['execution-mode-definitions'] as YamlMap;

        expect(execModes.length, equals(3));
        expect(execModes.containsKey('debug'), isTrue);
        expect(execModes.containsKey('release'), isTrue);
        expect(execModes.containsKey('profile'), isTrue);
      });

      test('project overrides debug mode optimization', () async {
        _createWorkspaceWithModesAndOverride(tempDir.path,
          workspaceModes: '''
execution-mode-definitions:
  debug:
    optimization: none
  release:
    optimization: full
''',
          projectModes: '''
execution-mode-definitions:
  debug:
    optimization: partial
    custom-debug-option: enabled
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final execModes = project['execution-mode-definitions'] as YamlMap;

        final debugMode = execModes['debug'] as YamlMap;
        expect(debugMode['optimization'], equals('partial'));
        expect(debugMode['custom-debug-option'], equals('enabled'));

        final releaseMode = execModes['release'] as YamlMap;
        expect(releaseMode['optimization'], equals('full'));
      });
    });

    // =========================================================================
    // deployment-mode-definitions tests
    // =========================================================================
    group('deployment-mode-definitions', () {
      test('workspace defines none, kubernetes, docker modes', () async {
        _createWorkspaceWithModes(tempDir.path, '''
deployment-mode-definitions:
  none:
    description: No deployment
  docker:
    description: Docker deployment
    image: my-app
    ports: [8080]
  kubernetes:
    description: Kubernetes deployment
    namespace: default
    replicas: 2
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final deployModes = project['deployment-mode-definitions'] as YamlMap;

        expect(deployModes.length, equals(3));
        expect(deployModes.containsKey('none'), isTrue);
        expect(deployModes.containsKey('docker'), isTrue);
        expect(deployModes.containsKey('kubernetes'), isTrue);
      });

      test('project overrides kubernetes replicas', () async {
        _createWorkspaceWithModesAndOverride(tempDir.path,
          workspaceModes: '''
deployment-mode-definitions:
  none:
    description: No deployment
  kubernetes:
    namespace: default
    replicas: 2
    resources:
      memory: 256Mi
      cpu: 100m
''',
          projectModes: '''
deployment-mode-definitions:
  kubernetes:
    namespace: production
    replicas: 5
    resources:
      memory: 512Mi
      cpu: 200m
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final deployModes = project['deployment-mode-definitions'] as YamlMap;

        final k8s = deployModes['kubernetes'] as YamlMap;
        expect(k8s['namespace'], equals('production'));
        expect(k8s['replicas'], equals(5));

        // none should still be inherited
        expect(deployModes.containsKey('none'), isTrue);
      });

      test('project adds new deployment mode', () async {
        _createWorkspaceWithModesAndOverride(tempDir.path,
          workspaceModes: '''
deployment-mode-definitions:
  none:
    description: No deployment
''',
          projectModes: '''
deployment-mode-definitions:
  custom-deploy:
    description: Custom deployment
    target: custom-server
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final deployModes = project['deployment-mode-definitions'] as YamlMap;

        // Both should be present
        expect(deployModes.containsKey('none'), isTrue);
        expect(deployModes.containsKey('custom-deploy'), isTrue);
        expect((deployModes['custom-deploy'] as YamlMap)['target'], 
            equals('custom-server'));
      });
    });

    // =========================================================================
    // cloud-provider-mode-definitions tests
    // =========================================================================
    group('cloud-provider-mode-definitions', () {
      test('workspace defines aws, gcp, azure modes', () async {
        _createWorkspaceWithModes(tempDir.path, '''
cloud-provider-mode-definitions:
  aws:
    description: Amazon Web Services
    region: us-east-1
    account-id: "123456789"
  gcp:
    description: Google Cloud Platform
    project-id: my-project
    region: us-central1
  azure:
    description: Microsoft Azure
    subscription-id: "abc123"
    resource-group: my-resources
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final cloudModes = project['cloud-provider-mode-definitions'] as YamlMap;

        expect(cloudModes.length, equals(3));
        expect(cloudModes.containsKey('aws'), isTrue);
        expect(cloudModes.containsKey('gcp'), isTrue);
        expect(cloudModes.containsKey('azure'), isTrue);
      });

      test('project overrides aws region', () async {
        _createWorkspaceWithModesAndOverride(tempDir.path,
          workspaceModes: '''
cloud-provider-mode-definitions:
  aws:
    region: us-east-1
    bucket: shared-bucket
  gcp:
    project-id: workspace-project
''',
          projectModes: '''
cloud-provider-mode-definitions:
  aws:
    region: eu-west-1
    bucket: project-bucket
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final cloudModes = project['cloud-provider-mode-definitions'] as YamlMap;

        final aws = cloudModes['aws'] as YamlMap;
        expect(aws['region'], equals('eu-west-1'));
        expect(aws['bucket'], equals('project-bucket'));

        // gcp should be inherited
        final gcp = cloudModes['gcp'] as YamlMap;
        expect(gcp['project-id'], equals('workspace-project'));
      });
    });

    // =========================================================================
    // publishing-mode-definitions tests
    // =========================================================================
    group('publishing-mode-definitions', () {
      test('workspace defines pub.dev, npm, pypi modes', () async {
        _createWorkspaceWithModes(tempDir.path, '''
publishing-mode-definitions:
  pub-dev:
    description: Publish to pub.dev
    registry: https://pub.dev
  npm:
    description: Publish to npm
    registry: https://registry.npmjs.org
  pypi:
    description: Publish to PyPI
    registry: https://pypi.org
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final pubModes = project['publishing-mode-definitions'] as YamlMap;

        expect(pubModes.length, equals(3));
        expect(pubModes.containsKey('pub-dev'), isTrue);
        expect(pubModes.containsKey('npm'), isTrue);
        expect(pubModes.containsKey('pypi'), isTrue);
      });

      test('project overrides pub.dev options', () async {
        _createWorkspaceWithModesAndOverride(tempDir.path,
          workspaceModes: '''
publishing-mode-definitions:
  pub-dev:
    dry-run: true
  private:
    description: Private registry
    url: https://private.example.com
''',
          projectModes: '''
publishing-mode-definitions:
  pub-dev:
    dry-run: false
    force: true
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final pubModes = project['publishing-mode-definitions'] as YamlMap;

        final pubDev = pubModes['pub-dev'] as YamlMap;
        expect(pubDev['dry-run'], isFalse);
        expect(pubDev['force'], isTrue);

        // private should be inherited
        expect(pubModes.containsKey('private'), isTrue);
      });
    });

    // =========================================================================
    // Multiple mode types combined
    // =========================================================================
    group('multiple mode types combined', () {
      test('project can override different modes from different types', () async {
        _createWorkspaceWithModesAndOverride(tempDir.path,
          workspaceModes: '''
environment-mode-definitions:
  local:
    port: 3000
  staging:
    port: 3001
deployment-mode-definitions:
  none:
    description: None
  kubernetes:
    replicas: 2
''',
          projectModes: '''
environment-mode-definitions:
  local:
    port: 8080
deployment-mode-definitions:
  kubernetes:
    replicas: 5
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);

        // Check environment modes
        final envModes = project['environment-mode-definitions'] as YamlMap;
        expect((envModes['local'] as YamlMap)['port'], equals(8080));
        expect((envModes['staging'] as YamlMap)['port'], equals(3001));

        // Check deployment modes
        final deployModes = project['deployment-mode-definitions'] as YamlMap;
        expect(deployModes.containsKey('none'), isTrue);
        expect((deployModes['kubernetes'] as YamlMap)['replicas'], equals(5));
      });

      test('project without mode overrides inherits all mode types', () async {
        _createWorkspaceWithModes(tempDir.path, '''
environment-mode-definitions:
  local:
    port: 3000
execution-mode-definitions:
  debug:
    optimization: none
deployment-mode-definitions:
  kubernetes:
    replicas: 2
cloud-provider-mode-definitions:
  aws:
    region: us-east-1
publishing-mode-definitions:
  pub-dev:
    dry-run: true
''');

        final analyzer = WorkspaceAnalyzer(tempDir.path);
        await analyzer.analyze();

        final yaml = _loadMasterYaml(tempDir.path);
        final project = _getFirstProject(yaml);

        // All mode types should be present
        expect(project.containsKey('environment-mode-definitions'), isTrue);
        expect(project.containsKey('execution-mode-definitions'), isTrue);
        expect(project.containsKey('deployment-mode-definitions'), isTrue);
        expect(project.containsKey('cloud-provider-mode-definitions'), isTrue);
        expect(project.containsKey('publishing-mode-definitions'), isTrue);
      });
    });
  });
}

// =============================================================================
// Helper Functions
// =============================================================================

void _createDartPackage(String basePath, {String name = 'test_package'}) {
  Directory(path.join(basePath, 'lib')).createSync(recursive: true);
  File(path.join(basePath, 'pubspec.yaml')).writeAsStringSync('''
name: $name
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
  File(path.join(basePath, 'lib', '$name.dart')).writeAsStringSync('// Lib');
}

void _createWorkspaceWithModes(String basePath, String modeDefinitions) {
  _createDartPackage(basePath);
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
$modeDefinitions
''');
}

void _createWorkspaceWithModesAndOverride(
  String basePath, {
  required String workspaceModes,
  required String projectModes,
}) {
  _createDartPackage(basePath);
  File(path.join(basePath, 'tom_workspace.yaml')).writeAsStringSync('''
name: test_workspace
$workspaceModes
''');
  File(path.join(basePath, 'tom_project.yaml')).writeAsStringSync(projectModes);
}

YamlMap _loadMasterYaml(String basePath) {
  final masterFile = File(path.join(basePath, '.tom_metadata', 'tom_master.yaml'));
  return loadYaml(masterFile.readAsStringSync()) as YamlMap;
}

YamlMap _getFirstProject(YamlMap yaml) {
  final projects = yaml['projects'] as YamlMap;
  return projects.values.first as YamlMap;
}
