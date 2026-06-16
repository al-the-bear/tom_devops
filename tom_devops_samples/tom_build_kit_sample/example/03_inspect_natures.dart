// Inspect — read a project's metadata through its detected nature.
//
// Every Dart project folder carries a `DartProjectFolder` nature populated from
// its pubspec: the package name, version, dependency maps, and derived facts
// like `isPublishable` (a versioned package that is not `publish_to: none`).
//
// pkg_core and pkg_data are versioned libraries → publishable.
// pkg_app is marked `publish_to: none` → not publishable.
//
// Run: dart run example/03_inspect_natures.dart

import 'package:tom_build_base/tom_build_base_v2.dart';

import 'fixture.dart';

Future<void> main() async {
  await BuildBase.forEachDartProject(
    (ctx) async {
      final dart = ctx.getNature<DartProjectFolder>();
      final publishable = dart.isPublishable ? 'publishable' : 'private';
      print('${dart.projectName} v${dart.version} — $publishable');
      return true;
    },
    scan: fixtureWorkspacePath(),
    recursive: false,
  );
  // expected output: pkg_core v1.0.0 — publishable
  // expected output: pkg_data v0.4.0 — publishable
  // expected output: pkg_app v0.1.0 — private
}
