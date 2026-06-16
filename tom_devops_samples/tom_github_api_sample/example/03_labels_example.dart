// Labels — list repo labels, create one, and attach it to an issue.
//
// Run: dart run example/03_labels_example.dart

import 'fake_github.dart';

Future<void> main() async {
  final client = newSampleClient();
  try {
    final labels = await client.listLabels(repoSlug: sampleRepo);
    print('Repo labels: ${labels.map((l) => l.name).join(', ')}');
    // expected output: Repo labels: new, severity:high, bug

    final created = await client.createLabel(
      repoSlug: sampleRepo,
      name: 'analyzed',
      color: '0e8a16',
      description: 'Root cause identified',
    );
    print('Created label: ${created.name} (#${created.color})');
    // expected output: Created label: analyzed (#0e8a16)

    final onIssue = await client.addLabelsToIssue(
      repoSlug: sampleRepo,
      issueNumber: 1,
      labels: ['analyzed'],
    );
    print('Issue #1 labels: ${onIssue.map((l) => l.name).join(', ')}');
    // expected output: Issue #1 labels: new, severity:high, analyzed
  } finally {
    client.close();
  }
}
