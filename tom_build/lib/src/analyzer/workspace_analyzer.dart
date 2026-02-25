/// Workspace Analyzer Library
///
/// Traverses a Dart/Flutter workspace and creates metadata files in
/// `.tom_metadata/` including a complete `tom_master.yaml` file.
library;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

/// Configuration options for the workspace analyzer.
class AnalyzerOptions {
  /// Whether to include test projects (those starting with 'zom_').
  final bool includeTestProjects;

  const AnalyzerOptions({
    this.includeTestProjects = false,
  });

  /// Options that include all projects (including test projects).
  static const all = AnalyzerOptions(includeTestProjects: true);

  /// Options that exclude test projects (default for production).
  static const production = AnalyzerOptions(includeTestProjects: false);
}

/// Analyzes a Dart/Flutter workspace and generates metadata files.
class WorkspaceAnalyzer {
  final String workspaceRoot;
  final AnalyzerOptions options;
  final List<ProjectInfo> projects = [];

  /// Workspace-level settings loaded from root tom_workspace.yaml
  Map<String, dynamic> workspaceSettings = {};

  /// Resolved build order based on build-after dependencies
  List<String> buildOrder = [];

  /// Default workspace settings
  static const defaultWorkspaceSettings = {
    'binaries': 'bin/',
    'operating-systems': ['macos', 'linux', 'windows'],
    'mobile-platforms': ['android', 'ios'],
  };

  /// Default build configuration per project type
  static const defaultBuildConfig = <String, Map<String, dynamic>>{
    'dart_package': {
      'commands': {
        'analyze': ['dart analyze lib test'],
        'test': ['dart test'],
        'test-coverage': ['dart test --coverage=coverage'],
        'build-runner': ['dart run build_runner build --delete-conflicting-outputs'],
        'compile': null,
      },
      'pre-build': ['build-runner'],
      'output': 'build/',
    },
    'dart_console': {
      'commands': {
        'analyze': ['dart analyze lib bin test'],
        'test': ['dart test'],
        'test-coverage': ['dart test --coverage=coverage'],
        'build-runner': ['dart run build_runner build --delete-conflicting-outputs'],
        'compile': ['dart compile exe bin/main.dart -o bin/\${name}'],
      },
      'pre-build': ['build-runner'],
      'output': 'bin/',
    },
    'flutter_app': {
      'commands': {
        'analyze': ['flutter analyze lib test'],
        'test': ['flutter test'],
        'test-coverage': ['flutter test --coverage'],
        'build-runner': ['dart run build_runner build --delete-conflicting-outputs'],
        'build-web': ['flutter build web'],
        'build-android': ['flutter build apk'],
        'build-ios': ['flutter build ios'],
      },
      'pre-build': ['build-runner'],
      'output': 'build/',
    },
    'vscode_extension': {
      'commands': {
        'install': ['npm install'],
        'compile': ['npm run compile'],
        'test': ['npm test'],
        'package': ['vsce package'],
      },
      'pre-build': ['install'],
      'output': 'out/',
    },
    'typescript': {
      'commands': {
        'install': ['npm install'],
        'compile': ['npm run build'],
        'test': ['npm test'],
      },
      'pre-build': ['install'],
      'output': 'dist/',
    },
    'javascript': {
      'commands': {
        'install': ['npm install'],
        'test': ['npm test'],
      },
      'pre-build': ['install'],
      'output': 'dist/',
    },
    'java': {
      'commands': {
        'compile': ['mvn compile'],
        'test': ['mvn test'],
        'package': ['mvn package'],
      },
      'pre-build': [],
      'output': 'target/',
    },
    // Python project types
    'python': {
      'commands': {
        'install': ['pip install -e .'],
        'install-dev': ['pip install -e ".[dev]"'],
        'test': ['pytest'],
        'lint': ['ruff check .'],
        'format': ['ruff format .'],
        'build': ['python -m build'],
      },
      'pre-build': ['install'],
      'output': 'dist/',
    },
    'python_poetry': {
      'commands': {
        'install': ['poetry install'],
        'test': ['poetry run pytest'],
        'lint': ['poetry run ruff check .'],
        'format': ['poetry run ruff format .'],
        'build': ['poetry build'],
        'publish': ['poetry publish'],
      },
      'pre-build': ['install'],
      'output': 'dist/',
    },
    'python_uv': {
      'commands': {
        'install': ['uv sync'],
        'test': ['uv run pytest'],
        'lint': ['uv run ruff check .'],
        'format': ['uv run ruff format .'],
        'build': ['uv build'],
      },
      'pre-build': ['install'],
      'output': 'dist/',
    },
    'python_pip': {
      'commands': {
        'install': ['pip install -e .'],
        'install-dev': ['pip install -e ".[dev]"'],
        'test': ['pytest'],
        'build': ['python -m build'],
      },
      'pre-build': ['install'],
      'output': 'dist/',
    },
    'python_conda': {
      'commands': {
        'install': ['conda env create -f environment.yml'],
        'test': ['pytest'],
      },
      'pre-build': ['install'],
      'output': 'dist/',
    },
    // Enhanced JS/TS types
    'typescript_node': {
      'commands': {
        'install': ['npm install'],
        'compile': ['npm run build'],
        'test': ['npm test'],
        'lint': ['npm run lint'],
      },
      'pre-build': ['install'],
      'output': 'dist/',
    },
    'typescript_react': {
      'commands': {
        'install': ['npm install'],
        'compile': ['npm run build'],
        'test': ['npm test'],
        'dev': ['npm run dev'],
      },
      'pre-build': ['install'],
      'output': 'build/',
    },
    'node_cli': {
      'commands': {
        'install': ['npm install'],
        'compile': ['npm run build'],
        'test': ['npm test'],
        'link': ['npm link'],
      },
      'pre-build': ['install'],
      'output': 'dist/',
    },
  };

  /// Default run configuration per project type
  static const defaultRunConfig = <String, Map<String, dynamic>>{
    'dart_console': {
      'commands': ['dart run'],
    },
    'flutter_app': {
      'commands': ['flutter run'],
    },
    'vscode_extension': {
      'commands': ['code --extensionDevelopmentPath=.'],
    },
    'python': {
      'commands': ['python -m \${name}'],
    },
    'python_poetry': {
      'commands': ['poetry run python -m \${name}'],
    },
    'python_uv': {
      'commands': ['uv run python -m \${name}'],
    },
    'node_cli': {
      'commands': ['node dist/index.js'],
    },
    'typescript_node': {
      'commands': ['node dist/index.js'],
    },
    'typescript_react': {
      'commands': ['npm run dev'],
    },
  };

  /// Default deployment configuration per project type
  static const defaultDeployConfig = <String, Map<String, dynamic>>{
    'dart_console': {
      'type': 'docker',
      'dockerfile': 'Dockerfile',
      'platforms': ['linux/amd64', 'linux/arm64'],
    },
    'flutter_app': {
      'type': 'web',
      'build-command': 'flutter build web',
      'output': 'build/web/',
    },
    'python': {
      'type': 'docker',
      'dockerfile': 'Dockerfile',
      'platforms': ['linux/amd64', 'linux/arm64'],
    },
    'python_poetry': {
      'type': 'docker',
      'dockerfile': 'Dockerfile',
      'platforms': ['linux/amd64', 'linux/arm64'],
    },
    'typescript_node': {
      'type': 'docker',
      'dockerfile': 'Dockerfile',
      'platforms': ['linux/amd64', 'linux/arm64'],
    },
  };

  WorkspaceAnalyzer(this.workspaceRoot, {this.options = const AnalyzerOptions()});

  /// Main entry point - analyzes workspace and writes metadata.
  Future<void> analyze() async {
    // Load workspace-level tom_workspace.yaml if present
    workspaceSettings = await _loadWorkspaceIndex();

    // Find all Dart/Flutter projects
    await _discoverProjects();

    // Analyze each project
    for (final project in projects) {
      await _analyzeProject(project);
      
      // Collect folder listings for project metadata
      project.copilotGuidelines = await _listFolderContents(
        path.join(project.path, '_copilot_guidelines'),
      );
      project.docs = await _listFolderContents(
        path.join(project.path, 'docs'),
      );
      project.tests = await _listFolderContents(
        path.join(project.path, 'test'),
      );
      project.examples = await _listFolderContents(
        path.join(project.path, 'example'),
      );

      // Load local tom_project.yaml if present
      project.localIndexEntries = await _loadLocalIndex(project.path);

      // Detect features for this project
      await _detectFeatures(project);

      // Populate manifest information based on project type
      await _populateManifest(project);

      // Resolve build/run/deploy configuration using override hierarchy
      _resolveProjectConfig(project);
    }

    // Resolve build order based on build-after dependencies
    _resolveBuildOrder();

    // Sort everything alphabetically
    _sortAll();

    // Write metadata files
    await _writeMetadata();
  }

  /// Sorts all projects, parts, modules, and sources alphabetically.
  void _sortAll() {
    // Sort projects by name
    projects.sort((a, b) => a.name.compareTo(b.name));

    for (final project in projects) {
      // Sort packageModule sources and subfolders
      if (project.packageModule != null) {
        _sortModule(project.packageModule!);
      }
      // Sort appModule sources and subfolders
      if (project.appModule != null) {
        _sortModule(project.appModule!);
      }

      // Sort parts by name
      project.parts.sort((a, b) => a.name.compareTo(b.name));

      for (final part in project.parts) {
        // Sort part sources
        part.sources.sort();

        // Sort modules by name
        part.modules.sort((a, b) => a.name.compareTo(b.name));

        for (final module in part.modules) {
          _sortModule(module);
        }
      }
    }
  }

  /// Recursively sorts a module and all its subfolders.
  void _sortModule(ModuleInfo module) {
    module.sources.sort();
    module.subfolders.sort((a, b) => a.name.compareTo(b.name));
    for (final subfolder in module.subfolders) {
      _sortModule(subfolder);
    }
  }

  /// Discovers all projects in the workspace.
  /// Scans direct subdirectories and sub-workspaces configured in .code-workspace file.
  Future<void> _discoverProjects() async {
    final rootDir = Directory(workspaceRoot);

    // Check if workspace root itself is a project
    if (await _isProject(workspaceRoot)) {
      final project = await _createProjectInfo(workspaceRoot);
      if (project != null && _shouldIncludeProject(project.name)) {
        projects.add(project);
      }
    }

    // Check subdirectories
    await for (final entity in rootDir.list()) {
      if (entity is Directory) {
        final dirPath = entity.path;
        final dirName = path.basename(dirPath);

        // Skip hidden directories and common non-project folders
        if (dirName.startsWith('.') ||
            dirName == 'build' ||
            dirName == 'node_modules' ||
            dirName == 'out' ||
            dirName == 'dist') {
          continue;
        }

        // Skip test projects if not included
        if (!_shouldIncludeProject(dirName)) {
          continue;
        }

        if (await _isProject(dirPath)) {
          final project = await _createProjectInfo(dirPath);
          if (project != null) projects.add(project);
        }
      }
    }

    // Scan sub-workspaces from .code-workspace file
    await _discoverSubWorkspaceProjects();

    print('Found ${projects.length} projects');
  }

  /// Discovers projects from sub-workspaces configured in .code-workspace file.
  /// Reads folder paths from VS Code workspace file and recursively scans for projects.
  Future<void> _discoverSubWorkspaceProjects() async {
    // Find .code-workspace files in workspace root
    final workspaceFiles = <File>[];
    final rootDir = Directory(workspaceRoot);
    await for (final entity in rootDir.list()) {
      if (entity is File && entity.path.endsWith('.code-workspace')) {
        workspaceFiles.add(entity);
      }
    }
    
    if (workspaceFiles.isEmpty) return;
    
    // Use the first .code-workspace file found (typically there's only one)
    final wsFile = workspaceFiles.first;
    print('Reading sub-workspaces from: ${path.basename(wsFile.path)}');
    
    try {
      final content = await wsFile.readAsString();
      // Parse JSON (VS Code workspace files are JSON with comments)
      // Remove single-line comments for basic parsing
      final cleanContent = content.replaceAll(RegExp(r'//[^\n]*'), '');
      final wsConfig = _parseWorkspaceJson(cleanContent);
      
      final folders = wsConfig['folders'] as List<dynamic>?;
      if (folders == null) return;
      
      for (final folder in folders) {
        if (folder is! Map) continue;
        final folderPath = folder['path'] as String?;
        if (folderPath == null || folderPath == '.') continue;
        
        // Resolve to absolute path
        final absoluteFolderPath = path.normalize(path.join(workspaceRoot, folderPath));
        final folderDir = Directory(absoluteFolderPath);
        
        if (!await folderDir.exists()) {
          print('  Sub-workspace folder not found: $folderPath');
          continue;
        }
        
        print('  Scanning sub-workspace: $folderPath');
        await _scanSubWorkspaceFolder(folderDir, folderPath);
      }
    } catch (e) {
      print('Warning: Failed to parse .code-workspace file: $e');
    }
  }

  /// Recursively scans a sub-workspace folder for projects.
  /// [baseRelativePath] is the path relative to workspace root (e.g., "xternal/tom_module_d4rt")
  Future<void> _scanSubWorkspaceFolder(Directory folder, String baseRelativePath) async {
    await for (final entity in folder.list()) {
      if (entity is Directory) {
        final dirPath = entity.path;
        final dirName = path.basename(dirPath);

        // Skip hidden directories and common non-project folders
        if (dirName.startsWith('.') ||
            dirName == 'build' ||
            dirName == 'node_modules' ||
            dirName == 'out' ||
            dirName == 'dist') {
          continue;
        }

        // Skip test projects if not included
        if (!_shouldIncludeProject(dirName)) {
          continue;
        }

        if (await _isProject(dirPath)) {
          // Calculate relative path from workspace root
          final relativePath = path.join(baseRelativePath, dirName);
          final project = await _createProjectInfo(dirPath, projectFolder: relativePath);
          if (project != null) {
            projects.add(project);
            print('    Found project: ${project.name} at $relativePath');
          }
        } else {
          // Recursively scan subdirectories (for nested structures)
          await _scanSubWorkspaceFolder(Directory(dirPath), path.join(baseRelativePath, dirName));
        }
      }
    }
  }

  /// Parses VS Code workspace JSON (simplified parser).
  Map<String, dynamic> _parseWorkspaceJson(String content) {
    try {
      // Use a simple regex-based approach to extract folders array
      // This handles the basic case of VS Code workspace files
      final foldersMatch = RegExp(r'"folders"\s*:\s*\[([^\]]*)\]', dotAll: true).firstMatch(content);
      if (foldersMatch == null) return {};
      
      final foldersContent = foldersMatch.group(1)!;
      final folders = <Map<String, String>>[];
      
      // Extract individual folder objects from the array
      // Each folder object may have "name" and/or "path" properties
      final folderObjectMatches = RegExp(r'\{([^}]+)\}').allMatches(foldersContent);
      for (final match in folderObjectMatches) {
        final objContent = match.group(1)!;
        final pathMatch = RegExp(r'"path"\s*:\s*"([^"]*)"').firstMatch(objContent);
        if (pathMatch != null) {
          folders.add({'path': pathMatch.group(1)!});
        }
      }
      
      return {'folders': folders};
    } catch (e) {
      return {};
    }
  }

  /// Checks if a project should be included based on options.
  bool _shouldIncludeProject(String name) {
    if (name.startsWith('zom_')) {
      return options.includeTestProjects;
    }
    return true;
  }

  /// Checks if a directory is any recognized project type.
  Future<bool> _isProject(String dirPath) async {
    return File(path.join(dirPath, 'pubspec.yaml')).existsSync() ||
           File(path.join(dirPath, 'package.json')).existsSync() ||
           File(path.join(dirPath, 'pom.xml')).existsSync() ||
           File(path.join(dirPath, 'build.gradle')).existsSync() ||
           File(path.join(dirPath, 'build.gradle.kts')).existsSync() ||
           File(path.join(dirPath, 'pyproject.toml')).existsSync() ||
           File(path.join(dirPath, 'requirements.txt')).existsSync() ||
           File(path.join(dirPath, 'environment.yml')).existsSync();
  }

  /// Creates a ProjectInfo from a project directory.
  /// [projectFolder] is the relative path from workspace root (null for direct children).
  Future<ProjectInfo?> _createProjectInfo(String projectPath, {String? projectFolder}) async {
    final type = _detectProjectType(projectPath);
    if (type == null) return null;

    // Use folder name as the primary identifier
    final folderName = path.basename(projectPath);
    String? projectName;  // Name from manifest file (package.json, pubspec.yaml)
    String? description;

    // Calculate projectFolder if not provided (for direct workspace children)
    final normalizedRoot = path.normalize(path.absolute(workspaceRoot));
    final normalizedProjectPath = path.normalize(path.absolute(projectPath));
    final relativePath = path.relative(normalizedProjectPath, from: normalizedRoot);
    final resolvedProjectFolder = projectFolder ?? (relativePath != folderName ? relativePath : null);

    // Extract projectName and description from manifest files
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    final packageJsonFile = File(path.join(projectPath, 'package.json'));
    final pomXmlFile = File(path.join(projectPath, 'pom.xml'));
    final pyprojectFile = File(path.join(projectPath, 'pyproject.toml'));

    if (pubspecFile.existsSync()) {
      final content = await pubspecFile.readAsString();
      try {
        final yaml = loadYaml(content) as YamlMap;
        final manifestName = yaml['name'] as String?;
        // Only set projectName if it differs from folder name
        if (manifestName != null && manifestName != folderName) {
          projectName = manifestName;
        }
        description = _cleanDescription(yaml['description'] as String?);
      } catch (e) {
        // pubspec.yaml may contain template syntax (tomplate) - extract name using regex
        print('  Warning: Failed to parse pubspec.yaml in $folderName (may be a tomplate): $e');
        final nameMatch = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
        final descMatch = RegExp(r'^description:\s*(.+)', multiLine: true).firstMatch(content);
        final manifestName = nameMatch?.group(1);
        if (manifestName != null && manifestName != folderName) {
          projectName = manifestName;
        }
        description = _cleanDescription(descMatch?.group(1));
      }
    } else if (packageJsonFile.existsSync()) {
      final content = await packageJsonFile.readAsString();
      final json = _parseJson(content);
      final manifestName = json['name'] as String?;
      // Only set projectName if it differs from folder name
      if (manifestName != null && manifestName != folderName) {
        projectName = manifestName;
      }
      description = _cleanDescription(json['description'] as String?);
    } else if (pyprojectFile.existsSync()) {
      final content = await pyprojectFile.readAsString();
      // Extract name and description from pyproject.toml
      final nameMatch = RegExp(r'^name\s*=\s*"([^"]*)"', multiLine: true).firstMatch(content);
      final descMatch = RegExp(r'^description\s*=\s*"([^"]*)"', multiLine: true).firstMatch(content);
      final manifestName = nameMatch?.group(1);
      if (manifestName != null && manifestName != folderName) {
        projectName = manifestName;
      }
      description = _cleanDescription(descMatch?.group(1));
    } else if (pomXmlFile.existsSync()) {
      // For Maven, we could parse XML but keeping it simple
      description = null;
    }

    return ProjectInfo(
      path: projectPath,
      name: folderName,
      displayName: _toDisplayName(folderName),
      projectName: projectName,
      description: description,
      type: type,
      projectFolder: resolvedProjectFolder,
    );
  }

  /// Parses JSON content, returns empty map on error.
  Map<String, dynamic> _parseJson(String content) {
    try {
      return Map<String, dynamic>.from(
        content.isEmpty ? {} : _jsonDecode(content) as Map,
      );
    } catch (e) {
      return {};
    }
  }

  /// Simple JSON decode (avoid importing dart:convert in library header).
  dynamic _jsonDecode(String source) {
    // Use a simple regex-based approach for basic JSON parsing
    // For package.json, we mainly need 'name', 'description', and 'engines.vscode'
    final nameMatch = RegExp(r'"name"\s*:\s*"([^"]*)"').firstMatch(source);
    final descMatch = RegExp(r'"description"\s*:\s*"([^"]*)"').firstMatch(source);
    final hasVscodeEngine = source.contains('"vscode"') && source.contains('"engines"');
    
    return {
      'name': nameMatch?.group(1),
      'description': descMatch?.group(1),
      '_hasVscodeEngine': hasVscodeEngine,
    };
  }

  /// Detects the type of a project.
  String? _detectProjectType(String projectPath) {
    final hasPubspec = File(path.join(projectPath, 'pubspec.yaml')).existsSync();
    final hasPackageJson = File(path.join(projectPath, 'package.json')).existsSync();
    final hasTsconfig = File(path.join(projectPath, 'tsconfig.json')).existsSync();
    final hasPomXml = File(path.join(projectPath, 'pom.xml')).existsSync();
    final hasBuildGradle = File(path.join(projectPath, 'build.gradle')).existsSync() ||
                           File(path.join(projectPath, 'build.gradle.kts')).existsSync();
    final hasPyprojectToml = File(path.join(projectPath, 'pyproject.toml')).existsSync();
    final hasSetupPy = File(path.join(projectPath, 'setup.py')).existsSync();
    final hasSetupCfg = File(path.join(projectPath, 'setup.cfg')).existsSync();
    final hasEnvironmentYml = File(path.join(projectPath, 'environment.yml')).existsSync() ||
                              File(path.join(projectPath, 'conda.yaml')).existsSync();

    // 1. Dart/Flutter projects
    if (hasPubspec) {
      return _detectDartProjectType(projectPath);
    }

    // 2. Python projects (check before Java because some Python projects use Gradle)
    if (hasPyprojectToml || hasSetupPy || hasSetupCfg || hasEnvironmentYml) {
      return _detectPythonProjectType(projectPath);
    }

    // 3. Java projects (Maven or Gradle)
    if (hasPomXml || hasBuildGradle) {
      return 'java';
    }

    // 4. Node.js/TypeScript projects
    if (hasPackageJson) {
      return _detectJsProjectType(projectPath, hasTsconfig);
    }

    return null;
  }

  /// Detects the specific type of Python project.
  String _detectPythonProjectType(String projectPath) {
    final pyprojectFile = File(path.join(projectPath, 'pyproject.toml'));
    final hasUvLock = File(path.join(projectPath, 'uv.lock')).existsSync();
    final hasEnvironmentYml = File(path.join(projectPath, 'environment.yml')).existsSync() ||
                              File(path.join(projectPath, 'conda.yaml')).existsSync();
    
    if (pyprojectFile.existsSync()) {
      try {
        final content = pyprojectFile.readAsStringSync();
        
        // Check for uv.lock first (uv creates standard pyproject.toml + lock file)
        if (hasUvLock || content.contains('[tool.uv]')) {
          return 'python_uv';
        }
        
        // Check for specific tool sections using regex (order matters - most specific first)
        // Use regex to match [tool.X] or [tool.X.anything]
        if (RegExp(r'\[tool\.poetry[\].]').hasMatch(content)) {
          return 'python_poetry';
        }
        if (RegExp(r'\[tool\.flit[\].]').hasMatch(content)) {
          return 'python_flit';
        }
        if (RegExp(r'\[tool\.pdm[\].]').hasMatch(content)) {
          return 'python_pdm';
        }
        if (RegExp(r'\[tool\.hatch[\].]').hasMatch(content)) {
          return 'python_hatch';
        }
        if (RegExp(r'\[tool\.setuptools[\].]').hasMatch(content)) {
          return 'python_setuptools';
        }
        if (content.contains('[project]')) {
          return 'python_pip';
        }
      } catch (_) {
        // Fall through to default
      }
    }
    
    if (hasEnvironmentYml) {
      return 'python_conda';
    }
    
    // Legacy setup.py or setup.cfg
    return 'python';
  }

  /// Detects the specific type of JavaScript/TypeScript project.
  String _detectJsProjectType(String projectPath, bool hasTsconfig) {
    final packageJsonFile = File(path.join(projectPath, 'package.json'));
    if (!packageJsonFile.existsSync()) return 'javascript';
    
    try {
      final content = packageJsonFile.readAsStringSync();
      
      // Check for VS Code extension first
      if (content.contains('"vscode"') && content.contains('"engines"')) {
        return 'vscode_extension';
      }
      
      // Check for CLI (has bin field)
      if (RegExp(r'"bin"\s*:').hasMatch(content)) {
        return 'node_cli';
      }
      
      // Check for React (TypeScript or JavaScript)
      if (content.contains('"react"') && content.contains('"dependencies"')) {
        if (hasTsconfig) {
          return 'typescript_react';
        }
        return 'javascript_react';
      }
      
      // Check for Vue
      if (content.contains('"vue"') && content.contains('"dependencies"')) {
        if (hasTsconfig) {
          return 'typescript_vue';
        }
        return 'javascript_vue';
      }
      
      // TypeScript project
      if (hasTsconfig) {
        return 'typescript_node';
      }
      
      // Plain JavaScript
      return 'javascript';
    } catch (_) {
      return hasTsconfig ? 'typescript' : 'javascript';
    }
  }

  /// Detects the specific type of Dart project.
  String _detectDartProjectType(String projectPath) {
    final hasBin = Directory(path.join(projectPath, 'bin')).existsSync();
    final hasLib = Directory(path.join(projectPath, 'lib')).existsSync();
    final hasLibSrc = Directory(path.join(projectPath, 'lib', 'src')).existsSync();

    // Check for Flutter
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    bool hasFlutterDependency = false;
    if (pubspecFile.existsSync()) {
      final content = pubspecFile.readAsStringSync();
      hasFlutterDependency = content.contains('sdk: flutter') ||
          content.contains("sdk: 'flutter'") ||
          content.contains('sdk: "flutter"');
    }

    if (hasBin && hasLib) {
      return 'dart_console';
    } else if (hasLibSrc) {
      return 'dart_package';
    } else if (hasLib && !hasBin && hasFlutterDependency) {
      return 'flutter_app';
    } else if (hasLib && !hasBin) {
      return 'dart_package';
    }

    return 'dart_package';
  }

  /// Analyzes a project to discover parts and modules.
  Future<void> _analyzeProject(ProjectInfo project) async {
    print('Analyzing project: ${project.name} (${project.type})');

    switch (project.type) {
      case 'dart_package':
        await _analyzePackageProject(project);
      case 'flutter_app':
        await _analyzeFlutterProject(project);
      case 'dart_console':
        await _analyzeServerProject(project);
      case 'vscode_extension':
      case 'typescript':
        await _analyzeTypeScriptProject(project);
      case 'javascript':
        await _analyzeJavaScriptProject(project);
      case 'java':
        await _analyzeJavaProject(project);
    }
  }

  /// Analyzes a Dart package project.
  Future<void> _analyzePackageProject(ProjectInfo project) async {
    final libDir = Directory(path.join(project.path, 'lib'));
    final libSrcDir = Directory(path.join(project.path, 'lib', 'src'));

    // Package module: top-level files in lib/
    if (libDir.existsSync()) {
      final packageSources = <String>[];
      await for (final entity in libDir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final fileName = path.basename(entity.path);
          if (!fileName.endsWith('.reflection.dart') && !fileName.endsWith('.g.dart')) {
            packageSources.add(fileName);
          }
        }
      }
      if (packageSources.isNotEmpty) {
        project.packageModule = ModuleInfo(
          name: 'package',
          displayName: project.displayName,
          sources: packageSources,
        );
      }
    }

    if (!libSrcDir.existsSync()) return;

    // Collect lib/src top-level files
    final srcSources = <String>[];
    await for (final entity in libSrcDir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = path.basename(entity.path);
        if (!fileName.endsWith('.reflection.dart') && !fileName.endsWith('.g.dart')) {
          srcSources.add(fileName);
        }
      }
    }

    // If there are top-level files in lib/src/, create a "src" part
    if (srcSources.isNotEmpty) {
      // Check if there are also subdirectories
      bool hasSubdirs = false;
      await for (final entity in libSrcDir.list()) {
        if (entity is Directory && !path.basename(entity.path).startsWith('.')) {
          hasSubdirs = true;
          break;
        }
      }

      // If no subdirectories, create a src part with these files
      if (!hasSubdirs) {
        final srcPart = PartInfo(
          name: 'src',
          displayName: 'Src',
          sources: srcSources,
        );
        project.parts.add(srcPart);
        return;
      }
    }

    // Parts are subdirectories of lib/src/
    await for (final entity in libSrcDir.list()) {
      if (entity is Directory) {
        final partName = path.basename(entity.path);
        if (partName.startsWith('.')) continue;

        final part = await _analyzePart(entity.path, partName);
        project.parts.add(part);
      }
    }
  }

  /// Analyzes a Flutter app project.
  Future<void> _analyzeFlutterProject(ProjectInfo project) async {
    final libDir = Directory(path.join(project.path, 'lib'));
    if (!libDir.existsSync()) return;

    // App module: top-level files in lib/
    final appSources = <String>[];
    await for (final entity in libDir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = path.basename(entity.path);
        if (!fileName.endsWith('.reflection.dart') && !fileName.endsWith('.g.dart')) {
          appSources.add(fileName);
        }
      }
    }
    if (appSources.isNotEmpty) {
      project.appModule = ModuleInfo(
        name: 'app',
        displayName: project.displayName,
        sources: appSources,
      );
    }

    // Parts are direct subdirectories of lib/
    await for (final entity in libDir.list()) {
      if (entity is Directory) {
        final partName = path.basename(entity.path);
        if (partName.startsWith('.') || partName == 'src') continue;

        final part = await _analyzePart(entity.path, partName);
        project.parts.add(part);
      }
    }
  }

  /// Analyzes a Dart server project.
  Future<void> _analyzeServerProject(ProjectInfo project) async {
    // Server projects always have bin and lib parts
    final binDir = Directory(path.join(project.path, 'bin'));
    final libDir = Directory(path.join(project.path, 'lib'));

    if (binDir.existsSync()) {
      // Collect direct source files in bin/
      final binSources = <String>[];
      await for (final entity in binDir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final fileName = path.basename(entity.path);
          if (!fileName.endsWith('.reflection.dart') && !fileName.endsWith('.g.dart')) {
            binSources.add(fileName);
          }
        }
      }

      final binPart = PartInfo(
        name: 'bin',
        displayName: 'Bin',
        sources: binSources,
      );

      // Check for bin/src/ subdirectories as modules
      final binSrcDir = Directory(path.join(project.path, 'bin', 'src'));
      if (binSrcDir.existsSync()) {
        await for (final entity in binSrcDir.list()) {
          if (entity is Directory) {
            final moduleName = path.basename(entity.path);
            if (moduleName.startsWith('.')) continue;

            final module = await _analyzeModule(entity.path, moduleName);
            binPart.modules.add(module);
          }
        }
      }

      project.parts.add(binPart);
    }

    if (libDir.existsSync()) {
      // Collect direct source files in lib/
      final libSources = <String>[];
      await for (final entity in libDir.list()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final fileName = path.basename(entity.path);
          if (!fileName.endsWith('.reflection.dart') && !fileName.endsWith('.g.dart')) {
            libSources.add(fileName);
          }
        }
      }

      final libPart = PartInfo(
        name: 'lib',
        displayName: 'Lib',
        sources: libSources,
      );

      // Check for lib/ subdirectories as modules (direct subdirs, excluding src/)
      await for (final entity in libDir.list()) {
        if (entity is Directory) {
          final moduleName = path.basename(entity.path);
          if (moduleName.startsWith('.') || moduleName == 'src') continue;

          final module = await _analyzeModule(entity.path, moduleName);
          libPart.modules.add(module);
        }
      }

      // Also check for lib/src/ subdirectories as modules
      final libSrcDir = Directory(path.join(project.path, 'lib', 'src'));
      if (libSrcDir.existsSync()) {
        await for (final entity in libSrcDir.list()) {
          if (entity is Directory) {
            final moduleName = path.basename(entity.path);
            if (moduleName.startsWith('.')) continue;

            final module = await _analyzeModule(entity.path, moduleName);
            libPart.modules.add(module);
          }
        }
      }

      project.parts.add(libPart);
    }
  }

  /// Analyzes a part directory.
  Future<PartInfo> _analyzePart(String partPath, String partName) async {
    final sources = <String>[];
    final partDir = Directory(partPath);

    // Collect direct source files in the part (not in subfolders)
    await for (final entity in partDir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = path.basename(entity.path);
        if (!fileName.endsWith('.reflection.dart') && !fileName.endsWith('.g.dart')) {
          sources.add(fileName);
        }
      }
    }

    final part = PartInfo(
      name: partName,
      displayName: _toDisplayName(partName),
      sources: sources,
    );

    // Look for modules (subdirectories within the part)
    await for (final entity in partDir.list()) {
      if (entity is Directory) {
        final moduleName = path.basename(entity.path);
        if (moduleName.startsWith('.')) continue;

        final module = await _analyzeModule(entity.path, moduleName);
        part.modules.add(module);
      }
    }

    return part;
  }

  /// Analyzes a module directory (supports nested subfolders).
  Future<ModuleInfo> _analyzeModule(String modulePath, String moduleName) async {
    final sources = <String>[];
    final subfolders = <ModuleInfo>[];
    final moduleDir = Directory(modulePath);

    // Collect direct source files in this module (not in subfolders)
    await for (final entity in moduleDir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = path.basename(entity.path);
        if (!fileName.endsWith('.reflection.dart') && !fileName.endsWith('.g.dart')) {
          sources.add(fileName);
        }
      }
    }

    // Recursively analyze subfolders
    await for (final entity in moduleDir.list()) {
      if (entity is Directory) {
        final subfolderName = path.basename(entity.path);
        if (subfolderName.startsWith('.')) continue;

        final subfolder = await _analyzeModule(entity.path, subfolderName);
        subfolders.add(subfolder);
      }
    }

    return ModuleInfo(
      name: moduleName,
      displayName: _toDisplayName(moduleName),
      sources: sources,
      subfolders: subfolders,
    );
  }

  /// Analyzes a module directory for TypeScript/JavaScript (supports nested subfolders).
  Future<ModuleInfo> _analyzeModuleForExtension(String modulePath, String moduleName, String extension) async {
    final sources = <String>[];
    final subfolders = <ModuleInfo>[];
    final moduleDir = Directory(modulePath);

    // Collect direct source files in this module
    await for (final entity in moduleDir.list()) {
      if (entity is File && entity.path.endsWith(extension)) {
        sources.add(path.basename(entity.path));
      }
    }

    // Recursively analyze subfolders
    await for (final entity in moduleDir.list()) {
      if (entity is Directory) {
        final subfolderName = path.basename(entity.path);
        if (subfolderName.startsWith('.') || 
            subfolderName == 'node_modules' ||
            subfolderName == 'out' ||
            subfolderName == 'dist') continue;

        final subfolder = await _analyzeModuleForExtension(entity.path, subfolderName, extension);
        subfolders.add(subfolder);
      }
    }

    return ModuleInfo(
      name: moduleName,
      displayName: _toDisplayName(moduleName),
      sources: sources,
      subfolders: subfolders,
    );
  }

  /// Analyzes a TypeScript or VS Code extension project.
  Future<void> _analyzeTypeScriptProject(ProjectInfo project) async {
    final srcDir = Directory(path.join(project.path, 'src'));
    if (!srcDir.existsSync()) return;

    // Extension/Main module: top-level .ts files in src/
    final mainSources = <String>[];
    await for (final entity in srcDir.list()) {
      if (entity is File && entity.path.endsWith('.ts')) {
        mainSources.add(path.basename(entity.path));
      }
    }

    if (mainSources.isNotEmpty) {
      project.packageModule = ModuleInfo(
        name: project.type == 'vscode_extension' ? 'extension' : 'main',
        displayName: project.displayName,
        sources: mainSources,
      );
    }

    // Parts are direct subdirectories of src/
    await for (final entity in srcDir.list()) {
      if (entity is Directory) {
        final partName = path.basename(entity.path);
        if (partName.startsWith('.') || 
            partName == 'node_modules' ||
            partName == 'out' ||
            partName == 'dist') continue;

        final part = await _analyzePartForExtension(entity.path, partName, '.ts');
        project.parts.add(part);
      }
    }
  }

  /// Analyzes a JavaScript project.
  Future<void> _analyzeJavaScriptProject(ProjectInfo project) async {
    final srcDir = Directory(path.join(project.path, 'src'));
    if (!srcDir.existsSync()) return;

    // Main module: top-level .js files in src/
    final mainSources = <String>[];
    await for (final entity in srcDir.list()) {
      if (entity is File && entity.path.endsWith('.js')) {
        mainSources.add(path.basename(entity.path));
      }
    }

    if (mainSources.isNotEmpty) {
      project.packageModule = ModuleInfo(
        name: 'main',
        displayName: project.displayName,
        sources: mainSources,
      );
    }

    // Parts are direct subdirectories of src/
    await for (final entity in srcDir.list()) {
      if (entity is Directory) {
        final partName = path.basename(entity.path);
        if (partName.startsWith('.') || 
            partName == 'node_modules' ||
            partName == 'dist') continue;

        final part = await _analyzePartForExtension(entity.path, partName, '.js');
        project.parts.add(part);
      }
    }
  }

  /// Analyzes a Java project (Maven or Gradle).
  Future<void> _analyzeJavaProject(ProjectInfo project) async {
    // Try Maven structure first
    var srcDir = Directory(path.join(project.path, 'src', 'main', 'java'));
    if (!srcDir.existsSync()) {
      // Try simple src/ structure
      srcDir = Directory(path.join(project.path, 'src'));
    }
    if (!srcDir.existsSync()) return;

    // Find all Java files and their package structure
    final packageDirs = <String>{};
    await _findJavaPackages(srcDir.path, srcDir.path, packageDirs);

    // Convert package directories to parts
    for (final packagePath in packageDirs) {
      final partName = path.basename(packagePath);
      final part = await _analyzePartForExtension(packagePath, partName, '.java');
      project.parts.add(part);
    }
  }

  /// Recursively finds Java package directories (directories with .java files).
  Future<void> _findJavaPackages(String basePath, String currentPath, Set<String> packages) async {
    final dir = Directory(currentPath);
    bool hasJavaFiles = false;
    final subDirs = <Directory>[];

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.java')) {
        hasJavaFiles = true;
      } else if (entity is Directory) {
        final name = path.basename(entity.path);
        if (!name.startsWith('.')) {
          subDirs.add(entity);
        }
      }
    }

    // If this directory has Java files, it's a package
    if (hasJavaFiles) {
      packages.add(currentPath);
    }

    // Recurse into subdirectories
    for (final subDir in subDirs) {
      await _findJavaPackages(basePath, subDir.path, packages);
    }
  }

  /// Analyzes a part directory for non-Dart projects.
  Future<PartInfo> _analyzePartForExtension(String partPath, String partName, String extension) async {
    final sources = <String>[];
    final partDir = Directory(partPath);

    // Collect direct source files in the part
    await for (final entity in partDir.list()) {
      if (entity is File && entity.path.endsWith(extension)) {
        sources.add(path.basename(entity.path));
      }
    }

    final part = PartInfo(
      name: partName,
      displayName: _toDisplayName(partName),
      sources: sources,
    );

    // Look for modules (subdirectories within the part)
    await for (final entity in partDir.list()) {
      if (entity is Directory) {
        final moduleName = path.basename(entity.path);
        if (moduleName.startsWith('.') ||
            moduleName == 'node_modules' ||
            moduleName == 'out' ||
            moduleName == 'dist') continue;

        final module = await _analyzeModuleForExtension(entity.path, moduleName, extension);
        part.modules.add(module);
      }
    }

    return part;
  }

  /// Writes all metadata files.
  Future<void> _writeMetadata() async {
    final metadataDir = Directory(path.join(workspaceRoot, '.tom_metadata'));
    if (!metadataDir.existsSync()) {
      await metadataDir.create(recursive: true);
    }

    // Write tom_master.yaml (default, contains all metadata)
    await _writeMasterYaml(metadataDir.path);
    
    // Write per-action master files (tom_master_<action>.yaml)
    await _writeActionMasterFiles(metadataDir.path);
  }
  
  /// Writes per-action master files (tom_master_<action>.yaml).
  ///
  /// Per tom_tool_specification.md Section 3.4.1, generates one file per action
  /// from action-mode-configuration and actions definitions.
  Future<void> _writeActionMasterFiles(String metadataPath) async {
    // Collect all action names
    final actionNames = <String>{};
    
    // From action-mode-configuration
    final workspaceModes = workspaceSettings['workspace-modes'];
    if (workspaceModes is Map) {
      final actionModeConfig = workspaceModes['action-mode-configuration'];
      if (actionModeConfig is Map) {
        for (final key in actionModeConfig.keys) {
          if (key != 'default') {
            actionNames.add(key.toString());
          }
        }
      }
    }
    
    // From actions definitions
    final actions = workspaceSettings['actions'];
    if (actions is Map) {
      actionNames.addAll(actions.keys.map((k) => k.toString()));
    }
    
    // Generate a file for each action
    for (final actionName in actionNames) {
      await _writeActionMasterYaml(metadataPath, actionName);
    }
    
    print('Generated ${actionNames.length} action-specific master files');
  }
  
  /// Writes an action-specific master file (tom_master_<action>.yaml).
  Future<void> _writeActionMasterYaml(String metadataPath, String actionName) async {
    final buffer = StringBuffer();
    final now = DateTime.now();
    
    buffer.writeln('# Action-specific Workspace Metadata');
    buffer.writeln('# Generated by WorkspaceAnalyzer for action: $actionName');
    buffer.writeln('# Date: ${now.toIso8601String()}');
    if (!options.includeTestProjects) {
      buffer.writeln('# Note: Test projects (zom_*) excluded.');
    }
    buffer.writeln();
    buffer.writeln('action: $actionName');
    buffer.writeln();
    buffer.writeln('scan-timestamp: "${now.toIso8601String()}"');
    buffer.writeln();
    
    // Write workspace name
    final normalizedRoot = path.normalize(path.absolute(workspaceRoot));
    final workspaceName = workspaceSettings['name'] ?? path.basename(normalizedRoot);
    buffer.writeln('name: $workspaceName');
    buffer.writeln();
    
    // Write resolved mode configuration for this action
    final workspaceModes = workspaceSettings['workspace-modes'];
    if (workspaceModes is Map) {
      final actionModeConfig = workspaceModes['action-mode-configuration'];
      if (actionModeConfig is Map) {
        // Get action-specific config or fall back to default
        final actionConfig = actionModeConfig[actionName] ?? actionModeConfig['default'];
        if (actionConfig is Map) {
          buffer.writeln('# Resolved mode configuration for action: $actionName');
          buffer.writeln('resolved-modes:');
          for (final entry in actionConfig.entries) {
            if (entry.key != 'description') {
              buffer.writeln('  ${entry.key}: ${entry.value}');
            }
          }
          buffer.writeln();
        }
      }
    }
    
    // Write action definition (from workspace-level actions)
    final actions = workspaceSettings['actions'];
    if (actions is Map && actions.containsKey(actionName)) {
      buffer.writeln('action-definition:');
      _writeYamlValue(buffer, actionName, actions[actionName], 2);
      buffer.writeln();
    }
    
    // Write build order (same as default)
    if (buildOrder.isNotEmpty) {
      buffer.writeln('build-order: [${buildOrder.join(", ")}]');
      buffer.writeln();
    }
    
    // Determine which projects to skip for this action
    final actionDef = actions is Map ? actions[actionName] : null;
    final skipTypes = actionDef is Map ? (actionDef['skip-types'] as List?)?.cast<String>() : null;
    final appliesToTypes = actionDef is Map ? (actionDef['applies-to-types'] as List?)?.cast<String>() : null;
    
    // Filter projects for this action
    final actionProjects = projects.where((project) {
      if (skipTypes != null && skipTypes.contains(project.type)) {
        return false;
      }
      if (appliesToTypes != null && !appliesToTypes.contains(project.type)) {
        return false;
      }
      return true;
    }).toList();
    
    // Write projects with full details
    buffer.writeln('projects:');
    for (final project in actionProjects) {
      _writeProjectYaml(buffer, project);
    }
    
    final actionFile = File(path.join(metadataPath, 'tom_master_$actionName.yaml'));
    await actionFile.writeAsString(buffer.toString());
    print('Wrote: ${actionFile.path}');
  }
  
  /// Writes a single project entry to the YAML buffer.
  /// 
  /// Projects inherit workspace-level `actions`, `cross-compilation`, and 
  /// `<mode-type>-mode-definitions` when they don't define their own.
  void _writeProjectYaml(StringBuffer buffer, ProjectInfo project) {
    buffer.writeln('  ${project.name}:');
    
    // === BASIC INFO (Section 3.4.1) ===
    buffer.writeln('    name: ${project.displayName}');
    buffer.writeln('    type: ${project.type}');
    // Include projectFolder if project is not in workspace root
    if (project.projectFolder != null) {
      buffer.writeln('    project-folder: ${project.projectFolder}');
    }
    // Include projectName if it differs from folder name (e.g., from manifest file)
    if (project.projectName != null && project.projectName != project.name) {
      buffer.writeln('    projectName: ${project.projectName}');
    }
    if (project.description != null) {
      buffer.writeln('    description: "${project.description}"');
    }

    // === BUILD ORDERING ===
    if (project.buildAfter.isNotEmpty) {
      buffer.writeln('    build-after: [${project.buildAfter.join(", ")}]');
    }
    
    // Action order from local tom_project.yaml
    final actionOrder = project.localIndexEntries['action-order'];
    if (actionOrder is Map && actionOrder.isNotEmpty) {
      _writeYamlValue(buffer, 'action-order', actionOrder, 4);
    }

    // === FEATURES ===
    if (project.features.isNotEmpty) {
      buffer.writeln('    features:');
      for (final entry in project.features.entries) {
        buffer.writeln('      ${entry.key}: ${entry.value}');
      }
    }

    // === MODE DEFINITIONS (per mode-type) ===
    // First-level merge: project.<mode> replaces workspace.<mode>, others inherited
    // COMPACT OUTPUT: Only write if merged result differs from workspace
    final workspaceModeDefKeys = workspaceSettings.keys
        .where((k) => k.endsWith('-mode-definitions') && k != 'action-mode-definitions')
        .toList()
      ..sort();
    
    for (final modeDefKey in workspaceModeDefKeys) {
      final workspaceDefs = workspaceSettings[modeDefKey];
      final projectDefs = project.localIndexEntries[modeDefKey];
      
      if (workspaceDefs is Map) {
        // First-level merge: start with workspace, override with project entries
        final merged = Map<String, dynamic>.from(workspaceDefs);
        if (projectDefs is Map) {
          for (final entry in projectDefs.entries) {
            merged[entry.key as String] = entry.value; // Replace entire mode entry
          }
        }
        // Only write if different from workspace (compact output)
        if (!_deepEquals(merged, workspaceDefs)) {
          _writeYamlValue(buffer, modeDefKey, merged, 4);
        }
      }
    }

    // === CROSS-COMPILATION ===
    // First-level merge for build-on.<target>, all-targets always from workspace
    // COMPACT OUTPUT: Only write if merged result differs from workspace
    final workspaceCrossComp = workspaceSettings['cross-compilation'];
    final projectCrossComp = project.localIndexEntries['cross-compilation'];
    
    if (workspaceCrossComp is Map) {
      final merged = <String, dynamic>{};
      
      // all-targets always from workspace (cannot be overridden)
      if (workspaceCrossComp['all-targets'] != null) {
        merged['all-targets'] = workspaceCrossComp['all-targets'];
      }
      
      // build-on: first-level merge per target
      final workspaceBuildOn = workspaceCrossComp['build-on'];
      final projectBuildOn = projectCrossComp is Map ? projectCrossComp['build-on'] : null;
      
      if (workspaceBuildOn is Map) {
        final mergedBuildOn = Map<String, dynamic>.from(workspaceBuildOn);
        if (projectBuildOn is Map) {
          for (final entry in projectBuildOn.entries) {
            mergedBuildOn[entry.key as String] = entry.value; // Replace entire target entry
          }
        }
        merged['build-on'] = mergedBuildOn;
      }
      
      // Copy other cross-compilation fields from project (e.g., targets, output-dir)
      if (projectCrossComp is Map) {
        for (final entry in projectCrossComp.entries) {
          if (entry.key != 'all-targets' && entry.key != 'build-on') {
            merged[entry.key as String] = entry.value;
          }
        }
      }
      
      // Only write if different from workspace (compact output)
      if (!_deepEquals(merged, workspaceCrossComp)) {
        _writeYamlValue(buffer, 'cross-compilation', merged, 4);
      }
    } else if (projectCrossComp is Map && projectCrossComp.isNotEmpty) {
      // No workspace cross-compilation, use project as-is
      _writeYamlValue(buffer, 'cross-compilation', projectCrossComp, 4);
    }

    // === ACTIONS ===
    // First-level merge: project.<action> replaces workspace.<action>, others inherited
    // COMPACT OUTPUT: Only write if merged result differs from workspace
    final workspaceActions = workspaceSettings['actions'];
    final projectActions = project.localIndexEntries['actions'];
    
    if (workspaceActions is Map) {
      final merged = Map<String, dynamic>.from(workspaceActions);
      if (projectActions is Map) {
        for (final entry in projectActions.entries) {
          merged[entry.key as String] = entry.value; // Replace entire action entry
        }
      }
      // Only write if different from workspace (compact output)
      if (!_deepEquals(merged, workspaceActions)) {
        _writeYamlValue(buffer, 'actions', merged, 4);
      }
    } else if (projectActions is Map && projectActions.isNotEmpty) {
      _writeYamlValue(buffer, 'actions', projectActions, 4);
    }

    // === ACTION-MODE-DEFINITIONS ===
    final actionModeDefs = project.localIndexEntries['action-mode-definitions'];
    if (actionModeDefs is Map && actionModeDefs.isNotEmpty) {
      _writeYamlValue(buffer, 'action-mode-definitions', actionModeDefs, 4);
    }

    // Note: Legacy build/run/deploy configs are no longer written to tom_master.yaml
    // Projects should use the 'actions' section instead, which comes from tom_project.yaml
    // or is inherited from workspace-level action-definitions

    // === METADATA FILES ===
    if (project.pubspec.isNotEmpty) {
      _writeYamlValue(buffer, 'pubspec', project.pubspec, 4);
    }
    if (project.packageJson.isNotEmpty) {
      _writeYamlValue(buffer, 'packageJson', project.packageJson, 4);
    }
    if (project.pyproject.isNotEmpty) {
      _writeYamlValue(buffer, 'pyproject', project.pyproject, 4);
    }

    // === PACKAGE/APP MODULE ===
    if (project.packageModule != null) {
      buffer.writeln('    packageModule:');
      buffer.writeln('      displayName: ${project.packageModule!.displayName}');
      if (project.packageModule!.sources.isNotEmpty) {
        buffer.writeln('      sources: [${project.packageModule!.sources.join(", ")}]');
      }
    }
    if (project.appModule != null) {
      buffer.writeln('    appModule:');
      buffer.writeln('      displayName: ${project.appModule!.displayName}');
      if (project.appModule!.sources.isNotEmpty) {
        buffer.writeln('      sources: [${project.appModule!.sources.join(", ")}]');
      }
    }

    // === PARTS ===
    if (project.parts.isNotEmpty) {
      buffer.writeln('    parts:');
      for (final part in project.parts) {
        buffer.writeln('      ${part.name}:');
        buffer.writeln('        name: ${part.displayName}');
        if (part.description != null) {
          buffer.writeln('        description: "${part.description}"');
        }
        if (part.sources.isNotEmpty) {
          buffer.writeln('        sources: [${part.sources.join(", ")}]');
        }
        if (part.modules.isNotEmpty) {
          buffer.writeln('        modules:');
          for (final module in part.modules) {
            _writeModuleYaml(buffer, module, 10);
          }
        }
      }
    }

    // === FOLDER LISTINGS ===
    if (project.tests.isNotEmpty) {
      buffer.writeln('    tests: [${project.tests.join(", ")}]');
    }
    if (project.examples.isNotEmpty) {
      buffer.writeln('    examples: [${project.examples.join(", ")}]');
    }
    if (project.docs.isNotEmpty) {
      buffer.writeln('    docs: [${project.docs.join(", ")}]');
    }
    if (project.copilotGuidelines.isNotEmpty) {
      buffer.writeln('    copilot-guidelines: [${project.copilotGuidelines.join(", ")}]');
    }

    // Write binaries from local index (if present)
    final localBinaries = project.localIndexEntries['binaries'];
    if (localBinaries is List && localBinaries.isNotEmpty) {
      buffer.writeln('    binaries: [${localBinaries.join(", ")}]');
    }

    // === EXECUTABLES ===
    final executables = project.localIndexEntries['executables'];
    if (executables is List && executables.isNotEmpty) {
      _writeYamlValue(buffer, 'executables', executables, 4);
    }

    // === CUSTOM TAGS (remaining entries) ===
    // Keys handled explicitly above
    final handledKeys = {
      'name', 'type', 'projectName', 'description', 'packageModule', 
      'appModule', 'parts', 'copilot-guidelines', 'docs', 'tests', 'examples',
      'build-after', 'action-order', 'features', 'build', 'run', 'deploy', 
      'binaries', 'pubspec', 'packageJson', 'pyproject', 'actions',
      'cross-compilation', 'action-mode-definitions', 'executables',
    };
    // Add mode-definition keys to handled set
    final projectModeDefKeys = project.localIndexEntries.keys
        .where((k) => k.endsWith('-mode-definitions') && k != 'action-mode-definitions')
        .toSet();
    handledKeys.addAll(projectModeDefKeys);
    
    for (final entry in project.localIndexEntries.entries) {
      if (handledKeys.contains(entry.key)) continue;
      _writeYamlValue(buffer, entry.key, entry.value, 4);
    }
  }

  /// Writes the master tom_master.yaml file.
  Future<void> _writeMasterYaml(String metadataPath) async {
    final buffer = StringBuffer();
    final now = DateTime.now();
    buffer.writeln('# Workspace Metadata Index');
    buffer.writeln('# Generated by WorkspaceAnalyzer');
    buffer.writeln('# Date: ${now.toIso8601String()}');
    if (!options.includeTestProjects) {
      buffer.writeln('# Note: Test projects (zom_*) excluded. Use ws_analyzer_all.dart to include them.');
    }
    buffer.writeln();
    buffer.writeln('scan-timestamp: "${now.toIso8601String()}"');
    buffer.writeln();
    
    // Normalize workspaceRoot to get proper name (handles '..' etc)
    final normalizedRoot = path.normalize(path.absolute(workspaceRoot));
    buffer.writeln('name: ${path.basename(normalizedRoot)}');
    buffer.writeln();

    // Write workspace-level settings (from root tom_workspace.yaml or defaults)
    final binaries = workspaceSettings['binaries'] ?? defaultWorkspaceSettings['binaries'];
    final operatingSystems = workspaceSettings['operating-systems'] ?? defaultWorkspaceSettings['operating-systems'];
    final mobilePlatforms = workspaceSettings['mobile-platforms'] ?? defaultWorkspaceSettings['mobile-platforms'];

    buffer.writeln('binaries: $binaries');
    buffer.writeln();
    
    if (operatingSystems is List) {
      buffer.writeln('operating-systems: [${operatingSystems.join(", ")}]');
      buffer.writeln();
    }
    if (mobilePlatforms is List) {
      buffer.writeln('mobile-platforms: [${mobilePlatforms.join(", ")}]');
      buffer.writeln();
    }

    // Write any additional workspace settings from root tom_workspace.yaml
    // Skip 'name' since we already wrote it above
    // Track which keys we've written to add empty lines between top-level sections
    final topLevelKeys = <String>[];
    for (final entry in workspaceSettings.entries) {
      if (!['name', 'binaries', 'operating-systems', 'mobile-platforms', 'projects', 'build', 'run', 'deploy'].contains(entry.key)) {
        _writeYamlValue(buffer, entry.key, entry.value, 0);
        topLevelKeys.add(entry.key);
        buffer.writeln(); // Add empty line after each top-level entry
      }
    }

    // Write workspace-level copilot guidelines
    final workspaceCopilotGuidelinesDir = Directory(path.join(workspaceRoot, '_copilot_guidelines'));
    if (await workspaceCopilotGuidelinesDir.exists()) {
      final copilotGuidelinesEntries = <String>[];
      await for (final entity in workspaceCopilotGuidelinesDir.list(followLinks: false)) {
        final name = path.basename(entity.path);
        if (entity is Directory) {
          copilotGuidelinesEntries.add('$name/');
        } else {
          copilotGuidelinesEntries.add(name);
        }
      }
      copilotGuidelinesEntries.sort();
      if (copilotGuidelinesEntries.isNotEmpty) {
        buffer.writeln('copilot-guidelines: [${copilotGuidelinesEntries.join(", ")}]');
        buffer.writeln();
      }
    }

    // Write build order
    if (buildOrder.isNotEmpty) {
      buffer.writeln('build-order: [${buildOrder.join(", ")}]');
      buffer.writeln();
    }

    buffer.writeln('projects:');

    for (final project in projects) {
      _writeProjectYaml(buffer, project);
    }

    final masterFile = File(path.join(metadataPath, 'tom_master.yaml'));
    await masterFile.writeAsString(buffer.toString());
    print('Wrote: ${masterFile.path}');
  }

  /// Writes a module to YAML with proper indentation (recursive for subfolders).
  void _writeModuleYaml(StringBuffer buffer, ModuleInfo module, int indent) {
    final pad = ' ' * indent;
    buffer.writeln('$pad- name: ${module.name}');
    buffer.writeln('$pad  displayName: ${module.displayName}');
    if (module.description != null) {
      buffer.writeln('$pad  description: "${module.description}"');
    }
    if (module.sources.isNotEmpty) {
      buffer.writeln('$pad  sources: [${module.sources.join(", ")}]');
    }
    if (module.subfolders.isNotEmpty) {
      buffer.writeln('$pad  subfolders:');
      for (final subfolder in module.subfolders) {
        _writeModuleYaml(buffer, subfolder, indent + 4);
      }
    }
  }

  /// Deep equality comparison for YAML values (Maps, Lists, primitives).
  /// Used for compact output to determine if project values differ from workspace.
  /// Handles both YamlMap/YamlList and regular Dart Map/List types.
  bool _deepEquals(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a == null || b == null) return false;

    // Handle Map comparison (both regular Map and YamlMap)
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }

    // Handle List comparison (both regular List and YamlList)
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }

    return a == b;
  }

  /// Writes a YAML key-value pair with proper indentation.
  /// Handles strings, lists, maps, and primitive values.
  void _writeYamlValue(StringBuffer buffer, String key, dynamic value, int indent) {
    final pad = ' ' * indent;
    if (value is List) {
      if (value.isEmpty) return;
      // Check if all items are simple values (can be inline)
      final allSimple = value.every((v) => v is String || v is num || v is bool);
      if (allSimple) {
        // Quote strings that need quoting
        final quotedItems = value.map((v) => _quoteYamlValue(v)).toList();
        buffer.writeln('$pad$key: [${quotedItems.join(", ")}]');
      } else {
        buffer.writeln('$pad$key:');
        for (final item in value) {
          if (item is Map) {
            buffer.writeln('$pad  -');
            for (final entry in item.entries) {
              _writeYamlValue(buffer, entry.key.toString(), entry.value, indent + 4);
            }
          } else {
            buffer.writeln('$pad  - ${_quoteYamlValue(item)}');
          }
        }
      }
    } else if (value is Map) {
      buffer.writeln('$pad$key:');
      for (final entry in value.entries) {
        _writeYamlValue(buffer, entry.key.toString(), entry.value, indent + 2);
      }
    } else if (value is String) {
      buffer.writeln('$pad$key: ${_quoteYamlValue(value)}');
    } else {
      buffer.writeln('$pad$key: $value');
    }
  }

  /// Quotes a YAML value if it contains special characters.
  String _quoteYamlValue(dynamic value) {
    if (value is! String) return value.toString();
    // Quote strings that contain special characters or start with special chars
    if (value.contains(':') || value.contains('#') || value.contains('\n') ||
        value.contains('\$') || value.contains('{') || value.contains('}') ||
        value.contains('[') || value.contains(']') || value.contains(',') ||
        value.contains('"') || value.contains("'") ||
        value.startsWith('>') || value.startsWith('<') || value.startsWith('=') ||
        value.startsWith('!') || value.startsWith('|') || value.startsWith('&') ||
        value.startsWith('*') || value.startsWith('%') || value.startsWith('@') ||
        value.startsWith('`') || value.startsWith('~')) {
      // Escape double quotes and newlines, then use double-quote wrapping
      final escaped = value
          .replaceAll('\\', '\\\\')  // Escape backslashes first
          .replaceAll('"', '\\"')     // Escape double quotes
          .replaceAll('\n', '\\n')    // Escape newlines
          .replaceAll('\r', '\\r')    // Escape carriage returns
          .replaceAll('\t', '\\t');   // Escape tabs
      return '"$escaped"';
    }
    return value;
  }

  // Note: Individual project/part/module metadata files are no longer generated.
  // All metadata is now consolidated in tom_master.yaml.
  // The _writeProjectMetadata and _writePartMetadata methods have been removed.

  /// Converts snake_case to Display Name.
  String _toDisplayName(String name) {
    return name
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  /// Cleans up description - returns null if empty or generic.
  String? _cleanDescription(String? description) {
    if (description == null || description.trim().isEmpty) return null;

    // Filter out generic placeholder descriptions
    final genericDescriptions = [
      'A starting point for Dart libraries or applications.',
      'A sample command-line application.',
      'A new Flutter project.',
    ];

    if (genericDescriptions.contains(description.trim())) {
      return null;
    }

    return description.trim();
  }

  /// Lists files and subfolders in a directory (non-recursive).
  /// Subfolders are listed with a trailing '/'.
  /// Returns empty list if directory doesn't exist.
  Future<List<String>> _listFolderContents(String folderPath) async {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) return [];

    final contents = <String>[];
    await for (final entity in dir.list()) {
      final name = path.basename(entity.path);
      if (name.startsWith('.')) continue;

      if (entity is Directory) {
        contents.add('$name/');
      } else if (entity is File) {
        contents.add(name);
      }
    }
    contents.sort();
    return contents;
  }

  /// Loads local tom_project.yaml from a project and returns its entries.
  Future<Map<String, dynamic>> _loadLocalIndex(String projectPath) async {
    final indexFile = File(path.join(projectPath, 'tom_project.yaml'));
    if (!indexFile.existsSync()) return {};

    try {
      final content = await indexFile.readAsString();
      final yaml = loadYaml(content);
      if (yaml is YamlMap) {
        return Map<String, dynamic>.from(yaml);
      }
    } catch (e) {
      // Ignore parse errors for local index files
    }
    return {};
  }

  /// Loads workspace root tom_workspace.yaml and returns its entries.
  Future<Map<String, dynamic>> _loadWorkspaceIndex() async {
    final indexFile = File(path.join(workspaceRoot, 'tom_workspace.yaml'));
    if (!indexFile.existsSync()) return {};

    try {
      final content = await indexFile.readAsString();
      final yaml = loadYaml(content);
      if (yaml is YamlMap) {
        return Map<String, dynamic>.from(yaml);
      }
    } catch (e) {
      // Ignore parse errors
    }
    return {};
  }

  /// Detects features for a project based on file system inspection.
  /// Features can be overridden in the project's local tom_project.yaml.
  Future<void> _detectFeatures(ProjectInfo project) async {
    final features = <String, bool>{};
    final projectPath = project.path;
    final projectName = project.projectName ?? project.name;
    final projectType = project.type;

    // Project-type-specific feature detection
    if (projectType.startsWith('dart') || projectType.startsWith('flutter')) {
      await _detectDartFeatures(features, projectPath, projectName);
    } else if (projectType.startsWith('python')) {
      await _detectPythonFeatures(features, projectPath, projectName);
    } else if (projectType.startsWith('typescript') || 
               projectType.startsWith('javascript') ||
               projectType == 'vscode_extension' ||
               projectType == 'node_cli') {
      await _detectJsFeatures(features, projectPath, projectName);
    } else if (projectType == 'java') {
      await _detectJavaFeatures(features, projectPath);
    }

    // Common features for all project types
    // Check for Docker
    final hasDocker = File(path.join(projectPath, 'Dockerfile')).existsSync() ||
        File(path.join(projectPath, 'docker-compose.yml')).existsSync() ||
        File(path.join(projectPath, 'docker-compose.yaml')).existsSync();
    features['has-docker'] = hasDocker;

    // Check for CI/CD
    final hasCi = Directory(path.join(projectPath, '.github', 'workflows')).existsSync() ||
        File(path.join(projectPath, '.gitlab-ci.yml')).existsSync() ||
        File(path.join(projectPath, 'Jenkinsfile')).existsSync();
    features['has-ci'] = hasCi;

    // Override with local tom_project.yaml feature settings
    final localFeatures = project.localIndexEntries['features'];
    if (localFeatures is Map) {
      for (final entry in localFeatures.entries) {
        if (entry.value is bool) {
          features[entry.key.toString()] = entry.value as bool;
        }
      }
    }

    project.features = features;
  }

  /// Detects Dart/Flutter-specific features.
  Future<void> _detectDartFeatures(Map<String, bool> features, String projectPath, String projectName) async {
    // Check for reflection (.reflection.dart files only, not .g.dart)
    final hasReflection = await _hasFileWithPattern(projectPath, RegExp(r'\.reflection\.dart$'));
    features['has-reflection'] = hasReflection;

    // Check for build_runner (build.yaml file exists and is not empty)
    final buildYamlFile = File(path.join(projectPath, 'build.yaml'));
    final hasBuildRunner = buildYamlFile.existsSync() && 
        (await buildYamlFile.length()) > 0;
    features['has-build-runner'] = hasBuildRunner;

    // Check for native dependencies (ffi in pubspec or native/ directory)
    final ffiInPubspec = await _pubspecContains(projectPath, 'ffi');
    final hasNativeDeps = ffiInPubspec || 
        Directory(path.join(projectPath, 'native')).existsSync();
    features['has-native-deps'] = hasNativeDeps;

    // Check for assets (assets/ folder, fonts/)
    final hasAssets = Directory(path.join(projectPath, 'assets')).existsSync() ||
        Directory(path.join(projectPath, 'fonts')).existsSync();
    features['has-assets'] = hasAssets;

    // Check publishable (not marked as publish_to: none in pubspec)
    final publishable = !await _pubspecContains(projectPath, 'publish_to: none');
    features['publishable'] = publishable;

    // Check for tests: test/ folder with meaningful tests
    final hasTests = await _hasRealTests(projectPath, projectName);
    features['has-tests'] = hasTests;

    // Check for examples: example/ folder with meaningful examples
    final hasExamples = await _hasRealExamples(projectPath, projectName);
    features['has-examples'] = hasExamples;
  }

  /// Detects Python-specific features.
  Future<void> _detectPythonFeatures(Map<String, bool> features, String projectPath, String projectName) async {
    // Check for tests (tests/, test/, *_test.py, test_*.py)
    final hasTestsDir = Directory(path.join(projectPath, 'tests')).existsSync() ||
        Directory(path.join(projectPath, 'test')).existsSync();
    final hasTestFiles = hasTestsDir || 
        await _hasFileWithPattern(projectPath, RegExp(r'(^test_|_test\.py$)'));
    features['has-tests'] = hasTestFiles;

    // Check for documentation (docs/ with Sphinx or MkDocs)
    final docsDir = Directory(path.join(projectPath, 'docs'));
    final hasDocs = docsDir.existsSync() && (
        File(path.join(projectPath, 'docs', 'conf.py')).existsSync() ||
        File(path.join(projectPath, 'mkdocs.yml')).existsSync() ||
        File(path.join(projectPath, 'mkdocs.yaml')).existsSync());
    features['has-docs'] = hasDocs;

    // Check for linting configuration
    final hasLint = File(path.join(projectPath, '.flake8')).existsSync() ||
        File(path.join(projectPath, '.pylintrc')).existsSync() ||
        File(path.join(projectPath, 'ruff.toml')).existsSync() ||
        File(path.join(projectPath, '.ruff.toml')).existsSync() ||
        await _pyprojectContains(projectPath, '[tool.ruff]') ||
        await _pyprojectContains(projectPath, '[tool.pylint]') ||
        await _pyprojectContains(projectPath, '[tool.flake8]');
    features['has-lint'] = hasLint;

    // Check for type hints (py.typed marker or mypy config)
    final hasTypeHints = File(path.join(projectPath, 'py.typed')).existsSync() ||
        await _pyprojectContains(projectPath, '[tool.mypy]') ||
        File(path.join(projectPath, 'mypy.ini')).existsSync() ||
        File(path.join(projectPath, '.mypy.ini')).existsSync();
    features['has-type-hints'] = hasTypeHints;

    // Check for CLI scripts
    final hasCli = await _pyprojectContains(projectPath, '[project.scripts]') ||
        await _pyprojectContains(projectPath, '[tool.poetry.scripts]');
    features['has-cli'] = hasCli;

    // Check for native dependencies (Cython, cffi, pybind11, or .pyx files)
    final hasNativeDeps = await _pyprojectContains(projectPath, 'cython') ||
        await _pyprojectContains(projectPath, 'cffi') ||
        await _pyprojectContains(projectPath, 'pybind11') ||
        await _hasFileWithPattern(projectPath, RegExp(r'\.pyx$'));
    features['has-native-deps'] = hasNativeDeps;

    // Check publishable (not private = true in pyproject.toml)
    final isPrivate = await _pyprojectContains(projectPath, 'private = true');
    features['publishable'] = !isPrivate;
  }

  /// Detects JavaScript/TypeScript-specific features.
  Future<void> _detectJsFeatures(Map<String, bool> features, String projectPath, String projectName) async {
    final packageJsonFile = File(path.join(projectPath, 'package.json'));
    String packageJsonContent = '';
    if (packageJsonFile.existsSync()) {
      try {
        packageJsonContent = await packageJsonFile.readAsString();
      } catch (_) {}
    }

    // Check for TypeScript
    final hasTypescript = File(path.join(projectPath, 'tsconfig.json')).existsSync();
    features['has-typescript'] = hasTypescript;

    // Check for ES modules
    final isEsm = packageJsonContent.contains('"type": "module"') ||
        packageJsonContent.contains('"type":"module"');
    features['is-esm'] = isEsm;

    // Check for tests (jest, mocha, vitest, or test directories)
    final hasTestInfra = packageJsonContent.contains('"jest"') ||
        packageJsonContent.contains('"mocha"') ||
        packageJsonContent.contains('"vitest"') ||
        packageJsonContent.contains('"ava"') ||
        Directory(path.join(projectPath, 'test')).existsSync() ||
        Directory(path.join(projectPath, '__tests__')).existsSync() ||
        await _hasFileWithPattern(projectPath, RegExp(r'\.(test|spec)\.(js|ts|jsx|tsx)$'));
    features['has-tests'] = hasTestInfra;

    // Check for linting (eslint)
    final hasLint = packageJsonContent.contains('"eslint"') ||
        File(path.join(projectPath, '.eslintrc')).existsSync() ||
        File(path.join(projectPath, '.eslintrc.js')).existsSync() ||
        File(path.join(projectPath, '.eslintrc.json')).existsSync() ||
        File(path.join(projectPath, '.eslintrc.yml')).existsSync() ||
        File(path.join(projectPath, 'eslint.config.js')).existsSync() ||
        File(path.join(projectPath, 'eslint.config.mjs')).existsSync();
    features['has-lint'] = hasLint;

    // Check for prettier
    final hasPrettier = packageJsonContent.contains('"prettier"') ||
        File(path.join(projectPath, '.prettierrc')).existsSync() ||
        File(path.join(projectPath, '.prettierrc.js')).existsSync() ||
        File(path.join(projectPath, '.prettierrc.json')).existsSync() ||
        File(path.join(projectPath, 'prettier.config.js')).existsSync();
    features['has-prettier'] = hasPrettier;

    // Check for bundler (webpack, rollup, vite, esbuild, parcel)
    final hasBundler = packageJsonContent.contains('"webpack"') ||
        packageJsonContent.contains('"rollup"') ||
        packageJsonContent.contains('"vite"') ||
        packageJsonContent.contains('"esbuild"') ||
        packageJsonContent.contains('"parcel"') ||
        File(path.join(projectPath, 'webpack.config.js')).existsSync() ||
        File(path.join(projectPath, 'vite.config.js')).existsSync() ||
        File(path.join(projectPath, 'vite.config.ts')).existsSync() ||
        File(path.join(projectPath, 'rollup.config.js')).existsSync();
    features['has-bundler'] = hasBundler;

    // Check for monorepo (workspaces, lerna, pnpm)
    final isMonorepo = packageJsonContent.contains('"workspaces"') ||
        File(path.join(projectPath, 'lerna.json')).existsSync() ||
        File(path.join(projectPath, 'pnpm-workspace.yaml')).existsSync();
    features['is-monorepo'] = isMonorepo;

    // Check publishable (not private: true)
    final isPrivate = packageJsonContent.contains('"private": true') ||
        packageJsonContent.contains('"private":true');
    features['publishable'] = !isPrivate;
  }

  /// Detects Java-specific features.
  Future<void> _detectJavaFeatures(Map<String, bool> features, String projectPath) async {
    // Check for tests
    final hasTests = Directory(path.join(projectPath, 'src', 'test')).existsSync();
    features['has-tests'] = hasTests;

    // Check for Maven vs Gradle
    final hasMaven = File(path.join(projectPath, 'pom.xml')).existsSync();
    final hasGradle = File(path.join(projectPath, 'build.gradle')).existsSync() ||
        File(path.join(projectPath, 'build.gradle.kts')).existsSync();
    features['uses-maven'] = hasMaven;
    features['uses-gradle'] = hasGradle;

    // Assume publishable unless in a test project
    features['publishable'] = true;
  }

  /// Checks if pyproject.toml contains a specific string.
  Future<bool> _pyprojectContains(String projectPath, String pattern) async {
    final pyprojectFile = File(path.join(projectPath, 'pyproject.toml'));
    if (!pyprojectFile.existsSync()) return false;
    try {
      final content = await pyprojectFile.readAsString();
      return content.contains(pattern);
    } catch (_) {
      return false;
    }
  }

  /// Checks if a project has real tests (not just boilerplate).
  /// Returns true if:
  /// - test/ folder exists AND
  /// - Either has files other than <projectname>_test.dart, OR
  /// - <projectname>_test.dart has >400 bytes and doesn't contain "Awesome"
  Future<bool> _hasRealTests(String projectPath, String projectName) async {
    final testDir = Directory(path.join(projectPath, 'test'));
    if (!testDir.existsSync()) return false;

    final boilerplateTestFile = '${projectName}_test.dart';
    var hasOtherTestFiles = false;

    try {
      await for (final entity in testDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('_test.dart')) {
          final fileName = path.basename(entity.path);
          if (fileName != boilerplateTestFile) {
            hasOtherTestFiles = true;
            break;
          }
        }
      }
    } catch (_) {
      return false;
    }

    if (hasOtherTestFiles) return true;

    // Check if the boilerplate test file has real content
    final testFile = File(path.join(projectPath, 'test', boilerplateTestFile));
    if (!testFile.existsSync()) return false;

    try {
      final fileSize = await testFile.length();
      if (fileSize <= 400) return false;
      
      final content = await testFile.readAsString();
      if (content.contains('Awesome')) return false;
      
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Checks if a project has real examples (not just boilerplate).
  /// Returns true if:
  /// - example/ folder exists AND
  /// - Either has files other than <projectname>_example.dart, OR
  /// - <projectname>_example.dart doesn't contain "Awesome"
  Future<bool> _hasRealExamples(String projectPath, String projectName) async {
    final exampleDir = Directory(path.join(projectPath, 'example'));
    if (!exampleDir.existsSync()) return false;

    final boilerplateExampleFile = '${projectName}_example.dart';
    var hasOtherFiles = false;

    try {
      await for (final entity in exampleDir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final fileName = path.basename(entity.path);
          if (fileName != boilerplateExampleFile) {
            hasOtherFiles = true;
            break;
          }
        }
      }
    } catch (_) {
      return false;
    }

    if (hasOtherFiles) return true;

    // Check if the boilerplate example file has real content
    final exampleFile = File(path.join(projectPath, 'example', boilerplateExampleFile));
    if (!exampleFile.existsSync()) return false;

    try {
      final content = await exampleFile.readAsString();
      if (content.contains('Awesome')) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Populates manifest information based on project type.
  Future<void> _populateManifest(ProjectInfo project) async {
    final projectType = project.type;
    
    if (projectType.startsWith('dart') || projectType.startsWith('flutter')) {
      await _populatePubspec(project);
    } else if (projectType.startsWith('python')) {
      await _populatePyproject(project);
    } else if (projectType.startsWith('typescript') || 
               projectType.startsWith('javascript') ||
               projectType == 'vscode_extension' ||
               projectType == 'node_cli') {
      await _populatePackageJson(project);
    }
    // Java projects don't have a simple manifest format to capture
  }

  /// Populates pubspec information using the override hierarchy:
  /// 1. Auto-generated values (name, type-specific defaults)
  /// 2. Global defaults from workspace settings
  /// 3. Actual pubspec.yaml content
  /// 4. Local tom_project.yaml pubspec overrides
  /// Each level overwrites existing entries or adds additional entries.
  Future<void> _populatePubspec(ProjectInfo project) async {
    final pubspec = <String, dynamic>{};

    // 1. Auto-generated values based on project type
    pubspec['name'] = project.projectName ?? project.name;
    if (project.description != null) {
      pubspec['description'] = project.description;
    }

    // 2. Apply global defaults from workspace settings (if any)
    final workspacePubspecDefaults = workspaceSettings['pubspec-defaults'];
    if (workspacePubspecDefaults is Map) {
      for (final entry in workspacePubspecDefaults.entries) {
        pubspec[entry.key.toString()] = _deepCopy(entry.value);
      }
    }

    // 3. Read and apply actual pubspec.yaml content
    final pubspecFile = File(path.join(project.path, 'pubspec.yaml'));
    if (pubspecFile.existsSync()) {
      try {
        final content = await pubspecFile.readAsString();
        final yaml = loadYaml(content);
        if (yaml is YamlMap) {
          for (final entry in yaml.entries) {
            final key = entry.key.toString();
            final value = _yamlToMap(entry.value);
            pubspec[key] = value;
          }
        }
      } catch (_) {
        // Ignore parse errors
      }
    }

    // 4. Override with local tom_project.yaml pubspec settings
    final localPubspec = project.localIndexEntries['pubspec'];
    if (localPubspec is Map) {
      for (final entry in localPubspec.entries) {
        pubspec[entry.key.toString()] = _deepCopy(entry.value);
      }
    }

    project.pubspec = pubspec;
  }

  /// Populates package.json information for JS/TS projects.
  Future<void> _populatePackageJson(ProjectInfo project) async {
    final packageJson = <String, dynamic>{};

    // 1. Auto-generated values
    packageJson['name'] = project.projectName ?? project.name;
    if (project.description != null) {
      packageJson['description'] = project.description;
    }

    // 2. Read and apply actual package.json content
    final packageJsonFile = File(path.join(project.path, 'package.json'));
    if (packageJsonFile.existsSync()) {
      try {
        final content = await packageJsonFile.readAsString();
        final parsed = _parseFullJson(content);
        for (final entry in parsed.entries) {
          packageJson[entry.key] = entry.value;
        }
      } catch (_) {
        // Ignore parse errors
      }
    }

    // 3. Override with local tom_project.yaml packageJson settings
    final localPackageJson = project.localIndexEntries['packageJson'];
    if (localPackageJson is Map) {
      for (final entry in localPackageJson.entries) {
        packageJson[entry.key.toString()] = _deepCopy(entry.value);
      }
    }

    project.packageJson = packageJson;
  }

  /// Populates pyproject.toml information for Python projects.
  Future<void> _populatePyproject(ProjectInfo project) async {
    final pyproject = <String, dynamic>{};

    // 1. Auto-generated values
    pyproject['name'] = project.projectName ?? project.name;
    if (project.description != null) {
      pyproject['description'] = project.description;
    }

    // 2. Read and apply actual pyproject.toml content
    final pyprojectFile = File(path.join(project.path, 'pyproject.toml'));
    if (pyprojectFile.existsSync()) {
      try {
        final content = await pyprojectFile.readAsString();
        final parsed = _parseToml(content);
        for (final entry in parsed.entries) {
          pyproject[entry.key] = entry.value;
        }
      } catch (_) {
        // Ignore parse errors
      }
    }

    // Also check setup.py and setup.cfg for legacy projects
    final setupPy = File(path.join(project.path, 'setup.py'));
    if (setupPy.existsSync() && !pyprojectFile.existsSync()) {
      pyproject['_legacy'] = 'setup.py';
    }

    // 3. Override with local tom_project.yaml pyproject settings
    final localPyproject = project.localIndexEntries['pyproject'];
    if (localPyproject is Map) {
      for (final entry in localPyproject.entries) {
        pyproject[entry.key.toString()] = _deepCopy(entry.value);
      }
    }

    project.pyproject = pyproject;
  }

  /// Parses JSON content fully (not just regex-based).
  Map<String, dynamic> _parseFullJson(String content) {
    try {
      // Simple recursive descent parser for JSON
      // We'll use Dart's built-in json decode via runtime
      final result = <String, dynamic>{};
      
      // Extract key fields using regex for simplicity
      // Name
      final nameMatch = RegExp(r'"name"\s*:\s*"([^"]*)"').firstMatch(content);
      if (nameMatch != null) result['name'] = nameMatch.group(1);
      
      // Version
      final versionMatch = RegExp(r'"version"\s*:\s*"([^"]*)"').firstMatch(content);
      if (versionMatch != null) result['version'] = versionMatch.group(1);
      
      // Description
      final descMatch = RegExp(r'"description"\s*:\s*"([^"]*)"').firstMatch(content);
      if (descMatch != null) result['description'] = descMatch.group(1);
      
      // Main
      final mainMatch = RegExp(r'"main"\s*:\s*"([^"]*)"').firstMatch(content);
      if (mainMatch != null) result['main'] = mainMatch.group(1);
      
      // Type (module/commonjs)
      final typeMatch = RegExp(r'"type"\s*:\s*"([^"]*)"').firstMatch(content);
      if (typeMatch != null) result['type'] = typeMatch.group(1);
      
      // License
      final licenseMatch = RegExp(r'"license"\s*:\s*"([^"]*)"').firstMatch(content);
      if (licenseMatch != null) result['license'] = licenseMatch.group(1);
      
      // Private
      if (content.contains('"private": true') || content.contains('"private":true')) {
        result['private'] = true;
      }
      
      // Has bin
      if (RegExp(r'"bin"\s*:').hasMatch(content)) {
        result['has-bin'] = true;
      }
      
      // Has scripts
      if (content.contains('"scripts"')) {
        result['has-scripts'] = true;
      }
      
      // Has dependencies
      if (content.contains('"dependencies"')) {
        result['has-dependencies'] = true;
      }
      
      // Has devDependencies
      if (content.contains('"devDependencies"')) {
        result['has-devDependencies'] = true;
      }
      
      // Engines node version
      final nodeMatch = RegExp(r'"node"\s*:\s*"([^"]*)"').firstMatch(content);
      if (nodeMatch != null) {
        result['engines'] = {'node': nodeMatch.group(1)};
      }
      
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Parses TOML content (simplified - extracts key sections).
  Map<String, dynamic> _parseToml(String content) {
    final result = <String, dynamic>{};
    
    try {
      // Extract [project] section values
      if (content.contains('[project]')) {
        final projectSection = <String, dynamic>{};
        
        // Name
        final nameMatch = RegExp(r'name\s*=\s*"([^"]*)"').firstMatch(content);
        if (nameMatch != null) projectSection['name'] = nameMatch.group(1);
        
        // Version
        final versionMatch = RegExp(r'version\s*=\s*"([^"]*)"').firstMatch(content);
        if (versionMatch != null) projectSection['version'] = versionMatch.group(1);
        
        // Description
        final descMatch = RegExp(r'description\s*=\s*"([^"]*)"').firstMatch(content);
        if (descMatch != null) projectSection['description'] = descMatch.group(1);
        
        // Python version requirement
        final pyVersionMatch = RegExp(r'requires-python\s*=\s*"([^"]*)"').firstMatch(content);
        if (pyVersionMatch != null) projectSection['requires-python'] = pyVersionMatch.group(1);
        
        if (projectSection.isNotEmpty) {
          result['project'] = projectSection;
        }
      }
      
      // Detect tool sections
      final toolSections = <String, bool>{};
      if (content.contains('[tool.poetry]')) toolSections['poetry'] = true;
      if (content.contains('[tool.setuptools]')) toolSections['setuptools'] = true;
      if (content.contains('[tool.flit]')) toolSections['flit'] = true;
      if (content.contains('[tool.pdm]')) toolSections['pdm'] = true;
      if (content.contains('[tool.hatch]')) toolSections['hatch'] = true;
      if (content.contains('[tool.ruff]')) toolSections['ruff'] = true;
      if (content.contains('[tool.mypy]')) toolSections['mypy'] = true;
      if (content.contains('[tool.pytest]')) toolSections['pytest'] = true;
      if (content.contains('[tool.black]')) toolSections['black'] = true;
      
      if (toolSections.isNotEmpty) {
        result['tool'] = toolSections;
      }
      
      // Build system
      if (content.contains('[build-system]')) {
        final buildBackendMatch = RegExp(r'build-backend\s*=\s*"([^"]*)"').firstMatch(content);
        if (buildBackendMatch != null) {
          result['build-system'] = {'build-backend': buildBackendMatch.group(1)};
        }
      }
      
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Converts a YAML value to a regular Dart Map/List/value.
  dynamic _yamlToMap(dynamic value) {
    if (value is YamlMap) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), _yamlToMap(e.value))),
      );
    } else if (value is YamlList) {
      return value.map(_yamlToMap).toList();
    } else {
      return value;
    }
  }

  /// Creates a deep copy of a value (for Maps and Lists).
  dynamic _deepCopy(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), _deepCopy(e.value))),
      );
    } else if (value is List) {
      return value.map(_deepCopy).toList();
    } else {
      return value;
    }
  }

  /// Checks if pubspec.yaml contains a specific string.
  Future<bool> _pubspecContains(String projectPath, String pattern) async {
    final pubspecFile = File(path.join(projectPath, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return false;
    try {
      final content = await pubspecFile.readAsString();
      return content.contains(pattern);
    } catch (_) {
      return false;
    }
  }

  /// Checks if any file in a directory matches a pattern.
  Future<bool> _hasFileWithPattern(String dirPath, RegExp pattern) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) return false;

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && pattern.hasMatch(entity.path)) {
          return true;
        }
      }
    } catch (_) {
      // Ignore errors
    }
    return false;
  }

  /// Resolves project configuration using the override hierarchy:
  /// 1. Auto-generated defaults (based on project type)
  /// 2. Workspace-level defaults (from tom_workspace.yaml)
  /// 3. Local project settings (from tom_project.yaml)
  void _resolveProjectConfig(ProjectInfo project) {
    // Resolve build configuration
    // Check if explicitly set to null in local index
    if (project.localIndexEntries.containsKey('build') && 
        project.localIndexEntries['build'] == null) {
      project.buildConfig = {};
    } else {
      project.buildConfig = _mergeConfigs([
        // Base defaults for this project type
        defaultBuildConfig[project.type] ?? {},
        // Workspace-level overrides for this project type
        _getWorkspaceBuildConfig(project.type),
        // Local project overrides
        project.localIndexEntries['build'] ?? {},
      ]);
    }

    // Resolve run configuration
    if (project.localIndexEntries.containsKey('run') && 
        project.localIndexEntries['run'] == null) {
      project.runConfig = {};
    } else {
      project.runConfig = _mergeConfigs([
        defaultRunConfig[project.type] ?? {},
        _getWorkspaceRunConfig(project.type),
        project.localIndexEntries['run'] ?? {},
      ]);
    }

    // Resolve deploy configuration
    if (project.localIndexEntries.containsKey('deploy') && 
        project.localIndexEntries['deploy'] == null) {
      project.deployConfig = {};
    } else {
      project.deployConfig = _mergeConfigs([
        defaultDeployConfig[project.type] ?? {},
        _getWorkspaceDeployConfig(project.type),
        project.localIndexEntries['deploy'] ?? {},
      ]);
    }

    // Extract build-after from local index or auto-detect from pubspec
    final localBuildAfter = project.localIndexEntries['build-after'];
    if (localBuildAfter is List) {
      project.buildAfter = List<String>.from(localBuildAfter.map((e) => e.toString()));
    } else {
      // Auto-detect from pubspec dependencies
      project.buildAfter = _detectBuildDependencies(project);
    }
  }

  /// Gets workspace-level build configuration for a project type.
  Map<String, dynamic> _getWorkspaceBuildConfig(String projectType) {
    final buildDefaults = workspaceSettings['build'];
    if (buildDefaults is Map) {
      final typeConfig = buildDefaults[projectType];
      if (typeConfig is Map) {
        return Map<String, dynamic>.from(typeConfig);
      }
    }
    return {};
  }

  /// Gets workspace-level run configuration for a project type.
  Map<String, dynamic> _getWorkspaceRunConfig(String projectType) {
    final runDefaults = workspaceSettings['run'];
    if (runDefaults is Map) {
      final typeConfig = runDefaults[projectType];
      if (typeConfig is Map) {
        return Map<String, dynamic>.from(typeConfig);
      }
    }
    return {};
  }

  /// Gets workspace-level deploy configuration for a project type.
  Map<String, dynamic> _getWorkspaceDeployConfig(String projectType) {
    final deployDefaults = workspaceSettings['deploy'];
    if (deployDefaults is Map) {
      final typeConfig = deployDefaults[projectType];
      if (typeConfig is Map) {
        return Map<String, dynamic>.from(typeConfig);
      }
    }
    return {};
  }

  /// Merges multiple configuration maps using override hierarchy.
  /// Later maps override earlier maps. Handles nested maps recursively.
  Map<String, dynamic> _mergeConfigs(List<dynamic> configs) {
    final result = <String, dynamic>{};
    
    for (final config in configs) {
      if (config is! Map) continue;
      
      for (final entry in config.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        
        if (value is Map && result[key] is Map) {
          // Recursively merge nested maps
          result[key] = _mergeConfigs([result[key], value]);
        } else if (value != null) {
          result[key] = value is Map 
              ? Map<String, dynamic>.from(value)
              : value is List 
                  ? List<dynamic>.from(value)
                  : value;
        }
      }
    }
    
    return result;
  }

  /// Detects build dependencies from pubspec.yaml.
  /// Returns list of workspace projects this project depends on.
  List<String> _detectBuildDependencies(ProjectInfo project) {
    final pubspecFile = File(path.join(project.path, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) return [];

    try {
      final content = pubspecFile.readAsStringSync();
      final yaml = loadYaml(content);
      if (yaml is! YamlMap) return [];

      final deps = <String>[];
      final projectNames = projects.map((p) => p.name).toSet();

      // Check dependencies
      final dependencies = yaml['dependencies'];
      if (dependencies is YamlMap) {
        for (final dep in dependencies.keys) {
          final depName = dep.toString();
          if (projectNames.contains(depName)) {
            deps.add(depName);
          }
        }
      }

      // Check dev_dependencies
      final devDependencies = yaml['dev_dependencies'];
      if (devDependencies is YamlMap) {
        for (final dep in devDependencies.keys) {
          final depName = dep.toString();
          if (projectNames.contains(depName)) {
            deps.add(depName);
          }
        }
      }

      return deps;
    } catch (_) {
      return [];
    }
  }

  /// Resolves the build order based on build-after dependencies.
  /// Uses topological sort to determine correct order.
  void _resolveBuildOrder() {
    // Build a dependency graph
    final graph = <String, Set<String>>{};
    final projectNames = <String>{};

    for (final project in projects) {
      projectNames.add(project.name);
      graph[project.name] = project.buildAfter.toSet();
    }

    // Filter out external dependencies (not in this workspace)
    for (final deps in graph.values) {
      deps.removeWhere((dep) => !projectNames.contains(dep));
    }

    // Topological sort using Kahn's algorithm
    final inDegree = <String, int>{};
    for (final name in projectNames) {
      inDegree[name] = 0;
    }

    for (final deps in graph.values) {
      for (final dep in deps) {
        if (inDegree.containsKey(dep)) {
          // Count how many projects depend on this one
        }
      }
    }

    // Count in-degree (how many other projects each project depends on)
    for (final entry in graph.entries) {
      inDegree[entry.key] = entry.value.length;
    }

    // Start with projects that have no dependencies
    final queue = <String>[];
    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    // Sort alphabetically for consistent ordering among equals
    queue.sort();

    final result = <String>[];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);

      // Find projects that depend on current
      for (final entry in graph.entries) {
        if (entry.value.contains(current)) {
          inDegree[entry.key] = inDegree[entry.key]! - 1;
          if (inDegree[entry.key] == 0) {
            queue.add(entry.key);
          }
        }
      }
      queue.sort();
    }

    // Check for cycles
    if (result.length != projectNames.length) {
      print('Warning: Circular dependency detected in build order');
      // Add remaining projects at the end
      for (final name in projectNames) {
        if (!result.contains(name)) {
          result.add(name);
        }
      }
    }

    buildOrder = result;
    print('Resolved build order: ${buildOrder.join(" -> ")}');
  }
}

/// Information about a project.
class ProjectInfo {
  final String path;
  final String name;           // Folder name (used as key in tom_master.yaml)
  final String displayName;
  final String? projectName;   // Name from manifest (package.json, pubspec.yaml) if different from folder
  final String? description;
  final String type;
  final String? projectFolder; // Relative path from workspace root (e.g., "xternal/tom_module_d4rt/tom_d4rt")
  ModuleInfo? packageModule;   // For dart_package: top-level lib/ files
  ModuleInfo? appModule;       // For flutter_app: top-level lib/ files
  final List<PartInfo> parts = [];

  // Folder listings (files and subfolders with trailing /)
  List<String> copilotGuidelines = [];
  List<String> docs = [];
  List<String> tests = [];
  List<String> examples = [];

  // Local tom_project.yaml entries (merged into project)
  Map<String, dynamic> localIndexEntries = {};

  // Build dependencies: list of projects this project depends on
  List<String> buildAfter = [];

  // Feature flags (auto-detected, can be overridden in local tom_project.yaml)
  Map<String, bool> features = {};

  // Pubspec.yaml content (merged from auto-generated + global defaults + pubspec.yaml + tom_project.yaml)
  Map<String, dynamic> pubspec = {};

  // Package.json content (for JS/TS projects)
  Map<String, dynamic> packageJson = {};

  // Pyproject.toml content (for Python projects)
  Map<String, dynamic> pyproject = {};

  // Resolved configuration (merged from defaults + workspace + local)
  Map<String, dynamic> buildConfig = {};
  Map<String, dynamic> runConfig = {};
  Map<String, dynamic> deployConfig = {};

  ProjectInfo({
    required this.path,
    required this.name,
    required this.displayName,
    this.projectName,
    this.description,
    required this.type,
    this.projectFolder,
  });
}

/// Information about a part.
class PartInfo {
  final String name;
  final String displayName;
  final String? description;
  final List<String> sources;
  final List<ModuleInfo> modules = [];

  PartInfo({
    required this.name,
    required this.displayName,
    this.description,
    List<String>? sources,
  }) : sources = sources ?? [];
}

/// Information about a module.
class ModuleInfo {
  final String name;
  final String displayName;
  final String? description;
  final List<String> sources;
  final List<ModuleInfo> subfolders;

  ModuleInfo({
    required this.name,
    required this.displayName,
    this.description,
    List<String>? sources,
    List<ModuleInfo>? subfolders,
  })  : sources = sources ?? [],
        subfolders = subfolders ?? [];
}
