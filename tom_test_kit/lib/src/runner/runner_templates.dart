/// Test-runner templates: a runner described by configuration, not code.
///
/// A template names a command (with `{report}`), the format and place of its
/// report, how it selects single tests by name (for `--failed` /
/// `--mismatched`) and when it applies to a project. testkit carries
/// [builtInRunnerTemplates]; the workspace adds or changes them under
/// `testkit: runners:` in `buildkit_master.yaml`, a project under
/// `testkit: runners:` in its `buildkit.yaml`, and a project picks one with
/// `testkit: runner: <name>`:
///
/// ```yaml
/// testkit:
///   runners:
///     pytest-uv:
///       command: uv run pytest -q --junitxml={report}
///       report: junit
///       filter: {args: ["-k", "{names}"], join: " or ", regex: false, cut: "["}
///       applies: {nature: python, files: [uv.lock]}
/// ```
library;

import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:tom_build_base/tom_build_base_v2.dart';

import 'report_parsers.dart';

/// In a filter argument: every selected name, joined with the filter's
/// `join`.
const namesPlaceholder = '{names}';

/// A filter argument that is exactly this is repeated once per name.
const namePlaceholder = '{name}';

/// How a runner selects tests by name: the arguments appended to its
/// command.
class NameFilter {
  /// The arguments; `{names}` inside one is replaced by the names joined
  /// with [join], an argument that is exactly `{name}` becomes one argument
  /// per name.
  final List<String> args;

  /// What joins the names in `{names}`.
  final String join;

  /// Whether each name is escaped as a regular expression (the runner reads
  /// the argument as a pattern).
  final bool regex;

  /// Each name is cut at the first occurrence of this text, and duplicates
  /// dropped: `/` runs a Go subtest's parent, `[` a parametrized pytest test.
  final String? cut;

  /// Each name keeps only what follows the last occurrence of this text:
  /// ` > ` turns vitest's `math > adds` into the title `adds`.
  final String? tail;

  /// Arguments repeated once per name after [args], `{name}` in them
  /// replaced: `[--match, '{name}']` gives `--match a --match b`.
  final List<String> each;

  const NameFilter({
    this.args = const [],
    this.join = '|',
    this.regex = true,
    this.cut,
    this.tail,
    this.each = const [],
  });

  /// The arguments that select [names]; empty when [names] is.
  List<String> argsFor(Iterable<String> names) {
    final selected = <String>[];
    for (final name in names) {
      var n = name;
      final tailAt = tail == null ? -1 : n.lastIndexOf(tail!);
      if (tailAt >= 0) n = n.substring(tailAt + tail!.length);
      final cutAt = cut == null ? -1 : n.indexOf(cut!);
      if (cutAt > 0) n = n.substring(0, cutAt);
      final value = regex ? RegExp.escape(n) : n;
      if (!selected.contains(value)) selected.add(value);
    }
    if (selected.isEmpty) return const [];
    return [
      for (final arg in args)
        if (arg == namePlaceholder)
          ...selected
        else
          arg.replaceAll(namesPlaceholder, selected.join(join)),
      for (final name in selected)
        for (final arg in each) arg.replaceAll(namePlaceholder, name),
    ];
  }

  /// Reads a `filter:` map; throws [FormatException] naming what is wrong.
  static NameFilter fromYaml(Object? yaml) {
    if (yaml is! Map) throw const FormatException('filter: must be a map');
    List<String> strings(String key) {
      final value = yaml[key];
      if (value == null) return const [];
      if (value is! List || value.any((a) => a is! String && a is! num)) {
        throw FormatException('filter: $key: must be a list of strings');
      }
      return [for (final a in value) '$a'];
    }

    final list = strings('args');
    final each = strings('each');
    if (!list.any(
          (a) => a == namePlaceholder || a.contains(namesPlaceholder),
        ) &&
        !each.any((a) => a.contains(namePlaceholder))) {
      throw const FormatException(
        'filter: args: must hold {names} or an argument {name}, or each: '
        '{name}',
      );
    }
    final join = yaml['join'];
    final regex = yaml['regex'];
    final cut = yaml['cut'];
    final tail = yaml['tail'];
    return NameFilter(
      args: list,
      each: each,
      join: join is String ? join : '|',
      regex: regex is bool ? regex : true,
      cut: cut is String && cut.isNotEmpty ? cut : null,
      tail: tail is String && tail.isNotEmpty ? tail : null,
    );
  }
}

/// When a template applies to a project: every condition given holds.
class AppliesWhen {
  /// The project has one of these natures (`typescript`, `javascript`,
  /// `python`, `java`, `go`, `rust`, `cpp`, `c`).
  final Set<String> natures;

  /// One of these files (globs, relative to the project) exists.
  final List<String> files;

  /// Each named file exists and matches its regular expression
  /// (`CMakeLists.txt: enable_testing`).
  final Map<String, String> contains;

  /// `package.json` names one of these in `dependencies` or
  /// `devDependencies`.
  final Set<String> dependencies;

  /// Each named `package.json` script exists and matches its regular
  /// expression (`test: \bjest\b`).
  final Map<String, String> scripts;

  const AppliesWhen({
    this.natures = const {},
    this.files = const [],
    this.contains = const {},
    this.dependencies = const {},
    this.scripts = const {},
  });

  /// Whether the project at [projectPath] with [projectNatures] meets every
  /// condition.
  bool holds(String projectPath, List<RunFolder> projectNatures) {
    if (natures.isNotEmpty &&
        !projectNatures.any((n) => natures.contains(natureName(n)))) {
      return false;
    }
    if (files.isNotEmpty && !files.any((f) => _globMatches(projectPath, f))) {
      return false;
    }
    for (final entry in contains.entries) {
      final file = File(p.join(projectPath, entry.key));
      if (!file.existsSync()) return false;
      final String text;
      try {
        text = file.readAsStringSync();
      } on FileSystemException {
        return false;
      }
      if (!RegExp(entry.value, multiLine: true).hasMatch(text)) return false;
    }
    if (dependencies.isNotEmpty &&
        !packageJsonDependencies(projectPath).any(dependencies.contains)) {
      return false;
    }
    if (scripts.isNotEmpty) {
      final present = packageJsonScripts(projectPath);
      for (final entry in scripts.entries) {
        final script = present[entry.key];
        if (script == null || !RegExp(entry.value).hasMatch(script)) {
          return false;
        }
      }
    }
    return true;
  }

  /// Reads an `applies:` map; throws [FormatException] naming what is wrong.
  static AppliesWhen fromYaml(Object? yaml) {
    if (yaml is! Map) throw const FormatException('applies: must be a map');
    Set<String> names(String key) => {...?_strings(yaml[key], key)};
    final natures = names('nature');
    final unknown = natures.difference(_natureNames.toSet());
    if (unknown.isNotEmpty) {
      throw FormatException(
        'applies: unknown nature ${unknown.join(', ')} (one of '
        '${_natureNames.join(', ')})',
      );
    }
    Map<String, String> patterns(String key, String what) {
      final value = yaml[key];
      if (value == null) return const {};
      if (value is! Map) {
        throw FormatException('applies: $key: must map $what to a pattern');
      }
      return {for (final e in value.entries) '${e.key}': '${e.value}'};
    }

    final applies = AppliesWhen(
      natures: natures,
      files: [...?_strings(yaml['files'], 'files')],
      contains: patterns('contains', 'a file'),
      dependencies: names('dependency'),
      scripts: patterns('scripts', 'a package.json script'),
    );
    if (applies.natures.isEmpty &&
        applies.files.isEmpty &&
        applies.contains.isEmpty &&
        applies.dependencies.isEmpty &&
        applies.scripts.isEmpty) {
      throw const FormatException(
        'applies: needs nature:, files:, contains:, dependency: or scripts:',
      );
    }
    return applies;
  }
}

/// A named runner: the command, its report, its name filter and when it
/// applies.
class RunnerTemplate {
  /// The name a project selects it by (`testkit: runner: <name>`).
  final String name;

  /// The shell command, run in the project; `{report}` is replaced by the
  /// report file's path.
  final String command;

  /// The format of the report.
  final ReportFormat format;

  /// Where a file report lands, relative to the project (a glob for several
  /// files); null: the file `$TESTKIT_REPORT` names.
  final String? reportPath;

  /// How it selects tests by name; null: it cannot, every test runs.
  final NameFilter? filter;

  /// When it applies; null: only when a project names it.
  final AppliesWhen? applies;

  /// Where it is defined: `built-in`, `buildkit_master.yaml` or
  /// `buildkit.yaml`.
  final String source;

  const RunnerTemplate({
    required this.name,
    required this.command,
    required this.format,
    required this.source,
    this.reportPath,
    this.filter,
    this.applies,
  });

  /// Reads a template from [yaml]; the fields it leaves out are taken from
  /// [base] (a template of the same name it changes). Throws
  /// [FormatException] naming what is wrong.
  static RunnerTemplate fromYaml(
    String name,
    Object? yaml, {
    required String source,
    RunnerTemplate? base,
  }) {
    if (yaml is! Map) {
      throw FormatException('runner $name must be a map');
    }
    try {
      final command = yaml['command'] ?? base?.command;
      if (command is! String || command.trim().isEmpty) {
        throw const FormatException('needs a command:');
      }
      final reportName = yaml['report'];
      final ReportFormat format;
      if (reportName == null) {
        format = base?.format ?? ReportFormat.testkit;
      } else {
        format =
            ReportFormat.byConfigName('$reportName') ??
            (throw FormatException(
              'unknown report "$reportName" (one of '
              '${ReportFormat.values.map((f) => f.configName).join(', ')})',
            ));
      }
      final reportPath = yaml.containsKey('report-path')
          ? yaml['report-path']
          : base?.reportPath;
      return RunnerTemplate(
        name: name,
        command: command,
        format: format,
        reportPath: reportPath is String ? reportPath : null,
        filter: yaml.containsKey('filter')
            ? (yaml['filter'] == null
                  ? null
                  : NameFilter.fromYaml(yaml['filter']))
            : base?.filter,
        applies: yaml.containsKey('applies')
            ? (yaml['applies'] == null
                  ? null
                  : AppliesWhen.fromYaml(yaml['applies']))
            : base?.applies,
        source: source,
      );
    } on FormatException catch (e) {
      throw FormatException('runner $name ($source): ${e.message}');
    }
  }
}

/// testkit's own templates, in the order they are tried: the same language
/// precedence as buildkit's `:test` (TypeScript and JavaScript, then Python,
/// Java, Go, Rust). Dart and Flutter projects run with `dart test` /
/// `flutter test`, which is no template.
const builtInRunnerTemplates = <RunnerTemplate>[
  RunnerTemplate(
    name: 'npm-test-jest',
    // The project's own jest invocation (its config and flags), when its
    // test script runs jest.
    command: 'npm test -- --json --outputFile={report}',
    format: ReportFormat.jestJson,
    filter: NameFilter(args: ['-t', '($namesPlaceholder)\$']),
    applies: AppliesWhen(
      natures: {'typescript', 'javascript'},
      scripts: {'test': r'(^|[\s/;&|])jest\b'},
    ),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'jest',
    command: 'npx jest --json --outputFile={report}',
    format: ReportFormat.jestJson,
    // jest matches -t against the full name (describe blocks and title).
    filter: NameFilter(args: ['-t', '($namesPlaceholder)\$']),
    applies: AppliesWhen(
      natures: {'typescript', 'javascript'},
      dependencies: {'jest'},
    ),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'vitest',
    command: 'npx vitest run --reporter=junit --outputFile={report}',
    format: ReportFormat.junit,
    // vitest reports `math > adds`; -t matches the full name joined by
    // spaces, which ends with the title.
    filter: NameFilter(args: ['-t', '($namesPlaceholder)\$'], tail: ' > '),
    applies: AppliesWhen(
      natures: {'typescript', 'javascript'},
      dependencies: {'vitest'},
    ),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'mocha',
    command: 'npx mocha --reporter json --reporter-option output={report}',
    format: ReportFormat.mochaJson,
    // --grep matches the full title (describe blocks and title).
    filter: NameFilter(args: ['--grep', '($namesPlaceholder)\$']),
    applies: AppliesWhen(
      natures: {'typescript', 'javascript'},
      dependencies: {'mocha'},
    ),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'ava',
    command: 'npx ava --tap',
    format: ReportFormat.tap,
    // --match takes a title (with * wildcards), once per test.
    filter: NameFilter(each: ['--match', namePlaceholder], regex: false),
    applies: AppliesWhen(
      natures: {'typescript', 'javascript'},
      dependencies: {'ava'},
    ),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'jasmine',
    // jasmine-reporters' JUnit reporter through --reporter, which wants a
    // module exporting the reporter's constructor: a one-line module in
    // testlog/. It writes junitresults.xml in the project.
    command:
        'mkdir -p testlog && printf %s '
        '\'module.exports = require("jasmine-reporters").JUnitXmlReporter;\' '
        '> testlog/testkit_jasmine_junit.cjs && '
        'npx jasmine --reporter=./testlog/testkit_jasmine_junit.cjs',
    format: ReportFormat.junit,
    reportPath: 'junitresults.xml',
    // No name filter: jasmine-reporters (2.5.2) writes the specs jasmine's
    // --filter excludes as passed testcases, so a filtered run would record
    // tests that did not run as passing. --failed runs every spec.
    applies: AppliesWhen(
      natures: {'typescript', 'javascript'},
      dependencies: {'jasmine-reporters'},
    ),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'node-test',
    command:
        'node --test --test-reporter=junit '
        '--test-reporter-destination={report}',
    format: ReportFormat.junit,
    filter: NameFilter(args: ['--test-name-pattern', '($namesPlaceholder)\$']),
    applies: AppliesWhen(natures: {'javascript'}),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'node-tsx',
    // node's runner on TypeScript through tsx; node's glob skips
    // node_modules.
    command:
        "node --import tsx --test --test-reporter=junit "
        "--test-reporter-destination={report} '**/*.{test,spec}.ts'",
    format: ReportFormat.junit,
    filter: NameFilter(args: ['--test-name-pattern', '($namesPlaceholder)\$']),
    applies: AppliesWhen(natures: {'typescript'}, dependencies: {'tsx'}),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'node-ts-node',
    command:
        "node --require ts-node/register --test --test-reporter=junit "
        "--test-reporter-destination={report} '**/*.{test,spec}.ts'",
    format: ReportFormat.junit,
    filter: NameFilter(args: ['--test-name-pattern', '($namesPlaceholder)\$']),
    applies: AppliesWhen(natures: {'typescript'}, dependencies: {'ts-node'}),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'pytest',
    command: 'python3 -m pytest -q --junitxml={report}',
    format: ReportFormat.junit,
    // -k takes a boolean expression of name parts, not a pattern; a
    // parametrized test (`test_x[1]`) is selected by its function.
    filter: NameFilter(
      args: ['-k', namesPlaceholder],
      join: ' or ',
      regex: false,
      cut: '[',
    ),
    applies: AppliesWhen(natures: {'python'}),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'maven',
    command: 'mvn -B test',
    format: ReportFormat.junit,
    reportPath: 'target/surefire-reports/TEST-*.xml',
    applies: AppliesWhen(natures: {'java'}, files: ['pom.xml']),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'gradle-wrapper',
    command: './gradlew test',
    format: ReportFormat.junit,
    reportPath: 'build/test-results/test/*.xml',
    applies: AppliesWhen(natures: {'java'}, files: ['gradlew']),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'gradle',
    command: 'gradle test',
    format: ReportFormat.junit,
    reportPath: 'build/test-results/test/*.xml',
    applies: AppliesWhen(natures: {'java'}),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'go-test',
    command: 'go test -json ./...',
    format: ReportFormat.goJson,
    // -run splits a pattern at `/` into one per subtest level: a subtest is
    // selected by the test it belongs to.
    filter: NameFilter(args: ['-run', '^($namesPlaceholder)\$'], cut: '/'),
    applies: AppliesWhen(natures: {'go'}),
    source: 'built-in',
  ),
  RunnerTemplate(
    name: 'cargo-test',
    // Without --no-fail-fast cargo stops at the first test binary with a
    // failing test, and the later binaries' tests go missing.
    command: 'cargo test --no-fail-fast',
    format: ReportFormat.libtest,
    filter: NameFilter(args: ['--', '--exact', namePlaceholder], regex: false),
    applies: AppliesWhen(natures: {'rust'}),
    source: 'built-in',
  ),
];

/// The templates a project sees, in the order detection tries them: its own
/// (`buildkit.yaml`), then the workspace's (`buildkit_master.yaml`), then the
/// built-ins. A template named like one further down replaces it in its
/// place, taking the fields it leaves out from it.
class RunnerTemplates {
  /// Every template, in detection order.
  final List<RunnerTemplate> templates;

  const RunnerTemplates(this.templates);

  /// The template named [name], or null.
  RunnerTemplate? byName(String name) {
    for (final t in templates) {
      if (t.name == name) return t;
    }
    return null;
  }

  /// The first template whose `applies:` holds for the project.
  RunnerTemplate? detect(String projectPath, List<RunFolder> natures) {
    for (final t in templates) {
      if (t.applies?.holds(projectPath, natures) ?? false) return t;
    }
    return null;
  }

  /// The built-ins with the workspace's [workspace] and the project's
  /// [project] `runners:` maps applied. Throws [FormatException] for a
  /// template that is not well-formed.
  static RunnerTemplates layered({Object? workspace, Object? project}) {
    var list = [...builtInRunnerTemplates];
    for (final (yaml, source) in [
      (workspace, 'buildkit_master.yaml'),
      (project, 'buildkit.yaml'),
    ]) {
      if (yaml == null) continue;
      if (yaml is! Map) {
        throw FormatException('testkit: runners: in $source must be a map');
      }
      final added = <RunnerTemplate>[];
      for (final entry in yaml.entries) {
        final name = '${entry.key}';
        final at = list.indexWhere((t) => t.name == name);
        final template = RunnerTemplate.fromYaml(
          name,
          entry.value,
          source: source,
          base: at < 0 ? null : list[at],
        );
        if (at < 0) {
          added.add(template);
        } else {
          list[at] = template;
        }
      }
      list = [...added, ...list];
    }
    return RunnerTemplates(list);
  }
}

/// The name a template's `applies: nature:` uses for [nature], or null for a
/// nature templates do not name.
String? natureName(RunFolder nature) => switch (nature) {
  TypeScriptFolder() => 'typescript',
  JavaScriptFolder() => 'javascript',
  PythonFolder() => 'python',
  JavaFolder() => 'java',
  GoFolder() => 'go',
  RustFolder() => 'rust',
  CppFolder() => 'cpp',
  CFolder() => 'c',
  _ => null,
};

const _natureNames = [
  'typescript',
  'javascript',
  'python',
  'java',
  'go',
  'rust',
  'cpp',
  'c',
];

/// The names in `package.json`'s `dependencies` and `devDependencies`.
Set<String> packageJsonDependencies(String projectPath) {
  final file = File(p.join(projectPath, 'package.json'));
  if (!file.existsSync()) return const {};
  try {
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map) return const {};
    return {
      for (final key in ['dependencies', 'devDependencies'])
        if (json[key] is Map) ...(json[key] as Map).keys.map((k) => '$k'),
    };
  } on FormatException {
    return const {};
  }
}

/// The `scripts` of `package.json` by name.
Map<String, String> packageJsonScripts(String projectPath) {
  final file = File(p.join(projectPath, 'package.json'));
  if (!file.existsSync()) return const {};
  try {
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map || json['scripts'] is! Map) return const {};
    return {
      for (final e in (json['scripts'] as Map).entries)
        '${e.key}': '${e.value}',
    };
  } on FormatException {
    return const {};
  }
}

bool _globMatches(String projectPath, String pattern) {
  if (!pattern.contains(RegExp(r'[*?\[{]'))) {
    return FileSystemEntity.typeSync(p.join(projectPath, pattern)) !=
        FileSystemEntityType.notFound;
  }
  return Glob(pattern).listSync(root: projectPath).isNotEmpty;
}

/// A string or a list of strings under [key]; null when absent.
List<String>? _strings(Object? value, String key) {
  if (value == null) return null;
  if (value is String) return [value];
  if (value is List && value.every((v) => v is String)) {
    return value.cast<String>();
  }
  throw FormatException('applies: $key: must be a string or a list of them');
}
