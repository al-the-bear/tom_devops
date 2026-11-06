// WorkspaceConfigCheck: the project-configuration rules PC-1..4 and
// WC-1..4 (documented on the class and in doc/tom_configuration_reference.md
// §7), first over hand-built configuration, then over a scratch workspace,
// then over this workspace itself.
//
// The live-workspace test (WCC-30) only READS files: safe while other
// sessions work in the workspace. It discovers projects the way the workspace
// analyzer does (~1 min on the full tree).
@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';

/// Manifest files that make a folder a project (WorkspaceAnalyzer._isProject).
const _manifests = [
  'pubspec.yaml',
  'package.json',
  'pom.xml',
  'build.gradle',
  'build.gradle.kts',
  'pyproject.toml',
  'requirements.txt',
  'environment.yml',
];

CheckedProject _project(
  String key, {
  String? relativePath,
  Map<String, dynamic>? config,
}) => CheckedProject(
  key: key,
  relativePath: relativePath ?? 'pkgs/$key',
  tomProject: config,
);

Map<String, dynamic> _complete(String id, String name) => {
  'project_id': id,
  'name': name,
  'description': 'The $name project',
};

Map<String, dynamic> _groups(Map<String, List<String>> groups) => {
  'groups': {
    for (final g in groups.entries)
      g.key: {'description': g.key, 'projects': g.value},
  },
};

List<String> _rules(List<ConfigFinding> findings) =>
    findings.map((f) => f.rule).toList();

void main() {
  group('rules over loaded configuration', () {
    test('WCC-1: a complete, grouped workspace has no findings', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: {
          ..._groups({
            'g': ['a', 'b'],
          }),
          'project-info': {
            'a': {'path': 'pkgs/a', 'release': '1.0.0'},
            'b': {'release': '1.0.0'},
          },
        },
        projects: [
          _project(
            'a',
            config: {
              ..._complete('A', 'alpha'),
              'build-after': ['b'],
            },
          ),
          _project('b', config: _complete('B', 'beta')),
        ],
      );
      expect(findings, isEmpty, reason: findings.join('\n'));
    });

    test('WCC-2: PC-1 names each missing or empty key', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g': ['a'],
        }),
        projects: [
          _project('a', config: {'name': 'alpha', 'description': ''}),
        ],
      );
      expect(_rules(findings), ['PC-1', 'PC-1']);
      expect(findings.map((f) => f.message), [
        'missing `project_id`',
        'missing `description`',
      ]);
      expect(findings.first.file, 'pkgs/a/tom_project.yaml');
    });

    test('WCC-3: a project without tom_project.yaml is not PC-checked', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g': ['a'],
        }),
        projects: [_project('a')],
      );
      expect(findings, isEmpty);
    });

    test('WCC-4: PC-2 project ids are unique, ignoring case', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g': ['a', 'b'],
        }),
        projects: [
          _project('a', config: _complete('AB', 'alpha')),
          _project('b', config: _complete('ab', 'beta')),
        ],
      );
      expect(_rules(findings), ['PC-2']);
      expect(findings.single.file, 'pkgs/b/tom_project.yaml');
    });

    test('WCC-5: PC-3 names are unique, ignoring case', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g': ['a', 'b'],
        }),
        projects: [
          _project('a', config: _complete('A', 'Kit')),
          _project('b', config: _complete('B', 'kit')),
        ],
      );
      expect(_rules(findings), ['PC-3']);
    });

    test('WCC-6: PC-3 a name must not be another project\'s folder or id', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g': ['a', 'pkg_b', 'c'],
        }),
        projects: [
          _project('a', config: _complete('A', 'pkg_b')),
          _project('pkg_b', config: _complete('IDB', 'beta')),
          _project('c', config: _complete('C', 'idb')),
        ],
      );
      // `pkg_b` is project pkg_b's folder; `idb` is its id (ignoring case).
      expect(_rules(findings), ['PC-3', 'PC-3']);
      expect(findings.map((f) => f.file), [
        'pkgs/a/tom_project.yaml',
        'pkgs/c/tom_project.yaml',
      ]);
    });

    test('WCC-7: PC-3 a name equal to the project\'s own folder is fine', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g': ['tom_x'],
        }),
        projects: [_project('tom_x', config: _complete('X', 'tom_x'))],
      );
      expect(findings, isEmpty);
    });

    test('WCC-8: PC-4 build-after and action-order name projects', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g': ['a'],
        }),
        projects: [
          _project(
            'a',
            config: {
              ..._complete('A', 'alpha'),
              'build-after': ['gone'],
              'action-order': {
                'deploy-after': ['also_gone'],
              },
            },
          ),
        ],
      );
      expect(_rules(findings), ['PC-4', 'PC-4']);
      expect(findings.last.message, contains('also_gone'));
    });

    test('WCC-9: WC-1 a project-info key must name a project', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: {
          ..._groups({
            'g': ['a'],
          }),
          'project-info': {
            'retired': {'release': '1.0.0'},
          },
        },
        projects: [_project('a')],
      );
      expect(_rules(findings), ['WC-1']);
      expect(findings.single.file, 'tom_workspace.yaml');
    });

    test('WCC-10: WC-2 a project-info path must be the project folder', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: {
          ..._groups({
            'g': ['a'],
          }),
          'project-info': {
            'a': {'path': 'old/place/a'},
          },
        },
        projects: [_project('a')],
      );
      expect(_rules(findings), ['WC-2']);
    });

    test('WCC-11: WC-3 a group member must be a project', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g': ['a', 'local_copy'],
        }),
        projects: [_project('a')],
      );
      expect(_rules(findings), ['WC-3']);
      expect(findings.single.message, contains('local_copy'));
    });

    test('WCC-12: WC-4 every project is in exactly one group', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g1': ['a', 'b'],
          'g2': ['b'],
        }),
        projects: [_project('a'), _project('b'), _project('c')],
      );
      expect(_rules(findings), ['WC-4', 'WC-4']);
      expect(findings.first.message, contains('`b` is in 2 groups'));
      expect(findings.last.message, contains('`c` (pkgs/c) is in no group'));
    });

    test('WCC-13: WC-4 skips zom_ test projects', () {
      final findings = WorkspaceConfigCheck.check(
        workspace: _groups({
          'g': ['a'],
        }),
        projects: [_project('a'), _project('zom_fixture')],
      );
      expect(findings, isEmpty);
    });
  });

  group('discovery', () {
    late Directory scratch;

    setUp(() {
      // testlog/ is gitignored test output of this package.
      final testlog = Directory('testlog')..createSync();
      scratch = testlog.createTempSync('config_check_');
    });

    tearDown(() => scratch.deleteSync(recursive: true));

    void write(String relative, String content) {
      // Without a .code-workspace listing `.`, the analyzer only looks at the
      // root's direct children.
      final workspaceFile = File(p.join(scratch.path, 'ws.code-workspace'));
      if (!workspaceFile.existsSync()) {
        workspaceFile.writeAsStringSync('{"folders": [{"path": "."}]}');
      }
      File(p.join(scratch.path, relative))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(content);
    }

    test('WCC-20: run() checks the projects the analyzer discovers', () async {
      write('tom_workspace.yaml', '''
actions:
  build:
    default:
      commands: [echo]
groups:
  libs:
    description: Libraries
    projects: [pkg_a]
project-info:
  pkg_a:
    path: libs/pkg_a
''');
      write('libs/pkg_a/pubspec.yaml', 'name: pkg_a\n');
      write('libs/pkg_a/tom_project.yaml', '''
project_id: PA
name: pa
description: Package A
build-after: [pkg_b]
''');
      write('libs/pkg_b/pubspec.yaml', 'name: pkg_b\n');

      final findings = await WorkspaceConfigCheck(scratch.path).run();

      expect(findings.map((f) => f.toString()), [
        '[WC-4] tom_workspace.yaml: project `pkg_b` (libs/pkg_b) '
            'is in no group',
      ]);
    });

    test(
      'WCC-21: includeProject leaves out folders the repository lacks',
      () async {
        write('tom_workspace.yaml', '''
groups:
  libs:
    description: Libraries
    projects: [pkg_a]
''');
        write('libs/pkg_a/pubspec.yaml', 'name: pkg_a\n');
        write('libs/pkg_a_copy/pubspec.yaml', 'name: pkg_a_copy\n');

        final findings = await WorkspaceConfigCheck(
          scratch.path,
          includeProject: (relative) => relative != 'libs/pkg_a_copy',
        ).run();

        expect(findings, isEmpty, reason: findings.join('\n'));
      },
    );
  });

  group('live workspace (read-only)', () {
    test(
      'WCC-30: this workspace\'s project configuration has no findings',
      () async {
        final root = _findWorkspaceRoot();
        final tracked = _trackedProjectFolders(root);
        final findings = await WorkspaceConfigCheck(
          root.path,
          includeProject: tracked.contains,
        ).run();
        expect(findings, isEmpty, reason: findings.join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}

/// The nearest folder above the package holding tom_workspace.yaml.
Directory _findWorkspaceRoot() {
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

/// Workspace-relative folders holding a tracked manifest (submodules
/// included): the projects of the repository, as opposed to the disk.
Set<String> _trackedProjectFolders(Directory root) {
  final result = Process.runSync('git', [
    'ls-files',
    '--recurse-submodules',
    '--',
    for (final manifest in _manifests) ...[manifest, '*/$manifest'],
  ], workingDirectory: root.path);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return const LineSplitter()
      .convert(result.stdout as String)
      .where((f) => f.isNotEmpty)
      .map(p.posix.dirname)
      .toSet();
}
