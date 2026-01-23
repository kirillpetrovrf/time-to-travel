import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/services/telegram_auth_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// POST /auth/telegram/callback-code
/// Обмен authCode на JWT токены (для polling после START в боте)
/// 
/// Логика:
/// 1. Клиент вводит номер телефона
/// 2. /init создаёт authCode = "AUTH_79281234567"
/// 3. Пользователь открывает Telegram и нажимает START
/// 4. Webhook получает /start AUTH_79281234567
/// 5. Webhook создаёт/обновляет user с этим phone и telegram_id
/// 6. Клиент опрашивает /callback-code с authCode
/// 7. Бэкенд ищет user по phone из authCode
/// 8. Если найден и telegram_id установлен -> возвращает токены
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  try {
    print('🔄 [POLLING] ========== ЗАПРОС НА ПРОВЕРКУ АВТОРИЗАЦИИ ==========');
    
    final body = await context.request.body();
    print('📦 [POLLING] Body: $body');
    
    final data = jsonDecode(body) as Map<String, dynamic>;
    final authCode = data['authCode'] as String?;
    
    print('🔑 [POLLING] Получен authCode: $authCode');

    if (authCode == null || authCode.isEmpty) {
      print('⚠️ [POLLING] authCode отсутствует');
      return Response.json(
        statusCode: 400,
        body: {'error': 'authCode is required'},
      );
    }

    // Извлекаем номер телефона из authCode
    // Формат: AUTH_79281234567
    if (!authCode.startsWith('AUTH_')) {
      print('⚠️ [POLLING] Неверный формат authCode: $authCode');
      return Response.json(
        statusCode: 400,
        body: {'error': 'Invalid authCode format'},
      );
    }

    final phone = '+${authCode.substring(5)}'; // AUTH_ = 5 символов
    print('📱 [POLLING] Извлечён телефон: $phone');

    final db = context.read<DatabaseService>();
    final userRepo = UserRepository(db);
    final jwtHelper = context.read<JwtHelper>();
    final authService = TelegramAuthService();

    print('🔍 [POLLING] Проверяем сессию авторизации: $authCode');
    
    // Сначала проверяем есть ли сохранённая сессия (webhook уже обработал /start)
    final session = authService.getAuthSession(authCode);
    
    if (session == null) {
      print('⏳ [POLLING] Сессия НЕ найдена - пользователь ещё не нажал START в боте');
      print('💡 [POLLING] Доступные сессии: ${authService.getStats()}');
      return Response.json(
        statusCode: 404,
        body: {'error': 'Telegram not connected - please press START in bot'},
      );
    }
    
    print('✅ [POLLING] Сессия найдена! userId=${session.userId}, phone=${session.phone}');
    print('🔍 [POLLING] Загружаем данные пользователя из БД...');
    
    // Находим пользователя по ID из сессии
    final user = await userRepo.findById(session.userId);

    if (user == null) {
      print('❌ [POLLING] Пользователь НЕ НАЙДЕН по ID: ${session.userId}');
      return Response.json(
        statusCode: 404,
        body: {'error': 'User not found'},
      );
    }

    print('👤 [POLLING] Пользователь загружен: id=${user.id}, telegram_id=${user.telegramId}, role=${user.role}');
    print('✅ [POLLING] Пользователь авторизован! Генерируем токены...');

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
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    print('💾 [POLLING] Создаём сессию для user_id: ${user.id}');
    
    await db.execute(
      '''
      INSERT INTO user_sessions (user_id, refresh_token, expires_at)
      VALUES (@user_id, @refresh_token, @expires_at)
      ''',
      parameters: {
        'user_id': user.id,
        'refresh_token': refreshToken,
        'expires_at': expiresAt,
      },
    );

    print('🎉 [POLLING] Session created for user: ${user.id}');

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
    print('❌ Error in callback-code: $e');
    print('StackTrace: $stackTrace');
    
    return Response.json(
      statusCode: 500,
      body: {'error': 'Internal server error', 'details': e.toString()},
    );
  }
}
