// Workflows — trigger a GitHub Actions workflow via workflow_dispatch.
//
// Run: dart run example/06_workflows_example.dart

import 'fake_github.dart';

Future<void> main() async {
  final client = newSampleClient();
  try {
    // Returns normally (HTTP 204) on success and throws on failure, so
    // reaching the next line means the dispatch was accepted.
    await client.dispatchWorkflow(
      repoSlug: sampleRepo,
      workflowId: 'ci.yml',
      ref: 'main',
      inputs: {'suite': 'smoke'},
    );
    print('Dispatched ci.yml on main (suite=smoke)');
    // expected output: Dispatched ci.yml on main (suite=smoke)
  } finally {
    client.close();
  }
}
