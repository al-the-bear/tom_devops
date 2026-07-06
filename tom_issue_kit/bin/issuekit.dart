/// Tom Issue Kit CLI — issue tracking tool using v2 framework.
///
/// This is the entry point that uses tom_build_base v2 for CLI handling.
/// Run `issuekit --help` for usage information.
library;

import 'dart:io';

import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_github_api/tom_github_api.dart';
import 'package:tom_issue_kit/src/config/issuekit_config.dart';
import 'package:tom_issue_kit/src/services/issue_service.dart';
import 'package:tom_issue_kit/src/v2/issuekit_executors.dart';
import 'package:tom_issue_kit/src/v2/issuekit_tool.dart';

void main(List<String> args) async {
  // Normalize non-standard -help / -version flags to --help / --version via the
  // shared tom_build_base helper (identical to what ToolRunner.run applies).
  // Bare `help` and `version` positionals are left as-is; ToolRunner's
  // dispatchers handle them (e.g. `issuekit help`, `issuekit version`).
  final normalizedArgs = ToolRunner.normalizeArgs(args);

  // Run inside the shared console_markdown zone (tom_build_base) so
  // help/version/output render consistently with buildkit and testkit.
  await runWithConsoleMarkdown(() => _runCli(normalizedArgs));
}

/// Run the issuekit CLI flow through the v2 [ToolRunner].
Future<void> _runCli(List<String> normalizedArgs) async {
  final preParser = CliArgParser(toolDefinition: issuekitTool);
  final preArgs = preParser.parse(normalizedArgs);

  // Early exit for help/version/completion and bare 'help'/'version'
  // positionals — these are global, service-free modes intercepted by
  // ToolRunner, so they must run before loading GitHub config to avoid a
  // spurious token-not-configured error (e.g. `issuekit --completion bash`).
  final isBareHelp =
      normalizedArgs.isNotEmpty && normalizedArgs.first.trim() == 'help';
  final isBareVersion =
      normalizedArgs.isNotEmpty && normalizedArgs.first.trim() == 'version';
  if (preArgs.help ||
      preArgs.version ||
      preArgs.completion != null ||
      isBareHelp ||
      isBareVersion) {
    final preRunner = ToolRunner(
      tool: issuekitTool,
      executors: const <String, CommandExecutor>{},
    );
    final preResult = await preRunner.run(normalizedArgs);
    if (!preResult.success) {
      exitCode = 1;
    }
    return;
  }

  // Load configuration from workspace root (current directory by default)
  final workspaceRoot =
      Platform.environment['TOM_WORKSPACE_ROOT'] ?? Directory.current.path;
  final config = await IssueKitConfig.load(workspaceRoot);

  // Resolve GitHub token
  final token = config.token;
  if (token == null) {
    stderr.writeln('Error: No GitHub token configured.');
    stderr.writeln(
      'Set GITHUB_TOKEN environment variable or configure '
      'token_file in tom_workspace.yaml',
    );
    exitCode = 1;
    return;
  }

  // Verify issue tracking is configured
  if (!config.isValid) {
    stderr.writeln(
      'Error: issue_tracking not configured in tom_workspace.yaml',
    );
    exitCode = 1;
    return;
  }

  // Create GitHub API client and Issue Service
  final client = GitHubApiClient(token: token);
  final service = IssueService(
    client: client,
    issuesRepo: config.issueTracking!.issuesRepo,
    testsRepo: config.issueTracking!.testsRepo,
  );

  try {
    // Create runner with all executors and run to completion. The shared
    // run → summary → exit-code tail lives in ToolRunner.runToCompletion
    // (tom_build_base) so process-exit semantics stay identical across
    // buildkit/testkit/issuekit; it writes the summary to the runner's
    // markdown-aware output sink (we already run inside runWithConsoleMarkdown).
    final runner = ToolRunner(
      tool: issuekitTool,
      executors: createIssuekitExecutors(service: service),
    );
    await runner.runToCompletion(normalizedArgs);
  } finally {
    service.close();
  }
}
