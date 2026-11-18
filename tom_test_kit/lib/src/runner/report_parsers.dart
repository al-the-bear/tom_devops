/// Readers for the machine-readable reports of the test runners testkit
/// drives besides `dart test`: each adds the tests it finds to a
/// [ResultCollector].
library;

import 'dart:convert';

import 'package:xml/xml.dart';

import '../model/test_run.dart';
import 'result_collector.dart';

/// The report formats testkit reads.
enum ReportFormat {
  /// testkit's own line protocol: one JSON object per line,
  /// `{"test": <name>, "result": "ok" | "fail" | "skip", "suite"?, "group"?}`,
  /// written to the file `$TESTKIT_REPORT` names. A project's own test script
  /// speaks it.
  testkit('testkit'),

  /// `go test -json` events on the runner's output.
  goJson('go-json'),

  /// libtest's text output (`cargo test`): `test <name> ... ok`.
  libtest('libtest'),

  /// JUnit XML (pytest `--junitxml`, Maven / Gradle surefire, `node --test
  /// --test-reporter=junit`, jest-junit, `ctest --output-junit`).
  junit('junit'),

  /// jest's `--json` report.
  jestJson('jest-json'),

  /// TAP (Test Anything Protocol, versions 12 to 14): `node --test
  /// --test-reporter=tap`, bats `--tap`, ava `--tap`, prove, tape, libtap.
  /// Read from the report file when the runner wrote one, else from its
  /// output.
  tap('tap');

  /// The name a `testkit:` section of `buildkit.yaml` uses for it.
  final String configName;

  const ReportFormat(this.configName);

  /// The format named [name] in a `testkit:` section, or null.
  static ReportFormat? byConfigName(String name) {
    for (final f in values) {
      if (f.configName == name) return f;
    }
    return null;
  }

  /// Whether the runner writes the report to a file (rather than its output).
  /// A [tap] report may be either: the file when there is one, else the
  /// output.
  bool get isFile => this == testkit || this == junit || this == jestJson;
}

/// Reads testkit's line protocol from [lines].
///
/// A line that is not a JSON object with `test` and `result` is skipped;
/// `result` is `ok` (or `pass`), `skip`, or anything else for a failure.
void parseTestkitLines(Iterable<String> lines, ResultCollector collector) {
  for (final line in lines) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('{')) continue;
    final Object? json;
    try {
      json = jsonDecode(trimmed);
    } on FormatException {
      continue;
    }
    if (json is! Map) continue;
    final name = json['test'];
    final result = json['result'];
    if (name is! String || name.isEmpty || result is! String) continue;
    final suite = json['suite'];
    final group = json['group'];
    collector.add(
      ReportedTest(
        name: name,
        suite: suite is String ? suite : null,
        groups: group is String ? group : (suite is String ? suite : null),
        result: switch (result) {
          'ok' || 'pass' || 'passed' => TestResult.ok,
          'skip' || 'skipped' => TestResult.skip,
          _ => TestResult.fail,
        },
      ),
    );
  }
}

/// Reads `go test -json` events from [lines].
///
/// Each test (subtests included, as `TestParent/sub`) is one result, grouped
/// by its package. A package that failed without running a test (its build
/// or setup failed) is a load failure carrying the build's and the package's
/// output.
void parseGoTestJson(Iterable<String> lines, ResultCollector collector) {
  final output = <String, List<String>>{};
  final testedPackages = <String>{};
  // Package -> the build that failed for it (`FailedBuild`, Go 1.24+), or
  // null when the package failed otherwise.
  final failedPackages = <String, String?>{};
  for (final line in lines) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('{')) continue;
    final Object? json;
    try {
      json = jsonDecode(trimmed);
    } on FormatException {
      continue;
    }
    if (json is! Map) continue;
    final action = json['Action'];
    // `build-output` (Go 1.24+) carries the build's `ImportPath`.
    final package = (json['Package'] ?? json['ImportPath']) as String?;
    if (action is! String || package == null) continue;
    final test = json['Test'];
    switch (action) {
      case 'output' || 'build-output':
        (output[package] ??= []).add(
          ((json['Output'] as String?) ?? '').trimRight(),
        );
      case 'pass' || 'fail' || 'skip' when test is String:
        testedPackages.add(package);
        collector.add(
          ReportedTest(
            name: test,
            suite: package,
            groups: package,
            result: switch (action) {
              'pass' => TestResult.ok,
              'skip' => TestResult.skip,
              _ => TestResult.fail,
            },
          ),
        );
      case 'fail':
        failedPackages[package] = json['FailedBuild'] as String?;
    }
  }
  for (final MapEntry(key: package, value: build) in failedPackages.entries) {
    if (testedPackages.contains(package)) continue;
    final said = [
      ...?output[build],
      ...?output[package],
    ].where((l) => l.isNotEmpty).toList();
    collector.addLoadFailure(
      package,
      said.isEmpty ? '(no output)' : said.join('\n'),
    );
  }
}

/// `test <name> ... <outcome>` in libtest's text output.
final _libtestLine = RegExp(r'^test (.+?) \.\.\. (ok|FAILED|ignored)\b');

/// The test binary cargo starts: `Running unittests src/lib.rs (target/...)`,
/// `Running tests/api.rs (target/...)`.
final _cargoRunning = RegExp(r'^\s*Running (.+?)(?: \(.*\))?\s*$');

/// cargo's doc-test run: `Doc-tests <crate>`.
final _cargoDocTests = RegExp(r'^\s*Doc-tests (\S+)\s*$');

/// Reads libtest's text output (`cargo test`) from [lines], with cargo's
/// progress lines on the same stream so each test is grouped by the test
/// binary it ran in.
void parseLibtestOutput(Iterable<String> lines, ResultCollector collector) {
  String? suite;
  for (final line in lines) {
    final running = _cargoRunning.firstMatch(line);
    if (running != null) {
      suite = running.group(1);
      continue;
    }
    final doc = _cargoDocTests.firstMatch(line);
    if (doc != null) {
      suite = 'doc-tests ${doc.group(1)}';
      continue;
    }
    final m = _libtestLine.firstMatch(line);
    if (m == null) continue;
    collector.add(
      ReportedTest(
        name: m.group(1)!,
        suite: suite,
        groups: suite,
        result: switch (m.group(2)) {
          'ok' => TestResult.ok,
          'ignored' => TestResult.skip,
          _ => TestResult.fail,
        },
      ),
    );
  }
}

/// Reads one JUnit XML document [xml] (a `<testsuites>` or `<testsuite>`
/// root). Each `<testcase>` is one result, grouped by its `classname` (else
/// the names of the `<testsuite>`s around it); a `<failure>` or `<error>`
/// child fails it, a `<skipped>` child skips it.
///
/// Throws [FormatException] when [xml] is not well-formed.
void parseJunitXml(String xml, ResultCollector collector) {
  final XmlDocument document;
  try {
    document = XmlDocument.parse(xml);
  } on XmlException catch (e) {
    throw FormatException('not a JUnit XML report: ${e.message}');
  }
  for (final testcase in document.findAllElements('testcase')) {
    final name = testcase.getAttribute('name');
    if (name == null || name.isEmpty) continue;
    // The enclosing <testsuite> names, outermost first.
    final suites = testcase.ancestorElements
        .where((e) => e.name.local == 'testsuite')
        .map((e) => e.getAttribute('name'))
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toList()
        .reversed
        .toList();
    // `node --test`'s reporter writes the constant classname `test` and puts
    // describe blocks into nested <testsuite>s.
    final classname = testcase.getAttribute('classname');
    final group =
        (classname != null && classname.isNotEmpty && classname != 'test')
        ? classname
        : suites.isEmpty
        ? null
        : suites.join(' > ');
    final children = testcase.childElements.map((e) => e.name.local).toSet();
    collector.add(
      ReportedTest(
        name: name,
        suite:
            testcase.getAttribute('file') ??
            (suites.isEmpty ? null : suites.last),
        groups: group,
        result: children.contains('failure') || children.contains('error')
            ? TestResult.fail
            : children.contains('skipped')
            ? TestResult.skip
            : TestResult.ok,
      ),
    );
  }
}

/// Reads jest's `--json` report [json]. Each assertion is one result, grouped
/// by its describe blocks; a test file that failed before any assertion ran
/// (it did not compile, or threw while loading) is a load failure.
///
/// Throws [FormatException] when [json] is not a jest report.
void parseJestJson(String json, ResultCollector collector) {
  final Object? report = jsonDecode(json);
  if (report is! Map || report['testResults'] is! List) {
    throw const FormatException('not a jest --json report (no testResults)');
  }
  for (final file in report['testResults'] as List) {
    if (file is! Map) continue;
    final path = file['name'] as String? ?? '';
    final assertions = (file['assertionResults'] as List?) ?? const [];
    if (assertions.isEmpty && file['status'] == 'failed') {
      collector.addLoadFailure(
        path,
        (file['message'] as String? ?? '(no message)').trim(),
      );
      continue;
    }
    for (final a in assertions) {
      if (a is! Map) continue;
      final title = a['title'] as String?;
      if (title == null) continue;
      final ancestors = ((a['ancestorTitles'] as List?) ?? const [])
          .whereType<String>()
          .toList();
      collector.add(
        ReportedTest(
          name: title,
          suite: path,
          groups: ancestors.isEmpty ? null : ancestors.join(' > '),
          result: switch (a['status']) {
            'passed' => TestResult.ok,
            'pending' || 'skipped' || 'todo' || 'disabled' => TestResult.skip,
            _ => TestResult.fail,
          },
        ),
      );
    }
  }
}

/// Where a TAP test point starts: indentation, `ok` / `not ok`, the number.
final _tapTestPoint = RegExp(r'^(\s*)(not ok|ok)\b\s*(\d+)?\s*(?:-\s*)?(.*)$');

/// A plan: `1..N`, possibly with a `# SKIP` reason.
final _tapPlan = RegExp(r'^(\s*)1\.\.(\d+)\b');

/// The directive at the end of a description: `# SKIP ...` / `# TODO ...`
/// (any case; `skipped` counts), after an unescaped `#`.
final _tapDirective = RegExp(
  r'(?:^|[^\\])#\s*(skip\S*|todo)\b\s*(.*)$',
  caseSensitive: false,
);

/// `# Subtest: <name>`, the comment that announces a subtest (TAP 14).
final _tapSubtest = RegExp(r'^(\s*)#\s*Subtest:\s*(.*)$');

/// `Bail out!` with its reason.
final _tapBailOut = RegExp(r'^\s*Bail out!\s*(.*)$');

/// Reads TAP (Test Anything Protocol, versions 12 to 14) from [lines].
///
/// - Each test point (`ok` / `not ok` with its description) is one result.
///   A `# SKIP` directive makes it skipped, whatever its `ok`; a `# TODO`
///   that fails is an expected failure and is recorded as skipped, a `# TODO`
///   that passes as passed.
/// - Subtests (indented, often announced by `# Subtest: <name>`) are grouped
///   by the test point they belong to, which closes them and is a group, not
///   a test; it is recorded only when it failed although none of its
///   subtests did (a hook failed, say).
/// - YAML diagnostic blocks (`---` ... `...`) and other comments are
///   skipped.
/// - `Bail out!`, and a plan (`1..N`) that does not match the number of test
///   points at its level, are load failures: the run is incomplete.
///
/// A test without a description is named by its number (`test 3`).
void parseTapOutput(Iterable<String> lines, ResultCollector collector) {
  // One frame per open level of subtests, the outermost first.
  final frames = <_TapFrame>[_TapFrame(0)];
  var inYaml = false;
  var yamlIndent = 0;

  void closeFramesDeeperThan(int indent, _TapPoint? parent) {
    while (frames.length > 1 && frames.last.indent > indent) {
      final frame = frames.removeLast();
      frame.checkPlan(collector, parent?.name);
      if (parent != null) {
        parent.children.addAll(frame.points);
      } else {
        // Subtests no test point closed (the output ended): keep them.
        frames.last.points.addAll(frame.points);
      }
    }
  }

  for (final raw in lines) {
    final line = raw.trimRight();
    if (inYaml) {
      final trimmed = line.trim();
      if (trimmed == '...' && _indentOf(line) <= yamlIndent) inYaml = false;
      continue;
    }
    if (line.trim() == '---') {
      inYaml = true;
      yamlIndent = _indentOf(line);
      continue;
    }
    final bail = _tapBailOut.firstMatch(line);
    if (bail != null) {
      collector.addLoadFailure(
        'TAP',
        'Bail out! ${bail.group(1)!.trim()}'.trim(),
      );
      continue;
    }
    final subtest = _tapSubtest.firstMatch(line);
    if (subtest != null) {
      // Announces a subtest whose own points are indented deeper.
      continue;
    }
    final plan = _tapPlan.firstMatch(line);
    if (plan != null) {
      final indent = plan.group(1)!.length;
      _frameAt(frames, indent).plan = int.parse(plan.group(2)!);
      continue;
    }
    final point = _tapTestPoint.firstMatch(line);
    if (point == null) continue;
    final indent = point.group(1)!.length;
    var description = point.group(4)!.trim();
    String? directive;
    final d = _tapDirective.firstMatch(description);
    if (d != null) {
      directive = d.group(1)!.toLowerCase();
      final hash = description.lastIndexOf('#', d.end - 1);
      description = description.substring(0, hash < 0 ? 0 : hash).trim();
    }
    description = description.replaceAll(r'\#', '#');
    final number = point.group(3);
    final passed = point.group(2) == 'ok';
    final result = directive != null && directive.startsWith('skip')
        ? TestResult.skip
        : directive == 'todo'
        ? (passed ? TestResult.ok : TestResult.skip)
        : (passed ? TestResult.ok : TestResult.fail);
    final current = _TapPoint(
      name: description.isNotEmpty
          ? description
          : 'test ${number ?? frames.last.points.length + 1}',
      result: result,
    );
    closeFramesDeeperThan(indent, current);
    final frame = _frameAt(frames, indent);
    frame.points.add(current);
  }
  closeFramesDeeperThan(0, null);
  frames.first.checkPlan(collector, null);
  for (final point in frames.first.points) {
    point.addTo(collector, null);
  }
}

/// A test point read from TAP, with the subtests it closed.
class _TapPoint {
  final String name;
  final TestResult result;
  final children = <_TapPoint>[];

  _TapPoint({required this.name, required this.result});

  /// Adds this point (a leaf) or its subtests (a group) to [collector].
  void addTo(ResultCollector collector, String? group) {
    if (children.isEmpty) {
      collector.add(ReportedTest(name: name, groups: group, result: result));
      return;
    }
    final own = group == null ? name : '$group > $name';
    for (final child in children) {
      child.addTo(collector, own);
    }
    if (result == TestResult.fail && !children.any((c) => c._failsAnywhere)) {
      collector.add(
        ReportedTest(name: name, groups: group, result: TestResult.fail),
      );
    }
  }

  bool get _failsAnywhere => children.isEmpty
      ? result == TestResult.fail
      : children.any((c) => c._failsAnywhere);
}

/// One level of TAP test points: their indentation, the points and the plan.
class _TapFrame {
  final int indent;
  final points = <_TapPoint>[];
  int? plan;

  _TapFrame(this.indent);

  /// Adds a load failure when the plan does not match the points.
  void checkPlan(ResultCollector collector, String? parent) {
    final planned = plan;
    if (planned == null || planned == points.length) return;
    collector.addLoadFailure(
      parent == null ? 'TAP' : 'TAP: $parent',
      'the plan 1..$planned announced $planned test(s), '
      '${points.length} reported',
    );
  }
}

/// The frame of [indent]: a deeper one is opened; a shallower indent takes
/// the innermost open frame not deeper than it.
_TapFrame _frameAt(List<_TapFrame> frames, int indent) {
  if (indent > frames.last.indent) {
    frames.add(_TapFrame(indent));
    return frames.last;
  }
  return frames.lastWhere(
    (f) => f.indent <= indent,
    orElse: () => frames.first,
  );
}

int _indentOf(String line) => line.length - line.trimLeft().length;
