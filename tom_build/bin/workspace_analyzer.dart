/// Workspace Analyzer Entry Point
///
/// Analyzes a Dart/Flutter workspace and generates `.tom_metadata/tom_master.yaml`
/// plus per-action master files.
///
/// Depends only on `tom_build` — no `tom_build_cli` or D4rt bridge required.
///
/// Usage:
///   dart run bin/workspace_analyzer.dart [workspace_path]
///   dart run bin/workspace_analyzer.dart wa-path=/path/to/workspace
///   dart run bin/workspace_analyzer.dart wa-path=. wa-include-tests
///
/// Options:
///   wa-path=<path>      Workspace path (default: parent directory of this project)
///   wa-include-tests    Include test projects (zom_*) in the output
///   --include-tests     (legacy) Include test projects
///   --help, -h          Show this help
library;

import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:tom_build/tom_build.dart';

void main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    _printUsage();
    return;
  }

  String? waPath;
  bool includeTests = false;

  for (final arg in arguments) {
    if (arg.startsWith('wa-path=')) {
      waPath = arg.substring('wa-path='.length);
    } else if (arg == 'wa-include-tests' || arg == '--include-tests') {
      includeTests = true;
    } else if (!arg.startsWith('-')) {
      // Positional argument — treat as workspace path
      waPath ??= arg;
    }
  }

  // Resolve workspace root: named param → positional → parent of current dir
  final String workspaceRoot;
  if (waPath != null) {
    workspaceRoot = path.isAbsolute(waPath)
        ? path.normalize(waPath)
        : path.normalize(path.absolute(waPath));
  } else {
    workspaceRoot = path.normalize(path.dirname(Directory.current.path));
  }

  if (!Directory(workspaceRoot).existsSync()) {
    stderr.writeln('Error: workspace path does not exist: $workspaceRoot');
    exitCode = 1;
    return;
  }

  print('Analyzing workspace: $workspaceRoot');
  if (!includeTests) {
    print(
        'Note: Excluding test projects (zom_*). Use wa-include-tests to include them.');
  }

  final options = AnalyzerOptions(includeTestProjects: includeTests);
  final analyzer = WorkspaceAnalyzer(workspaceRoot, options: options);
  await analyzer.analyze();

  print('\nWorkspace analysis complete!');
  print('Metadata written to: ${path.join(workspaceRoot, '.tom_metadata')}');
}

void _printUsage() {
  print('Workspace Analyzer — generate .tom_metadata/tom_master.yaml');
  print('');
  print('Usage:');
  print('  dart run bin/workspace_analyzer.dart [options]');
  print('  dart run bin/workspace_analyzer.dart wa-path=/path/to/workspace');
  print('  dart run bin/workspace_analyzer.dart . --include-tests');
  print('');
  print('Options (wa- prefix):');
  print('  wa-path=<path>      Workspace path (default: parent directory)');
  print('  wa-include-tests    Include test projects (zom_*)');
  print('');
  print('Legacy options:');
  print('  [path]              First positional arg as workspace path');
  print('  --include-tests     Include test projects');
  print('  --help, -h          Show this help');
}
