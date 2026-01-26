# 🔧 ПРАКТИЧЕСКОЕ РУКОВОДСТВО: Удаление SQLite

**Цель:** Перевести приложение с SQLite на чистый PostgreSQL через API  
**Время:** 3-4 дня работы  
**Сложность:** Средняя

---

## 📋 ЧТО НУЖНО СДЕЛАТЬ

### ✅ Этап 1: Анализ текущего использования SQLite

**Файлы для удаления:**
```
lib/services/
├── offline_orders_service.dart      ❌ УДАЛИТЬ
├── offline_routes_service.dart      ❌ УДАЛИТЬ  
├── local_routes_service.dart        ❌ УДАЛИТЬ
├── local_route_groups_service.dart  ❌ УДАЛИТЬ
└── orders_sync_service.dart         ❌ УДАЛИТЬ (синхронизация не нужна)
```

**Файлы для ПЕРЕПИСЫВАНИЯ (использовать ТОЛЬКО API):**
```
lib/services/
├── booking_service.dart             🔄 ПЕРЕПИСАТЬ
└── route_service.dart               🔄 ПЕРЕПИСАТЬ (если используется)

lib/features/orders/screens/
└── orders_screen.dart               🔄 ПЕРЕПИСАТЬ

lib/features/booking/screens/
├── group_booking_screen.dart        🔄 ПЕРЕПИСАТЬ
└── individual_booking_screen.dart   🔄 ПЕРЕПИСАТЬ

lib/features/home/screens/
└── dispatcher_home_screen.dart      🔄 ПЕРЕПИСАТЬ
```

---

## 🛠️ ПОШАГОВАЯ ИНСТРУКЦИЯ

### Шаг 1: Создать единый OrdersService (БЕЗ SQLite)

**Создать файл:** `lib/services/orders_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'api/orders_api_service.dart';
import '../models/booking.dart';

/// Единый сервис для работы с заказами
/// Использует ТОЛЬКО backend API (PostgreSQL)
/// БЕЗ локального SQLite кэша
class OrdersService {
  static final OrdersService _instance = OrdersService._internal();
  factory OrdersService() => _instance;
  OrdersService._internal();

  final OrdersApiService _api = OrdersApiService();
  
  // Кэш в памяти (опционально, для скорости)
  List<ApiOrder>? _cachedOrders;
  DateTime? _cacheTime;
  
  /// Получить все заказы
  /// [forceRefresh] - принудительная загрузка с сервера (игнорировать кэш)
  /// [status] - фильтр по статусу (pending, confirmed, completed)
  Future<List<ApiOrder>> getOrders({
    bool forceRefresh = false,
    OrderStatus? status,
    int limit = 100,
  }) async {
    debugPrint('📥 [OrdersService] Загрузка заказов...');
    
    // Если кэш свежий (< 30 сек) и нет фильтров - вернуть кэш
    if (!forceRefresh && status == null && _isCacheFresh()) {
      debugPrint('✅ [OrdersService] Возврат из кэша (${_cachedOrders!.length} заказов)');
      return _cachedOrders!;
    }
    
    try {
      // Загрузка с backend API
      final response = await _api.getOrders(
        status: status,
        limit: limit,
      );
      
      // Обновить кэш только если загружаем все заказы
      if (status == null) {
        _cachedOrders = response.orders;
        _cacheTime = DateTime.now();
      }
      
      debugPrint('✅ [OrdersService] Загружено ${response.orders.length} заказов с API');
      return response.orders;
      
    } catch (e) {
      debugPrint('❌ [OrdersService] Ошибка загрузки заказов: $e');
      
      // Если есть кэш - вернуть его (лучше старые данные, чем ничего)
      if (_cachedOrders != null) {
        debugPrint('⚠️ [OrdersService] Возврат устаревшего кэша');
        return _cachedOrders!;
      }
      
      rethrow;
    }
  }
  
  /// Создать новый заказ
  Future<ApiOrder> createOrder(Booking booking) async {
    debugPrint('📤 [OrdersService] Создание заказа...');
    
    try {
      // Подготовка данных
      DateTime departureDateTime;
      try {
        final timeComponents = booking.departureTime.split(':');
        final hour = int.parse(timeComponents[0]);
        final minute = int.parse(timeComponents[1]);
        
        departureDateTime = DateTime(
          booking.departureDate.year,
          booking.departureDate.month,
          booking.departureDate.day,
          hour,
          minute,
        );
      } catch (e) {
        debugPrint('⚠️ Ошибка парсинга времени: $e');
        departureDateTime = booking.departureDate;
      }
      
      // Конвертируем багаж
      List<Map<String, dynamic>>? baggageList;
      if (booking.baggage.isNotEmpty) {
        baggageList = booking.baggage.map((b) => {
          'size': b.size.toString().split('.').last,
          'quantity': b.quantity,
          'pricePerExtraItem': b.pricePerExtraItem,
          'customDescription': b.customDescription,
        }).toList();
      }
      
      // Конвертируем животных
      List<Map<String, dynamic>>? petsList;
      if (booking.pets.isNotEmpty) {
        petsList = booking.pets.map((p) => {
          'category': p.category.toString().split('.').last,
          'breed': p.breed,
          'cost': p.cost,
        }).toList();
      }
      
      // Конвертируем пассажиров
      List<Map<String, dynamic>>? passengersList;
      if (booking.passengers.isNotEmpty) {
        passengersList = booking.passengers.map((p) => {
          'type': p.type.toString().split('.').last,
        }).toList();
      }
      
      // Отправка на backend API
      final createdOrder = await _api.createOrder(
        fromAddress: booking.pickupAddress ?? 'Не указан',
        toAddress: booking.dropoffAddress ?? 'Не указан',
        departureTime: departureDateTime,
        passengerCount: booking.passengerCount,
        basePrice: booking.basePrice,
        totalPrice: booking.totalPrice,
        notes: booking.comments,
        phone: booking.clientPhone,
        tripType: booking.tripType.toString().split('.').last,
        direction: booking.direction.toString().split('.').last,
        passengers: passengersList,
        baggage: baggageList,
        pets: petsList,
      );
      
      // Обновить кэш - добавить новый заказ в начало
      if (_cachedOrders != null) {
        _cachedOrders!.insert(0, createdOrder);
      }
      
      debugPrint('✅ [OrdersService] Заказ создан: ${createdOrder.id}');
      return createdOrder;
      
    } catch (e) {
      debugPrint('❌ [OrdersService] Ошибка создания заказа: $e');
      rethrow;
    }
  }
  
  /// Обновить статус заказа
  Future<ApiOrder> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    debugPrint('🔄 [OrdersService] Обновление статуса заказа $orderId → ${newStatus.name}');
    
    try {
      final updatedOrder = await _api.updateOrder(
        orderId: orderId,
        status: newStatus,
      );
      
      // Обновить в кэше
      if (_cachedOrders != null) {
        final index = _cachedOrders!.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _cachedOrders![index] = updatedOrder;
        }
      }
      
      debugPrint('✅ [OrdersService] Статус обновлён: $orderId → ${newStatus.name}');
      return updatedOrder;
      
    } catch (e) {
      debugPrint('❌ [OrdersService] Ошибка обновления статуса: $e');
      rethrow;
    }
  }
  
  /// Получить заказ по ID
  Future<ApiOrder> getOrderById(String orderId) async {
    debugPrint('🔍 [OrdersService] Поиск заказа: $orderId');
    
    // Сначала проверить кэш
    if (_cachedOrders != null) {
      final cached = _cachedOrders!.where((o) => o.id == orderId).firstOrNull;
      if (cached != null) {
        debugPrint('✅ [OrdersService] Заказ найден в кэше');
        return cached;
      }
    }
    
    // Если нет в кэше - загрузить с API
    try {
      final order = await _api.getOrderById(orderId);
      debugPrint('✅ [OrdersService] Заказ загружен с API');
      return order;
    } catch (e) {
      debugPrint('❌ [OrdersService] Ошибка получения заказа: $e');
      rethrow;
    }
  }
  
  /// Очистить кэш (например, при выходе из аккаунта)
  void clearCache() {
    _cachedOrders = null;
    _cacheTime = null;
    debugPrint('🗑️ [OrdersService] Кэш очищен');
  }
  
  /// Проверка свежести кэша
  bool _isCacheFresh() {
    if (_cacheTime == null || _cachedOrders == null) return false;
    
    final age = DateTime.now().difference(_cacheTime!);
    return age < const Duration(seconds: 30);  // Кэш валиден 30 секунд
  }
}
```

---

### Шаг 2: Обновить BookingService

**Файл:** `lib/services/booking_service.dart`

**БЫЛО (с SQLite):**
```dart
Future<String> createBooking(Booking booking) async {
  // 1. Сохранить в SQLite
  await OfflineOrdersService.instance.saveOrder(order);
  
  // 2. Попытаться отправить на backend
  try {
    await _ordersApi.createOrder(...);
  } catch (e) {
    // Синхронизируем позже
  }
}
```

**СТАЛО (только API):**
```dart
import 'orders_service.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final OrdersService _ordersService = OrdersService();

  /// Создание нового бронирования
  Future<String> createBooking(Booking booking) async {
    debugPrint('📤 Создание бронирования через OrdersService...');
    
    try {
      // Отправка СРАЗУ на backend (без SQLite)
      final createdOrder = await _ordersService.createOrder(booking);
      
      debugPrint('✅ Бронирование создано: ${createdOrder.orderId}');
      
      // Уведомление пользователя
      await NotificationService.instance.showNotification(
        title: '✅ Заказ создан',
        body: 'Ожидает подтверждения диспетчера',
      );
      
      return createdOrder.orderId;
      
    } catch (e) {
      debugPrint('❌ Ошибка создания бронирования: $e');
      
      // Уведомление об ошибке
      await NotificationService.instance.showNotification(
        title: '❌ Ошибка',
        body: 'Не удалось создать заказ. Проверьте интернет.',
      );
      
      rethrow;
    }
  }
  
  /// Получить список бронирований
  Future<List<Booking>> getAllBookings({bool forceRefresh = false}) async {
    try {
      final orders = await _ordersService.getOrders(forceRefresh: forceRefresh);
      
      // Конвертировать ApiOrder → Booking
      return orders.map((apiOrder) => Booking.fromApiOrder(apiOrder)).toList();
      
    } catch (e) {
      debugPrint('❌ Ошибка загрузки бронирований: $e');
      return [];
    }
  }
}
```

---

### Шаг 3: Обновить OrdersScreen (экран заказов)

**Файл:** `lib/features/orders/screens/orders_screen.dart`

**УДАЛИТЬ:**
```dart
// ❌ УДАЛИТЬ ВСЁ ЭТО:
import '../../../services/offline_orders_service.dart';
final orders = await OfflineOrdersService.instance.getAllOrders();
```

**ДОБАВИТЬ:**
```dart
import '../../../services/orders_service.dart';

class _OrdersScreenState extends State<OrdersScreen> {
  final OrdersService _ordersService = OrdersService();
  List<Booking> _bookings = [];
  bool _isLoading = true;
  OrderStatus? _filterStatus;  // pending, confirmed, completed
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      debugPrint('🔍 Загрузка заказов с сервера...');
      
      // Загрузка с backend API
      final orders = await _ordersService.getOrders(
        forceRefresh: true,  // Всегда свежие данные
        status: _filterStatus,
        limit: 100,
      );
      
      // Конвертация ApiOrder → Booking
      final bookings = orders.map((order) => 
        Booking.fromApiOrder(order)
      ).toList();
      
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
      
      debugPrint('✅ Загружено ${bookings.length} заказов');
      
    } catch (e) {
      debugPrint('❌ Ошибка загрузки заказов: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      // Показать ошибку
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки заказов: $e')),
        );
      }
    }
  }
  
  // Pull-to-refresh
  Future<void> _handleRefresh() async {
    await _loadData();
  }
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _bookings.length,
            itemBuilder: (context, index) {
              final booking = _bookings[index];
              return OrderCard(booking: booking);
            },
          ),
    );
  }
}
```

---

### Шаг 4: Удалить модели с полем `isSynced`

**Файл:** `lib/models/taxi_order.dart`

```dart
class TaxiOrder {
  // ❌ УДАЛИТЬ:
  // final bool isSynced;
  
  // ❌ УДАЛИТЬ из toMap():
  // 'isSynced': isSynced ? 1 : 0,
  
  // ❌ УДАЛИТЬ из fromMap():
  // isSynced: (map['isSynced'] ?? 0) == 1,
  
  // ❌ УДАЛИТЬ из copyWith():
  // bool? isSynced,
}
```

---

### Шаг 5: Удалить файлы SQLite сервисов

```bash
cd /Users/kirillpetrov/Projects/time-to-travel

# Удалить SQLite сервисы
rm lib/services/offline_orders_service.dart
rm lib/services/offline_routes_service.dart
rm lib/services/local_routes_service.dart
rm lib/services/local_route_groups_service.dart
rm lib/services/orders_sync_service.dart

# Удалить из pubspec.yaml (если есть)
# sqflite: ^2.3.0  ❌ УДАЛИТЬ
# path: ^1.8.3     (оставить, используется для других целей)
```

---

### Шаг 6: Обновить pubspec.yaml

**Файл:** `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP клиент (ОСТАВИТЬ)
  dio: ^5.4.0
  
  # Хранилище для токенов и настроек (ОСТАВИТЬ)
  shared_preferences: ^2.2.2
  
  # ❌ УДАЛИТЬ SQLite:
  # sqflite: ^2.3.0
  # sqflite_common_ffi: ^2.3.0
  
  # Остальные зависимости...
```

---

## 🧪 ТЕСТИРОВАНИЕ

### Тест 1: Создание заказа

```dart
// 1. Открыть приложение
// 2. Создать новый заказ (Групповая поездка)
// 3. Заполнить все поля
// 4. Нажать "Забронировать"

// Ожидаемый результат:
// ✅ Заказ создан МГНОВЕННО на сервере
// ✅ Диспетчер видит заказ БЕЗ ЗАДЕРЖКИ
// ✅ В логах: "✅ [OrdersService] Заказ создан: ORDER-2026-01-XXX"
```

### Тест 2: Просмотр заказов диспетчером

```dart
// 1. Войти как диспетчер
// 2. Открыть раздел "Заказы"
// 3. Потянуть вниз (pull-to-refresh)

// Ожидаемый результат:
// ✅ Загружены ВСЕ заказы с PostgreSQL
// ✅ Время загрузки: < 2 секунд
// ✅ В логах: "✅ [OrdersService] Загружено X заказов с API"
```

### Тест 3: Обновление статуса

```dart
// 1. Диспетчер выбирает pending заказ
// 2. Нажимает "Подтвердить"

// Ожидаемый результат:
// ✅ Статус изменён на "confirmed" МГНОВЕННО
// ✅ В PostgreSQL: status = 'confirmed'
// ✅ Клиент видит обновлённый статус при следующем обновлении
```

### Тест 4: Работа без интернета

```dart
// 1. Отключить WiFi и мобильные данные
// 2. Открыть раздел "Заказы"

// Ожидаемый результат:
// ⚠️ Показан кэш (если был)
// ИЛИ
// ❌ Сообщение "Ошибка загрузки. Проверьте интернет."

// 3. Попытаться создать заказ

// Ожидаемый результат:
// ❌ Ошибка: "Не удалось создать заказ. Проверьте интернет."
// ❌ Заказ НЕ создан (это ПРАВИЛЬНО!)
```

---

## 📊 ПРОВЕРКА РЕЗУЛЬТАТОВ

### До миграции (SQLite + PostgreSQL):

```
Клиент создаёт заказ:
  ✅ Сохранено в SQLite
  ⏳ Синхронизация...
  ⏳ Отправка на сервер... (5-10 сек)
  ✅ Сохранено в PostgreSQL

Диспетчер открывает "Заказы":
  📥 Загрузка из SQLite
  ⚠️ Данные могут быть УСТАРЕВШИМИ!
  ⏳ Синхронизация...
  ✅ Обновлено с PostgreSQL (ещё 5 сек)

Итого: ~15 секунд задержки
```

### После миграции (только PostgreSQL):

```
Клиент создаёт заказ:
  📤 Отправка на PostgreSQL (2-3 сек)
  ✅ Сохранено

Диспетчер открывает "Заказы":
  📥 Загрузка из PostgreSQL (1-2 сек)
  ✅ Всегда актуальные данные!

Итого: ~3 секунды, данные ВСЕГДА актуальны
```

---

## ⚠️ ВАЖНЫЕ ЗАМЕЧАНИЯ

### 1. Обработка ошибок сети

```dart
try {
  await _ordersService.createOrder(booking);
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    _showError('Нет интернета. Проверьте подключение.');
  } else if (e.response?.statusCode == 401) {
    _showError('Требуется авторизация');
  } else {
    _showError('Ошибка сервера: ${e.message}');
  }
} catch (e) {
  _showError('Неизвестная ошибка: $e');
}
```

### 2. Индикатор загрузки

```dart
Widget build(BuildContext context) {
  return Scaffold(
    body: RefreshIndicator(
      onRefresh: _loadData,
      child: _isLoading && _bookings.isEmpty
        ? Center(child: CircularProgressIndicator())  // Первая загрузка
        : _bookings.isEmpty
          ? Center(child: Text('Нет заказов'))
          : ListView.builder(...),  // Показываем данные
    ),
  );
}
```

### 3. Кэш для скорости

```dart
// При первом открытии экрана:
await _ordersService.getOrders(forceRefresh: true);  // Загрузка

// При переключении между экранами:
await _ordersService.getOrders(forceRefresh: false);  // Из кэша (быстро!)

// Pull-to-refresh:
await _ordersService.getOrders(forceRefresh: true);  // Обновление
```

---

## ✅ ЧЕКЛИСТ МИГРАЦИИ

- [ ] Создан `lib/services/orders_service.dart`
- [ ] Обновлён `lib/services/booking_service.dart`
- [ ] Обновлён `lib/features/orders/screens/orders_screen.dart`
- [ ] Обновлён `lib/features/booking/screens/group_booking_screen.dart`
- [ ] Обновлён `lib/features/home/screens/dispatcher_home_screen.dart`
- [ ] Удалено поле `isSynced` из `lib/models/taxi_order.dart`
- [ ] Удалён `lib/services/offline_orders_service.dart`
- [ ] Удалён `lib/services/offline_routes_service.dart`
- [ ] Удалён `lib/services/local_routes_service.dart`
- [ ] Удалён `lib/services/local_route_groups_service.dart`
- [ ] Удалён `lib/services/orders_sync_service.dart`
- [ ] Удалена зависимость `sqflite` из `pubspec.yaml`
- [ ] Выполнен `flutter pub get`
- [ ] Протестировано создание заказа
- [ ] Протестировано отображение заказов у диспетчера
- [ ] Протестирована работа без интернета
- [ ] Проверены логи (нет ошибок)

---

**Готовы начать миграцию?** 🚀
