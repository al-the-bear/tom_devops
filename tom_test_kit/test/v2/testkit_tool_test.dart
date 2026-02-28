/// Unit tests for testkit tool definition.
///
/// Tests that the CLI tool definition is correctly structured,
/// and that gated built-in commands are not statically registered.
@TestOn('vm')
library;

import 'package:test/test.dart';
import 'package:tom_test_kit/src/v2/testkit_tool.dart';

void main() {
  group('TK-CLI-1: Tool Definition [2026-01-01]', () {
    test('TK-CLI-1: Tool has correct name and mode', () {
      expect(testkitTool.name, 'testkit');
      expect(testkitTool.version, isNotEmpty);
    });

    test('TK-CLI-2: Tool has expected commands', () {
      final commandNames = testkitTool.commands.map((c) => c.name).toSet();
      // Core tracking commands
      expect(commandNames, contains('baseline'));
      expect(commandNames, contains('test'));
    });
  });

  group('TK-CLI-2: Feature Gating [2026-01-01]', () {
    test('TK-CLI-NEG01: Tool definition does not register macro/define '
        'commands in static commands list', () {
      // :macro, :macros, :unmacro, :define, :defines, :undefine are built-in
      // commands handled exclusively by ToolRunner built-ins and gated behind
      // eligibility checks. They must NOT appear in the static tool definition
      // commands list for any tool that doesn't use pipeline/define features.
      final commandNames = testkitTool.commands.map((c) => c.name).toSet();

      for (final gatedCmd in [
        'macro',
        'macros',
        'unmacro',
        'define',
        'defines',
        'undefine',
      ]) {
        expect(
          commandNames,
          isNot(contains(gatedCmd)),
          reason:
              ':$gatedCmd should not be in the static commands list — '
              'it is a ToolRunner built-in gated by eligibility',
        );
      }
    });
  });
}
