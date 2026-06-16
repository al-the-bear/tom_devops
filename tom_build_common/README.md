# Tom Build Common

> Tom Build Common is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [LICENSE](LICENSE).

Shared build types and utilities for the Tom framework build tooling.

> **Status: reserved package.** `tom_build_common` is the *intended* home for
> types and helpers shared across the Tom build tools, but it is currently a
> placeholder — it ships only the default package scaffold and has no published
> shared API yet. The build types the tools use today live in
> [`tom_build`](../tom_build/) and [`tom_build_base`](../../basics/tom_build_base/).
> This README documents the package's role and tells you where the real code is,
> rather than dressing the placeholder up as a populated library.

---

## Overview

The Tom devops repository contains a family of build tools — the workspace
analyzer ([`tom_build`](../tom_build/)), the `tom` CLI
([`tom_build_cli`](../tom_build_cli/)), and the CLI kits
([`tom_build_kit`](../tom_build_kit/), [`tom_test_kit`](../tom_test_kit/),
[`tom_issue_kit`](../tom_issue_kit/)). As those tools grow, small types and
helpers naturally come to be shared between them. `tom_build_common` exists to
be the place that shared code lands, so a common type does not have to be
duplicated across tools or pulled in via a heavier dependency.

Right now that extraction has **not** happened: the shared build code still
lives where it was first written, and `tom_build_common` is an empty shell
waiting to receive it. Keeping the package in the tree (rather than creating it
later) means the dependency wiring and publishing slot already exist when the
first genuinely-shared type is ready to move.

### Where the shared build code lives today

| Concern | Current home |
| ------- | ------------ |
| Workspace model, file object model, analyzer, scripting helpers | [`tom_build`](../tom_build/) |
| CLI framework — arg parsing, help, traversal, pipelines, config | [`tom_build_base`](../../basics/tom_build_base/) (basics layer) |
| `tom` command surface, config merge, generation | [`tom_build_cli`](../tom_build_cli/) |
| Pipeline orchestration, git workflows | [`tom_build_kit`](../tom_build_kit/) |

When a type currently in one of those packages needs to be used by another
without taking on the whole dependency, that type is the candidate to move into
`tom_build_common`.

---

## Installation

`tom_build_common` is a **workspace-internal package** (`publish_to: none`). It
is not published to pub.dev — it lives inside the Tom devops repository and is
consumed in place by sibling packages. There is no `dart pub add
tom_build_common`, and you should **never** add a manual `path:` override to
reach it; a tool that needs it declares it as a workspace dependency.

```dart
import 'package:tom_build_common/tom_build_common.dart';
```

**SDK requirement:** Dart `^3.10.4`. The package has no runtime dependencies.

---

## Intended consumers

When populated, `tom_build_common` is expected to be depended on by the build
tools that need to share types:

| Package | Why it would consume `tom_build_common` |
| ------- | --------------------------------------- |
| [`tom_build`](../tom_build/) | Share workspace/build model types with the CLI and kits. |
| [`tom_build_cli`](../tom_build_cli/) | Reuse common types without re-declaring them. |
| [`tom_build_kit`](../tom_build_kit/) | Reuse shared pipeline/build primitives. |
| [`tom_test_kit`](../tom_test_kit/) / [`tom_issue_kit`](../tom_issue_kit/) | Reuse any cross-tool build types. |

No package depends on `tom_build_common` yet; the table records the design
intent, not current wiring.

---

## Current public surface

The package currently exposes only the default scaffold placeholder, kept so the
package builds, tests and analyzes cleanly until real shared types arrive:

```dart
import 'package:tom_build_common/tom_build_common.dart';

void main() {
  final awesome = Awesome();
  print(awesome.isAwesome); // true
}
```

`Awesome` is a placeholder from the package template and carries no build
meaning. It will be removed when the first real shared type lands here.

---

## Ecosystem

`tom_build_common` sits beside the other devops build packages as their shared
base. Today the arrows are dotted (intended), not solid (wired):

```
        tom_build_cli   tom_build_kit   tom_test_kit   tom_issue_kit
              ╎               ╎               ╎               ╎
              └───────────────┴───────┬───────┴───────────────┘
                                      ╎ (intended shared types)
                                      ▼
                            ┌──────────────────┐
                            │ tom_build_common │  ← you are here (reserved)
                            └──────────────────┘
                                      │ would sit alongside
                                      ▼
                                 tom_build
```

The shared CLI framework `tom_build_base` lives in the basics layer
([`tom_ai/basics/tom_build_base`](../../basics/tom_build_base/)); that is the
package to reach for when you need CLI plumbing, not `tom_build_common`.

---

## Related packages

Don't duplicate — follow the link:

| Package | Relationship |
| ------- | ------------ |
| [`tom_build`](../tom_build/) | Where the workspace/build model types live today. |
| [`tom_build_cli`](../tom_build_cli/) | The `tom` command built on `tom_build`. |
| [`tom_build_kit`](../tom_build_kit/) | The `buildkit` orchestrator. |
| [`tom_build_base`](../../basics/tom_build_base/) | The shared CLI / build framework (basics layer). |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 1.0.0 (`publish_to: none` — workspace-internal)
- **SDK:** Dart `^3.10.4`
- **Contents:** reserved placeholder — only the scaffold `Awesome` type and its
  single template test; no shared build API published yet.
- **Tests:** 1 (placeholder).

This README will grow into a full module manual — overview, feature tables,
quick start, usage and a key-types table — once `tom_build_common` holds real
shared build types.

---

## License

See [LICENSE](LICENSE); each package in this repository carries its own license
terms.
