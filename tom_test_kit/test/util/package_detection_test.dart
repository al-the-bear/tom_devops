import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_test_kit/tom_test_kit.dart';
import 'package:yaml/yaml.dart';

/// Test IDs: TK-PKG-1 through TK-PKG-9
void main() {
  group('package detection', () {
    group('pubspecDeclaresFlutterSdk', () {
      test('TK-PKG-1: detects a Flutter SDK dependency', () {
        final root = loadYaml('''
name: my_flutter_pkg
dependencies:
  flutter:
    sdk: flutter
''');
        expect(pubspecDeclaresFlutterSdk(root), isTrue);
      });

      test('TK-PKG-2: a plain Dart package is not a Flutter package', () {
        final root = loadYaml('''
name: my_dart_pkg
dependencies:
  path: ^1.9.0
  args: ^2.6.0
''');
        expect(pubspecDeclaresFlutterSdk(root), isFalse);
      });

      test('TK-PKG-3: no dependencies block is not a Flutter package', () {
        final root = loadYaml('name: bare_pkg\n');
        expect(pubspecDeclaresFlutterSdk(root), isFalse);
      });

      test('TK-PKG-4: flutter as a hosted (non-sdk) dep does not count', () {
        // A dependency literally named "flutter" without `sdk: flutter` is not
        // the Flutter SDK signal.
        final root = loadYaml('''
name: odd_pkg
dependencies:
  flutter: ^1.0.0
''');
        expect(pubspecDeclaresFlutterSdk(root), isFalse);
      });

      test('TK-PKG-5: flutter_test in dev_dependencies alone does not count',
          () {
        // Only a Flutter SDK dep in `dependencies` marks a Flutter package;
        // flutter_test in dev_dependencies is not sufficient on its own.
        final root = loadYaml('''
name: dev_only
dev_dependencies:
  flutter_test:
    sdk: flutter
''');
        expect(pubspecDeclaresFlutterSdk(root), isFalse);
      });

      test('TK-PKG-6: non-map input returns false', () {
        expect(pubspecDeclaresFlutterSdk(null), isFalse);
        expect(pubspecDeclaresFlutterSdk('not a map'), isFalse);
      });
    });

    group('isFlutterPackage', () {
      late Directory tempDir;

      setUp(() {
        tempDir = Directory.systemTemp.createTempSync('tk_pkg_detect_');
      });

      tearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      test('TK-PKG-7: reads a Flutter pubspec from disk', () {
        File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: flutter_app
dependencies:
  flutter:
    sdk: flutter
''');
        expect(isFlutterPackage(tempDir.path), isTrue);
      });

      test('TK-PKG-8: reads a plain Dart pubspec from disk', () {
        File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: dart_lib
dependencies:
  path: ^1.9.0
''');
        expect(isFlutterPackage(tempDir.path), isFalse);
      });

      test('TK-PKG-9: missing pubspec falls back to false', () {
        expect(isFlutterPackage(tempDir.path), isFalse);
      });
    });
  });
}
