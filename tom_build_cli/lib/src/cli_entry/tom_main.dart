/// Tom CLI entry point.
///
/// This file provides a callable entry point for the tom CLI tool.
library;

import 'dart:io';
import 'package:tom_build_cli/tom_build_cli.dart';

/// Main entry point for the Tom CLI.
Future<void> tomMain(List<String> args) async {
  final cli = TomCli();
  final result = await cli.run(args);

  if (result.message != null && result.message!.isNotEmpty) {
    print(result.message);
  }

  if (result.error != null && result.error!.isNotEmpty) {
    stderr.writeln(result.error);
  }

  exit(result.exitCode);
}
