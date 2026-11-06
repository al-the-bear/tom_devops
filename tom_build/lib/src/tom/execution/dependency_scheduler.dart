/// Dependency Scheduler
///
/// Runs one job per project in parallel while keeping the projects'
/// dependency order: a project starts once every project it depends on has
/// succeeded, and at most [DependencyScheduler.concurrency] run at a time.
/// It is how the Tom CLI runs an action over several projects
/// (`tom :groups <group> :build`): independent projects build side by side,
/// dependent ones wait.
library;

import 'dart:async';

/// How a scheduled project ended.
enum ScheduledOutcome {
  /// Ran, and `succeeded` said so.
  succeeded,

  /// Ran and failed, or threw ([ScheduledRun.error]).
  failed,

  /// Never started: a dependency failed or was skipped, or the run stopped
  /// after a failure ([ScheduledRun.skippedBecause]).
  skipped,
}

/// The result of one project's job.
class ScheduledRun<R> {
  const ScheduledRun._({
    required this.project,
    required this.outcome,
    this.result,
    this.error,
    this.skippedBecause,
  });

  final String project;
  final ScheduledOutcome outcome;

  /// The job's result, when it returned one.
  final R? result;

  /// What the job threw, when it threw.
  final Object? error;

  /// Why the project did not run, when [outcome] is skipped.
  final String? skippedBecause;

  @override
  String toString() => '$project: ${outcome.name}'
      '${skippedBecause == null ? '' : ' ($skippedBecause)'}';
}

/// The projects to run depend on each other in a cycle.
class DependencyCycleException implements Exception {
  const DependencyCycleException(this.cycle);

  /// The cycle, its first project repeated at the end (`a -> b -> a`).
  final List<String> cycle;

  @override
  String toString() =>
      'DependencyCycleException: ${cycle.join(' -> ')}; remove one '
      'dependency to break the cycle';
}

/// Runs jobs over projects in dependency order, [concurrency] at a time.
class DependencyScheduler {
  DependencyScheduler({required this.concurrency}) {
    if (concurrency < 1) {
      throw ArgumentError.value(concurrency, 'concurrency', 'must be >= 1');
    }
  }

  /// Most jobs running at once; 1 runs the projects one after another.
  final int concurrency;

  /// Runs [execute] for every project of [order].
  ///
  /// [order] is the preferred start order (e.g. the build order): among the
  /// projects whose dependencies are done, the earliest in [order] starts
  /// first, so `concurrency: 1` runs a valid topological sequence.
  /// [dependencies] maps a project to the projects it waits for; projects not
  /// in [order] are not waited for. [succeeded] reads a job's result.
  ///
  /// When a project fails, its dependents (transitively) are skipped. With
  /// [stopOnFailure] nothing new starts after the first failure: running jobs
  /// finish, and every project not yet started is skipped.
  ///
  /// Answers one [ScheduledRun] per project, in [order]. Throws
  /// [DependencyCycleException], before running anything, when the selected
  /// projects depend on each other in a cycle.
  Future<List<ScheduledRun<R>>> run<R>({
    required List<String> order,
    required Map<String, Iterable<String>> dependencies,
    required Future<R> Function(String project) execute,
    required bool Function(R result) succeeded,
    bool stopOnFailure = true,
  }) async {
    final selected = order.toSet();
    final waitsFor = {
      for (final project in order)
        project: {
          for (final dependency in dependencies[project] ?? const <String>[])
            if (selected.contains(dependency) && dependency != project)
              dependency,
        },
    };
    final cycle = _findCycle(order, waitsFor);
    if (cycle != null) throw DependencyCycleException(cycle);

    if (order.isEmpty) return const [];
    return _SchedulerRun<R>(
      order: order,
      waitsFor: waitsFor,
      concurrency: concurrency,
      execute: execute,
      succeeded: succeeded,
      stopOnFailure: stopOnFailure,
    ).start();
  }

  /// A cycle among [order]'s dependencies, or null.
  static List<String>? _findCycle(
    List<String> order,
    Map<String, Set<String>> waitsFor,
  ) {
    final done = <String>{};
    final path = <String>[];

    List<String>? visit(String project) {
      final onPath = path.indexOf(project);
      if (onPath >= 0) return [...path.sublist(onPath), project];
      if (done.contains(project)) return null;
      path.add(project);
      for (final dependency in waitsFor[project]!) {
        final cycle = visit(dependency);
        if (cycle != null) return cycle;
      }
      path.removeLast();
      done.add(project);
      return null;
    }

    for (final project in order) {
      final cycle = visit(project);
      if (cycle != null) return cycle;
    }
    return null;
  }
}

/// The state of one [DependencyScheduler.run].
class _SchedulerRun<R> {
  _SchedulerRun({
    required this.order,
    required this.waitsFor,
    required this.concurrency,
    required this.execute,
    required this.succeeded,
    required this.stopOnFailure,
  });

  final List<String> order;
  final Map<String, Set<String>> waitsFor;
  final int concurrency;
  final Future<R> Function(String project) execute;
  final bool Function(R result) succeeded;
  final bool stopOnFailure;

  final _finished = <String, ScheduledRun<R>>{};
  final _running = <String>{};
  final _allDone = Completer<void>();

  /// The project whose failure stopped the run (with stopOnFailure).
  String? _stoppedBy;

  Future<List<ScheduledRun<R>>> start() async {
    _schedule();
    await _allDone.future;
    return [for (final project in order) _finished[project]!];
  }

  /// Settles every project that can be settled now and starts what may start.
  ///
  /// One pass can resolve a project whose dependency comes later in [order]
  /// (a skip that cascades backwards), so passes repeat until one changes
  /// nothing.
  void _schedule() {
    var before = -1;
    while (before != _finished.length + _running.length) {
      before = _finished.length + _running.length;
      _pass();
    }
    if (_finished.length == order.length && !_allDone.isCompleted) {
      _allDone.complete();
    }
  }

  void _pass() {
    for (final project in order) {
      if (_finished.containsKey(project) || _running.contains(project)) {
        continue;
      }
      if (_stoppedBy != null) {
        _skip(project, 'stopped after $_stoppedBy failed');
        continue;
      }
      final blocker = waitsFor[project]!.where((d) {
        final outcome = _finished[d]?.outcome;
        return outcome != null && outcome != ScheduledOutcome.succeeded;
      }).firstOrNull;
      if (blocker != null) {
        _skip(project,
            'dependency $blocker ${_finished[blocker]!.outcome.name}');
        continue;
      }
      final ready = waitsFor[project]!
          .every((d) => _finished[d]?.outcome == ScheduledOutcome.succeeded);
      if (ready && _running.length < concurrency) _start(project);
    }
  }

  void _skip(String project, String because) {
    _finished[project] = ScheduledRun._(
      project: project,
      outcome: ScheduledOutcome.skipped,
      skippedBecause: because,
    );
  }

  void _start(String project) {
    _running.add(project);
    // The job's completion drives the next pass; nothing awaits it here.
    unawaited(Future<R>.sync(() => execute(project)).then(
      (result) => ScheduledRun<R>._(
        project: project,
        outcome: succeeded(result)
            ? ScheduledOutcome.succeeded
            : ScheduledOutcome.failed,
        result: result,
      ),
      onError: (Object error) => ScheduledRun<R>._(
        project: project,
        outcome: ScheduledOutcome.failed,
        error: error,
      ),
    ).then((run) {
      _running.remove(project);
      _finished[project] = run;
      if (run.outcome == ScheduledOutcome.failed && stopOnFailure) {
        _stoppedBy ??= project;
      }
      _schedule();
    }));
  }
}
