# 🚖 Time to Travel - Backend API

REST API для приложения такси **Time to Travel** на базе Dart Frog, PostgreSQL и Redis.

## 📋 Содержание

- [Обзор](#обзор)
- [Технологии](#технологии)
- [Быстрый старт](#быстрый-старт)
- [Деплой на продакшн](#деплой-на-продакшн)
- [API Документация](#api-документация)
- [Интеграция с Flutter](#интеграция-с-flutter)
- [Разработка](#разработка)

---

## 🎯 Обзор

**Time to Travel Backend** - это полнофункциональный REST API для мобильного приложения такси с межгородскими маршрутами.

### Основные возможности:

✅ **Аутентификация**:
- Регистрация и авторизация пользователей
- JWT токены (access + refresh)
- Безопасное хранение паролей (bcrypt)
- Автоматическое обновление токенов
- Logout с одного/всех устройств

✅ **Маршруты**:
- Поиск предопределённых маршрутов
- Расчёт расстояния и времени
- Динамическое ценообразование
- Поддержка багажа (S/M/L)

✅ **Заказы**:
- Создание заказов с выбором маршрута
- Редактирование и отмена заказов
- История заказов пользователя
- Статусы: pending, confirmed, in_progress, completed, cancelled

✅ **Администрирование**:
- Управление маршрутами (CRUD)
- Статистика по заказам
- Контроль доступа по ролям

---

## 🛠️ Технологии

| Компонент | Технология | Версия |
|-----------|------------|--------|
| **Backend Framework** | Dart Frog | 2.0+ |
| **Language** | Dart | 3.9+ |
| **Database** | PostgreSQL | 16 |
| **Cache** | Redis | 7 |
| **Web Server** | Nginx | Latest |
| **SSL** | Let's Encrypt | - |
| **Containerization** | Docker Compose | - |
| **Authentication** | JWT | - |

### Dart пакеты:
- `postgres` 3.0.1 - PostgreSQL клиент
- `dart_jsonwebtoken` 2.17.0 - JWT токены
- `bcrypt` 1.1.3 - Хеширование паролей
- `redis` 4.0.0 - Redis клиент
- `uuid` 4.5.1 - Генерация UUID
- `json_annotation` 4.9.0 - JSON сериализация

---

## 🚀 Быстрый старт

### Локальная разработка (macOS)

#### 1. Установить зависимости:
```bash
# Установить Dart SDK (если нет)
brew tap dart-lang/dart
brew install dart

# Установить Dart Frog CLI
dart pub global activate dart_frog_cli

# Установить Docker Desktop
# Скачать с https://www.docker.com/products/docker-desktop
```

#### 2. Клонировать репозиторий:
```bash
git clone https://github.com/your-username/time-to-travel.git
cd time-to-travel/backend
```

#### 3. Установить зависимости проекта:
```bash
dart pub get
```

#### 4. Запустить инфраструктуру (PostgreSQL + Redis):
```bash
docker compose up -d postgres redis
```

#### 5. Создать базу данных:
```bash
# Скопировать SQL скрипты в контейнер
docker cp database/init/01-schema.sql postgres:/tmp/
docker cp database/init/02-seed.sql postgres:/tmp/

# Выполнить миграции
docker exec -i postgres psql -U postgres -c "CREATE DATABASE timetotravel;"
docker exec -i postgres psql -U postgres -d timetotravel < /tmp/01-schema.sql
docker exec -i postgres psql -U postgres -d timetotravel < /tmp/02-seed.sql
```

#### 6. Создать `.env` файл:
```bash
cp .env.example .env
# Отредактировать .env и заполнить переменные
```

#### 7. Запустить backend:
```bash
dart_frog dev
```

Backend запустится на `http://localhost:8080`

#### 8. Проверить работу:
```bash
curl http://localhost:8080/health
```

Ожидаемый ответ:
```json
{
  "status": "healthy",
  "service": "Time to Travel API",
  "version": "1.0.0",
  "timestamp": "2025-01-..."
}
```

---

## 🌐 Деплой на продакшн

### Вариант 1: Автоматический деплой на Selectel VPS

**Полная инструкция**: [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)

#### Краткая инструкция:

1. **Арендовать VPS на Selectel**:
   - Ubuntu 22.04 LTS
   - 2 CPU, 2 GB RAM, 20 GB SSD
   - Домен: titotr.ru

2. **Загрузить скрипт деплоя**:
```bash
scp deploy.sh setup-ssl.sh root@titotr.ru:/root/
```

3. **Запустить деплой**:
```bash
ssh root@titotr.ru
chmod +x deploy.sh
sudo bash deploy.sh
```

4. **Проверить**:
```bash
curl https://titotr.ru/health
```

### Вариант 2: Ручной деплой

См. подробную инструкцию в [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 📚 API Документация

### Базовый URL

- **Production**: `https://titotr.ru`
- **Development**: `http://localhost:8080`

### Endpoints

| Метод | Path | Auth | Описание |
|-------|------|------|----------|
| **Health** |
| GET | `/health` | ❌ | Health check |
| **Authentication** |
| POST | `/auth/register` | ❌ | Регистрация |
| POST | `/auth/login` | ❌ | Авторизация |
| POST | `/auth/refresh` | ❌ | Обновить токен |
| POST | `/auth/logout` | ❌ | Выход (1 устройство) |
| POST | `/auth/logout-all` | ✅ | Выход (все устройства) |
| **Routes** |
| GET | `/routes/search` | ❌ | Поиск маршрутов |
| **Orders** |
| GET | `/orders` | ✅ | Список заказов |
| POST | `/orders` | ✅ | Создать заказ |
| GET | `/orders/:id` | ✅ | Получить заказ |
| PUT | `/orders/:id` | ✅ | Обновить заказ |
| DELETE | `/orders/:id` | ✅ | Отменить заказ |
| PATCH | `/orders/:id/status` | ✅ | Изменить статус |
| **Admin** |
| POST | `/admin/routes` | ✅ | Создать маршрут |
| PUT | `/admin/routes/:id` | ✅ | Обновить маршрут |
| DELETE | `/admin/routes/:id` | ✅ | Удалить маршрут |
| GET | `/admin/stats` | ✅ | Статистика |

### Примеры запросов

#### Регистрация
```bash
curl -X POST https://titotr.ru/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!",
    "name": "Иван Иванов",
    "phone": "+79001234567"
  }'
```

**Ответ**:
```json
{
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "name": "Иван Иванов",
    "role": "client",
    "created_at": "2025-01-31T12:00:00Z"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### Поиск маршрутов
```bash
curl "https://titotr.ru/routes/search?from_latitude=47.2357&from_longitude=39.7015&to_latitude=47.5090&to_longitude=42.1760&passengers=2"
```

**Ответ**:
```json
{
  "routes": [
    {
      "id": "uuid-here",
      "from_city": "Ростов-на-Дону",
      "to_city": "Волгодонск",
      "distance_km": 210,
      "duration_minutes": 180,
      "base_price": 2500,
      "price_per_passenger": 500,
      "available": true
    }
  ]
}
```

#### Создание заказа
```bash
curl -X POST https://titotr.ru/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "route_id": "route-uuid-here",
    "passengers": 2,
    "baggage_s": 1,
    "baggage_m": 0,
    "baggage_l": 0,
    "pickup_time": "2025-02-01T10:00:00Z",
    "notes": "Встреча у вокзала"
  }'
```

**Полная документация**: [API_ENDPOINTS.md](API_ENDPOINTS.md)

---

## 📱 Интеграция с Flutter

### Быстрая интеграция

1. **Установить пакеты**:
```yaml
dependencies:
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  provider: ^6.1.1
```

2. **Создать API клиент**:
```dart
import 'package:dio/dio.dart';

class ApiClient {
  static const baseUrl = 'https://titotr.ru';
  late final Dio _dio;
  
  ApiClient() {
    _dio = Dio(BaseOptions(baseUrl: baseUrl));
  }
}
```

3. **Использовать в приложении**:
```dart
final response = await ApiClient().dio.post('/auth/login', data: {
  'email': email,
  'password': password,
});
```

**Полная инструкция**: [FLUTTER_INTEGRATION.md](FLUTTER_INTEGRATION.md)

---

## 🔧 Разработка

### Структура проекта

```
backend/
├── routes/                  # API endpoints
│   ├── auth/               # Аутентификация
│   │   ├── register.dart
│   │   ├── login.dart
│   │   ├── refresh.dart
│   │   ├── logout.dart
│   │   └── logout-all.dart
│   ├── routes/             # Маршруты
│   │   └── search.dart
│   ├── orders/             # Заказы
│   │   ├── index.dart
│   │   └── [id].dart
│   ├── admin/              # Админка
│   │   ├── routes.dart
│   │   └── stats.dart
│   └── health.dart         # Health check
├── lib/
│   ├── models/             # Data models
│   │   ├── user.dart
│   │   ├── route.dart
│   │   └── order.dart
│   ├── repositories/       # Database access
│   │   ├── user_repository.dart
│   │   ├── route_repository.dart
│   │   └── order_repository.dart
│   ├── services/           # Business logic
│   │   ├── database_service.dart
│   │   └── jwt_helper.dart
│   └── middleware/         # Request middleware
│       └── auth_middleware.dart
├── database/
│   └── init/
│       ├── 01-schema.sql   # Database schema
│       └── 02-seed.sql     # Test data
├── test/                   # Unit tests
├── docker-compose.yml      # Docker setup
├── Dockerfile              # Backend image
└── .env.example            # Environment template
```

### Запуск тестов

```bash
# Все тесты
dart test

# Конкретный тест
dart test test/models/user_test.dart

# С покрытием
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Линтинг и форматирование

```bash
# Анализ кода
dart analyze

# Форматирование
dart format .

# Исправить проблемы
dart fix --apply
```

### Database миграции

```bash
# Создать новую миграцию
# 1. Отредактировать database/init/01-schema.sql
# 2. Применить:
docker exec -i postgres psql -U postgres -d timetotravel < database/init/01-schema.sql
```

### Просмотр логов

```bash
# Backend
docker compose logs -f backend

# PostgreSQL
docker compose logs -f postgres

# Redis
docker compose logs -f redis

# Nginx
docker compose logs -f nginx
```

---

## 🔐 Безопасность

### Best Practices

✅ **Пароли**:
- Хешируются с bcrypt (cost factor 12)
- Минимум 8 символов
- Требуются: заглавные, строчные, цифры, спецсимволы

✅ **JWT Токены**:
- Access token: 1 час
- Refresh token: 7 дней
- Хранятся в базе данных
- Поддержка отзыва (revocation)

✅ **HTTPS**:
- Обязателен на продакшене
- Let's Encrypt SSL сертификаты
- Автоматическое обновление

✅ **CORS**:
- Настроен для titotr.ru
- Только разрешённые origins

✅ **Rate Limiting**:
- Nginx: 100 req/min
- fail2ban для защиты от brute-force

---

## 📊 Мониторинг

### Health Check

```bash
curl https://titotr.ru/health
```

### Database Status

```bash
docker exec postgres pg_isready -U postgres
```

### Использование ресурсов

```bash
docker stats
```

### Размер базы данных

```bash
docker exec postgres psql -U postgres -d timetotravel -c "
  SELECT pg_size_pretty(pg_database_size('timetotravel'));
"
```

---

## 🤝 Contributing

1. Fork репозитория
2. Создать feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменений (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Открыть Pull Request

---

## 📄 Лицензия

MIT License - см. [LICENSE](LICENSE)

---

## 📞 Поддержка

- **Email**: support@titotr.ru
- **Telegram**: @titotr_support
- **Issues**: [GitHub Issues](https://github.com/your-username/time-to-travel/issues)

---

## 📖 Дополнительная документация

- [📋 Deployment Checklist](DEPLOYMENT_CHECKLIST.md) - Чек-лист для деплоя
- [🚀 Deployment Guide](DEPLOYMENT_GUIDE.md) - Подробная инструкция деплоя
- [📱 Flutter Integration](FLUTTER_INTEGRATION.md) - Интеграция с Flutter
- [📚 API Endpoints](API_ENDPOINTS.md) - Полная документация API
- [⚡ Quick Reference](API_QUICK_REFERENCE.md) - Быстрая справка

---

**Made with ❤️ by Time to Travel Team**

**Version**: 1.0.0  
**Last Updated**: 2025-01-31
