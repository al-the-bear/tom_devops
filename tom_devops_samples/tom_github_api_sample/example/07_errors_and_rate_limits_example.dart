// Errors and rate limits — typed exceptions and the rate-limit snapshot.
//
// Run: dart run example/07_errors_and_rate_limits_example.dart

import 'package:tom_github_api/tom_github_api.dart';

import 'fake_github.dart';

Future<void> main() async {
  final client = newSampleClient();
  try {
    // Failed requests raise a typed subclass of GitHubException. Catch the
    // specific one you care about (here: a missing issue → 404).
    try {
      await client.getIssue(repoSlug: sampleRepo, number: 999);
    } on GitHubNotFoundException catch (e) {
      print('Caught ${e.statusCode}: ${e.message}');
      // expected output: Caught 404: Not Found
    }

    final all = await client.listIssues(repoSlug: sampleRepo, state: 'all');
    print('Total issues: ${all.length}');
    // expected output: Total issues: 1

    // Every response carries rate-limit headers; the client exposes the most
    // recent snapshot. Two calls have been made above, so 4998 of 5000 remain.
    final rl = client.lastRateLimit!;
    print('Rate limit remaining: ${rl.remaining}/${rl.limit}');
    // expected output: Rate limit remaining: 4998/5000
  } finally {
    client.close();
  }
}
