import 'package:test/test.dart';
import '../../lib/core_lib.dart';

void main() {
  group('toJsonSafe', () {
    test('converts map to safe format', () {
      final result = toJsonSafe({'key': 'value'});
      expect(result, equals({'key': 'value'}));
    });
  });
}
