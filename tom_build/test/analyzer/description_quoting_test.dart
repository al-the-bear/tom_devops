import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

/// Regression test for the workspace analyzer's `tom_master.yaml` serializer.
///
/// Project / part / module `description:` fields are emitted as double-quoted
/// YAML scalars. The values are free text and legitimately contain `"` (e.g. a
/// description like `the meta-model ("reflection") classes`). The serializer
/// must escape those embedded quotes — otherwise the quote terminates the
/// scalar early and the whole `tom_master.yaml` becomes unparseable, which is
/// exactly what happened when `tom_spec_engine` / `tom_som_dart_runtime` were
/// registered. See decision **F20** in `d4rt_and_llm_tools_decisions.md`.
void main() {
  test('description with embedded quotes round-trips through tom_master.yaml',
      () async {
    final root = Directory.systemTemp.createTempSync('tom_build_descq_');
    addTearDown(() {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });

    // A description that broke the serializer: embedded double quotes plus a
    // backslash — both must be escaped inside a double-quoted YAML scalar.
    const description =
        r'The meta-model ("reflection") classes and a C:\path backslash.';

    final projectDir = Directory(p.join(root.path, 'quoted_proj'))
      ..createSync(recursive: true);
    // Single-quoted YAML scalar keeps the embedded double quotes and backslash
    // literal while remaining valid YAML in the fixture pubspec.
    File(p.join(projectDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: quoted_proj
description: '$description'
environment:
  sdk: ^3.0.0
''');

    await WorkspaceAnalyzer(root.path).analyze();

    final masterPath = p.join(root.path, '.tom_metadata', 'tom_master.yaml');
    final content = File(masterPath).readAsStringSync();

    // The file must be valid YAML — this is what regressed.
    final Object? parsed = loadYaml(content);
    expect(parsed, isA<YamlMap>());

    // And the description must survive intact (quotes + backslash preserved).
    final master = parsed as YamlMap;
    final projects = master['projects'] as YamlMap;
    final entry = projects['quoted_proj'] as YamlMap;
    expect(entry['description'], description);
  });
}
