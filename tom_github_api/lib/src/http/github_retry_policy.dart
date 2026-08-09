import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../github_exception.dart';

/// How the HTTP layer waits out GitHub's rate limits and transient failures.
///
/// GitHub signals three distinct conditions that all look like "try again
/// later" but need different waits:
///
/// * **Primary rate limit** — `403`/`429` with `x-ratelimit-remaining: 0`. The
///   only safe wait is until `x-ratelimit-reset`; retrying sooner is guaranteed
///   to fail and burns nothing but time.
/// * **Secondary rate limit** — `403`/`429` with a non-zero remaining count.
///   GitHub *sometimes* states the wait in a `retry-after` header, in which
///   case that is the wait. When it does not, the **body message** is the only
///   signal there is: the headers are byte-for-byte an authorization failure,
///   because the primary quota is untouched. Missing that case is not a missed
///   optimisation — a burst of issue writes trips this limit routinely, and a
///   caller that treats it as a refusal (D11 §7.3 propagates refusals) fails a
///   flush that would have succeeded a minute later. Backoff starts at
///   [secondaryDelay], GitHub's own "wait at least one minute" guidance.
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

  /// First backoff step for a secondary rate limit GitHub did not put a
  /// `retry-after` on; doubles per attempt like [baseDelay].
  ///
  /// A minute rather than a second because GitHub says so — "wait at least one
  /// minute before retrying" — and because a secondary limit is a *rate*
  /// judgement, not a transient fault: retrying in a second re-earns it.
  final Duration secondaryDelay;

  /// Ceiling on any single wait. A rate-limit reset an hour out would
  /// otherwise stall a caller indefinitely — past this cap the error is
  /// raised instead, so the caller decides whether to keep waiting.
  final Duration maxDelay;

  /// Ceiling on a *secondary*-limit wait specifically.
  ///
  /// Higher than [maxDelay] because the two situations are not alike. A
  /// primary-quota reset an hour out, or a server that has been failing for
  /// minutes, is a condition the caller should be told about — it may have
  /// something better to do than wait. A secondary limit is GitHub saying
  /// "slower", it clears on its own, and there is nothing better to do: giving
  /// up turns a flush that would have finished into a refusal, which D11 §7.3
  /// propagates to the user as a failure. Measured against a real repository, a
  /// 50-section create-flush was still blocked after the 3 minutes the general
  /// ceiling allowed, and the block cleared shortly after.
  final Duration maxSecondaryDelay;

  final Future<void> Function(Duration) sleep;

  const GitHubRetryPolicy({
    this.maxAttempts = 4,
    this.baseDelay = const Duration(seconds: 1),
    this.secondaryDelay = const Duration(seconds: 60),
    this.maxDelay = const Duration(minutes: 2),
    this.maxSecondaryDelay = const Duration(minutes: 5),
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
      final kind = GitHubSecondaryLimitKind.of(response.body);
      // The abuse-detection block is not a wait, it is a refusal wearing a
      // wait's clothing. Measured still in force fifteen minutes after an
      // unpaced burst earned it, so spending the secondary budget on it only
      // delays the failure the caller is going to see anyway — and D11 §7.3
      // journals the work rather than losing it.
      if (kind == GitHubSecondaryLimitKind.blocked) return null;
      final retryAfter = int.tryParse(headers['retry-after'] ?? '');
      if (retryAfter != null) return _cap(Duration(seconds: retryAfter));
      if (kind == GitHubSecondaryLimitKind.throttled) {
        return _cap(secondaryDelay * math.pow(2, attempt - 1).toInt(),
            ceiling: maxSecondaryDelay);
      }
      // A 403 with quota left and no secondary signal is an authorization
      // failure, not a wait.
      return null;
    }

    if (status >= 500) {
      return _cap(baseDelay * math.pow(2, attempt - 1).toInt());
    }
    return null;
  }

  /// Clamps to `[1s, ceiling]`, or `null` when the wait exceeds the ceiling.
  /// A zero/negative wait means the window has already passed — retry at once,
  /// but never in a tight spin.
  Duration? _cap(Duration d, {Duration? ceiling}) {
    if (d > (ceiling ?? maxDelay)) return null;
    return d.isNegative || d.inMilliseconds < 1000
        ? const Duration(seconds: 1)
        : d;
  }
}
