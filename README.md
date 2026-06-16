# Tom DevOps — the build, test and release tooling of the Tom framework

> Tom DevOps is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in each package's own license — see
> [LICENSE.md](LICENSE.md).

The command-line toolchain that turns the Tom monorepo into something you can
build, test, ship and document with a single, consistent set of tools. Every
package here is a CLI tool (or the library behind one): the workspace analyzer
and build orchestrator, the test- and issue-tracking kits, the deployment
tooling, a GitHub REST client, and a pair of Markdown converters.

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
project — it walks the GitHub REST client end to end (authenticate, list and
create issues, read repos, list pull requests and releases) and runs offline by
default, so it is the gentlest on-ramp into the toolchain. From there, the
[samples learning path](#samples-learning-path) takes you tool by tool.

---

## What you can do with Tom DevOps

- **Understand your workspace** — scan every package, derive the dependency
  build order, and regenerate the workspace metadata (`tom_build`,
  `workspace_analyzer`).
- **Drive the whole repo from one command** — the `tom` CLI and the `buildkit`
  orchestrator run cleanup, versioning, compilation, dependency resolution,
  publishing and git workflows as composable pipelines.
- **Track tests over time** — capture a baseline, re-run, and diff results to
  catch regressions and confirm fixes (`testkit`).
- **Manage issues from the terminal** — create, analyze, assign and verify
  issues, linking them to the tests that prove them fixed (`issuekit`).
- **Talk to GitHub** — a typed REST client for issues, repos, pull requests and
  releases (`tom_github_api`), the backbone of `issuekit`.
- **Ship to the cloud** — model and execute multi-target deployments
  (`tom_deploy`, `tom_deploy_tools`).
- **Turn Markdown into documents** — convert Markdown to LaTeX/PDF
  (`md2latex`) or straight to PDF (`md2pdf`).

---

## How the packages fit together

Tom DevOps splits into five concern areas. Read this framing before the
component tables so the inventory makes sense:

- **Build framework** — the workspace analyzer (`tom_build`), the `tom` CLI
  surface (`tom_build_cli`), and the shared build types they sit on
  (`tom_build_common`). These understand the monorepo's shape and order.
- **CLI kits** — the day-to-day developer tools: build orchestration
  (`tom_build_kit`), test tracking (`tom_test_kit`) and issue tracking
  (`tom_issue_kit`). Each is a standalone command driven by `tom_build_base`.
- **Deployment** — the multi-cloud deployment model (`tom_deploy`) and its CLI
  front end (`tom_deploy_tools`).
- **Integrations** — third-party service clients; today the GitHub REST client
  (`tom_github_api`) that `issuekit` builds on.
- **Doc conversion** — Markdown-to-document converters (`tom_md2latex`,
  `tom_md2pdf`) used to produce reference PDFs from the workspace's docs.

```
                    ┌──────────────────────────────────┐
                    │   tom_build_base (basics layer)   │
                    │   CLI framework: args, help,      │
                    │   traversal, pipelines, config    │
                    └─────────────────┬─────────────────┘
                                      │ every tool builds on it
   ┌───────────────┬──────────────────┼───────────────┬───────────────┐
   │               │                  │               │               │
┌──┴───────────┐ ┌─┴──────────────┐ ┌─┴───────────┐ ┌─┴───────────┐ ┌─┴───────────┐
│ Build        │ │ CLI kits       │ │ Deployment  │ │ Integrations│ │ Doc         │
│ framework    │ │ tom_build_kit  │ │ tom_deploy  │ │ tom_github_ │ │ conversion  │
│ tom_build    │ │ tom_test_kit   │ │ tom_deploy_ │ │  api        │ │ tom_md2latex│
│ tom_build_cli│ │ tom_issue_kit  │ │  tools      │ │     ▲       │ │ tom_md2pdf  │
│ tom_build_   │ │      │         │ │             │ │     │ used  │ │             │
│  common      │ │      └─────────┼─┼─────────────┼─┘ by issuekit │ │             │
└──────────────┘ └────────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

---

## Components

Every package appears in exactly one row below, linked to its own README. The
**Binary** column lists the command(s) each package installs; library-only
packages show `—`.

### Build framework

| Package | What it is | Binary |
| ------- | ---------- | ------ |
| [`tom_build`](tom_build/) | Build tools and workspace analyzer — scans the workspace, detects natures, derives build order and regenerates metadata. | `workspace_analyzer` |
| [`tom_build_cli`](tom_build_cli/) | The `tom` command surface; dispatches between Tom command mode and TomD4rt scripting. | `tom` |
| [`tom_build_common`](tom_build_common/) | Shared build types and utilities consumed by the build tools and kits. | — |

### CLI kits

| Package | What it is | Binary |
| ------- | ---------- | ------ |
| [`tom_build_kit`](tom_build_kit/) | Build orchestration with pipelines — cleanup, versioning, compile, dependencies, publish and git workflows. | `buildkit`, `findproject` |
| [`tom_test_kit`](tom_test_kit/) | Test result tracking — baseline / test / diff workflow with an optional TUI. | `testkit` |
| [`tom_issue_kit`](tom_issue_kit/) | Issue tracking CLI — create, analyze, assign and verify issues with test linkage. | `issuekit` |

### Deployment

| Package | What it is | Binary |
| ------- | ---------- | ------ |
| [`tom_deploy`](tom_deploy/) | Multi-cloud deployment model for server and web applications. | — |
| [`tom_deploy_tools`](tom_deploy_tools/) | Command-line front end that drives `tom_deploy` deployments. | `tom_deploy_tools` |

### Integrations

| Package | What it is | Binary |
| ------- | ---------- | ------ |
| [`tom_github_api`](tom_github_api/) | Typed GitHub REST client — auth, issues, repos, pull requests, releases; backs `issuekit`. | — |

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
  tom_build_kit: ^1.7.1
```

```bash
dart pub add tom_build_kit
```

Most tools are run as commands. Activate one and invoke it from any package in
the workspace:

```bash
dart pub global activate tom_build_kit
buildkit :test          # run a tracked test pipeline across the workspace
testkit :baseline       # capture a fresh test baseline for the current package
issuekit :list          # list open issues for the current repository
```

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
| 3 | [`tom_test_kit_sample`](tom_devops_samples/tom_test_kit_sample/) | The baseline → test → diff tracking workflow on a small fixture project. |
| 4 | [`tom_issue_kit_sample`](tom_devops_samples/tom_issue_kit_sample/) | The issue create / analyze / verify flow against a mock backend. |
| 5 | [`tom_md2pdf_sample`](tom_devops_samples/tom_md2pdf_sample/) | Converting Markdown to PDF (md2pdf) and LaTeX/PDF (md2latex). |
| 6 | [`tom_deploy_sample`](tom_devops_samples/tom_deploy_sample/) | Modelling a deployment with `tom_deploy` / `tom_deploy_tools` against a local target. |

> Sample 1 (`tom_github_api_sample`) is the confirmed flagship; samples 2–6 are
> planned and their links are forward references until each sample project
> lands.

---

## Documentation index

In-package guides beyond the package READMEs:

| Topic | Document |
| ----- | -------- |
| Workspace analyzer + tooling reference | [`tom_build/doc/tom_user_reference.md`](tom_build/doc/tom_user_reference.md) |
| Tool specification | [`tom_build/doc/tom_tool_specification.md`](tom_build/doc/tom_tool_specification.md) |
| `tom` CLI usage | [`tom_build_cli/doc/tom_cli_usage.md`](tom_build_cli/doc/tom_cli_usage.md) |
| buildkit — user guide | [`tom_build_kit/doc/buildkit_user_guide.md`](tom_build_kit/doc/buildkit_user_guide.md) |
| buildkit — tools user guide | [`tom_build_kit/doc/tools_user_guide.md`](tom_build_kit/doc/tools_user_guide.md) |
| buildkit — git guide mode | [`tom_build_kit/doc/git_guide_mode.md`](tom_build_kit/doc/git_guide_mode.md) |
| testkit — test tracking | [`tom_test_kit/doc/test_tracking.md`](tom_test_kit/doc/test_tracking.md) |
| testkit — TUI | [`tom_test_kit/doc/tom_test_tui.md`](tom_test_kit/doc/tom_test_tui.md) |
| issuekit — command reference | [`tom_issue_kit/doc/issuekit_command_reference.md`](tom_issue_kit/doc/issuekit_command_reference.md) |
| issuekit — issue tracking | [`tom_issue_kit/doc/issue_tracking.md`](tom_issue_kit/doc/issue_tracking.md) |
| GitHub API specification | [`tom_github_api/doc/github_api_specification.md`](tom_github_api/doc/github_api_specification.md) |

---

## Repository layout

```
tom_ai/devops/
├── README.md                 # this map
├── LICENSE.md                # per-package licensing note
├── analysis_options.yaml     # shared analyzer settings
│
├── tom_build/                # workspace analyzer + build-order/metadata (build framework)
│   └── doc/                  # analyzer + tooling references
├── tom_build_cli/            # the `tom` command surface + TomD4rt mode
│   └── doc/                  # tom CLI usage
├── tom_build_common/         # shared build types/utilities
│
├── tom_build_kit/            # buildkit orchestrator + pipelines (CLI kit)
│   └── doc/                  # buildkit + tools guides
├── tom_test_kit/             # testkit — baseline/test/diff tracking (CLI kit)
│   └── doc/                  # test tracking + TUI
├── tom_issue_kit/            # issuekit — issue lifecycle + test linkage (CLI kit)
│   └── doc/                  # issuekit references
│
├── tom_deploy/               # multi-cloud deployment model
├── tom_deploy_tools/         # tom_deploy_tools CLI front end
│
├── tom_github_api/           # GitHub REST client (backs issuekit)
│   └── doc/                  # GitHub API specification
│
├── tom_md2latex/             # Markdown → LaTeX → PDF converter
├── tom_md2pdf/               # Markdown → PDF converter (htmltopdfwidgets)
│
└── tom_devops_samples/       # runnable, article-grade sample projects
```

The CLI framework these tools share — `tom_build_base` — lives one repo over in
[`tom_ai/basics`](../basics/README.md), not here.

---

## License

See [LICENSE.md](LICENSE.md); each package carries its own license terms.
