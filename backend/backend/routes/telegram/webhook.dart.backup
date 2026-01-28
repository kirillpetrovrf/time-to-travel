import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/services/telegram_bot_service.dart';
import 'package:backend/services/telegram_auth_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:logging/logging.dart';

final _log = Logger('TelegramWebhook');

/// Обработчик Telegram webhook
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, body: 'Method Not Allowed');
  }

  try {
    print('🌐 [WEBHOOK] ========== ПОЛУЧЕН ЗАПРОС ОТ TELEGRAM ==========');
    
    final body = await context.request.body();
    print('📦 [WEBHOOK] Body: $body');
    
    final update = jsonDecode(body) as Map<String, dynamic>;
    print('📱 [WEBHOOK] Update parsed: ${update.keys.join(', ')}');

    // Получаем сервисы из контекста
    final db = context.read<DatabaseService>();
    final userRepo = UserRepository(db);
    final telegramBot = context.read<TelegramBotService>();

    // Обработка сообщения
    if (update['message'] != null) {
      final message = update['message'] as Map<String, dynamic>;
      print('💬 [WEBHOOK] Получено сообщение: ${message['text']}');
      
      final text = message['text'] as String?;
      final from = message['from'] as Map<String, dynamic>;
      final chatId = from['id'] as int;
      
      print('👤 [WEBHOOK] От пользователя: chatId=$chatId, username=${from['username']}, firstName=${from['first_name']}');

      if (text != null && text.startsWith('/start')) {
        print('🚀 [WEBHOOK] Обнаружена команда /start: $text');
        
        await _handleStartCommand(
          text: text,
          chatId: chatId,
          from: from,
          userRepo: userRepo,
          telegramBot: telegramBot,
        );
      } else {
        print('ℹ️ [WEBHOOK] Команда НЕ /start, игнорируем: $text');
      }
    } else {
      print('ℹ️ [WEBHOOK] Update без message, пропускаем');
    }

    print('✅ [WEBHOOK] Обработка завершена успешно');
    return Response(statusCode: 200, body: 'OK');
  } catch (e, stackTrace) {
    print('❌ [WEBHOOK] КРИТИЧЕСКАЯ ОШИБКА: $e');
    _log.severe('❌ [WEBHOOK] КРИТИЧЕСКАЯ ОШИБКА: $e', e, stackTrace);
    return Response(statusCode: 500, body: 'Internal Server Error');
  }
}

/// Обработка команды /start
Future<void> _handleStartCommand({
  required String text,
  required int chatId,
  required Map<String, dynamic> from,
  required UserRepository userRepo,
  required TelegramBotService telegramBot,
}) async {
  _log.info('🎯 [START] ========== ОБРАБОТКА КОМАНДЫ /start ==========');
  _log.info('📝 [START] Полный текст: $text');
  
  final telegramId = chatId;
  final firstName = from['first_name'] as String?;
  final lastName = from['last_name'] as String?;
  final username = from['username'] as String?;
  
  _log.info('👤 [START] Данные пользователя: telegramId=$telegramId, firstName=$firstName, lastName=$lastName, username=$username');

  // Проверяем есть ли параметр (deep link)
  final parts = text.split(' ');
  _log.info('🔍 [START] Разбор команды: найдено частей: ${parts.length}');
  
  String? authCode;
  String? phone;

  if (parts.length > 1) {
    authCode = parts[1]; // например: AUTH_79281234567
    _log.info('🔑 [START] Обнаружен параметр: $authCode');
    
    if (authCode.startsWith('AUTH_')) {
      phone = '+${authCode.substring(5)}'; // Убираем AUTH_
      _log.info('� [START] Извлечён телефон из authCode: $phone');
    } else {
      _log.warning('⚠️ [START] Параметр НЕ начинается с AUTH_: $authCode');
    }
  } else {
    _log.info('ℹ️ [START] Команда без параметров (обычный /start)');
  }

  try {
    _log.info('💾 [START] Вызываем upsertFromTelegram с phone=$phone, telegramId=$telegramId');
    
    // Создаём или обновляем пользователя
    final user = await userRepo.upsertFromTelegram(
      telegramId: telegramId,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      username: username,
    );

    _log.info('✅ [START] Пользователь обработан: id=${user.id}, phone=${user.phone}, telegram_id=${user.telegramId}');

    // Если это авторизация через deep link
    if (authCode != null) {
      // ✅ Сохраняем статус авторизации для polling
      final authService = TelegramAuthService();
      authService.setAuthSession(
        authCode: authCode,
        userId: user.id,
        phone: user.phone,
      );
      
      _log.info('💾 [START] Сессия авторизации сохранена: authCode=$authCode');

      // Отправляем приветствие
      await telegramBot.sendMessage(
        chatId: chatId,
        text: '''
🎉 <b>Добро пожаловать в TimeToTravel!</b>

Вы успешно авторизовались!

Теперь можете вернуться в приложение и начать пользоваться сервисом.

👉 Закройте Telegram и откройте приложение
''',
      );
    } else {
      // Обычный /start без параметров
      final greeting = user.isDispatcher
          ? '''
👋 Здравствуйте, <b>${user.fullName}</b>!

Вы зашли как <b>Диспетчер</b>.

📱 Откройте приложение Time To Travel для управления заказами.
'''
          : '''
👋 Здравствуйте, <b>${user.fullName}</b>!

Добро пожаловать в TimeToTravel!

🚗 Откройте приложение для бронирования поездок.
''';

      await telegramBot.sendMessage(chatId: chatId, text: greeting);
    }
  } catch (e) {
    _log.severe('❌ Ошибка обработки /start: $e');
    
    await telegramBot.sendMessage(
      chatId: chatId,
      text: '❌ Произошла ошибка. Попробуйте позже.',
    );
  }
}
