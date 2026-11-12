import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Turns one input into a new one.
///
/// [mutate] returns null when it cannot work on the input (a JSON mutator
/// given bytes that are not JSON); the fuzzer then uses another mutator.
/// [corpus] is every seed, for mutators that splice.
abstract class Mutator {
  /// A short name for reports.
  String get name;

  /// A mutated copy of [input], or null.
  Uint8List? mutate(Uint8List input, Random random, List<Uint8List> corpus);
}

/// Values at the edges of the ranges parsers count in.
const _interestingBytes = [
  0x00,
  0x01,
  0x7F,
  0x80,
  0xFF,
  0x0A,
  0x0D,
  0x22,
  0x3C,
];

/// Text fragments that break parsers more often than random bytes do.
final _interestingTokens = [
  '\u0000',
  '\uFFFF',
  '%n%s',
  '{{',
  '[[[[',
  '"',
  "'",
  '\\',
  '<',
  '>',
  '&',
  '-1',
  '0',
  '2147483648',
  '-9223372036854775809',
  '1e309',
  'NaN',
  '\u202E',
  '\uD800',
].map((t) => utf8.encode(t)).toList();

/// Byte-level mutation: bit flips, interesting values, insertion, deletion,
/// duplication of a range, and splicing with another seed.
class ByteMutator implements Mutator {
  /// The largest range inserted, deleted or duplicated at once.
  final int maxRange;

  /// Creates the mutator.
  const ByteMutator({this.maxRange = 64});

  @override
  String get name => 'bytes';

  @override
  Uint8List? mutate(Uint8List input, Random random, List<Uint8List> corpus) {
    final out = BytesBuilder(copy: false);
    final bytes = input;
    int at(int bound) => bound <= 0 ? 0 : random.nextInt(bound);
    int span() => 1 + random.nextInt(maxRange);
    switch (random.nextInt(bytes.isEmpty ? 3 : 8)) {
      case 0: // insert random bytes
        final pos = at(bytes.length + 1);
        out
          ..add(bytes.sublist(0, pos))
          ..add([for (var i = 0; i < span(); i++) random.nextInt(256)])
          ..add(bytes.sublist(pos));
      case 1: // insert an interesting token
        final pos = at(bytes.length + 1);
        out
          ..add(bytes.sublist(0, pos))
          ..add(_interestingTokens[random.nextInt(_interestingTokens.length)])
          ..add(bytes.sublist(pos));
      case 2: // splice with another seed
        final other = corpus.isEmpty
            ? Uint8List(0)
            : corpus[random.nextInt(corpus.length)];
        final a = at(bytes.length + 1);
        final b = at(other.length + 1);
        out
          ..add(bytes.sublist(0, a))
          ..add(other.sublist(b));
      case 3: // flip a bit
        final copy = Uint8List.fromList(bytes);
        final pos = at(copy.length);
        copy[pos] ^= 1 << random.nextInt(8);
        return copy;
      case 4: // set an interesting byte
        final copy = Uint8List.fromList(bytes);
        copy[at(copy.length)] =
            _interestingBytes[random.nextInt(_interestingBytes.length)];
        return copy;
      case 5: // delete a range
        final pos = at(bytes.length);
        final end = min(bytes.length, pos + span());
        out
          ..add(bytes.sublist(0, pos))
          ..add(bytes.sublist(end));
      case 6: // duplicate a range
        final pos = at(bytes.length);
        final end = min(bytes.length, pos + span());
        final range = bytes.sublist(pos, end);
        out
          ..add(bytes.sublist(0, end))
          ..add(range)
          ..add(bytes.sublist(end));
      default: // truncate
        return Uint8List.fromList(bytes.sublist(0, at(bytes.length)));
    }
    return out.takeBytes();
  }
}

/// Structure-level mutation of JSON: the input is decoded, one node of the
/// tree is replaced, removed, duplicated or nested deeply, and the tree is
/// encoded again. Inputs that are not JSON are left to other mutators.
class JsonMutator implements Mutator {
  /// Creates the mutator.
  const JsonMutator();

  @override
  String get name => 'json';

  static final _values = <Object? Function(Random)>[
    (_) => null,
    (_) => true,
    (_) => 0,
    (_) => -1,
    (_) => 9007199254740993,
    (_) => 1e308,
    (_) => '',
    (r) => 'x' * (1 << (8 + r.nextInt(8))),
    (_) => '\u0000\uFFFF\u202E',
    (_) => <Object?>[],
    (_) => <String, Object?>{},
    (r) {
      Object? v = 1;
      for (var i = 0; i < 64 + r.nextInt(512); i++) {
        v = [v];
      }
      return v;
    },
  ];

  @override
  Uint8List? mutate(Uint8List input, Random random, List<Uint8List> corpus) {
    final Object? tree;
    try {
      tree = jsonDecode(utf8.decode(input));
    } on FormatException {
      return null;
    }
    final nodes = <(Object, Object)>[]; // (container, key or index)
    void collect(Object? node) {
      if (node is Map) {
        for (final key in node.keys.toList()) {
          nodes.add((node, key as Object));
          collect(node[key]);
        }
      } else if (node is List) {
        for (var i = 0; i < node.length; i++) {
          nodes.add((node, i));
          collect(node[i]);
        }
      }
    }

    collect(tree);
    final Object? result;
    if (nodes.isEmpty) {
      result = _values[random.nextInt(_values.length)](random);
    } else {
      final (container, key) = nodes[random.nextInt(nodes.length)];
      final choice = random.nextInt(4);
      if (container is Map) {
        switch (choice) {
          case 0:
            container.remove(key);
          case 1:
            container['$key${random.nextInt(9)}'] = container[key];
          default:
            container[key] = _values[random.nextInt(_values.length)](random);
        }
      } else if (container is List) {
        final i = key as int;
        switch (choice) {
          case 0:
            container.removeAt(i);
          case 1:
            container.insert(i, container[i]);
          default:
            container[i] = _values[random.nextInt(_values.length)](random);
        }
      }
      result = tree;
    }
    return Uint8List.fromList(utf8.encode(jsonEncode(result)));
  }
}

/// Element-level mutation of XML: an element is removed, duplicated, nested
/// deeply or given hostile content (entities, a DOCTYPE, an unbalanced tag).
/// The input is read as text and elements are found by their tags, so a
/// malformed document is still mutated; inputs with no element are left to
/// other mutators.
class XmlMutator implements Mutator {
  /// Creates the mutator.
  const XmlMutator();

  @override
  String get name => 'xml';

  static final _element = RegExp(
    r'<([A-Za-z_][\w:.-]*)(\s[^<>]*)?(/>|>([^<]*)</\1\s*>)',
  );

  static const _hostile = [
    '&lt;&amp;&#0;&#x110000;&undefined;',
    '<!DOCTYPE x [<!ENTITY a "aaaaaaaaaa"><!ENTITY b "&a;&a;&a;&a;&a;">]>',
    '<![CDATA[]]]]><![CDATA[>]]>',
    '<unclosed>',
    '</stray>',
    '<?xml version="9.9"?>',
    '<a xmlns:x="urn:x" x:y="1" x:y="2"/>',
  ];

  @override
  Uint8List? mutate(Uint8List input, Random random, List<Uint8List> corpus) {
    final text = utf8.decode(input, allowMalformed: true);
    final elements = _element.allMatches(text).toList();
    if (elements.isEmpty) return null;
    final m = elements[random.nextInt(elements.length)];
    final element = m.group(0)!;
    final String replacement;
    switch (random.nextInt(4)) {
      case 0:
        replacement = '';
      case 1:
        replacement = element * (2 + random.nextInt(8));
      case 2:
        final depth = 32 + random.nextInt(512);
        replacement = '${'<n>' * depth}$element${'</n>' * depth}';
      default:
        final hostile = _hostile[random.nextInt(_hostile.length)];
        replacement = random.nextBool()
            ? '$hostile$element'
            : element.replaceFirst('>', '>$hostile');
    }
    return Uint8List.fromList(
      utf8.encode(text.replaceRange(m.start, m.end, replacement)),
    );
  }
}
