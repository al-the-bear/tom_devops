## 1.4.6

### Fixed — the commands print what they report

The commands that visit no projects (`:list`, `:show`, `:search`, `:summary`,
`:init`, ...) put their output into the messages of their results, and the
shared run summary prints only skips, failures and a footer: `issuekit :list`
printed "Done. No errors." over a repository with issues. Every executor now
prints the messages of its successful results, in order; an empty `:list` or
`:search` prints `No issues match.`

## 1.4.5

### Fixed — `issuekit help <command>` for a wired nested command

On tom_build_base 2.38.1: `issuekit help <nested command>` prints the help
of a wired nested command, taken from its nested tool, instead of
`Unknown help topic`.

## 1.4.4

### Fixed — `issuekit help <command>` prints the command's help

On tom_build_base 2.38.0: `issuekit help <command>` (also `help :<command>`, an
alias or an unambiguous prefix) prints the same help as
`issuekit :<command> --help` instead of `Unknown help topic`.

## 1.4.3

### Changed — no escape codes in piped output

On tom_build_base 2.37.0: issuekit styles its output only on a terminal. Piped or
redirected output, and any output under `NO_COLOR`, is plain text with the
markdown markers removed; `FORCE_COLOR=1` styles a pipe.

## 1.4.2

### Changed — a one-value option given twice is refused

On tom_build_base 2.36.0: `issuekit -s a -s b` (and any other option that takes
one value, given twice) stops with an error naming the option and both values,
instead of keeping the last value without a word. Several scan roots are
written once, comma-separated: `issuekit -s a,b`.

## 1.4.1

### Fixed — `navigation: exclude` on Windows

On tom_build_base 2.35.2: on Windows issuekit walked the projects
`buildkit_master.yaml` excludes (the forks under `xternal/`, `ai_build/`, ...),
because the path filters compared Windows paths with `/` patterns.

## 1.4.0

### Changed — the project id comes from `buildkit.yaml`

`IssueKitConfig.loadProject` reads `project_id` and `name` from the project's
`buildkit.yaml` (tom_build_base ^2.25.0, the one project file); `tom_project.yaml`
is not read any more. The hand-written YAML parser it used is gone (package:yaml
reads the file). IK-CFG-18, IK-CFG-22.

## 1.3.0

### Changed — configuration in `buildkit_master.yaml`, workspace by its marker

- The workspace is `TOM_WORKSPACE_ROOT` when set, else the nearest directory
  holding `buildkit_master.yaml` (tom_build_base `>=2.23.0`), else the current
  directory (`IssueKitConfig.workspaceRootFor`); before, it was the current
  directory unless the variable was set.
- The workspace settings are read from the `issuekit:` section of
  `buildkit_master.yaml` (`issue_tracking:`, `github_auth:`), with package:yaml.
  `tom_workspace.yaml` is no longer read; it never held an `issue_tracking`
  section, so nothing moves. Tests IK-CFG-17, IK-CFG-20, IK-CFG-21 (renumbered
  in 1.4.0; they were released as IK-CFG-19 and -20, which collided).

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
