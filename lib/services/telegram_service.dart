import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/booking.dart';
import '../models/user.dart';
import '../models/route_stop.dart';

/// Сервис для отправки уведомлений в Telegram
class TelegramService {
  static const TelegramService _instance = TelegramService._internal();

  const TelegramService._internal();

  static const TelegramService instance = _instance;

  // TODO: Заменить на реальные данные бота
  // Получить токен: https://t.me/BotFather
  // Получить chat_id: https://t.me/userinfobot или https://api.telegram.org/bot<TOKEN>/getUpdates
  static const String _botToken = '7934029372:AAEh68fQpOzU1EjJAHNvyZeNnbsqd9BxVDo'; // TODO: Заменить на реальный
  static const String _chatId = '878334685'; // TODO: Заменить на реальный ID чата диспетчеров

  // Telegram Bot API endpoint
  static const String _telegramApiUrl = 'https://api.telegram.org';

  /// Отправка уведомления о новом заказе
  Future<bool> sendNewBookingNotification(Booking booking, AppUser user) async {
    try {
      final message = _formatNewBookingMessage(booking, user);
      return await _sendMessage(message);
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления о новом заказе: $e');
      return false;
    }
  }

  /// Отправка уведомления об изменении заказа
  Future<bool> sendBookingUpdateNotification(
    Booking booking,
    String changeDescription,
  ) async {
    try {
      final message = _formatBookingUpdateMessage(booking, changeDescription);
      return await _sendMessage(message);
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления об изменении заказа: $e');
      return false;
    }
  }

  /// Отправка уведомления об отмене заказа
  Future<bool> sendBookingCancellationNotification(
    Booking booking,
    String reason,
  ) async {
    try {
      final message = _formatBookingCancellationMessage(booking, reason);
      return await _sendMessage(message);
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления об отмене заказа: $e');
      return false;
    }
  }

  /// Отправка напоминания о поездке (за 24 часа)
  Future<bool> sendTripReminder24h(Booking booking) async {
    try {
      final message = _formatTripReminderMessage(booking, '24 часа');
      return await _sendMessage(message);
    } catch (e) {
      debugPrint('❌ Ошибка отправки напоминания за 24ч: $e');
      return false;
    }
  }

  /// Отправка напоминания о поездке (за 1 час)
  Future<bool> sendTripReminder1h(Booking booking) async {
    try {
      final message = _formatTripReminderMessage(booking, '1 час');
      return await _sendMessage(message);
    } catch (e) {
      debugPrint('❌ Ошибка отправки напоминания за 1ч: $e');
      return false;
    }
  }

  /// Отправка уведомления о назначении водителя
  Future<bool> sendDriverAssignedNotification(
    Booking booking,
    String driverName,
    String driverPhone,
  ) async {
    try {
      final message = _formatDriverAssignedMessage(
        booking,
        driverName,
        driverPhone,
      );
      return await _sendMessage(message);
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления о водителе: $e');
      return false;
    }
  }

  /// Отправка сообщения в Telegram
  Future<bool> _sendMessage(String message) async {
    if (_botToken.contains('TODO') || _chatId.contains('TODO')) {
      debugPrint('⚠️ Telegram bot не настроен. Используется мок-режим.');
      debugPrint('📱 Сообщение для Telegram:\n$message');
      return true; // Мок режим - всегда успешно
    }

    try {
      final url = Uri.parse(
        '$_telegramApiUrl/bot$_botToken/sendMessage',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'chat_id': _chatId,
          'text': message,
          'parse_mode': 'HTML', // Поддержка HTML форматирования
          'disable_web_page_preview': true,
        }),
      ).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final ok = responseData['ok'] as bool? ?? false;

        if (ok) {
          debugPrint('✅ Сообщение успешно отправлено в Telegram');
          return true;
        } else {
          final errorDescription =
              responseData['description'] as String? ?? 'Unknown error';
          debugPrint('❌ Telegram API error: $errorDescription');
          return false;
        }
      } else {
        debugPrint(
          '❌ HTTP error ${response.statusCode}: ${response.body}',
        );
        return false;
      }
    } catch (e) {
      debugPrint('❌ Ошибка отправки сообщения в Telegram: $e');
      return false;
    }
  }

  /// Форматирование сообщения о новом заказе
  String _formatNewBookingMessage(Booking booking, AppUser user) {
    final emoji = booking.tripType == TripType.group ? '👥' : '🚗';
    final tripTypeText = booking.tripType == TripType.group
        ? 'Групповая'
        : 'Индивидуальная';

    return '''
$emoji <b>НОВЫЙ ЗАКАЗ</b>

🎫 <b>Заказ:</b> ${booking.id}
👤 <b>Клиент:</b> ${user.displayName}
📞 <b>Телефон:</b> ${user.phoneNumber}

🚌 <b>Тип:</b> $tripTypeText поездка
📍 <b>Маршрут:</b> ${booking.fromLocation} → ${booking.toLocation}
📅 <b>Дата:</b> ${_formatDate(booking.departureTime)}
🕐 <b>Время:</b> ${_formatTime(booking.departureTime)}

💰 <b>Стоимость:</b> ${booking.totalPrice.toInt()} ₽
${booking.passengerCount > 1 ? '👥 <b>Пассажиров:</b> ${booking.passengerCount}\n' : ''}
${booking.notes?.isNotEmpty == true ? '📝 <b>Примечания:</b> ${booking.notes}\n' : ''}

⏰ <i>Заказ создан: ${_formatDateTime(DateTime.now())}</i>
''';
  }

  /// Форматирование сообщения об изменении заказа
  String _formatBookingUpdateMessage(
    Booking booking,
    String changeDescription,
  ) {
    return '''
✏️ <b>ИЗМЕНЕНИЕ ЗАКАЗА</b>

🎫 <b>Заказ:</b> ${booking.id}
📍 <b>Маршрут:</b> ${booking.fromLocation} → ${booking.toLocation}
📅 <b>Дата:</b> ${_formatDate(booking.departureTime)}

🔄 <b>Изменения:</b> $changeDescription

⏰ <i>Изменено: ${_formatDateTime(DateTime.now())}</i>
''';
  }

  /// Форматирование сообщения об отмене заказа
  String _formatBookingCancellationMessage(Booking booking, String reason) {
    return '''
❌ <b>ОТМЕНА ЗАКАЗА</b>

🎫 <b>Заказ:</b> ${booking.id}
📍 <b>Маршрут:</b> ${booking.fromLocation} → ${booking.toLocation}
📅 <b>Дата:</b> ${_formatDate(booking.departureTime)}

🚫 <b>Причина отмены:</b> $reason

⏰ <i>Отменён: ${_formatDateTime(DateTime.now())}</i>
''';
  }

  /// Форматирование напоминания о поездке
  String _formatTripReminderMessage(Booking booking, String timeUntil) {
    final emoji = booking.tripType == TripType.group ? '👥' : '🚗';

    return '''
⏰ <b>НАПОМИНАНИЕ О ПОЕЗДКЕ</b>

$emoji <b>До отправления:</b> $timeUntil

🎫 <b>Заказ:</b> ${booking.id}
📍 <b>Маршрут:</b> ${booking.fromLocation} → ${booking.toLocation}
📅 <b>Дата:</b> ${_formatDate(booking.departureTime)}
🕐 <b>Время:</b> ${_formatTime(booking.departureTime)}

💰 <b>Стоимость:</b> ${booking.totalPrice.toInt()} ₽
${booking.passengerCount > 1 ? '👥 <b>Пассажиров:</b> ${booking.passengerCount}\n' : ''}

📞 <b>Связаться с клиентом:</b> ${booking.contactPhone ?? 'Не указан'}
''';
  }

  /// Форматирование сообщения о назначении водителя
  String _formatDriverAssignedMessage(
    Booking booking,
    String driverName,
    String driverPhone,
  ) {
    return '''
🚗 <b>ВОДИТЕЛЬ НАЗНАЧЕН</b>

🎫 <b>Заказ:</b> ${booking.id}
📍 <b>Маршрут:</b> ${booking.fromLocation} → ${booking.toLocation}
📅 <b>Дата:</b> ${_formatDate(booking.departureTime)}

👨‍💼 <b>Водитель:</b> $driverName
📞 <b>Телефон водителя:</b> $driverPhone

⏰ <i>Назначен: ${_formatDateTime(DateTime.now())}</i>
''';
  }

  /// Форматирование даты
  String _formatDate(DateTime dateTime) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  /// Форматирование времени
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Форматирование даты и времени
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} в ${_formatTime(dateTime)}';
  }

  /// Отправка произвольного сообщения (для администраторов)
  Future<bool> sendCustomMessage(String message) async {
    try {
      return await _sendMessage(message);
    } catch (e) {
      debugPrint('❌ Ошибка отправки произвольного сообщения: $e');
      return false;
    }
  }

  /// Тестирование подключения к боту
  Future<bool> testConnection() async {
    try {
      const testMessage =
          '''
🤖 <b>ТЕСТ ПОДКЛЮЧЕНИЯ</b>

✅ Бот "Time to Travel" работает корректно
⏰ Время тестирования: ${_formatDateTime}

🔧 Все системы уведомлений функционируют
''';

      return await _sendMessage(testMessage);
    } catch (e) {
      debugPrint('❌ Ошибка тестирования подключения: $e');
      return false;
    }
  }

  /// Форматирование текущего времени для тестов
  String get _formatDateTime {
    final now = DateTime.now();
    return '${_formatDate(now)} в ${_formatTime(now)}';
  }

  /// Отправка статистики за день
  Future<bool> sendDailyStats({
    required int totalBookings,
    required int groupBookings,
    required int individualBookings,
    required double totalRevenue,
    required int cancelledBookings,
  }) async {
    try {
      final message =
          '''
📊 <b>СТАТИСТИКА ЗА ДЕНЬ</b>

📅 <b>Дата:</b> ${_formatDate(DateTime.now())}

📈 <b>Общие показатели:</b>
• Всего заказов: $totalBookings
• Групповые поездки: $groupBookings
• Индивидуальные: $individualBookings
• Отменённые: $cancelledBookings

💰 <b>Выручка:</b> ${totalRevenue.toInt()} ₽

📊 <b>Конверсия:</b> ${((totalBookings - cancelledBookings) / totalBookings * 100).toStringAsFixed(1)}%

⏰ <i>Отчёт сформирован: ${_formatTime(DateTime.now())}</i>
''';

      return await _sendMessage(message);
    } catch (e) {
      debugPrint('❌ Ошибка отправки статистики: $e');
      return false;
    }
  }
}
