// A campaign file as a consumer writes one (fuzz/<name>_fuzz.dart), used by
// TF-11: one target with a planted bug, one clean.
import 'package:tom_fuzz/tom_fuzz.dart';

import 'parsers.dart';

Future<void> main(List<String> args) => fuzzMain(args, [
  FuzzCampaignTarget(
    FuzzTarget('key_value', brokenKeyValue, rejects: rejectsFormat),
    corpusDirectory: 'test/fixtures/corpus/key_value',
    coverage: const ['package:tom_fuzz_test_fixtures/'],
  ),
  FuzzCampaignTarget(
    FuzzTarget('json', jsonTarget, rejects: rejectsFormat),
    mutators: const [ByteMutator(), JsonMutator()],
    corpusDirectory: 'test/fixtures/corpus/json',
  ),
]);
