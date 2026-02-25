import 'package:test/test.dart';

import 'package:my_server/my_server.dart';

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
