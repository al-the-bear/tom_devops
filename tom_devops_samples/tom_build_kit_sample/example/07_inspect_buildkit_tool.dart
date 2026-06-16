// The real thing — introspect buildkit's own ToolDefinition.
//
// buildkit is just a (large) `ToolDefinition` assembled from the same
// `CommandDefinition` / `OptionDefinition` pieces used in examples 05 and 06.
// Because a definition is plain data, we can inspect it without building
// anything: no processes, no network, no filesystem traversal.
//
// This is the bridge from "author a toy tool" to "this is how buildkit is put
// together" — `:pubget`, the command this sample's quest is about, is right
// here in the command list, scoped to Dart projects exactly like our `:greet`.
//
// Run: dart run example/07_inspect_buildkit_tool.dart

import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_build_kit/tom_build_kit.dart';

Future<void> main() async {
  print('Tool: ${buildkitTool.name}');
  // expected output: Tool: buildkit

  print('Multi-command mode: ${buildkitTool.mode == ToolMode.multiCommand}');
  // expected output: Multi-command mode: true

  print('Has :pubget command: ${buildkitTool.findCommand('pubget') != null}');
  // expected output: Has :pubget command: true

  print('Has :cleanup command: ${buildkitTool.findCommand('cleanup') != null}');
  // expected output: Has :cleanup command: true

  // Commands carry their own nature requirements, just like our sample tools.
  final pubget = buildkitTool.findCommand('pubget')!;
  final dartScoped = pubget.worksWithNatures.contains(DartProjectFolder);
  print(':pubget scoped to Dart projects: $dartScoped');
  // expected output: :pubget scoped to Dart projects: true

  // Aliases resolve through findCommand too (:pg is the short form of :pubget).
  print(':pg resolves to: ${buildkitTool.findCommand('pg')?.name}');
  // expected output: :pg resolves to: pubget
}
