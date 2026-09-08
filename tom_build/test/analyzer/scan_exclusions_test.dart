import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';
import 'package:yaml/yaml.dart';

/// The directories the workspace scan must never descend into, and the rule
/// that they are named in exactly one place.
///
/// `ztmp/` is the workspace's designated scratch directory (`CLAUDE.md`: "any
/// temporary file must go to `<workspace-root>/ztmp`") and is gitignored. The
/// analyzer scanned it anyway, so a throwaway project an agent session
/// scaffolded there was registered as a real workspace project in
/// `.tom_metadata/tom_master.yaml` — which *is* committed — and reached the
/// generated build order. Two such projects had accumulated, one of them a copy
/// of `tom_d4rt_exec` carrying that pubspec name, so the metadata held the same
/// package twice under two keys.
///
/// The second test is the one that keeps this fixed. The skip list was written
/// out at seven sites in the analyzer and had already drifted — `build` was
/// skipped at two of them and `out` missing from another — which is how the
/// next entry gets added to only some of them.
void main() {
  group('scan exclusions', () {
    test('a project under ztmp/ is not registered', () async {
      final root = Directory.systemTemp.createTempSync('tom_build_ztmp_');
      addTearDown(() {
        if (root.existsSync()) root.deleteSync(recursive: true);
      });

      // The recursive discovery that reaches a NESTED project runs only for a
      // single-root `.code-workspace` — which is the real workspace's shape,
      // and without it this fixture cannot reproduce the defect at all.
      File(
        p.join(root.path, 'fixture.code-workspace'),
      ).writeAsStringSync('{"folders": [{"path": "."}]}');

      // A nested project that must be found, so the walk is shown to reach this
      // depth: without it, "not registered" would pass for the wrong reason.
      _writePackage(p.join(root.path, 'nested', 'real_proj'), 'real_proj');
      // The same shape under each excluded directory.
      _writePackage(p.join(root.path, 'ztmp', 'scratch_proj'), 'scratch_proj');
      _writePackage(p.join(root.path, 'build', 'built_proj'), 'built_proj');

      await WorkspaceAnalyzer(root.path).analyze();

      final master =
          loadYaml(
                File(
                  p.join(root.path, '.tom_metadata', 'tom_master.yaml'),
                ).readAsStringSync(),
              )
              as YamlMap;
      final projects = (master['projects'] as YamlMap).keys.cast<String>();

      expect(projects, contains('real_proj'));
      expect(
        projects,
        isNot(contains('scratch_proj')),
        reason:
            'ztmp/ is gitignored scratch and must not reach the '
            'committed metadata',
      );
      expect(projects, isNot(contains('built_proj')));
    });

    test('the excluded set is named once, not once per scan site', () {
      // Every scan site must ask [isScanExcludedDirectory]. A site that spells
      // the list out again is what let `build` and `out` drift apart across the
      // eight copies this replaced, so the guard is over the SOURCE: a new
      // comparison against one of these names is the shape of the regression.
      const scanFiles = [
        'lib/src/analyzer/workspace_analyzer.dart',
        'lib/src/tom/file_object_model/workspace_parser.dart',
      ];
      final offenders = <String, List<String>>{};
      for (final rel in scanFiles) {
        final file = File(p.join(Directory.current.path, rel));
        expect(
          file.existsSync(),
          isTrue,
          reason: '$rel moved; this guard now checks nothing',
        );
        final literals = RegExp(
          r"==\s*'(node_modules|build|out|dist|ztmp)'",
        ).allMatches(file.readAsStringSync()).map((m) => m.group(0)!).toList();
        if (literals.isNotEmpty) offenders[rel] = literals;
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'excluded directory names belong in scanExcludedDirectories, '
            'not in a scan site',
      );
    });

    test('the excluded set covers scratch and generated output', () {
      expect(
        scanExcludedDirectories,
        containsAll(<String>['build', 'node_modules', 'out', 'dist', 'ztmp']),
      );
      expect(isScanExcludedDirectory('ztmp'), isTrue);
      expect(
        isScanExcludedDirectory('.git'),
        isTrue,
        reason: 'hidden directories are excluded by the same predicate',
      );
      expect(isScanExcludedDirectory('lib'), isFalse);
    });
  });
}

void _writePackage(String dir, String name) {
  Directory(dir).createSync(recursive: true);
  File(p.join(dir, 'pubspec.yaml')).writeAsStringSync('''
name: $name
description: A fixture package.
environment:
  sdk: ^3.0.0
''');
}
