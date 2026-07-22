import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Detects whether the Dart package at [projectPath] targets Flutter.
///
/// A package is a Flutter package when its `pubspec.yaml` declares a
/// dependency on the Flutter SDK:
///
/// ```yaml
/// dependencies:
///   flutter:
///     sdk: flutter
/// ```
///
/// This is the same signal the Flutter tooling itself uses. Such packages
/// pull in `package:flutter`, so only `flutter test` (which boots the Flutter
/// test binding) can run their tests — plain `dart test` fails to resolve the
/// `dart:ui` bindings. testkit switches its runner on this signal so
/// `testkit :baseline` / `testkit :test` work uniformly for Dart and Flutter
/// packages.
///
/// Returns false when the pubspec is missing or unparseable — testkit then
/// falls back to `dart test`, preserving the previous behaviour for anything
/// that is not clearly a Flutter package.
bool isFlutterPackage(String projectPath) {
  final pubspec = File(p.join(projectPath, 'pubspec.yaml'));
  if (!pubspec.existsSync()) return false;

  final dynamic root;
  try {
    root = loadYaml(pubspec.readAsStringSync());
  } catch (_) {
    return false;
  }

  return pubspecDeclaresFlutterSdk(root);
}

/// Whether a parsed `pubspec.yaml` [root] declares a Flutter SDK dependency.
///
/// Split out from [isFlutterPackage] so the detection logic can be tested
/// without touching the filesystem. Accepts the raw value returned by
/// `loadYaml` (typically a [YamlMap]).
bool pubspecDeclaresFlutterSdk(dynamic root) {
  if (root is! Map) return false;
  final deps = root['dependencies'];
  if (deps is! Map) return false;
  final flutter = deps['flutter'];
  return flutter is Map && flutter['sdk'] == 'flutter';
}
