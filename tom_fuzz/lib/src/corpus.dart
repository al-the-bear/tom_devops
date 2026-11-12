import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// The suffix of the description a saved failure carries beside its input.
const kFailureSuffix = '.failure.json';

/// One seed input.
class CorpusEntry {
  /// Where it came from: the file name relative to the corpus folder, or a
  /// name given in code.
  final String name;

  /// The input.
  final Uint8List bytes;

  /// Creates an entry.
  CorpusEntry(this.name, List<int> bytes)
    : bytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
}

/// The seed inputs a run starts from.
///
/// Every seed is run once as it is before any mutation, so a saved failure
/// placed in the corpus folder (`tom_fuzz` writes them to `failures/` under
/// it by default) is replayed on every run: a failure becomes a regression
/// case.
class Corpus {
  /// The seeds, in a stable order.
  final List<CorpusEntry> entries;

  /// A corpus of [entries].
  Corpus(Iterable<CorpusEntry> entries) : entries = List.of(entries);

  /// Every file under [directory] (recursively) except the failure
  /// descriptions, sorted by path. A missing folder is an empty corpus.
  factory Corpus.directory(String directory) {
    final dir = Directory(directory);
    if (!dir.existsSync()) return Corpus(const []);
    final files =
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => !f.path.endsWith(kFailureSuffix))
            .where((f) => !p.basename(f.path).startsWith('.'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    return Corpus([
      for (final f in files)
        CorpusEntry(p.relative(f.path, from: directory), f.readAsBytesSync()),
    ]);
  }

  /// This corpus followed by [other]'s entries.
  Corpus plus(Corpus other) => Corpus([...entries, ...other.entries]);

  /// Whether there are no seeds.
  bool get isEmpty => entries.isEmpty;
}
