import 'package:test/test.dart';
import 'package:tom_github_api/tom_github_api.dart';

import '../helpers/mock_http_client.dart';

/// The repository payload GitHub answers `GET /repos/{owner}/{repo}` with,
/// reduced to the fields the client reads.
Map<String, dynamic> repoJson({
  String fullName = 'al-the-bear/tom_kdbx',
  String name = 'tom_kdbx',
  String owner = 'al-the-bear',
  int id = 1155216085,
  String defaultBranch = 'main',
  String nodeId = 'R_kgDORmxJ1Q',
  bool fork = true,
}) =>
    {
      'id': id,
      'full_name': fullName,
      'name': name,
      'owner': {'login': owner},
      'default_branch': defaultBranch,
      'node_id': nodeId,
      'fork': fork,
    };

void main() {
  group('GitHubApiClient — Repository Operations', () {
    test('GH-REPO-1: getRepository returns the typed repository [2026-08-02 10:00]',
        () async {
      final api = GitHubApiClient(
        token: 'test-token',
        httpClient: createMockClient({
          'GET /repos/al-the-bear/tom_kdbx': MockResponse(200, repoJson()),
        }),
      );

      final repo = await api.getRepository(repoSlug: 'al-the-bear/tom_kdbx');

      expect(repo.id, 1155216085);
      expect(repo.fullName, 'al-the-bear/tom_kdbx');
      expect(repo.name, 'tom_kdbx');
      expect(repo.owner, 'al-the-bear');
      expect(repo.defaultBranch, 'main');
      expect(repo.nodeId, 'R_kgDORmxJ1Q');
      expect(repo.isFork, isTrue);
      api.close();
    });

    test(
        'GH-REPO-2: a rename redirect answers with the current name, not the one asked for [2026-08-02 10:00]',
        () async {
      // This is the whole reason the model surfaces `full_name`. GitHub keeps a
      // redirect from a repository's pre-rename name, so the request succeeds
      // and the caller sees a 200 — the *only* signal that the name is stale is
      // that the answer disagrees with the question.
      final api = GitHubApiClient(
        token: 'test-token',
        httpClient: createMockClient({
          'GET /repos/al-the-bear/tom_kdbx.dart': MockResponse(
            200,
            repoJson(fullName: 'al-the-bear/tom_kdbx', name: 'tom_kdbx'),
          ),
        }),
      );

      final repo =
          await api.getRepository(repoSlug: 'al-the-bear/tom_kdbx.dart');

      expect(repo.fullName, isNot('al-the-bear/tom_kdbx.dart'));
      expect(repo.fullName, 'al-the-bear/tom_kdbx');
      api.close();
    });

    test('GH-REPO-3: getDefaultBranch reads through getRepository [2026-08-02 10:00]',
        () async {
      final api = GitHubApiClient(
        token: 'test-token',
        httpClient: createMockClient({
          'GET /repos/owner/repo':
              MockResponse(200, repoJson(defaultBranch: 'trunk')),
        }),
      );

      expect(await api.getDefaultBranch(owner: 'owner', repo: 'repo'), 'trunk');
      api.close();
    });

    test('GH-REPO-4: getRepositoryNodeId reads through getRepository [2026-08-02 10:00]',
        () async {
      final api = GitHubApiClient(
        token: 'test-token',
        httpClient: createMockClient({
          'GET /repos/owner/repo':
              MockResponse(200, repoJson(nodeId: 'R_kgDOabcdef')),
        }),
      );

      expect(
        await api.getRepositoryNodeId(owner: 'owner', repo: 'repo'),
        'R_kgDOabcdef',
      );
      api.close();
    });

    test('GH-REPO-5: a missing repository surfaces as a not-found exception [2026-08-02 10:00]',
        () async {
      final api = GitHubApiClient(
        token: 'test-token',
        httpClient: createMockClient({
          'GET /repos/owner/gone': MockResponse(404, {'message': 'Not Found'}),
        }),
      );

      await expectLater(
        api.getRepository(owner: 'owner', repo: 'gone'),
        throwsA(isA<GitHubNotFoundException>()),
      );
      api.close();
    });
  });
}
