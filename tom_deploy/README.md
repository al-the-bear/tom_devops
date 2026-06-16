# Tom Deploy

> Tom Deploy is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [LICENSE](LICENSE).

Multi-cloud deployment model for Tom framework server and web applications.

> **Status: reserved package.** `tom_deploy` is the *intended* home for the
> Tom framework's unified, multi-cloud deployment **model** — the
> platform-agnostic types and orchestration that a deployment CLI drives. It is
> currently a **placeholder**: it ships only the default package scaffold and
> has no published deployment API yet. The deployment *knowledge* the framework
> relies on today lives in the workspace cloud guidelines (see
> [Where deployment lives today](#where-deployment-lives-today)). This README
> documents the package's role and points you at the real material rather than
> dressing the placeholder up as a populated library.

---

## Overview

The Tom devops repository carries a family of build and shipping tools. Once an
application has been built, it has to be **deployed** — to a cloud server, a
static web host, or both at once. `tom_deploy` is the reserved home for the
piece that models that step: a single, platform-agnostic deployment model that
can target the major clouds with one consistent configuration.

The design intent (captured in the `tom_deploy` quest) is a clean split between
**model** and **front end**:

| Package | Role |
| ------- | ---- |
| **`tom_deploy`** (this package) | The deployment **model** — platform-agnostic types describing *what* to deploy (server app, web client, full-stack), *where* (AWS, Azure, GCP, Firebase), and the orchestration that executes a deployment. Meant to be consumable programmatically so other tools (e.g. `tom_provisioning`) can drive deployments. |
| [`tom_deploy_tools`](../tom_deploy_tools/) | The command-line **front end** that drives `tom_deploy`: parses deployment configuration, selects the target platform, and runs the model's orchestration. |

Keeping the model separate from the CLI means the same deployment logic can be
invoked from a terminal, from CI/CD, or from a running application — without
re-implementing it per entry point.

Right now that extraction has **not** happened: `tom_deploy` is an empty shell
and `tom_deploy_tools` is a matching CLI stub. Keeping both packages in the tree
means the dependency wiring and (workspace-internal) publishing slots already
exist when the first real deployment type is ready to land.

### Intended platform and application coverage

When populated, the model is intended to cover:

- **Target platforms** — Amazon Web Services (AWS), Microsoft Azure, Google
  Cloud Platform (GCP), and Firebase, with room for additional platforms behind
  a plugin-style boundary.
- **Application types** — Dart standalone **server** apps, Flutter-web / static
  **web** clients, and coordinated **full-stack** (server + client) deployments.
- **Build integration** — compilable to a native executable with minimal
  dependencies, so it runs cleanly inside cloud build / CI environments.

This list records the design target, not shipped behaviour.

---

## Where deployment lives today

Until the model is implemented here, the framework's deployment knowledge lives
in the workspace-root **cloud guidelines** under `_copilot_guidelines/cloud/`:

| Concern | Current home |
| ------- | ------------ |
| Cloud deployment patterns (AWS / Azure / GCP / Firebase) | `_copilot_guidelines/cloud/cloud_deployment.md` |
| Production & dev Docker images | `_copilot_guidelines/cloud/docker_image_creation.md` |
| Running server apps locally with Docker | `_copilot_guidelines/cloud/docker_local.md` |
| Deployment model objectives & scope | `_ai/quests/tom_deploy/overview.tom_deploy.md` |

When a deployment concept currently captured only as a guideline becomes a
reusable type, that type is the candidate to land in `tom_deploy`.

---

## Installation

`tom_deploy` is a **workspace-internal package** (`publish_to: none`). It is not
published to pub.dev — it lives inside the Tom devops repository and is consumed
in place by sibling packages. There is no `dart pub add tom_deploy`, and you
should **never** add a manual `path:` override to reach it; a tool that needs it
declares it as a workspace dependency.

```dart
import 'package:tom_deploy/tom_deploy.dart';
```

**SDK requirement:** Dart `^3.10.4`. The package has no runtime dependencies.

---

## Intended consumers

When populated, `tom_deploy` is expected to be depended on by the tools that
need to model or trigger a deployment:

| Package | Why it would consume `tom_deploy` |
| ------- | --------------------------------- |
| [`tom_deploy_tools`](../tom_deploy_tools/) | The CLI front end that parses config and runs the model's orchestration. |
| [`tom_provisioning`](../../cloud/tom_provisioning/) | Programmatic deployment from a running application / provisioning flow. |

No package depends on `tom_deploy` yet; the table records design intent, not
current wiring.

---

## Current public surface

The package currently exposes only the default scaffold placeholder, kept so the
package builds, tests and analyzes cleanly until the real deployment model
arrives:

```dart
import 'package:tom_deploy/tom_deploy.dart';

void main() {
  final awesome = Awesome();
  print(awesome.isAwesome); // true
}
```

`Awesome` is a placeholder from the package template and carries no deployment
meaning. It will be removed when the first real deployment type lands here.

---

## Ecosystem

`tom_deploy` sits beside its CLI front end and below the tools that would trigger
deployments. Today the arrows are dotted (intended), not solid (wired):

```
        tom_deploy_tools (CLI)        tom_provisioning
                 ╎                            ╎
                 └──────────────┬─────────────┘
                                ╎ (intended: drive the model)
                                ▼
                       ┌──────────────────┐
                       │    tom_deploy    │  ← you are here (reserved)
                       │ deployment model │
                       └──────────────────┘
                                │ targets
                                ▼
                   AWS · Azure · GCP · Firebase
```

---

## Related packages

Don't duplicate — follow the link:

| Package | Relationship |
| ------- | ------------ |
| [`tom_deploy_tools`](../tom_deploy_tools/) | The command-line front end that drives `tom_deploy` deployments. |
| [`tom_provisioning`](../../cloud/tom_provisioning/) | Automated cloud provisioning that would drive deployments programmatically. |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 1.0.0 (`publish_to: none` — workspace-internal)
- **SDK:** Dart `^3.10.4`
- **Contents:** reserved placeholder — only the scaffold `Awesome` type and its
  single template test; no deployment API published yet.
- **Tests:** 1 (placeholder).

This README will grow into a full module manual — overview, feature tables,
quick start, multi-cloud usage and a key-types table — once `tom_deploy` holds
the real deployment model.

---

## License

See [LICENSE](LICENSE); each package in this repository carries its own license
terms.
