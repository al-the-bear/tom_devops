/// The directory names a workspace scan never descends into.
///
/// Shared by every scan in this package — the workspace analyzer that writes
/// `.tom_metadata/tom_master.yaml` and the file-object-model parser — because
/// the question "is this directory source?" has one answer and used to have
/// eight copies of it.
library;

/// Directory names the workspace scan never descends into.
///
/// Two kinds of thing, and neither is ever source: **generated output**
/// (`build`, `out`, `dist`, `node_modules`) and the workspace's **scratch
/// directory** (`ztmp`, which `CLAUDE.md` designates for temporary files and
/// `.gitignore` excludes). A project scaffolded under one of these is a
/// throwaway; registering it puts it in the committed
/// `.tom_metadata/tom_master.yaml` and in the generated build order, where two
/// agent scratch projects had already accumulated — one of them a copy of
/// another package carrying that package's own `name:`, so the metadata held
/// the same package twice under two keys.
///
/// Named **once**. The analyzer asked this question at seven places and each
/// spelled the list out for itself, which had already drifted: `build` was
/// skipped at only two of the seven, and `out` was missing from another. A
/// second copy of a rule is how the next entry gets added to only one of them.
const Set<String> scanExcludedDirectories = {
  'build',
  'node_modules',
  'out',
  'dist',
  'ztmp',
};

/// Whether a scan should skip a directory named [dirName].
///
/// Hidden directories (`.git`, `.dart_tool`, `.tom_metadata`) are excluded by
/// the same predicate rather than by a separate check at each site, so a caller
/// asks one question and gets the whole rule.
bool isScanExcludedDirectory(String dirName) =>
    dirName.startsWith('.') || scanExcludedDirectories.contains(dirName);
