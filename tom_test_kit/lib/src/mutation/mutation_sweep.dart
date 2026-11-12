import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:tom_build_base/tom_build_base.dart' show killProcessTree;

import '../util/test_runner.dart';
import 'mutation_catalogue.dart';

/// What one mutation did to its tests.
enum MutationVerdict {
  /// The tests failed: the behaviour is pinned.
  killed,

  /// The tests did not finish within the time bound: the suite noticed, so it
  /// counts as killed.
  hung,

  /// The tests passed with the behaviour removed: it is named, not pinned.
  survived,

  /// The mutant did not compile: it fails every test without asking anything
  /// of them, so the entry has to be rewritten.
  invalid,

  /// Not run: a precondition it `requires` is not met here.
  skipped,
}

/// One mutation's result.
class MutationOutcome {
  /// The catalogue entry.
  final MutationEntry entry;

  /// What happened.
  final MutationVerdict verdict;

  /// How long its run took.
  final Duration elapsed;

  /// Why it was skipped.
  final String? reason;

  /// Creates an outcome.
  const MutationOutcome(
    this.entry,
    this.verdict, {
    this.elapsed = Duration.zero,
    this.reason,
  });

  /// The outcome as JSON.
  Map<String, Object?> toJson() => {
    ...entry.toJson(),
    'verdict': verdict.name,
    'seconds': elapsed.inMilliseconds / 1000,
    'reason': ?reason,
  };
}

/// The outcome of a sweep.
class MutationSweepResult {
  /// Why the sweep stopped before sweeping (a drifted `find`, an undeclared
  /// requirement, a red baseline, an unknown module); null when it ran.
  final String? error;

  /// The outcome of every selected entry, in catalogue order.
  final List<MutationOutcome> outcomes;

  /// The modules swept.
  final List<String> modules;

  /// Creates a result.
  const MutationSweepResult({
    this.error,
    this.outcomes = const [],
    this.modules = const [],
  });

  int _count(bool Function(MutationVerdict) test) =>
      outcomes.where((o) => test(o.verdict)).length;

  /// Killed, hung ones included.
  int get killed =>
      _count((v) => v == MutationVerdict.killed || v == MutationVerdict.hung);

  /// Survivors.
  int get survived => _count((v) => v == MutationVerdict.survived);

  /// Mutants that did not compile.
  int get invalid => _count((v) => v == MutationVerdict.invalid);

  /// Entries not run for a missing precondition.
  int get skipped => _count((v) => v == MutationVerdict.skipped);

  /// Mutations run.
  int get run => killed + survived + invalid;

  /// Killed / run, in percent; null when nothing ran.
  double? get killRate => run == 0 ? null : killed * 100 / run;

  /// The sweep's exit code: surviving + invalid (1 when it stopped early).
  int get exitCode => error != null ? 1 : survived + invalid;

  /// Per-module counts.
  Map<String, Map<String, int>> get byModule => {
    for (final module in modules)
      module: {
        for (final v in MutationVerdict.values)
          v.name: outcomes
              .where((o) => o.entry.module == module && o.verdict == v)
              .length,
      },
  };

  /// The result as JSON.
  Map<String, Object?> toJson() => {
    'error': error,
    'killed': killed,
    'survived': survived,
    'invalid': invalid,
    'skipped': skipped,
    'run': run,
    'killRate': killRate,
    'modules': byModule,
    'outcomes': [for (final o in outcomes) o.toJson()],
  };

  /// The result as a Markdown report.
  String toMarkdown({String? title}) {
    final b = StringBuffer('# ${title ?? 'Mutation sweep'}\n\n');
    if (error != null) {
      b.writeln('**Not swept:** $error');
      return b.toString();
    }
    b
      ..writeln(
        'Kill rate: **${killRate == null ? 'not measured' : '${killRate!.toStringAsFixed(1)} %'}** '
        '— $run run, $killed killed, $survived survived, $invalid invalid, '
        '$skipped skipped.\n',
      )
      ..writeln('| Module | Killed | Survived | Invalid | Skipped |')
      ..writeln('|---|---|---|---|---|');
    byModule.forEach((module, c) {
      b.writeln(
        '| $module | ${c['killed']! + c['hung']!} | ${c['survived']} | '
        '${c['invalid']} | ${c['skipped']} |',
      );
    });
    for (final (label, verdict) in [
      ('Survived', MutationVerdict.survived),
      ('Invalid (does not compile)', MutationVerdict.invalid),
      ('Skipped', MutationVerdict.skipped),
    ]) {
      final list = outcomes.where((o) => o.verdict == verdict).toList();
      if (list.isEmpty) continue;
      b.writeln('\n## $label\n');
      for (final o in list) {
        b.writeln(
          '- **${o.entry.module}**: ${o.entry.behaviour} '
          '(`${o.entry.file}`${o.reason == null ? '' : '; ${o.reason}'})',
        );
      }
    }
    return b.toString();
  }
}

/// A catalogued mutation sweep over one package: break each recorded
/// behaviour on purpose and see whether its tests notice.
///
/// Before anything is mutated: every `find` of the selected modules must occur
/// in its file exactly once (all drifted entries are named together), every
/// `requires` must be declared, and the named tests must pass unmutated — a
/// red suite would call every mutation killed. Each mutation is applied, its
/// tests run (`flutter test` for a Flutter package) with a time bound that
/// kills the whole process tree, and the file is restored whatever happens,
/// SIGINT and SIGTERM included.
class MutationSweep {
  /// The package root.
  final String projectPath;

  /// The catalogue.
  final MutationCatalogue catalogue;

  /// The declared preconditions.
  final Map<String, MutationRequirement> requirements;

  /// The modules to sweep; every module when empty.
  final List<String> modules;

  /// The time bound of one test run.
  final Duration timeout;

  /// Where progress is written.
  final void Function(String line) log;

  /// Creates a sweep.
  MutationSweep({
    required this.projectPath,
    required this.catalogue,
    this.requirements = const {},
    this.modules = const [],
    this.timeout = const Duration(minutes: 10),
    void Function(String line)? log,
  }) : log = log ?? ((line) => stdout.writeln(line));

  /// How a compile error reads in test output (the common front end's
  /// `<file>.dart:<line>:<col>: Error:`); a runtime failure never does.
  static final compileError = RegExp(r'\S+\.dart:\d+:\d+: Error:');

  String? _currentFile;
  String? _currentOriginal;
  Process? _currentProcess;

  /// The selected modules, or an error naming the unknown ones.
  (List<String>, String?) _select() {
    final selected = modules.isEmpty
        ? catalogue.modules.keys.toList()
        : modules;
    final unknown = selected.where((m) => !catalogue.modules.containsKey(m));
    if (unknown.isNotEmpty) {
      return (selected, 'not in the catalogue: ${unknown.join(', ')}');
    }
    return (selected, null);
  }

  /// Lists the selected entries and runs nothing.
  MutationSweepResult list() {
    final (selected, error) = _select();
    if (error != null) return MutationSweepResult(error: error);
    for (final module in selected) {
      final entries = catalogue.modules[module]!;
      log('$module (${entries.length})');
      for (final e in entries) {
        log(
          '    ${e.behaviour}${e.requires.isEmpty ? '' : '  [requires ${e.requires.join(', ')}]'}',
        );
      }
    }
    return MutationSweepResult(modules: selected);
  }

  /// Runs the sweep.
  Future<MutationSweepResult> run() async {
    final (selected, error) = _select();
    if (error != null) return MutationSweepResult(error: error);
    final entries = [for (final m in selected) ...catalogue.modules[m]!];

    final drifted = <String>[];
    for (final e in entries) {
      final file = File(p.join(projectPath, e.file));
      final count = file.existsSync()
          ? _occurrences(file.readAsStringSync(), e.find)
          : 0;
      if (count != 1) {
        drifted.add(
          '  ${e.module}: ${e.behaviour}\n    ${e.file}: `find` matches '
          '$count times${file.existsSync() ? '' : ' (no such file)'}',
        );
      }
    }
    if (drifted.isNotEmpty) {
      return MutationSweepResult(
        modules: selected,
        error:
            'catalogue entries no longer match their file:\n'
            '${drifted.join('\n')}',
      );
    }

    final used = {for (final e in entries) ...e.requires};
    final undeclared = used.where((r) => !requirements.containsKey(r));
    if (undeclared.isNotEmpty) {
      return MutationSweepResult(
        modules: selected,
        error:
            '`requires:` names ${undeclared.map((r) => '`$r`').join(', ')}, '
            'which the requirements file does not declare',
      );
    }
    final unmet = <String, String>{};
    for (final name in used) {
      final why = await requirements[name]!.unmet(projectPath);
      if (why != null) {
        unmet[name] = why;
        final what = requirements[name]!.description;
        log(
          'requirement `$name` not met ($why)${what.isEmpty ? '' : ' — $what'}: '
          'its entries are skipped',
        );
      }
    }
    String? skipReason(MutationEntry e) {
      for (final r in e.requires) {
        if (unmet.containsKey(r)) return 'requires $r: ${unmet[r]}';
      }
      return null;
    }

    final runnable = entries.where((e) => skipReason(e) == null).toList();
    final baseline = {for (final e in runnable) ...e.tests}.toList()..sort();
    final signals = _watchSignals();
    try {
      if (baseline.isNotEmpty) {
        log('baseline: ${baseline.length} test file(s)');
        final (code, output) = await _runTests(baseline);
        if (code != 0) {
          final failing = {
            for (final line in const LineSplitter().convert(output))
              if (line.trimRight().endsWith('[E]')) line.trim(),
          }.toList()..sort();
          return MutationSweepResult(
            modules: selected,
            error:
                'the suite is red before any mutation, so nothing can be '
                'concluded from it${code == null ? ' (it did not finish)' : ''}. '
                'Failing:\n  ${failing.join('\n  ')}\nFix it first.',
          );
        }
      }

      final outcomes = <MutationOutcome>[];
      for (final module in selected) {
        final moduleEntries = catalogue.modules[module]!;
        log('$module (${moduleEntries.length})');
        for (final e in moduleEntries) {
          final reason = skipReason(e);
          if (reason != null) {
            log('    skipped         ${e.behaviour}  ($reason)');
            outcomes.add(
              MutationOutcome(e, MutationVerdict.skipped, reason: reason),
            );
            continue;
          }
          final outcome = await _sweep(e);
          final mark = switch (outcome.verdict) {
            MutationVerdict.killed => 'killed       ',
            MutationVerdict.hung => 'killed (hung)',
            MutationVerdict.survived => 'SURVIVED     ',
            MutationVerdict.invalid => 'INVALID      ',
            MutationVerdict.skipped => 'skipped      ',
          };
          final seconds = (outcome.elapsed.inMilliseconds / 1000)
              .toStringAsFixed(1)
              .padLeft(5);
          log('    $mark $seconds s  ${e.behaviour}');
          outcomes.add(outcome);
        }
      }
      return MutationSweepResult(outcomes: outcomes, modules: selected);
    } finally {
      for (final s in signals) {
        await s.cancel();
      }
    }
  }

  static int _occurrences(String text, String find) {
    if (find.isEmpty) return 0;
    var count = 0;
    for (var i = text.indexOf(find); i >= 0; i = text.indexOf(find, i + 1)) {
      count++;
    }
    return count;
  }

  Future<MutationOutcome> _sweep(MutationEntry e) async {
    final file = File(p.join(projectPath, e.file));
    final original = file.readAsStringSync();
    final stopwatch = Stopwatch()..start();
    int? code;
    String output;
    _currentFile = file.path;
    _currentOriginal = original;
    try {
      file.writeAsStringSync(original.replaceFirst(e.find, e.replace));
      (code, output) = await _runTests(e.tests);
    } finally {
      file.writeAsStringSync(original);
      _currentFile = null;
      _currentOriginal = null;
    }
    final verdict = code == null
        ? MutationVerdict.hung
        : code == 0
        ? MutationVerdict.survived
        : compileError.hasMatch(output)
        ? MutationVerdict.invalid
        : MutationVerdict.killed;
    return MutationOutcome(e, verdict, elapsed: stopwatch.elapsed);
  }

  /// Runs [tests]; the exit code, or null when the run hit the time bound
  /// (and its process tree was killed), with the combined output.
  Future<(int?, String)> _runTests(List<String> tests) async {
    final runner = TestRunner.forPackage(projectPath);
    final process = await Process.start(
      runner.executable,
      ['test', '-j', '1', '--reporter', 'expanded', ...tests],
      workingDirectory: projectPath,
      runInShell: runner.runInShell,
    );
    _currentProcess = process;
    final out = StringBuffer();
    final done = Future.wait([
      process.stdout.transform(utf8.decoder).forEach(out.write),
      process.stderr.transform(utf8.decoder).forEach(out.write),
    ]);
    try {
      final code = await process.exitCode.timeout(timeout);
      await done;
      return (code, out.toString());
    } on TimeoutException {
      await killProcessTree(process.pid);
      await done.timeout(const Duration(seconds: 5), onTimeout: () => []);
      out.write('\n[timed out after ${timeout.inSeconds} s]');
      return (null, out.toString());
    } finally {
      _currentProcess = null;
    }
  }

  /// On SIGINT / SIGTERM: put the mutated file back, stop the test run and
  /// exit — an interrupted sweep must not leave a mutation in the package.
  List<StreamSubscription<ProcessSignal>> _watchSignals() {
    void onSignal(ProcessSignal signal) {
      final path = _currentFile, original = _currentOriginal;
      if (path != null && original != null) {
        File(path).writeAsStringSync(original);
        stderr.writeln('\ninterrupted: restored $path');
      }
      final process = _currentProcess;
      if (process != null) killProcessTree(process.pid);
      exit(signal == ProcessSignal.sigint ? 130 : 143);
    }

    return [
      ProcessSignal.sigint.watch().listen(onSignal),
      if (!Platform.isWindows) ProcessSignal.sigterm.watch().listen(onSignal),
    ];
  }
}
