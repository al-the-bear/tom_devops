/// Helper scripts testkit hands a runner command: `{script:<name>}` in a
/// command is replaced by the path of the script, written to `testlog/`
/// before the command runs. Embedded here so a compiled testkit carries them.
library;

/// A bundled script: its file extension and its text.
typedef BundledScript = ({String extension, String text});

/// The scripts by name.
const bundledScripts = <String, BundledScript>{
  // testkit's unittest runner: discovers and runs a project's unittest tests
  // and writes testkit's line protocol (Python 3.7+, standard library only).
  'unittest': (extension: 'py', text: _unittestRunner),
  // A Gradle init script: every test task records its results without
  // stopping the build, testkitTests runs every test task, and
  // -Ptestkit.tests=<a>|<b> selects tests in every one of them.
  'gradle-testkit': (extension: 'gradle', text: _gradleInit),
  // A cargo-nextest tool config: the `testkit` profile (based on the
  // project's default profile) writes a JUnit report to
  // target/nextest/testkit/junit.xml.
  'nextest-testkit': (extension: 'toml', text: _nextestToolConfig),
  // jasmine's --reporter wants a module exporting a reporter constructor;
  // jasmine-reporters exports an object of them.
  'jasmine-junit': (
    extension: 'cjs',
    text: "module.exports = require('jasmine-reporters').JUnitXmlReporter;\n",
  ),
};

const _unittestRunner =
    r'''# testkit's unittest runner: discovers and runs a project's unittest tests and
# writes testkit's line protocol, one JSON object per test case, to the file
# named first on the command line. Standard library only (Python 3.7+).
#
# Usage: python testkit_unittest.py REPORT [-k PATTERN]... [-s START] [-p PATTERN]
#
#   -k PATTERN   run only the tests matching PATTERN (as `python -m unittest
#                -k`: a substring, or an fnmatch pattern with `*`), repeatable
#   -s START     the discovery start directory (default: the project, `.`)
#   -p PATTERN   the test file pattern (default: test*.py)
#   --doctest    also run the doctests of every module discovery imports
#
# A test module that does not import is reported as a failed test named
# `<module> (failed to load)`, so the run fails instead of losing its tests.
import argparse
import doctest
import fnmatch
import importlib
import json
import os
import sys
import unittest


def _parts(test):
    """(name, group, suite) of a test: method, module.Class, module."""
    test_id = test.id()
    if isinstance(test, _ImportFailed):
        return test_id, None, None
    if isinstance(test, doctest.DocTestCase):
        # The name is qualified already (`calc.add`): no group.
        return test_id, None, test_id.rsplit(".", 1)[0]
    pieces = test_id.split(".")
    if len(pieces) >= 3:
        return pieces[-1], ".".join(pieces[:-1]), ".".join(pieces[:-2])
    return test_id, None, None


class _Result(unittest.TextTestResult):
    def __init__(self, report, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._report = report

    def _write(self, test, result):
        name, group, suite = _parts(test)
        if type(test).__name__ == "_FailedTest":
            # A module that did not import: unittest names it after the module.
            name = test_id_tail(test.id()) + " (failed to load)"
            group = None
            suite = None
        line = {"test": name, "result": result}
        if group:
            line["group"] = group
        if suite:
            line["suite"] = suite
        self._report.write(json.dumps(line) + "\n")
        self._report.flush()

    def addSuccess(self, test):
        super().addSuccess(test)
        self._write(test, "ok")

    def addFailure(self, test, err):
        super().addFailure(test, err)
        self._write(test, "fail")

    def addError(self, test, err):
        super().addError(test, err)
        self._write(test, "fail")

    def addSkip(self, test, reason):
        super().addSkip(test, reason)
        self._write(test, "skip")

    def addExpectedFailure(self, test, err):
        super().addExpectedFailure(test, err)
        self._write(test, "ok")

    def addUnexpectedSuccess(self, test):
        super().addUnexpectedSuccess(test)
        self._write(test, "fail")


def test_id_tail(test_id):
    return test_id.rsplit(".", 1)[-1]


_SKIP_DIRS = {"node_modules", "__pycache__", "build", "dist", "site-packages"}


def _project_modules(start, test_pattern):
    """The importable modules under [start]: top-level files, and files in
    packages (folders with __init__.py), outside hidden folders and
    virtual environments."""
    for root, dirs, files in os.walk(start):
        rel = os.path.relpath(root, start)
        parts = [] if rel == "." else rel.split(os.sep)
        dirs[:] = sorted(
            d for d in dirs
            if not d.startswith(".") and d not in _SKIP_DIRS
            and not os.path.exists(os.path.join(root, d, "pyvenv.cfg"))
        )
        if parts and not os.path.exists(os.path.join(root, "__init__.py")):
            dirs[:] = []
            continue
        for name in sorted(files):
            if (not name.endswith(".py") or name == "setup.py"
                    or fnmatch.fnmatch(name, test_pattern)):
                continue  # test modules are discovery's
            stem = name[:-3]
            yield ".".join(parts + ([] if stem == "__init__" else [stem]))


def _doctests(start, test_pattern, into, patterns):
    """Adds the doctests of every module of the project; a module that does
    not import is a failed test named `<module> (doctests failed to load)`."""
    for name in _project_modules(start, test_pattern):
        if not name:
            continue
        try:
            module = importlib.import_module(name)
        except Exception as error:  # noqa: BLE001 - any import failure
            into.addTest(_ImportFailed(name, error))
            continue
        try:
            tests = doctest.DocTestSuite(module)
        except ValueError:
            continue  # a module without doctests
        for test in _flatten(tests):
            if not patterns or any(
                fnmatch.fnmatchcase(test.id(), p) for p in patterns
            ):
                into.addTest(test)


class _ImportFailed(unittest.TestCase):
    def __init__(self, module, error):
        super().__init__("runTest")
        self._module = module
        self._error = error

    def id(self):
        return self._module + " (doctests failed to load)"

    def runTest(self):
        raise self._error


def _flatten(suite):
    for test in suite:
        if isinstance(test, unittest.TestSuite):
            yield from _flatten(test)
        else:
            yield test


def main(argv):
    parser = argparse.ArgumentParser(prog="testkit_unittest")
    parser.add_argument("report")
    parser.add_argument("-k", dest="patterns", action="append", default=None)
    parser.add_argument("-s", dest="start", default=".")
    parser.add_argument("-p", dest="pattern", default="test*.py")
    parser.add_argument("--doctest", action="store_true")
    args = parser.parse_args(argv)

    sys.path.insert(0, ".")
    loader = unittest.TestLoader()
    if args.patterns:
        loader.testNamePatterns = [
            p if "*" in p else "*%s*" % p for p in args.patterns
        ]
    suite = loader.discover(args.start, pattern=args.pattern)
    if args.doctest:
        docs = unittest.TestSuite()
        _doctests(args.start, args.pattern, docs, loader.testNamePatterns)
        suite.addTests(docs)

    with open(args.report, "a", encoding="utf-8") as report:
        runner = unittest.TextTestRunner(
            verbosity=2,
            resultclass=lambda *a, **k: _Result(report, *a, **k),
        )
        result = runner.run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
''';

const _gradleInit =
    r'''// testkit: every test task records its results without stopping the build,
// testkitTests runs every test task (test, integrationTest, ...), and
// -Ptestkit.tests=<a>|<b> runs only those tests (Gradle's --tests patterns;
// a name with a space selects its class), a project without a match being no
// error.
allprojects {
    def selected = findProperty('testkit.tests')
    tasks.withType(Test).configureEach {
        ignoreFailures = true
        filter.failOnNoMatchingTests = false
        if (selected) {
            selected.toString().split('\\|').each { name ->
                // A name with a space is no method name (a kotest test, a
                // JUnit @DisplayName), and Gradle's filter cannot match it:
                // its class runs.
                def dot = name.lastIndexOf('.')
                filter.includeTestsMatching(
                    name.contains(' ') && dot > 0 ? name.substring(0, dot) : name)
            }
        }
    }
    tasks.register('testkitTests') {
        dependsOn(tasks.withType(Test))
    }
}
''';

const _nextestToolConfig = '''
[profile.testkit]
fail-fast = false

[profile.testkit.junit]
path = "junit.xml"
''';
