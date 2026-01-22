# Техническое Задание: Миграция Time to Travel с SQLite на PostgreSQL Backend

## 📋 Общая Информация

**Дата создания:** 21 января 2026  
**Версия:** 2.1  
**Проект:** Time to Travel (titotr.ru)  
**Тип миграции:** SQLite (локальный) → PostgreSQL + Dart Frog Backend (Сервер Selectel)

---

## 🎯 Цель Проекта

Мигрировать Flutter-приложение Time to Travel с локальной базы SQLite на полноценный backend с PostgreSQL на базе Dart Frog, развернутый на выделенном сервере Selectel с доменом **titotr.ru**.

### Текущее состояние:

- ✅ Flutter приложение работает **офлайн** с SQLite
- ✅ Firebase подключен, но **не используется** (резерв на будущее)
- ✅ Все данные локальные (пользователи, заявки, маршруты)
- ❌ Нет синхронизации между устройствами
- ❌ Нет централизованного хранилища данных

### Целевое состояние:

- ✅ Centralized PostgreSQL база на сервере
- ✅ REST API на Dart Frog для всех операций
- ✅ JWT аутентификация
- ✅ Синхронизация данных между устройствами
- ✅ Возможность офлайн-работы с последующей синхронизацией

### Ключевые Задачи:

1. ✅ Развернуть выделенный сервер на Selectel Cloud
2. ✅ Настроить домен titotr.ru с DNS-серверами Selectel
3. ✅ Получить и настроить SSL-сертификат Let's Encrypt для HTTPS
4. ✅ Разработать backend на Dart Frog с REST API
5. ✅ Настроить PostgreSQL для централизованного хранения
6. ✅ Реализовать JWT аутентификацию
7. ✅ Мигрировать структуру данных SQLite → PostgreSQL
8. ✅ Обновить Flutter приложение для работы с API
9. ✅ Реализовать офлайн-режим с синхронизацией (опционально)
10. ✅ Автоматизировать деплой через Docker и CI/CD

**Примечание:** Проект работает только с текстовыми данными (заявки на поездки, информация о пользователях, маршруты), поэтому файловое хранилище (S3) не требуется. Все данные хранятся в PostgreSQL.

---

## 🖥️ Инфраструктура

### 1. Домен и DNS Настройка

**Домен:** titotr.ru  
**Регистратор:** Selectel  
**Статус:** Только что приобретён, требуется настройка DNS и SSL

#### DNS Настройка на Selectel

**DNS-серверы Selectel (как показано на скриншоте):**
```
d.ns.selectel.ru
a.ns.selectel.ru
b.ns.selectel.ru
c.ns.selectel.ru
```

**Необходимые DNS записи:**

| Тип | Имя | Значение | TTL |
|-----|-----|----------|-----|
| A | @ | <IP_ВАШЕГО_СЕРВЕРА> | 3600 |
| A | www | <IP_ВАШЕГО_СЕРВЕРА> | 3600 |
| AAAA | @ | <IPv6_АДРЕС> (если есть) | 3600 |
| CNAME | api | titotr.ru | 3600 |
| TXT | @ | "v=spf1 include:_spf.selectel.ru ~all" | 3600 |

#### Проверка DNS после настройки:
```bash
# Проверить A-запись
dig titotr.ru A

# Проверить DNS-серверы
dig titotr.ru NS

# Проверить с конкретного DNS
dig @d.ns.selectel.ru titotr.ru
```

⚠️ **ВАЖНО:** Распространение DNS записей может занять от 15 минут до 48 часов!

---

### 2. Провайдер и Конфигурация Сервера

**Хостинг:** Selectel Cloud (Выделенный VPS)  
**Локация:** Москва, Россия (рекомендуется для российской аудитории)  

**Минимальные требования для Time to Travel:**
- **CPU:** 2 vCPU (достаточно для старта)
- **RAM:** 4 GB (минимум для Dart Frog + PostgreSQL)
- **Диск:** 40 GB SSD (только БД и логи, без файлового хранилища)
- **ОС:** Ubuntu 22.04 LTS (стабильная версия с долгой поддержкой)
- **IP:** Статический IPv4 адрес
- **Bandwidth:** Безлимитный трафик

**Рекомендуемая конфигурация для роста:**
- **CPU:** 4 vCPU
- **RAM:** 8 GB (комфортная работа + запас)
- **Диск:** 80 GB SSD NVMe (с запасом для роста)
- **Backup:** Автоматические бэкапы 1 раз в день
- **IPv6:** Включить для будущего

**Примерная стоимость на Selectel:**
- Минимальная: ~500-700 руб/мес
- Рекомендуемая: ~1000-1500 руб/мес

---

## 🔄 Миграция с Firebase

### 3. Сравнение Архитектур

#### Старая архитектура (Firebase):
```
Flutter App
    ↓
Firebase SDK
    ├─→ Firebase Auth (аутентификация)
    ├─→ Firestore (база данных)
    ├─→ Cloud Functions (бизнес-логика)
    └─→ FCM (push-уведомления)
```

#### Новая архитектура (Dart Frog):
```
Flutter App
    ↓
HTTP Client (dio/http)
    ↓
HTTPS/REST API (titotr.ru/api)
    ↓
Nginx (Reverse Proxy + SSL)
    ↓
Dart Frog Backend (Docker)
    ├─→ JWT Auth (собственная аутентификация)
    ├─→ PostgreSQL (реляционная БД для всех данных)
    ├─→ Dart Frog Routes (REST API endpoints)
    └─→ Redis (кеширование + sessions)
```

### Преимущества миграции:

✅ **Полный контроль** над backend-логикой  
✅ **Нет vendor lock-in** (независимость от Firebase)  
✅ **Снижение затрат** на долгосрочной перспективе  
✅ **Единый язык** (Dart) для frontend и backend  
✅ **Производительность** - выделенные ресурсы  
✅ **Соблюдение 152-ФЗ** - данные в России  
✅ **Гибкость** в настройке и масштабировании  
✅ **Простота** - только БД, без дополнительных сервисов хранения

---

## 🔐 Безопасность и Доступ

### 4. SSH Конфигурация (Critical Security)

**Требования:**
- ✅ Отключить вход по паролю (только SSH-ключи)
- ✅ Изменить стандартный порт SSH (с 22 на кастомный, например 2222)
- ✅ Настроить fail2ban для защиты от brute-force атак
- ✅ Включить UFW (Uncomplicated Firewall)
- ✅ Использовать ED25519 SSH-ключи (современный стандарт)

**Генерация SSH-ключа на локальной машине (macOS/Linux):**
```bash
ssh-keygen -t ed25519 -C "your_email@example.com" -f ~/.ssh/id_ed25519_project
```

**Настройка SSH на сервере:**
```bash
# Создать директорию для ключей
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Добавить публичный ключ
nano ~/.ssh/authorized_keys
# Вставить содержимое id_ed25519_project.pub
chmod 600 ~/.ssh/authorized_keys

# Настроить sshd_config
sudo nano /etc/ssh/sshd_config
```

**Файл `/etc/ssh/sshd_config`:**
```
Port 2222
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM no
X11Forwarding no
AllowUsers deploy_user
```

**Настройка SSH на клиенте (macOS) `~/.ssh/config`:**
```
Host titotr-production
    HostName titotr.ru
    Port 2222
    User deploy
    IdentityFile ~/.ssh/id_ed25519_titotr
    UseKeychain yes
    AddKeysToAgent yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

**Добавить ключ в macOS Keychain:**
```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_titotr

# Проверить подключение
ssh titotr-production
```

---

## 🐸 Dart Frog Backend

### 5. Установка и Структура Dart Frog

**Что такое Dart Frog?**

Dart Frog - это современный backend-фреймворк на Dart, созданный командой Very Good Ventures. Он предоставляет:
- 🚀 Быструю разработку REST API
- 🔥 Hot reload для backend (как во Flutter!)
- 📦 Middleware system (auth, logging, CORS)
- 🧪 Встроенное тестирование
- 🐳 Docker support из коробки
- 🎯 Type-safe routing

**Официальный сайт:** https://dart-frog.dev/

#### Структура Dart Frog проекта:

```
backend/
├── routes/                    # API endpoints (автороутинг)
│   ├── index.dart            # GET/POST /api/
│   ├── health.dart           # GET /api/health
│   ├── auth/
│   │   ├── login.dart        # POST /api/auth/login
│   │   ├── register.dart     # POST /api/auth/register
│   │   └── refresh.dart      # POST /api/auth/refresh
│   ├── users/
│   │   ├── [id].dart         # GET/PUT/DELETE /api/users/:id
│   │   └── me.dart           # GET /api/users/me
│   ├── bookings/
│   │   ├── index.dart        # GET/POST /api/bookings
│   │   ├── [id].dart         # GET/PUT/DELETE /api/bookings/:id
│   │   └── [id]/
│   │       └── cancel.dart   # POST /api/bookings/:id/cancel
│   └── _middleware.dart      # Глобальный middleware
├── lib/
│   ├── models/               # Data models
│   │   ├── user.dart
│   │   ├── booking.dart
│   │   └── route.dart
│   ├── services/             # Business logic
│   │   ├── auth_service.dart
│   │   ├── database_service.dart
│   │   ├── storage_service.dart
│   │   └── notification_service.dart
│   ├── repositories/         # Data access layer
│   │   ├── user_repository.dart
│   │   └── booking_repository.dart
│   ├── middlewares/          # Custom middleware
│   │   ├── auth_middleware.dart
│   │   ├── cors_middleware.dart
│   │   └── logging_middleware.dart
│   └── utils/
│       ├── jwt_utils.dart
│       ├── validators.dart
│       └── constants.dart
├── test/                     # Unit & integration tests
│   ├── routes/
│   └── services/
├── pubspec.yaml              # Dependencies
├── Dockerfile                # Production image
├── docker-compose.yml        # Local development
└── .env.example              # Environment template
```

#### Пример routes/auth/login.dart:

```dart
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

// POST /api/auth/login
Future<Response> onRequest(RequestContext context) async {
  // Только POST запросы
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    // Получить данные из body
    final body = await context.request.json() as Map<String, dynamic>;
    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Email and password are required'},
      );
    }

    // Получить сервис из middleware
    final authService = context.read<AuthService>();
    
    // Аутентификация
    final result = await authService.login(email, password);

    return Response.json(
      body: {
        'access_token': result.accessToken,
        'refresh_token': result.refreshToken,
        'user': result.user.toJson(),
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Invalid credentials'},
    );
  }
}
```

#### Пример routes/_middleware.dart:

```dart
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/auth_service.dart';
import 'package:backend/services/database_service.dart';

// Глобальный middleware для всех routes
Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(corsMiddleware())
      .use(databaseProvider())
      .use(authServiceProvider());
}

// CORS middleware
Middleware corsMiddleware() {
  return (handler) {
    return (context) async {
      final response = await handler(context);
      
      return response.copyWith(
        headers: {
          ...response.headers,
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        },
      );
    };
  };
}

// Database connection provider
Middleware databaseProvider() {
  return provider<DatabaseService>(
    (_) => DatabaseService(connectionString: _envDatabaseUrl),
  );
}

// Auth service provider
Middleware authServiceProvider() {
  return (handler) {
    return (context) {
      final db = context.read<DatabaseService>();
      final authService = AuthService(db);
      
      return handler(
        context.provide<AuthService>(() => authService),
      );
    };
  };
}
```

#### pubspec.yaml для Dart Frog:

```yaml
name: time_to_travel_backend
description: Dart Frog backend for Time to Travel app
version: 1.0.0
publish_to: none

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  dart_frog: ^2.0.0
  postgres: ^3.0.0              # PostgreSQL driver
  jwt_decoder: ^2.0.1           # JWT parsing
  dart_jsonwebtoken: ^2.12.0    # JWT generation
  bcrypt: ^1.1.3                # Password hashing
  uuid: ^4.0.0                  # UUID generation
  http: ^1.1.0                  # HTTP client
  redis: ^3.1.0                 # Redis client
  dotenv: ^4.2.0                # Environment variables

dev_dependencies:
  build_runner: ^2.4.0
  build_verify: ^3.1.0
  build_version: ^2.1.1
  dart_frog_cli: ^2.0.0
  mocktail: ^1.0.0
  test: ^1.24.0
  very_good_analysis: ^6.0.0
```

#### Dockerfile для Dart Frog:

```dockerfile
# Build stage
FROM dart:stable AS build

WORKDIR /app

# Copy dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy source
COPY . .

# Build Dart Frog
RUN dart pub global activate dart_frog_cli
RUN dart pub global run dart_frog_cli:dart_frog build

# Production stage
FROM dart:stable-slim AS production

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built app
COPY --from=build /app/build .

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD dart /app/bin/server.dart || exit 1

# Run app
CMD ["dart", "bin/server.dart", "--hostname", "0.0.0.0", "--port", "8080"]
```

#### Локальная разработка:

```bash
# Установить Dart Frog CLI
dart pub global activate dart_frog_cli

# Создать новый проект
dart_frog create backend

# Запустить dev server с hot reload
cd backend
dart_frog dev

# Server запустится на http://localhost:8080
# Hot reload работает автоматически!
```

---

## 🗄️ PostgreSQL Database

### 6. Настройка PostgreSQL вместо Firestore

#### Миграция данных Firestore → PostgreSQL

**Firestore (NoSQL):**
```javascript
// Коллекция users
users/
  ├── user_id_1
  │   ├── email: "user@example.com"
  │   ├── name: "John Doe"
  │   └── created_at: Timestamp
  └── user_id_2
```

**PostgreSQL (SQL):**
```sql
-- Таблица users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для производительности
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_created_at ON users(created_at);
```

#### Схема базы данных Time to Travel:

```sql
-- Файл: database/init/01-schema.sql

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- для полнотекстового поиска

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Refresh tokens (для JWT)
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Routes (маршруты)
CREATE TABLE routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    from_city VARCHAR(255) NOT NULL,
    to_city VARCHAR(255) NOT NULL,
    distance_km DECIMAL(10, 2),
    duration_minutes INTEGER,
    base_price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Bookings (бронирования)
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES routes(id),
    pickup_address TEXT NOT NULL,
    dropoff_address TEXT NOT NULL,
    pickup_time TIMESTAMP WITH TIME ZONE NOT NULL,
    passengers INTEGER DEFAULT 1,
    luggage INTEGER DEFAULT 0,
    total_price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending', -- pending, confirmed, completed, cancelled
    payment_status VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payments (платежи)
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'RUB',
    payment_method VARCHAR(50), -- card, cash, sbp
    payment_provider VARCHAR(50), -- yookassa, tinkoff
    transaction_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending',
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для производительности
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_bookings_user_id ON bookings(user_id);
CREATE INDEX idx_bookings_status ON bookings(status);
CREATE INDEX idx_bookings_pickup_time ON bookings(pickup_time);
CREATE INDEX idx_payments_booking_id ON payments(booking_id);

-- Триггер для updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON routes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON bookings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

#### Database Service в Dart:

```dart
// lib/services/database_service.dart

import 'package:postgres/postgres.dart';

class DatabaseService {
  late final Connection _connection;
  
  DatabaseService({required String connectionString}) {
    _initConnection(connectionString);
  }

  Future<void> _initConnection(String connectionString) async {
    final uri = Uri.parse(connectionString);
    
    _connection = await Connection.open(
      Endpoint(
        host: uri.host,
        database: uri.pathSegments.first,
        username: uri.userInfo.split(':').first,
        password: uri.userInfo.split(':').last,
        port: uri.port,
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.require, // Важно для production!
      ),
    );
  }

  // Execute query
  Future<Result> execute(
    String query, {
    Map<String, dynamic>? parameters,
  }) async {
    return await _connection.execute(
      Sql.named(query),
      parameters: parameters,
    );
  }

  // Close connection
  Future<void> close() async {
    await _connection.close();
  }
}
```

---

## 🔑 JWT Authentication

### 7. Замена Firebase Auth на JWT

#### Концепция JWT:

Firebase Auth → **JWT (JSON Web Tokens)** + Refresh Tokens

**Преимущества JWT:**
- ✅ Stateless (не нужно хранить сессии)
- ✅ Работает везде (web, mobile, API)
- ✅ Содержит claims (роли, permissions)
- ✅ Безопасный при правильной реализации

#### AuthService с JWT:

```dart
// lib/services/auth_service.dart

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final DatabaseService _db;
  final String _jwtSecret;
  final Duration _accessTokenExpiry = Duration(minutes: 15);
  final Duration _refreshTokenExpiry = Duration(days: 30);

  AuthService(this._db, this._jwtSecret);

  // Регистрация
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
  }) async {
    // Проверить, существует ли пользователь
    final exists = await _userExists(email);
    if (exists) {
      throw AuthException('User already exists');
    }

    // Хешировать пароль
    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

    // Создать пользователя
    final result = await _db.execute(
      '''
      INSERT INTO users (email, password_hash, name)
      VALUES (@email, @password_hash, @name)
      RETURNING id, email, name, created_at
      ''',
      parameters: {
        'email': email,
        'password_hash': passwordHash,
        'name': name,
      },
    );

    final user = User.fromRow(result.first);

    // Сгенерировать токены
    final tokens = await _generateTokens(user.id);

    return AuthResult(
      user: user,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  // Вход
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // Найти пользователя
    final result = await _db.execute(
      'SELECT * FROM users WHERE email = @email',
      parameters: {'email': email},
    );

    if (result.isEmpty) {
      throw AuthException('Invalid credentials');
    }

    final user = User.fromRow(result.first);

    // Проверить пароль
    final passwordMatch = BCrypt.checkpw(
      password,
      user.passwordHash,
    );

    if (!passwordMatch) {
      throw AuthException('Invalid credentials');
    }

    // Сгенерировать токены
    final tokens = await _generateTokens(user.id);

    return AuthResult(
      user: user,
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  // Обновить access token через refresh token
  Future<TokenPair> refreshAccessToken(String refreshToken) async {
    // Проверить refresh token в БД
    final result = await _db.execute(
      '''
      SELECT rt.user_id
      FROM refresh_tokens rt
      WHERE rt.token_hash = @token_hash
        AND rt.expires_at > NOW()
      ''',
      parameters: {
        'token_hash': _hashToken(refreshToken),
      },
    );

    if (result.isEmpty) {
      throw AuthException('Invalid refresh token');
    }

    final userId = result.first[0] as String;

    // Сгенерировать новые токены
    return await _generateTokens(userId);
  }

  // Генерация токенов
  Future<TokenPair> _generateTokens(String userId) async {
    // Access token (короткий срок)
    final accessToken = JWT(
      {
        'user_id': userId,
        'type': 'access',
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': DateTime.now()
            .add(_accessTokenExpiry)
            .millisecondsSinceEpoch ~/ 1000,
      },
    ).sign(SecretKey(_jwtSecret));

    // Refresh token (длинный срок)
    final refreshToken = Uuid().v4();
    final refreshTokenHash = _hashToken(refreshToken);

    // Сохранить refresh token в БД
    await _db.execute(
      '''
      INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
      VALUES (@user_id, @token_hash, @expires_at)
      ''',
      parameters: {
        'user_id': userId,
        'token_hash': refreshTokenHash,
        'expires_at': DateTime.now().add(_refreshTokenExpiry),
      },
    );

    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  // Валидация access token
  Future<User?> validateAccessToken(String token) async {
    try {
      final jwt = JWT.verify(token, SecretKey(_jwtSecret));
      final userId = jwt.payload['user_id'] as String;

      // Получить пользователя
      final result = await _db.execute(
        'SELECT * FROM users WHERE id = @id',
        parameters: {'id': userId},
      );

      if (result.isEmpty) return null;

      return User.fromRow(result.first);
    } catch (e) {
      return null;
    }
  }

  String _hashToken(String token) {
    return BCrypt.hashpw(token, BCrypt.gensalt());
  }

  Future<bool> _userExists(String email) async {
    final result = await _db.execute(
      'SELECT COUNT(*) FROM users WHERE email = @email',
      parameters: {'email': email},
    );
    return result.first[0] as int > 0;
  }
}
```

#### Auth Middleware:

```dart
// lib/middlewares/auth_middleware.dart

import 'package:dart_frog/dart_frog.dart';

Middleware authMiddleware() {
  return (handler) {
    return (context) async {
      // Получить Authorization header
      final authHeader = context.request.headers['Authorization'];
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'Missing or invalid authorization header'},
        );
      }

      // Извлечь токен
      final token = authHeader.substring(7);

      // Валидировать токен
      final authService = context.read<AuthService>();
      final user = await authService.validateAccessToken(token);

      if (user == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {'error': 'Invalid or expired token'},
        );
      }

      // Добавить пользователя в context
      return handler(
        context.provide<User>(() => user),
      );
    };
  };
}
```

#### Использование в защищенных routes:

```dart
// routes/users/me/_middleware.dart

import 'package:dart_frog/dart_frog.dart';
import 'package:backend/middlewares/auth_middleware.dart';

Handler middleware(Handler handler) {
  return handler.use(authMiddleware());
}

// routes/users/me/index.dart

Future<Response> onRequest(RequestContext context) async {
  // Пользователь уже есть в context благодаря middleware
  final user = context.read<User>();

  return Response.json(
    body: user.toJson(),
  );
}
```

---

## 🐳 Docker Инфраструктура

### 8. Docker Compose Stack для Time to Travel

**Docker Engine:**
```bash
# Обновить систему
sudo apt update && sudo apt upgrade -y

# Установить зависимости
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Добавить GPG ключ Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавить репозиторий Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установить Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Добавить пользователя в группу docker
sudo usermod -aG docker deploy
newgrp docker

# Проверить установку
docker --version
docker compose version
```

**Настроить автозапуск Docker:**
```bash
sudo systemctl enable docker
sudo systemctl start docker
```

---

## 🏗️ Docker Compose для Time to Travel

### 9. Production Docker Compose

**docker-compose.yml:**

```yaml
version: '3.9'

services:
  # Nginx Reverse Proxy + SSL
  nginx:
    image: nginx:alpine
    container_name: titotr_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - certbot-www:/var/www/certbot:ro
      - certbot-conf:/etc/letsencrypt:ro
    depends_on:
      - backend
    networks:
      - titotr_network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  # Dart Frog Backend
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
      args:
        - DART_VERSION=stable
    container_name: titotr_backend
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
      - JWT_ACCESS_EXPIRY=900  # 15 minutes
      - JWT_REFRESH_EXPIRY=2592000  # 30 days
      - APP_ENV=production
      - LOG_LEVEL=info
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    networks:
      - titotr_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "5"

  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    container_name: titotr_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
      - POSTGRES_INITDB_ARGS=--encoding=UTF-8 --lc-collate=ru_RU.UTF-8 --lc-ctype=ru_RU.UTF-8
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d:ro
      - ./backups:/backups
    networks:
      - titotr_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # Redis Cache & Sessions
  redis:
    image: redis:7-alpine
    container_name: titotr_redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    networks:
      - titotr_network
    healthcheck:
      test: ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "3"

  # Certbot для SSL
  certbot:
    image: certbot/certbot:latest
    container_name: titotr_certbot
    volumes:
      - certbot-www:/var/www/certbot
      - certbot-conf:/etc/letsencrypt
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew --webroot -w /var/www/certbot --quiet; sleep 12h & wait $${!}; done;'"
    networks:
      - titotr_network

  # Портainer (опционально, для управления Docker через UI)
  portainer:
    image: portainer/portainer-ce:latest
    container_name: titotr_portainer
    restart: unless-stopped
    ports:
      - "9443:9443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    networks:
      - titotr_network
    command: --http-enabled

networks:
  titotr_network:
    driver: bridge
    name: titotr_network

volumes:
  postgres_data:
    name: titotr_postgres_data
  redis_data:
    name: titotr_redis_data
  certbot-www:
    name: titotr_certbot_www
  certbot-conf:
    name: titotr_certbot_conf
  portainer_data:
    name: titotr_portainer_data
```

**Файл .env для production:**

```bash
# Database
POSTGRES_USER=titotr_user
POSTGRES_PASSWORD=<STRONG_PASSWORD_32_CHARS>
POSTGRES_DB=titotr_production

# Redis
REDIS_PASSWORD=<REDIS_PASSWORD_32_CHARS>

# JWT
JWT_SECRET=<JWT_SECRET_64_CHARS>

# Email (опционально)
SMTP_HOST=smtp.yandex.ru
SMTP_PORT=465
SMTP_USER=noreply@titotr.ru
SMTP_PASSWORD=<EMAIL_PASSWORD>
SMTP_FROM=Time to Travel <noreply@titotr.ru>

# Payment (опционально, YooKassa или Тинькофф)
PAYMENT_PROVIDER=yookassa
PAYMENT_SHOP_ID=<SHOP_ID>
PAYMENT_SECRET_KEY=<PAYMENT_SECRET>

# App
APP_NAME=Time to Travel
APP_URL=https://titotr.ru
API_URL=https://titotr.ru/api
```

---

## 🌐 Nginx Configuration для titotr.ru

### 10. Настройка Nginx с SSL

**Структура конфигурации:**
```
nginx/
├── nginx.conf           # Основной файл
└── conf.d/
    ├── titotr.conf      # Конфигурация для titotr.ru
    └── ssl.conf         # SSL параметры
```

**nginx/nginx.conf:**

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 2048;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for" '
                    'rt=$request_time uct="$upstream_connect_time" '
                    'uht="$upstream_header_time" urt="$upstream_response_time"';

    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;
    client_body_buffer_size 128k;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript
               application/json application/javascript application/xml+rss
               application/rss+xml font/truetype font/opentype
               application/vnd.ms-fontobject image/svg+xml;
    gzip_disable "msie6";

    # Security headers (глобальные)
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=auth_limit:10m rate=5r/m;

    # Upstream для backend
    upstream backend_servers {
        least_conn;
        server backend:8080 max_fails=3 fail_timeout=30s;
        keepalive 32;
    }

    # Включить конфигурации сайтов
    include /etc/nginx/conf.d/*.conf;
}
```

**nginx/conf.d/titotr.conf:**

```nginx
# HTTP сервер - редирект на HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name titotr.ru www.titotr.ru;

    # ACME challenge для Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Health check (для мониторинга)
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    # Редирект всех остальных запросов на HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS сервер - основной
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name titotr.ru www.titotr.ru;

    # SSL сертификаты (после получения через certbot)
    ssl_certificate /etc/letsencrypt/live/titotr.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/titotr.ru/privkey.pem;

    # SSL параметры (современные и безопасные)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    
    # SSL session cache
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # OCSP Stapling
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/titotr.ru/chain.pem;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # Security headers для HTTPS
    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Logs
    access_log /var/log/nginx/titotr_access.log main;
    error_log /var/log/nginx/titotr_error.log warn;

    # Health check
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    # API endpoints (Dart Frog backend)
    location /api {
        # Rate limiting
        limit_req zone=api_limit burst=20 nodelay;
        limit_req_status 429;

        # Proxy к backend
        proxy_pass http://backend_servers;
        proxy_http_version 1.1;

        # Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Request-ID $request_id;

        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;

        # Buffering
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;

        # Keepalive
        proxy_set_header Connection "";
    }

    # Более строгий rate limit для auth endpoints
    location /api/auth {
        limit_req zone=auth_limit burst=5 nodelay;
        limit_req_status 429;

        proxy_pass http://backend_servers;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Статические файлы (если будут)
    location /static/ {
        alias /var/www/static/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    # Заглушка для корня (можно заменить на Landing Page)
    location = / {
        return 200 '{"status":"ok","message":"Time to Travel API","version":"1.0.0"}';
        add_header Content-Type application/json;
    }

    # Favicon
    location = /favicon.ico {
        access_log off;
        log_not_found off;
        return 204;
    }

    # Robots.txt
    location = /robots.txt {
        access_log off;
        log_not_found off;
        return 200 "User-agent: *\nDisallow: /api/\n";
        add_header Content-Type text/plain;
    }
}
```

### Получение SSL сертификата для titotr.ru:

```bash
# 1. Убедиться что DNS настроен (A-запись titotr.ru → IP сервера)
dig titotr.ru +short

# 2. Запустить только nginx (без SSL пока)
docker compose up -d nginx

# 3. Получить сертификат через certbot
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@titotr.ru \
  --agree-tos \
  --no-eff-email \
  --force-renewal \
  -d titotr.ru \
  -d www.titotr.ru

# 4. Перезапустить nginx с SSL
docker compose restart nginx

# 5. Проверить SSL
curl -I https://titotr.ru/health

# 6. Тест SSL рейтинга
# Открыть: https://www.ssllabs.com/ssltest/analyze.html?d=titotr.ru
```

**Автоматическое обновление сертификата:**

Сертификаты Let's Encrypt действуют 90 дней. Контейнер `certbot` в docker-compose автоматически обновляет их каждые 12 часов.

Можно также добавить cron job:

```bash
# Редактировать crontab
crontab -e

# Добавить строку (проверка обновления каждый день в 3:00)
0 3 * * * cd /opt/titotr && docker compose run --rm certbot renew --quiet && docker compose restart nginx
```

---

## 🏗️ Архитектура Приложения

### 4. Docker Compose Stack

**Основные сервисы:**

1. **Nginx** (Reverse Proxy + SSL)
   - Порты: 80 (HTTP), 443 (HTTPS)
   - SSL сертификаты через Let's Encrypt
   - Автоматическое перенаправление HTTP → HTTPS

2. **Backend API** (Dart/Frog, Node.js, или другой)
   - Внутренний порт: 8080
   - Health checks
   - Automatic restart

3. **Frontend Website** (Next.js, React, или другой)
   - Внутренний порт: 3000
   - Static file serving
   - Volume mounts для быстрого деплоя

4. **PostgreSQL Database**
   - Версия: 15-alpine
   - Persistent volume для данных
   - Регулярные бэкапы

5. **Redis Cache** (опционально)
   - Версия: 7-alpine
   - Для сессий и кэширования

**Пример структуры `docker-compose.yml`:**
```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    container_name: app_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/ssl:/etc/nginx/ssl:ro
      - certbot-www:/var/www/certbot
      - certbot-conf:/etc/letsencrypt
    depends_on:
      - backend
      - website
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: app_backend
    restart: unless-stopped
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/dbname
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  website:
    build:
      context: ./website
      dockerfile: Dockerfile
    container_name: app_website
    restart: unless-stopped
    volumes:
      - ./website/public:/app/public  # Для быстрого деплоя статики
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:15-alpine
    container_name: app_postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
      - POSTGRES_DB=${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./database/init:/docker-entrypoint-initdb.d
    networks:
      - app_network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: app_redis
    restart: unless-stopped
    volumes:
      - redis_data:/data
    networks:
      - app_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  certbot:
    image: certbot/certbot
    container_name: app_certbot
    volumes:
      - certbot-www:/var/www/certbot
      - certbot-conf:/etc/letsencrypt
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"

networks:
  app_network:
    driver: bridge

volumes:
  postgres_data:
  redis_data:
  certbot-www:
  certbot-conf:
```

---

## 🌐 Nginx и SSL

### 5. Настройка Reverse Proxy и SSL

**Структура nginx конфигурации:**
```
nginx/
├── nginx.conf           # Основной конфиг
├── ssl/                 # SSL сертификаты
└── conf.d/
    ├── default.conf     # Дефолтный сервер
    ├── api.conf         # Backend API
    └── website.conf     # Frontend website
```

**Пример `nginx.conf`:**
```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript 
               application/json application/javascript application/xml+rss 
               application/rss+xml font/truetype font/opentype 
               application/vnd.ms-fontobject image/svg+xml;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Include server configs
    include /etc/nginx/conf.d/*.conf;
}
```

**Пример конфига для website:**
```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name yourdomain.com www.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://website:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api {
        proxy_pass http://backend:8080;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Получение SSL сертификата:**
```bash
# Первоначальная настройка (только HTTP)
docker compose up -d nginx

# Получить сертификат
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  -d yourdomain.com \
  -d www.yourdomain.com \
  --email your_email@example.com \
  --agree-tos \
  --no-eff-email

# Перезапустить nginx с HTTPS
docker compose restart nginx
```

---

## 📦 Система Деплоя

### 6. Автоматизация Деплоя через SSH

**Структура скриптов деплоя:**
```
scripts/
├── deploy.sh              # Основной скрипт деплоя
├── deploy_backend.sh      # Деплой только backend
├── deploy_website.sh      # Деплой только website
├── backup_db.sh           # Бэкап базы данных
├── restore_db.sh          # Восстановление БД
└── setup_server.sh        # Первоначальная настройка сервера
```

**Пример `deploy.sh`:**
```bash
#!/bin/bash

# Конфигурация
SERVER_USER="deploy_user"
SERVER_HOST="yourdomain.com"
SERVER_PORT="2222"
DEPLOY_PATH="/opt/app"

echo "🚀 Деплой приложения на production сервер..."

# Проверка SSH соединения
echo "➡️ Проверка SSH соединения..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "echo '✅ SSH соединение успешно'" || exit 1

# Синхронизация файлов
echo "➡️ Синхронизация файлов..."
rsync -avz --delete \
  --exclude 'node_modules' \
  --exclude '.git' \
  --exclude '.env.local' \
  --exclude 'build' \
  -e "ssh -p $SERVER_PORT" \
  ./ $SERVER_USER@$SERVER_HOST:$DEPLOY_PATH/

# Копирование .env файла
echo "➡️ Копирование .env файла..."
scp -P $SERVER_PORT .env.production $SERVER_USER@$SERVER_HOST:$DEPLOY_PATH/.env

# Деплой на сервере
echo "➡️ Запуск деплоя на сервере..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST << 'EOF'
cd /opt/app

# Создать бэкап БД перед обновлением
echo "📦 Создание бэкапа базы данных..."
docker compose exec -T postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB > backup_$(date +%Y%m%d_%H%M%S).sql

# Пересборка и перезапуск контейнеров
echo "🔨 Пересборка Docker образов..."
docker compose build --no-cache

echo "♻️ Перезапуск контейнеров..."
docker compose up -d

# Ожидание запуска
echo "⏳ Ожидание запуска сервисов..."
sleep 10

# Проверка статуса
echo "📊 Статус контейнеров:"
docker compose ps

# Health check
echo "🏥 Проверка здоровья сервисов..."
curl -f http://localhost/health || echo "⚠️ Health check failed"

EOF

echo "✅ Деплой завершен!"
echo "🌐 Проверьте сайт: https://yourdomain.com"
```

**Пример `deploy_website.sh` (быстрый деплой только сайта):**
```bash
#!/bin/bash

SERVER_USER="deploy_user"
SERVER_HOST="yourdomain.com"
SERVER_PORT="2222"

echo "🚀 Быстрый деплой website..."

# Сборка локально
echo "🔨 Сборка Next.js приложения..."
cd website
npm run build

# Загрузка на сервер
echo "➡️ Загрузка файлов на сервер..."
rsync -avz --delete \
  -e "ssh -p $SERVER_PORT" \
  .next/ $SERVER_USER@$SERVER_HOST:/opt/app/website/.next/

rsync -avz --delete \
  -e "ssh -p $SERVER_PORT" \
  public/ $SERVER_USER@$SERVER_HOST:/opt/app/website/public/

# Перезапуск контейнера
echo "♻️ Перезапуск website контейнера..."
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "cd /opt/app && docker compose restart website"

echo "✅ Деплой website завершен!"
```

**Пример `backup_db.sh`:**
```bash
#!/bin/bash

SERVER_USER="deploy_user"
SERVER_HOST="yourdomain.com"
SERVER_PORT="2222"
BACKUP_DIR="./backups"

mkdir -p $BACKUP_DIR

BACKUP_FILE="backup_$(date +%Y%m%d_%H%M%S).sql"

echo "📦 Создание бэкапа базы данных..."

ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST \
  "cd /opt/app && docker compose exec -T postgres pg_dump -U \$POSTGRES_USER \$POSTGRES_DB" \
  > $BACKUP_DIR/$BACKUP_FILE

gzip $BACKUP_DIR/$BACKUP_FILE

echo "✅ Бэкап создан: $BACKUP_DIR/$BACKUP_FILE.gz"
```

---

## 🔧 Мониторинг и Логирование

### 7. Настройка Мониторинга

**Инструменты:**

1. **Docker Stats** (встроенный)
```bash
docker stats
```

2. **Portainer** (опционально - UI для Docker)
```yaml
# Добавить в docker-compose.yml
portainer:
  image: portainer/portainer-ce:latest
  container_name: portainer
  restart: unless-stopped
  ports:
    - "9000:9000"
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - portainer_data:/data
```

3. **Логирование**
```bash
# Просмотр логов контейнера
docker compose logs -f backend

# Ротация логов (добавить в docker-compose.yml)
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

4. **Uptime Kuma** (мониторинг доступности)
```yaml
uptime-kuma:
  image: louislam/uptime-kuma:1
  container_name: uptime_kuma
  restart: unless-stopped
  ports:
    - "3001:3001"
  volumes:
    - uptime_kuma_data:/app/data
```

---

## 🔥 Firewall и Безопасность

### 8. Настройка UFW

```bash
# Установить UFW
sudo apt install -y ufw

# Разрешить SSH (кастомный порт)
sudo ufw allow 2222/tcp

# Разрешить HTTP и HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Запретить всё остальное по умолчанию
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Включить firewall
sudo ufw enable

# Проверить статус
sudo ufw status verbose
```

**Настройка Fail2Ban:**
```bash
# Установить fail2ban
sudo apt install -y fail2ban

# Создать конфиг
sudo nano /etc/fail2ban/jail.local
```

**Файл `/etc/fail2ban/jail.local`:**
```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = 2222
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
```

```bash
# Запустить fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

## 📝 Environment Variables

### 9. Управление Секретами

**Создать `.env` файл на сервере:**
```bash
# Database
POSTGRES_USER=app_user
POSTGRES_PASSWORD=<STRONG_PASSWORD_HERE>
POSTGRES_DB=app_database

# JWT
JWT_SECRET=<RANDOM_SECRET_KEY>

# S3/Storage (если используется)
S3_ENDPOINT=https://s3.storage.selectel.ru
S3_ACCESS_KEY=<ACCESS_KEY>
S3_SECRET_KEY=<SECRET_KEY>
S3_BUCKET_NAME=app-storage

# Redis
REDIS_URL=redis://redis:6379

# Email (если используется)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@yourdomain.com
SMTP_PASSWORD=<EMAIL_PASSWORD>

# App
NODE_ENV=production
API_URL=https://yourdomain.com/api
```

**⚠️ ВАЖНО:**
- НЕ коммитить `.env` в Git
- Использовать `.env.example` для документации
- Генерировать сильные пароли (минимум 32 символа)
- Регулярно ротировать секреты

---

## 🗂️ Структура Проекта на Сервере

```
/opt/app/
├── docker-compose.yml
├── .env
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       ├── api.conf
│       └── website.conf
├── backend/
│   ├── Dockerfile
│   ├── pubspec.yaml
│   └── lib/
├── website/
│   ├── Dockerfile
│   ├── package.json
│   └── public/
├── database/
│   └── init/
│       └── 01-init.sql
├── backups/
├── scripts/
│   ├── backup.sh
│   └── restore.sh
└── logs/
```

---

## 📋 Чек-лист Первоначальной Настройки

### Шаг 1: Аренда Сервера
- [ ] Арендовать VPS на Selectel
- [ ] Выбрать Ubuntu 22.04 LTS
- [ ] Получить статический IP адрес
- [ ] Сохранить root пароль

### Шаг 2: Безопасность
- [ ] Создать нового пользователя (не root)
- [ ] Сгенерировать SSH-ключи
- [ ] Настроить SSH (отключить пароли, сменить порт)
- [ ] Настроить UFW firewall
- [ ] Установить fail2ban
- [ ] Обновить систему: `sudo apt update && sudo apt upgrade -y`

### Шаг 3: Docker
- [ ] Установить Docker Engine
- [ ] Установить Docker Compose
- [ ] Добавить пользователя в группу docker
- [ ] Проверить установку: `docker --version`

### Шаг 4: Приложение
- [ ] Создать директорию `/opt/app`
- [ ] Загрузить файлы проекта
- [ ] Настроить `.env` файл
- [ ] Создать `docker-compose.yml`

### Шаг 5: Nginx и SSL
- [ ] Настроить nginx конфигурацию
- [ ] Указать A-запись домена на IP сервера
- [ ] Получить SSL сертификат через Certbot
- [ ] Настроить автообновление сертификата

### Шаг 6: База данных
- [ ] Создать init скрипты для PostgreSQL
- [ ] Настроить volume для persistence
- [ ] Создать первый бэкап

### Шаг 7: Деплой
- [ ] Создать скрипты деплоя
- [ ] Протестировать деплой
- [ ] Настроить автоматические бэкапы (cron)

### Шаг 8: Мониторинг
- [ ] Установить Portainer (опционально)
- [ ] Настроить health checks
- [ ] Настроить логирование
- [ ] Установить Uptime monitoring

---

## 🚨 Troubleshooting

### Проблема: Контейнер не запускается
```bash
# Проверить логи
docker compose logs -f <service_name>

# Проверить статус
docker compose ps

# Пересоздать контейнер
docker compose up -d --force-recreate <service_name>
```

### Проблема: SSL сертификат не обновляется
```bash
# Проверить certbot
docker compose logs -f certbot

# Вручную обновить
docker compose run --rm certbot renew

# Перезапустить nginx
docker compose restart nginx
```

### Проблема: База данных не доступна
```bash
# Проверить статус PostgreSQL
docker compose exec postgres pg_isready -U app_user

# Проверить логи
docker compose logs -f postgres

# Войти в базу
docker compose exec postgres psql -U app_user -d app_database
```

### Проблема: Нехватает места на диске
```bash
# Проверить использование
df -h

# Очистить неиспользуемые Docker образы
docker system prune -a

# Очистить логи
docker compose logs --tail=0 -f backend > /dev/null
```

---

## 📊 Регулярное Обслуживание

### Ежедневно
- Проверка логов на ошибки
- Мониторинг использования ресурсов

### Еженедельно
- Бэкап базы данных
- Проверка обновлений безопасности

### Ежемесячно
- Обновление системы: `sudo apt update && sudo apt upgrade -y`
- Обновление Docker образов
- Ротация старых бэкапов
- Проверка SSL сертификатов

### Ежеквартально
- Аудит безопасности
- Оптимизация производительности
- Тестирование процедуры восстановления

---

## 📚 Полезные Команды

### Docker
```bash
# Просмотр логов
docker compose logs -f

# Перезапуск всех сервисов
docker compose restart

# Пересборка образов
docker compose build --no-cache

# Остановка всех сервисов
docker compose down

# Удаление всех данных (ОПАСНО!)
docker compose down -v
```

### PostgreSQL
```bash
# Бэкап
docker compose exec postgres pg_dump -U user dbname > backup.sql

# Восстановление
docker compose exec -T postgres psql -U user dbname < backup.sql

# Войти в psql
docker compose exec postgres psql -U user -d dbname
```

### Nginx
```bash
# Проверить конфигурацию
docker compose exec nginx nginx -t

# Перезагрузить конфигурацию
docker compose exec nginx nginx -s reload
```

### Системные
```bash
# Использование диска
df -h
du -sh /opt/app/*

# Использование RAM
free -h

# Процессы
top
htop

# Сетевые соединения
netstat -tulpn
```

---

## � Selectel S3 Storage

### 11. Настройка объектного хранилища (замена Firebase Storage)

**Firebase Storage → Selectel S3**

Selectel предоставляет S3-совместимое хранилище для файлов (аватары, документы, изображения).

#### Создание S3 bucket на Selectel:

1. Войти в панель Selectel
2. Перейти в раздел "Облачное хранилище" (S3)
3. Создать новый контейнер `titotr-storage`
4. Получить API ключи (Access Key + Secret Key)

**Endpoint:** `https://s3.storage.selcloud.ru`

#### Интеграция в Dart Frog:

```dart
// lib/services/storage_service.dart

import 'package:minio/minio.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final Minio _client;
  final String _bucketName;

  StorageService({
    required String endpoint,
    required String accessKey,
    required String secretKey,
    required String bucketName,
  })  : _bucketName = bucketName,
        _client = Minio(
          endPoint: endpoint.replaceAll('https://', ''),
          accessKey: accessKey,
          secretKey: secretKey,
          useSSL: true,
          region: 'ru-1',
        );

  // Загрузить файл
  Future<String> uploadFile({
    required List<int> fileBytes,
    required String fileName,
    String? contentType,
    String folder = 'uploads',
  }) async {
    // Генерировать уникальное имя файла
    final uuid = Uuid().v4();
    final extension = fileName.split('.').last;
    final uniqueFileName = '$uuid.$extension';
    final objectName = '$folder/$uniqueFileName';

    // Загрузить в S3
    await _client.putObject(
      _bucketName,
      objectName,
      Stream.value(fileBytes),
      fileBytes.length,
      contentType: contentType,
    );

    // Вернуть публичный URL
    return 'https://s3.storage.selcloud.ru/$_bucketName/$objectName';
  }

  // Получить файл
  Future<List<int>> getFile(String objectName) async {
    final stream = await _client.getObject(_bucketName, objectName);
    return await stream.expand((chunk) => chunk).toList();
  }

  // Удалить файл
  Future<void> deleteFile(String objectName) async {
    await _client.removeObject(_bucketName, objectName);
  }

  // Получить presigned URL (временная ссылка)
  Future<String> getPresignedUrl(
    String objectName, {
    Duration expiry = const Duration(hours: 1),
  }) async {
    return await _client.presignedGetObject(
      _bucketName,
      objectName,
      expires: expiry.inSeconds,
    );
  }
}
```

#### Пример использования в route:

```dart
// routes/users/avatar.dart

import 'dart:io';
import 'package:dart_frog/dart_frog.dart';

// POST /api/users/avatar - загрузить аватар
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final user = context.read<User>();
  final storageService = context.read<StorageService>();

  // Получить файл из multipart form data
  final formData = await context.request.formData();
  final file = formData.files['avatar'];

  if (file == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'No file provided'},
    );
  }

  // Проверить размер (макс 5MB)
  if (file.bytes.length > 5 * 1024 * 1024) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'File too large (max 5MB)'},
    );
  }

  // Загрузить в S3
  final avatarUrl = await storageService.uploadFile(
    fileBytes: file.bytes,
    fileName: file.name,
    contentType: file.contentType.toString(),
    folder: 'avatars',
  );

  // Обновить пользователя в БД
  final db = context.read<DatabaseService>();
  await db.execute(
    'UPDATE users SET avatar_url = @url WHERE id = @id',
    parameters: {'url': avatarUrl, 'id': user.id},
  );

  return Response.json(
    body: {'avatar_url': avatarUrl},
  );
}
```

---

<!--
## Selectel S3 Storage - НЕ ТРЕБУЕТСЯ

ВАЖНО: Данная секция закомментирована, так как проект Time to Travel 
работает ТОЛЬКО с текстовыми данными (заявки на поездки, информация о пользователях, маршруты).
Файловое хранилище S3 не требуется. Все данные хранятся в PostgreSQL.

Если в будущем потребуется загрузка файлов (фото водителей, документы и т.д.),
эту секцию можно раскомментировать и настроить Selectel S3.
-->

---

## 🔄 Миграция Данных из Firebase

### 11. План миграции существующих данных

**Примечание:** Проект работает только с текстовыми данными. Файловое хранилище не используется.

#### Экспорт данных из Firebase:

```bash
# Установить Firebase CLI
npm install -g firebase-tools

# Войти
firebase login

# Экспорт Firestore данных
firebase firestore:export gs://your-project.appspot.com/firestore-export

# Скачать экспорт локально
gsutil -m cp -r gs://your-project.appspot.com/firestore-export ./firebase-export
```

#### Скрипт миграции Firestore → PostgreSQL:

```dart
// tools/migrate_firebase.dart

import 'dart:io';
import 'dart:convert';
import 'package:postgres/postgres.dart';

void main() async {
  // Подключение к PostgreSQL
  final connection = await Connection.open(
    Endpoint(
      host: 'localhost',
      database: 'titotr_production',
      username: 'titotr_user',
      password: 'password',
    ),
  );

  // Читать экспорт Firestore
  final usersFile = File('./firebase-export/users.json');
  final usersJson = jsonDecode(await usersFile.readAsString());

  // Мигрировать пользователей
  for (final userData in usersJson) {
    await connection.execute(
      '''
      INSERT INTO users (id, email, name, phone, created_at)
      VALUES (@id, @email, @name, @phone, @created_at)
      ON CONFLICT (id) DO NOTHING
      ''',
      parameters: {
        'id': userData['uid'],
        'email': userData['email'],
        'name': userData['displayName'] ?? '',
        'phone': userData['phoneNumber'],
        'created_at': DateTime.parse(userData['metadata']['creationTime']),
      },
    );
  }

  print('✅ Миграция завершена!');
  await connection.close();
}
```

**Запуск миграции:**
```bash
dart run tools/migrate_firebase.dart
```

---

## 📦 Автоматизация Деплоя

### 13. Скрипты деплоя для Time to Travel

**Структура:**
```
scripts/
├── deploy.sh              # Полный деплой
├── deploy_backend.sh      # Только backend
├── backup_db.sh           # Бэкап БД
├── restore_db.sh          # Восстановление
├── setup_server.sh        # Первоначальная настройка
└── ssl_renew.sh           # Обновление SSL
```

**scripts/deploy.sh:**

```bash
#!/bin/bash

set -e  # Выход при ошибке

# Конфигурация
SERVER_HOST="titotr.ru"
SERVER_PORT="2222"
SERVER_USER="deploy"
DEPLOY_PATH="/opt/titotr"
BACKUP_PATH="./backups"

echo "🚀 Деплой Time to Travel на production..."

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Проверка SSH
echo -e "${YELLOW}➡️ Проверка SSH соединения...${NC}"
if ! ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST "echo 'SSH OK'"; then
    echo -e "${RED}❌ Не удалось подключиться к серверу${NC}"
    exit 1
fi
echo -e "${GREEN}✅ SSH соединение успешно${NC}"

# Создать бэкап перед деплоем
echo -e "${YELLOW}➡️ Создание бэкапа базы данных...${NC}"
./scripts/backup_db.sh

# Синхронизация файлов
echo -e "${YELLOW}➡️ Синхронизация файлов на сервер...${NC}"
rsync -avz --delete \
  --exclude '.git' \
  --exclude 'node_modules' \
  --exclude '.dart_tool' \
  --exclude 'build' \
  --exclude '.env.local' \
  --exclude 'backups' \
  --exclude '*.md' \
  -e "ssh -p $SERVER_PORT" \
  ./backend \
  ./database \
  ./nginx \
  ./docker-compose.yml \
  $SERVER_USER@$SERVER_HOST:$DEPLOY_PATH/

# Копировать .env
echo -e "${YELLOW}➡️ Копирование .env файла...${NC}"
scp -P $SERVER_PORT .env.production $SERVER_USER@$SERVER_HOST:$DEPLOY_PATH/.env

# Деплой на сервере
echo -e "${YELLOW}➡️ Запуск деплоя на сервере...${NC}"
ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST << 'ENDSSH'
cd /opt/titotr

# Загрузить переменные окружения
export $(cat .env | xargs)

echo "📦 Остановка контейнеров..."
docker compose down

echo "🔨 Пересборка образов..."
docker compose build --no-cache backend

echo "🚀 Запуск контейнеров..."
docker compose up -d

echo "⏳ Ожидание запуска сервисов (30 сек)..."
sleep 30

echo "📊 Статус контейнеров:"
docker compose ps

echo "🏥 Health check..."
if curl -f https://titotr.ru/api/health; then
    echo "✅ Backend работает!"
else
    echo "⚠️ Backend не отвечает!"
    docker compose logs backend
    exit 1
fi

echo "🧹 Очистка старых образов..."
docker image prune -f

ENDSSH

echo -e "${GREEN}✅ Деплой успешно завершен!${NC}"
echo -e "${GREEN}🌐 Проверьте: https://titotr.ru/api/health${NC}"
```

**scripts/backup_db.sh:**

```bash
#!/bin/bash

set -e

SERVER_HOST="titotr.ru"
SERVER_PORT="2222"
SERVER_USER="deploy"
BACKUP_DIR="./backups/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="titotr_backup_${TIMESTAMP}.sql"

mkdir -p $BACKUP_DIR

echo "📦 Создание бэкапа базы данных..."

ssh -p $SERVER_PORT $SERVER_USER@$SERVER_HOST \
  "cd /opt/titotr && docker compose exec -T postgres pg_dump -U titotr_user titotr_production" \
  > $BACKUP_DIR/$BACKUP_FILE

# Сжать бэкап
gzip $BACKUP_DIR/$BACKUP_FILE

echo "✅ Бэкап создан: $BACKUP_DIR/$BACKUP_FILE.gz"

# Удалить бэкапы старше 30 дней
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete

# Показать размер
du -h $BACKUP_DIR/$BACKUP_FILE.gz
```

**scripts/setup_server.sh** (первоначальная настройка сервера):

```bash
#!/bin/bash

set -e

SERVER_IP=$1

if [ -z "$SERVER_IP" ]; then
    echo "Usage: ./scripts/setup_server.sh <SERVER_IP>"
    exit 1
fi

echo "🔧 Настройка сервера Time to Travel на $SERVER_IP..."

# 1. Создать пользователя deploy
ssh root@$SERVER_IP << 'ENDSSH'
# Обновить систему
apt update && apt upgrade -y

# Создать пользователя deploy
useradd -m -s /bin/bash -G sudo deploy

# Настроить SSH для deploy
mkdir -p /home/deploy/.ssh
chmod 700 /home/deploy/.ssh
chown deploy:deploy /home/deploy/.ssh

# Установить базовые утилиты
apt install -y curl wget git htop nano ufw fail2ban

echo "✅ Базовая настройка выполнена"
ENDSSH

# 2. Копировать SSH ключ
echo "📋 Копирование SSH ключа..."
ssh-copy-id -i ~/.ssh/id_ed25519_titotr.pub deploy@$SERVER_IP

# 3. Настроить UFW firewall
ssh deploy@$SERVER_IP << 'ENDSSH'
# Разрешить SSH (временно стандартный порт)
sudo ufw allow 22/tcp
sudo ufw allow 2222/tcp  # Новый порт SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS

# Включить firewall
sudo ufw --force enable

echo "✅ Firewall настроен"
ENDSSH

# 4. Установить Docker
ssh deploy@$SERVER_IP << 'ENDSSH'
# Установить Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Добавить пользователя в группу docker
sudo usermod -aG docker deploy

# Установить Docker Compose
sudo apt install -y docker-compose-plugin

echo "✅ Docker установлен"
ENDSSH

# 5. Создать структуру директорий
ssh deploy@$SERVER_IP << 'ENDSSH'
mkdir -p /opt/titotr/{backend,database/init,nginx/conf.d,backups}
echo "✅ Директории созданы"
ENDSSH

echo "✅ Сервер настроен!"
echo "Следующие шаги:"
echo "1. Изменить SSH порт на 2222"
echo "2. Настроить DNS для titotr.ru"
echo "3. Запустить первый деплой: ./scripts/deploy.sh"
```

**Сделать скрипты исполняемыми:**
```bash
chmod +x scripts/*.sh
```

---

## 🔥 Обновленный Firewall и Безопасность

### 14. UFW для Time to Travel

```bash
# На сервере
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH (кастомный порт)
sudo ufw allow 2222/tcp comment 'SSH'

# HTTP/HTTPS
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Portainer (опционально, только с вашего IP)
sudo ufw allow from <YOUR_IP> to any port 9443 comment 'Portainer'

# Включить
sudo ufw enable

# Статус
sudo ufw status verbose
```

**Fail2ban конфигурация:**

```bash
# /etc/fail2ban/jail.local
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = admin@titotr.ru
sendername = Fail2Ban

[sshd]
enabled = true
port = 2222
logpath = /var/log/auth.log

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
```

```bash
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban
```

---

## 📊 Мониторинг и Логирование

### 15. Система мониторинга

#### Health Checks:

**routes/health.dart:**

```dart
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  try {
    // Проверить подключение к БД
    final db = context.read<DatabaseService>();
    await db.execute('SELECT 1');

    // Проверить Redis
    final redis = context.read<RedisService>();
    await redis.ping();

    return Response.json(
      body: {
        'status': 'ok',
        'service': 'Time to Travel API',
        'version': '1.0.0',
        'timestamp': DateTime.now().toIso8601String(),
        'checks': {
          'database': 'healthy',
          'redis': 'healthy',
        },
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: 503,
      body: {
        'status': 'error',
        'error': e.toString(),
      },
    );
  }
}
```

#### Логирование:

```bash
# Просмотр логов
docker compose logs -f backend
docker compose logs -f nginx
docker compose logs -f postgres

# Логи за последний час
docker compose logs --since 1h backend

# Только ошибки
docker compose logs backend | grep ERROR
```

---

## 📋 Чек-лист Миграции Firebase → Dart Frog

### Пошаговый план:

#### Фаза 1: Подготовка (1-2 дня)
- [ ] Арендовать VPS на Selectel
- [ ] Купить домен titotr.ru (✅ СДЕЛАНО)
- [ ] Настроить DNS записи на Selectel
- [ ] Настроить SSH доступ
- [ ] Установить Docker

#### Фаза 2: Backend Development (2-4 дня)
- [ ] Создать проект Dart Frog
- [ ] Спроектировать схему PostgreSQL
- [ ] Реализовать JWT аутентификацию
- [ ] Создать API endpoints (auth, users, bookings, routes)
- [ ] Написать unit тесты

#### Фаза 3: Инфраструктура (2-3 дня)
- [ ] Настроить PostgreSQL в Docker
- [ ] Настроить Redis
- [ ] Настроить Nginx
- [ ] Получить SSL сертификат для titotr.ru
- [ ] Создать docker-compose.yml
- [ ] Настроить автоматические бэкапы

#### Фаза 4: Миграция Данных (1-2 дня)
- [ ] Экспортировать данные из Firebase
- [ ] Написать скрипты миграции
- [ ] Протестировать миграцию на тестовых данных
- [ ] Выполнить полную миграцию

#### Фаза 5: Flutter App Integration (2-3 дня)
- [ ] Обновить API клиент в Flutter (заменить Firebase SDK на http/dio)
- [ ] Заменить Firebase Auth на JWT
- [ ] Обновить все модели данных
- [ ] Протестировать все функции
- [ ] Обработать edge cases

#### Фаза 6: Тестирование (2-3 дня)
- [ ] Unit тесты backend
- [ ] Integration тесты API
- [ ] E2E тесты Flutter app
- [ ] Нагрузочное тестирование
- [ ] Security аудит

#### Фаза 7: Деплой (1 день)
- [ ] Создать скрипты деплоя
- [ ] Выполнить первый деплой
- [ ] Настроить мониторинг
- [ ] Проверить все endpoints
- [ ] Настроить алерты

#### Фаза 8: Постмиграция (ongoing)
- [ ] Мониторинг ошибок
- [ ] Оптимизация производительности
- [ ] Отключить Firebase (постепенно)
- [ ] Документация API
- [ ] Обучение команды (если есть)

**Общее время: 10-16 дней** (упрощено за счёт отсутствия файлового хранилища)

---

## 💰 Обновленная Стоимость для Time to Travel

**Ежемесячные расходы:**

| Сервис | Стоимость | Примечание |
|--------|-----------|------------|
| Selectel VPS (4 vCPU, 8GB, 80GB SSD) | ~1200-1500 руб | Рекомендуемая конфигурация |
| Домен titotr.ru | ~40 руб/мес | ~500 руб/год |
| Бэкапы БД | ~200 руб | Автоматические (опционально) |
| **ИТОГО** | **~1450-1750 руб/мес** | **~17000-21000 руб/год** |

**Альтернатива - минимальная конфигурация:**

| Сервис | Стоимость | Примечание |
|--------|-----------|------------|
| Selectel VPS (2 vCPU, 4GB, 40GB SSD) | ~600-800 руб | Для старта достаточно |
| Домен titotr.ru | ~40 руб/мес | ~500 руб/год |
| **ИТОГО** | **~650-850 руб/мес** | **~8000-10000 руб/год** |

**Сравнение с Firebase (при росте):**

Firebase Blaze Plan для среднего приложения: $50-200/мес (~5000-20000 руб)  
**Экономия: 60-90% в долгосрочной перспективе**

**Дополнительные преимущества:**
- ✅ Нет зависимости от Firebase квот и лимитов
- ✅ Данные в России (соблюдение 152-ФЗ)
- ✅ Полный контроль над инфраструктурой
- ✅ Предсказуемая стоимость (нет внезапных скачков при росте)

---

## ✅ Критерии Готовности Production

Система готова к работе когда:

### Безопасность:
- ✅ SSH работает только по ключам на порту 2222
- ✅ UFW firewall активен
- ✅ Fail2ban настроен
- ✅ SSL сертификат установлен (A+ на SSLLabs)
- ✅ HTTPS редирект работает
- ✅ Security headers настроены

### Infrastructure:
- ✅ Docker контейнеры запущены и healthy
- ✅ PostgreSQL работает с persistence
- ✅ Redis работает
- ✅ Nginx reverse proxy работает
- ✅ Автоматические бэкапы настроены
- ✅ SSL автообновление настроено

### Backend:
- ✅ Dart Frog API отвечает на /api/health
- ✅ JWT аутентификация работает
- ✅ Все endpoints протестированы
- ✅ Rate limiting настроен
- ✅ CORS настроен
- ✅ Логирование работает

### Database:
- ✅ Схема создана
- ✅ Индексы настроены
- ✅ Данные мигрированы из Firebase
- ✅ Бэкапы создаются автоматически
- ✅ Restore процедура проверена

### Мониторинг:
- ✅ Health checks работают
- ✅ Логи доступны
- ✅ Алерты настроены
- ✅ Uptime monitoring активен

### Деплой:
- ✅ Скрипты деплоя работают
- ✅ Rollback процедура проверена
- ✅ Zero-downtime deployment (опционально)

---

## 📞 Поддержка и Документация

**Официальная документация:**
- Dart Frog: https://dart-frog.dev/
- PostgreSQL: https://www.postgresql.org/docs/
- Nginx: https://nginx.org/ru/docs/
- Docker: https://docs.docker.com/
- Selectel API: https://docs.selectel.ru/

**Сообщество:**
- Dart Frog Discord: https://discord.gg/very-good-ventures
- Flutter Russia: https://t.me/rudart
- Stack Overflow: https://stackoverflow.com/questions/tagged/dart-frog

**Поставщики:**
- Selectel поддержка: support@selectel.ru
- Панель Selectel: https://my.selectel.ru/

---

## 🎯 Итоговая Архитектура

```
┌─────────────────────────────────────────────────┐
│          Flutter Mobile App (Client)             │
│              iOS + Android                       │
└──────────────────┬──────────────────────────────┘
                   │ HTTPS
                   ▼
┌─────────────────────────────────────────────────┐
│              titotr.ru (Domain)                  │
│         DNS: Selectel (4 NS servers)             │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│         Nginx (Reverse Proxy + SSL)              │
│      Let's Encrypt SSL Certificate               │
│         Port 80 → 443 redirect                   │
└──────────────────┬──────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────┐
│          Dart Frog Backend API                   │
│       (Docker Container :8080)                   │
│                                                  │
│  ┌──────────────────────────────────────┐       │
│  │  Routes (Auto-routing)                │       │
│  │  ├─ /api/auth/*                       │       │
│  │  ├─ /api/users/*                      │       │
│  │  ├─ /api/bookings/*                   │       │
│  │  └─ /api/health                       │       │
│  └──────────────────────────────────────┘       │
│                                                  │
│  ┌──────────────────────────────────────┐       │
│  │  Services                             │       │
│  │  ├─ AuthService (JWT)                 │       │
│  │  ├─ DatabaseService (PostgreSQL)      │       │
│  │  └─ RedisService (Cache)              │       │
│  └──────────────────────────────────────┘       │
└──────────────────┬──────────────────────────────┘
                   │
       ┌───────────┴───────────┐
       ▼                       ▼
┌─────────────┐         ┌──────────┐
│ PostgreSQL  │         │  Redis   │
│  Database   │         │  Cache   │
│ (Container) │         │(Container)│
└─────────────┘         └──────────┘

Примечание: Хранилище файлов (S3) не требуется,
так как проект работает только с текстовыми данными.
```

---

**Версия документа:** 2.0  
**Последнее обновление:** 21 января 2026  
**Проект:** Time to Travel (titotr.ru)  
**Автор:** Senior Backend & Frontend Developer

**Статус:** ✅ Готово к реализации

---

## 🚀 Быстрый старт

```bash
# 1. Клонировать репозиторий
git clone <repo> time-to-travel
cd time-to-travel

# 2. Настроить сервер
./scripts/setup_server.sh <SERVER_IP>

# 3. Настроить DNS
# Добавить A-запись: titotr.ru → <SERVER_IP>

# 4. Создать .env.production
cp .env.example .env.production
nano .env.production  # Заполнить секреты

# 5. Первый деплой
./scripts/deploy.sh

# 6. Получить SSL
ssh titotr-production
cd /opt/titotr
docker compose run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  --email admin@titotr.ru \
  --agree-tos -d titotr.ru -d www.titotr.ru

# 7. Перезапустить nginx
docker compose restart nginx

# 8. Проверить
curl https://titotr.ru/api/health
```

**Готово! 🎉**
