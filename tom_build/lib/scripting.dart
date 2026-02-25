/// Scripting utilities for D4rt-based build scripts.
///
/// This library provides convenient helper classes for shell-script-like
/// operations in Dart, designed for use with the D4rt interpreter.
///
/// All helper classes use static methods for easy use in D4rt scripts.
///
/// ## Helpers
///
/// - [TomShell] - Execute shell commands
/// - [TomFs] - File system operations
/// - [TomPth] - Path manipulation
/// - [TomGlob] - File pattern matching
/// - [TomText] - Text processing
/// - [TomEnv] - Environment variables
/// - [TomMaps] - Map merging and traversal
/// - [ScriptYaml] - YAML loading utilities
/// - [TomZoned] - Zone value access
/// - [TomWs] - Workspace metadata access
///
/// ## Example
///
/// ```dart
/// // In a D4rt script:
///
/// // Find all Dart files and process them
/// final files = TomGlob.find('**/*.dart');
/// for (final file in files) {
///   final content = TomFs.read(file);
///   final processed = TomText.template(content, {'version': '1.0.0'});
///   TomFs.write(file, processed);
/// }
///
/// // Run a command
/// final result = TomShell.run('dart', ['analyze']);
/// if (result.exitCode != 0) {
///   print('Analysis failed!');
/// }
/// ```
library;

export 'src/scripting/env.dart';
export 'src/scripting/fs.dart';
export 'src/scripting/glob.dart';
export 'src/scripting/maps.dart';
export 'src/scripting/path.dart';
export 'src/scripting/shell.dart';
export 'src/scripting/text.dart';
export 'src/scripting/workspace.dart';
export 'src/scripting/yaml.dart';
export 'src/scripting/zone.dart';
