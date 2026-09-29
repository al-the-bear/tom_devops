## 1.2.0

### Fixed — options written after the command name were ignored (scf13)

tom_build_base's parser routes an option by position: before the command name
into `CliArgs.extraOptions`, after it into that command's own options. Every
executor read only `extraOptions`, so all 27 issuekit options were silently
dropped in the TRAILING position — the form the help and the workspace docs
use. `issuekit :list --state closed` listed every state, and
`issuekit :new "Title" --severity high` filed at the default severity.

All 18 read sites now go through `CliArgs.optionsFor(<command>)`
(tom_build_base >= 2.13.0), which merges both positions with the per-command
value winning, as testkit and buildkit already do.

## 1.1.0

### Fixed — issuekit declared it had no dry-run mode, while implementing one

`NavigationFeatures.dryRun` was false, but every executor checks `args.dryRun`
and returns a preview instead of writing -- seventeen call sites, covered by
tests such as `IK-INT-VAL-5: --fix --dry-run does not modify files`. The
declaration was simply wrong.

That became load-bearing in tom_build_base 2.12.0, which refuses `-n` for a
tool declaring `dryRun: false` and stops advertising the flag in its help. With
the old declaration, issuekit's working dry-run would have been rejected.

Requires tom_build_base >=2.12.0.

## 1.0.0

- Initial version.
