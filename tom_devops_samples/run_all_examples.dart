// Run All DevOps Samples
//
// Aggregator smoke test for the Tom devops sample projects. Each sample is a
// self-contained Dart package under this folder with its own
// `example/run_all_examples.dart`; this script runs every one of them in a
// subprocess and reports a combined pass/fail tally.
//
// Run with:
//   dart run run_all_examples.dart
//
// Registering a sample: add its directory name to [_plannedSamples] below.
// A sample whose package does not exist yet is reported as PENDING (skipped,
// not failed), so the full set can be listed ahead of the sample projects
// landing. Each sample "activates" automatically once its pubspec appears.

import 'dart:io';

/// The devops sample packages, in learning-path order.
///
/// Keep this list in sync with the `Sample | Demonstrates` table in
/// `README.md` and the samples learning-path table in `../README.md`.
const _plannedSamples = <String>[
  'tom_github_api_sample',
  'tom_build_kit_sample',
  'tom_test_kit_sample',
  'tom_issue_kit_sample',
  'tom_md2pdf_sample',
  'tom_deploy_sample',
];

Future<void> main() async {
  final here = File(Platform.script.toFilePath()).parent;

  print('=' * 60);
  print('Running all Tom devops samples');
  print('=' * 60);

  var passed = 0;
  var failed = 0;
  var pending = 0;
  final failures = <String, String>{};

  for (final sample in _plannedSamples) {
    final dir = Directory('${here.path}/$sample');
    final pubspec = File('${dir.path}/pubspec.yaml');
    final entry = File('${dir.path}/example/run_all_examples.dart');

    if (!pubspec.existsSync()) {
      print('\n- $sample ... PENDING (not created yet)');
      pending++;
      continue;
    }

    if (!entry.existsSync()) {
      print('\n- $sample ... FAILED (no example/run_all_examples.dart)');
      failures[sample] = 'Missing example/run_all_examples.dart';
      failed++;
      continue;
    }

    stdout.write('\n- $sample ... ');
    final result = await Process.run(
      'dart',
      ['run', 'example/run_all_examples.dart'],
      workingDirectory: dir.path,
    );

    if (result.exitCode == 0) {
      print('PASSED');
      passed++;
    } else {
      print('FAILED (exit ${result.exitCode})');
      failures[sample] = '${result.stdout}\n${result.stderr}';
      failed++;
    }
  }

  print('\n${'=' * 60}');
  print('Results: $passed passed, $failed failed, $pending pending');
  print('=' * 60);

  if (failures.isNotEmpty) {
    print('\nFailures:');
    for (final entry in failures.entries) {
      print('\n--- ${entry.key} ---');
      print(entry.value);
    }
    exit(1);
  }

  if (passed == 0) {
    print('\nNo samples have been created yet — nothing to run.');
  } else {
    print('\nAll runnable samples passed!');
  }
}
