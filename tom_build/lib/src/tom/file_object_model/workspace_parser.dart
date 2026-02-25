/// Workspace Parser
///
/// Parses a workspace directory and creates a TomMaster object representing
/// the complete workspace structure including all projects, parts, modules,
/// tests, examples, docs, and copilot-guidelines.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'file_object_model.dart';

/// Parses a workspace directory and returns a [TomMaster] representing
/// the complete workspace structure.
class WorkspaceParser {
  final String workspacePath;
  
  WorkspaceParser(this.workspacePath);
  
  /// Parses the workspace and returns a [TomMaster] object.
  TomMaster parse() {
    final workspaceYamlPath = p.join(workspacePath, 'tom_workspace.yaml');
    
    // Parse base workspace configuration
    TomWorkspace? baseWorkspace;
    if (File(workspaceYamlPath).existsSync()) {
      final yamlData = _loadYamlFile(workspaceYamlPath);
      baseWorkspace = TomWorkspace.fromYaml(yamlData);
    }
    
    // Discover all projects
    final projects = _discoverProjects();
    
    // Calculate build order based on dependencies
    final buildOrder = _calculateBuildOrder(projects);
    
    // Generate timestamp
    final timestamp = DateTime.now().toIso8601String();
    
    return TomMaster(
      name: baseWorkspace?.name,
      binaries: baseWorkspace?.binaries,
      operatingSystems: baseWorkspace?.operatingSystems,
      mobilePlatforms: baseWorkspace?.mobilePlatforms,
      imports: baseWorkspace?.imports,
      workspaceModes: baseWorkspace?.workspaceModes,
      crossCompilation: baseWorkspace?.crossCompilation,
      groups: baseWorkspace?.groups ?? {},
      projectTypes: baseWorkspace?.projectTypes ?? {},
      actions: baseWorkspace?.actions ?? {},
      modeDefinitions: baseWorkspace?.modeDefinitions ?? {},
      pipelines: baseWorkspace?.pipelines ?? {},
      projectInfo: baseWorkspace?.projectInfo ?? {},
      deps: baseWorkspace?.deps ?? {},
      depsDev: baseWorkspace?.depsDev ?? {},
      versionSettings: baseWorkspace?.versionSettings,
      customTags: baseWorkspace?.customTags ?? {},
      scanTimestamp: timestamp,
      projects: projects,
      buildOrder: buildOrder,
      actionOrder: {},
    );
  }
  
  /// Discovers all projects in the workspace.
  Map<String, TomProject> _discoverProjects() {
    final projects = <String, TomProject>{};
    final workspaceDir = Directory(workspacePath);
    
    for (final entity in workspaceDir.listSync()) {
      if (entity is Directory) {
        final dirName = p.basename(entity.path);
        
        // Skip hidden directories and common non-project folders
        if (dirName.startsWith('.') || 
            dirName.startsWith('_') ||
            dirName == 'node_modules' ||
            dirName == 'build' ||
            dirName == 'docs') {
          continue;
        }
        
        // Check for tom_project.yaml or pubspec.yaml
        final tomProjectPath = p.join(entity.path, 'tom_project.yaml');
        final pubspecPath = p.join(entity.path, 'pubspec.yaml');
        
        if (File(tomProjectPath).existsSync() || File(pubspecPath).existsSync()) {
          final project = _parseProject(entity.path, dirName);
          if (project != null) {
            projects[project.name] = project;
          }
        }
      }
    }
    
    return projects;
  }
  
  /// Parses a single project directory.
  TomProject? _parseProject(String projectPath, String defaultName) {
    final tomProjectPath = p.join(projectPath, 'tom_project.yaml');
    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    
    Map<String, dynamic> baseYaml = {};
    String projectName = defaultName;
    String? projectType;
    
    // Load tom_project.yaml if it exists
    if (File(tomProjectPath).existsSync()) {
      baseYaml = _loadYamlFile(tomProjectPath);
      projectName = baseYaml['name'] as String? ?? defaultName;
      projectType = baseYaml['type'] as String?;
    }
    
    // Load pubspec.yaml for additional info
    Map<String, dynamic>? pubspecYaml;
    if (File(pubspecPath).existsSync()) {
      pubspecYaml = _loadYamlFile(pubspecPath);
      projectName = pubspecYaml['name'] as String? ?? projectName;
    }
    
    // Detect project type if not specified
    if (projectType == null) {
      projectType = _detectProjectType(projectPath, pubspecYaml);
    }
    
    // Scan project structure
    final parts = _scanParts(projectPath, projectType);
    final packageModule = _scanPackageModule(projectPath, projectType, projectName);
    final tests = _scanDirectory(projectPath, 'test');
    final examples = _scanDirectory(projectPath, 'example');
    final docs = _scanDirectory(projectPath, 'docs');
    final copilotGuidelines = _scanDirectory(projectPath, 'copilot_guidelines');
    final binaryFiles = _scanDirectory(projectPath, 'bin');
    final executables = _scanExecutables(projectPath, baseYaml);
    
    return TomProject(
      name: projectName,
      type: projectType,
      description: baseYaml['description'] as String? ?? 
                   pubspecYaml?['description'] as String?,
      binaries: baseYaml['binaries'] as String?,
      buildAfter: _parseStringList(baseYaml['build-after']) ?? [],
      features: baseYaml['features'] != null
          ? Features.fromYaml(baseYaml['features'] as Map<String, dynamic>)
          : null,
      packageModule: packageModule,
      parts: parts,
      tests: tests.isNotEmpty ? tests : null,
      examples: examples.isNotEmpty ? examples : null,
      docs: docs.isNotEmpty ? docs : null,
      copilotGuidelines: copilotGuidelines.isNotEmpty ? copilotGuidelines : null,
      binaryFiles: binaryFiles.isNotEmpty ? binaryFiles : null,
      executables: executables,
    );
  }
  
  /// Detects project type based on file structure.
  String? _detectProjectType(String projectPath, Map<String, dynamic>? pubspec) {
    final binDir = Directory(p.join(projectPath, 'bin'));
    final libDir = Directory(p.join(projectPath, 'lib'));
    final dockerfile = File(p.join(projectPath, 'Dockerfile'));
    
    // Check for Flutter
    if (pubspec != null) {
      final deps = pubspec['dependencies'] as Map?;
      if (deps != null && deps.containsKey('flutter')) {
        return 'flutter_app';
      }
    }
    
    // Check for server
    if (dockerfile.existsSync()) {
      return 'dart_server';
    }
    
    // Check for CLI
    if (binDir.existsSync()) {
      return 'dart_cli';
    }
    
    // Default to package if has lib/
    if (libDir.existsSync()) {
      return 'dart_package';
    }
    
    return null;
  }
  
  /// Scans for parts in a dart_package project.
  Map<String, Part> _scanParts(String projectPath, String? projectType) {
    // Only scan parts for dart_package type
    if (projectType != 'dart_package') {
      return {};
    }
    
    final parts = <String, Part>{};
    final srcDir = Directory(p.join(projectPath, 'lib', 'src'));
    
    if (!srcDir.existsSync()) {
      return parts;
    }
    
    // Look for subdirectories in lib/src that represent parts
    for (final entity in srcDir.listSync()) {
      if (entity is Directory) {
        final partName = p.basename(entity.path);
        
        // Skip hidden folders
        if (partName.startsWith('.')) continue;
        
        // Check if there's a part library file (e.g., data.dart for data/)
        final partLibraryFile = File(p.join(entity.path, '$partName.dart'));
        
        // Scan for modules
        final modules = _scanModules(entity.path, partName);
        
        if (modules.isNotEmpty || partLibraryFile.existsSync()) {
          parts[partName] = Part(
            name: partName,
            libraryFile: partLibraryFile.existsSync() 
                ? 'lib/src/$partName/$partName.dart' 
                : null,
            modules: modules,
          );
        }
      }
    }
    
    return parts;
  }
  
  /// Scans for modules in a part directory.
  Map<String, Module> _scanModules(String partPath, String partName) {
    final modules = <String, Module>{};
    final partDir = Directory(partPath);
    
    if (!partDir.existsSync()) {
      return modules;
    }
    
    for (final entity in partDir.listSync()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = p.basenameWithoutExtension(entity.path);
        
        // Skip part library file and hidden files
        if (fileName == partName || fileName.startsWith('.') || fileName.startsWith('_')) {
          continue;
        }
        
        final relativePath = p.relative(entity.path, from: p.dirname(p.dirname(p.dirname(partPath))));
        
        modules[fileName] = Module(
          name: fileName,
          libraryFile: relativePath,
        );
      }
    }
    
    return modules;
  }
  
  /// Scans for package-module (simple structure without parts).
  PackageModule? _scanPackageModule(String projectPath, String? projectType, String projectName) {
    // Only for dart_package type
    if (projectType != 'dart_package') {
      return null;
    }
    
    final srcDir = Directory(p.join(projectPath, 'lib', 'src'));
    final libFile = File(p.join(projectPath, 'lib', '$projectName.dart'));
    
    // If there are parts, don't create package-module
    final hasParts = srcDir.existsSync() && 
        srcDir.listSync().any((e) => e is Directory && !p.basename(e.path).startsWith('.'));
    
    if (hasParts) {
      return null;
    }
    
    // Simple package with direct files in lib/src
    if (srcDir.existsSync()) {
      final sourceFolders = <String>[];
      for (final entity in srcDir.listSync()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          sourceFolders.add('lib/src');
          break;
        }
      }
      
      if (sourceFolders.isNotEmpty) {
        return PackageModule(
          name: projectName,
          libraryFile: libFile.existsSync() ? 'lib/$projectName.dart' : null,
          sourceFolders: sourceFolders.isNotEmpty ? sourceFolders : null,
        );
      }
    }
    
    return null;
  }
  
  /// Scans a directory and returns list of relative file paths.
  List<String> _scanDirectory(String projectPath, String dirName) {
    final files = <String>[];
    final dir = Directory(p.join(projectPath, dirName));
    
    if (!dir.existsSync()) {
      return files;
    }
    
    _scanDirectoryRecursive(dir, projectPath, files);
    
    return files;
  }
  
  /// Recursively scans a directory for files.
  void _scanDirectoryRecursive(Directory dir, String basePath, List<String> files) {
    for (final entity in dir.listSync()) {
      if (entity is File) {
        final relativePath = p.relative(entity.path, from: basePath);
        files.add(relativePath);
      } else if (entity is Directory) {
        final dirName = p.basename(entity.path);
        // Skip hidden directories
        if (!dirName.startsWith('.')) {
          _scanDirectoryRecursive(entity, basePath, files);
        }
      }
    }
  }
  
  /// Scans for executables based on bin/ directory or config.
  List<ExecutableDef> _scanExecutables(String projectPath, Map<String, dynamic> yaml) {
    final executables = <ExecutableDef>[];
    
    // Check yaml config first
    if (yaml['executables'] is List) {
      for (final item in yaml['executables'] as List) {
        if (item is Map) {
          executables.add(ExecutableDef(
            source: item['source'] as String? ?? '',
            output: item['output'] as String? ?? '',
          ));
        }
      }
      return executables;
    }
    
    // Auto-discover from bin/
    final binDir = Directory(p.join(projectPath, 'bin'));
    if (binDir.existsSync()) {
      for (final entity in binDir.listSync()) {
        if (entity is File && entity.path.endsWith('.dart')) {
          final fileName = p.basenameWithoutExtension(entity.path);
          executables.add(ExecutableDef(
            source: 'bin/$fileName.dart',
            output: fileName,
          ));
        }
      }
    }
    
    return executables;
  }
  
  /// Calculates build order based on build-after dependencies.
  List<String> _calculateBuildOrder(Map<String, TomProject> projects) {
    final order = <String>[];
    final visited = <String>{};
    final visiting = <String>{};
    
    void visit(String name) {
      if (visited.contains(name)) return;
      if (visiting.contains(name)) {
        // Circular dependency - just add it
        return;
      }
      
      visiting.add(name);
      
      final project = projects[name];
      if (project != null) {
        for (final dep in project.buildAfter) {
          if (projects.containsKey(dep)) {
            visit(dep);
          }
        }
      }
      
      visiting.remove(name);
      visited.add(name);
      order.add(name);
    }
    
    for (final name in projects.keys) {
      visit(name);
    }
    
    return order;
  }
  
  // Helper methods
  
  Map<String, dynamic> _loadYamlFile(String path) {
    final content = File(path).readAsStringSync();
    final yamlData = loadYaml(content);
    return _makeCleanMap(yamlData);
  }
  
  Map<String, dynamic> _makeCleanMap(dynamic data) {
    if (data == null) return {};
    if (data is! Map) return {};

    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final key = entry.key.toString();
      result[key] = _cleanValue(entry.value);
    }
    return result;
  }
  
  dynamic _cleanValue(dynamic value) {
    if (value == null) return null;
    if (value is Map) return _makeCleanMap(value);
    if (value is List) return value.map(_cleanValue).toList();
    if (value is YamlList) return value.map(_cleanValue).toList();
    return value;
  }
  
  List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }
}
