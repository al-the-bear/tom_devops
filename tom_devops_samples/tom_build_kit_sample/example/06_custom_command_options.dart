// Command options — declare a flag/value and read it back in the executor.
//
// A command can declare its own `OptionDefinition`s. Value options like
// `--prefix=<text>` are parsed per command and surface on
// `args.commandArgs[<command>].options`. Declaring the option (rather than
// letting it fall through to `extraOptions`) is what lets the parser know it
// consumes a value and keeps it from colliding with global navigation flags.
//
// Run: dart run example/06_custom_command_options.dart
// Run: dart run example/06_custom_command_options.dart   (prefix defaults to TOM)

import 'package:tom_build_base/tom_build_base_v2.dart';

import 'fixture.dart';

Future<void> main() async {
  final labels = <String>[];

  final tool = ToolDefinition(
    name: 'labelkit',
    description: 'Sample tool with a per-command value option',
    commands: const [
      CommandDefinition(
        name: 'label',
        description: 'Prefix each project name with a label',
        worksWithNatures: {DartProjectFolder},
        options: [
          OptionDefinition.option(
            name: 'prefix',
            description: 'Text to prepend to each project name',
            defaultValue: 'TOM',
            valueName: 'text',
          ),
        ],
      ),
    ],
  );

  final executors = <String, CommandExecutor>{
    'label': CallbackExecutor(
      onExecute: (context, args) async {
        // Per-command options live under commandArgs[<command>].options.
        // Fall back to the declared default when the flag is omitted.
        final prefix =
            args.commandArgs['label']?.options['prefix'] as String? ?? 'TOM';
        labels.add('$prefix:${context.name}');
        return ItemResult.success(path: context.path, name: context.name);
      },
    ),
  };

  final fixture = fixtureWorkspacePath();

  final runner = ToolRunner(
    tool: tool,
    executors: executors,
    verbose: false,
    output: StringBuffer(),
  );

  await runner.run([
    ':label',
    '--prefix', 'BUILD',
    '--scan', fixture,
    '--root', fixture,
    '--not-recursive',
  ]);
  print('With --prefix BUILD: ${labels.join(', ')}');
  // expected output: With --prefix BUILD: BUILD:pkg_core, BUILD:pkg_data, BUILD:pkg_app

  // Run again without the flag — the executor's default kicks in.
  labels.clear();
  final runner2 = ToolRunner(
    tool: tool,
    executors: executors,
    verbose: false,
    output: StringBuffer(),
  );
  await runner2.run([
    ':label',
    '--scan', fixture,
    '--root', fixture,
    '--not-recursive',
  ]);
  print('Default prefix: ${labels.join(', ')}');
  // expected output: Default prefix: TOM:pkg_core, TOM:pkg_data, TOM:pkg_app
}
