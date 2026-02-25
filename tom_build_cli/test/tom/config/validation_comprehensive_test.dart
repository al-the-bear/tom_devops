/// Comprehensive tests for ConfigValidator (Section 9)
///
/// Tests validation of workspace and project configurations according to
/// the Tom CLI specification error handling requirements.
library;

import 'package:test/test.dart';
import 'package:tom_build_cli/src/tom/config/validation.dart';
import 'package:tom_build/tom_build.dart';

void main() {
  late ConfigValidator validator;

  setUp(() {
    validator = ConfigValidator();
  });

  // ===========================================================================
  // Section 9.2 - Validation Errors
  // ===========================================================================

  group('Section 9.2 - Validation Errors', () {
    group('Missing required sections', () {
      test('fails when actions section is empty', () {
        final workspace = TomWorkspace.fromYaml({
          'actions': <String, dynamic>{},
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        expect(result.isValid, isFalse);
        expect(result.errors, hasLength(1));
        expect(
          result.errors[0].message,
          contains('Missing required block [actions:]'),
        );
      });

      test('error includes file path', () {
        final workspace = TomWorkspace.fromYaml({
          'actions': <String, dynamic>{},
        });

        final result = validator.validateWorkspace(
          workspace,
          '/path/to/tom_workspace.yaml',
        );

        expect(result.errors[0].filePath, equals('/path/to/tom_workspace.yaml'));
      });

      test('error includes resolution message', () {
        final workspace = TomWorkspace.fromYaml({
          'actions': <String, dynamic>{},
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        expect(
          result.errors[0].resolution,
          contains('Add an actions: section'),
        );
      });
    });

    group('Action default validation', () {
      test('fails when action missing default configuration', () {
        final workspace = TomWorkspace.fromYaml({
          'actions': {
            'build': {
              'dart_package': {
                'commands': ['dart compile exe'],
              },
            },
          },
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) => e.message.contains('[build]') &&
                e.message.contains('[default:]'),
          ),
          isTrue,
        );
      });

      test('passes when action has default configuration', () {
        final workspace = TomWorkspace.fromYaml({
          'actions': {
            'build': {
              'default': {
                'commands': ['dart compile exe'],
              },
            },
          },
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        expect(result.isValid, isTrue);
      });

      test('validates all actions for default', () {
        final workspace = TomWorkspace.fromYaml({
          'actions': {
            'build': {
              'default': {
                'commands': ['dart compile exe'],
              },
            },
            'test': {
              // Missing default!
              'dart_package': {
                'commands': ['dart test'],
              },
            },
            'deploy': {
              // Missing default!
            },
          },
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThanOrEqualTo(2));
        expect(
          result.errors.any((e) => e.message.contains('[test]')),
          isTrue,
        );
        expect(
          result.errors.any((e) => e.message.contains('[deploy]')),
          isTrue,
        );
      });
    });

    group('action-mode-configuration validation', () {
      test('fails when action-mode-configuration references undefined action', () {
        final workspace = TomWorkspace.fromYaml({
          'workspace-modes': {
            'mode-types': ['environment'],
            'action-mode-configuration': {
              'default': {
                'environment': 'local',
              },
              'build': {
                'environment': 'local',
              },
              'deploy': {
                'environment': 'prod',
              },
            },
          },
          'actions': {
            'build': {
              'default': {
                'commands': ['dart compile exe'],
              },
            },
            // Missing 'deploy' action!
          },
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.message.contains('[deploy]') &&
                e.message.contains('action-mode-configuration'),
          ),
          isTrue,
        );
      });

      test('ignores default entry in action-mode-configuration', () {
        final workspace = TomWorkspace.fromYaml({
          'workspace-modes': {
            'mode-types': ['environment'],
            'action-mode-configuration': {
              'default': {
                'environment': 'local',
              },
            },
          },
          'actions': {
            'build': {
              'default': {
                'commands': ['dart compile exe'],
              },
            },
          },
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        // Should not complain about 'default' not being an action
        expect(result.isValid, isTrue);
      });
    });

    group('Cross-compilation validation', () {
      test('fails when build-on key not in all-targets', () {
        final workspace = TomWorkspace.fromYaml({
          'cross-compilation': {
            'all-targets': ['linux-x64', 'darwin-arm64'],
            'build-on': {
              'win32-x64': {
                'targets': ['win32-x64'],
              },
            },
          },
          'actions': {
            'build': {
              'default': {
                'commands': ['dart compile exe'],
              },
            },
          },
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        expect(result.isValid, isFalse);
        expect(
          result.errors.any(
            (e) =>
                e.message.contains('win32-x64') &&
                e.message.contains('all-targets'),
          ),
          isTrue,
        );
      });

      test('fails when build-on target not in all-targets', () {
        final workspace = TomWorkspace.fromYaml({
          'cross-compilation': {
            'all-targets': ['linux-x64'],
            'build-on': {
              'linux-x64': {
                'targets': ['linux-x64', 'linux-arm64'],
              },
            },
          },
          'actions': {
            'build': {
              'default': {
                'commands': ['dart compile exe'],
              },
            },
          },
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        expect(result.isValid, isFalse);
        expect(
          result.errors.any((e) => e.message.contains('linux-arm64')),
          isTrue,
        );
      });

      test('passes when all build-on entries in all-targets', () {
        final workspace = TomWorkspace.fromYaml({
          'cross-compilation': {
            'all-targets': ['linux-x64', 'linux-arm64', 'darwin-arm64'],
            'build-on': {
              'linux-x64': {
                'targets': ['linux-x64', 'linux-arm64'],
              },
              'darwin-arm64': {
                'targets': ['darwin-arm64'],
              },
            },
          },
          'actions': {
            'build': {
              'default': {
                'commands': ['dart compile exe'],
              },
            },
          },
        });

        final result = validator.validateWorkspace(
          workspace,
          'tom_workspace.yaml',
        );

        expect(result.isValid, isTrue);
      });
    });
  });

  // ===========================================================================
  // Section 3.2.5 - Skip/Applies-to Conflict
  // ===========================================================================

  group('Section 3.2.5 - Skip/Applies-to Conflict', () {
    test('fails when action uses both skip and applies-to', () {
      final workspace = TomWorkspace.fromYaml({
        'actions': {
          'build': {
            'skip-types': ['dart_package'],
            'applies-to-types': ['dart_cli'],
            'default': {
              'commands': ['dart compile exe'],
            },
          },
        },
      });

      // TODO: Implement skip/applies-to conflict validation
      // For now, just verify the action was parsed
      expect(workspace.actions['build'], isNotNull);
    },
    skip: 'Skip/applies-to conflict validation not yet implemented',
    );

    test('passes when action uses only skip', () {
      final workspace = TomWorkspace.fromYaml({
        'actions': {
          'build': {
            'skip-types': ['dart_package'],
            'default': {
              'commands': ['dart compile exe'],
            },
          },
        },
      });

      final result = validator.validateWorkspace(
        workspace,
        'tom_workspace.yaml',
      );

      expect(result.isValid, isTrue);
    });

    test('passes when action uses only applies-to', () {
      final workspace = TomWorkspace.fromYaml({
        'actions': {
          'build': {
            'applies-to-types': ['dart_cli'],
            'default': {
              'commands': ['dart compile exe'],
            },
          },
        },
      });

      final result = validator.validateWorkspace(
        workspace,
        'tom_workspace.yaml',
      );

      expect(result.isValid, isTrue);
    });

    test('passes when action uses neither skip nor applies-to', () {
      final workspace = TomWorkspace.fromYaml({
        'actions': {
          'build': {
            'default': {
              'commands': ['dart compile exe'],
            },
          },
        },
      });

      final result = validator.validateWorkspace(
        workspace,
        'tom_workspace.yaml',
      );

      expect(result.isValid, isTrue);
    });
  });

  // ===========================================================================
  // Project Validation
  // ===========================================================================

  group('Project Validation', () {
    test('validates project cross-compilation references', () {
      final project = TomProject.fromYaml('test_project', {
        'type': 'dart_cli',
        'cross-compilation': {
          'all-targets': ['linux-x64'],
          'build-on': {
            'darwin-arm64': {
              'targets': ['darwin-arm64'],
            },
          },
        },
      });

      final result = validator.validateProject(
        project,
        'tom_project.yaml',
      );

      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.message.contains('darwin-arm64')),
        isTrue,
      );
    });

    test('passes when project cross-compilation is valid', () {
      final project = TomProject.fromYaml('test_project', {
        'type': 'dart_cli',
        'cross-compilation': {
          'all-targets': ['linux-x64', 'darwin-arm64'],
          'build-on': {
            'linux-x64': {
              'targets': ['linux-x64'],
            },
            'darwin-arm64': {
              'targets': ['darwin-arm64'],
            },
          },
        },
      });

      final result = validator.validateProject(
        project,
        'tom_project.yaml',
      );

      expect(result.isValid, isTrue);
    });

    test('passes when project has no cross-compilation', () {
      final project = TomProject.fromYaml('test_project', {
        'type': 'dart_package',
      });

      final result = validator.validateProject(
        project,
        'tom_project.yaml',
      );

      expect(result.isValid, isTrue);
    });
  });

  // ===========================================================================
  // ValidationResult and ConfigValidationError
  // ===========================================================================

  group('ValidationResult', () {
    test('success result has isValid true and empty errors', () {
      final result = ValidationResult.success();
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('failure result has isValid false and non-empty errors', () {
      final result = ValidationResult.failure([
        const ConfigValidationError(
          message: 'Test error',
          filePath: 'test.yaml',
          resolution: 'Fix it',
        ),
      ]);
      expect(result.isValid, isFalse);
      expect(result.errors, hasLength(1));
    });

    test('formatErrors returns formatted string', () {
      final result = ValidationResult.failure([
        const ConfigValidationError(
          message: 'Error 1',
          filePath: 'file1.yaml',
          resolution: 'Fix 1',
        ),
        const ConfigValidationError(
          message: 'Error 2',
          filePath: 'file2.yaml',
          line: 42,
          resolution: 'Fix 2',
        ),
      ]);

      final formatted = result.formatErrors();
      expect(formatted, contains('Error 1'));
      expect(formatted, contains('Error 2'));
      expect(formatted, contains('file1.yaml'));
      expect(formatted, contains('file2.yaml'));
    });
  });

  group('ConfigValidationError', () {
    test('toString format without line number', () {
      const error = ConfigValidationError(
        message: 'Test message',
        filePath: '/path/to/file.yaml',
        resolution: 'Do something',
      );

      final str = error.toString();
      expect(str, contains('Error: Test message'));
      expect(str, contains('File: [/path/to/file.yaml]'));
      expect(str, contains('Resolution: Do something'));
      expect(str, isNot(contains('Line:')));
    });

    test('toString format with line number', () {
      const error = ConfigValidationError(
        message: 'Test message',
        filePath: '/path/to/file.yaml',
        line: 42,
        resolution: 'Do something',
      );

      final str = error.toString();
      expect(str, contains('Error: Test message'));
      expect(str, contains('File: [/path/to/file.yaml]'));
      expect(str, contains('Line: [42]'));
      expect(str, contains('Resolution: Do something'));
    });
  });

  // ===========================================================================
  // Multiple Errors
  // ===========================================================================

  group('Multiple Errors', () {
    test('collects all errors in single validation', () {
      final workspace = TomWorkspace.fromYaml({
        'workspace-modes': {
          'mode-types': ['environment'],
          'action-mode-configuration': {
            'default': {
              'environment': 'local',
            },
            'missing_action': {
              'environment': 'local',
            },
          },
        },
        'cross-compilation': {
          'all-targets': ['linux-x64'],
          'build-on': {
            'invalid-target': {
              'targets': ['invalid-target'],
            },
          },
        },
        'actions': {
          'build': {
            // Missing default
            'dart_package': {
              'commands': ['build'],
            },
          },
          'test': {
            // Missing default
          },
        },
      });

      final result = validator.validateWorkspace(
        workspace,
        'tom_workspace.yaml',
      );

      expect(result.isValid, isFalse);
      // Should have errors for:
      // - build missing default
      // - test missing default
      // - missing_action not in actions
      // - invalid-target not in all-targets
      expect(result.errors.length, greaterThanOrEqualTo(4));
    });
  });
}
