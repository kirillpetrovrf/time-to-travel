import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/services/telegram_bot_service.dart';
import 'package:backend/utils/jwt_helper.dart';

// 🔥 ГЛОБАЛЬНЫЕ SINGLETON СЕРВИСЫ - инициализируются ОДИН РАЗ
DatabaseService? _globalDbService;
JwtHelper? _globalJwtHelper;
TelegramBotService? _globalTelegramBot;
bool _isInitialized = false;

/// Middleware для предоставления DatabaseService, JwtHelper и TelegramBotService во все routes
Handler middleware(Handler handler) {
  return (context) async {
    // ✅ ИНИЦИАЛИЗАЦИЯ ОДИН РАЗ при первом запросе
    if (!_isInitialized) {
      print('🚀 [MIDDLEWARE] Первая инициализация глобальных сервисов...');
      
      // Создаем DatabaseService ОДИН РАЗ
      _globalDbService = DatabaseService.fromEnv(Platform.environment);
      
      // Инициализируем подключение ОДИН РАЗ
      try {
        await _globalDbService!.initialize();
        print('✅ [MIDDLEWARE] DatabaseService инициализирован');
      } catch (e) {
        print('❌ [MIDDLEWARE] Failed to initialize database: $e');
        // В production можно вернуть 503 Service Unavailable
      }

      // Создаем JwtHelper ОДИН РАЗ
      _globalJwtHelper = JwtHelper.fromEnv(Platform.environment);
      print('✅ [MIDDLEWARE] JwtHelper инициализирован');

      // Создаем TelegramBotService ОДИН РАЗ
      final telegramToken = Platform.environment['TELEGRAM_BOT_TOKEN'];
      if (telegramToken == null || telegramToken.isEmpty) {
        print('⚠️ [MIDDLEWARE] TELEGRAM_BOT_TOKEN не установлен!');
      }
      _globalTelegramBot = TelegramBotService(botToken: telegramToken ?? '');
      print('✅ [MIDDLEWARE] TelegramBotService инициализирован');

      _isInitialized = true;
      print('🎉 [MIDDLEWARE] Все глобальные сервисы готовы к работе!');
    }

    // ✅ ПЕРЕИСПОЛЬЗУЕМ уже инициализированные сервисы
    final response = await handler(
      context
          .provide<DatabaseService>(() => _globalDbService!)
          .provide<JwtHelper>(() => _globalJwtHelper!)
          .provide<TelegramBotService>(() => _globalTelegramBot!),
    );

    return response;
  };
}
