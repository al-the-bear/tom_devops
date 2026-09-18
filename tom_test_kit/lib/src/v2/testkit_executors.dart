/// Testkit v2 command executors.
///
/// These executors wrap the existing command implementations
/// to work with the v2 ToolRunner framework.
library;

import 'package:tom_build_base/tom_build_base_v2.dart';

import '../tracking/basediff_command.dart';
import '../tracking/baseline_command.dart';
import '../tracking/crossref_command.dart';
import '../tracking/diff_command.dart';
import '../tracking/flaky_command.dart';
import '../tracking/history_command.dart';
import '../tracking/lastdiff_command.dart';
import '../tracking/reset_command.dart';
import '../tracking/runs_command.dart';
import '../tracking/status_command.dart';
import '../tracking/test_command.dart';
import '../tracking/trim_command.dart';

// =============================================================================
// Helper Functions
// =============================================================================

/// The options that apply to [command], written in EITHER position.
///
/// An option written after the command name lands in `commandArgs`, not
/// `extraOptions`. Reading only the latter dropped every option in the form
/// the help text and CLAUDE.md document — `testkit :baseline
/// --test-args="--name x"` ran the whole suite. `CliArgs.optionsFor`
/// (tom_build_base 2.13.0) merges both, per-command winning.
Map<String, dynamic> _optionsFor(
  CliArgs args,
  String command, {
  List<String> aliases = const [],
}) => args.optionsFor(command, aliases: aliases);

/// Parse test-args from the resolved options.
List<String> _parseTestArgs(Map<String, dynamic> opts) {
  final testArgsStr = opts['test-args'] as String?;
  if (testArgsStr == null) return const [];
  return testArgsStr.split(' ');
}

/// Get output spec from the resolved options.
OutputSpec? _parseOutputSpec(Map<String, dynamic> opts) {
  final outputStr = opts['output'] as String?;
  if (outputStr == null) return null;
  return OutputSpec.tryParse(outputStr);
}

/// Get boolean flag from the resolved options.
bool _getFlag(Map<String, dynamic> opts, String name) {
  return opts[name] == true;
}

/// Get string option from the resolved options.
String? _getString(Map<String, dynamic> opts, String name) {
  return opts[name] as String?;
}

// =============================================================================
// Baseline Executor
// =============================================================================

/// Executor for :baseline command.
class BaselineExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'baseline');
    if (args.dryRun) {
      final outputPath =
          _getString(cmdOpts, 'file') ?? 'testlog/baseline_<timestamp>.csv';
      return ItemResult.success(
        path: context.path,
        name: context.name,
        message: '[DRY RUN] Would run tests and create baseline at $outputPath',
      );
    }

    final success = await BaselineCommand.run(
      projectPath: context.path,
      outputPath: _getString(cmdOpts, 'file'),
      testArgs: _parseTestArgs(cmdOpts),
      verbose: args.verbose,
      comment: _getString(cmdOpts, 'comment'),
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Baseline creation failed',
          );
  }
}

// =============================================================================
// Test Executor
// =============================================================================

/// Executor for :test command.
class TestExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'test');
    if (args.dryRun) {
      final opts = <String>[];
      if (_getFlag(cmdOpts, 'baseline')) opts.add('--baseline');
      if (_getFlag(cmdOpts, 'failed')) opts.add('--failed');
      if (_getFlag(cmdOpts, 'mismatched')) opts.add('--mismatched');
      if (_getFlag(cmdOpts, 'no-update')) opts.add('--no-update');
      final testArgs = _parseTestArgs(cmdOpts);
      if (testArgs.isNotEmpty) opts.add('--test-args="${testArgs.join(' ')}"');
      return ItemResult.success(
        path: context.path,
        name: context.name,
        message:
            '[DRY RUN] Would run tests and update tracking'
            '${opts.isNotEmpty ? ' (${opts.join(', ')})' : ''}',
      );
    }

    final success = await TestCommand.run(
      projectPath: context.path,
      trackingFilePath: _getString(cmdOpts, 'file'),
      testArgs: _parseTestArgs(cmdOpts),
      verbose: args.verbose,
      createBaseline: _getFlag(cmdOpts, 'baseline'),
      comment: _getString(cmdOpts, 'comment'),
      failedOnly: _getFlag(cmdOpts, 'failed'),
      mismatchedOnly: _getFlag(cmdOpts, 'mismatched'),
      noUpdate: _getFlag(cmdOpts, 'no-update'),
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Test run failed',
          );
  }
}

// =============================================================================
// Analysis Executors
// =============================================================================

/// Executor for :runs command.
class RunsExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'runs');
    final success = await RunsCommand.run(
      projectPath: context.path,
      baselineFile: _getString(cmdOpts, 'baseline-file'),
      output: _parseOutputSpec(cmdOpts),
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Runs command failed',
          );
  }
}

/// Executor for :status command.
class StatusExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'status');
    final success = await StatusCommand.run(
      projectPath: context.path,
      baselineFile: _getString(cmdOpts, 'baseline-file'),
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Status command failed',
          );
  }
}

/// Executor for :basediff command.
class BaseDiffExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'basediff');
    final success = await BaseDiffCommand.run(
      projectPath: context.path,
      baselineFile: _getString(cmdOpts, 'baseline-file'),
      output: _parseOutputSpec(cmdOpts),
      full: _getFlag(cmdOpts, 'full'),
      reportPath: _getString(cmdOpts, 'report'),
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Basediff command failed',
          );
  }
}

/// Executor for :lastdiff command.
class LastDiffExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'lastdiff');
    final success = await LastDiffCommand.run(
      projectPath: context.path,
      baselineFile: _getString(cmdOpts, 'baseline-file'),
      output: _parseOutputSpec(cmdOpts),
      full: _getFlag(cmdOpts, 'full'),
      reportPath: _getString(cmdOpts, 'report'),
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Lastdiff command failed',
          );
  }
}

/// Executor for :diff command.
///
/// Note: This command requires positional args for timestamps.
class DiffExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'diff');
    final success = await DiffCommand.run(
      projectPath: context.path,
      timestamps: args.positionalArgs,
      baselineFile: _getString(cmdOpts, 'baseline-file'),
      output: _parseOutputSpec(cmdOpts),
      full: _getFlag(cmdOpts, 'full'),
      reportPath: _getString(cmdOpts, 'report'),
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Diff command failed',
          );
  }
}

/// Executor for :history command.
///
/// Note: This command requires positional args for search term.
class HistoryExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'history');
    if (args.positionalArgs.isEmpty) {
      return ItemResult.failure(
        path: context.path,
        name: context.name,
        error: ':history requires a search term',
      );
    }

    final success = await HistoryCommand.run(
      projectPath: context.path,
      searchTerm: args.positionalArgs.join(' '),
      baselineFile: _getString(cmdOpts, 'baseline-file'),
      output: _parseOutputSpec(cmdOpts),
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'History command failed',
          );
  }
}

/// Executor for :flaky command.
class FlakyExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'flaky');
    final success = await FlakyCommand.run(
      projectPath: context.path,
      baselineFile: _getString(cmdOpts, 'baseline-file'),
      output: _parseOutputSpec(cmdOpts),
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Flaky command failed',
          );
  }
}

/// Executor for :crossreference command.
class CrossReferenceExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'crossreference', aliases: const ['crossref', 'xref']);
    final success = await CrossReferenceCommand.run(
      projectPath: context.path,
      baselineFile: _getString(cmdOpts, 'baseline-file'),
      output: _parseOutputSpec(cmdOpts),
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Crossreference command failed',
          );
  }
}

// =============================================================================
// Maintenance Executors
// =============================================================================

/// Executor for :trim command.
///
/// Note: This command requires positional arg for count.
class TrimExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    final cmdOpts = _optionsFor(args, 'trim');
    if (args.positionalArgs.isEmpty) {
      return ItemResult.failure(
        path: context.path,
        name: context.name,
        error: ':trim requires a count',
      );
    }

    final keepCount = int.tryParse(args.positionalArgs.first);
    if (keepCount == null || keepCount < 1) {
      return ItemResult.failure(
        path: context.path,
        name: context.name,
        error: ':trim requires a positive integer',
      );
    }

    if (args.dryRun) {
      return ItemResult.success(
        path: context.path,
        name: context.name,
        message:
            '[DRY RUN] Would trim baselines, keeping $keepCount most recent',
      );
    }

    final success = await TrimCommand.run(
      projectPath: context.path,
      keepCount: keepCount,
      baselineFile: _getString(cmdOpts, 'baseline-file'),
      force: args.force,
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Trim command failed',
          );
  }
}

/// Executor for :reset command.
class ResetExecutor extends CommandExecutor {
  @override
  Future<ItemResult> execute(CommandContext context, CliArgs args) async {
    if (args.dryRun) {
      return ItemResult.success(
        path: context.path,
        name: context.name,
        message: '[DRY RUN] Would reset all tracking data',
      );
    }

    final success = await ResetCommand.run(
      projectPath: context.path,
      force: args.force,
      verbose: args.verbose,
    );

    return success
        ? ItemResult.success(path: context.path, name: context.name)
        : ItemResult.failure(
            path: context.path,
            name: context.name,
            error: 'Reset command failed',
          );
  }
}

// =============================================================================
// Executor Factory
// =============================================================================

/// Create all testkit executors.
Map<String, CommandExecutor> createTestkitExecutors() {
  return {
    // Run commands
    'baseline': BaselineExecutor(),
    'test': TestExecutor(),
    // Analysis commands
    'runs': RunsExecutor(),
    'status': StatusExecutor(),
    'basediff': BaseDiffExecutor(),
    'lastdiff': LastDiffExecutor(),
    'diff': DiffExecutor(),
    'history': HistoryExecutor(),
    'flaky': FlakyExecutor(),
    'crossreference': CrossReferenceExecutor(),
    'crossref': CrossReferenceExecutor(),
    'xref': CrossReferenceExecutor(),
    // Maintenance commands
    'trim': TrimExecutor(),
    'reset': ResetExecutor(),
  };
}
