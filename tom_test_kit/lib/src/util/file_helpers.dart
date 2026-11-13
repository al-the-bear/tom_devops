/// File-system helpers for tracking file discovery.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'format_helpers.dart';

/// Directory (next to each project's `doc/` folder) where testkit writes all
/// machine-generated test artifacts: baselines and `last_testrun.json`.
///
/// This folder is expected to be fully gitignored — test artifacts are never
/// versioned, and `doc/` is reserved for hand-authored documentation.
const String trackingDirName = 'testlog';

/// Returns the default output path for a baseline file.
///
/// Creates a path like `<projectPath>/testlog/baseline_<MMDD_HHMM>.csv`.
String defaultBaselinePath(String projectPath, {DateTime? now}) {
  final ts = now ?? DateTime.now();
  return p.join(
    projectPath,
    trackingDirName,
    'baseline_${baselineTimestamp(ts)}.csv',
  );
}

/// Finds the most recent `baseline_*.csv` file in a project's `testlog/`
/// folder.
///
/// Returns the absolute path of the latest file, or null if no tracking
/// files exist.
String? findLatestTrackingFile(String projectPath) {
  final docDir = Directory(p.join(projectPath, trackingDirName));
  if (!docDir.existsSync()) return null;

  final files = docDir
      .listSync()
      .whereType<File>()
      .where(
        (f) =>
            p.basename(f.path).startsWith('baseline_') &&
            f.path.endsWith('.csv'),
      )
      .toList();

  if (files.isEmpty) return null;

  // Sort by name (timestamp in filename) — latest first
  files.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
  return files.first.path;
}

/// Saves a test run's raw output to `testlog/<fileName>` in the project
/// (beside the baseline files): `last_testrun.json` for `dart test`'s JSON
/// events, `last_testrun.txt` for the other runners' output.
///
/// Overwrites any existing file.
Future<void> saveLastTestRunOutput(
  String projectPath,
  List<String> lines, {
  String fileName = 'last_testrun.json',
}) async {
  final dir = Directory(p.join(projectPath, trackingDirName));
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }
  final file = File(p.join(dir.path, fileName));
  await file.writeAsString('${lines.join('\n')}\n');
}
