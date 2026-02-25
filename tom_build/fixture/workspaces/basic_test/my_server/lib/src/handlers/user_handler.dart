import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Handler for GET /api/users
Response getUsersHandler(Request request) {
  final users = [
    {'id': '1', 'name': 'Alice'},
    {'id': '2', 'name': 'Bob'},
  ];
  return Response.ok(jsonEncode(users),
      headers: {'content-type': 'application/json'});
}

/// Handler for GET /api/users/<id>
Response getUserHandler(Request request, String id) {
  final user = {'id': id, 'name': 'User $id'};
  return Response.ok(jsonEncode(user),
      headers: {'content-type': 'application/json'});
}

/// Handler for POST /api/users
Future<Response> createUserHandler(Request request) async {
  final body = await request.readAsString();
  final data = jsonDecode(body) as Map<String, dynamic>;
  final user = {'id': '3', 'name': data['name']};
  return Response(201, body: jsonEncode(user),
      headers: {'content-type': 'application/json'});
}
