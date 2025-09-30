import 'package:flutter/foundation.dart';
import '../models/booking.dart';

/// Сервис для управления push-уведомлениями
class NotificationService {
  static const NotificationService _instance = NotificationService._internal();
  
  const NotificationService._internal();
  
  static const NotificationService instance = _instance;

  /// Инициализация сервиса уведомлений
  Future<bool> initialize() async {
    try {
      // В реальном приложении здесь будет инициализация Firebase Messaging
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('🔔 Сервис уведомлений инициализирован');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка инициализации уведомлений: $e');
      return false;
    }
  }

  /// Запрос разрешения на отправку уведомлений
  Future<bool> requestPermission() async {
    try {
      // В реальном приложении здесь запрос разрешений
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('🔔 Разрешение на уведомления получено');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка запроса разрешения на уведомления: $e');
      return false;
    }
  }

  /// Получение FCM токена
  Future<String?> getFCMToken() async {
    try {
      // В реальном приложении здесь получение FCM токена
      await Future.delayed(const Duration(milliseconds: 200));
      final token = 'fcm_token_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('🔔 FCM токен получен: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Ошибка получения FCM токена: $e');
      return null;
    }
  }

  /// Планирование напоминания за 24 часа до поездки
  Future<bool> schedule24HourReminder(Booking booking) async {
    try {
      final reminderTime = booking.departureTime.subtract(const Duration(hours: 24));
      
      // Проверяем, что время напоминания в будущем
      if (reminderTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Время напоминания в прошлом, пропускаем');
        return false;
      }

      final notification = NotificationData(
        id: '${booking.id}_24h',
        title: 'Напоминание о поездке',
        body: 'Завтра в ${_formatTime(booking.departureTime)} у вас поездка ${booking.fromLocation} → ${booking.toLocation}',
        scheduledTime: reminderTime,
        type: NotificationType.tripReminder24h,
        bookingId: booking.id,
      );

      return await _scheduleNotification(notification);
    } catch (e) {
      debugPrint('❌ Ошибка планирования напоминания 24ч: $e');
      return false;
    }
  }

  /// Планирование напоминания за 1 час до поездки
  Future<bool> schedule1HourReminder(Booking booking) async {
    try {
      final reminderTime = booking.departureTime.subtract(const Duration(hours: 1));
      
      // Проверяем, что время напоминания в будущем
      if (reminderTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Время напоминания в прошлом, пропускаем');
        return false;
      }

      final notification = NotificationData(
        id: '${booking.id}_1h',
        title: 'Поездка через час!',
        body: 'Через час отправление: ${booking.fromLocation} → ${booking.toLocation}. Подготовьтесь к поездке.',
        scheduledTime: reminderTime,
        type: NotificationType.tripReminder1h,
        bookingId: booking.id,
      );

      return await _scheduleNotification(notification);
    } catch (e) {
      debugPrint('❌ Ошибка планирования напоминания 1ч: $e');
      return false;
    }
  }

  /// Отправка уведомления о подтверждении бронирования
  Future<bool> sendBookingConfirmation(Booking booking) async {
    try {
      final notification = NotificationData(
        id: '${booking.id}_confirmed',
        title: 'Бронирование подтверждено',
        body: 'Ваша поездка ${booking.fromLocation} → ${booking.toLocation} на ${_formatDate(booking.departureTime)} подтверждена',
        type: NotificationType.bookingConfirmed,
        bookingId: booking.id,
      );

      return await _sendImmediateNotification(notification);
    } catch (e) {
      debugPrint('❌ Ошибка отправки подтверждения бронирования: $e');
      return false;
    }
  }

  /// Отправка уведомления об отмене бронирования
  Future<bool> sendBookingCancellation(Booking booking, String reason) async {
    try {
      final notification = NotificationData(
        id: '${booking.id}_cancelled',
        title: 'Бронирование отменено',
        body: 'Поездка ${booking.fromLocation} → ${booking.toLocation} отменена. Причина: $reason',
        type: NotificationType.bookingCancelled,
        bookingId: booking.id,
      );

      return await _sendImmediateNotification(notification);
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления об отмене: $e');
      return false;
    }
  }

  /// Отправка уведомления о назначении водителя
  Future<bool> sendDriverAssigned(Booking booking, String driverName, String driverPhone) async {
    try {
      final notification = NotificationData(
        id: '${booking.id}_driver',
        title: 'Водитель назначен',
        body: 'Водитель $driverName (тел. $driverPhone) назначен на вашу поездку',
        type: NotificationType.driverAssigned,
        bookingId: booking.id,
        data: {
          'driverName': driverName,
          'driverPhone': driverPhone,
        },
      );

      return await _sendImmediateNotification(notification);
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления о водителе: $e');
      return false;
    }
  }

  /// Отправка уведомления о изменении времени поездки
  Future<bool> sendTimeChanged(Booking booking, DateTime newTime) async {
    try {
      final notification = NotificationData(
        id: '${booking.id}_time_changed',
        title: 'Время поездки изменено',
        body: 'Новое время отправления: ${_formatDateTime(newTime)}',
        type: NotificationType.timeChanged,
        bookingId: booking.id,
        data: {
          'newTime': newTime.toIso8601String(),
        },
      );

      return await _sendImmediateNotification(notification);
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления об изменении времени: $e');
      return false;
    }
  }

  /// Отмена запланированных уведомлений для бронирования
  Future<bool> cancelBookingNotifications(String bookingId) async {
    try {
      final notificationIds = [
        '${bookingId}_24h',
        '${bookingId}_1h',
      ];

      for (final id in notificationIds) {
        await _cancelScheduledNotification(id);
      }

      debugPrint('🔔 Уведомления для заказа $bookingId отменены');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отмены уведомлений: $e');
      return false;
    }
  }

  /// Планирование уведомления
  Future<bool> _scheduleNotification(NotificationData notification) async {
    try {
      // В реальном приложении здесь планирование локального уведомления
      await Future.delayed(const Duration(milliseconds: 100));
      
      debugPrint('🔔 Уведомление запланировано: ${notification.title} на ${_formatDateTime(notification.scheduledTime!)}');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка планирования уведомления: $e');
      return false;
    }
  }

  /// Отправка немедленного уведомления
  Future<bool> _sendImmediateNotification(NotificationData notification) async {
    try {
      // В реальном приложении здесь отправка push уведомления
      await Future.delayed(const Duration(milliseconds: 100));
      
      debugPrint('🔔 Уведомление отправлено: ${notification.title}');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления: $e');
      return false;
    }
  }

  /// Отмена запланированного уведомления
  Future<bool> _cancelScheduledNotification(String notificationId) async {
    try {
      // В реальном приложении здесь отмена локального уведомления
      await Future.delayed(const Duration(milliseconds: 50));
      
      debugPrint('🔔 Уведомление $notificationId отменено');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отмены уведомления: $e');
      return false;
    }
  }

  /// Форматирование времени
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Форматирование даты
  String _formatDate(DateTime dateTime) {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]}';
  }

  /// Форматирование даты и времени
  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} в ${_formatTime(dateTime)}';
  }

  /// Получение всех запланированных уведомлений
  Future<List<NotificationData>> getScheduledNotifications() async {
    try {
      // В реальном приложении здесь получение списка из локальной базы
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Мок: возвращаем пустой список
      return [];
    } catch (e) {
      debugPrint('❌ Ошибка получения запланированных уведомлений: $e');
      return [];
    }
  }

  /// Планирование всех уведомлений для нового бронирования
  Future<bool> scheduleAllBookingNotifications(Booking booking) async {
    try {
      final results = await Future.wait([
        schedule24HourReminder(booking),
        schedule1HourReminder(booking),
      ]);

      final success = results.every((result) => result);
      debugPrint('🔔 Все уведомления для заказа ${booking.id} запланированы: $success');
      return success;
    } catch (e) {
      debugPrint('❌ Ошибка планирования всех уведомлений: $e');
      return false;
    }
  }
}

/// Данные уведомления
class NotificationData {
  final String id;
  final String title;
  final String body;
  final DateTime? scheduledTime;
  final NotificationType type;
  final String? bookingId;
  final Map<String, dynamic>? data;

  NotificationData({
    required this.id,
    required this.title,
    required this.body,
    this.scheduledTime,
    required this.type,
    this.bookingId,
    this.data,
  });

  @override
  String toString() {
    return 'NotificationData(id: $id, title: $title, type: $type, scheduledTime: $scheduledTime)';
  }
}

/// Типы уведомлений
enum NotificationType {
  tripReminder24h,
  tripReminder1h,
  bookingConfirmed,
  bookingCancelled,
  driverAssigned,
  timeChanged,
  tripStarted,
  tripCompleted,
}
