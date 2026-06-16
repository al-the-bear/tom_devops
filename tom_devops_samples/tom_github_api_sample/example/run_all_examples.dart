// Run every tom_github_api example in-process as an offline smoke test.
//
// Each example builds its own offline client, so they are independent and
// order-free. This aggregator runs them all, tallies pass/fail, and exits
// non-zero if any example throws — which is what the top-level
// `tom_devops_samples/run_all_examples.dart` checks.
//
// Run: dart run example/run_all_examples.dart

import 'dart:io';

import '01_authentication_example.dart' as authentication;
import '02_issues_example.dart' as issues;
import '03_labels_example.dart' as labels;
import '04_comments_example.dart' as comments;
import '05_search_example.dart' as search;
import '06_workflows_example.dart' as workflows;
import '07_errors_and_rate_limits_example.dart' as errors;

Future<void> main() async {
  final examples = <String, Future<void> Function()>{
    '01 authentication': authentication.main,
    '02 issues': issues.main,
    '03 labels': labels.main,
    '04 comments': comments.main,
    '05 search': search.main,
    '06 workflows': workflows.main,
    '07 errors and rate limits': errors.main,
  };

  var passed = 0;
  var failed = 0;
  final failures = <String, Object>{};

  for (final entry in examples.entries) {
    stdout.writeln('\n=== ${entry.key} ===');
    try {
      await entry.value();
      passed++;
    } catch (e, st) {
      failed++;
      failures[entry.key] = '$e\n$st';
    }
  }

  stdout.writeln('\n${'=' * 50}');
  stdout.writeln('Results: $passed passed, $failed failed');

  if (failures.isNotEmpty) {
    for (final f in failures.entries) {
      stdout.writeln('\n--- ${f.key} ---\n${f.value}');
    }
    exit(1);
  }

  stdout.writeln('All tom_github_api examples passed.');
}
