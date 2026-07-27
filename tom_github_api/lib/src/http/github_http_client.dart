import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../github_exception.dart';
import '../models/github_conditional.dart';
import '../models/github_rate_limit.dart';
import 'github_retry_policy.dart';

/// Internal HTTP wrapper that adds authentication, content headers,
/// rate limit tracking, retry/backoff, and error handling to all GitHub API
/// requests.
class GitHubHttpClient {
  /// Media type that makes the contents and blobs endpoints return the file
  /// body itself instead of a JSON envelope with a base64 field. Required for
  /// anything over 1 MB, and cheaper for everything else.
  static const rawMediaType = 'application/vnd.github.raw';

  final String _token;
  final http.Client _httpClient;
  final String _baseUrl;
  final GitHubRetryPolicy _retry;

  GitHubRateLimit? _lastRateLimit;

  GitHubHttpClient({
    required String token,
    required http.Client httpClient,
    required String baseUrl,
    GitHubRetryPolicy retryPolicy = const GitHubRetryPolicy(),
  })  : _token = token,
        _httpClient = httpClient,
        _baseUrl = baseUrl,
        _retry = retryPolicy;

  /// Rate limit info from the most recent response.
  GitHubRateLimit? get lastRateLimit => _lastRateLimit;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $_token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  // --- JSON verbs -------------------------------------------------------

  /// GET request, returning parsed JSON.
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final response = await getRaw(path, queryParams: queryParams);
    return _decodeObject(response);
  }

  /// GET request returning the raw [http.Response] (for pagination).
  Future<http.Response> getRaw(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = {..._headers, ...?extraHeaders};
    final response = await _send(() => _httpClient.get(uri, headers: headers));
    _checkForErrors(response);
    return response;
  }

  /// GET request from a full URL (for following pagination links).
  Future<http.Response> getUrl(String url) async {
    final uri = Uri.parse(url);
    final response = await _send(() => _httpClient.get(uri, headers: _headers));
    _checkForErrors(response);
    return response;
  }

  /// GET request whose body is a JSON array (e.g. a directory listing).
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final response = await getRaw(path, queryParams: queryParams);
    if (response.body.isEmpty) return const [];
    return jsonDecode(response.body) as List<dynamic>;
  }

  /// POST request, returning parsed JSON.
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async =>
      _decodeObject(await postRaw(path, body: body));

  /// POST request returning raw [http.Response] (for array responses).
  Future<http.Response> postRaw(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _sendBody('POST', path, body);
    _checkForErrors(response);
    return response;
  }

  /// PATCH request, returning parsed JSON.
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _sendBody('PATCH', path, body);
    _checkForErrors(response);
    return _decodeObject(response);
  }

  /// PUT request, returning parsed JSON. Used by the contents API.
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _sendBody('PUT', path, body);
    _checkForErrors(response);
    return _decodeObject(response);
  }

  /// DELETE request. Returns void.
  Future<void> delete(String path) async {
    final uri = _buildUri(path);
    final response =
        await _send(() => _httpClient.delete(uri, headers: _headers));
    _checkForErrors(response);
  }

  /// DELETE request carrying a JSON body — the contents API needs the blob
  /// sha and commit message in the body of a DELETE.
  Future<Map<String, dynamic>> deleteWithBody(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _sendBody('DELETE', path, body);
    _checkForErrors(response);
    return _decodeObject(response);
  }

  /// POST request that expects 204 No Content (e.g., workflow dispatch).
  Future<void> postNoContent(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await _sendBody('POST', path, body);
    _checkForErrors(response);
  }

  // --- Conditional / binary ---------------------------------------------

  /// Conditional JSON GET. A `304` is reported as
  /// [GitHubConditional.unmodified] rather than an error.
  Future<GitHubConditional<Map<String, dynamic>>> getConditional(
    String path, {
    Map<String, String>? queryParams,
    String? ifNoneMatch,
  }) async {
    final uri = _buildUri(path, queryParams);
    final headers = {
      ..._headers,
      if (ifNoneMatch != null) 'If-None-Match': ifNoneMatch,
    };
    final response = await _send(() => _httpClient.get(uri, headers: headers));
    if (response.statusCode == 304) {
      return GitHubConditional.unmodified(etag: ifNoneMatch);
    }
    _checkForErrors(response);
    return GitHubConditional.modified(
      _decodeObject(response),
      etag: response.headers['etag'],
    );
  }

  /// GET the response body as bytes, without JSON decoding.
  ///
  /// [accept] defaults to [rawMediaType] so file content comes back verbatim;
  /// that is the only form that works above the 1 MB base64 ceiling.
  Future<GitHubConditional<Uint8List>> getBytes(
    String path, {
    String accept = rawMediaType,
    String? ifNoneMatch,
  }) async {
    final uri = _buildUri(path);
    final headers = {
      ..._headers,
      'Accept': accept,
      if (ifNoneMatch != null) 'If-None-Match': ifNoneMatch,
    };
    final response = await _send(() => _httpClient.get(uri, headers: headers));
    if (response.statusCode == 304) {
      return GitHubConditional.unmodified(etag: ifNoneMatch);
    }
    _checkForErrors(response);
    return GitHubConditional.modified(
      Uint8List.fromList(response.bodyBytes),
      etag: response.headers['etag'],
    );
  }

  void close() {
    _httpClient.close();
  }

  // --- Internals ---

  /// Issues a request, waiting out rate limits and transient 5xx per the
  /// retry policy. Returns the last response whatever its status — throwing is
  /// the caller's decision, because a `304` and a `409` are both meaningful.
  Future<http.Response> _send(Future<http.Response> Function() issue) async {
    var attempt = 0;
    while (true) {
      attempt++;
      final response = await issue();
      _updateRateLimit(response.headers);
      if (response.statusCode < 400) return response;
      final delay = _retry.delayFor(response, attempt);
      if (delay == null) return response;
      await _retry.sleep(delay);
    }
  }

  Future<http.Response> _sendBody(
    String method,
    String path,
    Map<String, dynamic>? body,
  ) {
    final uri = _buildUri(path);
    final headers = {..._headers, 'Content-Type': 'application/json'};
    final encoded = body != null ? jsonEncode(body) : null;
    return _send(() {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (encoded != null) request.body = encoded;
      return _httpClient.send(request).then(http.Response.fromStream);
    });
  }

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final base = _baseUrl.endsWith('/') ? _baseUrl : '$_baseUrl/';
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$base$cleanPath');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  void _checkForErrors(http.Response response) {
    if (response.statusCode >= 400) {
      _throwException(response);
    }
  }

  Never _throwException(http.Response response) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = {'message': response.body};
    }
    throw GitHubException.fromResponse(
      response.statusCode,
      body,
      headers: response.headers,
    );
  }

  void _updateRateLimit(Map<String, String> headers) {
    if (headers.containsKey('x-ratelimit-limit')) {
      _lastRateLimit = GitHubRateLimit.fromHeaders(headers);
    }
  }
}

/// Parse the `Link` header from a paginated response.
///
/// Returns a map of rel -> url, e.g. `{'next': '...', 'last': '...'}`.
Map<String, String> parseLinkHeader(String? linkHeader) {
  if (linkHeader == null || linkHeader.isEmpty) return {};
  final links = <String, String>{};
  for (final part in linkHeader.split(',')) {
    final match = RegExp(r'<([^>]+)>;\s*rel="([^"]+)"').firstMatch(part.trim());
    if (match != null) {
      links[match.group(2)!] = match.group(1)!;
    }
  }
  return links;
}
