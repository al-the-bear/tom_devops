// Tests for ArgumentParser - CLI argument parsing
//
// Covers tom_tool_specification.md Section 6.1:
// - CLI Syntax structure
// - Global parameters
// - :projects scope limiter
// - :groups scope limiter
// - Action invocations
// - Internal commands
// - Argument prefixes
// - Help/version flags

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/cli/argument_parser.dart';

void main() {
  group('ArgumentParser', () {
    late ArgumentParser parser;

    setUp(() {
      parser = ArgumentParser();
    });

    // =========================================================================
    // Section 6.1 - Empty and Help Arguments
    // =========================================================================
    group('Section 6.1 - Empty and Help Arguments', () {
      test('empty arguments returns help requested', () {
        final result = parser.parse([]);

        expect(result.helpRequested, isTrue);
        expect(result.actions, isEmpty);
      });

      test('parses -help flag', () {
        final result = parser.parse(['-help']);

        expect(result.helpRequested, isTrue);
      });

      test('parses --help flag', () {
        final result = parser.parse(['--help']);

        expect(result.helpRequested, isTrue);
      });

      test('parses -h flag', () {
        final result = parser.parse(['-h']);

        expect(result.helpRequested, isTrue);
      });

      test('parses -version flag', () {
        final result = parser.parse(['-version']);

        expect(result.versionRequested, isTrue);
      });

      test('parses --version flag', () {
        final result = parser.parse(['--version']);

        expect(result.versionRequested, isTrue);
      });

      test('parses -v flag', () {
        final result = parser.parse(['-v']);

        expect(result.versionRequested, isTrue);
      });
    });

    // =========================================================================
    // Section 6.1.3 - Global Execution
    // =========================================================================
    group('Section 6.1.3 - Global Execution', () {
      test('parses single action', () {
        final result = parser.parse([':build']);

        expect(result.actions.length, equals(1));
        expect(result.actions[0].name, equals('build'));
        expect(result.targetsAllProjects, isTrue);
      });

      test('parses multiple actions', () {
        final result = parser.parse([':build', ':test']);

        expect(result.actions.length, equals(2));
        expect(result.actions[0].name, equals('build'));
        expect(result.actions[1].name, equals('test'));
      });

      test('parses action with parameters', () {
        final result = parser.parse([':build', '-verbose=true', '-output=./dist']);

        expect(result.actions.length, equals(1));
        expect(result.actions[0].parameters['verbose'], equals('true'));
        expect(result.actions[0].parameters['output'], equals('./dist'));
      });

      test('parses verbose flag', () {
        final result = parser.parse(['-verbose', ':build']);

        expect(result.verbose, isTrue);
      });

      test('parses dry-run flag', () {
        final result = parser.parse(['-dry-run', ':build']);

        expect(result.dryRun, isTrue);
      });
    });

    // =========================================================================
    // Section 6.1.1 - Project-Based Execution
    // =========================================================================
    group('Section 6.1.1 - Project-Based Execution', () {
      test('parses :projects with single project', () {
        final result = parser.parse([':projects', 'tom_build', ':build']);

        expect(result.hasProjectsScope, isTrue);
        expect(result.hasGroupsScope, isFalse);
        expect(result.projects, equals(['tom_build']));
        expect(result.actions.length, equals(1));
        expect(result.actions[0].name, equals('build'));
      });

      test('parses :projects with multiple projects', () {
        final result = parser.parse([
          ':projects',
          'tom_build',
          'tom_tools',
          ':build',
        ]);

        expect(result.projects, equals(['tom_build', 'tom_tools']));
      });

      test('parses project with parameters', () {
        final result = parser.parse([
          ':projects',
          'tom_uam_server',
          '-cloud-provider=gcp',
          ':build',
        ]);

        expect(result.projects, equals(['tom_uam_server']));
        expect(
          result.projectParameters['tom_uam_server']?['cloud-provider'],
          equals('gcp'),
        );
      });

      test('parses multiple projects with individual parameters', () {
        final result = parser.parse([
          ':projects',
          'project_a',
          '-env=prod',
          'project_b',
          '-env=dev',
          ':build',
        ]);

        expect(result.projectParameters['project_a']?['env'], equals('prod'));
        expect(result.projectParameters['project_b']?['env'], equals('dev'));
      });
    });

    // =========================================================================
    // Section 6.1.2 - Group-Based Execution
    // =========================================================================
    group('Section 6.1.2 - Group-Based Execution', () {
      test('parses :groups with single group', () {
        final result = parser.parse([':groups', 'dart-bridge', ':build']);

        expect(result.hasGroupsScope, isTrue);
        expect(result.hasProjectsScope, isFalse);
        expect(result.groups, equals(['dart-bridge']));
        expect(result.actions.length, equals(1));
      });

      test('parses :groups with multiple groups', () {
        final result = parser.parse([
          ':groups',
          'dart-bridge',
          'uam',
          ':deploy',
        ]);

        expect(result.groups, equals(['dart-bridge', 'uam']));
      });

      test('parses group with parameters', () {
        final result = parser.parse([
          ':groups',
          'uam',
          '-cloud-provider=aws',
          ':deploy_prod',
        ]);

        expect(result.groups, equals(['uam']));
        expect(
          result.groupParameters['uam']?['cloud-provider'],
          equals('aws'),
        );
      });

      test('throws when both :projects and :groups used', () {
        expect(
          () => parser.parse([':projects', 'proj', ':groups', 'grp', ':build']),
          throwsArgumentError,
        );
      });
    });

    // =========================================================================
    // Section 6.1.4 - Global Parameters
    // =========================================================================
    group('Section 6.1.4 - Global Parameters', () {
      test('parses global parameters before :projects', () {
        final result = parser.parse([
          '-verbose=true',
          '-output=./dist',
          ':projects',
          'tom_build',
          ':build',
        ]);

        expect(result.globalParameters['verbose'], equals('true'));
        expect(result.globalParameters['output'], equals('./dist'));
      });

      test('parses flag without value as true', () {
        final result = parser.parse(['-output', ':build']);

        // Flags without values are treated as boolean true
        expect(result.globalParameters['output'], equals('true'));
      });

      test('throws on unexpected argument in global position', () {
        expect(
          () => parser.parse(['unexpected_arg']),
          throwsArgumentError,
        );
      });
    });

    // =========================================================================
    // Section 6.3 - Built-in Commands vs Workspace Actions
    // =========================================================================
    group('Section 6.3 - Built-in Commands vs Workspace Actions', () {
      test('recognizes internal commands', () {
        final result = parser.parse([':analyze']);

        expect(result.actions[0].isInternalCommand, isTrue);
        expect(result.actions[0].name, equals('analyze'));
      });

      test('recognizes workspace actions (not internal)', () {
        final result = parser.parse([':build']);

        expect(result.actions[0].isInternalCommand, isFalse);
        expect(result.actions[0].name, equals('build'));
      });

      test('parses ! prefix for bypass', () {
        final result = parser.parse(['!build']);

        expect(result.actions[0].bypassWorkspaceAction, isTrue);
        expect(result.actions[0].name, equals('build'));
      });

      test('all internal commands are recognized', () {
        for (final cmd in ArgumentParser.internalCommands) {
          final result = parser.parse([':$cmd']);
          expect(result.actions[0].isInternalCommand, isTrue,
              reason: '$cmd should be internal');
        }
      });
    });

    // =========================================================================
    // Section 6.4 - Internal Commands
    // =========================================================================
    group('Section 6.4 - Internal Commands', () {
      test('parses :analyze command', () {
        final result = parser.parse([':analyze']);

        expect(result.actions[0].name, equals('analyze'));
        expect(result.actions[0].isInternalCommand, isTrue);
      });

      test('parses :version-bump command', () {
        final result = parser.parse([':version-bump']);

        expect(result.actions[0].name, equals('version-bump'));
        expect(result.actions[0].isInternalCommand, isTrue);
      });

      test('parses :reset-action-counter command', () {
        final result = parser.parse([':reset-action-counter']);

        expect(result.actions[0].name, equals('reset-action-counter'));
        expect(result.actions[0].isInternalCommand, isTrue);
      });

      test('parses :pipeline command', () {
        final result = parser.parse([':pipeline', '-name=ci']);

        expect(result.actions[0].name, equals('pipeline'));
        expect(result.actions[0].parameters['name'], equals('ci'));
      });

      test('chains internal commands with actions', () {
        final result = parser.parse([':analyze', ':build', ':test']);

        expect(result.actions.length, equals(3));
        expect(result.actions[0].isInternalCommand, isTrue);
        expect(result.actions[1].isInternalCommand, isFalse);
        expect(result.actions[2].isInternalCommand, isFalse);
      });
    });

    // =========================================================================
    // Section 6.5 - Argument Prefixes
    // =========================================================================
    group('Section 6.5 - Argument Prefixes', () {
      test('parses wa- prefix for analyze', () {
        final result = parser.parse(['-wa-verbose=true', ':analyze']);

        expect(result.globalParameters['wa-verbose'], equals('true'));
      });

      test('parses gr- prefix for generate-reflection', () {
        final result = parser.parse(['-gr-path=.', ':generate-reflection']);

        expect(result.globalParameters['gr-path'], equals('.'));
      });

      test('parses mp- prefix for md2pdf', () {
        final result = parser.parse(['-mp-output=./docs', ':md2pdf']);

        expect(result.globalParameters['mp-output'], equals('./docs'));
      });

      test('parses ml- prefix for md2latex', () {
        final result = parser.parse(['-ml-template=article', ':md2latex']);

        expect(result.globalParameters['ml-template'], equals('article'));
      });

      test('parses vb- prefix for version-bump', () {
        final result = parser.parse(['-vb-dry-run=true', ':version-bump']);

        expect(result.globalParameters['vb-dry-run'], equals('true'));
      });

      test('parses wp- prefix for prepper', () {
        final result = parser.parse(['-wp-dry-run=true', ':prepper']);

        expect(result.globalParameters['wp-dry-run'], equals('true'));
      });
    });

    // =========================================================================
    // ParsedArguments Properties
    // =========================================================================
    group('ParsedArguments Properties', () {
      test('targetsAllProjects is true when no scope', () {
        final result = parser.parse([':build']);

        expect(result.targetsAllProjects, isTrue);
      });

      test('targetsAllProjects is false with :projects', () {
        final result = parser.parse([':projects', 'proj', ':build']);

        expect(result.targetsAllProjects, isFalse);
      });

      test('targetsAllProjects is false with :groups', () {
        final result = parser.parse([':groups', 'grp', ':build']);

        expect(result.targetsAllProjects, isFalse);
      });

      test('targets returns projects when using :projects', () {
        final result = parser.parse([':projects', 'a', 'b', ':build']);

        expect(result.targets, equals(['a', 'b']));
      });

      test('targets returns groups when using :groups', () {
        final result = parser.parse([':groups', 'x', 'y', ':build']);

        expect(result.targets, equals(['x', 'y']));
      });
    });

    // =========================================================================
    // ActionInvocation
    // =========================================================================
    group('ActionInvocation', () {
      test('creates action with required fields', () {
        const action = ActionInvocation(name: 'build');

        expect(action.name, equals('build'));
        expect(action.parameters, isEmpty);
        expect(action.isInternalCommand, isFalse);
        expect(action.bypassWorkspaceAction, isFalse);
      });

      test('creates action with all fields', () {
        const action = ActionInvocation(
          name: 'analyze',
          parameters: {'verbose': 'true'},
          isInternalCommand: true,
          bypassWorkspaceAction: false,
        );

        expect(action.name, equals('analyze'));
        expect(action.parameters, equals({'verbose': 'true'}));
        expect(action.isInternalCommand, isTrue);
        expect(action.bypassWorkspaceAction, isFalse);
      });
    });

    // =========================================================================
    // ParsedArgumentsExtensions
    // =========================================================================
    group('ParsedArgumentsExtensions', () {
      test('getActionParameters merges global and action params', () {
        final result = parser.parse([
          '-global=yes',
          ':build',
          '-output=./dist',
        ]);

        final params = result.getActionParameters('build');

        expect(params['global'], equals('yes'));
        expect(params['output'], equals('./dist'));
      });

      test('actionNames returns list of action names', () {
        final result = parser.parse([':build', ':test', ':deploy']);

        expect(result.actionNames, equals(['build', 'test', 'deploy']));
      });

      test('hasInternalCommands returns true when present', () {
        final result = parser.parse([':analyze', ':build']);

        expect(result.hasInternalCommands, isTrue);
      });

      test('hasInternalCommands returns false when none present', () {
        final result = parser.parse([':build', ':test']);

        expect(result.hasInternalCommands, isFalse);
      });
    });

    // =========================================================================
    // Complex Scenarios
    // =========================================================================
    group('Complex Scenarios', () {
      test('full workflow with projects and multiple actions', () {
        final result = parser.parse([
          '-verbose',
          ':projects',
          'tom_core',
          '-env=prod',
          'tom_build',
          ':version-bump',
          ':build',
          '-release=true',
          ':test',
          ':publish',
        ]);

        expect(result.verbose, isTrue);
        expect(result.hasProjectsScope, isTrue);
        expect(result.projects, equals(['tom_core', 'tom_build']));
        expect(result.projectParameters['tom_core']?['env'], equals('prod'));
        expect(result.actions.length, equals(4));
        expect(result.actions[0].name, equals('version-bump'));
        expect(result.actions[1].name, equals('build'));
        expect(result.actions[1].parameters['release'], equals('true'));
        expect(result.actions[2].name, equals('test'));
        expect(result.actions[3].name, equals('publish'));
      });

      test('group workflow with prefixed parameters', () {
        final result = parser.parse([
          '-wa-verbose=true',
          '-gr-path=.',
          ':groups',
          'dart-packages',
          ':analyze',
          ':generate-reflection',
        ]);

        expect(result.hasGroupsScope, isTrue);
        expect(result.groups, equals(['dart-packages']));
        expect(result.globalParameters['wa-verbose'], equals('true'));
        expect(result.globalParameters['gr-path'], equals('.'));
        expect(result.actions.length, equals(2));
      });
    });
  });
}
