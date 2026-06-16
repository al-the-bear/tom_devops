# Tom DevOps Samples

> Tom DevOps Samples is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this repository's license — see
> [`../LICENSE.md`](../LICENSE.md).

Runnable, article-grade sample projects for the Tom devops toolchain.

This folder is the **canonical home** for user-facing, runnable samples of the
[`tom_ai/devops`](../README.md) tools. Each sample is a self-contained Dart
package demonstrating one tool end to end, with one-concept-per-file examples
(inline `// expected output`), its own `example/run_all_examples.dart`, and an
article-grade README. The per-tool manuals live in each tool's own README (e.g.
[`tom_github_api`](../tom_github_api/), [`tom_build_kit`](../tom_build_kit/));
this tree is where you go to *run* something.

---

## Samples

Ordered from the flagship through the rest of the toolchain. Each row links to
the sample package; **planned** samples are forward references until their
project lands.

| # | Sample | Demonstrates |
| - | ------ | ------------ |
| 1 | [`tom_github_api_sample`](tom_github_api_sample/) *(flagship)* | The [`tom_github_api`](../tom_github_api/) REST client end to end: token auth, listing/creating issues, labels, comments, search, and workflow dispatch — offline by default via a mock transport, with opt-in live mode. |
| 2 | [`tom_build_kit_sample`](tom_build_kit_sample/) *(planned)* | Authoring a small build tool / pipeline with [`buildkit`](../tom_build_kit/) against a fixture workspace. |
| 3 | [`tom_test_kit_sample`](tom_test_kit_sample/) *(planned)* | The baseline → test → diff tracking workflow of [`testkit`](../tom_test_kit/) on a small fixture project. |
| 4 | [`tom_issue_kit_sample`](tom_issue_kit_sample/) *(planned)* | The issue create / analyze / verify flow of [`issuekit`](../tom_issue_kit/) against a mock backend. |
| 5 | [`tom_md2pdf_sample`](tom_md2pdf_sample/) *(planned)* | Converting Markdown to PDF with [`md2pdf`](../tom_md2pdf/) and to LaTeX/PDF with [`md2latex`](../tom_md2latex/). |
| 6 | [`tom_deploy_sample`](tom_deploy_sample/) *(planned)* | Modelling a deployment with [`tom_deploy`](../tom_deploy/) / [`tom_deploy_tools`](../tom_deploy_tools/) against a local target. |

> Sample 1 (`tom_github_api_sample`) is the confirmed flagship; samples 2–6 are
> planned and their links are forward references until each sample project is
> created.

---

## Running the samples

Each sample runs on its own from inside its package:

```bash
cd tom_github_api_sample
dart pub get
dart run example/run_all_examples.dart
```

To run the whole set as one smoke test, use the top-level aggregator. It runs
every sample's `example/run_all_examples.dart` in a subprocess and reports a
combined tally; samples that don't exist yet are reported as **PENDING**, not
failures:

```bash
dart run run_all_examples.dart
```

```
============================================================
Running all Tom devops samples
============================================================

- tom_github_api_sample ... PENDING (not created yet)
- tom_build_kit_sample ... PENDING (not created yet)
...
============================================================
Results: 0 passed, 0 failed, 6 pending
============================================================

No samples have been created yet — nothing to run.
```

A sample **registers** with the aggregator by appearing in the `_plannedSamples`
list in [`run_all_examples.dart`](run_all_examples.dart) — all six are
pre-registered and activate automatically once their package is created.

---

## Layout

```
tom_devops_samples/
├── README.md                 # this index
├── analysis_options.yaml     # shared lints; samples include ../analysis_options.yaml
├── run_all_examples.dart     # top-level aggregator (runs each sample as a subprocess)
├── pubspec.yaml              # aggregator package
└── <tool>_sample/            # one self-contained package per tool (added per its todo)
    ├── README.md
    ├── pubspec.yaml
    └── example/
        └── run_all_examples.dart
```

Each sample includes the shared lint rules with `include: ../analysis_options.yaml`.

---

## Other sample homes

DevOps samples live **here**. Samples for other parts of the Tom framework have
their own canonical homes — if you're looking for those:

| Domain | Canonical samples home |
| ------ | ---------------------- |
| D4rt interpreter & bridging | [`tom_ai/d4rt/tom_d4rt/example/`](../../d4rt/tom_d4rt/example/) |
| The devops tools themselves | each tool's own README under [`tom_ai/devops/`](../README.md) |

---

## Related

| Link | What's there |
| ---- | ------------ |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain and its samples learning path. |
