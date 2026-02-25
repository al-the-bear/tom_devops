/// Workspace Analyzer - All Projects Mode
///
/// Analyzes a Dart/Flutter workspace and creates metadata files in
/// `.tom_metadata/` including a complete `index.yaml` file.
///
/// This entrypoint includes ALL projects, including test projects (zom_*).
/// Use ws_analyzer.dart for production builds that exclude test projects.
///
/// Usage:
///   dart run bin/ws_analyzer_all.dart [workspace_path]
///
/// If no path is provided, uses the parent directory of the current project.
library;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tom_build/tom_build.dart';

void main(List<String> arguments) async {
  // Determine workspace root
  final currentDir = Directory.current.path;
  final workspaceRoot = arguments.isNotEmpty
      ? path.absolute(arguments.first)
      : path.dirname(currentDir);

  print('Analyzing workspace: $workspaceRoot');
  print('Including all projects (including test projects zom_*)');

  final analyzer = WorkspaceAnalyzer(workspaceRoot, options: AnalyzerOptions.all);
  await analyzer.analyze();

  print('\nWorkspace analysis complete!');
  print('Metadata written to: ${path.join(workspaceRoot, '.tom_metadata')}');
}
