// Comments — add comments to an issue and read them back.
//
// Run: dart run example/04_comments_example.dart

import 'fake_github.dart';

Future<void> main() async {
  final client = newSampleClient();
  try {
    await client.addComment(
      repoSlug: sampleRepo,
      issueNumber: 1,
      body: 'Reproduced on main.',
    );
    await client.addComment(
      repoSlug: sampleRepo,
      issueNumber: 1,
      body: 'Fix pushed in #2, please verify.',
    );

    final comments =
        await client.listComments(repoSlug: sampleRepo, issueNumber: 1);
    print('Comments on #1: ${comments.length}');
    // expected output: Comments on #1: 2

    final first = comments.first;
    print('First: "${first.body}" by ${first.user.login}');
    // expected output: First: "Reproduced on main." by octodev
  } finally {
    client.close();
  }
}
