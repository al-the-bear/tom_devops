import 'dart:convert';

/// The JSON object a line of a test runner's output carries, or null.
///
/// Normally the whole line is the object. A test that writes to stdout
/// without a trailing newline (a progress line ending in `\r`, an ESC `[K`
/// erase) glues that text onto the front of the runner's next event, so the
/// line is `<text>{"type":...}`. Reading only whole lines would drop that
/// event and leave a passing test without a result. So when the line as a
/// whole is no object, the object is read from the first `{"` from which the
/// rest of the line decodes; the glued text is ignored.
Map<String, dynamic>? decodeJsonEventLine(String line) {
  final trimmed = line.trim();
  if (trimmed.isEmpty) return null;
  final whole = _decodeObject(trimmed);
  if (whole != null) return whole;
  for (
    var start = trimmed.indexOf('{"', 1);
    start > 0;
    start = trimmed.indexOf('{"', start + 1)
  ) {
    final tail = _decodeObject(trimmed.substring(start));
    if (tail != null) return tail;
  }
  return null;
}

Map<String, dynamic>? _decodeObject(String text) {
  if (!text.startsWith('{')) return null;
  try {
    final value = jsonDecode(text);
    return value is Map<String, dynamic> ? value : null;
  } on FormatException {
    return null;
  }
}
