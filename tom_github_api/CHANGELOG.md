## 1.3.0

### Added

- **A public GraphQL entry point** — `GitHubApiClient.graphql(query,
  {variables, operationName})`. The client had posted GraphQL since
  `transferIssue` landed, through a private `_http.post('/graphql', …)` that
  only that method could reach, so every other GraphQL need in the workspace
  stood up its own `http.Client` — a second place handling auth, retries and
  the rate-limit headers. The REST surface also cannot reach everything:
  Projects v2 is GraphQL-only, REST Projects classic having been sunset on
  2025-04-01.

  The error handling is shaped by what GitHub actually does rather than by
  what an HTTP client usually does, because GitHub answers **200 for every
  error class** and `path` is the discriminator:

  - a **field-scoped** error (`NOT_FOUND`, `VALIDATION`) arrives with `data`
    present, the offending field null and `path` naming it. Every sibling
    resolved, so it is **returned** — throwing would discard the half that
    worked. Read `GitHubGraphQlResponse.fieldErrors`.
  - a **query-fatal** error (`INSUFFICIENT_SCOPES`) arrives with no `data` key
    at all and no `path`. There is nothing to return, so it **throws**
    `GitHubGraphQlException`. An explicit `"data": null` throws too: nothing
    resolved is nothing resolved.

  There is deliberately no `expectErrors` flag. A flag that suppresses errors
  is one somebody sets once and forgets, and the shape above already gives a
  caller both halves.

- **`GitHubApiClient.lastGraphQlRateLimit`**, beside `lastRateLimit`.

  REST and GraphQL both answer `x-ratelimit-*` and they are **different
  currencies**: 5000 requests an hour against 5000 points, where one point
  covers roughly a hundred nodes. One field for both would let a REST caller
  read a GraphQL reply's points as requests and conclude the account had spent
  far less than it had — silently, and only after a GraphQL call had happened
  to run in between. The budget is routed on the request's own URL, so a
  future GraphQL caller cannot forget to set a flag.

- **`GitHubGraphQlCost`**, read from a document's own `rateLimit { … }` field.
  A different question again from the budget above: what *this query asked
  for*, rather than what the account has left. Null when the document did not
  request it — a zero would assert the query was free. `rateLimit` does not
  exist on `Mutation`, so a mutation's cost is readable only from the headers,
  which is the asymmetry the two accessors exist for.

### Changed

- `transferIssue` posts through the public entry point rather than the private
  one, so it is a caller of the same surface as everything else and an
  error-class change is one edit rather than two. Its behaviour is unchanged:
  the mutation has exactly one field, so **any** error is a failed transfer
  however GitHub chose to report it.

### Fixed

- The test mock now sets `request` on every response it builds, as
  `BaseClient` does in production. It was not merely thinner but
  **unfaithful**, and it hid behaviour that reads the field.

## 1.0.0

- Initial version.
