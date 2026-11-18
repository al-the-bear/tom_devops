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

  const NameFilter({
    required this.args,
    this.join = '|',
    this.regex = true,
    this.cut,
  });

  /// The arguments that select [names]; empty when [names] is.
  List<String> argsFor(Iterable<String> names) {
    final selected = <String>[];
    for (final name in names) {
      final cutAt = cut == null ? -1 : name.indexOf(cut!);
      final n = cutAt > 0 ? name.substring(0, cutAt) : name;
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
    ];
  }

  /// Reads a `filter:` map; throws [FormatException] naming what is wrong.
  static NameFilter fromYaml(Object? yaml) {
    if (yaml is! Map) throw const FormatException('filter: must be a map');
    final args = yaml['args'];
    if (args is! List ||
        args.isEmpty ||
        args.any((a) => a is! String && a is! num)) {
      throw const FormatException('filter: needs args: (a list of strings)');
    }
    final list = [for (final a in args) '$a'];
    if (!list.any(
      (a) => a == namePlaceholder || a.contains(namesPlaceholder),
    )) {
      throw const FormatException(
        'filter: args: must hold {names} or an argument {name}',
      );
    }
    final join = yaml['join'];
    final regex = yaml['regex'];
    final cut = yaml['cut'];
    return NameFilter(
      args: list,
      join: join is String ? join : '|',
      regex: regex is bool ? regex : true,
      cut: cut is String && cut.isNotEmpty ? cut : null,
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

  const AppliesWhen({
    this.natures = const {},
    this.files = const [],
    this.contains = const {},
    this.dependencies = const {},
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
    final contains = yaml['contains'];
    if (contains != null && contains is! Map) {
      throw const FormatException(
        'applies: contains: must map a file to a pattern',
      );
    }
    final applies = AppliesWhen(
      natures: natures,
      files: [...?_strings(yaml['files'], 'files')],
      contains: {
        if (contains is Map)
          for (final e in contains.entries) '${e.key}': '${e.value}',
      },
      dependencies: names('dependency'),
    );
    if (applies.natures.isEmpty &&
        applies.files.isEmpty &&
        applies.contains.isEmpty &&
        applies.dependencies.isEmpty) {
      throw const FormatException(
        'applies: needs nature:, files:, contains: or dependency:',
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
