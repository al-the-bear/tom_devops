import 'dart:io';

import 'package:test/test.dart';
import 'package:tom_build/src/tom/file_object_model/file_object_model.dart';

void main() {
  final fixtureDir = 'fixture/all_attributes';
  final resultDir = '$fixtureDir/results';

  setUpAll(() {
    Directory(resultDir).createSync(recursive: true);
  });

  group('All Attributes Round-Trip', () {
    test('tom_workspace.yaml exact round-trip', () {
      final inputPath = '$fixtureDir/tom_workspace.yaml';
      final resultPath = '$resultDir/tom_workspace.yaml';

      // Load original
      final originalContent = File(inputPath).readAsStringSync();
      final yaml = loadYamlFile(inputPath);

      // Parse and serialize
      final workspace = TomWorkspace.fromYaml(yaml);
      final resultYaml = workspace.toYaml();
      final resultContent = toYamlString(resultYaml);

      // Write result
      File(resultPath).writeAsStringSync(resultContent);

      // Reload result to verify it's valid YAML
      final reloadedYaml = loadYamlFile(resultPath);
      TomWorkspace.fromYaml(reloadedYaml);

      // Compare content
      _compareYamlFiles(
        'tom_workspace.yaml',
        originalContent,
        resultContent,
        yaml,
        resultYaml,
      );
    });

    test('tom_project.yaml exact round-trip', () {
      final inputPath = '$fixtureDir/tom_project.yaml';
      final resultPath = '$resultDir/tom_project.yaml';

      // Load original
      final originalContent = File(inputPath).readAsStringSync();
      final yaml = loadYamlFile(inputPath);

      // Parse and serialize
      final project = TomProject.fromYaml('test_project', yaml);
      final resultYaml = project.toYaml();
      final resultContent = toYamlString(resultYaml);

      // Write result
      File(resultPath).writeAsStringSync(resultContent);

      // Compare content
      _compareYamlFiles(
        'tom_project.yaml',
        originalContent,
        resultContent,
        yaml,
        resultYaml,
      );
    });

    // The master document round-trips COMPACTED, not exactly, and that is the
    // model's contract rather than a defect. `TomProject.toYamlCompact` omits a
    // project's `cross-compilation`, `<mode>-mode-definitions` and `actions`
    // when they equal the workspace's; the read does not put them back, so a
    // project that inherited a block comes back with `null`.
    //
    // Making the read symmetric was considered and rejected. It would change
    // what `project.crossCompilation` answers for EVERY project in the
    // workspace — `null` today, the workspace's value afterwards — so anything
    // distinguishing "defines one" from "inherits one" would change behaviour,
    // and it would deepen the model's investment in a generated manifest the
    // workspace is moving away from consulting at all.
    //
    // So the assertion states the contract instead of an exactness the writer
    // never promised, and it is deliberately not "ignore these keys": a
    // compacted key is tolerated ONLY where the project's original value really
    // does equal the workspace's. A block dropped for any other reason still
    // fails, which is the loss this test exists to catch.
    test('tom_master.yaml round-trips modulo documented compaction', () {
      final inputPath = '$fixtureDir/tom_master.yaml';
      final resultPath = '$resultDir/tom_master.yaml';

      final yaml = loadYamlFile(inputPath);
      final master = TomMaster.fromYaml(yaml);
      final resultYaml = master.toYaml();
      File(resultPath).writeAsStringSync(toYamlString(resultYaml));

      final differences = <String>[];
      _deepCompare('', yaml, resultYaml, differences);
      final unexplained =
          differences.where((d) => !_isDocumentedCompaction(d, yaml)).toList();
      if (unexplained.isNotEmpty) {
        fail('tom_master.yaml has differences beyond the documented '
            'compaction:\n${unexplained.join('\n')}');
      }

      // And the compacted form is a FIXED POINT: reading the result back and
      // re-writing it changes nothing. Without this, a field dropped on every
      // pass would satisfy the tolerance above and never be noticed.
      final secondYaml = TomMaster.fromYaml(loadYamlFile(resultPath)).toYaml();
      final drift = <String>[];
      _deepCompare('', resultYaml, secondYaml, drift);
      expect(drift, isEmpty,
          reason: 'the compacted document is not stable under re-reading');
    });
  });
}

/// Compare YAML files by comparing their parsed structure.
void _compareYamlFiles(
  String fileName,
  String original,
  String result,
  Map<String, dynamic> originalYaml,
  Map<String, dynamic> resultYaml,
) {
  // Deep compare the maps
  final differences = <String>[];
  _deepCompare('', originalYaml, resultYaml, differences);

  if (differences.isNotEmpty) {
    final diffReport = differences.join('\n');
    fail('$fileName has differences:\n$diffReport');
  }
}

/// Recursively compare two maps and collect differences.
void _deepCompare(
  String path,
  dynamic original,
  dynamic result,
  List<String> differences,
) {
  if (original == null && result == null) return;

  if (original == null) {
    differences.add('$path: missing in original, present in result: $result');
    return;
  }

  if (result == null) {
    differences.add('$path: present in original ($original), missing in result');
    return;
  }

  if (original is Map && result is Map) {
    final allKeys = {...original.keys, ...result.keys};
    for (final key in allKeys) {
      final keyPath = path.isEmpty ? key.toString() : '$path.$key';
      _deepCompare(keyPath, original[key], result[key], differences);
    }
  } else if (original is List && result is List) {
    if (original.length != result.length) {
      differences.add(
        '$path: list length differs (original: ${original.length}, result: ${result.length})',
      );
      return;
    }
    for (var i = 0; i < original.length; i++) {
      _deepCompare('$path[$i]', original[i], result[i], differences);
    }
  } else if (original.runtimeType != result.runtimeType) {
    differences.add(
      '$path: type differs (original: ${original.runtimeType}, result: ${result.runtimeType})',
    );
  } else if (original != result) {
    differences.add('$path: value differs (original: $original, result: $result)');
  }
}

/// Whether a difference is the compaction `toYamlCompact` documents.
///
/// Tolerated only for `projects.<name>.<key>` where `<key>` is one of the three
/// the writer compacts, the difference is an omission (never a changed value),
/// and the project's ORIGINAL value equals the workspace-level value it was
/// compacted against. Anything else is a real loss.
bool _isDocumentedCompaction(String difference, Map<String, dynamic> original) {
  final colon = difference.indexOf(':');
  if (colon < 0) return false;
  final path = difference.substring(0, colon);
  if (!difference.substring(colon).contains('missing in result')) return false;

  final parts = path.split('.');
  if (parts.length != 3 || parts[0] != 'projects') return false;
  final projectName = parts[1];
  final key = parts[2];

  final projects = original['projects'];
  if (projects is! Map) return false;
  final project = projects[projectName];
  if (project is! Map) return false;

  dynamic workspaceValue;
  if (key == 'cross-compilation' || key == 'actions') {
    workspaceValue = original[key];
  } else if (key.endsWith('-mode-definitions')) {
    workspaceValue = original[key];
  } else {
    return false;
  }

  final projectValue = project[key];
  final same = <String>[];
  _deepCompare('', projectValue, workspaceValue, same);
  return same.isEmpty;
}
