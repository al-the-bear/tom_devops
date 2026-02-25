// Tests for D4rtRunner - D4rt expression and script execution
//
// Covers tom_tool_specification.md Section 5.4.2 Command Types:
// - D4rt expression: {expr}
// - D4rt method: (){...}
// - Script file: file.dart
// - Reflection call: Class.method()
// - Script path resolution

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/execution/d4rt_runner.dart';

void main() {
  group('D4rtRunner', () {
    late Directory tempDir;
    late String workspacePath;
    late D4rtRunnerConfig config;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('d4rt_runner_test_');
      workspacePath = tempDir.path;
      config = D4rtRunnerConfig(workspacePath: workspacePath);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    // =========================================================================
    // Section 5.4.2 - D4rtResult
    // =========================================================================
    group('Section 5.4.2 - D4rtResult', () {
      test('success factory creates correct result', () {
        final result = D4rtResult.success(
          code: '{1 + 1}',
          value: 2,
          output: '2',
          duration: const Duration(milliseconds: 100),
        );

        expect(result.success, isTrue);
        expect(result.code, equals('{1 + 1}'));
        expect(result.value, equals(2));
        expect(result.output, equals('2'));
        expect(result.error, isNull);
        expect(result.duration, equals(const Duration(milliseconds: 100)));
      });

      test('failure factory creates correct result', () {
        final result = D4rtResult.failure(
          code: '{invalid}',
          error: 'Syntax error',
          output: '',
          duration: const Duration(milliseconds: 50),
        );

        expect(result.success, isFalse);
        expect(result.code, equals('{invalid}'));
        expect(result.error, equals('Syntax error'));
        expect(result.value, isNull);
        expect(result.duration, equals(const Duration(milliseconds: 50)));
      });
    });

    // =========================================================================
    // Section 5.4.2 - D4rtRunnerConfig
    // =========================================================================
    group('Section 5.4.2 - D4rtRunnerConfig', () {
      test('creates config with required parameters', () {
        final cfg = D4rtRunnerConfig(workspacePath: '/path/to/ws');

        expect(cfg.workspacePath, equals('/path/to/ws'));
        expect(cfg.scriptsPath, isNull);
        expect(cfg.verbose, isFalse);
        expect(cfg.context, isEmpty);
      });

      test('uses default scripts path', () {
        final cfg = D4rtRunnerConfig(workspacePath: '/path/to/ws');

        expect(cfg.scriptsDir, equals('/path/to/ws/tom_scripts/lib'));
      });

      test('uses custom scripts path when provided', () {
        final cfg = D4rtRunnerConfig(
          workspacePath: '/path/to/ws',
          scriptsPath: '/custom/scripts',
        );

        expect(cfg.scriptsDir, equals('/custom/scripts'));
      });

      test('accepts all optional parameters', () {
        final cfg = D4rtRunnerConfig(
          workspacePath: '/path/to/ws',
          scriptsPath: '/custom/scripts',
          verbose: true,
          context: {'key': 'value'},
        );

        expect(cfg.verbose, isTrue);
        expect(cfg.context, equals({'key': 'value'}));
      });
    });

    // =========================================================================
    // Section 5.4.2 - Command Type Detection
    // =========================================================================
    group('Section 5.4.2 - Command Type Detection', () {
      late D4rtRunner runner;

      setUp(() {
        runner = D4rtRunner(config: config);
      });

      test('detects D4rt expression: \$D4{expr}', () {
        expect(runner.getCommandType(r'$D4{1 + 1}'), D4rtCommandType.expression);
        expect(runner.getCommandType(r'$D4{buildProject()}'), D4rtCommandType.expression);
        expect(runner.getCommandType(r'$D4{calculateSum(a, b)}'), D4rtCommandType.expression);
      });

      test('detects D4rt multiline method: \$D4{\\n(){<code>}}', () {
        expect(runner.getCommandType(r'$D4{' '\n(){return 1;}}'), D4rtCommandType.methodMultiline);
        expect(runner.getCommandType(r'$D4{' '\n(){print("hello");}}'), D4rtCommandType.methodMultiline);
      });

      test('detects D4rt multiline script: \$D4{\\n<code>}', () {
        expect(runner.getCommandType(r'$D4{' '\nprint("hello");}'), D4rtCommandType.scriptMultiline);
        expect(runner.getCommandType(r'$D4{' '\nimport "dart:io";\nmain(){}}'), D4rtCommandType.scriptMultiline);
      });

      test('detects D4rt script file: \$D4{file.dart}', () {
        expect(runner.getCommandType(r'$D4{deploy.dart}'), D4rtCommandType.scriptFileInline);
        expect(runner.getCommandType(r'$D4{scripts/setup.dart}'), D4rtCommandType.scriptFileInline);
      });

      test('detects script file: file.dart', () {
        expect(runner.getCommandType('deploy.dart'), D4rtCommandType.scriptFileInline);
        expect(runner.getCommandType('utils/deploy.dart'), D4rtCommandType.scriptFileInline);
        expect(runner.getCommandType('build_scripts/setup.dart'), D4rtCommandType.scriptFileInline);
      });

      test('detects reflection call: Class.method()', () {
        expect(runner.getCommandType('BuildTool.generate()'), D4rtCommandType.reflectionCall);
        expect(runner.getCommandType('Analyzer.run()'), D4rtCommandType.reflectionCall);
        expect(runner.getCommandType('Config.load("file.yaml")'), D4rtCommandType.reflectionCall);
      });

      test('detects shell command (not D4rt)', () {
        expect(runner.getCommandType('dart analyze'), D4rtCommandType.shell);
        expect(runner.getCommandType('flutter build'), D4rtCommandType.shell);
        expect(runner.getCommandType('echo hello'), D4rtCommandType.shell);
      });

      test('does not confuse {{expr}} or {expr} with \$D4{expr}', () {
        // {{expr}} is a generator placeholder, not a D4rt expression
        expect(runner.getCommandType('{{projects.*.name;,}}'), D4rtCommandType.shell);
        // {expr} without $D4 prefix is shell (undocumented simple syntax removed)
        expect(runner.getCommandType('{1 + 1}'), D4rtCommandType.shell);
        expect(runner.getCommandType('(){return 1;}'), D4rtCommandType.shell);
      });

      test('isD4rtCommand returns true for D4rt commands', () {
        expect(runner.isD4rtCommand(r'$D4{expr}'), isTrue);
        expect(runner.isD4rtCommand(r'$D4{' '\n(){return 1;}}'), isTrue);
        expect(runner.isD4rtCommand('script.dart'), isTrue);
        expect(runner.isD4rtCommand('Class.method()'), isTrue);
      });

      test('isD4rtCommand returns false for shell commands', () {
        expect(runner.isD4rtCommand('dart analyze'), isFalse);
        expect(runner.isD4rtCommand('echo hello'), isFalse);
      });

      // VS Code command type detection
      test('detects VS Code expression: \$VSCODE{expr}', () {
        expect(
          runner.getCommandType(r'$VSCODE{expr}'),
          D4rtCommandType.vscodeExpression,
        );
        expect(
          runner.getCommandType(r'$VSCODE{VSCode.showMessage("Hi")}'),
          D4rtCommandType.vscodeExpression,
        );
      });

      test('detects VS Code script file: \$VSCODE{file.dart}', () {
        expect(
          runner.getCommandType(r'$VSCODE{deploy.dart}'),
          D4rtCommandType.vscodeScriptFile,
        );
        expect(
          runner.getCommandType(r'$VSCODE{scripts/setup.dart}'),
          D4rtCommandType.vscodeScriptFile,
        );
      });

      test('isVSCodeCommand returns true for VS Code commands', () {
        expect(runner.isVSCodeCommand(r'$VSCODE{expr}'), isTrue);
        expect(runner.isVSCodeCommand(r'$VSCODE{file.dart}'), isTrue);
        expect(runner.isVSCodeCommand(r'$VSCODE{' '\ncode}'), isTrue);
      });

      test('isVSCodeCommand returns true for VS Code commands with port', () {
        expect(runner.isVSCodeCommand(r'$VSCODE{:{9743}expr}'), isTrue);
        expect(runner.isVSCodeCommand(r'$VSCODE{:{8080}file.dart}'), isTrue);
      });

      test('detects VS Code commands with custom port', () {
        expect(
          runner.getCommandType(r'$VSCODE{:{9743}expr}'),
          D4rtCommandType.vscodeExpression,
        );
        expect(
          runner.getCommandType(r'$VSCODE{:{8080}deploy.dart}'),
          D4rtCommandType.vscodeScriptFile,
        );
      });

      test('isVSCodeCommand returns false for local D4rt commands', () {
        expect(runner.isVSCodeCommand(r'$D4{expr}'), isFalse);
        expect(runner.isVSCodeCommand('script.dart'), isFalse);
        expect(runner.isVSCodeCommand('Class.method()'), isFalse);
      });

      test('isLocalD4rtCommand returns true for local D4rt only', () {
        expect(runner.isLocalD4rtCommand(r'$D4{expr}'), isTrue);
        expect(runner.isLocalD4rtCommand('script.dart'), isTrue);
        expect(runner.isLocalD4rtCommand(r'$VSCODE{expr}'), isFalse);
      });
    });

    // =========================================================================
    // Section 5.4.2 - D4rt Expression Execution
    // =========================================================================
    group('Section 5.4.2 - D4rt Expression Execution', () {
      test('runs D4rt expression with default evaluator', () async {
        final runner = D4rtRunner(config: config);

        final result = await runner.run(r'$D4{1 + 1}');

        expect(result.success, isTrue);
        expect(result.code, equals(r'$D4{1 + 1}'));
        // Default evaluator now uses real D4rt interpreter
        expect(result.output, equals('2'));
        expect(result.value, equals(2));
      });

      test('runs D4rt expression with custom evaluator', () async {
        final runner = D4rtRunner(
          config: config,
          evaluator: (code, context) async => 42,
        );

        final result = await runner.run(r'$D4{getAnswer()}');

        expect(result.success, isTrue);
        expect(result.value, equals(42));
        expect(result.output, equals('42'));
      });

      test('evaluator receives context', () async {
        Map<String, dynamic>? receivedContext;

        final runner = D4rtRunner(
          config: D4rtRunnerConfig(
            workspacePath: workspacePath,
            context: {'key': 'value'},
          ),
          evaluator: (code, context) async {
            receivedContext = context;
            return 'ok';
          },
        );

        await runner.run(r'$D4{expr}');

        expect(receivedContext, isNotNull);
        expect(receivedContext!['key'], equals('value'));
      });
    });

    // =========================================================================
    // Section 5.4.2 - D4rt Method Execution
    // =========================================================================
    group('Section 5.4.2 - D4rt Method Execution', () {
      test('runs D4rt method with custom evaluator', () async {
        String? receivedCode;

        final runner = D4rtRunner(
          config: config,
          evaluator: (code, context) async {
            receivedCode = code;
            return 'result';
          },
        );

        // Use documented $D4{\n(){<code>}} syntax
        final result = await runner.run(r'$D4{' '\n(){return 1;}}');

        expect(result.success, isTrue);
        // Method body should be wrapped in a function call
        expect(receivedCode, contains('return 1;'));
      });
    });

    // =========================================================================
    // Section 5.4.2 - Script File Execution
    // =========================================================================
    group('Section 5.4.2 - Script File Execution', () {
      test('fails when script file not found', () async {
        final runner = D4rtRunner(config: config);

        final result = await runner.run('nonexistent.dart');

        expect(result.success, isFalse);
        expect(result.error, contains('not found'));
      });

      test('resolves script without path to tom_scripts/lib/', () async {
        // Create the scripts directory and file
        final scriptsDir = Directory('$workspacePath/tom_scripts/lib');
        scriptsDir.createSync(recursive: true);
        File('${scriptsDir.path}/deploy.dart').writeAsStringSync('// script');

        String? receivedCode;
        final runner = D4rtRunner(
          config: config,
          evaluator: (code, context) async {
            receivedCode = code;
            return 'done';
          },
        );

        final result = await runner.run('deploy.dart');

        expect(result.success, isTrue);
        expect(receivedCode, contains('// script'));
      });

      test('resolves script with path to tom_scripts/', () async {
        // Create the scripts directory and file
        final scriptsDir = Directory('$workspacePath/tom_scripts/utils');
        scriptsDir.createSync(recursive: true);
        File('${scriptsDir.path}/helper.dart').writeAsStringSync('// helper');

        String? receivedCode;
        final runner = D4rtRunner(
          config: config,
          evaluator: (code, context) async {
            receivedCode = code;
            return 'done';
          },
        );

        final result = await runner.run('utils/helper.dart');

        expect(result.success, isTrue);
        expect(receivedCode, contains('// helper'));
      });

      test('adds script path and directory to context', () async {
        final scriptsDir = Directory('$workspacePath/tom_scripts/lib');
        scriptsDir.createSync(recursive: true);
        File('${scriptsDir.path}/test.dart').writeAsStringSync('// test');

        Map<String, dynamic>? receivedContext;
        final runner = D4rtRunner(
          config: config,
          evaluator: (code, context) async {
            receivedContext = context;
            return 'done';
          },
        );

        await runner.run('test.dart');

        expect(receivedContext, isNotNull);
        expect(receivedContext!['__scriptPath'], contains('test.dart'));
        expect(receivedContext!['__scriptDir'], contains('tom_scripts/lib'));
      });
    });

    // =========================================================================
    // Section 5.4.2 - Reflection Call Execution
    // =========================================================================
    group('Section 5.4.2 - Reflection Call Execution', () {
      test('parses reflection call correctly', () async {
        String? receivedCode;

        final runner = D4rtRunner(
          config: config,
          evaluator: (code, context) async {
            receivedCode = code;
            return 'result';
          },
        );

        await runner.run('BuildTool.generate()');

        expect(receivedCode, isNotNull);
        expect(receivedCode, contains('BuildTool'));
        expect(receivedCode, contains('generate'));
      });

      test('handles reflection call with arguments', () async {
        String? receivedCode;

        final runner = D4rtRunner(
          config: config,
          evaluator: (code, context) async {
            receivedCode = code;
            return 'result';
          },
        );

        await runner.run('Config.load("file.yaml")');

        expect(receivedCode, isNotNull);
        expect(receivedCode, contains('"file.yaml"'));
      });
    });

    // =========================================================================
    // Error Handling
    // =========================================================================
    group('Error Handling', () {
      test('handles evaluator exceptions gracefully', () async {
        final runner = D4rtRunner(
          config: config,
          evaluator: (code, context) async {
            throw Exception('Evaluation failed');
          },
        );

        final result = await runner.run(r'$D4{expr}');

        expect(result.success, isFalse);
        expect(result.error, contains('Evaluation failed'));
      });

      test('returns failure for shell commands', () async {
        final runner = D4rtRunner(config: config);

        final result = await runner.run('dart analyze');

        expect(result.success, isFalse);
        expect(result.error, contains('Not a D4rt command'));
      });

      test('tracks execution duration', () async {
        final runner = D4rtRunner(
          config: config,
          evaluator: (code, context) async {
            await Future.delayed(const Duration(milliseconds: 50));
            return 'done';
          },
        );

        final result = await runner.run(r'$D4{expr}');

        expect(result.duration.inMilliseconds, greaterThanOrEqualTo(40));
      });
    });

    // =========================================================================
    // D4rtCommandExtension
    // =========================================================================
    group('D4rtCommandExtension', () {
      test('isD4rtCommand extension works correctly', () {
        expect(r'$D4{expr}'.isD4rtCommand, isTrue);
        expect((r'$D4{' '\n(){code}}').isD4rtCommand, isTrue);
        expect('script.dart'.isD4rtCommand, isTrue);
        expect('Class.method()'.isD4rtCommand, isTrue);
        expect('dart analyze'.isD4rtCommand, isFalse);
        expect('echo hello'.isD4rtCommand, isFalse);
      });

      test('isVSCodeCommand extension works for default port', () {
        expect(r'$VSCODE{expr}'.isVSCodeCommand, isTrue);
        expect(r'$VSCODE{file.dart}'.isVSCodeCommand, isTrue);
        expect(r'$VSCODE{' '\ncode}'.isVSCodeCommand, isTrue);
      });

      test('isVSCodeCommand extension works for custom port', () {
        expect(r'$VSCODE{:{9743}expr}'.isVSCodeCommand, isTrue);
        expect(r'$VSCODE{:{8080}file.dart}'.isVSCodeCommand, isTrue);
      });

      test('vscodeCommandPort returns null for default port', () {
        expect(r'$VSCODE{expr}'.vscodeCommandPort, isNull);
        expect(r'$VSCODE{file.dart}'.vscodeCommandPort, isNull);
      });

      test('vscodeCommandPort extracts custom port', () {
        expect(r'$VSCODE{:{9743}expr}'.vscodeCommandPort, equals(9743));
        expect(r'$VSCODE{:{8080}file.dart}'.vscodeCommandPort, equals(8080));
      });

      test('vscodeCommandBody strips VSCODE prefix correctly', () {
        // Default port (expression)
        expect(r'$VSCODE{expr}'.vscodeCommandBody, equals(r'$D4{expr}'));
        // Script file (detected by .dart suffix)
        expect(
          r'$VSCODE{file.dart}'.vscodeCommandBody,
          equals(r'$D4{file.dart}'),
        );
        // Custom port
        expect(r'$VSCODE{:{9743}expr}'.vscodeCommandBody, equals(r'$D4{expr}'));
        expect(
          r'$VSCODE{:{8080}file.dart}'.vscodeCommandBody,
          equals(r'$D4{file.dart}'),
        );
      });

      test('isLocalD4rtCommand excludes VS Code commands', () {
        expect(r'$D4{expr}'.isLocalD4rtCommand, isTrue);
        expect('script.dart'.isLocalD4rtCommand, isTrue);
        expect(r'$VSCODE{expr}'.isLocalD4rtCommand, isFalse);
        expect(r'$VSCODE{:{9743}expr}'.isLocalD4rtCommand, isFalse);
      });
    });

    // =========================================================================
    // createRealD4rtEvaluator Factory
    // =========================================================================
    group('createRealD4rtEvaluator Factory', () {
      test('creates evaluator with global context', () async {
        final evaluator = createRealD4rtEvaluator(
          globalContext: {'global': 'value'},
        );

        // The real evaluator now uses D4rt, so this will execute code
        // Simple expressions should work
        final result = await evaluator('1 + 1', {});

        // Should return 2 (actual D4rt execution)
        expect(result, equals(2));
      });
    });
  });
}
