/// D4rt expression execution for Tom CLI.
///
/// Handles running D4rt expressions and scripts during action execution.
/// Supports multiple command types as defined in Section 5.4.2.
///
/// ## Command Types
///
/// | Type | Syntax | Example |
/// |------|--------|---------|
/// | D4rt expression | `$D4{expr}` | `$D4{buildProject(options)}` |
/// | D4rt script (inline) | `$D4S{file}` | `$D4S{deploy.dart}` |
/// | D4rt script (multiline) | String starting with `$D4S\n` | See docs |
/// | D4rt method (multiline) | String starting with `$D4M\n` | See docs |
/// | Reflection call | `Class.method()` or `Class.property` | `BuildTool.generate()` |
/// | VS Code expression | `$VSCODE{expr}` | `$VSCODE{vscode.window.showMessage()}` |
/// | VS Code script | `$VSCODE{file.dart}` | `$VSCODE{deploy.dart}` |
/// | VS Code multiline script | `$VSCODE{\n<code>}` | Detected by leading newline |
/// | VS Code multiline method | `$VSCODE{\n(){<code>}}` | Detected by `\n(){` prefix |
library;

import 'dart:async';
import 'dart:io';

import 'package:tom_build/tom_build.dart';
import '../cli/workspace_context.dart';
import '../../dartscript/bridge_configuration.dart';
import '../../dartscript/d4rt_instance.dart';
import '../../dartscript/d4rt_context_provider.dart';

// =============================================================================
// D4RT RUNNER
// =============================================================================

/// Result of executing D4rt code.
class D4rtResult {
  /// The D4rt code that was executed.
  final String code;

  /// Whether execution was successful.
  final bool success;

  /// The result value (if any).
  final dynamic value;

  /// The output (stdout).
  final String output;

  /// Error message if execution failed.
  final String? error;

  /// Duration of execution.
  final Duration duration;

  const D4rtResult._({
    required this.code,
    required this.success,
    this.value,
    required this.output,
    this.error,
    required this.duration,
  });

  /// Creates a successful result.
  factory D4rtResult.success({
    required String code,
    dynamic value,
    String output = '',
    Duration duration = Duration.zero,
  }) {
    return D4rtResult._(
      code: code,
      success: true,
      value: value,
      output: output,
      duration: duration,
    );
  }

  /// Creates a failed result.
  factory D4rtResult.failure({
    required String code,
    required String error,
    String output = '',
    Duration duration = Duration.zero,
  }) {
    return D4rtResult._(
      code: code,
      success: false,
      output: output,
      error: error,
      duration: duration,
    );
  }
}

/// Configuration for D4rt execution.
class D4rtRunnerConfig {
  /// Path to the workspace root directory.
  final String workspacePath;

  /// Path to the tom_scripts directory.
  final String? scriptsPath;

  /// Whether to run in verbose mode.
  final bool verbose;

  /// Context variables available to D4rt code.
  final Map<String, dynamic> context;

  /// The loaded workspace for initializing the global `tom` context.
  ///
  /// If provided, the D4rt instance will have access to `tom.workspace`,
  /// `tom.projectInfo`, etc. If null, `tom.isInitialized` will be false.
  final TomWorkspace? workspace;

  /// The workspace context with runtime state.
  final WorkspaceContext? workspaceContext;

  /// The current project (if operating in project context).
  final TomProject? currentProject;

  /// Creates D4rt runner configuration.
  const D4rtRunnerConfig({
    required this.workspacePath,
    this.scriptsPath,
    this.verbose = false,
    this.context = const {},
    this.workspace,
    this.workspaceContext,
    this.currentProject,
  });

  /// Gets the scripts directory path.
  String get scriptsDir => scriptsPath ?? '$workspacePath/tom_scripts/lib';
}

/// Type of D4rt command.
enum D4rtCommandType {
  /// Inline expression: $D4{expr}
  expression,

  /// Inline script file reference: $D4S{file.dart}
  scriptFileInline,

  /// Multiline script: String starting with $D4S\n
  scriptMultiline,

  /// Multiline method: String starting with $D4M\n
  methodMultiline,

  /// Reflection call: Class.method() or Class.property
  reflectionCall,

  /// VS Code D4rt expression: $VSCODE{expr}
  /// Executed via VS Code VS Code Bridge socket
  vscodeExpression,

  /// VS Code D4rt script file: $VSCODE{file.dart} (detected by .dart suffix)
  /// Executed via VS Code VS Code Bridge socket
  vscodeScriptFile,

  /// VS Code D4rt multiline script: $VSCODE{\n<code>} (detected by leading newline)
  /// Executed via VS Code VS Code Bridge socket
  vscodeScriptMultiline,

  /// VS Code D4rt multiline method: $VSCODE{\n(){<code>}} (detected by \n(){ prefix)
  /// Executed via VS Code VS Code Bridge socket
  vscodeMethodMultiline,

  /// Not a D4rt command (shell command)
  shell,
}

/// Runs D4rt expressions and scripts.
///
/// Supports command types defined in Section 5.4.2:
/// - D4rt expression: `$D4{expr}`
/// - D4rt script (inline): `$D4S{file.dart}`
/// - D4rt script (multiline): String starting with `$D4S\n`
/// - D4rt method (multiline): String starting with `$D4M\n`
/// - Reflection call: `Class.method()` or `Class.property`
///
/// VS Code bridge commands (executed via socket on port 9742 default):
/// - Expression: `$VSCODE{expr}`
/// - Script file: `$VSCODE{file.dart}` (detected by .dart suffix)
/// - Multiline script: `$VSCODE{\n<code>}` (detected by leading newline)
/// - Multiline method: `$VSCODE{\n(){<code>}}` (detected by \n(){ prefix)
/// - With port: `$VSCODE:{9743}expr`, `$VSCODE:{9743}file.dart`
///
/// The optional `<port>` allows specifying a custom port for the VS Code bridge.
class D4rtRunner {
  /// Creates a D4rt runner.
  ///
  /// If no evaluator is provided, creates a real D4rt evaluator using the
  /// workspace from the config (if available).
  D4rtRunner({
    required this.config,
    ActionD4rtEvaluator? evaluator,
  }) : _evaluator = evaluator ??
            createRealD4rtEvaluator(
              workspace: config.workspace,
              workspaceContext: config.workspaceContext,
              currentProject: config.currentProject,
              workspacePath: config.workspacePath,
              globalContext: config.context,
            );

  /// Runner configuration.
  final D4rtRunnerConfig config;

  final ActionD4rtEvaluator _evaluator;

  /// Determines the type of a command.
  ///
  /// D4rt commands use the `$D4{...}` syntax with auto-detection:
  /// - `$D4{expression}` - expression (default)
  /// - `$D4{file.dart}` - script file (detected by .dart suffix)
  /// - `$D4{\n<code>}` - multiline script (detected by leading newline)
  /// - `$D4{\n(){<code>}}` - multiline method (detected by \n(){ prefix)
  ///
  /// VS Code commands use the `$VSCODE{...}` syntax with same auto-detection:
  /// - `$VSCODE{expression}` - expression (default)
  /// - `$VSCODE{file.dart}` - script file (detected by .dart suffix)
  /// - `$VSCODE{\n<code>}` - multiline script (detected by leading newline)
  /// - `$VSCODE{\n(){<code>}}` - multiline method (detected by \n(){ prefix)
  /// - `$VSCODE:{9743}expr` - custom port
  ///
  /// Returns [D4rtCommandType.shell] if the command is not a D4rt command.
  D4rtCommandType getCommandType(String command) {
    final trimmed = command.trim();

    // $VSCODE{...} syntax with auto-detection
    if (_matchesVSCodePlaceholder(trimmed)) {
      final content = _getVSCodeContent(trimmed);
      final body = _getVSCodeBody(content);

      // Multiline method: \n(){<code>} (starts with newline + (){)
      if (body.startsWith('\n(){') && body.endsWith('}')) {
        return D4rtCommandType.vscodeMethodMultiline;
      }
      // Multiline script: \n<code> (starts with newline, not a method)
      if (body.startsWith('\n')) {
        return D4rtCommandType.vscodeScriptMultiline;
      }
      // Script file: file.dart (ends with .dart suffix)
      if (body.endsWith('.dart')) {
        return D4rtCommandType.vscodeScriptFile;
      }
      // Expression (default)
      return D4rtCommandType.vscodeExpression;
    }

    // $D4{...} syntax with auto-detection (same pattern as $VSCODE)
    if (_matchesD4Placeholder(trimmed)) {
      final body = _getD4Body(trimmed);

      // Multiline method: \n(){<code>} (starts with newline + (){)
      if (body.startsWith('\n(){') && body.endsWith('}')) {
        return D4rtCommandType.methodMultiline;
      }
      // Multiline script: \n<code> (starts with newline, not a method)
      if (body.startsWith('\n')) {
        return D4rtCommandType.scriptMultiline;
      }
      // Script file: file.dart (ends with .dart suffix)
      if (body.endsWith('.dart')) {
        return D4rtCommandType.scriptFileInline;
      }
      // Expression (default)
      return D4rtCommandType.expression;
    }

    // Simple file.dart - ends with .dart, no parens (for command execution)
    if (trimmed.endsWith('.dart') && !trimmed.contains('(')) {
      return D4rtCommandType.scriptFileInline;
    }

    // Reflection call: Class.method() - starts with uppercase, contains dot
    // and ends with () (Optional args inside)
    final reflectionPattern =
        RegExp(r'^[A-Z][a-zA-Z0-9]*\.[a-zA-Z0-9]+(\(.*\))?$');
    if (reflectionPattern.hasMatch(trimmed)) {
      return D4rtCommandType.reflectionCall;
    }

    return D4rtCommandType.shell;
  }

  /// Checks if a command is a D4rt command (local or VS Code).
  bool isD4rtCommand(String command) {
    return getCommandType(command) != D4rtCommandType.shell;
  }

  /// Checks if a command requires VS Code bridge execution.
  bool isVSCodeCommand(String command) {
    final type = getCommandType(command);
    return type == D4rtCommandType.vscodeExpression ||
        type == D4rtCommandType.vscodeScriptFile ||
        type == D4rtCommandType.vscodeScriptMultiline ||
        type == D4rtCommandType.vscodeMethodMultiline;
  }

  /// Checks if a command is a local D4rt command (not VS Code).
  bool isLocalD4rtCommand(String command) {
    final type = getCommandType(command);
    return type != D4rtCommandType.shell && !isVSCodeCommand(command);
  }

  // ---------------------------------------------------------------------------
  // D4rt Command Pattern Matching Helpers
  // ---------------------------------------------------------------------------

  /// Pattern for D4rt placeholder: $D4{...}
  static final RegExp _d4Pattern = RegExp(r'^\$D4\{', caseSensitive: false);

  /// Matches D4rt placeholder patterns like $D4{
  bool _matchesD4Placeholder(String command) {
    return _d4Pattern.hasMatch(command) && command.endsWith('}');
  }

  /// Gets the body inside $D4{...}
  String _getD4Body(String command) {
    if (!_matchesD4Placeholder(command)) return '';
    // Extract content between $D4{ and }
    const prefixLength = 4; // length of '$D4{'
    return command.substring(prefixLength, command.length - 1);
  }

  // ---------------------------------------------------------------------------
  // VS Code Command Pattern Matching Helpers
  // ---------------------------------------------------------------------------

  /// Pattern for VS Code placeholder: $VSCODE{...} or $VSCODE:{port}...
  /// Syntax: $VSCODE{expr}, $VSCODE:{9743}expr
  static final RegExp _vscodePattern = RegExp(r'^\$VSCODE\{', caseSensitive: false);

  /// Matches VS Code placeholder patterns like $VSCODE{ or $VSCODE:{port}
  bool _matchesVSCodePlaceholder(String command) {
    return _vscodePattern.hasMatch(command) && command.endsWith('}');
  }

  /// Extracts the content inside $VSCODE{...}
  String _getVSCodeContent(String command) {
    if (!_matchesVSCodePlaceholder(command)) return '';
    // Extract content between $VSCODE{ and }
    final start = command.indexOf('{') + 1;
    return command.substring(start, command.length - 1);
  }

  /// Gets the body after stripping port from $VSCODE content.
  ///
  /// Port syntax: `:{port}rest` e.g. `$VSCODE{:{9743}expr}` -> body is `expr`
  /// Without port: returns content as-is
  String _getVSCodeBody(String content) {
    // Port syntax: :{port}rest where port is wrapped in braces
    if (content.startsWith(':{')) {
      final endBrace = content.indexOf('}', 2);
      if (endBrace > 0) {
        return content.substring(endBrace + 1);
      }
    }
    return content;
  }

  /// Runs a D4rt command.
  ///
  /// Returns a [D4rtResult] with the execution result.
  Future<D4rtResult> run(String command) async {
    final stopwatch = Stopwatch()..start();
    final type = getCommandType(command);

    try {
      switch (type) {
        case D4rtCommandType.expression:
          return await _runExpression(command, stopwatch);

        case D4rtCommandType.scriptFileInline:
          return await _runScriptFileInline(command, stopwatch);

        case D4rtCommandType.scriptMultiline:
          return await _runScriptMultiline(command, stopwatch);

        case D4rtCommandType.methodMultiline:
          return await _runMethodMultiline(command, stopwatch);

        case D4rtCommandType.reflectionCall:
          return await _runReflectionCall(command, stopwatch);

        case D4rtCommandType.vscodeExpression:
        case D4rtCommandType.vscodeScriptFile:
        case D4rtCommandType.vscodeScriptMultiline:
        case D4rtCommandType.vscodeMethodMultiline:
          // VS Code commands are handled by VSCodeBridgeClient, not D4rtRunner
          return D4rtResult.failure(
            code: command,
            error: 'VS Code commands must be executed via VSCodeBridgeClient.',
            duration: stopwatch.elapsed,
          );

        case D4rtCommandType.shell:
          // Not a D4rt command, should use CommandRunner
          return D4rtResult.failure(
            code: command,
            error: 'Not a D4rt command. Use CommandRunner for shell commands.',
            duration: stopwatch.elapsed,
          );
      }
    } catch (e) {
      stopwatch.stop();
      return D4rtResult.failure(
        code: command,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Runs a D4rt expression: $D4{expr}
  Future<D4rtResult> _runExpression(String command, Stopwatch stopwatch) async {
    // Extract expression from $D4{...}
    final expr = _getD4Body(command).trim();

    // Capture print output using Zone - print directly to stdout for pipe compatibility
    final capturedOutput = StringBuffer();
    final result = await runZoned(
      () => _evaluator(expr, config.context),
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          capturedOutput.writeln(line);
          // Print directly to stdout for pipe compatibility
          stdout.writeln(line);
        },
      ),
    );
    stopwatch.stop();

    // Print expression result to stdout (for pipe scripts)
    final resultStr = result?.toString() ?? '';
    if (resultStr.isNotEmpty && resultStr != 'null') {
      stdout.writeln(resultStr);
      capturedOutput.writeln(resultStr);
    }

    return D4rtResult.success(
      code: command,
      value: result,
      output: capturedOutput.toString().trim(),
      duration: stopwatch.elapsed,
    );
  }

  /// Runs a D4rt script file (inline): $D4{file.dart} or simple file.dart
  Future<D4rtResult> _runScriptFileInline(
      String command, Stopwatch stopwatch) async {
    String filePath;
    if (_matchesD4Placeholder(command)) {
      // Extract file path from $D4{file.dart}
      filePath = _getD4Body(command).trim();
    } else {
      // Simple file path: file.dart
      filePath = command.trim();
    }
    return await _runScriptFile(filePath, stopwatch);
  }

  /// Runs a D4rt multiline script: $D4{\n<code>}
  Future<D4rtResult> _runScriptMultiline(
      String command, Stopwatch stopwatch) async {
    // Extract script body from $D4{\n<code>}
    final body = _getD4Body(command).trim();

    // Wrap in immediately invoked function expression (IIFE) so eval() executes it
    // Format: ((){ <code> })()
    final wrappedCode = '((){ $body })()';
    
    // Capture print output using Zone - print directly to stdout for pipe compatibility
    final capturedOutput = StringBuffer();
    final result = await runZoned(
      () async {
        return await _evaluator(wrappedCode, config.context);
      },
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          capturedOutput.writeln(line);
          // Print directly to stdout for pipe compatibility
          stdout.writeln(line);
        },
      ),
    );
    stopwatch.stop();

    // Print result to stdout if not null (for pipe scripts)
    final resultStr = result?.toString() ?? '';
    if (resultStr.isNotEmpty && resultStr != 'null') {
      stdout.writeln(resultStr);
      capturedOutput.writeln(resultStr);
    }

    return D4rtResult.success(
      code: command,
      value: result,
      output: capturedOutput.toString().trim(),
      duration: stopwatch.elapsed,
    );
  }

  /// Runs a D4rt multiline method: $D4{\n(){<code>}}
  Future<D4rtResult> _runMethodMultiline(
      String command, Stopwatch stopwatch) async {
    // Extract method body from $D4{\n(){<code>}}
    // Body starts after \n and includes (){...}
    final body = _getD4Body(command).trim();

    // Wrap in immediate invocation
    final wrappedCode = _wrapAsMethod(body);
    
    // Capture print output using Zone - print directly to stdout for pipe compatibility
    final capturedOutput = StringBuffer();
    final result = await runZoned(
      () async => await _evaluator(wrappedCode, config.context),
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          capturedOutput.writeln(line);
          // Print directly to stdout for pipe compatibility
          stdout.writeln(line);
        },
      ),
    );
    stopwatch.stop();

    // Print result to stdout if not null (for pipe scripts)
    final resultStr = result?.toString() ?? '';
    if (resultStr.isNotEmpty && resultStr != 'null') {
      stdout.writeln(resultStr);
      capturedOutput.writeln(resultStr);
    }

    return D4rtResult.success(
      code: command,
      value: result,
      output: capturedOutput.toString().trim(),
      duration: stopwatch.elapsed,
    );
  }

  /// Wraps code as an immediately-invoked method.
  ///
  /// Rules:
  /// - If user provides a method `(){...}`: wrap as `((){...})()`
  /// - If user provides expression/code without method wrapper:
  ///   - Single-line + doesn't end with `}` or `;`: `((){ return <code>; })()`
  ///   - Otherwise: `((){ <code> })()`
  String _wrapAsMethod(String body) {
    // Check if user provided a method: (){...}
    if (body.startsWith('(){') && body.endsWith('}')) {
      // User provided method - just wrap it
      return '($body)()';
    }

    // User didn't provide method - wrap in method with potential return
    if (!body.contains('\n') && !body.endsWith('}') && !body.endsWith(';')) {
      // Single-line expression without } or ; ending - add return and ;
      return '((){ return $body; })()';
    }

    // Multiline or ends with } or ; - just wrap
    return '((){ $body })()';
  }

  /// Runs a D4rt script file.
  Future<D4rtResult> _runScriptFile(
      String filePath, Stopwatch stopwatch) async {
    final scriptPath = _resolveScriptPath(filePath);
    final file = File(scriptPath);

    if (!file.existsSync()) {
      stopwatch.stop();
      return D4rtResult.failure(
        code: filePath,
        error: 'Script file not found: $scriptPath',
        duration: stopwatch.elapsed,
      );
    }

    // Read and execute the script
    final scriptContent = file.readAsStringSync();

    // Add working directory to context
    final scriptContext = Map<String, dynamic>.from(config.context);
    scriptContext['__scriptPath'] = scriptPath;
    scriptContext['__scriptDir'] = file.parent.path;

    // Capture print output using Zone - print directly to stdout for pipe compatibility
    final capturedOutput = StringBuffer();
    final result = await runZoned(
      () async => await _evaluator(scriptContent, scriptContext),
      zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          capturedOutput.writeln(line);
          // Print directly to stdout for pipe compatibility
          stdout.writeln(line);
        },
      ),
    );
    stopwatch.stop();

    // Print result to stdout if not null (for pipe scripts)
    final resultStr = result?.toString() ?? '';
    if (resultStr.isNotEmpty && resultStr != 'null') {
      stdout.writeln(resultStr);
      capturedOutput.writeln(resultStr);
    }

    return D4rtResult.success(
      code: filePath,
      value: result,
      output: capturedOutput.toString().trim(),
      duration: stopwatch.elapsed,
    );
  }

  /// Runs a reflection call: Class.method() or Class.property
  ///
  /// Supports two formats:
  /// 1. Method call with parentheses: `ClassName.methodName()` or `ClassName.methodName(args)`
  /// 2. Property access without parentheses: `ClassName.propertyName`
  ///
  /// For method calls, arguments are parsed and passed to the method.
  /// Only basic types are supported: bool, int, String, double.
  /// Non-basic types are passed as null.
  Future<D4rtResult> _runReflectionCall(
    String command,
    Stopwatch stopwatch,
  ) async {
    try {
      // Parse the reflection call
      final dotIndex = command.indexOf('.');
      if (dotIndex == -1) {
        stopwatch.stop();
        return D4rtResult.failure(
          code: command,
          error: 'Invalid reflection call format. Expected: ClassName.methodName() or ClassName.property',
          duration: stopwatch.elapsed,
        );
      }

      final className = command.substring(0, dotIndex).trim();
      final remainder = command.substring(dotIndex + 1).trim();

      // Check if this is a method call (has parentheses) or property access
      final parenIndex = remainder.indexOf('(');
      final hasParentheses = parenIndex != -1 && remainder.endsWith(')');

      String memberName;
      String argsStr = '';

      if (hasParentheses) {
        // Method call: methodName(args)
        memberName = remainder.substring(0, parenIndex).trim();
        argsStr = remainder.substring(parenIndex + 1, remainder.length - 1).trim();
      } else {
        // Property access: propertyName
        memberName = remainder;
      }

      // Build D4rt code to call the method/getter
      // The D4rt evaluator handles the actual class resolution
      final String code;
      if (hasParentheses) {
        // Parse arguments and pass them
        final parsedArgs = _parseReflectionArgs(argsStr);
        code = '$className.$memberName($parsedArgs)';
      } else {
        // Property access
        code = '$className.$memberName';
      }

      final result = await _evaluator(code, config.context);
      stopwatch.stop();

      return D4rtResult.success(
        code: command,
        value: result,
        output: result?.toString() ?? '',
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return D4rtResult.failure(
        code: command,
        error: 'Reflection call failed: $e',
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Parses reflection call arguments.
  ///
  /// Handles basic types: bool, int, String, double.
  /// For complex types or unparseable values, passes through as-is.
  String _parseReflectionArgs(String argsStr) {
    if (argsStr.isEmpty) return '';

    // Simple passthrough - the D4rt evaluator handles the arguments
    // This preserves string literals, numbers, booleans, etc.
    return argsStr;
  }

  /// Resolves a script file path according to Section 5.4.2 rules.
  ///
  /// - Without path: `deploy.dart` → `tom_scripts/lib/deploy.dart`
  /// - With path: `utils/deploy.dart` → `tom_scripts/utils/deploy.dart`
  String _resolveScriptPath(String scriptName) {
    if (scriptName.contains('/')) {
      // Has a path component
      return '${config.workspacePath}/tom_scripts/$scriptName';
    }
    // Default: tom_scripts/lib/
    return '${config.scriptsDir}/$scriptName';
  }
}

// =============================================================================
// D4RT EVALUATOR
// =============================================================================

/// Evaluator function for D4rt code.
///
/// Takes D4rt code and a context map, returns the evaluation result.
typedef ActionD4rtEvaluator = Future<dynamic> Function(
  String code,
  Map<String, dynamic> context,
);

/// Creates a D4rt evaluator that uses the real D4rt interpreter.
///
/// The evaluator creates and manages a D4rt instance with all bridges
/// registered. The same instance is reused for all evaluations.
///
/// If [workspace] is provided, the global `tom` context will be initialized,
/// allowing scripts to access `tom.workspace`, `tom.projectInfo`, etc.
///
/// ## Usage
///
/// ```dart
/// final evaluator = createRealD4rtEvaluator(
///   workspace: loadedWorkspace,
///   globalContext: {'custom': 'data'},
/// );
///
/// final result = await evaluator('tom.projectInfo.length', {});
/// ```
ActionD4rtEvaluator createRealD4rtEvaluator({
  Map<String, dynamic>? globalContext,
  BridgeConfiguration? bridgeConfiguration,
  TomWorkspace? workspace,
  WorkspaceContext? workspaceContext,
  TomProject? currentProject,
  String? workspacePath,
}) {
  // Create a single D4rt instance that will be reused
  D4rtInstance? instance;

  return (code, context) async {
    // Create instance on first use (lazy initialization)
    instance ??= D4rtInstance.create(
      bridgeConfiguration: bridgeConfiguration,
      workspace: workspace,
      workspaceContext: workspaceContext,
      currentProject: currentProject,
      workspacePath: workspacePath,
    );

    // Set context variables
    if (globalContext != null) {
      instance!.setContextAll(globalContext);
    }
    instance!.setContextAll(context);

    // Evaluate the code
    return instance!.evaluate(code);
  };
}

/// Creates a D4rt evaluator that uses an existing [ActionD4rtContext].
///
/// This is the recommended approach for action execution to ensure
/// proper instance-per-action isolation.
ActionD4rtEvaluator createEvaluatorFromContext(ActionD4rtContext actionContext) {
  return (code, localContext) async {
    // Add local context to the action context's instance
    actionContext.instance.setContextAll(localContext);
    return actionContext.evaluate(code);
  };
}

// =============================================================================
// EXTENSIONS
// =============================================================================

/// Extension to check if a string is a D4rt command.
extension D4rtCommandExtension on String {
  /// Whether this string is a D4rt command (local or VS Code).
  bool get isD4rtCommand {
    final trimmed = trim();

    // VS Code syntax: $VSCODE{...}
    if (RegExp(r'^\$VSCODE\{', caseSensitive: false).hasMatch(trimmed) &&
        trimmed.endsWith('}')) {
      return true;
    }

    // D4rt syntax: $D4{...}
    if (RegExp(r'^\$D4\{', caseSensitive: false).hasMatch(trimmed) &&
        trimmed.endsWith('}')) {
      return true;
    }

    // Script file: *.dart (for command execution)
    if (trimmed.endsWith('.dart') && !trimmed.contains('(')) {
      return true;
    }

    // Reflection call: Class.method()
    final reflectionPattern =
        RegExp(r'^[A-Z][a-zA-Z0-9]*\.[a-zA-Z0-9]+\(.*\)$');
    if (reflectionPattern.hasMatch(trimmed)) {
      return true;
    }

    return false;
  }

  /// Whether this string is a VS Code bridge command.
  ///
  /// Syntax: `$VSCODE{...}`, `$VSCODE:{port}...`
  bool get isVSCodeCommand {
    final trimmed = trim();
    // Syntax: $VSCODE{...}
    return RegExp(r'^\$VSCODE\{', caseSensitive: false).hasMatch(trimmed) &&
        trimmed.endsWith('}');
  }

  /// Extracts the port from a VS Code command, or null if using default.
  ///
  /// Examples:
  /// - `$VSCODE{expr}` → null (use default port)
  /// - `$VSCODE{:{9743}expr}` → 9743
  int? get vscodeCommandPort {
    final trimmed = trim();
    // Check for port inside content: $VSCODE{:{port}...}
    if (RegExp(r'^\$VSCODE\{', caseSensitive: false).hasMatch(trimmed) &&
        trimmed.endsWith('}')) {
      final start = trimmed.indexOf('{') + 1;
      final content = trimmed.substring(start, trimmed.length - 1);
      // Port syntax: :{port}rest where port is wrapped in braces
      if (content.startsWith(':{')) {
        final endBrace = content.indexOf('}', 2);
        if (endBrace > 2) {
          return int.tryParse(content.substring(2, endBrace));
        }
      }
      return null;
    }
    return null;
  }

  /// Gets the D4 command portion with $VSCODE prefix stripped.
  ///
  /// Extracts content and returns as $D4{...} format.
  String get vscodeCommandBody {
    final trimmed = trim();
    // Syntax: $VSCODE{...}
    if (RegExp(r'^\$VSCODE\{', caseSensitive: false).hasMatch(trimmed) &&
        trimmed.endsWith('}')) {
      final start = trimmed.indexOf('{') + 1;
      var content = trimmed.substring(start, trimmed.length - 1);
      // Strip port if present: :{port}rest → rest
      if (content.startsWith(':{')) {
        final endBrace = content.indexOf('}', 2);
        if (endBrace > 0) {
          content = content.substring(endBrace + 1);
        }
      }
      // Return as unified $D4{...} format
      return '\$D4{$content}';
    }
    return trimmed;
  }

  /// Whether this string is a local D4rt command (not VS Code).
  bool get isLocalD4rtCommand {
    return isD4rtCommand && !isVSCodeCommand;
  }

  /// Whether this string is a VS Code simple command (not placeholder).
  ///
  /// VS Code simple commands use `vscode:` prefix (no `$`) and execute
  /// Dart code via the VS Code VS Code Bridge.
  ///
  /// Formats:
  /// - `vscode: script.dart` - execute script file
  /// - `vscode: "print('hello')"` - execute inline code
  /// - `vscode:9743: script.dart` - with custom port
  bool get isVSCodeSimpleCommand {
    final trimmed = trim();
    // Match vscode: optionally followed by port:
    // But NOT $VSCODE (that's a placeholder)
    return !trimmed.startsWith(r'$') &&
        RegExp(r'^vscode:(\d+:)?\s*', caseSensitive: false).hasMatch(trimmed);
  }

  /// Extracts the port from a VS Code simple command, or null if using default.
  ///
  /// Examples:
  /// - `vscode: script.dart` → null (use default port)
  /// - `vscode:9743: script.dart` → 9743
  int? get vscodeSimpleCommandPort {
    final trimmed = trim();
    final match = RegExp(r'^vscode:(\d+):', caseSensitive: false).firstMatch(trimmed);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return null;
  }

  /// Gets the command body from a VS Code simple command.
  ///
  /// Strips `vscode:` or `vscode:<port>:` prefix and returns the rest.
  ///
  /// Examples:
  /// - `vscode: script.dart` → `script.dart`
  /// - `vscode:9743: "code"` → `"code"`
  String get vscodeSimpleCommandBody {
    final trimmed = trim();
    final match = RegExp(r'^vscode:(\d+:)?\s*', caseSensitive: false).firstMatch(trimmed);
    if (match != null) {
      return trimmed.substring(match.end).trim();
    }
    return trimmed;
  }

  /// Whether this string is a DartScript simple command (local execution).
  ///
  /// DartScript simple commands use `dartscript:` prefix and execute locally.
  /// Unlike `$D4{}` placeholders which are resolved at runtime,
  /// `dartscript:` commands are executed at action execution time.
  ///
  /// Formats:
  /// - `dartscript: script.dart` - execute script file locally
  /// - `dartscript: "print('hello')"` - execute inline code locally
  /// - `dartscript:9743: script.dart` - with custom port (reserved for future)
  bool get isDartscriptSimpleCommand {
    final trimmed = trim();
    // Match dartscript: optionally followed by port:
    // But NOT $D4 (that's a placeholder)
    return !trimmed.startsWith(r'$') &&
        RegExp(r'^dartscript:(\d+:)?\s*', caseSensitive: false).hasMatch(trimmed);
  }

  /// Extracts the port from a DartScript simple command, or null if using default.
  ///
  /// Examples:
  /// - `dartscript: script.dart` → null (use default)
  /// - `dartscript:9743: script.dart` → 9743
  int? get dartscriptSimpleCommandPort {
    final trimmed = trim();
    final match = RegExp(r'^dartscript:(\d+):', caseSensitive: false).firstMatch(trimmed);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return null;
  }

  /// Gets the command body from a DartScript simple command.
  ///
  /// Strips `dartscript:` or `dartscript:<port>:` prefix and returns the rest.
  ///
  /// Examples:
  /// - `dartscript: script.dart` → `script.dart`
  /// - `dartscript:9743: "code"` → `"code"`
  String get dartscriptSimpleCommandBody {
    final trimmed = trim();
    final match = RegExp(r'^dartscript:(\d+:)?\s*', caseSensitive: false).firstMatch(trimmed);
    if (match != null) {
      return trimmed.substring(match.end).trim();
    }
    return trimmed;
  }

  /// Whether this string is a Tom CLI command.
  ///
  /// Tom CLI commands start with `tom:` prefix and invoke Tom CLI directly
  /// without spawning a shell process.
  ///
  /// Example: `tom: build my_project` → executes `tom build my_project`
  bool get isTomCommand {
    final trimmed = trim();
    return trimmed.startsWith('tom:');
  }

  /// Extracts the arguments from a Tom CLI command as a raw string.
  ///
  /// Strips the `tom:` prefix and returns the rest of the command line.
  ///
  /// Example: `tom: build my_project` → `build my_project`
  String get tomCommandArgs {
    final trimmed = trim();
    if (!trimmed.startsWith('tom:')) {
      return trimmed;
    }
    return trimmed.substring(4).trimLeft();
  }

  /// Extracts the arguments from a Tom CLI command as a list.
  ///
  /// Strips the `tom:` prefix and parses the rest using shell-style
  /// argument splitting (handles quoted strings).
  ///
  /// Example: `tom: build "my project"` → `['build', 'my project']`
  List<String> get tomCommandArgsList {
    return splitShellArgs(tomCommandArgs);
  }
}

// =============================================================================
// ARGUMENT PARSING UTILITIES
// =============================================================================

/// Splits a command string into arguments using shell-style parsing.
///
/// Handles:
/// - Single and double quoted strings (content preserved, quotes stripped)
/// - Whitespace as delimiter (spaces, tabs, newlines)
/// - Empty arguments are excluded
///
/// Examples:
/// - `build project` → `['build', 'project']`
/// - `build "my project"` → `['build', 'my project']`
/// - `build 'path with spaces'` → `['build', 'path with spaces']`
List<String> splitShellArgs(String command) {
  final args = <String>[];
  final buffer = StringBuffer();
  var inQuote = false;
  String? quoteChar;

  for (var i = 0; i < command.length; i++) {
    final char = command[i];

    if (inQuote) {
      if (char == quoteChar) {
        inQuote = false;
        args.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    } else if (char == '"' || char == "'") {
      inQuote = true;
      quoteChar = char;
    } else if (char == ' ' || char == '\t' || char == '\n') {
      if (buffer.isNotEmpty) {
        args.add(buffer.toString());
        buffer.clear();
      }
    } else {
      buffer.write(char);
    }
  }

  if (buffer.isNotEmpty) {
    args.add(buffer.toString());
  }

  return args;
}
