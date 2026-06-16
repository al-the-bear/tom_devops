// Shared helper: locate the bundled fixture workspace.
//
// Every example operates on `example/fixture_workspace/`, a tiny tree of three
// pubspec-only Dart projects (pkg_core ← pkg_data ← pkg_app). Keeping the path
// resolution in one place means the examples themselves stay focused on the one
// concept they demonstrate.
//
// The path is derived from `Platform.script` rather than the current working
// directory, so the examples produce identical output whether they are run as
// `dart run example/01_discover_projects.dart` from the package root, imported
// by `run_all_examples.dart`, or launched by the top-level samples aggregator.
// In every one of those cases the running script lives in this `example/`
// directory, so its parent is the right anchor for the fixture.

import 'dart:io';

/// Absolute path to the bundled `fixture_workspace/` directory.
String fixtureWorkspacePath() {
  final scriptDir = File.fromUri(Platform.script).parent.path;
  return '$scriptDir/fixture_workspace';
}
