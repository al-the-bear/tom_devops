import 'package:test/test.dart';
import '../lib/my_cli.dart';

void main() {
  group('MyCli', () {
    test('creates instance', () {
      final cli = MyCli();
      expect(cli, isNotNull);
    });
  });
}
