import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';

/// Middleware для предоставления DatabaseService во все routes
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

    // Предоставляем сервис в контекст
    final response = await handler(
      context.provide<DatabaseService>(() => dbService),
    );

    return response;
  };
}
