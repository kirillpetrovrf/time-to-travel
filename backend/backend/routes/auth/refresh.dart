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

    // Проверяем что refresh token существует в БД и не был отозван
    final tokenExists = await _checkRefreshToken(db, userId, refreshToken);
    
    if (!tokenExists) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Refresh token has been revoked'},
      );
    }

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

    // Генерируем новый access token (refresh token остается тот же)
    final newAccessToken = jwtHelper.createAccessToken(
      userId: userId,
      email: user.email,
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

/// Проверить существование refresh token в БД
Future<bool> _checkRefreshToken(
  DatabaseService db,
  String userId,
  String token,
) async {
  final result = await db.query(
    '''
    SELECT id FROM refresh_tokens
    WHERE user_id = @userId
      AND token = @token
      AND expires_at > NOW()
      AND revoked_at IS NULL
    ''',
    parameters: {
      'userId': userId,
      'token': token,
    },
  );

  return result.isNotEmpty;
}
