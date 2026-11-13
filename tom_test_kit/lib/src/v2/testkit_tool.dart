/// Tom Test Kit v2 — Test result tracking tool using tom_build_base v2.
///
/// This file defines the testkit tool using the v2 CLI framework.
library;

import 'package:tom_build_base/tom_build_base_v2.dart';

import '../version.versioner.dart';

// =============================================================================
// Command Options
// =============================================================================

/// Options for :baseline command.
const baselineOptions = <OptionDefinition>[
  OptionDefinition.option(
    name: 'comment',
    abbr: 'c',
    description: 'Short label shown in the baseline column header',
    valueName: 'text',
  ),
  OptionDefinition.option(
    name: 'file',
    description:
        'Output file path (overrides default testlog/baseline_<ts>.csv)',
    valueName: 'path',
  ),
  OptionDefinition.flag(
    name: 'coverage',
    description:
        'Measure line coverage (dart test / flutter test): '
        'coverage/lcov.info, and the percentage in the run column',
  ),
  OptionDefinition.option(
    name: 'test-args',
    description: 'Additional arguments passed to dart test',
    valueName: 'args',
  ),
];

/// Options for :test command.
const testOptions = <OptionDefinition>[
  OptionDefinition.option(
    name: 'comment',
    abbr: 'c',
    description: 'Short label shown in the run column header',
    valueName: 'text',
  ),
  OptionDefinition.option(
    name: 'file',
    description: 'Tracking file to update (instead of most recent)',
    valueName: 'path',
  ),
  OptionDefinition.flag(
    name: 'baseline',
    description: 'Create baseline if no tracking file exists',
  ),
  OptionDefinition.flag(
    name: 'failed',
    description: 'Re-run only failed tests (X/OK, X/X) from last run',
  ),
  OptionDefinition.flag(
    name: 'mismatched',
    description: 'Re-run tests that don\'t match expectation (X/OK, OK/X)',
  ),
  OptionDefinition.flag(
    name: 'no-update',
    description: 'Run tests without updating baseline; print summary only',
  ),
  OptionDefinition.flag(
    name: 'coverage',
    description:
        'Measure line coverage (dart test / flutter test): '
        'coverage/lcov.info, and the percentage in the run column',
  ),
  OptionDefinition.option(
    name: 'test-args',
    description: 'Additional arguments passed to dart test',
    valueName: 'args',
  ),
];

/// Options for analysis commands.
const analysisOptions = <OptionDefinition>[
  OptionDefinition.option(
    name: 'output',
    description: 'Output format: plain, csv, json, md (or <format>:<filename>)',
    valueName: 'format',
  ),
  OptionDefinition.option(
    name: 'baseline-file',
    description: 'Use a specific baseline file',
    valueName: 'path',
  ),
];

/// Options for diff commands.
const diffOptions = <OptionDefinition>[
  OptionDefinition.option(
    name: 'output',
    description: 'Output format: plain, csv, json, md (or <format>:<filename>)',
    valueName: 'format',
  ),
  OptionDefinition.option(
    name: 'baseline-file',
    description: 'Use a specific baseline file',
    valueName: 'path',
  ),
  OptionDefinition.flag(
    name: 'full',
    description: 'Include full details from last_testrun.json',
  ),
  OptionDefinition.option(
    name: 'report',
    description: 'Generate detailed Markdown report to file',
    valueName: 'filename',
  ),
];

/// Options for :trim command.
const trimOptions = <OptionDefinition>[
  OptionDefinition.option(
    name: 'baseline-file',
    description: 'Use a specific baseline file',
    valueName: 'path',
  ),
];

/// Options for :reset command.
const resetOptions = <OptionDefinition>[
  OptionDefinition.flag(
    name: 'force',
    description: 'Skip confirmation prompts',
  ),
];

// =============================================================================
// Command Definitions
// =============================================================================

/// The natures whose tests testkit runs and tracks (the runner per project:
/// `ProjectTestRunner`). Fuzzing, mutation sweeps and the cross-reference
/// stay Dart only.
const testedNatures = <Type>{
  DartProjectFolder,
  GoFolder,
  RustFolder,
  PythonFolder,
  JavaFolder,
  JavaScriptFolder,
  TypeScriptFolder,
  CFolder,
  CppFolder,
};

/// Run commands (run the project's tests).
const baselineCommand = CommandDefinition(
  name: 'baseline',
  description:
      'Create a new baseline tracking file; exits 1 when a test failed',
  options: baselineOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
  examples: [
    'testkit :baseline',
    'testkit :baseline -c "v2.0 release"',
    'testkit :baseline --test-args="--tags e2e"',
    'testkit :baseline -r',
  ],
);

const testCommand = CommandDefinition(
  name: 'test',
  description:
      'Run tests and append results to the tracking file; '
      'exits 1 when a test failed',
  options: testOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
  examples: [
    'testkit :test',
    'testkit :test --failed',
    'testkit :test -c "bugfix"',
  ],
);

/// Analysis commands (read-only).
const runsCommand = CommandDefinition(
  name: 'runs',
  description: 'List run timestamps in the tracking file',
  options: analysisOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
);

const statusCommand = CommandDefinition(
  name: 'status',
  description: 'Quick summary — pass/fail counts, regressions/fixes',
  options: analysisOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
);

const basediffCommand = CommandDefinition(
  name: 'basediff',
  description: 'Diff baseline vs latest run',
  options: diffOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
);

const lastdiffCommand = CommandDefinition(
  name: 'lastdiff',
  description: 'Diff previous run vs latest run',
  options: diffOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
);

const diffCommand = CommandDefinition(
  name: 'diff',
  description: 'Diff two arbitrary runs by timestamp',
  options: diffOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
  examples: ['testkit :diff 0211_1430', 'testkit :diff 0211_1430 0212_0900'],
);

const historyCommand = CommandDefinition(
  name: 'history',
  description: 'Show all results for a test across runs',
  options: analysisOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
  examples: ['testkit :history "parser"', 'testkit :history ID001'],
);

const flakyCommand = CommandDefinition(
  name: 'flaky',
  description: 'List tests with inconsistent results',
  options: analysisOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
);

/// Options for :report.
const reportOptions = <OptionDefinition>[
  OptionDefinition.option(
    name: 'output',
    description:
        'Also write the report to a file: <file>.md or <file>.json '
        '(or md:<file> / json:<file>); not inside a doc/ folder',
    valueName: 'file',
  ),
];

const reportCommand = CommandDefinition(
  name: 'report',
  description:
      'One table of the latest results of every project: state, last run, '
      'passed/failed/skipped, regressions, flaky, coverage; projects without '
      'testlog/ are listed as not measured',
  options: reportOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
  examples: [
    "testkit -s tom_ai -r -p 'tom_ai/basics/*' -p 'tom_ai/devops/*' :report",
    'testkit :report --output ztmp/test_report.md',
    'testkit -s . -r :report --output json:ztmp/test_report.json',
  ],
);

const crossreferenceCommand = CommandDefinition(
  name: 'crossreference',
  description: 'Map tests to source files',
  aliases: ['crossref', 'xref'],
  options: analysisOptions,
  worksWithNatures: {DartProjectFolder},
  supportsProjectTraversal: true,
);

/// Options for :fuzz command.
const fuzzOptions = <OptionDefinition>[
  OptionDefinition.option(
    name: 'iterations',
    abbr: 'n',
    description: 'Inputs per target (default 100000 without --duration)',
    valueName: 'count',
  ),
  OptionDefinition.option(
    name: 'duration',
    abbr: 'd',
    description: 'Seconds per target',
    valueName: 'seconds',
  ),
  OptionDefinition.option(
    name: 'seed',
    description: 'Seed of the mutations (default: from the clock)',
    valueName: 'n',
  ),
  OptionDefinition.multi(
    name: 'target',
    abbr: 't',
    description: 'Only these targets',
    valueName: 'name',
  ),
  OptionDefinition.multi(
    name: 'campaign',
    description: 'Only campaign files whose name contains this',
    valueName: 'name',
  ),
  OptionDefinition.option(
    name: 'timeout-ms',
    description: 'Time bound per input (default 2000)',
    valueName: 'ms',
  ),
  OptionDefinition.option(
    name: 'memory-mb',
    description: 'Memory bound per input (default 512)',
    valueName: 'mb',
  ),
  OptionDefinition.option(
    name: 'report',
    description: 'Write all reports as one JSON list to this file',
    valueName: 'path',
  ),
  OptionDefinition.flag(
    name: 'no-coverage',
    description:
        'Do not measure the line coverage of the libraries a target names',
  ),
];

/// Runs the project's fuzz campaigns (tom_fuzz).
const fuzzCommand = CommandDefinition(
  name: 'fuzz',
  description:
      'Run the fuzz campaigns in fuzz/*_fuzz.dart (tom_fuzz); exits 1 when a '
      'target failed',
  options: fuzzOptions,
  worksWithNatures: {DartProjectFolder},
  supportsProjectTraversal: true,
  examples: [
    'testkit :fuzz --duration 600',
    'testkit :fuzz --iterations 1000000 --seed 42 --target saml_response',
    'testkit :fuzz --report fuzz_report.json',
  ],
);

/// Options for :mutations command.
const mutationsOptions = <OptionDefinition>[
  OptionDefinition.flag(
    name: 'list',
    description: 'List the selected entries and run nothing',
  ),
  OptionDefinition.multi(
    name: 'module',
    description: 'Modules to sweep (also as positional arguments); default all',
    valueName: 'name',
  ),
  OptionDefinition.option(
    name: 'min-killed',
    description:
        'Pass when at least this percentage of the mutations run was killed '
        '(default: every survivor and invalid mutant fails)',
    valueName: 'percent',
  ),
  OptionDefinition.option(
    name: 'timeout',
    description: 'Seconds one test run may take (default 600)',
    valueName: 'seconds',
  ),
  OptionDefinition.option(
    name: 'catalogue',
    description: 'Catalogue file (default tool/mutations.yaml)',
    valueName: 'path',
  ),
  OptionDefinition.option(
    name: 'requirements',
    description:
        'Precondition declarations (default tool/mutation_requirements.yaml)',
    valueName: 'path',
  ),
  OptionDefinition.option(
    name: 'report',
    description:
        'Report path without extension (default testlog/mutations_<MMDD_HHMM>)',
    valueName: 'path',
  ),
];

/// Catalogued mutation sweep.
const mutationsCommand = CommandDefinition(
  name: 'mutations',
  description:
      'Catalogued mutation sweep (tool/mutations.yaml); exits with the number '
      'of surviving + invalid mutants',
  aliases: ['mutate'],
  options: mutationsOptions,
  worksWithNatures: {DartProjectFolder},
  supportsProjectTraversal: true,
  examples: [
    'testkit :mutations --list',
    'testkit :mutations cache endpoints',
    'testkit :mutations --min-killed 80',
  ],
);

/// Maintenance commands.
const trimCommand = CommandDefinition(
  name: 'trim',
  description: 'Keep only the last N runs',
  options: trimOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
  examples: ['testkit :trim 5', 'testkit :trim 10 -r'],
);

const resetCommand = CommandDefinition(
  name: 'reset',
  description: 'Delete all tracking files',
  options: resetOptions,
  worksWithNatures: testedNatures,
  supportsProjectTraversal: true,
  examples: ['testkit :reset', 'testkit :reset --force'],
);

// =============================================================================
// Tool Definition
// =============================================================================

/// Testkit tool definition.
final testkitTool = ToolDefinition(
  name: 'testkit',
  description: 'Test result tracking for projects in every language',
  version: TestKitVersionInfo.version,
  versionString: 'Tom TestKit ${TestKitVersionInfo.versionLong}',
  mode: ToolMode.multiCommand,
  helpTopics: defaultHelpTopics,
  features: const NavigationFeatures(
    projectTraversal: true,
    gitTraversal: false,
    recursiveScan: true,
    interactiveMode: true, // TUI mode
    // Implemented: the baseline, test, trim and reset executors each return
    // a `[DRY RUN] Would ...` preview instead of writing.
    dryRun: true,
    jsonOutput: false,
    verbose: true,
  ),
  globalOptions: const [
    OptionDefinition.flag(
      name: 'tui',
      description: 'Run in TUI mode (interactive)',
    ),
  ],
  commands: const [
    // Run commands
    baselineCommand,
    testCommand,
    // Analysis commands
    runsCommand,
    statusCommand,
    basediffCommand,
    lastdiffCommand,
    diffCommand,
    historyCommand,
    flakyCommand,
    reportCommand,
    crossreferenceCommand,
    // Fuzzing and mutation testing
    fuzzCommand,
    mutationsCommand,
    // Maintenance commands
    trimCommand,
    resetCommand,
  ],
  helpFooter: '''
Tracking File:
  Baseline: testlog/baseline_<MMDD_HHMM>.csv
  :test appends a result column to the most recent baseline file.
  Raw output: testlog/last_testrun.json (dart test), last_testrun.txt
  (other runners), last_testrun_report.* (the report file)
  (testlog/ is gitignored; doc/ holds hand-authored docs only.)

Result Format:
  OK/OK (pass), X/OK (regression), X/X (known fail),
  OK/X (progress), -/OK (skip), --/OK (absent)

Test Runner (per project):
  1. a testkit: section in buildkit.yaml (command:, report:, report-path:;
     report one of testkit, junit, go-json, libtest, jest-json)
  2. dart test / flutter test (Dart and Flutter projects)
  3. the test: step of buildkit.yaml, writing testkit's line protocol to
     \$TESTKIT_REPORT: one JSON object per line,
     {"test": "<name>", "result": "ok|fail|skip"}
  4. the language's runner: go test -json, cargo test, pytest --junitxml,
     Maven / Gradle surefire XML, jest --json, node --test (JUnit)

Exit Code (:baseline, :test):
  0  every test passed
  1  a test failed (its results are still recorded), no test ran, a test
     file failed to load, or the command could not run
''',
);
