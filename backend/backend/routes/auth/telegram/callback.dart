import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// POST /auth/telegram/callback
/// Обмен telegram_id на JWT токены
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final telegramId = data['telegramId'] as int?;

    if (telegramId == null) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'telegramId is required'},
      );
    }

    final db = context.read<DatabaseService>();
    final userRepo = UserRepository(db);
    final jwtHelper = context.read<JwtHelper>();

    // Находим пользователя
    final user = await userRepo.findByTelegramId(telegramId);

    if (user == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'User not found'},
      );
    }

    // Генерируем токены
    final accessToken = jwtHelper.createAccessToken(
      userId: user.id,
      email: user.email.isNotEmpty ? user.email : 'telegram_${user.telegramId}@local',
      additionalClaims: {
        'telegramId': user.telegramId,
        'role': user.role,
        'fullName': user.fullName,
      },
    );

    final refreshToken = jwtHelper.createRefreshToken(userId: user.id);

    // Сохраняем сессию
    final sessionId = _uuid.v4();
    await db.execute(
      '''
      INSERT INTO user_sessions (id, user_id, refresh_token)
      VALUES (@id, @userId, @refreshToken)
      ''',
      parameters: {
        'id': sessionId,
        'userId': user.id,
        'refreshToken': refreshToken,
      },
    );

    return Response.json(
      body: {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'user': {
          'id': user.id,
          'telegramId': user.telegramId,
          'phone': user.phone,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'username': user.username,
          'role': user.role,
          'fullName': user.fullName,
        },
      },
    );
  } catch (e) {
    print('❌ Error in telegram callback: $e');
    return Response.json(
      statusCode: 500,
      body: {'error': 'Internal server error'},
    );
  }
}
