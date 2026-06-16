// Runs every numbered example in order and reports a pass/fail tally.
//
// Each example exposes a `main()` we await in turn. Any thrown error (or a
// non-zero `exitCode` set by an example) marks that example failed; the script
// exits non-zero if any example fails, so it doubles as a smoke test for the
// whole sample.
//
// Run: dart run example/run_all_examples.dart

import 'dart:io';

import '01_discover_projects.dart' as ex01;
import '02_build_order.dart' as ex02;
import '03_inspect_natures.dart' as ex03;
import '04_filter_projects.dart' as ex04;
import '05_author_a_tool.dart' as ex05;
import '06_custom_command_options.dart' as ex06;
import '07_inspect_buildkit_tool.dart' as ex07;

typedef _Example = Future<void> Function();

Future<void> main() async {
  final examples = <String, _Example>{
    '01_discover_projects': ex01.main,
    '02_build_order': ex02.main,
    '03_inspect_natures': ex03.main,
    '04_filter_projects': ex04.main,
    '05_author_a_tool': ex05.main,
    '06_custom_command_options': ex06.main,
    '07_inspect_buildkit_tool': ex07.main,
  };

  var passed = 0;
  var failed = 0;

  for (final entry in examples.entries) {
    stdout.writeln('\n=== ${entry.key} ===');
    // Reset between examples so one example's exitCode cannot leak into the
    // next; we restore failures into our own tally below.
    exitCode = 0;
    try {
      await entry.value();
      if (exitCode != 0) {
        failed++;
        stderr.writeln('FAILED: ${entry.key} (exitCode $exitCode)');
      } else {
        passed++;
      }
    } catch (error, stack) {
      failed++;
      stderr.writeln('FAILED: ${entry.key}: $error');
      stderr.writeln(stack);
    }
  }

  stdout.writeln('\n$passed passed, $failed failed');
  exitCode = failed == 0 ? 0 : 1;
}
