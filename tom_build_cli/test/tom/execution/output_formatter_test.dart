// Tests for OutputFormatter - CLI output formatting
//
// Covers tom_tool_specification.md Section 9.2:
// - Error format: Error: <desc>, File: [...], Resolution: ...
// - Progress indicators for long operations
// - Verbose mode with detailed output
// - Color output when terminal supports it
// - Summary of completed actions

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/execution/output_formatter.dart';
import 'package:tom_build_cli/src/tom/execution/action_executor.dart';
import 'package:tom_build_cli/src/tom/execution/command_runner.dart';
import 'package:tom_build_cli/src/tom/cli/internal_commands.dart';

void main() {
  group('OutputFormatter', () {
    // =========================================================================
    // AnsiColors
    // =========================================================================
    group('AnsiColors', () {
      test('reset code is defined', () {
        expect(AnsiColors.reset, equals('\x1B[0m'));
      });

      test('foreground colors are defined', () {
        expect(AnsiColors.red, equals('\x1B[31m'));
        expect(AnsiColors.green, equals('\x1B[32m'));
        expect(AnsiColors.yellow, equals('\x1B[33m'));
        expect(AnsiColors.cyan, equals('\x1B[36m'));
      });

      test('styles are defined', () {
        expect(AnsiColors.bold, equals('\x1B[1m'));
        expect(AnsiColors.dim, equals('\x1B[2m'));
      });
    });

    // =========================================================================
    // OutputFormatterConfig
    // =========================================================================
    group('OutputFormatterConfig', () {
      test('creates config with default values', () {
        const config = OutputFormatterConfig();

        expect(config.useColors, isTrue);
        expect(config.verbose, isFalse);
        expect(config.showProgress, isTrue);
        expect(config.showTimings, isTrue);
        expect(config.maxWidth, equals(80));
      });

      test('copyWith creates modified copy', () {
        const original = OutputFormatterConfig(
          useColors: true,
          verbose: false,
        );

        final modified = original.copyWith(verbose: true);

        expect(modified.useColors, isTrue);
        expect(modified.verbose, isTrue);
      });

      test('copyWith preserves unspecified values', () {
        const original = OutputFormatterConfig(
          useColors: false,
          verbose: true,
          showProgress: false,
        );

        final modified = original.copyWith(maxWidth: 120);

        expect(modified.useColors, isFalse);
        expect(modified.verbose, isTrue);
        expect(modified.showProgress, isFalse);
        expect(modified.maxWidth, equals(120));
      });
    });

    // =========================================================================
    // ErrorMessage - Section 9.2 Format
    // =========================================================================
    group('ErrorMessage (Section 9.2)', () {
      test('formats basic error without colors', () {
        const error = ErrorMessage(
          description: 'Something went wrong',
        );

        final formatted = error.format();

        expect(formatted, contains('Error:'));
        expect(formatted, contains('Something went wrong'));
      });

      test('formats error with file path', () {
        const error = ErrorMessage(
          description: 'Invalid syntax',
          filePath: '/path/to/file.yaml',
        );

        final formatted = error.format();

        expect(formatted, contains('Error:'));
        expect(formatted, contains('Invalid syntax'));
        expect(formatted, contains('File:'));
        expect(formatted, contains('[/path/to/file.yaml]'));
      });

      test('formats error with line number', () {
        const error = ErrorMessage(
          description: 'Parse error',
          filePath: '/path/to/file.yaml',
          lineNumber: 42,
        );

        final formatted = error.format();

        expect(formatted, contains('Line:'));
        expect(formatted, contains('[42]'));
      });

      test('formats error with resolution', () {
        const error = ErrorMessage(
          description: 'Missing required field',
          resolution: 'Add the required field to your config',
        );

        final formatted = error.format();

        expect(formatted, contains('Resolution:'));
        expect(formatted, contains('Add the required field'));
      });

      test('formats error with context', () {
        const error = ErrorMessage(
          description: 'Invalid YAML',
          context: '"invalid: yaml: content"',
        );

        final formatted = error.format();

        expect(formatted, contains('Context:'));
        expect(formatted, contains('"invalid: yaml: content"'));
      });

      test('formats complete error per Section 9.2', () {
        const error = ErrorMessage(
          description: 'Action [build] requires [default:] definition',
          filePath: '~/tom_workspace.yaml',
          resolution: 'Add a default: block inside actions.build:',
        );

        final formatted = error.format();

        expect(formatted, contains('Error: Action [build] requires'));
        expect(formatted, contains('File: [~/tom_workspace.yaml]'));
        expect(formatted, contains('Resolution: Add a default: block'));
      });

      test('formats error with colors when enabled', () {
        const error = ErrorMessage(
          description: 'Test error',
        );

        final formatted = error.format(useColors: true);

        expect(formatted, contains('\x1B[')); // Contains ANSI codes
      });
    });

    // =========================================================================
    // OutputFormatter Error Methods
    // =========================================================================
    group('OutputFormatter Error Methods', () {
      test('printCircularDependencyError formats per Section 9.3', () {
        final buffer = StringBuffer();
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
          errorOutput: buffer,
        );

        formatter.printCircularDependencyError([
          'project_a',
          'project_b',
          'project_c',
          'project_a',
        ]);

        final output = buffer.toString();
        expect(output, contains('Circular dependency detected'));
        expect(output, contains('project_a → project_b → project_c → project_a'));
        expect(output, contains('Remove one dependency to break the cycle'));
      });

      test('printPlaceholderRecursionError formats per Section 9.4', () {
        final buffer = StringBuffer();
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
          errorOutput: buffer,
        );

        formatter.printPlaceholderRecursionError(
          filePath: 'tom_uam_server/pubspec.yaml.tomplate',
          unresolved: ['\${a}', '\${b}'],
        );

        final output = buffer.toString();
        expect(output, contains('Placeholder recursion exceeded 10 levels'));
        expect(output, contains('tom_uam_server/pubspec.yaml.tomplate'));
        expect(output, contains('Unresolved:'));
        expect(output, contains('\${a}, \${b}'));
      });

      test('printScopeConflictError formats per Section 9.6', () {
        final buffer = StringBuffer();
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
          errorOutput: buffer,
        );

        formatter.printScopeConflictError('tom :groups uam :projects tom_build :build');

        final output = buffer.toString();
        expect(output, contains('Cannot use both [:projects] and [:groups]'));
        expect(output, contains('Command:'));
        expect(output, contains('tom :groups uam :projects tom_build :build'));
      });
    });

    // =========================================================================
    // OutputFormatter Info/Success Methods
    // =========================================================================
    group('OutputFormatter Info/Success Methods', () {
      test('printSuccess formats message', () {
        final buffer = StringBuffer();
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
          output: buffer,
        );

        formatter.printSuccess('Task completed');

        expect(buffer.toString(), contains('✓'));
        expect(buffer.toString(), contains('Task completed'));
      });

      test('printInfo formats message', () {
        final buffer = StringBuffer();
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
          output: buffer,
        );

        formatter.printInfo('Information message');

        expect(buffer.toString(), contains('ℹ'));
        expect(buffer.toString(), contains('Information message'));
      });

      test('printWarning formats message', () {
        final buffer = StringBuffer();
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
          output: buffer,
        );

        formatter.printWarning('Warning message');

        expect(buffer.toString(), contains('⚠'));
        expect(buffer.toString(), contains('Warning message'));
      });

      test('printVerbose only prints when verbose enabled', () {
        final buffer = StringBuffer();
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, verbose: false),
          output: buffer,
        );

        formatter.printVerbose('Verbose message');

        expect(buffer.toString(), isEmpty);
      });

      test('printVerbose prints when verbose enabled', () {
        final buffer = StringBuffer();
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, verbose: true),
          output: buffer,
        );

        formatter.printVerbose('Verbose message');

        expect(buffer.toString(), contains('Verbose message'));
      });
    });

    // =========================================================================
    // Result Formatting
    // =========================================================================
    group('Result Formatting', () {
      test('formatCommandResult shows success', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, showTimings: true),
        );

        final result = CommandResult.success(
          command: 'dart analyze',
          stdout: 'No issues found',
          duration: const Duration(seconds: 2, milliseconds: 500),
        );

        final formatted = formatter.formatCommandResult(result);

        expect(formatted, contains('✓'));
        expect(formatted, contains('dart analyze'));
        expect(formatted, contains('2.5s'));
      });

      test('formatCommandResult shows failure', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, showTimings: false),
        );

        final result = CommandResult.failure(
          command: 'dart compile',
          exitCode: 1,
          stderr: 'Compilation failed',
        );

        final formatted = formatter.formatCommandResult(result);

        expect(formatted, contains('✗'));
        expect(formatted, contains('dart compile'));
      });

      test('formatActionResult shows success', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, showTimings: true),
        );

        final result = ActionExecutionResult.success(
          projectName: 'tom_core',
          actionName: 'build',
          commandResults: [],
          duration: const Duration(seconds: 5),
        );

        final formatted = formatter.formatActionResult(result);

        expect(formatted, contains('✓'));
        expect(formatted, contains('build'));
        expect(formatted, contains('tom_core'));
        expect(formatted, contains('5.0s'));
      });

      test('formatActionResult shows failure with error', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, showTimings: false),
        );

        final result = ActionExecutionResult.failure(
          projectName: 'tom_core',
          actionName: 'build',
          error: 'Compilation failed',
          duration: Duration.zero,
        );

        final formatted = formatter.formatActionResult(result);

        expect(formatted, contains('✗'));
        expect(formatted, contains('build'));
        expect(formatted, contains('Error:'));
        expect(formatted, contains('Compilation failed'));
      });

      test('formatInternalCommandResult shows success', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, showTimings: true),
        );

        final result = InternalCommandResult.success(
          command: 'analyze',
          message: 'Analysis complete',
          duration: const Duration(milliseconds: 500),
        );

        final formatted = formatter.formatInternalCommandResult(result);

        expect(formatted, contains('✓'));
        expect(formatted, contains(':analyze'));
        expect(formatted, contains('500ms'));
      });
    });

    // =========================================================================
    // Summary Formatting
    // =========================================================================
    group('Summary Formatting', () {
      test('formatSummary shows action results', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
        );

        final actionResults = [
          ActionExecutionResult.success(
            projectName: 'p1',
            actionName: 'build',
            commandResults: [],
            duration: Duration.zero,
          ),
          ActionExecutionResult.success(
            projectName: 'p2',
            actionName: 'build',
            commandResults: [],
            duration: Duration.zero,
          ),
          ActionExecutionResult.failure(
            projectName: 'p3',
            actionName: 'build',
            error: 'Failed',
            duration: Duration.zero,
          ),
        ];

        final formatted = formatter.formatSummary(
          actionResults: actionResults,
          commandResults: [],
          totalDuration: const Duration(seconds: 10),
        );

        expect(formatted, contains('Summary'));
        expect(formatted, contains('Actions:'));
        expect(formatted, contains('2 passed'));
        expect(formatted, contains('1 failed'));
        expect(formatted, contains('Duration:'));
      });

      test('formatSummary shows command results', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
        );

        final commandResults = [
          InternalCommandResult.success(
            command: 'analyze',
            duration: Duration.zero,
          ),
          InternalCommandResult.failure(
            command: 'version-bump',
            error: 'Failed',
            duration: Duration.zero,
          ),
        ];

        final formatted = formatter.formatSummary(
          actionResults: [],
          commandResults: commandResults,
          totalDuration: const Duration(seconds: 5),
        );

        expect(formatted, contains('Commands:'));
        expect(formatted, contains('1 passed'));
        expect(formatted, contains('1 failed'));
      });
    });

    // =========================================================================
    // Help Formatting
    // =========================================================================
    group('Help Formatting', () {
      test('formatHelp shows all sections', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false),
        );

        final formatted = formatter.formatHelp(
          toolName: 'Tom CLI',
          version: '1.0.0',
          description: 'A workspace build tool',
          usage: ['tom [options] <action>', 'tom :projects <names> <action>'],
          commands: {':analyze': 'Analyze workspace', ':build': 'Build projects'},
          options: {'-verbose': 'Show verbose output', '-dry-run': 'Dry run mode'},
        );

        expect(formatted, contains('Tom CLI'));
        expect(formatted, contains('v1.0.0'));
        expect(formatted, contains('A workspace build tool'));
        expect(formatted, contains('Usage:'));
        expect(formatted, contains('tom [options] <action>'));
        expect(formatted, contains('Commands:'));
        expect(formatted, contains(':analyze'));
        expect(formatted, contains('Options:'));
        expect(formatted, contains('-verbose'));
      });
    });

    // =========================================================================
    // Duration Formatting
    // =========================================================================
    group('Duration Formatting', () {
      test('formats milliseconds', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, showTimings: true),
        );

        final result = CommandResult.success(
          command: 'test',
          stdout: '',
          duration: const Duration(milliseconds: 250),
        );

        final formatted = formatter.formatCommandResult(result);
        expect(formatted, contains('250ms'));
      });

      test('formats seconds', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, showTimings: true),
        );

        final result = CommandResult.success(
          command: 'test',
          stdout: '',
          duration: const Duration(seconds: 3, milliseconds: 500),
        );

        final formatted = formatter.formatCommandResult(result);
        expect(formatted, contains('3.5s'));
      });

      test('formats minutes', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, showTimings: true),
        );

        final result = CommandResult.success(
          command: 'test',
          stdout: '',
          duration: const Duration(minutes: 2, seconds: 30),
        );

        final formatted = formatter.formatCommandResult(result);
        expect(formatted, contains('2m 30s'));
      });

      test('formats hours', () {
        final formatter = OutputFormatter(
          config: const OutputFormatterConfig(useColors: false, showTimings: true),
        );

        final result = CommandResult.success(
          command: 'test',
          stdout: '',
          duration: const Duration(hours: 1, minutes: 15, seconds: 30),
        );

        final formatted = formatter.formatCommandResult(result);
        expect(formatted, contains('1h 15m 30s'));
      });
    });

    // =========================================================================
    // Progress Indicator
    // =========================================================================
    group('ProgressIndicator', () {
      test('creates with message and total', () {
        final progress = ProgressIndicator(
          message: 'Processing',
          total: 10,
        );

        expect(progress.message, equals('Processing'));
        expect(progress.total, equals(10));
      });

      test('increment updates internal counter', () {
        final progress = ProgressIndicator(
          message: 'Processing',
          total: 10,
        );

        // We cannot easily test stdout output, but we verify no exceptions
        expect(() => progress.increment(itemName: 'item1'), returnsNormally);
        expect(() => progress.increment(itemName: 'item2'), returnsNormally);
      });

      test('complete marks as done', () {
        final progress = ProgressIndicator(
          message: 'Processing',
          total: 10,
        );

        expect(() => progress.complete(summary: 'Done!'), returnsNormally);
      });
    });
  });
}
