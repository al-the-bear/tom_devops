## 1.1.1

- **A run that measured nothing is no longer a green run** (scd7_aicx).
  `dart test` reports a test file it cannot load — an import that does not
  resolve, a compile error — as a pseudo-test `loading <file>` with result
  `error`, and exits 1, the same code as a run whose tests merely failed.
  The parser discarded those events, so a package whose every test file failed
  to load produced `Tests: 0 (0 passed, 0 failed)`, `:baseline ok`, exit 0 and
  an empty baseline CSV that the next run then diffed against. A file that
  failed to load alongside others vanished the same way.
  - `DartTestParser.parseJsonOutput` records each failed load as a
    `LoadFailure` (file and error text); `DartTestResults` carries it with the
    runner's `exitCode` and exposes `runProblem`, non-null for a run in which
    no test ran or a file failed to load.
  - `:baseline` writes no CSV for such a run, prints why and fails.
  - `:test` records no column for a run in which no test ran; for a partial
    load failure it records the tests that ran, then fails naming the file.
  - A runner that exits before reporting results (a dependency that does not
    resolve, exit 65; no test selected, exit 79) is reported with its exit code
    and the text it printed on stdout as well as stderr, once per line —
    previously only stderr, where exit 79 prints nothing.
  - Failing tests remain results: they are recorded and do not change the exit
    code.

## 1.1.0

- Add Flutter-package support: `:baseline` / `:test` now detect a Flutter
  package (Flutter SDK dependency in `pubspec.yaml`) and run
  `flutter test --reporter json` instead of `dart test --reporter json`. Both
  runners emit the identical package:test JSON protocol, so tracking is
  unchanged. Non-Flutter packages keep using `dart test`.
- `DartTestParser.buildLaunchError` now takes the executable name so launch
  errors name `flutter` vs `dart` (and `flutter.bat` vs `dart.bat` on Windows).

## 1.0.0

- Initial version.
