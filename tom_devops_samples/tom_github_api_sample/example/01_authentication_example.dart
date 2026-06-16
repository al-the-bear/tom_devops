// Authentication — resolving a token and constructing a client.
//
// Run: dart run example/01_authentication_example.dart

import 'package:tom_github_api/tom_github_api.dart';

import 'fake_github.dart';

Future<void> main() async {
  // `resolveToken` checks, in order: an explicit argument, the GITHUB_TOKEN
  // environment variable, then ~/.tom/github_token. It returns null when none
  // is configured — it never throws. (`resolveTokenOrThrow` is the variant
  // that raises GitHubAuthError instead of returning null.)
  final hasToken = GitHubAuth.resolveToken() != null;
  print('Live token available: $hasToken (offline mock used regardless)');
  // expected output (no token configured): Live token available: false (offline mock used regardless)

  // For live calls you would build the client straight from the token:
  //   final client = GitHubApiClient(token: GitHubAuth.resolveTokenOrThrow());
  // The samples stay offline by injecting an in-memory transport instead.
  final client = newSampleClient();
  try {
    final issue = await client.getIssue(repoSlug: sampleRepo, number: 1);
    print('Authenticated call reached issue #${issue.number}');
    // expected output: Authenticated call reached issue #1
  } finally {
    client.close();
  }
}
