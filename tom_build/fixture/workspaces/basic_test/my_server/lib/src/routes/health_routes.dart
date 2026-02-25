import 'package:shelf/shelf.dart';

/// Health check endpoint.
Response healthHandler(Request request) {
  return Response.ok('{"status": "healthy"}', 
      headers: {'content-type': 'application/json'});
}

/// Readiness check endpoint.
Response readinessHandler(Request request) {
  return Response.ok('{"status": "ready"}',
      headers: {'content-type': 'application/json'});
}
