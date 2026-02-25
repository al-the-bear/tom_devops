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

    test('tom_master.yaml exact round-trip', () {
      final inputPath = '$fixtureDir/tom_master.yaml';
      final resultPath = '$resultDir/tom_master.yaml';

      // Load original
      final originalContent = File(inputPath).readAsStringSync();
      final yaml = loadYamlFile(inputPath);

      // Parse and serialize
      final master = TomMaster.fromYaml(yaml);
      final resultYaml = master.toYaml();
      final resultContent = toYamlString(resultYaml);

      // Write result
      File(resultPath).writeAsStringSync(resultContent);

      // Compare content
      _compareYamlFiles(
        'tom_master.yaml',
        originalContent,
        resultContent,
        yaml,
        resultYaml,
      );
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
