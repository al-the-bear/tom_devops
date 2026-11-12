// Parser fixtures for the tom_fuzz tests. Targets run in a worker isolate,
// so they are top-level functions.
import 'dart:convert';
import 'dart:typed_data';

/// A `key=value` line parser with a planted bug: it rejects malformed lines
/// with a FormatException, but a NUL byte in a key crashes it with a
/// StateError instead.
void brokenKeyValue(Uint8List input) {
  final text = utf8.decode(input, allowMalformed: true);
  for (final line in const LineSplitter().convert(text)) {
    if (line.isEmpty) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) throw FormatException('no key', line);
    final key = line.substring(0, eq);
    if (key.contains('\u0000')) throw StateError('NUL in key reached the map');
  }
}

/// A clean target: dart:convert's JSON decoder.
void jsonTarget(Uint8List input) => jsonDecode(utf8.decode(input));

/// Never returns on an input starting with `x`; rejects everything else.
void hangsOnX(Uint8List input) {
  if (input.isNotEmpty && input[0] == 0x78) {
    var i = 0;
    while (true) {
      i++;
      if (i < 0) break;
    }
  }
  throw const FormatException('not x');
}

final _kept = <Uint8List>[];

/// Holds on to 128 MB per input.
void hoardsMemory(Uint8List input) {
  final block = Uint8List(128 * 1024 * 1024);
  for (var i = 0; i < block.length; i += 4096) {
    block[i] = 1;
  }
  _kept.add(block);
}

bool rejectsFormat(Object e) => e is FormatException;
