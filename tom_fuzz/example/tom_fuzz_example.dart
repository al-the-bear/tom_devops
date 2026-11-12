// A complete fuzz target and campaign for a small parser of untrusted input.
//
//   dart run example/tom_fuzz_example.dart --duration 30
//   dart run example/tom_fuzz_example.dart --iterations 20000 --seed 7
//
// In a package of your own the same file lives at fuzz/<name>_fuzz.dart and
// `testkit :fuzz` runs it; the seeds live in fuzz/corpus/<target>/.
import 'dart:convert';
import 'dart:typed_data';

import 'package:tom_fuzz/tom_fuzz.dart';

/// The parser under test: a semantic version, `MAJOR.MINOR.PATCH[-pre]`.
/// Malformed input is rejected with a FormatException — the declared
/// rejection. Anything else it throws is a bug the fuzzer reports.
(int, int, int, String?) parseVersion(String text) {
  final match = RegExp(
    r'^(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?$',
  ).firstMatch(text.trim());
  if (match == null) throw FormatException('not a version', text);
  int part(int i) {
    final value = int.tryParse(match.group(i)!);
    if (value == null) throw FormatException('number too large', text);
    return value;
  }

  return (part(1), part(2), part(3), match.group(4));
}

/// The target: bytes in, through the parser. Top-level, because the fuzzer
/// runs targets in a worker isolate.
void semverTarget(Uint8List input) =>
    parseVersion(utf8.decode(input, allowMalformed: true));

Future<void> main(List<String> args) => fuzzMain(args, [
  FuzzCampaignTarget(
    FuzzTarget('semver', semverTarget, rejects: rejectsFormatException),
    corpusDirectory: 'example/fuzz/corpus/semver',
  ),
]);
