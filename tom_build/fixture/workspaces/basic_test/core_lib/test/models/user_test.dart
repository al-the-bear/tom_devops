import 'package:test/test.dart';
import 'package:core_lib/core_lib.dart';

void main() {
  group('User', () {
    test('creates user with id and name', () {
      final user = User(id: '1', name: 'Test');
      expect(user.id, equals('1'));
      expect(user.name, equals('Test'));
    });
  });
}
