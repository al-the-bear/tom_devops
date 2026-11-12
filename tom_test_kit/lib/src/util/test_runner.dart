import 'dart:io';

import 'package:tom_build_base/tom_build_base.dart' show isFlutterPackage;

/// The test runner testkit launches for a package.
///
/// A Flutter package (tom_build_base's [isFlutterPackage]: the pubspec declares
/// `dependencies: flutter: sdk: flutter`) is run with `flutter test` — plain
/// `dart test` cannot resolve `package:flutter` or boot the test binding —
/// and every other package with `dart test`. Both emit the same package:test
/// JSON protocol, so everything after the launch is runner-agnostic.
class TestRunner {
  /// `flutter` or `dart`.
  final String executable;

  /// Whether the launcher is started through the shell: on Windows the SDK
  /// launchers are batch files (`dart.bat`, `flutter.bat`) that
  /// `Process.start` cannot resolve directly.
  final bool runInShell;

  const TestRunner({required this.executable, required this.runInShell});

  /// The runner for the package at [projectPath]. [windows] overrides the
  /// host check (tests use it to cover the Windows launcher on any host).
  factory TestRunner.forPackage(String projectPath, {bool? windows}) =>
      TestRunner(
        executable: isFlutterPackage(projectPath) ? 'flutter' : 'dart',
        runInShell: windows ?? Platform.isWindows,
      );

  /// The arguments of a JSON-reporting run with [testArgs] appended.
  List<String> argsFor(List<String> testArgs) => [
    'test',
    '--reporter',
    'json',
    ...testArgs,
  ];

  /// `flutter test` or `dart test`, for messages.
  String get label => '$executable test';
}
