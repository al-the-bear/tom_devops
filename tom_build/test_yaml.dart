import 'package:yaml/yaml.dart';

void main() {
  var yamlStr = '''
commands:
  - dartscript: |
      print("hello");
      print("world");
''';
  var y = loadYaml(yamlStr);
  print('Parsed: $y');
  print('Commands type: ${y['commands'].runtimeType}');
  print('First command: ${y['commands'][0]}');
  print('First command type: ${y['commands'][0].runtimeType}');
}
