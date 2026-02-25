import 'package:test/test.dart';
import 'package:tom_build_cli/tom_build_cli.dart';

void main() {
  group('TomCommandParser', () {
    late TomCommandParser parser;

    setUp(() {
      parser = TomCommandParser();
    });

    test('parses single command', () {
      final result = parser.parse(['ws_analyzer']);

      expect(result.commands.length, equals(1));
      expect(result.commands[0].name, equals('ws_analyzer'));
      expect(result.globalParams, isEmpty);
      expect(result.globalFlags, isEmpty);
    });

    test('parses command with parameters', () {
      final result = parser.parse(['ws_prepper', 'mode=dev']);

      expect(result.commands.length, equals(1));
      expect(result.commands[0].name, equals('ws_prepper'));
      expect(result.commands[0].params['mode'], equals('dev'));
    });

    test('parses command with flags', () {
      final result = parser.parse(['ws_analyzer', '--verbose', '-d']);

      expect(result.commands.length, equals(1));
      expect(result.commands[0].flags, contains('verbose'));
      expect(result.commands[0].flags, contains('d'));
    });

    test('parses global parameters before command', () {
      final result = parser.parse(['path=/my/workspace', 'ws_analyzer']);

      expect(result.globalParams['path'], equals('/my/workspace'));
      expect(result.commands.length, equals(1));
      expect(result.commands[0].name, equals('ws_analyzer'));
    });

    test('parses global flags before command', () {
      final result = parser.parse(['--verbose', '--dry-run', 'ws_analyzer']);

      expect(result.globalFlags, contains('verbose'));
      expect(result.globalFlags, contains('dry-run'));
      expect(result.verbose, isTrue);
      expect(result.dryRun, isTrue);
      expect(result.commands.length, equals(1));
    });

    test('parses multiple commands in sequence', () {
      final result = parser.parse([
        'ws_analyzer',
        'ws_prepper', 'mode=dev',
        'ws_prepper', 'mode=release',
      ]);

      expect(result.commands.length, equals(3));
      expect(result.commands[0].name, equals('ws_analyzer'));
      expect(result.commands[1].name, equals('ws_prepper'));
      expect(result.commands[1].params['mode'], equals('dev'));
      expect(result.commands[2].name, equals('ws_prepper'));
      expect(result.commands[2].params['mode'], equals('release'));
    });

    test('allows same command multiple times', () {
      final result = parser.parse([
        'ws_prepper', 'mode=dev',
        'ws_prepper', 'mode=production',
      ]);

      expect(result.commands.length, equals(2));
      expect(result.commands[0].params['mode'], equals('dev'));
      expect(result.commands[1].params['mode'], equals('production'));
    });

    test('merges global params with command params', () {
      final result = parser.parse([
        'path=/workspace', '--verbose',
        'ws_analyzer', '--dry-run',
      ]);

      final merged = parser.mergeWithGlobals(
        result.commands[0],
        result.globalParams,
        result.globalFlags,
      );

      expect(merged.params['path'], equals('/workspace'));
      expect(merged.flags, contains('verbose'));
      expect(merged.flags, contains('dry-run'));
    });

    test('command params override global params', () {
      final result = parser.parse([
        'path=/global',
        'ws_analyzer', 'path=/local',
      ]);

      final merged = parser.mergeWithGlobals(
        result.commands[0],
        result.globalParams,
        result.globalFlags,
      );

      expect(merged.params['path'], equals('/local'));
    });

    test('parses help flag', () {
      final result = parser.parse(['--help']);

      expect(result.help, isTrue);
      expect(result.hasCommands, isFalse);
    });

    test('parses short help flag', () {
      final result = parser.parse(['-h']);

      expect(result.help, isTrue);
    });

    test('parses complex multi-command pipeline', () {
      final result = parser.parse([
        'path=/my/workspace',
        '--verbose',
        'ws_analyzer',
        'ws_prepper', 'mode=dev', '--dry-run',
        'reflection_generator', 'target=lib/main.dart',
      ]);

      expect(result.globalParams['path'], equals('/my/workspace'));
      expect(result.verbose, isTrue);
      expect(result.commands.length, equals(3));

      expect(result.commands[0].name, equals('ws_analyzer'));

      expect(result.commands[1].name, equals('ws_prepper'));
      expect(result.commands[1].params['mode'], equals('dev'));
      expect(result.commands[1].dryRun, isTrue);

      expect(result.commands[2].name, equals('reflection_generator'));
      expect(result.commands[2].params['target'], equals('lib/main.dart'));
    });
  });

  group('parseTomCommand convenience function', () {
    test('parses arguments correctly', () {
      final result = parseTomCommand(['--verbose', 'ws_analyzer']);

      expect(result.verbose, isTrue);
      expect(result.commands.length, equals(1));
    });

    test('supports additional commands', () {
      final result = parseTomCommand(
        ['custom_cmd', 'param=value'],
        additionalCommands: {'custom_cmd'},
      );

      expect(result.commands.length, equals(1));
      expect(result.commands[0].name, equals('custom_cmd'));
    });
  });

  group('ParsedCommand', () {
    test('get returns default for missing key', () {
      const cmd = ParsedCommand(name: 'test', params: {});

      expect(cmd.get('missing', 'default'), equals('default'));
    });

    test('getInt parses integers', () {
      const cmd = ParsedCommand(name: 'test', params: {'count': '42'});

      expect(cmd.getInt('count'), equals(42));
      expect(cmd.getInt('missing'), isNull);
    });

    test('getBool parses booleans', () {
      const cmd = ParsedCommand(
        name: 'test',
        params: {'enabled': 'true', 'flag': '1', 'disabled': 'false'},
      );

      expect(cmd.getBool('enabled'), isTrue);
      expect(cmd.getBool('flag'), isTrue);
      expect(cmd.getBool('disabled'), isFalse);
      expect(cmd.getBool('missing'), isFalse);
      expect(cmd.getBool('missing', true), isTrue);
    });
  });
}
