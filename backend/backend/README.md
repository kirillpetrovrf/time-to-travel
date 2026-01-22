# Time to Travel Backend API

[![Powered by Dart Frog](https://img.shields.io/endpoint?url=https://tinyurl.com/dartfrog-badge)](https://dart-frog.dev)

Dart Frog REST API для приложения Time to Travel (такси).

## 🏗️ Архитектура

- **Framework**: Dart Frog 1.1+
- **Database**: PostgreSQL 16
- **Cache**: Redis 7
- **Proxy**: Nginx + Let's Encrypt SSL
- **Deploy**: Docker Compose на Selectel VPS
- **Domain**: titotr.ru

## 📋 Требования

- Dart SDK 3.8.0+
- Docker & Docker Compose
- PostgreSQL 16 (для локальной разработки)
- Redis 7 (для локальной разработки)

## 🚀 Быстрый старт

### Локальная разработка

1. **Установите зависимости**:
```bash
cd backend
dart pub get
```

2. **Сгенерируйте модели JSON**:
```bash
dart run build_runner build --delete-conflicting-outputs
```

3. **Настройте окружение**:
```bash
cp .env.example .env
# Отредактируйте .env с локальными настройками
```

4. **Запустите PostgreSQL и Redis**:
```bash
cd ..
docker-compose up -d postgres redis
```

5. **Запустите dev сервер**:
```bash
dart_frog dev
```

API будет доступен на `http://localhost:8080`

## 🔒 Безопасность

- JWT аутентификация (access + refresh tokens)
- Bcrypt хеширование паролей
- HTTPS через Let's Encrypt
- Rate limiting через Redis
- SQL injection защита (параметризованные запросы)
- CORS настройки

## 🧪 Тестирование

```bash
# Запуск тестов
dart test

# С покрытием
dart test --coverage=coverage
```

## 📄 Документация

См. [SERVER_SETUP_SPECIFICATION.md](../../SERVER_SETUP_SPECIFICATION.md) для полной документации.
