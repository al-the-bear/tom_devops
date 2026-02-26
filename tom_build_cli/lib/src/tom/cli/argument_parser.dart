/// Command-line argument parsing for Tom CLI.
///
/// Handles parsing of CLI arguments according to Section 6.1
/// of the Tom tool specification.
library;

// =============================================================================
// PARSED ARGUMENTS
// =============================================================================

/// Represents parsed command-line arguments.
class ParsedArguments {
  /// Global parameters (before :projects/:groups).
  final Map<String, String> globalParameters;

  /// Whether :projects scope limiter was specified.
  final bool hasProjectsScope;

  /// Whether :groups scope limiter was specified.
  final bool hasGroupsScope;

  /// List of project names (if :projects was specified).
  final List<String> projects;

  /// Project-specific parameters (project name -> parameters).
  final Map<String, Map<String, String>> projectParameters;

  /// List of group names (if :groups was specified).
  final List<String> groups;

  /// Group-specific parameters (group name -> parameters).
  final Map<String, Map<String, String>> groupParameters;

  /// List of actions to execute.
  final List<ActionInvocation> actions;

  /// Whether --help was requested.
  final bool helpRequested;

  /// Whether --version was requested.
  final bool versionRequested;

  /// Whether verbose mode is enabled.
  final bool verbose;

  /// Whether dry-run mode is enabled.
  final bool dryRun;

  /// Creates parsed arguments.
  const ParsedArguments({
    this.globalParameters = const {},
    this.hasProjectsScope = false,
    this.hasGroupsScope = false,
    this.projects = const [],
    this.projectParameters = const {},
    this.groups = const [],
    this.groupParameters = const {},
    this.actions = const [],
    this.helpRequested = false,
    this.versionRequested = false,
    this.verbose = false,
    this.dryRun = false,
  });

  /// Whether this targets all projects (no scope limiter).
  bool get targetsAllProjects => !hasProjectsScope && !hasGroupsScope;

  /// Gets the list of target identifiers (projects or groups).
  List<String> get targets => hasProjectsScope ? projects : groups;
}

/// Represents a single action invocation.
class ActionInvocation {
  /// The action name (without colon prefix).
  final String name;

  /// Parameters for this action.
  final Map<String, String> parameters;

  /// Whether this is an internal command (not a workspace action).
  final bool isInternalCommand;

  /// Whether this bypasses workspace action (! prefix).
  final bool bypassWorkspaceAction;

  /// Creates an action invocation.
  const ActionInvocation({
    required this.name,
    this.parameters = const {},
    this.isInternalCommand = false,
    this.bypassWorkspaceAction = false,
  });
}

// =============================================================================
// ARGUMENT PARSER
// =============================================================================

/// Parses command-line arguments for Tom CLI.
///
/// Supports the syntax defined in Section 6.1:
/// ```
/// tom [<global-params>] :projects <p1> [<p1-params>] ... :<action1> [<a1-params>]
/// tom [<global-params>] :groups <g1> [<g1-params>] ... :<action1> [<a1-params>]
/// tom [<global-params>] :<action1> [<a1-params>]
/// ```
class ArgumentParser {
  /// Internal commands that are recognized.
  static const Set<String> internalCommands = {
    'analyze',
    'generate-reflection',
    'version-bump',
    'prepper',
    'reset-action-counter',
    'pipeline',
    'help',
    'version',
    'vscode',
    'dartscript',
  };

  /// Argument prefixes for targeting specific commands.
  static const Map<String, String> argumentPrefixes = {
    'wa-': 'analyze',
    'gr-': 'generate-reflection',
    'vb-': 'version-bump',
    'wp-': 'prepper',
  };

  /// Parses command-line arguments.
  ///
  /// Throws [ArgumentError] if the arguments are invalid.
  ///
  /// ## Default Command
  ///
  /// If no internal command (`:command`) is specified and the first non-flag
  /// argument looks like a file or code, `:dartscript` is used as the default:
  ///
  /// ```
  /// tom script.dart          → tom :dartscript -file=script.dart
  /// tom "print('hi')"        → tom :dartscript -code="print('hi')"
  /// tom -expression "1+1"    → tom :dartscript -mode=expression -code="1+1"
  /// ```
  ParsedArguments parse(List<String> args) {
    if (args.isEmpty) {
      return const ParsedArguments(helpRequested: true);
    }

    // Check for default dartscript pattern
    final transformedArgs = _transformForDefaultCommand(args);

    final globalParams = <String, String>{};
    final projects = <String>[];
    final projectParams = <String, Map<String, String>>{};
    final groups = <String>[];
    final groupParams = <String, Map<String, String>>{};
    final actions = <ActionInvocation>[];

    var hasProjectsScope = false;
    var hasGroupsScope = false;
    var helpRequested = false;
    var versionRequested = false;
    var verbose = false;
    var dryRun = false;

    var i = 0;
    _ParseState state = _ParseState.global;
    String? currentProject;
    String? currentGroup;
    String? currentAction;
    Map<String, String> currentActionParams = {};
    var currentActionIsInternal = false;
    var currentActionBypass = false;

    // Helper to finalize current action
    void finalizeAction() {
      if (currentAction != null) {
        actions.add(
          ActionInvocation(
            name: currentAction!,
            parameters: Map.from(currentActionParams),
            isInternalCommand: currentActionIsInternal,
            bypassWorkspaceAction: currentActionBypass,
          ),
        );
        currentAction = null;
        currentActionParams = {};
        currentActionIsInternal = false;
        currentActionBypass = false;
      }
    }

    while (i < transformedArgs.length) {
      final arg = transformedArgs[i];

      // Check for help/version flags
      if (arg == '-help' || arg == '--help' || arg == '-h') {
        helpRequested = true;
        i++;
        continue;
      }
      if (arg == '-version' || arg == '--version' || arg == '-v') {
        versionRequested = true;
        i++;
        continue;
      }
      if (arg == '-verbose' || arg == '--verbose') {
        verbose = true;
        i++;
        continue;
      }
      if (arg == '-dry-run' || arg == '--dry-run') {
        dryRun = true;
        i++;
        continue;
      }

      // Check for scope limiters
      if (arg == ':projects') {
        if (hasGroupsScope) {
          throw ArgumentError('Cannot use both :projects and :groups');
        }
        finalizeAction();
        hasProjectsScope = true;
        state = _ParseState.projects;
        i++;
        continue;
      }
      if (arg == ':groups') {
        if (hasProjectsScope) {
          throw ArgumentError('Cannot use both :projects and :groups');
        }
        finalizeAction();
        hasGroupsScope = true;
        state = _ParseState.groups;
        i++;
        continue;
      }

      // Check for action/command invocation
      if (arg.startsWith(':') || arg.startsWith('!')) {
        finalizeAction();

        // Parse action name
        final bypass = arg.startsWith('!');
        final name = arg.substring(1);

        currentAction = name;
        currentActionParams = {};
        currentActionIsInternal = internalCommands.contains(name);
        currentActionBypass = bypass;
        state = _ParseState.actionParams;
        i++;
        continue;
      }

      // Parse based on current state
      switch (state) {
        case _ParseState.global:
          // Global parameter
          final param = _parseParameter(arg);
          if (param != null) {
            globalParams[param.key] = param.value;
            // Check for verbose/dry-run in parameters
            if (param.key == 'verbose' && param.value == 'true') {
              verbose = true;
            }
            if (param.key == 'dry-run' && param.value == 'true') {
              dryRun = true;
            }
          } else {
            // Unknown argument in global position
            throw ArgumentError('Unexpected argument: $arg');
          }

        case _ParseState.projects:
          if (_isParameter(arg)) {
            // Project-specific parameter
            if (currentProject != null) {
              final param = _parseParameter(arg);
              if (param != null) {
                projectParams.putIfAbsent(currentProject, () => {});
                projectParams[currentProject]![param.key] = param.value;
              }
            }
          } else if (!arg.startsWith(':') && !arg.startsWith('!')) {
            // Project name
            projects.add(arg);
            currentProject = arg;
          }

        case _ParseState.groups:
          if (_isParameter(arg)) {
            // Group-specific parameter
            if (currentGroup != null) {
              final param = _parseParameter(arg);
              if (param != null) {
                groupParams.putIfAbsent(currentGroup, () => {});
                groupParams[currentGroup]![param.key] = param.value;
              }
            }
          } else if (!arg.startsWith(':') && !arg.startsWith('!')) {
            // Group name
            groups.add(arg);
            currentGroup = arg;
          }

        case _ParseState.actionParams:
          if (_isParameter(arg)) {
            // Action parameter
            final param = _parseParameter(arg);
            if (param != null) {
              currentActionParams[param.key] = param.value;
            }
          } else if (currentAction == 'vscode' &&
              !currentActionParams.containsKey('hostport')) {
            // Positional host/port parameter for :vscode
            currentActionParams['hostport'] = arg;
          }
      }

      i++;
    }

    // Finalize any pending action
    finalizeAction();

    return ParsedArguments(
      globalParameters: globalParams,
      hasProjectsScope: hasProjectsScope,
      hasGroupsScope: hasGroupsScope,
      projects: projects,
      projectParameters: projectParams,
      groups: groups,
      groupParameters: groupParams,
      actions: actions,
      helpRequested: helpRequested,
      versionRequested: versionRequested,
      verbose: verbose,
      dryRun: dryRun,
    );
  }

  /// Checks if an argument is a parameter (starts with -).
  bool _isParameter(String arg) {
    return arg.startsWith('-');
  }

  /// Parses a parameter argument.
  ///
  /// Supports formats:
  /// - `-key=value`
  /// - `-key` (value is 'true')
  /// - `--key=value`
  /// - `--key` (value is 'true')
  _ParsedParameter? _parseParameter(String arg) {
    if (!arg.startsWith('-')) return null;

    // Remove leading dashes
    var stripped = arg;
    if (stripped.startsWith('--')) {
      stripped = stripped.substring(2);
    } else if (stripped.startsWith('-')) {
      stripped = stripped.substring(1);
    }

    // Check for prefix (e.g., wa-, gr-)
    String? prefix;
    for (final p in argumentPrefixes.keys) {
      if (stripped.startsWith(p)) {
        prefix = p;
        stripped = stripped.substring(p.length);
        break;
      }
    }

    // Parse key=value
    final equalsIndex = stripped.indexOf('=');
    String key;
    String value;

    if (equalsIndex > 0) {
      key = stripped.substring(0, equalsIndex);
      value = stripped.substring(equalsIndex + 1);
    } else {
      key = stripped;
      value = 'true';
    }

    // Store prefix in key if present
    if (prefix != null) {
      key = '$prefix$key';
    }

    return _ParsedParameter(key: key, value: value);
  }

  /// Transforms arguments for default :dartscript command.
  ///
  /// If no command (`:command`) is specified and arguments look like a
  /// dartscript invocation, transforms to explicit `:dartscript` format.
  ///
  /// Patterns:
  /// - `script.dart` → `:dartscript -file=script.dart`
  /// - `"code"` → `:dartscript -code="code"`
  /// - `-script script.dart` → `:dartscript -mode=script -file=script.dart`
  /// - `-expression "code"` → `:dartscript -mode=expression -code="code"`
  /// - `script.dart -script` → `:dartscript -file=script.dart -mode=script`
  List<String> _transformForDefaultCommand(List<String> args) {
    // Skip if already has a command
    if (_hasExplicitCommand(args)) {
      return args;
    }

    // Find the file or code argument and mode flags
    String? fileOrCode;
    String? mode;
    final otherArgs = <String>[];

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];

      // Check for mode flags
      if (arg == '-script' || arg == '--script') {
        mode = 'script';
        continue;
      }
      if (arg == '-expression' || arg == '--expression') {
        mode = 'expression';
        continue;
      }

      // Skip global flags that should be preserved
      if (_isGlobalFlag(arg)) {
        otherArgs.add(arg);
        continue;
      }

      // First non-flag, non-mode argument is the file or code
      if (fileOrCode == null && !arg.startsWith('-')) {
        fileOrCode = arg;
        continue;
      }

      // Other arguments pass through
      otherArgs.add(arg);
    }

    // If no file/code found, return original args
    if (fileOrCode == null) {
      return args;
    }

    // Build transformed arguments
    final result = <String>[':dartscript'];

    // Add file or code parameter
    if (fileOrCode.endsWith('.dart')) {
      result.add('-file=$fileOrCode');
    } else if (fileOrCode.startsWith('"') && fileOrCode.endsWith('"')) {
      // Quoted code
      result.add('-code=$fileOrCode');
    } else if (fileOrCode.startsWith("'") && fileOrCode.endsWith("'")) {
      // Single quoted code
      result.add('-code=$fileOrCode');
    } else {
      // Assume it's code
      result.add('-code=$fileOrCode');
    }

    // Add mode if specified
    if (mode != null) {
      result.add('-mode=$mode');
    }

    // Add other arguments
    result.addAll(otherArgs);

    return result;
  }

  /// Checks if arguments contain an explicit command.
  bool _hasExplicitCommand(List<String> args) {
    for (final arg in args) {
      if (arg.startsWith(':') || arg.startsWith('!')) {
        return true;
      }
    }
    return false;
  }

  /// Checks if an argument is a global flag.
  bool _isGlobalFlag(String arg) {
    return arg == '-help' ||
        arg == '--help' ||
        arg == '-h' ||
        arg == '-version' ||
        arg == '--version' ||
        arg == '-v' ||
        arg == '-verbose' ||
        arg == '--verbose' ||
        arg == '-dry-run' ||
        arg == '--dry-run';
  }
}

// =============================================================================
// PRIVATE HELPERS
// =============================================================================

/// Parse states for the argument parser.
enum _ParseState { global, projects, groups, actionParams }

/// A parsed parameter key-value pair.
class _ParsedParameter {
  final String key;
  final String value;

  const _ParsedParameter({required this.key, required this.value});
}

// =============================================================================
// EXTENSIONS
// =============================================================================

/// Extension methods for ParsedArguments.
extension ParsedArgumentsExtensions on ParsedArguments {
  /// Gets parameters for a specific action, including global parameters.
  Map<String, String> getActionParameters(String actionName) {
    final result = Map<String, String>.from(globalParameters);

    // Find action and add its parameters
    for (final action in actions) {
      if (action.name == actionName) {
        result.addAll(action.parameters);
        break;
      }
    }

    return result;
  }

  /// Gets the list of action names.
  List<String> get actionNames => actions.map((a) => a.name).toList();

  /// Whether any internal commands are present.
  bool get hasInternalCommands => actions.any((a) => a.isInternalCommand);
}
