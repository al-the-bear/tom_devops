#!/usr/bin/env dart

/// Standalone findproject tool.
///
/// Resolves a project by name, project ID, or folder name and prints
/// the absolute path to stdout.  Designed to be wrapped by a shell
/// function for `cd`:
///
/// ```bash
/// goto() { local d; d="$(findproject "$@" 2>/dev/null)"; if [[ -n "$d" && -d "$d" ]]; then cd "$d"; else findproject "$@"; return 1; fi; }
/// ```
library;

import 'dart:io';

import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_build_kit/src/v2/executors/findproject_executor.dart';

Future<void> main(List<String> arguments) async {
  final executor = FindProjectExecutor();

  final args = CliArgs(
    root: Directory.current.path,
    positionalArgs: arguments.where((a) => !a.startsWith('-')).toList(),
    verbose: arguments.contains('-v') || arguments.contains('--verbose'),
  );

  final result = await executor.executeWithoutTraversal(args);

  if (!result.success) {
    exit(1);
  }
}
