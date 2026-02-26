/// TomD4rt REPL with integrated Tom CLI functionality.
///
/// This REPL extends DcliRepl to add Tom workspace command support,
/// allowing users to execute :build, :analyze, and other Tom commands
/// directly from the REPL prompt.
library;

import 'dart:io';

import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_d4rt_dcli/tom_d4rt_dcli.dart';

import '../tom/cli/tom_cli.dart';
import 'dartscript.b.dart';
import 'version.versioner.dart';

/// TomD4rt REPL with integrated Tom CLI functionality.
///
/// Extends DcliRepl to add:
/// - Tom command support (: and ! prefixes)
/// - Tom-specific bridges
/// - Workspace context integration
class TomD4rtRepl extends DcliRepl {
  /// Tom CLI for executing workspace commands
  TomCli? _tomCli;

  /// Get or create the Tom CLI instance.
  TomCli get tomCli => _tomCli ??= TomCli();

  @override
  String get toolName => 'Tom';

  @override
  String get toolVersion => TomVersionInfo.versionLong;

  @override
  String get dataDirectory => '${Platform.environment['HOME']}/.tom/tom';

  @override
  List<String> get replayFilePatterns => [
    '.replay.txt',
    '.tom',
    '.d4rt',
    '.dcli',
  ];

  @override
  void registerBridges(D4rt d4rt) {
    // Register all Tom Framework bridges via generated registration class
    TomBuildCliBridges.register(d4rt);
  }

  @override
  String getImportBlock() {
    return getStdlibImports() + TomBuildCliBridges.getImportBlock();
  }

  @override
  Future<bool> handleAdditionalCommands(
    D4rt d4rt,
    ReplState state,
    String line, {
    bool silent = false,
  }) async {
    // Handle Tom commands (:, !, or - prefix) inside REPL
    // Note: : and ! are Tom commands, - forwards to Tom for option handling
    if (line.startsWith(':') || line.startsWith('!') || line.startsWith('-')) {
      await _executeTomCommand(d4rt, state, line, silent: silent);
      return true;
    }

    // Fall through to parent handling (VS Code commands, etc.)
    return super.handleAdditionalCommands(d4rt, state, line, silent: silent);
  }

  /// Execute a Tom CLI command from the REPL.
  Future<void> _executeTomCommand(
    D4rt d4rt,
    ReplState state,
    String line, {
    bool silent = false,
  }) async {
    // Parse the command line
    final args = _parseCommandLine(line);

    try {
      // Execute via TomCli with current working directory
      final cli = TomCli(
        config: TomCliConfig(workspacePath: state.currentDirectory),
      );
      final result = await cli.run(args);

      // Display results
      if (!silent) {
        if (result.message != null && result.message!.isNotEmpty) {
          print(result.message);
        }
        if (result.error != null && result.error!.isNotEmpty) {
          state.writeError(result.error!);
        }
      }
    } on FileSystemException catch (e) {
      // Handle missing workspace or file access errors
      if (!silent) {
        state.writeError('Workspace error: ${e.message}');
        state.writeMuted(
          'Ensure you are in a Tom workspace (directory with tom_workspace.yaml)',
        );
      }
    } catch (e) {
      // Handle unexpected errors gracefully
      if (!silent) {
        state.writeError('Command execution failed: $e');
      }
    }
  }

  /// Parse a command line string into arguments.
  List<String> _parseCommandLine(String line) {
    final args = <String>[];
    final buffer = StringBuffer();
    var inQuote = false;
    var quoteChar = '';

    for (var i = 0; i < line.length; i++) {
      final c = line[i];

      if (inQuote) {
        if (c == quoteChar) {
          inQuote = false;
          args.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(c);
        }
      } else if (c == '"' || c == "'") {
        inQuote = true;
        quoteChar = c;
      } else if (c == ' ') {
        if (buffer.isNotEmpty) {
          args.add(buffer.toString());
          buffer.clear();
        }
      } else {
        buffer.write(c);
      }
    }

    if (buffer.isNotEmpty) {
      args.add(buffer.toString());
    }

    return args;
  }

  @override
  List<String> getAdditionalHelpSections() {
    return [...super.getAdditionalHelpSections(), _getTomCommandsHelp()];
  }

  /// Returns the Tom workspace commands help section.
  String _getTomCommandsHelp() {
    return '''
<cyan>**Tom Workspace Commands**</cyan>
  <yellow>**:analyze**</yellow>          Run workspace analyzer
  <yellow>**:build**</yellow>            Build projects
  <yellow>**:test**</yellow>             Run tests
  <yellow>**:generate-***</yellow>       Code generation commands
  <yellow>**:version-bump**</yellow>     Bump package versions
  <yellow>**:pipeline**</yellow> <name>  Run named pipeline
  <yellow>**:projects**</yellow> p1 ...  Limit scope to projects
  <yellow>**:groups**</yellow> g1 ...    Limit scope to groups
  <yellow>**:help**</yellow>             Show Tom CLI help
  
  *Use* **:**<action> *for any workspace action defined in tom_master*.yaml*''';
  }

  @override
  ReplState createReplState() {
    // Let DcliRepl initialize VS Code integration
    super.createReplState();
    // Return state with tom prompt name but keep the data directory
    return ReplState(promptName: 'tom', dataDir: dataDirectory);
  }
}
