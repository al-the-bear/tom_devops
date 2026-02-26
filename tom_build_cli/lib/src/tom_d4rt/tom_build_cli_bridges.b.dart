// D4rt Bridge - Generated file, do not edit
// Sources: 39 files
// Generated: 2026-02-15T00:34:50.115553

// ignore_for_file: unused_import, deprecated_member_use, prefer_function_declarations_over_variables

import 'package:tom_d4rt/d4rt.dart';
import 'package:tom_d4rt/tom_d4rt.dart';
import 'dart:async';
import 'dart:io';

import 'package:tom_basics/src/runtime/platform_environment_runtime.dart'
    as $tom_basics_1;
import 'package:tom_build/src/tom/file_object_model/file_object_model.dart'
    as $tom_build_1;
import 'package:tom_build/src/tom/tom_context.dart' as $tom_build_2;
import 'package:tom_build_cli/src/dartscript/bridge_configuration.dart'
    as $tom_build_cli_1;
import 'package:tom_build_cli/src/dartscript/d4rt_cli_initialization.dart'
    as $tom_build_cli_2;
import 'package:tom_build_cli/src/dartscript/d4rt_context_provider.dart'
    as $tom_build_cli_3;
import 'package:tom_build_cli/src/dartscript/d4rt_globals.dart'
    as $tom_build_cli_4;
import 'package:tom_build_cli/src/dartscript/d4rt_instance.dart'
    as $tom_build_cli_5;
import 'package:tom_build_cli/src/tom/cli/argument_parser.dart'
    as $tom_build_cli_6;
import 'package:tom_build_cli/src/tom/cli/git_helper.dart' as $tom_build_cli_7;
import 'package:tom_build_cli/src/tom/cli/internal_commands.dart'
    as $tom_build_cli_8;
import 'package:tom_build_cli/src/tom/cli/tom_cli.dart' as $tom_build_cli_9;
import 'package:tom_build_cli/src/tom/cli/version_bumper.dart'
    as $tom_build_cli_10;
import 'package:tom_build_cli/src/tom/cli/workspace_context.dart'
    as $tom_build_cli_11;
import 'package:tom_build_cli/src/tom/config/config_loader.dart'
    as $tom_build_cli_12;
import 'package:tom_build_cli/src/tom/config/config_merger.dart'
    as $tom_build_cli_13;
import 'package:tom_build_cli/src/tom/config/validation.dart'
    as $tom_build_cli_14;
import 'package:tom_build_cli/src/tom/execution/action_executor.dart'
    as $tom_build_cli_15;
import 'package:tom_build_cli/src/tom/execution/command_runner.dart'
    as $tom_build_cli_16;
import 'package:tom_build_cli/src/tom/execution/d4rt_runner.dart'
    as $tom_build_cli_17;
import 'package:tom_build_cli/src/tom/execution/output_formatter.dart'
    as $tom_build_cli_18;
import 'package:tom_build_cli/src/tom/generation/build_order.dart'
    as $tom_build_cli_19;
import 'package:tom_build_cli/src/tom/generation/generator_placeholder.dart'
    as $tom_build_cli_20;
import 'package:tom_build_cli/src/tom/generation/master_generator.dart'
    as $tom_build_cli_21;
import 'package:tom_build_cli/src/tom/generation/placeholder_resolver.dart'
    as $tom_build_cli_22;
import 'package:tom_build_cli/src/tom/mode/mode_processor.dart'
    as $tom_build_cli_23;
import 'package:tom_build_cli/src/tom/mode/mode_resolver.dart'
    as $tom_build_cli_24;
import 'package:tom_build_cli/src/tom/template/tomplate_parser.dart'
    as $tom_build_cli_25;
import 'package:tom_build_cli/src/tom/template/tomplate_processor.dart'
    as $tom_build_cli_26;
import 'package:tom_build_cli/src/tom_cli_api/tom_api.dart'
    as $tom_build_cli_27;
import 'package:tom_build_cli/src/tom_d4rt/tom_d4rt_main.dart'
    as $tom_build_cli_28;
import 'package:tom_build_cli/src/tom_d4rt/tom_d4rt_repl.dart'
    as $tom_build_cli_29;
import 'package:tom_build_cli/src/tools/cli_args.dart' as $tom_build_cli_30;
import 'package:tom_build_cli/src/tools/pipeline.dart' as $tom_build_cli_31;
import 'package:tom_build_cli/src/tools/placeholder_resolver.dart'
    as $tom_build_cli_32;
import 'package:tom_build_cli/src/tools/tom_command_parser.dart'
    as $tom_build_cli_33;
import 'package:tom_build_cli/src/tools/tom_runner.dart' as $tom_build_cli_34;
import 'package:tom_build_cli/src/ws_prepper/template_parser.dart'
    as $tom_build_cli_35;
import 'package:tom_build_cli/src/ws_prepper/ws_prepper.dart'
    as $tom_build_cli_36;
import 'package:tom_core_kernel/src/tombase/beanlocator/bean_locator.dart'
    as $tom_core_kernel_1;
import 'package:tom_core_kernel/src/tombase/context/execution_context.dart'
    as $tom_core_kernel_2;
import 'package:tom_core_kernel/src/tombase/reflection/reflection.dart'
    as $tom_core_kernel_3;
import 'package:tom_d4rt/src/bridge/bridged_types.dart' as $tom_d4rt_1;
import 'package:tom_d4rt/src/d4rt_base.dart' as $tom_d4rt_2;
import 'package:tom_d4rt_dcli/src/cli/repl_state.dart' as $tom_d4rt_dcli_1;
import 'package:yaml/src/yaml_node.dart' as $yaml_1;
import 'package:tom_d4rt_dcli/src/cli/repl_base.dart' as $aux_tom_d4rt_dcli;

/// Bridge class for tom_build_cli module.
class TomBuildCliBridge {
  /// Returns all bridge class definitions.
  static List<BridgedClass> bridgeClasses() {
    return [
      _createBridgeConfigurationBridge(),
      _createBridgeModuleRegistryBridge(),
      _createD4rtContextProviderBridge(),
      _createD4rtContextProviderDefaultsBridge(),
      _createActionContextProviderBridge(),
      _createTemplateContextProviderBridge(),
      _createStandaloneContextProviderBridge(),
      _createCompositeContextProviderBridge(),
      _createD4rtGlobalsBridge(),
      _createD4rtInstanceBridge(),
      _createActionD4rtContextBridge(),
      _createParsedArgumentsBridge(),
      _createActionInvocationBridge(),
      _createArgumentParserBridge(),
      _createGitHelperBridge(),
      _createInternalCommandsBridge(),
      _createInternalCommandInfoBridge(),
      _createInternalCommandConfigBridge(),
      _createInternalCommandResultBridge(),
      _createInternalCommandExecutorBridge(),
      _createActionCounterManagerBridge(),
      _createTomCliConfigBridge(),
      _createTomCliResultBridge(),
      _createTomCliBridge(),
      _createVersionBumperBridge(),
      _createVersionBumpResultBridge(),
      _createWorkspaceDiscoveryResultBridge(),
      _createWorkspaceContextBridge(),
      _createMasterGenerationSummaryBridge(),
      _createWorkspaceContextExceptionBridge(),
      _createConfigLoaderBridge(),
      _createConfigLoadExceptionBridge(),
      _createConfigMergerBridge(),
      _createValidationResultBridge(),
      _createConfigValidationErrorBridge(),
      _createConfigValidatorBridge(),
      _createActionExecutorConfigBridge(),
      _createActionExecutionResultBridge(),
      _createActionExecutorBridge(),
      _createCommandResultBridge(),
      _createCommandRunnerBridge(),
      _createD4rtResultBridge(),
      _createD4rtRunnerConfigBridge(),
      _createD4rtRunnerBridge(),
      _createAnsiColorsBridge(),
      _createOutputFormatterConfigBridge(),
      _createErrorMessageBridge(),
      _createProgressIndicatorBridge(),
      _createOutputFormatterBridge(),
      _createBuildOrderProjectBridge(),
      _createBuildOrderResultBridge(),
      _createCircularDependencyExceptionBridge(),
      _createBuildOrderCalculatorBridge(),
      _createGeneratorResultBridge(),
      _createGeneratorResolutionExceptionBridge(),
      _createGeneratorPlaceholderResolverBridge(),
      _createMasterGeneratorConfigBridge(),
      _createMasterGenerationResultBridge(),
      _createMasterGeneratorBridge(),
      _createPlaceholderResultBridge(),
      _createGeneratorPlaceholderExceptionBridge(),
      _createPlaceholderResolverBridge(),
      _createModeProcessorBridge(),
      _createModeResolverBridge(),
      _createResolvedModesBridge(),
      _createTomplateParserBridge(),
      _createTomplateFileBridge(),
      _createPlaceholderInfoBridge(),
      _createTomplateProcessorBridge(),
      _createTomplateResultBridge(),
      _createPlaceholderResolutionExceptionBridge(),
      _createToolPrefixBridge(),
      _createCliArgsBridge(),
      _createPipelineDefinitionBridge(),
      _createPipelineResultBridge(),
      _createPipelineLoaderBridge(),
      _createPipelineRunnerBridge(),
      _createPackageInfoBridge(),
      _createTomPlaceholderResolverBridge(),
      _createParsedCommandBridge(),
      _createParsedTomCommandBridge(),
      _createTomCommandParserBridge(),
      _createTomRunResultBridge(),
      _createTomRunResultsBridge(),
      _createTomRunnerBridge(),
      _createTemplateParserBridge(),
      _createParsedTemplateBridge(),
      _createTemplateSegmentBridge(),
      _createTextSegmentBridge(),
      _createModeBlockGroupBridge(),
      _createModeBlockBridge(),
      _createWsPrepperBridge(),
      _createWsPrepperOptionsBridge(),
      _createWsPrepperResultBridge(),
      _createPreparedTemplateBridge(),
      _createWsPrepperErrorBridge(),
      _createTomD4rtReplBridge(),
      _createTomBridge(),
      _createTomWorkspaceBridge(),
      _createTomProjectBridge(),
    ];
  }

  /// Returns a map of class names to their canonical source URIs.
  ///
  /// Used for deduplication when the same class is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> classSourceUris() {
    return {
      'BridgeConfiguration':
          'package:tom_build_cli/src/dartscript/bridge_configuration.dart',
      'BridgeModuleRegistry':
          'package:tom_build_cli/src/dartscript/bridge_configuration.dart',
      'D4rtContextProvider':
          'package:tom_build_cli/src/dartscript/d4rt_context_provider.dart',
      'D4rtContextProviderDefaults':
          'package:tom_build_cli/src/dartscript/d4rt_context_provider.dart',
      'ActionContextProvider':
          'package:tom_build_cli/src/dartscript/d4rt_context_provider.dart',
      'TemplateContextProvider':
          'package:tom_build_cli/src/dartscript/d4rt_context_provider.dart',
      'StandaloneContextProvider':
          'package:tom_build_cli/src/dartscript/d4rt_context_provider.dart',
      'CompositeContextProvider':
          'package:tom_build_cli/src/dartscript/d4rt_context_provider.dart',
      'D4rtGlobals': 'package:tom_build_cli/src/dartscript/d4rt_globals.dart',
      'D4rtInstance': 'package:tom_build_cli/src/dartscript/d4rt_instance.dart',
      'ActionD4rtContext':
          'package:tom_build_cli/src/dartscript/d4rt_instance.dart',
      'ParsedArguments':
          'package:tom_build_cli/src/tom/cli/argument_parser.dart',
      'ActionInvocation':
          'package:tom_build_cli/src/tom/cli/argument_parser.dart',
      'ArgumentParser':
          'package:tom_build_cli/src/tom/cli/argument_parser.dart',
      'GitHelper': 'package:tom_build_cli/src/tom/cli/git_helper.dart',
      'InternalCommands':
          'package:tom_build_cli/src/tom/cli/internal_commands.dart',
      'InternalCommandInfo':
          'package:tom_build_cli/src/tom/cli/internal_commands.dart',
      'InternalCommandConfig':
          'package:tom_build_cli/src/tom/cli/internal_commands.dart',
      'InternalCommandResult':
          'package:tom_build_cli/src/tom/cli/internal_commands.dart',
      'InternalCommandExecutor':
          'package:tom_build_cli/src/tom/cli/internal_commands.dart',
      'ActionCounterManager':
          'package:tom_build_cli/src/tom/cli/internal_commands.dart',
      'TomCliConfig': 'package:tom_build_cli/src/tom/cli/tom_cli.dart',
      'TomCliResult': 'package:tom_build_cli/src/tom/cli/tom_cli.dart',
      'TomCli': 'package:tom_build_cli/src/tom/cli/tom_cli.dart',
      'VersionBumper': 'package:tom_build_cli/src/tom/cli/version_bumper.dart',
      'VersionBumpResult':
          'package:tom_build_cli/src/tom/cli/version_bumper.dart',
      'WorkspaceDiscoveryResult':
          'package:tom_build_cli/src/tom/cli/workspace_context.dart',
      'WorkspaceContext':
          'package:tom_build_cli/src/tom/cli/workspace_context.dart',
      'MasterGenerationSummary':
          'package:tom_build_cli/src/tom/cli/workspace_context.dart',
      'WorkspaceContextException':
          'package:tom_build_cli/src/tom/cli/workspace_context.dart',
      'ConfigLoader': 'package:tom_build_cli/src/tom/config/config_loader.dart',
      'ConfigLoadException':
          'package:tom_build_cli/src/tom/config/config_loader.dart',
      'ConfigMerger': 'package:tom_build_cli/src/tom/config/config_merger.dart',
      'ValidationResult':
          'package:tom_build_cli/src/tom/config/validation.dart',
      'ConfigValidationError':
          'package:tom_build_cli/src/tom/config/validation.dart',
      'ConfigValidator': 'package:tom_build_cli/src/tom/config/validation.dart',
      'ActionExecutorConfig':
          'package:tom_build_cli/src/tom/execution/action_executor.dart',
      'ActionExecutionResult':
          'package:tom_build_cli/src/tom/execution/action_executor.dart',
      'ActionExecutor':
          'package:tom_build_cli/src/tom/execution/action_executor.dart',
      'CommandResult':
          'package:tom_build_cli/src/tom/execution/command_runner.dart',
      'CommandRunner':
          'package:tom_build_cli/src/tom/execution/command_runner.dart',
      'D4rtResult': 'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'D4rtRunnerConfig':
          'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'D4rtRunner': 'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'AnsiColors':
          'package:tom_build_cli/src/tom/execution/output_formatter.dart',
      'OutputFormatterConfig':
          'package:tom_build_cli/src/tom/execution/output_formatter.dart',
      'ErrorMessage':
          'package:tom_build_cli/src/tom/execution/output_formatter.dart',
      'ProgressIndicator':
          'package:tom_build_cli/src/tom/execution/output_formatter.dart',
      'OutputFormatter':
          'package:tom_build_cli/src/tom/execution/output_formatter.dart',
      'BuildOrderProject':
          'package:tom_build_cli/src/tom/generation/build_order.dart',
      'BuildOrderResult':
          'package:tom_build_cli/src/tom/generation/build_order.dart',
      'CircularDependencyException':
          'package:tom_build_cli/src/tom/generation/build_order.dart',
      'BuildOrderCalculator':
          'package:tom_build_cli/src/tom/generation/build_order.dart',
      'GeneratorResult':
          'package:tom_build_cli/src/tom/generation/generator_placeholder.dart',
      'GeneratorResolutionException':
          'package:tom_build_cli/src/tom/generation/generator_placeholder.dart',
      'GeneratorPlaceholderResolver':
          'package:tom_build_cli/src/tom/generation/generator_placeholder.dart',
      'MasterGeneratorConfig':
          'package:tom_build_cli/src/tom/generation/master_generator.dart',
      'MasterGenerationResult':
          'package:tom_build_cli/src/tom/generation/master_generator.dart',
      'MasterGenerator':
          'package:tom_build_cli/src/tom/generation/master_generator.dart',
      'PlaceholderResult':
          'package:tom_build_cli/src/tom/generation/placeholder_resolver.dart',
      'GeneratorPlaceholderException':
          'package:tom_build_cli/src/tom/generation/placeholder_resolver.dart',
      'PlaceholderResolver':
          'package:tom_build_cli/src/tom/generation/placeholder_resolver.dart',
      'ModeProcessor': 'package:tom_build_cli/src/tom/mode/mode_processor.dart',
      'ModeResolver': 'package:tom_build_cli/src/tom/mode/mode_resolver.dart',
      'ResolvedModes': 'package:tom_build_cli/src/tom/mode/mode_resolver.dart',
      'TomplateParser':
          'package:tom_build_cli/src/tom/template/tomplate_parser.dart',
      'TomplateFile':
          'package:tom_build_cli/src/tom/template/tomplate_parser.dart',
      'PlaceholderInfo':
          'package:tom_build_cli/src/tom/template/tomplate_parser.dart',
      'TomplateProcessor':
          'package:tom_build_cli/src/tom/template/tomplate_processor.dart',
      'TomplateResult':
          'package:tom_build_cli/src/tom/template/tomplate_processor.dart',
      'PlaceholderResolutionException':
          'package:tom_build_cli/src/tom/template/tomplate_processor.dart',
      'ToolPrefix': 'package:tom_build_cli/src/tools/cli_args.dart',
      'CliArgs': 'package:tom_build_cli/src/tools/cli_args.dart',
      'PipelineDefinition': 'package:tom_build_cli/src/tools/pipeline.dart',
      'PipelineResult': 'package:tom_build_cli/src/tools/pipeline.dart',
      'PipelineLoader': 'package:tom_build_cli/src/tools/pipeline.dart',
      'PipelineRunner': 'package:tom_build_cli/src/tools/pipeline.dart',
      'PackageInfo':
          'package:tom_build_cli/src/tools/placeholder_resolver.dart',
      'TomPlaceholderResolver':
          'package:tom_build_cli/src/tools/placeholder_resolver.dart',
      'ParsedCommand':
          'package:tom_build_cli/src/tools/tom_command_parser.dart',
      'ParsedTomCommand':
          'package:tom_build_cli/src/tools/tom_command_parser.dart',
      'TomCommandParser':
          'package:tom_build_cli/src/tools/tom_command_parser.dart',
      'TomRunResult': 'package:tom_build_cli/src/tools/tom_runner.dart',
      'TomRunResults': 'package:tom_build_cli/src/tools/tom_runner.dart',
      'TomRunner': 'package:tom_build_cli/src/tools/tom_runner.dart',
      'TemplateParser':
          'package:tom_build_cli/src/ws_prepper/template_parser.dart',
      'ParsedTemplate':
          'package:tom_build_cli/src/ws_prepper/template_parser.dart',
      'TemplateSegment':
          'package:tom_build_cli/src/ws_prepper/template_parser.dart',
      'TextSegment':
          'package:tom_build_cli/src/ws_prepper/template_parser.dart',
      'ModeBlockGroup':
          'package:tom_build_cli/src/ws_prepper/template_parser.dart',
      'ModeBlock': 'package:tom_build_cli/src/ws_prepper/template_parser.dart',
      'WsPrepper': 'package:tom_build_cli/src/ws_prepper/ws_prepper.dart',
      'WsPrepperOptions':
          'package:tom_build_cli/src/ws_prepper/ws_prepper.dart',
      'WsPrepperResult': 'package:tom_build_cli/src/ws_prepper/ws_prepper.dart',
      'PreparedTemplate':
          'package:tom_build_cli/src/ws_prepper/ws_prepper.dart',
      'WsPrepperError': 'package:tom_build_cli/src/ws_prepper/ws_prepper.dart',
      'TomD4rtRepl': 'package:tom_build_cli/src/tom_d4rt/tom_d4rt_repl.dart',
      'Tom': 'package:tom_build_cli/src/tom_cli_api/tom_api.dart',
      'TomWorkspace':
          'package:tom_build/src/tom/file_object_model/file_object_model.dart',
      'TomProject':
          'package:tom_build/src/tom/file_object_model/file_object_model.dart',
    };
  }

  /// Returns all bridged enum definitions.
  static List<BridgedEnumDefinition> bridgedEnums() {
    return [
      BridgedEnumDefinition<$tom_build_cli_10.BumpType>(
        name: 'BumpType',
        values: $tom_build_cli_10.BumpType.values,
      ),
      BridgedEnumDefinition<$tom_build_cli_17.D4rtCommandType>(
        name: 'D4rtCommandType',
        values: $tom_build_cli_17.D4rtCommandType.values,
      ),
      BridgedEnumDefinition<$tom_build_cli_25.PlaceholderType>(
        name: 'PlaceholderType',
        values: $tom_build_cli_25.PlaceholderType.values,
      ),
      BridgedEnumDefinition<$tom_build_cli_28.TomExecutionMode>(
        name: 'TomExecutionMode',
        values: $tom_build_cli_28.TomExecutionMode.values,
      ),
    ];
  }

  /// Returns a map of enum names to their canonical source URIs.
  ///
  /// Used for deduplication when the same enum is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> enumSourceUris() {
    return {
      'BumpType': 'package:tom_build_cli/src/tom/cli/version_bumper.dart',
      'D4rtCommandType':
          'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'PlaceholderType':
          'package:tom_build_cli/src/tom/template/tomplate_parser.dart',
      'TomExecutionMode':
          'package:tom_build_cli/src/tom_d4rt/tom_d4rt_main.dart',
    };
  }

  /// Returns all bridged extension definitions.
  static List<BridgedExtensionDefinition> bridgedExtensions() {
    return [
      BridgedExtensionDefinition(
        name: 'ParsedArgumentsExtensions',
        onTypeName: 'ParsedArguments',
        getters: {
          'actionNames': (visitor, target) =>
              (target as $tom_build_cli_6.ParsedArguments).actionNames,
          'hasInternalCommands': (visitor, target) =>
              (target as $tom_build_cli_6.ParsedArguments).hasInternalCommands,
        },
        methods: {
          'getActionParameters':
              (visitor, target, positional, named, typeArgs) {
                final t = target as $tom_build_cli_6.ParsedArguments;
                return Function.apply(
                  t.getActionParameters,
                  positional,
                  named.map((k, v) => MapEntry(Symbol(k), v)),
                );
              },
        },
      ),
      BridgedExtensionDefinition(
        name: 'D4rtCommandExtension',
        onTypeName: 'String',
        getters: {
          'isD4rtCommand': (visitor, target) =>
              (target as String).isD4rtCommand,
          'isVSCodeCommand': (visitor, target) =>
              (target as String).isVSCodeCommand,
          'vscodeCommandPort': (visitor, target) =>
              (target as String).vscodeCommandPort,
          'vscodeCommandBody': (visitor, target) =>
              (target as String).vscodeCommandBody,
          'isLocalD4rtCommand': (visitor, target) =>
              (target as String).isLocalD4rtCommand,
          'isVSCodeSimpleCommand': (visitor, target) =>
              (target as String).isVSCodeSimpleCommand,
          'vscodeSimpleCommandPort': (visitor, target) =>
              (target as String).vscodeSimpleCommandPort,
          'vscodeSimpleCommandBody': (visitor, target) =>
              (target as String).vscodeSimpleCommandBody,
          'isDartscriptSimpleCommand': (visitor, target) =>
              (target as String).isDartscriptSimpleCommand,
          'dartscriptSimpleCommandPort': (visitor, target) =>
              (target as String).dartscriptSimpleCommandPort,
          'dartscriptSimpleCommandBody': (visitor, target) =>
              (target as String).dartscriptSimpleCommandBody,
          'isTomCommand': (visitor, target) => (target as String).isTomCommand,
          'tomCommandArgs': (visitor, target) =>
              (target as String).tomCommandArgs,
          'tomCommandArgsList': (visitor, target) =>
              (target as String).tomCommandArgsList,
        },
      ),
      BridgedExtensionDefinition(
        name: 'CommandResultExtensions',
        onTypeName: 'List',
        getters: {
          'allSucceeded': (visitor, target) =>
              (target as List<$tom_build_cli_16.CommandResult>).allSucceeded,
          'firstFailure': (visitor, target) =>
              (target as List<$tom_build_cli_16.CommandResult>).firstFailure,
          'totalDuration': (visitor, target) =>
              (target as List<$tom_build_cli_16.CommandResult>).totalDuration,
        },
      ),
      BridgedExtensionDefinition(
        name: 'PipelineCommands',
        onTypeName: 'TomRunner',
        methods: {
          'runPipeline': (visitor, target, positional, named, typeArgs) {
            final t = target as $tom_build_cli_34.TomRunner;
            return Function.apply(
              t.runPipeline,
              positional,
              named.map((k, v) => MapEntry(Symbol(k), v)),
            );
          },
        },
      ),
    ];
  }

  /// Returns a map of extension identifiers to their canonical source URIs.
  static Map<String, String> extensionSourceUris() {
    return {
      'ParsedArgumentsExtensions':
          'package:tom_build_cli/src/tom/cli/argument_parser.dart',
      'D4rtCommandExtension':
          'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'CommandResultExtensions':
          'package:tom_build_cli/src/tom/execution/command_runner.dart',
      'PipelineCommands': 'package:tom_build_cli/src/tools/pipeline.dart',
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
      interpreter.registerBridgedClass(
        bridge,
        importPath,
        sourceUri: classSources[bridge.name],
      );
    }

    // Register bridged enums with source URIs for deduplication
    final enums = bridgedEnums();
    final enumSources = enumSourceUris();
    for (final enumDef in enums) {
      interpreter.registerBridgedEnum(
        enumDef,
        importPath,
        sourceUri: enumSources[enumDef.name],
      );
    }

    // Register global variables
    registerGlobalVariables(interpreter, importPath);

    // Register global functions with source URIs for deduplication
    final funcs = globalFunctions();
    final funcSources = globalFunctionSourceUris();
    final funcSigs = globalFunctionSignatures();
    for (final entry in funcs.entries) {
      interpreter.registertopLevelFunction(
        entry.key,
        entry.value,
        importPath,
        sourceUri: funcSources[entry.key],
        signature: funcSigs[entry.key],
      );
    }

    // Register bridged extensions with source URIs for deduplication
    final extensions = bridgedExtensions();
    final extSources = extensionSourceUris();
    for (final extDef in extensions) {
      final extKey = extDef.name ?? '<unnamed>@${extDef.onTypeName}';
      interpreter.registerBridgedExtension(
        extDef,
        importPath,
        sourceUri: extSources[extKey],
      );
    }
  }

  /// Registers all global variables with the interpreter.
  ///
  /// [importPath] is the package import path for library-scoped registration.
  /// Collects all registration errors and throws a single exception
  /// with all error details if any registrations fail.
  static void registerGlobalVariables(D4rt interpreter, String importPath) {
    final errors = <String>[];

    try {
      interpreter.registerGlobalVariable(
        'cliGlobalVariables',
        $tom_build_cli_2.cliGlobalVariables,
        importPath,
        sourceUri:
            'package:tom_build_cli/src/dartscript/d4rt_cli_initialization.dart',
      );
    } catch (e) {
      errors.add('Failed to register variable "cliGlobalVariables": $e');
    }
    try {
      interpreter.registerGlobalVariable(
        'd4rtInstanceZoneKey',
        $tom_build_cli_5.d4rtInstanceZoneKey,
        importPath,
        sourceUri: 'package:tom_build_cli/src/dartscript/d4rt_instance.dart',
      );
    } catch (e) {
      errors.add('Failed to register variable "d4rtInstanceZoneKey": $e');
    }
    try {
      interpreter.registerGlobalVariable(
        'knownCommands',
        $tom_build_cli_33.knownCommands,
        importPath,
        sourceUri: 'package:tom_build_cli/src/tools/tom_command_parser.dart',
      );
    } catch (e) {
      errors.add('Failed to register variable "knownCommands": $e');
    }

    if (errors.isNotEmpty) {
      throw StateError(
        'Bridge registration errors (tom_build_cli):\n${errors.join("\n")}',
      );
    }
  }

  /// Returns a map of global function names to their native implementations.
  static Map<String, NativeFunctionImpl> globalFunctions() {
    return {
      'getCliInitializationScript': (visitor, positional, named, typeArgs) {
        return $tom_build_cli_2.getCliInitializationScript();
      },
      'getCliImportsOnly': (visitor, positional, named, typeArgs) {
        return $tom_build_cli_2.getCliImportsOnly();
      },
      'getCliGlobalVariablesOnly': (visitor, positional, named, typeArgs) {
        return $tom_build_cli_2.getCliGlobalVariablesOnly();
      },
      'getProjectClearScript': (visitor, positional, named, typeArgs) {
        return $tom_build_cli_2.getProjectClearScript();
      },
      'getProjectPrepareScript': (visitor, positional, named, typeArgs) {
        return $tom_build_cli_2.getProjectPrepareScript();
      },
      'createD4rtEvaluatorFromContext': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'createD4rtEvaluatorFromContext');
        final context = D4.getRequiredArg<$tom_build_cli_5.ActionD4rtContext>(
          positional,
          0,
          'context',
          'createD4rtEvaluatorFromContext',
        );
        return $tom_build_cli_5.createD4rtEvaluatorFromContext(context);
      },
      'runTomCli': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'runTomCli');
        final args = D4.getRequiredArg<List<String>>(
          positional,
          0,
          'args',
          'runTomCli',
        );
        return $tom_build_cli_9.runTomCli(args);
      },
      'parseBumpType': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'parseBumpType');
        final value = D4.getRequiredArg<String?>(
          positional,
          0,
          'value',
          'parseBumpType',
        );
        return $tom_build_cli_10.parseBumpType(value);
      },
      'discoverWorkspace': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'discoverWorkspace');
        final startPath = D4.getRequiredArg<String>(
          positional,
          0,
          'startPath',
          'discoverWorkspace',
        );
        return $tom_build_cli_11.discoverWorkspace(startPath);
      },
      'discoverProjects': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'discoverProjects');
        final workspacePath = D4.getRequiredArg<String>(
          positional,
          0,
          'workspacePath',
          'discoverProjects',
        );
        final workspace = D4.getRequiredArg<$tom_build_1.TomWorkspace>(
          positional,
          1,
          'workspace',
          'discoverProjects',
        );
        return $tom_build_cli_11.discoverProjects(workspacePath, workspace);
      },
      'mergeStringLists': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'mergeStringLists');
        final base = D4.getRequiredArg<List<String>?>(
          positional,
          0,
          'base',
          'mergeStringLists',
        );
        final override = D4.getRequiredArg<List<String>?>(
          positional,
          1,
          'override',
          'mergeStringLists',
        );
        return $tom_build_cli_13.mergeStringLists(base, override);
      },
      'mergeDeps': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'mergeDeps');
        final base = D4.getRequiredArg<Map<String, String>?>(
          positional,
          0,
          'base',
          'mergeDeps',
        );
        final override = D4.getRequiredArg<Map<String, String>?>(
          positional,
          1,
          'override',
          'mergeDeps',
        );
        return $tom_build_cli_13.mergeDeps(base, override);
      },
      'createRealD4rtEvaluator': (visitor, positional, named, typeArgs) {
        final globalContext = D4.getOptionalNamedArg<Map<String, dynamic>?>(
          named,
          'globalContext',
        );
        final bridgeConfiguration = D4
            .getOptionalNamedArg<$tom_build_cli_1.BridgeConfiguration?>(
              named,
              'bridgeConfiguration',
            );
        final workspace = D4.getOptionalNamedArg<$tom_build_1.TomWorkspace?>(
          named,
          'workspace',
        );
        final workspaceContext = D4
            .getOptionalNamedArg<$tom_build_cli_11.WorkspaceContext?>(
              named,
              'workspaceContext',
            );
        final currentProject = D4.getOptionalNamedArg<$tom_build_1.TomProject?>(
          named,
          'currentProject',
        );
        final workspacePath = D4.getOptionalNamedArg<String?>(
          named,
          'workspacePath',
        );
        return $tom_build_cli_17.createRealD4rtEvaluator(
          globalContext: globalContext,
          bridgeConfiguration: bridgeConfiguration,
          workspace: workspace,
          workspaceContext: workspaceContext,
          currentProject: currentProject,
          workspacePath: workspacePath,
        );
      },
      'createEvaluatorFromContext': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'createEvaluatorFromContext');
        final actionContext = D4
            .getRequiredArg<$tom_build_cli_5.ActionD4rtContext>(
              positional,
              0,
              'actionContext',
              'createEvaluatorFromContext',
            );
        return $tom_build_cli_17.createEvaluatorFromContext(actionContext);
      },
      'splitShellArgs': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'splitShellArgs');
        final command = D4.getRequiredArg<String>(
          positional,
          0,
          'command',
          'splitShellArgs',
        );
        return $tom_build_cli_17.splitShellArgs(command);
      },
      'parseWsPrepperArgs': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'parseWsPrepperArgs');
        final args = D4.getRequiredArg<List<String>>(
          positional,
          0,
          'args',
          'parseWsPrepperArgs',
        );
        return $tom_build_cli_30.parseWsPrepperArgs(args);
      },
      'parseWorkspaceAnalyzerArgs': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'parseWorkspaceAnalyzerArgs');
        final args = D4.getRequiredArg<List<String>>(
          positional,
          0,
          'args',
          'parseWorkspaceAnalyzerArgs',
        );
        return $tom_build_cli_30.parseWorkspaceAnalyzerArgs(args);
      },
      'parseReflectionGeneratorArgs': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'parseReflectionGeneratorArgs');
        final args = D4.getRequiredArg<List<String>>(
          positional,
          0,
          'args',
          'parseReflectionGeneratorArgs',
        );
        return $tom_build_cli_30.parseReflectionGeneratorArgs(args);
      },
      'loadEnvironmentWithDotEnv': (visitor, positional, named, typeArgs) {
        final dotEnvPath = positional.isNotEmpty
            ? positional[0] as String?
            : null;
        return $tom_build_cli_32.loadEnvironmentWithDotEnv(dotEnvPath);
      },
      'parseTomCommand': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'parseTomCommand');
        final args = D4.getRequiredArg<List<String>>(
          positional,
          0,
          'args',
          'parseTomCommand',
        );
        final additionalCommands = D4.getOptionalNamedArg<Set<String>?>(
          named,
          'additionalCommands',
        );
        return $tom_build_cli_33.parseTomCommand(
          args,
          additionalCommands: additionalCommands,
        );
      },
      'determineExecutionMode': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'determineExecutionMode');
        final args = D4.getRequiredArg<List<String>>(
          positional,
          0,
          'args',
          'determineExecutionMode',
        );
        return $tom_build_cli_28.determineExecutionMode(args);
      },
      'runTomD4rt': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'runTomD4rt');
        final args = D4.getRequiredArg<List<String>>(
          positional,
          0,
          'args',
          'runTomD4rt',
        );
        return $tom_build_cli_28.runTomD4rt(args);
      },
      'runTomFromRepl': (visitor, positional, named, typeArgs) {
        if (!named.containsKey('args') || named['args'] == null) {
          throw ArgumentError(
            'runTomFromRepl: Missing required named argument "args"',
          );
        }
        final args = D4.coerceList<String>(named['args'], 'args');
        final cwd = D4.getRequiredNamedArg<String>(
          named,
          'cwd',
          'runTomFromRepl',
        );
        return $tom_build_cli_28.runTomFromRepl(args: args, cwd: cwd);
      },
    };
  }

  /// Returns a map of global function names to their canonical source URIs.
  ///
  /// Used for deduplication when the same function is exported through
  /// multiple barrels (e.g., tom_core_kernel and tom_core_server).
  static Map<String, String> globalFunctionSourceUris() {
    return {
      'getCliInitializationScript':
          'package:tom_build_cli/src/dartscript/d4rt_cli_initialization.dart',
      'getCliImportsOnly':
          'package:tom_build_cli/src/dartscript/d4rt_cli_initialization.dart',
      'getCliGlobalVariablesOnly':
          'package:tom_build_cli/src/dartscript/d4rt_cli_initialization.dart',
      'getProjectClearScript':
          'package:tom_build_cli/src/dartscript/d4rt_cli_initialization.dart',
      'getProjectPrepareScript':
          'package:tom_build_cli/src/dartscript/d4rt_cli_initialization.dart',
      'createD4rtEvaluatorFromContext':
          'package:tom_build_cli/src/dartscript/d4rt_instance.dart',
      'runTomCli': 'package:tom_build_cli/src/tom/cli/tom_cli.dart',
      'parseBumpType': 'package:tom_build_cli/src/tom/cli/version_bumper.dart',
      'discoverWorkspace':
          'package:tom_build_cli/src/tom/cli/workspace_context.dart',
      'discoverProjects':
          'package:tom_build_cli/src/tom/cli/workspace_context.dart',
      'mergeStringLists':
          'package:tom_build_cli/src/tom/config/config_merger.dart',
      'mergeDeps': 'package:tom_build_cli/src/tom/config/config_merger.dart',
      'createRealD4rtEvaluator':
          'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'createEvaluatorFromContext':
          'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'splitShellArgs':
          'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'parseWsPrepperArgs': 'package:tom_build_cli/src/tools/cli_args.dart',
      'parseWorkspaceAnalyzerArgs':
          'package:tom_build_cli/src/tools/cli_args.dart',
      'parseReflectionGeneratorArgs':
          'package:tom_build_cli/src/tools/cli_args.dart',
      'loadEnvironmentWithDotEnv':
          'package:tom_build_cli/src/tools/placeholder_resolver.dart',
      'parseTomCommand':
          'package:tom_build_cli/src/tools/tom_command_parser.dart',
      'determineExecutionMode':
          'package:tom_build_cli/src/tom_d4rt/tom_d4rt_main.dart',
      'runTomD4rt': 'package:tom_build_cli/src/tom_d4rt/tom_d4rt_main.dart',
      'runTomFromRepl': 'package:tom_build_cli/src/tom_d4rt/tom_d4rt_main.dart',
    };
  }

  /// Returns a map of global function names to their display signatures.
  static Map<String, String> globalFunctionSignatures() {
    return {
      'getCliInitializationScript': 'String getCliInitializationScript()',
      'getCliImportsOnly': 'String getCliImportsOnly()',
      'getCliGlobalVariablesOnly': 'String getCliGlobalVariablesOnly()',
      'getProjectClearScript': 'String getProjectClearScript()',
      'getProjectPrepareScript': 'String getProjectPrepareScript()',
      'createD4rtEvaluatorFromContext':
          'D4rtEvaluatorFunction createD4rtEvaluatorFromContext(ActionD4rtContext context)',
      'runTomCli': 'Future<int> runTomCli(List<String> args)',
      'parseBumpType': 'BumpType parseBumpType(String? value)',
      'discoverWorkspace':
          'WorkspaceDiscoveryResult discoverWorkspace(String startPath)',
      'discoverProjects':
          'Future<Map<String, TomProject>> discoverProjects(String workspacePath, TomWorkspace workspace)',
      'mergeStringLists':
          'List<String> mergeStringLists(List<String>? base, List<String>? override)',
      'mergeDeps':
          'Map<String, String> mergeDeps(Map<String, String>? base, Map<String, String>? override)',
      'createRealD4rtEvaluator':
          'ActionD4rtEvaluator createRealD4rtEvaluator({Map<String, dynamic>? globalContext, BridgeConfiguration? bridgeConfiguration, TomWorkspace? workspace, WorkspaceContext? workspaceContext, TomProject? currentProject, String? workspacePath})',
      'createEvaluatorFromContext':
          'ActionD4rtEvaluator createEvaluatorFromContext(ActionD4rtContext actionContext)',
      'splitShellArgs': 'List<String> splitShellArgs(String command)',
      'parseWsPrepperArgs': 'CliArgs parseWsPrepperArgs(List<String> args)',
      'parseWorkspaceAnalyzerArgs':
          'CliArgs parseWorkspaceAnalyzerArgs(List<String> args)',
      'parseReflectionGeneratorArgs':
          'CliArgs parseReflectionGeneratorArgs(List<String> args)',
      'loadEnvironmentWithDotEnv':
          'Map<String, String> loadEnvironmentWithDotEnv([String? dotEnvPath])',
      'parseTomCommand':
          'ParsedTomCommand parseTomCommand(List<String> args, {Set<String>? additionalCommands})',
      'determineExecutionMode':
          'TomExecutionMode determineExecutionMode(List<String> args)',
      'runTomD4rt': 'Future<int> runTomD4rt(List<String> args)',
      'runTomFromRepl':
          'Future<void> runTomFromRepl({required List<String> args, required String cwd})',
    };
  }

  /// Returns the list of canonical source library URIs.
  ///
  /// These are the actual source locations of all elements in this bridge,
  /// used for deduplication when the same libraries are exported through
  /// multiple barrels.
  static List<String> sourceLibraries() {
    return [
      'package:tom_build/src/tom/file_object_model/file_object_model.dart',
      'package:tom_build_cli/src/dartscript/bridge_configuration.dart',
      'package:tom_build_cli/src/dartscript/d4rt_cli_initialization.dart',
      'package:tom_build_cli/src/dartscript/d4rt_context_provider.dart',
      'package:tom_build_cli/src/dartscript/d4rt_globals.dart',
      'package:tom_build_cli/src/dartscript/d4rt_instance.dart',
      'package:tom_build_cli/src/tom/cli/argument_parser.dart',
      'package:tom_build_cli/src/tom/cli/git_helper.dart',
      'package:tom_build_cli/src/tom/cli/internal_commands.dart',
      'package:tom_build_cli/src/tom/cli/tom_cli.dart',
      'package:tom_build_cli/src/tom/cli/version_bumper.dart',
      'package:tom_build_cli/src/tom/cli/workspace_context.dart',
      'package:tom_build_cli/src/tom/config/config_loader.dart',
      'package:tom_build_cli/src/tom/config/config_merger.dart',
      'package:tom_build_cli/src/tom/config/validation.dart',
      'package:tom_build_cli/src/tom/execution/action_executor.dart',
      'package:tom_build_cli/src/tom/execution/command_runner.dart',
      'package:tom_build_cli/src/tom/execution/d4rt_runner.dart',
      'package:tom_build_cli/src/tom/execution/output_formatter.dart',
      'package:tom_build_cli/src/tom/generation/build_order.dart',
      'package:tom_build_cli/src/tom/generation/generator_placeholder.dart',
      'package:tom_build_cli/src/tom/generation/master_generator.dart',
      'package:tom_build_cli/src/tom/generation/placeholder_resolver.dart',
      'package:tom_build_cli/src/tom/mode/mode_processor.dart',
      'package:tom_build_cli/src/tom/mode/mode_resolver.dart',
      'package:tom_build_cli/src/tom/template/tomplate_parser.dart',
      'package:tom_build_cli/src/tom/template/tomplate_processor.dart',
      'package:tom_build_cli/src/tom_cli_api/tom_api.dart',
      'package:tom_build_cli/src/tom_d4rt/tom_d4rt_main.dart',
      'package:tom_build_cli/src/tom_d4rt/tom_d4rt_repl.dart',
      'package:tom_build_cli/src/tools/cli_args.dart',
      'package:tom_build_cli/src/tools/pipeline.dart',
      'package:tom_build_cli/src/tools/placeholder_resolver.dart',
      'package:tom_build_cli/src/tools/tom_command_parser.dart',
      'package:tom_build_cli/src/tools/tom_runner.dart',
      'package:tom_build_cli/src/ws_prepper/template_parser.dart',
      'package:tom_build_cli/src/ws_prepper/ws_prepper.dart',
    ];
  }

  /// Returns the import statement needed for D4rt scripts.
  ///
  /// Use this in your D4rt initialization script to make all
  /// bridged classes available to scripts.
  static String getImportBlock() {
    final imports = StringBuffer();
    imports.writeln("import 'package:tom_build_cli/tom_build_cli.dart';");
    imports.writeln("import 'package:tom_build/tom_build.dart';");
    return imports.toString();
  }

  /// Returns barrel import URIs for sub-packages discovered through re-exports.
  ///
  /// When a module follows re-exports into sub-packages (e.g., dcli re-exports
  /// dcli_core), D4rt scripts may import those sub-packages directly.
  /// These barrels need to be registered with the interpreter separately
  /// so that module resolution finds content for those URIs.
  static List<String> subPackageBarrels() {
    return ['package:tom_build/tom_build.dart'];
  }

  /// Returns a list of bridged enum names.
  static List<String> get enumNames => [
    'BumpType',
    'D4rtCommandType',
    'PlaceholderType',
    'TomExecutionMode',
  ];
}

// =============================================================================
// BridgeConfiguration Bridge
// =============================================================================

BridgedClass _createBridgeConfigurationBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_1.BridgeConfiguration,
    name: 'BridgeConfiguration',
    constructors: {
      '': (visitor, positional, named) {
        final bridgeModules =
            named.containsKey('bridgeModules') && named['bridgeModules'] != null
            ? D4.coerceList<String>(named['bridgeModules'], 'bridgeModules')
            : const <String>[];
        final additionalClasses =
            named.containsKey('additionalClasses') &&
                named['additionalClasses'] != null
            ? D4.coerceList<$tom_d4rt_1.BridgedClass>(
                named['additionalClasses'],
                'additionalClasses',
              )
            : const <$tom_d4rt_1.BridgedClass>[];
        final additionalClassImportPath = D4.getOptionalNamedArg<String?>(
          named,
          'additionalClassImportPath',
        );
        return $tom_build_cli_1.BridgeConfiguration(
          bridgeModules: bridgeModules,
          additionalClasses: additionalClasses,
          additionalClassImportPath: additionalClassImportPath,
        );
      },
    },
    getters: {
      'bridgeModules': (visitor, target) => D4
          .validateTarget<$tom_build_cli_1.BridgeConfiguration>(
            target,
            'BridgeConfiguration',
          )
          .bridgeModules,
      'additionalClasses': (visitor, target) => D4
          .validateTarget<$tom_build_cli_1.BridgeConfiguration>(
            target,
            'BridgeConfiguration',
          )
          .additionalClasses,
      'additionalClassImportPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_1.BridgeConfiguration>(
            target,
            'BridgeConfiguration',
          )
          .additionalClassImportPath,
    },
    methods: {
      'apply': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_1.BridgeConfiguration>(
          target,
          'BridgeConfiguration',
        );
        D4.requireMinArgs(positional, 1, 'apply');
        final interpreter = D4.getRequiredArg<$tom_d4rt_2.D4rt>(
          positional,
          0,
          'interpreter',
          'apply',
        );
        t.apply(interpreter);
        return null;
      },
      'withModules': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_1.BridgeConfiguration>(
          target,
          'BridgeConfiguration',
        );
        D4.requireMinArgs(positional, 1, 'withModules');
        if (positional.isEmpty) {
          throw ArgumentError(
            'withModules: Missing required argument "modules" at position 0',
          );
        }
        final modules = D4.coerceList<String>(positional[0], 'modules');
        return t.withModules(modules);
      },
      'withClasses': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_1.BridgeConfiguration>(
          target,
          'BridgeConfiguration',
        );
        D4.requireMinArgs(positional, 1, 'withClasses');
        if (positional.isEmpty) {
          throw ArgumentError(
            'withClasses: Missing required argument "classes" at position 0',
          );
        }
        final classes = D4.coerceList<$tom_d4rt_1.BridgedClass>(
          positional[0],
          'classes',
        );
        final importPath = D4.getOptionalNamedArg<String?>(named, 'importPath');
        return t.withClasses(classes, importPath: importPath);
      },
    },
    staticGetters: {
      'empty': (visitor) => $tom_build_cli_1.BridgeConfiguration.empty,
    },
    constructorSignatures: {
      '': 'const BridgeConfiguration({List<String> bridgeModules = const [], List<BridgedClass> additionalClasses = const [], String? additionalClassImportPath})',
    },
    methodSignatures: {
      'apply': 'void apply(D4rt interpreter)',
      'withModules': 'BridgeConfiguration withModules(List<String> modules)',
      'withClasses':
          'BridgeConfiguration withClasses(List<BridgedClass> classes, {String? importPath})',
    },
    getterSignatures: {
      'bridgeModules': 'List<String> get bridgeModules',
      'additionalClasses': 'List<BridgedClass> get additionalClasses',
      'additionalClassImportPath': 'String? get additionalClassImportPath',
    },
    staticGetterSignatures: {'empty': 'dynamic get empty'},
  );
}

// =============================================================================
// BridgeModuleRegistry Bridge
// =============================================================================

BridgedClass _createBridgeModuleRegistryBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_1.BridgeModuleRegistry,
    name: 'BridgeModuleRegistry',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_1.BridgeModuleRegistry();
      },
    },
    staticGetters: {
      'registeredModules': (visitor) =>
          $tom_build_cli_1.BridgeModuleRegistry.registeredModules,
    },
    staticMethods: {
      'register': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 2, 'register');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'register',
        );
        if (positional.length <= 1) {
          throw ArgumentError(
            'register: Missing required argument "registrar" at position 1',
          );
        }
        final registrarRaw = positional[1];
        final registrar = ($tom_d4rt_2.D4rt p0) {
          D4.callInterpreterCallback(visitor, registrarRaw, [p0]);
        };
        return $tom_build_cli_1.BridgeModuleRegistry.register(name, registrar);
      },
      'get': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'get');
        final name = D4.getRequiredArg<String>(positional, 0, 'name', 'get');
        return $tom_build_cli_1.BridgeModuleRegistry.get(name);
      },
      'isRegistered': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'isRegistered');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'isRegistered',
        );
        return $tom_build_cli_1.BridgeModuleRegistry.isRegistered(name);
      },
      'clear': (visitor, positional, named, typeArgs) {
        return $tom_build_cli_1.BridgeModuleRegistry.clear();
      },
    },
    constructorSignatures: {'': 'BridgeModuleRegistry()'},
    staticMethodSignatures: {
      'register': 'void register(String name, void Function(D4rt) registrar)',
      'get': 'void Function(D4rt)? get(String name)',
      'isRegistered': 'bool isRegistered(String name)',
      'clear': 'void clear()',
    },
    staticGetterSignatures: {
      'registeredModules': 'List<String> get registeredModules',
    },
  );
}

// =============================================================================
// D4rtContextProvider Bridge
// =============================================================================

BridgedClass _createD4rtContextProviderBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_3.D4rtContextProvider,
    name: 'D4rtContextProvider',
    constructors: {},
    getters: {
      'importPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProvider>(
            target,
            'D4rtContextProvider',
          )
          .importPath,
      'initializeTomContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProvider>(
            target,
            'D4rtContextProvider',
          )
          .initializeTomContext,
      'workspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProvider>(
            target,
            'D4rtContextProvider',
          )
          .workspace,
      'workspaceContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProvider>(
            target,
            'D4rtContextProvider',
          )
          .workspaceContext,
      'currentProject': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProvider>(
            target,
            'D4rtContextProvider',
          )
          .currentProject,
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProvider>(
            target,
            'D4rtContextProvider',
          )
          .workspacePath,
    },
    methods: {
      'getContext': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.D4rtContextProvider>(
          target,
          'D4rtContextProvider',
        );
        return t.getContext();
      },
      'getBridgeConfiguration': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.D4rtContextProvider>(
          target,
          'D4rtContextProvider',
        );
        return t.getBridgeConfiguration();
      },
    },
    methodSignatures: {
      'getContext': 'Map<String, dynamic> getContext()',
      'getBridgeConfiguration': 'BridgeConfiguration? getBridgeConfiguration()',
    },
    getterSignatures: {
      'importPath': 'String get importPath',
      'initializeTomContext': 'bool get initializeTomContext',
      'workspace': 'TomWorkspace? get workspace',
      'workspaceContext': 'WorkspaceContext? get workspaceContext',
      'currentProject': 'TomProject? get currentProject',
      'workspacePath': 'String? get workspacePath',
    },
  );
}

// =============================================================================
// D4rtContextProviderDefaults Bridge
// =============================================================================

BridgedClass _createD4rtContextProviderDefaultsBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_3.D4rtContextProviderDefaults,
    name: 'D4rtContextProviderDefaults',
    constructors: {},
    getters: {
      'importPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProviderDefaults>(
            target,
            'D4rtContextProviderDefaults',
          )
          .importPath,
      'initializeTomContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProviderDefaults>(
            target,
            'D4rtContextProviderDefaults',
          )
          .initializeTomContext,
      'workspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProviderDefaults>(
            target,
            'D4rtContextProviderDefaults',
          )
          .workspace,
      'workspaceContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProviderDefaults>(
            target,
            'D4rtContextProviderDefaults',
          )
          .workspaceContext,
      'currentProject': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProviderDefaults>(
            target,
            'D4rtContextProviderDefaults',
          )
          .currentProject,
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.D4rtContextProviderDefaults>(
            target,
            'D4rtContextProviderDefaults',
          )
          .workspacePath,
    },
    methods: {
      'getBridgeConfiguration': (visitor, target, positional, named, typeArgs) {
        final t = D4
            .validateTarget<$tom_build_cli_3.D4rtContextProviderDefaults>(
              target,
              'D4rtContextProviderDefaults',
            );
        return t.getBridgeConfiguration();
      },
      'getContext': (visitor, target, positional, named, typeArgs) {
        final t = D4
            .validateTarget<$tom_build_cli_3.D4rtContextProviderDefaults>(
              target,
              'D4rtContextProviderDefaults',
            );
        return t.getContext();
      },
    },
    methodSignatures: {
      'getBridgeConfiguration': 'BridgeConfiguration? getBridgeConfiguration()',
      'getContext': 'Map<String, dynamic> getContext()',
    },
    getterSignatures: {
      'importPath': 'String get importPath',
      'initializeTomContext': 'bool get initializeTomContext',
      'workspace': 'TomWorkspace? get workspace',
      'workspaceContext': 'WorkspaceContext? get workspaceContext',
      'currentProject': 'TomProject? get currentProject',
      'workspacePath': 'String? get workspacePath',
    },
  );
}

// =============================================================================
// ActionContextProvider Bridge
// =============================================================================

BridgedClass _createActionContextProviderBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_3.ActionContextProvider,
    name: 'ActionContextProvider',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'ActionContextProvider',
        );
        final projectName = D4.getRequiredNamedArg<String>(
          named,
          'projectName',
          'ActionContextProvider',
        );
        final actionName = D4.getRequiredNamedArg<String>(
          named,
          'actionName',
          'ActionContextProvider',
        );
        final workspace = D4.getOptionalNamedArg<$tom_build_1.TomWorkspace?>(
          named,
          'workspace',
        );
        final currentProject = D4.getOptionalNamedArg<$tom_build_1.TomProject?>(
          named,
          'currentProject',
        );
        final workspaceContext = D4
            .getOptionalNamedArg<$tom_build_cli_11.WorkspaceContext?>(
              named,
              'workspaceContext',
            );
        final additionalContext =
            named.containsKey('additionalContext') &&
                named['additionalContext'] != null
            ? D4.coerceMap<String, dynamic>(
                named['additionalContext'],
                'additionalContext',
              )
            : const <String, dynamic>{};
        final bridgeConfiguration = D4
            .getOptionalNamedArg<$tom_build_cli_1.BridgeConfiguration?>(
              named,
              'bridgeConfiguration',
            );
        return $tom_build_cli_3.ActionContextProvider(
          workspacePath: workspacePath,
          projectName: projectName,
          actionName: actionName,
          workspace: workspace,
          currentProject: currentProject,
          workspaceContext: workspaceContext,
          additionalContext: additionalContext,
          bridgeConfiguration: bridgeConfiguration,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.ActionContextProvider>(
            target,
            'ActionContextProvider',
          )
          .workspacePath,
      'projectName': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.ActionContextProvider>(
            target,
            'ActionContextProvider',
          )
          .projectName,
      'actionName': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.ActionContextProvider>(
            target,
            'ActionContextProvider',
          )
          .actionName,
      'workspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.ActionContextProvider>(
            target,
            'ActionContextProvider',
          )
          .workspace,
      'currentProject': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.ActionContextProvider>(
            target,
            'ActionContextProvider',
          )
          .currentProject,
      'workspaceContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.ActionContextProvider>(
            target,
            'ActionContextProvider',
          )
          .workspaceContext,
      'additionalContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.ActionContextProvider>(
            target,
            'ActionContextProvider',
          )
          .additionalContext,
      'initializeTomContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.ActionContextProvider>(
            target,
            'ActionContextProvider',
          )
          .initializeTomContext,
      'importPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.ActionContextProvider>(
            target,
            'ActionContextProvider',
          )
          .importPath,
    },
    methods: {
      'getContext': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.ActionContextProvider>(
          target,
          'ActionContextProvider',
        );
        return t.getContext();
      },
      'getBridgeConfiguration': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.ActionContextProvider>(
          target,
          'ActionContextProvider',
        );
        return t.getBridgeConfiguration();
      },
    },
    constructorSignatures: {
      '': 'ActionContextProvider({required String workspacePath, required String projectName, required String actionName, TomWorkspace? workspace, TomProject? currentProject, WorkspaceContext? workspaceContext, Map<String, dynamic> additionalContext = const {}, BridgeConfiguration? bridgeConfiguration})',
    },
    methodSignatures: {
      'getContext': 'Map<String, dynamic> getContext()',
      'getBridgeConfiguration': 'BridgeConfiguration? getBridgeConfiguration()',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'projectName': 'String get projectName',
      'actionName': 'String get actionName',
      'workspace': 'TomWorkspace? get workspace',
      'currentProject': 'TomProject? get currentProject',
      'workspaceContext': 'WorkspaceContext? get workspaceContext',
      'additionalContext': 'Map<String, dynamic> get additionalContext',
      'initializeTomContext': 'bool get initializeTomContext',
      'importPath': 'String get importPath',
    },
  );
}

// =============================================================================
// TemplateContextProvider Bridge
// =============================================================================

BridgedClass _createTemplateContextProviderBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_3.TemplateContextProvider,
    name: 'TemplateContextProvider',
    constructors: {
      '': (visitor, positional, named) {
        final workspace = D4.getOptionalNamedArg<$tom_build_1.TomWorkspace?>(
          named,
          'workspace',
        );
        final project = D4.getOptionalNamedArg<$tom_build_1.TomProject?>(
          named,
          'project',
        );
        final resolvedModes = D4
            .getOptionalNamedArg<$tom_build_cli_24.ResolvedModes?>(
              named,
              'resolvedModes',
            );
        final workspacePath = D4.getOptionalNamedArg<String?>(
          named,
          'workspacePath',
        );
        return $tom_build_cli_3.TemplateContextProvider(
          workspace: workspace,
          project: project,
          resolvedModes: resolvedModes,
          workspacePath: workspacePath,
        );
      },
    },
    getters: {
      'workspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.TemplateContextProvider>(
            target,
            'TemplateContextProvider',
          )
          .workspace,
      'currentProject': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.TemplateContextProvider>(
            target,
            'TemplateContextProvider',
          )
          .currentProject,
      'project': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.TemplateContextProvider>(
            target,
            'TemplateContextProvider',
          )
          .project,
      'resolvedModes': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.TemplateContextProvider>(
            target,
            'TemplateContextProvider',
          )
          .resolvedModes,
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.TemplateContextProvider>(
            target,
            'TemplateContextProvider',
          )
          .workspacePath,
      'initializeTomContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.TemplateContextProvider>(
            target,
            'TemplateContextProvider',
          )
          .initializeTomContext,
      'importPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.TemplateContextProvider>(
            target,
            'TemplateContextProvider',
          )
          .importPath,
      'workspaceContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.TemplateContextProvider>(
            target,
            'TemplateContextProvider',
          )
          .workspaceContext,
    },
    methods: {
      'getContext': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.TemplateContextProvider>(
          target,
          'TemplateContextProvider',
        );
        return t.getContext();
      },
      'getBridgeConfiguration': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.TemplateContextProvider>(
          target,
          'TemplateContextProvider',
        );
        return t.getBridgeConfiguration();
      },
    },
    constructorSignatures: {
      '': 'TemplateContextProvider({TomWorkspace? workspace, TomProject? project, ResolvedModes? resolvedModes, String? workspacePath})',
    },
    methodSignatures: {
      'getContext': 'Map<String, dynamic> getContext()',
      'getBridgeConfiguration': 'BridgeConfiguration? getBridgeConfiguration()',
    },
    getterSignatures: {
      'workspace': 'TomWorkspace? get workspace',
      'currentProject': 'TomProject? get currentProject',
      'project': 'TomProject? get project',
      'resolvedModes': 'ResolvedModes? get resolvedModes',
      'workspacePath': 'String? get workspacePath',
      'initializeTomContext': 'bool get initializeTomContext',
      'importPath': 'String get importPath',
      'workspaceContext': 'WorkspaceContext? get workspaceContext',
    },
  );
}

// =============================================================================
// StandaloneContextProvider Bridge
// =============================================================================

BridgedClass _createStandaloneContextProviderBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_3.StandaloneContextProvider,
    name: 'StandaloneContextProvider',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'StandaloneContextProvider');
        if (positional.isEmpty) {
          throw ArgumentError(
            'StandaloneContextProvider: Missing required argument "customContext" at position 0',
          );
        }
        final customContext = D4.coerceMap<String, dynamic>(
          positional[0],
          'customContext',
        );
        final bridgeConfiguration = D4
            .getOptionalNamedArg<$tom_build_cli_1.BridgeConfiguration?>(
              named,
              'bridgeConfiguration',
            );
        final importPath = D4.getOptionalNamedArg<String?>(named, 'importPath');
        return $tom_build_cli_3.StandaloneContextProvider(
          customContext,
          bridgeConfiguration: bridgeConfiguration,
          importPath: importPath,
        );
      },
    },
    getters: {
      'customContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.StandaloneContextProvider>(
            target,
            'StandaloneContextProvider',
          )
          .customContext,
      'importPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.StandaloneContextProvider>(
            target,
            'StandaloneContextProvider',
          )
          .importPath,
      'initializeTomContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.StandaloneContextProvider>(
            target,
            'StandaloneContextProvider',
          )
          .initializeTomContext,
      'workspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.StandaloneContextProvider>(
            target,
            'StandaloneContextProvider',
          )
          .workspace,
      'workspaceContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.StandaloneContextProvider>(
            target,
            'StandaloneContextProvider',
          )
          .workspaceContext,
      'currentProject': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.StandaloneContextProvider>(
            target,
            'StandaloneContextProvider',
          )
          .currentProject,
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.StandaloneContextProvider>(
            target,
            'StandaloneContextProvider',
          )
          .workspacePath,
    },
    methods: {
      'getContext': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.StandaloneContextProvider>(
          target,
          'StandaloneContextProvider',
        );
        return t.getContext();
      },
      'getBridgeConfiguration': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.StandaloneContextProvider>(
          target,
          'StandaloneContextProvider',
        );
        return t.getBridgeConfiguration();
      },
    },
    constructorSignatures: {
      '': 'StandaloneContextProvider(Map<String, dynamic> customContext, {BridgeConfiguration? bridgeConfiguration, String? importPath})',
    },
    methodSignatures: {
      'getContext': 'Map<String, dynamic> getContext()',
      'getBridgeConfiguration': 'BridgeConfiguration? getBridgeConfiguration()',
    },
    getterSignatures: {
      'customContext': 'Map<String, dynamic> get customContext',
      'importPath': 'String get importPath',
      'initializeTomContext': 'bool get initializeTomContext',
      'workspace': 'TomWorkspace? get workspace',
      'workspaceContext': 'WorkspaceContext? get workspaceContext',
      'currentProject': 'TomProject? get currentProject',
      'workspacePath': 'String? get workspacePath',
    },
  );
}

// =============================================================================
// CompositeContextProvider Bridge
// =============================================================================

BridgedClass _createCompositeContextProviderBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_3.CompositeContextProvider,
    name: 'CompositeContextProvider',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'CompositeContextProvider');
        if (positional.isEmpty) {
          throw ArgumentError(
            'CompositeContextProvider: Missing required argument "providers" at position 0',
          );
        }
        final providers = D4.coerceList<$tom_build_cli_3.D4rtContextProvider>(
          positional[0],
          'providers',
        );
        return $tom_build_cli_3.CompositeContextProvider(providers);
      },
    },
    getters: {
      'providers': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.CompositeContextProvider>(
            target,
            'CompositeContextProvider',
          )
          .providers,
      'initializeTomContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.CompositeContextProvider>(
            target,
            'CompositeContextProvider',
          )
          .initializeTomContext,
      'workspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.CompositeContextProvider>(
            target,
            'CompositeContextProvider',
          )
          .workspace,
      'workspaceContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.CompositeContextProvider>(
            target,
            'CompositeContextProvider',
          )
          .workspaceContext,
      'currentProject': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.CompositeContextProvider>(
            target,
            'CompositeContextProvider',
          )
          .currentProject,
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.CompositeContextProvider>(
            target,
            'CompositeContextProvider',
          )
          .workspacePath,
      'importPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_3.CompositeContextProvider>(
            target,
            'CompositeContextProvider',
          )
          .importPath,
    },
    methods: {
      'getContext': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.CompositeContextProvider>(
          target,
          'CompositeContextProvider',
        );
        return t.getContext();
      },
      'getBridgeConfiguration': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_3.CompositeContextProvider>(
          target,
          'CompositeContextProvider',
        );
        return t.getBridgeConfiguration();
      },
    },
    constructorSignatures: {
      '': 'CompositeContextProvider(List<D4rtContextProvider> providers)',
    },
    methodSignatures: {
      'getContext': 'Map<String, dynamic> getContext()',
      'getBridgeConfiguration': 'BridgeConfiguration? getBridgeConfiguration()',
    },
    getterSignatures: {
      'providers': 'List<D4rtContextProvider> get providers',
      'initializeTomContext': 'bool get initializeTomContext',
      'workspace': 'TomWorkspace? get workspace',
      'workspaceContext': 'WorkspaceContext? get workspaceContext',
      'currentProject': 'TomProject? get currentProject',
      'workspacePath': 'String? get workspacePath',
      'importPath': 'String get importPath',
    },
  );
}

// =============================================================================
// D4rtGlobals Bridge
// =============================================================================

BridgedClass _createD4rtGlobalsBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_4.D4rtGlobals,
    name: 'D4rtGlobals',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_4.D4rtGlobals();
      },
    },
    staticGetters: {
      'tom': (visitor) => $tom_build_cli_4.D4rtGlobals.tom,
      'tomExecutionContext': (visitor) =>
          $tom_build_cli_4.D4rtGlobals.tomExecutionContext,
      'tomReflector': (visitor) => $tom_build_cli_4.D4rtGlobals.tomReflector,
      'tomComponent': (visitor) => $tom_build_cli_4.D4rtGlobals.tomComponent,
      'platformWeb': (visitor) => $tom_build_cli_4.D4rtGlobals.platformWeb,
      'platformMacos': (visitor) => $tom_build_cli_4.D4rtGlobals.platformMacos,
      'platformWindows': (visitor) =>
          $tom_build_cli_4.D4rtGlobals.platformWindows,
      'platformAndroid': (visitor) =>
          $tom_build_cli_4.D4rtGlobals.platformAndroid,
      'platformIos': (visitor) => $tom_build_cli_4.D4rtGlobals.platformIos,
      'platformLinux': (visitor) => $tom_build_cli_4.D4rtGlobals.platformLinux,
      'platformFuchsia': (visitor) =>
          $tom_build_cli_4.D4rtGlobals.platformFuchsia,
      'defaultTomEnvironment': (visitor) =>
          $tom_build_cli_4.D4rtGlobals.defaultTomEnvironment,
      'noTomEnvironment': (visitor) =>
          $tom_build_cli_4.D4rtGlobals.noTomEnvironment,
      'noTomPlatform': (visitor) => $tom_build_cli_4.D4rtGlobals.noTomPlatform,
    },
    constructorSignatures: {'': 'D4rtGlobals()'},
    staticGetterSignatures: {
      'tom': 'tom_ctx.TomContext get tom',
      'tomExecutionContext': 'core.TomExecutionContext get tomExecutionContext',
      'tomReflector': 'core.TomReflector get tomReflector',
      'tomComponent': 'core.TomComponent get tomComponent',
      'platformWeb': 'core.TomPlatform get platformWeb',
      'platformMacos': 'core.TomPlatform get platformMacos',
      'platformWindows': 'core.TomPlatform get platformWindows',
      'platformAndroid': 'core.TomPlatform get platformAndroid',
      'platformIos': 'core.TomPlatform get platformIos',
      'platformLinux': 'core.TomPlatform get platformLinux',
      'platformFuchsia': 'core.TomPlatform get platformFuchsia',
      'defaultTomEnvironment': 'core.TomEnvironment get defaultTomEnvironment',
      'noTomEnvironment': 'core.TomEnvironment get noTomEnvironment',
      'noTomPlatform': 'core.TomPlatform get noTomPlatform',
    },
  );
}

// =============================================================================
// D4rtInstance Bridge
// =============================================================================

BridgedClass _createD4rtInstanceBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_5.D4rtInstance,
    name: 'D4rtInstance',
    constructors: {
      'currentOrCreate': (visitor, positional, named) {
        final bridgeConfiguration = D4
            .getOptionalNamedArg<$tom_build_cli_1.BridgeConfiguration?>(
              named,
              'bridgeConfiguration',
            );
        final workspace = D4.getOptionalNamedArg<$tom_build_1.TomWorkspace?>(
          named,
          'workspace',
        );
        final workspaceContext = D4
            .getOptionalNamedArg<$tom_build_cli_11.WorkspaceContext?>(
              named,
              'workspaceContext',
            );
        final currentProject = D4.getOptionalNamedArg<$tom_build_1.TomProject?>(
          named,
          'currentProject',
        );
        final workspacePath = D4.getOptionalNamedArg<String?>(
          named,
          'workspacePath',
        );
        return $tom_build_cli_5.D4rtInstance.currentOrCreate(
          bridgeConfiguration: bridgeConfiguration,
          workspace: workspace,
          workspaceContext: workspaceContext,
          currentProject: currentProject,
          workspacePath: workspacePath,
        );
      },
      'create': (visitor, positional, named) {
        final bridgeConfiguration = D4
            .getOptionalNamedArg<$tom_build_cli_1.BridgeConfiguration?>(
              named,
              'bridgeConfiguration',
            );
        final workspace = D4.getOptionalNamedArg<$tom_build_1.TomWorkspace?>(
          named,
          'workspace',
        );
        final workspaceContext = D4
            .getOptionalNamedArg<$tom_build_cli_11.WorkspaceContext?>(
              named,
              'workspaceContext',
            );
        final currentProject = D4.getOptionalNamedArg<$tom_build_1.TomProject?>(
          named,
          'currentProject',
        );
        final workspacePath = D4.getOptionalNamedArg<String?>(
          named,
          'workspacePath',
        );
        return $tom_build_cli_5.D4rtInstance.create(
          bridgeConfiguration: bridgeConfiguration,
          workspace: workspace,
          workspaceContext: workspaceContext,
          currentProject: currentProject,
          workspacePath: workspacePath,
        );
      },
      'fromProvider': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'D4rtInstance');
        final provider = D4
            .getRequiredArg<$tom_build_cli_3.D4rtContextProvider>(
              positional,
              0,
              'provider',
              'D4rtInstance',
            );
        return $tom_build_cli_5.D4rtInstance.fromProvider(provider);
      },
    },
    getters: {
      'interpreter': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.D4rtInstance>(target, 'D4rtInstance')
          .interpreter,
      'isDisposed': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.D4rtInstance>(target, 'D4rtInstance')
          .isDisposed,
      'isInitialized': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.D4rtInstance>(target, 'D4rtInstance')
          .isInitialized,
      'context': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.D4rtInstance>(target, 'D4rtInstance')
          .context,
    },
    methods: {
      'setContext': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.D4rtInstance>(
          target,
          'D4rtInstance',
        );
        D4.requireMinArgs(positional, 2, 'setContext');
        final key = D4.getRequiredArg<String>(
          positional,
          0,
          'key',
          'setContext',
        );
        final value = D4.getRequiredArg<dynamic>(
          positional,
          1,
          'value',
          'setContext',
        );
        t.setContext(key, value);
        return null;
      },
      'setContextAll': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.D4rtInstance>(
          target,
          'D4rtInstance',
        );
        D4.requireMinArgs(positional, 1, 'setContextAll');
        if (positional.isEmpty) {
          throw ArgumentError(
            'setContextAll: Missing required argument "values" at position 0',
          );
        }
        final values = D4.coerceMap<String, dynamic>(positional[0], 'values');
        t.setContextAll(values);
        return null;
      },
      'prepareForScripts': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.D4rtInstance>(
          target,
          'D4rtInstance',
        );
        return t.prepareForScripts();
      },
      'evaluate': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.D4rtInstance>(
          target,
          'D4rtInstance',
        );
        D4.requireMinArgs(positional, 1, 'evaluate');
        final expression = D4.getRequiredArg<String>(
          positional,
          0,
          'expression',
          'evaluate',
        );
        return t.evaluate(expression);
      },
      'executeScript': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.D4rtInstance>(
          target,
          'D4rtInstance',
        );
        D4.requireMinArgs(positional, 1, 'executeScript');
        final scriptContent = D4.getRequiredArg<String>(
          positional,
          0,
          'scriptContent',
          'executeScript',
        );
        return t.executeScript(scriptContent);
      },
      'dispose': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.D4rtInstance>(
          target,
          'D4rtInstance',
        );
        t.dispose();
        return null;
      },
      'updateTomGlobal': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.D4rtInstance>(
          target,
          'D4rtInstance',
        );
        t.updateTomGlobal();
        return null;
      },
    },
    staticGetters: {
      'current': (visitor) => $tom_build_cli_5.D4rtInstance.current,
    },
    constructorSignatures: {
      'currentOrCreate':
          'factory D4rtInstance.currentOrCreate({BridgeConfiguration? bridgeConfiguration, TomWorkspace? workspace, WorkspaceContext? workspaceContext, TomProject? currentProject, String? workspacePath})',
      'create':
          'factory D4rtInstance.create({BridgeConfiguration? bridgeConfiguration, TomWorkspace? workspace, WorkspaceContext? workspaceContext, TomProject? currentProject, String? workspacePath})',
      'fromProvider':
          'factory D4rtInstance.fromProvider(D4rtContextProvider provider)',
    },
    methodSignatures: {
      'setContext': 'void setContext(String key, dynamic value)',
      'setContextAll': 'void setContextAll(Map<String, dynamic> values)',
      'prepareForScripts': 'Future<void> prepareForScripts()',
      'evaluate': 'Future<dynamic> evaluate(String expression)',
      'executeScript': 'Future<dynamic> executeScript(String scriptContent)',
      'dispose': 'void dispose()',
      'updateTomGlobal': 'void updateTomGlobal()',
    },
    getterSignatures: {
      'interpreter': 'D4rt get interpreter',
      'isDisposed': 'bool get isDisposed',
      'isInitialized': 'bool get isInitialized',
      'context': 'Map<String, dynamic> get context',
    },
    staticGetterSignatures: {'current': 'D4rtInstance? get current'},
  );
}

// =============================================================================
// ActionD4rtContext Bridge
// =============================================================================

BridgedClass _createActionD4rtContextBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_5.ActionD4rtContext,
    name: 'ActionD4rtContext',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'ActionD4rtContext',
        );
        final projectName = D4.getRequiredNamedArg<String>(
          named,
          'projectName',
          'ActionD4rtContext',
        );
        final actionName = D4.getRequiredNamedArg<String>(
          named,
          'actionName',
          'ActionD4rtContext',
        );
        final additionalContext =
            named.containsKey('additionalContext') &&
                named['additionalContext'] != null
            ? D4.coerceMap<String, dynamic>(
                named['additionalContext'],
                'additionalContext',
              )
            : const <String, dynamic>{};
        final bridgeConfiguration = D4
            .getOptionalNamedArg<$tom_build_cli_1.BridgeConfiguration?>(
              named,
              'bridgeConfiguration',
            );
        return $tom_build_cli_5.ActionD4rtContext(
          workspacePath: workspacePath,
          projectName: projectName,
          actionName: actionName,
          additionalContext: additionalContext,
          bridgeConfiguration: bridgeConfiguration,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.ActionD4rtContext>(
            target,
            'ActionD4rtContext',
          )
          .workspacePath,
      'projectName': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.ActionD4rtContext>(
            target,
            'ActionD4rtContext',
          )
          .projectName,
      'actionName': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.ActionD4rtContext>(
            target,
            'ActionD4rtContext',
          )
          .actionName,
      'additionalContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.ActionD4rtContext>(
            target,
            'ActionD4rtContext',
          )
          .additionalContext,
      'bridgeConfiguration': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.ActionD4rtContext>(
            target,
            'ActionD4rtContext',
          )
          .bridgeConfiguration,
      'instance': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.ActionD4rtContext>(
            target,
            'ActionD4rtContext',
          )
          .instance,
      'context': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.ActionD4rtContext>(
            target,
            'ActionD4rtContext',
          )
          .context,
      'isInstanceCreated': (visitor, target) => D4
          .validateTarget<$tom_build_cli_5.ActionD4rtContext>(
            target,
            'ActionD4rtContext',
          )
          .isInstanceCreated,
    },
    methods: {
      'evaluate': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.ActionD4rtContext>(
          target,
          'ActionD4rtContext',
        );
        D4.requireMinArgs(positional, 1, 'evaluate');
        final expression = D4.getRequiredArg<String>(
          positional,
          0,
          'expression',
          'evaluate',
        );
        return t.evaluate(expression);
      },
      'executeScript': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.ActionD4rtContext>(
          target,
          'ActionD4rtContext',
        );
        D4.requireMinArgs(positional, 1, 'executeScript');
        final scriptContent = D4.getRequiredArg<String>(
          positional,
          0,
          'scriptContent',
          'executeScript',
        );
        return t.executeScript(scriptContent);
      },
      'dispose': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_5.ActionD4rtContext>(
          target,
          'ActionD4rtContext',
        );
        t.dispose();
        return null;
      },
    },
    constructorSignatures: {
      '': 'ActionD4rtContext({required String workspacePath, required String projectName, required String actionName, Map<String, dynamic> additionalContext = const {}, BridgeConfiguration? bridgeConfiguration})',
    },
    methodSignatures: {
      'evaluate': 'Future<dynamic> evaluate(String expression)',
      'executeScript': 'Future<dynamic> executeScript(String scriptContent)',
      'dispose': 'void dispose()',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'projectName': 'String get projectName',
      'actionName': 'String get actionName',
      'additionalContext': 'Map<String, dynamic> get additionalContext',
      'bridgeConfiguration': 'BridgeConfiguration? get bridgeConfiguration',
      'instance': 'D4rtInstance get instance',
      'context': 'Map<String, dynamic> get context',
      'isInstanceCreated': 'bool get isInstanceCreated',
    },
  );
}

// =============================================================================
// ParsedArguments Bridge
// =============================================================================

BridgedClass _createParsedArgumentsBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_6.ParsedArguments,
    name: 'ParsedArguments',
    constructors: {
      '': (visitor, positional, named) {
        final globalParameters =
            named.containsKey('globalParameters') &&
                named['globalParameters'] != null
            ? D4.coerceMap<String, String>(
                named['globalParameters'],
                'globalParameters',
              )
            : const <String, String>{};
        final hasProjectsScope = D4.getNamedArgWithDefault<bool>(
          named,
          'hasProjectsScope',
          false,
        );
        final hasGroupsScope = D4.getNamedArgWithDefault<bool>(
          named,
          'hasGroupsScope',
          false,
        );
        final projects =
            named.containsKey('projects') && named['projects'] != null
            ? D4.coerceList<String>(named['projects'], 'projects')
            : const <String>[];
        final projectParameters =
            named.containsKey('projectParameters') &&
                named['projectParameters'] != null
            ? D4.coerceMap<String, Map<String, String>>(
                named['projectParameters'],
                'projectParameters',
              )
            : const <String, Map<String, String>>{};
        final groups = named.containsKey('groups') && named['groups'] != null
            ? D4.coerceList<String>(named['groups'], 'groups')
            : const <String>[];
        final groupParameters =
            named.containsKey('groupParameters') &&
                named['groupParameters'] != null
            ? D4.coerceMap<String, Map<String, String>>(
                named['groupParameters'],
                'groupParameters',
              )
            : const <String, Map<String, String>>{};
        final actions = named.containsKey('actions') && named['actions'] != null
            ? D4.coerceList<$tom_build_cli_6.ActionInvocation>(
                named['actions'],
                'actions',
              )
            : const <$tom_build_cli_6.ActionInvocation>[];
        final helpRequested = D4.getNamedArgWithDefault<bool>(
          named,
          'helpRequested',
          false,
        );
        final versionRequested = D4.getNamedArgWithDefault<bool>(
          named,
          'versionRequested',
          false,
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        return $tom_build_cli_6.ParsedArguments(
          globalParameters: globalParameters,
          hasProjectsScope: hasProjectsScope,
          hasGroupsScope: hasGroupsScope,
          projects: projects,
          projectParameters: projectParameters,
          groups: groups,
          groupParameters: groupParameters,
          actions: actions,
          helpRequested: helpRequested,
          versionRequested: versionRequested,
          verbose: verbose,
          dryRun: dryRun,
        );
      },
    },
    getters: {
      'globalParameters': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .globalParameters,
      'hasProjectsScope': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .hasProjectsScope,
      'hasGroupsScope': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .hasGroupsScope,
      'projects': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .projects,
      'projectParameters': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .projectParameters,
      'groups': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .groups,
      'groupParameters': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .groupParameters,
      'actions': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .actions,
      'helpRequested': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .helpRequested,
      'versionRequested': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .versionRequested,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .verbose,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .dryRun,
      'targetsAllProjects': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .targetsAllProjects,
      'targets': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ParsedArguments>(
            target,
            'ParsedArguments',
          )
          .targets,
    },
    constructorSignatures: {
      '': 'const ParsedArguments({Map<String, String> globalParameters = const {}, bool hasProjectsScope = false, bool hasGroupsScope = false, List<String> projects = const [], Map<String, Map<String, String>> projectParameters = const {}, List<String> groups = const [], Map<String, Map<String, String>> groupParameters = const {}, List<ActionInvocation> actions = const [], bool helpRequested = false, bool versionRequested = false, bool verbose = false, bool dryRun = false})',
    },
    getterSignatures: {
      'globalParameters': 'Map<String, String> get globalParameters',
      'hasProjectsScope': 'bool get hasProjectsScope',
      'hasGroupsScope': 'bool get hasGroupsScope',
      'projects': 'List<String> get projects',
      'projectParameters':
          'Map<String, Map<String, String>> get projectParameters',
      'groups': 'List<String> get groups',
      'groupParameters': 'Map<String, Map<String, String>> get groupParameters',
      'actions': 'List<ActionInvocation> get actions',
      'helpRequested': 'bool get helpRequested',
      'versionRequested': 'bool get versionRequested',
      'verbose': 'bool get verbose',
      'dryRun': 'bool get dryRun',
      'targetsAllProjects': 'bool get targetsAllProjects',
      'targets': 'List<String> get targets',
    },
  );
}

// =============================================================================
// ActionInvocation Bridge
// =============================================================================

BridgedClass _createActionInvocationBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_6.ActionInvocation,
    name: 'ActionInvocation',
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(
          named,
          'name',
          'ActionInvocation',
        );
        final parameters =
            named.containsKey('parameters') && named['parameters'] != null
            ? D4.coerceMap<String, String>(named['parameters'], 'parameters')
            : const <String, String>{};
        final isInternalCommand = D4.getNamedArgWithDefault<bool>(
          named,
          'isInternalCommand',
          false,
        );
        final bypassWorkspaceAction = D4.getNamedArgWithDefault<bool>(
          named,
          'bypassWorkspaceAction',
          false,
        );
        return $tom_build_cli_6.ActionInvocation(
          name: name,
          parameters: parameters,
          isInternalCommand: isInternalCommand,
          bypassWorkspaceAction: bypassWorkspaceAction,
        );
      },
    },
    getters: {
      'name': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ActionInvocation>(
            target,
            'ActionInvocation',
          )
          .name,
      'parameters': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ActionInvocation>(
            target,
            'ActionInvocation',
          )
          .parameters,
      'isInternalCommand': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ActionInvocation>(
            target,
            'ActionInvocation',
          )
          .isInternalCommand,
      'bypassWorkspaceAction': (visitor, target) => D4
          .validateTarget<$tom_build_cli_6.ActionInvocation>(
            target,
            'ActionInvocation',
          )
          .bypassWorkspaceAction,
    },
    constructorSignatures: {
      '': 'const ActionInvocation({required String name, Map<String, String> parameters = const {}, bool isInternalCommand = false, bool bypassWorkspaceAction = false})',
    },
    getterSignatures: {
      'name': 'String get name',
      'parameters': 'Map<String, String> get parameters',
      'isInternalCommand': 'bool get isInternalCommand',
      'bypassWorkspaceAction': 'bool get bypassWorkspaceAction',
    },
  );
}

// =============================================================================
// ArgumentParser Bridge
// =============================================================================

BridgedClass _createArgumentParserBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_6.ArgumentParser,
    name: 'ArgumentParser',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_6.ArgumentParser();
      },
    },
    methods: {
      'parse': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_6.ArgumentParser>(
          target,
          'ArgumentParser',
        );
        D4.requireMinArgs(positional, 1, 'parse');
        if (positional.isEmpty) {
          throw ArgumentError(
            'parse: Missing required argument "args" at position 0',
          );
        }
        final args = D4.coerceList<String>(positional[0], 'args');
        return t.parse(args);
      },
    },
    staticGetters: {
      'internalCommands': (visitor) =>
          $tom_build_cli_6.ArgumentParser.internalCommands,
      'argumentPrefixes': (visitor) =>
          $tom_build_cli_6.ArgumentParser.argumentPrefixes,
    },
    constructorSignatures: {'': 'ArgumentParser()'},
    methodSignatures: {'parse': 'ParsedArguments parse(List<String> args)'},
    staticGetterSignatures: {
      'internalCommands': 'Set<String> get internalCommands',
      'argumentPrefixes': 'Map<String, String> get argumentPrefixes',
    },
  );
}

// =============================================================================
// GitHelper Bridge
// =============================================================================

BridgedClass _createGitHelperBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_7.GitHelper,
    name: 'GitHelper',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'GitHelper',
        );
        return $tom_build_cli_7.GitHelper(workspacePath: workspacePath);
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_7.GitHelper>(target, 'GitHelper')
          .workspacePath,
    },
    methods: {
      'isGitRepository': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_7.GitHelper>(
          target,
          'GitHelper',
        );
        return t.isGitRepository();
      },
      'getChangedFiles': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_7.GitHelper>(
          target,
          'GitHelper',
        );
        final since = D4.getOptionalNamedArg<String?>(named, 'since');
        return t.getChangedFiles(since: since);
      },
      'getChangesSinceLastTag': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_7.GitHelper>(
          target,
          'GitHelper',
        );
        D4.requireMinArgs(positional, 1, 'getChangesSinceLastTag');
        final projectName = D4.getRequiredArg<String>(
          positional,
          0,
          'projectName',
          'getChangesSinceLastTag',
        );
        return t.getChangesSinceLastTag(projectName);
      },
      'hasProjectChanges': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_7.GitHelper>(
          target,
          'GitHelper',
        );
        D4.requireMinArgs(positional, 1, 'hasProjectChanges');
        final projectPath = D4.getRequiredArg<String>(
          positional,
          0,
          'projectPath',
          'hasProjectChanges',
        );
        return t.hasProjectChanges(projectPath);
      },
      'createTag': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_7.GitHelper>(
          target,
          'GitHelper',
        );
        D4.requireMinArgs(positional, 1, 'createTag');
        final tagName = D4.getRequiredArg<String>(
          positional,
          0,
          'tagName',
          'createTag',
        );
        final message = D4.getOptionalNamedArg<String?>(named, 'message');
        return t.createTag(tagName, message: message);
      },
      'commitAll': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_7.GitHelper>(
          target,
          'GitHelper',
        );
        D4.requireMinArgs(positional, 1, 'commitAll');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'commitAll',
        );
        return t.commitAll(message);
      },
    },
    constructorSignatures: {'': 'GitHelper({required String workspacePath})'},
    methodSignatures: {
      'isGitRepository': 'bool isGitRepository()',
      'getChangedFiles':
          'Future<List<String>> getChangedFiles({String? since})',
      'getChangesSinceLastTag':
          'Future<List<String>> getChangesSinceLastTag(String projectName)',
      'hasProjectChanges': 'Future<bool> hasProjectChanges(String projectPath)',
      'createTag': 'Future<bool> createTag(String tagName, {String? message})',
      'commitAll': 'Future<bool> commitAll(String message)',
    },
    getterSignatures: {'workspacePath': 'String get workspacePath'},
  );
}

// =============================================================================
// InternalCommands Bridge
// =============================================================================

BridgedClass _createInternalCommandsBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_8.InternalCommands,
    name: 'InternalCommands',
    constructors: {},
    staticGetters: {
      'commands': (visitor) => $tom_build_cli_8.InternalCommands.commands,
    },
    staticMethods: {
      'isInternalCommand': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'isInternalCommand');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'isInternalCommand',
        );
        return $tom_build_cli_8.InternalCommands.isInternalCommand(name);
      },
      'getCommand': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'getCommand');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'getCommand',
        );
        return $tom_build_cli_8.InternalCommands.getCommand(name);
      },
      'getPrefix': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'getPrefix');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'getPrefix',
        );
        return $tom_build_cli_8.InternalCommands.getPrefix(name);
      },
      'getCommandForPrefix': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'getCommandForPrefix');
        final prefix = D4.getRequiredArg<String>(
          positional,
          0,
          'prefix',
          'getCommandForPrefix',
        );
        return $tom_build_cli_8.InternalCommands.getCommandForPrefix(prefix);
      },
    },
    staticMethodSignatures: {
      'isInternalCommand': 'bool isInternalCommand(String name)',
      'getCommand': 'InternalCommandInfo? getCommand(String name)',
      'getPrefix': 'String? getPrefix(String name)',
      'getCommandForPrefix': 'String? getCommandForPrefix(String prefix)',
    },
    staticGetterSignatures: {
      'commands': 'Map<String, InternalCommandInfo> get commands',
    },
  );
}

// =============================================================================
// InternalCommandInfo Bridge
// =============================================================================

BridgedClass _createInternalCommandInfoBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_8.InternalCommandInfo,
    name: 'InternalCommandInfo',
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(
          named,
          'name',
          'InternalCommandInfo',
        );
        final prefix = D4.getRequiredNamedArg<String?>(
          named,
          'prefix',
          'InternalCommandInfo',
        );
        final description = D4.getRequiredNamedArg<String>(
          named,
          'description',
          'InternalCommandInfo',
        );
        final requiresWorkspace = D4.getRequiredNamedArg<bool>(
          named,
          'requiresWorkspace',
          'InternalCommandInfo',
        );
        return $tom_build_cli_8.InternalCommandInfo(
          name: name,
          prefix: prefix,
          description: description,
          requiresWorkspace: requiresWorkspace,
        );
      },
    },
    getters: {
      'name': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandInfo>(
            target,
            'InternalCommandInfo',
          )
          .name,
      'prefix': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandInfo>(
            target,
            'InternalCommandInfo',
          )
          .prefix,
      'description': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandInfo>(
            target,
            'InternalCommandInfo',
          )
          .description,
      'requiresWorkspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandInfo>(
            target,
            'InternalCommandInfo',
          )
          .requiresWorkspace,
    },
    constructorSignatures: {
      '': 'const InternalCommandInfo({required String name, required String? prefix, required String description, required bool requiresWorkspace})',
    },
    getterSignatures: {
      'name': 'String get name',
      'prefix': 'String? get prefix',
      'description': 'String get description',
      'requiresWorkspace': 'bool get requiresWorkspace',
    },
  );
}

// =============================================================================
// InternalCommandConfig Bridge
// =============================================================================

BridgedClass _createInternalCommandConfigBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_8.InternalCommandConfig,
    name: 'InternalCommandConfig',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'InternalCommandConfig',
        );
        final metadataPath = D4.getOptionalNamedArg<String?>(
          named,
          'metadataPath',
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        final projects =
            named.containsKey('projects') && named['projects'] != null
            ? D4.coerceList<String>(named['projects'], 'projects')
            : const <String>[];
        final groups = named.containsKey('groups') && named['groups'] != null
            ? D4.coerceList<String>(named['groups'], 'groups')
            : const <String>[];
        return $tom_build_cli_8.InternalCommandConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
          verbose: verbose,
          dryRun: dryRun,
          projects: projects,
          groups: groups,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandConfig>(
            target,
            'InternalCommandConfig',
          )
          .workspacePath,
      'metadataPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandConfig>(
            target,
            'InternalCommandConfig',
          )
          .metadataPath,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandConfig>(
            target,
            'InternalCommandConfig',
          )
          .verbose,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandConfig>(
            target,
            'InternalCommandConfig',
          )
          .dryRun,
      'projects': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandConfig>(
            target,
            'InternalCommandConfig',
          )
          .projects,
      'groups': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandConfig>(
            target,
            'InternalCommandConfig',
          )
          .groups,
      'metadataDir': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandConfig>(
            target,
            'InternalCommandConfig',
          )
          .metadataDir,
      'stateFilePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandConfig>(
            target,
            'InternalCommandConfig',
          )
          .stateFilePath,
    },
    constructorSignatures: {
      '': 'const InternalCommandConfig({required String workspacePath, String? metadataPath, bool verbose = false, bool dryRun = false, List<String> projects = const [], List<String> groups = const []})',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'metadataPath': 'String? get metadataPath',
      'verbose': 'bool get verbose',
      'dryRun': 'bool get dryRun',
      'projects': 'List<String> get projects',
      'groups': 'List<String> get groups',
      'metadataDir': 'String get metadataDir',
      'stateFilePath': 'String get stateFilePath',
    },
  );
}

// =============================================================================
// InternalCommandResult Bridge
// =============================================================================

BridgedClass _createInternalCommandResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_8.InternalCommandResult,
    name: 'InternalCommandResult',
    constructors: {
      'success': (visitor, positional, named) {
        final command = D4.getRequiredNamedArg<String>(
          named,
          'command',
          'InternalCommandResult',
        );
        final message = D4.getOptionalNamedArg<String?>(named, 'message');
        final duration = D4.getRequiredNamedArg<Duration>(
          named,
          'duration',
          'InternalCommandResult',
        );
        return $tom_build_cli_8.InternalCommandResult.success(
          command: command,
          message: message,
          duration: duration,
        );
      },
      'failure': (visitor, positional, named) {
        final command = D4.getRequiredNamedArg<String>(
          named,
          'command',
          'InternalCommandResult',
        );
        final error = D4.getRequiredNamedArg<String>(
          named,
          'error',
          'InternalCommandResult',
        );
        final duration = D4.getRequiredNamedArg<Duration>(
          named,
          'duration',
          'InternalCommandResult',
        );
        return $tom_build_cli_8.InternalCommandResult.failure(
          command: command,
          error: error,
          duration: duration,
        );
      },
    },
    getters: {
      'command': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandResult>(
            target,
            'InternalCommandResult',
          )
          .command,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandResult>(
            target,
            'InternalCommandResult',
          )
          .success,
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandResult>(
            target,
            'InternalCommandResult',
          )
          .message,
      'error': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandResult>(
            target,
            'InternalCommandResult',
          )
          .error,
      'duration': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandResult>(
            target,
            'InternalCommandResult',
          )
          .duration,
    },
    constructorSignatures: {
      'success':
          'factory InternalCommandResult.success({required String command, String? message, required Duration duration})',
      'failure':
          'factory InternalCommandResult.failure({required String command, required String error, required Duration duration})',
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
// InternalCommandExecutor Bridge
// =============================================================================

BridgedClass _createInternalCommandExecutorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_8.InternalCommandExecutor,
    name: 'InternalCommandExecutor',
    constructors: {
      '': (visitor, positional, named) {
        final config = D4
            .getRequiredNamedArg<$tom_build_cli_8.InternalCommandConfig>(
              named,
              'config',
              'InternalCommandExecutor',
            );
        final counterManager = D4
            .getOptionalNamedArg<$tom_build_cli_8.ActionCounterManager?>(
              named,
              'counterManager',
            );
        return $tom_build_cli_8.InternalCommandExecutor(
          config: config,
          counterManager: counterManager,
        );
      },
    },
    getters: {
      'config': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.InternalCommandExecutor>(
            target,
            'InternalCommandExecutor',
          )
          .config,
    },
    methods: {
      'execute': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_8.InternalCommandExecutor>(
          target,
          'InternalCommandExecutor',
        );
        final commandName = D4.getRequiredNamedArg<String>(
          named,
          'commandName',
          'execute',
        );
        final parameters =
            named.containsKey('parameters') && named['parameters'] != null
            ? D4.coerceMap<String, String>(named['parameters'], 'parameters')
            : const <String, String>{};
        return t.execute(commandName: commandName, parameters: parameters);
      },
    },
    constructorSignatures: {
      '': 'InternalCommandExecutor({required InternalCommandConfig config, ActionCounterManager? counterManager})',
    },
    methodSignatures: {
      'execute':
          'Future<InternalCommandResult> execute({required String commandName, Map<String, String> parameters = const {}})',
    },
    getterSignatures: {'config': 'InternalCommandConfig get config'},
  );
}

// =============================================================================
// ActionCounterManager Bridge
// =============================================================================

BridgedClass _createActionCounterManagerBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_8.ActionCounterManager,
    name: 'ActionCounterManager',
    constructors: {
      '': (visitor, positional, named) {
        final stateFilePath = D4.getRequiredNamedArg<String>(
          named,
          'stateFilePath',
          'ActionCounterManager',
        );
        return $tom_build_cli_8.ActionCounterManager(
          stateFilePath: stateFilePath,
        );
      },
    },
    getters: {
      'stateFilePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_8.ActionCounterManager>(
            target,
            'ActionCounterManager',
          )
          .stateFilePath,
    },
    methods: {
      'get': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_8.ActionCounterManager>(
          target,
          'ActionCounterManager',
        );
        return t.get();
      },
      'increment': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_8.ActionCounterManager>(
          target,
          'ActionCounterManager',
        );
        return t.increment();
      },
      'reset': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_8.ActionCounterManager>(
          target,
          'ActionCounterManager',
        );
        return t.reset();
      },
      'set': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_8.ActionCounterManager>(
          target,
          'ActionCounterManager',
        );
        D4.requireMinArgs(positional, 1, 'set');
        final value = D4.getRequiredArg<int>(positional, 0, 'value', 'set');
        return t.set(value);
      },
    },
    constructorSignatures: {
      '': 'ActionCounterManager({required String stateFilePath})',
    },
    methodSignatures: {
      'get': 'Future<int> get()',
      'increment': 'Future<int> increment()',
      'reset': 'Future<void> reset()',
      'set': 'Future<void> set(int value)',
    },
    getterSignatures: {'stateFilePath': 'String get stateFilePath'},
  );
}

// =============================================================================
// TomCliConfig Bridge
// =============================================================================

BridgedClass _createTomCliConfigBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_9.TomCliConfig,
    name: 'TomCliConfig',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getOptionalNamedArg<String?>(
          named,
          'workspacePath',
        );
        final metadataPath = D4.getOptionalNamedArg<String?>(
          named,
          'metadataPath',
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        final stopOnFailure = D4.getNamedArgWithDefault<bool>(
          named,
          'stopOnFailure',
          true,
        );
        return $tom_build_cli_9.TomCliConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
          verbose: verbose,
          dryRun: dryRun,
          stopOnFailure: stopOnFailure,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliConfig>(target, 'TomCliConfig')
          .workspacePath,
      'metadataPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliConfig>(target, 'TomCliConfig')
          .metadataPath,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliConfig>(target, 'TomCliConfig')
          .verbose,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliConfig>(target, 'TomCliConfig')
          .dryRun,
      'stopOnFailure': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliConfig>(target, 'TomCliConfig')
          .stopOnFailure,
      'resolvedWorkspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliConfig>(target, 'TomCliConfig')
          .resolvedWorkspacePath,
      'resolvedMetadataPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliConfig>(target, 'TomCliConfig')
          .resolvedMetadataPath,
    },
    methods: {
      'copyWith': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_9.TomCliConfig>(
          target,
          'TomCliConfig',
        );
        final workspacePath = D4.getOptionalNamedArg<String?>(
          named,
          'workspacePath',
        );
        final metadataPath = D4.getOptionalNamedArg<String?>(
          named,
          'metadataPath',
        );
        final verbose = D4.getOptionalNamedArg<bool?>(named, 'verbose');
        final dryRun = D4.getOptionalNamedArg<bool?>(named, 'dryRun');
        final stopOnFailure = D4.getOptionalNamedArg<bool?>(
          named,
          'stopOnFailure',
        );
        return t.copyWith(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
          verbose: verbose,
          dryRun: dryRun,
          stopOnFailure: stopOnFailure,
        );
      },
    },
    constructorSignatures: {
      '': 'const TomCliConfig({String? workspacePath, String? metadataPath, bool verbose = false, bool dryRun = false, bool stopOnFailure = true})',
    },
    methodSignatures: {
      'copyWith':
          'TomCliConfig copyWith({String? workspacePath, String? metadataPath, bool? verbose, bool? dryRun, bool? stopOnFailure})',
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
    nativeType: $tom_build_cli_9.TomCliResult,
    name: 'TomCliResult',
    constructors: {
      'success': (visitor, positional, named) {
        final message = D4.getOptionalNamedArg<String?>(named, 'message');
        final actionResults =
            named.containsKey('actionResults') && named['actionResults'] != null
            ? D4.coerceList<$tom_build_cli_15.ActionExecutionResult>(
                named['actionResults'],
                'actionResults',
              )
            : const <$tom_build_cli_15.ActionExecutionResult>[];
        final commandResults =
            named.containsKey('commandResults') &&
                named['commandResults'] != null
            ? D4.coerceList<$tom_build_cli_8.InternalCommandResult>(
                named['commandResults'],
                'commandResults',
              )
            : const <$tom_build_cli_8.InternalCommandResult>[];
        return $tom_build_cli_9.TomCliResult.success(
          message: message,
          actionResults: actionResults,
          commandResults: commandResults,
        );
      },
      'failure': (visitor, positional, named) {
        final error = D4.getRequiredNamedArg<String>(
          named,
          'error',
          'TomCliResult',
        );
        final exitCode = D4.getNamedArgWithDefault<int>(named, 'exitCode', 1);
        final actionResults =
            named.containsKey('actionResults') && named['actionResults'] != null
            ? D4.coerceList<$tom_build_cli_15.ActionExecutionResult>(
                named['actionResults'],
                'actionResults',
              )
            : const <$tom_build_cli_15.ActionExecutionResult>[];
        final commandResults =
            named.containsKey('commandResults') &&
                named['commandResults'] != null
            ? D4.coerceList<$tom_build_cli_8.InternalCommandResult>(
                named['commandResults'],
                'commandResults',
              )
            : const <$tom_build_cli_8.InternalCommandResult>[];
        return $tom_build_cli_9.TomCliResult.failure(
          error: error,
          exitCode: exitCode,
          actionResults: actionResults,
          commandResults: commandResults,
        );
      },
      'help': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'TomCliResult');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'TomCliResult',
        );
        return $tom_build_cli_9.TomCliResult.help(message);
      },
    },
    getters: {
      'exitCode': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliResult>(target, 'TomCliResult')
          .exitCode,
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliResult>(target, 'TomCliResult')
          .message,
      'error': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliResult>(target, 'TomCliResult')
          .error,
      'actionResults': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliResult>(target, 'TomCliResult')
          .actionResults,
      'commandResults': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliResult>(target, 'TomCliResult')
          .commandResults,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_9.TomCliResult>(target, 'TomCliResult')
          .success,
    },
    constructorSignatures: {
      'success':
          'factory TomCliResult.success({String? message, List<ActionExecutionResult> actionResults = const [], List<InternalCommandResult> commandResults = const []})',
      'failure':
          'factory TomCliResult.failure({required String error, int exitCode = 1, List<ActionExecutionResult> actionResults = const [], List<InternalCommandResult> commandResults = const []})',
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
// TomCli Bridge
// =============================================================================

BridgedClass _createTomCliBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_9.TomCli,
    name: 'TomCli',
    constructors: {
      '': (visitor, positional, named) {
        final config = D4.getOptionalNamedArg<$tom_build_cli_9.TomCliConfig?>(
          named,
          'config',
        );
        final argumentParser = D4
            .getOptionalNamedArg<$tom_build_cli_6.ArgumentParser?>(
              named,
              'argumentParser',
            );
        final commandExecutor = D4
            .getOptionalNamedArg<$tom_build_cli_8.InternalCommandExecutor?>(
              named,
              'commandExecutor',
            );
        final actionExecutor = D4
            .getOptionalNamedArg<$tom_build_cli_15.ActionExecutor?>(
              named,
              'actionExecutor',
            );
        return $tom_build_cli_9.TomCli(
          config: config,
          argumentParser: argumentParser,
          commandExecutor: commandExecutor,
          actionExecutor: actionExecutor,
        );
      },
    },
    methods: {
      'run': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_9.TomCli>(target, 'TomCli');
        D4.requireMinArgs(positional, 1, 'run');
        if (positional.isEmpty) {
          throw ArgumentError(
            'run: Missing required argument "args" at position 0',
          );
        }
        final args = D4.coerceList<String>(positional[0], 'args');
        return t.run(args);
      },
    },
    constructorSignatures: {
      '': 'TomCli({TomCliConfig? config, ArgumentParser? argumentParser, InternalCommandExecutor? commandExecutor, ActionExecutor? actionExecutor})',
    },
    methodSignatures: {'run': 'Future<TomCliResult> run(List<String> args)'},
  );
}

// =============================================================================
// VersionBumper Bridge
// =============================================================================

BridgedClass _createVersionBumperBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_10.VersionBumper,
    name: 'VersionBumper',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'VersionBumper',
        );
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        return $tom_build_cli_10.VersionBumper(
          workspacePath: workspacePath,
          dryRun: dryRun,
          verbose: verbose,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_10.VersionBumper>(
            target,
            'VersionBumper',
          )
          .workspacePath,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_10.VersionBumper>(
            target,
            'VersionBumper',
          )
          .dryRun,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_10.VersionBumper>(
            target,
            'VersionBumper',
          )
          .verbose,
    },
    methods: {
      'bumpVersion': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_10.VersionBumper>(
          target,
          'VersionBumper',
        );
        D4.requireMinArgs(positional, 1, 'bumpVersion');
        final projectPath = D4.getRequiredArg<String>(
          positional,
          0,
          'projectPath',
          'bumpVersion',
        );
        final bumpType = D4.getRequiredNamedArg<$tom_build_cli_10.BumpType>(
          named,
          'bumpType',
          'bumpVersion',
        );
        return t.bumpVersion(projectPath, bumpType: bumpType);
      },
    },
    constructorSignatures: {
      '': 'VersionBumper({required String workspacePath, bool dryRun = false, bool verbose = false})',
    },
    methodSignatures: {
      'bumpVersion':
          'Future<VersionBumpResult> bumpVersion(String projectPath, {required BumpType bumpType})',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'dryRun': 'bool get dryRun',
      'verbose': 'bool get verbose',
    },
  );
}

// =============================================================================
// VersionBumpResult Bridge
// =============================================================================

BridgedClass _createVersionBumpResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_10.VersionBumpResult,
    name: 'VersionBumpResult',
    constructors: {
      'success': (visitor, positional, named) {
        final projectPath = D4.getRequiredNamedArg<String>(
          named,
          'projectPath',
          'VersionBumpResult',
        );
        final oldVersion = D4.getRequiredNamedArg<String>(
          named,
          'oldVersion',
          'VersionBumpResult',
        );
        final newVersion = D4.getRequiredNamedArg<String>(
          named,
          'newVersion',
          'VersionBumpResult',
        );
        final dryRun = D4.getRequiredNamedArg<bool>(
          named,
          'dryRun',
          'VersionBumpResult',
        );
        return $tom_build_cli_10.VersionBumpResult.success(
          projectPath: projectPath,
          oldVersion: oldVersion,
          newVersion: newVersion,
          dryRun: dryRun,
        );
      },
      'failure': (visitor, positional, named) {
        final projectPath = D4.getRequiredNamedArg<String>(
          named,
          'projectPath',
          'VersionBumpResult',
        );
        final error = D4.getRequiredNamedArg<String>(
          named,
          'error',
          'VersionBumpResult',
        );
        return $tom_build_cli_10.VersionBumpResult.failure(
          projectPath: projectPath,
          error: error,
        );
      },
    },
    getters: {
      'projectPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_10.VersionBumpResult>(
            target,
            'VersionBumpResult',
          )
          .projectPath,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_10.VersionBumpResult>(
            target,
            'VersionBumpResult',
          )
          .success,
      'oldVersion': (visitor, target) => D4
          .validateTarget<$tom_build_cli_10.VersionBumpResult>(
            target,
            'VersionBumpResult',
          )
          .oldVersion,
      'newVersion': (visitor, target) => D4
          .validateTarget<$tom_build_cli_10.VersionBumpResult>(
            target,
            'VersionBumpResult',
          )
          .newVersion,
      'error': (visitor, target) => D4
          .validateTarget<$tom_build_cli_10.VersionBumpResult>(
            target,
            'VersionBumpResult',
          )
          .error,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_10.VersionBumpResult>(
            target,
            'VersionBumpResult',
          )
          .dryRun,
    },
    constructorSignatures: {
      'success':
          'factory VersionBumpResult.success({required String projectPath, required String oldVersion, required String newVersion, required bool dryRun})',
      'failure':
          'factory VersionBumpResult.failure({required String projectPath, required String error})',
    },
    getterSignatures: {
      'projectPath': 'String get projectPath',
      'success': 'bool get success',
      'oldVersion': 'String? get oldVersion',
      'newVersion': 'String? get newVersion',
      'error': 'String? get error',
      'dryRun': 'bool get dryRun',
    },
  );
}

// =============================================================================
// WorkspaceDiscoveryResult Bridge
// =============================================================================

BridgedClass _createWorkspaceDiscoveryResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_11.WorkspaceDiscoveryResult,
    name: 'WorkspaceDiscoveryResult',
    constructors: {
      'found': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'WorkspaceDiscoveryResult');
        final workspacePath = D4.getRequiredArg<String>(
          positional,
          0,
          'workspacePath',
          'WorkspaceDiscoveryResult',
        );
        return $tom_build_cli_11.WorkspaceDiscoveryResult.found(workspacePath);
      },
      'notFound': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'WorkspaceDiscoveryResult');
        final searchStart = D4.getRequiredArg<String>(
          positional,
          0,
          'searchStart',
          'WorkspaceDiscoveryResult',
        );
        return $tom_build_cli_11.WorkspaceDiscoveryResult.notFound(searchStart);
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceDiscoveryResult>(
            target,
            'WorkspaceDiscoveryResult',
          )
          .workspacePath,
      'found': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceDiscoveryResult>(
            target,
            'WorkspaceDiscoveryResult',
          )
          .found,
      'error': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceDiscoveryResult>(
            target,
            'WorkspaceDiscoveryResult',
          )
          .error,
    },
    constructorSignatures: {
      'found': 'factory WorkspaceDiscoveryResult.found(String workspacePath)',
      'notFound':
          'factory WorkspaceDiscoveryResult.notFound(String searchStart)',
    },
    getterSignatures: {
      'workspacePath': 'String? get workspacePath',
      'found': 'bool get found',
      'error': 'String? get error',
    },
  );
}

// =============================================================================
// WorkspaceContext Bridge
// =============================================================================

BridgedClass _createWorkspaceContextBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_11.WorkspaceContext,
    name: 'WorkspaceContext',
    constructors: {},
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .workspacePath,
      'workspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .workspace,
      'projects': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .projects,
      'metadataPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .metadataPath,
      'stateFilePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .stateFilePath,
      'masterFilesGenerated': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .masterFilesGenerated,
      'actions': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .actions,
      'pipelines': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .pipelines,
      'groups': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .groups,
      'projectsInBuildOrder': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContext>(
            target,
            'WorkspaceContext',
          )
          .projectsInBuildOrder,
    },
    methods: {
      'markMasterFilesGenerated':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_11.WorkspaceContext>(
              target,
              'WorkspaceContext',
            );
            t.markMasterFilesGenerated();
            return null;
          },
      'ensureMasterFilesGenerated':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_11.WorkspaceContext>(
              target,
              'WorkspaceContext',
            );
            return t.ensureMasterFilesGenerated();
          },
      'getProjectsInGroup': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_11.WorkspaceContext>(
          target,
          'WorkspaceContext',
        );
        D4.requireMinArgs(positional, 1, 'getProjectsInGroup');
        final groupName = D4.getRequiredArg<String>(
          positional,
          0,
          'groupName',
          'getProjectsInGroup',
        );
        return t.getProjectsInGroup(groupName);
      },
    },
    staticGetters: {
      'current': (visitor) => $tom_build_cli_11.WorkspaceContext.current,
    },
    staticMethods: {
      'load': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'load');
        final workspacePath = D4.getRequiredArg<String>(
          positional,
          0,
          'workspacePath',
          'load',
        );
        return $tom_build_cli_11.WorkspaceContext.load(workspacePath);
      },
      'reset': (visitor, positional, named, typeArgs) {
        return $tom_build_cli_11.WorkspaceContext.reset();
      },
    },
    methodSignatures: {
      'markMasterFilesGenerated': 'void markMasterFilesGenerated()',
      'ensureMasterFilesGenerated':
          'Future<MasterGenerationSummary> ensureMasterFilesGenerated()',
      'getProjectsInGroup': 'List<String> getProjectsInGroup(String groupName)',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'workspace': 'TomWorkspace get workspace',
      'projects': 'Map<String, TomProject> get projects',
      'metadataPath': 'String get metadataPath',
      'stateFilePath': 'String get stateFilePath',
      'masterFilesGenerated': 'bool get masterFilesGenerated',
      'actions': 'Map<String, ActionDef> get actions',
      'pipelines': 'Map<String, Pipeline> get pipelines',
      'groups': 'Map<String, GroupDef> get groups',
      'projectsInBuildOrder': 'List<String> get projectsInBuildOrder',
    },
    staticMethodSignatures: {
      'load': 'Future<WorkspaceContext> load(String workspacePath)',
      'reset': 'void reset()',
    },
    staticGetterSignatures: {'current': 'WorkspaceContext? get current'},
  );
}

// =============================================================================
// MasterGenerationSummary Bridge
// =============================================================================

BridgedClass _createMasterGenerationSummaryBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_11.MasterGenerationSummary,
    name: 'MasterGenerationSummary',
    constructors: {
      '': (visitor, positional, named) {
        final success = D4.getRequiredNamedArg<bool>(
          named,
          'success',
          'MasterGenerationSummary',
        );
        final message = D4.getRequiredNamedArg<String>(
          named,
          'message',
          'MasterGenerationSummary',
        );
        final filesGenerated = D4.getRequiredNamedArg<int>(
          named,
          'filesGenerated',
          'MasterGenerationSummary',
        );
        return $tom_build_cli_11.MasterGenerationSummary(
          success: success,
          message: message,
          filesGenerated: filesGenerated,
        );
      },
    },
    getters: {
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.MasterGenerationSummary>(
            target,
            'MasterGenerationSummary',
          )
          .success,
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.MasterGenerationSummary>(
            target,
            'MasterGenerationSummary',
          )
          .message,
      'filesGenerated': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.MasterGenerationSummary>(
            target,
            'MasterGenerationSummary',
          )
          .filesGenerated,
    },
    constructorSignatures: {
      '': 'const MasterGenerationSummary({required bool success, required String message, required int filesGenerated})',
    },
    getterSignatures: {
      'success': 'bool get success',
      'message': 'String get message',
      'filesGenerated': 'int get filesGenerated',
    },
  );
}

// =============================================================================
// WorkspaceContextException Bridge
// =============================================================================

BridgedClass _createWorkspaceContextExceptionBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_11.WorkspaceContextException,
    name: 'WorkspaceContextException',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'WorkspaceContextException');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'WorkspaceContextException',
        );
        return $tom_build_cli_11.WorkspaceContextException(message);
      },
    },
    getters: {
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_11.WorkspaceContextException>(
            target,
            'WorkspaceContextException',
          )
          .message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4
            .validateTarget<$tom_build_cli_11.WorkspaceContextException>(
              target,
              'WorkspaceContextException',
            );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const WorkspaceContextException(String message)',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {'message': 'String get message'},
  );
}

// =============================================================================
// ConfigLoader Bridge
// =============================================================================

BridgedClass _createConfigLoaderBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_12.ConfigLoader,
    name: 'ConfigLoader',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_12.ConfigLoader();
      },
    },
    methods: {
      'loadWorkspaceConfig': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_12.ConfigLoader>(
          target,
          'ConfigLoader',
        );
        D4.requireMinArgs(positional, 1, 'loadWorkspaceConfig');
        final workspaceDir = D4.getRequiredArg<String>(
          positional,
          0,
          'workspaceDir',
          'loadWorkspaceConfig',
        );
        return t.loadWorkspaceConfig(workspaceDir);
      },
      'loadProjectConfig': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_12.ConfigLoader>(
          target,
          'ConfigLoader',
        );
        D4.requireMinArgs(positional, 2, 'loadProjectConfig');
        final projectDir = D4.getRequiredArg<String>(
          positional,
          0,
          'projectDir',
          'loadProjectConfig',
        );
        final projectName = D4.getRequiredArg<String>(
          positional,
          1,
          'projectName',
          'loadProjectConfig',
        );
        return t.loadProjectConfig(projectDir, projectName);
      },
      'loadYamlFile': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_12.ConfigLoader>(
          target,
          'ConfigLoader',
        );
        D4.requireMinArgs(positional, 1, 'loadYamlFile');
        final filePath = D4.getRequiredArg<String>(
          positional,
          0,
          'filePath',
          'loadYamlFile',
        );
        return t.loadYamlFile(filePath);
      },
      'loadWorkspaceWithImports':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_12.ConfigLoader>(
              target,
              'ConfigLoader',
            );
            D4.requireMinArgs(positional, 1, 'loadWorkspaceWithImports');
            final workspaceDir = D4.getRequiredArg<String>(
              positional,
              0,
              'workspaceDir',
              'loadWorkspaceWithImports',
            );
            return t.loadWorkspaceWithImports(workspaceDir);
          },
    },
    constructorSignatures: {'': 'ConfigLoader()'},
    methodSignatures: {
      'loadWorkspaceConfig':
          'TomWorkspace? loadWorkspaceConfig(String workspaceDir)',
      'loadProjectConfig':
          'TomProject? loadProjectConfig(String projectDir, String projectName)',
      'loadYamlFile': 'Map<String, dynamic> loadYamlFile(String filePath)',
      'loadWorkspaceWithImports':
          'TomWorkspace? loadWorkspaceWithImports(String workspaceDir)',
    },
  );
}

// =============================================================================
// ConfigLoadException Bridge
// =============================================================================

BridgedClass _createConfigLoadExceptionBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_12.ConfigLoadException,
    name: 'ConfigLoadException',
    constructors: {
      '': (visitor, positional, named) {
        final message = D4.getRequiredNamedArg<String>(
          named,
          'message',
          'ConfigLoadException',
        );
        final filePath = D4.getRequiredNamedArg<String>(
          named,
          'filePath',
          'ConfigLoadException',
        );
        final line = D4.getOptionalNamedArg<int?>(named, 'line');
        final resolution = D4.getRequiredNamedArg<String>(
          named,
          'resolution',
          'ConfigLoadException',
        );
        return $tom_build_cli_12.ConfigLoadException(
          message: message,
          filePath: filePath,
          line: line,
          resolution: resolution,
        );
      },
    },
    getters: {
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_12.ConfigLoadException>(
            target,
            'ConfigLoadException',
          )
          .message,
      'filePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_12.ConfigLoadException>(
            target,
            'ConfigLoadException',
          )
          .filePath,
      'line': (visitor, target) => D4
          .validateTarget<$tom_build_cli_12.ConfigLoadException>(
            target,
            'ConfigLoadException',
          )
          .line,
      'resolution': (visitor, target) => D4
          .validateTarget<$tom_build_cli_12.ConfigLoadException>(
            target,
            'ConfigLoadException',
          )
          .resolution,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_12.ConfigLoadException>(
          target,
          'ConfigLoadException',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const ConfigLoadException({required String message, required String filePath, int? line, required String resolution})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'message': 'String get message',
      'filePath': 'String get filePath',
      'line': 'int? get line',
      'resolution': 'String get resolution',
    },
  );
}

// =============================================================================
// ConfigMerger Bridge
// =============================================================================

BridgedClass _createConfigMergerBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_13.ConfigMerger,
    name: 'ConfigMerger',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_13.ConfigMerger();
      },
    },
    methods: {
      'deepMerge': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_13.ConfigMerger>(
          target,
          'ConfigMerger',
        );
        D4.requireMinArgs(positional, 2, 'deepMerge');
        if (positional.isEmpty) {
          throw ArgumentError(
            'deepMerge: Missing required argument "base" at position 0',
          );
        }
        final base = D4.coerceMap<String, dynamic>(positional[0], 'base');
        if (positional.length <= 1) {
          throw ArgumentError(
            'deepMerge: Missing required argument "override" at position 1',
          );
        }
        final override = D4.coerceMap<String, dynamic>(
          positional[1],
          'override',
        );
        return t.deepMerge(base, override);
      },
      'mergeAll': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_13.ConfigMerger>(
          target,
          'ConfigMerger',
        );
        D4.requireMinArgs(positional, 1, 'mergeAll');
        if (positional.isEmpty) {
          throw ArgumentError(
            'mergeAll: Missing required argument "configs" at position 0',
          );
        }
        final configs = D4.coerceList<Map<String, dynamic>>(
          positional[0],
          'configs',
        );
        return t.mergeAll(configs);
      },
      'mergeProjectConfig': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_13.ConfigMerger>(
          target,
          'ConfigMerger',
        );
        final autoDetected = D4.coerceMapOrNull<String, dynamic>(
          named['autoDetected'],
          'autoDetected',
        );
        final projectTypeDefaults = D4.coerceMapOrNull<String, dynamic>(
          named['projectTypeDefaults'],
          'projectTypeDefaults',
        );
        final groupOverrides = D4.coerceMapOrNull<String, dynamic>(
          named['groupOverrides'],
          'groupOverrides',
        );
        final workspaceDefaults = D4.coerceMapOrNull<String, dynamic>(
          named['workspaceDefaults'],
          'workspaceDefaults',
        );
        final projectOverrides = D4.coerceMapOrNull<String, dynamic>(
          named['projectOverrides'],
          'projectOverrides',
        );
        final globalCliParams = D4.coerceMapOrNull<String, dynamic>(
          named['globalCliParams'],
          'globalCliParams',
        );
        final targetCliParams = D4.coerceMapOrNull<String, dynamic>(
          named['targetCliParams'],
          'targetCliParams',
        );
        return t.mergeProjectConfig(
          autoDetected: autoDetected,
          projectTypeDefaults: projectTypeDefaults,
          groupOverrides: groupOverrides,
          workspaceDefaults: workspaceDefaults,
          projectOverrides: projectOverrides,
          globalCliParams: globalCliParams,
          targetCliParams: targetCliParams,
        );
      },
    },
    constructorSignatures: {'': 'ConfigMerger()'},
    methodSignatures: {
      'deepMerge':
          'Map<String, dynamic> deepMerge(Map<String, dynamic> base, Map<String, dynamic> override)',
      'mergeAll':
          'Map<String, dynamic> mergeAll(List<Map<String, dynamic>> configs)',
      'mergeProjectConfig':
          'Map<String, dynamic> mergeProjectConfig({Map<String, dynamic>? autoDetected, Map<String, dynamic>? projectTypeDefaults, Map<String, dynamic>? groupOverrides, Map<String, dynamic>? workspaceDefaults, Map<String, dynamic>? projectOverrides, Map<String, dynamic>? globalCliParams, Map<String, dynamic>? targetCliParams})',
    },
  );
}

// =============================================================================
// ValidationResult Bridge
// =============================================================================

BridgedClass _createValidationResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_14.ValidationResult,
    name: 'ValidationResult',
    constructors: {
      'success': (visitor, positional, named) {
        return $tom_build_cli_14.ValidationResult.success();
      },
      'failure': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'ValidationResult');
        if (positional.isEmpty) {
          throw ArgumentError(
            'ValidationResult: Missing required argument "errors" at position 0',
          );
        }
        final errors = D4.coerceList<$tom_build_cli_14.ConfigValidationError>(
          positional[0],
          'errors',
        );
        return $tom_build_cli_14.ValidationResult.failure(errors);
      },
    },
    getters: {
      'isValid': (visitor, target) => D4
          .validateTarget<$tom_build_cli_14.ValidationResult>(
            target,
            'ValidationResult',
          )
          .isValid,
      'errors': (visitor, target) => D4
          .validateTarget<$tom_build_cli_14.ValidationResult>(
            target,
            'ValidationResult',
          )
          .errors,
    },
    methods: {
      'formatErrors': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_14.ValidationResult>(
          target,
          'ValidationResult',
        );
        return t.formatErrors();
      },
    },
    constructorSignatures: {
      'success': 'ValidationResult.success()',
      'failure': 'ValidationResult.failure(List<ConfigValidationError> errors)',
    },
    methodSignatures: {'formatErrors': 'String formatErrors()'},
    getterSignatures: {
      'isValid': 'bool get isValid',
      'errors': 'List<ConfigValidationError> get errors',
    },
  );
}

// =============================================================================
// ConfigValidationError Bridge
// =============================================================================

BridgedClass _createConfigValidationErrorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_14.ConfigValidationError,
    name: 'ConfigValidationError',
    constructors: {
      '': (visitor, positional, named) {
        final message = D4.getRequiredNamedArg<String>(
          named,
          'message',
          'ConfigValidationError',
        );
        final filePath = D4.getRequiredNamedArg<String>(
          named,
          'filePath',
          'ConfigValidationError',
        );
        final line = D4.getOptionalNamedArg<int?>(named, 'line');
        final resolution = D4.getRequiredNamedArg<String>(
          named,
          'resolution',
          'ConfigValidationError',
        );
        return $tom_build_cli_14.ConfigValidationError(
          message: message,
          filePath: filePath,
          line: line,
          resolution: resolution,
        );
      },
    },
    getters: {
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_14.ConfigValidationError>(
            target,
            'ConfigValidationError',
          )
          .message,
      'filePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_14.ConfigValidationError>(
            target,
            'ConfigValidationError',
          )
          .filePath,
      'line': (visitor, target) => D4
          .validateTarget<$tom_build_cli_14.ConfigValidationError>(
            target,
            'ConfigValidationError',
          )
          .line,
      'resolution': (visitor, target) => D4
          .validateTarget<$tom_build_cli_14.ConfigValidationError>(
            target,
            'ConfigValidationError',
          )
          .resolution,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_14.ConfigValidationError>(
          target,
          'ConfigValidationError',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const ConfigValidationError({required String message, required String filePath, int? line, required String resolution})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'message': 'String get message',
      'filePath': 'String get filePath',
      'line': 'int? get line',
      'resolution': 'String get resolution',
    },
  );
}

// =============================================================================
// ConfigValidator Bridge
// =============================================================================

BridgedClass _createConfigValidatorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_14.ConfigValidator,
    name: 'ConfigValidator',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_14.ConfigValidator();
      },
    },
    methods: {
      'validateWorkspace': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_14.ConfigValidator>(
          target,
          'ConfigValidator',
        );
        D4.requireMinArgs(positional, 2, 'validateWorkspace');
        final workspace = D4.getRequiredArg<$tom_build_1.TomWorkspace>(
          positional,
          0,
          'workspace',
          'validateWorkspace',
        );
        final filePath = D4.getRequiredArg<String>(
          positional,
          1,
          'filePath',
          'validateWorkspace',
        );
        return t.validateWorkspace(workspace, filePath);
      },
      'validateProject': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_14.ConfigValidator>(
          target,
          'ConfigValidator',
        );
        D4.requireMinArgs(positional, 2, 'validateProject');
        final project = D4.getRequiredArg<$tom_build_1.TomProject>(
          positional,
          0,
          'project',
          'validateProject',
        );
        final filePath = D4.getRequiredArg<String>(
          positional,
          1,
          'filePath',
          'validateProject',
        );
        return t.validateProject(project, filePath);
      },
      'validateMaster': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_14.ConfigValidator>(
          target,
          'ConfigValidator',
        );
        D4.requireMinArgs(positional, 2, 'validateMaster');
        final master = D4.getRequiredArg<$tom_build_1.TomMaster>(
          positional,
          0,
          'master',
          'validateMaster',
        );
        final filePath = D4.getRequiredArg<String>(
          positional,
          1,
          'filePath',
          'validateMaster',
        );
        return t.validateMaster(master, filePath);
      },
    },
    constructorSignatures: {'': 'ConfigValidator()'},
    methodSignatures: {
      'validateWorkspace':
          'ValidationResult validateWorkspace(TomWorkspace workspace, String filePath)',
      'validateProject':
          'ValidationResult validateProject(TomProject project, String filePath)',
      'validateMaster':
          'ValidationResult validateMaster(TomMaster master, String filePath)',
    },
  );
}

// =============================================================================
// ActionExecutorConfig Bridge
// =============================================================================

BridgedClass _createActionExecutorConfigBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_15.ActionExecutorConfig,
    name: 'ActionExecutorConfig',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'ActionExecutorConfig',
        );
        final metadataPath = D4.getOptionalNamedArg<String?>(
          named,
          'metadataPath',
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        final environment =
            named.containsKey('environment') && named['environment'] != null
            ? D4.coerceMap<String, String>(named['environment'], 'environment')
            : const <String, String>{};
        return $tom_build_cli_15.ActionExecutorConfig(
          workspacePath: workspacePath,
          metadataPath: metadataPath,
          verbose: verbose,
          dryRun: dryRun,
          environment: environment,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutorConfig>(
            target,
            'ActionExecutorConfig',
          )
          .workspacePath,
      'metadataPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutorConfig>(
            target,
            'ActionExecutorConfig',
          )
          .metadataPath,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutorConfig>(
            target,
            'ActionExecutorConfig',
          )
          .verbose,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutorConfig>(
            target,
            'ActionExecutorConfig',
          )
          .dryRun,
      'environment': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutorConfig>(
            target,
            'ActionExecutorConfig',
          )
          .environment,
      'metadataDir': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutorConfig>(
            target,
            'ActionExecutorConfig',
          )
          .metadataDir,
    },
    constructorSignatures: {
      '': 'const ActionExecutorConfig({required String workspacePath, String? metadataPath, bool verbose = false, bool dryRun = false, Map<String, String> environment = const {}})',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'metadataPath': 'String? get metadataPath',
      'verbose': 'bool get verbose',
      'dryRun': 'bool get dryRun',
      'environment': 'Map<String, String> get environment',
      'metadataDir': 'String get metadataDir',
    },
  );
}

// =============================================================================
// ActionExecutionResult Bridge
// =============================================================================

BridgedClass _createActionExecutionResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_15.ActionExecutionResult,
    name: 'ActionExecutionResult',
    constructors: {
      'success': (visitor, positional, named) {
        final projectName = D4.getRequiredNamedArg<String>(
          named,
          'projectName',
          'ActionExecutionResult',
        );
        final actionName = D4.getRequiredNamedArg<String>(
          named,
          'actionName',
          'ActionExecutionResult',
        );
        if (!named.containsKey('commandResults') ||
            named['commandResults'] == null) {
          throw ArgumentError(
            'ActionExecutionResult: Missing required named argument "commandResults"',
          );
        }
        final commandResults = D4.coerceList<$tom_build_cli_16.CommandResult>(
          named['commandResults'],
          'commandResults',
        );
        final duration = D4.getRequiredNamedArg<Duration>(
          named,
          'duration',
          'ActionExecutionResult',
        );
        return $tom_build_cli_15.ActionExecutionResult.success(
          projectName: projectName,
          actionName: actionName,
          commandResults: commandResults,
          duration: duration,
        );
      },
      'failure': (visitor, positional, named) {
        final projectName = D4.getRequiredNamedArg<String>(
          named,
          'projectName',
          'ActionExecutionResult',
        );
        final actionName = D4.getRequiredNamedArg<String>(
          named,
          'actionName',
          'ActionExecutionResult',
        );
        final error = D4.getRequiredNamedArg<String>(
          named,
          'error',
          'ActionExecutionResult',
        );
        final commandResults =
            named.containsKey('commandResults') &&
                named['commandResults'] != null
            ? D4.coerceList<$tom_build_cli_16.CommandResult>(
                named['commandResults'],
                'commandResults',
              )
            : const <$tom_build_cli_16.CommandResult>[];
        final duration = D4.getNamedArgWithDefault<Duration>(
          named,
          'duration',
          Duration.zero,
        );
        return $tom_build_cli_15.ActionExecutionResult.failure(
          projectName: projectName,
          actionName: actionName,
          error: error,
          commandResults: commandResults,
          duration: duration,
        );
      },
    },
    getters: {
      'projectName': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutionResult>(
            target,
            'ActionExecutionResult',
          )
          .projectName,
      'actionName': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutionResult>(
            target,
            'ActionExecutionResult',
          )
          .actionName,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutionResult>(
            target,
            'ActionExecutionResult',
          )
          .success,
      'commandResults': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutionResult>(
            target,
            'ActionExecutionResult',
          )
          .commandResults,
      'error': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutionResult>(
            target,
            'ActionExecutionResult',
          )
          .error,
      'duration': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutionResult>(
            target,
            'ActionExecutionResult',
          )
          .duration,
    },
    constructorSignatures: {
      'success':
          'factory ActionExecutionResult.success({required String projectName, required String actionName, required List<CommandResult> commandResults, required Duration duration})',
      'failure':
          'factory ActionExecutionResult.failure({required String projectName, required String actionName, required String error, List<CommandResult> commandResults = const [], Duration duration = Duration.zero})',
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
// ActionExecutor Bridge
// =============================================================================

BridgedClass _createActionExecutorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_15.ActionExecutor,
    name: 'ActionExecutor',
    constructors: {
      '': (visitor, positional, named) {
        final config = D4
            .getRequiredNamedArg<$tom_build_cli_15.ActionExecutorConfig>(
              named,
              'config',
              'ActionExecutor',
            );
        final commandRunner = D4
            .getOptionalNamedArg<$tom_build_cli_16.CommandRunner?>(
              named,
              'commandRunner',
            );
        final tomplateProcessor = D4
            .getOptionalNamedArg<$tom_build_cli_26.TomplateProcessor?>(
              named,
              'tomplateProcessor',
            );
        return $tom_build_cli_15.ActionExecutor(
          config: config,
          commandRunner: commandRunner,
          tomplateProcessor: tomplateProcessor,
        );
      },
    },
    getters: {
      'config': (visitor, target) => D4
          .validateTarget<$tom_build_cli_15.ActionExecutor>(
            target,
            'ActionExecutor',
          )
          .config,
    },
    methods: {
      'executeAction': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_15.ActionExecutor>(
          target,
          'ActionExecutor',
        );
        final actionName = D4.getRequiredNamedArg<String>(
          named,
          'actionName',
          'executeAction',
        );
        final projectName = D4.getRequiredNamedArg<String>(
          named,
          'projectName',
          'executeAction',
        );
        final additionalModes = D4.getOptionalNamedArg<Set<String>?>(
          named,
          'additionalModes',
        );
        final parameters = D4.coerceMapOrNull<String, String>(
          named['parameters'],
          'parameters',
        );
        return t.executeAction(
          actionName: actionName,
          projectName: projectName,
          additionalModes: additionalModes,
          parameters: parameters,
        );
      },
      'executeActionOnProjects': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_15.ActionExecutor>(
          target,
          'ActionExecutor',
        );
        final actionName = D4.getRequiredNamedArg<String>(
          named,
          'actionName',
          'executeActionOnProjects',
        );
        if (!named.containsKey('projectNames') ||
            named['projectNames'] == null) {
          throw ArgumentError(
            'executeActionOnProjects: Missing required named argument "projectNames"',
          );
        }
        final projectNames = D4.coerceList<String>(
          named['projectNames'],
          'projectNames',
        );
        final stopOnFailure = D4.getNamedArgWithDefault<bool>(
          named,
          'stopOnFailure',
          true,
        );
        return t.executeActionOnProjects(
          actionName: actionName,
          projectNames: projectNames,
          stopOnFailure: stopOnFailure,
        );
      },
    },
    constructorSignatures: {
      '': 'ActionExecutor({required ActionExecutorConfig config, CommandRunner? commandRunner, TomplateProcessor? tomplateProcessor})',
    },
    methodSignatures: {
      'executeAction':
          'Future<ActionExecutionResult> executeAction({required String actionName, required String projectName, Set<String>? additionalModes, Map<String, String>? parameters})',
      'executeActionOnProjects':
          'Future<List<ActionExecutionResult>> executeActionOnProjects({required String actionName, required List<String> projectNames, bool stopOnFailure = true})',
    },
    getterSignatures: {'config': 'ActionExecutorConfig get config'},
  );
}

// =============================================================================
// CommandResult Bridge
// =============================================================================

BridgedClass _createCommandResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_16.CommandResult,
    name: 'CommandResult',
    constructors: {
      'success': (visitor, positional, named) {
        final command = D4.getRequiredNamedArg<String>(
          named,
          'command',
          'CommandResult',
        );
        final stdout = D4.getRequiredNamedArg<String>(
          named,
          'stdout',
          'CommandResult',
        );
        final stderr = D4.getNamedArgWithDefault<String>(named, 'stderr', '');
        final duration = D4.getNamedArgWithDefault<Duration>(
          named,
          'duration',
          Duration.zero,
        );
        return $tom_build_cli_16.CommandResult.success(
          command: command,
          stdout: stdout,
          stderr: stderr,
          duration: duration,
        );
      },
      'failure': (visitor, positional, named) {
        final command = D4.getRequiredNamedArg<String>(
          named,
          'command',
          'CommandResult',
        );
        final exitCode = D4.getRequiredNamedArg<int>(
          named,
          'exitCode',
          'CommandResult',
        );
        final stdout = D4.getNamedArgWithDefault<String>(named, 'stdout', '');
        final stderr = D4.getNamedArgWithDefault<String>(named, 'stderr', '');
        final duration = D4.getNamedArgWithDefault<Duration>(
          named,
          'duration',
          Duration.zero,
        );
        return $tom_build_cli_16.CommandResult.failure(
          command: command,
          exitCode: exitCode,
          stdout: stdout,
          stderr: stderr,
          duration: duration,
        );
      },
    },
    getters: {
      'command': (visitor, target) => D4
          .validateTarget<$tom_build_cli_16.CommandResult>(
            target,
            'CommandResult',
          )
          .command,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_16.CommandResult>(
            target,
            'CommandResult',
          )
          .success,
      'exitCode': (visitor, target) => D4
          .validateTarget<$tom_build_cli_16.CommandResult>(
            target,
            'CommandResult',
          )
          .exitCode,
      'stdout': (visitor, target) => D4
          .validateTarget<$tom_build_cli_16.CommandResult>(
            target,
            'CommandResult',
          )
          .stdout,
      'stderr': (visitor, target) => D4
          .validateTarget<$tom_build_cli_16.CommandResult>(
            target,
            'CommandResult',
          )
          .stderr,
      'duration': (visitor, target) => D4
          .validateTarget<$tom_build_cli_16.CommandResult>(
            target,
            'CommandResult',
          )
          .duration,
    },
    constructorSignatures: {
      'success':
          'factory CommandResult.success({required String command, required String stdout, String stderr = \'\', Duration duration = Duration.zero})',
      'failure':
          'factory CommandResult.failure({required String command, required int exitCode, String stdout = \'\', String stderr = \'\', Duration duration = Duration.zero})',
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

// =============================================================================
// CommandRunner Bridge
// =============================================================================

BridgedClass _createCommandRunnerBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_16.CommandRunner,
    name: 'CommandRunner',
    constructors: {
      '': (visitor, positional, named) {
        final shell = D4.getNamedArgWithDefault<bool>(named, 'shell', true);
        final defaultTimeout = D4.getNamedArgWithDefault<Duration>(
          named,
          'defaultTimeout',
          const Duration(minutes: 5),
        );
        return $tom_build_cli_16.CommandRunner(
          shell: shell,
          defaultTimeout: defaultTimeout,
        );
      },
    },
    getters: {
      'shell': (visitor, target) => D4
          .validateTarget<$tom_build_cli_16.CommandRunner>(
            target,
            'CommandRunner',
          )
          .shell,
      'defaultTimeout': (visitor, target) => D4
          .validateTarget<$tom_build_cli_16.CommandRunner>(
            target,
            'CommandRunner',
          )
          .defaultTimeout,
    },
    methods: {
      'run': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_16.CommandRunner>(
          target,
          'CommandRunner',
        );
        final command = D4.getRequiredNamedArg<String>(named, 'command', 'run');
        final workingDirectory = D4.getOptionalNamedArg<String?>(
          named,
          'workingDirectory',
        );
        final environment = D4.coerceMapOrNull<String, String>(
          named['environment'],
          'environment',
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final timeout = D4.getOptionalNamedArg<Duration?>(named, 'timeout');
        return t.run(
          command: command,
          workingDirectory: workingDirectory,
          environment: environment,
          verbose: verbose,
          timeout: timeout,
        );
      },
      'runAll': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_16.CommandRunner>(
          target,
          'CommandRunner',
        );
        if (!named.containsKey('commands') || named['commands'] == null) {
          throw ArgumentError(
            'runAll: Missing required named argument "commands"',
          );
        }
        final commands = D4.coerceList<String>(named['commands'], 'commands');
        final workingDirectory = D4.getOptionalNamedArg<String?>(
          named,
          'workingDirectory',
        );
        final environment = D4.coerceMapOrNull<String, String>(
          named['environment'],
          'environment',
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final stopOnFailure = D4.getNamedArgWithDefault<bool>(
          named,
          'stopOnFailure',
          true,
        );
        return t.runAll(
          commands: commands,
          workingDirectory: workingDirectory,
          environment: environment,
          verbose: verbose,
          stopOnFailure: stopOnFailure,
        );
      },
    },
    constructorSignatures: {
      '': 'CommandRunner({bool shell = true, Duration defaultTimeout = const Duration(minutes: 5)})',
    },
    methodSignatures: {
      'run':
          'Future<CommandResult> run({required String command, String? workingDirectory, Map<String, String>? environment, bool verbose = false, Duration? timeout})',
      'runAll':
          'Future<List<CommandResult>> runAll({required List<String> commands, String? workingDirectory, Map<String, String>? environment, bool verbose = false, bool stopOnFailure = true})',
    },
    getterSignatures: {
      'shell': 'bool get shell',
      'defaultTimeout': 'Duration get defaultTimeout',
    },
  );
}

// =============================================================================
// D4rtResult Bridge
// =============================================================================

BridgedClass _createD4rtResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_17.D4rtResult,
    name: 'D4rtResult',
    constructors: {
      'success': (visitor, positional, named) {
        final code = D4.getRequiredNamedArg<String>(
          named,
          'code',
          'D4rtResult',
        );
        final value = D4.getOptionalNamedArg<dynamic>(named, 'value');
        final output = D4.getNamedArgWithDefault<String>(named, 'output', '');
        final duration = D4.getNamedArgWithDefault<Duration>(
          named,
          'duration',
          Duration.zero,
        );
        return $tom_build_cli_17.D4rtResult.success(
          code: code,
          value: value,
          output: output,
          duration: duration,
        );
      },
      'failure': (visitor, positional, named) {
        final code = D4.getRequiredNamedArg<String>(
          named,
          'code',
          'D4rtResult',
        );
        final error = D4.getRequiredNamedArg<String>(
          named,
          'error',
          'D4rtResult',
        );
        final output = D4.getNamedArgWithDefault<String>(named, 'output', '');
        final duration = D4.getNamedArgWithDefault<Duration>(
          named,
          'duration',
          Duration.zero,
        );
        return $tom_build_cli_17.D4rtResult.failure(
          code: code,
          error: error,
          output: output,
          duration: duration,
        );
      },
    },
    getters: {
      'code': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtResult>(target, 'D4rtResult')
          .code,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtResult>(target, 'D4rtResult')
          .success,
      'value': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtResult>(target, 'D4rtResult')
          .value,
      'output': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtResult>(target, 'D4rtResult')
          .output,
      'error': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtResult>(target, 'D4rtResult')
          .error,
      'duration': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtResult>(target, 'D4rtResult')
          .duration,
    },
    constructorSignatures: {
      'success':
          'factory D4rtResult.success({required String code, dynamic value, String output = \'\', Duration duration = Duration.zero})',
      'failure':
          'factory D4rtResult.failure({required String code, required String error, String output = \'\', Duration duration = Duration.zero})',
    },
    getterSignatures: {
      'code': 'String get code',
      'success': 'bool get success',
      'value': 'dynamic get value',
      'output': 'String get output',
      'error': 'String? get error',
      'duration': 'Duration get duration',
    },
  );
}

// =============================================================================
// D4rtRunnerConfig Bridge
// =============================================================================

BridgedClass _createD4rtRunnerConfigBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_17.D4rtRunnerConfig,
    name: 'D4rtRunnerConfig',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'D4rtRunnerConfig',
        );
        final scriptsPath = D4.getOptionalNamedArg<String?>(
          named,
          'scriptsPath',
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final context = named.containsKey('context') && named['context'] != null
            ? D4.coerceMap<String, dynamic>(named['context'], 'context')
            : const <String, dynamic>{};
        final workspace = D4.getOptionalNamedArg<$tom_build_1.TomWorkspace?>(
          named,
          'workspace',
        );
        final workspaceContext = D4
            .getOptionalNamedArg<$tom_build_cli_11.WorkspaceContext?>(
              named,
              'workspaceContext',
            );
        final currentProject = D4.getOptionalNamedArg<$tom_build_1.TomProject?>(
          named,
          'currentProject',
        );
        return $tom_build_cli_17.D4rtRunnerConfig(
          workspacePath: workspacePath,
          scriptsPath: scriptsPath,
          verbose: verbose,
          context: context,
          workspace: workspace,
          workspaceContext: workspaceContext,
          currentProject: currentProject,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtRunnerConfig>(
            target,
            'D4rtRunnerConfig',
          )
          .workspacePath,
      'scriptsPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtRunnerConfig>(
            target,
            'D4rtRunnerConfig',
          )
          .scriptsPath,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtRunnerConfig>(
            target,
            'D4rtRunnerConfig',
          )
          .verbose,
      'context': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtRunnerConfig>(
            target,
            'D4rtRunnerConfig',
          )
          .context,
      'workspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtRunnerConfig>(
            target,
            'D4rtRunnerConfig',
          )
          .workspace,
      'workspaceContext': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtRunnerConfig>(
            target,
            'D4rtRunnerConfig',
          )
          .workspaceContext,
      'currentProject': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtRunnerConfig>(
            target,
            'D4rtRunnerConfig',
          )
          .currentProject,
      'scriptsDir': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtRunnerConfig>(
            target,
            'D4rtRunnerConfig',
          )
          .scriptsDir,
    },
    constructorSignatures: {
      '': 'const D4rtRunnerConfig({required String workspacePath, String? scriptsPath, bool verbose = false, Map<String, dynamic> context = const {}, TomWorkspace? workspace, WorkspaceContext? workspaceContext, TomProject? currentProject})',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'scriptsPath': 'String? get scriptsPath',
      'verbose': 'bool get verbose',
      'context': 'Map<String, dynamic> get context',
      'workspace': 'TomWorkspace? get workspace',
      'workspaceContext': 'WorkspaceContext? get workspaceContext',
      'currentProject': 'TomProject? get currentProject',
      'scriptsDir': 'String get scriptsDir',
    },
  );
}

// =============================================================================
// D4rtRunner Bridge
// =============================================================================

BridgedClass _createD4rtRunnerBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_17.D4rtRunner,
    name: 'D4rtRunner',
    constructors: {
      '': (visitor, positional, named) {
        final config = D4
            .getRequiredNamedArg<$tom_build_cli_17.D4rtRunnerConfig>(
              named,
              'config',
              'D4rtRunner',
            );
        final evaluatorRaw = named['evaluator'];
        return $tom_build_cli_17.D4rtRunner(
          config: config,
          evaluator: evaluatorRaw == null
              ? null
              : (String p0, Map<String, dynamic> p1) {
                  return D4.callInterpreterCallback(visitor, evaluatorRaw, [
                        p0,
                        p1,
                      ])
                      as Future<dynamic>;
                },
        );
      },
    },
    getters: {
      'config': (visitor, target) => D4
          .validateTarget<$tom_build_cli_17.D4rtRunner>(target, 'D4rtRunner')
          .config,
    },
    methods: {
      'getCommandType': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_17.D4rtRunner>(
          target,
          'D4rtRunner',
        );
        D4.requireMinArgs(positional, 1, 'getCommandType');
        final command = D4.getRequiredArg<String>(
          positional,
          0,
          'command',
          'getCommandType',
        );
        return t.getCommandType(command);
      },
      'isD4rtCommand': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_17.D4rtRunner>(
          target,
          'D4rtRunner',
        );
        D4.requireMinArgs(positional, 1, 'isD4rtCommand');
        final command = D4.getRequiredArg<String>(
          positional,
          0,
          'command',
          'isD4rtCommand',
        );
        return t.isD4rtCommand(command);
      },
      'isVSCodeCommand': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_17.D4rtRunner>(
          target,
          'D4rtRunner',
        );
        D4.requireMinArgs(positional, 1, 'isVSCodeCommand');
        final command = D4.getRequiredArg<String>(
          positional,
          0,
          'command',
          'isVSCodeCommand',
        );
        return t.isVSCodeCommand(command);
      },
      'isLocalD4rtCommand': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_17.D4rtRunner>(
          target,
          'D4rtRunner',
        );
        D4.requireMinArgs(positional, 1, 'isLocalD4rtCommand');
        final command = D4.getRequiredArg<String>(
          positional,
          0,
          'command',
          'isLocalD4rtCommand',
        );
        return t.isLocalD4rtCommand(command);
      },
      'run': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_17.D4rtRunner>(
          target,
          'D4rtRunner',
        );
        D4.requireMinArgs(positional, 1, 'run');
        final command = D4.getRequiredArg<String>(
          positional,
          0,
          'command',
          'run',
        );
        return t.run(command);
      },
    },
    constructorSignatures: {
      '': 'D4rtRunner({required D4rtRunnerConfig config, ActionD4rtEvaluator? evaluator})',
    },
    methodSignatures: {
      'getCommandType': 'D4rtCommandType getCommandType(String command)',
      'isD4rtCommand': 'bool isD4rtCommand(String command)',
      'isVSCodeCommand': 'bool isVSCodeCommand(String command)',
      'isLocalD4rtCommand': 'bool isLocalD4rtCommand(String command)',
      'run': 'Future<D4rtResult> run(String command)',
    },
    getterSignatures: {'config': 'D4rtRunnerConfig get config'},
  );
}

// =============================================================================
// AnsiColors Bridge
// =============================================================================

BridgedClass _createAnsiColorsBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_18.AnsiColors,
    name: 'AnsiColors',
    constructors: {},
    staticGetters: {
      'reset': (visitor) => $tom_build_cli_18.AnsiColors.reset,
      'black': (visitor) => $tom_build_cli_18.AnsiColors.black,
      'red': (visitor) => $tom_build_cli_18.AnsiColors.red,
      'green': (visitor) => $tom_build_cli_18.AnsiColors.green,
      'yellow': (visitor) => $tom_build_cli_18.AnsiColors.yellow,
      'blue': (visitor) => $tom_build_cli_18.AnsiColors.blue,
      'magenta': (visitor) => $tom_build_cli_18.AnsiColors.magenta,
      'cyan': (visitor) => $tom_build_cli_18.AnsiColors.cyan,
      'white': (visitor) => $tom_build_cli_18.AnsiColors.white,
      'brightBlack': (visitor) => $tom_build_cli_18.AnsiColors.brightBlack,
      'brightRed': (visitor) => $tom_build_cli_18.AnsiColors.brightRed,
      'brightGreen': (visitor) => $tom_build_cli_18.AnsiColors.brightGreen,
      'brightYellow': (visitor) => $tom_build_cli_18.AnsiColors.brightYellow,
      'brightBlue': (visitor) => $tom_build_cli_18.AnsiColors.brightBlue,
      'brightMagenta': (visitor) => $tom_build_cli_18.AnsiColors.brightMagenta,
      'brightCyan': (visitor) => $tom_build_cli_18.AnsiColors.brightCyan,
      'brightWhite': (visitor) => $tom_build_cli_18.AnsiColors.brightWhite,
      'bold': (visitor) => $tom_build_cli_18.AnsiColors.bold,
      'dim': (visitor) => $tom_build_cli_18.AnsiColors.dim,
      'italic': (visitor) => $tom_build_cli_18.AnsiColors.italic,
      'underline': (visitor) => $tom_build_cli_18.AnsiColors.underline,
    },
    staticGetterSignatures: {
      'reset': 'String get reset',
      'black': 'String get black',
      'red': 'String get red',
      'green': 'String get green',
      'yellow': 'String get yellow',
      'blue': 'String get blue',
      'magenta': 'String get magenta',
      'cyan': 'String get cyan',
      'white': 'String get white',
      'brightBlack': 'String get brightBlack',
      'brightRed': 'String get brightRed',
      'brightGreen': 'String get brightGreen',
      'brightYellow': 'String get brightYellow',
      'brightBlue': 'String get brightBlue',
      'brightMagenta': 'String get brightMagenta',
      'brightCyan': 'String get brightCyan',
      'brightWhite': 'String get brightWhite',
      'bold': 'String get bold',
      'dim': 'String get dim',
      'italic': 'String get italic',
      'underline': 'String get underline',
    },
  );
}

// =============================================================================
// OutputFormatterConfig Bridge
// =============================================================================

BridgedClass _createOutputFormatterConfigBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_18.OutputFormatterConfig,
    name: 'OutputFormatterConfig',
    constructors: {
      '': (visitor, positional, named) {
        final useColors = D4.getNamedArgWithDefault<bool>(
          named,
          'useColors',
          true,
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final showProgress = D4.getNamedArgWithDefault<bool>(
          named,
          'showProgress',
          true,
        );
        final showTimings = D4.getNamedArgWithDefault<bool>(
          named,
          'showTimings',
          true,
        );
        final maxWidth = D4.getNamedArgWithDefault<int>(named, 'maxWidth', 80);
        return $tom_build_cli_18.OutputFormatterConfig(
          useColors: useColors,
          verbose: verbose,
          showProgress: showProgress,
          showTimings: showTimings,
          maxWidth: maxWidth,
        );
      },
    },
    getters: {
      'useColors': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.OutputFormatterConfig>(
            target,
            'OutputFormatterConfig',
          )
          .useColors,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.OutputFormatterConfig>(
            target,
            'OutputFormatterConfig',
          )
          .verbose,
      'showProgress': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.OutputFormatterConfig>(
            target,
            'OutputFormatterConfig',
          )
          .showProgress,
      'showTimings': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.OutputFormatterConfig>(
            target,
            'OutputFormatterConfig',
          )
          .showTimings,
      'maxWidth': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.OutputFormatterConfig>(
            target,
            'OutputFormatterConfig',
          )
          .maxWidth,
    },
    methods: {
      'copyWith': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatterConfig>(
          target,
          'OutputFormatterConfig',
        );
        final useColors = D4.getOptionalNamedArg<bool?>(named, 'useColors');
        final verbose = D4.getOptionalNamedArg<bool?>(named, 'verbose');
        final showProgress = D4.getOptionalNamedArg<bool?>(
          named,
          'showProgress',
        );
        final showTimings = D4.getOptionalNamedArg<bool?>(named, 'showTimings');
        final maxWidth = D4.getOptionalNamedArg<int?>(named, 'maxWidth');
        return t.copyWith(
          useColors: useColors,
          verbose: verbose,
          showProgress: showProgress,
          showTimings: showTimings,
          maxWidth: maxWidth,
        );
      },
    },
    constructorSignatures: {
      '': 'const OutputFormatterConfig({bool useColors = true, bool verbose = false, bool showProgress = true, bool showTimings = true, int maxWidth = 80})',
    },
    methodSignatures: {
      'copyWith':
          'OutputFormatterConfig copyWith({bool? useColors, bool? verbose, bool? showProgress, bool? showTimings, int? maxWidth})',
    },
    getterSignatures: {
      'useColors': 'bool get useColors',
      'verbose': 'bool get verbose',
      'showProgress': 'bool get showProgress',
      'showTimings': 'bool get showTimings',
      'maxWidth': 'int get maxWidth',
    },
  );
}

// =============================================================================
// ErrorMessage Bridge
// =============================================================================

BridgedClass _createErrorMessageBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_18.ErrorMessage,
    name: 'ErrorMessage',
    constructors: {
      '': (visitor, positional, named) {
        final description = D4.getRequiredNamedArg<String>(
          named,
          'description',
          'ErrorMessage',
        );
        final filePath = D4.getOptionalNamedArg<String?>(named, 'filePath');
        final lineNumber = D4.getOptionalNamedArg<int?>(named, 'lineNumber');
        final resolution = D4.getOptionalNamedArg<String?>(named, 'resolution');
        final context = D4.getOptionalNamedArg<String?>(named, 'context');
        return $tom_build_cli_18.ErrorMessage(
          description: description,
          filePath: filePath,
          lineNumber: lineNumber,
          resolution: resolution,
          context: context,
        );
      },
    },
    getters: {
      'description': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.ErrorMessage>(
            target,
            'ErrorMessage',
          )
          .description,
      'filePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.ErrorMessage>(
            target,
            'ErrorMessage',
          )
          .filePath,
      'lineNumber': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.ErrorMessage>(
            target,
            'ErrorMessage',
          )
          .lineNumber,
      'resolution': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.ErrorMessage>(
            target,
            'ErrorMessage',
          )
          .resolution,
      'context': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.ErrorMessage>(
            target,
            'ErrorMessage',
          )
          .context,
    },
    methods: {
      'format': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.ErrorMessage>(
          target,
          'ErrorMessage',
        );
        final useColors = D4.getNamedArgWithDefault<bool>(
          named,
          'useColors',
          false,
        );
        return t.format(useColors: useColors);
      },
    },
    constructorSignatures: {
      '': 'const ErrorMessage({required String description, String? filePath, int? lineNumber, String? resolution, String? context})',
    },
    methodSignatures: {'format': 'String format({bool useColors = false})'},
    getterSignatures: {
      'description': 'String get description',
      'filePath': 'String? get filePath',
      'lineNumber': 'int? get lineNumber',
      'resolution': 'String? get resolution',
      'context': 'String? get context',
    },
  );
}

// =============================================================================
// ProgressIndicator Bridge
// =============================================================================

BridgedClass _createProgressIndicatorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_18.ProgressIndicator,
    name: 'ProgressIndicator',
    constructors: {
      '': (visitor, positional, named) {
        final message = D4.getRequiredNamedArg<String>(
          named,
          'message',
          'ProgressIndicator',
        );
        final total = D4.getRequiredNamedArg<int>(
          named,
          'total',
          'ProgressIndicator',
        );
        final useColors = D4.getNamedArgWithDefault<bool>(
          named,
          'useColors',
          false,
        );
        return $tom_build_cli_18.ProgressIndicator(
          message: message,
          total: total,
          useColors: useColors,
        );
      },
    },
    getters: {
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.ProgressIndicator>(
            target,
            'ProgressIndicator',
          )
          .message,
      'total': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.ProgressIndicator>(
            target,
            'ProgressIndicator',
          )
          .total,
      'useColors': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.ProgressIndicator>(
            target,
            'ProgressIndicator',
          )
          .useColors,
    },
    methods: {
      'update': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.ProgressIndicator>(
          target,
          'ProgressIndicator',
        );
        D4.requireMinArgs(positional, 1, 'update');
        final current = D4.getRequiredArg<int>(
          positional,
          0,
          'current',
          'update',
        );
        final itemName = D4.getOptionalNamedArg<String?>(named, 'itemName');
        t.update(current, itemName: itemName);
        return null;
      },
      'increment': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.ProgressIndicator>(
          target,
          'ProgressIndicator',
        );
        final itemName = D4.getOptionalNamedArg<String?>(named, 'itemName');
        t.increment(itemName: itemName);
        return null;
      },
      'complete': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.ProgressIndicator>(
          target,
          'ProgressIndicator',
        );
        final summary = D4.getOptionalNamedArg<String?>(named, 'summary');
        t.complete(summary: summary);
        return null;
      },
    },
    constructorSignatures: {
      '': 'ProgressIndicator({required String message, required int total, bool useColors = false})',
    },
    methodSignatures: {
      'update': 'void update(int current, {String? itemName})',
      'increment': 'void increment({String? itemName})',
      'complete': 'void complete({String? summary})',
    },
    getterSignatures: {
      'message': 'String get message',
      'total': 'int get total',
      'useColors': 'bool get useColors',
    },
  );
}

// =============================================================================
// OutputFormatter Bridge
// =============================================================================

BridgedClass _createOutputFormatterBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_18.OutputFormatter,
    name: 'OutputFormatter',
    constructors: {
      '': (visitor, positional, named) {
        final config = D4
            .getOptionalNamedArg<$tom_build_cli_18.OutputFormatterConfig?>(
              named,
              'config',
            );
        final output = D4.getOptionalNamedArg<StringSink?>(named, 'output');
        final errorOutput = D4.getOptionalNamedArg<StringSink?>(
          named,
          'errorOutput',
        );
        return $tom_build_cli_18.OutputFormatter(
          config: config,
          output: output,
          errorOutput: errorOutput,
        );
      },
    },
    getters: {
      'useColors': (visitor, target) => D4
          .validateTarget<$tom_build_cli_18.OutputFormatter>(
            target,
            'OutputFormatter',
          )
          .useColors,
    },
    methods: {
      'printError': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 1, 'printError');
        final error = D4.getRequiredArg<$tom_build_cli_18.ErrorMessage>(
          positional,
          0,
          'error',
          'printError',
        );
        t.printError(error);
        return null;
      },
      'printErrorString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 1, 'printErrorString');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'printErrorString',
        );
        t.printErrorString(message);
        return null;
      },
      'printCircularDependencyError':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
              target,
              'OutputFormatter',
            );
            D4.requireMinArgs(positional, 1, 'printCircularDependencyError');
            if (positional.isEmpty) {
              throw ArgumentError(
                'printCircularDependencyError: Missing required argument "cycle" at position 0',
              );
            }
            final cycle = D4.coerceList<String>(positional[0], 'cycle');
            t.printCircularDependencyError(cycle);
            return null;
          },
      'printPlaceholderRecursionError':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
              target,
              'OutputFormatter',
            );
            final filePath = D4.getRequiredNamedArg<String>(
              named,
              'filePath',
              'printPlaceholderRecursionError',
            );
            if (!named.containsKey('unresolved') ||
                named['unresolved'] == null) {
              throw ArgumentError(
                'printPlaceholderRecursionError: Missing required named argument "unresolved"',
              );
            }
            final unresolved = D4.coerceList<String>(
              named['unresolved'],
              'unresolved',
            );
            t.printPlaceholderRecursionError(
              filePath: filePath,
              unresolved: unresolved,
            );
            return null;
          },
      'printScopeConflictError':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
              target,
              'OutputFormatter',
            );
            D4.requireMinArgs(positional, 1, 'printScopeConflictError');
            final command = D4.getRequiredArg<String>(
              positional,
              0,
              'command',
              'printScopeConflictError',
            );
            t.printScopeConflictError(command);
            return null;
          },
      'printSuccess': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 1, 'printSuccess');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'printSuccess',
        );
        t.printSuccess(message);
        return null;
      },
      'printInfo': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 1, 'printInfo');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'printInfo',
        );
        t.printInfo(message);
        return null;
      },
      'printWarning': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 1, 'printWarning');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'printWarning',
        );
        t.printWarning(message);
        return null;
      },
      'printVerbose': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 1, 'printVerbose');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'printVerbose',
        );
        t.printVerbose(message);
        return null;
      },
      'createProgress': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 2, 'createProgress');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'createProgress',
        );
        final total = D4.getRequiredArg<int>(
          positional,
          1,
          'total',
          'createProgress',
        );
        return t.createProgress(message, total);
      },
      'printHeader': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 1, 'printHeader');
        final title = D4.getRequiredArg<String>(
          positional,
          0,
          'title',
          'printHeader',
        );
        t.printHeader(title);
        return null;
      },
      'formatCommandResult': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 1, 'formatCommandResult');
        final result = D4.getRequiredArg<$tom_build_cli_16.CommandResult>(
          positional,
          0,
          'result',
          'formatCommandResult',
        );
        return t.formatCommandResult(result);
      },
      'formatActionResult': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        D4.requireMinArgs(positional, 1, 'formatActionResult');
        final result = D4
            .getRequiredArg<$tom_build_cli_15.ActionExecutionResult>(
              positional,
              0,
              'result',
              'formatActionResult',
            );
        return t.formatActionResult(result);
      },
      'formatInternalCommandResult':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
              target,
              'OutputFormatter',
            );
            D4.requireMinArgs(positional, 1, 'formatInternalCommandResult');
            final result = D4
                .getRequiredArg<$tom_build_cli_8.InternalCommandResult>(
                  positional,
                  0,
                  'result',
                  'formatInternalCommandResult',
                );
            return t.formatInternalCommandResult(result);
          },
      'formatSummary': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        if (!named.containsKey('actionResults') ||
            named['actionResults'] == null) {
          throw ArgumentError(
            'formatSummary: Missing required named argument "actionResults"',
          );
        }
        final actionResults = D4
            .coerceList<$tom_build_cli_15.ActionExecutionResult>(
              named['actionResults'],
              'actionResults',
            );
        if (!named.containsKey('commandResults') ||
            named['commandResults'] == null) {
          throw ArgumentError(
            'formatSummary: Missing required named argument "commandResults"',
          );
        }
        final commandResults = D4
            .coerceList<$tom_build_cli_8.InternalCommandResult>(
              named['commandResults'],
              'commandResults',
            );
        final totalDuration = D4.getRequiredNamedArg<Duration>(
          named,
          'totalDuration',
          'formatSummary',
        );
        return t.formatSummary(
          actionResults: actionResults,
          commandResults: commandResults,
          totalDuration: totalDuration,
        );
      },
      'printSummary': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        if (!named.containsKey('actionResults') ||
            named['actionResults'] == null) {
          throw ArgumentError(
            'printSummary: Missing required named argument "actionResults"',
          );
        }
        final actionResults = D4
            .coerceList<$tom_build_cli_15.ActionExecutionResult>(
              named['actionResults'],
              'actionResults',
            );
        if (!named.containsKey('commandResults') ||
            named['commandResults'] == null) {
          throw ArgumentError(
            'printSummary: Missing required named argument "commandResults"',
          );
        }
        final commandResults = D4
            .coerceList<$tom_build_cli_8.InternalCommandResult>(
              named['commandResults'],
              'commandResults',
            );
        final totalDuration = D4.getRequiredNamedArg<Duration>(
          named,
          'totalDuration',
          'printSummary',
        );
        t.printSummary(
          actionResults: actionResults,
          commandResults: commandResults,
          totalDuration: totalDuration,
        );
        return null;
      },
      'formatHelp': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_18.OutputFormatter>(
          target,
          'OutputFormatter',
        );
        final toolName = D4.getRequiredNamedArg<String>(
          named,
          'toolName',
          'formatHelp',
        );
        final version = D4.getRequiredNamedArg<String>(
          named,
          'version',
          'formatHelp',
        );
        final description = D4.getRequiredNamedArg<String>(
          named,
          'description',
          'formatHelp',
        );
        if (!named.containsKey('usage') || named['usage'] == null) {
          throw ArgumentError(
            'formatHelp: Missing required named argument "usage"',
          );
        }
        final usage = D4.coerceList<String>(named['usage'], 'usage');
        if (!named.containsKey('commands') || named['commands'] == null) {
          throw ArgumentError(
            'formatHelp: Missing required named argument "commands"',
          );
        }
        final commands = D4.coerceMap<String, String>(
          named['commands'],
          'commands',
        );
        if (!named.containsKey('options') || named['options'] == null) {
          throw ArgumentError(
            'formatHelp: Missing required named argument "options"',
          );
        }
        final options = D4.coerceMap<String, String>(
          named['options'],
          'options',
        );
        return t.formatHelp(
          toolName: toolName,
          version: version,
          description: description,
          usage: usage,
          commands: commands,
          options: options,
        );
      },
    },
    constructorSignatures: {
      '': 'OutputFormatter({OutputFormatterConfig? config, StringSink? output, StringSink? errorOutput})',
    },
    methodSignatures: {
      'printError': 'void printError(ErrorMessage error)',
      'printErrorString': 'void printErrorString(String message)',
      'printCircularDependencyError':
          'void printCircularDependencyError(List<String> cycle)',
      'printPlaceholderRecursionError':
          'void printPlaceholderRecursionError({required String filePath, required List<String> unresolved})',
      'printScopeConflictError': 'void printScopeConflictError(String command)',
      'printSuccess': 'void printSuccess(String message)',
      'printInfo': 'void printInfo(String message)',
      'printWarning': 'void printWarning(String message)',
      'printVerbose': 'void printVerbose(String message)',
      'createProgress':
          'ProgressIndicator createProgress(String message, int total)',
      'printHeader': 'void printHeader(String title)',
      'formatCommandResult': 'String formatCommandResult(CommandResult result)',
      'formatActionResult':
          'String formatActionResult(ActionExecutionResult result)',
      'formatInternalCommandResult':
          'String formatInternalCommandResult(InternalCommandResult result)',
      'formatSummary':
          'String formatSummary({required List<ActionExecutionResult> actionResults, required List<InternalCommandResult> commandResults, required Duration totalDuration})',
      'printSummary':
          'void printSummary({required List<ActionExecutionResult> actionResults, required List<InternalCommandResult> commandResults, required Duration totalDuration})',
      'formatHelp':
          'String formatHelp({required String toolName, required String version, required String description, required List<String> usage, required Map<String, String> commands, required Map<String, String> options})',
    },
    getterSignatures: {'useColors': 'bool get useColors'},
  );
}

// =============================================================================
// BuildOrderProject Bridge
// =============================================================================

BridgedClass _createBuildOrderProjectBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_19.BuildOrderProject,
    name: 'BuildOrderProject',
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(
          named,
          'name',
          'BuildOrderProject',
        );
        final buildAfter =
            named.containsKey('buildAfter') && named['buildAfter'] != null
            ? D4.coerceList<String>(named['buildAfter'], 'buildAfter')
            : const <String>[];
        return $tom_build_cli_19.BuildOrderProject(
          name: name,
          buildAfter: buildAfter,
        );
      },
    },
    getters: {
      'name': (visitor, target) => D4
          .validateTarget<$tom_build_cli_19.BuildOrderProject>(
            target,
            'BuildOrderProject',
          )
          .name,
      'buildAfter': (visitor, target) => D4
          .validateTarget<$tom_build_cli_19.BuildOrderProject>(
            target,
            'BuildOrderProject',
          )
          .buildAfter,
    },
    constructorSignatures: {
      '': 'const BuildOrderProject({required String name, List<String> buildAfter = const []})',
    },
    getterSignatures: {
      'name': 'String get name',
      'buildAfter': 'List<String> get buildAfter',
    },
  );
}

// =============================================================================
// BuildOrderResult Bridge
// =============================================================================

BridgedClass _createBuildOrderResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_19.BuildOrderResult,
    name: 'BuildOrderResult',
    constructors: {
      'success': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'BuildOrderResult');
        if (positional.isEmpty) {
          throw ArgumentError(
            'BuildOrderResult: Missing required argument "order" at position 0',
          );
        }
        final order = D4.coerceList<String>(positional[0], 'order');
        return $tom_build_cli_19.BuildOrderResult.success(order);
      },
      'error': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'BuildOrderResult');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'BuildOrderResult',
        );
        final circularPath = D4.coerceListOrNull<String>(
          named['circularPath'],
          'circularPath',
        );
        return $tom_build_cli_19.BuildOrderResult.error(
          message,
          circularPath: circularPath,
        );
      },
    },
    getters: {
      'order': (visitor, target) => D4
          .validateTarget<$tom_build_cli_19.BuildOrderResult>(
            target,
            'BuildOrderResult',
          )
          .order,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_19.BuildOrderResult>(
            target,
            'BuildOrderResult',
          )
          .success,
      'error': (visitor, target) => D4
          .validateTarget<$tom_build_cli_19.BuildOrderResult>(
            target,
            'BuildOrderResult',
          )
          .error,
      'circularPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_19.BuildOrderResult>(
            target,
            'BuildOrderResult',
          )
          .circularPath,
    },
    constructorSignatures: {
      'success': 'factory BuildOrderResult.success(List<String> order)',
      'error':
          'factory BuildOrderResult.error(String message, {List<String>? circularPath})',
    },
    getterSignatures: {
      'order': 'List<String> get order',
      'success': 'bool get success',
      'error': 'String? get error',
      'circularPath': 'List<String>? get circularPath',
    },
  );
}

// =============================================================================
// CircularDependencyException Bridge
// =============================================================================

BridgedClass _createCircularDependencyExceptionBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_19.CircularDependencyException,
    name: 'CircularDependencyException',
    constructors: {
      '': (visitor, positional, named) {
        final message = D4.getRequiredNamedArg<String>(
          named,
          'message',
          'CircularDependencyException',
        );
        if (!named.containsKey('cyclePath') || named['cyclePath'] == null) {
          throw ArgumentError(
            'CircularDependencyException: Missing required named argument "cyclePath"',
          );
        }
        final cyclePath = D4.coerceList<String>(
          named['cyclePath'],
          'cyclePath',
        );
        return $tom_build_cli_19.CircularDependencyException(
          message: message,
          cyclePath: cyclePath,
        );
      },
    },
    getters: {
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_19.CircularDependencyException>(
            target,
            'CircularDependencyException',
          )
          .message,
      'cyclePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_19.CircularDependencyException>(
            target,
            'CircularDependencyException',
          )
          .cyclePath,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4
            .validateTarget<$tom_build_cli_19.CircularDependencyException>(
              target,
              'CircularDependencyException',
            );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const CircularDependencyException({required String message, required List<String> cyclePath})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'message': 'String get message',
      'cyclePath': 'List<String> get cyclePath',
    },
  );
}

// =============================================================================
// BuildOrderCalculator Bridge
// =============================================================================

BridgedClass _createBuildOrderCalculatorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_19.BuildOrderCalculator,
    name: 'BuildOrderCalculator',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_19.BuildOrderCalculator();
      },
    },
    methods: {
      'calculateBuildOrder': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_19.BuildOrderCalculator>(
          target,
          'BuildOrderCalculator',
        );
        D4.requireMinArgs(positional, 1, 'calculateBuildOrder');
        if (positional.isEmpty) {
          throw ArgumentError(
            'calculateBuildOrder: Missing required argument "projects" at position 0',
          );
        }
        final projects = D4
            .coerceMap<String, $tom_build_cli_19.BuildOrderProject>(
              positional[0],
              'projects',
            );
        return t.calculateBuildOrder(projects);
      },
      'calculateBuildOrderSafe': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_19.BuildOrderCalculator>(
          target,
          'BuildOrderCalculator',
        );
        D4.requireMinArgs(positional, 1, 'calculateBuildOrderSafe');
        if (positional.isEmpty) {
          throw ArgumentError(
            'calculateBuildOrderSafe: Missing required argument "projects" at position 0',
          );
        }
        final projects = D4
            .coerceMap<String, $tom_build_cli_19.BuildOrderProject>(
              positional[0],
              'projects',
            );
        return t.calculateBuildOrderSafe(projects);
      },
      'calculateActionOrder': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_19.BuildOrderCalculator>(
          target,
          'BuildOrderCalculator',
        );
        if (!named.containsKey('projects') || named['projects'] == null) {
          throw ArgumentError(
            'calculateActionOrder: Missing required named argument "projects"',
          );
        }
        final projects = D4
            .coerceMap<String, $tom_build_cli_19.BuildOrderProject>(
              named['projects'],
              'projects',
            );
        final action = D4.getRequiredNamedArg<String>(
          named,
          'action',
          'calculateActionOrder',
        );
        final actionDeps = D4.coerceMapOrNull<String, List<String>>(
          named['actionDeps'],
          'actionDeps',
        );
        return t.calculateActionOrder(
          projects: projects,
          action: action,
          actionDeps: actionDeps,
        );
      },
      'validateDependencies': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_19.BuildOrderCalculator>(
          target,
          'BuildOrderCalculator',
        );
        D4.requireMinArgs(positional, 1, 'validateDependencies');
        if (positional.isEmpty) {
          throw ArgumentError(
            'validateDependencies: Missing required argument "projects" at position 0',
          );
        }
        final projects = D4
            .coerceMap<String, $tom_build_cli_19.BuildOrderProject>(
              positional[0],
              'projects',
            );
        return t.validateDependencies(projects);
      },
    },
    staticMethods: {
      'fromProjectConfigs': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'fromProjectConfigs');
        if (positional.isEmpty) {
          throw ArgumentError(
            'fromProjectConfigs: Missing required argument "configs" at position 0',
          );
        }
        final configs = D4.coerceMap<String, Map<String, dynamic>>(
          positional[0],
          'configs',
        );
        return $tom_build_cli_19.BuildOrderCalculator.fromProjectConfigs(
          configs,
        );
      },
    },
    constructorSignatures: {'': 'BuildOrderCalculator()'},
    methodSignatures: {
      'calculateBuildOrder':
          'List<String> calculateBuildOrder(Map<String, BuildOrderProject> projects)',
      'calculateBuildOrderSafe':
          'BuildOrderResult calculateBuildOrderSafe(Map<String, BuildOrderProject> projects)',
      'calculateActionOrder':
          'List<String> calculateActionOrder({required Map<String, BuildOrderProject> projects, required String action, Map<String, List<String>>? actionDeps})',
      'validateDependencies':
          'List<String> validateDependencies(Map<String, BuildOrderProject> projects)',
    },
    staticMethodSignatures: {
      'fromProjectConfigs':
          'Map<String, BuildOrderProject> fromProjectConfigs(Map<String, Map<String, dynamic>> configs)',
    },
  );
}

// =============================================================================
// GeneratorResult Bridge
// =============================================================================

BridgedClass _createGeneratorResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_20.GeneratorResult,
    name: 'GeneratorResult',
    constructors: {
      '': (visitor, positional, named) {
        final value = D4.getRequiredNamedArg<dynamic>(
          named,
          'value',
          'GeneratorResult',
        );
        final fullyResolved = D4.getRequiredNamedArg<bool>(
          named,
          'fullyResolved',
          'GeneratorResult',
        );
        final unresolvedGenerators =
            named.containsKey('unresolvedGenerators') &&
                named['unresolvedGenerators'] != null
            ? D4.coerceList<String>(
                named['unresolvedGenerators'],
                'unresolvedGenerators',
              )
            : const <String>[];
        return $tom_build_cli_20.GeneratorResult(
          value: value,
          fullyResolved: fullyResolved,
          unresolvedGenerators: unresolvedGenerators,
        );
      },
    },
    getters: {
      'value': (visitor, target) => D4
          .validateTarget<$tom_build_cli_20.GeneratorResult>(
            target,
            'GeneratorResult',
          )
          .value,
      'fullyResolved': (visitor, target) => D4
          .validateTarget<$tom_build_cli_20.GeneratorResult>(
            target,
            'GeneratorResult',
          )
          .fullyResolved,
      'unresolvedGenerators': (visitor, target) => D4
          .validateTarget<$tom_build_cli_20.GeneratorResult>(
            target,
            'GeneratorResult',
          )
          .unresolvedGenerators,
    },
    constructorSignatures: {
      '': 'const GeneratorResult({required dynamic value, required bool fullyResolved, List<String> unresolvedGenerators = const []})',
    },
    getterSignatures: {
      'value': 'dynamic get value',
      'fullyResolved': 'bool get fullyResolved',
      'unresolvedGenerators': 'List<String> get unresolvedGenerators',
    },
  );
}

// =============================================================================
// GeneratorResolutionException Bridge
// =============================================================================

BridgedClass _createGeneratorResolutionExceptionBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_20.GeneratorResolutionException,
    name: 'GeneratorResolutionException',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'GeneratorResolutionException');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'GeneratorResolutionException',
        );
        final generator = D4.getOptionalNamedArg<String?>(named, 'generator');
        return $tom_build_cli_20.GeneratorResolutionException(
          message,
          generator: generator,
        );
      },
    },
    getters: {
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_20.GeneratorResolutionException>(
            target,
            'GeneratorResolutionException',
          )
          .message,
      'generator': (visitor, target) => D4
          .validateTarget<$tom_build_cli_20.GeneratorResolutionException>(
            target,
            'GeneratorResolutionException',
          )
          .generator,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4
            .validateTarget<$tom_build_cli_20.GeneratorResolutionException>(
              target,
              'GeneratorResolutionException',
            );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const GeneratorResolutionException(String message, {String? generator})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'message': 'String get message',
      'generator': 'String? get generator',
    },
  );
}

// =============================================================================
// GeneratorPlaceholderResolver Bridge
// =============================================================================

BridgedClass _createGeneratorPlaceholderResolverBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_20.GeneratorPlaceholderResolver,
    name: 'GeneratorPlaceholderResolver',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_20.GeneratorPlaceholderResolver();
      },
    },
    methods: {
      'resolve': (visitor, target, positional, named, typeArgs) {
        final t = D4
            .validateTarget<$tom_build_cli_20.GeneratorPlaceholderResolver>(
              target,
              'GeneratorPlaceholderResolver',
            );
        final content = D4.getRequiredNamedArg<dynamic>(
          named,
          'content',
          'resolve',
        );
        if (!named.containsKey('context') || named['context'] == null) {
          throw ArgumentError(
            'resolve: Missing required named argument "context"',
          );
        }
        final context = D4.coerceMap<String, dynamic>(
          named['context'],
          'context',
        );
        final throwOnUnresolved = D4.getNamedArgWithDefault<bool>(
          named,
          'throwOnUnresolved',
          true,
        );
        return t.resolve(
          content: content,
          context: context,
          throwOnUnresolved: throwOnUnresolved,
        );
      },
    },
    constructorSignatures: {'': 'GeneratorPlaceholderResolver()'},
    methodSignatures: {
      'resolve':
          'GeneratorResult resolve({required dynamic content, required Map<String, dynamic> context, bool throwOnUnresolved = true})',
    },
  );
}

// =============================================================================
// MasterGeneratorConfig Bridge
// =============================================================================

BridgedClass _createMasterGeneratorConfigBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_21.MasterGeneratorConfig,
    name: 'MasterGeneratorConfig',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'MasterGeneratorConfig',
        );
        final outputPath = D4.getOptionalNamedArg<String?>(named, 'outputPath');
        final resolvePlaceholders = D4.getNamedArgWithDefault<bool>(
          named,
          'resolvePlaceholders',
          true,
        );
        final processModeBlocks = D4.getNamedArgWithDefault<bool>(
          named,
          'processModeBlocks',
          true,
        );
        return $tom_build_cli_21.MasterGeneratorConfig(
          workspacePath: workspacePath,
          outputPath: outputPath,
          resolvePlaceholders: resolvePlaceholders,
          processModeBlocks: processModeBlocks,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGeneratorConfig>(
            target,
            'MasterGeneratorConfig',
          )
          .workspacePath,
      'outputPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGeneratorConfig>(
            target,
            'MasterGeneratorConfig',
          )
          .outputPath,
      'resolvePlaceholders': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGeneratorConfig>(
            target,
            'MasterGeneratorConfig',
          )
          .resolvePlaceholders,
      'processModeBlocks': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGeneratorConfig>(
            target,
            'MasterGeneratorConfig',
          )
          .processModeBlocks,
      'outputDir': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGeneratorConfig>(
            target,
            'MasterGeneratorConfig',
          )
          .outputDir,
    },
    constructorSignatures: {
      '': 'const MasterGeneratorConfig({required String workspacePath, String? outputPath, bool resolvePlaceholders = true, bool processModeBlocks = true})',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'outputPath': 'String? get outputPath',
      'resolvePlaceholders': 'bool get resolvePlaceholders',
      'processModeBlocks': 'bool get processModeBlocks',
      'outputDir': 'String get outputDir',
    },
  );
}

// =============================================================================
// MasterGenerationResult Bridge
// =============================================================================

BridgedClass _createMasterGenerationResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_21.MasterGenerationResult,
    name: 'MasterGenerationResult',
    constructors: {
      'success': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'MasterGenerationResult');
        if (positional.isEmpty) {
          throw ArgumentError(
            'MasterGenerationResult: Missing required argument "data" at position 0',
          );
        }
        final data = D4.coerceMap<String, dynamic>(positional[0], 'data');
        final outputPath = D4.getOptionalNamedArg<String?>(named, 'outputPath');
        return $tom_build_cli_21.MasterGenerationResult.success(
          data,
          outputPath: outputPath,
        );
      },
      'error': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'MasterGenerationResult');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'MasterGenerationResult',
        );
        return $tom_build_cli_21.MasterGenerationResult.error(message);
      },
    },
    getters: {
      'data': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGenerationResult>(
            target,
            'MasterGenerationResult',
          )
          .data,
      'outputPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGenerationResult>(
            target,
            'MasterGenerationResult',
          )
          .outputPath,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGenerationResult>(
            target,
            'MasterGenerationResult',
          )
          .success,
      'error': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGenerationResult>(
            target,
            'MasterGenerationResult',
          )
          .error,
    },
    constructorSignatures: {
      'success':
          'factory MasterGenerationResult.success(Map<String, dynamic> data, {String? outputPath})',
      'error': 'factory MasterGenerationResult.error(String message)',
    },
    getterSignatures: {
      'data': 'Map<String, dynamic> get data',
      'outputPath': 'String? get outputPath',
      'success': 'bool get success',
      'error': 'String? get error',
    },
  );
}

// =============================================================================
// MasterGenerator Bridge
// =============================================================================

BridgedClass _createMasterGeneratorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_21.MasterGenerator,
    name: 'MasterGenerator',
    constructors: {
      '': (visitor, positional, named) {
        final workspace = D4.getRequiredNamedArg<$tom_build_1.TomWorkspace>(
          named,
          'workspace',
          'MasterGenerator',
        );
        if (!named.containsKey('projects') || named['projects'] == null) {
          throw ArgumentError(
            'MasterGenerator: Missing required named argument "projects"',
          );
        }
        final projects = D4.coerceMap<String, $tom_build_1.TomProject>(
          named['projects'],
          'projects',
        );
        final config = D4
            .getRequiredNamedArg<$tom_build_cli_21.MasterGeneratorConfig>(
              named,
              'config',
              'MasterGenerator',
            );
        return $tom_build_cli_21.MasterGenerator(
          workspace: workspace,
          projects: projects,
          config: config,
        );
      },
    },
    getters: {
      'workspace': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGenerator>(
            target,
            'MasterGenerator',
          )
          .workspace,
      'projects': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGenerator>(
            target,
            'MasterGenerator',
          )
          .projects,
      'config': (visitor, target) => D4
          .validateTarget<$tom_build_cli_21.MasterGenerator>(
            target,
            'MasterGenerator',
          )
          .config,
    },
    methods: {
      'generateMaster': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_21.MasterGenerator>(
          target,
          'MasterGenerator',
        );
        return t.generateMaster();
      },
      'generateActionMaster': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_21.MasterGenerator>(
          target,
          'MasterGenerator',
        );
        D4.requireMinArgs(positional, 1, 'generateActionMaster');
        final action = D4.getRequiredArg<String>(
          positional,
          0,
          'action',
          'generateActionMaster',
        );
        return t.generateActionMaster(action);
      },
      'generateAndWriteMaster': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_21.MasterGenerator>(
          target,
          'MasterGenerator',
        );
        return t.generateAndWriteMaster();
      },
      'generateAndWriteActionMaster':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_21.MasterGenerator>(
              target,
              'MasterGenerator',
            );
            D4.requireMinArgs(positional, 1, 'generateAndWriteActionMaster');
            final action = D4.getRequiredArg<String>(
              positional,
              0,
              'action',
              'generateAndWriteActionMaster',
            );
            return t.generateAndWriteActionMaster(action);
          },
      'generateAndWriteAllActionMasters':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_21.MasterGenerator>(
              target,
              'MasterGenerator',
            );
            return t.generateAndWriteAllActionMasters();
          },
    },
    constructorSignatures: {
      '': 'MasterGenerator({required TomWorkspace workspace, required Map<String, TomProject> projects, required MasterGeneratorConfig config})',
    },
    methodSignatures: {
      'generateMaster': 'TomMaster generateMaster()',
      'generateActionMaster': 'TomMaster generateActionMaster(String action)',
      'generateAndWriteMaster':
          'MasterGenerationResult generateAndWriteMaster()',
      'generateAndWriteActionMaster':
          'MasterGenerationResult generateAndWriteActionMaster(String action)',
      'generateAndWriteAllActionMasters':
          'List<MasterGenerationResult> generateAndWriteAllActionMasters()',
    },
    getterSignatures: {
      'workspace': 'TomWorkspace get workspace',
      'projects': 'Map<String, TomProject> get projects',
      'config': 'MasterGeneratorConfig get config',
    },
  );
}

// =============================================================================
// PlaceholderResult Bridge
// =============================================================================

BridgedClass _createPlaceholderResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_22.PlaceholderResult,
    name: 'PlaceholderResult',
    constructors: {
      '': (visitor, positional, named) {
        final value = D4.getRequiredNamedArg<dynamic>(
          named,
          'value',
          'PlaceholderResult',
        );
        final fullyResolved = D4.getRequiredNamedArg<bool>(
          named,
          'fullyResolved',
          'PlaceholderResult',
        );
        final unresolvedPlaceholders =
            named.containsKey('unresolvedPlaceholders') &&
                named['unresolvedPlaceholders'] != null
            ? D4.coerceList<String>(
                named['unresolvedPlaceholders'],
                'unresolvedPlaceholders',
              )
            : const <String>[];
        final iterations = D4.getNamedArgWithDefault<int>(
          named,
          'iterations',
          0,
        );
        return $tom_build_cli_22.PlaceholderResult(
          value: value,
          fullyResolved: fullyResolved,
          unresolvedPlaceholders: unresolvedPlaceholders,
          iterations: iterations,
        );
      },
    },
    getters: {
      'value': (visitor, target) => D4
          .validateTarget<$tom_build_cli_22.PlaceholderResult>(
            target,
            'PlaceholderResult',
          )
          .value,
      'fullyResolved': (visitor, target) => D4
          .validateTarget<$tom_build_cli_22.PlaceholderResult>(
            target,
            'PlaceholderResult',
          )
          .fullyResolved,
      'unresolvedPlaceholders': (visitor, target) => D4
          .validateTarget<$tom_build_cli_22.PlaceholderResult>(
            target,
            'PlaceholderResult',
          )
          .unresolvedPlaceholders,
      'iterations': (visitor, target) => D4
          .validateTarget<$tom_build_cli_22.PlaceholderResult>(
            target,
            'PlaceholderResult',
          )
          .iterations,
    },
    constructorSignatures: {
      '': 'const PlaceholderResult({required dynamic value, required bool fullyResolved, List<String> unresolvedPlaceholders = const [], int iterations = 0})',
    },
    getterSignatures: {
      'value': 'dynamic get value',
      'fullyResolved': 'bool get fullyResolved',
      'unresolvedPlaceholders': 'List<String> get unresolvedPlaceholders',
      'iterations': 'int get iterations',
    },
  );
}

// =============================================================================
// GeneratorPlaceholderException Bridge
// =============================================================================

BridgedClass _createGeneratorPlaceholderExceptionBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_22.GeneratorPlaceholderException,
    name: 'GeneratorPlaceholderException',
    constructors: {
      '': (visitor, positional, named) {
        final message = D4.getRequiredNamedArg<String>(
          named,
          'message',
          'GeneratorPlaceholderException',
        );
        if (!named.containsKey('unresolvedPlaceholders') ||
            named['unresolvedPlaceholders'] == null) {
          throw ArgumentError(
            'GeneratorPlaceholderException: Missing required named argument "unresolvedPlaceholders"',
          );
        }
        final unresolvedPlaceholders = D4.coerceList<String>(
          named['unresolvedPlaceholders'],
          'unresolvedPlaceholders',
        );
        final iterations = D4.getRequiredNamedArg<int>(
          named,
          'iterations',
          'GeneratorPlaceholderException',
        );
        return $tom_build_cli_22.GeneratorPlaceholderException(
          message: message,
          unresolvedPlaceholders: unresolvedPlaceholders,
          iterations: iterations,
        );
      },
    },
    getters: {
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_22.GeneratorPlaceholderException>(
            target,
            'GeneratorPlaceholderException',
          )
          .message,
      'unresolvedPlaceholders': (visitor, target) => D4
          .validateTarget<$tom_build_cli_22.GeneratorPlaceholderException>(
            target,
            'GeneratorPlaceholderException',
          )
          .unresolvedPlaceholders,
      'iterations': (visitor, target) => D4
          .validateTarget<$tom_build_cli_22.GeneratorPlaceholderException>(
            target,
            'GeneratorPlaceholderException',
          )
          .iterations,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4
            .validateTarget<$tom_build_cli_22.GeneratorPlaceholderException>(
              target,
              'GeneratorPlaceholderException',
            );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const GeneratorPlaceholderException({required String message, required List<String> unresolvedPlaceholders, required int iterations})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'message': 'String get message',
      'unresolvedPlaceholders': 'List<String> get unresolvedPlaceholders',
      'iterations': 'int get iterations',
    },
  );
}

// =============================================================================
// PlaceholderResolver Bridge
// =============================================================================

BridgedClass _createPlaceholderResolverBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_22.PlaceholderResolver,
    name: 'PlaceholderResolver',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_22.PlaceholderResolver();
      },
    },
    methods: {
      'resolve': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_22.PlaceholderResolver>(
          target,
          'PlaceholderResolver',
        );
        final content = D4.getRequiredNamedArg<dynamic>(
          named,
          'content',
          'resolve',
        );
        if (!named.containsKey('context') || named['context'] == null) {
          throw ArgumentError(
            'resolve: Missing required named argument "context"',
          );
        }
        final context = D4.coerceMap<String, dynamic>(
          named['context'],
          'context',
        );
        final throwOnUnresolved = D4.getNamedArgWithDefault<bool>(
          named,
          'throwOnUnresolved',
          true,
        );
        return t.resolve(
          content: content,
          context: context,
          throwOnUnresolved: throwOnUnresolved,
        );
      },
    },
    staticGetters: {
      'maxIterations': (visitor) =>
          $tom_build_cli_22.PlaceholderResolver.maxIterations,
    },
    constructorSignatures: {'': 'PlaceholderResolver()'},
    methodSignatures: {
      'resolve':
          'PlaceholderResult resolve({required dynamic content, required Map<String, dynamic> context, bool throwOnUnresolved = true})',
    },
    staticGetterSignatures: {'maxIterations': 'int get maxIterations'},
  );
}

// =============================================================================
// ModeProcessor Bridge
// =============================================================================

BridgedClass _createModeProcessorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_23.ModeProcessor,
    name: 'ModeProcessor',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_23.ModeProcessor();
      },
    },
    methods: {
      'processContent': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_23.ModeProcessor>(
          target,
          'ModeProcessor',
        );
        D4.requireMinArgs(positional, 2, 'processContent');
        final content = D4.getRequiredArg<String>(
          positional,
          0,
          'content',
          'processContent',
        );
        final activeModes = D4.getRequiredArg<Set<String>>(
          positional,
          1,
          'activeModes',
          'processContent',
        );
        final modeTypeValues =
            named.containsKey('modeTypeValues') &&
                named['modeTypeValues'] != null
            ? D4.coerceMap<String, String>(
                named['modeTypeValues'],
                'modeTypeValues',
              )
            : const <String, String>{};
        return t.processContent(
          content,
          activeModes,
          modeTypeValues: modeTypeValues,
        );
      },
    },
    constructorSignatures: {'': 'ModeProcessor()'},
    methodSignatures: {
      'processContent':
          'String processContent(String content, Set<String> activeModes, {Map<String, String> modeTypeValues = const {}})',
    },
  );
}

// =============================================================================
// ModeResolver Bridge
// =============================================================================

BridgedClass _createModeResolverBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_24.ModeResolver,
    name: 'ModeResolver',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_24.ModeResolver();
      },
    },
    methods: {
      'resolve': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_24.ModeResolver>(
          target,
          'ModeResolver',
        );
        final actionName = D4.getRequiredNamedArg<String>(
          named,
          'actionName',
          'resolve',
        );
        final workspaceModes = D4
            .getOptionalNamedArg<$tom_build_1.WorkspaceModes?>(
              named,
              'workspaceModes',
            );
        final modeDefinitions = D4
            .coerceMapOrNull<String, $tom_build_1.ModeDefinitions>(
              named['modeDefinitions'],
              'modeDefinitions',
            );
        final cliOverrides =
            named.containsKey('cliOverrides') && named['cliOverrides'] != null
            ? D4.coerceMap<String, String>(
                named['cliOverrides'],
                'cliOverrides',
              )
            : const <String, String>{};
        return t.resolve(
          actionName: actionName,
          workspaceModes: workspaceModes,
          modeDefinitions: modeDefinitions,
          cliOverrides: cliOverrides,
        );
      },
      'resolveModeProperties': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_24.ModeResolver>(
          target,
          'ModeResolver',
        );
        final resolved = D4
            .getRequiredNamedArg<$tom_build_cli_24.ResolvedModes>(
              named,
              'resolved',
              'resolveModeProperties',
            );
        if (!named.containsKey('modeDefinitions') ||
            named['modeDefinitions'] == null) {
          throw ArgumentError(
            'resolveModeProperties: Missing required named argument "modeDefinitions"',
          );
        }
        final modeDefinitions = D4
            .coerceMapOrNull<String, $tom_build_1.ModeDefinitions>(
              named['modeDefinitions'],
              'modeDefinitions',
            );
        return t.resolveModeProperties(
          resolved: resolved,
          modeDefinitions: modeDefinitions,
        );
      },
      'getDefaultMode': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_24.ModeResolver>(
          target,
          'ModeResolver',
        );
        D4.requireMinArgs(positional, 2, 'getDefaultMode');
        final modeType = D4.getRequiredArg<String>(
          positional,
          0,
          'modeType',
          'getDefaultMode',
        );
        final workspaceModes = D4.getRequiredArg<$tom_build_1.WorkspaceModes?>(
          positional,
          1,
          'workspaceModes',
          'getDefaultMode',
        );
        return t.getDefaultMode(modeType, workspaceModes);
      },
    },
    constructorSignatures: {'': 'ModeResolver()'},
    methodSignatures: {
      'resolve':
          'ResolvedModes resolve({required String actionName, WorkspaceModes? workspaceModes, Map<String, ModeDefinitions>? modeDefinitions, Map<String, String> cliOverrides = const {}})',
      'resolveModeProperties':
          'Map<String, dynamic> resolveModeProperties({required ResolvedModes resolved, required Map<String, ModeDefinitions>? modeDefinitions})',
      'getDefaultMode':
          'String? getDefaultMode(String modeType, WorkspaceModes? workspaceModes)',
    },
  );
}

// =============================================================================
// ResolvedModes Bridge
// =============================================================================

BridgedClass _createResolvedModesBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_24.ResolvedModes,
    name: 'ResolvedModes',
    constructors: {
      '': (visitor, positional, named) {
        final activeModes = D4.getRequiredNamedArg<Set<String>>(
          named,
          'activeModes',
          'ResolvedModes',
        );
        if (!named.containsKey('modeTypeValues') ||
            named['modeTypeValues'] == null) {
          throw ArgumentError(
            'ResolvedModes: Missing required named argument "modeTypeValues"',
          );
        }
        final modeTypeValues = D4.coerceMap<String, String>(
          named['modeTypeValues'],
          'modeTypeValues',
        );
        final impliedModes = D4.getRequiredNamedArg<Set<String>>(
          named,
          'impliedModes',
          'ResolvedModes',
        );
        return $tom_build_cli_24.ResolvedModes(
          activeModes: activeModes,
          modeTypeValues: modeTypeValues,
          impliedModes: impliedModes,
        );
      },
    },
    getters: {
      'activeModes': (visitor, target) => D4
          .validateTarget<$tom_build_cli_24.ResolvedModes>(
            target,
            'ResolvedModes',
          )
          .activeModes,
      'modeTypeValues': (visitor, target) => D4
          .validateTarget<$tom_build_cli_24.ResolvedModes>(
            target,
            'ResolvedModes',
          )
          .modeTypeValues,
      'impliedModes': (visitor, target) => D4
          .validateTarget<$tom_build_cli_24.ResolvedModes>(
            target,
            'ResolvedModes',
          )
          .impliedModes,
    },
    methods: {
      'isActive': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_24.ResolvedModes>(
          target,
          'ResolvedModes',
        );
        D4.requireMinArgs(positional, 1, 'isActive');
        final mode = D4.getRequiredArg<String>(
          positional,
          0,
          'mode',
          'isActive',
        );
        return t.isActive(mode);
      },
      'getModeValue': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_24.ResolvedModes>(
          target,
          'ResolvedModes',
        );
        D4.requireMinArgs(positional, 1, 'getModeValue');
        final modeType = D4.getRequiredArg<String>(
          positional,
          0,
          'modeType',
          'getModeValue',
        );
        return t.getModeValue(modeType);
      },
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_24.ResolvedModes>(
          target,
          'ResolvedModes',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const ResolvedModes({required Set<String> activeModes, required Map<String, String> modeTypeValues, required Set<String> impliedModes})',
    },
    methodSignatures: {
      'isActive': 'bool isActive(String mode)',
      'getModeValue': 'String? getModeValue(String modeType)',
      'toString': 'String toString()',
    },
    getterSignatures: {
      'activeModes': 'Set<String> get activeModes',
      'modeTypeValues': 'Map<String, String> get modeTypeValues',
      'impliedModes': 'Set<String> get impliedModes',
    },
  );
}

// =============================================================================
// TomplateParser Bridge
// =============================================================================

BridgedClass _createTomplateParserBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_25.TomplateParser,
    name: 'TomplateParser',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_25.TomplateParser();
      },
    },
    methods: {
      'findTemplates': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_25.TomplateParser>(
          target,
          'TomplateParser',
        );
        D4.requireMinArgs(positional, 1, 'findTemplates');
        final directory = D4.getRequiredArg<String>(
          positional,
          0,
          'directory',
          'findTemplates',
        );
        return t.findTemplates(directory);
      },
      'parseFile': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_25.TomplateParser>(
          target,
          'TomplateParser',
        );
        D4.requireMinArgs(positional, 1, 'parseFile');
        final filePath = D4.getRequiredArg<String>(
          positional,
          0,
          'filePath',
          'parseFile',
        );
        return t.parseFile(filePath);
      },
      'parseContent': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_25.TomplateParser>(
          target,
          'TomplateParser',
        );
        D4.requireMinArgs(positional, 2, 'parseContent');
        final content = D4.getRequiredArg<String>(
          positional,
          0,
          'content',
          'parseContent',
        );
        final sourcePath = D4.getRequiredArg<String>(
          positional,
          1,
          'sourcePath',
          'parseContent',
        );
        return t.parseContent(content, sourcePath);
      },
    },
    constructorSignatures: {'': 'TomplateParser()'},
    methodSignatures: {
      'findTemplates': 'List<TomplateFile> findTemplates(String directory)',
      'parseFile': 'TomplateFile parseFile(String filePath)',
      'parseContent':
          'TomplateFile parseContent(String content, String sourcePath)',
    },
  );
}

// =============================================================================
// TomplateFile Bridge
// =============================================================================

BridgedClass _createTomplateFileBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_25.TomplateFile,
    name: 'TomplateFile',
    constructors: {
      '': (visitor, positional, named) {
        final sourcePath = D4.getRequiredNamedArg<String>(
          named,
          'sourcePath',
          'TomplateFile',
        );
        final targetPath = D4.getRequiredNamedArg<String>(
          named,
          'targetPath',
          'TomplateFile',
        );
        final content = D4.getRequiredNamedArg<String>(
          named,
          'content',
          'TomplateFile',
        );
        if (!named.containsKey('placeholders') ||
            named['placeholders'] == null) {
          throw ArgumentError(
            'TomplateFile: Missing required named argument "placeholders"',
          );
        }
        final placeholders = D4.coerceList<$tom_build_cli_25.PlaceholderInfo>(
          named['placeholders'],
          'placeholders',
        );
        final hasModeBlocks = D4.getRequiredNamedArg<bool>(
          named,
          'hasModeBlocks',
          'TomplateFile',
        );
        return $tom_build_cli_25.TomplateFile(
          sourcePath: sourcePath,
          targetPath: targetPath,
          content: content,
          placeholders: placeholders,
          hasModeBlocks: hasModeBlocks,
        );
      },
    },
    getters: {
      'sourcePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.TomplateFile>(
            target,
            'TomplateFile',
          )
          .sourcePath,
      'targetPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.TomplateFile>(
            target,
            'TomplateFile',
          )
          .targetPath,
      'content': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.TomplateFile>(
            target,
            'TomplateFile',
          )
          .content,
      'placeholders': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.TomplateFile>(
            target,
            'TomplateFile',
          )
          .placeholders,
      'hasModeBlocks': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.TomplateFile>(
            target,
            'TomplateFile',
          )
          .hasModeBlocks,
      'hasPlaceholders': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.TomplateFile>(
            target,
            'TomplateFile',
          )
          .hasPlaceholders,
    },
    methods: {
      'getPlaceholdersOfType': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_25.TomplateFile>(
          target,
          'TomplateFile',
        );
        D4.requireMinArgs(positional, 1, 'getPlaceholdersOfType');
        final type = D4.getRequiredArg<$tom_build_cli_25.PlaceholderType>(
          positional,
          0,
          'type',
          'getPlaceholdersOfType',
        );
        return t.getPlaceholdersOfType(type);
      },
    },
    constructorSignatures: {
      '': 'const TomplateFile({required String sourcePath, required String targetPath, required String content, required List<PlaceholderInfo> placeholders, required bool hasModeBlocks})',
    },
    methodSignatures: {
      'getPlaceholdersOfType':
          'List<PlaceholderInfo> getPlaceholdersOfType(PlaceholderType type)',
    },
    getterSignatures: {
      'sourcePath': 'String get sourcePath',
      'targetPath': 'String get targetPath',
      'content': 'String get content',
      'placeholders': 'List<PlaceholderInfo> get placeholders',
      'hasModeBlocks': 'bool get hasModeBlocks',
      'hasPlaceholders': 'bool get hasPlaceholders',
    },
  );
}

// =============================================================================
// PlaceholderInfo Bridge
// =============================================================================

BridgedClass _createPlaceholderInfoBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_25.PlaceholderInfo,
    name: 'PlaceholderInfo',
    constructors: {
      '': (visitor, positional, named) {
        final type = D4.getRequiredNamedArg<$tom_build_cli_25.PlaceholderType>(
          named,
          'type',
          'PlaceholderInfo',
        );
        final fullMatch = D4.getRequiredNamedArg<String>(
          named,
          'fullMatch',
          'PlaceholderInfo',
        );
        final key = D4.getRequiredNamedArg<String>(
          named,
          'key',
          'PlaceholderInfo',
        );
        final defaultValue = D4.getOptionalNamedArg<String?>(
          named,
          'defaultValue',
        );
        final offset = D4.getRequiredNamedArg<int>(
          named,
          'offset',
          'PlaceholderInfo',
        );
        return $tom_build_cli_25.PlaceholderInfo(
          type: type,
          fullMatch: fullMatch,
          key: key,
          defaultValue: defaultValue,
          offset: offset,
        );
      },
    },
    getters: {
      'type': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.PlaceholderInfo>(
            target,
            'PlaceholderInfo',
          )
          .type,
      'fullMatch': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.PlaceholderInfo>(
            target,
            'PlaceholderInfo',
          )
          .fullMatch,
      'key': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.PlaceholderInfo>(
            target,
            'PlaceholderInfo',
          )
          .key,
      'defaultValue': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.PlaceholderInfo>(
            target,
            'PlaceholderInfo',
          )
          .defaultValue,
      'offset': (visitor, target) => D4
          .validateTarget<$tom_build_cli_25.PlaceholderInfo>(
            target,
            'PlaceholderInfo',
          )
          .offset,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_25.PlaceholderInfo>(
          target,
          'PlaceholderInfo',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const PlaceholderInfo({required PlaceholderType type, required String fullMatch, required String key, String? defaultValue, required int offset})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'type': 'PlaceholderType get type',
      'fullMatch': 'String get fullMatch',
      'key': 'String get key',
      'defaultValue': 'String? get defaultValue',
      'offset': 'int get offset',
    },
  );
}

// =============================================================================
// TomplateProcessor Bridge
// =============================================================================

BridgedClass _createTomplateProcessorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_26.TomplateProcessor,
    name: 'TomplateProcessor',
    constructors: {
      '': (visitor, positional, named) {
        final modeProcessor = D4
            .getOptionalNamedArg<$tom_build_cli_23.ModeProcessor?>(
              named,
              'modeProcessor',
            );
        return $tom_build_cli_26.TomplateProcessor(
          modeProcessor: modeProcessor,
        );
      },
    },
    methods: {
      'process': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_26.TomplateProcessor>(
          target,
          'TomplateProcessor',
        );
        final template = D4.getRequiredNamedArg<$tom_build_cli_25.TomplateFile>(
          named,
          'template',
          'process',
        );
        final resolvedModes = D4
            .getOptionalNamedArg<$tom_build_cli_24.ResolvedModes?>(
              named,
              'resolvedModes',
            );
        final context = D4.coerceMapOrNull<String, dynamic>(
          named['context'],
          'context',
        );
        final resolveEnvironment = D4.getNamedArgWithDefault<bool>(
          named,
          'resolveEnvironment',
          false,
        );
        final environment = D4.coerceMapOrNull<String, String>(
          named['environment'],
          'environment',
        );
        final resolveGenerators = D4.getNamedArgWithDefault<bool>(
          named,
          'resolveGenerators',
          true,
        );
        return t.process(
          template: template,
          resolvedModes: resolvedModes,
          context: context,
          resolveEnvironment: resolveEnvironment,
          environment: environment,
          resolveGenerators: resolveGenerators,
        );
      },
      'writeToFile': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_26.TomplateProcessor>(
          target,
          'TomplateProcessor',
        );
        D4.requireMinArgs(positional, 1, 'writeToFile');
        final processed = D4.getRequiredArg<$tom_build_cli_26.TomplateResult>(
          positional,
          0,
          'processed',
          'writeToFile',
        );
        t.writeToFile(processed);
        return null;
      },
      'processAndWrite': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_26.TomplateProcessor>(
          target,
          'TomplateProcessor',
        );
        final template = D4.getRequiredNamedArg<$tom_build_cli_25.TomplateFile>(
          named,
          'template',
          'processAndWrite',
        );
        final resolvedModes = D4
            .getOptionalNamedArg<$tom_build_cli_24.ResolvedModes?>(
              named,
              'resolvedModes',
            );
        final context = D4.coerceMapOrNull<String, dynamic>(
          named['context'],
          'context',
        );
        final resolveEnvironment = D4.getNamedArgWithDefault<bool>(
          named,
          'resolveEnvironment',
          false,
        );
        final environment = D4.coerceMapOrNull<String, String>(
          named['environment'],
          'environment',
        );
        t.processAndWrite(
          template: template,
          resolvedModes: resolvedModes,
          context: context,
          resolveEnvironment: resolveEnvironment,
          environment: environment,
        );
        return null;
      },
    },
    constructorSignatures: {
      '': 'TomplateProcessor({ModeProcessor? modeProcessor})',
    },
    methodSignatures: {
      'process':
          'TomplateResult process({required TomplateFile template, ResolvedModes? resolvedModes, Map<String, dynamic>? context, bool resolveEnvironment = false, Map<String, String>? environment, bool resolveGenerators = true})',
      'writeToFile': 'void writeToFile(TomplateResult processed)',
      'processAndWrite':
          'void processAndWrite({required TomplateFile template, ResolvedModes? resolvedModes, Map<String, dynamic>? context, bool resolveEnvironment = false, Map<String, String>? environment})',
    },
  );
}

// =============================================================================
// TomplateResult Bridge
// =============================================================================

BridgedClass _createTomplateResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_26.TomplateResult,
    name: 'TomplateResult',
    constructors: {
      '': (visitor, positional, named) {
        final sourcePath = D4.getRequiredNamedArg<String>(
          named,
          'sourcePath',
          'TomplateResult',
        );
        final targetPath = D4.getRequiredNamedArg<String>(
          named,
          'targetPath',
          'TomplateResult',
        );
        final content = D4.getRequiredNamedArg<String>(
          named,
          'content',
          'TomplateResult',
        );
        return $tom_build_cli_26.TomplateResult(
          sourcePath: sourcePath,
          targetPath: targetPath,
          content: content,
        );
      },
    },
    getters: {
      'sourcePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_26.TomplateResult>(
            target,
            'TomplateResult',
          )
          .sourcePath,
      'targetPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_26.TomplateResult>(
            target,
            'TomplateResult',
          )
          .targetPath,
      'content': (visitor, target) => D4
          .validateTarget<$tom_build_cli_26.TomplateResult>(
            target,
            'TomplateResult',
          )
          .content,
    },
    constructorSignatures: {
      '': 'const TomplateResult({required String sourcePath, required String targetPath, required String content})',
    },
    getterSignatures: {
      'sourcePath': 'String get sourcePath',
      'targetPath': 'String get targetPath',
      'content': 'String get content',
    },
  );
}

// =============================================================================
// PlaceholderResolutionException Bridge
// =============================================================================

BridgedClass _createPlaceholderResolutionExceptionBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_26.PlaceholderResolutionException,
    name: 'PlaceholderResolutionException',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'PlaceholderResolutionException');
        final message = D4.getRequiredArg<String>(
          positional,
          0,
          'message',
          'PlaceholderResolutionException',
        );
        final unresolved = D4.getOptionalNamedArg<String?>(named, 'unresolved');
        return $tom_build_cli_26.PlaceholderResolutionException(
          message,
          unresolved: unresolved,
        );
      },
    },
    getters: {
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_26.PlaceholderResolutionException>(
            target,
            'PlaceholderResolutionException',
          )
          .message,
      'unresolved': (visitor, target) => D4
          .validateTarget<$tom_build_cli_26.PlaceholderResolutionException>(
            target,
            'PlaceholderResolutionException',
          )
          .unresolved,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4
            .validateTarget<$tom_build_cli_26.PlaceholderResolutionException>(
              target,
              'PlaceholderResolutionException',
            );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const PlaceholderResolutionException(String message, {String? unresolved})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'message': 'String get message',
      'unresolved': 'String? get unresolved',
    },
  );
}

// =============================================================================
// ToolPrefix Bridge
// =============================================================================

BridgedClass _createToolPrefixBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_30.ToolPrefix,
    name: 'ToolPrefix',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_30.ToolPrefix();
      },
    },
    staticGetters: {
      'wsPrepper': (visitor) => $tom_build_cli_30.ToolPrefix.wsPrepper,
      'workspaceAnalyzer': (visitor) =>
          $tom_build_cli_30.ToolPrefix.workspaceAnalyzer,
      'reflectionGenerator': (visitor) =>
          $tom_build_cli_30.ToolPrefix.reflectionGenerator,
    },
    constructorSignatures: {'': 'ToolPrefix()'},
    staticGetterSignatures: {
      'wsPrepper': 'dynamic get wsPrepper',
      'workspaceAnalyzer': 'dynamic get workspaceAnalyzer',
      'reflectionGenerator': 'dynamic get reflectionGenerator',
    },
  );
}

// =============================================================================
// CliArgs Bridge
// =============================================================================

BridgedClass _createCliArgsBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_30.CliArgs,
    name: 'CliArgs',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'CliArgs');
        final prefix = D4.getRequiredArg<String>(
          positional,
          0,
          'prefix',
          'CliArgs',
        );
        if (positional.length <= 1) {
          throw ArgumentError(
            'CliArgs: Missing required argument "arguments" at position 1',
          );
        }
        final arguments = D4.coerceList<String>(positional[1], 'arguments');
        return $tom_build_cli_30.CliArgs(prefix, arguments);
      },
    },
    getters: {
      'prefix': (visitor, target) => D4
          .validateTarget<$tom_build_cli_30.CliArgs>(target, 'CliArgs')
          .prefix,
      'rawArgs': (visitor, target) => D4
          .validateTarget<$tom_build_cli_30.CliArgs>(target, 'CliArgs')
          .rawArgs,
      'positionalArgs': (visitor, target) => D4
          .validateTarget<$tom_build_cli_30.CliArgs>(target, 'CliArgs')
          .positionalArgs,
      'namedParams': (visitor, target) => D4
          .validateTarget<$tom_build_cli_30.CliArgs>(target, 'CliArgs')
          .namedParams,
      'flags': (visitor, target) =>
          D4.validateTarget<$tom_build_cli_30.CliArgs>(target, 'CliArgs').flags,
      'help': (visitor, target) =>
          D4.validateTarget<$tom_build_cli_30.CliArgs>(target, 'CliArgs').help,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_30.CliArgs>(target, 'CliArgs')
          .dryRun,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_30.CliArgs>(target, 'CliArgs')
          .verbose,
    },
    methods: {
      'get': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_30.CliArgs>(
          target,
          'CliArgs',
        );
        D4.requireMinArgs(positional, 1, 'get');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'get');
        final defaultValue = D4.getOptionalArgWithDefault<String>(
          positional,
          1,
          'defaultValue',
          '',
        );
        return t.get(key, defaultValue);
      },
      'getInt': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_30.CliArgs>(
          target,
          'CliArgs',
        );
        D4.requireMinArgs(positional, 1, 'getInt');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'getInt');
        return t.getInt(key);
      },
      'getBool': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_30.CliArgs>(
          target,
          'CliArgs',
        );
        D4.requireMinArgs(positional, 1, 'getBool');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'getBool');
        final defaultValue = D4.getOptionalArgWithDefault<bool>(
          positional,
          1,
          'defaultValue',
          false,
        );
        return t.getBool(key, defaultValue);
      },
      'hasFlag': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_30.CliArgs>(
          target,
          'CliArgs',
        );
        D4.requireMinArgs(positional, 1, 'hasFlag');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'hasFlag');
        return t.hasFlag(key);
      },
      'has': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_30.CliArgs>(
          target,
          'CliArgs',
        );
        D4.requireMinArgs(positional, 1, 'has');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'has');
        return t.has(key);
      },
      'resolvePath': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_30.CliArgs>(
          target,
          'CliArgs',
        );
        D4.requireMinArgs(positional, 1, 'resolvePath');
        final pathArg = D4.getRequiredArg<String>(
          positional,
          0,
          'pathArg',
          'resolvePath',
        );
        return t.resolvePath(pathArg);
      },
      'getWorkspacePath': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_30.CliArgs>(
          target,
          'CliArgs',
        );
        final positionalIndex = D4.getNamedArgWithDefault<int>(
          named,
          'positionalIndex',
          0,
        );
        return t.getWorkspacePath(positionalIndex: positionalIndex);
      },
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_30.CliArgs>(
          target,
          'CliArgs',
        );
        return t.toString();
      },
      '[]': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_30.CliArgs>(
          target,
          'CliArgs',
        );
        final index = D4.getRequiredArg<String>(
          positional,
          0,
          'index',
          'operator[]',
        );
        return t[index];
      },
    },
    constructorSignatures: {
      '': 'CliArgs(String prefix, List<String> arguments)',
    },
    methodSignatures: {
      'get': 'String get(String key, [String defaultValue = \'\'])',
      'getInt': 'int? getInt(String key)',
      'getBool': 'bool getBool(String key, [bool defaultValue = false])',
      'hasFlag': 'bool hasFlag(String key)',
      'has': 'bool has(String key)',
      'resolvePath': 'String resolvePath(String pathArg)',
      'getWorkspacePath': 'String getWorkspacePath({int positionalIndex = 0})',
      'toString': 'String toString()',
    },
    getterSignatures: {
      'prefix': 'String get prefix',
      'rawArgs': 'List<String> get rawArgs',
      'positionalArgs': 'List<String> get positionalArgs',
      'namedParams': 'Map<String, String> get namedParams',
      'flags': 'Set<String> get flags',
      'help': 'bool get help',
      'dryRun': 'bool get dryRun',
      'verbose': 'bool get verbose',
    },
  );
}

// =============================================================================
// PipelineDefinition Bridge
// =============================================================================

BridgedClass _createPipelineDefinitionBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_31.PipelineDefinition,
    name: 'PipelineDefinition',
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(
          named,
          'name',
          'PipelineDefinition',
        );
        if (!named.containsKey('commands') || named['commands'] == null) {
          throw ArgumentError(
            'PipelineDefinition: Missing required named argument "commands"',
          );
        }
        final commands = D4.coerceList<String>(named['commands'], 'commands');
        return $tom_build_cli_31.PipelineDefinition(
          name: name,
          commands: commands,
        );
      },
      'fromYaml': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'PipelineDefinition');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'PipelineDefinition',
        );
        final yaml = D4.getRequiredArg<dynamic>(
          positional,
          1,
          'yaml',
          'PipelineDefinition',
        );
        return $tom_build_cli_31.PipelineDefinition.fromYaml(name, yaml);
      },
    },
    getters: {
      'name': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineDefinition>(
            target,
            'PipelineDefinition',
          )
          .name,
      'commands': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineDefinition>(
            target,
            'PipelineDefinition',
          )
          .commands,
    },
    methods: {
      'parseCommands': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_31.PipelineDefinition>(
          target,
          'PipelineDefinition',
        );
        return t.parseCommands();
      },
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_31.PipelineDefinition>(
          target,
          'PipelineDefinition',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const PipelineDefinition({required String name, required List<String> commands})',
      'fromYaml':
          'factory PipelineDefinition.fromYaml(String name, dynamic yaml)',
    },
    methodSignatures: {
      'parseCommands': 'List<ParsedTomCommand> parseCommands()',
      'toString': 'String toString()',
    },
    getterSignatures: {
      'name': 'String get name',
      'commands': 'List<String> get commands',
    },
  );
}

// =============================================================================
// PipelineResult Bridge
// =============================================================================

BridgedClass _createPipelineResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_31.PipelineResult,
    name: 'PipelineResult',
    constructors: {
      '': (visitor, positional, named) {
        final pipeline = D4
            .getRequiredNamedArg<$tom_build_cli_31.PipelineDefinition>(
              named,
              'pipeline',
              'PipelineResult',
            );
        if (!named.containsKey('commandResults') ||
            named['commandResults'] == null) {
          throw ArgumentError(
            'PipelineResult: Missing required named argument "commandResults"',
          );
        }
        final commandResults = D4.coerceList<$tom_build_cli_34.TomRunResults>(
          named['commandResults'],
          'commandResults',
        );
        return $tom_build_cli_31.PipelineResult(
          pipeline: pipeline,
          commandResults: commandResults,
        );
      },
    },
    getters: {
      'pipeline': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineResult>(
            target,
            'PipelineResult',
          )
          .pipeline,
      'commandResults': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineResult>(
            target,
            'PipelineResult',
          )
          .commandResults,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineResult>(
            target,
            'PipelineResult',
          )
          .success,
      'totalDuration': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineResult>(
            target,
            'PipelineResult',
          )
          .totalDuration,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_31.PipelineResult>(
          target,
          'PipelineResult',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const PipelineResult({required PipelineDefinition pipeline, required List<TomRunResults> commandResults})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'pipeline': 'PipelineDefinition get pipeline',
      'commandResults': 'List<TomRunResults> get commandResults',
      'success': 'bool get success',
      'totalDuration': 'Duration get totalDuration',
    },
  );
}

// =============================================================================
// PipelineLoader Bridge
// =============================================================================

BridgedClass _createPipelineLoaderBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_31.PipelineLoader,
    name: 'PipelineLoader',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'PipelineLoader');
        final workspacePath = D4.getRequiredArg<String>(
          positional,
          0,
          'workspacePath',
          'PipelineLoader',
        );
        return $tom_build_cli_31.PipelineLoader(workspacePath);
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineLoader>(
            target,
            'PipelineLoader',
          )
          .workspacePath,
    },
    methods: {
      'loadPipelines': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_31.PipelineLoader>(
          target,
          'PipelineLoader',
        );
        return t.loadPipelines();
      },
      'getPipeline': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_31.PipelineLoader>(
          target,
          'PipelineLoader',
        );
        D4.requireMinArgs(positional, 1, 'getPipeline');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'getPipeline',
        );
        return t.getPipeline(name);
      },
      'listPipelineNames': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_31.PipelineLoader>(
          target,
          'PipelineLoader',
        );
        return t.listPipelineNames();
      },
    },
    constructorSignatures: {'': 'PipelineLoader(String workspacePath)'},
    methodSignatures: {
      'loadPipelines':
          'Future<Map<String, PipelineDefinition>> loadPipelines()',
      'getPipeline': 'Future<PipelineDefinition?> getPipeline(String name)',
      'listPipelineNames': 'Future<List<String>> listPipelineNames()',
    },
    getterSignatures: {'workspacePath': 'String get workspacePath'},
  );
}

// =============================================================================
// PipelineRunner Bridge
// =============================================================================

BridgedClass _createPipelineRunnerBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_31.PipelineRunner,
    name: 'PipelineRunner',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'PipelineRunner',
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        final output = D4.getOptionalNamedArg<StringSink?>(named, 'output');
        return $tom_build_cli_31.PipelineRunner(
          workspacePath: workspacePath,
          verbose: verbose,
          dryRun: dryRun,
          output: output,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineRunner>(
            target,
            'PipelineRunner',
          )
          .workspacePath,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineRunner>(
            target,
            'PipelineRunner',
          )
          .verbose,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineRunner>(
            target,
            'PipelineRunner',
          )
          .dryRun,
      'output': (visitor, target) => D4
          .validateTarget<$tom_build_cli_31.PipelineRunner>(
            target,
            'PipelineRunner',
          )
          .output,
    },
    methods: {
      'runPipeline': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_31.PipelineRunner>(
          target,
          'PipelineRunner',
        );
        D4.requireMinArgs(positional, 1, 'runPipeline');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'runPipeline',
        );
        return t.runPipeline(name);
      },
      'execute': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_31.PipelineRunner>(
          target,
          'PipelineRunner',
        );
        D4.requireMinArgs(positional, 1, 'execute');
        final pipeline = D4
            .getRequiredArg<$tom_build_cli_31.PipelineDefinition>(
              positional,
              0,
              'pipeline',
              'execute',
            );
        return t.execute(pipeline);
      },
    },
    constructorSignatures: {
      '': 'PipelineRunner({required String workspacePath, bool verbose = false, bool dryRun = false, StringSink? output})',
    },
    methodSignatures: {
      'runPipeline': 'Future<PipelineResult> runPipeline(String name)',
      'execute': 'Future<PipelineResult> execute(PipelineDefinition pipeline)',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'verbose': 'bool get verbose',
      'dryRun': 'bool get dryRun',
      'output': 'StringSink get output',
    },
  );
}

// =============================================================================
// PackageInfo Bridge
// =============================================================================

BridgedClass _createPackageInfoBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_32.PackageInfo,
    name: 'PackageInfo',
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(
          named,
          'name',
          'PackageInfo',
        );
        final version = D4.getOptionalNamedArg<String?>(named, 'version');
        final publishable = D4.getNamedArgWithDefault<bool>(
          named,
          'publishable',
          true,
        );
        final lastChangeCommit = D4.getOptionalNamedArg<String?>(
          named,
          'lastChangeCommit',
        );
        final metadata =
            named.containsKey('metadata') && named['metadata'] != null
            ? D4.coerceMap<String, dynamic>(named['metadata'], 'metadata')
            : const <String, dynamic>{};
        return $tom_build_cli_32.PackageInfo(
          name: name,
          version: version,
          publishable: publishable,
          lastChangeCommit: lastChangeCommit,
          metadata: metadata,
        );
      },
      'fromYaml': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'PackageInfo');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'PackageInfo',
        );
        final yaml = D4.getRequiredArg<$yaml_1.YamlMap>(
          positional,
          1,
          'yaml',
          'PackageInfo',
        );
        return $tom_build_cli_32.PackageInfo.fromYaml(name, yaml);
      },
    },
    getters: {
      'name': (visitor, target) => D4
          .validateTarget<$tom_build_cli_32.PackageInfo>(target, 'PackageInfo')
          .name,
      'version': (visitor, target) => D4
          .validateTarget<$tom_build_cli_32.PackageInfo>(target, 'PackageInfo')
          .version,
      'publishable': (visitor, target) => D4
          .validateTarget<$tom_build_cli_32.PackageInfo>(target, 'PackageInfo')
          .publishable,
      'lastChangeCommit': (visitor, target) => D4
          .validateTarget<$tom_build_cli_32.PackageInfo>(target, 'PackageInfo')
          .lastChangeCommit,
      'metadata': (visitor, target) => D4
          .validateTarget<$tom_build_cli_32.PackageInfo>(target, 'PackageInfo')
          .metadata,
    },
    methods: {
      'toMap': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_32.PackageInfo>(
          target,
          'PackageInfo',
        );
        return t.toMap();
      },
      '[]': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_32.PackageInfo>(
          target,
          'PackageInfo',
        );
        final index = D4.getRequiredArg<String>(
          positional,
          0,
          'index',
          'operator[]',
        );
        return t[index];
      },
    },
    constructorSignatures: {
      '': 'const PackageInfo({required String name, String? version, bool publishable = true, String? lastChangeCommit, Map<String, dynamic> metadata = const {}})',
      'fromYaml': 'factory PackageInfo.fromYaml(String name, YamlMap yaml)',
    },
    methodSignatures: {'toMap': 'Map<String, dynamic> toMap()'},
    getterSignatures: {
      'name': 'String get name',
      'version': 'String? get version',
      'publishable': 'bool get publishable',
      'lastChangeCommit': 'String? get lastChangeCommit',
      'metadata': 'Map<String, dynamic> get metadata',
    },
  );
}

// =============================================================================
// TomPlaceholderResolver Bridge
// =============================================================================

BridgedClass _createTomPlaceholderResolverBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_32.TomPlaceholderResolver,
    name: 'TomPlaceholderResolver',
    constructors: {
      '': (visitor, positional, named) {
        if (!named.containsKey('data') || named['data'] == null) {
          throw ArgumentError(
            'TomPlaceholderResolver: Missing required named argument "data"',
          );
        }
        final data = D4.coerceMap<String, dynamic>(named['data'], 'data');
        final environment = D4.coerceMapOrNull<String, String>(
          named['environment'],
          'environment',
        );
        final d4rt = D4.getOptionalNamedArg<$tom_build_cli_5.D4rtInstance?>(
          named,
          'd4rt',
        );
        return $tom_build_cli_32.TomPlaceholderResolver(
          data: data,
          environment: environment,
          d4rt: d4rt,
        );
      },
    },
    getters: {
      'data': (visitor, target) => D4
          .validateTarget<$tom_build_cli_32.TomPlaceholderResolver>(
            target,
            'TomPlaceholderResolver',
          )
          .data,
      'environment': (visitor, target) => D4
          .validateTarget<$tom_build_cli_32.TomPlaceholderResolver>(
            target,
            'TomPlaceholderResolver',
          )
          .environment,
      'd4rt': (visitor, target) => D4
          .validateTarget<$tom_build_cli_32.TomPlaceholderResolver>(
            target,
            'TomPlaceholderResolver',
          )
          .d4rt,
    },
    methods: {
      'resolve': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_32.TomPlaceholderResolver>(
          target,
          'TomPlaceholderResolver',
        );
        D4.requireMinArgs(positional, 1, 'resolve');
        final input = D4.getRequiredArg<String>(
          positional,
          0,
          'input',
          'resolve',
        );
        return t.resolve(input);
      },
    },
    constructorSignatures: {
      '': 'TomPlaceholderResolver({required Map<String, dynamic> data, Map<String, String>? environment, D4rtInstance? d4rt})',
    },
    methodSignatures: {'resolve': 'Future<String> resolve(String input)'},
    getterSignatures: {
      'data': 'Map<String, dynamic> get data',
      'environment': 'Map<String, String> get environment',
      'd4rt': 'D4rtInstance? get d4rt',
    },
  );
}

// =============================================================================
// ParsedCommand Bridge
// =============================================================================

BridgedClass _createParsedCommandBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_33.ParsedCommand,
    name: 'ParsedCommand',
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(
          named,
          'name',
          'ParsedCommand',
        );
        final params = named.containsKey('params') && named['params'] != null
            ? D4.coerceMap<String, String>(named['params'], 'params')
            : const <String, String>{};
        final flags = D4.getNamedArgWithDefault<Set<String>>(
          named,
          'flags',
          const {},
        );
        final positionalArgs =
            named.containsKey('positionalArgs') &&
                named['positionalArgs'] != null
            ? D4.coerceList<String>(named['positionalArgs'], 'positionalArgs')
            : const <String>[];
        return $tom_build_cli_33.ParsedCommand(
          name: name,
          params: params,
          flags: flags,
          positionalArgs: positionalArgs,
        );
      },
    },
    getters: {
      'name': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedCommand>(
            target,
            'ParsedCommand',
          )
          .name,
      'params': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedCommand>(
            target,
            'ParsedCommand',
          )
          .params,
      'flags': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedCommand>(
            target,
            'ParsedCommand',
          )
          .flags,
      'positionalArgs': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedCommand>(
            target,
            'ParsedCommand',
          )
          .positionalArgs,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedCommand>(
            target,
            'ParsedCommand',
          )
          .verbose,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedCommand>(
            target,
            'ParsedCommand',
          )
          .dryRun,
      'help': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedCommand>(
            target,
            'ParsedCommand',
          )
          .help,
    },
    methods: {
      'get': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_33.ParsedCommand>(
          target,
          'ParsedCommand',
        );
        D4.requireMinArgs(positional, 1, 'get');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'get');
        final defaultValue = D4.getOptionalArgWithDefault<String>(
          positional,
          1,
          'defaultValue',
          '',
        );
        return t.get(key, defaultValue);
      },
      'getInt': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_33.ParsedCommand>(
          target,
          'ParsedCommand',
        );
        D4.requireMinArgs(positional, 1, 'getInt');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'getInt');
        return t.getInt(key);
      },
      'getBool': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_33.ParsedCommand>(
          target,
          'ParsedCommand',
        );
        D4.requireMinArgs(positional, 1, 'getBool');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'getBool');
        final defaultValue = D4.getOptionalArgWithDefault<bool>(
          positional,
          1,
          'defaultValue',
          false,
        );
        return t.getBool(key, defaultValue);
      },
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_33.ParsedCommand>(
          target,
          'ParsedCommand',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const ParsedCommand({required String name, Map<String, String> params = const {}, Set<String> flags = const {}, List<String> positionalArgs = const []})',
    },
    methodSignatures: {
      'get': 'String get(String key, [String defaultValue = \'\'])',
      'getInt': 'int? getInt(String key)',
      'getBool': 'bool getBool(String key, [bool defaultValue = false])',
      'toString': 'String toString()',
    },
    getterSignatures: {
      'name': 'String get name',
      'params': 'Map<String, String> get params',
      'flags': 'Set<String> get flags',
      'positionalArgs': 'List<String> get positionalArgs',
      'verbose': 'bool get verbose',
      'dryRun': 'bool get dryRun',
      'help': 'bool get help',
    },
  );
}

// =============================================================================
// ParsedTomCommand Bridge
// =============================================================================

BridgedClass _createParsedTomCommandBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_33.ParsedTomCommand,
    name: 'ParsedTomCommand',
    constructors: {
      '': (visitor, positional, named) {
        if (!named.containsKey('globalParams') ||
            named['globalParams'] == null) {
          throw ArgumentError(
            'ParsedTomCommand: Missing required named argument "globalParams"',
          );
        }
        final globalParams = D4.coerceMap<String, String>(
          named['globalParams'],
          'globalParams',
        );
        final globalFlags = D4.getRequiredNamedArg<Set<String>>(
          named,
          'globalFlags',
          'ParsedTomCommand',
        );
        if (!named.containsKey('commands') || named['commands'] == null) {
          throw ArgumentError(
            'ParsedTomCommand: Missing required named argument "commands"',
          );
        }
        final commands = D4.coerceList<$tom_build_cli_33.ParsedCommand>(
          named['commands'],
          'commands',
        );
        if (!named.containsKey('rawArgs') || named['rawArgs'] == null) {
          throw ArgumentError(
            'ParsedTomCommand: Missing required named argument "rawArgs"',
          );
        }
        final rawArgs = D4.coerceList<String>(named['rawArgs'], 'rawArgs');
        return $tom_build_cli_33.ParsedTomCommand(
          globalParams: globalParams,
          globalFlags: globalFlags,
          commands: commands,
          rawArgs: rawArgs,
        );
      },
    },
    getters: {
      'globalParams': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedTomCommand>(
            target,
            'ParsedTomCommand',
          )
          .globalParams,
      'globalFlags': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedTomCommand>(
            target,
            'ParsedTomCommand',
          )
          .globalFlags,
      'commands': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedTomCommand>(
            target,
            'ParsedTomCommand',
          )
          .commands,
      'rawArgs': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedTomCommand>(
            target,
            'ParsedTomCommand',
          )
          .rawArgs,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedTomCommand>(
            target,
            'ParsedTomCommand',
          )
          .verbose,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedTomCommand>(
            target,
            'ParsedTomCommand',
          )
          .dryRun,
      'help': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedTomCommand>(
            target,
            'ParsedTomCommand',
          )
          .help,
      'hasCommands': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.ParsedTomCommand>(
            target,
            'ParsedTomCommand',
          )
          .hasCommands,
    },
    methods: {
      'get': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_33.ParsedTomCommand>(
          target,
          'ParsedTomCommand',
        );
        D4.requireMinArgs(positional, 1, 'get');
        final key = D4.getRequiredArg<String>(positional, 0, 'key', 'get');
        final defaultValue = D4.getOptionalArgWithDefault<String>(
          positional,
          1,
          'defaultValue',
          '',
        );
        return t.get(key, defaultValue);
      },
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_33.ParsedTomCommand>(
          target,
          'ParsedTomCommand',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const ParsedTomCommand({required Map<String, String> globalParams, required Set<String> globalFlags, required List<ParsedCommand> commands, required List<String> rawArgs})',
    },
    methodSignatures: {
      'get': 'String get(String key, [String defaultValue = \'\'])',
      'toString': 'String toString()',
    },
    getterSignatures: {
      'globalParams': 'Map<String, String> get globalParams',
      'globalFlags': 'Set<String> get globalFlags',
      'commands': 'List<ParsedCommand> get commands',
      'rawArgs': 'List<String> get rawArgs',
      'verbose': 'bool get verbose',
      'dryRun': 'bool get dryRun',
      'help': 'bool get help',
      'hasCommands': 'bool get hasCommands',
    },
  );
}

// =============================================================================
// TomCommandParser Bridge
// =============================================================================

BridgedClass _createTomCommandParserBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_33.TomCommandParser,
    name: 'TomCommandParser',
    constructors: {
      '': (visitor, positional, named) {
        final additionalCommands = D4.getNamedArgWithDefault<Set<String>>(
          named,
          'additionalCommands',
          const {},
        );
        return $tom_build_cli_33.TomCommandParser(
          additionalCommands: additionalCommands,
        );
      },
    },
    getters: {
      'additionalCommands': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.TomCommandParser>(
            target,
            'TomCommandParser',
          )
          .additionalCommands,
      'allCommands': (visitor, target) => D4
          .validateTarget<$tom_build_cli_33.TomCommandParser>(
            target,
            'TomCommandParser',
          )
          .allCommands,
    },
    methods: {
      'parse': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_33.TomCommandParser>(
          target,
          'TomCommandParser',
        );
        D4.requireMinArgs(positional, 1, 'parse');
        if (positional.isEmpty) {
          throw ArgumentError(
            'parse: Missing required argument "args" at position 0',
          );
        }
        final args = D4.coerceList<String>(positional[0], 'args');
        return t.parse(args);
      },
      'mergeWithGlobals': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_33.TomCommandParser>(
          target,
          'TomCommandParser',
        );
        D4.requireMinArgs(positional, 3, 'mergeWithGlobals');
        final cmd = D4.getRequiredArg<$tom_build_cli_33.ParsedCommand>(
          positional,
          0,
          'cmd',
          'mergeWithGlobals',
        );
        if (positional.length <= 1) {
          throw ArgumentError(
            'mergeWithGlobals: Missing required argument "globalParams" at position 1',
          );
        }
        final globalParams = D4.coerceMap<String, String>(
          positional[1],
          'globalParams',
        );
        final globalFlags = D4.getRequiredArg<Set<String>>(
          positional,
          2,
          'globalFlags',
          'mergeWithGlobals',
        );
        return t.mergeWithGlobals(cmd, globalParams, globalFlags);
      },
    },
    constructorSignatures: {
      '': 'TomCommandParser({Set<String> additionalCommands = const {}})',
    },
    methodSignatures: {
      'parse': 'ParsedTomCommand parse(List<String> args)',
      'mergeWithGlobals':
          'ParsedCommand mergeWithGlobals(ParsedCommand cmd, Map<String, String> globalParams, Set<String> globalFlags)',
    },
    getterSignatures: {
      'additionalCommands': 'Set<String> get additionalCommands',
      'allCommands': 'Set<String> get allCommands',
    },
  );
}

// =============================================================================
// TomRunResult Bridge
// =============================================================================

BridgedClass _createTomRunResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_34.TomRunResult,
    name: 'TomRunResult',
    constructors: {
      '': (visitor, positional, named) {
        final success = D4.getRequiredNamedArg<bool>(
          named,
          'success',
          'TomRunResult',
        );
        final command = D4.getRequiredNamedArg<String>(
          named,
          'command',
          'TomRunResult',
        );
        final message = D4.getRequiredNamedArg<String>(
          named,
          'message',
          'TomRunResult',
        );
        final error = D4.getOptionalNamedArg<String?>(named, 'error');
        final duration = D4.getRequiredNamedArg<Duration>(
          named,
          'duration',
          'TomRunResult',
        );
        return $tom_build_cli_34.TomRunResult(
          success: success,
          command: command,
          message: message,
          error: error,
          duration: duration,
        );
      },
    },
    getters: {
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunResult>(
            target,
            'TomRunResult',
          )
          .success,
      'command': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunResult>(
            target,
            'TomRunResult',
          )
          .command,
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunResult>(
            target,
            'TomRunResult',
          )
          .message,
      'error': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunResult>(
            target,
            'TomRunResult',
          )
          .error,
      'duration': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunResult>(
            target,
            'TomRunResult',
          )
          .duration,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_34.TomRunResult>(
          target,
          'TomRunResult',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const TomRunResult({required bool success, required String command, required String message, String? error, required Duration duration})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'success': 'bool get success',
      'command': 'String get command',
      'message': 'String get message',
      'error': 'String? get error',
      'duration': 'Duration get duration',
    },
  );
}

// =============================================================================
// TomRunResults Bridge
// =============================================================================

BridgedClass _createTomRunResultsBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_34.TomRunResults,
    name: 'TomRunResults',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'TomRunResults');
        if (positional.isEmpty) {
          throw ArgumentError(
            'TomRunResults: Missing required argument "results" at position 0',
          );
        }
        final results = D4.coerceList<$tom_build_cli_34.TomRunResult>(
          positional[0],
          'results',
        );
        return $tom_build_cli_34.TomRunResults(results);
      },
    },
    getters: {
      'results': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunResults>(
            target,
            'TomRunResults',
          )
          .results,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunResults>(
            target,
            'TomRunResults',
          )
          .success,
      'totalDuration': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunResults>(
            target,
            'TomRunResults',
          )
          .totalDuration,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_34.TomRunResults>(
          target,
          'TomRunResults',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'const TomRunResults(List<TomRunResult> results)',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'results': 'List<TomRunResult> get results',
      'success': 'bool get success',
      'totalDuration': 'Duration get totalDuration',
    },
  );
}

// =============================================================================
// TomRunner Bridge
// =============================================================================

BridgedClass _createTomRunnerBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_34.TomRunner,
    name: 'TomRunner',
    constructors: {
      '': (visitor, positional, named) {
        final workspacePath = D4.getRequiredNamedArg<String>(
          named,
          'workspacePath',
          'TomRunner',
        );
        final verbose = D4.getNamedArgWithDefault<bool>(
          named,
          'verbose',
          false,
        );
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        final output = D4.getOptionalNamedArg<StringSink?>(named, 'output');
        return $tom_build_cli_34.TomRunner(
          workspacePath: workspacePath,
          verbose: verbose,
          dryRun: dryRun,
          output: output,
        );
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunner>(target, 'TomRunner')
          .workspacePath,
      'verbose': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunner>(target, 'TomRunner')
          .verbose,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunner>(target, 'TomRunner')
          .dryRun,
      'output': (visitor, target) => D4
          .validateTarget<$tom_build_cli_34.TomRunner>(target, 'TomRunner')
          .output,
    },
    methods: {
      'run': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_34.TomRunner>(
          target,
          'TomRunner',
        );
        D4.requireMinArgs(positional, 1, 'run');
        final parsed = D4.getRequiredArg<$tom_build_cli_33.ParsedTomCommand>(
          positional,
          0,
          'parsed',
          'run',
        );
        return t.run(parsed);
      },
    },
    constructorSignatures: {
      '': 'TomRunner({required String workspacePath, bool verbose = false, bool dryRun = false, StringSink? output})',
    },
    methodSignatures: {
      'run': 'Future<TomRunResults> run(ParsedTomCommand parsed)',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'verbose': 'bool get verbose',
      'dryRun': 'bool get dryRun',
      'output': 'StringSink get output',
    },
  );
}

// =============================================================================
// TemplateParser Bridge
// =============================================================================

BridgedClass _createTemplateParserBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_35.TemplateParser,
    name: 'TemplateParser',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'TemplateParser');
        final content = D4.getRequiredArg<String>(
          positional,
          0,
          'content',
          'TemplateParser',
        );
        return $tom_build_cli_35.TemplateParser(content);
      },
    },
    getters: {
      'content': (visitor, target) => D4
          .validateTarget<$tom_build_cli_35.TemplateParser>(
            target,
            'TemplateParser',
          )
          .content,
    },
    methods: {
      'parse': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_35.TemplateParser>(
          target,
          'TemplateParser',
        );
        return t.parse();
      },
    },
    staticGetters: {
      'markerPrefix': (visitor) =>
          $tom_build_cli_35.TemplateParser.markerPrefix,
      'modeStartPattern': (visitor) =>
          $tom_build_cli_35.TemplateParser.modeStartPattern,
      'modeEndPattern': (visitor) =>
          $tom_build_cli_35.TemplateParser.modeEndPattern,
    },
    constructorSignatures: {'': 'TemplateParser(String content)'},
    methodSignatures: {'parse': 'ParsedTemplate parse()'},
    getterSignatures: {'content': 'String get content'},
    staticGetterSignatures: {
      'markerPrefix': 'String get markerPrefix',
      'modeStartPattern': 'RegExp get modeStartPattern',
      'modeEndPattern': 'RegExp get modeEndPattern',
    },
  );
}

// =============================================================================
// ParsedTemplate Bridge
// =============================================================================

BridgedClass _createParsedTemplateBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_35.ParsedTemplate,
    name: 'ParsedTemplate',
    constructors: {
      '': (visitor, positional, named) {
        if (!named.containsKey('segments') || named['segments'] == null) {
          throw ArgumentError(
            'ParsedTemplate: Missing required named argument "segments"',
          );
        }
        final segments = D4.coerceList<$tom_build_cli_35.TemplateSegment>(
          named['segments'],
          'segments',
        );
        if (!named.containsKey('blocks') || named['blocks'] == null) {
          throw ArgumentError(
            'ParsedTemplate: Missing required named argument "blocks"',
          );
        }
        final blocks = D4.coerceList<$tom_build_cli_35.ModeBlock>(
          named['blocks'],
          'blocks',
        );
        return $tom_build_cli_35.ParsedTemplate(
          segments: segments,
          blocks: blocks,
        );
      },
    },
    getters: {
      'segments': (visitor, target) => D4
          .validateTarget<$tom_build_cli_35.ParsedTemplate>(
            target,
            'ParsedTemplate',
          )
          .segments,
      'blocks': (visitor, target) => D4
          .validateTarget<$tom_build_cli_35.ParsedTemplate>(
            target,
            'ParsedTemplate',
          )
          .blocks,
      'definedModes': (visitor, target) => D4
          .validateTarget<$tom_build_cli_35.ParsedTemplate>(
            target,
            'ParsedTemplate',
          )
          .definedModes,
    },
    constructorSignatures: {
      '': 'ParsedTemplate({required List<TemplateSegment> segments, required List<ModeBlock> blocks})',
    },
    getterSignatures: {
      'segments': 'List<TemplateSegment> get segments',
      'blocks': 'List<ModeBlock> get blocks',
      'definedModes': 'Set<String> get definedModes',
    },
  );
}

// =============================================================================
// TemplateSegment Bridge
// =============================================================================

BridgedClass _createTemplateSegmentBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_35.TemplateSegment,
    name: 'TemplateSegment',
    constructors: {},
  );
}

// =============================================================================
// TextSegment Bridge
// =============================================================================

BridgedClass _createTextSegmentBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_35.TextSegment,
    name: 'TextSegment',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'TextSegment');
        final content = D4.getRequiredArg<String>(
          positional,
          0,
          'content',
          'TextSegment',
        );
        return $tom_build_cli_35.TextSegment(content);
      },
    },
    getters: {
      'content': (visitor, target) => D4
          .validateTarget<$tom_build_cli_35.TextSegment>(target, 'TextSegment')
          .content,
    },
    constructorSignatures: {'': 'TextSegment(String content)'},
    getterSignatures: {'content': 'String get content'},
  );
}

// =============================================================================
// ModeBlockGroup Bridge
// =============================================================================

BridgedClass _createModeBlockGroupBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_35.ModeBlockGroup,
    name: 'ModeBlockGroup',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'ModeBlockGroup');
        if (positional.isEmpty) {
          throw ArgumentError(
            'ModeBlockGroup: Missing required argument "blocks" at position 0',
          );
        }
        final blocks = D4.coerceList<$tom_build_cli_35.ModeBlock>(
          positional[0],
          'blocks',
        );
        return $tom_build_cli_35.ModeBlockGroup(blocks);
      },
    },
    getters: {
      'blocks': (visitor, target) => D4
          .validateTarget<$tom_build_cli_35.ModeBlockGroup>(
            target,
            'ModeBlockGroup',
          )
          .blocks,
    },
    constructorSignatures: {'': 'ModeBlockGroup(List<ModeBlock> blocks)'},
    getterSignatures: {'blocks': 'List<ModeBlock> get blocks'},
  );
}

// =============================================================================
// ModeBlock Bridge
// =============================================================================

BridgedClass _createModeBlockBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_35.ModeBlock,
    name: 'ModeBlock',
    constructors: {
      '': (visitor, positional, named) {
        if (!named.containsKey('modes') || named['modes'] == null) {
          throw ArgumentError(
            'ModeBlock: Missing required named argument "modes"',
          );
        }
        final modes = D4.coerceList<String>(named['modes'], 'modes');
        final content = D4.getRequiredNamedArg<String>(
          named,
          'content',
          'ModeBlock',
        );
        return $tom_build_cli_35.ModeBlock(modes: modes, content: content);
      },
    },
    getters: {
      'modes': (visitor, target) => D4
          .validateTarget<$tom_build_cli_35.ModeBlock>(target, 'ModeBlock')
          .modes,
      'content': (visitor, target) => D4
          .validateTarget<$tom_build_cli_35.ModeBlock>(target, 'ModeBlock')
          .content,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_35.ModeBlock>(
          target,
          'ModeBlock',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'ModeBlock({required List<String> modes, required String content})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'modes': 'List<String> get modes',
      'content': 'String get content',
    },
  );
}

// =============================================================================
// WsPrepper Bridge
// =============================================================================

BridgedClass _createWsPrepperBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_36.WsPrepper,
    name: 'WsPrepper',
    constructors: {
      '': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'WsPrepper');
        final workspacePath = D4.getRequiredArg<String>(
          positional,
          0,
          'workspacePath',
          'WsPrepper',
        );
        final options = D4
            .getOptionalNamedArg<$tom_build_cli_36.WsPrepperOptions?>(
              named,
              'options',
            );
        return $tom_build_cli_36.WsPrepper(workspacePath, options: options);
      },
    },
    getters: {
      'workspacePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepper>(target, 'WsPrepper')
          .workspacePath,
      'options': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepper>(target, 'WsPrepper')
          .options,
    },
    methods: {
      'findTemplates': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_36.WsPrepper>(
          target,
          'WsPrepper',
        );
        return t.findTemplates();
      },
      'processAll': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_36.WsPrepper>(
          target,
          'WsPrepper',
        );
        D4.requireMinArgs(positional, 1, 'processAll');
        final mode = D4.getRequiredArg<String>(
          positional,
          0,
          'mode',
          'processAll',
        );
        return t.processAll(mode);
      },
      'processTemplate': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_36.WsPrepper>(
          target,
          'WsPrepper',
        );
        D4.requireMinArgs(positional, 2, 'processTemplate');
        final template = D4.getRequiredArg<File>(
          positional,
          0,
          'template',
          'processTemplate',
        );
        final mode = D4.getRequiredArg<String>(
          positional,
          1,
          'mode',
          'processTemplate',
        );
        return t.processTemplate(template, mode);
      },
      'generateOutput': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_36.WsPrepper>(
          target,
          'WsPrepper',
        );
        D4.requireMinArgs(positional, 2, 'generateOutput');
        final parsed = D4.getRequiredArg<$tom_build_cli_35.ParsedTemplate>(
          positional,
          0,
          'parsed',
          'generateOutput',
        );
        final mode = D4.getRequiredArg<String>(
          positional,
          1,
          'mode',
          'generateOutput',
        );
        return t.generateOutput(parsed, mode);
      },
    },
    constructorSignatures: {
      '': 'WsPrepper(String workspacePath, {WsPrepperOptions? options})',
    },
    methodSignatures: {
      'findTemplates': 'Future<List<File>> findTemplates()',
      'processAll': 'Future<WsPrepperResult> processAll(String mode)',
      'processTemplate':
          'Future<PreparedTemplate> processTemplate(File template, String mode)',
      'generateOutput':
          'String generateOutput(ParsedTemplate parsed, String mode)',
    },
    getterSignatures: {
      'workspacePath': 'String get workspacePath',
      'options': 'WsPrepperOptions get options',
    },
  );
}

// =============================================================================
// WsPrepperOptions Bridge
// =============================================================================

BridgedClass _createWsPrepperOptionsBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_36.WsPrepperOptions,
    name: 'WsPrepperOptions',
    constructors: {
      '': (visitor, positional, named) {
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        final excludePatterns = D4.coerceListOrNull<String>(
          named['excludePatterns'],
          'excludePatterns',
        );
        return $tom_build_cli_36.WsPrepperOptions(
          dryRun: dryRun,
          excludePatterns: excludePatterns,
        );
      },
    },
    getters: {
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepperOptions>(
            target,
            'WsPrepperOptions',
          )
          .dryRun,
      'excludePatterns': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepperOptions>(
            target,
            'WsPrepperOptions',
          )
          .excludePatterns,
    },
    constructorSignatures: {
      '': 'WsPrepperOptions({bool dryRun = false, List<String>? excludePatterns})',
    },
    getterSignatures: {
      'dryRun': 'bool get dryRun',
      'excludePatterns': 'List<String> get excludePatterns',
    },
  );
}

// =============================================================================
// WsPrepperResult Bridge
// =============================================================================

BridgedClass _createWsPrepperResultBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_36.WsPrepperResult,
    name: 'WsPrepperResult',
    constructors: {
      '': (visitor, positional, named) {
        final mode = D4.getRequiredNamedArg<String>(
          named,
          'mode',
          'WsPrepperResult',
        );
        final processed = D4
            .coerceListOrNull<$tom_build_cli_36.PreparedTemplate>(
              named['processed'],
              'processed',
            );
        final errors = D4.coerceListOrNull<$tom_build_cli_36.WsPrepperError>(
          named['errors'],
          'errors',
        );
        return $tom_build_cli_36.WsPrepperResult(
          mode: mode,
          processed: processed,
          errors: errors,
        );
      },
    },
    getters: {
      'mode': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepperResult>(
            target,
            'WsPrepperResult',
          )
          .mode,
      'processed': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepperResult>(
            target,
            'WsPrepperResult',
          )
          .processed,
      'errors': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepperResult>(
            target,
            'WsPrepperResult',
          )
          .errors,
      'success': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepperResult>(
            target,
            'WsPrepperResult',
          )
          .success,
      'totalTemplates': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepperResult>(
            target,
            'WsPrepperResult',
          )
          .totalTemplates,
    },
    constructorSignatures: {
      '': 'WsPrepperResult({required String mode, List<PreparedTemplate>? processed, List<WsPrepperError>? errors})',
    },
    getterSignatures: {
      'mode': 'String get mode',
      'processed': 'List<PreparedTemplate> get processed',
      'errors': 'List<WsPrepperError> get errors',
      'success': 'bool get success',
      'totalTemplates': 'int get totalTemplates',
    },
  );
}

// =============================================================================
// PreparedTemplate Bridge
// =============================================================================

BridgedClass _createPreparedTemplateBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_36.PreparedTemplate,
    name: 'PreparedTemplate',
    constructors: {
      '': (visitor, positional, named) {
        final templatePath = D4.getRequiredNamedArg<String>(
          named,
          'templatePath',
          'PreparedTemplate',
        );
        final outputPath = D4.getRequiredNamedArg<String>(
          named,
          'outputPath',
          'PreparedTemplate',
        );
        final mode = D4.getRequiredNamedArg<String>(
          named,
          'mode',
          'PreparedTemplate',
        );
        final blocksFound = D4.getRequiredNamedArg<int>(
          named,
          'blocksFound',
          'PreparedTemplate',
        );
        final dryRun = D4.getNamedArgWithDefault<bool>(named, 'dryRun', false);
        return $tom_build_cli_36.PreparedTemplate(
          templatePath: templatePath,
          outputPath: outputPath,
          mode: mode,
          blocksFound: blocksFound,
          dryRun: dryRun,
        );
      },
    },
    getters: {
      'templatePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.PreparedTemplate>(
            target,
            'PreparedTemplate',
          )
          .templatePath,
      'outputPath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.PreparedTemplate>(
            target,
            'PreparedTemplate',
          )
          .outputPath,
      'mode': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.PreparedTemplate>(
            target,
            'PreparedTemplate',
          )
          .mode,
      'blocksFound': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.PreparedTemplate>(
            target,
            'PreparedTemplate',
          )
          .blocksFound,
      'dryRun': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.PreparedTemplate>(
            target,
            'PreparedTemplate',
          )
          .dryRun,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_36.PreparedTemplate>(
          target,
          'PreparedTemplate',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'PreparedTemplate({required String templatePath, required String outputPath, required String mode, required int blocksFound, bool dryRun = false})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'templatePath': 'String get templatePath',
      'outputPath': 'String get outputPath',
      'mode': 'String get mode',
      'blocksFound': 'int get blocksFound',
      'dryRun': 'bool get dryRun',
    },
  );
}

// =============================================================================
// WsPrepperError Bridge
// =============================================================================

BridgedClass _createWsPrepperErrorBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_36.WsPrepperError,
    name: 'WsPrepperError',
    constructors: {
      '': (visitor, positional, named) {
        final templatePath = D4.getRequiredNamedArg<String>(
          named,
          'templatePath',
          'WsPrepperError',
        );
        final message = D4.getRequiredNamedArg<String>(
          named,
          'message',
          'WsPrepperError',
        );
        return $tom_build_cli_36.WsPrepperError(
          templatePath: templatePath,
          message: message,
        );
      },
    },
    getters: {
      'templatePath': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepperError>(
            target,
            'WsPrepperError',
          )
          .templatePath,
      'message': (visitor, target) => D4
          .validateTarget<$tom_build_cli_36.WsPrepperError>(
            target,
            'WsPrepperError',
          )
          .message,
    },
    methods: {
      'toString': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_36.WsPrepperError>(
          target,
          'WsPrepperError',
        );
        return t.toString();
      },
    },
    constructorSignatures: {
      '': 'WsPrepperError({required String templatePath, required String message})',
    },
    methodSignatures: {'toString': 'String toString()'},
    getterSignatures: {
      'templatePath': 'String get templatePath',
      'message': 'String get message',
    },
  );
}

// =============================================================================
// TomD4rtRepl Bridge
// =============================================================================

BridgedClass _createTomD4rtReplBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_29.TomD4rtRepl,
    name: 'TomD4rtRepl',
    constructors: {
      '': (visitor, positional, named) {
        return $tom_build_cli_29.TomD4rtRepl();
      },
    },
    getters: {
      'tomCli': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .tomCli,
      'toolName': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .toolName,
      'toolVersion': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .toolVersion,
      'dataDirectory': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .dataDirectory,
      'replayFilePatterns': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .replayFilePatterns,
      'hasVSCodeIntegration': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .hasVSCodeIntegration,
      'toolExtension': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .toolExtension,
      'dataDirectoryShort': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .dataDirectoryShort,
      'initSourceFileName': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .initSourceFileName,
      'vscodePort': (visitor, target) => D4
          .validateTarget<$tom_build_cli_29.TomD4rtRepl>(target, 'TomD4rtRepl')
          .vscodePort,
    },
    methods: {
      'registerBridges': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        D4.requireMinArgs(positional, 1, 'registerBridges');
        final d4rt = D4.getRequiredArg<$tom_d4rt_2.D4rt>(
          positional,
          0,
          'd4rt',
          'registerBridges',
        );
        t.registerBridges(d4rt);
        return null;
      },
      'getImportBlock': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        return t.getImportBlock();
      },
      'handleAdditionalCommands':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
              target,
              'TomD4rtRepl',
            );
            D4.requireMinArgs(positional, 3, 'handleAdditionalCommands');
            final d4rt = D4.getRequiredArg<$tom_d4rt_2.D4rt>(
              positional,
              0,
              'd4rt',
              'handleAdditionalCommands',
            );
            final state = D4.getRequiredArg<$tom_d4rt_dcli_1.ReplState>(
              positional,
              1,
              'state',
              'handleAdditionalCommands',
            );
            final line = D4.getRequiredArg<String>(
              positional,
              2,
              'line',
              'handleAdditionalCommands',
            );
            final silent = D4.getNamedArgWithDefault<bool>(
              named,
              'silent',
              false,
            );
            return t.handleAdditionalCommands(
              d4rt,
              state,
              line,
              silent: silent,
            );
          },
      'getAdditionalHelpSections':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
              target,
              'TomD4rtRepl',
            );
            return t.getAdditionalHelpSections();
          },
      'createReplState': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        return t.createReplState();
      },
      'getBridgesHelp': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        final d4rt = D4.getOptionalArg<$tom_d4rt_2.D4rt?>(
          positional,
          0,
          'd4rt',
        );
        return t.getBridgesHelp(d4rt);
      },
      'getCliOptionsHelp': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        return t.getCliOptionsHelp();
      },
      'onReplStartup': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        D4.requireMinArgs(positional, 2, 'onReplStartup');
        final d4rt = D4.getRequiredArg<$tom_d4rt_2.D4rt>(
          positional,
          0,
          'd4rt',
          'onReplStartup',
        );
        final state = D4.getRequiredArg<$tom_d4rt_dcli_1.ReplState>(
          positional,
          1,
          'state',
          'onReplStartup',
        );
        return t.onReplStartup(d4rt, state);
      },
      'handleAdditionalMultilineEnd':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
              target,
              'TomD4rtRepl',
            );
            D4.requireMinArgs(positional, 4, 'handleAdditionalMultilineEnd');
            final d4rt = D4.getRequiredArg<$tom_d4rt_2.D4rt>(
              positional,
              0,
              'd4rt',
              'handleAdditionalMultilineEnd',
            );
            final state = D4.getRequiredArg<$tom_d4rt_dcli_1.ReplState>(
              positional,
              1,
              'state',
              'handleAdditionalMultilineEnd',
            );
            final mode = D4.getRequiredArg<$tom_d4rt_dcli_1.MultilineMode>(
              positional,
              2,
              'mode',
              'handleAdditionalMultilineEnd',
            );
            final code = D4.getRequiredArg<String>(
              positional,
              3,
              'code',
              'handleAdditionalMultilineEnd',
            );
            final silent = D4.getNamedArgWithDefault<bool>(
              named,
              'silent',
              false,
            );
            return t.handleAdditionalMultilineEnd(
              d4rt,
              state,
              mode,
              code,
              silent: silent,
            );
          },
      'getVersionBanner': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        return t.getVersionBanner();
      },
      'getCliExamplesHelp': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        return t.getCliExamplesHelp();
      },
      'printUsage': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        t.printUsage();
        return null;
      },
      'printReplHelp': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        final d4rt = D4.getOptionalArg<$tom_d4rt_2.D4rt?>(
          positional,
          0,
          'd4rt',
        );
        t.printReplHelp(d4rt);
        return null;
      },
      'run': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        D4.requireMinArgs(positional, 1, 'run');
        if (positional.isEmpty) {
          throw ArgumentError(
            'run: Missing required argument "arguments" at position 0',
          );
        }
        final arguments = D4.coerceList<String>(positional[0], 'arguments');
        return t.run(arguments);
      },
      'processInput': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        D4.requireMinArgs(positional, 3, 'processInput');
        final d4rt = D4.getRequiredArg<$tom_d4rt_2.D4rt>(
          positional,
          0,
          'd4rt',
          'processInput',
        );
        final state = D4.getRequiredArg<$tom_d4rt_dcli_1.ReplState>(
          positional,
          1,
          'state',
          'processInput',
        );
        final input = D4.getRequiredArg<String>(
          positional,
          2,
          'input',
          'processInput',
        );
        final silent = D4.getNamedArgWithDefault<bool>(named, 'silent', false);
        return t.processInput(d4rt, state, input, silent: silent);
      },
      'getPackageNames': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        D4.requireMinArgs(positional, 1, 'getPackageNames');
        final d4rt = D4.getRequiredArg<$tom_d4rt_2.D4rt>(
          positional,
          0,
          'd4rt',
          'getPackageNames',
        );
        return t.getPackageNames(d4rt);
      },
      'printAllPackagesInfo': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        D4.requireMinArgs(positional, 1, 'printAllPackagesInfo');
        final d4rt = D4.getRequiredArg<$tom_d4rt_2.D4rt>(
          positional,
          0,
          'd4rt',
          'printAllPackagesInfo',
        );
        t.printAllPackagesInfo(d4rt);
        return null;
      },
      'initVSCodeIntegration': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        final onStatusMessageRaw = named['onStatusMessage'];
        final onErrorMessageRaw = named['onErrorMessage'];
        t.initVSCodeIntegration(
          onStatusMessage: onStatusMessageRaw == null
              ? null
              : (String p0) {
                  D4.callInterpreterCallback(visitor, onStatusMessageRaw, [p0]);
                },
          onErrorMessage: onErrorMessageRaw == null
              ? null
              : (String p0) {
                  D4.callInterpreterCallback(visitor, onErrorMessageRaw, [p0]);
                },
        );
        return null;
      },
      'checkVSCodeAvailability':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
              target,
              'TomD4rtRepl',
            );
            return t.checkVSCodeAvailability();
          },
      'getVSCodeIntegrationHelp':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
              target,
              'TomD4rtRepl',
            );
            return t.getVSCodeIntegrationHelp();
          },
      'handleVSCodeCommands': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
          target,
          'TomD4rtRepl',
        );
        D4.requireMinArgs(positional, 2, 'handleVSCodeCommands');
        final state = D4.getRequiredArg<$tom_d4rt_dcli_1.ReplState>(
          positional,
          0,
          'state',
          'handleVSCodeCommands',
        );
        final line = D4.getRequiredArg<String>(
          positional,
          1,
          'line',
          'handleVSCodeCommands',
        );
        final silent = D4.getNamedArgWithDefault<bool>(named, 'silent', false);
        return t.handleVSCodeCommands(state, line, silent: silent);
      },
      'handleVSCodeMultilineEnd':
          (visitor, target, positional, named, typeArgs) {
            final t = D4.validateTarget<$tom_build_cli_29.TomD4rtRepl>(
              target,
              'TomD4rtRepl',
            );
            D4.requireMinArgs(positional, 3, 'handleVSCodeMultilineEnd');
            final state = D4.getRequiredArg<$tom_d4rt_dcli_1.ReplState>(
              positional,
              0,
              'state',
              'handleVSCodeMultilineEnd',
            );
            final mode = D4.getRequiredArg<$tom_d4rt_dcli_1.MultilineMode>(
              positional,
              1,
              'mode',
              'handleVSCodeMultilineEnd',
            );
            final code = D4.getRequiredArg<String>(
              positional,
              2,
              'code',
              'handleVSCodeMultilineEnd',
            );
            final silent = D4.getNamedArgWithDefault<bool>(
              named,
              'silent',
              false,
            );
            return t.handleVSCodeMultilineEnd(
              state,
              mode,
              code,
              silent: silent,
            );
          },
    },
    constructorSignatures: {'': 'TomD4rtRepl()'},
    methodSignatures: {
      'registerBridges': 'void registerBridges(D4rt d4rt)',
      'getImportBlock': 'String getImportBlock()',
      'handleAdditionalCommands':
          'Future<bool> handleAdditionalCommands(D4rt d4rt, ReplState state, String line, {bool silent = false})',
      'getAdditionalHelpSections': 'List<String> getAdditionalHelpSections()',
      'createReplState': 'ReplState createReplState()',
      'getBridgesHelp': 'String getBridgesHelp([D4rt? d4rt])',
      'getCliOptionsHelp': 'String getCliOptionsHelp()',
      'onReplStartup': 'Future<void> onReplStartup(D4rt d4rt, ReplState state)',
      'handleAdditionalMultilineEnd':
          'Future<bool> handleAdditionalMultilineEnd(D4rt d4rt, ReplState state, MultilineMode mode, String code, {bool silent = false})',
      'getVersionBanner': 'String getVersionBanner()',
      'getCliExamplesHelp': 'String getCliExamplesHelp()',
      'printUsage': 'void printUsage()',
      'printReplHelp': 'void printReplHelp([D4rt? d4rt])',
      'run': 'Future<void> run(List<String> arguments)',
      'processInput':
          'Future<bool> processInput(D4rt d4rt, ReplState state, String input, {bool silent = false})',
      'getPackageNames': 'List<String> getPackageNames(D4rt d4rt)',
      'printAllPackagesInfo': 'void printAllPackagesInfo(D4rt d4rt)',
      'initVSCodeIntegration':
          'void initVSCodeIntegration({void Function(String)? onStatusMessage, void Function(String)? onErrorMessage})',
      'checkVSCodeAvailability': 'Future<void> checkVSCodeAvailability()',
      'getVSCodeIntegrationHelp': 'String getVSCodeIntegrationHelp()',
      'handleVSCodeCommands':
          'Future<bool> handleVSCodeCommands(ReplState state, String line, {bool silent = false})',
      'handleVSCodeMultilineEnd':
          'Future<bool> handleVSCodeMultilineEnd(ReplState state, MultilineMode mode, String code, {bool silent = false})',
    },
    getterSignatures: {
      'tomCli': 'TomCli get tomCli',
      'toolName': 'String get toolName',
      'toolVersion': 'String get toolVersion',
      'dataDirectory': 'String get dataDirectory',
      'replayFilePatterns': 'List<String> get replayFilePatterns',
      'hasVSCodeIntegration': 'bool get hasVSCodeIntegration',
      'toolExtension': 'String get toolExtension',
      'dataDirectoryShort': 'String get dataDirectoryShort',
      'initSourceFileName': 'String get initSourceFileName',
      'vscodePort': 'int get vscodePort',
    },
  );
}

// =============================================================================
// Tom Bridge
// =============================================================================

BridgedClass _createTomBridge() {
  return BridgedClass(
    nativeType: $tom_build_cli_27.Tom,
    name: 'Tom',
    constructors: {},
    staticGetters: {
      'workspace': (visitor) => $tom_build_cli_27.Tom.workspace,
      'cwd': (visitor) => $tom_build_cli_27.Tom.cwd,
      'project': (visitor) => $tom_build_cli_27.Tom.project,
      'projectInfo': (visitor) => $tom_build_cli_27.Tom.projectInfo,
      'actions': (visitor) => $tom_build_cli_27.Tom.actions,
      'groups': (visitor) => $tom_build_cli_27.Tom.groups,
      'env': (visitor) => $tom_build_cli_27.Tom.env,
    },
    staticMethods: {
      'runAction': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'runAction');
        final action = D4.getRequiredArg<String>(
          positional,
          0,
          'action',
          'runAction',
        );
        final addArgs = positional.length > 1
            ? D4.coerceListOrNull<String>(positional[1], 'addArgs')
            : null;
        return $tom_build_cli_27.Tom.runAction(action, addArgs);
      },
      'runActions': (visitor, positional, named, typeArgs) {
        D4.requireMinArgs(positional, 1, 'runActions');
        if (positional.isEmpty) {
          throw ArgumentError(
            'runActions: Missing required argument "actions" at position 0',
          );
        }
        final actions = D4.coerceList<String>(positional[0], 'actions');
        return $tom_build_cli_27.Tom.runActions(actions);
      },
      'analyze': (visitor, positional, named, typeArgs) {
        return $tom_build_cli_27.Tom.analyze();
      },
      'build': (visitor, positional, named, typeArgs) {
        final project = D4.getOptionalArg<String?>(positional, 0, 'project');
        return $tom_build_cli_27.Tom.build(project);
      },
      'test': (visitor, positional, named, typeArgs) {
        final project = D4.getOptionalArg<String?>(positional, 0, 'project');
        return $tom_build_cli_27.Tom.test(project);
      },
    },
    staticMethodSignatures: {
      'runAction':
          'Future<TomCliResult> runAction(String action, [List<String>? addArgs])',
      'runActions':
          'Future<List<TomCliResult>> runActions(List<String> actions)',
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
// TomWorkspace Bridge
// =============================================================================

BridgedClass _createTomWorkspaceBridge() {
  return BridgedClass(
    nativeType: $tom_build_1.TomWorkspace,
    name: 'TomWorkspace',
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getOptionalNamedArg<String?>(named, 'name');
        final binaries = D4.getOptionalNamedArg<String?>(named, 'binaries');
        final operatingSystems = D4.coerceListOrNull<String>(
          named['operatingSystems'],
          'operatingSystems',
        );
        final mobilePlatforms = D4.coerceListOrNull<String>(
          named['mobilePlatforms'],
          'mobilePlatforms',
        );
        final imports = D4.coerceListOrNull<String>(
          named['imports'],
          'imports',
        );
        final workspaceModes = D4
            .getOptionalNamedArg<$tom_build_1.WorkspaceModes?>(
              named,
              'workspaceModes',
            );
        final crossCompilation = D4
            .getOptionalNamedArg<$tom_build_1.CrossCompilation?>(
              named,
              'crossCompilation',
            );
        final groups = named.containsKey('groups') && named['groups'] != null
            ? D4.coerceMap<String, $tom_build_1.GroupDef>(
                named['groups'],
                'groups',
              )
            : const <String, $tom_build_1.GroupDef>{};
        final projectTypes =
            named.containsKey('projectTypes') && named['projectTypes'] != null
            ? D4.coerceMap<String, $tom_build_1.ProjectTypeDef>(
                named['projectTypes'],
                'projectTypes',
              )
            : const <String, $tom_build_1.ProjectTypeDef>{};
        final actions = named.containsKey('actions') && named['actions'] != null
            ? D4.coerceMap<String, $tom_build_1.ActionDef>(
                named['actions'],
                'actions',
              )
            : const <String, $tom_build_1.ActionDef>{};
        final modeDefinitions =
            named.containsKey('modeDefinitions') &&
                named['modeDefinitions'] != null
            ? D4.coerceMap<String, $tom_build_1.ModeDefinitions>(
                named['modeDefinitions'],
                'modeDefinitions',
              )
            : const <String, $tom_build_1.ModeDefinitions>{};
        final pipelines =
            named.containsKey('pipelines') && named['pipelines'] != null
            ? D4.coerceMap<String, $tom_build_1.Pipeline>(
                named['pipelines'],
                'pipelines',
              )
            : const <String, $tom_build_1.Pipeline>{};
        final projectInfo =
            named.containsKey('projectInfo') && named['projectInfo'] != null
            ? D4.coerceMap<String, $tom_build_1.ProjectEntry>(
                named['projectInfo'],
                'projectInfo',
              )
            : const <String, $tom_build_1.ProjectEntry>{};
        final deps = named.containsKey('deps') && named['deps'] != null
            ? D4.coerceMap<String, String>(named['deps'], 'deps')
            : const <String, String>{};
        final depsDev = named.containsKey('depsDev') && named['depsDev'] != null
            ? D4.coerceMap<String, String>(named['depsDev'], 'depsDev')
            : const <String, String>{};
        final versionSettings = D4
            .getOptionalNamedArg<$tom_build_1.VersionSettings?>(
              named,
              'versionSettings',
            );
        final customTags =
            named.containsKey('customTags') && named['customTags'] != null
            ? D4.coerceMap<String, dynamic>(named['customTags'], 'customTags')
            : const <String, dynamic>{};
        return $tom_build_1.TomWorkspace(
          name: name,
          binaries: binaries,
          operatingSystems: operatingSystems,
          mobilePlatforms: mobilePlatforms,
          imports: imports,
          workspaceModes: workspaceModes,
          crossCompilation: crossCompilation,
          groups: groups,
          projectTypes: projectTypes,
          actions: actions,
          modeDefinitions: modeDefinitions,
          pipelines: pipelines,
          projectInfo: projectInfo,
          deps: deps,
          depsDev: depsDev,
          versionSettings: versionSettings,
          customTags: customTags,
        );
      },
      'fromYaml': (visitor, positional, named) {
        D4.requireMinArgs(positional, 1, 'TomWorkspace');
        if (positional.isEmpty) {
          throw ArgumentError(
            'TomWorkspace: Missing required argument "yaml" at position 0',
          );
        }
        final yaml = D4.coerceMap<String, dynamic>(positional[0], 'yaml');
        return $tom_build_1.TomWorkspace.fromYaml(yaml);
      },
    },
    getters: {
      'name': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .name,
      'binaries': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .binaries,
      'operatingSystems': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .operatingSystems,
      'mobilePlatforms': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .mobilePlatforms,
      'imports': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .imports,
      'workspaceModes': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .workspaceModes,
      'crossCompilation': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .crossCompilation,
      'groups': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .groups,
      'projectTypes': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .projectTypes,
      'actions': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .actions,
      'modeDefinitions': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .modeDefinitions,
      'pipelines': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .pipelines,
      'projectInfo': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .projectInfo,
      'deps': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .deps,
      'depsDev': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .depsDev,
      'versionSettings': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .versionSettings,
      'customTags': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomWorkspace>(target, 'TomWorkspace')
          .customTags,
    },
    methods: {
      'toYaml': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_1.TomWorkspace>(
          target,
          'TomWorkspace',
        );
        return t.toYaml();
      },
    },
    constructorSignatures: {
      '': 'TomWorkspace({String? name, String? binaries, List<String>? operatingSystems, List<String>? mobilePlatforms, List<String>? imports, WorkspaceModes? workspaceModes, CrossCompilation? crossCompilation, Map<String, GroupDef> groups = const {}, Map<String, ProjectTypeDef> projectTypes = const {}, Map<String, ActionDef> actions = const {}, Map<String, ModeDefinitions> modeDefinitions = const {}, Map<String, Pipeline> pipelines = const {}, Map<String, ProjectEntry> projectInfo = const {}, Map<String, String> deps = const {}, Map<String, String> depsDev = const {}, VersionSettings? versionSettings, Map<String, dynamic> customTags = const {}})',
      'fromYaml': 'factory TomWorkspace.fromYaml(Map<String, dynamic> yaml)',
    },
    methodSignatures: {'toYaml': 'Map<String, dynamic> toYaml()'},
    getterSignatures: {
      'name': 'String? get name',
      'binaries': 'String? get binaries',
      'operatingSystems': 'List<String>? get operatingSystems',
      'mobilePlatforms': 'List<String>? get mobilePlatforms',
      'imports': 'List<String>? get imports',
      'workspaceModes': 'WorkspaceModes? get workspaceModes',
      'crossCompilation': 'CrossCompilation? get crossCompilation',
      'groups': 'Map<String, GroupDef> get groups',
      'projectTypes': 'Map<String, ProjectTypeDef> get projectTypes',
      'actions': 'Map<String, ActionDef> get actions',
      'modeDefinitions': 'Map<String, ModeDefinitions> get modeDefinitions',
      'pipelines': 'Map<String, Pipeline> get pipelines',
      'projectInfo': 'Map<String, ProjectEntry> get projectInfo',
      'deps': 'Map<String, String> get deps',
      'depsDev': 'Map<String, String> get depsDev',
      'versionSettings': 'VersionSettings? get versionSettings',
      'customTags': 'Map<String, dynamic> get customTags',
    },
  );
}

// =============================================================================
// TomProject Bridge
// =============================================================================

BridgedClass _createTomProjectBridge() {
  return BridgedClass(
    nativeType: $tom_build_1.TomProject,
    name: 'TomProject',
    constructors: {
      '': (visitor, positional, named) {
        final name = D4.getRequiredNamedArg<String>(
          named,
          'name',
          'TomProject',
        );
        final type = D4.getOptionalNamedArg<String?>(named, 'type');
        final description = D4.getOptionalNamedArg<String?>(
          named,
          'description',
        );
        final binaries = D4.getOptionalNamedArg<String?>(named, 'binaries');
        final buildAfter =
            named.containsKey('buildAfter') && named['buildAfter'] != null
            ? D4.coerceList<String>(named['buildAfter'], 'buildAfter')
            : const <String>[];
        final actionOrder =
            named.containsKey('actionOrder') && named['actionOrder'] != null
            ? D4.coerceMap<String, List<String>>(
                named['actionOrder'],
                'actionOrder',
              )
            : const <String, List<String>>{};
        final features = D4.getOptionalNamedArg<$tom_build_1.Features?>(
          named,
          'features',
        );
        final actions = named.containsKey('actions') && named['actions'] != null
            ? D4.coerceMap<String, $tom_build_1.ActionDef>(
                named['actions'],
                'actions',
              )
            : const <String, $tom_build_1.ActionDef>{};
        final modeDefinitions =
            named.containsKey('modeDefinitions') &&
                named['modeDefinitions'] != null
            ? D4.coerceMap<String, $tom_build_1.ModeDefinitions>(
                named['modeDefinitions'],
                'modeDefinitions',
              )
            : const <String, $tom_build_1.ModeDefinitions>{};
        final crossCompilation = D4
            .getOptionalNamedArg<$tom_build_1.CrossCompilation?>(
              named,
              'crossCompilation',
            );
        final packageModule = D4
            .getOptionalNamedArg<$tom_build_1.PackageModule?>(
              named,
              'packageModule',
            );
        final parts = named.containsKey('parts') && named['parts'] != null
            ? D4.coerceMap<String, $tom_build_1.Part>(named['parts'], 'parts')
            : const <String, $tom_build_1.Part>{};
        final tests = D4.coerceListOrNull<String>(named['tests'], 'tests');
        final examples = D4.coerceListOrNull<String>(
          named['examples'],
          'examples',
        );
        final docs = D4.coerceListOrNull<String>(named['docs'], 'docs');
        final copilotGuidelines = D4.coerceListOrNull<String>(
          named['copilotGuidelines'],
          'copilotGuidelines',
        );
        final binaryFiles = D4.coerceListOrNull<String>(
          named['binaryFiles'],
          'binaryFiles',
        );
        final executables =
            named.containsKey('executables') && named['executables'] != null
            ? D4.coerceList<$tom_build_1.ExecutableDef>(
                named['executables'],
                'executables',
              )
            : const <$tom_build_1.ExecutableDef>[];
        final metadataFiles =
            named.containsKey('metadataFiles') && named['metadataFiles'] != null
            ? D4.coerceMap<String, dynamic>(
                named['metadataFiles'],
                'metadataFiles',
              )
            : const <String, dynamic>{};
        final actionModeDefinitions = D4.coerceMapOrNull<String, dynamic>(
          named['actionModeDefinitions'],
          'actionModeDefinitions',
        );
        final customTags =
            named.containsKey('customTags') && named['customTags'] != null
            ? D4.coerceMap<String, dynamic>(named['customTags'], 'customTags')
            : const <String, dynamic>{};
        return $tom_build_1.TomProject(
          name: name,
          type: type,
          description: description,
          binaries: binaries,
          buildAfter: buildAfter,
          actionOrder: actionOrder,
          features: features,
          actions: actions,
          modeDefinitions: modeDefinitions,
          crossCompilation: crossCompilation,
          packageModule: packageModule,
          parts: parts,
          tests: tests,
          examples: examples,
          docs: docs,
          copilotGuidelines: copilotGuidelines,
          binaryFiles: binaryFiles,
          executables: executables,
          metadataFiles: metadataFiles,
          actionModeDefinitions: actionModeDefinitions,
          customTags: customTags,
        );
      },
      'fromYaml': (visitor, positional, named) {
        D4.requireMinArgs(positional, 2, 'TomProject');
        final name = D4.getRequiredArg<String>(
          positional,
          0,
          'name',
          'TomProject',
        );
        if (positional.length <= 1) {
          throw ArgumentError(
            'TomProject: Missing required argument "yaml" at position 1',
          );
        }
        final yaml = D4.coerceMap<String, dynamic>(positional[1], 'yaml');
        final defaultActions = D4
            .coerceMapOrNull<String, $tom_build_1.ActionDef>(
              named['defaultActions'],
              'defaultActions',
            );
        return $tom_build_1.TomProject.fromYaml(
          name,
          yaml,
          defaultActions: defaultActions,
        );
      },
    },
    getters: {
      'name': (visitor, target) =>
          D4.validateTarget<$tom_build_1.TomProject>(target, 'TomProject').name,
      'type': (visitor, target) =>
          D4.validateTarget<$tom_build_1.TomProject>(target, 'TomProject').type,
      'description': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .description,
      'binaries': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .binaries,
      'buildAfter': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .buildAfter,
      'actionOrder': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .actionOrder,
      'features': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .features,
      'actions': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .actions,
      'modeDefinitions': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .modeDefinitions,
      'crossCompilation': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .crossCompilation,
      'packageModule': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .packageModule,
      'parts': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .parts,
      'tests': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .tests,
      'examples': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .examples,
      'docs': (visitor, target) =>
          D4.validateTarget<$tom_build_1.TomProject>(target, 'TomProject').docs,
      'copilotGuidelines': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .copilotGuidelines,
      'binaryFiles': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .binaryFiles,
      'executables': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .executables,
      'metadataFiles': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .metadataFiles,
      'actionModeDefinitions': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .actionModeDefinitions,
      'customTags': (visitor, target) => D4
          .validateTarget<$tom_build_1.TomProject>(target, 'TomProject')
          .customTags,
    },
    methods: {
      'toYaml': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_1.TomProject>(
          target,
          'TomProject',
        );
        return t.toYaml();
      },
      'toYamlCompact': (visitor, target, positional, named, typeArgs) {
        final t = D4.validateTarget<$tom_build_1.TomProject>(
          target,
          'TomProject',
        );
        final workspaceCrossCompilation = D4
            .getOptionalNamedArg<$tom_build_1.CrossCompilation?>(
              named,
              'workspaceCrossCompilation',
            );
        final workspaceModeDefinitions = D4
            .coerceMapOrNull<String, $tom_build_1.ModeDefinitions>(
              named['workspaceModeDefinitions'],
              'workspaceModeDefinitions',
            );
        final workspaceActions = D4
            .coerceMapOrNull<String, $tom_build_1.ActionDef>(
              named['workspaceActions'],
              'workspaceActions',
            );
        return t.toYamlCompact(
          workspaceCrossCompilation: workspaceCrossCompilation,
          workspaceModeDefinitions: workspaceModeDefinitions,
          workspaceActions: workspaceActions,
        );
      },
    },
    constructorSignatures: {
      '': 'TomProject({required String name, String? type, String? description, String? binaries, List<String> buildAfter = const [], Map<String, List<String>> actionOrder = const {}, Features? features, Map<String, ActionDef> actions = const {}, Map<String, ModeDefinitions> modeDefinitions = const {}, CrossCompilation? crossCompilation, PackageModule? packageModule, Map<String, Part> parts = const {}, List<String>? tests, List<String>? examples, List<String>? docs, List<String>? copilotGuidelines, List<String>? binaryFiles, List<ExecutableDef> executables = const [], Map<String, dynamic> metadataFiles = const {}, Map<String, dynamic>? actionModeDefinitions, Map<String, dynamic> customTags = const {}})',
      'fromYaml':
          'factory TomProject.fromYaml(String name, Map<String, dynamic> yaml, {Map<String, ActionDef>? defaultActions})',
    },
    methodSignatures: {
      'toYaml': 'Map<String, dynamic> toYaml()',
      'toYamlCompact':
          'Map<String, dynamic> toYamlCompact({CrossCompilation? workspaceCrossCompilation, Map<String, ModeDefinitions>? workspaceModeDefinitions, Map<String, ActionDef>? workspaceActions})',
    },
    getterSignatures: {
      'name': 'String get name',
      'type': 'String? get type',
      'description': 'String? get description',
      'binaries': 'String? get binaries',
      'buildAfter': 'List<String> get buildAfter',
      'actionOrder': 'Map<String, List<String>> get actionOrder',
      'features': 'Features? get features',
      'actions': 'Map<String, ActionDef> get actions',
      'modeDefinitions': 'Map<String, ModeDefinitions> get modeDefinitions',
      'crossCompilation': 'CrossCompilation? get crossCompilation',
      'packageModule': 'PackageModule? get packageModule',
      'parts': 'Map<String, Part> get parts',
      'tests': 'List<String>? get tests',
      'examples': 'List<String>? get examples',
      'docs': 'List<String>? get docs',
      'copilotGuidelines': 'List<String>? get copilotGuidelines',
      'binaryFiles': 'List<String>? get binaryFiles',
      'executables': 'List<ExecutableDef> get executables',
      'metadataFiles': 'Map<String, dynamic> get metadataFiles',
      'actionModeDefinitions':
          'Map<String, dynamic>? get actionModeDefinitions',
      'customTags': 'Map<String, dynamic> get customTags',
    },
  );
}
