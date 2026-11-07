// The workspace's build actions (tom_workspace.yaml) against the project
// types the workspace analyzer assigns.
//
// - `build`: the whole build of a project. Dart and Flutter run buildkit's
//   chain, which does only what the project's buildkit.yaml configures
//   (pub get, build_runner, d4rtgen, versioner, native compilation);
//   JavaScript/TypeScript run their package script; Java its build_jar.sh;
//   Python has nothing to build.
// - `pubget`, `builder_runner`, `bin_release`: single buildkit steps, for
//   Dart and Flutter projects only.
//
// BA-1..7 read tom_workspace.yaml. That every tracked project can run its
// build is live_workspace_test.dart LW-3.
@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';

import 'support/workspace_support.dart';

late final Map<String, ActionDef> _actions;

void main() {
  setUpAll(() async {
    _actions = TomWorkspace.fromYaml(
      await readClonedWorkspaceYaml(),
    ).actions;
  });

  group('the build action', () {
    test(
      'BA-1: Dart and Flutter projects run the buildkit chain (default)',
      () {
        final build = _actions['build']!;
        expect(commandsOf(build.defaultConfig), [buildkitBuild]);
        for (final type in WorkspaceAnalyzer.dartProjectTypes) {
          expect(build.typeConfigs, isNot(contains(type)), reason: type);
        }
      },
    );

    test('BA-2: extensions compile, other JS/TS packages run their build '
        'script', () {
      final build = _actions['build']!;
      expect(commandsOf(build.typeConfigs['vscode_extension']), [
        extensionBuild,
      ]);
      for (final type in WorkspaceAnalyzer.javascriptProjectTypes.where(
        (t) => t != 'vscode_extension',
      )) {
        expect(commandsOf(build.typeConfigs[type]), [
          packageBuild,
        ], reason: type);
      }
    });

    test('BA-3: Java builds its jar, Python is skipped', () {
      final build = _actions['build']!;
      expect(commandsOf(build.typeConfigs['java']), [javaBuild]);
      expect(
        build.skipTypes,
        unorderedEquals(WorkspaceAnalyzer.pythonProjectTypes),
      );
      expect(build.appliesToTypes, isNull);
    });

    test('BA-4: every non-Dart type has exactly one of: a config, a skip', () {
      final build = _actions['build']!;
      final configured = build.typeConfigs.keys.toSet();
      final skipped = build.skipTypes!.toSet();
      expect(configured.intersection(skipped), isEmpty);
      expect(
        configured.union(skipped),
        WorkspaceAnalyzer.projectTypes.difference(
          WorkspaceAnalyzer.dartProjectTypes,
        ),
      );
    });
  });

  group('Dart-only build steps', () {
    for (final (rule, action, command) in [
      ('BA-5', 'pubget', 'buildkit --nested :pubget'),
      ('BA-6', 'builder_runner', 'buildkit --nested :runner'),
      ('BA-7', 'bin_release', 'buildkit --nested :compiler'),
    ]) {
      test('$rule: $action runs `$command` for Dart and Flutter only', () {
        final def = _actions[action]!;
        expect(commandsOf(def.defaultConfig), [command]);
        expect(def.typeConfigs, isEmpty);
        expect(
          def.appliesToTypes,
          unorderedEquals(WorkspaceAnalyzer.dartProjectTypes),
        );
        expect(def.skipTypes, isNull);
      });
    }
  });
}
