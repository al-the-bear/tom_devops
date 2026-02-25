/// Tests for Workspace scripting helper.
///
/// Note: These tests require a valid workspace context to be loaded.
/// They test the wrapper functionality around ToolContext and WorkspaceInfo.
library;

import 'package:test/test.dart';
import 'package:tom_build/src/scripting/workspace.dart';
import 'package:tom_build/src/tools/tool_context.dart';

void main() {
  group('Workspace', () {
    setUpAll(() async {
      // Ensure tool context is loaded
      await ToolContext.load();
    });

    group('context access', () {
      test('context returns ToolContext.current', () {
        expect(TomWs.context, same(ToolContext.current));
      });

      test('info returns workspace info', () {
        expect(TomWs.info, isNotNull);
        expect(TomWs.info, isA<WorkspaceInfo>());
      });

      test('path returns workspace path', () {
        expect(TomWs.path, isNotEmpty);
        expect(TomWs.path, ToolContext.current.workspacePath);
      });

      test('platform returns platform info', () {
        expect(TomWs.platform, isNotNull);
        expect(TomWs.platform, isA<PlatformInfo>());
      });
    });

    group('project access', () {
      test('projects returns list of projects', () {
        expect(TomWs.projects, isA<List<WorkspaceProject>>());
      });

      test('projectsMap returns map of projects', () {
        expect(TomWs.projectsMap, isA<Map<String, WorkspaceProject>>());
      });

      test('groups returns list of groups', () {
        expect(TomWs.groups, isA<List<WorkspaceGroup>>());
      });

      test('groupsMap returns map of groups', () {
        expect(TomWs.groupsMap, isA<Map<String, WorkspaceGroup>>());
      });

      test('projectNames returns list of project names', () {
        expect(TomWs.projectNames, isA<List<String>>());
        // We know tom_build exists in this workspace
        expect(TomWs.projectNames, contains('tom_build'));
      });

      test('groupNames returns list of group names', () {
        expect(TomWs.groupNames, isA<List<String>>());
      });

      test('buildOrder returns build order list', () {
        expect(TomWs.buildOrder, isA<List<String>>());
      });
    });

    group('project lookup', () {
      test('project() finds existing project', () {
        final project = TomWs.project('tom_build');
        expect(project, isNotNull);
        expect(project!.name, 'tom_build');
      });

      test('project() returns null for missing project', () {
        final project = TomWs.project('nonexistent_project');
        expect(project, isNull);
      });

      test('hasProject() returns true for existing project', () {
        expect(TomWs.hasProject('tom_build'), isTrue);
      });

      test('hasProject() returns false for missing project', () {
        expect(TomWs.hasProject('nonexistent'), isFalse);
      });
    });

    group('group lookup', () {
      test('group() finds existing group', () {
        // Skip if no groups defined
        if (TomWs.groupNames.isEmpty) {
          return;
        }
        final groupName = TomWs.groupNames.first;
        final group = TomWs.group(groupName);
        expect(group, isNotNull);
        expect(group!.name, groupName);
      });

      test('group() returns null for missing group', () {
        final group = TomWs.group('nonexistent_group');
        expect(group, isNull);
      });

      test('hasGroup() returns true for existing group', () {
        if (TomWs.groupNames.isEmpty) return;
        expect(TomWs.hasGroup(TomWs.groupNames.first), isTrue);
      });

      test('hasGroup() returns false for missing group', () {
        expect(TomWs.hasGroup('nonexistent'), isFalse);
      });
    });

    group('projectsInGroup', () {
      test('returns projects in specified group', () {
        if (TomWs.groupNames.isEmpty) return;

        final groupName = TomWs.groupNames.first;
        final projects = TomWs.projectsInGroup(groupName);

        expect(projects, isA<List<WorkspaceProject>>());
      });

      test('returns empty list for unknown group', () {
        final projects = TomWs.projectsInGroup('nonexistent');
        expect(projects, isEmpty);
      });
    });

    group('filtering', () {
      test('where() filters projects', () {
        final dartPackages = TomWs.where((p) => p.type == 'dart_package');
        expect(dartPackages, isA<List<WorkspaceProject>>());
      });

      test('ofType() filters by project type', () {
        final packages = TomWs.ofType('dart_package');
        expect(packages, isA<List<WorkspaceProject>>());
        for (final p in packages) {
          expect(p.type, 'dart_package');
        }
      });

      test('dartPackages returns dart_package projects', () {
        final packages = TomWs.dartPackages;
        for (final p in packages) {
          expect(p.type, 'dart_package');
        }
      });

      test('flutterApps returns flutter_app projects', () {
        final apps = TomWs.flutterApps;
        for (final p in apps) {
          expect(p.type, 'flutter_app');
        }
      });

      test('dartServers returns dart_server projects', () {
        final servers = TomWs.dartServers;
        for (final p in servers) {
          expect(p.type, 'dart_server');
        }
      });

      test('vscodeExtensions returns vscode_extension projects', () {
        final extensions = TomWs.vscodeExtensions;
        for (final p in extensions) {
          expect(p.type, 'vscode_extension');
        }
      });
    });

    group('platform checks', () {
      test('isMacOS is consistent with platform', () {
        expect(
          TomWs.isMacOS,
          TomWs.platform.os == OperatingSystem.macos,
        );
      });

      test('isLinux is consistent with platform', () {
        expect(
          TomWs.isLinux,
          TomWs.platform.os == OperatingSystem.linux,
        );
      });

      test('isWindows is consistent with platform', () {
        expect(
          TomWs.isWindows,
          TomWs.platform.os == OperatingSystem.windows,
        );
      });

      test('osName returns OS name string', () {
        expect(TomWs.osName, isNotEmpty);
        expect(TomWs.osName, anyOf(['macos', 'linux', 'windows']));
      });

      test('arch returns architecture name', () {
        expect(TomWs.arch, isNotEmpty);
      });
    });

    group('context state', () {
      test('isLoaded returns true after load', () {
        expect(TomWs.isLoaded, isTrue);
      });

      test('reload() refreshes context', () async {
        await TomWs.reload();
        expect(TomWs.isLoaded, isTrue);
      });
    });
  });
}
