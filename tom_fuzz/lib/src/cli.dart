import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'corpus.dart';
import 'engine.dart';
import 'mutators.dart';
import 'target.dart';

/// How a campaign file describes one target: the target, its mutators and
/// where its corpus is.
class FuzzCampaignTarget {
  /// The target.
  final FuzzTarget target;

  /// The mutators; [ByteMutator] alone by default.
  final List<Mutator> mutators;

  /// The corpus folder; `fuzz/corpus/<target name>` of the package by
  /// default.
  final String? corpusDirectory;

  /// Creates the description.
  const FuzzCampaignTarget(
    this.target, {
    this.mutators = const [ByteMutator()],
    this.corpusDirectory,
  });
}

/// The entry of a campaign file (`fuzz/<name>_fuzz.dart`): runs the [targets]
/// as the command line asks and exits 1 when any failed.
///
/// ```text
/// dart run fuzz/saml_fuzz.dart [--target NAME] [--iterations N]
///     [--duration SECONDS] [--seed N] [--timeout-ms MS] [--memory-mb MB]
///     [--failures DIR] [--report FILE] [--list]
/// ```
///
/// Without `--iterations` and `--duration` a campaign runs 100000 inputs per
/// target. Failures are saved under `--failures` (default the target's corpus
/// folder's `failures/`, so the next run replays them); `--report` writes the
/// reports as a JSON list. testkit's `:fuzz` command runs these files.
Future<void> fuzzMain(
  List<String> arguments,
  List<FuzzCampaignTarget> targets,
) async {
  final parser = ArgParser()
    ..addMultiOption('target', abbr: 't', help: 'Run only these targets')
    ..addOption('iterations', abbr: 'n', help: 'Inputs per target')
    ..addOption('duration', abbr: 'd', help: 'Seconds per target')
    ..addOption('seed', help: 'Seed of the mutations (default: from the clock)')
    ..addOption('timeout-ms', defaultsTo: '2000', help: 'Time bound per input')
    ..addOption('memory-mb', defaultsTo: '512', help: 'Memory bound per input')
    ..addOption('failures', help: 'Where failures are saved')
    ..addOption('report', help: 'Write the reports as JSON to this file')
    ..addFlag('list', negatable: false, help: 'List the targets and stop')
    ..addFlag('help', abbr: 'h', negatable: false);
  final ArgResults args;
  try {
    args = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n${parser.usage}');
    exitCode = 2;
    return;
  }
  if (args['help'] as bool) {
    stdout.writeln(parser.usage);
    return;
  }
  if (args['list'] as bool) {
    for (final t in targets) {
      stdout.writeln(t.target.name);
    }
    return;
  }
  final names = args['target'] as List<String>;
  final unknown = names.where((n) => !targets.any((t) => t.target.name == n));
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown target(s): ${unknown.join(', ')}');
    exitCode = 2;
    return;
  }
  final selected = names.isEmpty
      ? targets
      : targets.where((t) => names.contains(t.target.name)).toList();
  final iterationsText = args['iterations'] as String?;
  final durationText = args['duration'] as String?;
  final iterations = iterationsText == null
      ? (durationText == null ? 100000 : null)
      : int.parse(iterationsText);
  final duration = durationText == null
      ? null
      : Duration(seconds: int.parse(durationText));
  final seedText = args['seed'] as String?;

  final reports = <FuzzReport>[];
  for (final t in selected) {
    final corpusDir =
        t.corpusDirectory ?? p.join('fuzz', 'corpus', t.target.name);
    final fuzzer = Fuzzer(
      t.target,
      corpus: Corpus.directory(corpusDir),
      mutators: t.mutators,
      timeout: Duration(milliseconds: int.parse(args['timeout-ms'] as String)),
      memoryLimitBytes: int.parse(args['memory-mb'] as String) * 1024 * 1024,
      failureDirectory:
          args['failures'] as String? ?? p.join(corpusDir, 'failures'),
    );
    final report = await fuzzer.run(
      iterations: iterations,
      duration: duration,
      seed: seedText == null ? null : int.parse(seedText),
    );
    stdout.writeln(report.toText());
    reports.add(report);
  }
  final reportPath = args['report'] as String?;
  if (reportPath != null) {
    File(reportPath)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(
        const JsonEncoder.withIndent(
          '  ',
        ).convert([for (final r in reports) r.toJson()]),
      );
  }
  if (reports.any((r) => !r.clean)) exitCode = 1;
}
