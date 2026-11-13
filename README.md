# Tom DevOps — the build, test and release tooling of the Tom framework

> Tom DevOps is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in each package's own license — see
> [LICENSE.md](LICENSE.md).

The command-line toolchain that turns the Tom monorepo into something you can
build, test, ship and document with a single, consistent set of tools. Every
package here is a CLI tool (or the library behind one): the test- and
issue-tracking kits, the fuzzing harness, the deployment tooling and a pair of
Markdown converters. The build orchestrator, `buildkit`, and the GitHub REST
client live in the basics layer.

**This document is the map.** It orients you to the whole `tom_ai/devops`
repository and routes you to the one tool you actually need — each package
carries its own README with the full manual, and the runnable samples live in
[`tom_devops_samples/`](tom_devops_samples/). Depth lives downstream; this page
is just the index.

> Every CLI tool here is built on **`tom_build_base`** — the unified CLI / build
> framework that provides argument parsing, help formatting, workspace
> traversal and pipelines. `tom_build_base` is **not** in this repo; it lives in
> the basics layer at [`tom_ai/basics/tom_build_base`](../basics/tom_build_base/).
> See the [basics repository map](../basics/README.md) for the framework itself.

---

## New here?

Start with the **[`tom_github_api_sample`](tom_devops_samples/tom_github_api_sample/)**
project — it walks the GitHub API client
([`tom_github_api`](../basics/tom_github_api/), in the basics layer) end to end
(authenticate, list and create issues, read repos, list pull requests and
releases) and runs offline by default, so it is the gentlest on-ramp into the
toolchain. From there, the
[samples learning path](#samples-learning-path) takes you tool by tool.

---

## What you can do with Tom DevOps

- **Build the whole repo** — cleanup, versioning, compilation, dependency
  resolution, publishing and git workflows as composable pipelines are
  `buildkit`'s, in the [basics layer](../basics/tom_build_kit/).
- **Track tests over time** — capture a baseline, re-run, and diff results to
  catch regressions and confirm fixes (`testkit`).
- **Manage issues from the terminal** — create, analyze, assign and verify
  issues, linking them to the tests that prove them fixed (`issuekit`).
- **Talk to GitHub** — `issuekit` and the samples use the typed GitHub API
  client [`tom_github_api`](../basics/tom_github_api/), which lives in the
  basics layer beside git in pure Dart ([`tom_git`](../basics/tom_git/)).
- **Ship to the cloud** — model and execute multi-target deployments
  (`tom_deploy`, `tom_deploy_tools`).
- **Turn Markdown into documents** — convert Markdown to LaTeX/PDF
  (`md2latex`) or straight to PDF (`md2pdf`).

---

## How the packages fit together

Tom DevOps splits into three concern areas. Read this framing before the
component tables so the inventory makes sense:

- **CLI kits** — the day-to-day developer tools: test tracking
  (`tom_test_kit`) and issue tracking (`tom_issue_kit`). Each is a standalone
  command driven by `tom_build_base`. The build orchestrator itself —
  `buildkit` (`tom_build_kit`) — now lives in the basics layer alongside its
  framework; see [`tom_ai/basics/tom_build_kit`](../basics/tom_build_kit/).
- **Deployment** — the multi-cloud deployment model (`tom_deploy`) and its CLI
  front end (`tom_deploy_tools`).
- **Doc conversion** — Markdown-to-document converters (`tom_md2latex`,
  `tom_md2pdf`) used to produce reference PDFs from the workspace's docs.

The repository also keeps the archived packages of the old build stack
(`tom_build`, its CLI and `tom_build_common`): code only, skipped by every tool
and not maintained. What they were is described in the tom_deploy quest's
`archived_tom_build_stack/README.md`.

```
                    ┌──────────────────────────────────┐
                    │   tom_build_base (basics layer)   │
                    │   CLI framework: args, help,      │
                    │   traversal, pipelines, config    │
                    └─────────────────┬─────────────────┘
                                      │ every tool builds on it
             ┌────────────────────────┼─────────────────┐
             │                        │                 │
    ┌────────┴───────┐         ┌──────┴──────┐   ┌──────┴──────┐
    │ CLI kits       │         │ Deployment  │   │ Doc         │
    │ tom_test_kit   │         │ tom_deploy  │   │ conversion  │
    │ tom_issue_kit  │         │ tom_deploy_ │   │ tom_md2latex│
    │ tom_fuzz       │         │  tools      │   │ tom_md2pdf  │
    └────────────────┘         └─────────────┘   └─────────────┘
```

---

## Components

Every package appears in exactly one row below, linked to its own README. The
**Binary** column lists the command(s) each package installs; library-only
packages show `—`.

### CLI kits

| Package | What it is | Binary |
| ------- | ---------- | ------ |
| [`tom_test_kit`](tom_test_kit/) | Test result tracking — baseline / test / diff workflow with an optional TUI. | `testkit` |
| [`tom_issue_kit`](tom_issue_kit/) | Issue tracking CLI — create, analyze, assign and verify issues with test linkage. | `issuekit` |
| [`tom_fuzz`](tom_fuzz/) | Fuzzing harness for parsers of untrusted input — seeded mutation, crash/timeout/memory detection, replayable failures; campaigns run by `testkit :fuzz`. | — (library) |

### Deployment

| Package | What it is | Binary |
| ------- | ---------- | ------ |
| [`tom_deploy`](tom_deploy/) | Multi-cloud deployment model for server and web applications. | — |
| [`tom_deploy_tools`](tom_deploy_tools/) | Command-line front end that drives `tom_deploy` deployments. | `tom_deploy_tools` |

### Doc conversion

| Package | What it is | Binary |
| ------- | ---------- | ------ |
| [`tom_md2latex`](tom_md2latex/) | Markdown → LaTeX converter with PDF output (xelatex). | `md_latex_converter` |
| [`tom_md2pdf`](tom_md2pdf/) | Markdown → PDF converter via htmltopdfwidgets (no system LaTeX needed). | `md_pdf_converter` |

---

## Getting started

Add the package you need with its hosted version constraint (never a path
override):

```yaml
dependencies:
  tom_test_kit: ^0.1.0
```

```bash
dart pub add tom_test_kit
```

Most tools are run as commands. Activate one and invoke it from any package in
the workspace:

```bash
dart pub global activate tom_test_kit
testkit :baseline       # capture a fresh test baseline for the current package
issuekit :list          # list open issues for the current repository
```

> The `buildkit` orchestrator moved to the basics layer — see its quick-start in
> [`tom_ai/basics/tom_build_kit`](../basics/tom_build_kit/).

Each package README opens with its own runnable quick-start — follow the link
from the component tables above.

---

## Samples learning path

Runnable, article-grade sample projects live in
[`tom_devops_samples/`](tom_devops_samples/), one self-contained Dart package
each. Ordered from first contact to advanced toolchain use:

| # | Sample | Demonstrates |
| - | ------ | ------------ |
| 1 | [`tom_github_api_sample`](tom_devops_samples/tom_github_api_sample/) | The GitHub REST client end to end: auth, issues, repos, PRs, releases (offline by default). |
| 2 | [`tom_build_kit_sample`](tom_devops_samples/tom_build_kit_sample/) | Authoring a small build tool / pipeline with buildkit against a fixture workspace. |
| 3 | `tom_test_kit_sample` *(planned)* | The baseline → test → diff tracking workflow on a small fixture project. |
| 4 | `tom_issue_kit_sample` *(planned)* | The issue create / analyze / verify flow against a mock backend. |
| 5 | `tom_md2pdf_sample` *(planned)* | Converting Markdown to PDF (md2pdf) and LaTeX/PDF (md2latex). |
| 6 | `tom_deploy_sample` *(planned)* | Modelling a deployment with `tom_deploy` / `tom_deploy_tools` against a local target. |

> Sample 1 (`tom_github_api_sample`) is the confirmed flagship; samples 2–6 are
> planned and their links are forward references until each sample project
> lands.

---

## Documentation index

In-package guides beyond the package READMEs:

| Topic | Document |
| ----- | -------- |
| testkit — test tracking | [`tom_test_kit/doc/test_tracking.md`](tom_test_kit/doc/test_tracking.md) |
| testkit — TUI | [`tom_test_kit/doc/tom_test_tui.md`](tom_test_kit/doc/tom_test_tui.md) |
| issuekit — command reference | [`tom_issue_kit/doc/issuekit_command_reference.md`](tom_issue_kit/doc/issuekit_command_reference.md) |
| issuekit — issue tracking | [`tom_issue_kit/doc/issue_tracking.md`](tom_issue_kit/doc/issue_tracking.md) |

---

## Repository layout

```
tom_ai/devops/
├── README.md                 # this map
├── LICENSE.md                # per-package licensing note
├── analysis_options.yaml     # shared analyzer settings
│
├── tom_test_kit/             # testkit — baseline/test/diff tracking (CLI kit)
│   └── doc/                  # test tracking + TUI
├── tom_issue_kit/            # issuekit — issue lifecycle + test linkage (CLI kit)
│   └── doc/                  # issuekit references
│
├── tom_deploy/               # multi-cloud deployment model
├── tom_deploy_tools/         # tom_deploy_tools CLI front end
│
├── tom_md2latex/             # Markdown → LaTeX → PDF converter
├── tom_md2pdf/               # Markdown → PDF converter (htmltopdfwidgets)
│
├── tom_devops_samples/       # runnable, article-grade sample projects
│
└── tom_build/, tom_build_*/  # archived: the old build stack (kept, skipped by every tool)
```

The CLI framework these tools share — `tom_build_base` — lives one repo over in
[`tom_ai/basics`](../basics/README.md), not here.

---

## License

See [LICENSE.md](LICENSE.md); each package carries its own license terms.
