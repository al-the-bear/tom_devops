/// Bridge generator script for tom_build package.
///
/// Run with: dart run tool/generate_bridges.dart
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_d4rt_generator/tom_d4rt_generator.dart';

void main() async {
  print('Generating D4rt bridges for tom_build...');
  print('');

  final projectDir = Directory.current.path;
  
  // Verify we're in the tom_build directory
  if (!File(p.join(projectDir, 'pubspec.yaml')).existsSync()) {
    print('Error: Must run from tom_build directory');
    exit(1);
  }

  final generator = BridgeGenerator(
    workspacePath: projectDir,
    skipPrivate: true,
    helpersImport: 'package:tom_d4rt/tom_d4rt.dart',
    sourceImport: 'tom_build.dart',
    packageName: 'tom_build',
    verbose: true,
  );

  // Generate from the barrel file
  final barrelFile = p.join(projectDir, 'lib', 'tom_build.dart');
  final outputPath = p.join(projectDir, 'lib', 'src', 'd4rt_bridges', 'tom_build_bridges.dart');

  print('Barrel file: $barrelFile');
  print('Output path: $outputPath');
  print('');

  try {
    final result = await generator.generateBridgesFromExports(
      barrelFiles: [barrelFile],
      outputPath: outputPath,
      moduleName: 'all',
      excludePatterns: [
        '_bridge.dart',
        '_generated.dart',
        'bridge_generator.dart',
        'd4rt_helpers.dart',
      ],
      excludeClasses: [
        'BridgeGenerator',
        'ExternalTypeWarning',
        'ExportInfo',
      ],
    );

    print('');
    print('Generation complete:');
    print('  Classes: ${result.classesGenerated}');
    print('  Functions: ${result.globalFunctionsGenerated}');
    print('  Variables: ${result.globalVariablesGenerated}');
    print('  Output files: ${result.outputFiles.length}');
    
    if (result.errors.isNotEmpty) {
      print('');
      print('Errors:');
      for (final error in result.errors) {
        print('  - $error');
      }
    }
    
    if (result.warnings.isNotEmpty) {
      print('');
      print('Warnings: ${result.warnings.length}');
    }
    
    print('');
    print('✓ Successfully generated: $outputPath');
  } catch (e, stack) {
    print('Error generating bridges: $e');
    print(stack);
    exit(1);
  }
}
