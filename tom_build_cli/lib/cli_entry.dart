/// CLI entry points for tom_build_cli binaries.
///
/// These functions allow other packages to call the CLI tools programmatically.
library;

// Re-export main functions from bin files
export 'src/cli_entry/ws_analyzer_main.dart';
export 'src/cli_entry/ws_prepper_main.dart';
export 'src/cli_entry/doc_scanner_main.dart';
export 'src/cli_entry/docspecs_main.dart';
export 'src/cli_entry/md_latex_main.dart';
export 'src/cli_entry/md_pdf_main.dart';
export 'src/cli_entry/tom_main.dart';
