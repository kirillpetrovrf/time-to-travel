import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// POST /auth/logout-all - Выйти со всех устройств (отозвать все refresh tokens)
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

    // Получаем access token из Authorization header
    final authHeader = context.request.headers['authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Authorization required'},
      );
    }

    final token = authHeader.substring(7);
    final payload = jwtHelper.verifyToken(token);

    if (payload == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid or expired token'},
      );
    }

    final userId = payload['userId'] as String?;
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid token payload'},
      );
    }

    // Проверяем что пользователь существует
    final user = await userRepo.findById(userId);

    if (user == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'User not found'},
      );
    }

    // Отзываем все refresh tokens пользователя
    final revokedCount = await _revokeAllRefreshTokens(db, userId);

    return Response.json(
      body: {
        'message': 'Logged out from all devices successfully',
        'revokedTokens': revokedCount,
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to logout from all devices: ${e.toString()}'},
    );
  }
}

/// Отозвать все refresh tokens пользователя
Future<int> _revokeAllRefreshTokens(
  DatabaseService db,
  String userId,
) async {
  final result = await db.execute(
    '''
    UPDATE refresh_tokens
    SET revoked_at = NOW()
    WHERE user_id = @userId
      AND revoked_at IS NULL
    ''',
    parameters: {'userId': userId},
  );

  return result;
}
