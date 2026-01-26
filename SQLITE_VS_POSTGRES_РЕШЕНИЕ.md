# 🔥 КРИТИЧЕСКИЙ АНАЛИЗ: SQLite + PostgreSQL = Путаница

**Дата:** 26 января 2026  
**Проблема:** Двойное хранилище данных создаёт проблемы синхронизации

---

## ⚠️ ТЕКУЩАЯ ПРОБЛЕМА

У вас сейчас **ДВА ХРАНИЛИЩА ДАННЫХ**, которые должны быть синхронизированы:

```
┌─────────────────────────────────────────┐
│   📱 Flutter Приложение                 │
│                                         │
│   SQLite (локально)                     │
│   ├── taxi_orders.db                    │
│   ├── predefined_routes.db              │
│   └── route_groups.db                   │
│                                         │
│   ⬇️ Синхронизация ⬇️                    │
│                                         │
└─────────────────┬───────────────────────┘
                  │
                  │ HTTPS API
                  │
                  ▼
┌─────────────────────────────────────────┐
│   🗄️ PostgreSQL (на сервере)            │
│   ├── orders                            │
│   ├── predefined_routes                 │
│   └── route_groups                      │
└─────────────────────────────────────────┘
```

### 🔴 ПРОБЛЕМЫ ЭТОГО ПОДХОДА:

#### 1. **Конфликты синхронизации**
```dart
// Сценарий 1: Клиент создаёт заказ ОФЛАЙН
await OfflineOrdersService.saveOrder(order);  // Сохранено в SQLite
// ❌ Но НЕ отправлено на сервер!

// Диспетчер НЕ ВИДИТ этот заказ!

// Когда появится интернет:
await syncOrders();  // Отправляет на сервер
// ✅ Теперь диспетчер видит

// Проблема: Задержка в 1-2 часа!
```

#### 2. **Несоответствие данных**
```dart
// Сценарий 2: Диспетчер меняет статус заказа
// Backend:
UPDATE orders SET status = 'confirmed' WHERE order_id = 'ORDER-001';

// Клиент:
// ❌ Всё ещё видит status = 'pending' в SQLite!
// Нужна синхронизация в обратную сторону!
```

#### 3. **Дублирование кода**
```dart
// lib/services/offline_orders_service.dart - SQLite
await OfflineOrdersService.instance.saveOrder(order);

// lib/services/api/orders_api_service.dart - API
await OrdersApiService().createOrder(...);

// ❌ Два разных сервиса делают одно и то же!
```

#### 4. **Разные типы данных**
```dart
// SQLite:
passengersJson TEXT  // "[{\"type\":\"adult\"}]"
timestamp INTEGER    // 1738067200000

// PostgreSQL:
passengers JSONB     // [{"type":"adult"}]
created_at TIMESTAMP WITH TIME ZONE  // 2026-01-26 12:00:00+00
```

#### 5. **Сложность отладки**
```
Клиент: "У меня заказ не отображается!"

Разработчик:
- Проверить SQLite ✓ Есть
- Проверить PostgreSQL ✗ Нет
- Проверить синхронизацию ? Не работает
- Проверить логи ? Ошибка сети
- Проверить код ? 3 разных места

❌ Потрачено 2 часа на отладку!
```

---

## ✅ ПРАВИЛЬНОЕ РЕШЕНИЕ: УБРАТЬ SQLite

### Вариант 1: ТОЛЬКО PostgreSQL (Рекомендуется!)

```
┌─────────────────────────────────────────┐
│   📱 Flutter Приложение                 │
│                                         │
│   ❌ УБРАТЬ SQLite                      │
│   ✅ Кэширование в памяти (опционально) │
│                                         │
│   ВСЕГДА работать через API             │
│   ├── OrdersApiService                  │
│   ├── RoutesApiService                  │
│   └── AdminApiService                   │
│                                         │
└─────────────────┬───────────────────────┘
                  │
                  │ HTTPS API (ВСЕГДА!)
                  │
                  ▼
┌─────────────────────────────────────────┐
│   🗄️ PostgreSQL (единственный источник) │
│   ├── orders                            │
│   ├── predefined_routes                 │
│   └── route_groups                      │
└─────────────────────────────────────────┘
```

**Преимущества:**
- ✅ **Нет синхронизации** - данные всегда актуальны
- ✅ **Один источник правды** - PostgreSQL
- ✅ **Проще код** - убрать все `OfflineService`
- ✅ **Проще отладка** - проверяем только PostgreSQL
- ✅ **Диспетчер видит всё мгновенно**

**Недостатки:**
- ❌ **Нужен интернет** - без сети приложение не работает
- ❌ **Медленнее** - каждый запрос идёт на сервер

---

### Вариант 2: PostgreSQL + Кэш в памяти (Компромисс)

```dart
class OrdersService {
  // Кэш в памяти (НЕ SQLite!)
  List<Order> _cachedOrders = [];
  DateTime? _cacheTime;
  
  Future<List<Order>> getOrders({bool forceRefresh = false}) async {
    // Если кэш свежий (< 30 сек) - вернуть кэш
    if (!forceRefresh && _isCacheFresh()) {
      return _cachedOrders;
    }
    
    // Иначе - запрос к API
    final orders = await OrdersApiService().getOrders();
    
    // Обновить кэш
    _cachedOrders = orders;
    _cacheTime = DateTime.now();
    
    return orders;
  }
  
  bool _isCacheFresh() {
    if (_cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < Duration(seconds: 30);
  }
}
```

**Преимущества:**
- ✅ **Быстрая загрузка** - кэш в памяти
- ✅ **Нет синхронизации** - кэш временный
- ✅ **Всегда актуальные данные** - обновляется каждые 30 сек

---

### Вариант 3: Оставить SQLite только для офлайн-режима (НЕ рекомендуется)

**Если ОЧЕНЬ нужен офлайн-режим:**

```dart
class OrdersService {
  Future<List<Order>> getOrders() async {
    try {
      // Попытка загрузить с сервера
      final orders = await OrdersApiService().getOrders();
      
      // Сохранить в SQLite для офлайн
      await OfflineOrdersService.saveOrders(orders);
      
      return orders;
    } catch (e) {
      // Нет интернета - загрузить из SQLite
      return await OfflineOrdersService.getOrders();
    }
  }
}
```

**НО это создаёт проблемы:**
- ❌ Диспетчер НЕ увидит заказы, созданные офлайн
- ❌ Статусы не обновляются в реальном времени
- ❌ Сложная логика синхронизации

---

## 🎯 РЕКОМЕНДАЦИЯ ДЛЯ ВАШЕГО ПРОЕКТА

### ✅ **УБРАТЬ SQLite ПОЛНОСТЬЮ**

**Почему:**
1. Это **такси-сервис** - нужен интернет для GPS, карт, связи
2. **Диспетчер** должен видеть заказы **мгновенно**
3. **Без интернета** такси не работает (нет GPS, нет связи с водителем)
4. Упростит код на **70%**

**Что сделать:**

### Шаг 1: Удалить все SQLite сервисы

```bash
# Удалить файлы
rm lib/services/offline_orders_service.dart
rm lib/services/offline_routes_service.dart
rm lib/services/local_route_groups_service.dart
```

### Шаг 2: Использовать ТОЛЬКО API сервисы

```dart
// lib/services/orders_service.dart
class OrdersService {
  final OrdersApiService _api = OrdersApiService();
  
  // Кэш в памяти (опционально)
  List<ApiOrder>? _cachedOrders;
  
  Future<List<ApiOrder>> getOrders({bool refresh = false}) async {
    if (!refresh && _cachedOrders != null) {
      return _cachedOrders!;
    }
    
    final response = await _api.getOrders(limit: 100);
    _cachedOrders = response.orders;
    return _cachedOrders!;
  }
  
  Future<ApiOrder> createOrder(Booking booking) async {
    final order = await _api.createOrder(
      fromAddress: booking.pickupAddress,
      toAddress: booking.dropoffAddress,
      // ...
    );
    
    // Обновить кэш
    _cachedOrders?.insert(0, order);
    
    return order;
  }
}
```

### Шаг 3: Обновить все экраны

```dart
// lib/features/orders/screens/orders_screen.dart
class _OrdersScreenState extends State<OrdersScreen> {
  final OrdersService _ordersService = OrdersService();
  
  Future<void> _loadOrders() async {
    final orders = await _ordersService.getOrders(refresh: true);
    setState(() {
      _orders = orders;
    });
  }
  
  // ❌ УБРАТЬ:
  // await OfflineOrdersService.instance.getAllOrders();
}
```

---

## 📊 СРАВНЕНИЕ ПОДХОДОВ

| Критерий | SQLite + PostgreSQL | ТОЛЬКО PostgreSQL | PostgreSQL + Кэш |
|----------|---------------------|-------------------|------------------|
| **Сложность кода** | 🔴 Очень сложно | 🟢 Просто | 🟡 Средне |
| **Синхронизация** | 🔴 Нужна постоянно | 🟢 Не нужна | 🟢 Не нужна |
| **Актуальность данных** | 🔴 Задержки | 🟢 Мгновенно | 🟢 30 сек |
| **Офлайн-режим** | 🟢 Работает | 🔴 Не работает | 🔴 Не работает |
| **Скорость загрузки** | 🟢 Быстро | 🟡 Средне | 🟢 Быстро |
| **Отладка** | 🔴 Сложно | 🟢 Легко | 🟢 Легко |
| **Диспетчер видит заказы** | 🔴 С задержкой | 🟢 Мгновенно | 🟢 Мгновенно |

---

## 🚀 ПЛАН МИГРАЦИИ

### Этап 1: Подготовка (1 день)

```bash
# 1. Создать новый бранч
git checkout -b remove-sqlite

# 2. Сделать резервную копию
cp -r lib/services lib/services_backup

# 3. Протестировать API endpoints
curl https://titotr.ru/api/orders
curl https://titotr.ru/api/search
```

### Этап 2: Удаление SQLite (2-3 дня)

1. **Удалить SQLite сервисы:**
   - `offline_orders_service.dart`
   - `offline_routes_service.dart`
   - `local_route_groups_service.dart`
   - `local_routes_service.dart`

2. **Создать единый `OrdersService`:**
   ```dart
   // lib/services/orders_service.dart
   class OrdersService {
     final OrdersApiService _api = OrdersApiService();
     // Только API, никакого SQLite!
   }
   ```

3. **Обновить все экраны:**
   - `orders_screen.dart`
   - `booking_screen.dart`
   - `dispatcher_home_screen.dart`

4. **Убрать `isSynced` из моделей:**
   ```dart
   class TaxiOrder {
     // ❌ УБРАТЬ: final bool isSynced;
   }
   ```

### Этап 3: Тестирование (1 день)

```dart
// Создать заказ
final order = await OrdersService().createOrder(booking);

// Проверить в PostgreSQL
// Должен появиться МГНОВЕННО

// Диспетчер открывает "Заказы"
// Должен увидеть новый заказ БЕЗ ЗАДЕРЖКИ
```

### Этап 4: Деплой (1 день)

```bash
# 1. Протестировать на test-устройстве
flutter run --release

# 2. Создать новую версию
flutter build apk --release
flutter build ipa --release

# 3. Залить на сервер
git push origin remove-sqlite
```

---

## ❓ А ЕСЛИ ВСЁ-ТАКИ НУЖЕН ОФЛАЙН?

**Альтернатива SQLite:**

### Использовать `shared_preferences` для кэша

```dart
import 'package:shared_preferences/shared_preferences.dart';

class OrdersCache {
  static Future<void> save(List<ApiOrder> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(orders.map((o) => o.toJson()).toList());
    await prefs.setString('cached_orders', json);
    await prefs.setString('cache_time', DateTime.now().toIso8601String());
  }
  
  static Future<List<ApiOrder>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('cached_orders');
    if (json == null) return null;
    
    final cacheTime = DateTime.parse(prefs.getString('cache_time')!);
    if (DateTime.now().difference(cacheTime) > Duration(hours: 1)) {
      return null; // Кэш устарел
    }
    
    final list = jsonDecode(json) as List;
    return list.map((j) => ApiOrder.fromJson(j)).toList();
  }
}
```

**Преимущества:**
- ✅ Проще чем SQLite
- ✅ Нет баз данных
- ✅ Только для чтения (не создаём заказы офлайн)

---

## 🎓 УРОК НА БУДУЩЕЕ

Вы правы: **СНАЧАЛА BACKEND, ПОТОМ КЛИЕНТ**!

### Правильный порядок разработки:

```
1. 📋 Проектирование (1 неделя)
   ├── Определить функционал
   ├── Нарисовать схему БД
   └── Спроектировать API endpoints

2. 🗄️ Backend (2-3 недели)
   ├── PostgreSQL схема
   ├── API endpoints (Dart Frog)
   ├── Аутентификация (JWT)
   └── Тесты API

3. 📱 Frontend (3-4 недели)
   ├── UI/UX дизайн
   ├── Экраны
   ├── Интеграция с API
   └── Тестирование

4. 🚀 Деплой (1 неделя)
   ├── Backend на сервер
   ├── App в AppStore/PlayStore
   └── Мониторинг
```

**Ваш случай (как было):**
```
❌ 1. Сделали Flutter приложение со SQLite
❌ 2. Потом начали делать backend
❌ 3. Теперь нужна синхронизация
❌ 4. Двойная работа!
```

---

## ✅ ИТОГОВАЯ РЕКОМЕНДАЦИЯ

### 🎯 **УБРАТЬ SQLite ПОЛНОСТЬЮ**

1. ✅ Упростит код на 70%
2. ✅ Диспетчер видит заказы мгновенно
3. ✅ Нет проблем с синхронизацией
4. ✅ Один источник правды (PostgreSQL)
5. ✅ Проще поддержка и отладка

### 🔧 **Если нужна скорость:**

Добавить **кэш в памяти** (НЕ SQLite):
- Хранить последние 100 заказов в `List<ApiOrder>`
- Обновлять каждые 30 секунд
- Показывать кэш пока грузятся новые данные

### ❌ **НЕ оставлять SQLite:**

SQLite имеет смысл ТОЛЬКО для:
- Офлайн-приложений (заметки, ToDo)
- Приложений БЕЗ backend (калькуляторы)
- Игр с локальным сохранением

**Ваш случай:** Онлайн-сервис такси → **ТОЛЬКО PostgreSQL**!

---

**Нужна помощь с миграцией?** Могу показать конкретные примеры кода! 🚀
