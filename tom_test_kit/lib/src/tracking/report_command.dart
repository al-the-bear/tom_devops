import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../model/line_coverage.dart';
import '../model/test_run.dart';
import '../model/tracking_file.dart';
import '../util/file_helpers.dart';
import '../util/format_helpers.dart';
import '../util/output_formatter.dart';
import 'flaky_command.dart';
import 'status_command.dart';

/// Where a project stands in the `:report` table.
enum ReportState {
  /// No tracking file in `testlog/`: never baselined here, so nothing is
  /// known about its tests. Never counted as clean.
  notMeasured('not measured'),

  /// A test that passed in the baseline fails in the latest run.
  regressed('regressed'),

  /// Tests fail in the latest run, none of them a regression.
  failing('failing'),

  /// Every test of the latest run passed or was skipped.
  green('green');

  final String label;
  const ReportState(this.label);
}

/// One project's row of the `:report` table, read from the latest tracking
/// file in its `testlog/`.
class ProjectReport {
  /// The project's path, relative to the execution root.
  final String project;

  /// The tracking file read, relative to the project; null when none.
  final String? trackingFile;

  /// When the latest run was made; null when not measured.
  final DateTime? lastRun;

  /// Runs in the tracking file, the baseline included.
  final int runs;

  /// Results of the latest run.
  final int passed, failed, skipped;

  /// Tests that passed in the baseline and fail in the latest run.
  final int regressions;

  /// Tests that passed in one run and failed in another.
  final int flaky;

  /// The latest run's line coverage, when it was measured.
  final LineCoverage? coverage;

  const ProjectReport({
    required this.project,
    this.trackingFile,
    this.lastRun,
    this.runs = 0,
    this.passed = 0,
    this.failed = 0,
    this.skipped = 0,
    this.regressions = 0,
    this.flaky = 0,
    this.coverage,
  });

  /// A project without tracking data.
  const ProjectReport.notMeasured(this.project)
    : trackingFile = null,
      lastRun = null,
      runs = 0,
      passed = 0,
      failed = 0,
      skipped = 0,
      regressions = 0,
      flaky = 0,
      coverage = null;

  /// Reads the latest tracking file of the project at [projectPath]; a
  /// project without one (or with one that cannot be read or holds no run)
  /// is not measured.
  factory ProjectReport.read(String projectPath, {required String project}) {
    final file = findLatestTrackingFile(projectPath);
    final tracking = file == null ? null : TrackingFile.load(file);
    if (tracking == null || tracking.runs.isEmpty) {
      return ProjectReport.notMeasured(project);
    }
    final latest = tracking.runs.last;
    var passed = 0, failed = 0, skipped = 0;
    for (final key in tracking.entries.keys) {
      switch (latest.getResult(key)) {
        case TestResult.ok:
          passed++;
        case TestResult.fail:
          failed++;
        case TestResult.skip:
          skipped++;
        case TestResult.absent:
          break;
      }
    }
    final (regressions, _) = StatusCommand.compareRuns(
      tracking,
      tracking.runs.first,
      latest,
    );
    return ProjectReport(
      project: project,
      trackingFile: p.relative(file!, from: projectPath),
      lastRun: latest.timestamp,
      runs: tracking.runs.length,
      passed: passed,
      failed: failed,
      skipped: skipped,
      regressions: regressions,
      flaky: FlakyCommand.countFlaky(tracking),
      coverage: latest.coverage,
    );
  }

  bool get measured => lastRun != null;

  ReportState get state => !measured
      ? ReportState.notMeasured
      : regressions > 0
      ? ReportState.regressed
      : failed > 0
      ? ReportState.failing
      : ReportState.green;

  /// The table cells, in [WorkspaceReport.headers] order.
  List<String> get cells => measured
      ? [
          project,
          state.label,
          _formatTime(lastRun!),
          '$passed',
          '$failed',
          '$skipped',
          '$regressions',
          '$flaky',
          coverage == null ? '' : '${coverage!.percent.toStringAsFixed(1)}%',
        ]
      : [project, state.label, '', '', '', '', '', '', ''];

  Map<String, Object?> toJson() => {
    'project': project,
    'state': state.label,
    'trackingFile': trackingFile,
    'lastRun': lastRun?.toIso8601String(),
    'runs': measured ? runs : null,
    'passed': measured ? passed : null,
    'failed': measured ? failed : null,
    'skipped': measured ? skipped : null,
    'regressions': measured ? regressions : null,
    'flaky': measured ? flaky : null,
    'coverage': coverage == null
        ? null
        : {'covered': coverage!.covered, 'coverable': coverage!.coverable},
  };

  static String _formatTime(DateTime t) =>
      '${t.year}-${padTwo(t.month)}-${padTwo(t.day)} '
      '${padTwo(t.hour)}:${padTwo(t.minute)}';
}

/// The `:report` table over every project the traversal visited.
class WorkspaceReport {
  static const headers = [
    'Project',
    'State',
    'Last run',
    'Passed',
    'Failed',
    'Skipped',
    'Regressions',
    'Flaky',
    'Coverage',
  ];

  final List<ProjectReport> projects;

  const WorkspaceReport(this.projects);

  /// One line counting the projects per state, the unmeasured ones named as
  /// such.
  String get summary {
    String count(ReportState s) =>
        '${projects.where((r) => r.state == s).length} ${s.label}';
    return '${projects.length} projects: ${count(ReportState.green)}, '
        '${count(ReportState.failing)}, ${count(ReportState.regressed)}, '
        '${count(ReportState.notMeasured)}';
  }

  /// The table as aligned plain text, for the console.
  String toPlain() {
    final rows = [headers, for (final r in projects) r.cells];
    final widths = [
      for (var c = 0; c < headers.length; c++)
        rows.map((row) => row[c].length).reduce((a, b) => a > b ? a : b),
    ];
    String line(List<String> row) => [
      for (var c = 0; c < row.length; c++)
        // Numbers right-aligned, text left-aligned.
        c >= 3 ? row[c].padLeft(widths[c]) : row[c].padRight(widths[c]),
    ].join('  ').trimRight();
    return [
      line(rows.first),
      widths.map((w) => '-' * w).join('  '),
      for (final row in rows.skip(1)) line(row),
      '',
      summary,
    ].join('\n');
  }

  String toMarkdown() {
    String row(List<String> cells) =>
        '| ${cells.map((c) => c.replaceAll('|', r'\|')).join(' | ')} |';
    return [
      '# Test report',
      '',
      summary,
      '',
      row(headers),
      '| ${[for (var c = 0; c < headers.length; c++) c >= 3 ? '---:' : '---'].join(' | ')} |',
      for (final r in projects) row(r.cells),
      '',
    ].join('\n');
  }

  String toJson() => const JsonEncoder.withIndent('  ').convert({
    'summary': summary,
    'projects': [for (final r in projects) r.toJson()],
  });
}

/// Implements `:report`'s output: the table on stdout and, with `--output`,
/// the same as Markdown or JSON in a file.
class ReportCommand {
  /// The file `--output` names: `md:<file>` / `json:<file>`, or a bare file
  /// whose extension (`.md`, `.json`) gives the format. Null when [value] is
  /// none of these.
  static OutputSpec? parseOutput(String value) {
    final spec = OutputSpec.tryParse(value);
    if (spec != null) {
      return spec.hasFile &&
              (spec.format == OutputFormat.md ||
                  spec.format == OutputFormat.json)
          ? spec
          : null;
    }
    return switch (p.extension(value).toLowerCase()) {
      '.md' => OutputSpec(format: OutputFormat.md, filePath: value),
      '.json' => OutputSpec(format: OutputFormat.json, filePath: value),
      _ => null,
    };
  }

  /// Why [filePath] may not take the report, or null: `doc/` holds
  /// hand-authored documents only, so nothing below a `doc` folder.
  static String? refuseOutputPath(String filePath) {
    final parts = p.split(p.normalize(p.absolute(filePath)));
    return parts.reversed.skip(1).contains('doc')
        ? '$filePath is inside a doc/ folder, which holds hand-authored '
              'documents only; write the report elsewhere'
        : null;
  }

  /// Prints [report] and writes it to [output] when given. Returns an error
  /// message when the file could not be written, else null.
  static Future<String?> emit(
    WorkspaceReport report, {
    String? output,
    StringSink? sink,
  }) async {
    final out = sink ?? stdout;
    if (report.projects.isEmpty) {
      out.writeln('No project to report on.');
    } else {
      out.writeln();
      out.writeln(report.toPlain());
    }
    if (output == null) return null;

    final spec = parseOutput(output);
    if (spec == null) {
      return '--output $output: give a .md or .json file '
          '(or md:<file> / json:<file>)';
    }
    final refused = refuseOutputPath(spec.filePath!);
    if (refused != null) return refused;
    final file = File(spec.filePath!);
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(
        spec.format == OutputFormat.json
            ? '${report.toJson()}\n'
            : report.toMarkdown(),
      );
    } on FileSystemException catch (e) {
      return 'Could not write ${spec.filePath}: ${e.message}';
    }
    out.writeln('Report written to ${spec.filePath}');
    return null;
  }
}
