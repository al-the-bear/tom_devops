import 'package:test/test.dart';

import '../lib/my_server.dart';

void main() {
  group('MyServer', () {
    late MyServer server;

    setUp(() {
      server = MyServer();
    });

    test('router is configured', () {
      expect(server.router, isNotNull);
    });
  });
}
