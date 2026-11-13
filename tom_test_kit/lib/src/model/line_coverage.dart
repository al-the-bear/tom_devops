/// The line coverage of a test run: lines hit out of the lines that could be
/// hit, summed over every file of an lcov report.
class LineCoverage {
  /// Lines executed at least once.
  final int covered;

  /// Lines that hold code (lcov's `LF`).
  final int coverable;

  const LineCoverage({required this.covered, required this.coverable});

  /// Covered lines as a share of the coverable ones, 0..100; 0 without any.
  double get percent => coverable == 0 ? 0 : covered * 100 / coverable;

  /// `81.2% (1234/1520 lines)`.
  String describe() =>
      '${percent.toStringAsFixed(1)}% ($covered/$coverable lines)';

  /// The token kept in a run's column header: `cov:1234/1520`.
  String get headerToken => 'cov:$covered/$coverable';

  /// Reads the token at the start of [text] (a column header's text after
  /// its timestamp); null when there is none.
  static ({LineCoverage coverage, String rest})? fromHeaderText(String text) {
    final match = RegExp(r'^cov:(\d+)/(\d+)(?:\s+|$)').firstMatch(text);
    if (match == null) return null;
    return (
      coverage: LineCoverage(
        covered: int.parse(match.group(1)!),
        coverable: int.parse(match.group(2)!),
      ),
      rest: text.substring(match.end).trim(),
    );
  }

  /// Sums an lcov report: `LH` (lines hit) and `LF` (lines found) per file;
  /// a file without them is counted from its `DA:<line>,<hits>` records.
  /// Null when [lcov] holds no file record.
  static LineCoverage? parseLcov(String lcov) {
    var covered = 0;
    var coverable = 0;
    var files = 0;
    int? lh, lf;
    var daHit = 0, daFound = 0;
    for (final raw in lcov.split('\n')) {
      final line = raw.trim();
      if (line.startsWith('SF:')) {
        lh = lf = null;
        daHit = daFound = 0;
      } else if (line.startsWith('DA:')) {
        final parts = line.substring(3).split(',');
        if (parts.length >= 2) {
          daFound++;
          if ((int.tryParse(parts[1]) ?? 0) > 0) daHit++;
        }
      } else if (line.startsWith('LH:')) {
        lh = int.tryParse(line.substring(3));
      } else if (line.startsWith('LF:')) {
        lf = int.tryParse(line.substring(3));
      } else if (line == 'end_of_record') {
        files++;
        covered += lh ?? daHit;
        coverable += lf ?? daFound;
      }
    }
    return files == 0
        ? null
        : LineCoverage(covered: covered, coverable: coverable);
  }

  @override
  bool operator ==(Object other) =>
      other is LineCoverage &&
      other.covered == covered &&
      other.coverable == coverable;

  @override
  int get hashCode => Object.hash(covered, coverable);
}
