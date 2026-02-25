/// Tom Build CLI - CLI implementation for the Tom build system.
///
/// This package contains the CLI-specific code for the Tom build tool,
/// including argument parsing, action execution, configuration loading,
/// and workspace management.
///
/// For scripting utilities (Shell, Fs, etc.), use `package:tom_build/scripting.dart`.
/// For the main Tom Build API, use `package:tom_build/tom_build.dart`.
library;

// =============================================================================
// DARTSCRIPT / D4RT CLI INITIALIZATION
// =============================================================================
export 'src/dartscript/bridge_configuration.dart';
export 'src/dartscript/d4rt_cli_initialization.dart';
export 'src/dartscript/d4rt_context_provider.dart';
export 'src/dartscript/d4rt_globals.dart';
export 'src/dartscript/d4rt_instance.dart';

// =============================================================================
// TOM CLI
// =============================================================================
// CLI
export 'src/tom/cli/argument_parser.dart';
export 'src/tom/cli/git_helper.dart';
export 'src/tom/cli/internal_commands.dart';
export 'src/tom/cli/tom_cli.dart';
export 'src/tom/cli/version_bumper.dart';
export 'src/tom/cli/workspace_context.dart';

// Config
export 'src/tom/config/config_loader.dart';
export 'src/tom/config/config_merger.dart';
export 'src/tom/config/validation.dart';

// Execution
export 'src/tom/execution/action_executor.dart';
export 'src/tom/execution/command_runner.dart';
export 'src/tom/execution/d4rt_runner.dart';
export 'src/tom/execution/output_formatter.dart';

// VS Code Bridge Client (re-exported from tom_dartscript_bridges)
export 'package:tom_dartscript_bridges/tom_dartscript_bridges.dart' show VSCodeBridgeClient, VSCodeBridgeResult, VSCodeBridgeAdapter, defaultVSCodeBridgePort;

// Generation
export 'src/tom/generation/build_order.dart';
export 'src/tom/generation/generator_placeholder.dart';
export 'src/tom/generation/master_generator.dart';
export 'src/tom/generation/placeholder_resolver.dart';

// Mode
export 'src/tom/mode/mode_processor.dart';
export 'src/tom/mode/mode_resolver.dart';

// Template
export 'src/tom/template/tomplate_parser.dart';
export 'src/tom/template/tomplate_processor.dart';

// =============================================================================
// TOOLS
// =============================================================================
export 'src/tools/cli_args.dart';
export 'src/tools/pipeline.dart';
export 'src/tools/placeholder_resolver.dart';
export 'src/tools/tom_command_parser.dart';
// Hide runTomCli - use the newer one from tom_cli.dart instead
export 'src/tools/tom_runner.dart' hide runTomCli;

// =============================================================================
// WS PREPPER
// =============================================================================
export 'src/ws_prepper/template_parser.dart';
export 'src/ws_prepper/ws_prepper.dart';

// =============================================================================
// TOM D4RT - Integrated REPL with Tom CLI
// =============================================================================
export 'src/tom_d4rt/dartscript.b.dart';
export 'src/tom_d4rt/tom_d4rt_main.dart';
export 'src/tom_d4rt/tom_d4rt_repl.dart';
export 'src/tom_d4rt/version.versioner.dart';

// =============================================================================
// TOM CLI API - Bridgeable classes for D4rt scripts
// =============================================================================
export 'src/tom_cli_api/tom_api.dart';
