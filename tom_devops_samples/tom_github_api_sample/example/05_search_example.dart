// Search — query issues with GitHub's search syntax.
//
// Run: dart run example/05_search_example.dart

import 'fake_github.dart';

Future<void> main() async {
  final client = newSampleClient();
  try {
    final result = await client.searchIssues(
      query: 'repo:$sampleRepo parser in:title',
    );
    print('Matches: ${result.totalCount}');
    // expected output: Matches: 1

    final top = result.items.first;
    print('Top hit: #${top.number} ${top.title}');
    // expected output: Top hit: #1 Array parser crashes on empty arrays
  } finally {
    client.close();
  }
}
