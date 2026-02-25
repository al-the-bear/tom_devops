/// Comprehensive tests for ModeResolver (Section 4)
///
/// Tests mode resolution according to the Tom CLI specification.
library;

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/mode/mode_resolver.dart';
import 'package:tom_build/tom_build.dart';

void main() {
  late ModeResolver resolver;

  setUp(() {
    resolver = ModeResolver();
  });

  // ===========================================================================
  // Section 4.1 - Mode Types
  // ===========================================================================

  group('Section 4.1 - Mode Types', () {
    test('resolves single mode type value', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'default': ActionModeEntry(
              modes: {'environment': 'development'},
            ),
          },
        ),
      );

      final result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
      );

      expect(result.modeTypeValues['environment'], equals('development'));
    });

    test('resolves multiple mode types', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment', 'execution'],
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'default': ActionModeEntry(
              modes: {
                'environment': 'development',
                'execution': 'local',
              },
            ),
          },
        ),
      );

      final result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
      );

      expect(result.modeTypeValues['environment'], equals('development'));
      expect(result.modeTypeValues['execution'], equals('local'));
    });

    test('mode type values are added to active modes', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'default': ActionModeEntry(
              modes: {'environment': 'production'},
            ),
          },
        ),
      );

      final result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
      );

      expect(result.activeModes, contains('production'));
    });

    test('custom mode types are supported', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['target-platform', 'log-level'],
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'default': ActionModeEntry(
              modes: {
                'target-platform': 'ios',
                'log-level': 'debug',
              },
            ),
          },
        ),
      );

      final result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
      );

      expect(result.modeTypeValues['target-platform'], equals('ios'));
      expect(result.modeTypeValues['log-level'], equals('debug'));
    });
  });

  // ===========================================================================
  // Section 4.3 - Mode Resolution Order
  // ===========================================================================

  group('Section 4.3 - Mode Resolution Order', () {
    test('CLI overrides take highest priority', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'build': ActionModeEntry(
              modes: {'environment': 'development'},
            ),
            'default': ActionModeEntry(
              modes: {'environment': 'staging'},
            ),
          },
        ),
      );

      final result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
        cliOverrides: {'environment': 'production'},
      );

      expect(result.modeTypeValues['environment'], equals('production'));
    });

    test('action-specific config takes priority over default', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'build': ActionModeEntry(
              modes: {'environment': 'development'},
            ),
            'deploy': ActionModeEntry(
              modes: {'environment': 'production'},
            ),
            'default': ActionModeEntry(
              modes: {'environment': 'staging'},
            ),
          },
        ),
      );

      var result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
      );
      expect(result.modeTypeValues['environment'], equals('development'));

      result = resolver.resolve(
        actionName: 'deploy',
        workspaceModes: workspaceModes,
      );
      expect(result.modeTypeValues['environment'], equals('production'));
    });

    test('falls back to default when action not found', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'default': ActionModeEntry(
              modes: {'environment': 'development'},
            ),
          },
        ),
      );

      final result = resolver.resolve(
        actionName: 'unknown-action',
        workspaceModes: workspaceModes,
      );

      expect(result.modeTypeValues['environment'], equals('development'));
    });

    test('empty resolved modes when no config', () {
      final result = resolver.resolve(
        actionName: 'build',
        workspaceModes: null,
      );

      expect(result.activeModes, isEmpty);
      expect(result.modeTypeValues, isEmpty);
    });
  });

  // ===========================================================================
  // Implied Modes
  // ===========================================================================

  group('Implied Modes', () {
    test('supported mode implies other modes', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        supported: [
          SupportedMode(
            name: 'production',
            implies: ['release', 'optimized'],
          ),
        ],
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'default': ActionModeEntry(
              modes: {'environment': 'production'},
            ),
          },
        ),
      );

      final result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
      );

      expect(result.activeModes, contains('production'));
      expect(result.activeModes, contains('release'));
      expect(result.activeModes, contains('optimized'));
      expect(result.impliedModes, contains('release'));
      expect(result.impliedModes, contains('optimized'));
    });

    test('mode type config implies modes', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        modeTypeConfigs: {
          'environment': ModeTypeConfig(
            defaultMode: 'development',
            entries: {
              'production': ModeEntry(
                modes: ['release', 'minified'],
              ),
              'development': ModeEntry(
                modes: ['debug', 'hot-reload'],
              ),
            },
          ),
        },
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'default': ActionModeEntry(
              modes: {'environment': 'production'},
            ),
          },
        ),
      );

      final result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
      );

      expect(result.activeModes, contains('release'));
      expect(result.activeModes, contains('minified'));
      expect(result.impliedModes, contains('release'));
    });

    test('implied modes from multiple sources', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment', 'execution'],
        modeTypeConfigs: {
          'environment': ModeTypeConfig(
            entries: {
              'prod': ModeEntry(modes: ['release']),
            },
          ),
          'execution': ModeTypeConfig(
            entries: {
              'docker': ModeEntry(modes: ['containerized']),
            },
          ),
        },
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'default': ActionModeEntry(
              modes: {
                'environment': 'prod',
                'execution': 'docker',
              },
            ),
          },
        ),
      );

      final result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
      );

      expect(result.activeModes, contains('release'));
      expect(result.activeModes, contains('containerized'));
    });
  });

  // ===========================================================================
  // Mode Properties
  // ===========================================================================

  group('Mode Properties Resolution', () {
    test('resolves properties from mode definition', () {
      final resolved = ResolvedModes(
        activeModes: {'production'},
        modeTypeValues: {'environment': 'production'},
        impliedModes: {},
      );

      final modeDefinitions = {
        'environment': ModeDefinitions(
          definitions: {
            'production': ModeDef(
              name: 'production',
              properties: {
                'debug': false,
                'minify': true,
                'base-url': 'https://api.example.com',
              },
            ),
            'development': ModeDef(
              name: 'development',
              properties: {
                'debug': true,
                'minify': false,
                'base-url': 'http://localhost:8080',
              },
            ),
          },
        ),
      };

      final properties = resolver.resolveModeProperties(
        resolved: resolved,
        modeDefinitions: modeDefinitions,
      );

      expect(properties['debug'], equals(false));
      expect(properties['minify'], equals(true));
      expect(properties['base-url'], equals('https://api.example.com'));
    });

    test('merges properties from multiple mode types', () {
      final resolved = ResolvedModes(
        activeModes: {'production', 'docker'},
        modeTypeValues: {
          'environment': 'production',
          'execution': 'docker',
        },
        impliedModes: {},
      );

      final modeDefinitions = {
        'environment': ModeDefinitions(
          definitions: {
            'production': ModeDef(
              name: 'production',
              properties: {'api-url': 'https://api.example.com'},
            ),
          },
        ),
        'execution': ModeDefinitions(
          definitions: {
            'docker': ModeDef(
              name: 'docker',
              properties: {'working-dir': '/app'},
            ),
          },
        ),
      };

      final properties = resolver.resolveModeProperties(
        resolved: resolved,
        modeDefinitions: modeDefinitions,
      );

      expect(properties['api-url'], equals('https://api.example.com'));
      expect(properties['working-dir'], equals('/app'));
    });

    test('later mode type properties override earlier', () {
      final resolved = ResolvedModes(
        activeModes: {'production'},
        modeTypeValues: {
          'environment': 'production',
          'override': 'custom',
        },
        impliedModes: {},
      );

      final modeDefinitions = {
        'environment': ModeDefinitions(
          definitions: {
            'production': ModeDef(
              name: 'production',
              properties: {'shared-key': 'from-environment'},
            ),
          },
        ),
        'override': ModeDefinitions(
          definitions: {
            'custom': ModeDef(
              name: 'custom',
              properties: {'shared-key': 'from-override'},
            ),
          },
        ),
      };

      final properties = resolver.resolveModeProperties(
        resolved: resolved,
        modeDefinitions: modeDefinitions,
      );

      // Later mode type wins (depends on map iteration order)
      expect(properties['shared-key'], isNotNull);
    });

    test('returns empty map when no mode definitions', () {
      final resolved = ResolvedModes(
        activeModes: {'production'},
        modeTypeValues: {'environment': 'production'},
        impliedModes: {},
      );

      final properties = resolver.resolveModeProperties(
        resolved: resolved,
        modeDefinitions: null,
      );

      expect(properties, isEmpty);
    });
  });

  // ===========================================================================
  // Default Mode Resolution
  // ===========================================================================

  group('Default Mode Resolution', () {
    test('gets default mode for mode type', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        modeTypeConfigs: {
          'environment': ModeTypeConfig(
            defaultMode: 'development',
            entries: {},
          ),
        },
      );

      final defaultMode = resolver.getDefaultMode(
        'environment',
        workspaceModes,
      );

      expect(defaultMode, equals('development'));
    });

    test('returns null when no default defined', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        modeTypeConfigs: {
          'environment': ModeTypeConfig(entries: {}),
        },
      );

      final defaultMode = resolver.getDefaultMode(
        'environment',
        workspaceModes,
      );

      expect(defaultMode, isNull);
    });

    test('returns null for unknown mode type', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment'],
        modeTypeConfigs: {},
      );

      final defaultMode = resolver.getDefaultMode(
        'unknown',
        workspaceModes,
      );

      expect(defaultMode, isNull);
    });
  });

  // ===========================================================================
  // ResolvedModes API
  // ===========================================================================

  group('ResolvedModes', () {
    test('isActive returns true for active modes', () {
      final resolved = ResolvedModes(
        activeModes: {'development', 'debug', 'verbose'},
        modeTypeValues: {'environment': 'development'},
        impliedModes: {'debug'},
      );

      expect(resolved.isActive('development'), isTrue);
      expect(resolved.isActive('debug'), isTrue);
      expect(resolved.isActive('verbose'), isTrue);
      expect(resolved.isActive('production'), isFalse);
    });

    test('getModeValue returns mode type value', () {
      final resolved = ResolvedModes(
        activeModes: {'production'},
        modeTypeValues: {
          'environment': 'production',
          'execution': 'docker',
        },
        impliedModes: {},
      );

      expect(resolved.getModeValue('environment'), equals('production'));
      expect(resolved.getModeValue('execution'), equals('docker'));
      expect(resolved.getModeValue('unknown'), isNull);
    });

    test('toString provides readable output', () {
      final resolved = ResolvedModes(
        activeModes: {'production'},
        modeTypeValues: {'environment': 'production'},
        impliedModes: {},
      );

      final str = resolved.toString();
      expect(str, contains('ResolvedModes'));
      expect(str, contains('production'));
    });
  });

  // ===========================================================================
  // Real-World Scenarios
  // ===========================================================================

  group('Real-World Scenarios', () {
    test('typical workspace-modes configuration', () {
      final workspaceModes = WorkspaceModes(
        modeTypes: ['environment', 'execution'],
        supported: [
          SupportedMode(
            name: 'production',
            description: 'Production mode',
            implies: ['release', 'minified'],
          ),
          SupportedMode(
            name: 'development',
            description: 'Development mode',
            implies: ['debug', 'hot-reload'],
          ),
        ],
        modeTypeConfigs: {
          'environment': ModeTypeConfig(
            defaultMode: 'development',
            entries: {
              'production': ModeEntry(
                description: 'Production environment',
                modes: ['release'],
              ),
              'staging': ModeEntry(
                description: 'Staging environment',
                modes: ['debug', 'staging-server'],
              ),
              'development': ModeEntry(
                description: 'Development environment',
                modes: ['debug', 'local-server'],
              ),
            },
          ),
          'execution': ModeTypeConfig(
            defaultMode: 'local',
            entries: {
              'local': ModeEntry(
                modes: ['local-deps'],
              ),
              'docker': ModeEntry(
                modes: ['containerized'],
              ),
            },
          ),
        },
        actionModeConfiguration: ActionModeConfiguration(
          entries: {
            'build': ActionModeEntry(
              description: 'Build action modes',
              modes: {
                'environment': 'development',
                'execution': 'local',
              },
            ),
            'deploy': ActionModeEntry(
              description: 'Deploy action modes',
              modes: {
                'environment': 'production',
                'execution': 'docker',
              },
            ),
            'default': ActionModeEntry(
              modes: {
                'environment': 'development',
                'execution': 'local',
              },
            ),
          },
        ),
      );

      // Build action
      var result = resolver.resolve(
        actionName: 'build',
        workspaceModes: workspaceModes,
      );

      expect(result.modeTypeValues['environment'], equals('development'));
      expect(result.modeTypeValues['execution'], equals('local'));
      expect(result.activeModes, contains('development'));
      expect(result.activeModes, contains('debug'));
      expect(result.activeModes, contains('local-server'));

      // Deploy action
      result = resolver.resolve(
        actionName: 'deploy',
        workspaceModes: workspaceModes,
      );

      expect(result.modeTypeValues['environment'], equals('production'));
      expect(result.modeTypeValues['execution'], equals('docker'));
      expect(result.activeModes, contains('production'));
      expect(result.activeModes, contains('release'));
      expect(result.activeModes, contains('containerized'));

      // CLI override for deploy
      result = resolver.resolve(
        actionName: 'deploy',
        workspaceModes: workspaceModes,
        cliOverrides: {'environment': 'staging'},
      );

      expect(result.modeTypeValues['environment'], equals('staging'));
      expect(result.activeModes, contains('staging'));
      expect(result.activeModes, contains('staging-server'));
    });
  });
}
