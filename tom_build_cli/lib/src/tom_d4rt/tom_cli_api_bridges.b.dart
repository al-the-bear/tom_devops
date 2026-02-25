// D4rt Bridge - Generated file, do not edit
// Sources: 8 files
// Generated: 2026-02-14T14:38:47.974940

// ignore_for_file: unused_import, deprecated_member_use, prefer_function_declarations_over_variables

import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_d4rt/tom_d4rt.dart';
import 'dart:async';

import 'package:tom_build_cli/src/tom/cli/argument_parser.dart' as $tom_build_cli_1;
import 'package:tom_build_cli/src/tom/cli/internal_commands.dart' as $tom_build_cli_2;
import 'package:tom_build_cli/src/tom/cli/tom_cli.dart' as $tom_build_cli_3;
import 'package:tom_build_cli/src/tom/execution/action_executor.dart' as $tom_build_cli_4;
import 'package:tom_build_cli/src/tom/execution/command_runner.dart' as $tom_build_cli_5;
import 'package:tom_build_cli/src/tom/execution/d4rt_runner.dart' as $tom_build_cli_6;
import 'package:tom_build_cli/src/tom_cli_api/tom_api.dart' as $tom_build_cli_7;

/// Bridge class for tom_cli_api module.
class TomCliApiBridge {
  /// Returns all bridge class definitions.
  static List<BridgedClass> bridgeClasses() {
    return [
      _createTomCliConfigBridge(),
      _createTomCliResultBridge(),
      _createActionExecutionResultBridge(),
      _createInternalCommandResultBridge(),
      _createTomBridge(),
      _createCommandResultBridge(),
    ];
  }

  /// Returns a map of class names to their canonical source URIs.
  ///
  /// Used for deduplication when the same class is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> classSourceUris() {
    return {
      'TomCliConfig': 'package:tom_build_cli/src/tom/cli/tom_cli.dart',
      'TomCliResult': 'package:tom_build_cli/src/tom/cli/tom_cli.dart',
      'ActionExecutionResult': 'package:tom_build_cli/src/tom/execution/action_executor.dart',
      'InternalCommandResult': 'package:tom_build_cli/src/tom/cli/internal_commands.dart',
      'Tom': 'package:tom_build_cli/src/tom_cli_api/tom_api.dart',
      'CommandResult': 'package:tom_build_cli/src/tom/execution/command_runner.dart',
    };
  }

  /// Returns all bridged enum definitions.
  static List<BridgedEnumDefinition> bridgedEnums() {
    return [
    ];
  }

  /// Returns a map of enum names to their canonical source URIs.
  ///
  /// Used for deduplication when the same enum is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> enumSourceUris() {
    return {
    };
  }

  /// Returns all bridged extension definitions.
  static List<BridgedExtensionDefinition> bridgedExtensions() {
    return [
      BridgedExtensionDefinition(
        name: 'CommandResultExtensions',
        onTypeName: 'List',
        getters: {
          'allSucceeded': (visitor, target) => (target as List<$tom_build_cli_5.CommandResult>).allSucceeded,
          'firstFailure': (visitor, target) => (target as List<$tom_build_cli_5.CommandResult>).firstFailure,
          'totalDuration': (visitor, target) => (target as List<$tom_build_cli_5.CommandResult>).totalDuration,
        },
      ),
      BridgedExtensionDefinition(
        name: 'D4rtCommandExtension',
        onTypeName: 'String',
        getters: {
          'isD4rtCommand': (visitor, target) => (target as String).isD4rtCommand,
          'isVSCodeCommand': (visitor, target) => (target as String).isVSCodeCommand,
          'vscodeCommandPort': (visitor, target) => (target as String).vscodeCommandPort,
          'vscodeCommandBody': (visitor, target) => (target as String).vscodeCommandBody,
          'isLocalD4rtCommand': (visitor, target) => (target as String).isLocalD4rtCommand,
          'isVSCodeSimpleCommand': (visitor, target) => (target as String).isVSCodeSimpleCommand,
          'vscodeSimpleCommandPort': (visitor, target) => (target as String).vscodeSimpleCommandPort,
          'vscodeSimpleCommandBody': (visitor, target) => (target as String).vscodeSimpleCommandBody,
          'isDartscriptSimpleCommand': (visitor, target) => (target as String).isDartscriptSimpleCommand,
          'dartscriptSimpleCommandPort': (visitor, target) => (target as String).dartscriptSimpleCommandPort,
          'dartscriptSimpleCommandBody': (visitor, target) => (target as String).dartscriptSimpleCommandBody,
          'isTomCommand': (visitor, target) => (target as String).isTomCommand,
          'tomCommandArgs': (visitor, target) => (target as String).tomCommandArgs,
          'tomCommandArgsList': (visitor, target) => (target as String).tomCommandArgsList,
        },
      ),
      BridgedExtensionDefinition(
        name: 'D4rtCommandExtension',
        onTypeName: 'String',
        getters: {
          'isD4rtCommand': (visitor, target) => (target as String).isD4rtCommand,
          'isVSCodeCommand': (visitor, target) => (target as String).isVSCodeCommand,
          'vscodeCommandPort': (visitor, target) => (target as String).vscodeCommandPort,
          'vscodeCommandBody': (visitor, target) => (target as String).vscodeCommandBody,
          'isLocalD4rtCommand': (visitor, target) => (target as String).isLocalD4rtCommand,
          'isVSCodeSimpleCommand': (visitor, target) => (target as String).isVSCodeSimpleCommand,
          'vscodeSimpleCommandPort': (visitor, target) => (target as String).vscodeSimpleCommandPort,
          'vscodeSimpleCommandBody': (visitor, target) => (target as String).vscodeSimpleCommandBody,
          'isDartscriptSimpleCommand': (visitor, target) => (target as String).isDartscriptSimpleCommand,
          'dartscriptSimpleCommandPort': (visitor, target) => (target as String).dartscriptSimpleCommandPort,
          'dartscriptSimpleCommandBody': (visitor, target) => (target as String).dartscriptSimpleCommandBody,
          'isTomCommand': (visitor, target) => (target as String).isTomCommand,
          'tomCommandArgs': (visitor, target) => (target as String).tomCommandArgs,
          'tomCommandArgsList': (visitor, target) => (target as String).tomCommandArgsList,
        },
      ),
    ];
  }

  /// Returns a map of extension identifiers to their canonical source URIs.
  static Map<String, String> extensionSourceUris() {
    return {
      'CommandResultExtensions': 'package:tom_build_cli/src/tom/execution/command_runner.dart',
      'D4rtCommandExtension': 'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'D4rtCommandExtension': 'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
    };
  }

  /// Registers all bridges with an interpreter.
  ///
  /// [importPath] is the package import path that D4rt scripts will use
  /// to access these classes (e.g., 'package:tom_build/tom.dart').
  static void registerBridges(D4rt interpreter, String importPath) {
    // Register bridged classes with source URIs for deduplication
    final classes = bridgeClasses();
    final classSources = classSourceUris();
    for (final bridge in classes) {
      interpreter.registerBridgedClass(bridge, importPath, sourceUri: classSources[bridge.name]);
    }

    // Register bridged extensions with source URIs for deduplication
    final extensions = bridgedExtensions();
    final extSources = extensionSourceUris();
    for (final extDef in extensions) {
      final extKey = extDef.name ?? '<unnamed>@${extDef.onTypeName}';
      interpreter.registerBridgedExtension(extDef, importPath, sourceUri: extSources[extKey]);
    }
  }

  /// Returns a map of global function names to their native implementations.
  static Map<String, NativeFunctionImpl> globalFunctions() {
    return {};
  }

  /// Returns a map of global function names to their canonical source URIs.
  static Map<String, String> globalFunctionSourceUris() {
    return {};
  }

  /// Returns a map of global function names to their display signatures.
  static Map<String, String> globalFunctionSignatures() {
    return {};
  }

  /// Returns the list of canonical source library URIs.
  ///
  /// These are the actual source locations of all elements in this bridge,
  /// used for deduplication when the same libraries are exported through
  /// multiple barrels.
  static List<String> sourceLibraries() {
    return [
      'package:tom_build_cli/src/tom/cli/internal_commands.dart',
      'package:tom_build_cli/src/tom/cli/tom_cli.dart',
      'package:tom_build_cli/src/tom/execution/action_executor.dart',
      'package:tom_build_cli/src/tom/execution/command_runner.dart',
      'package:tom_build_cli/src/tom_cli_api/tom_api.dart',
    ];
  }

  /// Returns the import statement needed for D4rt scripts.
  ///
  /// Use this in your D4rt initialization script to make all
  /// bridged classes available to scripts.
  static String getImportBlock() {
    return "import 'package:tom_build_cli/tom_cli_api.dart';";
  }

  /// Returns barrel import URIs for sub-packages discovered through re-exports.
  ///
  /// When a module follows re-exports into sub-packages (e.g., dcli re-exports
  /// dcli_core), D4rt scripts may import those sub-packages directly.
  /// These barrels need to be registered with the interpreter separately
  /// so that module resolution finds content for those URIs.
  static List<String> subPackageBarrels() {
    return [];
  }

}

// =============================================================================
// TomCliConfig Bridge
// =============================================================================

BridgedClass _createTomCliConfigBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_3.TomCliConfig,
    name: 'TomCliConfig',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getOptionalNamedArg<String?>(named, 'workspacePath');
        final metadataPath = D4.getOptionalNamedArg<String?>(named, 'metadataPath');
        final verbose = D4.getNamedArgWithDefault<bool>(named, 'verbose', false);
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        final stopOnFailure = D4.getNamedArgWithDefault<bool>(named, 'stopOnFailure', true);
        return $tom_build_cli_3.TomCliConfig(workspacePath: workspacePath, metadataPath: metadataPath, verbose: verbose, dryRun: dryRun, stopOnFailure: stopOnFailure);
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliConfig>(target, 'TomCliConfig').workspacePath,
      'metadataPath': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliConfig>(target, 'TomCliConfig').metadataPath,
      'verbose': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliConfig>(target, 'TomCliConfig').verbose,
      'dryRun': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliConfig>(target, 'TomCliConfig').dryRun,
      'stopOnFailure': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliConfig>(target, 'TomCliConfig').stopOnFailure,
      'resolvedWorkspacePath': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliConfig>(target, 'TomCliConfig').resolvedWorkspacePath,
      'resolvedMetadataPath': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliConfig>(target, 'TomCliConfig').resolvedMetadataPath,
    },
    methods: {
      'copyWith': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.TomCliConfig>(target, 'TomCliConfig');
        final workspacePath = D4.getOptionalNamedArg<String?>(named, 'workspacePath');
        final metadataPath = D4.getOptionalNamedArg<String?>(named, 'metadataPath');
        final verbose = D4.getOptionalNamedArg<bool?>(named, 'verbose');
        final dryRun = D4.getOptionalNamedArg<bool?>(named, 'dryRun');
        final stopOnFailure = D4.getOptionalNamedArg<bool?>(named, 'stopOnFailure');
        return t.copyWith(workspacePath: workspacePath, metadataPath: metadataPath, verbose: verbose, dryRun: dryRun, stopOnFailure: stopOnFailure);
      },
    },
    constructorSignatures: {
      '': 'const TomCliConfig({String? workspacePath, String? metadataPath, bool verbose = false, bool dryRun = false, bool stopOnFailure = true})',
    },
    methodSignatures: {
      'copyWith': 'TomCliConfig copyWith({String? workspacePath, String? metadataPath, bool? verbose, bool? dryRun, bool? stopOnFailure})',
    },
    getterSignatures: {
      'workspacePath': 'String? get workspacePath',
      'metadataPath': 'String? get metadataPath',
      'verbose': 'bool get verbose',
      'dryRun': 'bool get dryRun',
      'stopOnFailure': 'bool get stopOnFailure',
      'resolvedWorkspacePath': 'String get resolvedWorkspacePath',
      'resolvedMetadataPath': 'String get resolvedMetadataPath',
    },
  );
}

// =============================================================================
// TomCliResult Bridge
// =============================================================================

BridgedClass _createTomCliResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_3.TomCliResult,
    name: 'TomCliResult',
    constructors: {
      'success': (visitor, positional, named) {
        final message = D4.getOptionalNamedArg<String?>(named, 'message');
        final actionResults = named.containsKey('actionResults') && named['actionResults'] != null
            ? D4.coerceList<$tom_build_cli_4.ActionExecutionResult>(named['actionResults'], 'actionResults')
            : const <$tom_build_cli_4.ActionExecutionResult>[];
        final commandResults = named.containsKey('commandResults') && named['commandResults'] != null
            ? D4.coerceList<$tom_build_cli_2.InternalCommandResult>(named['commandResults'], 'commandResults')
            : const <$tom_build_cli_2.InternalCommandResult>[];
        return $tom_build_cli_3.TomCliResult.success(message: message, actionResults: actionResults, commandResults: commandResults);
      },
      'failure': (visitor, positional, named) {
        final error = D4.getRequiredNamedArg<String>(named, 'error', 'TomCliResult');
        final exitCode = D4.getNamedArgWithDefault<int>(named, 'exitCode', 1);
        final actionResults = named.containsKey('actionResults') && named['actionResults'] != null
            ? D4.coerceList<$tom_build_cli_4.ActionExecutionResult>(named['actionResults'], 'actionResults')
            : const <$tom_build_cli_4.ActionExecutionResult>[];
        final commandResults = named.containsKey('commandResults') && named['commandResults'] != null
            ? D4.coerceList<$tom_build_cli_2.InternalCommandResult>(named['commandResults'], 'commandResults')
            : const <$tom_build_cli_2.InternalCommandResult>[];
        return $tom_build_cli_3.TomCliResult.failure(error: error, exitCode: exitCode, actionResults: actionResults, commandResults: commandResults);
      },
      'help': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'TomCliResult');
        final message = D4.getRequiredArg<String>(positional, 0, 'message', 'TomCliResult');
        return $tom_build_cli_3.TomCliResult.help(message);
      },
    },
    getters: {
      'exitCode': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliResult>(target, 'TomCliResult').exitCode,
      'message': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliResult>(target, 'TomCliResult').message,
      'error': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliResult>(target, 'TomCliResult').error,
      'actionResults': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliResult>(target, 'TomCliResult').actionResults,
      'commandResults': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliResult>(target, 'TomCliResult').commandResults,
      'success': (visitor, target) => D4.validateTarget<$tom_build_cli_3.TomCliResult>(target, 'TomCliResult').success,
    },
    constructorSignatures: {
      'success': 'factory TomCliResult.success({String? message, List<ActionExecutionResult> actionResults = const [], List<InternalCommandResult> commandResults = const []})',
      'failure': 'factory TomCliResult.failure({required String error, int exitCode = 1, List<ActionExecutionResult> actionResults = const [], List<InternalCommandResult> commandResults = const []})',
      'help': 'factory TomCliResult.help(String message)',
    },
    getterSignatures: {
      'exitCode': 'int get exitCode',
      'message': 'String? get message',
      'error': 'String? get error',
      'actionResults': 'List<ActionExecutionResult> get actionResults',
      'commandResults': 'List<InternalCommandResult> get commandResults',
      'success': 'bool get success',
    },
  );
}

// =============================================================================
// ActionExecutionResult Bridge
// =============================================================================

BridgedClass _createActionExecutionResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_4.ActionExecutionResult,
    name: 'ActionExecutionResult',
    constructors: {
      'success': (visitor, positional, named) {
        final projectName = D4.getRequiredNamedArg<String>(named, 'projectName', 'ActionExecutionResult');
        final actionName = D4.getRequiredNamedArg<String>(named, 'actionName', 'ActionExecutionResult');
        if (!named.containsKey('commandResults') || named['commandResults'] == null) {
          throw ArgumentError('ActionExecutionResult: Missing required named argument "commandResults"');
        }
        final commandResults = D4.coerceList<$tom_build_cli_5.CommandResult>(named['commandResults'], 'commandResults');
        final duration = D4.getRequiredNamedArg<Duration>(named, 'duration', 'ActionExecutionResult');
        return $tom_build_cli_4.ActionExecutionResult.success(projectName: projectName, actionName: actionName, commandResults: commandResults, duration: duration);
      },
      'failure': (visitor, positional, named) {
        final projectName = D4.getRequiredNamedArg<String>(named, 'projectName', 'ActionExecutionResult');
        final actionName = D4.getRequiredNamedArg<String>(named, 'actionName', 'ActionExecutionResult');
        final error = D4.getRequiredNamedArg<String>(named, 'error', 'ActionExecutionResult');
        final commandResults = named.containsKey('commandResults') && named['commandResults'] != null
            ? D4.coerceList<$tom_build_cli_5.CommandResult>(named['commandResults'], 'commandResults')
            : const <$tom_build_cli_5.CommandResult>[];
        final duration = D4.getNamedArgWithDefault<Duration>(named, 'duration', Duration.zero);
        return $tom_build_cli_4.ActionExecutionResult.failure(projectName: projectName, actionName: actionName, error: error, commandResults: commandResults, duration: duration);
      },
    },
    getters: {
      'projectName': (visitor, target) => D4.validateTarget<$tom_build_cli_4.ActionExecutionResult>(target, 'ActionExecutionResult').projectName,
      'actionName': (visitor, target) => D4.validateTarget<$tom_build_cli_4.ActionExecutionResult>(target, 'ActionExecutionResult').actionName,
      'success': (visitor, target) => D4.validateTarget<$tom_build_cli_4.ActionExecutionResult>(target, 'ActionExecutionResult').success,
      'commandResults': (visitor, target) => D4.validateTarget<$tom_build_cli_4.ActionExecutionResult>(target, 'ActionExecutionResult').commandResults,
      'error': (visitor, target) => D4.validateTarget<$tom_build_cli_4.ActionExecutionResult>(target, 'ActionExecutionResult').error,
      'duration': (visitor, target) => D4.validateTarget<$tom_build_cli_4.ActionExecutionResult>(target, 'ActionExecutionResult').duration,
    },
    constructorSignatures: {
      'success': 'factory ActionExecutionResult.success({required String projectName, required String actionName, required List<CommandResult> commandResults, required Duration duration})',
      'failure': 'factory ActionExecutionResult.failure({required String projectName, required String actionName, required String error, List<CommandResult> commandResults = const [], Duration duration = Duration.zero})',
    },
    getterSignatures: {
      'projectName': 'String get projectName',
      'actionName': 'String get actionName',
      'success': 'bool get success',
      'commandResults': 'List<CommandResult> get commandResults',
      'error': 'String? get error',
      'duration': 'Duration get duration',
    },
  );
}

// =============================================================================
// InternalCommandResult Bridge
// =============================================================================

BridgedClass _createInternalCommandResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_2.InternalCommandResult,
    name: 'InternalCommandResult',
    constructors: {
      'success': (visitor, positional, named) {
        final command = D4.getRequiredNamedArg<String>(named, 'command', 'InternalCommandResult');
        final message = D4.getOptionalNamedArg<String?>(named, 'message');
        final duration = D4.getRequiredNamedArg<Duration>(named, 'duration', 'InternalCommandResult');
        return $tom_build_cli_2.InternalCommandResult.success(command: command, message: message, duration: duration);
      },
      'failure': (visitor, positional, named) {
        final command = D4.getRequiredNamedArg<String>(named, 'command', 'InternalCommandResult');
        final error = D4.getRequiredNamedArg<String>(named, 'error', 'InternalCommandResult');
        final duration = D4.getRequiredNamedArg<Duration>(named, 'duration', 'InternalCommandResult');
        return $tom_build_cli_2.InternalCommandResult.failure(command: command, error: error, duration: duration);
      },
    },
    getters: {
      'command': (visitor, target) => D4.validateTarget<$tom_build_cli_2.InternalCommandResult>(target, 'InternalCommandResult').command,
      'success': (visitor, target) => D4.validateTarget<$tom_build_cli_2.InternalCommandResult>(target, 'InternalCommandResult').success,
      'message': (visitor, target) => D4.validateTarget<$tom_build_cli_2.InternalCommandResult>(target, 'InternalCommandResult').message,
      'error': (visitor, target) => D4.validateTarget<$tom_build_cli_2.InternalCommandResult>(target, 'InternalCommandResult').error,
      'duration': (visitor, target) => D4.validateTarget<$tom_build_cli_2.InternalCommandResult>(target, 'InternalCommandResult').duration,
    },
    constructorSignatures: {
      'success': 'factory InternalCommandResult.success({required String command, String? message, required Duration duration})',
      'failure': 'factory InternalCommandResult.failure({required String command, required String error, required Duration duration})',
    },
    getterSignatures: {
      'command': 'String get command',
      'success': 'bool get success',
      'message': 'String? get message',
      'error': 'String? get error',
      'duration': 'Duration get duration',
    },
  );
}

// =============================================================================
// Tom Bridge
// =============================================================================

BridgedClass _createTomBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_7.Tom,
    name: 'Tom',
    constructors: {
    },
    staticGetters: {
      'workspace': (visitor) => $tom_build_cli_7.Tom.workspace,
      'cwd': (visitor) => $tom_build_cli_7.Tom.cwd,
      'project': (visitor) => $tom_build_cli_7.Tom.project,
      'projectInfo': (visitor) => $tom_build_cli_7.Tom.projectInfo,
      'actions': (visitor) => $tom_build_cli_7.Tom.actions,
      'groups': (visitor) => $tom_build_cli_7.Tom.groups,
      'env': (visitor) => $tom_build_cli_7.Tom.env,
    },
    staticMethods: {
      'runAction': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'runAction');
        final action = D4.getRequiredArg<String>(positional, 0, 'action', 'runAction');
        final addArgs = positional.length > 1
            ? D4.coerceListOrNull<String>(positional[1], 'addArgs')
            : null;
        return $tom_build_cli_7.Tom.runAction(action, addArgs);
      },
      'runActions': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'runActions');
        if (positional.isEmpty) {
          throw ArgumentError('runActions: Missing required argument "actions" at position 0');
        }
        final actions = D4.coerceList<String>(positional[0], 'actions');
        return $tom_build_cli_7.Tom.runActions(actions);
      },
      'analyze': (visitor, positional, named, typeArgs) {
        return $tom_build_cli_7.Tom.analyze();
      },
      'build': (visitor, positional, named, typeArgs) {
        final project = D4.getOptionalArg<String?>(positional, 0, 'project');
        return $tom_build_cli_7.Tom.build(project);
      },
      'test': (visitor, positional, named, typeArgs) {
        final project = D4.getOptionalArg<String?>(positional, 0, 'project');
        return $tom_build_cli_7.Tom.test(project);
      },
    },
    staticMethodSignatures: {
      'runAction': 'Future<TomCliResult> runAction(String action, [List<String>? addArgs])',
      'runActions': 'Future<List<TomCliResult>> runActions(List<String> actions)',
      'analyze': 'Future<TomCliResult> analyze()',
      'build': 'Future<TomCliResult> build([String? project])',
      'test': 'Future<TomCliResult> test([String? project])',
    },
    staticGetterSignatures: {
      'workspace': 'dynamic get workspace',
      'cwd': 'String get cwd',
      'project': 'dynamic get project',
      'projectInfo': 'Map<String, dynamic> get projectInfo',
      'actions': 'Map<String, dynamic> get actions',
      'groups': 'Map<String, dynamic> get groups',
      'env': 'Map<String, String> get env',
    },
  );
}

// =============================================================================
// CommandResult Bridge
// =============================================================================

BridgedClass _createCommandResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_5.CommandResult,
    name: 'CommandResult',
    constructors: {
      'success': (visitor, positional, named) {
        final command = D4.getRequiredNamedArg<String>(named, 'command', 'CommandResult');
        final stdout = D4.getRequiredNamedArg<String>(named, 'stdout', 'CommandResult');
        final stderr = D4.getNamedArgWithDefault<String>(named, 'stderr', '');
        final duration = D4.getNamedArgWithDefault<Duration>(named, 'duration', Duration.zero);
        return $tom_build_cli_5.CommandResult.success(command: command, stdout: stdout, stderr: stderr, duration: duration);
      },
      'failure': (visitor, positional, named) {
        final command = D4.getRequiredNamedArg<String>(named, 'command', 'CommandResult');
        final exitCode = D4.getRequiredNamedArg<int>(named, 'exitCode', 'CommandResult');
        final stdout = D4.getNamedArgWithDefault<String>(named, 'stdout', '');
        final stderr = D4.getNamedArgWithDefault<String>(named, 'stderr', '');
        final duration = D4.getNamedArgWithDefault<Duration>(named, 'duration', Duration.zero);
        return $tom_build_cli_5.CommandResult.failure(command: command, exitCode: exitCode, stdout: stdout, stderr: stderr, duration: duration);
      },
    },
    getters: {
      'command': (visitor, target) => D4.validateTarget<$tom_build_cli_5.CommandResult>(target, 'CommandResult').command,
      'success': (visitor, target) => D4.validateTarget<$tom_build_cli_5.CommandResult>(target, 'CommandResult').success,
      'exitCode': (visitor, target) => D4.validateTarget<$tom_build_cli_5.CommandResult>(target, 'CommandResult').exitCode,
      'stdout': (visitor, target) => D4.validateTarget<$tom_build_cli_5.CommandResult>(target, 'CommandResult').stdout,
      'stderr': (visitor, target) => D4.validateTarget<$tom_build_cli_5.CommandResult>(target, 'CommandResult').stderr,
      'duration': (visitor, target) => D4.validateTarget<$tom_build_cli_5.CommandResult>(target, 'CommandResult').duration,
    },
    constructorSignatures: {
      'success': 'factory CommandResult.success({required String command, required String stdout, String stderr = \'\', Duration duration = Duration.zero})',
      'failure': 'factory CommandResult.failure({required String command, required int exitCode, String stdout = \'\', String stderr = \'\', Duration duration = Duration.zero})',
    },
    getterSignatures: {
      'command': 'String get command',
      'success': 'bool get success',
      'exitCode': 'int get exitCode',
      'stdout': 'String get stdout',
      'stderr': 'String get stderr',
      'duration': 'Duration get duration',
    },
  );
}

