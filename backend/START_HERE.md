# ✅ Backend Готов К Деплою!

## 📁 Структура проекта

```
/Users/kirillpetrov/Projects/time-to-travel/backend/
├── backend/                    # ← Основной код Dart Frog
│   ├── routes/                # API endpoints (17 endpoints)
│   ├── lib/                   # Models, repositories, services
│   ├── test/                  # Unit tests (11/11 passed)
│   ├── pubspec.yaml          # Dart dependencies
│   └── Dockerfile            # Backend image
├── database/
│   └── init/
│       ├── 01-schema.sql     # PostgreSQL schema (6 tables)
│       └── 02-seed.sql       # Test data (3 users, 8 routes, 3 orders)
├── nginx/
│   └── conf.d/
│       └── titotr.conf       # Nginx SSL configuration
├── docker-compose.yml        # Full stack (Backend + PostgreSQL + Redis + Nginx)
├── deploy.sh                 # 🚀 Автоматический деплой на Selectel
├── setup-ssl.sh              # 🔒 SSL сертификат Let's Encrypt
├── .env.example              # Шаблон переменных окружения
├── DEPLOYMENT_CHECKLIST.md   # Чек-лист для деплоя
├── DEPLOYMENT_GUIDE.md       # Подробная инструкция деплоя
├── FLUTTER_INTEGRATION.md    # Интеграция с Flutter приложением
└── README.md                 # Главная документация
```

---

## 🎯 Что готово

### ✅ Backend API (17 endpoints)

**Authentication (6 endpoints):**
- POST /auth/register - Регистрация пользователя
- POST /auth/login - Авторизация
- POST /auth/refresh - Обновление токена
- POST /auth/logout - Выход с одного устройства
- POST /auth/logout-all - Выход со всех устройств
- GET /health - Health check

**Routes (1 endpoint):**
- GET /routes/search - Поиск маршрутов с динамическим ценообразованием

**Orders (5 endpoints):**
- GET /orders - Список заказов пользователя
- POST /orders - Создать заказ
- GET /orders/:id - Получить заказ по ID
- PUT /orders/:id - Обновить заказ
- DELETE /orders/:id - Отменить заказ
- PATCH /orders/:id/status - Изменить статус заказа (admin)

**Admin (4 endpoints):**
- POST /admin/routes - Создать маршрут
- PUT /admin/routes/:id - Обновить маршрут
- DELETE /admin/routes/:id - Удалить маршрут
- GET /admin/stats - Статистика по заказам

### ✅ База данных

**PostgreSQL Schema (6 таблиц):**
1. users - Пользователи (id, email, password_hash, name, phone, role, created_at, updated_at)
2. refresh_tokens - JWT refresh токены (id, user_id, token, expires_at, revoked_at, created_at)
3. route_groups - Группы маршрутов (id, name, description)
4. predefined_routes - Предопределённые маршруты (id, from_city, to_city, distance_km, duration_minutes, base_price, etc.)
5. orders - Заказы (id, user_id, route_id, status, passengers, baggage, total_price, pickup_time, etc.)
6. payments - Платежи (id, order_id, amount, status, payment_method, transaction_id, etc.)

**Test Data:**
- 3 пользователя (admin, client, driver)
- 8 маршрутов (Ростов → Волгодонск, Таганрог, Новочеркасск, etc.)
- 3 тестовых заказа

### ✅ Infrastructure

**Docker Compose:**
- Backend (Dart Frog на порту 8080)
- PostgreSQL 16 (порт 5432)
- Redis 7 (порт 6379)
- Nginx (порты 80, 443)

**Security:**
- JWT authentication (access + refresh tokens)
- Bcrypt password hashing (cost factor 12)
- SSL/TLS с Let's Encrypt
- Firewall (ufw)
- Fail2ban для brute-force protection

### ✅ Deployment Scripts

**deploy.sh:**
- Полностью автоматизированный деплой на Ubuntu 22.04
- Обновление системы
- Установка Docker
- Клонирование репозитория
- Создание .env файла
- Инициализация базы данных
- Настройка SSL сертификата
- Запуск сервисов
- Настройка firewall
- Health check verification

**setup-ssl.sh:**
- Установка Certbot
- Генерация SSL сертификатов для titotr.ru
- Обновление Nginx конфигурации
- Настройка автоматического обновления (cron)

### ✅ Documentation

- **README.md** - Главная документация с quick start
- **DEPLOYMENT_CHECKLIST.md** - Пошаговый чек-лист для деплоя
- **DEPLOYMENT_GUIDE.md** - Подробное руководство (500+ строк)
- **FLUTTER_INTEGRATION.md** - Полная инструкция по интеграции с Flutter
- **API_ENDPOINTS.md** - Документация всех 17 endpoints с примерами
- **API_QUICK_REFERENCE.md** - Быстрая справка по API

---

## 🚀 Что делать дальше?

### Вариант 1: Деплой на Selectel VPS (рекомендуется)

Для запуска backend на production сервере:

#### Шаг 1: Арендовать VPS
1. Зайти на [selectel.ru](https://selectel.ru)
2. Создать VPS:
   - **ОС**: Ubuntu 22.04 LTS
   - **CPU**: 2 ядра
   - **RAM**: 2 GB
   - **SSD**: 20 GB
   - **Стоимость**: ~600-800 руб/месяц
3. Записать публичный IP-адрес

#### Шаг 2: Настроить DNS
1. В панели Selectel DNS добавить A-записи:
   ```
   @ → IP_АДРЕС_VPS
   www → IP_АДРЕС_VPS
   ```
2. Дождаться распространения DNS (5-60 минут)
3. Проверить: `ping titotr.ru`

#### Шаг 3: Подготовить секреты
```bash
# Сгенерировать JWT secret
openssl rand -base64 32

# Сгенерировать PostgreSQL пароль
openssl rand -base64 24

# Сгенерировать Redis пароль
openssl rand -base64 24
```

Сохранить все секреты!

#### Шаг 4: Запустить деплой
```bash
# С вашего Mac
cd /Users/kirillpetrov/Projects/time-to-travel/backend

# Загрузить скрипты на сервер
scp deploy.sh setup-ssl.sh root@titotr.ru:/root/

# Подключиться к серверу
ssh root@titotr.ru

# На сервере отредактировать переменные в deploy.sh
nano deploy.sh
# Найти и заменить:
# - POSTGRES_PASSWORD="YOUR_STRONG_PASSWORD"
# - REDIS_PASSWORD="YOUR_REDIS_PASSWORD"
# - JWT_SECRET="YOUR_JWT_SECRET"
# - YANDEX_API_KEY="YOUR_YANDEX_API_KEY"

# Запустить деплой
chmod +x deploy.sh setup-ssl.sh
sudo bash deploy.sh
```

Скрипт автоматически:
- Обновит систему
- Установит Docker
- Клонирует репозиторий
- Создаст .env файл
- Инициализирует базу данных
- Установит SSL сертификат
- Запустит все сервисы
- Настроит firewall
- Проверит работоспособность

#### Шаг 5: Проверить деплой
```bash
# Health check
curl https://titotr.ru/health

# Ожидаемый ответ:
# {
#   "status": "healthy",
#   "service": "Time to Travel API",
#   "version": "1.0.0",
#   "timestamp": "2025-01-31T..."
# }
```

#### Шаг 6: Протестировать API
```bash
# Регистрация
curl -X POST https://titotr.ru/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "name": "Test User"
  }'

# Поиск маршрутов
curl "https://titotr.ru/routes/search?from_latitude=47.2357&from_longitude=39.7015&to_latitude=47.5090&to_longitude=42.1760"
```

**📖 Подробная инструкция**: `DEPLOYMENT_CHECKLIST.md`

---

### Вариант 2: Интеграция с Flutter приложением

После успешного деплоя backend можно подключить Flutter приложение:

#### Шаг 1: Установить пакеты
```yaml
# pubspec.yaml
dependencies:
  dio: ^5.4.0
  flutter_secure_storage: ^9.0.0
  provider: ^6.1.1
```

#### Шаг 2: Создать API клиент
```dart
// lib/api/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://titotr.ru';
}
```

#### Шаг 3: Реализовать сервисы
- AuthService (регистрация, логин, refresh, logout)
- RouteService (поиск маршрутов)
- OrderService (создание, редактирование заказов)

**📖 Полная инструкция**: `FLUTTER_INTEGRATION.md`

---

## 📚 Документация

### Для деплоя:
1. **[DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md)** - Пошаговый чек-лист
   - Подготовка VPS
   - Настройка DNS
   - Генерация секретов
   - Запуск деплоя
   - Проверка работоспособности

2. **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Подробное руководство
   - Требования к VPS
   - Автоматический деплой
   - Ручной деплой (13 шагов)
   - Troubleshooting
   - Maintenance
   - Security best practices

### Для интеграции:
3. **[FLUTTER_INTEGRATION.md](FLUTTER_INTEGRATION.md)** - Интеграция Flutter
   - Необходимые пакеты
   - Архитектура проекта
   - API Client с interceptors
   - Token storage (JWT)
   - Auth/Route/Order сервисы
   - Примеры UI screens
   - Error handling

### Для разработки:
4. **[README.md](README.md)** - Главная документация
   - Обзор проекта
   - Технологии
   - Быстрый старт
   - Локальная разработка
   - Структура проекта

5. **[API_ENDPOINTS.md](backend/API_ENDPOINTS.md)** - API документация
   - Все 17 endpoints
   - Примеры запросов/ответов
   - Коды ошибок
   - Authentication flow

6. **[API_QUICK_REFERENCE.md](backend/API_QUICK_REFERENCE.md)** - Быстрая справка
   - Таблица всех endpoints
   - Требования к авторизации
   - HTTP методы и пути

---

## 🔧 Локальная разработка

Если хотите протестировать backend локально перед деплоем:

```bash
cd /Users/kirillpetrov/Projects/time-to-travel/backend

# Запустить PostgreSQL и Redis
docker compose up -d postgres redis

# Создать базу данных
docker cp database/init/01-schema.sql postgres:/tmp/
docker cp database/init/02-seed.sql postgres:/tmp/
docker exec postgres psql -U postgres -c "CREATE DATABASE timetotravel;"
docker exec -i postgres psql -U postgres -d timetotravel < /tmp/01-schema.sql
docker exec -i postgres psql -U postgres -d timetotravel < /tmp/02-seed.sql

# Запустить backend
cd backend
dart pub get
dart_frog dev

# В другом терминале протестировать
curl http://localhost:8080/health
```

---

## ✅ Финальный чек-лист

Перед деплоем убедитесь:

- [ ] VPS на Selectel арендован (Ubuntu 22.04, 2GB RAM)
- [ ] Домен titotr.ru привязан к IP сервера
- [ ] DNS A-записи настроены (@ и www)
- [ ] Секреты сгенерированы (JWT_SECRET, POSTGRES_PASSWORD, REDIS_PASSWORD)
- [ ] Yandex Maps API ключ получен
- [ ] SSH доступ к серверу работает
- [ ] Скрипты deploy.sh и setup-ssl.sh загружены на сервер
- [ ] Переменные в deploy.sh заполнены
- [ ] Email для SSL сертификата подготовлен

После деплоя проверьте:

- [ ] Health check возвращает 200 OK
- [ ] Регистрация работает
- [ ] Авторизация работает
- [ ] Поиск маршрутов работает
- [ ] Создание заказов работает
- [ ] SSL сертификат установлен (https работает)
- [ ] Firewall настроен
- [ ] Логи без критических ошибок

---

## 🎯 Следующие шаги

### Сразу после деплоя:
1. ✅ Протестировать все endpoints через curl
2. ✅ Создать первого реального пользователя
3. ✅ Настроить backup базы данных (cron job)
4. ✅ Добавить мониторинг (опционально: UptimeRobot)

### Интеграция Flutter:
1. ✅ Обновить base URL на https://titotr.ru
2. ✅ Создать API сервисы (Auth, Route, Order)
3. ✅ Реализовать JWT token storage
4. ✅ Обновить UI для работы с API
5. ✅ Удалить SQLite код
6. ✅ Протестировать все user flows

### Дополнительные фичи:
1. 📧 Email верификация
2. 🔐 Восстановление пароля
3. 📲 Push уведомления (Firebase)
4. 💳 Платёжная интеграция
5. 📊 Admin dashboard
6. 🗺️ Real-time tracking водителя

---

## 📞 Контакты

Если возникнут вопросы:
- 📧 Email: support@titotr.ru
- 📱 Telegram: @titotr_support
- 📖 Документация: [README.md](README.md)

---

## 🎉 Готов к деплою!

Весь backend готов к продакшну. Выберите один из вариантов:

**Вариант 1 (Рекомендуется):**
Сначала задеплоить backend → потом интегрировать Flutter

**Вариант 2:**
Сразу начать Flutter интеграцию → потом деплой

Удачи! 🚀

---

**Version**: 1.0.0  
**Last Updated**: 2025-01-31  
**Status**: ✅ Ready for Production
