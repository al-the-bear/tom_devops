import '../model/test_entry.dart';

/// Parses structured metadata from a test description string.
///
/// Format: `<ID>: <description> [<creation date>] (<expected result>)`
///
/// All components except description are optional.
class TestDescriptionParser {
  /// Regex for creation date in `[YYYY-MM-DD HH:MM]` format.
  static final _datePattern = RegExp(
    r'\[(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2})\]',
  );

  /// Regex for expected result `(PASS)` or `(FAIL)`.
  static final _expectPattern = RegExp(r'\((PASS|FAIL)\)\s*$');

  /// Regex for test ID (alphanumeric with hyphens before the first colon).
  ///
  /// A colon followed by another colon is a path separator (`module::test`),
  /// not the end of an ID.
  static final _idPattern = RegExp(
    r'^([A-Za-z][\w-]*(?:-\d+\w*)?)\s*:(?!:)\s*',
  );

  /// Parses a test description into a [TestEntry].
  ///
  /// [fullDescription] is the complete description as reported by `dart test`.
  /// [suite] is the optional test file path.
  /// [groups] is the optional group path extracted from the test hierarchy.
  ///
  /// An ID is taken only when [fullDescription] spells it `<ID>: `: that is
  /// the form a tracking file writes it back in (or as a bare `<ID>:`), so
  /// any other spelling (a test named `case:x` in another language) would
  /// come back as a different test. Such a name keeps its colon in the
  /// description.
  static TestEntry parse(
    String fullDescription, {
    String? suite,
    String? groups,
  }) {
    var remaining = fullDescription.trim();
    String? id;
    DateTime? creationDate;
    var expectation = 'OK';

    // Extract expected result from end
    final expectMatch = _expectPattern.firstMatch(remaining);
    if (expectMatch != null) {
      expectation = expectMatch.group(1) == 'FAIL' ? 'FAIL' : 'OK';
      remaining = remaining.substring(0, expectMatch.start).trim();
    }

    // Extract creation date
    final dateMatch = _datePattern.firstMatch(remaining);
    if (dateMatch != null) {
      creationDate = DateTime(
        int.parse(dateMatch.group(1)!),
        int.parse(dateMatch.group(2)!),
        int.parse(dateMatch.group(3)!),
        int.parse(dateMatch.group(4)!),
        int.parse(dateMatch.group(5)!),
      );
      remaining = remaining.replaceFirst(dateMatch.group(0)!, '').trim();
    }

    // Extract ID
    final idMatch = _idPattern.firstMatch(remaining);
    final spelled = fullDescription.trim();
    if (idMatch != null &&
        (spelled.startsWith('${idMatch.group(1)}: ') ||
            spelled == '${idMatch.group(1)}:')) {
      id = idMatch.group(1);
      remaining = remaining.substring(idMatch.end).trim();
    }

    return TestEntry(
      id: id,
      fullDescription: fullDescription,
      description: remaining,
      groups: groups,
      creationDate: creationDate,
      expectation: expectation,
      suite: suite,
    );
  }
}
