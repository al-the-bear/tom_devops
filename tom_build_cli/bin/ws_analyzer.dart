/// Workspace Analyzer - Production Mode
///
/// Analyzes a Dart/Flutter workspace and creates metadata files in
/// `.tom_metadata/` including a complete `index.yaml` file.
///
/// This entrypoint excludes test projects (those starting with 'zom_').
/// Use ws_analyzer_all.dart to include test projects.
///
/// Usage (legacy):
///   dart run bin/ws_analyzer.dart [workspace_path] [--include-tests]
///
/// Usage (new named parameters with wa- prefix):
///   dart run bin/ws_analyzer.dart wa-path=/path/to/workspace
///   dart run bin/ws_analyzer.dart wa-path=. wa-include-tests
///
/// Options:
///   wa-path=<path>     Workspace path (default: parent directory)
///   wa-include-tests   Include test projects (zom_*) in the output
///   --include-tests    (legacy) Include test projects
///
/// If no path is provided, uses the parent directory of the current project.
library;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

void main(List<String> arguments) async {
  final args = parseWorkspaceAnalyzerArgs(arguments);

  // Handle help
  if (args.help) {
    _printUsage();
    return;
  }

  // Parse include-tests flag (both new and legacy)
  final includeTests = args.hasFlag('include-tests') || 
      arguments.contains('--include-tests');

  // Determine workspace root - check named param first, then positional, then default
  final currentDir = Directory.current.path;
  String workspaceRoot;
  
  if (args.has('path')) {
    workspaceRoot = args.resolvePath(args['path']!);
  } else if (args.positionalArgs.isNotEmpty) {
    workspaceRoot = path.isAbsolute(args.positionalArgs.first)
        ? args.positionalArgs.first
        : path.absolute(args.positionalArgs.first);
  } else {
    workspaceRoot = path.dirname(currentDir);
  }

  print('Analyzing workspace: $workspaceRoot');
  if (!includeTests) {
    print('Note: Excluding test projects (zom_*). Use wa-include-tests to include them.');
  }

  final options = AnalyzerOptions(includeTestProjects: includeTests);
  final analyzer = WorkspaceAnalyzer(workspaceRoot, options: options);
  await analyzer.analyze();

  print('\nWorkspace analysis complete!');
  print('Metadata written to: ${path.join(workspaceRoot, '.tom_metadata')}');
}

void _printUsage() {
  print('Workspace Analyzer - Generate workspace metadata');
  print('');
  print('Analyzes a Dart/Flutter workspace and creates .tom_metadata/index.yaml');
  print('');
  print('Usage:');
  print('  dart run tom_build_cli:ws_analyzer [options]');
  print('  dart run tom_build_cli:ws_analyzer wa-path=/path/to/workspace');
  print('  dart run tom_build_cli:ws_analyzer . --include-tests');
  print('');
  print('Options (wa- prefix):');
  print('  wa-path=<path>     Workspace path (default: parent directory)');
  print('  wa-include-tests   Include test projects (zom_*)');
  print('');
  print('Legacy options:');
  print('  [path]             First positional arg as workspace path');
  print('  --include-tests    Include test projects');
  print('  --help, -h         Show this help');
}
