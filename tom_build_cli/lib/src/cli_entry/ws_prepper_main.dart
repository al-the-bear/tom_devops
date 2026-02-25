/// Workspace Preparer CLI entry point.
library;

import 'dart:io';
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';
import 'ws_analyzer_main.dart';

/// Main entry point for workspace preparer CLI.
Future<void> wsPrepperMain(List<String> arguments) async {
  if (arguments.isEmpty) {
    printWsPrepperUsage();
    exit(1);
  }

  final args = parseWsPrepperArgs(arguments);

  if (args.help) {
    printWsPrepperUsage();
    return;
  }

  String workspacePath;
  if (args.has('path')) {
    workspacePath = args.resolvePath(args['path']!);
  } else {
    workspacePath = Directory.current.path;
  }

  if (args.hasFlag('modes')) {
    await _listWorkspaceModes(workspacePath);
    return;
  }

  if (args.hasFlag('list')) {
    await _listTemplates(workspacePath);
    return;
  }

  final mode = args['mode'] ?? '';
  if (mode.isEmpty) {
    print('Error: No mode specified. Use wp-mode=<mode>');
    printWsPrepperUsage();
    exit(1);
  }

  final dryRun = args.hasFlag('dry-run');
  final skipValidation = args.hasFlag('skip-validation');
  final runAnalyzer = args.hasFlag('analyze') || args.hasFlag('run-analyzer');

  final requestedModes = mode.split(',').map((m) => m.trim()).where((m) => m.isNotEmpty).toList();

  if (runAnalyzer) {
    print('Running workspace analyzer first...\n');
    await wsAnalyzerMain(['wa-path=$workspacePath']);
    print('');
  }

  List<String> resolvedModes;
  if (skipValidation) {
    resolvedModes = requestedModes;
    print('Note: Mode validation skipped (wp-skip-validation)');
  } else {
    try {
      final context = await ToolContext.load(workspacePath: workspacePath);
      final validation = context.validateModes(requestedModes);
      if (!validation.isValid) {
        print('Error: ${validation.errorMessage}');
        print('\nUse wp-skip-validation to bypass mode validation.');
        exit(1);
      }
      resolvedModes = validation.resolvedModes;
      if (resolvedModes.length != requestedModes.length || 
          !resolvedModes.every((m) => requestedModes.contains(m))) {
        print('Resolved modes: ${resolvedModes.join(', ')} (includes implied modes)');
      }
    } on ToolContextException catch (e) {
      print('Warning: ${e.message}');
      print('Proceeding without mode validation.\n');
      resolvedModes = requestedModes;
    }
  }

  final modesDisplay = resolvedModes.length > 1 
      ? 'modes: ${resolvedModes.join(', ')} (last match wins)'
      : 'mode: ${resolvedModes.first}';
  print('Preparing workspace for $modesDisplay${dryRun ? ' (dry run)' : ''}');
  print('Workspace: $workspacePath\n');

  final prepper = WsPrepper(workspacePath, options: WsPrepperOptions(dryRun: dryRun));
  final result = await prepper.processAll(resolvedModes.join(','));

  if (result.processed.isEmpty && result.errors.isEmpty) {
    print('No .tomplate files found in workspace.');
    return;
  }

  for (final processed in result.processed) {
    print(processed);
  }
  for (final error in result.errors) {
    print('ERROR: $error');
  }

  print('\nSummary: ${result.processed.length} files processed, ${result.errors.length} errors');
  if (!result.success) exit(1);
}

Future<void> _listWorkspaceModes(String workspacePath) async {
  print('Valid workspace modes:\n');
  try {
    final context = await ToolContext.load(workspacePath: workspacePath);
    final modes = context.workspaceInfo.workspaceModes;
    if (modes == null || modes.supportedModes.isEmpty) {
      print('No workspace-modes section found in .tom_metadata/tom_master.yaml');
      return;
    }
    for (final mode in modes.supportedModes) {
      final implies = mode.implies.isNotEmpty ? ' (implies: ${mode.implies.join(', ')})' : '';
      final isDefault = mode.name == modes.defaultMode ? ' [default]' : '';
      print('  - ${mode.name}$implies$isDefault');
    }
    print('\nDefault mode: ${modes.defaultMode ?? 'none'}');
  } on ToolContextException catch (e) {
    print('Error: ${e.message}');
    exit(1);
  }
}

Future<void> _listTemplates(String workspacePath) async {
  print('Scanning for .tomplate files in: $workspacePath\n');
  final prepper = WsPrepper(workspacePath);
  final templates = await prepper.findTemplates();
  if (templates.isEmpty) {
    print('No .tomplate files found.');
    return;
  }
  print('Found ${templates.length} template(s):');
  for (final template in templates) {
    final relativePath = template.path.replaceFirst('$workspacePath/', '');
    final content = await template.readAsString();
    final parser = TemplateParser(content);
    final parsed = parser.parse();
    final modes = parsed.definedModes.toList()..sort();
    print('  $relativePath');
    print('    Modes: ${modes.join(', ')}');
    print('    Blocks: ${parsed.blocks.length}');
  }
}

void printWsPrepperUsage() {
  print('Workspace Preparer (ws_prepper) - Process template files based on mode');
  print('\nUsage: ws_prepper wp-mode=<mode> [options]');
  print('\nOptions:');
  print('  wp-mode=<modes>      Mode(s) to apply, comma-separated');
  print('  wp-path=<path>       Workspace path (default: current directory)');
  print('  wp-dry-run           Preview changes without writing files');
  print('  wp-list              List all template files and their modes');
  print('  wp-modes             List valid modes from workspace metadata');
  print('  wp-skip-validation   Skip mode validation');
  print('  wp-analyze           Run workspace analyzer first');
}
