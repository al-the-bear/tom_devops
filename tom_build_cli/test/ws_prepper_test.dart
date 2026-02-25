import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

void main() {
  group('TemplateParser', () {
    test('parses template with single mode block', () {
      const template = '''
before
@@@mode dev
dev content
@@@endmode
after
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      expect(parsed.segments.length, equals(3));
      expect(parsed.blocks.length, equals(1));
      expect(parsed.blocks[0].modes, equals(['dev']));
      expect(parsed.blocks[0].content, equals('dev content\n'));
    });

    test('parses template with multiple mode alternatives', () {
      const template = '''
before
@@@mode dev
dev content
@@@mode release
release content
@@@endmode
after
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      expect(parsed.segments.length, equals(3));
      expect(parsed.blocks.length, equals(2));
      expect(parsed.blocks[0].modes, equals(['dev']));
      expect(parsed.blocks[1].modes, equals(['release']));
    });

    test('parses comma-separated modes', () {
      const template = '''
@@@mode dev, staging
shared content
@@@endmode
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      expect(parsed.blocks.length, equals(1));
      expect(parsed.blocks[0].modes, equals(['dev', 'staging']));
    });

    test('parses default mode', () {
      const template = '''
@@@mode dev
dev content
@@@mode default
default content
@@@endmode
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      expect(parsed.blocks.length, equals(2));
      expect(parsed.definedModes, contains('default'));
    });

    test('parses multiple separate mode block groups', () {
      const template = '''
start
@@@mode dev
first dev
@@@mode release
first release
@@@endmode
middle
@@@mode dev
second dev
@@@endmode
end
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      expect(parsed.segments.length, equals(5)); // text, group, text, group, text
      expect(parsed.blocks.length, equals(3));
    });

    test('handles template with no mode blocks', () {
      const template = '''
just regular content
no modes here
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      expect(parsed.segments.length, equals(1));
      expect(parsed.blocks.length, equals(0));
    });

    test('returns all defined modes', () {
      const template = '''
@@@mode dev
dev
@@@mode release, staging
release
@@@endmode
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      expect(parsed.definedModes, equals({'dev', 'release', 'staging'}));
    });
  });

  group('WsPrepper.generateOutput', () {
    late WsPrepper switcher;

    setUp(() {
      switcher = WsPrepper('/tmp/test');
    });

    test('generates output for matching mode', () {
      const template = '''
before
@@@mode dev
dev content
@@@mode release
release content
@@@endmode
after
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      final devOutput = switcher.generateOutput(parsed, 'dev');
      expect(devOutput, contains('dev content'));
      expect(devOutput, isNot(contains('release content')));
      expect(devOutput, contains('before'));
      expect(devOutput, contains('after'));

      final releaseOutput = switcher.generateOutput(parsed, 'release');
      expect(releaseOutput, contains('release content'));
      expect(releaseOutput, isNot(contains('dev content')));
    });

    test('uses default mode when no match', () {
      const template = '''
@@@mode dev
dev content
@@@mode default
default content
@@@endmode
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      final unknownOutput = switcher.generateOutput(parsed, 'unknown');
      expect(unknownOutput, contains('default content'));
      expect(unknownOutput, isNot(contains('dev content')));
    });

    test('produces empty for unmatched mode without default', () {
      const template = '''
before
@@@mode dev
dev content
@@@endmode
after
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      final unknownOutput = switcher.generateOutput(parsed, 'unknown');
      expect(unknownOutput, equals('before\nafter\n'));
    });

    test('handles comma-separated modes', () {
      const template = '''
@@@mode dev, staging
shared content
@@@mode release
release content
@@@endmode
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      expect(switcher.generateOutput(parsed, 'dev'), contains('shared content'));
      expect(switcher.generateOutput(parsed, 'staging'), contains('shared content'));
      expect(switcher.generateOutput(parsed, 'release'), contains('release content'));
    });

    test('handles multiple mode block groups', () {
      const template = '''
@@@mode dev
first dev
@@@mode release
first release
@@@endmode
middle
@@@mode dev
second dev
@@@endmode
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      final devOutput = switcher.generateOutput(parsed, 'dev');
      expect(devOutput, contains('first dev'));
      expect(devOutput, contains('second dev'));
      expect(devOutput, contains('middle'));
      expect(devOutput, isNot(contains('first release')));
    });

    test('handles multiple comma-separated modes input (last match wins)', () {
      const template = '''
@@@mode dev
dev content
@@@mode local
local content
@@@mode debug
debug content
@@@endmode
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      // Single mode still works
      expect(switcher.generateOutput(parsed, 'dev'), contains('dev content'));
      expect(switcher.generateOutput(parsed, 'local'), contains('local content'));

      // Multiple modes - last match wins
      expect(switcher.generateOutput(parsed, 'dev,local'), contains('local content'));
      expect(switcher.generateOutput(parsed, 'local,dev'), contains('dev content'));
      expect(switcher.generateOutput(parsed, 'dev,local,debug'), contains('debug content'));
      
      // Order matters - last matching mode wins
      expect(switcher.generateOutput(parsed, 'debug,local,dev'), contains('dev content'));
    });

    test('multiple modes falls back to default when no match', () {
      const template = '''
@@@mode dev
dev content
@@@mode default
default content
@@@endmode
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      // Unknown modes fall back to default
      expect(switcher.generateOutput(parsed, 'unknown,other'), contains('default content'));
      
      // But if one matches, use it
      expect(switcher.generateOutput(parsed, 'unknown,dev'), contains('dev content'));
    });

    test('multiple modes with spaces are trimmed', () {
      const template = '''
@@@mode dev
dev content
@@@mode local
local content
@@@endmode
''';
      final parser = TemplateParser(template);
      final parsed = parser.parse();

      // Spaces around mode names should be trimmed
      expect(switcher.generateOutput(parsed, 'dev , local'), contains('local content'));
      expect(switcher.generateOutput(parsed, ' dev, local '), contains('local content'));
    });
  });

  group('WsPrepper file processing', () {
    late Directory tempDir;
    late String fixturesPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ws_prepper_test_');
      fixturesPath = p.join(
        Directory.current.path,
        'test',
        'fixtures',
        'ws_prepper',
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('finds template files', () async {
      // Copy fixture to temp
      final templateContent = File(p.join(fixturesPath, 'pubspec.yaml.tomplate'))
          .readAsStringSync();
      File(p.join(tempDir.path, 'pubspec.yaml.tomplate'))
          .writeAsStringSync(templateContent);

      final switcher = WsPrepper(tempDir.path);
      final templates = await switcher.findTemplates();

      expect(templates.length, equals(1));
      expect(templates[0].path, endsWith('.tomplate'));
    });

    // Note: Legacy .modetemplate support was removed in the refactoring
    // as per TODO 10 (backwards compatibility removal)

    test('processes pubspec.yaml template for dev mode', () async {
      final templateContent = File(p.join(fixturesPath, 'pubspec.yaml.tomplate'))
          .readAsStringSync();
      File(p.join(tempDir.path, 'pubspec.yaml.tomplate'))
          .writeAsStringSync(templateContent);

      final switcher = WsPrepper(tempDir.path);
      final result = await switcher.processAll('dev');

      expect(result.success, isTrue);
      expect(result.processed.length, equals(1));

      final outputFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      expect(outputFile.existsSync(), isTrue);

      final content = outputFile.readAsStringSync();
      expect(content, contains('path: ../tom_core'));
      expect(content, contains('path: ../tom_shared'));
      expect(content, isNot(contains('tom_core: ^1.0.0')));
      expect(content, isNot(contains('@@@')));
    });

    test('processes pubspec.yaml template for release mode', () async {
      final templateContent = File(p.join(fixturesPath, 'pubspec.yaml.tomplate'))
          .readAsStringSync();
      File(p.join(tempDir.path, 'pubspec.yaml.tomplate'))
          .writeAsStringSync(templateContent);

      final switcher = WsPrepper(tempDir.path);
      await switcher.processAll('release');

      final outputFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      final content = outputFile.readAsStringSync();

      expect(content, contains('tom_core: ^1.0.0'));
      expect(content, contains('tom_shared: ^1.0.0'));
      expect(content, isNot(contains('path: ../tom_core')));
    });

    test('processes config.json template', () async {
      final templateContent = File(p.join(fixturesPath, 'config.json.tomplate'))
          .readAsStringSync();
      File(p.join(tempDir.path, 'config.json.tomplate'))
          .writeAsStringSync(templateContent);

      final switcher = WsPrepper(tempDir.path);
      await switcher.processAll('dev');

      final outputFile = File(p.join(tempDir.path, 'config.json'));
      final content = outputFile.readAsStringSync();

      expect(content, contains('http://localhost:8080'));
      expect(content, contains('"debug": true'));
    });

    test('dry run does not write files', () async {
      final templateContent = File(p.join(fixturesPath, 'pubspec.yaml.tomplate'))
          .readAsStringSync();
      File(p.join(tempDir.path, 'pubspec.yaml.tomplate'))
          .writeAsStringSync(templateContent);

      final switcher = WsPrepper(
        tempDir.path,
        options: WsPrepperOptions(dryRun: true),
      );
      final result = await switcher.processAll('dev');

      expect(result.success, isTrue);
      expect(result.processed.length, equals(1));
      expect(result.processed[0].dryRun, isTrue);

      final outputFile = File(p.join(tempDir.path, 'pubspec.yaml'));
      expect(outputFile.existsSync(), isFalse);
    });

    test('handles template with no mode blocks', () async {
      final templateContent = File(p.join(fixturesPath, 'no_modes.txt.tomplate'))
          .readAsStringSync();
      File(p.join(tempDir.path, 'no_modes.txt.tomplate'))
          .writeAsStringSync(templateContent);

      final switcher = WsPrepper(tempDir.path);
      await switcher.processAll('dev');

      final outputFile = File(p.join(tempDir.path, 'no_modes.txt'));
      final content = outputFile.readAsStringSync();

      expect(content, equals(templateContent));
    });

    test('processes multiple templates', () async {
      // Copy multiple fixtures
      for (final name in ['pubspec.yaml', 'config.json', 'no_modes.txt']) {
        final templateContent = File(p.join(fixturesPath, '$name.tomplate'))
            .readAsStringSync();
        File(p.join(tempDir.path, '$name.tomplate'))
            .writeAsStringSync(templateContent);
      }

      final switcher = WsPrepper(tempDir.path);
      final result = await switcher.processAll('dev');

      expect(result.success, isTrue);
      expect(result.processed.length, equals(3));
    });

    test('excludes .dart_tool directory', () async {
      // Create template in .dart_tool
      final dartToolDir = Directory(p.join(tempDir.path, '.dart_tool'));
      dartToolDir.createSync();
      File(p.join(dartToolDir.path, 'test.txt.tomplate'))
          .writeAsStringSync('content');

      final switcher = WsPrepper(tempDir.path);
      final templates = await switcher.findTemplates();

      expect(templates, isEmpty);
    });

    test('processes dart file with multiple mode block groups', () async {
      final templateContent = File(p.join(fixturesPath, 'main.dart.tomplate'))
          .readAsStringSync();
      File(p.join(tempDir.path, 'main.dart.tomplate'))
          .writeAsStringSync(templateContent);

      final switcher = WsPrepper(tempDir.path);
      await switcher.processAll('dev');

      final outputFile = File(p.join(tempDir.path, 'main.dart'));
      final content = outputFile.readAsStringSync();

      expect(content, contains("const bool kDebugMode = true;"));
      expect(content, contains("runDevServer();"));
      expect(content, isNot(contains('@@@')));
    });

    test('uses default for unmatched mode', () async {
      final templateContent = File(p.join(fixturesPath, 'main.dart.tomplate'))
          .readAsStringSync();
      File(p.join(tempDir.path, 'main.dart.tomplate'))
          .writeAsStringSync(templateContent);

      final switcher = WsPrepper(tempDir.path);
      await switcher.processAll('unknown_mode');

      final outputFile = File(p.join(tempDir.path, 'main.dart'));
      final content = outputFile.readAsStringSync();

      // Should use default for first block
      expect(content, contains("const String kEnvironment = 'unknown';"));
    });
  });
}
