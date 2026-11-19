import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

/// The workspace analyzer lists a project's and the workspace's guidelines
/// from `_agent_guidelines/`, else from the old `_copilot_guidelines/`
/// (under the metadata's `copilot-guidelines:` key either way).
void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('tom_build_guide_'));
  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  void write(String rel, [String text = '']) => File(p.join(root.path, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);

  void project(String name) => write(
    '$name/pubspec.yaml',
    'name: $name\ndescription: x\nenvironment:\n  sdk: ^3.0.0\n',
  );

  Future<YamlMap> analyze() async {
    await WorkspaceAnalyzer(root.path).analyze();
    final file = File(p.join(root.path, '.tom_metadata', 'tom_master.yaml'));
    return loadYaml(file.readAsStringSync()) as YamlMap;
  }

  List<String>? projectGuidelines(YamlMap master, String name) {
    final entry = (master['projects'] as YamlMap)[name] as YamlMap;
    final list = entry['copilot-guidelines'] as YamlList?;
    return list?.map((e) => '$e').toList();
  }

  test('guidelinesFolderOf: _agent_guidelines, else _copilot_guidelines, '
      'else none [2026-11-19]', () {
    expect(guidelinesFolderOf(root.path), isNull);
    write('_copilot_guidelines/a.md');
    expect(
      p.basename(guidelinesFolderOf(root.path)!.path),
      '_copilot_guidelines',
    );
    write('_agent_guidelines/b.md');
    expect(
      p.basename(guidelinesFolderOf(root.path)!.path),
      '_agent_guidelines',
    );
  });

  test('a project\'s guidelines: the new folder, the old one, both (the new '
      'wins), neither [2026-11-19]', () async {
    project('newpkg');
    write('newpkg/_agent_guidelines/index.md');
    write('newpkg/_agent_guidelines/build.md');
    project('oldpkg');
    write('oldpkg/_copilot_guidelines/index.md');
    project('bothpkg');
    write('bothpkg/_agent_guidelines/new.md');
    write('bothpkg/_copilot_guidelines/old.md');
    project('nonepkg');

    final master = await analyze();
    expect(projectGuidelines(master, 'newpkg'), ['build.md', 'index.md']);
    expect(projectGuidelines(master, 'oldpkg'), ['index.md']);
    expect(projectGuidelines(master, 'bothpkg'), ['new.md']);
    expect(projectGuidelines(master, 'nonepkg'), isNull);
  });

  test('the workspace\'s guidelines: the new folder, else the old one '
      '[2026-11-19]', () async {
    project('pkg');
    write('_copilot_guidelines/old.md');
    var master = await analyze();
    expect((master['copilot-guidelines'] as YamlList).map((e) => '$e'), [
      'old.md',
    ]);
    write('_agent_guidelines/dart/coding.md');
    write('_agent_guidelines/index.md');
    master = await analyze();
    expect((master['copilot-guidelines'] as YamlList).map((e) => '$e'), [
      'dart/',
      'index.md',
    ]);
  });
}
