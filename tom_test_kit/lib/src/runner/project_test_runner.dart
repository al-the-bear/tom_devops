/// How testkit runs a project's tests, in any language.
///
/// The runner of a project comes from, in this order:
///
/// 1. a `testkit:` section in its `buildkit.yaml`:
///
///    ```yaml
///    testkit:
///      command: ./run_tests.sh     # shell command, run in the project
///      report: testkit             # testkit | junit | go-json | libtest | jest-json
///      report-path: build/*.xml    # junit / jest-json written elsewhere
///    ```
///
///    `report` defaults to `testkit`; without `report-path` a file report is
///    written to the path `$TESTKIT_REPORT` names (`{report}` in the command
///    is replaced by the same path);
/// 2. a Dart or Flutter project: `dart test` / `flutter test`;
/// 3. the `test:` step of its `buildkit.yaml` (the step `buildkit :test`
///    runs): a script that writes testkit's line protocol to
///    `$TESTKIT_REPORT`;
/// 4. the default of its language: `go test -json ./...`, `cargo test
///    --no-fail-fast`,
///    pytest with `--junitxml`, Maven / Gradle surefire reports, jest
///    `--json` or `node --test` with the JUnit reporter.
///
/// A C or C++ project, and a TypeScript project without jest, has no
/// default: it needs 1 or 3.
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

import '../model/test_run_results.dart';
import '../parser/dart_test_parser.dart';
import '../util/file_helpers.dart';
import 'report_parsers.dart';
import 'result_collector.dart';

/// The environment variable that names the file a run writes its report to.
const testkitReportVariable = 'TESTKIT_REPORT';

/// The file in `testlog/` that keeps a non-Dart run's output.
const lastTestRunTextName = 'last_testrun.txt';

/// Written in a runner command, replaced by the (quoted) path of the report
/// file — the same path `$TESTKIT_REPORT` holds, in a form every shell reads.
const reportPlaceholder = '{report}';

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
  ) {
    final config = _readBuildkitYaml(projectPath);
    final section = config?['testkit'];
    if (section != null) return _fromSection(section, projectPath);
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
    return _languageDefault(projectPath, natures);
  }

  /// A short description for messages: the command and where it came from.
  String get label;

  /// Whether `--failed` / `--mismatched` can select single tests (only
  /// `dart test --name` can; the other runners run every test).
  bool get selectsTestsByName => false;

  /// Runs the tests in [projectPath] with [testArgs] appended to the command
  /// and reads the results; null when the run could not happen (the reason
  /// is on stderr).
  Future<TestRunResults?> run({
    required String projectPath,
    List<String> testArgs = const [],
    bool verbose = false,
    String? pubCachePath,
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
  Future<TestRunResults?> run({
    required String projectPath,
    List<String> testArgs = const [],
    bool verbose = false,
    String? pubCachePath,
  }) => DartTestParser.runAndParse(
    projectPath: projectPath,
    additionalArgs: testArgs,
    verbose: verbose,
    pubCachePath: pubCachePath,
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

  /// Where the runner came from: `buildkit.yaml testkit:`, `buildkit.yaml
  /// test:` or `default (language)`.
  final String origin;

  const CommandRunner({
    required this.command,
    required this.format,
    required this.origin,
    this.reportPath,
  });

  @override
  String get label => '`$command` [$origin]';

  /// The report file testkit hands the command in `$TESTKIT_REPORT`, kept in
  /// `testlog/` for inspection.
  static String reportFileFor(String projectPath, ReportFormat format) =>
      p.join(
        projectPath,
        trackingDirName,
        'last_testrun_report.${switch (format) {
          ReportFormat.junit => 'xml',
          ReportFormat.jestJson => 'json',
          _ => 'jsonl',
        }}',
      );

  @override
  Future<TestRunResults?> run({
    required String projectPath,
    List<String> testArgs = const [],
    bool verbose = false,
    String? pubCachePath,
  }) async {
    // Absolute: a traversal hands relative project paths, and a test script
    // that changes directory still has to find $TESTKIT_REPORT.
    final reportFile = p.normalize(
      p.absolute(reportFileFor(projectPath, format)),
    );
    Directory(p.dirname(reportFile)).createSync(recursive: true);
    // A report left by an earlier run must not be read as this run's.
    _deleteReports(projectPath, reportFile);

    final full = [
      command.replaceAll(reportPlaceholder, _shellQuote(reportFile)),
      ...testArgs.map(_shellQuote),
    ].join(' ');
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
  }) async {
    stderr.writeln('[$projectPath] $reason');
    return null;
  }
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

ProjectTestRunner _fromSection(Object section, String projectPath) {
  const where = 'the testkit: section of buildkit.yaml';
  if (section is! YamlMap) {
    return const RunnerUnavailable('$where must be a map with command:');
  }
  final command = section['command'];
  if (command is! String || command.trim().isEmpty) {
    return const RunnerUnavailable('$where needs a command:');
  }
  final reportName = section['report'] as Object? ?? 'testkit';
  final format = ReportFormat.byConfigName('$reportName');
  if (format == null) {
    return RunnerUnavailable(
      '$where: unknown report "$reportName" (one of '
      '${ReportFormat.values.map((f) => f.configName).join(', ')})',
    );
  }
  final reportPath = section['report-path'];
  return CommandRunner(
    command: command,
    format: format,
    reportPath: reportPath is String ? reportPath : null,
    origin: 'buildkit.yaml testkit:',
  );
}

ProjectTestRunner _languageDefault(
  String projectPath,
  List<RunFolder> natures,
) {
  CommandRunner def(
    String command,
    ReportFormat format,
    String language, [
    String? reportPath,
  ]) => CommandRunner(
    command: command,
    format: format,
    reportPath: reportPath,
    origin: 'default ($language)',
  );

  // The same precedence as buildkit's `:test` and tom_build_base's project
  // listing: TypeScript and JavaScript before Python, Java, Go, Rust, C++, C.
  for (final nature in _ordered(natures)) {
    switch (nature) {
      case TypeScriptFolder():
        if (_usesJest(projectPath)) return _jest(def, 'typescript');
        return const RunnerUnavailable(
          'testkit has no default test runner for a TypeScript project '
          'without jest. Add a testkit: section to buildkit.yaml (command: '
          'and report:), or a test: step that writes testkit\'s line '
          'protocol to \$$testkitReportVariable.',
        );
      case JavaScriptFolder():
        if (_usesJest(projectPath)) return _jest(def, 'javascript');
        return def(
          'node --test --test-reporter=junit '
              '--test-reporter-destination={report}',
          ReportFormat.junit,
          'javascript',
        );
      case PythonFolder():
        return def(
          'python3 -m pytest -q --junitxml={report}',
          ReportFormat.junit,
          'python',
        );
      case JavaFolder(:final buildTool):
        return buildTool == JavaBuildTool.maven
            ? def(
                'mvn -B test',
                ReportFormat.junit,
                'java, maven',
                'target/surefire-reports/TEST-*.xml',
              )
            : def(
                File(p.join(projectPath, 'gradlew')).existsSync()
                    ? './gradlew test'
                    : 'gradle test',
                ReportFormat.junit,
                'java, gradle',
                'build/test-results/test/*.xml',
              );
      case GoFolder():
        return def('go test -json ./...', ReportFormat.goJson, 'go');
      case RustFolder():
        // Without --no-fail-fast cargo stops at the first test binary with a
        // failing test, and the later binaries' tests go missing.
        return def('cargo test --no-fail-fast', ReportFormat.libtest, 'rust');
      case CppFolder() || CFolder():
        return RunnerUnavailable(
          'testkit has no default test runner for a '
          '${nature is CppFolder ? 'C++' : 'C'} project. Add a test: step to '
          'buildkit.yaml that writes testkit\'s line protocol to '
          '\$$testkitReportVariable, or a testkit: section (command: and '
          'report:, e.g. ctest --output-junit with report: junit).',
        );
      default:
        break;
    }
  }
  return const RunnerUnavailable(
    'testkit found no language it can test in this folder.',
  );
}

CommandRunner _jest(
  CommandRunner Function(String, ReportFormat, String) def,
  String language,
) => def(
  'npx jest --json --outputFile={report}',
  ReportFormat.jestJson,
  '$language, jest',
);

List<RunFolder> _ordered(List<RunFolder> natures) {
  int rank(RunFolder n) => switch (n) {
    TypeScriptFolder() => 0,
    JavaScriptFolder() => 1,
    PythonFolder() => 2,
    JavaFolder() => 3,
    GoFolder() => 4,
    RustFolder() => 5,
    CppFolder() => 6,
    CFolder() => 7,
    _ => 8,
  };
  return [...natures]..sort((a, b) => rank(a).compareTo(rank(b)));
}

/// Whether the project's package.json names jest as a dependency.
bool _usesJest(String projectPath) {
  final file = File(p.join(projectPath, 'package.json'));
  if (!file.existsSync()) return false;
  try {
    final json = jsonDecode(file.readAsStringSync());
    if (json is! Map) return false;
    for (final key in ['dependencies', 'devDependencies']) {
      final deps = json[key];
      if (deps is Map && deps.containsKey('jest')) return true;
    }
  } on FormatException {
    return false;
  }
  return false;
}
