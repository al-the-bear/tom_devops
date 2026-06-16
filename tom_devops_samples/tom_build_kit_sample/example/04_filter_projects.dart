// Filter — narrow the traversal to a subset of projects.
//
// The traversal helpers accept `include` (only these projects) and `exclude`
// (everything but these). These map to buildkit's `--project` / `-p` and
// `--exclude-projects` flags. Filtering happens *after* nature detection, so
// matching is by package name, and *before* the callback runs, so excluded
// projects are never touched.
//
// Run: dart run example/04_filter_projects.dart

import 'package:tom_build_base/tom_build_base_v2.dart';

import 'fixture.dart';

Future<void> main() async {
  final fixture = fixtureWorkspacePath();

  // exclude: drop pkg_app, keep the rest (build order preserved).
  final kept = <String>[];
  await BuildBase.forEachDartProject(
    (ctx) async {
      kept.add(ctx.name);
      return true;
    },
    scan: fixture,
    recursive: false,
    exclude: ['pkg_app'],
  );
  print('Excluding pkg_app: ${kept.join(', ')}');
  // expected output: Excluding pkg_app: pkg_core, pkg_data

  // include: keep only pkg_core.
  final only = <String>[];
  await BuildBase.forEachDartProject(
    (ctx) async {
      only.add(ctx.name);
      return true;
    },
    scan: fixture,
    recursive: false,
    include: ['pkg_core'],
  );
  print('Including only pkg_core: ${only.join(', ')}');
  // expected output: Including only pkg_core: pkg_core
}
