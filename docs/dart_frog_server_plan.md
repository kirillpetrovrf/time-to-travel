# Серверная часть на Dart Frog - План разработки

## 1. Структура проекта сервера

```
server/
├── main.dart                    # Точка входа сервера
├── routes/                      # API маршруты
│   ├── api/
│   │   ├── v1/
│   │   │   ├── auth/
│   │   │   │   ├── login.dart
│   │   │   │   ├── register.dart
│   │   │   │   ├── verify.dart
│   │   │   │   └── refresh.dart
│   │   │   ├── users/
│   │   │   │   ├── profile.dart
│   │   │   │   ├── [id].dart
│   │   │   │   └── index.dart
│   │   │   ├── rides/
│   │   │   │   ├── create.dart
│   │   │   │   ├── search.dart
│   │   │   │   ├── [id].dart
│   │   │   │   └── index.dart
│   │   │   ├── bookings/
│   │   │   │   ├── create.dart
│   │   │   │   ├── cancel.dart
│   │   │   │   └── [id].dart
│   │   │   ├── payments/
│   │   │   │   ├── create.dart
│   │   │   │   ├── webhook.dart
│   │   │   │   └── status.dart
│   │   │   └── notifications/
│   │   │       ├── send.dart
│   │   │       └── subscribe.dart
│   │   └── health.dart
│   └── _middleware.dart         # Общий middleware
├── lib/
│   ├── models/                  # Модели данных
│   │   ├── user.dart
│   │   ├── ride.dart
│   │   ├── booking.dart
│   │   ├── payment.dart
│   │   └── notification.dart
│   ├── services/                # Бизнес-логика
│   │   ├── auth_service.dart
│   │   ├── user_service.dart
│   │   ├── ride_service.dart
│   │   ├── payment_service.dart
│   │   ├── notification_service.dart
│   │   └── geo_service.dart
│   ├── repositories/            # Работа с БД
│   │   ├── user_repository.dart
│   │   ├── ride_repository.dart
│   │   ├── booking_repository.dart
│   │   └── payment_repository.dart
│   ├── database/                # База данных
│   │   ├── database.dart
│   │   ├── connection.dart
│   │   └── migrations/
│   │       ├── 001_create_users.sql
│   │       ├── 002_create_rides.sql
│   │       ├── 003_create_bookings.sql
│   │       └── 004_create_payments.sql
│   ├── middleware/              # Middleware
│   │   ├── auth_middleware.dart
│   │   ├── cors_middleware.dart
│   │   ├── rate_limit_middleware.dart
│   │   └── logging_middleware.dart
│   ├── utils/                   # Утилиты
│   │   ├── jwt_utils.dart
│   │   ├── validation.dart
│   │   ├── crypto.dart
│   │   └── constants.dart
│   └── config/                  # Конфигурация
│       ├── app_config.dart
│       ├── database_config.dart
│       └── env.dart
├── pubspec.yaml
├── Dockerfile
└── docker-compose.yml
```

## 2. Основные модели данных

### 2.1 Пользователь (User)
```dart
// lib/models/user.dart
class User {
  final String id;
  final String phone;
  final String? email;
  final String firstName;
  final String lastName;
  final String? avatar;
  final UserRole role; // driver, passenger, both
  final double rating;
  final int ridesCount;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Для водителей
  final String? licenseNumber;
  final String? carModel;
  final String? carColor;
  final String? carPlate;
  final DateTime? licenseExpiry;
}

enum UserRole { driver, passenger, both }
```

### 2.2 Поездка (Ride)
```dart
// lib/models/ride.dart
class Ride {
  final String id;
  final String driverId;
  final String fromAddress;
  final String toAddress;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final DateTime departureTime;
  final int availableSeats;
  final int totalSeats;
  final double pricePerSeat;
  final RideStatus status;
  final String? description;
  final bool allowsSmokingChat;
  final bool allowsPets;
  final bool allowsMusic;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Связанные данные
  final User? driver;
  final List<Booking>? bookings;
}

enum RideStatus { 
  active, 
  in_progress, 
  completed, 
  cancelled 
}
```

### 2.3 Бронирование (Booking)
```dart
// lib/models/booking.dart
class Booking {
  final String id;
  final String rideId;
  final String passengerId;
  final int seatsBooked;
  final double totalPrice;
  final BookingStatus status;
  final String? pickupPoint;
  final String? dropoffPoint;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Связанные данные
  final Ride? ride;
  final User? passenger;
}

enum BookingStatus {
  pending,
  confirmed,
  in_progress,
  completed,
  cancelled,
  refunded
}
```

## 3. API Endpoints

### 3.1 Аутентификация
```
POST /api/v1/auth/register      # Регистрация
POST /api/v1/auth/login         # Вход по телефону
POST /api/v1/auth/verify        # Подтверждение SMS кода
POST /api/v1/auth/refresh       # Обновление токена
POST /api/v1/auth/logout        # Выход
```

### 3.2 Пользователи
```
GET    /api/v1/users/profile    # Профиль текущего пользователя
PUT    /api/v1/users/profile    # Обновление профиля
POST   /api/v1/users/avatar     # Загрузка аватара
GET    /api/v1/users/{id}       # Публичный профиль пользователя
POST   /api/v1/users/verify     # Верификация документов
```

### 3.3 Поездки
```
GET    /api/v1/rides            # Поиск поездок
POST   /api/v1/rides            # Создание поездки
GET    /api/v1/rides/{id}       # Детали поездки
PUT    /api/v1/rides/{id}       # Обновление поездки
DELETE /api/v1/rides/{id}       # Отмена поездки
GET    /api/v1/rides/my         # Мои поездки
```

### 3.4 Бронирования
```
POST   /api/v1/bookings         # Создание бронирования
GET    /api/v1/bookings/{id}    # Детали бронирования
PUT    /api/v1/bookings/{id}    # Обновление бронирования
DELETE /api/v1/bookings/{id}    # Отмена бронирования
GET    /api/v1/bookings/my      # Мои бронирования
```

### 3.5 Платежи
```
POST   /api/v1/payments         # Создание платежа
GET    /api/v1/payments/{id}    # Статус платежа
POST   /api/v1/payments/webhook # Webhook от платежной системы
GET    /api/v1/payments/my      # История платежей
```

## 4. Файлы конфигурации

### 4.1 pubspec.yaml
```yaml
name: taxi_poputchik_server
description: Taxi Poputchik Backend Server

environment:
  sdk: ^3.9.0

dependencies:
  dart_frog: ^0.3.0
  postgres: ^2.6.2
  redis: ^4.0.1
  crypto: ^3.0.3
  jose: ^0.3.4
  http: ^1.1.2
  uuid: ^4.1.0
  bcrypt: ^1.1.3
  
dev_dependencies:
  test: ^1.21.0
  lints: ^3.0.0
```

### 4.2 Dockerfile
```dockerfile
FROM dart:stable AS build

WORKDIR /app
COPY pubspec.yaml ./
RUN dart pub get

COPY . .
RUN dart pub get --offline
RUN dart compile exe main.dart -o server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server

EXPOSE 8080
CMD ["/app/server"]
```

### 4.3 docker-compose.yml
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/taxi_poputchik
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=your-secret-key
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      POSTGRES_DB: taxi_poputchik
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./lib/database/migrations:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## 5. Основные сервисы

### 5.1 Auth Service
```dart
// lib/services/auth_service.dart
class AuthService {
  static Future<String> sendSmsCode(String phone) async {
    // Генерация и отправка SMS кода
    // Сохранение кода в Redis с TTL 5 минут
  }
  
  static Future<AuthResult> verifyCode(String phone, String code) async {
    // Проверка SMS кода
    // Создание или обновление пользователя
    // Генерация JWT токенов
  }
  
  static Future<AuthResult> refreshToken(String refreshToken) async {
    // Обновление access токена
  }
  
  static Future<bool> validateToken(String token) async {
    // Валидация JWT токена
  }
}
```

### 5.2 Ride Service
```dart
// lib/services/ride_service.dart
class RideService {
  static Future<List<Ride>> searchRides({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    DateTime? departureTime,
    int? seatsNeeded,
    double? maxPrice,
    double? radiusKm,
  }) async {
    // Поиск поездок в радиусе
    // Фильтрация по параметрам
    // Сортировка по релевантности
  }
  
  static Future<Ride> createRide(CreateRideRequest request) async {
    // Создание новой поездки
    // Валидация данных
    // Геокодирование адресов
  }
  
  static Future<Ride> updateRideStatus(String rideId, RideStatus status) async {
    // Обновление статуса поездки
    // Уведомление пассажиров
  }
}
```

## 6. Middleware

### 6.1 Auth Middleware
```dart
// lib/middleware/auth_middleware.dart
Handler authMiddleware(Handler handler) {
  return (RequestContext context) async {
    final authHeader = context.request.headers['Authorization'];
    
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response(statusCode: HttpStatus.unauthorized);
    }
    
    final token = authHeader.substring(7);
    final user = await AuthService.validateToken(token);
    
    if (user == null) {
      return Response(statusCode: HttpStatus.unauthorized);
    }
    
    // Добавляем пользователя в контекст
    context.provide<User>(() => user);
    
    return handler(context);
  };
}
```

### 6.2 CORS Middleware
```dart
// lib/middleware/cors_middleware.dart
Handler corsMiddleware(Handler handler) {
  return (RequestContext context) async {
    final response = await handler(context);
    
    return response.copyWith(headers: {
      ...response.headers,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    });
  };
}
```

## 7. База данных

### 7.1 Схема пользователей
```sql
-- lib/database/migrations/001_create_users.sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    avatar TEXT,
    role VARCHAR(20) NOT NULL DEFAULT 'passenger',
    rating DECIMAL(3,2) DEFAULT 5.0,
    rides_count INTEGER DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    
    -- Для водителей
    license_number VARCHAR(50),
    car_model VARCHAR(100),
    car_color VARCHAR(50),
    car_plate VARCHAR(20),
    license_expiry DATE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_role ON users(role);
```

### 7.2 Схема поездок
```sql
-- lib/database/migrations/002_create_rides.sql
CREATE TABLE rides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES users(id),
    from_address TEXT NOT NULL,
    to_address TEXT NOT NULL,
    from_lat DECIMAL(10,8) NOT NULL,
    from_lng DECIMAL(11,8) NOT NULL,
    to_lat DECIMAL(10,8) NOT NULL,
    to_lng DECIMAL(11,8) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    available_seats INTEGER NOT NULL,
    total_seats INTEGER NOT NULL,
    price_per_seat DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    description TEXT,
    allows_smoking BOOLEAN DEFAULT FALSE,
    allows_pets BOOLEAN DEFAULT FALSE,
    allows_music BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rides_driver ON rides(driver_id);
CREATE INDEX idx_rides_status ON rides(status);
CREATE INDEX idx_rides_departure ON rides(departure_time);
CREATE INDEX idx_rides_location_from ON rides(from_lat, from_lng);
CREATE INDEX idx_rides_location_to ON rides(to_lat, to_lng);
```

## 8. Безопасность

### 8.1 JWT токены
- Access токен: 15 минут
- Refresh токен: 30 дней
- Хранение в httpOnly cookies

### 8.2 Rate Limiting
- 100 запросов в минуту на IP
- 10 попыток входа в час на номер телефона
- 5 SMS кодов в час на номер

### 8.3 Валидация данных
- Проверка номеров телефонов
- Валидация геокоординат
- Санитизация пользовательского ввода

## 9. Мониторинг и логирование

### 9.1 Логирование
```dart
// lib/middleware/logging_middleware.dart
Handler loggingMiddleware(Handler handler) {
  return (RequestContext context) async {
    final stopwatch = Stopwatch()..start();
    
    print('${context.request.method} ${context.request.uri}');
    
    final response = await handler(context);
    
    stopwatch.stop();
    print('Response: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)');
    
    return response;
  };
}
```

### 9.2 Health Check
```dart
// routes/api/health.dart
import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  return Response.json(
    body: {
      'status': 'ok',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    },
  );
}
```

## 10. Deployment

### 10.1 Production конфигурация
```bash
# .env.production
DATABASE_URL=postgresql://user:password@localhost:5432/taxi_poputchik
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-very-secure-secret-key
SMS_API_KEY=your-sms-api-key
PAYMENT_API_KEY=your-payment-api-key
```

### 10.2 Systemd сервис
```ini
# /etc/systemd/system/taxi-poputchik.service
[Unit]
Description=Taxi Poputchik Server
After=network.target

[Service]
Type=simple
User=taxi
WorkingDirectory=/opt/taxi-poputchik
ExecStart=/opt/taxi-poputchik/server
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

Этот план обеспечивает полную серверную архитектуру для вашего приложения "Такси Попутчик" на Dart Frog!
