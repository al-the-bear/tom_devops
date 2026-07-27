import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:tom_github_api/tom_github_api.dart';

import '../helpers/mock_http_client.dart';

/// Seconds-since-epoch [offset] from now, as GitHub sends it.
int _resetIn(Duration offset) =>
    (DateTime.now().toUtc().add(offset).millisecondsSinceEpoch / 1000).round();

http.Response _response(int status, Map<String, String> headers) =>
    http.Response('{}', status, headers: headers);

void main() {
  group('GitHubRetryPolicy.delayFor', () {
    const policy = GitHubRetryPolicy();

    test('waits until reset when the primary rate limit is exhausted', () {
      final delay = policy.delayFor(
        _response(403, {
          'x-ratelimit-remaining': '0',
          'x-ratelimit-reset': '${_resetIn(const Duration(seconds: 30))}',
        }),
        1,
      );
      expect(delay, isNotNull);
      expect(delay!.inSeconds, inInclusiveRange(25, 31));
    });

    test('honours retry-after for a secondary rate limit', () {
      final delay = policy.delayFor(
        _response(429, {'x-ratelimit-remaining': '4321', 'retry-after': '17'}),
        1,
      );
      expect(delay, const Duration(seconds: 17));
    });

    test('does not retry a 403 that still has quota — that is authorization',
        () {
      final delay = policy.delayFor(
        _response(403, {'x-ratelimit-remaining': '4321'}),
        1,
      );
      expect(delay, isNull);
    });

    test('backs off exponentially on 5xx', () {
      expect(policy.delayFor(_response(500, {}), 1),
          const Duration(seconds: 1));
      expect(policy.delayFor(_response(502, {}), 2),
          const Duration(seconds: 2));
      expect(policy.delayFor(_response(503, {}), 3),
          const Duration(seconds: 4));
    });

    test('does not retry client errors that mean something', () {
      expect(policy.delayFor(_response(404, {}), 1), isNull);
      expect(policy.delayFor(_response(409, {}), 1), isNull);
      expect(policy.delayFor(_response(422, {}), 1), isNull);
    });

    test('gives up once maxAttempts is reached', () {
      expect(policy.delayFor(_response(500, {}), policy.maxAttempts), isNull);
    });

    test('refuses to sleep past maxDelay rather than hanging the app', () {
      final delay = policy.delayFor(
        _response(403, {
          'x-ratelimit-remaining': '0',
          'x-ratelimit-reset': '${_resetIn(const Duration(hours: 1))}',
        }),
        1,
      );
      expect(delay, isNull);
    });

    test('GitHubRetryPolicy.none never waits', () {
      expect(GitHubRetryPolicy.none.delayFor(_response(500, {}), 1), isNull);
    });
  });

  group('GitHubHttpClient retry integration', () {
    test('retries a 500 and returns the eventual success', () async {
      final slept = <Duration>[];
      final client = GitHubApiClient(
        token: 'test',
        httpClient: createMockClient(
          const {},
          sequences: {
            'GET /repos/o/r/git/ref/heads/main': [
              MockResponse(500, {'message': 'boom'}),
              MockResponse(200, {
                'ref': 'refs/heads/main',
                'object': {'sha': 'abc123'},
              }),
            ],
          },
        ),
        retryPolicy: GitHubRetryPolicy(sleep: (d) async => slept.add(d)),
      );
      addTearDown(client.close);

      final ref = await client.git.getRef(owner: 'o', repo: 'r', ref: 'heads/main');
      expect(ref.sha, 'abc123');
      expect(slept, [const Duration(seconds: 1)]);
    });

    test('surfaces the error once the policy stops retrying', () async {
      final client = GitHubApiClient(
        token: 'test',
        httpClient: createMockClient({
          'GET /repos/o/r/git/ref/heads/main':
              MockResponse(500, {'message': 'boom'}),
        }),
        retryPolicy: GitHubRetryPolicy(
          maxAttempts: 2,
          sleep: (_) async {},
        ),
      );
      addTearDown(client.close);

      expect(
        () => client.git.getRef(owner: 'o', repo: 'r', ref: 'heads/main'),
        throwsA(isA<GitHubException>()),
      );
    });
  });
}
