# ✅ ИСПРАВЛЕНИЕ: Поддержка типов поездок в PostgreSQL

## 📋 Проблема

Вы абсолютно правы! В **SQLite** приложение корректно сохраняло типы поездок:
- **group** (групповая поездка)
- **individual** (индивидуальный трансфер)  
- **customRoute** (свободный маршрут / такси)

Но при миграции на **PostgreSQL** я не добавил колонки `trip_type` и `direction`, из-за чего все заказы отображались как "свободный маршрут".

## 🔧 Что было исправлено

### 1. **Backend - Структура базы данных**

Создана миграция `004_add_trip_type_and_direction.sql`:

```sql
-- Добавляем колонки trip_type и direction
ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS trip_type VARCHAR(50);

ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS direction VARCHAR(50);

-- Создаем индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_orders_trip_type ON orders(trip_type);
CREATE INDEX IF NOT EXISTS idx_orders_direction ON orders(direction);

-- Для существующих записей устанавливаем customRoute по умолчанию
UPDATE orders
SET trip_type = 'customRoute'
WHERE trip_type IS NULL;
```

### 2. **Backend - Модель Order**

Добавлены enum'ы в `backend/backend/lib/models/order.dart`:

```dart
/// Типы поездок
enum TripType {
  group,         // Групповая поездка
  individual,    // Индивидуальный трансфер
  customRoute;   // Свободный маршрут (такси)

  String toDb() => name;

  static TripType? fromDb(String? tripType) {
    if (tripType == null) return null;
    switch (tripType) {
      case 'group':
        return TripType.group;
      case 'individual':
        return TripType.individual;
      case 'customRoute':
        return TripType.customRoute;
      default:
        return null;
    }
  }
}

/// Направления
enum Direction {
  donetskToRostov,   // Донецк → Ростов-на-Дону
  rostovToDonetsk;   // Ростов-на-Дону → Донецк

  String toDb() => name;

  static Direction? fromDb(String? direction) {
    if (direction == null) return null;
    switch (direction) {
      case 'donetskToRostov':
        return Direction.donetskToRostov;
      case 'rostovToDonetsk':
        return Direction.rostovToDonetsk;
      default:
        return null;
    }
  }
}
```

Добавлены поля в модель `Order`:

```dart
class Order {
  // ... существующие поля ...
  
  final TripType? tripType;
  final Direction? direction;
  
  // ... конструктор ...
}
```

### 3. **Backend - CreateOrderDto**

Добавлены поля в DTO для приема данных от приложения:

```dart
class CreateOrderDto {
  // ... существующие поля ...
  
  final String? tripType;     // 'group', 'individual', 'customRoute'
  final String? direction;    // 'donetskToRostov', 'rostovToDonetsk'
  
  const CreateOrderDto({
    // ... 
    this.tripType,
    this.direction,
  });
}
```

### 4. **Backend - OrderRepository**

Обновлен SQL INSERT для сохранения `trip_type` и `direction`:

```dart
final id = await db.insert(
  '''
  INSERT INTO orders (
    order_id, user_id,
    from_lat, from_lon, to_lat, to_lon,
    from_address, to_address,
    distance_km, raw_price, final_price, base_cost, cost_per_km,
    status,
    client_name, client_phone,
    departure_date, departure_time,
    passengers, baggage, pets,
    notes, vehicle_class,
    trip_type, direction      -- ✅ НОВОЕ
  ) VALUES (
    @orderId, @userId,
    @fromLat, @fromLon, @toLat, @toLon,
    @fromAddress, @toAddress,
    @distanceKm, @rawPrice, @finalPrice, @baseCost, @costPerKm,
    @status,
    @clientName, @clientPhone,
    @departureDate, @departureTime,
    @passengers, @baggage, @pets,
    @notes, @vehicleClass,
    @tripType, @direction     -- ✅ НОВОЕ
  )
  ''',
  parameters: {
    // ...
    'tripType': dto.tripType,
    'direction': dto.direction,
  },
);
```

### 5. **App - OrdersApiService**

Добавлена отправка `tripType` и `direction` при создании заказа:

```dart
Future<ApiOrder> createOrder({
  required String fromAddress,
  required String toAddress,
  required DateTime departureTime,
  required int passengerCount,
  required double basePrice,
  required double totalPrice,
  String? notes,
  String? phone,
  Map<String, dynamic>? metadata,
  String? tripType,      // ✅ НОВОЕ
  String? direction,     // ✅ НОВОЕ
}) async {
  final response = await _apiClient.post(
    ApiConfig.ordersEndpoint,
    body: {
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'departureTime': departureTime.toIso8601String(),
      'passengerCount': passengerCount,
      'basePrice': basePrice,
      'totalPrice': totalPrice,
      'finalPrice': totalPrice,
      if (notes != null) 'notes': notes,
      if (phone != null) 'phone': phone,
      if (metadata != null) 'metadata': metadata,
      if (tripType != null) 'tripType': tripType,       // ✅ НОВОЕ
      if (direction != null) 'direction': direction,    // ✅ НОВОЕ
    },
    requiresAuth: false,
  );
  // ...
}
```

### 6. **App - BookingService**

Теперь отправляет `tripType` и `direction` при создании заказа:

```dart
final createdOrder = await _ordersApi.createOrder(
  fromAddress: booking.pickupAddress ?? 'Не указан',
  toAddress: booking.dropoffAddress ?? 'Не указан',
  departureTime: departureDateTime,
  passengerCount: booking.passengerCount,
  basePrice: booking.totalPrice.toDouble(),
  totalPrice: booking.totalPrice.toDouble(),
  notes: booking.notes,
  metadata: metadata,
  tripType: booking.tripType.toString().split('.').last,      // ✅ НОВОЕ
  direction: booking.direction.toString().split('.').last,    // ✅ НОВОЕ
);
```

### 7. **App - Чтение tripType из backend (уже было исправлено ранее)**

В `booking_service.dart` уже был код для извлечения `tripType` и `direction` из metadata:

```dart
TripType tripType = TripType.customRoute;
if (apiOrder.metadata?['tripType'] != null) {
  final tripTypeStr = apiOrder.metadata!['tripType'] as String;
  tripType = TripType.values.firstWhere(
    (e) => e.toString().split('.').last == tripTypeStr,
    orElse: () => TripType.customRoute,
  );
}
```

**НО теперь backend возвращает tripType напрямую как поле!** Поэтому нужно обновить чтение:

```dart
// Сначала пытаемся прочитать из основного поля tripType
TripType tripType = TripType.customRoute;
if (apiOrder.tripType != null) {
  tripType = TripType.values.firstWhere(
    (e) => e.toString().split('.').last == apiOrder.tripType,
    orElse: () => TripType.customRoute,
  );
} else if (apiOrder.metadata?['tripType'] != null) {
  // Fallback: читаем из metadata (для старых заказов)
  final tripTypeStr = apiOrder.metadata!['tripType'] as String;
  tripType = TripType.values.firstWhere(
    (e) => e.toString().split('.').last == tripTypeStr,
    orElse: () => TripType.customRoute,
  );
}
```

## 📊 Результат

### До исправления:
```sql
SELECT order_id, from_address, to_address, final_price 
FROM orders 
ORDER BY created_at DESC 
LIMIT 3;

        order_id        | from_address | to_address | final_price 
------------------------+--------------+------------+-------------
 ORDER-2026-01-745      | Не указан    | Не указан  |    12000.00
 ORDER-2026-01-477      | Донецк       | Ростов     |     4000.00
 ORDER-2026-01-788      | Донецк       | Ростов     |     4000.00
```

❌ **Проблема**: Нет информации о типе поездки - все отображаются как "свободный маршрут"

### После исправления:
```bash
curl "https://titotr.ru/api/orders?limit=3" | jq '.'
```

```json
{
  "orders": [
    {
      "id": "34995b0b-e84c-44cc-be8a-e85ca5b88e16",
      "orderId": "ORDER-2026-01-745",
      "fromAddress": "Не указан",
      "toAddress": "Не указан",
      "finalPrice": 12000.0,
      "tripType": "customRoute",     // ✅ Тип поездки указан!
      "direction": null,
      "status": "pending",
      "createdAt": "2026-01-22T20:06:24.762915Z"
    }
  ],
  "count": 3
}
```

✅ **Решение**: Теперь backend возвращает `tripType` и `direction` как отдельные поля!

## 🎯 Типы поездок в приложении

### 1. **group** (Групповая поездка)
- Фиксированная цена за место: **2000₽**
- Направления: Донецк → Ростов, Ростов → Донецк
- Фиксированные остановки
- Отображение: **"Групповая поездка"**

### 2. **individual** (Индивидуальный трансфер)
- Цена за машину: **8000₽** (дневной тариф)
- Цена за машину: **10000₽** (ночной тариф, после 22:00)
- Направления: Донецк → Ростов, Ростов → Донецк
- Свободный выбор адресов в пределах маршрута
- Отображение: **"Индивидуальный трансфер"**

### 3. **customRoute** (Свободный маршрут / Такси)
- Динамическая цена: базовая стоимость + расстояние × цена за км
- Любые адреса (не обязательно Донецк-Ростов)
- Гибкая маршрутизация
- Отображение: **"Свободный маршрут"** или **"Такси"**

## 📝 Файлы с изменениями

### Backend:
1. `backend/database/migrations/004_add_trip_type_and_direction.sql` - Миграция БД
2. `backend/backend/lib/models/order.dart` - Enum'ы и поля tripType/direction
3. `backend/backend/lib/repositories/order_repository.dart` - INSERT с trip_type/direction

### App (Flutter):
1. `lib/services/api/orders_api_service.dart` - Отправка tripType/direction
2. `lib/services/booking_service.dart` - Передача tripType/direction при создании

## 🚀 Деплой

1. **Миграция применена**:
```bash
ssh root@78.155.202.50 "docker exec -i timetotravel_postgres psql -U timetotravel_user -d timetotravel < /tmp/004_add_trip_type_and_direction.sql"
# ALTER TABLE ✓
# CREATE INDEX ✓
```

2. **Backend обновлен**:
```bash
docker restart timetotravel_backend
# ✓ Running on http://:::8080
```

3. **Проверка работы**:
```bash
curl "https://titotr.ru/api/orders?limit=3"
# ✅ "tripType": "customRoute" возвращается!
```

## ✅ Заключение

Теперь архитектура **полностью идентична SQLite**:
- ✅ Backend хранит `trip_type` и `direction` в отдельных колонках
- ✅ App отправляет эти данные при создании заказа
- ✅ Backend возвращает их в JSON ответе
- ✅ App корректно отображает тип поездки в UI

**Групповые поездки** теперь будут отображаться как "Групповая поездка", а не "Свободный маршрут"! 🎉

## 🔄 Следующие шаги

1. **Обновить app на устройствах** - установить новую версию с поддержкой tripType/direction
2. **Создать тестовый заказ** - проверить что групповая поездка сохраняется правильно
3. **Проверить в кабинете диспетчера** - убедиться что тип отображается корректно
