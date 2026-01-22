import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/utils/jwt_helper.dart';

/// Middleware для проверки JWT токена
/// Добавляет userId в контекст если токен валиден
Handler authMiddleware(Handler handler) {
  return (context) async {
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем токен из заголовка
    final authHeader = context.request.headers['authorization'];
    
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Missing or invalid authorization header'},
      );
    }

    final token = authHeader.substring(7); // Убираем "Bearer "

    // Проверяем токен
    final payload = jwtHelper.verifyToken(token);
    if (payload == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid or expired token'},
      );
    }

    // Проверяем что это access token
    if (!jwtHelper.isAccessToken(payload)) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid token type'},
      );
    }

    // Получаем userId
    final userId = payload['userId'] as String?;
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid token payload'},
      );
    }

    // Добавляем userId в контекст
    return handler(
      context.provide<String>(() => userId),
    );
  };
}
