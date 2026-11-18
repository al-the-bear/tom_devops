/// The C and C++ runner templates: the build systems that run the tests
/// (Bazel, Meson, Ceedling, CTest with and without GoogleTest's own reports)
/// and, for a make project, its test programs by framework (GoogleTest,
/// Catch2, doctest, Boost.Test, CppUnit, CMocka, Check, Unity, libtap);
/// `binaries:` / `build:` / `env:`, `{report-dir}`, and the CppUnit, Check
/// and Unity readers.
///
/// TK-CC-2 and TK-CC-3 read the reports CTest (CMake 4.2), GoogleTest 1.17,
/// Catch2 3.8, doctest 2.4, Boost.Test 1.92, CppUnit 1.15, CMocka 1.1, Check
/// 0.15, Unity 2.6, Ceedling 0.31, Meson 1.12 and Bazel 8.4 wrote for small projects
/// (`test/fixtures/reports/cc/`, paths removed).
///
/// Test IDs: TK-CC-1..7.
@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:tom_build_base/tom_build_base_v2.dart';
import 'package:tom_test_kit/tom_test_kit.dart';

void main() {
  late Directory root;
  late String project;
  late FsFolder folder;

  setUp(() {
    root = Directory(
      Directory.systemTemp.createTempSync('tk_cc_').resolveSymbolicLinksSync(),
    );
    project = p.join(root.path, 'pkg');
    Directory(project).createSync();
    folder = FsFolder(path: project);
  });
  tearDown(() => root.deleteSync(recursive: true));

  void write(String rel, String text) => File(p.join(project, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);

  /// A test program: an executable that is no script (never run here).
  void program(String rel) {
    write(rel, '\x7fELF');
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['+x', p.join(project, rel)]);
    }
  }

  String fixture(String name) =>
      p.join('test', 'fixtures', 'reports', 'cc', name);

  RunnerTemplate template(String name) =>
      builtInRunnerTemplates.firstWhere((t) => t.name == name);

  String origin(List<RunFolder> natures) {
    final r = ProjectTestRunner.resolve(project, natures);
    expect(
      r,
      isA<CommandRunner>(),
      reason: r is RunnerUnavailable ? r.reason : null,
    );
    return (r as CommandRunner).origin;
  }

  List<RunFolder> cpp([NativeBuildSystem system = NativeBuildSystem.make]) => [
    CppFolder(folder, buildSystem: system, projectFile: 'Makefile'),
  ];

  /// Copies the fixture [from] (a file or folder) to [to] in the project.
  String copy(String from, String to) {
    final src = p.absolute(fixture(from));
    final q = Platform.isWindows ? '"' : "'";
    return FileSystemEntity.isDirectorySync(src)
        ? 'mkdir -p $q$to$q && cp -R $q$src/.$q $q$to$q'
        : 'mkdir -p $q${p.dirname(to)}$q && cp $q$src$q $q$to$q';
  }

  Future<Map<String, TestResult>> recorded(
    RunnerTemplate t,
    String command, {
    List<String>? binaries,
    Map<String, String>? env,
  }) async {
    final results = (await CommandRunner(
      command: command,
      format: t.format,
      reportPath: t.reportPath,
      binaries: binaries ?? t.binaries,
      env: env ?? t.env,
      origin: 'test',
    ).run(projectPath: project))!;
    return results.run.results;
  }

  test('TK-CC-1: each C / C++ template is picked from the project\'s '
      'files [2026-11-18]', () {
    write('src/a.cpp', 'int a() { return 1; }\n');
    write('MODULE.bazel', '');
    expect(origin(cpp(NativeBuildSystem.bazel)), 'runner bazel, built-in');
    File(p.join(project, 'MODULE.bazel')).deleteSync();

    write('meson.build', "project('m', 'cpp')\n");
    expect(origin(cpp(NativeBuildSystem.meson)), 'runner meson, built-in');
    File(p.join(project, 'meson.build')).deleteSync();

    write(
      'project.yml',
      ':plugins:\n  :enabled:\n    - report_tests_log_factory\n',
    );
    expect(origin(cpp()), 'runner ceedling, built-in');
    File(p.join(project, 'project.yml')).deleteSync();

    write('CMakeLists.txt', 'project(x)\nenable_testing()\n');
    expect(origin(cpp(NativeBuildSystem.cmake)), 'runner ctest, built-in');
    write('CMakeLists.txt', 'project(x)\ninclude(CTest)\n');
    expect(origin(cpp(NativeBuildSystem.cmake)), 'runner ctest, built-in');
    write(
      'tests/CMakeLists.txt',
      'target_link_libraries(t GTest::gtest_main)\n',
    );
    expect(
      origin(cpp(NativeBuildSystem.cmake)),
      'runner ctest-gtest, built-in',
    );
    // Without CTest, GoogleTest in CMake is no CTest project.
    write('CMakeLists.txt', 'project(x)\nadd_subdirectory(tests)\n');
    expect(
      ProjectTestRunner.resolve(project, cpp(NativeBuildSystem.cmake)),
      isA<RunnerUnavailable>(),
    );
    File(p.join(project, 'CMakeLists.txt')).deleteSync();
    File(p.join(project, 'tests/CMakeLists.txt')).deleteSync();

    write('Makefile', 'all:\n');
    for (final (include, expected) in [
      ('<gtest/gtest.h>', 'gtest'),
      ('<catch2/catch_test_macros.hpp>', 'catch2'),
      ('"catch.hpp"', 'catch2'),
      ('"doctest.h"', 'doctest'),
      ('<doctest/doctest.h>', 'doctest'),
      ('<boost/test/unit_test.hpp>', 'boost-test'),
      ('<cppunit/TestRunner.h>', 'cppunit'),
      ('<cmocka.h>', 'cmocka'),
      ('<check.h>', 'check'),
      ('"unity.h"', 'unity'),
      ('"tap.h"', 'libtap'),
    ]) {
      write('tests/t.cpp', '#include $include\n');
      expect(origin(cpp()), 'runner $expected, built-in', reason: include);
    }
    // A header that only mentions a framework is no include of it.
    write('tests/t.cpp', '// see gtest/gtest.h\n');
    expect(ProjectTestRunner.resolve(project, cpp()), isA<RunnerUnavailable>());

    // A project names its test programs, their build and environment.
    write(
      'buildkit.yaml',
      'testkit:\n  runner: gtest\n  binaries: out/unit_tests\n'
          '  build: cmake --build build\n  env: {GTEST_COLOR: "no"}\n',
    );
    final own = ProjectTestRunner.resolve(project, cpp()) as CommandRunner;
    expect(own.origin, 'runner gtest, built-in, picked in buildkit.yaml');
    expect(own.binaries, ['out/unit_tests']);
    expect(own.build, 'cmake --build build');
    expect(own.env, {'GTEST_COLOR': 'no'});
    expect(own.filter, isNotNull, reason: 'kept from gtest');
  });

  test(
    'TK-CC-2: Bazel, Meson, Ceedling, CTest and CTest with GoogleTest\'s '
    'reports '
    'record per-test results from their recorded reports [2026-11-18]',
    () async {
      expect(
        await recorded(template('bazel'), copy('bazel', 'bazel-testlogs')),
        {
          'Adds': TestResult.ok,
          'SubtractsWrongly': TestResult.fail,
          'Later': TestResult.skip,
          'Positive/0': TestResult.ok,
          'Positive/1': TestResult.ok,
          'plain_test': TestResult.ok,
        },
      );
      expect(
        await recorded(
          template('ceedling'),
          copy('ceedling_report.xml', 'build/artifacts/test/report.xml'),
        ),
        {
          'test_adds': TestResult.ok,
          'test_subtracts_wrongly': TestResult.fail,
          'test_later': TestResult.skip,
        },
      );
      // gtest and TAP tests per test case, the others per test.
      expect(
        await recorded(
          template('meson'),
          copy('meson_testlog.junit.xml', 'build/meson-logs/testlog.junit.xml'),
        ),
        {
          'Adds': TestResult.ok,
          'SubtractsWrongly': TestResult.fail,
          'Later': TestResult.skip,
          'Positive/0': TestResult.ok,
          'Positive/1': TestResult.ok,
          '1 - adds': TestResult.ok,
          '2 - subtracts wrongly': TestResult.fail,
          '3': TestResult.skip,
          'ms:plain': TestResult.ok,
        },
      );
      // catch_discover_tests and doctest_discover_tests: one CTest test per
      // test case; the name is not repeated as a group.
      final ctest = await CommandRunner(
        command: copy(
          'ctest_junit.xml',
          'out.xml',
        ).replaceAll("'out.xml'", '{report}'),
        format: template('ctest').format,
        origin: 'test',
      ).run(projectPath: project);
      expect(ctest!.run.results, {
        'adds': TestResult.ok,
        'subtracts wrongly': TestResult.fail,
        'sections': TestResult.ok,
        'fails on purpose': TestResult.fail,
        'plain_test': TestResult.ok,
      });
      expect(ctest.entries.map((e) => e.groups).toSet(), {
        null,
      }, reason: 'no group: CTest repeats the name as classname');
      expect(
        await recorded(
          template('ctest-gtest'),
          copy('ctest_gtest', 'testlog/reports'),
        ),
        // math_test runs as one CTest test, str_test's cases one by one
        // (gtest_discover_tests): a report each.
        {
          'Math > Adds': TestResult.ok,
          'SubtractsWrongly': TestResult.fail,
          'Later': TestResult.skip,
          'Positive/0': TestResult.ok,
          'Positive/1': TestResult.ok,
          'Str > Adds': TestResult.ok,
          'Empty': TestResult.ok,
        },
      );
    },
  );

  test('TK-CC-3: the test programs of GoogleTest, Catch2, doctest, '
      'Boost.Test, CppUnit, CMocka, Check, Unity and libtap record per-test '
      'results [2026-11-18]', () async {
    program('build/math_test');
    final q = Platform.isWindows ? '"' : "'";
    String toReport(String file) =>
        'cp $q${p.absolute(fixture(file))}$q {report}';
    String toOutput(String file) => 'cat $q${p.absolute(fixture(file))}$q';

    expect(await recorded(template('gtest'), toReport('gtest.xml')), {
      'Adds': TestResult.ok,
      'SubtractsWrongly': TestResult.fail,
      'Later': TestResult.skip,
      'Positive/0': TestResult.ok,
      'Positive/1': TestResult.ok,
    });
    expect(await recorded(template('catch2'), toReport('catch2.xml')), {
      'adds': TestResult.ok,
      'subtracts wrongly': TestResult.fail,
      'sections': TestResult.ok,
      'sections/first': TestResult.ok,
      'sections/second': TestResult.ok,
    });
    expect(await recorded(template('doctest'), toReport('doctest.xml')), {
      'adds': TestResult.ok,
      'fails on purpose': TestResult.fail,
    });
    expect(await recorded(template('boost-test'), toReport('boost.xml')), {
      'math > adds': TestResult.ok,
      'subtracts_wrongly': TestResult.fail,
      'later': TestResult.skip,
      'words > adds': TestResult.ok,
    });
    const cppunit = {
      'adds': TestResult.ok,
      'subtractsWrongly': TestResult.fail,
      'throws': TestResult.fail,
    };
    // To $TESTKIT_REPORT, or on the output.
    expect(
      await recorded(template('cppunit'), toReport('cppunit.xml')),
      cppunit,
    );
    expect(
      await recorded(template('cppunit'), toOutput('cppunit_stdout.txt')),
      cppunit,
    );
    // CMocka writes a file per group to CMOCKA_XML_FILE (with %g).
    expect(
      await recorded(
        template('cmocka'),
        'cp $q${p.absolute(fixture('cmocka'))}$q/*.xml {report-dir}/',
      ),
      {
        'adds': TestResult.ok,
        'subtracts_wrongly': TestResult.fail,
        'later': TestResult.skip,
        'words_adds': TestResult.ok,
      },
    );
    expect(template('cmocka').env, {
      'CMOCKA_MESSAGE_OUTPUT': 'xml',
      'CMOCKA_XML_FILE': '{report-dir}/{binary-name}-%g.xml',
    });
    // Check writes to CK_XML_LOG_FILE_NAME, here {report}.
    expect(
      await recorded(
        template('check'),
        'cp $q${p.absolute(fixture('check.xml'))}$q "\$CK_XML_LOG_FILE_NAME"',
      ),
      {
        'adds': TestResult.ok,
        'subtracts_wrongly': TestResult.fail,
        'crashes': TestResult.fail,
      },
    );
    expect(await recorded(template('unity'), toOutput('unity.txt')), {
      'test_adds': TestResult.ok,
      'test_subtracts_wrongly': TestResult.fail,
      'test_later': TestResult.skip,
    });
    // libtap: TAP on the output, grouped by the program.
    final tap = await CommandRunner(
      command: "printf 'ok 1 - adds\\nnot ok 2 - subtracts wrongly\\n1..2\\n'",
      format: template('libtap').format,
      binaries: template('libtap').binaries,
      origin: 'test',
    ).run(projectPath: project);
    expect(tap!.run.results, {
      'adds': TestResult.ok,
      'subtracts wrongly': TestResult.fail,
    });
    expect(tap.entries.map((e) => e.groups).toSet(), {'math_test'});
  }, testOn: '!windows');

  test('TK-CC-4: binaries: runs the command once per test program, with '
      '{binary}, {binary-name}, its own {report} and env:; build: comes '
      'first [2026-11-18]', () async {
    program('build/a_test');
    program('tests/b_test');
    program('testlog/old_test'); // testkit's own folder
    write('build/c_test.c', 'int main() {}\n'); // not executable
    write('run_tests', '#!/bin/sh\n'); // a script
    if (!Platform.isWindows) {
      Process.runSync('chmod', ['+x', p.join(project, 'run_tests')]);
    }
    final runner = CommandRunner(
      command:
          "printf '{\"test\": \"%s %s\", \"result\": \"ok\"}\\n' {binary} "
          '"\$WHO" > {report}',
      format: ReportFormat.testkit,
      binaries: const ['**/*[Tt]est*', 'run_tests'],
      build: 'echo built > built.txt',
      env: const {'WHO': '{binary-name}'},
      origin: 'test',
    );
    final results = (await runner.run(projectPath: project))!;
    expect(results.run.results.keys.toSet(), {
      'build/a_test a_test',
      'tests/b_test b_test',
    });
    expect(File(p.join(project, 'built.txt')).existsSync(), isTrue);
    expect(
      Directory(
        p.join(project, 'testlog', 'reports'),
      ).listSync().map((f) => p.basename(f.path)).toSet(),
      {'build_a_test.jsonl', 'tests_b_test.jsonl'},
    );

    // A failing build runs no test.
    final broken = CommandRunner(
      command: 'echo never',
      format: ReportFormat.testkit,
      binaries: const ['**/*[Tt]est*'],
      build: 'exit 3',
      origin: 'test',
    );
    expect(await broken.run(projectPath: project), isNull);

    // No test program: the run says what it looked for.
    final none = await CommandRunner(
      command: '{binary}',
      format: ReportFormat.unity,
      binaries: const ['nothing/*'],
      origin: 'test',
    ).run(projectPath: project);
    expect(none!.run.results, isEmpty);
    expect(none.runProblem, contains('no test program matches nothing/*'));

    // {binary} without binaries: is refused.
    expect(
      await CommandRunner(
        command: '{binary}',
        format: ReportFormat.unity,
        origin: 'test',
      ).run(projectPath: project),
      isNull,
    );
  }, testOn: '!windows');

  test('TK-CC-5: the CppUnit, Check and Unity readers [2026-11-18]', () {
    Map<String, TestResult> read(void Function(ResultCollector) parse) {
      final c = ResultCollector();
      parse(c);
      return c
          .build(rawOutput: const [], rawOutputName: 'x', exitCode: 1)
          .run
          .results;
    }

    // CppUnit's report on the output, with the program's own lines around
    // it; the fixture is the group.
    expect(
      read(
        (c) => parseCppunitXml(
          'Running 2 tests\n<?xml version="1.0" ?>\n<TestRun>'
          '<FailedTests><FailedTest id="1"><Name>A::x</Name></FailedTest>'
          '</FailedTests><SuccessfulTests><Test id="2"><Name>B::x</Name>'
          '</Test></SuccessfulTests></TestRun>\nbye\n',
          c,
        ),
      ),
      {'A > x': TestResult.fail, 'B > x': TestResult.ok},
    );
    expect(
      () => parseCppunitXml('no report', ResultCollector()),
      throwsFormatException,
    );
    expect(
      read(
        (c) => parseCheckXml(File(fixture('check.xml')).readAsStringSync(), c),
      ),
      {
        'adds': TestResult.ok,
        'subtracts_wrongly': TestResult.fail,
        'crashes': TestResult.fail,
      },
    );
    expect(
      () => parseCheckXml('<TestRun/>', ResultCollector()),
      throwsFormatException,
    );
    expect(
      read(
        (c) => parseUnityOutput([
          'a.c:3:test_x:PASS',
          'b.c:9:test_x:FAIL: Expected 1 Was 2',
          'c.c:4:test_y:IGNORE',
          '3 Tests 1 Failures 1 Ignored',
        ], c),
      ),
      {
        'a.c > test_x': TestResult.ok,
        'b.c > test_x': TestResult.fail,
        'test_y': TestResult.skip,
      },
    );
  });

  test('TK-CC-6: the name filters: CTest -R, GoogleTest --gtest_filter, '
      'Catch2 test cases, doctest --test-case; none for the others '
      '[2026-11-18]', () {
    List<String> args(String name, List<String> names) =>
        template(name).filter!.argsFor(names);
    expect(args('ctest', ['adds', 'subtracts wrongly']), [
      '-R',
      r'^(adds|subtracts wrongly)$',
    ]);
    final gtest = CommandRunner.fromTemplate(template('gtest'));
    String gtestName(String name, String group) =>
        gtest.selectionName(TestDescriptionParser.parse(name, groups: group));
    expect(
      args('gtest', [
        gtestName('SubtractsWrongly', 'Math'),
        gtestName('Positive/1', 'Small/Param'),
      ]),
      ['--gtest_filter=Math.SubtractsWrongly:Small/Param.Positive/1'],
    );
    // A section runs its test case.
    expect(
      args('catch2', [
        'subtracts wrongly',
        'sections/first',
        'sections/second',
      ]),
      ['subtracts wrongly,sections'],
    );
    expect(args('doctest', ['adds', 'fails on purpose']), [
      '--test-case=adds,fails on purpose',
    ]);
    for (final name in [
      'bazel',
      'meson',
      'ceedling',
      'ctest-gtest',
      'boost-test',
      'cppunit',
      'cmocka',
      'check',
      'unity',
      'libtap',
    ]) {
      expect(template(name).filter, isNull, reason: name);
    }
  });

  test('TK-CC-7: {report-dir} is an empty folder for the run\'s reports '
      '[2026-11-18]', () async {
    write(
      'testlog/reports/stale.xml',
      '<testsuites><testcase name="old"/></testsuites>',
    );
    final results = (await CommandRunner(
      command:
          "printf '<testsuites><testcase name=\"new\"/></testsuites>' > "
          '{report-dir}/a.xml',
      format: ReportFormat.junit,
      reportPath: 'testlog/reports/*.xml',
      origin: 'test',
    ).run(projectPath: project))!;
    expect(results.run.results, {'new': TestResult.ok});
  }, testOn: '!windows');
}
