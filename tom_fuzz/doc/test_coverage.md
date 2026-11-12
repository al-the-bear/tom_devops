# Tom Fuzz — Test Coverage

**Test file:** `test/tom_fuzz_test.dart` — **ID prefix `TF`**. The fixtures in `test/fixtures/parsers.dart` are parsers
whose behaviour is known: one with a planted bug, a clean JSON target, one that hangs, one that holds memory.

| ID | Feature | Status |
|----|---------|--------|
| TF-1 | The planted bug of a broken parser is found (crash, error type, stack, input) | ✅ |
| TF-2 | A parser that only rejects the declared way is clean | ✅ |
| TF-3 | A run that does not finish is caught; the worker restarts and the run goes on | ✅ |
| TF-4 | A saved failure has its description, replays, and as a seed runs first | ✅ |
| TF-5 | The same seed gives the same run | ✅ |
| TF-6 | Memory growth past the bound is a failure | ✅ |
| TF-7 | JSON mutation keeps JSON and changes it; non-JSON is left to others | ✅ |
| TF-8 | XML mutation works on elements; text without one is left | ✅ |
| TF-9 | Byte mutation always yields an input, even from an empty one | ✅ |
| TF-10 | A text target sees malformed UTF-8 decoded leniently | ✅ |
| TF-11 | The campaign runs from the command line: exit code, text and JSON report, `--list` | ✅ |
| TF-12 | `fuzzTest` runs the fixed-seed short mode as a test | ✅ |
