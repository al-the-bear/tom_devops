import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';

/// Where the workspace analyzer writes when it is not told where to.
///
/// The analyzer entry points (tom_build's `workspace_analyzer`, tom_build_cli's
/// `ws_analyzer`, `ws_analyzer_all` and `ws_analyzer_main`) used to default to
/// the parent of the current directory and write `.tom_metadata/` there. Run
/// from `_scripts/bin` or `tom_ai/basics`, that planted `.tom_metadata/`
/// folders inside the workspace, and every root finder that takes the nearest
/// `.tom_metadata` as the workspace root then stopped there. The default is now
/// the nearest directory holding `tom_workspace.yaml`, and none means none.
void main() {
  late Directory scratch;

  setUp(() {
    scratch = Directory(
      p.join(Directory.current.path, '.dart_tool', 'analyzer_root_test'),
    );
    if (scratch.existsSync()) scratch.deleteSync(recursive: true);
    scratch.createSync(recursive: true);
  });

  tearDown(() {
    if (scratch.existsSync()) scratch.deleteSync(recursive: true);
  });

  test('WA-ROOT-1: the default root is the nearest tom_workspace.yaml above '
      'the start [2026-11-09]', () {
    File(p.join(scratch.path, 'tom_workspace.yaml')).writeAsStringSync('');
    final deep = Directory(p.join(scratch.path, '_scripts', 'bin'))
      ..createSync(recursive: true);

    expect(
      WorkspaceAnalyzer.findWorkspaceRoot(deep.path),
      p.normalize(scratch.absolute.path),
    );
  });

  test('WA-ROOT-2: a stray .tom_metadata is not a workspace root '
      '[2026-11-09]', () {
    File(p.join(scratch.path, 'tom_workspace.yaml')).writeAsStringSync('');
    final sub = Directory(p.join(scratch.path, 'tom_ai', 'basics'))
      ..createSync(recursive: true);
    Directory(p.join(scratch.path, 'tom_ai', '.tom_metadata')).createSync();

    expect(
      WorkspaceAnalyzer.findWorkspaceRoot(sub.path),
      p.normalize(scratch.absolute.path),
    );
  });

  test('WA-ROOT-3: no tom_workspace.yaml above the start is no root, not the '
      'parent directory [2026-11-09]', () {
    final sub = Directory(p.join(scratch.path, 'a', 'b'))
      ..createSync(recursive: true);
    // The scratch dir lives inside the workspace, so start from a directory
    // with no tom_workspace.yaml anywhere above it: the filesystem root.
    final root = Directory(p.rootPrefix(sub.absolute.path));

    expect(WorkspaceAnalyzer.findWorkspaceRoot(root.path), isNull);
  });
}
