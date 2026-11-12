import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_fuzz/tom_fuzz.dart' show FuzzReport;

/// What a `:fuzz` run found in one project.
enum FuzzCampaignOutcome {
  /// Every target of every campaign ran clean.
  clean,

  /// A target failed, or a campaign did not run to its report.
  failed,

  /// The project has no campaign file (`fuzz/*_fuzz.dart`).
  noCampaign,
}

/// Implements the `:fuzz` subcommand: runs the project's fuzz campaigns
/// (`fuzz/*_fuzz.dart`, each a `main` calling tom_fuzz's `fuzzMain`) and
/// reports what they found.
///
/// Each campaign runs as `dart run <file>` in the project with the given
/// limits and writes its report as JSON, which is read back here through
/// tom_fuzz's [FuzzReport]. The campaign's own text report is shown as it
/// runs.
class FuzzCommand {
  /// The campaign files of [projectPath], sorted.
  static List<String> campaigns(String projectPath) {
    final dir = Directory(p.join(projectPath, 'fuzz'));
    if (!dir.existsSync()) return const [];
    return [
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('_fuzz.dart'))
          p.relative(f.path, from: projectPath),
    ]..sort();
  }

  /// The `fuzzMain` arguments for the limits given.
  static List<String> campaignArgs({
    int? iterations,
    int? durationSeconds,
    int? seed,
    List<String> targets = const [],
    int? timeoutMs,
    int? memoryMb,
  }) => [
    if (iterations != null) ...['--iterations', '$iterations'],
    if (durationSeconds != null) ...['--duration', '$durationSeconds'],
    if (seed != null) ...['--seed', '$seed'],
    for (final t in targets) ...['--target', t],
    if (timeoutMs != null) ...['--timeout-ms', '$timeoutMs'],
    if (memoryMb != null) ...['--memory-mb', '$memoryMb'],
  ];

  /// Runs the campaigns of [projectPath]: every campaign file, or those whose
  /// file name contains one of [campaignFilter]. [reportPath] receives the
  /// reports of all campaigns as one JSON list.
  static Future<(FuzzCampaignOutcome, List<FuzzReport>)> run({
    required String projectPath,
    List<String> campaignArgs = const [],
    List<String> campaignFilter = const [],
    String? reportPath,
    bool verbose = false,
  }) async {
    var files = campaigns(projectPath);
    if (campaignFilter.isNotEmpty) {
      files = files
          .where((f) => campaignFilter.any((c) => p.basename(f).contains(c)))
          .toList();
    }
    if (files.isEmpty) return (FuzzCampaignOutcome.noCampaign, <FuzzReport>[]);

    final reports = <FuzzReport>[];
    var failed = false;
    final scratch = Directory(p.join(projectPath, '.dart_tool', 'tom_fuzz'))
      ..createSync(recursive: true);
    for (final file in files) {
      final report = p.join(
        scratch.path,
        '${p.basenameWithoutExtension(file)}.report.json',
      );
      final reportFile = File(report);
      if (reportFile.existsSync()) reportFile.deleteSync();
      final args = ['run', file, ...campaignArgs, '--report', report];
      stdout.writeln('  Campaign: $file');
      if (verbose) stdout.writeln('  Running: dart ${args.join(' ')}');
      final process = await Process.start(
        'dart',
        args,
        workingDirectory: projectPath,
        mode: ProcessStartMode.inheritStdio,
        runInShell: Platform.isWindows,
      );
      final exit = await process.exitCode;
      if (!reportFile.existsSync()) {
        stderr.writeln(
          '[$projectPath] $file ended (exit $exit) without a report: the '
          'campaign did not run.',
        );
        failed = true;
        continue;
      }
      final decoded = jsonDecode(reportFile.readAsStringSync()) as List;
      final fileReports = [
        for (final r in decoded) FuzzReport.fromJson((r as Map).cast()),
      ];
      reports.addAll(fileReports);
      if (exit != 0 || fileReports.any((r) => !r.clean)) failed = true;
    }

    if (reportPath != null) {
      File(reportPath)
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(
          const JsonEncoder.withIndent(
            '  ',
          ).convert([for (final r in reports) r.toJson()]),
        );
    }
    final failures = reports.fold<int>(0, (n, r) => n + r.failures.length);
    final inputs = reports.fold<int>(0, (n, r) => n + r.inputsRun);
    stdout.writeln(
      '  Fuzz: ${reports.length} target(s), $inputs inputs, '
      '$failures failure(s)',
    );
    return (
      failed ? FuzzCampaignOutcome.failed : FuzzCampaignOutcome.clean,
      reports,
    );
  }
}
