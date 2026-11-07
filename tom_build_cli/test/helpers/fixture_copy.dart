import 'dart:io';

import 'package:path/path.dart' as path;

/// A working copy of the checked-in workspace-analyzer fixtures, for suites
/// whose analyzer runs write into the workspace they analyse.
///
/// `WorkspaceAnalyzer.analyze()` writes `.tom_metadata/tom_master*.yaml` into
/// the workspace it is given. Run on `test/fixtures/workspace_analyzer/`
/// directly, it rewrote those TRACKED files on every run, so a run left the
/// repository modified. The copy is made once per test file under this
/// package's `.dart_tool/` (ignored) and removed by [deleteFixtureCopy].
String workspaceAnalyzerFixtures() => _copy ??= _makeCopy(
  path.join(Directory.current.path, 'test', 'fixtures', 'workspace_analyzer'),
);

String? _copy;

String _makeCopy(String source) {
  final base = Directory(
    path.join(Directory.current.path, '.dart_tool', 'fixture_copies'),
  )..createSync(recursive: true);
  final target = base.createTempSync('workspace_analyzer_').path;
  _copyDirectory(Directory(source), Directory(target));
  return target;
}

void _copyDirectory(Directory source, Directory target) {
  target.createSync(recursive: true);
  for (final entity in source.listSync(followLinks: false)) {
    final name = path.basename(entity.path);
    if (entity is Directory) {
      _copyDirectory(entity, Directory(path.join(target.path, name)));
    } else if (entity is File) {
      entity.copySync(path.join(target.path, name));
    }
  }
}

/// Remove this file's copy; call from `tearDownAll`.
void deleteFixtureCopy() {
  final copy = _copy;
  if (copy != null && Directory(copy).existsSync()) {
    Directory(copy).deleteSync(recursive: true);
  }
  _copy = null;
}
