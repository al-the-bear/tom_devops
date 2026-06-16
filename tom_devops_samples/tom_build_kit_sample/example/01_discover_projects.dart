// Discover — find the Dart projects in a directory tree.
//
// `BuildBase.findProjects` scans a path, detects the "nature" of every folder
// it finds, and hands back a list of `CommandContext` objects. This is the
// lowest-level entry point: no command, no execution, just "what is here?".
//
// Filesystem listing order is not guaranteed, so we sort the names before
// printing to keep the output deterministic. Example 02 shows the ordering you
// actually want for a build — dependency (build) order.
//
// Run: dart run example/01_discover_projects.dart

import 'package:tom_build_base/tom_build_base_v2.dart';

import 'fixture.dart';

Future<void> main() async {
  final contexts = await BuildBase.findProjects(
    scan: fixtureWorkspacePath(),
    recursive: false,
  );

  // Keep only the Dart projects (the scanned root folder itself is an FsFolder
  // with no pubspec, so it is not a Dart project).
  final names = contexts
      .where((ctx) => ctx.isDartProject)
      .map((ctx) => ctx.name)
      .toList()
    ..sort();

  print('Discovered ${names.length} Dart projects: ${names.join(', ')}');
  // expected output: Discovered 3 Dart projects: pkg_app, pkg_core, pkg_data
}
