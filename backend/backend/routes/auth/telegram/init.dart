import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:logging/logging.dart';

final _log = Logger('TelegramInit');

/// POST /auth/telegram/init
/// Начать процесс авторизации через Telegram
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405);
  }

  try {
    print('🚀 [INIT] Получен запрос на инициализацию Telegram авторизации');
    
    final body = await context.request.body();
    print('📦 [INIT] Body получен: ${body.substring(0, body.length > 100 ? 100 : body.length)}...');
    
    final data = jsonDecode(body) as Map<String, dynamic>;
    final phone = data['phone'] as String?;
    
    print('📱 [INIT] Phone из запроса: $phone');

    if (phone == null || phone.isEmpty) {
      print('⚠️ [INIT] Phone отсутствует в запросе');
      return Response.json(
        statusCode: 400,
        body: {'error': 'Phone number is required'},
      );
    }

    // Очищаем телефон от лишних символов
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    print('🧹 [INIT] Очищенный phone: $cleanPhone');
    
    // Генерируем код авторизации
    final authCode = 'AUTH_${cleanPhone.replaceAll('+', '')}';
    print('🔑 [INIT] Сгенерирован authCode: $authCode');
    
    // Создаём или находим пользователя по телефону
    final db = context.read<DatabaseService>();
    final userRepo = UserRepository(db);
    
    print('🔍 [INIT] Ищем пользователя по телефону: $cleanPhone');
    var user = await userRepo.findByPhone(cleanPhone);
    
    if (user == null) {
      print('➕ [INIT] Пользователь не найден, создаём нового');
      
      // Создаём временную запись пользователя
      final userId = await db.insert(
        '''
        INSERT INTO users (
          phone, role, is_active, email, password_hash, name
        ) VALUES (
          @phone, 'passenger', true, '', '', 'Новый пользователь'
        )
        ''',
        parameters: {
          'phone': cleanPhone,
        },
      );
      
      print('✅ [INIT] Создан временный пользователь: id=$userId, phone=$cleanPhone');
    } else {
      print('✅ [INIT] Найден существующий пользователь: id=${user.id}, phone=$cleanPhone, telegram_id=${user.telegramId}');
    }
    
    // Формируем deep link
    final deepLink = 'https://t.me/timetotravelauth_bot?start=$authCode';
    print('🔗 [INIT] Сформирован deep link: $deepLink');

    print('✅ [INIT] Успешный ответ клиенту');
    return Response.json(
      body: {
        'deepLink': deepLink,
        'authCode': authCode,
        'phone': cleanPhone,
      },
    );
  } catch (e, stackTrace) {
    print('❌ [INIT] КРИТИЧЕСКАЯ ОШИБКА: $e');
    _log.severe('❌ [INIT] КРИТИЧЕСКАЯ ОШИБКА: $e', e, stackTrace);
    return Response.json(
      statusCode: 500,
      body: {'error': 'Internal server error', 'details': e.toString()},
    );
  }
}
