#!/usr/bin/env dart

library;

import 'dart:async';
import 'dart:io';

import 'package:console_markdown/console_markdown.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_build_kit/tom_build_kit.dart';

Future<void> main(List<String> args) async {
  if (Zone.current[#consoleMarkdownActive] != true) {
    return runZoned(
      () => main(args),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          parent.print(zone, line.toConsole());
        },
      ),
      zoneValues: {#consoleMarkdownActive: true},
    );
  }

  final runner = ToolRunner(
    tool: buildkitTool,
    executors: createBuildkitExecutors(),
    verbose: true,
  );

  final result = await runner.run(args);
  final failures = result.itemResults.where((item) => !item.success).toList();

  if (failures.isEmpty) {
    stdout.writeln('\nDone. No errors.');
  } else {
    stdout.writeln('\n=== Errors ===');
    for (final item in failures) {
      final cmd = item.commandName != null ? ' :${item.commandName}' : '';
      final err = item.error ?? 'unknown error';
      stdout.writeln('  ${item.name}$cmd — $err');
    }
    stdout.writeln(
      '${failures.length} error(s) in '
      '${failures.map((f) => f.name).toSet().length} project(s).',
    );
  }

  if (!result.success) {
    exit(1);
  }
}
