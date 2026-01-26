/// ⚠️ DEPRECATED: Этот файл больше не используется.
/// Уведомления Telegram теперь обрабатываются через PostgreSQL API (backend).
/// 
/// История:
/// - Старая версия отправляла уведомления напрямую из Flutter-приложения
/// - Новая архитектура: Flutter → PostgreSQL API → Backend Telegram Service
/// - Файл оставлен для справки, но весь код закомментирован
///
/// Миграция на PostgreSQL завершена. Файл можно удалить после финального тестирования.

// ВЕСЬ КОД НИЖЕ ЗАКОММЕНТИРОВАН - НЕ ИСПОЛЬЗУЕТСЯ

/*
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/booking.dart';
import '../models/user.dart';
import '../models/route_stop.dart';

class TelegramService {
  static const TelegramService _instance = TelegramService._internal();
  const TelegramService._internal();
  static const TelegramService instance = _instance;
  
  // ... ВСЕ 350+ СТРОК КОДА УДАЛЕНЫ ...
  // См. Git history для восстановления старой версии
}
*/
