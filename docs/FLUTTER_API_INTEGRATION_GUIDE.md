# 🚀 Интеграция Flutter с Backend API

## 📋 Содержание
- [Обзор](#обзор)
- [Созданные API сервисы](#созданные-api-сервисы)
- [Настройка Telegram бота](#настройка-telegram-бота)
- [Примеры использования](#примеры-использования)
- [Схема работы приложения](#схема-работы-приложения)
- [План миграции](#план-миграции)

---

## 🎯 Обзор

Создана полная инфраструктура для интеграции Flutter приложения с backend API на **https://titotr.ru**. 

### Что готово:

✅ **Базовая инфраструктура API**
- `lib/services/api/api_client.dart` - HTTP клиент с JWT аутентификацией
- `lib/services/api/api_config.dart` - Конфигурация endpoints
- `lib/services/api/api_exceptions.dart` - Типизированные ошибки API

✅ **API Сервисы**
- `lib/services/api/auth_api_service.dart` - Аутентификация (6 endpoints)
- `lib/services/api/orders_api_service.dart` - Управление заказами (5 endpoints)
- `lib/services/api/routes_api_service.dart` - Поиск маршрутов (1 endpoint)
- `lib/services/api/admin_api_service.dart` - Админ-панель (4 endpoints)

✅ **Telegram интеграция**
- `lib/services/telegram_service.dart` - Обновлен для реальных HTTP запросов к Telegram Bot API

✅ **Зависимости**
- `flutter_secure_storage: ^9.2.2` - Добавлена для безопасного хранения токенов

---

## 📦 Созданные API сервисы

### 1. AuthApiService - Аутентификация

```dart
import 'package:time_to_travel/services/api/auth_api_service.dart';

final authService = AuthApiService();
await authService.init();

// Регистрация
final authResponse = await authService.register(
  email: 'user@example.com',
  password: 'securePassword123',
  name: 'Иван Петров',
  phone: '+79001234567',
);

// Вход
final loginResponse = await authService.login(
  email: 'user@example.com',
  password: 'securePassword123',
);

// Получить текущего пользователя
final currentUser = await authService.getCurrentUser();
print('Role: ${currentUser.role}'); // client, driver, admin

// Обновить токен
final refreshed = await authService.refreshToken();

// Выход
await authService.logout();

// Проверка авторизации
if (authService.isAuthenticated) {
  print('User is logged in');
}
```

**Модели:**
- `ApiUser` - пользователь (id, email, name, phone, role, isVerified, isActive)
- `AuthResponse` - ответ авторизации (user, accessToken, refreshToken)

---

### 2. OrdersApiService - Управление заказами

```dart
import 'package:time_to_travel/services/api/orders_api_service.dart';

final ordersService = OrdersApiService();

// Получить список заказов
final ordersResponse = await ordersService.getOrders(
  status: OrderStatus.pending,
  limit: 50,
);
print('Total orders: ${ordersResponse.count}');

// Создать заказ
final newOrder = await ordersService.createOrder(
  fromAddress: 'Донецк, пр. Ильича',
  toAddress: 'Ростов-на-Дону, Центральный автовокзал',
  departureTime: DateTime(2026, 1, 25, 14, 00),
  passengerCount: 2,
  basePrice: 1500.0,
  totalPrice: 1800.0,
  phone: '+79001234567',
  notes: 'С багажом',
  metadata: {
    'tripType': 'group',
    'baggage': [
      {'size': 'M', 'count': 1}
    ],
  },
);

// Получить заказ по ID
final order = await ordersService.getOrderById('order-id-123');

// Обновить статус (для диспетчера)
final updated = await ordersService.updateOrderStatus(
  orderId: 'order-id-123',
  status: OrderStatus.confirmed,
);

// Отменить заказ
await ordersService.cancelOrder('order-id-123');
```

**Модели:**
- `ApiOrder` - заказ с полными данными
- `OrderStatus` - enum (pending, confirmed, inProgress, completed, cancelled)

---

### 3. RoutesApiService - Поиск маршрутов

```dart
import 'package:time_to_travel/services/api/routes_api_service.dart';

final routesService = RoutesApiService();

// Поиск маршрутов
final searchResult = await routesService.searchRoutes(
  from: 'Ростов',
  to: 'Азов',
);

for (final route in searchResult.routes) {
  print('${route.fromCity} → ${route.toCity}: ${route.basePrice}₽');
  print('Расстояние: ${route.distanceKm} км');
  print('Время в пути: ${route.durationMinutes} мин');
}
```

**Модели:**
- `ApiPredefinedRoute` - предопределенный маршрут
- `RoutesSearchResponse` - результаты поиска (routes, count)

---

### 4. AdminApiService - Админ-панель для диспетчеров

```dart
import 'package:time_to_travel/services/api/admin_api_service.dart';

final adminService = AdminApiService();

// ⚠️ Требуется role: 'admin' в JWT токене!

// Создать маршрут
final route = await adminService.createRoute(
  fromCity: 'Ростов-на-Дону',
  toCity: 'Таганрог',
  basePrice: 800.0,
  durationMinutes: 60,
  distanceKm: 70,
  description: 'Прямой маршрут через М4',
);

// Обновить маршрут
final updated = await adminService.updateRoute(
  routeId: 'route-id-123',
  basePrice: 900.0,
  description: 'Обновленное описание',
);

// Удалить маршрут
await adminService.deleteRoute('route-id-123');

// Получить статистику
final stats = await adminService.getStats();
print('Всего заказов: ${stats.totalOrders}');
print('Ожидают подтверждения: ${stats.pendingOrders}');
print('Выручка: ${stats.totalRevenue}₽');

// Получить список всех маршрутов
final routes = await adminService.getPredefinedRoutes();
```

**Модели:**
- `AdminStats` - статистика (totalOrders, pendingOrders, totalRevenue и т.д.)

---

## 🤖 Настройка Telegram бота

### Шаг 1: Создание бота

1. Откройте Telegram и найдите [@BotFather](https://t.me/BotFather)
2. Отправьте команду `/newbot`
3. Следуйте инструкциям:
   - Введите имя бота: **Time to Travel Dispatcher Bot**
   - Введите username: **timetotravel_dispatcher_bot** (должен заканчиваться на `_bot`)
4. Скопируйте полученный **токен** (формат: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`)

### Шаг 2: Получение Chat ID

**Вариант 1: Через бота @userinfobot**
1. Найдите [@userinfobot](https://t.me/userinfobot)
2. Отправьте `/start`
3. Скопируйте ваш **ID** (числовое значение)

**Вариант 2: Для группового чата**
1. Добавьте вашего бота в группу диспетчеров
2. Сделайте бота администратором группы
3. Откройте в браузере:
   ```
   https://api.telegram.org/bot<ВАШ_ТОКЕН>/getUpdates
   ```
4. Найдите `"chat":{"id":-1001234567890}` в ответе
5. Скопируйте **Chat ID** (отрицательное число для групп)

### Шаг 3: Обновление кода

Откройте `lib/services/telegram_service.dart` и замените:

```dart
static const String _botToken = 'ВАШ_РЕАЛЬНЫЙ_ТОКЕН';
static const String _chatId = 'ВАШ_CHAT_ID';
```

### Шаг 4: Тестирование

```dart
import 'package:time_to_travel/services/telegram_service.dart';

// Отправить тестовое сообщение
final success = await TelegramService.instance.testConnection();
if (success) {
  print('✅ Telegram бот работает!');
}
```

---

## 💡 Примеры использования

### Пример 1: Полный flow регистрации и создания заказа

```dart
import 'package:time_to_travel/services/api/auth_api_service.dart';
import 'package:time_to_travel/services/api/orders_api_service.dart';
import 'package:time_to_travel/services/telegram_service.dart';

Future<void> createBookingExample() async {
  final authService = AuthApiService();
  final ordersService = OrdersApiService();
  
  try {
    // 1. Инициализация
    await authService.init();
    
    // 2. Регистрация или вход
    final authResponse = await authService.login(
      email: 'client@example.com',
      password: 'Test123!',
    );
    
    print('Вход выполнен: ${authResponse.user.email}');
    
    // 3. Создание заказа
    final order = await ordersService.createOrder(
      fromAddress: 'Донецк, пр. Ильича 15',
      toAddress: 'Ростов-на-Дону, Главный автовокзал',
      departureTime: DateTime.now().add(Duration(days: 1)),
      passengerCount: 2,
      basePrice: 1500.0,
      totalPrice: 1800.0,
      phone: '+79001234567',
      notes: 'Групповая поездка с багажом',
      metadata: {
        'tripType': 'group',
        'baggage': [
          {'size': 'M', 'count': 1, 'price': 100},
        ],
        'hasAnimals': false,
      },
    );
    
    print('Заказ создан: ${order.id}');
    
    // 4. Отправка уведомления диспетчеру в Telegram
    // (требуется корректная модель Booking из вашего приложения)
    // await TelegramService.instance.sendNewBookingNotification(booking, user);
    
  } catch (e) {
    print('Ошибка: $e');
  }
}
```

### Пример 2: Диспетчер подтверждает заказ

```dart
import 'package:time_to_travel/services/api/auth_api_service.dart';
import 'package:time_to_travel/services/api/orders_api_service.dart';

Future<void> dispatcherConfirmOrder(String orderId) async {
  final authService = AuthApiService();
  final ordersService = OrdersApiService();
  
  try {
    // 1. Вход как диспетчер/админ
    await authService.login(
      email: 'admin@titotr.ru',
      password: 'Test123!',
    );
    
    // 2. Проверка роли
    final user = await authService.getCurrentUser();
    if (!user.isAdmin && !user.isDriver) {
      throw Exception('Недостаточно прав');
    }
    
    // 3. Подтверждение заказа
    final updated = await ordersService.updateOrderStatus(
      orderId: orderId,
      status: OrderStatus.confirmed,
    );
    
    print('Заказ ${updated.id} подтвержден!');
    print('Статус: ${updated.status}');
    
    // 4. Отправка уведомления клиенту (опционально)
    // await NotificationService.sendOrderConfirmed(updated);
    
  } catch (e) {
    print('Ошибка подтверждения: $e');
  }
}
```

### Пример 3: Получение списка pending заказов для диспетчера

```dart
import 'package:time_to_travel/services/api/orders_api_service.dart';
import 'package:flutter/material.dart';

class DispatcherOrdersScreen extends StatefulWidget {
  @override
  _DispatcherOrdersScreenState createState() => _DispatcherOrdersScreenState();
}

class _DispatcherOrdersScreenState extends State<DispatcherOrdersScreen> {
  final _ordersService = OrdersApiService();
  List<ApiOrder> _pendingOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingOrders();
  }

  Future<void> _loadPendingOrders() async {
    try {
      final response = await _ordersService.getOrders(
        status: OrderStatus.pending,
        limit: 100,
      );
      
      setState(() {
        _pendingOrders = response.orders;
        _loading = false;
      });
    } catch (e) {
      print('Ошибка загрузки заказов: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmOrder(String orderId) async {
    try {
      await _ordersService.updateOrderStatus(
        orderId: orderId,
        status: OrderStatus.confirmed,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Заказ подтвержден')),
      );
      
      _loadPendingOrders(); // Обновить список
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _pendingOrders.length,
      itemBuilder: (context, index) {
        final order = _pendingOrders[index];
        return ListTile(
          title: Text('${order.fromAddress} → ${order.toAddress}'),
          subtitle: Text('${order.passengerCount} пас. • ${order.totalPrice}₽'),
          trailing: ElevatedButton(
            onPressed: () => _confirmOrder(order.id),
            child: Text('Подтвердить'),
          ),
        );
      },
    );
  }
}
```

---

## 🏗️ Схема работы приложения

### Архитектура "Клиент → Backend → Telegram"

```
┌────────────────────┐
│  Flutter App       │
│  (Пользователь)    │
└─────────┬──────────┘
          │
          │ 1. POST /api/orders
          │    (создание заказа)
          ▼
┌────────────────────┐
│  Backend API       │
│  titotr.ru         │
│                    │
│  ✅ Сохраняет в    │
│     PostgreSQL     │
└─────────┬──────────┘
          │
          │ 2. Webhook (планируется)
          │    или polling
          ▼
┌────────────────────┐
│  Telegram Bot      │
│  (Диспетчер)       │
│                    │
│  📱 Получает       │
│     уведомление    │
└────────────────────┘

Обратный flow:
┌────────────────────┐
│  Telegram Bot      │
│  (Диспетчер)       │
└─────────┬──────────┘
          │
          │ 3. Callback кнопка
          │    "Подтвердить"
          ▼
┌────────────────────┐
│  Backend API       │
│                    │
│  PATCH /orders/123 │
│  status=confirmed  │
└─────────┬──────────┘
          │
          │ 4. Push notification
          │    (FCM)
          ▼
┌────────────────────┐
│  Flutter App       │
│  (Пользователь)    │
│                    │
│  🔔 "Заказ         │
│      подтвержден"  │
└────────────────────┘
```

---

## 📝 План миграции с Firebase на Backend API

### Этап 1: Подготовка (Выполнено ✅)

- [x] Создать API сервисы
- [x] Настроить JWT аутентификацию
- [x] Добавить flutter_secure_storage
- [x] Обновить Telegram integration

### Этап 2: Интеграция аутентификации (TODO)

1. Заменить `FirebaseAuth` на `AuthApiService` в:
   - `lib/features/auth/screens/auth_screen.dart`
   - `lib/services/user_service.dart`

2. Обновить хранилище состояния пользователя:
   - Использовать `flutter_secure_storage` вместо SharedPreferences для токенов
   - Сохранять `ApiUser` вместо Firebase User

3. Добавить автоматическое обновление токена:
   - Interceptor для обработки 401 ошибок
   - Автоматический вызов `/auth/refresh`

### Этап 3: Миграция заказов (TODO)

1. Обновить `lib/services/offline_orders_service.dart`:
   - Заменить Firebase sync на API sync
   - Использовать `OrdersApiService.createOrder()`

2. Обновить `lib/services/orders_sync_service.dart`:
   - Синхронизация локальных заказов с backend
   - Периодическая проверка новых заказов с сервера

3. Заменить Firebase реалтайм слушатели:
   - Использовать polling или WebSocket (будущее)
   - Для диспетчера: проверка новых заказов каждые 30 сек

### Этап 4: Экраны диспетчера (TODO)

1. Создать `lib/features/dispatcher/screens/dispatcher_orders_screen.dart`:
   - Список заказов со статусом `pending`
   - Кнопки "Подтвердить" / "Отклонить"
   - Детальный просмотр заказа

2. Обновить `lib/features/home/screens/dispatcher_home_screen.dart`:
   - Использовать `OrdersApiService.getOrders()`
   - Использовать `AdminApiService.getStats()`

3. Добавить управление маршрутами:
   - CRUD для `ApiPredefinedRoute`
   - Использовать `AdminApiService`

### Этап 5: Telegram уведомления (TODO)

1. Получить реальный токен бота от @BotFather
2. Получить Chat ID группы диспетчеров
3. Обновить `_botToken` и `_chatId` в `telegram_service.dart`
4. Интегрировать отправку уведомлений:
   - При создании заказа → `TelegramService.sendNewBookingNotification()`
   - При отмене → `TelegramService.sendBookingCancellationNotification()`

### Этап 6: Telegram Bot для диспетчеров (Расширенное, Опционально)

1. Создать Telegram бота на Python/Node.js:
   ```python
   # Пример на Python с aiogram
   from aiogram import Bot, Dispatcher, types
   import aiohttp
   
   @dp.message_handler(commands=['orders'])
   async def get_pending_orders(message: types.Message):
       async with aiohttp.ClientSession() as session:
           headers = {'Authorization': f'Bearer {ADMIN_JWT_TOKEN}'}
           async with session.get(
               'https://titotr.ru/api/orders?status=pending',
               headers=headers
           ) as resp:
               data = await resp.json()
               # Форматировать и отправить список заказов
   
   @dp.callback_query_handler(lambda c: c.data.startswith('confirm_'))
   async def confirm_order(callback: types.CallbackQuery):
       order_id = callback.data.split('_')[1]
       async with aiohttp.ClientSession() as session:
           headers = {'Authorization': f'Bearer {ADMIN_JWT_TOKEN}'}
           async with session.patch(
               f'https://titotr.ru/api/orders/{order_id}/status',
               json={'status': 'confirmed'},
               headers=headers
           ) as resp:
               await callback.answer('✅ Заказ подтвержден')
   ```

2. Добавить inline кнопки к уведомлениям:
   ```python
   keyboard = InlineKeyboardMarkup()
   keyboard.add(
       InlineKeyboardButton("✅ Подтвердить", callback_data=f"confirm_{order_id}"),
       InlineKeyboardButton("❌ Отклонить", callback_data=f"reject_{order_id}")
   )
   ```

---

## 🔒 Безопасность

### JWT токены

- **Access Token**: Срок жизни 1 час, используется для всех API запросов
- **Refresh Token**: Срок жизни 7 дней, хранится в flutter_secure_storage
- Автоматическое обновление при истечении access token

### Хранение данных

```dart
// ✅ Безопасно (зашифровано)
await FlutterSecureStorage().write(key: 'access_token', value: token);

// ❌ Небезопасно (открытый текст)
await SharedPreferences.setString('access_token', token);
```

### Роли пользователей

- `client` - обычный пользователь (создание заказов)
- `driver` - водитель (просмотр назначенных заказов)
- `admin` - диспетчер (полный доступ к управлению)

---

## 🐛 Обработка ошибок

```dart
import 'package:time_to_travel/services/api/api_exceptions.dart';

try {
  final orders = await ordersService.getOrders();
} on UnauthorizedException catch (e) {
  // 401: Токен истек, нужно перелогиниться
  print('Требуется авторизация: $e');
  Navigator.pushReplacementNamed(context, '/auth');
} on ForbiddenException catch (e) {
  // 403: Недостаточно прав
  print('Доступ запрещен: $e');
} on NotFoundException catch (e) {
  // 404: Ресурс не найден
  print('Не найдено: $e');
} on NetworkException catch (e) {
  // Нет интернета
  print('Ошибка сети: $e');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Нет подключения к интернету')),
  );
} on ApiException catch (e) {
  // Другие ошибки API
  print('Ошибка API: $e');
} catch (e) {
  // Неизвестные ошибки
  print('Неизвестная ошибка: $e');
}
```

---

## 📞 Поддержка

- **Backend API**: https://titotr.ru
- **Health Check**: https://titotr.ru/health
- **Документация API**: `/Users/kirillpetrov/Projects/time-to-travel/backend/backend/API_ENDPOINTS.md`
- **Telegram**: @Time_to_travel_dnr

---

## ✅ Следующие шаги

1. **Настроить Telegram бота** (получить токен и chat_id)
2. **Создать экраны диспетчера** для управления заказами
3. **Интегрировать API в существующие экраны** бронирования
4. **Настроить синхронизацию** офлайн заказов с backend
5. **Добавить обработку ошибок** и retry логику
6. **Тестирование** полного flow: регистрация → заказ → уведомление → подтверждение

---

**Дата создания**: 22 января 2026  
**Версия**: 1.0.0  
**Статус**: ✅ Базовая интеграция готова, требуется настройка Telegram и обновление UI
