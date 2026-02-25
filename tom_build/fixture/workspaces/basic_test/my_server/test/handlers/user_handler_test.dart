import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'package:my_server/my_server.dart';

void main() {
  group('User handlers', () {
    test('getUsersHandler returns list of users', () {
      final request = Request('GET', Uri.parse('http://localhost/api/users'));
      final response = getUsersHandler(request);
      
      expect(response.statusCode, equals(200));
      
      final body = jsonDecode(response.readAsString() as String);
      expect(body, isList);
    });

    test('getUserHandler returns single user', () {
      final request = Request('GET', Uri.parse('http://localhost/api/users/1'));
      final response = getUserHandler(request, '1');
      
      expect(response.statusCode, equals(200));
    });
  });
}
