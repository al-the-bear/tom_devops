import 'models/github_rate_limit.dart';

/// How GitHub's *secondary* rate limits are recognised.
///
/// They are recognisable by nothing but the response body. A secondary limit
/// leaves the primary quota untouched, so `x-ratelimit-remaining` still reads
/// in the thousands and the headers are byte-for-byte an authorization
/// failure. The retry policy and the exception mapping both classify through
/// this one type, so they cannot come to different conclusions about the same
/// response.
///
/// Matched on the raw body rather than a decoded `message` field: GitHub
/// answers some abuse-detection cases with an HTML page, and a JSON decode
/// that threw would turn the one recoverable 403 back into a refusal.
enum GitHubSecondaryLimitKind {
  /// Not a secondary limit at all.
  none,

  /// "You have exceeded a secondary rate limit. Please wait a few minutes."
  /// Measured to clear inside a minute or two — worth waiting out.
  throttled,

  /// "…and have been temporarily blocked from content creation." The
  /// abuse-detection block, measured still in force fifteen minutes after an
  /// unpaced burst earned it. Not something a flush can wait out.
  blocked;

  /// Classifies a raw response body.
  static GitHubSecondaryLimitKind of(String body) {
    if (body.isEmpty) return none;
    final lower = body.toLowerCase();
    final isSecondary = lower.contains('secondary rate limit') ||
        // The older wording, still served by some endpoints.
        lower.contains('abuse detection');
    if (!isSecondary) return none;
    return lower.contains('blocked from content creation')
        ? blocked
        : throttled;
  }
}

/// Base exception for all GitHub API errors.
class GitHubException implements Exception {
  final int statusCode;
  final String message;
  final String? documentationUrl;
  final Map<String, dynamic>? responseBody;

  const GitHubException({
    required this.statusCode,
    required this.message,
    this.documentationUrl,
    this.responseBody,
  });

  /// [rawBody] is the undecoded response body, when the caller still has it.
  /// A secondary rate limit is recognisable only from the body text, and
  /// GitHub answers some of them with an HTML page that never became [body].
  factory GitHubException.fromResponse(
    int statusCode,
    Map<String, dynamic> body, {
    Map<String, String>? headers,
    String? rawBody,
  }) {
    final message = body['message'] as String? ?? 'Unknown error';
    final docUrl = body['documentation_url'] as String?;

    // Distinguish 403 causes
    if (statusCode == 403 && headers != null) {
      final remaining = headers['x-ratelimit-remaining'];
      if (remaining == '0') {
        return GitHubRateLimitException(
          statusCode: statusCode,
          message: message,
          documentationUrl: docUrl,
          responseBody: body,
          rateLimit: GitHubRateLimit.fromHeaders(headers),
        );
      }
    }

    if (statusCode == 403 || statusCode == 429) {
      final kind = GitHubSecondaryLimitKind.of(rawBody ?? message);
      if (kind != GitHubSecondaryLimitKind.none) {
        return GitHubSecondaryRateLimitException(
          statusCode: statusCode,
          message: message,
          documentationUrl: docUrl,
          responseBody: body,
          kind: kind,
        );
      }
    }

    return switch (statusCode) {
      401 => GitHubAuthException(
          statusCode: statusCode,
          message: message,
          documentationUrl: docUrl,
          responseBody: body,
        ),
      403 => GitHubAuthException(
          statusCode: statusCode,
          message: message,
          documentationUrl: docUrl,
          responseBody: body,
        ),
      404 => GitHubNotFoundException(
          statusCode: statusCode,
          message: message,
          documentationUrl: docUrl,
          responseBody: body,
        ),
      422 => GitHubValidationException(
          statusCode: statusCode,
          message: message,
          documentationUrl: docUrl,
          responseBody: body,
          errors: (body['errors'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>(),
        ),
      _ => GitHubException(
          statusCode: statusCode,
          message: message,
          documentationUrl: docUrl,
          responseBody: body,
        ),
    };
  }

  @override
  String toString() => 'GitHubException($statusCode): $message';
}

/// 404 Not Found.
class GitHubNotFoundException extends GitHubException {
  const GitHubNotFoundException({
    required super.statusCode,
    required super.message,
    super.documentationUrl,
    super.responseBody,
  });

  @override
  String toString() => 'GitHubNotFoundException($statusCode): $message';
}

/// 401 Unauthorized / 403 Forbidden (not rate limit).
class GitHubAuthException extends GitHubException {
  const GitHubAuthException({
    required super.statusCode,
    required super.message,
    super.documentationUrl,
    super.responseBody,
  });

  @override
  String toString() => 'GitHubAuthException($statusCode): $message';
}

/// 422 Unprocessable Entity — validation errors.
class GitHubValidationException extends GitHubException {
  final List<Map<String, dynamic>>? errors;

  const GitHubValidationException({
    required super.statusCode,
    required super.message,
    super.documentationUrl,
    super.responseBody,
    this.errors,
  });

  @override
  String toString() => 'GitHubValidationException($statusCode): $message';
}

/// 403/429 caused by a *secondary* rate limit — "you are going too fast",
/// not "you may not do this".
///
/// Separate from [GitHubRateLimitException] because the primary quota is
/// untouched: there is no reset time to wait for, and the recovery is
/// different. Separate from [GitHubAuthException] because a caller told its
/// token was refused will go and check the token, which is the one thing that
/// is not wrong here.
class GitHubSecondaryRateLimitException extends GitHubException {
  final GitHubSecondaryLimitKind kind;

  const GitHubSecondaryRateLimitException({
    required super.statusCode,
    required super.message,
    super.documentationUrl,
    super.responseBody,
    required this.kind,
  });

  /// Whether GitHub's abuse detection has blocked content creation outright,
  /// rather than merely throttling it. Measured: the throttle clears in about
  /// a minute; the block was still in force fifteen minutes on. A caller that
  /// sees this should stop and journal the work, not keep retrying.
  bool get blockedFromContentCreation =>
      kind == GitHubSecondaryLimitKind.blocked;

  @override
  String toString() => 'GitHubSecondaryRateLimitException($statusCode): '
      '$message${blockedFromContentCreation ? ' [content creation blocked]' : ''}';
}

/// 403 Rate Limit Exceeded.
class GitHubRateLimitException extends GitHubException {
  final GitHubRateLimit rateLimit;

  const GitHubRateLimitException({
    required super.statusCode,
    required super.message,
    super.documentationUrl,
    super.responseBody,
    required this.rateLimit,
  });

  @override
  String toString() =>
      'GitHubRateLimitException: $message (resets at ${rateLimit.resetAt})';
}
