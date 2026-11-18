/// How testkit runs a project's tests, in any language.
///
/// The runner of a project comes from, in this order:
///
/// 1. a `testkit:` section in its `buildkit.yaml`:
///
///    ```yaml
///    testkit:
///      runner: pytest              # a template by name, or:
///      command: ./run_tests.sh     # shell command, run in the project
///      report: testkit             # testkit | junit | go-json | libtest | jest-json | mocha-json | testng | tap
///      report-path: build/*.xml    # a file report written elsewhere
///      filter: {args: [-k, '{names}'], join: ' or ', regex: false}
///    ```
///
///    With `runner:` the named template ([RunnerTemplate]) runs, and the
///    section's `command:`, `report:`, `report-path:` and `filter:` change
///    it. Without it `command:` is the runner; `report` defaults to
///    `testkit`, and without `report-path` a file report is written to the
///    path `$TESTKIT_REPORT` names (`{report}` in the command is replaced by
///    the same path). `runners:` adds or changes templates for this
///    project; a section holding only `runners:` names no runner;
/// 2. a Dart or Flutter project: `dart test` / `flutter test`;
/// 3. the `test:` step of its `buildkit.yaml` (the step `buildkit :test`
///    runs): a script that writes testkit's line protocol to
///    `$TESTKIT_REPORT`;
/// 4. the first template whose `applies:` holds: the project's own
///    (`testkit: runners:` in `buildkit.yaml`), the workspace's
///    (`testkit: runners:` in `buildkit_master.yaml`), then testkit's
///    built-ins ([builtInRunnerTemplates]: jest, node --test, pytest, Maven,
///    Gradle, go test, cargo test).
///
/// A C or C++ project, and a TypeScript project without jest, has no
/// built-in template: it needs 1, 3 or a template of its own.
library;

import 'dart:convert';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;
import 'package:tom_build_base/tom_build_base.dart'
    show ProcessRunResult, ProcessRunner, TomBuildConfig;
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:yaml/yaml.dart';

import '../model/test_entry.dart';
import '../model/test_run_results.dart';
import '../parser/dart_test_parser.dart';
import '../util/file_helpers.dart';
import 'bundled_scripts.dart';
import 'report_parsers.dart';
import 'result_collector.dart';
import 'runner_templates.dart';

/// The environment variable that names the file a run writes its report to.
const testkitReportVariable = 'TESTKIT_REPORT';

/// The file in `testlog/` that keeps a non-Dart run's output.
const lastTestRunTextName = 'last_testrun.txt';

/// Written in a runner command, replaced by the (quoted) path of the report
/// file — the same path `$TESTKIT_REPORT` holds, in a form every shell reads.
const reportPlaceholder = '{report}';

/// Written in a runner command, replaced by the project's Python: its own
/// environment when it has one ([projectPythonCommand]), else `python3`.
const pythonPlaceholder = '{python}';

/// Written in a runner command, replaced by the project's Gradle: the
/// nearest wrapper at or above it ([projectGradleCommand]), else `gradle`.
const gradlePlaceholder = '{gradle}';

/// The command placeholders that depend on the project, with how each is
/// resolved.
final _projectCommands = <String, String Function(String)>{
  pythonPlaceholder: projectPythonCommand,
  gradlePlaceholder: projectGradleCommand,
};

/// `{script:<name>}` in a runner command: replaced by the (quoted) path of
/// the bundled script [bundledScripts] names, written to `testlog/` first.
final _scriptPlaceholder = RegExp(r'\{script:([\w-]+)\}');

/// How many lines of a runner's output a "no test ran" message quotes.
const _diagnosticLines = 15;

/// A project's test runner.
sealed class ProjectTestRunner {
  const ProjectTestRunner();

  /// The runner for the project at [projectPath] with [natures], or a
  /// [RunnerUnavailable] saying why there is none.
  static ProjectTestRunner resolve(
    String projectPath,
    List<RunFolder> natures,
  ) => _withProjectCommands(_resolve(projectPath, natures), projectPath);

  static ProjectTestRunner _resolve(
    String projectPath,
    List<RunFolder> natures,
  ) {
    final config = _readBuildkitYaml(projectPath);
    // The section as tom_build_base hands it: without its defines (those are
    // the build tools'), null when it holds nothing else.
    final section = TomBuildConfig.readToolSection(
      dir: projectPath,
      toolKey: 'testkit',
    );
    if (section != null && section is! Map) {
      return const RunnerUnavailable(
        'the testkit: section of buildkit.yaml must be a map with runner: or '
        'command:',
      );
    }
    final RunnerTemplates templates;
    try {
      templates = RunnerTemplates.layered(
        workspace: _workspaceRunners(projectPath),
        project: (section as Map?)?['runners'],
      );
    } on FormatException catch (e) {
      return RunnerUnavailable(e.message);
    }
    if (section != null && _namesRunner(section)) {
      return _fromSection(section, templates);
    }
    if (natures.any((n) => n is DartProjectFolder)) {
      return const DartRunner();
    }
    final step = config?['test'];
    if (step is String) {
      return CommandRunner(
        command: step,
        format: ReportFormat.testkit,
        origin: 'buildkit.yaml test:',
      );
    }
    if (step is YamlList && step.isNotEmpty) {
      return CommandRunner(
        command: step.map((c) => '$c').join(' && '),
        format: ReportFormat.testkit,
        origin: 'buildkit.yaml test:',
      );
    }
    final template = templates.detect(projectPath, natures);
    if (template != null) return CommandRunner.fromTemplate(template);
    return _noTemplate(natures);
  }

  /// A short description for messages: the command and where it came from.
  String get label;

  /// Whether `--failed` / `--mismatched` can select single tests: `dart test
  /// --name`, and a template that declares a `filter:`. The other runners
  /// run every test.
  bool get selectsTestsByName => false;

  /// The name [entry] of a tracking file has for this runner's selection:
  /// the tracking key, without the `<group> > ` a collected run puts before a
  /// name it reported twice.
  String selectionName(TestEntry entry) => entry.fullDescription;

  /// The arguments that run only the tests named [names] (each a
  /// [selectionName]); empty when the runner cannot select by name.
  List<String> selectArgs(List<String> names) => const [];

  /// Runs the tests in [projectPath] with [testArgs] appended to the command
  /// and reads the results; null when the run could not happen (the reason
  /// is on stderr). With [coveragePath] the run's line coverage is measured
  /// into an lcov report there and kept on the run, where the runner can
  /// (only `dart test` / `flutter test`).
  Future<TestRunResults?> run({
    required String projectPath,
    List<String> testArgs = const [],
    bool verbose = false,
    String? pubCachePath,
    String? coveragePath,
  });
}

/// `dart test` or `flutter test` with the JSON reporter.
class DartRunner extends ProjectTestRunner {
  const DartRunner();

  @override
  String get label => 'dart test / flutter test';

  @override
  bool get selectsTestsByName => true;

  @override
  List<String> selectArgs(List<String> names) => [
    for (final name in names) ...['--name', '^${_escapeRegex(name)}\$'],
  ];

  @override
  Future<TestRunResults?> run({
    required String projectPath,
    List<String> testArgs = const [],
    bool verbose = false,
    String? pubCachePath,
    String? coveragePath,
  }) => DartTestParser.runAndParse(
    projectPath: projectPath,
    additionalArgs: testArgs,
    verbose: verbose,
    pubCachePath: pubCachePath,
    coveragePath: coveragePath,
  );
}

/// A shell command whose report testkit reads in [format].
class CommandRunner extends ProjectTestRunner {
  /// The shell command, run in the project folder.
  final String command;

  /// The format of its report.
  final ReportFormat format;

  /// Where a file report lands, relative to the project (a glob for
  /// several files); null: the file `$TESTKIT_REPORT` names.
  final String? reportPath;

  /// Where the runner came from: `buildkit.yaml testkit:`,
  /// `buildkit.yaml test:`, or `runner <name>, <source>` for a template
  /// (its name and where it is defined).
  final String origin;

  /// How it selects tests by name; null: every test runs.
  final NameFilter? filter;

  const CommandRunner({
    required this.command,
    required this.format,
    required this.origin,
    this.reportPath,
    this.filter,
  });

  /// The runner of [template]; [pickedIn] says where a project named it.
  factory CommandRunner.fromTemplate(
    RunnerTemplate template, {
    String? pickedIn,
  }) => CommandRunner(
    command: template.command,
    format: template.format,
    reportPath: template.reportPath,
    filter: template.filter,
    origin:
        'runner ${template.name}, ${template.source}'
        '${pickedIn == null ? '' : ', picked in $pickedIn'}',
  );

  @override
  String get label => '`$command` [$origin]';

  @override
  bool get selectsTestsByName => filter != null;

  @override
  String selectionName(TestEntry entry) {
    var name = entry.fullDescription;
    for (final qualifier in [entry.groups, entry.suite]) {
      if (qualifier != null && name.startsWith('$qualifier > ')) {
        name = name.substring(qualifier.length + 3);
        break;
      }
    }
    final qualify = filter?.qualify;
    final group = entry.groups;
    return qualify != null && group != null && group.isNotEmpty
        ? '$group$qualify$name'
        : name;
  }

  @override
  List<String> selectArgs(List<String> names) =>
      filter?.argsFor(names) ?? const [];

  /// The report file testkit hands the command in `$TESTKIT_REPORT`, kept in
  /// `testlog/` for inspection.
  static String reportFileFor(String projectPath, ReportFormat format) =>
      p.join(
        projectPath,
        trackingDirName,
        'last_testrun_report.${switch (format) {
          ReportFormat.junit || ReportFormat.testng => 'xml',
          ReportFormat.jestJson || ReportFormat.mochaJson => 'json',
          ReportFormat.tap => 'tap',
          _ => 'jsonl',
        }}',
      );

  @override
  Future<TestRunResults?> run({
    required String projectPath,
    List<String> testArgs = const [],
    bool verbose = false,
    String? pubCachePath,
    String? coveragePath,
  }) async {
    if (coveragePath != null) {
      stderr.writeln(
        '[$projectPath] No coverage: only `dart test` / `flutter test` runs '
        'measure it; $label runs without.',
      );
    }
    // Absolute: a traversal hands relative project paths, and a test script
    // that changes directory still has to find $TESTKIT_REPORT.
    final reportFile = p.normalize(
      p.absolute(reportFileFor(projectPath, format)),
    );
    Directory(p.dirname(reportFile)).createSync(recursive: true);
    // A report left by an earlier run must not be read as this run's.
    _deleteReports(projectPath, reportFile);

    final String expanded;
    try {
      expanded = _expandPlaceholders(command, projectPath, reportFile);
    } on StateError catch (e) {
      stderr.writeln('[$projectPath] ${e.message}');
      return null;
    }
    final full = [expanded, ...testArgs.map(_shellQuote)].join(' ');
    if (verbose) {
      print('  Running: $full');
      print('  In: $projectPath');
    }
    final ProcessRunResult result;
    try {
      // One stream: cargo writes its progress (which binary runs) to stderr
      // and the test lines to stdout, and the libtest reader needs both in
      // order.
      // A group, so that `2>&1` covers every command of a compound one
      // (`make && ./run_tests.sh`).
      result = await ProcessRunner.runShell(
        Platform.isWindows ? '($full) 2>&1' : '{ $full\n} 2>&1',
        workingDirectory: projectPath,
        environment: {testkitReportVariable: reportFile},
      );
    } on ProcessException catch (e) {
      stderr.writeln('Error: could not start the shell to run `$full`: $e');
      return null;
    }
    final output = const LineSplitter().convert(result.stdout);
    if (verbose) {
      for (final line in output) {
        print('  | $line');
      }
    }

    final collector = ResultCollector();
    try {
      switch (format) {
        case ReportFormat.goJson:
          parseGoTestJson(output, collector);
        case ReportFormat.libtest:
          parseLibtestOutput(output, collector);
        case ReportFormat.testkit:
          for (final f in _reportFiles(projectPath, reportFile)) {
            parseTestkitLines(f.readAsLinesSync(), collector);
          }
        case ReportFormat.junit:
          for (final f in _reportFiles(projectPath, reportFile)) {
            parseJunitXml(f.readAsStringSync(), collector);
          }
        case ReportFormat.jestJson:
          for (final f in _reportFiles(projectPath, reportFile)) {
            parseJestJson(f.readAsStringSync(), collector);
          }
        case ReportFormat.testng:
          for (final f in _reportFiles(projectPath, reportFile)) {
            parseTestngResults(f.readAsStringSync(), collector);
          }
        case ReportFormat.mochaJson:
          for (final f in _reportFiles(projectPath, reportFile)) {
            parseMochaJson(f.readAsStringSync(), collector);
          }
        case ReportFormat.tap:
          // The report file when the runner wrote one ({report},
          // report-path:), else its output.
          final files = _reportFiles(projectPath, reportFile);
          if (files.isEmpty) {
            parseTapOutput(output, collector);
          } else {
            for (final f in files) {
              parseTapOutput(f.readAsLinesSync(), collector);
            }
          }
      }
    } on FormatException catch (e) {
      stderr.writeln(
        '[$projectPath] The ${format.configName} report of '
        '`$full` could not be read: ${e.message}',
      );
      return null;
    }

    String? diagnostic;
    if (collector.length == 0) {
      final tail = output
          .where((l) => l.trim().isNotEmpty)
          .toList()
          .reversed
          .take(_diagnosticLines)
          .toList()
          .reversed;
      final reportNote = format.isFile
          ? '  (no ${format.configName} report found at '
                '${reportPath ?? p.relative(reportFile, from: projectPath)})\n'
          : '';
      diagnostic =
          '$reportNote  `$full` exited with code ${result.exitCode}; its last '
          'output:\n${tail.map((l) => '    $l').join('\n')}';
    }
    return collector.build(
      rawOutput: output,
      rawOutputName: lastTestRunTextName,
      exitCode: result.exitCode,
      diagnostic: diagnostic,
    );
  }

  /// The report files of this run: [reportPath]'s matches, else the file
  /// handed over in `$TESTKIT_REPORT` when the command wrote it.
  List<File> _reportFiles(String projectPath, String reportFile) {
    if (reportPath == null) {
      final f = File(reportFile);
      return f.existsSync() ? [f] : const [];
    }
    final files =
        Glob(
            reportPath!,
            recursive: true,
          ).listSync(root: projectPath).whereType<File>().toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  void _deleteReports(String projectPath, String reportFile) {
    for (final f in [
      File(reportFile),
      ..._reportFiles(projectPath, reportFile),
    ]) {
      if (f.existsSync()) f.deleteSync();
    }
  }
}

/// A project testkit cannot run: [reason] says why and what to configure.
class RunnerUnavailable extends ProjectTestRunner {
  /// Why there is no runner.
  final String reason;

  const RunnerUnavailable(this.reason);

  @override
  String get label => 'no test runner';

  @override
  Future<TestRunResults?> run({
    required String projectPath,
    List<String> testArgs = const [],
    bool verbose = false,
    String? pubCachePath,
    String? coveragePath,
  }) async {
    stderr.writeln('[$projectPath] $reason');
    return null;
  }
}

/// [runner] with `{python}` and `{gradle}` replaced by the project's
/// commands, so messages and a dry run name the command that runs.
ProjectTestRunner _withProjectCommands(
  ProjectTestRunner runner,
  String projectPath,
) {
  if (runner is! CommandRunner ||
      !_projectCommands.keys.any(runner.command.contains)) {
    return runner;
  }
  return CommandRunner(
    command: _resolveProjectCommands(runner.command, projectPath),
    format: runner.format,
    reportPath: runner.reportPath,
    filter: runner.filter,
    origin: runner.origin,
  );
}

/// [command] with `{report}`, `{python}` and `{script:<name>}` replaced;
/// a bundled script is written to `testlog/` beside the report file. Throws
/// [StateError] for a script testkit does not bundle.
String _expandPlaceholders(
  String command,
  String projectPath,
  String reportFile,
) {
  final result = _resolveProjectCommands(
    command.replaceAll(reportPlaceholder, _shellQuote(reportFile)),
    projectPath,
  );
  return result.replaceAllMapped(_scriptPlaceholder, (m) {
    final name = m.group(1)!;
    final script = bundledScripts[name];
    if (script == null) {
      throw StateError(
        'unknown script {script:$name} in `$command` (one of '
        '${bundledScripts.keys.join(', ')})',
      );
    }
    final file = File(
      p.join(p.dirname(reportFile), 'testkit_$name.${script.extension}'),
    )..writeAsStringSync(script.text);
    return _shellQuote(file.path);
  });
}

/// [command] with each project placeholder ([_projectCommands]) it holds
/// replaced.
String _resolveProjectCommands(String command, String projectPath) {
  var result = command;
  for (final MapEntry(key: placeholder, value: resolve)
      in _projectCommands.entries) {
    if (result.contains(placeholder)) {
      result = result.replaceAll(placeholder, resolve(projectPath));
    }
  }
  return result;
}

/// Quotes [arg] for `sh -c` / `cmd /c` when it holds anything but safe
/// characters.
String _shellQuote(String arg) {
  if (RegExp(r'^[\w@%+=:,./-]+$').hasMatch(arg)) return arg;
  if (Platform.isWindows) return '"${arg.replaceAll('"', r'\"')}"';
  return "'${arg.replaceAll("'", r"'\''")}'";
}

YamlMap? _readBuildkitYaml(String projectPath) {
  final file = File(p.join(projectPath, TomBuildConfig.projectFilename));
  if (!file.existsSync()) return null;
  final Object? yaml;
  try {
    yaml = loadYaml(file.readAsStringSync());
  } on YamlException {
    return null;
  }
  return yaml is YamlMap ? yaml : null;
}

/// Whether a `testkit:` section names a runner (rather than only adding
/// templates with `runners:`).
bool _namesRunner(Map section) => section.keys.any(
  (k) => const {
    'runner',
    'command',
    'report',
    'report-path',
    'filter',
  }.contains(k),
);

ProjectTestRunner _fromSection(Map section, RunnerTemplates templates) {
  const where = 'the testkit: section of buildkit.yaml';
  final picked = section['runner'];
  final overrides = {
    for (final key in ['command', 'report', 'report-path', 'filter'])
      if (section.containsKey(key)) key: section[key],
  };
  try {
    if (picked != null) {
      final base = templates.byName('$picked');
      if (base == null) {
        return RunnerUnavailable(
          '$where: unknown runner "$picked" (one of '
          '${templates.templates.map((t) => t.name).join(', ')})',
        );
      }
      final template = overrides.isEmpty
          ? base
          : RunnerTemplate.fromYaml(
              base.name,
              overrides,
              source: base.source,
              base: base,
            );
      return CommandRunner.fromTemplate(template, pickedIn: 'buildkit.yaml');
    }
    final command = section['command'];
    if (command is! String || command.trim().isEmpty) {
      return const RunnerUnavailable('$where needs a command: or a runner:');
    }
    final own = RunnerTemplate.fromYaml(
      'testkit',
      overrides,
      source: 'buildkit.yaml',
    );
    return CommandRunner(
      command: own.command,
      format: own.format,
      reportPath: own.reportPath,
      filter: own.filter,
      origin: 'buildkit.yaml testkit:',
    );
  } on FormatException catch (e) {
    return RunnerUnavailable('$where: ${e.message}');
  }
}

/// The `runners:` of the workspace's `testkit:` section in
/// `buildkit_master.yaml`, or null.
Object? _workspaceRunners(String projectPath) {
  final root = findWorkspaceRootOrNull(projectPath);
  if (root == null) return null;
  final file = File(p.join(root, TomBuildConfig.masterFilename));
  final Object? doc;
  try {
    doc = loadYaml(file.readAsStringSync());
  } on YamlException {
    return null;
  } on FileSystemException {
    return null;
  }
  if (doc is! Map) return null;
  final section = doc['testkit'];
  return section is Map ? section['runners'] : null;
}

/// Why a project no template applies to has no runner.
ProjectTestRunner _noTemplate(List<RunFolder> natures) {
  const add =
      'Add a testkit: section to buildkit.yaml (runner: <template>, or '
      'command: and report:), a test: step that writes testkit\'s line '
      'protocol to \$$testkitReportVariable, or a template of your own '
      'under testkit: runners:.';
  for (final nature in natures) {
    switch (nature) {
      case TypeScriptFolder():
        return const RunnerUnavailable(
          'testkit has no runner template for a TypeScript project without '
          'jest. $add',
        );
      case CppFolder() || CFolder():
        return RunnerUnavailable(
          'testkit has no runner template for a '
          '${nature is CppFolder ? 'C++' : 'C'} project (e.g. ctest '
          '--output-junit {report} with report: junit). $add',
        );
      default:
        break;
    }
  }
  return const RunnerUnavailable(
    'testkit found no language it can test in this folder.',
  );
}

/// Escapes the regular-expression characters in a `dart test --name` value.
String _escapeRegex(String input) => input.replaceAllMapped(
  RegExp(r'[.*+?^${}()|[\]\\]'),
  (match) => '\\${match.group(0)}',
);
