import 'package:core_lib/core_lib.dart';

void main() {
  // Create a user
  final user = User(id: '123', name: 'John Doe');
  print('Created user: ${user.name}');
  
  // Create config
  final config = Config(appName: 'MyApp', version: '1.0.0');
  print('App: ${config.appName} v${config.version}');
}
