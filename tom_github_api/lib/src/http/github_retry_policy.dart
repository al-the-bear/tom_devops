import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// How the HTTP layer waits out GitHub's rate limits and transient failures.
///
/// GitHub signals three distinct conditions that all look like "try again
/// later" but need different waits:
///
/// * **Primary rate limit** — `403`/`429` with `x-ratelimit-remaining: 0`. The
///   only safe wait is until `x-ratelimit-reset`; retrying sooner is guaranteed
///   to fail and burns nothing but time.
/// * **Secondary rate limit** — `403`/`429` with a `retry-after` header and a
///   non-zero remaining count. GitHub tells us the wait explicitly.
/// * **Transient server errors** — `5xx`. Nothing is advertised, so this is the
///   one case that gets exponential backoff.
///
/// [sleep] is injectable so tests can exercise the waits without spending the
/// wall-clock time they describe.
class GitHubRetryPolicy {
  /// Total attempts including the first. `1` disables retrying.
  final int maxAttempts;

  /// First backoff step for transient errors; doubles per attempt.
  final Duration baseDelay;

  /// Ceiling on any single wait. A rate-limit reset an hour out would
  /// otherwise stall a caller indefinitely — past this cap the error is
  /// raised instead, so the caller decides whether to keep waiting.
  final Duration maxDelay;

  final Future<void> Function(Duration) sleep;

  const GitHubRetryPolicy({
    this.maxAttempts = 4,
    this.baseDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 2),
    this.sleep = _realSleep,
  });

  /// Never retries — the right choice inside an outer loop that owns its own
  /// recovery (a compare-and-swap retry, say).
  static const none = GitHubRetryPolicy(maxAttempts: 1);

  static Future<void> _realSleep(Duration d) => Future<void>.delayed(d);

  /// The wait before re-issuing [response], or `null` when it must not be
  /// retried. [attempt] is 1-based.
  Duration? delayFor(http.Response response, int attempt) {
    if (attempt >= maxAttempts) return null;
    final status = response.statusCode;
    final headers = response.headers;

    if (status == 403 || status == 429) {
      final remaining = int.tryParse(headers['x-ratelimit-remaining'] ?? '');
      if (remaining != null && remaining <= 0) {
        final reset = int.tryParse(headers['x-ratelimit-reset'] ?? '');
        if (reset == null) return null;
        final resetAt =
            DateTime.fromMillisecondsSinceEpoch(reset * 1000, isUtc: true);
        return _cap(resetAt.difference(DateTime.now().toUtc()));
      }
      final retryAfter = int.tryParse(headers['retry-after'] ?? '');
      if (retryAfter != null) return _cap(Duration(seconds: retryAfter));
      // A 403 with quota left is an authorization failure, not a wait.
      return null;
    }

    if (status >= 500) {
      return _cap(baseDelay * math.pow(2, attempt - 1).toInt());
    }
    return null;
  }

  /// Clamps to `[1s, maxDelay]`, or `null` when the wait exceeds the ceiling.
  /// A zero/negative wait means the window has already passed — retry at once,
  /// but never in a tight spin.
  Duration? _cap(Duration d) {
    if (d > maxDelay) return null;
    return d.isNegative || d.inMilliseconds < 1000
        ? const Duration(seconds: 1)
        : d;
  }
}
