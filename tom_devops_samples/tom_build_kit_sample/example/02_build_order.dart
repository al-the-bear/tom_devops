// Build order — traverse projects dependency-first.
//
// `BuildBase.forEachDartProject` runs a callback once per Dart project. By
// default it sorts the projects in *build order*: a project is always visited
// after every workspace project it depends on. The fixture graph is
// pkg_core ← pkg_data ← pkg_app, so the order is fixed regardless of how the
// filesystem happens to list the folders.
//
// This is the ordering buildkit uses for `:pubget`, `:compile`, `:publish`,
// etc. — you never want to build a dependent before its dependency.
//
// Run: dart run example/02_build_order.dart

import 'dart:io';

import 'package:tom_build_base/tom_build_base_v2.dart';

import 'fixture.dart';

Future<void> main() async {
  final visited = <String>[];

  await BuildBase.forEachDartProject(
    (ctx) async {
      visited.add(ctx.name);
      return true; // returning true records the project as processed
    },
    scan: fixtureWorkspacePath(),
    recursive: false,
  );

  print('Build order: ${visited.join(' -> ')}');
  // expected output: Build order: pkg_core -> pkg_data -> pkg_app

  // The order is total and deterministic: dependencies always come first.
  if (visited.indexOf('pkg_core') > visited.indexOf('pkg_data')) {
    stderr.writeln('Build order violated: pkg_core must precede pkg_data');
    exitCode = 1;
  }
}
