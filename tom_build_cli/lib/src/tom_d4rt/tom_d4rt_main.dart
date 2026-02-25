/// TomD4rt Main Entry Point.
///
/// Provides the main entry point for running TomD4rt REPL or scripts.
library;

import 'dart:io';

import '../tom/cli/tom_cli.dart';
import 'tom_d4rt_repl.dart';

/// Execution mode for the tom command.
enum TomExecutionMode {
  /// Execute Tom CLI commands and exit.
  tomCommand,
  
  /// Forward to TomD4rt (REPL or script execution).
  tomD4rt,
}

/// Determine the execution mode based on command-line arguments.
/// 
/// Returns [TomExecutionMode.tomCommand] if any argument starts with ':' or '!'.
/// Otherwise returns [TomExecutionMode.tomD4rt].
TomExecutionMode determineExecutionMode(List<String> args) {
  // Check for Tom commands (: or ! prefix only)
  for (final arg in args) {
    if (arg.startsWith(':') || arg.startsWith('!')) {
      return TomExecutionMode.tomCommand;
    }
  }
  
  // No :command present -> EXCLUSIVELY handled by TomD4rt
  return TomExecutionMode.tomD4rt;
}

/// Run the TomD4rt REPL or execute a script.
/// 
/// This handles all TomD4rt mode execution including:
/// - Starting the interactive REPL
/// - Executing script files
/// - Replaying session files
Future<int> runTomD4rt(List<String> args) async {
  final repl = TomD4rtRepl();
  await repl.run(args);
  return 0;
}

/// Entry point for REPL-originated Tom commands.
/// 
/// Handles differences from direct CLI execution:
/// - Working directory: Uses REPL's cwd (passed via context)
/// - Output: Uses console_markdown (already active via zone)
Future<void> runTomFromRepl({
  required List<String> args,
  required String cwd,
}) async {
  final cli = TomCli(
    config: TomCliConfig(workspacePath: cwd),
  );
  final result = await cli.run(args);
  
  if (result.message != null && result.message!.isNotEmpty) {
    print(result.message);
  }
  
  if (result.error != null && result.error!.isNotEmpty) {
    stderr.writeln(result.error);
  }
}
