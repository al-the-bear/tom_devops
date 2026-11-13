/// Tom Test Kit — test result tracking for projects in every language its
/// runners know (Dart, Flutter, Go, Rust, Python, Java, JavaScript,
/// TypeScript, C, C++).
///
/// Run `test_kit help` or `--help` for full usage information.
library;

export 'src/model/line_coverage.dart';
export 'src/model/test_entry.dart';
export 'src/model/test_run.dart';
export 'src/model/test_run_results.dart';
export 'src/model/tracking_file.dart';
export 'src/parser/dart_test_parser.dart';
export 'src/parser/test_description_parser.dart';
export 'src/runner/project_test_runner.dart';
export 'src/runner/report_parsers.dart';
export 'src/runner/result_collector.dart';
export 'src/tracking/baseline_command.dart';
export 'src/tracking/basediff_command.dart';
export 'src/tracking/crossref_command.dart';
export 'src/tracking/diff_command.dart';
export 'src/tracking/diff_helper.dart';
export 'src/tracking/flaky_command.dart';
export 'src/tracking/fuzz_command.dart';
export 'src/mutation/mutation_catalogue.dart';
export 'src/mutation/mutation_sweep.dart';
export 'src/mutation/mutations_command.dart';
export 'src/tracking/history_command.dart';
export 'src/tracking/lastdiff_command.dart';
export 'src/tracking/reset_command.dart';
export 'src/tracking/runs_command.dart';
export 'src/tracking/status_command.dart';
export 'src/tracking/test_command.dart';
export 'src/tracking/trim_command.dart';
export 'src/util/file_helpers.dart';
export 'src/util/format_helpers.dart';
export 'src/util/markdown_table.dart';
export 'src/util/output_formatter.dart';
export 'src/util/test_runner.dart';

// TUI framework
export 'src/tui/tui_command.dart';
export 'src/tui/tui_command_registry.dart';
export 'src/tui/tui_module.dart';
export 'src/tui/tui_output_parser.dart';
export 'src/tui/external_tool_adapter.dart';
export 'src/tui/commands/baseline_tui_command.dart';
export 'src/tui/commands/test_tui_command.dart';
export 'src/tui/app/test_kit_tui_app.dart';
export 'src/tui/app/tui_output_panel.dart';
export 'src/tui/app/tui_menu_panel.dart';
