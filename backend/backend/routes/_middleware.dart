import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/services/telegram_bot_service.dart';
import 'package:backend/utils/jwt_helper.dart';

/// Middleware для предоставления DatabaseService, JwtHelper и TelegramBotService во все routes
Handler middleware(Handler handler) {
  return (context) async {
    // Создаем DatabaseService из environment variables
    final dbService = DatabaseService.fromEnv(
      Platform.environment,
    );

    // Инициализируем подключение
    try {
      await dbService.initialize();
    } catch (e) {
      print('❌ Failed to initialize database: $e');
      // В production можно вернуть 503 Service Unavailable
    }

    // Создаем JwtHelper
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Создаем TelegramBotService
    final telegramToken = Platform.environment['TELEGRAM_BOT_TOKEN'];
    if (telegramToken == null || telegramToken.isEmpty) {
      print('⚠️ TELEGRAM_BOT_TOKEN не установлен!');
    }
    final telegramBot = TelegramBotService(botToken: telegramToken ?? '');

    // Предоставляем все сервисы в контекст
    final response = await handler(
      context
          .provide<DatabaseService>(() => dbService)
          .provide<JwtHelper>(() => jwtHelper)
          .provide<TelegramBotService>(() => telegramBot),
    );

    return response;
  };
}
