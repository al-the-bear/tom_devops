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
