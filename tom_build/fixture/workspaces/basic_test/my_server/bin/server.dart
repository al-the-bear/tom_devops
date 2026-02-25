import 'dart:io';

import 'package:my_server/my_server.dart';

Future<void> main(List<String> args) async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = MyServer();
  await server.start(port: port);
  print('Server listening on port $port');
}
