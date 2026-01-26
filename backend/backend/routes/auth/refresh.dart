import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// POST /auth/refresh - Обновить access token используя refresh token
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final db = context.read<DatabaseService>();
    final userRepo = UserRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем refresh token из body или Authorization header
    String? refreshToken;
    
    // Пробуем получить из body
    try {
      final json = await context.request.json() as Map<String, dynamic>?;
      refreshToken = json?['refreshToken'] as String?;
    } catch (e) {
      // Body пустое или невалидный JSON, продолжаем с header
      refreshToken = null;
    }

    // Если нет в body, пробуем из header
    if (refreshToken == null) {
      final authHeader = context.request.headers['authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        refreshToken = authHeader.substring(7);
      }
    }

    if (refreshToken == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Refresh token is required'},
      );
    }

    // Проверяем refresh token
    final payload = jwtHelper.verifyToken(refreshToken);

    if (payload == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid or expired refresh token'},
      );
    }

    // Проверяем что это именно refresh token
    final tokenType = payload['type'] as String?;
    if (tokenType != 'refresh') {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Invalid token type. Expected refresh token'},
      );
    }

    final userId = payload['userId'] as String?;
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid token payload'},
      );
    }

    // NOTE: Refresh token проверяется через JWT подпись выше (verifyToken)
    // Проверка в БД не требуется, так как токен криптографически подписан
    // и проверен через jwtHelper.verifyToken()
    
    // Получаем пользователя
    final user = await userRepo.findById(userId);

    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'User not found'},
      );
    }

    if (!user.isActive) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'User account is deactivated'},
      );
    }

    // Генерируем новый access token с role (refresh token остается тот же)
    final newAccessToken = jwtHelper.createAccessToken(
      userId: userId,
      email: user.email,
      additionalClaims: {'role': user.role},
    );

    return Response.json(
      body: {
        'accessToken': newAccessToken,
        'user': user.toJson(),
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to refresh token: ${e.toString()}'},
    );
  }
}
