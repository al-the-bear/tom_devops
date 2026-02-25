# My Server

HTTP server application built with Shelf.

## Running

```bash
dart run bin/server.dart
```

## Endpoints

- `GET /health` - Health check
- `GET /ready` - Readiness check
- `GET /api/users` - List users
- `GET /api/users/<id>` - Get user by ID
- `POST /api/users` - Create user

## Docker

```bash
docker build -t my_server .
docker run -p 8080:8080 my_server
```
