import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/generation/master_generator.dart';
import 'package:tom_build/tom_build.dart';

void main() {
  group('MasterGeneratorConfig', () {
    test('default output path is .tom_metadata', () {
      final config = MasterGeneratorConfig(
        workspacePath: '/workspace',
      );

      expect(config.outputDir, equals('/workspace/.tom_metadata'));
    });

    test('custom output path is respected', () {
      final config = MasterGeneratorConfig(
        workspacePath: '/workspace',
        outputPath: '/custom/output',
      );

      expect(config.outputDir, equals('/custom/output'));
    });

    test('resolvePlaceholders defaults to true', () {
      final config = MasterGeneratorConfig(workspacePath: '/workspace');
      expect(config.resolvePlaceholders, isTrue);
    });

    test('processModeBlocks defaults to true', () {
      final config = MasterGeneratorConfig(workspacePath: '/workspace');
      expect(config.processModeBlocks, isTrue);
    });
  });

  group('MasterGenerationResult', () {
    test('success result has success flag true', () {
      final result = MasterGenerationResult.success(
        {'name': 'test'},
        outputPath: '/path/to/tom_master.yaml',
      );

      expect(result.success, isTrue);
      expect(result.data['name'], equals('test'));
      expect(result.outputPath, equals('/path/to/tom_master.yaml'));
      expect(result.error, isNull);
    });

    test('success result without outputPath', () {
      final result = MasterGenerationResult.success({'key': 'value'});

      expect(result.success, isTrue);
      expect(result.outputPath, isNull);
      expect(result.data, equals({'key': 'value'}));
    });

    test('error result has success flag false', () {
      final result = MasterGenerationResult.error('Something went wrong');

      expect(result.success, isFalse);
      expect(result.error, equals('Something went wrong'));
      expect(result.data, isEmpty);
    });
  });

  group('MasterGenerator', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('master_generator_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // =====================================================================
    // Basic Generation
    // =====================================================================
    group('Basic Generation', () {
      test('generates tom_master with scan timestamp', () {
        final workspace = TomWorkspace(name: 'test_workspace');
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final master = generator.generateMaster();

        expect(master.scanTimestamp, isNotNull);
        // ISO 8601 format
        expect(master.scanTimestamp!, contains('T'));
      });

      test('generates empty build-order for no projects', () {
        final workspace = TomWorkspace(name: 'test_workspace');
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final master = generator.generateMaster();

        expect(master.buildOrder, isEmpty);
      });

      test('includes workspace name in master', () {
        final workspace = TomWorkspace(name: 'test_workspace');
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final master = generator.generateMaster();

        // TomMaster extends TomWorkspace so name is inherited
        expect(master.name, equals('test_workspace'));
      });

      test('preserves project types from workspace', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          projectTypes: {
            'dart-package': ProjectTypeDef(
              name: 'dart-package',
              description: 'A Dart package',
            ),
            'flutter-app': ProjectTypeDef(
              name: 'flutter-app',
              description: 'A Flutter application',
            ),
          },
        );
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final master = generator.generateMaster();

        expect(master.projectTypes.keys, contains('dart-package'));
        expect(master.projectTypes.keys, contains('flutter-app'));
      });
    });

    // =====================================================================
    // Build Order Calculation
    // =====================================================================
    group('Build Order Calculation', () {
      test('calculates build order for independent projects', () {
        final workspace = TomWorkspace(name: 'test_ws');
        final projects = {
          'project_a': TomProject(name: 'project_a', type: 'dart-package'),
          'project_b': TomProject(name: 'project_b', type: 'dart-package'),
          'project_c': TomProject(name: 'project_c', type: 'dart-package'),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();

        expect(
          master.buildOrder,
          containsAll(['project_a', 'project_b', 'project_c']),
        );
        expect(master.buildOrder.length, equals(3));
      });

      test('respects build-after dependencies in order', () {
        final workspace = TomWorkspace(name: 'test_ws');
        final projects = {
          'core': TomProject(name: 'core', type: 'dart-package'),
          'utils': TomProject(
            name: 'utils',
            type: 'dart-package',
            buildAfter: ['core'],
          ),
          'app': TomProject(
            name: 'app',
            type: 'dart-package',
            buildAfter: ['utils', 'core'],
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();

        final coreIdx = master.buildOrder.indexOf('core');
        final utilsIdx = master.buildOrder.indexOf('utils');
        final appIdx = master.buildOrder.indexOf('app');

        expect(coreIdx, lessThan(utilsIdx), reason: 'core must come before utils');
        expect(utilsIdx, lessThan(appIdx), reason: 'utils must come before app');
        expect(coreIdx, lessThan(appIdx), reason: 'core must come before app');
      });

      test('handles diamond dependency pattern', () {
        final workspace = TomWorkspace(name: 'test_ws');
        // Diamond: D -> B, D -> C, B -> A, C -> A
        final projects = {
          'd': TomProject(name: 'd', type: 'dart-package'),
          'b': TomProject(name: 'b', type: 'dart-package', buildAfter: ['d']),
          'c': TomProject(name: 'c', type: 'dart-package', buildAfter: ['d']),
          'a': TomProject(
            name: 'a',
            type: 'dart-package',
            buildAfter: ['b', 'c'],
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();

        final dIdx = master.buildOrder.indexOf('d');
        final bIdx = master.buildOrder.indexOf('b');
        final cIdx = master.buildOrder.indexOf('c');
        final aIdx = master.buildOrder.indexOf('a');

        expect(dIdx, lessThan(bIdx));
        expect(dIdx, lessThan(cIdx));
        expect(bIdx, lessThan(aIdx));
        expect(cIdx, lessThan(aIdx));
      });
    });

    // =====================================================================
    // Action-Specific Master Generation
    // =====================================================================
    group('Action-Specific Master', () {
      test('generates master for specific action', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          actions: {
            'build': ActionDef(name: 'build', description: 'Build'),
          },
        );
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final master = generator.generateActionMaster('build');

        expect(master.scanTimestamp, isNotNull);
        expect(master.actions.keys, contains('build'));
      });

      test('action master calculates action-specific order', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          actions: {
            'deploy': ActionDef(name: 'deploy', description: 'Deploy'),
          },
        );
        final projects = {
          'frontend': TomProject(
            name: 'frontend',
            type: 'flutter-app',
            actionOrder: {'deploy-after': ['backend']},
          ),
          'backend': TomProject(name: 'backend', type: 'dart-server'),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateActionMaster('deploy');
        final deployOrder = master.actionOrder['deploy'];

        expect(deployOrder, isNotNull);
        if (deployOrder != null) {
          final backendIdx = deployOrder.indexOf('backend');
          final frontendIdx = deployOrder.indexOf('frontend');
          expect(backendIdx, lessThan(frontendIdx));
        }
      });
    });

    // =====================================================================
    // Project Processing
    // =====================================================================
    group('Project Processing', () {
      test('includes all projects in master', () {
        final workspace = TomWorkspace(name: 'test_ws');
        final projects = {
          'lib_a': TomProject(name: 'lib_a', type: 'dart-package'),
          'lib_b': TomProject(name: 'lib_b', type: 'dart-package'),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();

        expect(master.projects.keys, contains('lib_a'));
        expect(master.projects.keys, contains('lib_b'));
      });

      test('preserves project features', () {
        final workspace = TomWorkspace(name: 'test_ws');
        final projects = {
          'my_lib': TomProject(
            name: 'my_lib',
            type: 'dart-package',
            features: Features(
              flags: {
                'publishable': true,
                'has-tests': true,
                'has-examples': true,
              },
            ),
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();

        final project = master.projects['my_lib'];
        expect(project, isNotNull);
        expect(project!.features?['publishable'], isTrue);
        expect(project.features?['has-tests'], isTrue);
        expect(project.features?['has-examples'], isTrue);
      });
    });

    // =====================================================================
    // Action Orders
    // =====================================================================
    group('Action Orders', () {
      test('calculates action orders for multiple actions', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          actions: {
            'build': ActionDef(name: 'build', description: 'Build'),
            'test': ActionDef(name: 'test', description: 'Test'),
          },
        );
        final projects = {
          'core': TomProject(name: 'core', type: 'dart-package'),
          'lib': TomProject(
            name: 'lib',
            type: 'dart-package',
            actionOrder: {'build-after': ['core']},
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();

        expect(master.actionOrder.keys, contains('build'));
        expect(master.actionOrder.keys, contains('test'));
      });

      test('action-specific order differs from build order', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          actions: {
            'deploy': ActionDef(name: 'deploy', description: 'Deploy'),
          },
        );
        // Build order: a, b (no deps)
        // Deploy order: b before a (action-specific)
        final projects = {
          'a': TomProject(
            name: 'a',
            type: 'dart-package',
            actionOrder: {'deploy-after': ['b']},
          ),
          'b': TomProject(name: 'b', type: 'dart-package'),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();

        final deployOrder = master.actionOrder['deploy'];
        expect(deployOrder, isNotNull);
        if (deployOrder != null) {
          final bIdx = deployOrder.indexOf('b');
          final aIdx = deployOrder.indexOf('a');
          expect(
            bIdx,
            lessThan(aIdx),
            reason: 'b should come before a in deploy order',
          );
        }
      });
    });

    // =====================================================================
    // File Writing
    // =====================================================================
    group('File Writing', () {
      test('writes tom_master.yaml to output path', () {
        final workspace = TomWorkspace(name: 'file_test');
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final result = generator.generateAndWriteMaster();

        expect(result.success, isTrue);
        expect(result.outputPath, isNotNull);
        expect(File(result.outputPath!).existsSync(), isTrue);
      });

      test('writes action-specific master file', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          actions: {
            'build': ActionDef(name: 'build', description: 'Build'),
          },
        );
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final result = generator.generateAndWriteActionMaster('build');

        expect(result.success, isTrue);
        expect(result.outputPath, isNotNull);
        expect(result.outputPath!, endsWith('tom_master_build.yaml'));
        expect(File(result.outputPath!).existsSync(), isTrue);
      });

      test('generates all action masters', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          actions: {
            'build': ActionDef(name: 'build', description: 'Build'),
            'test': ActionDef(name: 'test', description: 'Test'),
            'deploy': ActionDef(name: 'deploy', description: 'Deploy'),
          },
        );
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final results = generator.generateAndWriteAllActionMasters();

        expect(results.length, equals(3));
        expect(results.every((r) => r.success), isTrue);
      });

      test('creates output directory if not exists', () {
        final outputPath = '${tempDir.path}/nested/output';
        final workspace = TomWorkspace(name: 'test_ws');
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: outputPath,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        generator.generateAndWriteMaster();

        expect(Directory(outputPath).existsSync(), isTrue);
      });
    });

    // =====================================================================
    // Custom Tags Preservation
    // =====================================================================
    group('Custom Tags', () {
      test('preserves workspace custom tags', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          customTags: {
            'my_custom': 'value',
            'nested': {'a': 1, 'b': 2},
          },
        );
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final master = generator.generateMaster();

        expect(master.customTags['my_custom'], equals('value'));
        expect(master.customTags['nested'], equals({'a': 1, 'b': 2}));
      });

      test('preserves project custom tags', () {
        final workspace = TomWorkspace(name: 'test_ws');
        final projects = {
          'my_lib': TomProject(
            name: 'my_lib',
            type: 'dart-package',
            customTags: {
              'custom_field': 'project_value',
              'settings': {'enabled': true},
            },
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();
        final project = master.projects['my_lib'];

        expect(project, isNotNull);
        expect(project!.customTags['custom_field'], equals('project_value'));
        expect(project.customTags['settings'], equals({'enabled': true}));
      });
    });

    // =====================================================================
    // Groups Preservation
    // =====================================================================
    group('Groups', () {
      test('preserves group definitions', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          groups: {
            'core': GroupDef(
              name: 'core',
              description: 'Core libraries',
              projects: ['lib_a', 'lib_b'],
            ),
          },
        );
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final master = generator.generateMaster();

        expect(master.groups.keys, contains('core'));
        expect(master.groups['core']!.projects, equals(['lib_a', 'lib_b']));
      });
    });

    // =====================================================================
    // Pipelines Preservation
    // =====================================================================
    group('Pipelines', () {
      test('preserves pipeline definitions', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          pipelines: {
            'ci': Pipeline(
              name: 'ci',
              globalParameters: ['--verbose'],
            ),
          },
        );
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final master = generator.generateMaster();

        expect(master.pipelines.keys, contains('ci'));
        expect(
          master.pipelines['ci']!.globalParameters,
          contains('--verbose'),
        );
      });
    });

    // =====================================================================
    // Edge Cases
    // =====================================================================
    group('Edge Cases', () {
      test('handles workspace with no actions', () {
        final workspace = TomWorkspace(name: 'minimal');
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: {},
          config: config,
        );

        final results = generator.generateAndWriteAllActionMasters();

        expect(results, isEmpty);
      });

      test('handles project with empty build-after', () {
        final workspace = TomWorkspace(name: 'test_ws');
        final projects = {
          'standalone': TomProject(
            name: 'standalone',
            type: 'dart-package',
            buildAfter: [],
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();

        expect(master.buildOrder, contains('standalone'));
      });

      test('handles circular dependencies gracefully', () {
        final workspace = TomWorkspace(name: 'test_ws');
        // Circular: a -> b -> c -> a
        final projects = {
          'a': TomProject(
            name: 'a',
            type: 'dart-package',
            buildAfter: ['c'],
          ),
          'b': TomProject(
            name: 'b',
            type: 'dart-package',
            buildAfter: ['a'],
          ),
          'c': TomProject(
            name: 'c',
            type: 'dart-package',
            buildAfter: ['b'],
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        // Should not throw, falls back to alphabetical
        final master = generator.generateMaster();

        expect(master.buildOrder.length, equals(3));
        expect(master.buildOrder, containsAll(['a', 'b', 'c']));
      });

      test('handles missing dependencies in build-after', () {
        final workspace = TomWorkspace(name: 'test_ws');
        final projects = {
          'lib': TomProject(
            name: 'lib',
            type: 'dart-package',
            buildAfter: ['nonexistent'],
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        // Should not throw
        final master = generator.generateMaster();

        expect(master.buildOrder, contains('lib'));
      });
    });

    // =====================================================================
    // Compact Output - Omit Identical Sections
    // =====================================================================
    group('Compact Output', () {
      test('omits cross-compilation from project when identical to workspace', () {
        final crossComp = CrossCompilation(
          allTargets: ['darwin-x64', 'linux-x64'],
        );
        final workspace = TomWorkspace(
          name: 'test_ws',
          crossCompilation: crossComp,
        );
        final projects = {
          'lib': TomProject(
            name: 'lib',
            type: 'dart-package',
            crossCompilation: crossComp, // Same as workspace
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();
        final projectYaml = master.toYaml()['projects']['lib'] as Map;

        // cross-compilation should be omitted since it's identical
        expect(projectYaml.containsKey('cross-compilation'), isFalse);
      });

      test('includes cross-compilation in project when different from workspace', () {
        final workspaceCrossComp = CrossCompilation(
          allTargets: ['darwin-x64', 'linux-x64'],
        );
        final projectCrossComp = CrossCompilation(
          allTargets: ['win32-x64'], // Different
        );
        final workspace = TomWorkspace(
          name: 'test_ws',
          crossCompilation: workspaceCrossComp,
        );
        final projects = {
          'lib': TomProject(
            name: 'lib',
            type: 'dart-package',
            crossCompilation: projectCrossComp,
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();
        final projectYaml = master.toYaml()['projects']['lib'] as Map;

        // cross-compilation should be included since it's different
        expect(projectYaml.containsKey('cross-compilation'), isTrue);
      });

      test('omits mode-definitions from project when identical to workspace', () {
        final modeDefs = ModeDefinitions(
          definitions: {
            'dev': ModeDef(name: 'dev', description: 'Development'),
            'prod': ModeDef(name: 'prod', description: 'Production'),
          },
        );
        final workspace = TomWorkspace(
          name: 'test_ws',
          modeDefinitions: {'environment': modeDefs},
        );
        final projects = {
          'lib': TomProject(
            name: 'lib',
            type: 'dart-package',
            modeDefinitions: {'environment': modeDefs}, // Same
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();
        final projectYaml = master.toYaml()['projects']['lib'] as Map;

        // environment-mode-definitions should be omitted
        expect(
          projectYaml.containsKey('environment-mode-definitions'),
          isFalse,
        );
      });

      test('includes mode-definitions in project when different from workspace', () {
        final workspaceModeDefs = ModeDefinitions(
          definitions: {
            'dev': ModeDef(name: 'dev', description: 'Development'),
          },
        );
        final projectModeDefs = ModeDefinitions(
          definitions: {
            'dev': ModeDef(name: 'dev', description: 'Dev - custom'), // Different
          },
        );
        final workspace = TomWorkspace(
          name: 'test_ws',
          modeDefinitions: {'environment': workspaceModeDefs},
        );
        final projects = {
          'lib': TomProject(
            name: 'lib',
            type: 'dart-package',
            modeDefinitions: {'environment': projectModeDefs},
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();
        final projectYaml = master.toYaml()['projects']['lib'] as Map;

        // environment-mode-definitions should be included
        expect(
          projectYaml.containsKey('environment-mode-definitions'),
          isTrue,
        );
      });

      test('omits actions from project when identical to workspace', () {
        final actions = {
          'build': ActionDef(
            name: 'build',
            defaultConfig: ActionConfig(commands: ['dart build']),
          ),
        };
        final workspace = TomWorkspace(
          name: 'test_ws',
          actions: actions,
        );
        final projects = {
          'lib': TomProject(
            name: 'lib',
            type: 'dart-package',
            actions: actions, // Same
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();
        final projectYaml = master.toYaml()['projects']['lib'] as Map;

        // actions should be omitted
        expect(projectYaml.containsKey('actions'), isFalse);
      });

      test('includes actions in project when different from workspace', () {
        final workspaceActions = {
          'build': ActionDef(
            name: 'build',
            defaultConfig: ActionConfig(commands: ['dart build']),
          ),
        };
        final projectActions = {
          'build': ActionDef(
            name: 'build',
            defaultConfig: ActionConfig(commands: ['dart build --release']), // Different
          ),
        };
        final workspace = TomWorkspace(
          name: 'test_ws',
          actions: workspaceActions,
        );
        final projects = {
          'lib': TomProject(
            name: 'lib',
            type: 'dart-package',
            actions: projectActions,
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();
        final projectYaml = master.toYaml()['projects']['lib'] as Map;

        // actions should be included
        expect(projectYaml.containsKey('actions'), isTrue);
      });

      test('preserves project fields unrelated to workspace', () {
        final workspace = TomWorkspace(
          name: 'test_ws',
          crossCompilation: CrossCompilation(allTargets: ['linux-x64']),
        );
        final projects = {
          'lib': TomProject(
            name: 'lib',
            type: 'dart-package',
            features: Features(flags: {'publishable': true}),
            crossCompilation: CrossCompilation(allTargets: ['linux-x64']), // Same
          ),
        };
        final config = MasterGeneratorConfig(
          workspacePath: tempDir.path,
          outputPath: tempDir.path,
        );
        final generator = MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );

        final master = generator.generateMaster();
        final projectYaml = master.toYaml()['projects']['lib'] as Map;

        // features should still be present
        expect(projectYaml.containsKey('features'), isTrue);
        // cross-compilation should be omitted (identical)
        expect(projectYaml.containsKey('cross-compilation'), isFalse);
      });
    });
  });
}
