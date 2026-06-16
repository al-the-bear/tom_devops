# Tom Deploy Tools

> Tom Deploy Tools is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [LICENSE](LICENSE).

Command-line front end that drives Tom framework multi-cloud deployments.

> **Status: reserved package.** `tom_deploy_tools` is the *intended* home for the
> **command-line front end** that drives the [`tom_deploy`](../tom_deploy/)
> deployment model — the `tom_deploy_tools` CLI you would run to deploy a Tom
> application to a cloud target. It is currently a **placeholder**: it ships only
> the default `dart create` console scaffold (a `calculate()` stub and a
> hello-world `main`) and has no deployment commands yet. This README documents
> the package's role and points you at the real material rather than dressing the
> placeholder up as a working CLI.

---

## Overview

Once a Tom application has been built, deploying it should be one consistent
command regardless of the target cloud. `tom_deploy_tools` is the reserved home
for that command-line entry point.

The design intent (captured in the [`tom_deploy` quest](../../../_ai/quests/tom_deploy/overview.tom_deploy.md))
is a clean split between **model** and **front end**:

| Package | Role |
| ------- | ---- |
| [`tom_deploy`](../tom_deploy/) | The deployment **model** — platform-agnostic types describing *what* to deploy (server app, web client, full-stack), *where* (AWS, Azure, GCP, Firebase), and the orchestration that executes a deployment. |
| **`tom_deploy_tools`** (this package) | The command-line **front end** that drives `tom_deploy`: it parses deployment configuration, selects the target platform, and runs the model's orchestration from a terminal or a CI/CD pipeline. |

Keeping the CLI thin — a front end over a reusable model — means the same
deployment logic can also be invoked programmatically (e.g. from
`tom_provisioning`) without duplicating it.

Right now that split exists only on paper: `tom_deploy` is an empty model shell
and `tom_deploy_tools` is a matching console stub. Keeping both packages in the
tree means the dependency wiring and (workspace-internal) executable slot already
exist when the first real deployment command is ready to land.

### Intended command surface

When populated, the CLI is intended to offer:

- **One deploy command per application type** — server apps, Flutter-web / static
  web clients, and coordinated full-stack deployments.
- **Platform selection from one config** — AWS, Azure, GCP, and Firebase behind a
  single, consistent configuration format.
- **CI-friendly execution** — compilable to a native executable with minimal
  dependencies, so it runs cleanly inside cloud build / CI environments.

This list records the design target, not shipped behaviour.

---

## Installation

`tom_deploy_tools` is a **workspace-internal package** (`publish_to: none`). It is
not published to pub.dev — it lives inside the Tom devops repository and is built
in place. There is no `dart pub global activate tom_deploy_tools`, and you should
**never** add a manual `path:` override to reach `tom_deploy`; the CLI declares
the model as a workspace dependency once the model exists.

The package exposes a single console entry point:

```bash
# from the package directory (placeholder behaviour today)
dart run bin/tom_deploy_tools.dart
# → Hello world: 42!
```

That output is the scaffold placeholder, not a deployment — it will be replaced
by the real command surface when the model lands.

**SDK requirement:** Dart `^3.10.4`.

---

## Where deployment lives today

Until the CLI and its model are implemented, the framework's deployment knowledge
lives in the workspace-root **cloud guidelines** under `_copilot_guidelines/cloud/`:

| Concern | Current home |
| ------- | ------------ |
| Cloud deployment patterns (AWS / Azure / GCP / Firebase) | `_copilot_guidelines/cloud/cloud_deployment.md` |
| Production & dev Docker images | `_copilot_guidelines/cloud/docker_image_creation.md` |
| Running server apps locally with Docker | `_copilot_guidelines/cloud/docker_local.md` |
| Deployment model objectives & scope | `_ai/quests/tom_deploy/overview.tom_deploy.md` |

---

## Current public surface

The package currently exposes only the default console scaffold, kept so it
builds, tests and analyzes cleanly until the real CLI arrives:

```dart
import 'package:tom_deploy_tools/tom_deploy_tools.dart';

void main() {
  print(calculate()); // 42
}
```

`calculate()` is a placeholder from the `dart create` console template and
carries no deployment meaning. It will be removed when the first real deployment
command lands here.

---

## Ecosystem

`tom_deploy_tools` sits above the deployment model it drives. Today the arrows are
dotted (intended), not solid (wired):

```
                   you / CI pipeline
                          │ runs
                          ▼
                ┌────────────────────┐
                │  tom_deploy_tools  │  ← you are here (reserved CLI)
                └────────────────────┘
                          ╎ (intended: drive the model)
                          ▼
                   ┌──────────────┐
                   │  tom_deploy  │  deployment model
                   └──────────────┘
                          │ targets
                          ▼
              AWS · Azure · GCP · Firebase
```

---

## Related packages

Don't duplicate — follow the link:

| Package | Relationship |
| ------- | ------------ |
| [`tom_deploy`](../tom_deploy/) | The deployment model this CLI is the front end for. |
| [`tom_provisioning`](../../cloud/tom_provisioning/) | Automated cloud provisioning that would drive deployments programmatically. |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 1.0.0 (`publish_to: none` — workspace-internal)
- **SDK:** Dart `^3.10.4`
- **Contents:** reserved placeholder — only the `dart create` console scaffold
  (`calculate()` + hello-world `main`) and its single template test; no
  deployment commands yet.
- **Tests:** 1 (placeholder).

This README will grow into a full CLI manual — command reference, configuration
format, per-platform usage and CI examples — once `tom_deploy_tools` drives the
real deployment model.

---

## License

See [LICENSE](LICENSE); each package in this repository carries its own license
terms.
