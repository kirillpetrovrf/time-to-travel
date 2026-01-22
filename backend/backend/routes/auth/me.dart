import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// GET /auth/me - Получить текущего пользователя
Future<Response> onRequest(RequestContext context) async {
  // Проверяем метод
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    // Получаем сервисы
    final db = context.read<DatabaseService>();
    final userRepo = UserRepository(db);
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

    // Находим пользователя
    final user = await userRepo.findById(userId);
    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'User not found'},
      );
    }

    // Проверяем активность
    if (!user.isActive) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Account is deactivated'},
      );
    }

    // Возвращаем пользователя
    return Response.json(
      body: {'user': user.toJson()},
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to get user: ${e.toString()}'},
    );
  }
}
