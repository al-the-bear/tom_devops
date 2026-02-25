import 'package:test/test.dart';
import 'package:utils_lib/utils_lib.dart';

void main() {
  group('capitalize', () {
    test('capitalizes first letter', () {
      expect(capitalize('hello'), equals('Hello'));
    });
    
    test('handles empty string', () {
      expect(capitalize(''), equals(''));
    });
  });
  
  group('toSnakeCase', () {
    test('converts camelCase to snake_case', () {
      expect(toSnakeCase('helloWorld'), equals('hello_world'));
    });
  });
}
