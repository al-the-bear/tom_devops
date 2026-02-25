import 'package:shelf_router/shelf_router.dart';

import '../handlers/handlers.dart';

/// Configures all routes on the router.
void configureRoutes(Router router) {
  // Health check routes
  router.get('/health', healthHandler);
  router.get('/ready', readinessHandler);
  
  // API routes
  router.get('/api/users', getUsersHandler);
  router.get('/api/users/<id>', getUserHandler);
  router.post('/api/users', createUserHandler);
}
