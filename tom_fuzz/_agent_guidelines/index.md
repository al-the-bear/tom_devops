# Tom Fuzz — guidelines

- Tests: `testkit :test` from the package root; IDs and what each covers: `doc/test_coverage.md`.
- Fixture targets must stay top-level functions: the fuzzer runs targets in a worker isolate.
- The short mode (`fuzzTest`) must stay fast and deterministic: a fixed seed and a few hundred inputs.
- Campaigns are started by a person (`dart run fuzz/<name>_fuzz.dart`, `testkit :fuzz`); never schedule one.
- Releases go to pub.dev through `_bin/publishing/publish_staged.sh` from the container root.
