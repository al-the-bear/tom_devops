import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/cli/workspace_context.dart';

void main() {
  group('WorkspaceDiscovery', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('tom_workspace_context_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('finds workspace root in current directory', () {
      File(p.join(tempDir.path, 'tom_workspace.yaml')).createSync();

      final result = discoverWorkspace(tempDir.path);
      expect(result.found, isTrue);
      // Absolute path comparison
      expect(result.workspacePath, equals(tempDir.absolute.path));
    });

    test('finds workspace root in parent directory', () {
      File(p.join(tempDir.path, 'tom_workspace.yaml')).createSync();
      final deepDir = Directory(p.join(tempDir.path, 'level1', 'level2'))..createSync(recursive: true);

      final result = discoverWorkspace(deepDir.path);
      expect(result.found, isTrue);
      expect(result.workspacePath, equals(tempDir.absolute.path));
    });

    test('returns notFound if no workspace found', () {
      // Ensure specific temp dir doesn't accidentally live inside a workspace
      // But assuming system temp is outside.
      
      final result = discoverWorkspace(tempDir.path);
      expect(result.found, isFalse);
      expect(result.workspacePath, isNull);
    });
  });
}
