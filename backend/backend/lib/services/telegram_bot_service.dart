import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

/// Сервис для работы с Telegram Bot API
class TelegramBotService {
  static final _log = Logger('TelegramBotService');
  
  final String botToken;
  final String baseUrl = 'https://api.telegram.org/bot';

  TelegramBotService({required this.botToken});

  /// Отправить сообщение пользователю
  Future<bool> sendMessage({
    required int chatId,
    required String text,
    String? parseMode = 'HTML',
  }) async {
    try {
      final url = Uri.parse('$baseUrl$botToken/sendMessage');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': chatId,
          'text': text,
          'parse_mode': parseMode,
        }),
      );

      if (response.statusCode == 200) {
        _log.info('✅ Сообщение отправлено в Telegram chat_id=$chatId');
        return true;
      } else {
        _log.warning('❌ Ошибка отправки: ${response.body}');
        return false;
      }
    } catch (e) {
      _log.severe('❌ Ошибка Telegram API: $e');
      return false;
    }
  }

  /// Получить информацию о пользователе
  Future<Map<String, dynamic>?> getChat(int chatId) async {
    try {
      final url = Uri.parse('$baseUrl$botToken/getChat?chat_id=$chatId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return data['result'] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      _log.severe('❌ Ошибка получения информации о чате: $e');
      return null;
    }
  }

  /// Установить webhook для получения обновлений
  Future<bool> setWebhook(String webhookUrl) async {
    try {
      final url = Uri.parse('$baseUrl$botToken/setWebhook');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': webhookUrl}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _log.info('✅ Webhook установлен: $webhookUrl');
        return data['ok'] == true;
      }
      return false;
    } catch (e) {
      _log.severe('❌ Ошибка установки webhook: $e');
      return false;
    }
  }

  /// Отправить уведомление о новом заказе
  Future<bool> notifyNewOrder({
    required int chatId,
    required String orderId,
    required String from,
    required String to,
    required String date,
    required String time,
    required double price,
    required String tripType,
  }) async {
    final tripTypeText = _getTripTypeText(tripType);
    
    final message = '''
🚗 <b>НОВЫЙ ЗАКАЗ!</b>

📋 Номер: <code>$orderId</code>
🎫 Тип: $tripTypeText

📍 <b>Откуда:</b> $from
📍 <b>Куда:</b> $to

📅 Дата: $date
🕐 Время: $time

💰 Стоимость: <b>${price.toStringAsFixed(0)} ₽</b>

👉 Откройте приложение для деталей
''';

    return sendMessage(chatId: chatId, text: message);
  }

  String _getTripTypeText(String tripType) {
    switch (tripType) {
      case 'group':
        return '🚌 Групповая поездка';
      case 'individual':
        return '🚗 Индивидуальный трансфер';
      case 'customRoute':
        return '🗺️ Свободный маршрут';
      default:
        return tripType;
    }
  }
}
