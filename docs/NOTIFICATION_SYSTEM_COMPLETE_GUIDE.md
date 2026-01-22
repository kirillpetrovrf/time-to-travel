# 🔔 ПОЛНАЯ ИНСТРУКЦИЯ ПО ИНТЕГРАЦИИ СИСТЕМЫ УВЕДОМЛЕНИЙ

## 📋 ОГЛАВЛЕНИЕ
1. [Обзор системы](#обзор-системы)
2. [Зависимости (pubspec.yaml)](#зависимости)
3. [Android конфигурация](#android-конфигурация)
4. [iOS конфигурация](#ios-конфигурация)
5. [Главный файл main.dart](#главный-файл-maindart)
6. [Сервис уведомлений notification_service.dart](#сервис-уведомлений)
7. [Инициализация в SplashScreen](#инициализация-в-splashscreen)
8. [Использование в приложении](#использование-в-приложении)
9. [Чеклист интеграции](#чеклист-интеграции)

---

## 🎯 ОБЗОР СИСТЕМЫ

### Что делает система:
- ✅ Локальные push-уведомления (работают даже когда приложение ЗАКРЫТО)
- ✅ Планирование уведомлений на точное время (zonedSchedule)
- ✅ Напоминания за 24 часа и 1 час до события
- ✅ Навигация к экрану деталей при нажатии на уведомление
- ✅ Поддержка Android 12+ (точные будильники)
- ✅ Поддержка iOS
- ✅ Восстановление уведомлений после перезагрузки устройства

### Используемые пакеты:
- `flutter_local_notifications: ^18.0.1` - локальные уведомления
- `timezone: ^0.9.4` - работа с часовыми поясами для планирования

---

## 📦 ЗАВИСИМОСТИ

### Файл: `pubspec.yaml`

Добавить в секцию `dependencies`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # ========== УВЕДОМЛЕНИЯ ==========
  # Для локальных уведомлений (работают даже когда приложение закрыто)
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.4
```

После добавления выполнить:
```bash
flutter pub get
```

---

## 🤖 ANDROID КОНФИГУРАЦИЯ

### Файл: `android/app/src/main/AndroidManifest.xml`

#### 1. Добавить разрешения (ПЕРЕД тегом `<application>`):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    
    <!-- ========== РАЗРЕШЕНИЯ ДЛЯ УВЕДОМЛЕНИЙ ========== -->
    
    <!-- Разрешения для уведомлений (Android 13+) -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    
    <!-- Разрешения для точных уведомлений (для напоминаний) -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
    <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
    
    <!-- Разрешение на работу в фоновом режиме -->
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    
    <!-- ========== КОНЕЦ РАЗРЕШЕНИЙ ДЛЯ УВЕДОМЛЕНИЙ ========== -->
    
    <application
        ...
```

#### 2. Добавить receivers (ВНУТРИ тега `<application>`, ПОСЛЕ `<activity>`):

```xml
    <application
        android:label="YourAppName"
        ... >
        
        <activity ... >
            ...
        </activity>
        
        <!-- ========== RECEIVERS ДЛЯ УВЕДОМЛЕНИЙ ========== -->
        
        <!-- Receiver для перезагрузки устройства (восстановление уведомлений) -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
            </intent-filter>
        </receiver>
        
        <!-- Receiver для точных уведомлений -->
        <receiver
            android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"
            android:exported="false" />
        
        <!-- ========== КОНЕЦ RECEIVERS ДЛЯ УВЕДОМЛЕНИЙ ========== -->
        
    </application>
</manifest>
```

### Файл: `android/app/src/main/res/drawable/ic_notification.xml`

Создать иконку для уведомлений (ОБЯЗАТЕЛЬНО белая на прозрачном фоне):

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Иконка для уведомлений - ДОЛЖНА БЫТЬ БЕЛОЙ! -->
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    
    <!-- Белая иконка колокольчика (пример) -->
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M12,22c1.1,0 2,-0.9 2,-2h-4c0,1.1 0.9,2 2,2zM18,16v-5c0,-3.07 -1.63,-5.64 -4.5,-6.32V4c0,-0.83 -0.67,-1.5 -1.5,-1.5s-1.5,0.67 -1.5,1.5v0.68C7.64,5.36 6,7.92 6,11v5l-2,2v1h16v-1l-2,-2z"/>
</vector>
```

**ВАЖНО:** Иконка уведомления на Android ДОЛЖНА быть:
- Белого цвета (#FFFFFF)
- На прозрачном фоне
- В формате vector drawable
- Размер 24x24dp

---

## 🍎 iOS КОНФИГУРАЦИЯ

### Файл: `ios/Runner/Info.plist`

Для локальных уведомлений на iOS специальных настроек в Info.plist НЕ ТРЕБУЕТСЯ.
Разрешения запрашиваются программно через код.

**Опционально** (для background режима, если нужно):
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## 📱 ГЛАВНЫЙ ФАЙЛ main.dart

### Добавить глобальный NavigatorKey:

```dart
import 'package:flutter/material.dart'; // или cupertino

// ========== ГЛОБАЛЬНЫЙ КЛЮЧ ДЛЯ НАВИГАЦИИ ИЗ УВЕДОМЛЕНИЙ ==========
/// Этот ключ позволяет выполнять навигацию из любого места приложения,
/// включая обработчики уведомлений которые срабатывают в background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... другая инициализация ...
  
  runApp(const MyApp());
}
```

### Передать navigatorKey в MaterialApp/CupertinoApp:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ========== ВАЖНО: ПЕРЕДАЁМ NAVIGATOR KEY ==========
      navigatorKey: navigatorKey,
      
      title: 'Your App',
      home: const SplashScreen(),
      
      // ========== РОУТИНГ ДЛЯ НАВИГАЦИИ ИЗ УВЕДОМЛЕНИЙ ==========
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          
          // Этот роут нужен для навигации при нажатии на уведомление
          case '/booking-details':
            final bookingId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => BookingDetailScreen(bookingId: bookingId),
            );
          
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}
```

---

## 🔔 СЕРВИС УВЕДОМЛЕНИЙ

### Файл: `lib/services/notification_service.dart`

**ПОЛНЫЙ КОД СЕРВИСА (скопировать целиком):**

```dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

// ВАЖНО: Импортировать navigatorKey из main.dart
import '../main.dart' show navigatorKey;

// ============================================================
// ГЛОБАЛЬНЫЙ ОБРАБОТЧИК BACKGROUND УВЕДОМЛЕНИЙ
// ============================================================
// Эта функция ДОЛЖНА быть на верхнем уровне файла (не внутри класса)
// Аннотация @pragma обязательна для работы в background

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  debugPrint('🔔 BACKGROUND УВЕДОМЛЕНИЕ ПОЛУЧЕНО!');
  debugPrint('🔔 ID: ${notificationResponse.id}');
  debugPrint('🔔 Payload: ${notificationResponse.payload}');
  
  _handleNotificationNavigation(notificationResponse.payload);
}

/// Глобальная функция для обработки навигации из уведомлений
void _handleNotificationNavigation(String? payload) {
  if (payload == null || payload.isEmpty) {
    debugPrint('⚠️ Payload пустой, навигация не требуется');
    return;
  }

  debugPrint('🔔 Обработка навигации: $payload');

  // Разбираем payload формата "тип:id"
  final parts = payload.split(':');
  if (parts.length != 2) {
    debugPrint('⚠️ Неверный формат payload: $payload');
    return;
  }

  final type = parts[0]; // 'booking', 'order', 'reminder' и т.д.
  final id = parts[1];   // ID сущности

  // Используем глобальный navigatorKey для навигации
  final context = navigatorKey.currentContext;
  if (context == null) {
    debugPrint('⚠️ Navigator context недоступен');
    return;
  }

  // Навигация в зависимости от типа уведомления
  switch (type) {
    case 'booking':
    case 'order':
      Navigator.of(context).pushNamed('/booking-details', arguments: id);
      break;
    case 'test':
      debugPrint('🧪 Тестовое уведомление: $id');
      break;
    default:
      debugPrint('⚠️ Неизвестный тип уведомления: $type');
  }
}

// ============================================================
// КЛАСС СЕРВИСА УВЕДОМЛЕНИЙ
// ============================================================

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ============================================================
  // ИНИЦИАЛИЗАЦИЯ
  // ============================================================
  
  /// Инициализация сервиса уведомлений
  /// Вызывать при старте приложения (в SplashScreen или main)
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      debugPrint('🔔 [INIT] Начало инициализации уведомлений...');

      // 1. Инициализация timezone
      tz.initializeTimeZones();
      // ВАЖНО: Установить правильный часовой пояс для вашего региона
      tz.setLocalLocation(tz.getLocation('Europe/Moscow'));
      debugPrint('🔔 [INIT] ✅ Timezone: Europe/Moscow');

      // 2. Настройки для Android
      // ВАЖНО: Имя иконки должно совпадать с файлом в res/drawable/
      const androidSettings = AndroidInitializationSettings(
        '@drawable/ic_notification', // Имя файла без расширения
      );

      // 3. Настройки для iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // 4. Объединяем настройки
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 5. Инициализация плагина
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      debugPrint('🔔 [INIT] ✅ FlutterLocalNotifications инициализирован');

      // 6. Проверка разрешений для Android 12+
      await _checkAndRequestExactAlarmPermission();

      _initialized = true;
      debugPrint('🔔 [INIT] ✅ Сервис уведомлений готов к работе');
      return true;
    } catch (e) {
      debugPrint('❌ [INIT] Ошибка инициализации: $e');
      return false;
    }
  }

  /// Проверка и запрос разрешения на точные будильники (Android 12+)
  Future<void> _checkAndRequestExactAlarmPermission() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    final canSchedule = await androidPlugin.canScheduleExactNotifications();
    debugPrint('🔔 [INIT] canScheduleExactNotifications: $canSchedule');

    if (canSchedule == null || !canSchedule) {
      debugPrint('⚠️ [INIT] Запрашиваем разрешение на точные alarm\'ы...');
      final granted = await androidPlugin.requestExactAlarmsPermission();
      debugPrint('🔔 [INIT] Разрешение: ${granted == true ? "✅" : "❌"}');
    }
  }

  /// Обработчик нажатия на уведомление (статический)
  @pragma('vm:entry-point')
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🔔 Нажатие на уведомление:');
    debugPrint('   ID: ${response.id}');
    debugPrint('   Payload: ${response.payload}');
    
    _handleNotificationNavigation(response.payload);
  }

  // ============================================================
  // НЕМЕДЛЕННОЕ УВЕДОМЛЕНИЕ
  // ============================================================

  /// Показать уведомление немедленно
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'general_notifications',        // Channel ID
        'Общие уведомления',             // Channel Name
        channelDescription: 'Уведомления приложения',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableLights: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        channelShowBadge: true,
        autoCancel: true,
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

      // Генерируем уникальный ID
      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      await _localNotifications.show(
        notificationId,
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

  // ============================================================
  // ЗАПЛАНИРОВАННОЕ УВЕДОМЛЕНИЕ
  // ============================================================

  /// Запланировать уведомление на определённое время
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      // Проверяем, что время в будущем
      if (scheduledTime.isBefore(DateTime.now())) {
        debugPrint('⚠️ Время уведомления в прошлом, пропускаем');
        return false;
      }

      // Конвертируем в TZDateTime
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      final androidDetails = AndroidNotificationDetails(
        'scheduled_notifications',
        'Запланированные уведомления',
        channelDescription: 'Напоминания и запланированные уведомления',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableLights: true,
        ledColor: const Color(0xFFFF0000),
        ledOnMs: 1000,
        ledOffMs: 500,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 250, 500]),
        playSound: true,
        fullScreenIntent: true,
        channelShowBadge: true,
        autoCancel: false,
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
        id,
        title,
        body,
        tzScheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint('✅ Уведомление запланировано:');
      debugPrint('   ID: $id');
      debugPrint('   Время: $tzScheduledTime');
      debugPrint('   Заголовок: $title');
      
      return true;
    } catch (e) {
      debugPrint('❌ Ошибка планирования уведомления: $e');
      return false;
    }
  }

  // ============================================================
  // НАПОМИНАНИЯ (ПРИМЕР ДЛЯ БРОНИРОВАНИЙ)
  // ============================================================

  /// Запланировать напоминание за 24 часа
  /// eventTime - время события (например, время поездки)
  /// eventId - ID события для навигации
  /// eventDescription - описание для текста уведомления
  Future<bool> scheduleReminder24Hours({
    required DateTime eventTime,
    required String eventId,
    required String eventDescription,
  }) async {
    // Вычисляем время напоминания: за 1 день, в 9:00 утра
    final reminderDate = eventTime.subtract(const Duration(days: 1));
    final reminderTime = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      9, // 9:00 утра
      0,
    );

    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ [24H] Время напоминания в прошлом');
      return false;
    }

    return scheduleNotification(
      id: '${eventId}_24h'.hashCode,
      title: '📅 Напоминание: завтра',
      body: '$eventDescription завтра в ${_formatTime(eventTime)}',
      scheduledTime: reminderTime,
      payload: 'booking:$eventId',
    );
  }

  /// Запланировать напоминание за 1 час
  Future<bool> scheduleReminder1Hour({
    required DateTime eventTime,
    required String eventId,
    required String eventDescription,
  }) async {
    final reminderTime = eventTime.subtract(const Duration(hours: 1));

    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ [1H] Время напоминания в прошлом');
      return false;
    }

    return scheduleNotification(
      id: '${eventId}_1h'.hashCode,
      title: '⏰ Через 1 час',
      body: '$eventDescription в ${_formatTime(eventTime)}',
      scheduledTime: reminderTime,
      payload: 'booking:$eventId',
    );
  }

  /// Запланировать все напоминания для события
  Future<void> scheduleAllReminders({
    required DateTime eventTime,
    required String eventId,
    required String eventDescription,
  }) async {
    await Future.wait([
      scheduleReminder24Hours(
        eventTime: eventTime,
        eventId: eventId,
        eventDescription: eventDescription,
      ),
      scheduleReminder1Hour(
        eventTime: eventTime,
        eventId: eventId,
        eventDescription: eventDescription,
      ),
    ]);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // ОТМЕНА УВЕДОМЛЕНИЙ
  // ============================================================

  /// Отменить уведомления для события по ID
  Future<void> cancelEventNotifications(String eventId) async {
    try {
      await _localNotifications.cancel('${eventId}_24h'.hashCode);
      await _localNotifications.cancel('${eventId}_1h'.hashCode);
      debugPrint('✅ Уведомления для $eventId отменены');
    } catch (e) {
      debugPrint('❌ Ошибка отмены уведомлений: $e');
    }
  }

  /// Отменить конкретное уведомление по ID
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      debugPrint('✅ Уведомление $id отменено');
    } catch (e) {
      debugPrint('❌ Ошибка отмены уведомления: $e');
    }
  }

  /// Отменить ВСЕ уведомления
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      debugPrint('✅ Все уведомления отменены');
    } catch (e) {
      debugPrint('❌ Ошибка отмены всех уведомлений: $e');
    }
  }

  // ============================================================
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ============================================================

  /// Получить список запланированных уведомлений
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Ошибка получения списка: $e');
      return [];
    }
  }

  // ============================================================
  // ТЕСТИРОВАНИЕ
  // ============================================================

  /// Тест: немедленное уведомление
  Future<void> testNotificationNow() async {
    await showNotification(
      title: '🧪 Тест (сейчас)',
      body: 'Это тестовое уведомление',
      payload: 'test:now',
    );
  }

  /// Тест: уведомление через 5 секунд
  Future<void> testNotification5Seconds() async {
    final time = DateTime.now().add(const Duration(seconds: 5));
    await scheduleNotification(
      id: 99991,
      title: '🧪 Тест (5 сек)',
      body: 'Уведомление через 5 секунд',
      scheduledTime: time,
      payload: 'test:5sec',
    );
  }

  /// Тест: уведомление через 10 секунд (закройте приложение!)
  Future<void> testNotification10Seconds() async {
    final time = DateTime.now().add(const Duration(seconds: 10));
    await scheduleNotification(
      id: 99992,
      title: '🧪 Тест (10 сек)',
      body: 'ЗАКРОЙТЕ ПРИЛОЖЕНИЕ! Уведомление в background',
      scheduledTime: time,
      payload: 'test:10sec',
    );
  }
}
```

---

## 🚀 ИНИЦИАЛИЗАЦИЯ В SPLASHSCREEN

### Пример инициализации:

```dart
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // ... другая инициализация (анимации и т.д.)
    
    // Инициализация уведомлений
    await NotificationService.instance.initialize();
    
    // Переход на следующий экран
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

---

## 📲 ИСПОЛЬЗОВАНИЕ В ПРИЛОЖЕНИИ

### 1. Показать уведомление сейчас:

```dart
await NotificationService.instance.showNotification(
  title: 'Заказ подтверждён',
  body: 'Ваш заказ #123 успешно создан',
  payload: 'order:123', // формат: тип:id
);
```

### 2. Запланировать уведомление:

```dart
await NotificationService.instance.scheduleNotification(
  id: 12345,
  title: 'Напоминание',
  body: 'Не забудьте про встречу!',
  scheduledTime: DateTime.now().add(Duration(hours: 2)),
  payload: 'reminder:meeting_1',
);
```

### 3. Запланировать напоминания для события:

```dart
// При создании заказа/бронирования
await NotificationService.instance.scheduleAllReminders(
  eventTime: DateTime(2025, 12, 25, 14, 30), // Время события
  eventId: 'booking_123',
  eventDescription: 'Поездка Донецк → Ростов',
);
```

### 4. Отменить уведомления при отмене заказа:

```dart
await NotificationService.instance.cancelEventNotifications('booking_123');
```

### 5. Тестирование:

```dart
// Кнопка в настройках для тестирования
ElevatedButton(
  onPressed: () async {
    await NotificationService.instance.testNotificationNow();
    await NotificationService.instance.testNotification5Seconds();
    await NotificationService.instance.testNotification10Seconds();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('3 тестовых уведомления запланированы')),
    );
  },
  child: Text('Тест уведомлений'),
)
```

---

## ✅ ЧЕКЛИСТ ИНТЕГРАЦИИ

### Шаг 1: Зависимости
- [ ] Добавить `flutter_local_notifications: ^18.0.1` в pubspec.yaml
- [ ] Добавить `timezone: ^0.9.4` в pubspec.yaml
- [ ] Выполнить `flutter pub get`

### Шаг 2: Android
- [ ] Добавить разрешения в AndroidManifest.xml
- [ ] Добавить receivers в AndroidManifest.xml
- [ ] Создать иконку `ic_notification.xml` (белая на прозрачном фоне)

### Шаг 3: Код
- [ ] Добавить `navigatorKey` в main.dart
- [ ] Передать `navigatorKey` в MaterialApp/CupertinoApp
- [ ] Создать файл `notification_service.dart`
- [ ] Настроить роуты для навигации (`/booking-details`)

### Шаг 4: Инициализация
- [ ] Вызвать `NotificationService.instance.initialize()` в SplashScreen

### Шаг 5: Тестирование
- [ ] Проверить немедленное уведомление
- [ ] Проверить уведомление через 5 секунд (приложение открыто)
- [ ] Проверить уведомление через 10 секунд (приложение ЗАКРЫТО)
- [ ] Проверить навигацию при нажатии на уведомление

---

## 🐛 ЧАСТЫЕ ПРОБЛЕМЫ И РЕШЕНИЯ

### Проблема: Уведомления не приходят на Android 12+
**Решение:** Проверить разрешения `SCHEDULE_EXACT_ALARM` и `USE_EXACT_ALARM`

### Проблема: Иконка отображается как квадрат
**Решение:** Иконка должна быть БЕЛОЙ на прозрачном фоне

### Проблема: Уведомления не приходят после перезагрузки
**Решение:** Добавить `ScheduledNotificationBootReceiver` в AndroidManifest

### Проблема: Навигация не работает при нажатии
**Решение:** Проверить что `navigatorKey` передан в MaterialApp

### Проблема: Уведомления приходят с задержкой
**Решение:** Использовать `AndroidScheduleMode.exactAllowWhileIdle`

---

## 📁 СТРУКТУРА ФАЙЛОВ

```
your_app/
├── lib/
│   ├── main.dart                    # navigatorKey + роуты
│   └── services/
│       └── notification_service.dart # весь код уведомлений
├── android/
│   └── app/
│       └── src/
│           └── main/
│               ├── AndroidManifest.xml  # разрешения + receivers
│               └── res/
│                   └── drawable/
│                       └── ic_notification.xml  # иконка
├── ios/
│   └── Runner/
│       └── Info.plist               # (опционально)
└── pubspec.yaml                     # зависимости
```

---

**Дата создания:** 23 декабря 2025
**Версия:** 1.0
**Протестировано на:** Flutter 3.x, Android 12+, iOS 15+
