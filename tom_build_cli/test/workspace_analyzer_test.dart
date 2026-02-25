import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('WorkspaceAnalyzer', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_analyzer_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('scanTimestamp', () {
      test('generates tom_master.yaml with scanTimestamp', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final masterFile = File('${tempDir.path}/.tom_metadata/tom_master.yaml');
        expect(masterFile.existsSync(), isTrue, reason: 'tom_master.yaml should be created');

        final content = masterFile.readAsStringSync();
        final yaml = loadYaml(content);

        // Verify scan-timestamp exists and is a valid ISO8601 date
        expect(yaml['scan-timestamp'], isNotNull, reason: 'scan-timestamp should be present');
        final timestamp = yaml['scan-timestamp'] as String;
        expect(
          DateTime.tryParse(timestamp),
          isNotNull,
          reason: 'scanTimestamp should be a valid ISO8601 date: $timestamp',
        );
      });

      test('scanTimestamp is updated on each analysis', () async {
        _createDartPackage(tempDir.path);

        final analyzer1 = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer1.analyze();
        final masterFile = File('${tempDir.path}/.tom_metadata/tom_master.yaml');
        final yaml1 = loadYaml(masterFile.readAsStringSync());
        final timestamp1 = yaml1['scan-timestamp'] as String;

        // Wait a bit and re-analyze with a new analyzer instance
        await Future.delayed(const Duration(milliseconds: 10));
        
        final analyzer2 = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );
        await analyzer2.analyze();

        final yaml2 = loadYaml(masterFile.readAsStringSync());
        final timestamp2 = yaml2['scan-timestamp'] as String;

        expect(timestamp2, isNot(equals(timestamp1)),
            reason: 'scan-timestamp should be updated on re-analysis');
      });
    });

    group('project type detection', () {
      test('detects dart_package project type', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('dart_package'));
      });

      test('detects dart_console project type with bin directory', () async {
        _createDartPackage(tempDir.path);
        // Add bin directory to make it a dart_console
        Directory('${tempDir.path}/bin').createSync();
        File('${tempDir.path}/bin/main.dart').writeAsStringSync('void main() {}');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('dart_console'));
      });

      test('detects dart_console even with empty bin directory', () async {
        _createDartPackage(tempDir.path);
        // Add empty bin directory (with .gitkeep)
        Directory('${tempDir.path}/bin').createSync();
        File('${tempDir.path}/bin/.gitkeep').writeAsStringSync('');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('dart_console'),
            reason: 'Empty bin/ with .gitkeep should still be detected as dart_console');
      });

      test('detects flutter_app project type', () async {
        // Flutter app: lib/ without lib/src/
        Directory('${tempDir.path}/lib').createSync(recursive: true);
        File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: test_flutter_app
version: 1.0.0
environment:
  sdk: ^3.0.0
dependencies:
  flutter:
    sdk: flutter
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('flutter_app'));
      });

      test('detects vscode_extension project type', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-extension",
  "version": "1.0.0",
  "engines": {
    "vscode": "^1.80.0"
  }
}
''');
        Directory('${tempDir.path}/src').createSync();

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('vscode_extension'));
      });

      test('detects typescript project type', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-ts-project",
  "version": "1.0.0"
}
''');
        File('${tempDir.path}/tsconfig.json').writeAsStringSync('{}');
        Directory('${tempDir.path}/src').createSync();

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('typescript_node'));
      });

      test('detects javascript project type', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-js-project",
  "version": "1.0.0"
}
''');
        Directory('${tempDir.path}/src').createSync();

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('javascript'));
      });

      test('detects typescript_react project type', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-ts-react",
  "version": "1.0.0",
  "dependencies": {
    "react": "^18.2.0"
  }
}
''');
        File('${tempDir.path}/tsconfig.json').writeAsStringSync('{}');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('typescript_react'));
      });

      test('detects javascript_react project type', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-js-react",
  "version": "1.0.0",
  "dependencies": {
    "react": "^18.2.0"
  }
}
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('javascript_react'));
      });

      test('detects typescript_vue project type', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-ts-vue",
  "version": "1.0.0",
  "dependencies": {
    "vue": "^3.4.0"
  }
}
''');
        File('${tempDir.path}/tsconfig.json').writeAsStringSync('{}');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('typescript_vue'));
      });

      test('detects javascript_vue project type', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-js-vue",
  "version": "1.0.0",
  "dependencies": {
    "vue": "^3.4.0"
  }
}
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('javascript_vue'));
      });

      test('detects node_cli project type', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-node-cli",
  "version": "1.0.0",
  "bin": {
    "my-cli": "./dist/cli.js"
  }
}
''');
        File('${tempDir.path}/tsconfig.json').writeAsStringSync('{}');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('node_cli'));
      });
    });

    group('Python project type detection', () {
      test('detects python_poetry project type', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[tool.poetry]
name = "test-poetry"
version = "0.1.0"

[tool.poetry.dependencies]
python = "^3.10"
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('python_poetry'));
      });

      test('detects python_uv project type with uv.lock', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-uv"
version = "0.1.0"
''');
        File('${tempDir.path}/uv.lock').writeAsStringSync('');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('python_uv'));
      });

      test('detects python_uv project type with tool.uv section', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-uv"
version = "0.1.0"

[tool.uv]
dev-dependencies = ["pytest"]
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('python_uv'));
      });

      test('detects python_flit project type', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[build-system]
requires = ["flit_core"]
build-backend = "flit_core.buildapi"

[tool.flit.metadata]
module = "test_flit"
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('python_flit'));
      });

      test('detects python_pdm project type', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-pdm"
version = "0.1.0"

[tool.pdm]
distribution = true
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('python_pdm'));
      });

      test('detects python_hatch project type', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-hatch"
version = "0.1.0"

[tool.hatch.build.targets.wheel]
packages = ["src/test_hatch"]
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('python_hatch'));
      });

      test('detects python_setuptools project type', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-setuptools"
version = "0.1.0"

[tool.setuptools]
packages = ["test_setuptools"]
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('python_setuptools'));
      });

      test('detects python_pip project type (PEP 621)', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-pip"
version = "0.1.0"
requires-python = ">=3.10"
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('python_pip'));
      });

      test('detects python_conda project type', () async {
        File('${tempDir.path}/environment.yml').writeAsStringSync('''
name: test-conda
channels:
  - conda-forge
dependencies:
  - python=3.10
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['type'], equals('python_conda'));
      });

      test('extracts name and description from pyproject.toml', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "my-python-package"
description = "A test Python package"
version = "0.1.0"
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['projectName'], equals('my-python-package'));
        expect(project['description'], equals('A test Python package'));
      });
    });

    group('workspace structure', () {
      test('creates .tom_metadata directory', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final metadataDir = Directory('${tempDir.path}/.tom_metadata');
        expect(metadataDir.existsSync(), isTrue);
      });

      test('includes projectName from pubspec when different from folder', () async {
        _createDartPackage(tempDir.path, name: 'my_custom_project_name');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final projects = yaml['projects'] as YamlMap;
        // The project key is the folder name
        // But projectName should contain the name from pubspec.yaml
        final project = projects.values.first as YamlMap;
        expect(project['projectName'], equals('my_custom_project_name'),
            reason: 'projectName should be set from pubspec.yaml when different from folder name');
      });

      test('includes workspace name in tom_master.yaml', () async {
        _createDartPackage(tempDir.path);

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        expect(yaml['name'], isNotNull);
      });
    });

    group('multi-project workspace', () {
      test('detects multiple projects in workspace', () async {
        // Create two projects in subdirectories
        final project1Dir = Directory('${tempDir.path}/project_one');
        final project2Dir = Directory('${tempDir.path}/project_two');

        _createDartPackage(project1Dir.path, name: 'project_one');
        _createDartPackage(project2Dir.path, name: 'project_two');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final projects = yaml['projects'] as YamlMap;
        expect(projects.length, equals(2));
        expect(projects.containsKey('project_one'), isTrue);
        expect(projects.containsKey('project_two'), isTrue);
      });

      test('excludes test projects with zom_ prefix', () async {
        _createDartPackage('${tempDir.path}/real_project', name: 'real_project');
        _createDartPackage('${tempDir.path}/zom_test_project', name: 'zom_test_project');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final projects = yaml['projects'] as YamlMap;
        expect(projects.length, equals(1));
        expect(projects.containsKey('real_project'), isTrue);
        expect(projects.containsKey('zom_test_project'), isFalse);
      });
    });

    group('JS/TS feature detection', () {
      test('detects has-typescript feature', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-ts",
  "version": "1.0.0"
}
''');
        File('${tempDir.path}/tsconfig.json').writeAsStringSync('{}');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final features = project['features'] as YamlMap;
        expect(features['has-typescript'], isTrue);
      });

      test('detects is-esm feature', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-esm",
  "version": "1.0.0",
  "type": "module"
}
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final features = project['features'] as YamlMap;
        expect(features['is-esm'], isTrue);
      });

      test('detects has-lint feature with eslint', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-lint",
  "version": "1.0.0",
  "devDependencies": {
    "eslint": "^8.0.0"
  }
}
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final features = project['features'] as YamlMap;
        expect(features['has-lint'], isTrue);
      });

      test('detects has-bundler feature with vite', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-bundler",
  "version": "1.0.0",
  "devDependencies": {
    "vite": "^5.0.0"
  }
}
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final features = project['features'] as YamlMap;
        expect(features['has-bundler'], isTrue);
      });

      test('detects is-monorepo feature with workspaces', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-monorepo",
  "version": "1.0.0",
  "workspaces": ["packages/*"]
}
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final features = project['features'] as YamlMap;
        expect(features['is-monorepo'], isTrue);
      });
    });

    group('Python feature detection', () {
      test('detects has-tests feature with tests directory', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-python"
version = "0.1.0"
''');
        Directory('${tempDir.path}/tests').createSync();

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final features = project['features'] as YamlMap;
        expect(features['has-tests'], isTrue);
      });

      test('detects has-lint feature with ruff', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-python"
version = "0.1.0"

[tool.ruff]
line-length = 88
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final features = project['features'] as YamlMap;
        expect(features['has-lint'], isTrue);
      });

      test('detects has-type-hints feature with mypy', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-python"
version = "0.1.0"

[tool.mypy]
strict = true
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final features = project['features'] as YamlMap;
        expect(features['has-type-hints'], isTrue);
      });

      test('detects has-cli feature with project.scripts', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-python"
version = "0.1.0"

[project.scripts]
my-cli = "my_package.cli:main"
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        final features = project['features'] as YamlMap;
        expect(features['has-cli'], isTrue);
      });
    });

    group('manifest metadata', () {
      test('includes packageJson for JS projects', () async {
        File('${tempDir.path}/package.json').writeAsStringSync('''
{
  "name": "test-js",
  "version": "1.0.0",
  "description": "A test project",
  "main": "src/index.js",
  "scripts": {
    "test": "jest"
  }
}
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['packageJson'], isNotNull);
        final packageJson = project['packageJson'] as YamlMap;
        expect(packageJson['name'], equals('test-js'));
        expect(packageJson['version'], equals('1.0.0'));
      });

      test('includes pyproject for Python projects', () async {
        File('${tempDir.path}/pyproject.toml').writeAsStringSync('''
[project]
name = "test-python"
version = "0.1.0"
description = "A test Python project"
requires-python = ">=3.10"
''');

        final analyzer = WorkspaceAnalyzer(
          tempDir.path,
          options: AnalyzerOptions.production,
        );

        await analyzer.analyze();

        final yaml = _loadIndexYaml(tempDir.path);
        final project = _getFirstProject(yaml);
        expect(project['pyproject'], isNotNull);
      });
    });
  });
}

/// Creates a minimal Dart package structure
void _createDartPackage(String path, {String name = 'test_package'}) {
  Directory('$path/lib/src').createSync(recursive: true);
  File('$path/pubspec.yaml').writeAsStringSync('''
name: $name
version: 1.0.0
environment:
  sdk: ^3.0.0
''');
}

/// Loads the tom_master.yaml file from the workspace
YamlMap _loadIndexYaml(String workspacePath) {
  final masterFile = File('$workspacePath/.tom_metadata/tom_master.yaml');
  return loadYaml(masterFile.readAsStringSync()) as YamlMap;
}

/// Gets the first project from the workspace
YamlMap _getFirstProject(YamlMap yaml) {
  final projects = yaml['projects'] as YamlMap;
  return projects.values.first as YamlMap;
}
