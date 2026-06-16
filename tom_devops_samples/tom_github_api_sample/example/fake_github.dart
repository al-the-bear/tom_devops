// Fake GitHub — an in-memory transport for the tom_github_api samples.
//
// `GitHubApiClient` takes an injectable `http.Client`. By passing a
// `MockClient` (from package:http/testing.dart) that answers requests out of a
// few in-memory maps, every example becomes a deterministic, offline smoke
// test: no network, no token, no live mutations. The routing here mirrors the
// real GitHub REST endpoints the client actually calls — Issues, Labels,
// Comments, Search, and Workflow dispatch — and nothing else.
//
// Each example builds its own client with [newSampleClient], so the fake
// starts from the same seeded state every time and examples never interfere.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tom_github_api/tom_github_api.dart';

/// The repository every sample talks to (it only exists inside the fake).
const sampleRepo = 'al-the-bear/tom_issues';

/// Build a client wired to a fresh, seeded in-memory GitHub.
///
/// The token is a placeholder — the fake never checks it. Swap the
/// `httpClient` argument out (and pass a real token) to talk to live GitHub.
GitHubApiClient newSampleClient() =>
    GitHubApiClient(token: 'mock-token', httpClient: FakeGitHub().asClient());

/// A tiny, stateful, in-memory stand-in for the GitHub REST API.
class FakeGitHub {
  /// Fixed timestamp so model output is byte-for-byte deterministic.
  static const _date = '2026-01-15T09:00:00.000Z';

  /// Far-future reset instant for the rate-limit headers.
  static const _resetEpoch = 1893456000; // 2030-01-01T00:00:00Z

  final Map<int, Map<String, dynamic>> _issues = {};
  final Map<int, List<Map<String, dynamic>>> _comments = {};
  final Map<String, Map<String, dynamic>> _labels = {};

  int _nextIssue = 2;
  int _nextCommentId = 100;
  int _nextLabelId = 300;
  int _remaining = 5000;

  FakeGitHub() {
    _labels['new'] = _label('new', 'd73a4a', 'Newly reported, not yet triaged');
    _labels['severity:high'] =
        _label('severity:high', 'b60205', 'High severity');
    _labels['bug'] = _label('bug', 'd73a4a', "Something isn't working");

    _issues[1] = _issue(
      number: 1,
      title: 'Array parser crashes on empty arrays',
      body: 'Parsing `[]` throws a RangeError instead of an empty list.',
      state: 'open',
      labelNames: ['new', 'severity:high'],
      login: 'octocat',
    );
  }

  /// The `http.Client` to hand to [GitHubApiClient].
  http.Client asClient() => MockClient(_handle);

  // --- Routing -------------------------------------------------------------

  Future<http.Response> _handle(http.Request request) async {
    if (_remaining > 0) _remaining--;
    final segs = request.url.pathSegments;
    final method = request.method;

    if (segs.length == 2 && segs[0] == 'search' && segs[1] == 'issues') {
      return _search(request);
    }
    if (segs.length >= 3 && segs[0] == 'repos') {
      return _repo(method, segs.sublist(3), request);
    }
    return _json(404, {'message': 'Not Found'});
  }

  http.Response _repo(String method, List<String> p, http.Request request) {
    if (p.isEmpty) return _json(404, {'message': 'Not Found'});
    switch (p[0]) {
      case 'issues':
        return _issuesRoute(method, p, request);
      case 'labels':
        return _labelsRoute(method, p, request);
      case 'actions':
        if (p.length == 4 &&
            p[1] == 'workflows' &&
            p[3] == 'dispatches' &&
            method == 'POST') {
          return _noContent();
        }
    }
    return _json(404, {'message': 'Not Found'});
  }

  // --- Issues --------------------------------------------------------------

  http.Response _issuesRoute(
      String method, List<String> p, http.Request request) {
    if (p.length == 1) {
      if (method == 'POST') return _createIssue(request);
      if (method == 'GET') return _listIssues(request);
    }

    final number = p.length >= 2 ? int.tryParse(p[1]) : null;
    if (number == null) return _json(404, {'message': 'Not Found'});

    if (p.length == 2) {
      if (method == 'GET') {
        final issue = _issues[number];
        return issue == null
            ? _json(404, {'message': 'Not Found'})
            : _json(200, issue);
      }
      if (method == 'PATCH') return _updateIssue(number, request);
    }
    if (p.length == 3 && p[2] == 'comments') {
      if (method == 'POST') return _addComment(number, request);
      if (method == 'GET') return _json(200, _comments[number] ?? const []);
    }
    if (p.length == 3 && p[2] == 'labels' && method == 'POST') {
      return _addLabels(number, request);
    }
    if (p.length == 4 && p[2] == 'labels' && method == 'DELETE') {
      return _removeLabel(number, p[3]);
    }
    return _json(404, {'message': 'Not Found'});
  }

  http.Response _createIssue(http.Request request) {
    final data = jsonDecode(request.body) as Map<String, dynamic>;
    final number = _nextIssue++;
    final issue = _issue(
      number: number,
      title: data['title'] as String,
      body: data['body'] as String?,
      state: 'open',
      labelNames: (data['labels'] as List?)?.cast<String>() ?? const [],
      login: 'octodev',
      assignee: data['assignee'] as String?,
    );
    _issues[number] = issue;
    return _json(201, issue);
  }

  http.Response _updateIssue(int number, http.Request request) {
    final issue = _issues[number];
    if (issue == null) return _json(404, {'message': 'Not Found'});
    final data = jsonDecode(request.body) as Map<String, dynamic>;
    if (data.containsKey('title')) issue['title'] = data['title'];
    if (data.containsKey('body')) issue['body'] = data['body'];
    if (data.containsKey('state')) {
      issue['state'] = data['state'];
      if (data['state'] == 'closed') {
        issue['closed_at'] = _date;
      } else {
        issue.remove('closed_at');
      }
    }
    if (data.containsKey('labels')) {
      issue['labels'] =
          (data['labels'] as List).cast<String>().map(_resolveLabel).toList();
    }
    if (data.containsKey('assignee')) {
      issue['assignee'] = _user(data['assignee'] as String, 9000);
    }
    return _json(200, issue);
  }

  http.Response _listIssues(http.Request request) {
    final q = request.url.queryParameters;
    final state = q['state'] ?? 'open';
    final labelFilter = q['labels'];

    var list = _issues.values.toList();
    if (state != 'all') {
      list = list.where((i) => i['state'] == state).toList();
    }
    if (labelFilter != null && labelFilter.isNotEmpty) {
      final wanted = labelFilter.split(',');
      list = list.where((i) {
        final names = (i['labels'] as List)
            .map((l) => (l as Map)['name'] as String)
            .toSet();
        return wanted.every(names.contains);
      }).toList();
    }
    return _json(200, list);
  }

  // --- Comments ------------------------------------------------------------

  http.Response _addComment(int number, http.Request request) {
    if (!_issues.containsKey(number)) {
      return _json(404, {'message': 'Not Found'});
    }
    final data = jsonDecode(request.body) as Map<String, dynamic>;
    final comment = _comment(_nextCommentId++, data['body'] as String);
    _comments.putIfAbsent(number, () => []).add(comment);
    _issues[number]!['comments'] = _comments[number]!.length;
    return _json(201, comment);
  }

  // --- Labels --------------------------------------------------------------

  http.Response _labelsRoute(
      String method, List<String> p, http.Request request) {
    if (p.length == 1) {
      if (method == 'GET') return _json(200, _labels.values.toList());
      if (method == 'POST') return _createLabel(request);
    }
    if (p.length == 2) {
      final name = p[1];
      if (method == 'PATCH') return _updateLabel(name, request);
      if (method == 'DELETE') {
        _labels.remove(name);
        return _noContent();
      }
    }
    return _json(404, {'message': 'Not Found'});
  }

  http.Response _createLabel(http.Request request) {
    final data = jsonDecode(request.body) as Map<String, dynamic>;
    final name = data['name'] as String;
    final label = _label(
      name,
      data['color'] as String,
      data['description'] as String?,
    );
    _labels[name] = label;
    return _json(201, label);
  }

  http.Response _updateLabel(String name, http.Request request) {
    final label = _labels[name];
    if (label == null) return _json(404, {'message': 'Not Found'});
    final data = jsonDecode(request.body) as Map<String, dynamic>;
    if (data.containsKey('color')) label['color'] = data['color'];
    if (data.containsKey('description')) {
      label['description'] = data['description'];
    }
    if (data.containsKey('new_name')) {
      label['name'] = data['new_name'];
      _labels.remove(name);
      _labels[data['new_name'] as String] = label;
    }
    return _json(200, label);
  }

  http.Response _addLabels(int number, http.Request request) {
    final issue = _issues[number];
    if (issue == null) return _json(404, {'message': 'Not Found'});
    final data = jsonDecode(request.body) as Map<String, dynamic>;
    final toAdd = (data['labels'] as List).cast<String>();
    final labels = (issue['labels'] as List).cast<Map<String, dynamic>>();
    final names = labels.map((l) => l['name'] as String).toSet();
    for (final name in toAdd) {
      if (!names.contains(name)) labels.add(_resolveLabel(name));
    }
    return _json(200, labels);
  }

  http.Response _removeLabel(int number, String name) {
    final issue = _issues[number];
    if (issue == null) return _json(404, {'message': 'Not Found'});
    (issue['labels'] as List).removeWhere((l) => (l as Map)['name'] == name);
    return _json(200, issue['labels']);
  }

  // --- Search --------------------------------------------------------------

  http.Response _search(http.Request request) {
    final query = request.url.queryParameters['q'] ?? '';
    // Drop qualifiers like `repo:...` / `in:title`; match free-text terms
    // against issue titles (case-insensitive, all terms must appear).
    final terms = query
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !t.contains(':'))
        .map((t) => t.toLowerCase())
        .toList();
    final items = _issues.values.where((i) {
      final title = (i['title'] as String).toLowerCase();
      return terms.every(title.contains);
    }).toList();
    return _json(200, {
      'total_count': items.length,
      'incomplete_results': false,
      'items': items,
    });
  }

  // --- JSON builders -------------------------------------------------------

  Map<String, dynamic> _user(String login, int id) => {
        'login': login,
        'id': id,
        'avatar_url': 'https://avatars.example/$login',
      };

  Map<String, dynamic> _label(String name, String color, String? description) =>
      {
        'id': _nextLabelId++,
        'name': name,
        'color': color,
        'description': description,
      };

  Map<String, dynamic> _resolveLabel(String name) =>
      Map<String, dynamic>.from(_labels[name] ?? _label(name, 'ededed', null));

  Map<String, dynamic> _comment(int id, String body) => {
        'id': id,
        'body': body,
        'user': _user('octodev', 2000),
        'created_at': _date,
        'updated_at': _date,
      };

  Map<String, dynamic> _issue({
    required int number,
    required String title,
    String? body,
    required String state,
    required List<String> labelNames,
    required String login,
    String? assignee,
  }) =>
      {
        'number': number,
        'title': title,
        'body': ?body,
        'state': state,
        'labels': labelNames.map(_resolveLabel).toList(),
        'user': _user(login, 1000 + number),
        if (assignee != null) 'assignee': _user(assignee, 9000),
        'created_at': _date,
        'updated_at': _date,
        'comments': 0,
        'html_url': 'https://github.com/$sampleRepo/issues/$number',
      };

  // --- Responses -----------------------------------------------------------

  http.Response _json(int status, Object? body) => http.Response(
        jsonEncode(body),
        status,
        headers: _rateHeaders(contentType: true),
      );

  http.Response _noContent() =>
      http.Response('', 204, headers: _rateHeaders());

  Map<String, String> _rateHeaders({bool contentType = false}) => {
        if (contentType) 'content-type': 'application/json',
        'x-ratelimit-limit': '5000',
        'x-ratelimit-remaining': '$_remaining',
        'x-ratelimit-reset': '$_resetEpoch',
      };
}
