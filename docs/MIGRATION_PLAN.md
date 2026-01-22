# 🚀 План Миграции Time to Travel: Firebase → Dart Frog

**Проект:** Time to Travel (titotr.ru)  
**Дата старта:** 21 января 2026  
**Общее время:** 10-16 дней  
**Статус:** 🟡 В процессе

---

## 📋 Оглавление

1. [Этап 0: Подготовка и Планирование](#этап-0-подготовка-и-планирование)
2. [Этап 1: Аренда и Настройка Сервера](#этап-1-аренда-и-настройка-сервера)
3. [Этап 2: DNS и Домен](#этап-2-dns-и-домен)
4. [Этап 3: SSH и Безопасность](#этап-3-ssh-и-безопасность)
5. [Этап 4: Docker Инфраструктура](#этап-4-docker-инфраструктура)
6. [Этап 5: PostgreSQL Схема](#этап-5-postgresql-схема)
7. [Этап 6: Dart Frog Backend](#этап-6-dart-frog-backend)
8. [Этап 7: JWT Authentication](#этап-7-jwt-authentication)
9. [Этап 8: API Endpoints](#этап-8-api-endpoints)
10. [Этап 9: Nginx и SSL](#этап-9-nginx-и-ssl)
11. [Этап 10: Миграция Данных](#этап-10-миграция-данных)
12. [Этап 11: Flutter Integration](#этап-11-flutter-integration)
13. [Этап 12: Тестирование](#этап-12-тестирование)
14. [Этап 13: Production Deploy](#этап-13-production-deploy)
15. [Этап 14: Мониторинг](#этап-14-мониторинг)
16. [Этап 15: Отключение Firebase](#этап-15-отключение-firebase)

---

## Этап 0: Подготовка и Планирование

**Время:** 1 день  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **0.1** Создать бэкап всех данных Firebase
  ```bash
  # Firebase Console -> Project Settings -> Service Accounts
  # Download private key для admin SDK
  ```

- [ ] **0.2** Экспортировать данные Firestore
  ```bash
  firebase firestore:export gs://time-to-travel.appspot.com/backup-$(date +%Y%m%d)
  ```

- [ ] **0.3** Сохранить список всех пользователей Firebase Auth
  ```bash
  # Через Firebase Console или Admin SDK
  # Экспортировать в CSV/JSON
  ```

- [ ] **0.4** Документировать текущие API endpoints Firebase
  - Список всех Cloud Functions
  - Структура данных Firestore
  - Firestore Security Rules

- [ ] **0.5** Подготовить локальное окружение
  ```bash
  # Установить необходимые инструменты
  brew install dart
  dart pub global activate dart_frog_cli
  brew install postgresql@15
  brew install redis
  ```

- [ ] **0.6** Создать репозиторий для backend
  ```bash
  cd /Users/kirillpetrov/Projects/time-to-travel
  mkdir backend
  cd backend
  dart_frog create .
  git init
  git add .
  git commit -m "Initial Dart Frog setup"
  ```

### Результат:
✅ Полный бэкап данных Firebase  
✅ Локальное окружение готово  
✅ Структура backend проекта создана

---

## Этап 1: Аренда и Настройка Сервера

**Время:** 0.5 дня  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **1.1** Арендовать VPS на Selectel
  - Войти в [my.selectel.ru](https://my.selectel.ru)
  - Выбрать "Облачная платформа" → "Серверы"
  - **Конфигурация для старта:**
    - CPU: 2 vCPU
    - RAM: 4 GB
    - Диск: 40 GB SSD
    - ОС: Ubuntu 22.04 LTS
    - Локация: Москва
  - Стоимость: ~600-800 руб/мес

- [ ] **1.2** Записать данные сервера
  ```
  IP адрес: _________________
  Root пароль: _____________
  ```

- [ ] **1.3** Первый вход на сервер
  ```bash
  ssh root@<IP_СЕРВЕРА>
  # Сменить root пароль
  passwd
  ```

- [ ] **1.4** Обновить систему
  ```bash
  apt update && apt upgrade -y
  ```

- [ ] **1.5** Установить базовые утилиты
  ```bash
  apt install -y \
    curl \
    wget \
    git \
    htop \
    nano \
    vim \
    net-tools \
    ufw \
    fail2ban \
    ca-certificates \
    gnupg \
    lsb-release
  ```

### Результат:
✅ VPS арендован  
✅ Сервер обновлен  
✅ Базовые утилиты установлены

---

## Этап 2: DNS и Домен

**Время:** 0.5 дня (+ время на распространение DNS)  
**Статус:** 🟢 Домен куплен (titotr.ru)

### Задачи:

- [ ] **2.1** Настроить DNS на Selectel
  - Войти в панель Selectel
  - Перейти в раздел "DNS"
  - Добавить домен titotr.ru

- [ ] **2.2** Добавить DNS записи
  ```
  Тип: A
  Имя: @
  Значение: <IP_ВАШЕГО_СЕРВЕРА>
  TTL: 3600

  Тип: A
  Имя: www
  Значение: <IP_ВАШЕГО_СЕРВЕРА>
  TTL: 3600

  Тип: CNAME
  Имя: api
  Значение: titotr.ru
  TTL: 3600
  ```

- [ ] **2.3** Проверить DNS (может занять до 48 часов)
  ```bash
  # Проверить A-запись
  dig titotr.ru A
  
  # Проверить с разных DNS
  dig @8.8.8.8 titotr.ru
  dig @1.1.1.1 titotr.ru
  
  # Проверить распространение
  # https://dnschecker.org/#A/titotr.ru
  ```

### Результат:
✅ DNS записи настроены  
✅ Домен доступен и резолвится на IP сервера

---

## Этап 3: SSH и Безопасность

**Время:** 1 день  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **3.1** Создать нового пользователя (не root)
  ```bash
  # На сервере
  adduser deploy
  usermod -aG sudo deploy
  ```

- [ ] **3.2** Сгенерировать SSH ключ на Mac
  ```bash
  # На локальной машине (Mac)
  ssh-keygen -t ed25519 -C "titotr-production" -f ~/.ssh/id_ed25519_titotr
  
  # Добавить в Keychain
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519_titotr
  ```

- [ ] **3.3** Скопировать публичный ключ на сервер
  ```bash
  # На локальной машине
  ssh-copy-id -i ~/.ssh/id_ed25519_titotr.pub deploy@<IP_СЕРВЕРА>
  ```

- [ ] **3.4** Настроить SSH config на Mac
  ```bash
  # Создать/отредактировать ~/.ssh/config
  nano ~/.ssh/config
  ```
  
  Добавить:
  ```
  Host titotr-production
      HostName <IP_СЕРВЕРА>
      Port 2222
      User deploy
      IdentityFile ~/.ssh/id_ed25519_titotr
      UseKeychain yes
      AddKeysToAgent yes
      ServerAliveInterval 60
  ```

- [ ] **3.5** Настроить SSH на сервере
  ```bash
  # На сервере под root
  nano /etc/ssh/sshd_config
  ```
  
  Изменить:
  ```
  Port 2222
  PermitRootLogin no
  PubkeyAuthentication yes
  PasswordAuthentication no
  ChallengeResponseAuthentication no
  UsePAM no
  X11Forwarding no
  AllowUsers deploy
  ```

- [ ] **3.6** Перезапустить SSH
  ```bash
  systemctl restart sshd
  ```

- [ ] **3.7** Проверить новое подключение (НЕ ЗАКРЫВАТЬ СТАРУЮ СЕССИЮ!)
  ```bash
  # В новом терминале
  ssh titotr-production
  ```

- [ ] **3.8** Настроить UFW Firewall
  ```bash
  # На сервере
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw allow 2222/tcp comment 'SSH'
  sudo ufw allow 80/tcp comment 'HTTP'
  sudo ufw allow 443/tcp comment 'HTTPS'
  sudo ufw enable
  sudo ufw status verbose
  ```

- [ ] **3.9** Настроить Fail2Ban
  ```bash
  sudo nano /etc/fail2ban/jail.local
  ```
  
  Добавить:
  ```ini
  [DEFAULT]
  bantime = 3600
  findtime = 600
  maxretry = 5

  [sshd]
  enabled = true
  port = 2222
  logpath = /var/log/auth.log
  ```
  
  ```bash
  sudo systemctl enable fail2ban
  sudo systemctl start fail2ban
  ```

### Результат:
✅ SSH работает только по ключам на порту 2222  
✅ Root доступ отключен  
✅ Firewall настроен  
✅ Fail2ban активен

---

## Этап 4: Docker Инфраструктура

**Время:** 0.5 дня  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **4.1** Установить Docker
  ```bash
  # На сервере
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  
  # Добавить пользователя в группу docker
  sudo usermod -aG docker deploy
  
  # Перелогиниться
  exit
  ssh titotr-production
  
  # Проверить
  docker --version
  docker compose version
  ```

- [ ] **4.2** Настроить автозапуск Docker
  ```bash
  sudo systemctl enable docker
  sudo systemctl start docker
  ```

- [ ] **4.3** Создать структуру директорий
  ```bash
  sudo mkdir -p /opt/titotr/{backend,database/init,nginx/conf.d,backups,logs}
  sudo chown -R deploy:deploy /opt/titotr
  cd /opt/titotr
  ```

- [ ] **4.4** Создать .env файл
  ```bash
  nano /opt/titotr/.env
  ```
  
  Содержимое:
  ```bash
  # Database
  POSTGRES_USER=titotr_user
  POSTGRES_PASSWORD=<СГЕНЕРИРОВАТЬ_ПАРОЛЬ_32_СИМВОЛА>
  POSTGRES_DB=titotr_production

  # Redis
  REDIS_PASSWORD=<СГЕНЕРИРОВАТЬ_ПАРОЛЬ_32_СИМВОЛА>

  # JWT
  JWT_SECRET=<СГЕНЕРИРОВАТЬ_СЕКРЕТ_64_СИМВОЛА>

  # App
  NODE_ENV=production
  API_URL=https://titotr.ru/api
  ```

- [ ] **4.5** Сгенерировать безопасные пароли
  ```bash
  # На Mac или сервере
  openssl rand -base64 32  # для POSTGRES_PASSWORD
  openssl rand -base64 32  # для REDIS_PASSWORD
  openssl rand -base64 64  # для JWT_SECRET
  ```

### Результат:
✅ Docker установлен  
✅ Структура директорий создана  
✅ Переменные окружения настроены

---

## Этап 5: PostgreSQL Схема

**Время:** 1 день  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **5.1** Создать файл инициализации БД
  ```bash
  nano /opt/titotr/database/init/01-schema.sql
  ```

- [ ] **5.2** Добавить схему базы данных
  ```sql
  -- Enable extensions
  CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
  CREATE EXTENSION IF NOT EXISTS "pg_trgm";

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

  -- Refresh tokens
  CREATE TABLE refresh_tokens (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      token_hash VARCHAR(255) NOT NULL,
      expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  );

  -- Routes
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

  -- Bookings
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
      status VARCHAR(50) DEFAULT 'pending',
      payment_status VARCHAR(50) DEFAULT 'pending',
      notes TEXT,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
      updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  );

  -- Payments
  CREATE TABLE payments (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
      amount DECIMAL(10, 2) NOT NULL,
      currency VARCHAR(3) DEFAULT 'RUB',
      payment_method VARCHAR(50),
      payment_provider VARCHAR(50),
      transaction_id VARCHAR(255),
      status VARCHAR(50) DEFAULT 'pending',
      paid_at TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
  );

  -- Indexes
  CREATE INDEX idx_users_email ON users(email);
  CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
  CREATE INDEX idx_bookings_user_id ON bookings(user_id);
  CREATE INDEX idx_bookings_status ON bookings(status);
  CREATE INDEX idx_bookings_pickup_time ON bookings(pickup_time);
  CREATE INDEX idx_payments_booking_id ON payments(booking_id);

  -- Trigger для updated_at
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

- [ ] **5.3** Создать тестовые данные (опционально)
  ```bash
  nano /opt/titotr/database/init/02-seed.sql
  ```

### Результат:
✅ SQL схема создана  
✅ Индексы настроены  
✅ Триггеры настроены

---

## Этап 6: Dart Frog Backend

**Время:** 2-3 дня  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **6.1** Создать Dart Frog проект локально
  ```bash
  cd /Users/kirillpetrov/Projects/time-to-travel
  mkdir backend
  cd backend
  dart_frog create .
  ```

- [ ] **6.2** Настроить pubspec.yaml
  ```yaml
  name: time_to_travel_backend
  description: Dart Frog backend for Time to Travel
  version: 1.0.0

  environment:
    sdk: '>=3.0.0 <4.0.0'

  dependencies:
    dart_frog: ^2.0.0
    postgres: ^3.0.0
    jwt_decoder: ^2.0.1
    dart_jsonwebtoken: ^2.12.0
    bcrypt: ^1.1.3
    uuid: ^4.0.0
    http: ^1.1.0
    redis: ^3.1.0
    dotenv: ^4.2.0

  dev_dependencies:
    build_runner: ^2.4.0
    dart_frog_cli: ^2.0.0
    mocktail: ^1.0.0
    test: ^1.24.0
    very_good_analysis: ^6.0.0
  ```

- [ ] **6.3** Установить зависимости
  ```bash
  dart pub get
  ```

- [ ] **6.4** Создать структуру директорий
  ```bash
  mkdir -p lib/{models,services,repositories,middlewares,utils}
  mkdir -p routes/{auth,users,bookings,routes}
  mkdir -p test/{routes,services}
  ```

- [ ] **6.5** Создать модели данных
  
  Файл: `lib/models/user.dart`
  Файл: `lib/models/booking.dart`
  Файл: `lib/models/route.dart`

- [ ] **6.6** Создать DatabaseService
  
  Файл: `lib/services/database_service.dart`

- [ ] **6.7** Создать Dockerfile
  ```bash
  nano Dockerfile
  ```

- [ ] **6.8** Протестировать локально
  ```bash
  dart_frog dev
  # Должен запуститься на http://localhost:8080
  ```

### Результат:
✅ Dart Frog проект создан  
✅ Зависимости установлены  
✅ Базовая структура готова  
✅ Локальный запуск работает

---

## Этап 7: JWT Authentication

**Время:** 1-2 дня  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **7.1** Создать AuthService
  
  Файл: `lib/services/auth_service.dart`
  - Метод register()
  - Метод login()
  - Метод refreshToken()
  - Метод validateToken()

- [ ] **7.2** Создать Auth Middleware
  
  Файл: `lib/middlewares/auth_middleware.dart`

- [ ] **7.3** Создать auth routes
  - `routes/auth/register.dart`
  - `routes/auth/login.dart`
  - `routes/auth/refresh.dart`
  - `routes/auth/logout.dart`

- [ ] **7.4** Протестировать регистрацию
  ```bash
  curl -X POST http://localhost:8080/auth/register \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"test123","name":"Test User"}'
  ```

- [ ] **7.5** Протестировать логин
  ```bash
  curl -X POST http://localhost:8080/auth/login \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com","password":"test123"}'
  ```

- [ ] **7.6** Написать unit тесты
  
  Файл: `test/services/auth_service_test.dart`

### Результат:
✅ JWT аутентификация работает  
✅ Регистрация работает  
✅ Логин работает  
✅ Тесты проходят

---

## Этап 8: API Endpoints

**Время:** 2-3 дня  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **8.1** Создать Users API
  - `routes/users/me/index.dart` - GET текущий пользователь
  - `routes/users/[id].dart` - GET/PUT/DELETE пользователь

- [ ] **8.2** Создать Routes API
  - `routes/routes/index.dart` - GET список маршрутов
  - `routes/routes/[id].dart` - GET конкретный маршрут

- [ ] **8.3** Создать Bookings API
  - `routes/bookings/index.dart` - GET/POST бронирования
  - `routes/bookings/[id].dart` - GET/PUT/DELETE бронирование
  - `routes/bookings/[id]/cancel.dart` - POST отмена

- [ ] **8.4** Создать Health Check
  - `routes/health.dart` - GET проверка здоровья

- [ ] **8.5** Добавить CORS middleware
  
  Файл: `routes/_middleware.dart`

- [ ] **8.6** Протестировать все endpoints
  ```bash
  # Создать Postman коллекцию или использовать curl
  ```

- [ ] **8.7** Написать integration тесты

### Результат:
✅ Все API endpoints работают  
✅ CORS настроен  
✅ Тесты проходят

---

## Этап 9: Nginx и SSL

**Время:** 1 день  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **9.1** Создать docker-compose.yml
  ```bash
  nano /opt/titotr/docker-compose.yml
  ```

- [ ] **9.2** Создать Nginx конфигурацию
  ```bash
  nano /opt/titotr/nginx/nginx.conf
  nano /opt/titotr/nginx/conf.d/titotr.conf
  ```

- [ ] **9.3** Запустить Docker Compose (без SSL)
  ```bash
  cd /opt/titotr
  docker compose up -d nginx postgres redis
  ```

- [ ] **9.4** Проверить доступность на HTTP
  ```bash
  curl http://titotr.ru/health
  ```

- [ ] **9.5** Получить SSL сертификат
  ```bash
  docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@titotr.ru \
    --agree-tos \
    --no-eff-email \
    -d titotr.ru \
    -d www.titotr.ru
  ```

- [ ] **9.6** Обновить Nginx конфигурацию для HTTPS

- [ ] **9.7** Перезапустить Nginx
  ```bash
  docker compose restart nginx
  ```

- [ ] **9.8** Проверить HTTPS
  ```bash
  curl https://titotr.ru/health
  ```

- [ ] **9.9** Проверить SSL рейтинг
  - Открыть: https://www.ssllabs.com/ssltest/analyze.html?d=titotr.ru
  - Цель: A+ рейтинг

### Результат:
✅ Docker Compose запущен  
✅ Nginx работает  
✅ SSL сертификат установлен  
✅ HTTPS работает  
✅ SSL рейтинг A+

---

## Этап 10: Миграция Данных

**Время:** 1-2 дня  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **10.1** Экспортировать пользователей из Firebase Auth
  ```javascript
  // Использовать Firebase Admin SDK
  // Сохранить в users.json
  ```

- [ ] **10.2** Экспортировать данные из Firestore
  ```bash
  firebase firestore:export ./firestore-backup
  ```

- [ ] **10.3** Создать скрипт миграции
  
  Файл: `tools/migrate_firebase.dart`

- [ ] **10.4** Протестировать на тестовой БД
  ```bash
  dart run tools/migrate_firebase.dart --test
  ```

- [ ] **10.5** Выполнить финальную миграцию
  ```bash
  dart run tools/migrate_firebase.dart --production
  ```

- [ ] **10.6** Проверить целостность данных
  ```sql
  -- На сервере
  docker compose exec postgres psql -U titotr_user -d titotr_production
  SELECT COUNT(*) FROM users;
  SELECT COUNT(*) FROM bookings;
  ```

### Результат:
✅ Пользователи мигрированы  
✅ Бронирования мигрированы  
✅ Данные проверены

---

## Этап 11: Flutter Integration

**Время:** 2-3 дня  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **11.1** Создать API клиент в Flutter
  ```dart
  // lib/services/api_client.dart
  ```

- [ ] **11.2** Заменить Firebase Auth на JWT
  - Удалить firebase_auth
  - Создать auth_service.dart
  - Реализовать JWT хранение (flutter_secure_storage)

- [ ] **11.3** Обновить модели данных
  - User model
  - Booking model
  - Route model

- [ ] **11.4** Обновить все API вызовы
  - Заменить Firestore запросы на HTTP
  - Обновить auth методы
  - Обновить CRUD операции

- [ ] **11.5** Обработать ошибки и retry логику

- [ ] **11.6** Добавить офлайн-режим (опционально)
  - Кеширование через sqflite
  - Sync при появлении интернета

- [ ] **11.7** Протестировать на реальных устройствах
  - iOS
  - Android

### Результат:
✅ Firebase SDK удален  
✅ API клиент работает  
✅ Аутентификация работает  
✅ Все функции работают

---

## Этап 12: Тестирование

**Время:** 2-3 дня  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **12.1** Backend Unit Tests
  ```bash
  cd backend
  dart test
  ```

- [ ] **12.2** Backend Integration Tests
  ```bash
  dart test test/integration
  ```

- [ ] **12.3** Flutter Unit Tests
  ```bash
  cd mobile
  flutter test
  ```

- [ ] **12.4** Flutter Widget Tests

- [ ] **12.5** E2E тесты (patrol или integration_test)

- [ ] **12.6** Нагрузочное тестирование
  ```bash
  # Использовать Apache Bench или k6
  ab -n 1000 -c 10 https://titotr.ru/api/health
  ```

- [ ] **12.7** Security аудит
  - SQL injection тесты
  - XSS тесты
  - CSRF тесты
  - Rate limiting тесты

- [ ] **12.8** Тестирование на медленном интернете

### Результат:
✅ Все тесты проходят  
✅ Нагрузка выдерживается  
✅ Security проблем нет

---

## Этап 13: Production Deploy

**Время:** 1 день  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **13.1** Создать deploy скрипты
  ```bash
  chmod +x scripts/deploy.sh
  chmod +x scripts/backup_db.sh
  ```

- [ ] **13.2** Выполнить первый деплой
  ```bash
  ./scripts/deploy.sh
  ```

- [ ] **13.3** Проверить все сервисы
  ```bash
  ssh titotr-production
  docker compose ps
  docker compose logs -f
  ```

- [ ] **13.4** Настроить автоматические бэкапы
  ```bash
  # Добавить в crontab
  crontab -e
  # 0 3 * * * cd /opt/titotr && ./scripts/backup_db.sh
  ```

- [ ] **13.5** Создать тестовый бэкап и restore
  ```bash
  ./scripts/backup_db.sh
  ./scripts/restore_db.sh backup_20260121.sql.gz
  ```

- [ ] **13.6** Настроить логирование
  ```bash
  # Проверить ротацию логов
  docker compose logs --tail=100 backend
  ```

### Результат:
✅ Production деплой выполнен  
✅ Все сервисы работают  
✅ Бэкапы настроены  
✅ Логирование работает

---

## Этап 14: Мониторинг

**Время:** 1 день  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **14.1** Установить Portainer (опционально)
  ```bash
  # Уже в docker-compose.yml
  # Открыть https://titotr.ru:9443
  ```

- [ ] **14.2** Настроить Uptime мониторинг
  - Использовать UptimeRobot.com (бесплатно)
  - Добавить https://titotr.ru/health
  - Настроить email алерты

- [ ] **14.3** Настроить мониторинг ресурсов
  ```bash
  # На сервере
  htop
  docker stats
  df -h
  ```

- [ ] **14.4** Настроить алерты
  - Email при падении сервиса
  - Telegram бот (опционально)

- [ ] **14.5** Создать dashboard для метрик (опционально)
  - Grafana + Prometheus
  - Или простой скрипт со статистикой

### Результат:
✅ Uptime мониторинг настроен  
✅ Алерты работают  
✅ Метрики отслеживаются

---

## Этап 15: Отключение Firebase

**Время:** 1 день  
**Статус:** ⏳ Не начат

### Задачи:

- [ ] **15.1** Проверить работу в production (1 неделя)
  - Мониторить ошибки
  - Собирать feedback от пользователей

- [ ] **15.2** Убедиться что все данные мигрированы

- [ ] **15.3** Отключить Firebase Functions
  ```bash
  firebase functions:delete --force
  ```

- [ ] **15.4** Отключить Firebase Firestore
  - Экспортировать финальный бэкап
  - Удалить данные

- [ ] **15.5** Отключить Firebase Auth
  - Убедиться что все пользователи перешли

- [ ] **15.6** Понизить Firebase план до Spark (бесплатный)
  - Firebase Console → Settings → Usage and billing

- [ ] **15.7** Обновить документацию
  - README
  - API документация

### Результат:
✅ Firebase отключен  
✅ Проект работает на собственном backend  
✅ Документация обновлена

---

## 📊 Трекинг Прогресса

| Этап | Задач | Выполнено | Прогресс | Статус |
|------|-------|-----------|----------|--------|
| 0. Подготовка | 6 | 0 | 0% | ⏳ |
| 1. Сервер | 5 | 0 | 0% | ⏳ |
| 2. DNS | 3 | 1 | 33% | 🟡 |
| 3. SSH | 9 | 0 | 0% | ⏳ |
| 4. Docker | 5 | 0 | 0% | ⏳ |
| 5. PostgreSQL | 3 | 0 | 0% | ⏳ |
| 6. Dart Frog | 8 | 0 | 0% | ⏳ |
| 7. JWT | 6 | 0 | 0% | ⏳ |
| 8. API | 7 | 0 | 0% | ⏳ |
| 9. Nginx/SSL | 9 | 0 | 0% | ⏳ |
| 10. Миграция | 6 | 0 | 0% | ⏳ |
| 11. Flutter | 7 | 0 | 0% | ⏳ |
| 12. Тесты | 8 | 0 | 0% | ⏳ |
| 13. Deploy | 6 | 0 | 0% | ⏳ |
| 14. Мониторинг | 5 | 0 | 0% | ⏳ |
| 15. Firebase OFF | 7 | 0 | 0% | ⏳ |
| **ИТОГО** | **90** | **1** | **1%** | 🟡 |

---

## 🎯 Следующие Шаги

**Начать с Этапа 0: Подготовка**

1. Создать бэкап Firebase
2. Установить локальное окружение
3. Создать структуру backend

**Готовы начать?** Скажи "Начинаем Этап 0" и я помогу пошагово!

---

**Обновлено:** 21 января 2026  
**Автор:** AI Assistant + Kirill Petrov
