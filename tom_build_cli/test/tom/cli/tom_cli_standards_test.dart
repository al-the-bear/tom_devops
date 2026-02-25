// Tests for Tom CLI Standards and Naming Conventions
//
// Verifies compliance with tom_tool_specification.md Section 6.0:
// - Arguments: No dash
// - Parameters: Single dash with equals (-key=value)
// - Options: Single or double dash boolean flags (-verbose, --dry-run)

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/cli/argument_parser.dart';

void main() {
  group('Tom CLI Standards', () {
    late ArgumentParser parser;

    setUp(() {
      parser = ArgumentParser();
    });

    // =========================================================================
    // Naming Convention: Arguments (No Dash)
    // =========================================================================
    group('Arguments (No Dash)', () {
      test('accepts project names as arguments', () {
        final result = parser.parse([':projects', 'project_one', 'project_two']);
        
        expect(result.projects, contains('project_one'));
        expect(result.projects, contains('project_two'));
      });

      test('accepts group names as arguments', () {
        final result = parser.parse([':groups', 'group_a', 'group_b']);
        
        expect(result.groups, contains('group_a'));
        expect(result.groups, contains('group_b'));
      });
    });

    // =========================================================================
    // Naming Convention: Parameters (-key=value)
    // =========================================================================
    group('Parameters (-key=value)', () {
      test('accepts parameters with single dash', () {
        final result = parser.parse([':analyze', '-mode=full']);
        
        expect(result.actions[0].parameters['mode'], equals('full'));
      });

      test('accepts parameters with double dash', () {
        final result = parser.parse([':analyze', '--mode=full']);
        
        expect(result.actions[0].parameters['mode'], equals('full'));
      });
      
      test('interprets no-dash key=value as argument (not parameter)', () {
        // In :projects scope, "key=value" should be treated as a project name, not a parameter
        final result = parser.parse([':projects', 'mode=full']);
        
        expect(result.projects, contains('mode=full'));
        expect(result.projectParameters, isEmpty);
      });

       test('throws on no-dash key=value in global scope', () {
        // In global scope, non-parameters are unexpected
        expect(() => parser.parse(['mode=full', ':analyze']), throwsArgumentError);
      });
    });

    // =========================================================================
    // Naming Convention: Options (-flag or --flag)
    // =========================================================================
    group('Options (-flag or --flag)', () {
      test('accepts global options with single dash', () {
        final result = parser.parse(['-verbose', ':analyze']);
        expect(result.verbose, isTrue);
      });

      test('accepts global options with double dash', () {
        final result = parser.parse(['--verbose', ':analyze']);
        expect(result.verbose, isTrue);
      });

      test('accepts action options (boolean parameters)', () {
        // Options passed to actions work as boolean parameters
        // -force becomes force=true
        final result = parser.parse([':analyze', '-force']);
        
        expect(result.actions[0].parameters['force'], equals('true'));
      });
      
      test('accepts action options with double dash', () {
        final result = parser.parse([':analyze', '--force']);
        
        expect(result.actions[0].parameters['force'], equals('true'));
      });
    });

    // =========================================================================
    // Complex Usage Scenarios
    // =========================================================================
    group('Complex Usage', () {
      test('mixes arguments, parameters, and options', () {
        final result = parser.parse([
          '-verbose',                        // Global Option
          '-env=prod',                       // Global Parameter
          ':projects',                       // Scope
          'tom_core',                        // Argument (Project)
          '-branch=main',                    // Parameter (Project-specific)
          ':analyze',                        // Action
          '-depth=full',                     // Parameter (Action-specific)
          '--report'                         // Option (Action-specific)
        ]);

        expect(result.verbose, isTrue);
        expect(result.globalParameters['env'], equals('prod'));
        
        expect(result.projects, contains('tom_core'));
        expect(result.projectParameters['tom_core']?['branch'], equals('main'));
        
        expect(result.actions[0].name, equals('analyze'));
        expect(result.actions[0].parameters['depth'], equals('full'));
        expect(result.actions[0].parameters['report'], equals('true'));
      });
    });
  });
}
