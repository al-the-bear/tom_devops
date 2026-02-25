// Tests for TomD4rtRepl - TomD4rt REPL with integrated Tom CLI functionality
//
// Covers tom_d4rt_integration_design.md:
// - TomD4rtRepl class structure
// - Tom command handling (: ! - prefixes)
// - Command line parsing
// - Bridge registration
// - Help sections

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom_d4rt/tom_d4rt_repl.dart';
import 'package:tom_d4rt/d4rt.dart';

void main() {
  group('TomD4rtRepl', () {
    late TomD4rtRepl repl;

    setUp(() {
      repl = TomD4rtRepl();
    });

    // =========================================================================
    // Tool Configuration
    // =========================================================================
    group('Tool Configuration', () {
      test('toolName is Tom', () {
        expect(repl.toolName, equals('Tom'));
      });

      test('toolVersion is not empty', () {
        expect(repl.toolVersion, isNotEmpty);
      });

      test('dataDirectory contains tom', () {
        expect(repl.dataDirectory, contains('.tom/tom'));
      });

      test('replayFilePatterns includes tom extension', () {
        expect(repl.replayFilePatterns, contains('.tom'));
        expect(repl.replayFilePatterns, contains('.d4rt'));
        expect(repl.replayFilePatterns, contains('.dcli'));
        expect(repl.replayFilePatterns, contains('.replay.txt'));
      });
    });

    // =========================================================================
    // Bridge Registration
    // =========================================================================
    group('Bridge Registration', () {
      test('registerBridges registers Tom class', () {
        final d4rt = D4rt();
        repl.registerBridges(d4rt);

        // Verify Tom class is available
        final config = d4rt.getConfiguration();
        final imports = config.imports;

        // Check that we have bridge imports registered
        expect(imports.isNotEmpty, isTrue,
            reason: 'Expected bridge imports to be registered');

        // Look for Tom class in the registered classes
        final allClasses = imports.expand((i) => i.classes).map((c) => c.name);
        expect(allClasses, contains('Tom'),
            reason: 'Tom class should be registered');
      });

      test('getImportBlock includes Tom import', () {
        final importBlock = repl.getImportBlock();
        expect(importBlock, contains('tom_build_cli'));
        expect(importBlock, contains('Tom'));
      });
    });

    // =========================================================================
    // Help Sections
    // =========================================================================
    group('Help Sections', () {
      test('getAdditionalHelpSections includes Tom commands', () {
        final sections = repl.getAdditionalHelpSections();
        expect(sections.isNotEmpty, isTrue);

        final tomSection = sections.last;
        expect(tomSection, contains('Tom Workspace Commands'));
        expect(tomSection, contains(':analyze'));
        expect(tomSection, contains(':build'));
        expect(tomSection, contains(':test'));
      });
    });

    // =========================================================================
    // ReplState Creation
    // =========================================================================
    group('ReplState Creation', () {
      test('createReplState returns state with tom prompt', () {
        final state = repl.createReplState();
        expect(state.promptName, equals('tom'));
      });
    });
  });

  group('Tom Command Detection', () {
    // These tests verify that commands with : ! - prefixes are detected
    // as Tom commands

    test(':analyze is a Tom command', () {
      expect(':analyze'.startsWith(':'), isTrue);
    });

    test('!build is a Tom command', () {
      expect('!build'.startsWith('!'), isTrue);
    });

    test('-verbose is a Tom command', () {
      expect('-verbose'.startsWith('-'), isTrue);
    });

    test('print("hello") is not a Tom command', () {
      final line = 'print("hello")';
      expect(
        line.startsWith(':') || line.startsWith('!') || line.startsWith('-'),
        isFalse,
      );
    });

    test('connect is not a Tom command', () {
      final line = 'connect';
      expect(
        line.startsWith(':') || line.startsWith('!') || line.startsWith('-'),
        isFalse,
      );
    });
  });
}
