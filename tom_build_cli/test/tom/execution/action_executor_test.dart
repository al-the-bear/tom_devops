// Tests for ActionExecutor - Action execution orchestration
//
// Covers tom_tool_specification.md Section 5.4:
// - Phase 3 Execution Flow (5.4.1)
// - Loading master files for actions
// - Resolving [[ENV]] placeholders
// - Processing tomplate files
// - Executing pre-commands, commands, post-commands
// - Action order handling
// - Dry-run mode
// - Error handling

import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/execution/action_executor.dart';
import 'package:tom_build_cli/src/tom/execution/command_runner.dart';

void main() {
  group('ActionExecutor', () {
    late Directory tempDir;
    late String workspacePath;
    late String metadataPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('action_executor_test_');
      workspacePath = tempDir.path;
      metadataPath = '$workspacePath/.tom_metadata';
      Directory(metadataPath).createSync(recursive: true);
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    // Helper to create a master file for testing
    void createMasterFile(String actionName, Map<String, dynamic> content) {
      final file = File('$metadataPath/tom_master_$actionName.yaml');
      final yaml = _toYamlString(content);
      file.writeAsStringSync(yaml);
    }

    // Helper to create a minimal project directory
    void createProject(String name) {
      Directory('$workspacePath/$name').createSync(recursive: true);
    }

    // =========================================================================
    // Section 5.4.1 - ActionExecutorConfig
    // =========================================================================
    group('Section 5.4.1 - ActionExecutorConfig', () {
      test('creates config with required parameters', () {
        final config = ActionExecutorConfig(workspacePath: '/path/to/ws');

        expect(config.workspacePath, equals('/path/to/ws'));
        expect(config.metadataPath, isNull);
        expect(config.verbose, isFalse);
        expect(config.dryRun, isFalse);
        expect(config.environment, isEmpty);
      });

      test('uses default metadata path', () {
        final config = ActionExecutorConfig(workspacePath: '/path/to/ws');

        expect(config.metadataDir, equals('/path/to/ws/.tom_metadata'));
      });

      test('uses custom metadata path when provided', () {
        final config = ActionExecutorConfig(
          workspacePath: '/path/to/ws',
          metadataPath: '/custom/metadata',
        );

        expect(config.metadataDir, equals('/custom/metadata'));
      });

      test('accepts all optional parameters', () {
        final config = ActionExecutorConfig(
          workspacePath: '/path/to/ws',
          metadataPath: '/custom/metadata',
          verbose: true,
          dryRun: true,
          environment: {'KEY': 'value'},
        );

        expect(config.verbose, isTrue);
        expect(config.dryRun, isTrue);
        expect(config.environment, equals({'KEY': 'value'}));
      });
    });

    // =========================================================================
    // Section 5.4.1 - ActionExecutionResult
    // =========================================================================
    group('Section 5.4.1 - ActionExecutionResult', () {
      test('success factory creates correct result', () {
        final commandResults = [
          CommandResult.success(command: 'echo test', stdout: 'test'),
        ];

        final result = ActionExecutionResult.success(
          projectName: 'my_project',
          actionName: 'build',
          commandResults: commandResults,
          duration: const Duration(seconds: 5),
        );

        expect(result.success, isTrue);
        expect(result.projectName, equals('my_project'));
        expect(result.actionName, equals('build'));
        expect(result.commandResults, equals(commandResults));
        expect(result.duration, equals(const Duration(seconds: 5)));
        expect(result.error, isNull);
      });

      test('failure factory creates correct result', () {
        final result = ActionExecutionResult.failure(
          projectName: 'my_project',
          actionName: 'build',
          error: 'Something went wrong',
          duration: const Duration(seconds: 2),
        );

        expect(result.success, isFalse);
        expect(result.projectName, equals('my_project'));
        expect(result.actionName, equals('build'));
        expect(result.error, equals('Something went wrong'));
        expect(result.duration, equals(const Duration(seconds: 2)));
      });

      test('failure result includes command results', () {
        final commandResults = [
          CommandResult.failure(command: 'exit 1', exitCode: 1),
        ];

        final result = ActionExecutionResult.failure(
          projectName: 'my_project',
          actionName: 'build',
          error: 'Command failed',
          commandResults: commandResults,
        );

        expect(result.commandResults, equals(commandResults));
      });
    });

    // =========================================================================
    // Section 5.4.1 - Execution Flow
    // =========================================================================
    group('Section 5.4.1 - Execution Flow', () {
      test('fails when master file not found', () async {
        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'nonexistent',
          projectName: 'my_project',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Master file not found'));
      });

      test('fails when project not found in master file', () async {
        createMasterFile('build', {
          'projects': {
            'other_project': {
              'name': 'other_project',
              'actions': {},
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Project not found'));
      });

      test('fails when action not defined for project', () async {
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {},
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Action not defined'));
      });

      test('succeeds with valid configuration and no commands', () async {
        createProject('my_project');
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'build': {
                  'default': {},
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        expect(result.success, isTrue);
        expect(result.projectName, equals('my_project'));
        expect(result.actionName, equals('build'));
      });
    });

    // =========================================================================
    // Section 5.4.2 - Command Execution
    // =========================================================================
    group('Section 5.4.2 - Command Execution', () {
      test('executes commands in project directory', () async {
        createProject('my_project');
        createMasterFile('test', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'test': {
                  'default': {
                    'commands': ['pwd'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'test',
          projectName: 'my_project',
        );

        expect(result.success, isTrue);
        expect(result.commandResults.length, equals(1));
        // Resolve symlinks for macOS /var -> /private/var
        final expectedPath =
            Directory('$workspacePath/my_project').resolveSymbolicLinksSync();
        expect(result.commandResults[0].stdout.trim(), contains(expectedPath));
      });

      test('executes pre-commands before commands', () async {
        createProject('my_project');
        // Create a file to track execution order
        final orderFile = File('$workspacePath/my_project/order.txt');
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'build': {
                  'default': {
                    'pre-commands': ['echo pre >> order.txt'],
                    'commands': ['echo main >> order.txt'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        final order = orderFile.readAsStringSync().trim().split('\n');
        expect(order, equals(['pre', 'main']));
      });

      test('executes post-commands after commands', () async {
        createProject('my_project');
        final orderFile = File('$workspacePath/my_project/order.txt');
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['echo main >> order.txt'],
                    'post-commands': ['echo post >> order.txt'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        final order = orderFile.readAsStringSync().trim().split('\n');
        expect(order, equals(['main', 'post']));
      });

      test('stops on pre-command failure', () async {
        createProject('my_project');
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'build': {
                  'default': {
                    'pre-commands': ['exit 1'],
                    'commands': ['echo should not run'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Pre-command failed'));
        expect(result.commandResults.length, equals(1));
      });

      test('stops on command failure', () async {
        createProject('my_project');
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['exit 1', 'echo should not run'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        expect(result.success, isFalse);
        expect(result.error, contains('Command failed'));
        expect(result.commandResults.length, equals(1));
      });
    });

    // =========================================================================
    // Section 5.5.2 - Environment Placeholder Resolution
    // =========================================================================
    group('Section 5.5.2 - Environment Placeholder Resolution [[ENV]]', () {
      test('resolves [[ENV]] placeholders in commands', () async {
        createProject('my_project');
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['echo [[MY_VAR]]'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
          environment: {'MY_VAR': 'test_value'},
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        expect(result.success, isTrue);
        expect(result.commandResults[0].stdout.trim(), equals('test_value'));
      });

      test('resolves [[ENV:-default]] with default value', () async {
        createProject('my_project');
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['echo [[MISSING_VAR:-fallback]]'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        expect(result.success, isTrue);
        expect(result.commandResults[0].stdout.trim(), equals('fallback'));
      });

      test('leaves unresolved [[ENV]] if no default', () async {
        createProject('my_project');
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['echo "[[MISSING_VAR]]"'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        expect(result.success, isTrue);
        expect(
            result.commandResults[0].stdout.trim(), equals('[[MISSING_VAR]]'));
      });
    });

    // =========================================================================
    // Dry Run Mode
    // =========================================================================
    group('Dry Run Mode', () {
      test('does not execute commands in dry-run mode', () async {
        createProject('my_project');
        final testFile = File('$workspacePath/my_project/test.txt');
        createMasterFile('build', {
          'projects': {
            'my_project': {
              'name': 'my_project',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['touch test.txt'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
          dryRun: true,
        );
        final executor = ActionExecutor(config: config);

        final result = await executor.executeAction(
          actionName: 'build',
          projectName: 'my_project',
        );

        expect(result.success, isTrue);
        expect(testFile.existsSync(), isFalse);
        expect(result.commandResults[0].stdout, contains('[dry-run]'));
      });
    });

    // =========================================================================
    // executeActionOnProjects
    // =========================================================================
    group('executeActionOnProjects', () {
      test('executes action on multiple projects', () async {
        createProject('project_a');
        createProject('project_b');
        createMasterFile('build', {
          'build-order': ['project_a', 'project_b'],
          'action-order': {
            'build': ['project_a', 'project_b'],
          },
          'projects': {
            'project_a': {
              'name': 'project_a',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['echo a'],
                  },
                },
              },
            },
            'project_b': {
              'name': 'project_b',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['echo b'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final results = await executor.executeActionOnProjects(
          actionName: 'build',
          projectNames: ['project_a', 'project_b'],
        );

        expect(results.length, equals(2));
        expect(results[0].projectName, equals('project_a'));
        expect(results[1].projectName, equals('project_b'));
        expect(results.every((r) => r.success), isTrue);
      });

      test('respects action order from master file', () async {
        createProject('project_a');
        createProject('project_b');
        createProject('project_c');
        createMasterFile('build', {
          'build-order': ['project_c', 'project_a', 'project_b'],
          'projects': {
            'project_a': {
              'name': 'project_a',
              'actions': {
                'build': {'default': {}},
              },
            },
            'project_b': {
              'name': 'project_b',
              'actions': {
                'build': {'default': {}},
              },
            },
            'project_c': {
              'name': 'project_c',
              'actions': {
                'build': {'default': {}},
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final results = await executor.executeActionOnProjects(
          actionName: 'build',
          projectNames: ['project_a', 'project_b', 'project_c'],
        );

        expect(results.length, equals(3));
        // Order should follow build-order: c, a, b
        expect(results[0].projectName, equals('project_c'));
        expect(results[1].projectName, equals('project_a'));
        expect(results[2].projectName, equals('project_b'));
      });

      test('stops on failure when stopOnFailure is true', () async {
        createProject('project_a');
        createProject('project_b');
        createMasterFile('build', {
          'build-order': ['project_a', 'project_b'],
          'projects': {
            'project_a': {
              'name': 'project_a',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['exit 1'],
                  },
                },
              },
            },
            'project_b': {
              'name': 'project_b',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['echo b'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final results = await executor.executeActionOnProjects(
          actionName: 'build',
          projectNames: ['project_a', 'project_b'],
          stopOnFailure: true,
        );

        expect(results.length, equals(1));
        expect(results[0].success, isFalse);
      });

      test('continues on failure when stopOnFailure is false', () async {
        createProject('project_a');
        createProject('project_b');
        createMasterFile('build', {
          'build-order': ['project_a', 'project_b'],
          'projects': {
            'project_a': {
              'name': 'project_a',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['exit 1'],
                  },
                },
              },
            },
            'project_b': {
              'name': 'project_b',
              'actions': {
                'build': {
                  'default': {
                    'commands': ['echo b'],
                  },
                },
              },
            },
          },
        });

        final config = ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
        );
        final executor = ActionExecutor(config: config);

        final results = await executor.executeActionOnProjects(
          actionName: 'build',
          projectNames: ['project_a', 'project_b'],
          stopOnFailure: false,
        );

        expect(results.length, equals(2));
        expect(results[0].success, isFalse);
        expect(results[1].success, isTrue);
      });
    });
  });
}

// =============================================================================
// Helpers
// =============================================================================

/// Converts a map to a YAML string.
String _toYamlString(Map<String, dynamic> map) {
  return _formatValue(map, 0);
}

String _formatValue(dynamic value, int indent) {
  final prefix = '  ' * indent;
  final buffer = StringBuffer();

  if (value is Map) {
    if (value.isEmpty) {
      buffer.write('{}');
    } else {
      for (final entry in value.entries) {
        buffer.writeln();
        buffer.write('$prefix${entry.key}:');
        if (entry.value is Map && (entry.value as Map).isNotEmpty) {
          buffer.write(_formatValue(entry.value, indent + 1));
        } else if (entry.value is List && (entry.value as List).isNotEmpty) {
          buffer.write(_formatValue(entry.value, indent + 1));
        } else if (entry.value is Map && (entry.value as Map).isEmpty) {
          buffer.write(' {}');
        } else if (entry.value == null) {
          buffer.write('');
        } else {
          buffer.write(' ${entry.value}');
        }
      }
    }
  } else if (value is List) {
    for (final item in value) {
      buffer.writeln();
      if (item is Map) {
        buffer.write('$prefix-');
        final mapStr = _formatValue(item, indent + 1);
        buffer.write(mapStr);
      } else {
        buffer.write('$prefix- $item');
      }
    }
  }

  return buffer.toString();
}
