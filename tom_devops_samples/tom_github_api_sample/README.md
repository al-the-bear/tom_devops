# tom_github_api Sample — the GitHub REST client, end to end

> This is the **flagship** Tom devops sample. It is part of the **Tom
> framework** by al-the-bear, distributed under the terms in this repository's
> license — see [`../../LICENSE.md`](../../LICENSE.md).

A self-contained, **offline-by-default** tour of
[`tom_github_api`](../../tom_github_api/) — the typed Dart client for the
GitHub REST API v3. Seven runnable, one-concept-per-file examples cover the
whole surface the client actually implements: **authentication, issues, labels,
comments, search, workflow dispatch, and the error / rate-limit model.**

Every example runs with no network and no token because the client takes an
injectable `http.Client`, and these samples inject an in-memory fake. The same
code talks to live GitHub by swapping that one argument out — see
[Going live](#going-live).

- Tool manual (the reference): [`tom_github_api/README.md`](../../tom_github_api/README.md)
- Samples index (all devops samples): [`../README.md`](../README.md)

---

## Contents

- [Why offline by default](#why-offline-by-default)
- [Running the sample](#running-the-sample)
- [The examples, one by one](#the-examples-one-by-one)
  - [01 — Authentication](#01--authentication)
  - [02 — Issues](#02--issues)
  - [03 — Labels](#03--labels)
  - [04 — Comments](#04--comments)
  - [05 — Search](#05--search)
  - [06 — Workflows](#06--workflows)
  - [07 — Errors and rate limits](#07--errors-and-rate-limits)
- [The API surface at a glance](#the-api-surface-at-a-glance)
- [The error taxonomy](#the-error-taxonomy)
- [Rate limits](#rate-limits)
- [How the offline fake works](#how-the-offline-fake-works)
- [Going live](#going-live)
- [Layout](#layout)
- [Related](#related)

---

## Why offline by default

A sample that needs a token and a network to run is a sample most people never
run. It also can't be a CI smoke test: it's slow, it's flaky, and — for a
client whose job is to *create issues and dispatch workflows* — running it for
real **mutates a live repository**.

`GitHubApiClient` is built to avoid all of that. Its constructor accepts an
optional `http.Client`:

```dart
GitHubApiClient({
  required String token,
  http.Client? httpClient,          // ← inject anything that speaks http
  String baseUrl = 'https://api.github.com',
});
```

The samples pass a [`MockClient`](https://pub.dev/documentation/http/latest/testing/MockClient-class.html)
(from `package:http/testing.dart`) backed by a few in-memory maps. The result:

- **No network.** Nothing leaves the process.
- **No token.** The fake never inspects the placeholder token.
- **Deterministic.** Fixed seed data and fixed timestamps mean each example's
  output is byte-for-byte stable — which is why every line below carries an
  inline `// expected output`.
- **Safe.** "Create issue", "close issue", "dispatch workflow" all hit the
  fake, never a real repo.

The seed is one repository, `al-the-bear/tom_issues`, containing issue **#1**
("Array parser crashes on empty arrays") with the labels `new` and
`severity:high`, plus the repo labels `new`, `severity:high`, and `bug`.

---

## Running the sample

From this directory:

```bash
dart pub get
dart run example/run_all_examples.dart
```

You'll see each example run in turn and a final tally:

```
=== 01 authentication ===
Live token available: false (offline mock used regardless)
Authenticated call reached issue #1

=== 02 issues ===
Created #2: Improve error message for null configs
Fetched #2 (open)
Open issues: 2
After close, #2 is closed
After reopen, #2 is open

... (03–07) ...

==================================================
Results: 7 passed, 0 failed
All tom_github_api examples passed.
```

Run a single example on its own:

```bash
dart run example/02_issues_example.dart
```

This sample is also wired into the devops-wide aggregator one level up
([`../run_all_examples.dart`](../run_all_examples.dart)), where it reports as
**PASSED**.

---

## The examples, one by one

Each file is a complete program: build a client with `newSampleClient()`, do
one thing, print the result, and `close()` the client in a `finally`. The
printed lines match the `// expected output` comments exactly.

### 01 — Authentication

`GitHubAuth.resolveToken()` looks for a token in three places, in order: an
explicit argument, the `GITHUB_TOKEN` environment variable, then
`~/.tom/github_token`. It returns `null` when none is found — it never throws.
(`resolveTokenOrThrow()` is the variant that raises `GitHubAuthError`.)

```dart
final hasToken = GitHubAuth.resolveToken() != null;
print('Live token available: $hasToken (offline mock used regardless)');
// expected output (no token configured): Live token available: false (offline mock used regardless)

final client = newSampleClient();
try {
  final issue = await client.getIssue(repoSlug: sampleRepo, number: 1);
  print('Authenticated call reached issue #${issue.number}');
  // expected output: Authenticated call reached issue #1
} finally {
  client.close();
}
```

→ [`example/01_authentication_example.dart`](example/01_authentication_example.dart)

### 02 — Issues

The issue lifecycle: `createIssue`, `getIssue`, `listIssues` (filtered by
state), and the `closeIssue` / `reopenIssue` convenience wrappers (each a thin
`updateIssue` with `state: 'closed'` / `'open'`).

```dart
final created = await client.createIssue(
  repoSlug: sampleRepo,
  title: 'Improve error message for null configs',
  body: 'The loader should name the missing key.',
  labels: ['new'],
);
print('Created #${created.number}: ${created.title}');
// expected output: Created #2: Improve error message for null configs

final open = await client.listIssues(repoSlug: sampleRepo, state: 'open');
print('Open issues: ${open.length}');
// expected output: Open issues: 2

final closed = await client.closeIssue(repoSlug: sampleRepo, number: created.number);
print('After close, #${closed.number} is ${closed.state}');
// expected output: After close, #2 is closed
```

`listIssues` filters pull requests out automatically — the GitHub Issues
endpoint returns both, and the client drops anything carrying a `pull_request`
field. Addressing works either as `repoSlug: 'owner/repo'` or as separate
`owner:` / `repo:` arguments.

→ [`example/02_issues_example.dart`](example/02_issues_example.dart)

### 03 — Labels

List the repo's labels, create a new one, and attach it to an issue.
`addLabelsToIssue` is additive — it returns the issue's full label set after
the addition, leaving existing labels in place.

```dart
final labels = await client.listLabels(repoSlug: sampleRepo);
print('Repo labels: ${labels.map((l) => l.name).join(', ')}');
// expected output: Repo labels: new, severity:high, bug

await client.createLabel(
  repoSlug: sampleRepo, name: 'analyzed', color: '0e8a16',
  description: 'Root cause identified',
);

final onIssue = await client.addLabelsToIssue(
  repoSlug: sampleRepo, issueNumber: 1, labels: ['analyzed'],
);
print('Issue #1 labels: ${onIssue.map((l) => l.name).join(', ')}');
// expected output: Issue #1 labels: new, severity:high, analyzed
```

→ [`example/03_labels_example.dart`](example/03_labels_example.dart)

### 04 — Comments

Add comments and read them back. `listComments` returns a single page;
`listAllComments` follows pagination links to fetch every page.

```dart
await client.addComment(repoSlug: sampleRepo, issueNumber: 1, body: 'Reproduced on main.');
await client.addComment(repoSlug: sampleRepo, issueNumber: 1, body: 'Fix pushed in #2, please verify.');

final comments = await client.listComments(repoSlug: sampleRepo, issueNumber: 1);
print('Comments on #1: ${comments.length}');
// expected output: Comments on #1: 2

print('First: "${comments.first.body}" by ${comments.first.user.login}');
// expected output: First: "Reproduced on main." by octodev
```

→ [`example/04_comments_example.dart`](example/04_comments_example.dart)

### 05 — Search

`searchIssues` takes a raw GitHub search query and returns a
`GitHubSearchResult` (`totalCount`, `incompleteResults`, `items`).

```dart
final result = await client.searchIssues(query: 'repo:$sampleRepo parser in:title');
print('Matches: ${result.totalCount}');
// expected output: Matches: 1

final top = result.items.first;
print('Top hit: #${top.number} ${top.title}');
// expected output: Top hit: #1 Array parser crashes on empty arrays
```

→ [`example/05_search_example.dart`](example/05_search_example.dart)

### 06 — Workflows

`dispatchWorkflow` triggers a GitHub Actions `workflow_dispatch` event. It
returns `void`: success is HTTP 204, and any failure throws — so reaching the
next line means the dispatch was accepted.

```dart
await client.dispatchWorkflow(
  repoSlug: sampleRepo, workflowId: 'ci.yml', ref: 'main',
  inputs: {'suite': 'smoke'},
);
print('Dispatched ci.yml on main (suite=smoke)');
// expected output: Dispatched ci.yml on main (suite=smoke)
```

→ [`example/06_workflows_example.dart`](example/06_workflows_example.dart)

### 07 — Errors and rate limits

Failed requests raise a typed subclass of `GitHubException`; catch the specific
one you care about. The client also exposes `lastRateLimit`, the rate-limit
snapshot from the most recent response.

```dart
try {
  await client.getIssue(repoSlug: sampleRepo, number: 999);
} on GitHubNotFoundException catch (e) {
  print('Caught ${e.statusCode}: ${e.message}');
  // expected output: Caught 404: Not Found
}

final rl = client.lastRateLimit!;
print('Rate limit remaining: ${rl.remaining}/${rl.limit}');
// expected output: Rate limit remaining: 4998/5000
```

→ [`example/07_errors_and_rate_limits_example.dart`](example/07_errors_and_rate_limits_example.dart)

---

## The API surface at a glance

`tom_github_api` is deliberately scoped to the operations `tom_issue_kit` and
`tom_test_kit` need. The full method set demonstrated above:

| Area | Methods |
| ---- | ------- |
| **Issues** | `createIssue`, `getIssue`, `updateIssue`, `closeIssue`, `reopenIssue`, `listIssues`, `listAllIssues` |
| **Labels** | `createLabel`, `listLabels`, `updateLabel`, `deleteLabel`, `addLabelsToIssue`, `removeLabelFromIssue` |
| **Comments** | `addComment`, `listComments`, `listAllComments` |
| **Search** | `searchIssues` |
| **Workflows** | `dispatchWorkflow` |
| **Auth** | `GitHubAuth.resolveToken`, `GitHubAuth.resolveTokenOrThrow` |
| **Rate limit** | `client.lastRateLimit` |

Every repository-scoped method addresses the target either with
`repoSlug: 'owner/repo'` or with separate `owner:` and `repo:` arguments.
`list*` methods return a single page; the `listAll*` variants follow the
`Link` header to fetch every page.

The typed models returned by these methods: `GitHubIssue`, `GitHubLabel`,
`GitHubComment`, `GitHubUser`, `GitHubSearchResult`, and `GitHubRateLimit`.

---

## The error taxonomy

The base type is `GitHubException` (`statusCode`, `message`,
`documentationUrl`, `responseBody`). The client raises the most specific
subclass it can, so you can catch narrowly:

| Exception | When | Notable fields |
| --------- | ---- | -------------- |
| `GitHubNotFoundException` | 404 | — |
| `GitHubAuthException` | 401 / 403 (not rate limit) | — |
| `GitHubValidationException` | 422 | `errors` (per-field detail) |
| `GitHubRateLimitException` | 403 with `x-ratelimit-remaining: 0` | `rateLimit` |
| `GitHubException` | any other ≥ 400 | — |

Because the subclasses all extend `GitHubException`, a single
`on GitHubException catch (e)` still catches everything — reach for the
subclasses only where you want to branch on the cause, as example 07 does for
404s. Auth resolution has its own separate error, `GitHubAuthError`, thrown by
`resolveTokenOrThrow` when no token is configured.

---

## Rate limits

Every GitHub response carries `x-ratelimit-*` headers. The client parses them
on each call and exposes the latest as `client.lastRateLimit`, a
`GitHubRateLimit` with:

- `limit` — the ceiling (5000 for an authenticated token);
- `remaining` — calls left in the current window;
- `resetAt` — when the window resets (and `resetIn` for the duration);
- `isExceeded` — `true` once `remaining` hits zero.

In example 07 the fake reports `4998/5000` because exactly two calls preceded
the read. A real long-running job can poll `lastRateLimit` to back off before
it hits the wall and starts getting `GitHubRateLimitException`s.

---

## How the offline fake works

[`example/fake_github.dart`](example/fake_github.dart) is the whole trick. It
defines:

- `FakeGitHub` — a stateful, in-memory stand-in. It seeds one repo, then
  routes by HTTP method + URL path to a handful of handlers that mutate a few
  maps (`_issues`, `_comments`, `_labels`) and return JSON shaped exactly like
  GitHub's, complete with `x-ratelimit-*` headers. The routes mirror the real
  endpoints the client calls — `/repos/{o}/{r}/issues`, `.../labels`,
  `.../comments`, `/search/issues`,
  `.../actions/workflows/{id}/dispatches` — and reply `404 Not Found` to
  anything else.
- `newSampleClient()` — constructs a `GitHubApiClient` whose `httpClient` is
  `FakeGitHub().asClient()` (a `MockClient`). Each call gets a **fresh** fake,
  so examples are independent and order-free.
- `sampleRepo` — the `'al-the-bear/tom_issues'` slug every example targets.

This is the same injection seam the client's own test suite uses; the fake here
is just a friendlier, narrative version sized for the examples.

---

## Going live

To talk to real GitHub, change two things: resolve a real token, and **omit**
the `httpClient` argument so the client uses a real `http.Client`.

```dart
import 'package:tom_github_api/tom_github_api.dart';

Future<void> main() async {
  // Reads GITHUB_TOKEN (or ~/.tom/github_token); throws if neither is set.
  final token = GitHubAuth.resolveTokenOrThrow();
  final client = GitHubApiClient(token: token); // real transport
  try {
    final issue = await client.getIssue(
      repoSlug: 'al-the-bear/tom_issues',
      number: 1,
    );
    print('${issue.title} (${issue.state})');
  } finally {
    client.close();
  }
}
```

```bash
export GITHUB_TOKEN=ghp_xxx
dart run live.dart
```

Mind that live mode makes real changes: `createIssue`, `closeIssue`,
`addComment`, and `dispatchWorkflow` all act on the target repository. Point
them at a scratch repo until you trust the call.

---

## Layout

```
tom_github_api_sample/
├── README.md                 # this article
├── analysis_options.yaml     # include: ../analysis_options.yaml
├── pubspec.yaml              # depends on tom_github_api (path) + http
└── example/
    ├── fake_github.dart                       # in-memory transport + newSampleClient()
    ├── 01_authentication_example.dart
    ├── 02_issues_example.dart
    ├── 03_labels_example.dart
    ├── 04_comments_example.dart
    ├── 05_search_example.dart
    ├── 06_workflows_example.dart
    ├── 07_errors_and_rate_limits_example.dart
    └── run_all_examples.dart                  # runs all seven, tallies, exits non-zero on failure
```

The package is workspace-internal (`publish_to: none`) and consumes its sibling
`tom_github_api` by path — the same way `tom_issue_kit` does. That's a normal
dependency on an unpublished workspace package, not an override.

---

## Related

| Link | What's there |
| ---- | ------------ |
| [`tom_github_api/README.md`](../../tom_github_api/README.md) | The client's own reference manual — every method, model, and option. |
| [`../README.md`](../README.md) | The Tom devops samples index and learning path. |
| [Tom DevOps map](../../README.md) | The repository-level index for the whole devops toolchain. |
