/// The Python runner templates: unittest through testkit's bundled runner
/// (a project without pytest), pytest / nose2 / tox / nox detected from the
/// project's files, the doctest variants, and `{python}`, which runs the
/// project's own environment (uv, poetry, pipenv, a venv) when it has one.
///
/// TK-PY-3..6 run the bundled unittest runner with the machine's Python (they
/// are skipped without `python3`); TK-PY-7 reads the reports pytest 8.4,
/// nose2 0.16, tox 4.30 and nox 2026.4 wrote for the same small project
/// (`test/fixtures/reports/python/`, paths replaced).
///
/// Test IDs: TK-PY-1..9.
@TestOn('vm')
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

final _python = () {
  try {
    final r = Process.runSync(Platform.isWindows ? 'python' : 'python3', const [
      '--version',
    ]);
    return r.exitCode == 0;
  } on ProcessException {
    return false;
  }
}();

void main() {
  late Directory root;
  late String project;
  late FsFolder folder;

  setUp(() {
    root = Directory(
      Directory.systemTemp.createTempSync('tk_py_').resolveSymbolicLinksSync(),
    );
    project = p.join(root.path, 'pkg');
    Directory(project).createSync();
    folder = FsFolder(path: project);
  });
  tearDown(() => root.deleteSync(recursive: true));

  void write(String rel, String text) => File(p.join(project, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);

  List<RunFolder> python() => [
    PythonFolder(folder, projectFile: 'pyproject.toml'),
  ];

  CommandRunner runner() {
    final r = ProjectTestRunner.resolve(project, python());
    expect(
      r,
      isA<CommandRunner>(),
      reason: r is RunnerUnavailable ? r.reason : null,
    );
    return r as CommandRunner;
  }

  /// A small unittest project: two classes with a test of the same name, a
  /// failure, an error, a skip, an expected failure, a module that does not
  /// import, and a doctest in the code.
  void unittestProject() {
    write('calc.py', '''
def add(a, b):
    """Adds.

    >>> add(1, 2)
    3
    """
    return a + b
''');
    write('tests/__init__.py', '');
    write('tests/test_calc.py', '''
import unittest
from calc import add


class TestCalc(unittest.TestCase):
    def test_adds(self):
        self.assertEqual(add(1, 1), 2)

    def test_subtracts_wrongly(self):
        self.assertEqual(2 - 1, 0)

    def test_errors(self):
        raise RuntimeError("boom")

    @unittest.skip("not ready")
    def test_skipped(self):
        pass

    @unittest.expectedFailure
    def test_known_bug(self):
        self.assertEqual(1, 2)


class TestOther(unittest.TestCase):
    def test_adds(self):
        self.assertTrue(True)
''');
    write('tests/test_broken.py', 'import does_not_exist\n');
  }

  test('TK-PY-1: {python} is the project\'s own environment, else python3 '
      '[2026-11-18]', () {
    final plain = Platform.isWindows ? 'python' : 'python3';
    expect(projectPythonCommand(project), plain);
    void venv(String dir) {
      write(p.join(dir, 'pyvenv.cfg'), 'home = /usr/bin\n');
      write(
        Platform.isWindows
            ? p.join(dir, 'Scripts', 'python.exe')
            : p.join(dir, 'bin', 'python'),
        '',
      );
    }

    venv('env');
    expect(projectPythonCommand(project), p.join('env', 'bin', 'python'));
    venv('.venv');
    expect(projectPythonCommand(project), p.join('.venv', 'bin', 'python'));
    write('Pipfile.lock', '{}');
    expect(projectPythonCommand(project), 'pipenv run python');
    write('poetry.lock', '');
    expect(projectPythonCommand(project), 'poetry run python');
    write('uv.lock', '');
    expect(projectPythonCommand(project), 'uv run python');
  }, skip: Platform.isWindows ? 'POSIX venv layout' : false);

  test('TK-PY-2: pytest, nose2, tox and nox are picked from the project\'s '
      'files; a project without them runs unittest [2026-11-18]', () {
    expect(runner().origin, 'runner unittest, built-in');
    for (final (file, text) in [
      ('conftest.py', ''),
      ('pytest.ini', '[pytest]\n'),
      ('tests/conftest.py', ''),
      ('pyproject.toml', '[tool.pytest.ini_options]\naddopts = "-q"\n'),
      ('setup.cfg', '[tool:pytest]\n'),
      ('tox.ini', '[pytest]\n'),
      ('requirements-dev.txt', 'black\npytest>=8\n'),
    ]) {
      write(file, text);
      expect(runner().origin, 'runner pytest, built-in', reason: file);
      File(p.join(project, file)).deleteSync();
    }
    for (final (file, text, expected) in [
      ('nose2.cfg', '[unittest]\n', 'nose2'),
      ('requirements.txt', 'nose2\n', 'nose2'),
      ('tox.ini', '[testenv]\ncommands = pytest {posargs}\n', 'tox'),
      ('noxfile.py', 'session.run("pytest", *session.posargs)\n', 'nox'),
    ]) {
      write(file, text);
      expect(runner().origin, 'runner $expected, built-in', reason: file);
      File(p.join(project, file)).deleteSync();
    }
    // A requirements file that names pytest-cov only is no pytest project.
    write('requirements.txt', 'pytestcov-lookalike\n');
    expect(runner().origin, 'runner unittest, built-in');
  });

  group('the bundled unittest runner', () {
    setUp(unittestProject);

    test('TK-PY-3: a project without pytest records every test case: '
        'errors fail, an expected failure passes, a module that does not '
        'import fails [2026-11-18]', () async {
      final results = (await runner().run(projectPath: project))!;
      expect(results.run.results, {
        'tests.test_calc.TestCalc > test_adds': TestResult.ok,
        'tests.test_calc.TestOther > test_adds': TestResult.ok,
        'test_subtracts_wrongly': TestResult.fail,
        'test_errors': TestResult.fail,
        'test_skipped': TestResult.skip,
        'test_known_bug': TestResult.ok,
        'test_broken (failed to load)': TestResult.fail,
      });
      expect(
        File(p.join(project, 'testlog', 'testkit_unittest.py')).existsSync(),
        isTrue,
        reason: 'the bundled script is written to testlog/',
      );
    }, skip: _python ? false : 'no python3');

    test('TK-PY-4: --failed runs only the failed tests, selected by their '
        'qualified name [2026-11-18]', () async {
      final r = runner();
      await BaselineCommand.run(projectPath: project, runner: r);
      write('calc.py', 'def add(a, b):\n    return a + b\n');
      write(
        'tests/test_calc.py',
        File(p.join(project, 'tests', 'test_calc.py'))
            .readAsStringSync() // A different length: Python's bytecode cache keys on the source's
            // mtime and size, and both may be unchanged within one second.
            .replaceAll('(2 - 1, 0)', '(2 - 1, 1)  # fixed'),
      );
      await TestCommand.run(projectPath: project, runner: r, failedOnly: true);
      final tracking = TrackingFile.load(findLatestTrackingFile(project)!)!;
      final last = tracking.runs.last.results;
      expect(last['test_subtracts_wrongly'], TestResult.ok);
      expect(last['test_errors'], TestResult.fail);
      expect(
        last['tests.test_calc.TestCalc > test_adds'],
        TestResult.absent,
        reason: 'a passing test is not run again',
      );
    }, skip: _python ? false : 'no python3');

    test('TK-PY-5: unittest-doctest adds the doctests of the project\'s '
        'modules; a failing doctest fails [2026-11-18]', () async {
      write('pkg_mod/__init__.py', '');
      write('pkg_mod/maths.py', '''
def double(x):
    """
    >>> double(2)
    5
    """
    return 2 * x
''');
      write('buildkit.yaml', 'testkit:\n  runner: unittest-doctest\n');
      final results = (await runner().run(projectPath: project))!;
      expect(results.run.results['calc.add'], TestResult.ok);
      expect(results.run.results['pkg_mod.maths.double'], TestResult.fail);
      expect(results.run.results['test_adds'], isNull);
      expect(
        results.run.results['tests.test_calc.TestCalc > test_adds'],
        TestResult.ok,
      );
    }, skip: _python ? false : 'no python3');

    test('TK-PY-6: the project\'s virtual environment runs the tests '
        '[2026-11-18]', () async {
      final venv = Process.runSync('python3', [
        '-m',
        'venv',
        '--without-pip',
        p.join(project, '.venv'),
      ]);
      expect(venv.exitCode, 0, reason: '${venv.stderr}');
      write('tests/test_where.py', '''
import sys
import unittest


class TestWhere(unittest.TestCase):
    def test_prefix(self):
        with open("prefix.txt", "w") as f:
            f.write(sys.prefix)
''');
      final r = runner();
      await r.run(projectPath: project);
      expect(
        p.canonicalize(File(p.join(project, 'prefix.txt')).readAsStringSync()),
        p.canonicalize(p.join(project, '.venv')),
      );
    }, skip: _python && !Platform.isWindows ? false : 'no python3');
  });

  test('TK-PY-7: pytest, nose2, tox and nox record per-test results from '
      'their recorded JUnit reports [2026-11-18]', () async {
    String fixture(String name) => File(
      p.join('test', 'fixtures', 'reports', 'python', name),
    ).absolute.path;
    const common = {
      'test_subtracts_wrongly': TestResult.fail,
      'test_errors': TestResult.fail,
      'test_skipped': TestResult.skip,
      'tests.test_calc.TestCalc > test_adds': TestResult.ok,
      'tests.test_calc.TestOther > test_adds': TestResult.ok,
    };
    for (final (template, report, extra) in [
      (
        'pytest',
        'pytest_junit.xml',
        {
          'tests.test_broken': TestResult.fail,
          'calc.add': TestResult.ok,
          'test_known_bug': TestResult.skip,
        },
      ),
      (
        'tox',
        'tox_junit.xml',
        {
          'tests.test_broken': TestResult.fail,
          'test_known_bug': TestResult.skip,
        },
      ),
      (
        'nox',
        'nox_junit.xml',
        {
          'tests.test_broken': TestResult.fail,
          'test_known_bug': TestResult.skip,
        },
      ),
      (
        'nose2',
        'nose2_junit.xml',
        {'test_broken': TestResult.fail, 'test_known_bug': TestResult.skip},
      ),
    ]) {
      final t = builtInRunnerTemplates.firstWhere((t) => t.name == template);
      final results = (await CommandRunner(
        command: 'cp "${fixture(report)}" {report}',
        format: t.format,
        reportPath: t.reportPath,
        origin: 'test',
      ).run(projectPath: project))!;
      expect(results.run.results, {...common, ...extra}, reason: template);
    }
  });

  test('TK-PY-8: the Python name filters [2026-11-18]', () {
    List<String> args(String name, List<String> names) => builtInRunnerTemplates
        .firstWhere((t) => t.name == name)
        .filter!
        .argsFor(names);
    expect(args('pytest', ['test_a', 'test_b[1]']), ['-k', 'test_a or test_b']);
    expect(args('tox', ['test_a']), ['-k', 'test_a']);
    expect(args('unittest', ['tests.test_calc.TestCalc.test_adds']), [
      '-k',
      '*tests.test_calc.TestCalc.test_adds',
    ]);
    expect(args('nose2', ['tests.test_calc.TestCalc.test_adds']), [
      'tests.test_calc.TestCalc.test_adds',
    ]);
    // The qualified name comes from the entry's group.
    final unittest = CommandRunner.fromTemplate(
      builtInRunnerTemplates.firstWhere((t) => t.name == 'unittest'),
    );
    final entry = TestDescriptionParser.parse(
      'tests.test_calc.TestCalc > test_adds',
      groups: 'tests.test_calc.TestCalc',
    );
    expect(unittest.selectionName(entry), 'tests.test_calc.TestCalc.test_adds');
  });

  test('TK-PY-9: an unknown {script:...} stops the run with the reason; '
      'the jasmine template writes its bundled reporter module '
      '[2026-11-18]', () async {
    final unknown = CommandRunner(
      command: 'sh {script:nope}',
      format: ReportFormat.testkit,
      origin: 'test',
    );
    expect(await unknown.run(projectPath: project), isNull);
    final jasmine = builtInRunnerTemplates.firstWhere(
      (t) => t.name == 'jasmine',
    );
    expect(jasmine.command, contains('{script:jasmine-junit}'));
    await CommandRunner(
      command: jasmine.command.replaceAll('npx jasmine', 'echo'),
      format: jasmine.format,
      reportPath: jasmine.reportPath,
      origin: 'test',
    ).run(projectPath: project);
    expect(
      File(
        p.join(project, 'testlog', 'testkit_jasmine-junit.cjs'),
      ).readAsStringSync(),
      contains("require('jasmine-reporters').JUnitXmlReporter"),
    );
  });
}
