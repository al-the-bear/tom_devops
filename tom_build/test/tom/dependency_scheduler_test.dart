// DependencyScheduler: runs an action over projects in parallel, starting a
// project only once every project it depends on has succeeded, with at most
// `concurrency` running at a time. And TomProject.dependenciesFor, which says
// what a project waits for under one action.
import 'dart:async';

import 'package:test/test.dart';
import 'package:tom_build/tom_build.dart';

/// An execute callback whose runs finish only when the test completes them.
class _Controlled {
  final _pending = <String, Completer<bool>>{};
  final started = <String>[];
  int inFlight = 0;
  int maxInFlight = 0;

  Future<bool> execute(String project) {
    started.add(project);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    final completer = Completer<bool>();
    _pending[project] = completer;
    return completer.future.whenComplete(() => inFlight--);
  }

  Future<void> finish(String project, {bool ok = true}) async {
    _pending.remove(project)!.complete(ok);
    // Let the scheduler react (start the next projects).
    await pumpEventQueue();
  }
}

Future<bool> _immediate(String project) async => true;

void main() {
  group('DependencyScheduler', () {
    test('DS-1: concurrency 1 runs one project at a time, in order', () async {
      final runs = _Controlled();
      final done = DependencyScheduler(concurrency: 1).run<bool>(
        order: ['a', 'b', 'c'],
        dependencies: const {},
        execute: runs.execute,
        succeeded: (ok) => ok,
      );
      await pumpEventQueue();
      expect(runs.started, ['a']);
      await runs.finish('a');
      expect(runs.started, ['a', 'b']);
      await runs.finish('b');
      await runs.finish('c');
      final results = await done;
      expect(runs.maxInFlight, 1);
      expect(results.map((r) => r.outcome),
          everyElement(ScheduledOutcome.succeeded));
    });

    test('DS-2: independent projects run in parallel up to the limit',
        () async {
      final runs = _Controlled();
      final done = DependencyScheduler(concurrency: 2).run<bool>(
        order: ['a', 'b', 'c'],
        dependencies: const {},
        execute: runs.execute,
        succeeded: (ok) => ok,
      );
      await pumpEventQueue();
      expect(runs.started, ['a', 'b']);
      await runs.finish('b');
      expect(runs.started, ['a', 'b', 'c']);
      await runs.finish('a');
      await runs.finish('c');
      await done;
      expect(runs.maxInFlight, 2);
    });

    test('DS-3: a project starts only after all its dependencies succeeded',
        () async {
      final runs = _Controlled();
      final done = DependencyScheduler(concurrency: 4).run<bool>(
        order: ['core', 'ui', 'app'],
        dependencies: {
          'ui': ['core'],
          'app': ['core', 'ui'],
        },
        execute: runs.execute,
        succeeded: (ok) => ok,
      );
      await pumpEventQueue();
      expect(runs.started, ['core']);
      await runs.finish('core');
      expect(runs.started, ['core', 'ui']);
      await runs.finish('ui');
      expect(runs.started, ['core', 'ui', 'app']);
      await runs.finish('app');
      await done;
    });

    test('DS-4: dependencies outside the selection are not waited for',
        () async {
      final results = await DependencyScheduler(concurrency: 2).run<bool>(
        order: ['app'],
        dependencies: {
          'app': ['not_selected'],
        },
        execute: _immediate,
        succeeded: (ok) => ok,
      );
      expect(results.single.outcome, ScheduledOutcome.succeeded);
    });

    test('DS-5: stopOnFailure starts nothing new; running projects finish',
        () async {
      final runs = _Controlled();
      final done = DependencyScheduler(concurrency: 2).run<bool>(
        order: ['a', 'b', 'c', 'd'],
        dependencies: const {},
        execute: runs.execute,
        succeeded: (ok) => ok,
      );
      await pumpEventQueue();
      await runs.finish('a', ok: false);
      expect(runs.started, ['a', 'b'], reason: 'c must not start');
      await runs.finish('b');
      final results = await done;
      expect({for (final r in results) r.project: r.outcome}, {
        'a': ScheduledOutcome.failed,
        'b': ScheduledOutcome.succeeded,
        'c': ScheduledOutcome.skipped,
        'd': ScheduledOutcome.skipped,
      });
      expect(results[2].skippedBecause, contains('a'));
    });

    test('DS-6: without stopOnFailure only the dependents of a failure are '
        'skipped, transitively', () async {
      final results = await DependencyScheduler(concurrency: 3).run<bool>(
        order: ['core', 'ui', 'app', 'tool'],
        dependencies: {
          'ui': ['core'],
          'app': ['ui'],
        },
        execute: (project) async => project != 'core',
        succeeded: (ok) => ok,
        stopOnFailure: false,
      );
      expect({for (final r in results) r.project: r.outcome}, {
        'core': ScheduledOutcome.failed,
        'ui': ScheduledOutcome.skipped,
        'app': ScheduledOutcome.skipped,
        'tool': ScheduledOutcome.succeeded,
      });
      expect(results[1].skippedBecause, contains('core'));
      expect(results[2].skippedBecause, contains('ui'));
    });

    test('DS-12: a skip cascades to dependents listed earlier in the order',
        () async {
      final results = await DependencyScheduler(concurrency: 2)
          .run<bool>(
            order: ['app', 'ui', 'core'],
            dependencies: {
              'app': ['ui'],
              'ui': ['core'],
            },
            execute: (project) async => false,
            succeeded: (ok) => ok,
            stopOnFailure: false,
          )
          .timeout(const Duration(seconds: 5));
      expect(results.map((r) => r.outcome), [
        ScheduledOutcome.skipped,
        ScheduledOutcome.skipped,
        ScheduledOutcome.failed,
      ]);
    });

    test('DS-7: a dependency cycle among the selection fails before any run',
        () async {
      final started = <String>[];
      await expectLater(
        DependencyScheduler(concurrency: 2).run<bool>(
          order: ['a', 'b', 'c'],
          dependencies: {
            'a': ['c'],
            'b': ['a'],
            'c': ['b'],
          },
          execute: (project) async {
            started.add(project);
            return true;
          },
          succeeded: (ok) => ok,
        ),
        throwsA(isA<DependencyCycleException>().having(
            (e) => e.cycle, 'cycle', containsAll(['a', 'b', 'c']))),
      );
      expect(started, isEmpty);
    });

    test('DS-8: a run that throws is a failure with its error', () async {
      final results = await DependencyScheduler(concurrency: 1).run<bool>(
        order: ['a', 'b'],
        dependencies: {
          'b': ['a'],
        },
        execute: (project) async => throw StateError('boom in $project'),
        succeeded: (ok) => ok,
        stopOnFailure: false,
      );
      expect(results[0].outcome, ScheduledOutcome.failed);
      expect(results[0].error, isA<StateError>());
      expect(results[1].outcome, ScheduledOutcome.skipped);
    });

    test('DS-9: results come back in the given order, not completion order',
        () async {
      final runs = _Controlled();
      final done = DependencyScheduler(concurrency: 3).run<bool>(
        order: ['a', 'b', 'c'],
        dependencies: const {},
        execute: runs.execute,
        succeeded: (ok) => ok,
      );
      await pumpEventQueue();
      await runs.finish('c');
      await runs.finish('b');
      await runs.finish('a');
      expect((await done).map((r) => r.project), ['a', 'b', 'c']);
    });

    test('DS-10: concurrency must be at least 1', () {
      expect(() => DependencyScheduler(concurrency: 0), throwsArgumentError);
    });

    test('DS-11: a dependency listed later in the order still runs first',
        () async {
      final started = <String>[];
      await DependencyScheduler(concurrency: 1).run<bool>(
        order: ['app', 'core'],
        dependencies: {
          'app': ['core'],
        },
        execute: (project) async {
          started.add(project);
          return true;
        },
        succeeded: (ok) => ok,
      );
      expect(started, ['core', 'app']);
    });
  });

  group('TomProject.dependenciesFor', () {
    test('DS-20: build-after applies to every action', () {
      final project = TomProject.fromYaml('app', {
        'build-after': ['core'],
      });
      expect(project.dependenciesFor('build'), ['core']);
      expect(project.dependenciesFor('test'), ['core']);
    });

    test('DS-21: <action>-after replaces build-after for that action', () {
      final project = TomProject.fromYaml('app', {
        'build-after': ['core'],
        'action-order': {
          'deploy-after': ['server'],
        },
      });
      expect(project.dependenciesFor('deploy'), ['server']);
      expect(project.dependenciesFor('build'), ['core']);
    });
  });
}
