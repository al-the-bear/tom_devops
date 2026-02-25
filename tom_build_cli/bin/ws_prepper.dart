import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

/// Command-line tool to prepare workspace by processing mode templates.
///
/// Usage:
///   dart run tom_build_cli:ws_prepper wp-mode=development wp-path=/workspace
///   dart run tom_build_cli:ws_prepper wp-mode=dev,local,debug wp-dry-run
///   dart run tom_build_cli:ws_prepper wp-list wp-path=.
///   dart run tom_build_cli:ws_prepper wp-modes
Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    _printUsage();
    exit(1);
  }

  final args = parseWsPrepperArgs(arguments);

  // Handle help
  if (args.help) {
    _printUsage();
    return;
  }

  // Determine workspace path from named params or current directory
  String workspacePath;
  if (args.has('path')) {
    workspacePath = args.resolvePath(args['path']!);
  } else {
    workspacePath = Directory.current.path;
  }

  // Handle wp-modes option - list valid modes from workspace metadata
  if (args.hasFlag('modes')) {
    await _listWorkspaceModes(workspacePath);
    return;
  }

  // Handle wp-list option
  if (args.hasFlag('list')) {
    await _listTemplates(workspacePath);
    return;
  }

  // Parse mode from named param
  final mode = args['mode'] ?? '';

  if (mode.isEmpty) {
    print('Error: No mode specified');
    print('Use wp-mode=<mode> to specify the mode');
    _printUsage();
    exit(1);
  }

  // Parse options
  final dryRun = args.hasFlag('dry-run');
  final skipValidation = args.hasFlag('skip-validation');
  final runAnalyzer = args.hasFlag('analyze') || args.hasFlag('run-analyzer');

  // Parse and validate modes
  final requestedModes = mode.split(',')
      .map((m) => m.trim())
      .where((m) => m.isNotEmpty)
      .toList();

  // Run workspace analyzer first if requested
  if (runAnalyzer) {
    print('Running workspace analyzer first...\n');
    await _runWorkspaceAnalyzer(workspacePath);
    print('');
  }

  // Validate modes against workspace metadata unless --skip-validation
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
        print('');
        print('Use wp-skip-validation to bypass mode validation.');
        exit(1);
      }
      
      resolvedModes = validation.resolvedModes;
      
      // Show implied modes if different from requested
      if (resolvedModes.length != requestedModes.length || 
          !resolvedModes.every((m) => requestedModes.contains(m))) {
        print('Resolved modes: ${resolvedModes.join(', ')} (includes implied modes)');
      }
    } on ToolContextException catch (e) {
      print('Warning: ${e.message}');
      print('Proceeding without mode validation.');
      print('');
      resolvedModes = requestedModes;
    }
  }

  final modesDisplay = resolvedModes.length > 1 
      ? 'modes: ${resolvedModes.join(', ')} (last match wins)'
      : 'mode: ${resolvedModes.first}';
  print('Preparing workspace for $modesDisplay${dryRun ? ' (dry run)' : ''}');
  print('Workspace: $workspacePath\n');

  final prepper = WsPrepper(
    workspacePath,
    options: WsPrepperOptions(dryRun: dryRun),
  );

  // Use resolved modes as comma-separated string
  final result = await prepper.processAll(resolvedModes.join(','));

  // Print results
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

  print('');
  print(
    'Summary: ${result.processed.length} files processed, '
    '${result.errors.length} errors',
  );

  if (!result.success) {
    exit(1);
  }
}

/// Runs the workspace analyzer as a subprocess.
Future<void> _runWorkspaceAnalyzer(String workspacePath) async {
  // Find the ws_analyzer.dart script
  final scriptPath = p.join(
    p.dirname(Platform.script.toFilePath()),
    'ws_analyzer.dart',
  );

  if (!File(scriptPath).existsSync()) {
    print('Warning: Could not find ws_analyzer.dart at $scriptPath');
    print('Skipping workspace analysis.');
    return;
  }

  final result = await Process.run(
    'dart',
    [scriptPath, 'wa-path=$workspacePath'],
    workingDirectory: workspacePath,
  );

  stdout.write(result.stdout);
  if (result.stderr.toString().isNotEmpty) {
    stderr.write(result.stderr);
  }

  if (result.exitCode != 0) {
    print('Warning: Workspace analyzer exited with code ${result.exitCode}');
  }
}

/// Lists valid workspace modes from .tom_metadata/tom_master.yaml.
Future<void> _listWorkspaceModes(String workspacePath) async {
  print('Valid workspace modes:\n');
  
  try {
    final context = await ToolContext.load(workspacePath: workspacePath);
    final modes = context.workspaceInfo.workspaceModes;
    
    if (modes == null || modes.supportedModes.isEmpty) {
      print('No workspace-modes section found in .tom_metadata/tom_master.yaml');
      print('');
      print('Add a workspace-modes section to your tom_workspace.yaml:');
      print('');
      print('workspace-modes:');
      print('  supported:');
      print('    - name: development');
      print('      implies: [ relative_build ]');
      print('    - name: production');
      print('    - name: default');
      print('  default: default');
      return;
    }
    
    for (final mode in modes.supportedModes) {
      final implies = mode.implies.isNotEmpty 
          ? ' (implies: ${mode.implies.join(', ')})'
          : '';
      final isDefault = mode.name == modes.defaultMode ? ' [default]' : '';
      final desc = mode.description != null ? '\n      ${mode.description}' : '';
      print('  - ${mode.name}$implies$isDefault$desc');
    }
    
    print('');
    print('Default mode: ${modes.defaultMode ?? 'none'}');
  } on ToolContextException catch (e) {
    print('Error: ${e.message}');
    exit(1);
  }
}

/// Lists all .tomplate files in the workspace.
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

void _printUsage() {
  print('Workspace Preparer (ws_prepper) - Process template files based on mode');
  print('');
  print('Scans workspace for .tomplate files and generates output files');
  print('based on the specified mode(s). Modes are validated against the');
  print('workspace-modes section in .tom_metadata/tom_master.yaml.');
  print('');
  print('Usage:');
  print('  dart run tom_build_cli:ws_prepper wp-mode=<mode> [options]');
  print('');
  print('Options (wp- prefix for composability):');
  print('  wp-mode=<modes>      Mode(s) to apply, comma-separated');
  print('  wp-path=<path>       Workspace path (default: current directory)');
  print('  wp-dry-run           Preview changes without writing files');
  print('  wp-list              List all template files and their modes');
  print('  wp-modes             List valid modes from workspace metadata');
  print('  wp-skip-validation   Skip mode validation (allow any mode)');
  print('  wp-analyze           Run workspace analyzer before preparing');
  print('  wp-run-analyzer      Alias for wp-analyze');
  print('  --help, -h           Show this help');
  print('');
  print('Mode resolution:');
  print('  When a mode implies other modes, they are automatically included.');
  print('  Order: mode1, <mode1-implies>, mode2, <mode2-implies>');
  print('  When multiple modes match a block, the last one wins.');
  print('');
  print('Examples:');
  print('  dart run tom_build_cli:ws_prepper wp-mode=development');
  print('  dart run tom_build_cli:ws_prepper wp-mode=dev,local wp-path=.. wp-dry-run');
  print('  dart run tom_build_cli:ws_prepper wp-modes wp-path=..');
  print('  dart run tom_build_cli:ws_prepper wp-analyze wp-mode=production');
}
