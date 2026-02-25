/// Tom CLI API - Classes for D4rt bridge generation.
///
/// This file contains the `Tom` class and related types that are exposed
/// to D4rt scripts for interacting with Tom workspace commands.
///
/// The bridge for this class is manually implemented in `tom_bridge.dart`
/// because it requires special handling (static-only class with TomContext access).
library;

import 'dart:io';

import 'package:tom_build/tom_build.dart' show TomContext, tom;

import '../tom/cli/tom_cli.dart';

// Re-export TomCliResult and TomCliConfig for bridge generation
export '../tom/cli/tom_cli.dart' show TomCliResult, TomCliConfig;
// Re-export types used in TomCliResult constructors
export '../tom/execution/action_executor.dart' show ActionExecutionResult;
export '../tom/cli/internal_commands.dart' show InternalCommandResult;

/// The `Tom` class for D4rt scripts.
///
/// Provides static methods to interact with Tom CLI and workspace.
///
/// Example usage in D4rt:
/// ```dart
/// // Run workspace action
/// await Tom.runAction('analyze');
///
/// // Build specific project
/// await Tom.build('tom_build_cli');
///
/// // Access workspace info
/// print(Tom.workspace);
/// print(Tom.cwd);
/// ```
class Tom {
  Tom._();

  // Access to TomContext via global 'tom' object
  static TomContext get _tom => tom;

  /// Run a workspace/project action with optional arguments.
  static Future<TomCliResult> runAction(String action,
      [List<String>? addArgs]) async {
    final cli = TomCli();
    final args = [':$action', ...?addArgs];
    return await cli.run(args);
  }

  /// Run multiple actions in sequence.
  static Future<List<TomCliResult>> runActions(List<String> actions) async {
    final cli = TomCli();
    final results = <TomCliResult>[];
    for (final action in actions) {
      final result = await cli.run([':$action']);
      results.add(result);
    }
    return results;
  }

  /// Run :analyze command.
  static Future<TomCliResult> analyze() => runAction('analyze');

  /// Run :build command, optionally on specific project.
  static Future<TomCliResult> build([String? project]) async {
    if (project != null) {
      final cli = TomCli();
      return await cli.run([':projects', project, ':build']);
    } else {
      return await runAction('build');
    }
  }

  /// Run :test command, optionally on specific project.
  static Future<TomCliResult> test([String? project]) async {
    if (project != null) {
      final cli = TomCli();
      return await cli.run([':projects', project, ':test']);
    } else {
      return await runAction('test');
    }
  }

  /// Access the current workspace configuration.
  static dynamic get workspace => _tom.workspace;

  /// Access the current working directory.
  static String get cwd => Directory.current.path;

  /// Access the current project (if set).
  static dynamic get project => _tom.project;

  /// Access the map of all projects.
  static Map<String, dynamic> get projectInfo => _tom.projectInfo;

  /// Access the map of action definitions.
  static Map<String, dynamic> get actions => _tom.actions;

  /// Access the map of group definitions.
  static Map<String, dynamic> get groups => _tom.groups;

  /// Access environment variables.
  static Map<String, String> get env => _tom.env;
}
