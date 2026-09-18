import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';

/// Groups are DERIVED from where projects are, never copied from a curated list.
///
/// The `groups:` block of `tom_workspace.yaml` used to reach
/// `.tom_metadata/tom_master.yaml` verbatim — not by being named, but through
/// the analyzer's generic "copy every unrecognised top-level key" loop, which is
/// why grepping the analyzer for `groups` found nothing. A copied list rots in
/// both directions and regenerating the metadata does not fix it: you refresh,
/// the stale block comes through unchanged, and tooling that iterates by group
/// silently skips the projects nobody added. Measured before this was derived:
/// **6 phantom entries and 72 missing ones across 11 of the 20 groups.**
///
/// Deriving removes the staleness class rather than watching it: a list computed
/// from the project set on every scan cannot disagree with the project set.
///
/// The three exclusions each exist for a measured reason and are pinned below:
/// a project at the workspace root has no directory to be grouped by, and `_ai`,
/// `_doc` and `_scripts` hold quest scratch, documentation samples and the
/// workspace's own script project rather than shipped projects.
void main() {
  group('deriveProjectGroups', () {
    test('a tom_ai project is grouped by its subdirectory, not by tom_ai', () {
      final groups = deriveProjectGroups({
        'tom_specs_model': 'tom_ai/ai_build/tom_specs_model',
        'tom_build': 'tom_ai/devops/tom_build',
        'tom_build_kit': 'tom_ai/devops/tom_build_kit',
      });

      expect(groups.keys, containsAll(<String>['ai_build', 'devops']));
      expect(groups['ai_build'], equals(['tom_specs_model']));
      expect(groups['devops'], equals(['tom_build', 'tom_build_kit']));
      expect(groups.containsKey('tom_ai'), isFalse);
    });

    test('a top-level repository is its own group', () {
      final groups = deriveProjectGroups({
        'tom_specs_editor': 'tom_forge/tom_specs_editor',
        'tom_forge_core': 'tom_forge/tom_forge_core',
      });

      expect(groups['tom_forge'], equals(['tom_forge_core', 'tom_specs_editor']));
    });

    test('members are sorted, so a rescan cannot reorder the file', () {
      final groups = deriveProjectGroups({
        'zeta': 'tom_ai/basics/zeta',
        'alpha': 'tom_ai/basics/alpha',
        'mid': 'tom_ai/basics/mid',
      });

      expect(groups['basics'], equals(['alpha', 'mid', 'zeta']));
    });

    test('a project at the workspace root belongs to no group', () {
      // `_scripts` is the real case: its `project-folder` is empty, so the
      // first path segment is empty too and it would otherwise create a group
      // whose name is the empty string.
      final groups = deriveProjectGroups({
        '_scripts': '',
        'other': null,
        'real': 'tom_ai/basics/real',
      });

      expect(groups.keys, equals(<String>{'basics'}));
    });

    test('quest scratch, doc samples and the script project are not groups', () {
      final groups = deriveProjectGroups({
        'bench': '_ai/quests/tom_brain/bench',
        'dart_overview': '_doc/dart_reference/dart_overview',
        'script_thing': '_scripts/script_thing',
        'real': 'tom_ai/core/real',
      });

      expect(groups.keys, equals(<String>{'core'}));
    });

    test('a leading ./ is not part of the group name', () {
      final groups = deriveProjectGroups({
        'a': './tom_ai/cloud/a',
        'b': 'tom_ai/cloud/b',
      });

      expect(groups['cloud'], equals(['a', 'b']));
    });

    test('a project directly under tom_ai is grouped by its own directory', () {
      // Nothing lives there today, but the rule still has to answer. It answers
      // the same way `_bin/check_workspace_groups.py` did when it was the one
      // checking these lists: a group owns `tom_ai/<name>` when that directory
      // exists, so a project AT `tom_ai/odd` is the sole member of group `odd`.
      // Keeping the two rules identical is the point -- the derivation replaced
      // that gate, and a replacement that bucketed differently would silently
      // move projects between groups the day it landed.
      final groups = deriveProjectGroups({'odd': 'tom_ai/odd'});

      expect(groups['odd'], equals(['odd']));
      expect(groups.containsKey('tom_ai'), isFalse);
    });
  });
}
