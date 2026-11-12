import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../util/format_helpers.dart';
import 'mutation_catalogue.dart';
import 'mutation_sweep.dart';

/// The result of `:mutations` on one project, for the executor.
class MutationsOutcome {
  /// Whether the project passes.
  final bool passed;

  /// The exit code it stands for: surviving + invalid (1 for a sweep that
  /// stopped early, 0 when it passed).
  final int exitCode;

  /// A one-line summary.
  final String message;

  /// The sweep's result (null for `--list`, a dry run or a config error).
  final MutationSweepResult? result;

  /// Creates an outcome.
  const MutationsOutcome({
    required this.passed,
    required this.exitCode,
    required this.message,
    this.result,
  });
}

/// Implements the `:mutations` subcommand: the catalogued mutation sweep of
/// [MutationSweep] over one package, with its report and gate.
///
/// The report goes to testkit's gitignored `testlog/` as
/// `mutations_<MMDD_HHMM>.json` and `.md` (killed, survived, invalid and
/// skipped per module, the kill rate, every survivor with its behaviour).
/// Without `--min-killed` every survivor and invalid mutant fails the
/// project; with it, the project passes when the kill rate reaches the
/// threshold. The exit code of a failing project is its surviving + invalid
/// count.
class MutationsCommand {
  /// Runs the command for [projectPath].
  static Future<MutationsOutcome> run({
    required String projectPath,
    List<String> modules = const [],
    bool listOnly = false,
    String? cataloguePath,
    String? requirementsPath,
    String? reportBase,
    Duration? timeout,
    double? minKilled,
    bool dryRun = false,
    void Function(String line)? log,
  }) async {
    final void Function(String) out = log ?? (line) => stdout.writeln(line);
    final MutationCatalogue catalogue;
    final Map<String, MutationRequirement> requirements;
    try {
      catalogue = MutationCatalogue.load(
        p.join(projectPath, cataloguePath ?? kDefaultMutationCatalogue),
      );
      requirements = MutationRequirement.load(
        p.join(projectPath, requirementsPath ?? kDefaultMutationRequirements),
      );
    } on MutationConfigError catch (e) {
      out('  $e');
      return MutationsOutcome(passed: false, exitCode: 1, message: '$e');
    }

    final sweep = MutationSweep(
      projectPath: projectPath,
      catalogue: catalogue,
      requirements: requirements,
      modules: modules,
      timeout: timeout ?? const Duration(minutes: 10),
      log: out,
    );
    if (listOnly || dryRun) {
      final listed = sweep.list();
      if (listed.error != null) {
        out('  ${listed.error}');
        return MutationsOutcome(
          passed: false,
          exitCode: 1,
          message: listed.error!,
        );
      }
      return MutationsOutcome(
        passed: true,
        exitCode: 0,
        message:
            '${dryRun ? '[DRY RUN] ' : ''}'
            '${catalogue.entries.length} catalogued mutation(s)',
      );
    }

    final result = await sweep.run();
    final base =
        reportBase ??
        p.join(
          projectPath,
          'testlog',
          'mutations_${baselineTimestamp(DateTime.now())}',
        );
    Directory(p.dirname(base)).createSync(recursive: true);
    File('$base.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(result.toJson()),
    );
    File('$base.md').writeAsStringSync(
      result.toMarkdown(title: 'Mutation sweep: ${p.basename(projectPath)}'),
    );

    if (result.error != null) {
      out('\n${result.error}');
      return MutationsOutcome(
        passed: false,
        exitCode: 1,
        message: result.error!.split('\n').first,
        result: result,
      );
    }

    final rate = result.killRate;
    out('');
    out(
      '${result.run} mutation(s), ${result.killed} killed, '
      '${result.survived} survived, ${result.invalid} did not compile'
      '${result.skipped > 0 ? ', ${result.skipped} skipped' : ''}'
      ' — kill rate ${rate == null ? 'not measured' : '${rate.toStringAsFixed(1)} %'}',
    );
    for (final o in result.outcomes) {
      final label = switch (o.verdict) {
        MutationVerdict.survived => 'survived',
        MutationVerdict.invalid => 'does not compile',
        _ => null,
      };
      if (label == null) continue;
      out('  $label -- ${o.entry.module}: ${o.entry.behaviour}');
      out('    ${o.entry.file}  ->  ${jsonEncode(o.entry.replace)}');
    }
    out('  report: ${p.relative('$base.md', from: projectPath)} (and .json)');

    final failures = result.survived + result.invalid;
    final bool passed;
    String verdict;
    if (minKilled != null) {
      if (rate == null) {
        passed = false;
        verdict = 'NOT MEASURED: no mutation ran';
      } else {
        passed = rate >= minKilled;
        verdict =
            'kill rate ${rate.toStringAsFixed(1)} % '
            '${passed ? '>=' : '<'} ${minKilled.toStringAsFixed(1)} %';
      }
    } else {
      passed = failures == 0;
      verdict = passed
          ? 'every mutation killed'
          : '$failures mutation(s) survived or did not compile';
    }
    return MutationsOutcome(
      passed: passed,
      exitCode: passed ? 0 : (failures == 0 ? 1 : failures),
      message: verdict,
      result: result,
    );
  }
}
