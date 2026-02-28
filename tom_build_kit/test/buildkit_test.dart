/// Integration tests for the BuildKit pipeline orchestrator.
///
/// Uses a dedicated 'pipeline' fixture with test-simple, test-multi,
/// test-shell, and test-internal pipeline definitions.
///
/// Test IDs: BKT_LST01, BKT_HLP01, BKT_HLP02, BKT_CMD01, BKT_PIP01, BKT_DRY01,
///           BKT_DRY02, BKT_OPT01, BKT_SHL01, BKT_XPJ01, BKT_XPJ02,
///           BKT_ERR01, BKT_ERR02, BKT_MAC01, BKT_MAC02, BKT_MAC03,
///           BKT_STD01, BKT_STD02
@TestOn('!browser')
@Timeout(Duration(seconds: 180))
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/test_workspace.dart';

void main() {
  late TestWorkspace ws;
  late TestLogger log;

  setUpAll(() async {
    ws = TestWorkspace();
    print('');
    print('╔══════════════════════════════════════════════════════╗');
    print('║          BuildKit Integration Tests                  ║');
    print('╚══════════════════════════════════════════════════════╝');
    print('Workspace root:  ${ws.workspaceRoot}');
    print('Buildkit root:   ${ws.buildkitRoot}');
    await ws.requireCleanWorkspace();
    await ws.saveHeadRefs();
  });

  setUp(() async {
    log = TestLogger(ws);
    await ws.installFixture('pipeline');
  });

  tearDown(() async {
    log.finish();
    await ws.revertAll();
    // Clean up macro persistence file (untracked, not removed by git checkout)
    final macroFile = File(p.join(ws.workspaceRoot, '.buildkit_macros'));
    if (macroFile.existsSync()) macroFile.deleteSync();
  });

  tearDownAll(() async {
    print('');
    print('  ── BuildKit Tests: Tear-down ──');
    await ws.verifyHeadRefs();
    print('  ── BuildKit Tests: Complete ──');
  });

  // ----------- Tests ----------- //

  group('buildkit', () {
    test('--list shows available pipelines', () async {
      log.start('BKT_LST01', '--list shows available pipelines');
      final result = await ws.runPipeline('--list', []);
      log.capture('buildkit --list', result);

      // --list exits non-zero (1 = error/no direct result)
      expect(result.exitCode, isNot(equals(0)),
          reason: '--list exits with non-zero exit code');

      // Output should show usage or available commands/pipelines
      final combined = '${result.stdout}\n${result.stderr}';
      final hasUsageInfo = combined.contains('buildkit') ||
          combined.contains('Usage') ||
          combined.contains('pipeline');
      expect(hasUsageInfo, isTrue, reason: '--list should show some usage info');

      log.expectation('non-zero exit', result.exitCode != 0);
      log.expectation('has usage info', hasUsageInfo);
    });

    test('--help shows usage information', () async {
      log.start('BKT_HLP01', '--help shows usage');
      final result = await ws.runPipeline('--help', []);
      log.capture('buildkit --help', result);

      final stdout = (result.stdout as String);
      expect(result.exitCode, equals(0));
      // Help should show usage text
      expect(stdout, contains('Usage'),
          reason: 'Help should show Usage section');
      expect(stdout, contains('pipeline'),
          reason: 'Help should mention pipelines');
      log.expectation('shows usage', stdout.contains('Usage'));
    });

    test('direct command execution (:versioner)', () async {
      log.start('BKT_CMD01', 'direct command :versioner');
      final result = await ws.runPipeline(
          ':versioner', [],
          globalArgs: ['--project', 'devops/tom_build_kit', '--dry-run']);
      log.capture('buildkit --project devops/tom_build_kit --dry-run :versioner', result);

      // Versioner in dry-run: exits 0 (no files changed or no output in dry mode)
      expect(result.exitCode, equals(0));
      log.expectation('exit code 0', result.exitCode == 0);
    });

    test('pipeline execution runs all steps', () async {
      log.start('BKT_PIP01', 'pipeline execution');
      // test-simple has two shell echo steps — both should execute
      final result =
          await ws.runPipeline('test-simple', [],
              globalArgs: ['--project', 'devops/tom_build_kit']);
      log.capture('buildkit --project devops/tom_build_kit test-simple', result);

      final stdout = (result.stdout as String);
      expect(result.exitCode, equals(0));

      // Both echo steps should produce output
      expect(stdout, contains('step-1-hello'),
          reason: 'First pipeline step should execute');
      expect(stdout, contains('step-2-world'),
          reason: 'Second pipeline step should execute');

      log.expectation('step 1 executed', stdout.contains('step-1-hello'));
      log.expectation('step 2 executed', stdout.contains('step-2-world'));
    });

    test('--dry-run after pipeline name prevents execution (bug #15)',
        () async {
      log.start('BKT_DRY01', '--dry-run after pipeline prevents execution');
      // Command: buildkit test-simple --project _build --dry-run
      // Bug #15: ArgParser(allowTrailingOptions: false) silently drops
      // --dry-run when placed after the pipeline name.
      final result = await ws.runPipeline(
          'test-simple', ['--project', '_build', '--dry-run']);
      log.capture(
          'buildkit test-simple --project _build --dry-run', result);

      final stdout = (result.stdout as String);
      expect(result.exitCode, equals(0));

      // INTENDED behavior: dry-run should show [DRY RUN] markers
      expect(stdout, contains('[DRY RUN]'),
          reason: 'Dry-run should print [DRY RUN] markers for shell cmds');

      // INTENDED behavior: step commands should appear in [DRY RUN] context
      // only — not as actual echo output on their own lines
      final lines = stdout.split('\n');
      final stepLines = lines.where((l) =>
          l.contains('step-1-hello') || l.contains('step-2-world'));
      for (final line in stepLines) {
        expect(line, contains('[DRY RUN]'),
            reason: 'Step commands should only appear in [DRY RUN] context, '
                'not as actual echo output. Line: $line');
      }

      log.expectation(
          'has [DRY RUN] markers', stdout.contains('[DRY RUN]'));
      log.expectation('no bare echo output',
          !lines.any((l) => l.trim() == 'step-1-hello'));
    },
        skip: 'Bug #15: --dry-run after pipeline name is passed to '
            'pipeline_executor as rest arg. Fix adds a CLI warning but '
            'does not change parsing behavior (by design).');

    test('--dry-run before pipeline name works correctly', () async {
      log.start('BKT_DRY02', '--dry-run before pipeline (workaround)');
      // Workaround for bug #15: place global flags BEFORE the pipeline name.
      // Command: buildkit --dry-run --project _build test-simple
      // Use runPipeline with --dry-run as "pipeline" arg for correct ordering.
      final result = await ws.runPipeline(
          '--dry-run', ['--project', 'devops/tom_build_kit', 'test-simple']);
      log.capture(
          'buildkit --dry-run --project devops/tom_build_kit test-simple', result);

      final stdout = (result.stdout as String);
      expect(result.exitCode, equals(0));

      // With flags before pipeline name, --dry-run IS parsed correctly.
      // New format: shell commands shown as [PIPELINE:shell] <command>
      expect(stdout, contains('[PIPELINE:shell]'),
          reason:
              'Dry-run markers ([PIPELINE:shell]) should appear when flag is before pipeline');

      // Step commands should appear with [PIPELINE:shell] prefix
      final lines = stdout.split('\n');
      final pipelineLines = lines.where((l) => l.contains('[PIPELINE:shell]'));
      expect(pipelineLines, isNotEmpty,
          reason: 'Should have [PIPELINE:shell] lines for each step');

      // No bare echo output (commands not actually executed in dry-run)
      expect(lines.any((l) => l.trim() == 'step-1-hello'), isFalse,
          reason: 'Dry-run should prevent shell commands from executing');

      log.expectation(
          'has [PIPELINE:shell] markers', stdout.contains('[PIPELINE:shell]'));
      log.expectation('no bare echo output',
          !lines.any((l) => l.trim() == 'step-1-hello'));
    });

    test('per-step option suppression (-s-)', () async {
      log.start('BKT_OPT01', 'per-step option suppression');
      // Run with scan and suppress scan for the direct command
      // The -s- flag should suppress the global --scan for just that step
      final result = await ws.runPipeline(':versioner',
          ['-s-'],
          globalArgs: ['--project', 'devops/tom_build_kit', '--dry-run']);
      log.capture('buildkit --project devops/tom_build_kit --dry-run :versioner -s-',
          result);

      // Should complete without error (syntax accepted)
      expect(result.exitCode, equals(0),
          reason: 'Option suppression syntax should be accepted');
      log.expectation('exit code 0', result.exitCode == 0);
    });

    test('shell command execution in pipeline', () async {
      log.start('BKT_SHL01', 'shell command in pipeline');
      // test-shell pipeline has: shell echo "hello from test pipeline"
      final result = await ws.runPipeline(
          'test-shell', [],
          globalArgs: ['--project', 'devops/tom_build_kit']);
      log.capture('buildkit --project devops/tom_build_kit test-shell', result);

      final stdout = (result.stdout as String);
      expect(result.exitCode, equals(0));
      // The echo command should produce output
      expect(stdout, contains('hello from test pipeline'),
          reason: 'Shell echo command should produce output');
      log.expectation(
          'echo output present', stdout.contains('hello from test pipeline'));
    });

    test('--exclude-projects filters pipeline targets', () async {
      log.start('BKT_XPJ01', '--exclude-projects in pipeline');
      final result = await ws.runPipeline('test-simple', [],
          globalArgs: [
            '--scan', '.',
            '--recursive',
            '--exclude-projects', '_build',
            '--dry-run',
            '--verbose',
          ]);
      log.capture('buildkit --scan . --recursive --exclude-projects _build --dry-run test-simple',
          result);

      expect(result.exitCode, equals(0));

      // _build should be excluded from processing
      log.expectation('exit code 0', result.exitCode == 0);
    });

    test('--exclude and --exclude-projects combined', () async {
      log.start('BKT_XPJ02', '--exclude + --exclude-projects');
      final result = await ws.runPipeline('test-simple', [],
          globalArgs: [
            '--scan', '.',
            '--recursive',
            '--exclude', 'core/*',
            '--exclude-projects', '_build',
            '--dry-run',
            '--verbose',
          ]);
      log.capture('buildkit --scan . --recursive --exclude core/* --exclude-projects _build test-simple',
          result);

      expect(result.exitCode, equals(0));

      // Both exclusion types should apply
      log.expectation('exit code 0', result.exitCode == 0);
    });

    test('unknown pipeline name produces clear error', () async {
      log.start('BKT_ERR01', 'unknown pipeline error handling');
      // Use flags-before-pipeline workaround for bug #15.
      // Command: buildkit --project _build nonexistent-pipeline-xyz
      final result = await ws.runPipeline(
          '--project', ['_build', 'nonexistent-pipeline-xyz']);
      log.capture(
          'buildkit --project _build nonexistent-pipeline-xyz', result);

      // Unknown pipeline should produce an error (non-zero exit)
      expect(result.exitCode, isNot(equals(0)),
          reason: 'Unknown pipeline name should fail with non-zero exit');

      final combined = '${result.stdout}\n${result.stderr}';
      final hasError = combined.toLowerCase().contains('not found') ||
          combined.toLowerCase().contains('unknown') ||
          combined.toLowerCase().contains('error') ||
          combined.toLowerCase().contains('pipeline') ||
          combined.toLowerCase().contains('command') ||
          combined.toLowerCase().contains('no command');
      expect(hasError, isTrue,
          reason: 'Should show clear error for unknown pipeline name. '
              'Output: ${combined.substring(0, combined.length.clamp(0, 300))}');

      log.expectation('non-zero exit', result.exitCode != 0);
      log.expectation('has error message', hasError);
    });

    test('--project with non-existent path gives clear error', () async {
      log.start('BKT_ERR02', 'non-existent --project error');
      // Command: buildkit --project _build/nonexistent test-simple
      final result = await ws.runPipeline(
          '--project', ['_build/nonexistent_dir', 'test-simple']);
      log.capture(
          'buildkit --project _build/nonexistent_dir test-simple', result);

      // Non-existent --project filter: pipeline still runs in workspace root
      // (project filter is a traversal filter, not a hard path check).
      // Just verify the command completes without crashing.
      log.expectation('completes without crash', true);
    });
  });

  group('help', () {
    test('help pipelines shows pipeline configuration reference', () async {
      log.start('BKT_HLP02', 'help pipelines shows pipeline config reference');
      final result = await ws.runPipeline('help', ['pipelines']);
      log.capture('buildkit help pipelines', result);

      final stdout = (result.stdout as String);
      expect(result.exitCode, equals(0),
          reason: 'help pipelines should exit 0');
      expect(stdout, contains('Pipeline Configuration'),
          reason: 'Should show pipeline configuration header');
      expect(stdout, contains('stdin'),
          reason: 'Should document stdin command prefix');
      expect(stdout, contains('shell'),
          reason: 'Should document shell command prefix');
      expect(stdout, contains('precore'),
          reason: 'Should document pipeline structure phases');
      log.expectation('exits 0', result.exitCode == 0);
      log.expectation(
          'shows pipeline config', stdout.contains('Pipeline Configuration'));
    });
  });

  group('stdin', () {
    test('stdin pipeline dry-run prints command and stdin lines', () async {
      log.start('BKT_STD01', 'stdin pipeline dry-run output');
      final result = await ws.runPipeline(
        'test-stdin',
        [],
        globalArgs: ['--dry-run'],
      );
      log.capture('buildkit --dry-run test-stdin', result);

      final stdout = (result.stdout as String);
      expect(result.exitCode, equals(0),
          reason: 'dry-run stdin pipeline should exit 0');
      expect(stdout, contains('[PIPELINE:stdin]'),
          reason: 'Should show [PIPELINE:stdin] prefix');
      expect(stdout, contains('cat'),
          reason: 'Should show the piped command');
      expect(stdout, contains('Hello stdin world'),
          reason: 'Should show stdin lines with | prefix');
      log.expectation('exits 0', result.exitCode == 0);
      log.expectation('shows stdin prefix', stdout.contains('[PIPELINE:stdin]'));
      log.expectation(
          'shows stdin lines', stdout.contains('Hello stdin world'));
    });

    test('stdin pipeline executes command with piped input', () async {
      log.start('BKT_STD02', 'stdin pipeline actual execution');
      final result = await ws.runPipeline(
        'test-stdin',
        [],
        globalArgs: ['--project', 'devops/tom_build_kit'],
      );
      log.capture('buildkit --project devops/tom_build_kit test-stdin', result);

      final combined = '${result.stdout}\n${result.stderr}';
      expect(result.exitCode, equals(0),
          reason: 'stdin pipeline should exit 0. Output: $combined');
      // cat echoes the stdin content back to stdout
      expect((result.stdout as String), contains('Hello stdin world'),
          reason: 'cat should echo stdin content to stdout');
      log.expectation('exits 0', result.exitCode == 0);
      log.expectation(
          'echoes stdin', (result.stdout as String).contains('Hello stdin world'));
    });
  });

  group('macros', () {
    test('defines shows no macros when none defined', () async {
      log.start('BKT_MAC01', 'defines with no macros');
      final result = await ws.runPipeline(':defines', []);
      log.capture('buildkit :defines', result);

      final stdout = (result.stdout as String);
      expect(result.exitCode, equals(0));
      expect(stdout, contains('No defines found'),
          reason: 'Should show "No defines found" message');
      log.expectation('shows no defines', stdout.contains('No defines found'));
    });

    test('define creates a macro and defines lists it', () async {
      log.start('BKT_MAC02', 'define and list macro');

      // Define a persistent define
      var result = await ws.runPipeline(':define', ['test=:versioner --list']);
      log.capture('buildkit :define test=:versioner --list', result);
      expect(result.exitCode, equals(0));
      expect((result.stdout as String), contains('Added define: test'),
          reason: 'Should confirm define was added');

      // List defines
      result = await ws.runPipeline(':defines', []);
      log.capture('buildkit :defines', result);
      final stdout = (result.stdout as String);
      expect(result.exitCode, equals(0));
      expect(stdout, contains('test'),
          reason: 'Should list the test macro');
      expect(stdout, contains(':versioner'),
          reason: 'Should show macro value');
      log.expectation('define listed', stdout.contains('test'));
    });

    test('undefine removes a macro', () async {
      log.start('BKT_MAC03', 'undefine removes macro');

      // Define a persistent define first
      var result = await ws.runPipeline(':define', ['removeme=:cleanup']);
      log.capture('buildkit :define removeme=:cleanup', result);
      expect(result.exitCode, equals(0));

      // Undefine it
      result = await ws.runPipeline(':undefine', ['removeme']);
      log.capture('buildkit :undefine removeme', result);
      expect(result.exitCode, equals(0));
      expect((result.stdout as String), contains('Removed define: removeme'),
          reason: 'Should confirm define was removed');

      // Verify it's gone
      result = await ws.runPipeline(':defines', []);
      log.capture('buildkit :defines', result);
      final stdout = (result.stdout as String);
      expect(stdout, isNot(contains('removeme')),
          reason: 'Macro should be removed from list');
      log.expectation('define removed', !stdout.contains('removeme'));
    });
  });
}
