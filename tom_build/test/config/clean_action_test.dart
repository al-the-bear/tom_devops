// The workspace's clean action (tom_workspace.yaml) against the project
// types the workspace analyzer assigns: it removes what a build generated.
//
// - Dart (the default): buildkit's :cleanup, which deletes the files the
//   project's buildkit.yaml `cleanup:` list names (and skips itself without
//   one), and the API docs the docs action generated (build/api_doc/).
//   Flutter apps `flutter clean` instead of the latter (build/, .dart_tool/).
// - TypeScript and VS Code extensions: their `clean` script if any, then
//   `tsc --build --clean`, which deletes exactly what tsc built.
// - Plain JavaScript: their `clean` script if any (nothing is compiled).
// - Java: build/ (Gradle, build_jar.sh) and target/ (Maven).
// - Python: build/ and *.egg-info (setuptools).
//
// CL-1..5 read tom_workspace.yaml. That every tracked project can run its
// clean is live_workspace_test.dart LW-5.
@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';

import 'support/workspace_support.dart';

/// JavaScript/TypeScript types compiled by tsc (detected with a
/// tsconfig.json; extensions are TypeScript in this workspace).
const _typescriptTypes = {
  'vscode_extension',
  'typescript_node',
  'typescript_react',
  'typescript_vue',
  'typescript',
};

late final ActionDef _clean;

void main() {
  setUpAll(() {
    _clean = TomWorkspace.fromYaml(
      readWorkspaceYaml(findWorkspaceRoot()),
    ).actions['clean']!;
  });

  test('CL-1: Dart projects run buildkit :cleanup and remove generated API '
      'docs (the default)', () {
    expect(commandsOf(_clean.defaultConfig), [buildkitCleanup, apiDocClean]);
    for (final type in WorkspaceAnalyzer.dartProjectTypes.where(
      (t) => t != 'flutter_app',
    )) {
      expect(_clean.typeConfigs, isNot(contains(type)), reason: type);
    }
  });

  test('CL-2: Flutter apps also run flutter clean', () {
    expect(commandsOf(_clean.typeConfigs['flutter_app']), [
      buildkitCleanup,
      flutterClean,
    ]);
  });

  test('CL-3: TypeScript removes tsc output, plain JavaScript only its '
      'clean script', () {
    for (final type in WorkspaceAnalyzer.javascriptProjectTypes) {
      expect(
        commandsOf(_clean.typeConfigs[type]),
        _typescriptTypes.contains(type) ? [npmClean, tscClean] : [npmClean],
        reason: type,
      );
    }
  });

  test('CL-4: Java and Python remove their build folders', () {
    expect(commandsOf(_clean.typeConfigs['java']), [javaClean]);
    for (final type in WorkspaceAnalyzer.pythonProjectTypes) {
      expect(commandsOf(_clean.typeConfigs[type]), [pythonClean], reason: type);
    }
  });

  test('CL-5: every type is handled; nothing is filtered out', () {
    expect(_clean.skipTypes, isNull);
    expect(_clean.appliesToTypes, isNull);
    expect({
      ...WorkspaceAnalyzer.dartProjectTypes,
      ..._clean.typeConfigs.keys,
    }, WorkspaceAnalyzer.projectTypes);
  });
}
