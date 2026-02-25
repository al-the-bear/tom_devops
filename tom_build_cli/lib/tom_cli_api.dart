/// Tom CLI API - Export barrel for D4rt bridge generation.
///
/// This barrel exports all types needed for the Tom CLI API
/// and is used by the bridge generator.
///
/// Usage:
/// ```dart
/// import 'package:tom_build_cli/tom_cli_api.dart';
///
/// void main() async {
///   await Tom.runAction('analyze');
///   await Tom.build('tom_build_cli');
///   print(Tom.cwd);
/// }
/// ```
library;

export 'src/tom_cli_api/tom_api.dart';
export 'src/tom/execution/command_runner.dart' show CommandResult;
