# Tom GitHub API

> Tom GitHub API is part of the **Tom framework** by al-the-bear.
> Distributed under the terms in this package's license — see
> [LICENSE](LICENSE).

Typed Dart client for the GitHub REST API v3 — issues, labels, comments, search
and workflows.

`tom_github_api` is a small, standalone Dart library that wraps the
[GitHub REST API v3](https://docs.github.com/en/rest) with typed models, token
authentication, transparent pagination, rate-limit tracking and a structured
exception hierarchy. It implements exactly the slice the Tom CLI kits need —
**issues, labels, comments, search and workflow dispatch** — and nothing more,
so it stays dependency-light (`http` only) and easy to reason about.

It is the HTTP engine under [`tom_issue_kit`](../tom_issue_kit/) (the `issuekit`
CLI) and the GitHub-backed flows in [`tom_test_kit`](../tom_test_kit/).

---

## Overview

GitHub's REST API is large; the Tom kits use a narrow, well-defined corner of
it. `tom_github_api` packages that corner as a reusable library so each kit does
not re-implement request signing, JSON parsing, pagination and error mapping.

| Concern | What the library does |
| ------- | --------------------- |
| **Typed surface** | Every response becomes a Dart model (`GitHubIssue`, `GitHubLabel`, `GitHubComment`, `GitHubUser`, `GitHubRateLimit`, `GitHubSearchResult`) — no raw maps leak to callers. |
| **Authentication** | Resolves a Personal Access Token from an explicit argument, the `GITHUB_TOKEN` environment variable, or `~/.tom/github_token` (in that order). |
| **Pagination** | `listAll…` methods follow GitHub's `Link` header to fetch every page; single-page `list…` methods expose `perPage`/`page` for manual control. |
| **Rate limiting** | Every response updates `lastRateLimit`; a 403 with `x-ratelimit-remaining: 0` is raised as a dedicated `GitHubRateLimitException`. |
| **Structured errors** | HTTP failures map to typed exceptions (`GitHubNotFoundException`, `GitHubAuthException`, `GitHubValidationException`, `GitHubRateLimitException`) instead of bare status codes. |

The library is **standalone** — it has no dependency on `tom_build_base`,
`tom_issue_kit` or `tom_test_kit`; the dependency arrow points the other way.

### What it does *not* cover

The surface is intentionally scoped to what the kits use. It does **not**
implement repository, pull-request or release endpoints. If a kit grows a need
for one of those, the endpoint is added here first (with tests) — never worked
around in the consumer.

---

## Installation

`tom_github_api` is a standalone library; add it as a normal dependency. Do
**not** reach it with a `path:` override from a consumer — depend on the
published version and bump the constraint when the API grows.

```yaml
dependencies:
  tom_github_api: ^1.0.0
```

```dart
import 'package:tom_github_api/tom_github_api.dart';
```

**SDK requirement:** Dart `^3.10.8`. **Runtime dependency:** `http: ^1.3.0` (the
only one).

---

## Features

### Operations

| Group | Methods |
| ----- | ------- |
| **Issues** | `createIssue`, `getIssue`, `updateIssue`, `closeIssue`, `reopenIssue`, `listIssues` (single page), `listAllIssues` (all pages) |
| **Labels** | `createLabel`, `listLabels`, `updateLabel`, `deleteLabel`, `addLabelsToIssue`, `removeLabelFromIssue` |
| **Comments** | `addComment`, `listComments` (single page), `listAllComments` (all pages) |
| **Search** | `searchIssues` (GitHub search syntax) |
| **Workflows** | `dispatchWorkflow` (trigger a GitHub Actions `workflow_dispatch`) |

### Cross-cutting

| Capability | Where |
| ---------- | ----- |
| Token resolution | `GitHubAuth.resolveToken` / `resolveTokenOrThrow` |
| Rate-limit snapshot | `GitHubApiClient.lastRateLimit` → `GitHubRateLimit` |
| Typed errors | `GitHubException` + four subtypes |
| Pull-request filtering | `listIssues` / `listAllIssues` drop entries that carry a `pull_request` field, so you get issues only |
| Custom base URL | `GitHubApiClient(baseUrl: …)` for GitHub Enterprise |
| Injectable transport | `GitHubApiClient(httpClient: …)` for testing with a mock client |

### Repo addressing

Every repo-scoped method accepts the target either as a single
`repoSlug: 'owner/repo'` **or** as separate `owner:` + `repo:` arguments — pick
whichever reads better at the call site.

---

## Quick start

```dart
import 'package:tom_github_api/tom_github_api.dart';

void main() async {
  // Resolve a token from arg / GITHUB_TOKEN / ~/.tom/github_token.
  final token = GitHubAuth.resolveTokenOrThrow();
  final client = GitHubApiClient(token: token);

  try {
    final issues = await client.listIssues(
      repoSlug: 'al-the-bear/tom_issues',
      state: 'open',
    );
    for (final issue in issues) {
      print('#${issue.number}: ${issue.title}'); // #42: Pagination bug
    }
  } on GitHubException catch (e) {
    print('GitHub error ${e.statusCode}: ${e.message}');
  } finally {
    client.close(); // always release the underlying http.Client
  }
}
```

Always `close()` the client when you are done — it owns an `http.Client`.

---

## Example projects

| Location | What it shows |
| -------- | ------------- |
| [`example/tom_github_api_example.dart`](example/tom_github_api_example.dart) | Minimal end-to-end: resolve a token, list issues, print them. |
| [`test/`](test/) | 57 tests across client / models / http / error handling, run against a mock `http.Client` (no network). |
| [`tool/integration_test.dart`](tool/integration_test.dart), [`tool/api_integration_test.dart`](tool/api_integration_test.dart) | Opt-in integration checks that hit the **live** GitHub API (require a real token). |
| `../tom_devops_samples/tom_github_api_sample/` | The flagship devops sample, built on this library — see the [samples learning path](../README.md). *(forward reference — added later in this quest.)* |

---

## Usage

### 1. Authentication

`GitHubAuth` resolves a Personal Access Token from three sources, in order:

1. an explicit `token:` argument,
2. the `GITHUB_TOKEN` environment variable,
3. the file `~/.tom/github_token` (first line only).

```dart
// Returns null if nothing is found.
final maybe = GitHubAuth.resolveToken();

// Throws GitHubAuthError (with a message listing all three sources) if missing.
final token = GitHubAuth.resolveTokenOrThrow();

// Or pass one explicitly — it always wins.
final explicit = GitHubAuth.resolveTokenOrThrow(token: 'ghp_xxx');
```

The token is sent as `Authorization: Bearer <token>` with
`Accept: application/vnd.github+json` and `X-GitHub-Api-Version: 2022-11-28` on
every request.

### 2. Issues

```dart
final client = GitHubApiClient(token: token);

// Create
final created = await client.createIssue(
  repoSlug: 'al-the-bear/tom_issues',
  title: 'Flaky pagination test',
  body: 'Fails ~1 in 10 runs.',
  labels: ['bug', 'flaky'],
  assignee: 'al-the-bear',
);

// Read
final issue = await client.getIssue(
  repoSlug: 'al-the-bear/tom_issues', number: created.number);

// Update (only non-null fields are sent)
await client.updateIssue(
  repoSlug: 'al-the-bear/tom_issues',
  number: issue.number,
  labels: ['bug'],
);

// Close / reopen (convenience over updateIssue)
await client.closeIssue(repoSlug: 'al-the-bear/tom_issues', number: issue.number);
await client.reopenIssue(repoSlug: 'al-the-bear/tom_issues', number: issue.number);
```

#### Listing and pagination

`listIssues` returns a single page (use `perPage`/`page` to walk manually);
`listAllIssues` transparently follows the `Link` header until every matching
issue is fetched:

```dart
// One page, filtered.
final page1 = await client.listIssues(
  repoSlug: 'al-the-bear/tom_issues',
  state: 'open',
  labels: ['bug'],
  sort: 'updated',
  direction: 'desc',
  perPage: 50,
  page: 1,
);

// Everything, across all pages (per_page=100 internally).
final all = await client.listAllIssues(
  repoSlug: 'al-the-bear/tom_issues',
  state: 'all',
  since: DateTime.utc(2026, 1, 1),
);
```

Both methods **exclude pull requests** — GitHub returns PRs from the issues
endpoint, and the client drops any entry carrying a `pull_request` field.

### 3. Labels

```dart
await client.createLabel(
  repoSlug: 'al-the-bear/tom_issues',
  name: 'needs-triage',
  color: 'ededed',
  description: 'Awaiting first review',
);

final labels = await client.listLabels(repoSlug: 'al-the-bear/tom_issues');

await client.updateLabel(
  repoSlug: 'al-the-bear/tom_issues',
  name: 'needs-triage',
  newName: 'triage',
  color: 'fbca04',
);

// Add labels to an issue without clearing existing ones.
await client.addLabelsToIssue(
  repoSlug: 'al-the-bear/tom_issues', issueNumber: 42, labels: ['triage']);

await client.removeLabelFromIssue(
  repoSlug: 'al-the-bear/tom_issues', issueNumber: 42, label: 'triage');

await client.deleteLabel(repoSlug: 'al-the-bear/tom_issues', name: 'triage');
```

### 4. Comments

```dart
await client.addComment(
  repoSlug: 'al-the-bear/tom_issues',
  issueNumber: 42,
  body: 'Reproduced on CI — see run #1234.',
);

// Single page or all pages.
final page = await client.listComments(
  repoSlug: 'al-the-bear/tom_issues', issueNumber: 42, perPage: 30);
final everything = await client.listAllComments(
  repoSlug: 'al-the-bear/tom_issues', issueNumber: 42);
```

### 5. Search

```dart
final result = await client.searchIssues(
  query: 'repo:al-the-bear/tom_issues is:open label:bug',
  sort: 'updated',
  order: 'desc',
);
print('${result.totalCount} matches');
for (final issue in result.items) {
  print('#${issue.number}: ${issue.title}');
}
```

### 6. Workflow dispatch

```dart
await client.dispatchWorkflow(
  repoSlug: 'al-the-bear/tom_issues',
  workflowId: 'verify.yml',
  ref: 'main',
  inputs: {'issue': '42'},
);
```

### 7. Errors and rate limits

Every failed request maps to a typed exception so callers can branch on cause,
not status code:

```dart
try {
  await client.getIssue(repoSlug: 'al-the-bear/tom_issues', number: 999999);
} on GitHubNotFoundException {
  // 404 — issue doesn't exist
} on GitHubValidationException catch (e) {
  // 422 — e.errors holds the field-level details
} on GitHubRateLimitException catch (e) {
  // 403 with remaining == 0 — e.rateLimit.resetAt tells you when to retry
} on GitHubAuthException {
  // 401 / 403 — bad or missing token
} on GitHubException catch (e) {
  // any other non-2xx
  print('${e.statusCode}: ${e.message}');
}

// Inspect the most recent rate-limit snapshot at any time.
final rl = client.lastRateLimit;
if (rl != null && rl.remaining < 10) {
  print('Slow down — ${rl.remaining} calls left until ${rl.resetAt}');
}
```

### Testing against a mock transport

Inject any `http.Client` to test without a network:

```dart
final client = GitHubApiClient(
  token: 'test-token',
  httpClient: myMockHttpClient, // returns canned responses
);
```

This is how the package's own 57-test suite runs — see
[`test/helpers/mock_http_client.dart`](test/helpers/mock_http_client.dart).

---

## Architecture

```
            GitHubApiClient            ← public façade: typed operations
                  │  delegates transport to
                  ▼
            GitHubHttpClient           ← internal: signs requests, tracks
                  │                       rate limits, maps errors, paginates
       ┌──────────┼──────────┐
       ▼          ▼          ▼
   GitHubAuth  models     GitHubException (+ subtypes)
   (token      (Issue,    NotFound / Auth /
    resolution) Label,    Validation / RateLimit
                Comment…)
                  │
                  ▼
            GitHub REST API v3
```

`GitHubApiClient` is the only class callers construct. It owns an internal
`GitHubHttpClient` (not exported) that adds the auth headers, records the
rate-limit headers, raises typed exceptions on non-2xx responses, and follows
`Link` headers for the `listAll…` methods. Models are immutable value types
built from JSON via `fromJson` factories.

### Key types

| Type | Role |
| ---- | ---- |
| `GitHubApiClient` | Public client — all issue / label / comment / search / workflow operations; `lastRateLimit`; `close()`. |
| `GitHubAuth` | Static token resolver (`resolveToken`, `resolveTokenOrThrow`); throws `GitHubAuthError` when no token is found. |
| `GitHubException` | Base API exception (`statusCode`, `message`, `documentationUrl`, `responseBody`); `fromResponse` factory picks the subtype. |
| `GitHubNotFoundException` | 404. |
| `GitHubAuthException` | 401 / 403 (bad or missing token, not rate limit). |
| `GitHubValidationException` | 422 — carries field-level `errors`. |
| `GitHubRateLimitException` | 403 with `x-ratelimit-remaining: 0` — carries a `GitHubRateLimit`. |
| `GitHubIssue` | Issue model (number, title, body, state, labels, assignee, user, timestamps, `commentsCount`, `htmlUrl`). |
| `GitHubLabel` | Label model (id, name, color, description). |
| `GitHubComment` | Comment model (id, body, user, timestamps). |
| `GitHubUser` | Minimal user model (login, id, avatarUrl). |
| `GitHubRateLimit` | Rate-limit snapshot (limit, remaining, resetAt); `fromHeaders`. |
| `GitHubSearchResult` | Search wrapper (totalCount, incompleteResults, items). |

(`GitHubHttpClient` is internal and intentionally not exported.)

---

## Ecosystem

```
        tom_issue_kit (issuekit)      tom_test_kit (testkit)
                 │                            │
                 └──────────────┬─────────────┘
                                │ depend on
                                ▼
                       ┌──────────────────┐
                       │  tom_github_api  │  ← you are here
                       └──────────────────┘
                                │ depends on
                                ▼
                          package:http
```

`tom_github_api` sits at the bottom of the GitHub-facing stack: the kits call
it, it calls `http`, and it depends on nothing else in the workspace.

---

## Further documentation

| Document | What it covers |
| -------- | -------------- |
| [`doc/github_api_specification.md`](doc/github_api_specification.md) | The authoritative API specification — full surface, data models, behaviour, error mapping and rate-limit rules. |

### Related packages

| Package | Relationship |
| ------- | ------------ |
| [`tom_issue_kit`](../tom_issue_kit/) | The `issuekit` CLI — primary consumer of this client. |
| [`tom_test_kit`](../tom_test_kit/) | The `testkit` CLI — uses the GitHub-backed flows. |
| [Tom DevOps map](../README.md) | The repository-level index for the whole devops toolchain. |

---

## Status

- **Version:** 1.0.0
- **SDK:** Dart `^3.10.8`
- **Runtime dependencies:** `http: ^1.3.0` (only).
- **Surface:** Issues, Labels, Comments, Search, Workflow dispatch, token auth,
  rate-limit tracking, typed exceptions. (No repo / pull-request / release
  endpoints — added on demand.)
- **Tests:** 57 (mock-transport unit suite) + opt-in live-API integration checks
  under `tool/`.

---

## License

See [LICENSE](LICENSE); each package in this repository carries its own license
terms.
