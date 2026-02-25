import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/cli/tom_cli.dart';
import 'package:tom_build_cli/src/tom/cli/workspace_context.dart';

void main() {
  group('TomCli - Automatic Master Generation', () {
    late Directory tempDir;
    late String workspacePath;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('tom_cli_master_test');
      workspacePath = tempDir.path;
      
      // Reset generic singleton
      WorkspaceContext.reset();
      
      // Create minimal workspace
      File(p.join(workspacePath, 'tom_workspace.yaml')).writeAsStringSync('''
projects: []
groups: {}
pipelines: {}
''');
      
      // Create .tom_metadata
      Directory(p.join(workspacePath, '.tom_metadata')).createSync();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
      WorkspaceContext.reset();
    });

    test('generates master files before workspace action', () async {
      // We'll run a non-existent workspace action which should fail, 
      // but PRE-generation should still happen.
      // Wait, if validation happens early? 
      // ParsedArguments doesn't validate action existence against workspace config, 
      // only internal commands logic.
      // But _executeWorkspaceAction will try to resolve projects.
      
      // Better: use internal command that requires workspace, e.g. :analyze
      // Actually :analyze explicitly generates master files anyway.
      
      // Let's use :version-bump, which requires workspace but doesn't explicitly generate master files
      // (in the placeholder implementation at least).
      
      // But wait! Master files are generated in .tom_metadata/tom_master.yaml
      
      final cli = TomCli(
        config: TomCliConfig(workspacePath: workspacePath),
      );
      
      // :version-bump requires workspace (requiresWorkspace=true)
      // So it should trigger ensureMasterFilesGenerated
      await cli.run([':version-bump']);
      
      final masterFile = File(p.join(workspacePath, '.tom_metadata', 'tom_master.yaml'));
      expect(masterFile.existsSync(), isTrue, reason: 'tom_master.yaml should be generated');
      
      // Double check it was generated
      final content = masterFile.readAsStringSync();
      expect(content, contains('projects:'), reason: 'Should contain basics');
    });

    test('skips master generation for non-workspace commands', () async {
      final cli = TomCli(
        config: TomCliConfig(workspacePath: workspacePath),
      );
      
      await cli.run([':help']);
      
      final masterFile = File(p.join(workspacePath, '.tom_metadata', 'tom_master.yaml'));
      expect(masterFile.existsSync(), isFalse, reason: 'tom_master.yaml should NOT be generated for :help');
    });
  });
}
