// The workspace's docs action (tom_workspace.yaml): generated API
// documentation.
//
// `doc/` is hand-authored (CLAUDE.md, Documentation Placement), and
// `doc/api/` holds the hand-written API summaries
// (_copilot_guidelines/dart/api_summary_creation.md). dartdoc's default
// output folder is that same `doc/api/`, so the action writes the generated
// HTML to `build/api_doc/` instead: gitignored, and outside every folder a
// person writes in. Dart and Flutter packages only; no other type has an API
// documentation generator configured.
@TestOn('vm')
library;

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';

import 'support/workspace_support.dart';

late final ActionDef _docs;

void main() {
  setUpAll(() {
    _docs = TomWorkspace.fromYaml(
      readWorkspaceYaml(findWorkspaceRoot()),
    ).actions['docs']!;
  });

  test('DA-1: Dart and Flutter packages run dart doc into build/api_doc', () {
    expect(commandsOf(_docs.defaultConfig), [dartDoc]);
    expect(_docs.typeConfigs, isEmpty);
    expect(
      _docs.appliesToTypes,
      unorderedEquals(WorkspaceAnalyzer.dartProjectTypes),
    );
    expect(_docs.skipTypes, isNull);
  });

  test('DA-2: generated documentation never lands in doc/', () {
    for (final command in commandsOf(_docs.defaultConfig)) {
      final output = RegExp(r'--output[= ](\S+)').firstMatch(command);
      expect(
        output,
        isNotNull,
        reason: 'dart doc without --output writes doc/api/: $command',
      );
      final segments = p.posix.split(output!.group(1)!);
      expect(segments, isNot(contains('doc')), reason: command);
      expect(
        segments.first,
        'build',
        reason: 'build/ is gitignored in every repository: $command',
      );
    }
  });
}
