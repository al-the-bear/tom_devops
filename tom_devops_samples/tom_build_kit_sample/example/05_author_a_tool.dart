// Author a tool — the four pieces buildkit itself is built from.
//
// A tom_build_base tool is:
//   1. a `ToolDefinition`     — declares the tool and its commands;
//   2. one `CommandExecutor`  — the logic run per project;
//   3. a `ToolRunner`         — parses args, traverses, dispatches;
//   4. command-line `args`    — `:command` plus navigation flags.
//
// Here we build a one-command tool, `:greet`, that visits every Dart project.
// The runner's own progress output is captured into a `StringBuffer` (the
// injectable `output` sink) so the example stays deterministic and silent;
// real binaries let it flow to stdout.
//
// `worksWithNatures: {DartProjectFolder}` is what scopes `:greet` to Dart
// projects — a command with no nature requirement is never invoked.
//
// Run: dart run example/05_author_a_tool.dart

import 'package:tom_build_base/tom_build_base_v2.dart';

import 'fixture.dart';

Future<void> main() async {
  final greeted = <String>[];

  final tool = ToolDefinition(
    name: 'greetkit',
    description: 'A minimal sample tool that greets each Dart project',
    commands: const [
      CommandDefinition(
        name: 'greet',
        description: 'Print a greeting for each project',
        worksWithNatures: {DartProjectFolder},
      ),
    ],
  );

  final executors = <String, CommandExecutor>{
    'greet': CallbackExecutor(
      onExecute: (context, args) async {
        greeted.add(context.name);
        return ItemResult.success(
          path: context.path,
          name: context.name,
          message: 'greeted',
        );
      },
    ),
  };

  final transcript = StringBuffer();
  final runner = ToolRunner(
    tool: tool,
    executors: executors,
    verbose: false,
    output: transcript,
  );

  final fixture = fixtureWorkspacePath();
  final result = await runner.run([
    ':greet',
    '--scan', fixture,
    '--root', fixture,
    '--not-recursive',
  ]);

  print('Succeeded: ${result.success}');
  // expected output: Succeeded: true
  print('Projects processed: ${result.processedCount}');
  // expected output: Projects processed: 3
  print('Greeted in build order: ${greeted.join(' -> ')}');
  // expected output: Greeted in build order: pkg_core -> pkg_data -> pkg_app
}
