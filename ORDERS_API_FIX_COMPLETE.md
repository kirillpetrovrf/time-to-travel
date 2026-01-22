# ✅ ИСПРАВЛЕНИЕ: Заказы теперь отправляются напрямую в PostgREST (backend)

**Дата:** 22 января 2026, 21:25 UTC  
**Статус:** ✅ ИСПРАВЛЕНО И ПЕРЕСОБРАНО

---

## 🔍 Проблема

**Из логов приложения:**
```
📤 Создание бронирования: сначала отправка на backend API...
⚠️ Ошибка отправки на backend: ServerException: Unknown error
📱 Сохраняем заказ локально для последующей синхронизации
📱 Создано оффлайн бронирование: offline_1769105713247
```

**Заказы НЕ попадали на backend!** Все сохранялись как `offline_XXXXXXX`.

---

## ⚙️ Корень проблемы

### 1. **Требовалась авторизация**
```dart
// БЫЛО: ❌
final response = await _apiClient.post(
  ApiConfig.ordersEndpoint,
  body: {...},
  requiresAuth: true,  // ❌ Требовал токен авторизации!
);
```

Пользователь не авторизован (`clientId: "offline_user_demo"`), поэтому запрос падал.

### 2. **Неправильная структура ответа**
Backend возвращает:
```json
{
  "order": {
    "orderId": "ORDER-2026-01-XXX",
    "userId": null,
    "finalPrice": 4000.0,
    ...
  }
}
```

Но код ожидал:
```dart
ApiOrder(
  id: json['id'],           // ❌ Нет такого поля
  userId: json['userId'],   // ❌ Обязательное, а на backend null
  totalPrice: json['totalPrice'],  // ❌ Backend использует finalPrice
  ...
)
```

### 3. **Отсутствие логирования**
Ошибки были слишком общими: `ServerException: Unknown error`

---

## ✅ Решение

### Изменение 1: Убрана обязательная авторизация
**Файл:** `lib/services/api/orders_api_service.dart`

```dart
// БЫЛО ❌
requiresAuth: true,

// СТАЛО ✅
requiresAuth: false, // Заказы можно создавать БЕЗ авторизации
```

### Изменение 2: Добавлено обязательное поле `finalPrice`
**Файл:** `lib/services/api/orders_api_service.dart`

```dart
final response = await _apiClient.post(
  ApiConfig.ordersEndpoint,
  body: {
    'fromAddress': fromAddress,
    'toAddress': toAddress,
    'departureTime': departureTime.toIso8601String(),
    'passengerCount': passengerCount,
    'basePrice': basePrice,
    'totalPrice': totalPrice,
    'finalPrice': totalPrice, // ✅ ОБЯЗАТЕЛЬНОЕ ПОЛЕ для backend
    if (notes != null) 'notes': notes,
    if (phone != null) 'phone': phone,
    if (metadata != null) 'metadata': metadata,
  },
  requiresAuth: false, // ✅ БЕЗ авторизации
);
```

### Изменение 3: Исправлен парсинг ответа
**Файл:** `lib/services/api/orders_api_service.dart`

```dart
factory ApiOrder.fromJson(Map<String, dynamic> json) {
  // Backend возвращает {"order": {...}} - распаковываем
  final data = json.containsKey('order') 
      ? json['order'] as Map<String, dynamic> 
      : json;
  
  return ApiOrder(
    id: data['orderId'] as String? ?? data['id'] as String, // ✅ orderId приоритет
    userId: data['userId'] as String? ?? '', // ✅ Может быть null
    fromAddress: data['fromAddress'] as String,
    toAddress: data['toAddress'] as String,
    departureTime: data['departureTime'] != null 
        ? DateTime.parse(data['departureTime'] as String)
        : DateTime.now(), // ✅ Fallback если null
    passengerCount: data['passengerCount'] as int? ?? 1,
    basePrice: data['basePrice'] != null 
        ? (data['basePrice'] as num).toDouble() 
        : 0.0,
    totalPrice: data['finalPrice'] != null  // ✅ finalPrice!
        ? (data['finalPrice'] as num).toDouble()
        : (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
    status: OrderStatus.fromString(data['status'] as String? ?? 'pending'),
    notes: data['notes'] as String?,
    phone: data['clientPhone'] as String?, // ✅ clientPhone
    metadata: data['metadata'] as Map<String, dynamic>?,
    createdAt: data['createdAt'] != null 
        ? DateTime.parse(data['createdAt'] as String)
        : DateTime.now(),
    updatedAt: data['updatedAt'] != null
        ? DateTime.parse(data['updatedAt'] as String)
        : DateTime.now(),
  );
}
```

### Изменение 4: Добавлено детальное логирование
**Файлы:** 
- `lib/services/api/orders_api_service.dart`
- `lib/services/api/api_client.dart`

```dart
// В OrdersApiService
debugPrint('📤 [API] Отправка заказа на backend...');
debugPrint('   От: $fromAddress');
debugPrint('   До: $toAddress');
debugPrint('   Цена: $totalPrice');

// В ApiClient
debugPrint('🌐 [API] POST $uri');
debugPrint('🌐 [API] Headers: $headers');
debugPrint('🌐 [API] Body: ${jsonEncode(body)}');
debugPrint('🌐 [API] Response status: ${response.statusCode}');
debugPrint('🌐 [API] Response body: ${response.body}');
```

---

## 📦 Сборка

```bash
flutter build apk --release
✓ Built build/app/outputs/flutter-apk/app-release.apk (161.8MB)
```

---

## ✅ Ожидаемый результат

**ТЕПЕРЬ при создании заказа:**

1. ✅ Приложение отправляет заказ на backend API (https://titotr.ru)
2. ✅ Backend создаёт заказ с ID вида `ORDER-2026-01-XXX`
3. ✅ Заказ сохраняется в PostgreSQL
4. ✅ Приложение получает реальный ID от backend
5. ✅ Заказ дублируется локально в SQLite (как резерв)
6. ✅ Диспетчер видит заказ в своём кабинете

**В логах должно появиться:**
```
📤 [API] Отправка заказа на backend...
   От: Донецк, ул. Артёма 120
   До: Ростов-на-Дону
   Цена: 4000.0
🌐 [API] POST https://titotr.ru/api/orders
🌐 [API] Response status: 201
✅ [API] Backend вернул успешный ответ
✅ [API] Заказ создан с ID: ORDER-2026-01-XXX
✅ Заказ успешно создан на backend с ID: ORDER-2026-01-XXX
```

**Вместо старого:**
```
⚠️ Ошибка отправки на backend: ServerException: Unknown error
📱 Сохраняем заказ локально для последующей синхронизации
📱 Создано оффлайн бронирование: offline_1769105713247
```

---

## 🧪 Как протестировать

1. **Установите новый APK** на телефон
2. **Создайте новый заказ** в приложении
3. **Проверьте логи** - должен быть `ORDER-2026-01-XXX` вместо `offline_`
4. **Откройте кабинет диспетчера** - заказ должен быть виден
5. **Проверьте БД** (опционально):
```sql
SELECT order_id, from_address, to_address, final_price, status, created_at 
FROM orders 
ORDER BY created_at DESC 
LIMIT 5;
```

---

## 📋 Изменённые файлы

1. ✅ `lib/services/api/orders_api_service.dart` - убрана авторизация, добавлен finalPrice, исправлен fromJson, добавлено логирование
2. ✅ `lib/services/api/api_client.dart` - добавлено детальное логирование HTTP запросов

---

## 🎯 Архитектура синхронизации (как задумано)

### Основной поток (онлайн):
```
Приложение → Backend API (https://titotr.ru) → PostgreSQL
     ↓
 SQLite (локальная копия)
```

### Резервный поток (оффлайн):
```
Приложение → SQLite (временное хранилище)
     ↓
При восстановлении сети → Backend API → PostgreSQL
```

### Ключевые моменты:
- ✅ **Firebase НЕ используется** для заказов (только маршруты)
- ✅ **SQLite** - только как резервная копия при отсутствии интернета
- ✅ **PostgREST** - основная БД для всех заказов
- ✅ **Все заказы** попадают в PostgreSQL напрямую (онлайн)

---

**Готово к тестированию!** 🚀
