/// Workspace Config Check
///
/// Checks that the project configuration of a workspace is correct and
/// complete: each project's `tom_project.yaml`, and the parts of
/// `tom_workspace.yaml` that name projects (`project-info`, `groups`). The
/// shape of both files is the JSON Schemas' job
/// (`.tom/json-schema/tom_build/`); this check covers what a schema cannot
/// see: references between projects, uniqueness, and coverage.
///
/// Projects are what [WorkspaceAnalyzer.discoverProjects] finds, keyed by
/// folder name — the key `tom_master.yaml`, `project-info` and `groups` use.
/// The check only reads files.
library;

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'workspace_analyzer.dart';

/// One problem the check found.
class ConfigFinding {
  const ConfigFinding({
    required this.rule,
    required this.file,
    required this.message,
  });

  /// Rule id, e.g. `PC-2` (see [WorkspaceConfigCheck]).
  final String rule;

  /// Workspace-relative file the finding is about.
  final String file;

  final String message;

  @override
  String toString() => '[$rule] $file: $message';
}

/// A project as the check sees it.
class CheckedProject {
  const CheckedProject({
    required this.key,
    required this.relativePath,
    this.tomProject,
  });

  /// The project's folder name: its key in `tom_master.yaml`, `project-info`
  /// and `groups`.
  final String key;

  /// Workspace-relative folder, posix separators.
  final String relativePath;

  /// The parsed `tom_project.yaml`, or null when the project has none.
  final Map<String, dynamic>? tomProject;

  String get tomProjectFile =>
      path.posix.join(relativePath, 'tom_project.yaml');
}

/// The project configuration rules.
///
/// tom_project.yaml:
/// - **PC-1** it declares `project_id`, `name` and `description`, each a
///   non-empty string.
/// - **PC-2** no two projects share a `project_id` (compared ignoring case,
///   as buildkit's `--project` does).
/// - **PC-3** no two projects share a `name`, and a `name` is not another
///   project's folder name or `project_id`: buildkit resolves `--project` by
///   folder name, then id, then name, so such a name selects the other
///   project.
/// - **PC-4** every project named in `build-after` and `action-order` exists.
///
/// tom_workspace.yaml:
/// - **WC-1** every `project-info` key is a project.
/// - **WC-2** a `project-info` entry's `path`, when given, is that project's
///   folder.
/// - **WC-3** every group member is a project.
/// - **WC-4** every project is in exactly one group (`zom_` test projects
///   excepted).
class WorkspaceConfigCheck {
  WorkspaceConfigCheck(this.workspaceRoot, {this.includeProject});

  final String workspaceRoot;

  /// Which discovered projects to check, by workspace-relative folder (posix
  /// separators); all when null. Discovery reads the disk, so a folder only
  /// one machine has (a gitignored copy, a scratch clone) is found too — a
  /// check of the repository passes "tracked by git" here.
  final bool Function(String relativePath)? includeProject;

  static const workspaceFile = 'tom_workspace.yaml';

  /// Discovers the workspace's projects and checks them.
  Future<List<ConfigFinding>> run() async {
    final analyzer = WorkspaceAnalyzer(workspaceRoot);
    final discovered = await analyzer.discoverProjects();
    final projects = [
      for (final project in discovered) _load(project),
    ].where((p) => includeProject?.call(p.relativePath) ?? true).toList();
    return check(
      workspace: _readYamlMap(path.join(workspaceRoot, workspaceFile)) ?? {},
      projects: projects,
    );
  }

  CheckedProject _load(ProjectInfo project) {
    final relative = path.relative(project.path, from: workspaceRoot);
    return CheckedProject(
      key: project.name,
      relativePath: path.split(relative).join('/'),
      tomProject: _readYamlMap(path.join(project.path, 'tom_project.yaml')),
    );
  }

  /// The rules over already-loaded configuration; pure, for tests.
  static List<ConfigFinding> check({
    required Map<String, dynamic> workspace,
    required List<CheckedProject> projects,
  }) {
    final findings = <ConfigFinding>[];
    final byKey = {for (final p in projects) p.key: p};
    _checkProjectFiles(projects, byKey, findings);
    _checkProjectInfo(workspace, byKey, findings);
    _checkGroups(workspace, projects, byKey, findings);
    return findings;
  }

  static void _checkProjectFiles(
    List<CheckedProject> projects,
    Map<String, CheckedProject> byKey,
    List<ConfigFinding> findings,
  ) {
    final ids = <String, CheckedProject>{};
    final names = <String, CheckedProject>{};

    for (final project in projects) {
      final config = project.tomProject;
      if (config == null) continue;
      final file = project.tomProjectFile;

      for (final key in const ['project_id', 'name', 'description']) {
        final value = config[key];
        if (value is! String || value.trim().isEmpty) {
          findings.add(
            ConfigFinding(rule: 'PC-1', file: file, message: 'missing `$key`'),
          );
        }
      }

      final id = config['project_id'];
      if (id is String && id.isNotEmpty) {
        final other = ids[id.toLowerCase()];
        if (other != null) {
          findings.add(
            ConfigFinding(
              rule: 'PC-2',
              file: file,
              message: 'project_id `$id` is also ${other.tomProjectFile}\'s',
            ),
          );
        } else {
          ids[id.toLowerCase()] = project;
        }
      }

      final name = config['name'];
      if (name is String && name.isNotEmpty) {
        final other = names[name.toLowerCase()];
        if (other != null) {
          findings.add(
            ConfigFinding(
              rule: 'PC-3',
              file: file,
              message: 'name `$name` is also ${other.tomProjectFile}\'s',
            ),
          );
        } else {
          names[name.toLowerCase()] = project;
        }
      }

      for (final reference in _orderReferences(config)) {
        if (!byKey.containsKey(reference)) {
          findings.add(
            ConfigFinding(
              rule: 'PC-4',
              file: file,
              message: 'orders after unknown project `$reference`',
            ),
          );
        }
      }
    }

    // A name equal to another project's folder name or id selects that
    // project in buildkit: folder and id are matched first.
    for (final entry in names.entries) {
      final owner = entry.value;
      final folderOwner = byKey.entries
          .where((e) => e.key.toLowerCase() == entry.key)
          .map((e) => e.value)
          .where((p) => p != owner);
      final idOwner = ids[entry.key];
      for (final other in [
        ...folderOwner,
        if (idOwner != null && idOwner != owner) idOwner,
      ]) {
        findings.add(
          ConfigFinding(
            rule: 'PC-3',
            file: owner.tomProjectFile,
            message:
                'name `${owner.tomProject!['name']}` selects '
                '${other.relativePath} in buildkit (its folder name or id)',
          ),
        );
      }
    }
  }

  static Iterable<String> _orderReferences(Map<String, dynamic> config) sync* {
    final buildAfter = config['build-after'];
    if (buildAfter is List) yield* buildAfter.map((e) => e.toString());
    final actionOrder = config['action-order'];
    if (actionOrder is Map) {
      for (final list in actionOrder.values) {
        if (list is List) yield* list.map((e) => e.toString());
      }
    }
  }

  static void _checkProjectInfo(
    Map<String, dynamic> workspace,
    Map<String, CheckedProject> byKey,
    List<ConfigFinding> findings,
  ) {
    final info = workspace['project-info'];
    if (info is! Map) return;
    for (final entry in info.entries) {
      final key = entry.key.toString();
      final project = byKey[key];
      if (project == null) {
        findings.add(
          ConfigFinding(
            rule: 'WC-1',
            file: workspaceFile,
            message: 'project-info `$key` names no project',
          ),
        );
        continue;
      }
      final declared = entry.value is Map ? (entry.value as Map)['path'] : null;
      if (declared != null && declared.toString() != project.relativePath) {
        findings.add(
          ConfigFinding(
            rule: 'WC-2',
            file: workspaceFile,
            message:
                'project-info `$key` path `$declared` is not the '
                'project\'s folder `${project.relativePath}`',
          ),
        );
      }
    }
  }

  static void _checkGroups(
    Map<String, dynamic> workspace,
    List<CheckedProject> projects,
    Map<String, CheckedProject> byKey,
    List<ConfigFinding> findings,
  ) {
    final groups = workspace['groups'];
    final membership = <String, List<String>>{};
    if (groups is Map) {
      for (final group in groups.entries) {
        final members = group.value is Map
            ? (group.value as Map)['projects']
            : null;
        if (members is! List) continue;
        for (final member in members.map((m) => m.toString())) {
          membership.putIfAbsent(member, () => []).add(group.key.toString());
          if (!byKey.containsKey(member)) {
            findings.add(
              ConfigFinding(
                rule: 'WC-3',
                file: workspaceFile,
                message: 'group `${group.key}` lists unknown project `$member`',
              ),
            );
          }
        }
      }
    }

    for (final project in projects) {
      if (project.key.startsWith('zom_')) continue;
      final inGroups = membership[project.key] ?? const <String>[];
      if (inGroups.length != 1) {
        findings.add(
          ConfigFinding(
            rule: 'WC-4',
            file: workspaceFile,
            message: inGroups.isEmpty
                ? 'project `${project.key}` (${project.relativePath}) is in no group'
                : 'project `${project.key}` is in ${inGroups.length} groups: '
                      '${inGroups.join(', ')}',
          ),
        );
      }
    }
  }

  static Map<String, dynamic>? _readYamlMap(String file) {
    final f = File(file);
    if (!f.existsSync()) return null;
    final yaml = loadYaml(f.readAsStringSync());
    return yaml is Map ? _plainMap(yaml) : null;
  }

  static Map<String, dynamic> _plainMap(Map yaml) => {
    for (final entry in yaml.entries) entry.key.toString(): _plain(entry.value),
  };

  static Object? _plain(Object? node) {
    if (node is Map) return _plainMap(node);
    if (node is List) return [for (final item in node) _plain(item)];
    return node;
  }
}
