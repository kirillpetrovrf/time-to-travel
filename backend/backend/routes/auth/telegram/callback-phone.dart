import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// POST /auth/telegram/callback-phone
/// Обмен номера телефона на JWT токены (для polling после START в боте)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  try {
    final body = await context.request.body();
    final data = jsonDecode(body) as Map<String, dynamic>;
    final phone = data['phone'] as String?;

    if (phone == null || phone.isEmpty) {
      return Response.json(
        statusCode: 400,
        body: {'error': 'phone is required'},
      );
    }

    final db = context.read<DatabaseService>();
    final userRepo = UserRepository(db);
    final jwtHelper = context.read<JwtHelper>();

    // Находим пользователя по номеру телефона и проверяем, что у него есть telegram_id
    final user = await userRepo.findByPhone(phone);

    if (user == null) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'User not found - please press START in Telegram bot first'},
      );
    }

    // Проверяем, что пользователь нажал START в боте (telegram_id установлен)
    if (user.telegramId == null || user.telegramId == 0) {
      return Response.json(
        statusCode: 404,
        body: {'error': 'Telegram not connected - please press START in bot'},
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

    final refreshToken = jwtHelper.createRefreshToken(
      userId: user.id,
    );

    // Создаём сессию
    final sessionId = _uuid.v4();
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    await db.execute(
      '''
      INSERT INTO user_sessions (session_id, user_id, refresh_token, expires_at, created_at)
      VALUES (@session_id, @user_id, @refresh_token, @expires_at, NOW())
      ''',
      parameters: {
        'session_id': sessionId,
        'user_id': user.id,
        'refresh_token': refreshToken,
        'expires_at': expiresAt,
      },
    );

    // Возвращаем токены и данные пользователя
    return Response.json(
      body: {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'user': {
          'id': user.id,
          'fullName': user.fullName,
          'phone': user.phone,
          'email': user.email,
          'role': user.role,
          'telegramId': user.telegramId,
        },
      },
    );
  } catch (e, stackTrace) {
    print('❌ Error in callback-phone: $e');
    print('StackTrace: $stackTrace');
    
    return Response.json(
      statusCode: 500,
      body: {'error': 'Internal server error', 'details': e.toString()},
    );
  }
}
