// Shared by the test/config tests: the workspace this package lives in, its
// configuration files, and the commands the workspace actions run.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

// Commands of the workspace actions (tom_workspace.yaml). The action tests
// pin the actions to them; the live-workspace checks know which file each
// one needs.
const testkitTest = 'testkit --nested :test --baseline';
const npmTest = 'npm test';
const runTestsScript = './run_tests.sh';

const buildkitBuild =
    'buildkit --nested :pubget :runner :d4rtgen :versioner :compiler';
const extensionBuild = 'npm run compile';
const packageBuild = 'npm run build --if-present';
const javaBuild = './build_jar.sh';

const flutterRun = 'flutter run';
const npmStart = 'npm run start --if-present';
const dartWatch = 'buildkit --nested :runner --command=watch';
const npmWatch = 'npm run watch --if-present';

const buildkitCleanup = 'buildkit --nested :cleanup';
const apiDocClean = 'rm -rf build/api_doc';
const flutterClean = 'flutter clean';
const npmClean = 'npm run clean --if-present';
const tscClean = 'npx --no-install tsc --build --clean';
const javaClean = 'rm -rf build target';
const pythonClean = 'rm -rf build *.egg-info';

const dartDoc = 'dart doc --output build/api_doc';

/// Manifest files that make a folder a project (WorkspaceAnalyzer's
/// detection).
const manifestFiles = [
  'pubspec.yaml',
  'package.json',
  'pom.xml',
  'build.gradle',
  'build.gradle.kts',
  'pyproject.toml',
  'setup.py',
  'setup.cfg',
  'requirements.txt',
  'environment.yml',
];

/// The nearest folder above the package holding tom_workspace.yaml.
Directory findWorkspaceRoot() {
  var dir = Directory.current.absolute;
  while (!File(p.join(dir.path, 'tom_workspace.yaml')).existsSync()) {
    final parent = dir.parent;
    if (parent.path == dir.path) {
      fail('No tom_workspace.yaml above ${Directory.current.path}');
    }
    dir = parent;
  }
  return dir;
}

/// [file] parsed as YAML into plain maps and lists.
Map<String, dynamic> readYamlMap(String file) =>
    plainYaml(loadYaml(File(file).readAsStringSync())) as Map<String, dynamic>;

/// YAML nodes as plain maps and lists.
Object? plainYaml(Object? node) {
  if (node is YamlMap) {
    return {
      for (final entry in node.entries)
        entry.key.toString(): plainYaml(entry.value),
    };
  }
  if (node is YamlList) return [for (final item in node) plainYaml(item)];
  return node;
}

/// The workspace's tom_workspace.yaml.
Map<String, dynamic> readWorkspaceYaml(Directory root) =>
    readYamlMap(p.join(root.path, 'tom_workspace.yaml'));

/// The commands of [config], as text.
List<String> commandsOf(ActionConfig? config) => [
  for (final c in config?.commands ?? const []) c.toString(),
];

/// Workspace-relative folders holding a tracked manifest (submodules
/// included): the projects of the repository, as opposed to the disk.
Set<String> trackedProjectFolders(Directory root) {
  final result = Process.runSync('git', [
    'ls-files',
    '--recurse-submodules',
    '--',
    for (final m in manifestFiles) ...[m, '*/$m'],
  ], workingDirectory: root.path);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return const LineSplitter()
      .convert(result.stdout as String)
      .where((f) => f.isNotEmpty)
      .map(p.posix.dirname)
      .toSet();
}

/// [projectPath] relative to [root], posix separators.
String relativeProjectPath(Directory root, String projectPath) =>
    p.split(p.relative(projectPath, from: root.path)).join('/');
