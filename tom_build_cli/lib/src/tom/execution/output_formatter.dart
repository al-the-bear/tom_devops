// Output Formatter for Tom CLI
//
// Implements tom_tool_specification.md Section 9.2:
// - Error format: Error: <desc>, File: [...], Resolution: ...
// - Progress indicators for long operations
// - Verbose mode with detailed output
// - Color output when terminal supports it
// - Summary of completed actions

import 'dart:io';

import 'action_executor.dart';
import '../cli/internal_commands.dart';
import 'command_runner.dart';

// =============================================================================
// ANSI COLOR CODES
// =============================================================================

/// ANSI color codes for terminal output.
class AnsiColors {
  const AnsiColors._();

  // Reset
  static const String reset = '\x1B[0m';

  // Foreground colors
  static const String black = '\x1B[30m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';

  // Bright foreground colors
  static const String brightBlack = '\x1B[90m';
  static const String brightRed = '\x1B[91m';
  static const String brightGreen = '\x1B[92m';
  static const String brightYellow = '\x1B[93m';
  static const String brightBlue = '\x1B[94m';
  static const String brightMagenta = '\x1B[95m';
  static const String brightCyan = '\x1B[96m';
  static const String brightWhite = '\x1B[97m';

  // Styles
  static const String bold = '\x1B[1m';
  static const String dim = '\x1B[2m';
  static const String italic = '\x1B[3m';
  static const String underline = '\x1B[4m';
}

// =============================================================================
// OUTPUT FORMATTER CONFIGURATION
// =============================================================================

/// Configuration for the output formatter.
class OutputFormatterConfig {
  const OutputFormatterConfig({
    this.useColors = true,
    this.verbose = false,
    this.showProgress = true,
    this.showTimings = true,
    this.maxWidth = 80,
  });

  /// Whether to use ANSI colors in output.
  final bool useColors;

  /// Whether to show verbose output.
  final bool verbose;

  /// Whether to show progress indicators.
  final bool showProgress;

  /// Whether to show timing information.
  final bool showTimings;

  /// Maximum line width for output.
  final int maxWidth;

  /// Creates a new config with the specified overrides.
  OutputFormatterConfig copyWith({
    bool? useColors,
    bool? verbose,
    bool? showProgress,
    bool? showTimings,
    int? maxWidth,
  }) {
    return OutputFormatterConfig(
      useColors: useColors ?? this.useColors,
      verbose: verbose ?? this.verbose,
      showProgress: showProgress ?? this.showProgress,
      showTimings: showTimings ?? this.showTimings,
      maxWidth: maxWidth ?? this.maxWidth,
    );
  }
}

// =============================================================================
// ERROR MESSAGE
// =============================================================================

/// Represents a structured error message.
///
/// Per Section 9.2:
/// ```
/// Error: <description>
///   File: [<file_path>]
///   Line: [<line_number>]  (optional)
///   Resolution: <how to fix>
/// ```
class ErrorMessage {
  const ErrorMessage({
    required this.description,
    this.filePath,
    this.lineNumber,
    this.resolution,
    this.context,
  });

  /// Error description.
  final String description;

  /// File path where error occurred.
  final String? filePath;

  /// Line number where error occurred.
  final int? lineNumber;

  /// How to fix the error.
  final String? resolution;

  /// Additional context about the error.
  final String? context;

  /// Formats the error message.
  String format({bool useColors = false}) {
    final buffer = StringBuffer();
    final red = useColors ? AnsiColors.red : '';
    final yellow = useColors ? AnsiColors.yellow : '';
    final cyan = useColors ? AnsiColors.cyan : '';
    final reset = useColors ? AnsiColors.reset : '';
    final bold = useColors ? AnsiColors.bold : '';

    buffer.writeln('${red}${bold}Error:$reset $description');

    if (filePath != null) {
      buffer.writeln('  ${cyan}File:$reset [$filePath]');
    }

    if (lineNumber != null) {
      buffer.writeln('  ${cyan}Line:$reset [$lineNumber]');
    }

    if (context != null) {
      buffer.writeln('  ${cyan}Context:$reset $context');
    }

    if (resolution != null) {
      buffer.writeln('  ${yellow}Resolution:$reset $resolution');
    }

    return buffer.toString();
  }
}

// =============================================================================
// PROGRESS INDICATOR
// =============================================================================

/// A simple progress indicator for long operations.
class ProgressIndicator {
  ProgressIndicator({
    required this.message,
    required this.total,
    this.useColors = false,
  });

  /// Progress message.
  final String message;

  /// Total number of items.
  final int total;

  /// Whether to use colors.
  final bool useColors;

  /// Current progress count.
  int _current = 0;

  /// Whether progress is complete.
  bool _complete = false;

  /// Updates progress.
  void update(int current, {String? itemName}) {
    _current = current;
    _printProgress(itemName);
  }

  /// Increments progress by one.
  void increment({String? itemName}) {
    _current++;
    _printProgress(itemName);
  }

  /// Marks progress as complete.
  void complete({String? summary}) {
    _complete = true;
    final green = useColors ? AnsiColors.green : '';
    final reset = useColors ? AnsiColors.reset : '';

    // Clear line and print completion
    stdout.write('\r\x1B[K');
    if (summary != null) {
      stdout.writeln('${green}✓$reset $summary');
    } else {
      stdout.writeln('${green}✓$reset $message: Complete ($total/$total)');
    }
  }

  void _printProgress(String? itemName) {
    if (_complete) return;

    final cyan = useColors ? AnsiColors.cyan : '';
    final reset = useColors ? AnsiColors.reset : '';
    final percent = ((_current / total) * 100).toInt();

    stdout.write('\r\x1B[K');
    if (itemName != null) {
      stdout.write('$cyan$message:$reset [$_current/$total] $percent% - $itemName');
    } else {
      stdout.write('$cyan$message:$reset [$_current/$total] $percent%');
    }
  }
}

// =============================================================================
// OUTPUT FORMATTER
// =============================================================================

/// Formats output for the Tom CLI.
///
/// Provides consistent formatting for:
/// - Error messages (per Section 9.2)
/// - Success messages
/// - Progress indicators
/// - Action/command results
/// - Summaries
class OutputFormatter {
  OutputFormatter({
    OutputFormatterConfig? config,
    StringSink? output,
    StringSink? errorOutput,
  })  : _config = config ?? const OutputFormatterConfig(),
        _output = output ?? stdout,
        _errorOutput = errorOutput ?? stderr;

  final OutputFormatterConfig _config;
  final StringSink _output;
  final StringSink _errorOutput;

  /// Whether colors are enabled.
  bool get useColors => _config.useColors && _supportsColors();

  /// Checks if the terminal supports colors.
  bool _supportsColors() {
    if (!stdout.hasTerminal) return false;

    final term = Platform.environment['TERM'];
    if (term == null) return false;

    return term.contains('xterm') ||
        term.contains('color') ||
        term.contains('ansi') ||
        term == 'screen';
  }

  // ---------------------------------------------------------------------------
  // Error Formatting
  // ---------------------------------------------------------------------------

  /// Formats and prints an error message.
  void printError(ErrorMessage error) {
    _errorOutput.writeln(error.format(useColors: useColors));
  }

  /// Formats and prints a simple error string.
  void printErrorString(String message) {
    final red = useColors ? AnsiColors.red : '';
    final bold = useColors ? AnsiColors.bold : '';
    final reset = useColors ? AnsiColors.reset : '';

    _errorOutput.writeln('${red}${bold}Error:$reset $message');
  }

  /// Formats a circular dependency error (per Section 9.3).
  void printCircularDependencyError(List<String> cycle) {
    final error = ErrorMessage(
      description: 'Circular dependency detected',
      resolution: 'Remove one dependency to break the cycle',
    );

    _errorOutput.writeln(error.format(useColors: useColors));

    final cyan = useColors ? AnsiColors.cyan : '';
    final reset = useColors ? AnsiColors.reset : '';

    _errorOutput.writeln('  ${cyan}Cycle:$reset ${cycle.join(' → ')}');
  }

  /// Formats a placeholder recursion error (per Section 9.4).
  void printPlaceholderRecursionError({
    required String filePath,
    required List<String> unresolved,
  }) {
    final error = ErrorMessage(
      description: 'Placeholder recursion exceeded 10 levels',
      filePath: filePath,
      resolution: 'Check for circular placeholder references or missing definitions',
    );

    _errorOutput.writeln(error.format(useColors: useColors));

    final cyan = useColors ? AnsiColors.cyan : '';
    final reset = useColors ? AnsiColors.reset : '';

    _errorOutput.writeln('  ${cyan}Unresolved:$reset ${unresolved.join(', ')}');
  }

  /// Formats a scope conflict error (per Section 9.6).
  void printScopeConflictError(String command) {
    final error = ErrorMessage(
      description: 'Cannot use both [:projects] and [:groups] in the same command',
      resolution: 'Use either [:projects] OR [:groups], not both',
    );

    _errorOutput.writeln(error.format(useColors: useColors));

    final cyan = useColors ? AnsiColors.cyan : '';
    final reset = useColors ? AnsiColors.reset : '';

    _errorOutput.writeln('  ${cyan}Command:$reset $command');
  }

  // ---------------------------------------------------------------------------
  // Success/Info Formatting
  // ---------------------------------------------------------------------------

  /// Prints a success message.
  void printSuccess(String message) {
    final green = useColors ? AnsiColors.green : '';
    final reset = useColors ? AnsiColors.reset : '';

    _output.writeln('${green}✓$reset $message');
  }

  /// Prints an info message.
  void printInfo(String message) {
    final cyan = useColors ? AnsiColors.cyan : '';
    final reset = useColors ? AnsiColors.reset : '';

    _output.writeln('${cyan}ℹ$reset $message');
  }

  /// Prints a warning message.
  void printWarning(String message) {
    final yellow = useColors ? AnsiColors.yellow : '';
    final reset = useColors ? AnsiColors.reset : '';

    _output.writeln('${yellow}⚠$reset $message');
  }

  /// Prints a verbose message (only if verbose mode is enabled).
  void printVerbose(String message) {
    if (!_config.verbose) return;

    final dim = useColors ? AnsiColors.dim : '';
    final reset = useColors ? AnsiColors.reset : '';

    _output.writeln('$dim  $message$reset');
  }

  // ---------------------------------------------------------------------------
  // Progress Formatting
  // ---------------------------------------------------------------------------

  /// Creates a progress indicator.
  ProgressIndicator createProgress(String message, int total) {
    return ProgressIndicator(
      message: message,
      total: total,
      useColors: useColors,
    );
  }

  /// Prints a section header.
  void printHeader(String title) {
    final cyan = useColors ? AnsiColors.cyan : '';
    final bold = useColors ? AnsiColors.bold : '';
    final reset = useColors ? AnsiColors.reset : '';

    _output.writeln('');
    _output.writeln('$cyan$bold$title$reset');
    _output.writeln('$cyan${'─' * title.length}$reset');
  }

  // ---------------------------------------------------------------------------
  // Result Formatting
  // ---------------------------------------------------------------------------

  /// Formats a command run result.
  String formatCommandResult(CommandResult result) {
    final buffer = StringBuffer();
    final green = useColors ? AnsiColors.green : '';
    final red = useColors ? AnsiColors.red : '';
    final cyan = useColors ? AnsiColors.cyan : '';
    final dim = useColors ? AnsiColors.dim : '';
    final reset = useColors ? AnsiColors.reset : '';

    final statusIcon = result.success ? '${green}✓$reset' : '${red}✗$reset';
    final timing = _config.showTimings
        ? ' ${dim}(${_formatDuration(result.duration)})$reset'
        : '';

    buffer.writeln('$statusIcon ${cyan}${result.command}$reset$timing');

    if (_config.verbose) {
      if (result.stdout.isNotEmpty) {
        buffer.writeln('$dim  stdout: ${_truncate(result.stdout, 100)}$reset');
      }
      if (result.stderr.isNotEmpty) {
        buffer.writeln('$dim  stderr: ${_truncate(result.stderr, 100)}$reset');
      }
    }

    return buffer.toString();
  }

  /// Formats an action execution result.
  String formatActionResult(ActionExecutionResult result) {
    final buffer = StringBuffer();
    final green = useColors ? AnsiColors.green : '';
    final red = useColors ? AnsiColors.red : '';
    final cyan = useColors ? AnsiColors.cyan : '';
    final dim = useColors ? AnsiColors.dim : '';
    final reset = useColors ? AnsiColors.reset : '';

    final statusIcon = result.success ? '${green}✓$reset' : '${red}✗$reset';
    final timing = _config.showTimings
        ? ' ${dim}(${_formatDuration(result.duration)})$reset'
        : '';

    buffer.writeln(
        '$statusIcon ${cyan}${result.actionName}$reset on ${result.projectName}$timing');

    if (!result.success && result.error != null) {
      buffer.writeln('  ${red}Error:$reset ${result.error}');
    }

    if (_config.verbose) {
      for (final cmdResult in result.commandResults) {
        buffer.write('  ');
        buffer.write(formatCommandResult(cmdResult));
      }
    }

    return buffer.toString();
  }

  /// Formats an internal command result.
  String formatInternalCommandResult(InternalCommandResult result) {
    final buffer = StringBuffer();
    final green = useColors ? AnsiColors.green : '';
    final red = useColors ? AnsiColors.red : '';
    final cyan = useColors ? AnsiColors.cyan : '';
    final dim = useColors ? AnsiColors.dim : '';
    final reset = useColors ? AnsiColors.reset : '';

    final statusIcon = result.success ? '${green}✓$reset' : '${red}✗$reset';
    final timing = _config.showTimings
        ? ' ${dim}(${_formatDuration(result.duration)})$reset'
        : '';

    buffer.writeln('$statusIcon ${cyan}:${result.command}$reset$timing');

    if (result.message != null && _config.verbose) {
      buffer.writeln('$dim  ${result.message}$reset');
    }

    if (!result.success && result.error != null) {
      buffer.writeln('  ${red}Error:$reset ${result.error}');
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Summary Formatting
  // ---------------------------------------------------------------------------

  /// Formats a summary of action and command results.
  String formatSummary({
    required List<ActionExecutionResult> actionResults,
    required List<InternalCommandResult> commandResults,
    required Duration totalDuration,
  }) {
    final buffer = StringBuffer();
    final green = useColors ? AnsiColors.green : '';
    final red = useColors ? AnsiColors.red : '';
    final cyan = useColors ? AnsiColors.cyan : '';
    final bold = useColors ? AnsiColors.bold : '';
    final dim = useColors ? AnsiColors.dim : '';
    final reset = useColors ? AnsiColors.reset : '';

    buffer.writeln('');
    buffer.writeln('$cyan${bold}Summary$reset');
    buffer.writeln('$cyan───────$reset');

    // Count successes and failures
    final actionSuccess = actionResults.where((r) => r.success).length;
    final actionFailure = actionResults.length - actionSuccess;
    final cmdSuccess = commandResults.where((r) => r.success).length;
    final cmdFailure = commandResults.length - cmdSuccess;

    if (actionResults.isNotEmpty) {
      final actionIcon = actionFailure == 0 ? '${green}✓$reset' : '${red}✗$reset';
      buffer.writeln(
          '$actionIcon Actions: $actionSuccess passed, $actionFailure failed');
    }

    if (commandResults.isNotEmpty) {
      final cmdIcon = cmdFailure == 0 ? '${green}✓$reset' : '${red}✗$reset';
      buffer.writeln(
          '$cmdIcon Commands: $cmdSuccess passed, $cmdFailure failed');
    }

    buffer.writeln('$dim  Duration: ${_formatDuration(totalDuration)}$reset');

    return buffer.toString();
  }

  /// Prints the summary.
  void printSummary({
    required List<ActionExecutionResult> actionResults,
    required List<InternalCommandResult> commandResults,
    required Duration totalDuration,
  }) {
    _output.write(formatSummary(
      actionResults: actionResults,
      commandResults: commandResults,
      totalDuration: totalDuration,
    ));
  }

  // ---------------------------------------------------------------------------
  // Help Formatting
  // ---------------------------------------------------------------------------

  /// Formats help text.
  String formatHelp({
    required String toolName,
    required String version,
    required String description,
    required List<String> usage,
    required Map<String, String> commands,
    required Map<String, String> options,
  }) {
    final buffer = StringBuffer();
    final cyan = useColors ? AnsiColors.cyan : '';
    final bold = useColors ? AnsiColors.bold : '';
    final dim = useColors ? AnsiColors.dim : '';
    final reset = useColors ? AnsiColors.reset : '';

    // Title
    buffer.writeln('$cyan$bold$toolName$reset v$version');
    buffer.writeln('');
    buffer.writeln(description);
    buffer.writeln('');

    // Usage
    buffer.writeln('${cyan}Usage:$reset');
    for (final u in usage) {
      buffer.writeln('  $u');
    }
    buffer.writeln('');

    // Commands
    if (commands.isNotEmpty) {
      buffer.writeln('${cyan}Commands:$reset');
      final maxLen = commands.keys.map((k) => k.length).reduce((a, b) => a > b ? a : b);
      for (final entry in commands.entries) {
        final padding = ' ' * (maxLen - entry.key.length + 2);
        buffer.writeln('  ${entry.key}$padding$dim${entry.value}$reset');
      }
      buffer.writeln('');
    }

    // Options
    if (options.isNotEmpty) {
      buffer.writeln('${cyan}Options:$reset');
      final maxLen = options.keys.map((k) => k.length).reduce((a, b) => a > b ? a : b);
      for (final entry in options.entries) {
        final padding = ' ' * (maxLen - entry.key.length + 2);
        buffer.writeln('  ${entry.key}$padding$dim${entry.value}$reset');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Utility Methods
  // ---------------------------------------------------------------------------

  /// Formats a duration.
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final mins = duration.inMinutes.remainder(60);
      final secs = duration.inSeconds.remainder(60);
      return '${duration.inHours}h ${mins}m ${secs}s';
    } else if (duration.inMinutes > 0) {
      final secs = duration.inSeconds.remainder(60);
      return '${duration.inMinutes}m ${secs}s';
    } else if (duration.inSeconds > 0) {
      final millis = duration.inMilliseconds.remainder(1000);
      return '${duration.inSeconds}.${(millis ~/ 100)}s';
    } else {
      return '${duration.inMilliseconds}ms';
    }
  }

  /// Truncates a string.
  String _truncate(String text, int maxLength) {
    final oneLine = text.replaceAll('\n', ' ').trim();
    if (oneLine.length <= maxLength) return oneLine;
    return '${oneLine.substring(0, maxLength - 3)}...';
  }
}
