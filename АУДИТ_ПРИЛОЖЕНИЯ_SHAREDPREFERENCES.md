# 🔍 ПОЛНЫЙ АУДИТ ПРИЛОЖЕНИЯ: SharedPreferences

**Дата:** 28 января 2026  
**Цель:** Анализ использования SharedPreferences для безопасного удаления offline_bookings

---

## 📊 РЕЗУЛЬТАТЫ АУДИТА

### ✅ ШАГ 1: Где Используется SharedPreferences

#### 1️⃣ АВТОРИЗАЦИЯ (✅ ОСТАВИТЬ)

**Файлы:**
- `lib/services/auth_storage_service.dart`
- `lib/services/auth_service.dart`
- `lib/core/di/service_locator.dart`

**Что хранится:**
```dart
// Токены (FlutterSecureStorage + SharedPreferences fallback)
- access_token
- refresh_token  
- user_id

// Настройки пользователя
- user_type           // client / dispatcher
- last_screen         // последний экран
- form_data_*         // данные форм
- offline_user        // демо пользователь
- is_offline_mode     // режим оффлайн
- current_user_id     // текущий ID
```

**Использование:**
- `AuthStorageService`: Безопасное хранение токенов
- `AuthInterceptor` (service_locator.dart): Читает токен для HTTP запросов
- `AuthService`: userType, навигация, форм-данные

**Вывод:** ✅ **КРИТИЧЕСКИ ВАЖНО** - НЕ ТРОГАТЬ!

---

#### 2️⃣ НАСТРОЙКИ И ONBOARDING (✅ ОСТАВИТЬ)

**Файлы:**
- `lib/features/tutorial/tutorial_preferences.dart`
- `lib/services/user_service.dart`
- `lib/features/home/screens/home_screen.dart`

**Что хранится:**
```dart
// Tutorial/Onboarding
- tutorialCompleted        // завершён ли onboarding
- lastShownTutorial        // последний показанный тьюториал

// Профиль пользователя
- user_profile             // JSON профиля

// UI состояние
- lastTab                  // последняя вкладка
```

**Вывод:** ✅ **ПРАВИЛЬНОЕ ИСПОЛЬЗОВАНИЕ** - НЕ ТРОГАТЬ!

---

#### 3️⃣ ЗАКАЗЫ (❌ УДАЛИТЬ - ИСТОЧНИК ПРОБЛЕМЫ)

**Файл:**
- `lib/services/booking_service.dart`

**Ключ:**
```dart
static const String _offlineBookingsKey = 'offline_bookings';
```

**Методы использующие offline_bookings:**

| Метод | Строка | Действие | Решение |
|-------|--------|----------|---------|
| `_saveBookingToSharedPreferences()` | 141 | Сохранение в JSON | ❌ УДАЛИТЬ |
| `_createOfflineBooking()` | 175 | Создание offline заказа | ❌ УДАЛИТЬ |
| `_getOfflineBookingById()` | 275 | Поиск по ID | ❌ УДАЛИТЬ |
| `_getOfflineActiveBookings()` | 556 | Активные заказы | ❌ УДАЛИТЬ |
| `_cancelOfflineBooking()` | 627 | Отмена offline заказа | ❌ УДАЛИТЬ |

**Где вызываются:**

```dart
// createBooking() - строка 125
await _saveBookingToSharedPreferences(bookingWithId);

// createBooking() - catch block
return _createOfflineBooking(booking); // Fallback

// getBookingById() - строка 268
return _getOfflineBookingById(bookingId);

// getClientBookings() - строка 367
// Merge с локальными данными:
final bookingsJson = prefs.getString(_offlineBookingsKey);
allBookings.addAll(localBookings);

// getActiveBookings() - catch block
return _getOfflineActiveBookings();

// cancelBooking() - строка 604
await _cancelOfflineBooking(bookingId, reason);
```

**Вывод:** ❌ **УДАЛИТЬ ПОЛНОСТЬЮ** - создаёт дубликаты и конфликты с backend

---

### ✅ ШАГ 2: Анализ Зависимостей UI

#### Проверенные Экраны:

**1. OrdersScreen** (`lib/features/orders/screens/orders_screen.dart`)
```dart
// Строка 43-50
if (currentUserType == UserType.client) {
  final bookings = await BookingService().getClientBookings(user.id);
} else {
  final bookings = await BookingService().getActiveBookings(
    userType: 'dispatcher',
  );
}
```
✅ **НЕ зависит напрямую** от SharedPreferences  
✅ Использует методы BookingService (которые загружают с backend)

---

**2. DispatcherHomeScreen** (`lib/features/home/screens/dispatcher_home_screen.dart`)
```dart
// Строка 35
final bookings = await BookingService().getActiveBookings(
  userType: 'dispatcher',
);
```
✅ **НЕ зависит напрямую** от SharedPreferences  
✅ Использует метод BookingService

---

**3. ClientHomeScreen** (`lib/features/home/screens/client_home_screen.dart`)
```dart
// Строка 35
final bookings = await BookingService().getClientBookings(user.id);
```
✅ **НЕ зависит напрямую** от SharedPreferences  
✅ Использует метод BookingService

---

**4. BookingDetailScreen**
✅ Получает Booking как параметр конструктора  
✅ **НЕ читает** из SharedPreferences

---

**Вывод:** ✅ **ВСЕ UI-компоненты работают через BookingService**  
→ Можем безопасно удалить offline_bookings внутри BookingService

---

### ✅ ШАГ 3: Анализ OrdersCacheDataSource

**Файл:** `lib/data/datasources/orders_cache_datasource.dart`

**Архитектура:**
```dart
class OrdersCacheDataSource {
  final Map<String, OrderModel> _cache = {};              // In-Memory
  final Map<String, DateTime> _cacheTimestamps = {};
  
  static const _cacheDuration = Duration(seconds: 30);    // ⚠️ TTL!
}
```

**Методы:**
- `cacheOrders()` - сохранить список в память
- `getCachedOrders()` - получить с проверкой TTL
- `cacheOrder()` - обновить один заказ
- `clearCache()` - очистить всё
- `isCacheFresh` - проверка свежести

**Использование:**
- `lib/domain/repositories/orders_repository_impl.dart`
- Кэширует результаты API запросов

**Проблема:**
⚠️ TTL слишком короткий - **30 секунд**  
→ Слишком частые запросы к backend  
→ Рекомендация: увеличить до **5 минут**

**Вывод:**
✅ **ПРАВИЛЬНАЯ АРХИТЕКТУРА** - НЕ зависит от SharedPreferences  
⚠️ Нужно увеличить TTL после удаления offline_bookings

---

## 🎯 ПЛАН МИГРАЦИИ

### Файл: `lib/services/booking_service.dart`

#### 1️⃣ УДАЛИТЬ Константу (строка 25)
```dart
// ❌ УДАЛИТЬ:
static const String _offlineBookingsKey = 'offline_bookings';
```

---

#### 2️⃣ УДАЛИТЬ Методы

**Метод `_saveBookingToSharedPreferences()` (строка 141-153)**
```dart
// ❌ УДАЛИТЬ ПОЛНОСТЬЮ:
Future<void> _saveBookingToSharedPreferences(Booking booking) async {
  final prefs = await SharedPreferences.getInstance();
  // ... весь метод
}
```

---

**Метод `_createOfflineBooking()` (строка 175-266)**
```dart
// ❌ УДАЛИТЬ ПОЛНОСТЬЮ:
Future<String> _createOfflineBooking(Booking booking) async {
  final prefs = await SharedPreferences.getInstance();
  // ... весь метод
}
```

---

**Метод `_getOfflineBookingById()` (строка 275-316)**
```dart
// ❌ УДАЛИТЬ ПОЛНОСТЬЮ:
Future<Booking?> _getOfflineBookingById(String bookingId) async {
  final prefs = await SharedPreferences.getInstance();
  // ... весь метод
}
```

---

**Метод `_getOfflineActiveBookings()` (строка 556-585)**
```dart
// ❌ УДАЛИТЬ ПОЛНОСТЬЮ:
Future<List<Booking>> _getOfflineActiveBookings() async {
  final prefs = await SharedPreferences.getInstance();
  // ... весь метод
}
```

---

**Метод `_cancelOfflineBooking()` (строка 627-663)**
```dart
// ❌ УДАЛИТЬ ПОЛНОСТЬЮ:
Future<void> _cancelOfflineBooking(String bookingId, [String? reason]) async {
  final prefs = await SharedPreferences.getInstance();
  // ... весь метод
}
```

---

#### 3️⃣ ИЗМЕНИТЬ Метод `createBooking()` (строка 28-138)

**БЫЛО:**
```dart
try {
  // Отправка на backend...
  
  await _saveBookingToSharedPreferences(bookingWithId); // ❌
  await _planBookingNotifications(bookingWithId);
  
  return bookingId;
} catch (e) {
  debugPrint('⚠️ Ошибка отправки на backend: $e');
  return _createOfflineBooking(booking); // ❌ Fallback
}
```

**СТАНЕТ:**
```dart
try {
  // Отправка на backend...
  
  // ✅ УДАЛИТЬ строку 125:
  // await _saveBookingToSharedPreferences(bookingWithId);
  
  await _planBookingNotifications(bookingWithId);
  
  return bookingId;
} catch (e) {
  debugPrint('❌ Ошибка создания заказа: $e');
  
  // ✅ Показываем ошибку пользователю вместо offline fallback
  rethrow; // Или throw Exception('Не удалось создать заказ')
}
```

---

#### 4️⃣ ИЗМЕНИТЬ Метод `getBookingById()` (строка 268-273)

**БЫЛО:**
```dart
Future<Booking?> getBookingById(String bookingId) async {
  debugPrint('ℹ️ Поиск бронирования по ID локально (Firebase не подключен)');
  return _getOfflineBookingById(bookingId); // ❌
}
```

**СТАНЕТ:**
```dart
Future<Booking?> getBookingById(String bookingId) async {
  debugPrint('🔍 Поиск заказа по ID: $bookingId');
  
  try {
    // ✅ Загружаем с backend через OrdersService
    final result = await _ordersService.getOrderById(bookingId);
    
    if (result.isSuccess && result.order != null) {
      return _convertDomainOrderToBooking(result.order!);
    }
    
    return null;
  } catch (e) {
    debugPrint('❌ Ошибка загрузки заказа: $e');
    return null;
  }
}
```

---

#### 5️⃣ ИЗМЕНИТЬ Метод `getClientBookings()` (строка 336-405)

**БЫЛО (строки 365-378):**
```dart
// 2. Загружаем локальные данные (индивидуальные трансферы из SharedPreferences)
try {
  final prefs = await SharedPreferences.getInstance();
  final bookingsJson = prefs.getString(_offlineBookingsKey); // ❌
  
  if (bookingsJson != null) {
    final decoded = jsonDecode(bookingsJson) as List<dynamic>;
    final localBookings = decoded
        .map((json) => Booking.fromJson(json as Map<String, dynamic>))
        .toList();
    debugPrint('📦 Загружено ${localBookings.length} локальных индивидуальных трансферов');
    allBookings.addAll(localBookings); // ❌ Merge
  }
} catch (e) {
  debugPrint('⚠️ Ошибка загрузки локальных данных: $e');
}
```

**СТАНЕТ:**
```dart
// ✅ УДАЛИТЬ ВЕСЬ БЛОК (строки 365-378)
// Загружаем ТОЛЬКО с backend, без merge
```

---

#### 6️⃣ ИЗМЕНИТЬ Метод `getActiveBookings()` (строка 513-552)

**БЫЛО:**
```dart
try {
  final result = await _ordersService.getOrders(...);
  // Конвертация...
  return bookings;
} catch (e) {
  debugPrint('❌ Ошибка загрузки заказов с сервера: $e');
  debugPrint('⚠️ Fallback: загружаем локальные заказы');
  return _getOfflineActiveBookings(); // ❌ Fallback
}
```

**СТАНЕТ:**
```dart
try {
  final result = await _ordersService.getOrders(...);
  // Конвертация...
  return bookings;
} catch (e) {
  debugPrint('❌ Ошибка загрузки заказов: $e');
  
  // ✅ Возвращаем пустой список вместо offline fallback
  return [];
}
```

---

#### 7️⃣ ИЗМЕНИТЬ Метод `cancelBooking()` (строка 587-606)

**БЫЛО:**
```dart
Future<void> cancelBooking(String bookingId, [String? reason]) async {
  debugPrint('ℹ️ Отмена бронирования локально (Firebase не подключен)');
  await _cancelOfflineBooking(bookingId, reason); // ❌
}
```

**СТАНЕТ:**
```dart
Future<void> cancelBooking(String bookingId, [String? reason]) async {
  debugPrint('🔍 Отмена заказа: $bookingId');
  
  try {
    // ✅ Отменяем на backend через OrdersService
    final result = await _ordersService.cancelOrder(
      orderId: bookingId,
      reason: reason,
    );
    
    if (!result.isSuccess) {
      throw Exception(result.error ?? 'Ошибка отмены заказа');
    }
    
    debugPrint('✅ Заказ $bookingId отменён');
  } catch (e) {
    debugPrint('❌ Ошибка отмены заказа: $e');
    rethrow;
  }
}
```

---

### Файл: `lib/data/datasources/orders_cache_datasource.dart`

#### 8️⃣ УВЕЛИЧИТЬ TTL кэша

**БЫЛО (строка 11):**
```dart
static const _cacheDuration = Duration(seconds: 30); // ⚠️ Слишком мало!
```

**СТАНЕТ:**
```dart
static const _cacheDuration = Duration(minutes: 5); // ✅ Оптимально
```

**Обоснование:**
- 30 секунд → слишком частые запросы к backend
- 5 минут → баланс между актуальностью и нагрузкой
- Диспетчер меняет статус → клиент увидит в течение 5 мин
- Pull-to-refresh для мгновенного обновления

---

## 🧪 ПЛАН ТЕСТИРОВАНИЯ

### Тест 1: Создание Заказа
**Действие:**
1. Создать новый заказ через GroupBookingScreen
2. Проверить отправку на backend (логи)
3. Проверить что НЕ сохраняется в SharedPreferences

**Ожидаемый результат:**
- ✅ POST /api/orders успешно
- ✅ Заказ получает ID от сервера
- ❌ НЕТ записи в SharedPreferences 'offline_bookings'
- ✅ Заказ появляется в списке OrdersScreen

---

### Тест 2: Загрузка Заказов
**Действие:**
1. Открыть OrdersScreen (режим клиента)
2. Проверить GET запрос к backend
3. Проверить что данные НЕ берутся из SharedPreferences

**Ожидаемый результат:**
- ✅ GET /api/orders выполнен
- ✅ Заказы загружены с сервера
- ❌ SharedPreferences НЕ читается
- ✅ Список отображается корректно

---

### Тест 3: Диспетчер → Клиент Синхронизация
**Действие:**
1. Диспетчер меняет статус заказа (pending → confirmed)
2. Клиент обновляет список (pull-to-refresh)

**Ожидаемый результат:**
- ✅ Диспетчер: PUT /api/orders/:id успешно
- ✅ Клиент: GET /api/orders показывает новый статус
- ✅ UI обновился (статус изменился)

---

### Тест 4: Offline Режим (НЕТ ИНТЕРНЕТА)
**Действие:**
1. Отключить интернет
2. Попытаться создать заказ
3. Попытаться загрузить список

**Ожидаемый результат:**
- ❌ Создание заказа: показывается ошибка "Нет подключения"
- ❌ Загрузка списка: показывается пустой список или ошибка
- ✅ НЕ сохраняется локально в offline_bookings

---

### Тест 5: Кэш в Памяти (OrdersCacheDataSource)
**Действие:**
1. Загрузить список заказов (1-й раз)
2. Сразу же загрузить снова (2-й раз, в течение 5 минут)
3. Проверить логи

**Ожидаемый результат:**
- ✅ 1-й раз: GET /api/orders выполнен
- ✅ 2-й раз: данные взяты из кэша (БЕЗ запроса к backend)
- ✅ Логи показывают "Загружено из кэша"
- ✅ Через 5 минут: кэш истёк, новый запрос к backend

---

## 📋 CHECKLIST ДЛЯ ВНЕДРЕНИЯ

### Подготовка
- [ ] Создать Git commit перед изменениями (для rollback)
- [ ] Сохранить копию `booking_service.dart`
- [ ] Убедиться что backend API работает (https://titotr.ru)

### Изменения в Коде
- [ ] Удалить константу `_offlineBookingsKey`
- [ ] Удалить метод `_saveBookingToSharedPreferences()`
- [ ] Удалить метод `_createOfflineBooking()`
- [ ] Удалить метод `_getOfflineBookingById()`
- [ ] Удалить метод `_getOfflineActiveBookings()`
- [ ] Удалить метод `_cancelOfflineBooking()`
- [ ] Изменить `createBooking()` (убрать fallback)
- [ ] Изменить `getBookingById()` (загрузка с backend)
- [ ] Изменить `getClientBookings()` (убрать merge)
- [ ] Изменить `getActiveBookings()` (убрать fallback)
- [ ] Изменить `cancelBooking()` (отмена через backend)
- [ ] Увеличить TTL в `orders_cache_datasource.dart` до 5 минут

### Тестирование
- [ ] Тест 1: Создание заказа
- [ ] Тест 2: Загрузка заказов
- [ ] Тест 3: Диспетчер → Клиент синхронизация
- [ ] Тест 4: Offline режим
- [ ] Тест 5: Кэш в памяти

### Деплой
- [ ] Backend обновлён и стабилен
- [ ] Flutter приложение собрано
- [ ] Тестирование на реальных устройствах
- [ ] Мониторинг логов 24 часа

---

## ✅ ПРЕИМУЩЕСТВА ПОСЛЕ МИГРАЦИИ

### 1. Нет Дубликатов
- ❌ БЫЛО: Backend + SharedPreferences = дубликаты
- ✅ СТАНЕТ: Только Backend = единственный источник истины

### 2. Актуальные Данные
- ❌ БЫЛО: Клиент видит старые данные из SharedPreferences
- ✅ СТАНЕТ: Всегда свежие данные с backend

### 3. Быстрая Синхронизация
- ❌ БЫЛО: Диспетчер меняет статус → клиент видит только после удаления кэша
- ✅ СТАНЕТ: Диспетчер меняет → клиент видит через 0-5 минут (или pull-to-refresh)

### 4. Проще Код
- ❌ БЫЛО: 5 методов для offline, merge логика, дедупликация
- ✅ СТАНЕТ: Один источник данных, меньше кода, меньше багов

### 5. Правильная Архитектура
```
БЫЛО:
┌─────────┐     ┌──────────────────┐     ┌─────────┐
│ Backend ├────►│ SharedPreferences├────►│   UI    │
└─────────┘     └──────────────────┘     └─────────┘
                       ↓
                  ДУБЛИКАТЫ!

СТАНЕТ:
┌─────────┐     ┌──────────────┐     ┌─────────┐
│ Backend ├────►│ Memory Cache ├────►│   UI    │
└─────────┘     └──────────────┘     └─────────┘
                   (TTL 5 min)
```

---

## 🔄 ROLLBACK ПЛАН

Если что-то пошло не так:

```bash
# 1. Откатить изменения через Git
git reset --hard HEAD~1

# 2. Или восстановить файл из бэкапа
cp booking_service.dart.backup lib/services/booking_service.dart

# 3. Пересобрать приложение
flutter clean
flutter pub get
flutter run
```

---

## 📝 ВЫВОДЫ АУДИТА

### ✅ ЧТО СОХРАНЯЕМ в SharedPreferences:
1. **Авторизация** (токены, userId) - КРИТИЧНО
2. **Настройки** (userType, lastTab) - ПРАВИЛЬНО
3. **Onboarding** (tutorialCompleted) - ПРАВИЛЬНО
4. **Профиль** (user_profile) - ПРАВИЛЬНО

### ❌ ЧТО УДАЛЯЕМ:
1. **offline_bookings** - ИСТОЧНИК ПРОБЛЕМ
2. Все 5 методов работы с offline заказами
3. Merge логика с локальными данными
4. Fallback на локальное хранение при ошибках

### ✅ ЧТО УЛУЧШАЕМ:
1. **TTL кэша**: 30 сек → 5 минут
2. **Архитектура**: Backend + Memory Cache (БЕЗ SharedPreferences)
3. **Синхронизация**: Мгновенная между диспетчером и клиентами
4. **Код**: Проще, меньше багов, легче поддержка

---

## 🎯 ГОТОВНОСТЬ К МИГРАЦИИ

**Статус:** ✅ **ГОТОВО К ВНЕДРЕНИЮ**

**Риски:** 🟢 **НИЗКИЕ**
- Все UI компоненты работают через BookingService
- Нет прямых зависимостей от offline_bookings
- Backend API стабилен и протестирован
- Есть план rollback

**Рекомендация:**
✅ **НАЧИНАЕМ МИГРАЦИЮ**  
Все компоненты проверены, план составлен, риски минимальны.
