import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

/// Test IDs: TK-TRN-1 through TK-TRN-7
///
/// Which runner testkit launches: `flutter test` for a Flutter package,
/// `dart test` otherwise (the rule is tom_build_base's `isFlutterPackage`),
/// through the shell on Windows where both launchers are `.bat` files.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('tk_runner_'));
  tearDown(() => dir.deleteSync(recursive: true));

  void pubspec(String text) =>
      File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync(text);

  const flutterPubspec = '''
name: probe_app
environment:
  sdk: ^3.0.0
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
''';

  group('TestRunner.forPackage', () {
    test('TK-TRN-1: a Flutter package runs `flutter test`', () {
      pubspec(flutterPubspec);
      final runner = TestRunner.forPackage(dir.path, windows: false);
      expect(runner.executable, 'flutter');
      expect(runner.argsFor(['--name', 'x']), [
        'test',
        '--reporter',
        'json',
        '--name',
        'x',
      ]);
      expect(runner.label, 'flutter test');
    });

    test('TK-TRN-2: a Dart package runs `dart test`', () {
      pubspec('name: probe_lib\nenvironment:\n  sdk: ^3.0.0\n');
      final runner = TestRunner.forPackage(dir.path, windows: false);
      expect(runner.executable, 'dart');
      expect(runner.argsFor(const []), ['test', '--reporter', 'json']);
    });

    test('TK-TRN-3: on Windows both launchers go through the shell', () {
      // `dart.bat` / `flutter.bat` resolve only through the shell.
      pubspec(flutterPubspec);
      expect(TestRunner.forPackage(dir.path, windows: true).runInShell, isTrue);
      pubspec('name: probe_lib\n');
      expect(TestRunner.forPackage(dir.path, windows: true).runInShell, isTrue);
    });

    test('TK-TRN-4: elsewhere neither does', () {
      pubspec(flutterPubspec);
      expect(
        TestRunner.forPackage(dir.path, windows: false).runInShell,
        isFalse,
      );
      pubspec('name: probe_lib\n');
      expect(
        TestRunner.forPackage(dir.path, windows: false).runInShell,
        isFalse,
      );
    });

    test('TK-TRN-5: without an override, the host decides', () {
      pubspec('name: probe_lib\n');
      expect(TestRunner.forPackage(dir.path).runInShell, Platform.isWindows);
    });
  });

  /// A minimal Flutter package with one widget test, resolved.
  Future<void> flutterPackage() async {
    pubspec(flutterPubspec);
    Directory(p.join(dir.path, 'test')).createSync();
    File(p.join(dir.path, 'test', 'widget_test.dart')).writeAsStringSync(
      "import 'package:flutter/material.dart';\n"
      "import 'package:flutter_test/flutter_test.dart';\n"
      'void main() {\n'
      "  testWidgets('W-1: renders text', (tester) async {\n"
      "    await tester.pumpWidget(const Directionality(\n"
      "        textDirection: TextDirection.ltr, child: Text('hi')));\n"
      "    expect(find.text('hi'), findsOneWidget);\n"
      '  });\n'
      '}\n',
    );
    final got = await Process.run(
      'flutter',
      ['pub', 'get'],
      workingDirectory: dir.path,
      runInShell: Platform.isWindows,
    );
    if (got.exitCode != 0) fail('flutter pub get: ${got.stderr}');
  }

  final noFlutter = _flutterAvailable() ? false : 'flutter is not on PATH';

  test(
    'TK-TRN-6: a Flutter package is run with `flutter test` and its widget '
    'test lands in the baseline',
    () async {
      await flutterPackage();

      final ok = await BaselineCommand.run(projectPath: dir.path);

      expect(ok, isTrue);
      final tracking = TrackingFile.load(findLatestTrackingFile(dir.path)!);
      expect(tracking!.entries.keys, contains('W-1: renders text'));
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: noFlutter,
  );

  test(
    'TK-TRN-7: the TUI baseline command runs `flutter test` for it too',
    () async {
      await flutterPackage();
      final sink = TuiCommandSink();

      final result = await BaselineTuiCommand().execute(
        projectPath: dir.path,
        sink: sink,
      );

      expect(result.success, isTrue, reason: result.summary);
      expect(result.passedCount, 1);
      expect(
        sink.events.whereType<TuiPhaseStarted>().map((e) => e.phaseName),
        contains('Running flutter test'),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: noFlutter,
  );
}

bool _flutterAvailable() {
  try {
    return Process.runSync('flutter', [
          '--version',
        ], runInShell: Platform.isWindows).exitCode ==
        0;
  } on ProcessException {
    return false;
  }
}
