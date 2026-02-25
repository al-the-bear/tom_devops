import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'routes/routes.dart';

/// Main server class that configures and starts the HTTP server.
class MyServer {
  HttpServer? _server;
  
  /// Creates the router with all routes configured.
  Router get router {
    final router = Router();
    configureRoutes(router);
    return router;
  }
  
  /// Starts the server on the specified port.
  Future<void> start({int port = 8080}) async {
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router);
    
    _server = await io.serve(handler, InternetAddress.anyIPv4, port);
  }
  
  /// Stops the server.
  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }
}
