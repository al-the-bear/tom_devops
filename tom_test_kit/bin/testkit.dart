/// Tom Test Kit CLI — test result tracking tool.
///
/// Run `testkit --help` for usage information.
library;

import 'dart:io';

import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:utopia_tui/utopia_tui.dart';
import 'package:tom_test_kit/src/v2/testkit_executors.dart';
import 'package:tom_test_kit/src/v2/testkit_tool.dart';
import 'package:tom_test_kit/src/tui/app/test_kit_tui_app.dart';
import 'package:tom_test_kit/src/tui/tui_command_registry.dart';
import 'package:tom_test_kit/src/tui/commands/baseline_tui_command.dart';
import 'package:tom_test_kit/src/tui/commands/test_tui_command.dart';

void main(List<String> args) async {
  // Normalize non-standard -help / -version flags via the shared tom_build_base
  // helper (identical to what ToolRunner.run applies). Bare `help` positional is
  // passed as-is; ToolRunner's positional dispatcher handles it.
  final normalizedArgs = ToolRunner.normalizeArgs(args);

  // Parse args to check for TUI mode first
  final parser = CliArgParser(toolDefinition: testkitTool);
  final cliArgs = parser.parse(normalizedArgs);

  // Check for --tui mode. The TUI renders its own frames and must run OUTSIDE
  // the console_markdown zone to avoid interfering with terminal control.
  if (cliArgs.extraOptions['tui'] == true) {
    await _runTuiMode(cliArgs);
    return;
  }

  // Run the CLI inside the shared console_markdown zone (tom_build_base) so
  // help/version/output render consistently with buildkit and issuekit.
  await runWithConsoleMarkdown(() => _runCli(normalizedArgs));
}

/// Run the standard (non-TUI) CLI flow through the v2 [ToolRunner].
Future<void> _runCli(List<String> normalizedArgs) async {
  // Create runner with all executors
  final runner = ToolRunner(
    tool: testkitTool,
    executors: createTestkitExecutors(),
  );

  // Run to completion — the shared run → summary → exit-code tail lives in
  // ToolRunner.runToCompletion (tom_build_base) so process-exit semantics stay
  // identical across buildkit/testkit/issuekit. It writes the summary to the
  // runner's markdown-aware output sink (we run inside runWithConsoleMarkdown).
  await runner.runToCompletion(normalizedArgs);
}

/// Run TUI mode with the existing TUI implementation.
Future<void> _runTuiMode(CliArgs args) async {
  // Resolve project path from navigation args
  final projectPath = args.root ?? Directory.current.path;

  // Build command registry with built-in commands
  final registry = TuiCommandRegistry()
    ..registerCommand(BaselineTuiCommand())
    ..registerCommand(TestTuiCommand());

  // Launch TUI
  final app = TestKitTuiApp(registry: registry, projectPath: projectPath);
  await TuiRunner(app).run();

  // Restore terminal line discipline after TUI exits.
  await Process.run('stty', ['sane'], runInShell: true);
}
