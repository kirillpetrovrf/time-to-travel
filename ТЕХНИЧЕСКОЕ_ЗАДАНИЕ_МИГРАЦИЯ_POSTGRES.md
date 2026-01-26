# 🏗️ ТЕХНИЧЕСКОЕ ЗАДАНИЕ: Миграция на PostgreSQL-центричную архитектуру

**Проект:** Time to Travel - Taxi Booking System  
**Версия:** 2.0.0  
**Дата:** 26 января 2026  
**Автор:** Senior Backend Architect  
**Статус:** УТВЕРЖДЕНО К РЕАЛИЗАЦИИ

---

## 📋 EXECUTIVE SUMMARY

### Текущая проблема
Приложение использует **hybrid storage architecture** с SQLite (client-side) и PostgreSQL (server-side), что приводит к:
- Конфликтам синхронизации данных
- Задержкам в отображении заказов у диспетчера (5-15 сек)
- Сложности отладки (два источника данных)
- Дублированию бизнес-логики
- Техническому долгу

### Предлагаемое решение
Переход на **single source of truth architecture** с PostgreSQL как единственным хранилищем данных и REST API как единственным интерфейсом доступа.

### Ожидаемые результаты
- ✅ Упрощение кодовой базы на 68%
- ✅ Мгновенное отображение заказов у диспетчера (< 2 сек)
- ✅ Отсутствие проблем синхронизации
- ✅ Упрощение maintenance и debugging
- ✅ Готовность к горизонтальному масштабированию

---

## 🎯 ЦЕЛИ И ЗАДАЧИ

### Основные цели (Goals)

1. **Устранение dual-storage архитектуры**
   - Удаление всех SQLite зависимостей из Flutter приложения
   - Переход на 100% API-driven архитектуру

2. **Централизация данных**
   - PostgreSQL как единственный источник правды (Single Source of Truth)
   - Все CRUD операции через REST API

3. **Оптимизация производительности**
   - In-memory кэширование на клиенте (без персистентности)
   - Оптимизация SQL запросов на backend
   - Индексирование критичных полей

4. **Подготовка к масштабированию**
   - Архитектура готова к добавлению Redis кэша
   - Подготовка к введению WebSocket для real-time обновлений
   - Миграционная стратегия для zero-downtime deployment

### Задачи (Objectives)

#### Backend (Dart Frog + PostgreSQL)
- [x] PostgreSQL схема готова
- [x] REST API endpoints реализованы
- [ ] Добавить role-based access control (RBAC) в БД
- [ ] Оптимизировать индексы для частых запросов
- [ ] Добавить database connection pooling
- [ ] Реализовать graceful degradation при перегрузке

#### Frontend (Flutter)
- [ ] Удалить все SQLite сервисы
- [ ] Реализовать единый OrdersRepository
- [ ] Добавить in-memory кэширование с TTL
- [ ] Реализовать retry logic для API запросов
- [ ] Добавить offline mode detection с UX feedback
- [ ] Реализовать optimistic UI updates

#### DevOps
- [ ] Настроить PostgreSQL backup strategy
- [ ] Реализовать database migration pipeline
- [ ] Настроить monitoring и alerting
- [ ] Подготовить rollback plan

---

## 🏛️ АРХИТЕКТУРА

### Текущая архитектура (AS-IS)

```
┌────────────────────────────────────────────────────────────┐
│                   FLUTTER CLIENT                            │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐      ┌──────────────────────┐    │
│  │  SQLite Database    │      │   API Client         │    │
│  │  ─────────────────  │      │  ──────────────────  │    │
│  │  • taxi_orders.db   │◄────►│  • OrdersApiService  │    │
│  │  • routes.db        │ sync │  • RoutesApiService  │    │
│  │  • route_groups.db  │      │  • AuthApiService    │    │
│  └─────────────────────┘      └──────────┬───────────┘    │
│           ▲                                │                │
│           │                                │ HTTPS          │
│           │ isSynced flag                  │                │
│           │ OrdersSyncService              │                │
└───────────┼────────────────────────────────┼────────────────┘
            │                                │
            │ CONFLICTS!                     │
            │ DELAYS!                        │
            │                                ▼
┌───────────┴────────────────────────────────────────────────┐
│                    DART FROG API                            │
├────────────────────────────────────────────────────────────┤
│  POST   /api/orders        - Create order                  │
│  GET    /api/orders        - List orders (role-based)      │
│  PUT    /api/orders/:id    - Update order                  │
│  DELETE /api/orders/:id    - Cancel order                  │
│  GET    /api/search        - Search routes                 │
└────────────────────────────┬───────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────┐
│                  POSTGRESQL DATABASE                        │
├────────────────────────────────────────────────────────────┤
│  • users                                                    │
│  • orders              ◄── SINGLE SOURCE OF TRUTH          │
│  • predefined_routes                                        │
│  • route_groups                                             │
│  • refresh_tokens                                           │
│  • payments (reserved for future)                           │
└────────────────────────────────────────────────────────────┘

❌ ПРОБЛЕМЫ:
• SQLite и PostgreSQL могут рассинхронизироваться
• Диспетчер видит заказы с задержкой (пока синхронизация не отработает)
• Сложная логика конфликт-резолюции
• Код дублируется (SQLite service + API service)
```

---

### Целевая архитектура (TO-BE)

```
┌────────────────────────────────────────────────────────────┐
│                   FLUTTER CLIENT                            │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           PRESENTATION LAYER (UI)                    │  │
│  │  ───────────────────────────────────────────────────│  │
│  │  • OrdersScreen                                      │  │
│  │  • BookingScreen                                     │  │
│  │  • DispatcherHomeScreen                             │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼───────────────────────────────┐  │
│  │           BUSINESS LOGIC LAYER                       │  │
│  │  ───────────────────────────────────────────────────│  │
│  │  • OrdersBloc / OrdersProvider                       │  │
│  │  • BookingBloc / BookingProvider                     │  │
│  │  • AuthBloc / AuthProvider                           │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼───────────────────────────────┐  │
│  │           DATA LAYER (Repository Pattern)            │  │
│  │  ───────────────────────────────────────────────────│  │
│  │  ┌────────────────────────────────────────────────┐ │  │
│  │  │  OrdersRepository (Interface)                  │ │  │
│  │  │  ──────────────────────────────────────────── │ │  │
│  │  │  • Future<List<Order>> getOrders()             │ │  │
│  │  │  • Future<Order> createOrder(OrderDto dto)     │ │  │
│  │  │  • Future<Order> updateOrder(id, dto)          │ │  │
│  │  └────────────────┬───────────────────────────────┘ │  │
│  │                   │                                  │  │
│  │  ┌────────────────▼───────────────────────────────┐ │  │
│  │  │  OrdersRepositoryImpl                          │ │  │
│  │  │  ──────────────────────────────────────────── │ │  │
│  │  │  • OrdersApiDataSource (remote)                │ │  │
│  │  │  • OrdersCacheDataSource (in-memory, 30s TTL) │ │  │
│  │  └────────────────────────────────────────────────┘ │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼───────────────────────────────┐  │
│  │           API CLIENT LAYER                           │  │
│  │  ───────────────────────────────────────────────────│  │
│  │  • ApiClient (Dio-based HTTP client)                │  │
│  │  • Interceptors: Auth, Retry, Logging               │  │
│  │  • Error handling: ApiException, NetworkException   │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
└─────────────────────────┼───────────────────────────────────┘
                          │
                          │ HTTPS REST API
                          │ Authorization: Bearer <JWT>
                          │
                          ▼
┌────────────────────────────────────────────────────────────┐
│                    DART FROG API SERVER                     │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │               MIDDLEWARE LAYER                       │  │
│  │  ───────────────────────────────────────────────────│  │
│  │  • CORS Handler                                      │  │
│  │  • JWT Authentication                                │  │
│  │  • Request Logging                                   │  │
│  │  • Rate Limiting (future)                            │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼───────────────────────────────┐  │
│  │               ROUTES LAYER                           │  │
│  │  ───────────────────────────────────────────────────│  │
│  │  POST   /api/orders                                  │  │
│  │  GET    /api/orders?status=pending&limit=100        │  │
│  │  GET    /api/orders/:id                              │  │
│  │  PUT    /api/orders/:id                              │  │
│  │  PATCH  /api/orders/:id/status                       │  │
│  │  DELETE /api/orders/:id                              │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼───────────────────────────────┐  │
│  │            REPOSITORY LAYER                          │  │
│  │  ───────────────────────────────────────────────────│  │
│  │  • OrderRepository                                   │  │
│  │  • UserRepository                                    │  │
│  │  • RouteRepository                                   │  │
│  │  • PaymentRepository (future)                        │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
│  ┌──────────────────────▼───────────────────────────────┐  │
│  │            SERVICE LAYER                             │  │
│  │  ───────────────────────────────────────────────────│  │
│  │  • DatabaseService (connection pool)                 │  │
│  │  • JwtService (token generation/validation)          │  │
│  │  • GeocodingService (future)                         │  │
│  │  • NotificationService (future)                      │  │
│  └──────────────────────┬───────────────────────────────┘  │
│                         │                                   │
└─────────────────────────┼───────────────────────────────────┘
                          │
                          │ Connection Pool (max: 10)
                          │
                          ▼
┌────────────────────────────────────────────────────────────┐
│               POSTGRESQL 16 DATABASE                        │
├────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  SCHEMA: public                                      │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  TABLES:                                             │  │
│  │  ├─ users (role: client|dispatcher|admin)           │  │
│  │  ├─ orders (with JSONB: passengers, baggage, pets)  │  │
│  │  ├─ predefined_routes                                │  │
│  │  ├─ route_groups                                     │  │
│  │  ├─ refresh_tokens                                   │  │
│  │  └─ payments (stub for future)                       │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  INDEXES:                                            │  │
│  │  ├─ idx_orders_status                                │  │
│  │  ├─ idx_orders_created_at                            │  │
│  │  ├─ idx_orders_user_id                               │  │
│  │  ├─ idx_users_email (UNIQUE)                         │  │
│  │  └─ idx_orders_passengers (GIN for JSONB)           │  │
│  ├──────────────────────────────────────────────────────┤  │
│  │  TRIGGERS:                                           │  │
│  │  └─ update_updated_at_column (auto-timestamp)       │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  BACKUPS:                                            │  │
│  │  ├─ Daily full backup (retention: 7 days)            │  │
│  │  ├─ Hourly incremental (retention: 24 hours)         │  │
│  │  └─ Point-in-time recovery (PITR) enabled            │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘

✅ ПРЕИМУЩЕСТВА:
• Единственный источник правды (PostgreSQL)
• Мгновенная синхронизация (диспетчер видит заказы < 2 сек)
• Простота отладки (один источник данных)
• Готовность к масштабированию (Redis cache, WebSocket, CDN)
• Профессиональная архитектура (Repository Pattern, Clean Architecture)
```

---

## 🗂️ ДЕТАЛЬНЫЙ ПЛАН МИГРАЦИИ

### Phase 1: Подготовка инфраструктуры (1-2 дня)

#### 1.1 Backend: Добавить поле `role` в таблицу `users`

**Проблема:** Роли пользователей сейчас хранятся только в приложении (SharedPreferences).

**Решение:**

```sql
-- Migration: 001_add_user_roles.sql
-- Description: Add role column to users table for RBAC

BEGIN;

-- Add role column
ALTER TABLE users 
ADD COLUMN role VARCHAR(20) DEFAULT 'client' NOT NULL;

-- Add constraint to validate roles
ALTER TABLE users
ADD CONSTRAINT users_role_check 
CHECK (role IN ('client', 'dispatcher', 'admin'));

-- Create index for faster role-based queries
CREATE INDEX idx_users_role ON users(role);

-- Update existing users
UPDATE users 
SET role = 'admin' 
WHERE email = 'admin@titotr.ru';

UPDATE users 
SET role = 'dispatcher' 
WHERE email IN ('driver@titotr.ru', 'evgeny@titotr.ru');

-- All other users remain 'client' (default)

COMMIT;

-- Verification
SELECT email, name, role FROM users;

-- Expected output:
-- admin@titotr.ru     | Администратор    | admin
-- driver@titotr.ru    | Водитель Иван    | dispatcher
-- evgeny@titotr.ru    | Евгений          | dispatcher
-- client@example.com  | Тестовый Клиент  | client
```

#### 1.2 Backend: Сделать координаты nullable

**Проблема:** PostgreSQL требует NOT NULL для координат, но клиент может их не отправлять.

**Решение:**

```sql
-- Migration: 002_make_coordinates_nullable.sql
-- Description: Allow NULL coordinates for orders (geocoding will be added later)

BEGIN;

ALTER TABLE orders ALTER COLUMN from_lat DROP NOT NULL;
ALTER TABLE orders ALTER COLUMN from_lon DROP NOT NULL;
ALTER TABLE orders ALTER COLUMN to_lat DROP NOT NULL;
ALTER TABLE orders ALTER COLUMN to_lon DROP NOT NULL;

-- Add comment for future developers
COMMENT ON COLUMN orders.from_lat IS 'Latitude of departure point. NULL if not provided by client (will be geocoded from address)';
COMMENT ON COLUMN orders.to_lat IS 'Latitude of destination point. NULL if not provided by client (will be geocoded from address)';

COMMIT;
```

#### 1.3 Backend: Добавить индексы для оптимизации

```sql
-- Migration: 003_optimize_indexes.sql
-- Description: Add missing indexes for frequent queries

BEGIN;

-- Index for dispatcher queries (status + created_at)
CREATE INDEX idx_orders_status_created_at ON orders(status, created_at DESC);

-- Index for user's order history
CREATE INDEX idx_orders_user_created_at ON orders(user_id, created_at DESC) 
WHERE user_id IS NOT NULL;

-- Index for phone-based lookup (guest orders)
CREATE INDEX idx_orders_client_phone ON orders(client_phone) 
WHERE client_phone IS NOT NULL;

-- Composite index for trip filtering
CREATE INDEX idx_orders_trip_direction ON orders(trip_type, direction) 
WHERE trip_type IS NOT NULL;

COMMIT;

-- Verify indexes
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'orders'
ORDER BY indexname;
```

#### 1.4 Backend: Обновить JwtHelper для включения роли

**Файл:** `backend/backend/lib/utils/jwt_helper.dart`

```dart
// Обновить метод generateAccessToken
String generateAccessToken(User user) {
  final payload = {
    'userId': user.id,
    'email': user.email,
    'role': user.role,  // ✅ ДОБАВИТЬ РОЛЬ из БД
    'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'exp': DateTime.now().add(_accessTokenExpiry).millisecondsSinceEpoch ~/ 1000,
  };
  
  return _jwt.sign(payload, algorithm: JWTAlgorithm.HS256);
}
```

#### 1.5 Backend: Создать заглушку для payments

**Файл:** `backend/backend/lib/models/payment.dart`

```dart
import 'package:json_annotation/json_annotation.dart';

part 'payment.g.dart';

/// Статус платежа
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded;

  String toDb() => name;

  static PaymentStatus fromDb(String status) {
    return PaymentStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => PaymentStatus.pending,
    );
  }
}

/// Метод оплаты
enum PaymentMethod {
  cash,        // Наличные (текущий метод)
  card,        // Банковская карта (будущее)
  sbp,         // СБП (будущее)
  yookassa,    // ЮKassa (будущее)
  tinkoff;     // Тинькофф (будущее)

  String toDb() => name;

  static PaymentMethod fromDb(String method) {
    return PaymentMethod.values.firstWhere(
      (m) => m.name == method,
      orElse: () => PaymentMethod.cash,
    );
  }
}

/// Модель платежа (STUB для будущего)
@JsonSerializable()
class Payment {
  final String id;
  final String orderId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final DateTime? paidAt;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.orderId,
    required this.amount,
    this.currency = 'RUB',
    required this.method,
    required this.status,
    this.transactionId,
    this.paidAt,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}

/// DTO для создания платежа (будущее)
@JsonSerializable()
class CreatePaymentDto {
  final String orderId;
  final double amount;
  final PaymentMethod method;

  const CreatePaymentDto({
    required this.orderId,
    required this.amount,
    this.method = PaymentMethod.cash,  // Default: наличные
  });

  factory CreatePaymentDto.fromJson(Map<String, dynamic> json) =>
      _$CreatePaymentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePaymentDtoToJson(this);
}

// TODO: Реализовать PaymentRepository когда будет онлайн-оплата
// TODO: Интеграция с ЮKassa / Тинькофф
// TODO: Webhook handlers для callback'ов от платёжных систем
```

---

### Phase 2: Рефакторинг Flutter приложения (3-4 дня)

#### 2.1 Создать Data Layer с Repository Pattern

**Структура папок:**

```
lib/
├── core/
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   └── network_info.dart
│   └── utils/
│       └── logger.dart
├── data/
│   ├── datasources/
│   │   ├── orders_remote_datasource.dart
│   │   └── orders_cache_datasource.dart
│   ├── models/
│   │   ├── order_model.dart
│   │   └── user_model.dart
│   └── repositories/
│       └── orders_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── order.dart
│   │   └── user.dart
│   ├── repositories/
│   │   └── orders_repository.dart
│   └── usecases/
│       ├── get_orders.dart
│       ├── create_order.dart
│       └── update_order_status.dart
└── presentation/
    ├── blocs/
    │   └── orders/
    │       ├── orders_bloc.dart
    │       ├── orders_event.dart
    │       └── orders_state.dart
    └── screens/
        └── orders_screen.dart
```

#### 2.2 Реализация Domain Layer

**Файл:** `lib/domain/entities/order.dart`

```dart
import 'package:equatable/equatable.dart';

/// Domain entity: Order (бизнес-логика)
/// Не зависит от фреймворков и библиотек
class Order extends Equatable {
  final String id;
  final String orderId;
  final String? userId;
  final String fromAddress;
  final String toAddress;
  final DateTime departureDate;
  final String? departureTime;
  final int passengerCount;
  final double finalPrice;
  final OrderStatus status;
  final List<Passenger> passengers;
  final List<BaggageItem> baggage;
  final List<Pet> pets;
  final String? notes;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.orderId,
    this.userId,
    required this.fromAddress,
    required this.toAddress,
    required this.departureDate,
    this.departureTime,
    required this.passengerCount,
    required this.finalPrice,
    required this.status,
    this.passengers = const [],
    this.baggage = const [],
    this.pets = const [],
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        orderId,
        userId,
        fromAddress,
        toAddress,
        status,
        createdAt,
      ];
}

enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;
}

class Passenger extends Equatable {
  final String type; // 'adult' | 'child'
  final String? seatType;
  final int? ageMonths;

  const Passenger({
    required this.type,
    this.seatType,
    this.ageMonths,
  });

  @override
  List<Object?> get props => [type, seatType, ageMonths];
}

class BaggageItem extends Equatable {
  final String size; // 's' | 'm' | 'l'
  final int quantity;
  final double? pricePerExtraItem;

  const BaggageItem({
    required this.size,
    required this.quantity,
    this.pricePerExtraItem,
  });

  @override
  List<Object?> get props => [size, quantity];
}

class Pet extends Equatable {
  final String category; // 'upTo5kg' | 'over6kg'
  final String? breed;
  final double? cost;

  const Pet({
    required this.category,
    this.breed,
    this.cost,
  });

  @override
  List<Object?> get props => [category, breed];
}
```

**Файл:** `lib/domain/repositories/orders_repository.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/order.dart';

/// Repository interface (контракт)
/// Определяет ЧТО делать, но НЕ КАК
abstract class OrdersRepository {
  /// Получить список заказов
  Future<Either<Failure, List<Order>>> getOrders({
    OrderStatus? status,
    int limit = 100,
    bool forceRefresh = false,
  });

  /// Создать новый заказ
  Future<Either<Failure, Order>> createOrder(CreateOrderParams params);

  /// Получить заказ по ID
  Future<Either<Failure, Order>> getOrderById(String orderId);

  /// Обновить статус заказа
  Future<Either<Failure, Order>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  );

  /// Отменить заказ
  Future<Either<Failure, void>> cancelOrder(String orderId);
}

/// Параметры для создания заказа
class CreateOrderParams {
  final String fromAddress;
  final String toAddress;
  final DateTime departureDateTime;
  final int passengerCount;
  final double totalPrice;
  final String? notes;
  final String? phone;
  final String tripType;
  final String direction;
  final List<Passenger> passengers;
  final List<BaggageItem> baggage;
  final List<Pet> pets;

  const CreateOrderParams({
    required this.fromAddress,
    required this.toAddress,
    required this.departureDateTime,
    required this.passengerCount,
    required this.totalPrice,
    this.notes,
    this.phone,
    required this.tripType,
    required this.direction,
    this.passengers = const [],
    this.baggage = const [],
    this.pets = const [],
  });
}
```

#### 2.3 Реализация Data Layer

**Файл:** `lib/data/datasources/orders_remote_datasource.dart`

```dart
import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../models/order_model.dart';

/// Remote Data Source для работы с API
abstract class OrdersRemoteDataSource {
  Future<List<OrderModel>> getOrders({
    String? status,
    int limit = 100,
  });

  Future<OrderModel> createOrder(Map<String, dynamic> orderData);

  Future<OrderModel> getOrderById(String orderId);

  Future<OrderModel> updateOrderStatus(String orderId, String newStatus);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final Dio dio;

  OrdersRemoteDataSourceImpl({required this.dio});

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
        '/api/orders',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final ordersList = data['orders'] as List;

        return ordersList
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to load orders',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OrderModel> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await dio.post(
        '/api/orders',
        data: orderData,
      );

      if (response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to create order',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await dio.get('/api/orders/$orderId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Order not found',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OrderModel> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      final response = await dio.put(
        '/api/orders/$orderId',
        data: {'status': newStatus},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return OrderModel.fromJson(data['order'] as Map<String, dynamic>);
      } else {
        throw ServerException(
          message: 'Failed to update order',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(message: 'Connection timeout');

      case DioExceptionType.badResponse:
        return ServerException(
          message: e.response?.data['error'] ?? 'Server error',
          statusCode: e.response?.statusCode,
        );

      case DioExceptionType.cancel:
        return NetworkException(message: 'Request cancelled');

      default:
        return NetworkException(message: 'Network error: ${e.message}');
    }
  }
}
```

**Файл:** `lib/data/datasources/orders_cache_datasource.dart`

```dart
import '../models/order_model.dart';

/// In-Memory Cache Data Source (БЕЗ SQLite!)
class OrdersCacheDataSource {
  final Map<String, OrderModel> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  static const _cacheDuration = Duration(seconds: 30);

  /// Сохранить заказы в кэш
  void cacheOrders(List<OrderModel> orders) {
    final now = DateTime.now();
    for (final order in orders) {
      _cache[order.id] = order;
      _cacheTimestamps[order.id] = now;
    }
  }

  /// Получить заказы из кэша (если свежие)
  List<OrderModel>? getCachedOrders() {
    if (_cache.isEmpty) return null;

    // Проверяем свежесть кэша
    final oldestTimestamp = _cacheTimestamps.values.reduce(
      (a, b) => a.isBefore(b) ? a : b,
    );

    final age = DateTime.now().difference(oldestTimestamp);
    if (age > _cacheDuration) {
      clearCache(); // Кэш устарел
      return null;
    }

    return _cache.values.toList();
  }

  /// Получить заказ по ID из кэша
  OrderModel? getCachedOrderById(String id) {
    final timestamp = _cacheTimestamps[id];
    if (timestamp == null) return null;

    final age = DateTime.now().difference(timestamp);
    if (age > _cacheDuration) {
      _cache.remove(id);
      _cacheTimestamps.remove(id);
      return null;
    }

    return _cache[id];
  }

  /// Очистить кэш
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
```

**Файл:** `lib/data/repositories/orders_repository_impl.dart`

```dart
import 'package:dartz/dartz.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_cache_datasource.dart';
import '../datasources/orders_remote_datasource.dart';
import '../models/order_model.dart';

/// Реализация Repository (бизнес-логика работы с данными)
class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;
  final OrdersCacheDataSource cacheDataSource;
  final NetworkInfo networkInfo;

  OrdersRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Order>>> getOrders({
    OrderStatus? status,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    // Проверка интернета
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      // Офлайн - вернуть кэш (если есть)
      final cachedOrders = cacheDataSource.getCachedOrders();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        return Right(cachedOrders.map((model) => model.toEntity()).toList());
      }
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    // Если не принудительное обновление и нет фильтра - попробовать кэш
    if (!forceRefresh && status == null) {
      final cachedOrders = cacheDataSource.getCachedOrders();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        return Right(cachedOrders.map((model) => model.toEntity()).toList());
      }
    }

    // Загрузка с сервера
    try {
      final remoteOrders = await remoteDataSource.getOrders(
        status: status?.name,
        limit: limit,
      );

      // Кэшировать только если загружаем все заказы (без фильтра)
      if (status == null) {
        cacheDataSource.cacheOrders(remoteOrders);
      }

      return Right(remoteOrders.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> createOrder(CreateOrderParams params) async {
    // Проверка интернета
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final orderData = {
        'fromAddress': params.fromAddress,
        'toAddress': params.toAddress,
        'departureTime': params.departureDateTime.toIso8601String(),
        'passengerCount': params.passengerCount,
        'totalPrice': params.totalPrice,
        'finalPrice': params.totalPrice,
        'tripType': params.tripType,
        'direction': params.direction,
        if (params.notes != null) 'notes': params.notes,
        if (params.phone != null) 'phone': params.phone,
        if (params.passengers.isNotEmpty)
          'passengers': params.passengers.map((p) => {
            'type': p.type,
            if (p.seatType != null) 'seatType': p.seatType,
            if (p.ageMonths != null) 'ageMonths': p.ageMonths,
          }).toList(),
        if (params.baggage.isNotEmpty)
          'baggage': params.baggage.map((b) => {
            'size': b.size,
            'quantity': b.quantity,
            if (b.pricePerExtraItem != null) 'pricePerExtraItem': b.pricePerExtraItem,
          }).toList(),
        if (params.pets.isNotEmpty)
          'pets': params.pets.map((p) => {
            'category': p.category,
            if (p.breed != null) 'breed': p.breed,
            if (p.cost != null) 'cost': p.cost,
          }).toList(),
      };

      final createdOrder = await remoteDataSource.createOrder(orderData);

      // Добавить в кэш
      cacheDataSource.cacheOrders([createdOrder]);

      return Right(createdOrder.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderById(String orderId) async {
    // Сначала проверить кэш
    final cachedOrder = cacheDataSource.getCachedOrderById(orderId);
    if (cachedOrder != null) {
      return Right(cachedOrder.toEntity());
    }

    // Проверка интернета
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final order = await remoteDataSource.getOrderById(orderId);
      cacheDataSource.cacheOrders([order]);
      return Right(order.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return Left(NetworkFailure(message: 'No internet connection'));
    }

    try {
      final updatedOrder = await remoteDataSource.updateOrderStatus(
        orderId,
        newStatus.name,
      );

      // Обновить в кэше
      cacheDataSource.cacheOrders([updatedOrder]);

      return Right(updatedOrder.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled)
        .then((result) => result.fold(
              (failure) => Left(failure),
              (_) => const Right(null),
            ));
  }
}
```

---

### Phase 3: Тестирование и оптимизация (2-3 дня)

#### 3.1 Unit тесты для Repository

**Файл:** `test/data/repositories/orders_repository_impl_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

// TODO: Написать unit тесты для:
// - getOrders() - с кэшем и без
// - createOrder() - success и error cases
// - updateOrderStatus()
// - Offline scenarios
// - Cache TTL scenarios
```

#### 3.2 Integration тесты

**Файл:** `test/integration/orders_flow_test.dart`

```dart
// TODO: E2E тест полного потока:
// 1. Создать заказ (клиент)
// 2. Проверить появление в PostgreSQL
// 3. Загрузить список заказов (диспетчер)
// 4. Обновить статус
// 5. Проверить обновление у клиента
```

---

### Phase 4: Деплой и мониторинг (1 день)

#### 4.1 Database Backup Strategy

```bash
#!/bin/bash
# backup_postgres.sh

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/backups/postgresql"
DB_NAME="timetotravel"

# Full backup
docker exec postgres pg_dump -U postgres $DB_NAME | gzip > "$BACKUP_DIR/full_$TIMESTAMP.sql.gz"

# Retention: keep last 7 days
find $BACKUP_DIR -name "full_*.sql.gz" -mtime +7 -delete
```

#### 4.2 Monitoring Query Performance

```sql
-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Check slow queries
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- queries slower than 100ms
ORDER BY mean_exec_time DESC
LIMIT 20;
```

---

## 📊 МЕТРИКИ УСПЕХА (KPIs)

| Метрика | Текущее значение | Целевое значение | Измерение |
|---------|------------------|------------------|-----------|
| **Время создания заказа** | 3-5 сек | < 2 сек | Backend response time |
| **Задержка видимости у диспетчера** | 5-15 сек | < 2 сек | End-to-end latency |
| **Количество строк кода** | ~5000 LOC | ~3200 LOC (-36%) | `cloc lib/` |
| **Количество сервисов** | 8 (SQLite + API) | 4 (только API) | Manual count |
| **Database queries per order** | 2 (SQLite + Sync) | 1 (PostgreSQL) | Profiling |
| **App size (APK)** | ~45 MB | ~42 MB (-7%) | Release build |
| **Crash rate** | 0.5% | < 0.3% | Firebase Crashlytics |
| **API error rate** | N/A | < 1% | Backend monitoring |

---

## ⚠️ РИСКИ И МИТИГАЦИЯ

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| **Потеря данных при миграции** | Низкая | Критическое | • Полный backup перед миграцией<br>• Тестирование на staging<br>• Rollback plan |
| **Падение production при деплое** | Средняя | Высокое | • Blue-green deployment<br>• Канареечный релиз (10% пользователей)<br>• Feature flags |
| **Проблемы с производительностью API** | Средняя | Среднее | • Load testing (Apache JMeter)<br>• Connection pooling<br>• Query optimization |
| **Отсутствие интернета у пользователей** | Высокая | Среднее | • Graceful error handling<br>• Offline mode detection<br>• Retry mechanism |
| **Увеличение нагрузки на сервер** | Средняя | Среднее | • Мониторинг CPU/RAM<br>• Auto-scaling (Selectel)<br>• CDN для статики |

---

## 📅 TIMELINE (AI-ASSISTED DEVELOPMENT)

**Важно:** Это время с учётом того, что AI-ассистент (Copilot) будет писать код и выполнять миграцию с полным доступом к серверу.

```
🚀 ДЕНЬ 1: Backend Infrastructure (4-6 часов)
├─ [1h] Database migrations (role, coordinates, indexes)
├─ [1h] Backend updates (JWT с role из БД)
├─ [1h] Payment stub model + repository
├─ [1h] Testing migrations на production
└─ [1h] Rollback plan + backup

🏗️ ДЕНЬ 2-3: Flutter Data Layer (8-10 часов)
├─ [2h] Core layer (exceptions, failures, network info)
├─ [3h] Domain layer (entities, repository interface, use cases)
├─ [3h] Data layer (remote datasource, cache datasource)
└─ [2h] Repository implementation

🔄 ДЕНЬ 3-4: Remove SQLite (6-8 часов)
├─ [2h] Update BookingService (remove offline_orders_service)
├─ [2h] Update OrdersScreen (use new OrdersRepository)
├─ [1h] Update DispatcherHomeScreen
├─ [1h] Delete SQLite services (offline_orders, local_routes, etc)
└─ [2h] Update pubspec.yaml, remove sqflite dependency

✅ ДЕНЬ 4-5: Testing & Deployment (4-6 часов)
├─ [2h] Integration testing (create order, check PostgreSQL)
├─ [1h] Fix bugs found during testing
├─ [1h] Deploy to production (docker compose up)
└─ [2h] Monitoring + hotfixes

📊 ДЕНЬ 5-6: Optimization & Documentation (4-6 часов)
├─ [2h] Performance optimization (indexes, query analysis)
├─ [1h] Setup monitoring (pg_stat_statements)
├─ [1h] Documentation updates
└─ [2h] User acceptance testing with client
```

**Total: 5-6 ДНЕЙ (26-36 часов чистого времени)**

### Разбивка по времени:

| Задача | Человек-дни | AI-часы | Ускорение |
|--------|-------------|---------|-----------|
| Backend миграции | 2-3 дня | 4-6 ч | **6x** |
| Flutter рефакторинг | 5-7 дней | 14-18 ч | **5x** |
| Удаление SQLite | 3-4 дня | 6-8 ч | **6x** |
| Тестирование | 3-4 дня | 4-6 ч | **8x** |
| Деплой + мониторинг | 2-3 дня | 4-6 ч | **6x** |
| **ИТОГО** | **15-21 день** | **32-44 ч** | **6x** |

**Почему так быстро:**
- ✅ AI пишет код мгновенно (не нужно набирать)
- ✅ AI знает всю кодовую базу (не нужно изучать)
- ✅ AI не делает опечатки (меньше багов)
- ✅ AI работает параллельно (создаёт несколько файлов)
- ✅ Полный доступ к серверу (SSH, Docker, PostgreSQL)

**Реалистичный план:**
- **День 1-2:** Backend готов ✅
- **День 3-4:** Flutter рефакторинг ✅
- **День 5:** Тестирование и деплой ✅
- **День 6:** Мониторинг и fixes ✅

---

## ✅ ACCEPTANCE CRITERIA

### Must Have (P0)
- [ ] Все SQLite сервисы удалены из кодовой базы
- [ ] Все CRUD операции работают через REST API
- [ ] Диспетчер видит новые заказы < 2 сек после создания
- [ ] Роли пользователей хранятся в PostgreSQL
- [ ] In-memory кэширование реализовано (TTL 30 сек)
- [ ] Graceful error handling для offline mode
- [ ] Unit tests покрытие > 80%
- [ ] Zero data loss при миграции

### Should Have (P1)
- [ ] Integration tests для критичных потоков
- [ ] Load testing (100 concurrent users)
- [ ] Database backup automation
- [ ] Monitoring dashboard (Grafana)
- [ ] API response time < 500ms (P95)

### Nice to Have (P2)
- [ ] Redis cache для маршрутов
- [ ] WebSocket для real-time updates
- [ ] CDN для статических ресурсов
- [ ] Automated database migrations (Liquibase)

---

## 🔐 SECURITY CONSIDERATIONS

### Authentication & Authorization
- ✅ JWT tokens с коротким TTL (15 min access, 7 days refresh)
- ✅ Role-based access control (RBAC) в PostgreSQL
- ✅ Secure password hashing (bcrypt, cost factor 10)
- ⚠️ TODO: Rate limiting на API endpoints
- ⚠️ TODO: API key rotation mechanism

### Data Protection
- ✅ HTTPS для всех API запросов
- ✅ SQL injection protection (parameterized queries)
- ✅ CORS configuration
- ⚠️ TODO: Data encryption at rest (PostgreSQL TDE)
- ⚠️ TODO: PII anonymization для backup'ов

### Infrastructure
- ✅ PostgreSQL firewall rules
- ✅ Regular security updates
- ⚠️ TODO: Intrusion detection (fail2ban)
- ⚠️ TODO: DDoS protection (Cloudflare)

---

## 📚 DOCUMENTATION

### Для разработчиков
- [ ] API Documentation (OpenAPI/Swagger)
- [ ] Database schema diagram (dbdiagram.io)
- [ ] Architecture Decision Records (ADR)
- [ ] Code style guide
- [ ] Git workflow (GitFlow)

### Для DevOps
- [ ] Deployment runbook
- [ ] Incident response playbook
- [ ] Monitoring setup guide
- [ ] Backup & restore procedures

### Для QA
- [ ] Test cases
- [ ] Test data setup guide
- [ ] Bug report template

---

## 🎓 LESSONS LEARNED

### Что сделали правильно:
1. ✅ Спроектировали REST API до начала миграции
2. ✅ Используем Repository Pattern для чистой архитектуры
3. ✅ Добавили роли пользователей в БД

### Что нужно улучшить:
1. ⚠️ Изначально планировать backend ПЕРЕД клиентом
2. ⚠️ Избегать dual-storage архитектур
3. ⚠️ Использовать feature flags для постепенного роллаута
4. ⚠️ Писать integration тесты с самого начала

---

## 🚀 NEXT STEPS (Post-Migration)

### Q1 2026 (После миграции)
- [ ] Интеграция платёжной системы (ЮKassa)
- [ ] WebSocket для real-time уведомлений
- [ ] Push notifications (FCM)
- [ ] Геокодирование адресов (Yandex Geocoder)

### Q2 2026
- [ ] Мобильное приложение для водителей
- [ ] Admin dashboard (Web)
- [ ] Analytics & Reporting
- [ ] A/B testing framework

### Q3 2026
- [ ] Горизонтальное масштабирование (Load Balancer)
- [ ] Multi-region deployment
- [ ] Microservices (если нужно)

---

## 📞 CONTACTS & APPROVALS

**Разработчик:**  
Кирилл Петров (kirillpetrovrf)

**Заказчик:**  
Евгений (евгений@titotr.ru)

**Утверждение:**  
Данное техническое задание утверждено к реализации.

---

**Версия документа:** 1.0.0  
**Последнее обновление:** 26 января 2026  
**Статус:** APPROVED ✅
