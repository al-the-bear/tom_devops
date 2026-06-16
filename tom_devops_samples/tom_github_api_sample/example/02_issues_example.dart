// Issues — create, read, list, close, and reopen.
//
// Run: dart run example/02_issues_example.dart

import 'fake_github.dart';

Future<void> main() async {
  final client = newSampleClient();
  try {
    final created = await client.createIssue(
      repoSlug: sampleRepo,
      title: 'Improve error message for null configs',
      body: 'The loader should name the missing key.',
      labels: ['new'],
    );
    print('Created #${created.number}: ${created.title}');
    // expected output: Created #2: Improve error message for null configs

    final fetched =
        await client.getIssue(repoSlug: sampleRepo, number: created.number);
    print('Fetched #${fetched.number} (${fetched.state})');
    // expected output: Fetched #2 (open)

    final open = await client.listIssues(repoSlug: sampleRepo, state: 'open');
    print('Open issues: ${open.length}');
    // expected output: Open issues: 2

    final closed =
        await client.closeIssue(repoSlug: sampleRepo, number: created.number);
    print('After close, #${closed.number} is ${closed.state}');
    // expected output: After close, #2 is closed

    final reopened =
        await client.reopenIssue(repoSlug: sampleRepo, number: created.number);
    print('After reopen, #${reopened.number} is ${reopened.state}');
    // expected output: After reopen, #2 is open
  } finally {
    client.close();
  }
}
