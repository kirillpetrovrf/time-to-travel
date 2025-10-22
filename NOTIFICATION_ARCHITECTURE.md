# 🗺️ АРХИТЕКТУРА СИСТЕМЫ УВЕДОМЛЕНИЙ

## 📐 Общая схема

```
┌─────────────────────────────────────────────────────────────┐
│                    TIME TO TRAVEL APP                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              NOTIFICATION SYSTEM                      │   │
│  │                                                       │   │
│  │  ┌──────────────┐     ┌──────────────┐              │   │
│  │  │   Scheduled  │────▶│   Display    │              │   │
│  │  │ Notifications│     │ Notification │              │   │
│  │  └──────────────┘     └──────────────┘              │   │
│  │         │                     │                      │   │
│  │         ▼                     ▼                      │   │
│  │  ┌──────────────┐     ┌──────────────┐              │   │
│  │  │  User Taps   │────▶│  Navigation  │              │   │
│  │  │ Notification │     │   Handler    │              │   │
│  │  └──────────────┘     └──────────────┘              │   │
│  │                              │                       │   │
│  │                              ▼                       │   │
│  │                       ┌──────────────┐              │   │
│  │                       │  Booking     │              │   │
│  │                       │  Details     │              │   │
│  │                       └──────────────┘              │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Поток данных

### 1. Создание заказа
```
┌──────────┐     ┌──────────────┐     ┌──────────────────┐
│  User    │────▶│ Create       │────▶│ Schedule         │
│  Action  │     │ Booking      │     │ Notifications    │
└──────────┘     └──────────────┘     └──────────────────┘
                                              │
                                              ▼
                                  ┌──────────────────────┐
                                  │ • 24h reminder       │
                                  │ • 1h reminder        │
                                  └──────────────────────┘
```

### 2. Получение уведомления
```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  Scheduled   │────▶│  Android     │────▶│  Display     │
│  Time        │     │  System      │     │  on Screen   │
└──────────────┘     └──────────────┘     └──────────────┘
                                                  │
                                                  ▼
                                     ┌─────────────────────┐
                                     │ 🚗 Icon             │
                                     │ 🔊 Sound            │
                                     │ 📳 Vibration        │
                                     │ 💡 LED              │
                                     └─────────────────────┘
```

### 3. Навигация при нажатии
```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│  User Tap    │────▶│  Parse       │────▶│  Navigate    │
│              │     │  Payload     │     │  to Screen   │
└──────────────┘     └──────────────┘     └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │ booking:abc  │
                    │    ↑     ↑   │
                    │  type   id   │
                    └──────────────┘
```

---

## 🏗️ Компоненты системы

### 1. NotificationService
```
┌─────────────────────────────────────────┐
│     NotificationService                 │
├─────────────────────────────────────────┤
│ • initialize()                          │
│ • showNotification()                    │
│ • schedule24HourReminder()              │
│ • schedule1HourReminder()               │
│ • sendTestNotificationNow()             │
│ • sendTestNotification1MinuteAppOn()    │
│ • sendTestNotification2MinuteAppOff()   │
│ • getPendingNotifications()             │
│ • cancelBookingNotifications()          │
└─────────────────────────────────────────┘
```

### 2. Обработчики уведомлений
```
┌──────────────────────────────────────────┐
│  Global Handlers                         │
├──────────────────────────────────────────┤
│                                          │
│  notificationTapBackground()             │
│  ├─ Для background нажатий              │
│  └─ Вызывает _handleNotificationNav()   │
│                                          │
│  _onNotificationTappedStatic()           │
│  ├─ Для foreground нажатий              │
│  └─ Вызывает _handleNotificationNav()   │
│                                          │
│  _handleNotificationNavigation()         │
│  ├─ Парсит payload                      │
│  ├─ Определяет тип (booking/test)       │
│  └─ Выполняет навигацию                 │
│                                          │
└──────────────────────────────────────────┘
```

### 3. Навигационная система
```
┌──────────────────────────────────────────┐
│  Navigation Stack                        │
├──────────────────────────────────────────┤
│                                          │
│  navigatorKey (Global)                   │
│  ├─ Доступен из любой точки             │
│  └─ Используется для навигации          │
│                                          │
│  Routes:                                 │
│  ├─ /auth                               │
│  ├─ /home                               │
│  └─ /booking-details (NEW!)             │
│      ├─ Arguments: bookingId            │
│      └─ Widget: _BookingDetailsLoader   │
│                                          │
└──────────────────────────────────────────┘
```

---

## 📋 Конфигурация уведомлений

### Android Notification Details
```
┌─────────────────────────────────────────┐
│  AndroidNotificationDetails             │
├─────────────────────────────────────────┤
│                                         │
│  Channel:                               │
│  ├─ ID: 'test_notifications'            │
│  ├─ Name: 'Тестовые уведомления'        │
│  └─ Description: 'Для тестирования'     │
│                                         │
│  Visual:                                │
│  ├─ Icon: @drawable/ic_notification_car │
│  ├─ Importance: MAX                     │
│  └─ Priority: MAX                       │
│                                         │
│  Sound & Vibration:                     │
│  ├─ Sound: System default               │
│  ├─ Vibration: Custom pattern           │
│  └─ LED: Green/Red                      │
│                                         │
│  Behavior:                              │
│  ├─ autoCancel: false                   │
│  ├─ ongoing: false                      │
│  └─ fullScreenIntent: true              │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🔁 Жизненный цикл уведомления

```
START
  │
  ▼
┌────────────────────┐
│  User creates      │
│  booking           │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│  Calculate         │
│  notification      │
│  times             │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│  Schedule          │
│  notifications     │
│  • 24h before      │
│  • 1h before       │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│  Wait for          │
│  scheduled time    │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│  Android triggers  │
│  notification      │
└────────┬───────────┘
         │
         ▼
┌────────────────────┐
│  Display on        │
│  screen            │
│  🚗 🔊 📳 💡       │
└────────┬───────────┘
         │
         ▼
    ┌───────┐
    │ User  │
    │ taps? │
    └───┬───┘
        │
        ├─ YES ──────────┐
        │                │
        │                ▼
        │     ┌────────────────────┐
        │     │ Parse payload      │
        │     └────────┬───────────┘
        │              │
        │              ▼
        │     ┌────────────────────┐
        │     │ Navigate to        │
        │     │ booking details    │
        │     └────────┬───────────┘
        │              │
        │              ▼
        │     ┌────────────────────┐
        │     │ Show booking info  │
        │     └────────────────────┘
        │
        └─ NO ──────────┐
                        │
                        ▼
                ┌────────────────┐
                │ Stays in       │
                │ notification   │
                │ tray           │
                └────────────────┘
                        │
                        ▼
                      END
```

---

## 📱 UI Screens Flow

```
Settings Screen
      │
      ├─ Tap "Уведомления" block
      │
      ▼
Notifications Screen
      │
      ├─ Shows all scheduled
      │  notifications
      │
      └─ Tap notification
            │
            ▼
      Booking Details
            │
            ├─ Shows route info
            ├─ Shows time info
            ├─ Shows price info
            └─ Cancel button
```

---

## 🔐 Permissions Flow

```
App Launch
      │
      ▼
Check Notification Permission
      │
      ├─ Granted ────────┐
      │                  │
      └─ Not granted     │
            │            │
            ▼            │
    Request Permission   │
            │            │
            ├─ Granted ──┤
            │            │
            └─ Denied    │
                  │      │
                  ▼      ▼
            Show Dialog  Initialize Notifications
                         │
                         ▼
                    Ready to use
```

---

## 🧩 Integration Points

### With BookingService
```
BookingService
      │
      ├─ createBooking()
      │     │
      │     └──▶ NotificationService.scheduleAll()
      │
      ├─ cancelBooking()
      │     │
      │     └──▶ NotificationService.cancel()
      │
      └─ getCurrentBookings()
            │
            └──▶ NotificationsScreen.display()
```

### With Settings Screen
```
SettingsScreen
      │
      ├─ Check permissions
      │     │
      │     └──▶ PermissionService
      │
      ├─ Get pending count
      │     │
      │     └──▶ NotificationService.getPending()
      │
      ├─ Send test notification
      │     │
      │     └──▶ NotificationService.sendTest()
      │
      └─ Open notifications screen
            │
            └──▶ NotificationsScreen
```

---

## 🎯 Data Flow Example

### Creating a booking and scheduling notifications:

```
1. User fills booking form
         ↓
2. BookingService.createBooking()
         ↓
3. Booking saved to database
         ↓
4. NotificationService.scheduleAllBookingNotifications()
         ↓
5. Calculate notification times:
   • departureTime - 24 hours = reminderTime24h
   • departureTime - 1 hour = reminderTime1h
         ↓
6. Schedule notifications:
   • ID: ${bookingId}_24h
   • ID: ${bookingId}_1h
   • Payload: booking:${bookingId}
         ↓
7. Return success
         ↓
8. Show confirmation to user
```

### Receiving and handling notification:

```
1. Android triggers notification at scheduled time
         ↓
2. Notification displayed with:
   • Icon: 🚗 (ic_notification_car)
   • Title: "Напоминание: Поездка через час"
   • Body: "Донецк → Ростов-на-Дону"
   • Sound: 🔊
   • Vibration: 📳
         ↓
3. User taps notification
         ↓
4. notificationTapBackground() OR _onNotificationTappedStatic()
         ↓
5. _handleNotificationNavigation(payload)
         ↓
6. Parse payload: "booking:abc123"
   • type = "booking"
   • id = "abc123"
         ↓
7. Navigator.pushNamed('/booking-details', arguments: id)
         ↓
8. _BookingDetailsLoader loads booking
         ↓
9. BookingDetailScreen displays booking info
         ↓
10. User sees booking details
```

---

## 📊 Monitoring & Debugging

### Logging Points:
```
NotificationService
  │
  ├─ ✅ Инициализация
  ├─ 🔔 Запланировано
  ├─ 📨 Отправлено
  ├─ 🔔 Получено
  ├─ 📱 Обработка навигации
  └─ ❌ Ошибки
```

### Debug Console Output:
```
I/flutter: ✅ Сервис локальных уведомлений инициализирован
I/flutter: 🔔 Напоминание за 1ч запланировано для Донецк → Ростов
I/flutter: 🔔 ========================================
I/flutter: 🔔 УВЕДОМЛЕНИЕ ПОЛУЧЕНО!
I/flutter: 🔔 ID: 1001
I/flutter: 🔔 Payload: booking:abc123
I/flutter: 🔔 ========================================
I/flutter: 🔔 Обработка навигации: booking:abc123
I/flutter: 📱 Переход к деталям заказа: abc123
```

---

## 🔧 Configuration Files

```
project/
├── lib/
│   ├── main.dart
│   │   ├── navigatorKey (global)
│   │   ├── Routes configuration
│   │   └── _BookingDetailsLoader
│   │
│   ├── services/
│   │   └── notification_service.dart
│   │       ├── NotificationService class
│   │       ├── Global handlers
│   │       └── Navigation handler
│   │
│   └── features/
│       ├── settings/
│       │   └── settings_screen.dart
│       │       ├── Notifications block
│       │       ├── Test buttons
│       │       └── Navigation methods
│       │
│       └── notifications/
│           └── notifications_screen.dart
│               └── List of notifications
│
└── android/
    └── app/src/main/res/
        └── drawable/
            └── ic_notification_car.xml (NEW!)
```

---

## ✅ System Health Checklist

- [x] NotificationService initialized
- [x] Permissions granted
- [x] Icon configured (ic_notification_car)
- [x] Sounds enabled
- [x] Vibration patterns set
- [x] LED indicators configured
- [x] NavigatorKey registered
- [x] Routes configured
- [x] Handlers registered
- [x] Payload format validated
- [x] Navigation tested
- [x] Background handling works
- [x] Logging enabled

---

## 🎓 Best Practices Applied

1. ✅ **Separation of Concerns**
   - Service layer for notifications
   - UI layer for display
   - Navigation layer for routing

2. ✅ **Error Handling**
   - Try-catch blocks
   - Null safety
   - Fallback screens

3. ✅ **User Experience**
   - Fast test notifications (5-10s)
   - Clear visual feedback
   - Intuitive navigation

4. ✅ **Performance**
   - Lazy loading of booking details
   - Efficient state management
   - Minimal rebuilds

5. ✅ **Maintainability**
   - Clear code structure
   - Comprehensive documentation
   - Debug logging

---

**Дата:** 22 октября 2025  
**Версия:** 1.0.0  
**Статус:** Production Ready ✅
