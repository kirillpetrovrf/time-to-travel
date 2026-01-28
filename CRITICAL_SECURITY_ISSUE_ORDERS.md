# 🚨 КРИТИЧЕСКАЯ ПРОБЛЕМА БЕЗОПАСНОСТИ: ВСЕ ВИДЯТ ВСЕ ЗАКАЗЫ

## 📊 Результаты анализа (27 января 2026)

### ❌ ГЛАВНАЯ ПРОБЛЕМА
**ВСЕ клиенты видят ВСЕ заказы всех пользователей!**

---

## 🔍 Анализ кода

### 1. Backend API (`/api/orders` GET)
**Файл:** `backend/backend/routes/orders/index.dart`

**Текущая логика (строки 26-90):**

```dart
Future<Response> _getOrders(RequestContext context) async {
  // Получаем токен
  final authHeader = context.request.headers['authorization'];
  String? userId;
  String? userRole;

  if (authHeader != null && authHeader.startsWith('Bearer ')) {
    final token = authHeader.substring(7);
    final payload = jwtHelper.verifyToken(token);
    userId = payload?['userId'] as String?;
    userRole = payload?['role'] as String?;
  }

  // Логика фильтрации:
  
  // ✅ Диспетчеры и админы - видят ВСЕ заказы
  if (userRole == 'dispatcher' || userRole == 'admin') {
    orders = await orderRepo.findAll(limit: limit);
  }
  // ✅ Обычные пользователи - свои заказы
  else if (userId != null) {
    orders = await orderRepo.findByUserId(userId, limit: limit);
  }
  // 🚨 НЕ авторизованные - ВСЕ заказы (ДЛЯ ОБРАТНОЙ СОВМЕСТИМОСТИ!)
  else {
    orders = await orderRepo.findAll(limit: limit);  // ❌❌❌
  }
}
```

**ПРОБЛЕМА:**
- Строки 84-89: **Если нет токена → возвращаются ВСЕ заказы!**
- Комментарий: "для обратной совместимости" - это огромная дыра в безопасности

---

### 2. Flutter App - Orders Screen
**Файл:** `lib/features/orders/screens/orders_screen.dart`

**Текущая логика (строки 27-48):**

```dart
Future<void> _loadData() async {
  final user = await AuthService.instance.getCurrentUser();
  
  if (user != null) {
    setState(() => _userType = user.userType);

    if (user.userType == UserType.client) {
      // Загружаем заказы клиента
      final bookings = await BookingService().getClientBookings(user.id);
      setState(() => _bookings = bookings);
    } else {
      // Загружаем все активные заказы для диспетчера
      final bookings = await BookingService().getActiveBookings();
      setState(() => _bookings = bookings);
    }
  }
}
```

**Выглядит правильно** - разделяет клиентов и диспетчеров.

---

### 3. BookingService
**Файл:** `lib/services/booking_service.dart`

**Метод getClientBookings (строки 335-370):**

```dart
Future<List<Booking>> getClientBookings(String clientId) async {
  debugPrint('📥 Загрузка бронирований через OrdersService...');
  
  // Получаем заказы через Clean Architecture
  final ordersResult = await _ordersService.getOrders(
    limit: 100, 
    forceRefresh: true
  );
  
  // ❌ НЕТ ФИЛЬТРАЦИИ ПО clientId!
  // Просто возвращаем ВСЕ заказы с backend
  
  if (ordersResult.isSuccess && ordersResult.orders != null) {
    final backendBookings = ordersResult.orders!
        .map((order) => _convertDomainOrderToBooking(order))
        .toList();
    
    allBookings.addAll(backendBookings);
  }
  
  return allBookings;
}
```

**ПРОБЛЕМА:**
- Метод принимает `clientId`, но **НЕ использует его для фильтрации!**
- Просто вызывает `getOrders()` без параметров
- Backend возвращает ВСЕ заказы (т.к. нет токена или токен не проверяется)

**Метод getActiveBookings (строки 508-545):**

```dart
Future<List<Booking>> getActiveBookings() async {
  debugPrint('🔍 Получение активных бронирований через OrdersService...');
  
  final result = await _ordersService.getOrders(limit: 100, forceRefresh: true);
  
  // Фильтрует только по статусу (pending, confirmed, inProgress)
  // Но возвращает ВСЕ заказы всех пользователей!
  
  return bookings;
}
```

**Правильно для диспетчеров**, но также используется для клиентов из-за бага выше.

---

### 4. OrdersService (Clean Architecture)
**Файл:** `lib/services/orders_service.dart`

```dart
Future<OrdersResult> getOrders({
  OrderStatus? status,
  int limit = 100,
  bool forceRefresh = false,
}) async {
  final result = await _repository.getOrders(
    status: status,
    limit: limit,
    forceRefresh: forceRefresh,
  );
  // ...
}
```

**НЕТ ПАРАМЕТРА userId!** - невозможно запросить заказы конкретного пользователя.

---

### 5. OrdersRepository
**Файл:** `lib/data/repositories/orders_repository_impl.dart`

```dart
@override
Future<Either<Failure, List<Order>>> getOrders({
  OrderStatus? status,
  int limit = 100,
  bool forceRefresh = false,
}) async {
  // ...
  final remoteOrders = await remoteDataSource.getOrders(
    status: status?.value,
    limit: limit,
  );
  // ...
}
```

**НЕТ ПАРАМЕТРА userId!**

---

### 6. Remote Data Source (HTTP клиент)
**Файл:** `lib/data/datasources/orders_remote_datasource.dart`

```dart
@override
Future<List<OrderModel>> getOrders({
  String? status,
  int limit = 100,
}) async {
  try {
    final queryParams = <String, dynamic>{
      'limit': limit,
      if (status != null) 'status': status,
    };

    final response = await dio.get(
      '/orders',  // ❌ Запрос БЕЗ фильтрации по пользователю!
      queryParameters: queryParams,
    );
    // ...
  }
}
```

**ПРОБЛЕМА:**
- Запрос `/orders?limit=100` без параметра `userId`
- Backend должен фильтровать по токену, но...

---

### 7. Auth Interceptor (Добавление токена к запросам)
**Файл:** `lib/core/di/service_locator.dart`

```dart
class _AuthInterceptor extends Interceptor {
  final SharedPreferences prefs;

  _AuthInterceptor(this.prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = prefs.getString('access_token');  // ❌ НЕПРАВИЛЬНЫЙ КЛЮЧ!
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

**КРИТИЧЕСКАЯ ПРОБЛЕМА:**
- Читает токен из `SharedPreferences` по ключу `'access_token'`
- НО токен сохраняется по ключу `'auth_access_token_fallback'`!

---

### 8. Auth Storage Service
**Файл:** `lib/services/auth_storage_service.dart`

```dart
class AuthStorageService {
  // FlutterSecureStorage ключи
  static const _accessTokenKey = 'access_token';
  
  // SharedPreferences fallback ключи  
  static const _accessTokenKeyFallback = 'auth_access_token_fallback';  // ❌
  
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKeyFallback, accessToken);  // ❌
      // Сохраняет под НЕПРАВИЛЬНЫМ ключом!
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    }
  }
}
```

**ПРОБЛЕМА:**
- При использовании SharedPreferences сохраняет токен как `'auth_access_token_fallback'`
- Но Dio interceptor читает `'access_token'`
- **Результат: токен НЕ отправляется на backend!**

---

## 🔗 Цепочка проблем

```
1. AuthStorageService сохраняет токен в SharedPreferences:
   ключ: 'auth_access_token_fallback'
   
2. _AuthInterceptor пытается прочитать токен:
   ключ: 'access_token'  ❌ НЕ НАХОДИТ!
   
3. Запрос на backend идёт БЕЗ токена:
   GET /api/orders?limit=100
   Headers: {} (нет Authorization!)
   
4. Backend не может определить пользователя:
   userId = null
   userRole = null
   
5. Backend выполняет fallback для "обратной совместимости":
   else { orders = await orderRepo.findAll(limit: limit); }
   
6. Возвращаются ВСЕ заказы ВСЕХ пользователей! 🚨
```

---

## 🎯 Почему это происходит?

### Сценарий на реальном устройстве (Android):

1. **Пользователь авторизуется** (Кирилл Петров)
   - AuthProvider вызывает `authStorage.saveTokens(...)`
   - FlutterSecureStorage может не работать на некоторых устройствах
   - Fallback: токен сохраняется в SharedPreferences как `'auth_access_token_fallback'`

2. **Пользователь открывает экран "Мои заказы"**
   - OrdersScreen вызывает `BookingService.getClientBookings(user.id)`
   - BookingService вызывает `OrdersService.getOrders()` (БЕЗ userId!)
   - Dio делает запрос `GET /api/orders?limit=100`
   - **Interceptor не находит токен** (ключ не совпадает)
   - Запрос идёт БЕЗ заголовка `Authorization`

3. **Backend получает запрос БЕЗ токена**
   - `authHeader = null`
   - `userId = null`, `userRole = null`
   - Выполняется `else { orders = await orderRepo.findAll(); }`
   - **Возвращаются ВСЕ 8 заказов**

4. **Flutter отображает ВСЕ заказы**
   - Пользователь видит чужие заказы! 🚨

### Сценарий в другом аккаунте (Анастасия Петрова):

**ТО ЖЕ САМОЕ!** Потому что:
- Токен не отправляется (ключ не совпадает)
- Backend возвращает ВСЕ заказы
- Результат: видит те же 8 заказов что и Кирилл

---

## 📋 Список критических багов

### 🔴 КРИТИЧЕСКИЙ #1: Неправильные ключи токена
**Файлы:**
- `lib/core/di/service_locator.dart` (строка ~120)
- `lib/services/auth_storage_service.dart` (строки 13, 87)

**Проблема:**
```dart
// AuthStorageService сохраняет:
prefs.setString('auth_access_token_fallback', accessToken);

// Interceptor читает:
final token = prefs.getString('access_token');  // null!
```

**Решение:**
Использовать единый ключ `'access_token'` везде.

---

### 🔴 КРИТИЧЕСКИЙ #2: Backend возвращает все заказы без токена
**Файл:** `backend/backend/routes/orders/index.dart` (строки 84-89)

**Проблема:**
```dart
else {
  // НЕ авторизованные - ВСЕ заказы
  orders = await orderRepo.findAll(limit: limit);  // ❌
}
```

**Решение:**
Возвращать ошибку `401 Unauthorized` если нет токена:
```dart
else {
  return Response.json(
    statusCode: HttpStatus.unauthorized,
    body: {'error': 'Authentication required'},
  );
}
```

---

### 🔴 КРИТИЧЕСКИЙ #3: getClientBookings не фильтрует по userId
**Файл:** `lib/services/booking_service.dart` (строки 335-370)

**Проблема:**
```dart
Future<List<Booking>> getClientBookings(String clientId) async {
  // clientId ИГНОРИРУЕТСЯ!
  final ordersResult = await _ordersService.getOrders(limit: 100);
  // ...
}
```

**Решение:**
Backend должен фильтровать заказы по токену автоматически.
Или добавить параметр `userId` в API.

---

### 🟡 СРЕДНИЙ #4: Отсутствует параметр userId в Clean Architecture
**Файлы:**
- `lib/services/orders_service.dart`
- `lib/domain/repositories/orders_repository.dart`
- `lib/data/repositories/orders_repository_impl.dart`
- `lib/data/datasources/orders_remote_datasource.dart`

**Проблема:**
Невозможно запросить заказы конкретного пользователя через API.

**Решение:**
Backend должен фильтровать по JWT токену автоматически.

---

## ✅ План исправления

### Этап 1: КРИТИЧЕСКИЙ FIX (немедленно!)

1. **Исправить ключ токена в interceptor:**
   ```dart
   // lib/core/di/service_locator.dart
   final token = prefs.getString('access_token');  // Было
   final token = prefs.getString('auth_access_token_fallback');  // Стало
   ```

2. **Добавить дублирование токена в оба ключа:**
   ```dart
   // lib/services/auth_storage_service.dart
   if (_useSharedPreferences) {
     final prefs = await SharedPreferences.getInstance();
     await Future.wait([
       prefs.setString(_accessTokenKeyFallback, accessToken),
       prefs.setString('access_token', accessToken),  // ✅ Для Dio
       // ...
     ]);
   }
   ```

3. **Убрать fallback "все заказы" из backend:**
   ```dart
   // backend/backend/routes/orders/index.dart
   else {
     return Response.json(
       statusCode: HttpStatus.unauthorized,
       body: {'error': 'Authentication required'},
     );
   }
   ```

### Этап 2: Тестирование

1. Очистить приложение: `flutter clean`
2. Переустановить приложение
3. Авторизоваться под Кирилл Петров
4. Создать 2 тестовых заказа
5. Выйти и авторизоваться под Анастасия Петрова
6. **Проверить: должен видеть ТОЛЬКО свои заказы (0 шт)**
7. Создать 1 тестовый заказ
8. **Проверить: должен видеть 1 заказ**
9. Переключиться в режим диспетчера
10. **Проверить: должен видеть ВСЕ 3 заказа**

### Этап 3: Улучшения (опционально)

1. Добавить роль `admin` вместо `dispatcher`
2. Удалить дублирующую логику из BookingService
3. Использовать только Clean Architecture (OrdersService)
4. Добавить unit-тесты для проверки прав доступа

---

## 📊 Текущее состояние базы данных

**Таблица users:**
```sql
id                                  | role       | name
------------------------------------|------------|------------------
ed7093ae-8020-43fd-b2fa-63f4291b... | client     | Кирилл Петров
...                                 | client     | Анастасия Петрова
```

**Таблица orders:**
```sql
id          | user_id                              | from_address      | to_address
------------|--------------------------------------|-------------------|------------------
9115ad79... | NULL                                 | Донецк            | Ростов
6083f274... | NULL                                 | Ростов            | Донецк
...         | NULL                                 | ...               | ...
```

**ПРОБЛЕМА:**
- Поле `user_id` = `NULL` для всех заказов!
- Это означает что заказы НЕ привязаны к пользователям вообще!

**Почему?**
Потому что создание заказов происходит БЕЗ токена (та же проблема с interceptor).

---

## 🎯 Выводы

### Архитектурные проблемы:

1. **Нет единого источника истины для токенов**
   - AuthStorageService использует свои ключи
   - Dio interceptor использует другие ключи
   - Результат: токены не отправляются

2. **Backend слишком доверчивый**
   - "Для обратной совместимости" возвращает все данные
   - Нет обязательной аутентификации
   - Результат: любой может получить все заказы

3. **Нет связи заказов с пользователями**
   - `user_id` = `NULL` в базе данных
   - Невозможно определить кто создал заказ
   - Результат: все видят все

4. **Дублирующаяся логика**
   - BookingService (старый)
   - OrdersService (новый Clean Architecture)
   - Используются оба одновременно
   - Результат: путаница и баги

---

## 🚨 СРОЧНОСТЬ

**КРИТИЧЕСКАЯ УЯЗВИМОСТЬ:**
- Любой пользователь видит личные данные других пользователей
- Телефоны, адреса, маршруты, цены
- Нарушение GDPR и конфиденциальности

**ТРЕБУЕТСЯ НЕМЕДЛЕННОЕ ИСПРАВЛЕНИЕ!**

---

*Дата анализа: 27 января 2026*
*Аналитик: GitHub Copilot*
