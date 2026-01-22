import 'package:dart_frog/dart_frog.dart';

/// Health check endpoint
/// GET /health
Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'status': 'ok',
      'service': 'Time to Travel API',
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
}
