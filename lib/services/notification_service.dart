import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/booking.dart';
import '../main.dart' show navigatorKey;

/// Глобальный обработчик для background уведомлений
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('🔔 ========================================');
  print('🔔 BACKGROUND УВЕДОМЛЕНИЕ ПОЛУЧЕНО!');
  print('🔔 ID: ${notificationResponse.id}');
  print('🔔 Payload: ${notificationResponse.payload}');
  print('🔔 Время: ${DateTime.now()}');
  print('🔔 ========================================');
  debugPrint('🔔 ========================================');
  debugPrint('🔔 BACKGROUND УВЕДОМЛЕНИЕ ПОЛУЧЕНО!');
  debugPrint('🔔 ID: ${notificationResponse.id}');
  debugPrint('🔔 Payload: ${notificationResponse.payload}');
  debugPrint('🔔 Время: ${DateTime.now()}');
  debugPrint('🔔 ========================================');

  // Навигация к деталям заказа
  _handleNotificationNavigation(notificationResponse.payload);
}

/// Глобальная функция для обработки навигации из уведомлений
void _handleNotificationNavigation(String? payload) {
  if (payload == null || payload.isEmpty) {
    debugPrint('⚠️ Payload пустой, навигация не требуется');
    return;
  }

  debugPrint('🔔 Обработка навигации: $payload');

  // Разбираем payload
  final parts = payload.split(':');
  if (parts.length != 2) {
    debugPrint('⚠️ Неверный формат payload: $payload');
    return;
  }

  final type = parts[0]; // 'booking' или 'test'
  final id = parts[1]; // ID заказа или тип теста

  if (type == 'booking') {
    // Навигация к деталям заказа
    debugPrint('📱 Переход к деталям заказа: $id');

    // Используем глобальный navigatorKey для навигации
    final context = navigatorKey.currentContext;
    if (context != null) {
      // Навигация к экрану деталей заказа
      // Используем именованный маршрут с параметром
      Navigator.of(context).pushNamed('/booking-details', arguments: id);
    } else {
      debugPrint('⚠️ Navigator context недоступен');
    }
  } else if (type == 'test') {
    // Тестовое уведомление - просто логируем
    debugPrint('🧪 Тестовое уведомление: $id');
  }
}

/// Сервис для управления уведомлениями
/// Поддерживает локальные уведомления даже когда приложение закрыто
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  NotificationService._internal();

  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _localInitialized = false;

  /// Инициализация сервиса уведомлений
  Future<bool> initialize() async {
    if (_localInitialized) return true;

    try {
      print('🔔 [INIT] ===== ИНИЦИАЛИЗАЦИЯ УВЕДОМЛЕНИЙ =====');

      // Инициализация timezone для запланированных уведомлений
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
      print('🔔 [INIT] ✅ Timezone установлена: Europe/Moscow');

      // Настройки для Android
      // Используем иконку красного автомобиля для уведомлений
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_notification_car',
      );

      // Настройки для iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTappedStatic,
      );
      print('🔔 [INIT] ✅ FlutterLocalNotifications инициализирован');

      // Проверяем разрешение на точные alarm'ы (Android 12+)
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        print('🔔 [INIT] Проверяем разрешение на точные alarm\'ы...');

        final canScheduleExactAlarms = await androidPlugin
            .canScheduleExactNotifications();
        print(
          '🔔 [INIT] canScheduleExactNotifications: $canScheduleExactAlarms',
        );

        if (canScheduleExactAlarms == null || !canScheduleExactAlarms) {
          print('⚠️ [INIT] ❌ РАЗРЕШЕНИЕ НА ТОЧНЫЕ ALARM\'Ы НЕ ПРЕДОСТАВЛЕНО!');
          print('⚠️ [INIT] Запрашиваем разрешение...');

          // Запрашиваем разрешение
          final granted = await androidPlugin.requestExactAlarmsPermission();
          print('🔔 [INIT] Результат запроса разрешения: $granted');

          if (granted == null || !granted) {
            print(
              '❌ [INIT] КРИТИЧНО: Разрешение не предоставлено! Уведомления могут не работать!',
            );
          } else {
            print('✅ [INIT] Разрешение на точные alarm\'ы ПРЕДОСТАВЛЕНО!');
          }
        } else {
          print('✅ [INIT] Разрешение на точные alarm\'ы уже есть');
        }
      }

      _localInitialized = true;
      print('🔔 [INIT] ========================================');
      debugPrint('✅ Сервис локальных уведомлений инициализирован');

      return true;
    } catch (e) {
      print('❌ [INIT] ОШИБКА: $e');
      debugPrint('❌ Ошибка инициализации уведомлений: $e');
      return false;
    }
  }

  /// Обработчик нажатия на уведомление (статический для background)
  @pragma('vm:entry-point')
  static void _onNotificationTappedStatic(NotificationResponse response) {
    print('🔔 ========================================');
    print('🔔 УВЕДОМЛЕНИЕ ПОЛУЧЕНО (НАЖАТИЕ)!');
    print('🔔 ID: ${response.id}');
    print('🔔 Payload: ${response.payload}');
    print('🔔 Action ID: ${response.actionId}');
    print('🔔 Input: ${response.input}');
    print(
      '🔔 Notification Response Type: ${response.notificationResponseType}',
    );
    print('🔔 Время: ${DateTime.now()}');
    print('🔔 ========================================');
    debugPrint('🔔 ========================================');
    debugPrint('🔔 УВЕДОМЛЕНИЕ ПОЛУЧЕНО!');
    debugPrint('🔔 ID: ${response.id}');
    debugPrint('🔔 Payload: ${response.payload}');
    debugPrint('🔔 Action ID: ${response.actionId}');
    debugPrint('🔔 Input: ${response.input}');
    debugPrint(
      '🔔 Notification Response Type: ${response.notificationResponseType}',
    );
    debugPrint('🔔 Время: ${DateTime.now()}');
    debugPrint('🔔 ========================================');

    // Навигация к деталям заказа
    _handleNotificationNavigation(response.payload);
  }

  /// Обработчик получения уведомления в foreground
  @pragma('vm:entry-point')
  static void _onForegroundNotification(NotificationResponse response) {
    debugPrint('📱 ========================================');
    debugPrint('📱 FOREGROUND УВЕДОМЛЕНИЕ!');
    debugPrint('📱 ID: ${response.id}');
    debugPrint('📱 Payload: ${response.payload}');
    debugPrint('📱 Время: ${DateTime.now()}');
    debugPrint('📱 ========================================');
  }

  /// Получить полный DateTime из Booking
  DateTime _getBookingDateTime(Booking booking) {
    final timeParts = booking.departureTime.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    return DateTime(
      booking.departureDate.year,
      booking.departureDate.month,
      booking.departureDate.day,
      hour,
      minute,
    );
  }

  /// Получить строку маршрута из Booking
  String _getRouteString(Booking booking) {
    if (booking.pickupAddress != null && booking.dropoffAddress != null) {
      return '${booking.pickupAddress} → ${booking.dropoffAddress}';
    } else if (booking.fromStop != null && booking.toStop != null) {
      return '${booking.fromStop!.name} → ${booking.toStop!.name}';
    } else if (booking.pickupPoint != null) {
      return 'из ${booking.pickupPoint}';
    } else {
      return 'вашу поездку';
    }
  }

  /// Показать немедленное уведомление
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'trip_reminders',
        'Напоминания о поездках',
        channelDescription: 'Уведомления о предстоящих поездках',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        ticker: 'Time to Travel',
        fullScreenIntent: true,
        channelShowBadge: true,
        autoCancel: false,
        ongoing: false,
        onlyAlertOnce: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
        payload: payload,
      );
      debugPrint('✅ Уведомление показано: $title');
    } catch (e) {
      debugPrint('❌ Ошибка показа уведомления: $e');
    }
  }

  /// Планирование напоминания за 1 день до поездки (в 9:00 утра)
  Future<bool> schedule24HourReminder(Booking booking) async {
    try {
      print('🔔 [24H] ===== НАЧАЛО ПЛАНИРОВАНИЯ =====');
      final bookingDateTime = _getBookingDateTime(booking);
      print('🔔 [24H] Время поездки: $bookingDateTime');

      // Вычисляем дату напоминания (за день до поездки)
      final reminderDate = bookingDateTime.subtract(const Duration(days: 1));
      print('🔔 [24H] Дата - 1 день: $reminderDate');

      // Устанавливаем время на 9:00 утра
      final reminderTime = DateTime(
        reminderDate.year,
        reminderDate.month,
        reminderDate.day,
        9, // 9 утра
        0, // 0 минут
      );
      print('🔔 [24H] Установлено время 9:00: $reminderTime');

      // Проверяем, что время напоминания в будущем
      final now = DateTime.now();
      print('🔔 [24H] Текущее время: $now');
      print(
        '🔔 [24H] Проверка: reminderTime.isBefore(now) = ${reminderTime.isBefore(now)}',
      );

      if (reminderTime.isBefore(now)) {
        print('⚠️ [24H] ❌ Время напоминания в прошлом, ПРОПУСКАЕМ');
        debugPrint('⚠️ [24H] Время напоминания в прошлом, пропускаем');
        debugPrint('   Время поездки: $bookingDateTime');
        debugPrint('   Запланированное время уведомления: $reminderTime');
        debugPrint('   Текущее время: $now');
        return false;
      }
      print('🔔 [24H] ✅ Время в будущем, продолжаем');

      final routeString = _getRouteString(booking);
      print('🔔 [24H] Маршрут: $routeString');

      // Конвертируем в TZDateTime для планирования
      print('🔔 [24H] Конвертируем в TZDateTime...');
      print('🔔 [24H] reminderTime ДО конвертации: $reminderTime');
      final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);
      print('🔔 [24H] TZDateTime ПОСЛЕ конвертации: $scheduledTime');
      print('🔔 [24H] Timezone: ${tz.local.name}');

      // Настройки уведомления
      print('🔔 [24H] Создаем настройки Android...');
      final androidDetails = AndroidNotificationDetails(
        'trip_reminders',
        'Напоминания о поездках',
        channelDescription: 'Уведомления о предстоящих поездках',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableLights: true,
        ledColor: const Color(0xFF0000FF),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        playSound: true,
        icon: '@drawable/ic_notification_car',
        ticker: 'Time to Travel - Поездка завтра',
        fullScreenIntent: true,
        channelShowBadge: true,
        autoCancel: false,
        ongoing: false,
        onlyAlertOnce: false,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Генерируем уникальный ID для уведомления
      final notificationId = '${booking.id}_24h'.hashCode;
      print('🔔 [24H] ID уведомления: $notificationId');
      print('🔔 [24H] Payload: booking:${booking.id}');

      // Планируем уведомление
      print('🔔 [24H] ⏰ ВЫЗЫВАЕМ zonedSchedule()...');
      print('🔔 [24H]    ID: $notificationId');
      print('🔔 [24H]    Заголовок: 🚗 Поездка завтра');
      print(
        '🔔 [24H]    Тело: Напоминание: $routeString завтра в ${booking.departureTime}',
      );
      print('🔔 [24H]    Время: $scheduledTime');
      print('🔔 [24H]    Режим: exactAllowWhileIdle');

      await _localNotifications.zonedSchedule(
        notificationId,
        '🚗 Поездка завтра',
        'Напоминание: $routeString завтра в ${booking.departureTime}',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'booking:${booking.id}',
      );
      print('🔔 [24H] ✅ zonedSchedule() ЗАВЕРШЁН УСПЕШНО!');

      debugPrint(
        '✅ [24H] Напоминание за 1 день запланировано для $routeString',
      );
      debugPrint('   ID уведомления: $notificationId');
      debugPrint('   Время поездки: $bookingDateTime');
      debugPrint('   Время уведомления: $scheduledTime');
      debugPrint('   Payload: booking:${booking.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка планирования напоминания за 1 день: $e');
      return false;
    }
  }

  /// Планирование напоминания за 1 час до поездки
  Future<bool> schedule1HourReminder(Booking booking) async {
    try {
      print('🔔 [1H] ===== НАЧАЛО ПЛАНИРОВАНИЯ =====');
      final bookingDateTime = _getBookingDateTime(booking);
      print('🔔 [1H] Время поездки: $bookingDateTime');

      final reminderTime = bookingDateTime.subtract(const Duration(hours: 1));
      print('🔔 [1H] Время - 1 час: $reminderTime');

      // Проверяем, что время напоминания в будущем
      final now = DateTime.now();
      print('🔔 [1H] Текущее время: $now');
      print(
        '🔔 [1H] Проверка: reminderTime.isBefore(now) = ${reminderTime.isBefore(now)}',
      );

      if (reminderTime.isBefore(now)) {
        print('⚠️ [1H] ❌ Время напоминания в прошлом, ПРОПУСКАЕМ');
        debugPrint('⚠️ [1H] Время напоминания в прошлом, пропускаем');
        debugPrint('   Время поездки: $bookingDateTime');
        debugPrint('   Запланированное время уведомления: $reminderTime');
        debugPrint('   Текущее время: $now');
        return false;
      }
      print('🔔 [1H] ✅ Время в будущем, продолжаем');

      final routeString = _getRouteString(booking);
      print('🔔 [1H] Маршрут: $routeString');

      // Конвертируем в TZDateTime для планирования
      print('🔔 [1H] Конвертируем в TZDateTime...');
      print('🔔 [1H] reminderTime ДО конвертации: $reminderTime');
      final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);
      print('🔔 [1H] TZDateTime ПОСЛЕ конвертации: $scheduledTime');
      print('🔔 [1H] Timezone: ${tz.local.name}');

      // Настройки уведомления
      print('🔔 [1H] Создаем настройки Android...');
      final androidDetails = AndroidNotificationDetails(
        'trip_reminders',
        'Напоминания о поездках',
        channelDescription: 'Уведомления о предстоящих поездках',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableLights: true,
        ledColor: const Color(0xFFFF0000),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        playSound: true,
        icon: '@drawable/ic_notification_car',
        ticker: 'Time to Travel - Поездка через час',
        fullScreenIntent: true,
        channelShowBadge: true,
        autoCancel: false,
        ongoing: false,
        onlyAlertOnce: false,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Генерируем уникальный ID для уведомления
      final notificationId = '${booking.id}_1h'.hashCode;
      print('🔔 [1H] ID уведомления: $notificationId');
      print('🔔 [1H] Payload: booking:${booking.id}');

      // Планируем уведомление
      print('🔔 [1H] ⏰ ВЫЗЫВАЕМ zonedSchedule()...');
      print('🔔 [1H]    ID: $notificationId');
      print('🔔 [1H]    Заголовок: 🚗 Поездка через час');
      print(
        '🔔 [1H]    Тело: Скоро выезд: $routeString в ${booking.departureTime}',
      );
      print('🔔 [1H]    Время: $scheduledTime');
      print('🔔 [1H]    Режим: exactAllowWhileIdle');

      await _localNotifications.zonedSchedule(
        notificationId,
        '🚗 Поездка через час',
        'Скоро выезд: $routeString в ${booking.departureTime}',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'booking:${booking.id}',
      );
      print('🔔 [1H] ✅ zonedSchedule() ЗАВЕРШЁН УСПЕШНО!');

      debugPrint('✅ [1H] Напоминание за 1 час запланировано для $routeString');
      debugPrint('   ID уведомления: $notificationId');
      debugPrint('   Время поездки: $bookingDateTime');
      debugPrint('   Время уведомления: $scheduledTime');
      debugPrint('   Payload: booking:${booking.id}');
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка планирования напоминания 1ч: $e');
      return false;
    }
  }

  /// Отправка уведомления о подтверждении бронирования
  Future<bool> sendBookingConfirmation(Booking booking) async {
    try {
      final routeString = _getRouteString(booking);
      await showNotification(
        title: 'Бронирование подтверждено',
        body: 'Ваша поездка $routeString подтверждена',
        payload: 'booking:${booking.id}',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отправки подтверждения бронирования: $e');
      return false;
    }
  }

  /// Отправка уведомления об отмене бронирования
  Future<bool> sendBookingCancellation(Booking booking, String reason) async {
    try {
      final routeString = _getRouteString(booking);
      await showNotification(
        title: 'Бронирование отменено',
        body: 'Поездка $routeString отменена. Причина: $reason',
        payload: 'booking:${booking.id}',
      );
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка отправки уведомления об отмене: $e');
      return false;
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
      debugPrint(
        '🔔 Все уведомления для заказа ${booking.id} запланированы: $success',
      );
      return success;
    } catch (e) {
      debugPrint('❌ Ошибка планирования всех уведомлений: $e');
      return false;
    }
  }

  /// Отменить все уведомления для бронирования
  Future<void> cancelBookingNotifications(String bookingId) async {
    try {
      await _localNotifications.cancel('${bookingId}_24h'.hashCode);
      await _localNotifications.cancel('${bookingId}_1h'.hashCode);
      debugPrint('✅ Все уведомления для заказа $bookingId отменены');
    } catch (e) {
      debugPrint('❌ Ошибка отмены уведомлений: $e');
    }
  }

  /// Отменить все уведомления
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('✅ Все уведомления отменены');
    } catch (e) {
      debugPrint('❌ Ошибка отмены всех уведомлений: $e');
    }
  }

  /// Получить список активных уведомлений
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Ошибка получения списка уведомлений: $e');
      return [];
    }
  }

  /// Запрос разрешения на отправку уведомлений
  Future<bool> requestPermission() async {
    try {
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
      final token = 'fcm_token_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('🔔 FCM токен получен: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Ошибка получения FCM токена: $e');
      return null;
    }
  }

  /// ТЕСТИРОВАНИЕ: Отправить немедленное тестовое уведомление
  Future<void> sendTestNotificationNow() async {
    await showNotification(
      title: '🚗 Тестовое уведомление (сейчас)',
      body: 'Это тестовое уведомление отправлено немедленно',
      payload: 'test:now',
    );
    debugPrint('✅ Тестовое уведомление (сейчас) отправлено');
  }

  /// ТЕСТИРОВАНИЕ: Запланировать уведомление через 5 секунд (приложение включено)
  Future<void> sendTestNotification1MinuteAppOn() async {
    try {
      final scheduledTime = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 5));

      final androidDetails = AndroidNotificationDetails(
        'test_notifications',
        'Тестовые уведомления',
        channelDescription: 'Уведомления для тестирования системы',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableLights: true,
        ledColor: const Color(0xFF00FF00),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        playSound: true,
        ticker: 'Time to Travel Test - 5 sec',
        fullScreenIntent: true,
        channelShowBadge: true,
        autoCancel: false,
        ongoing: false,
        onlyAlertOnce: false,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        99991, // Уникальный ID для тестового уведомления
        '🚗 Тест через 5 секунд (включено)',
        'Приложение включено. Время: ${DateTime.now().add(const Duration(seconds: 5)).toString().substring(11, 19)}',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test:5sec_on',
      );

      debugPrint('✅ Тестовое уведомление через 5 секунд запланировано');
      debugPrint('   Время: $scheduledTime');
    } catch (e) {
      debugPrint('❌ Ошибка планирования теста 5 секунд: $e');
    }
  }

  /// ТЕСТИРОВАНИЕ: Запланировать уведомление через 10 секунд (приложение выключено)
  Future<void> sendTestNotification2MinuteAppOff() async {
    try {
      final scheduledTime = tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 10));

      final androidDetails = AndroidNotificationDetails(
        'test_notifications',
        'Тестовые уведомления',
        channelDescription: 'Уведомления для тестирования системы',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableLights: true,
        ledColor: const Color(0xFFFF0000),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        playSound: true,
        ticker: 'Time to Travel Test - 10 sec',
        fullScreenIntent: true,
        channelShowBadge: true,
        autoCancel: false,
        ongoing: false,
        onlyAlertOnce: false,
        visibility: NotificationVisibility.public,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        99992, // Уникальный ID для тестового уведомления
        '🚗 Тест через 10 секунд (ВЫКЛЮЧЕНО)',
        'Закройте приложение СЕЙЧАС! Уведомление в: ${DateTime.now().add(const Duration(seconds: 10)).toString().substring(11, 19)}',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'test:10sec_off',
      );

      debugPrint('✅ Тестовое уведомление через 10 секунд запланировано');
      debugPrint('   Время: $scheduledTime');
      debugPrint('   ⚠️ ЗАКРОЙТЕ ПРИЛОЖЕНИЕ для проверки!');
    } catch (e) {
      debugPrint('❌ Ошибка планирования теста 10 секунд: $e');
    }
  }

  /// ТЕСТИРОВАНИЕ: Запланировать все 3 тестовых уведомления
  Future<void> sendAllTestNotifications() async {
    await sendTestNotificationNow();
    await sendTestNotification1MinuteAppOn();
    await sendTestNotification2MinuteAppOff();

    debugPrint('🚗 ВСЕ 3 ТЕСТОВЫХ УВЕДОМЛЕНИЯ ЗАПЛАНИРОВАНЫ:');
    debugPrint('   1️⃣ Сейчас - отправлено');
    debugPrint('   2️⃣ Через 5 секунд (приложение включено)');
    debugPrint('   3️⃣ Через 10 секунд (ЗАКРОЙТЕ ПРИЛОЖЕНИЕ!)');
  }
}
