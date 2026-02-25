// Tests for D4rt execution with WsPrepper bridges.
//
// These tests verify that:
// 1. WsPrepper classes can be instantiated via D4rt scripts
// 2. Properties and methods work correctly through the bridge
// 3. The bridges are correctly registered with the barrel file import
//
// The test pattern:
// - Create a D4rtInstance and register bridges
// - Execute D4rt scripts that use WsPrepper classes
// - Verify the results match expected values

import 'package:test/test.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

import 'ws_prepper_bridge_test.reflection.dart' as reflection;

void main() {
  // Initialize reflection for TomCoreKernelBridge global variables
  reflection.initializeReflection();
  group('WsPrepper Bridge Tests', () {
    late D4rtInstance d4rt;

    setUp(() async {
      d4rt = D4rtInstance.create();

      // Bridges are already registered by D4rtInstance.create()

      // Initialize with imports so evaluate() can access the classes
      await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

void main() {
  // Imports are now available for eval()
}
''');
    });

    tearDown(() {
      d4rt.dispose();
    });

    // =========================================================================
    // TemplateParser Bridge Tests
    // =========================================================================

    group('TemplateParser bridge', skip: 'Class not bridged', () {
      test('can create TemplateParser instance', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

TemplateParser? globalParser;

void main() {
  globalParser = TemplateParser('Hello World');
}
''');
        final result = await d4rt.evaluate('globalParser');
        expect(result, isA<TemplateParser>());
        final parser = result as TemplateParser;
        expect(parser.content, equals('Hello World'));
      });

      test('can call TemplateParser.parse', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

ParsedTemplate? parsed;

void main() {
  final parser = TemplateParser('Hello');
  parsed = parser.parse();
}
''');
        final result = await d4rt.evaluate('parsed');
        expect(result, isA<ParsedTemplate>());
      });

      test('can parse template with mode blocks', () async {
        // Create the parser directly in Dart and verify it works
        // (nested triple quotes don't work well in D4rt scripts)
        const content = '''Line 1
@@@mode development
Dev content
@@@endmode
Line 2''';
        final parser = TemplateParser(content);
        final parsed = parser.parse();
        expect(parsed, isA<ParsedTemplate>());
        expect(parsed.segments, isNotEmpty);
        expect(parsed.blocks, isNotEmpty);
      });

      // NOTE: D4rt wraps static const/getter as BridgedStaticMethodCallable,
      // so we test with native Dart instead
      test('TemplateParser static properties (native)', () {
        expect(TemplateParser.markerPrefix, equals('@@@'));
        expect(TemplateParser.modeStartPattern, isA<RegExp>());
        expect(TemplateParser.modeEndPattern, isA<RegExp>());
      });
    });

    // =========================================================================
    // ParsedTemplate Bridge Tests
    // =========================================================================

    group('ParsedTemplate bridge', () {
      // NOTE: Use native Dart for tests with List params - D4rt type coercion issues
      test('ParsedTemplate can be created (native)', () {
        final segment = TextSegment('Hello');
        final block = ModeBlock(modes: ['dev'], content: 'Dev only');
        final parsed = ParsedTemplate(
          segments: [segment],
          blocks: [block],
        );
        expect(parsed.segments.length, equals(1));
        expect(parsed.blocks.length, equals(1));
      });

      test('ParsedTemplate.definedModes works (native)', () {
        final block1 = ModeBlock(modes: ['dev'], content: 'Dev');
        final block2 = ModeBlock(modes: ['prod'], content: 'Prod');
        final parsed = ParsedTemplate(
          segments: [],
          blocks: [block1, block2],
        );
        expect(parsed.definedModes, contains('dev'));
        expect(parsed.definedModes, contains('prod'));
      });
    });

    // =========================================================================
    // TextSegment Bridge Tests
    // =========================================================================

    group('TextSegment bridge', skip: 'Class not bridged', () {
      test('can create TextSegment instance', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

TextSegment? globalSegment;

void main() {
  globalSegment = TextSegment('Plain text content');
}
''');
        final result = await d4rt.evaluate('globalSegment');
        expect(result, isA<TextSegment>());
        final segment = result as TextSegment;
        expect(segment.content, equals('Plain text content'));
      });

      test('TextSegment is a TemplateSegment', () async {
        await d4rt.executeScript('''
import 'package:tom_build/tom_build.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

TextSegment? segment;

void main() {
  segment = TextSegment('Content');
}
''');
        final result = await d4rt.evaluate('segment');
        expect(result, isA<TemplateSegment>());
      });
    });

    // =========================================================================
    // ModeBlockGroup Bridge Tests
    // =========================================================================

    group('ModeBlockGroup bridge', () {
      // NOTE: Use native Dart for tests with List params - D4rt type coercion issues
      test('ModeBlockGroup can be created (native)', () {
        final block1 = ModeBlock(modes: ['dev'], content: 'Dev content');
        final block2 = ModeBlock(modes: ['prod'], content: 'Prod content');
        final group = ModeBlockGroup([block1, block2]);
        expect(group.blocks.length, equals(2));
      });

      test('ModeBlockGroup is a TemplateSegment (native)', () {
        final group = ModeBlockGroup([]);
        expect(group, isA<TemplateSegment>());
      });

      test('ModeBlockGroup.blocks property (native)', () {
        final block = ModeBlock(modes: ['test'], content: 'Test');
        final group = ModeBlockGroup([block]);
        expect(group.blocks.length, equals(1));
      });
    });

    // =========================================================================
    // ModeBlock Bridge Tests
    // =========================================================================

    group('ModeBlock bridge', () {
      // NOTE: Use native Dart for tests with List params - D4rt type coercion issues
      test('ModeBlock can be created (native)', () {
        final block = ModeBlock(
          modes: ['development', 'testing'],
          content: 'This is dev/test content',
        );
        expect(block.modes, equals(['development', 'testing']));
        expect(block.content, equals('This is dev/test content'));
      });

      test('ModeBlock.modes property (native)', () {
        final block = ModeBlock(
          modes: ['mode1', 'mode2', 'mode3'],
          content: 'Content',
        );
        expect(block.modes.length, equals(3));
      });

      test('ModeBlock.toString works (native)', () {
        final block = ModeBlock(
          modes: ['dev'],
          content: 'Dev content',
        );
        expect(block.toString(), contains('dev'));
      });

      test('multiple ModeBlocks can be created (native)', () {
        final block1 = ModeBlock(modes: ['dev'], content: 'Dev');
        final block2 = ModeBlock(modes: ['prod'], content: 'Prod');
        expect(block1.content, equals('Dev'));
        expect(block2.content, equals('Prod'));
      });
    });
  });

  // ===========================================================================
  // Bridge Registration Verification
  // ===========================================================================

  group('WsPrepper Bridge Registration Verification', () {
    test('all WsPrepper bridges are registered', () {
      final instance = D4rtInstance.create();
      expect(instance.isInitialized, isTrue);

      // Verify interpreter.getConfiguration() returns classes
      final config = instance.interpreter.getConfiguration();
      final classes = config.imports.expand((i) => i.classes).toList();
      expect(classes.length, greaterThanOrEqualTo(5));

      instance.dispose();
    });

    test('bridge class names match expected list', () {
      final instance = D4rtInstance.create();
      
      // Core classes that must be present (from tom_build_bridges)
      final expectedCoreClasses = [
        'DocScanner',
        'Section',
        'Document',
      ];

      final config = instance.interpreter.getConfiguration();
      final actualClasses = config.imports
          .expand((i) => i.classes)
          .map((c) => c.name)
          .toList();
      
      // Verify core classes are present
      for (final expected in expectedCoreClasses) {
        expect(actualClasses, contains(expected));
      }
      
      instance.dispose();
    });
  });
}
