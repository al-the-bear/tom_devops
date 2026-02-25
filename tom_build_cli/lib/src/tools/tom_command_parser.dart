/// Tom CLI Command Parser
///
/// Parses the advanced tom command syntax:
/// ```
/// tom [global parameters key=value] [global options --verbose] command1 [command1 params] command2 [command2 params] ...
/// ```
///
/// Supports:
/// - Global parameters (applied to all commands)
/// - Global options (--verbose, --dry-run, etc.)
/// - Multiple commands in sequence
/// - Same command can appear multiple times
library;

/// Known commands that the tom CLI can execute.
/// Used to identify command boundaries in argument parsing.
const Set<String> knownCommands = {
  // Workspace tools
  'ws_analyzer',
  'ws_prepper',
  'ws_versioner',
  'ws_publisher',
  // Generators
  'reflection_generator',
  // Pipeline commands
  'pipeline',
  'run',
  // Utility commands
  'help',
  'version',
};

/// Represents a single parsed command with its parameters.
class ParsedCommand {
  /// The command name (e.g., 'ws_analyzer', 'ws_prepper').
  final String name;

  /// Named parameters for this command (key=value pairs).
  final Map<String, String> params;

  /// Boolean flags for this command (--flag or -f).
  final Set<String> flags;

  /// Positional arguments for this command.
  final List<String> positionalArgs;

  const ParsedCommand({
    required this.name,
    this.params = const {},
    this.flags = const {},
    this.positionalArgs = const [],
  });

  /// Whether verbose mode is enabled.
  bool get verbose => flags.contains('verbose') || flags.contains('v');

  /// Whether dry run mode is enabled.
  bool get dryRun => flags.contains('dry-run');

  /// Whether help is requested.
  bool get help => flags.contains('help') || flags.contains('h');

  /// Gets a parameter value with optional default.
  String get(String key, [String defaultValue = '']) => params[key] ?? defaultValue;

  /// Gets a parameter as an integer.
  int? getInt(String key) {
    final value = params[key];
    if (value == null) return null;
    return int.tryParse(value);
  }

  /// Gets a parameter as a boolean.
  bool getBool(String key, [bool defaultValue = false]) {
    final value = params[key];
    if (value == null) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }

  @override
  String toString() {
    final buffer = StringBuffer('ParsedCommand($name)');
    if (params.isNotEmpty) buffer.write(' params=$params');
    if (flags.isNotEmpty) buffer.write(' flags=$flags');
    if (positionalArgs.isNotEmpty) buffer.write(' args=$positionalArgs');
    return buffer.toString();
  }
}

/// Result of parsing tom CLI arguments.
class ParsedTomCommand {
  /// Global parameters applied to all commands.
  final Map<String, String> globalParams;

  /// Global flags applied to all commands.
  final Set<String> globalFlags;

  /// List of commands to execute in sequence.
  final List<ParsedCommand> commands;

  /// Raw arguments that were parsed.
  final List<String> rawArgs;

  const ParsedTomCommand({
    required this.globalParams,
    required this.globalFlags,
    required this.commands,
    required this.rawArgs,
  });

  /// Whether verbose mode is globally enabled.
  bool get verbose => globalFlags.contains('verbose') || globalFlags.contains('v');

  /// Whether dry run mode is globally enabled.
  bool get dryRun => globalFlags.contains('dry-run');

  /// Whether help is requested.
  bool get help => globalFlags.contains('help') || globalFlags.contains('h');

  /// Whether there are any commands to execute.
  bool get hasCommands => commands.isNotEmpty;

  /// Gets a global parameter value with optional default.
  String get(String key, [String defaultValue = '']) => globalParams[key] ?? defaultValue;

  @override
  String toString() {
    final buffer = StringBuffer('ParsedTomCommand\n');
    buffer.writeln('  Global Params: $globalParams');
    buffer.writeln('  Global Flags: $globalFlags');
    buffer.writeln('  Commands: ${commands.length}');
    for (final cmd in commands) {
      buffer.writeln('    - $cmd');
    }
    return buffer.toString();
  }
}

/// Parser for the tom CLI command syntax.
///
/// Syntax:
/// ```
/// tom [global key=value] [--global-flags] command1 [cmd1 key=value] [--cmd1-flags] command2 ...
/// ```
class TomCommandParser {
  /// Additional commands to recognize (beyond the built-in ones).
  final Set<String> additionalCommands;

  /// Creates a parser with optional additional commands.
  TomCommandParser({this.additionalCommands = const {}});

  /// All recognized command names.
  Set<String> get allCommands => {...knownCommands, ...additionalCommands};

  /// Parses command-line arguments into a structured result.
  ParsedTomCommand parse(List<String> args) {
    final globalParams = <String, String>{};
    final globalFlags = <String>{};
    final commands = <ParsedCommand>[];

    var i = 0;

    // Parse global parameters and flags until we hit a command
    while (i < args.length && !_isCommand(args[i])) {
      final arg = args[i];
      
      if (_isNamedParam(arg)) {
        final (key, value) = _parseNamedParam(arg);
        globalParams[key] = value;
      } else if (_isFlag(arg)) {
        globalFlags.addAll(_parseFlags(arg));
      }
      // Ignore other arguments in global section
      
      i++;
    }

    // Parse commands and their arguments
    while (i < args.length) {
      final commandName = args[i];
      if (!_isCommand(commandName)) {
        // Skip unknown tokens
        i++;
        continue;
      }

      i++; // Move past command name

      final cmdParams = <String, String>{};
      final cmdFlags = <String>{};
      final cmdPositional = <String>[];

      // Collect arguments until next command
      while (i < args.length && !_isCommand(args[i])) {
        final arg = args[i];
        
        if (_isNamedParam(arg)) {
          final (key, value) = _parseNamedParam(arg);
          cmdParams[key] = value;
        } else if (_isFlag(arg)) {
          cmdFlags.addAll(_parseFlags(arg));
        } else if (!arg.startsWith('-')) {
          cmdPositional.add(arg);
        }
        
        i++;
      }

      commands.add(ParsedCommand(
        name: commandName,
        params: Map.unmodifiable(cmdParams),
        flags: Set.unmodifiable(cmdFlags),
        positionalArgs: List.unmodifiable(cmdPositional),
      ));
    }

    return ParsedTomCommand(
      globalParams: Map.unmodifiable(globalParams),
      globalFlags: Set.unmodifiable(globalFlags),
      commands: List.unmodifiable(commands),
      rawArgs: List.unmodifiable(args),
    );
  }

  /// Checks if a token is a known command.
  bool _isCommand(String token) {
    // Commands don't start with - and are in our known set
    if (token.startsWith('-')) return false;
    if (token.contains('=')) return false;
    return allCommands.contains(token);
  }

  /// Checks if an argument is a named parameter (key=value).
  bool _isNamedParam(String arg) {
    if (arg.startsWith('-')) return false;
    return arg.contains('=');
  }

  /// Parses a named parameter into key and value.
  (String, String) _parseNamedParam(String arg) {
    final eqIndex = arg.indexOf('=');
    return (arg.substring(0, eqIndex), arg.substring(eqIndex + 1));
  }

  /// Checks if an argument is a flag.
  bool _isFlag(String arg) {
    return arg.startsWith('-');
  }

  /// Parses flags from an argument.
  Set<String> _parseFlags(String arg) {
    if (arg.startsWith('--')) {
      // Long flag: --verbose or --option=value (treat as flag only)
      final rest = arg.substring(2);
      final eqIndex = rest.indexOf('=');
      if (eqIndex > 0) {
        // --option=value - we ignore the value for flags
        return {rest.substring(0, eqIndex)};
      }
      return {rest};
    } else if (arg.startsWith('-')) {
      // Short flags: -v or -vf (multiple)
      return arg.substring(1).split('').toSet();
    }
    return {};
  }

  /// Merges global parameters/flags with command-specific ones.
  /// Command-specific takes precedence.
  ParsedCommand mergeWithGlobals(
    ParsedCommand cmd,
    Map<String, String> globalParams,
    Set<String> globalFlags,
  ) {
    return ParsedCommand(
      name: cmd.name,
      params: {...globalParams, ...cmd.params},
      flags: {...globalFlags, ...cmd.flags},
      positionalArgs: cmd.positionalArgs,
    );
  }
}

/// Convenience function to parse tom CLI arguments.
ParsedTomCommand parseTomCommand(List<String> args, {Set<String>? additionalCommands}) {
  final parser = TomCommandParser(additionalCommands: additionalCommands ?? const {});
  return parser.parse(args);
}
