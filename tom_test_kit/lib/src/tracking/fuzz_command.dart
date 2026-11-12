import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:coverage/coverage.dart' show HitMap, collect;
import 'package:tom_build_base/tom_build_base.dart' show killProcessTree;
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
  /// file name contains one of [campaignFilter]; every target, or those named
  /// in [targets]. [reportPath] receives every report as one JSON list.
  ///
  /// Each target runs in a process of its own (`--target`), so its coverage
  /// is its own: when the target names coverage libraries and [coverage] is
  /// on, the process runs under the VM service, pauses on exit, and the line
  /// coverage of those libraries is collected before it is let go. A campaign
  /// whose tom_fuzz predates `--describe` (0.2.0) runs whole, as before,
  /// without coverage.
  static Future<(FuzzCampaignOutcome, List<FuzzReport>)> run({
    required String projectPath,
    List<String> campaignArgs = const [],
    List<String> campaignFilter = const [],
    List<String> targets = const [],
    bool coverage = true,
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
    final unmatched = {...targets};
    for (final file in files) {
      stdout.writeln('  Campaign: $file');
      final described = await _describe(projectPath, file);
      if (described == null) {
        if (verbose) {
          stdout.writeln('  (no --describe: run whole, without coverage)');
        }
        final (ok, fileReports) = await _runOne(
          projectPath: projectPath,
          file: file,
          args: [
            ...campaignArgs,
            for (final t in targets) ...['--target', t],
          ],
          report: p.join(
            scratch.path,
            '${p.basenameWithoutExtension(file)}.report.json',
          ),
          coverageLibraries: const [],
          verbose: verbose,
        );
        reports.addAll(fileReports);
        unmatched.removeAll(fileReports.map((r) => r.target));
        if (!ok) failed = true;
        continue;
      }
      for (final (name, libraries) in described) {
        if (targets.isNotEmpty && !targets.contains(name)) continue;
        unmatched.remove(name);
        final (ok, targetReports) = await _runOne(
          projectPath: projectPath,
          file: file,
          args: [...campaignArgs, '--target', name],
          report: p.join(
            scratch.path,
            '${p.basenameWithoutExtension(file)}.$name.report.json',
          ),
          coverageLibraries: coverage ? libraries : const [],
          verbose: verbose,
        );
        reports.addAll(targetReports);
        if (!ok) failed = true;
      }
    }
    if (unmatched.isNotEmpty) {
      stderr.writeln(
        '[$projectPath] no campaign has the target(s) ${unmatched.join(', ')}',
      );
      failed = true;
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

  /// The targets of a campaign file with their coverage libraries, or null
  /// when the file's tom_fuzz has no `--describe`.
  static Future<List<(String, List<String>)>?> _describe(
    String projectPath,
    String file,
  ) async {
    final r = await Process.run(
      'dart',
      ['run', file, '--describe'],
      workingDirectory: projectPath,
      runInShell: Platform.isWindows,
    );
    if (r.exitCode != 0) return null;
    final line = const LineSplitter()
        .convert('${r.stdout}')
        .lastWhere((l) => l.trimLeft().startsWith('['), orElse: () => '');
    if (line.isEmpty) return null;
    return [
      for (final t in jsonDecode(line) as List)
        (
          (t as Map)['target'] as String,
          [for (final l in (t['coverage'] as List?) ?? const []) '$l'],
        ),
    ];
  }

  static final _serviceUri = RegExp(
    r'The Dart VM service is listening on (\S+)',
  );

  /// Runs one campaign process and reads its reports; with
  /// [coverageLibraries], under the VM service, filling in their coverage.
  static Future<(bool, List<FuzzReport>)> _runOne({
    required String projectPath,
    required String file,
    required List<String> args,
    required String report,
    required List<String> coverageLibraries,
    required bool verbose,
  }) async {
    final reportFile = File(report);
    if (reportFile.existsSync()) reportFile.deleteSync();
    final measure = coverageLibraries.isNotEmpty;
    final dartArgs = [
      'run',
      if (measure) ...[
        '--enable-vm-service=0',
        '--no-serve-devtools',
        '--pause-isolates-on-exit',
      ],
      file,
      ...args,
      '--report',
      report,
    ];
    if (verbose) stdout.writeln('  Running: dart ${dartArgs.join(' ')}');
    final int exit;
    (int, int)? lines;
    if (!measure) {
      final process = await Process.start(
        'dart',
        dartArgs,
        workingDirectory: projectPath,
        mode: ProcessStartMode.inheritStdio,
        runInShell: Platform.isWindows,
      );
      exit = await process.exitCode;
    } else {
      final process = await Process.start(
        'dart',
        dartArgs,
        workingDirectory: projectPath,
        runInShell: Platform.isWindows,
      );
      final uri = Completer<Uri?>();
      final done = Future.wait([
        process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .forEach((line) {
              final m = _serviceUri.firstMatch(line);
              if (m != null) {
                if (!uri.isCompleted) uri.complete(Uri.parse(m.group(1)!));
                if (verbose) stdout.writeln(line);
                return;
              }
              // The campaign cannot measure coverage itself; the measured
              // figure is printed below instead of its placeholder.
              if (line.startsWith('  coverage: not measured')) return;
              stdout.writeln(line);
            }),
        process.stderr.transform(utf8.decoder).forEach(stderr.write),
      ]);
      unawaited(
        process.exitCode.then((_) {
          if (!uri.isCompleted) uri.complete(null);
        }),
      );
      final serviceUri = await uri.future;
      if (serviceUri != null) {
        try {
          final json = await collect(
            serviceUri,
            true, // resume the paused isolates afterwards
            true, // wait until the campaign has paused on exit
            false,
            {
              for (final l in coverageLibraries)
                if (l.startsWith('package:')) l.substring(8).split('/').first,
            },
          );
          final hits = await HitMap.parseJson(
            (json['coverage'] as List).cast<Map<String, dynamic>>(),
          );
          lines = lineCoverage(hits, coverageLibraries);
        } catch (e) {
          // The campaign is paused on exit and would wait for ever; its
          // report is written by then, so stopping it loses nothing.
          stderr.writeln('[$projectPath] coverage of $file not collected: $e');
          await killProcessTree(process.pid);
        }
      }
      exit = await process.exitCode;
      await done;
    }

    if (!reportFile.existsSync()) {
      stderr.writeln(
        '[$projectPath] $file ended (exit $exit) without a report: the '
        'campaign did not run.',
      );
      return (false, <FuzzReport>[]);
    }
    final decoded = jsonDecode(reportFile.readAsStringSync()) as List;
    var reports = [
      for (final r in decoded) FuzzReport.fromJson((r as Map).cast()),
    ];
    if (lines != null) {
      final (covered, coverable) = lines;
      reports = [
        for (final r in reports)
          r.withCoverage(covered: covered, coverable: coverable),
      ];
      for (final r in reports) {
        stdout.writeln('  coverage: ${r.coverageText}');
      }
    }
    return (exit == 0 && reports.every((r) => r.clean), reports);
  }

  /// Covered and coverable lines of the sources whose URI starts with one of
  /// [libraries].
  static (int, int) lineCoverage(
    Map<String, HitMap> hits,
    List<String> libraries,
  ) {
    var covered = 0, coverable = 0;
    hits.forEach((source, map) {
      if (!libraries.any(source.startsWith)) return;
      coverable += map.lineHits.length;
      covered += map.lineHits.values.where((n) => n > 0).length;
    });
    return (covered, coverable);
  }
}
