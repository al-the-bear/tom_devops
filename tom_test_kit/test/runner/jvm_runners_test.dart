/// The JVM runner templates: Maven (a reactor's surefire and failsafe
/// reports), Gradle (every subproject's test tasks through testkit's init
/// script, Java and Kotlin), sbt (Scala), TestNG's own report, and the JUnit
/// Platform Console Standalone for a project javac builds without a build
/// tool; `{gradle}` is the nearest Gradle wrapper, else `gradle`.
///
/// TK-JVM-3 reads the reports Maven 3.9 (surefire / failsafe 3.5, JUnit 5,
/// two modules), Gradle 9.1 (JUnit 5 and kotest, two subprojects with `test`
/// and `integrationTest`), sbt 2.1 (Scala 3, MUnit) and the JUnit console 1.11
/// wrote (`test/fixtures/reports/jvm/`, paths and properties removed); TK-JVM-4
/// the `testng-results.xml` TestNG 7.10 wrote under Maven and run plain.
///
/// Test IDs: TK-JVM-1..6.
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
      Directory.systemTemp.createTempSync('tk_jvm_').resolveSymbolicLinksSync(),
    );
    project = p.join(root.path, 'pkg');
    Directory(project).createSync();
    folder = FsFolder(path: project);
  });
  tearDown(() => root.deleteSync(recursive: true));

  void write(String rel, String text) => File(p.join(project, rel))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(text);

  void delete(String rel) => File(p.join(project, rel)).deleteSync();

  String fixture(String name) =>
      p.join('test', 'fixtures', 'reports', 'jvm', name);

  String origin(List<RunFolder> natures) {
    final r = ProjectTestRunner.resolve(project, natures);
    expect(
      r,
      isA<CommandRunner>(),
      reason: r is RunnerUnavailable ? r.reason : null,
    );
    return (r as CommandRunner).origin;
  }

  List<RunFolder> maven() => [
    JavaFolder(folder, buildTool: JavaBuildTool.maven, projectFile: 'pom.xml'),
  ];
  List<RunFolder> gradle() => [
    JavaFolder(
      folder,
      buildTool: JavaBuildTool.gradle,
      projectFile: 'build.gradle',
    ),
  ];
  List<RunFolder> scala() => [ScalaFolder(folder)];

  RunnerTemplate template(String name) =>
      builtInRunnerTemplates.firstWhere((t) => t.name == name);

  test('TK-JVM-1: each JVM template is picked from the project\'s files '
      '[2026-11-18]', () {
    write(
      'pom.xml',
      '<project><modules><module>a</module></modules></project>',
    );
    expect(origin(maven()), 'runner maven, built-in');
    // failsafe in the parent or in a module's pom runs `mvn verify`.
    write('a/pom.xml', '<plugin>maven-failsafe-plugin</plugin>');
    expect(origin(maven()), 'runner maven-verify, built-in');
    delete('a/pom.xml');
    write('pom.xml', '<artifactId>maven-failsafe-plugin</artifactId>');
    expect(origin(maven()), 'runner maven-verify, built-in');
    delete('pom.xml');

    for (final file in [
      'build.gradle',
      'build.gradle.kts',
      'settings.gradle',
      'settings.gradle.kts',
    ]) {
      write(file, '');
      expect(origin(gradle()), 'runner gradle, built-in', reason: file);
      delete(file);
    }

    write('build.sbt', 'scalaVersion := "3.3.6"\n');
    expect(origin(scala()), 'runner sbt, built-in');
    write('project/build.properties', 'sbt.version=1.11.7\n');
    expect(origin(scala()), 'runner sbt, built-in');
    write('project/build.properties', 'sbt.version = 2.1.0\n');
    expect(origin(scala()), 'runner sbt2, built-in');
    expect(template('sbt2').command, 'sbt -batch testFull');

    // A project javac builds: the jar in lib/ picks the runner.
    write('pom.xml', '<project/>');
    write('lib/junit-platform-console-standalone-1.11.4.jar', '');
    expect(origin(maven()), 'runner junit-console, built-in');
    write('lib/testng-7.10.2.jar', '');
    write('testng.xml', '<suite name="all"><test name="t"/></suite>');
    expect(origin(maven()), 'runner junit-console, built-in');
    delete('lib/junit-platform-console-standalone-1.11.4.jar');
    expect(origin(maven()), 'runner testng, built-in');
    // Without a suite file TestNG has nothing to run.
    delete('testng.xml');
    expect(origin(maven()), 'runner maven, built-in');
  });

  test('TK-JVM-2: {gradle} is the nearest Gradle wrapper, else gradle '
      '[2026-11-18]', () {
    final sub = p.join(project, 'core');
    Directory(sub).createSync();
    expect(projectGradleCommand(sub), 'gradle');
    write('gradlew', '');
    write('gradlew.bat', '');
    final wrapper = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
    expect(
      projectGradleCommand(project),
      Platform.isWindows ? wrapper : './$wrapper',
    );
    expect(projectGradleCommand(sub), p.join('..', wrapper));

    write('build.gradle', '');
    final r = ProjectTestRunner.resolve(project, gradle()) as CommandRunner;
    expect(
      r.command,
      '${Platform.isWindows ? wrapper : './$wrapper'} testkitTests '
      '--init-script {script:gradle-testkit}',
    );
  });

  test(
    'TK-JVM-3: Maven, Gradle, sbt and the JUnit console record per-test '
    'results from every report of a multi-module project [2026-11-18]',
    () async {
      Future<Map<String, TestResult>> recorded(
        String name,
        String fixtureDir, {
        String into = '.',
      }) async {
        final t = template(name);
        final src = Directory(fixture(fixtureDir)).absolute.path;
        final results = (await CommandRunner(
          command: 'mkdir -p $into && cp -R "$src/." $into',
          format: t.format,
          reportPath: t.reportPath,
          origin: 'test',
        ).run(projectPath: project))!;
        return results.run.results;
      }

      const surefire = {
        // Module a: a parametrized test, a skip, a failure, a nested class.
        'adds': TestResult.ok,
        'subtractsWrongly': TestResult.fail,
        'positive(int)[1]': TestResult.ok,
        'positive(int)[2]': TestResult.ok,
        'skipped': TestResult.skip,
        'multiplies': TestResult.ok,
        // Module b.
        'failsOnPurpose': TestResult.fail,
        'sizes': TestResult.ok,
      };
      expect(await recorded('maven', 'maven'), surefire);
      // failsafe's integration tests beside surefire's.
      expect(await recorded('maven-verify', 'maven'), {
        ...surefire,
        'stores': TestResult.ok,
      });
      expect(await recorded('gradle', 'gradle'), {
        // core: test and integrationTest.
        'adds()': TestResult.ok,
        'subtractsWrongly()': TestResult.fail,
        'skipped()': TestResult.skip,
        'stores()': TestResult.ok,
        // app: kotest.
        'length is counted': TestResult.ok,
        'upper case is wrong': TestResult.fail,
        'ignored one': TestResult.skip,
      });
      expect(await recorded('sbt', 'sbt'), {
        'adds': TestResult.ok,
        'subtracts wrongly': TestResult.fail,
        'not ready': TestResult.skip,
      });
      expect(
        await recorded(
          'junit-console',
          'console',
          into: 'testlog/junit-platform',
        ),
        {
          'adds()': TestResult.ok,
          'addsWrongly()': TestResult.fail,
          'later()': TestResult.skip,
        },
      );
    },
  );

  test('TK-JVM-4: TestNG\'s testng-results.xml: one entry per test method, '
      'configuration methods left out, data-provider runs numbered '
      '[2026-11-18]', () async {
    final t = template('testng');
    expect(t.format, ReportFormat.testng);
    for (final file in [
      'maven_testng-results.xml',
      'plain_testng-results.xml',
    ]) {
      final src = File(fixture(p.join('testng', file))).absolute.path;
      final results = (await CommandRunner(
        command: 'mkdir -p testlog/testng && cp "$src" ${t.reportPath}',
        format: t.format,
        reportPath: t.reportPath,
        origin: 'test',
      ).run(projectPath: project))!;
      expect(results.run.results, {
        'failsOnPurpose': TestResult.fail,
        'sizes': TestResult.ok,
      }, reason: file);
    }

    final collector = ResultCollector();
    parseTestngResults('''
<testng-results>
  <suite name="s"><test name="t">
    <class name="demo.DataTest">
      <test-method status="PASS" name="setUp" is-config="true"/>
      <test-method status="PASS" name="square"/>
      <test-method status="FAIL" name="square"/>
      <test-method status="SKIP" name="later"/>
    </class>
  </test></suite>
</testng-results>
''', collector);
    final run = collector
        .build(rawOutput: const [], rawOutputName: 'x', exitCode: 1)
        .run;
    expect(run.results, {
      'square[0]': TestResult.ok,
      'square[1]': TestResult.fail,
      'later': TestResult.skip,
    });
    expect(
      () => parseTestngResults('<testsuite/>', ResultCollector()),
      throwsFormatException,
    );
  });

  test('TK-JVM-5: the Maven and Gradle name filters [2026-11-18]', () {
    String name(String template, String test, String group) =>
        CommandRunner.fromTemplate(
          builtInRunnerTemplates.firstWhere((t) => t.name == template),
        ).selectionName(TestDescriptionParser.parse(test, groups: group));
    // A parametrized test runs by its method: the name is cut at `(`.
    expect(
      template('maven').filter!.argsFor([
        name('maven', 'positive(int)[1]', 'demo.MathTest'),
        name('maven', 'positive(int)[2]', 'demo.MathTest'),
      ]),
      [
        '-Dtest=demo.MathTest#positive',
        '-Dsurefire.failIfNoSpecifiedTests=false',
      ],
    );
    expect(
      template('gradle').filter!.argsFor([
        name('gradle', 'subtractsWrongly()', 'demo.MathTest'),
      ]),
      ['-Ptestkit.tests=demo.MathTest.subtractsWrongly'],
    );
    expect(
      template(
        'maven',
      ).filter!.argsFor(['demo.MathTest#adds', 'demo.ListTest#sizes']),
      [
        '-Dtest=demo.MathTest#adds,demo.ListTest#sizes',
        '-Dsurefire.failIfNoSpecifiedTests=false',
      ],
    );
    expect(template('maven-verify').filter!.argsFor(['demo.StoreIT#stores']), [
      '-Dtest=demo.StoreIT#stores',
      '-Dit.test=demo.StoreIT#stores',
      '-Dsurefire.failIfNoSpecifiedTests=false',
      '-Dfailsafe.failIfNoSpecifiedTests=false',
    ]);
    expect(
      template('gradle').filter!.argsFor([
        'demo.MathTest.adds',
        'demo.StringSpecTest.length is counted',
      ]),
      [
        '-Ptestkit.tests=demo.MathTest.adds|demo.StringSpecTest.length is counted',
      ],
    );
  });

  test('TK-JVM-6: the gradle template writes its bundled init script, which '
      'runs every Test task without failing the build [2026-11-18]', () async {
    final t = template('gradle');
    await CommandRunner(
      command: t.command.replaceAll('{gradle}', 'echo'),
      format: t.format,
      reportPath: t.reportPath,
      origin: 'test',
    ).run(projectPath: project);
    final script = File(
      p.join(project, 'testlog', 'testkit_gradle-testkit.gradle'),
    );
    expect(script.existsSync(), isTrue);
    expect(
      script.readAsStringSync(),
      allOf(
        contains('ignoreFailures = true'),
        contains('failOnNoMatchingTests = false'),
        contains('testkit.tests'),
        contains('testkitTests'),
      ),
    );
  });
}
