import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/utils/jwt_helper.dart';

/// POST /auth/logout - Выход (отзыв refresh token)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final db = context.read<DatabaseService>();
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем refresh token из body или Authorization header
    String? refreshToken;
    
    // Пробуем получить из body
    final json = await context.request.json() as Map<String, dynamic>?;
    refreshToken = json?['refreshToken'] as String?;

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
      // Даже если токен невалидный, возвращаем успех
      // (пользователь уже "вышел")
      return Response.json(
        body: {'message': 'Logged out successfully'},
      );
    }

    final userId = payload['userId'] as String?;
    if (userId == null) {
      return Response.json(
        body: {'message': 'Logged out successfully'},
      );
    }

    // Отзываем refresh token в БД
    final revoked = await _revokeRefreshToken(db, userId, refreshToken);

    if (revoked) {
      return Response.json(
        body: {
          'message': 'Logged out successfully',
          'revokedTokens': 1,
        },
      );
    } else {
      // Токен не найден, но это не ошибка
      return Response.json(
        body: {'message': 'Logged out successfully'},
      );
    }
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to logout: ${e.toString()}'},
    );
  }
}

/// Отозвать refresh token в БД
Future<bool> _revokeRefreshToken(
  DatabaseService db,
  String userId,
  String token,
) async {
  final result = await db.execute(
    '''
    UPDATE refresh_tokens
    SET revoked_at = NOW()
    WHERE user_id = @userId
      AND token = @token
      AND revoked_at IS NULL
    ''',
    parameters: {
      'userId': userId,
      'token': token,
    },
  );

  return result > 0;
}
