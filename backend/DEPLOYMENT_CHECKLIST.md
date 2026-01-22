# 🚀 Финальный чек-лист для деплоя на Selectel

## ✅ Подготовка (Что нужно сделать ДО деплоя)

### 1. VPS на Selectel
- [ ] Зарегистрироваться на [selectel.ru](https://selectel.ru)
- [ ] Пополнить баланс (~600-800 руб/месяц)
- [ ] Создать VPS с параметрами:
  - **ОС**: Ubuntu 22.04 LTS
  - **CPU**: 2 ядра
  - **RAM**: 2 GB
  - **SSD**: 20 GB
  - **IP**: записать публичный IP-адрес
- [ ] Сохранить root пароль из email

### 2. Домен titotr.ru
- [ ] Зайти в панель управления Selectel DNS
- [ ] Добавить A-записи:
  ```
  @ → IP_АДРЕС_VPS
  www → IP_АДРЕС_VPS
  ```
- [ ] Дождаться распространения DNS (5-60 минут)
- [ ] Проверить: `ping titotr.ru` и `ping www.titotr.ru`

### 3. SSH Доступ
- [ ] Подключиться к серверу: `ssh root@titotr.ru`
- [ ] Создать SSH ключ локально (если нет): `ssh-keygen -t ed25519`
- [ ] Скопировать ключ на сервер: `ssh-copy-id root@titotr.ru`
- [ ] Проверить вход без пароля: `ssh root@titotr.ru`

### 4. Генерация секретов
- [ ] JWT Secret: 
  ```bash
  openssl rand -base64 32
  ```
  Сохранить результат!

- [ ] PostgreSQL пароль:
  ```bash
  openssl rand -base64 24
  ```
  Сохранить результат!

- [ ] Redis пароль:
  ```bash
  openssl rand -base64 24
  ```
  Сохранить результат!

### 5. Yandex Maps API Key
- [ ] Получить API ключ на [developer.tech.yandex.ru](https://developer.tech.yandex.ru)
- [ ] Включить сервисы: Geocoding API, Routes API
- [ ] Сохранить ключ

---

## 🔧 Деплой (Автоматический вариант)

### Шаг 1: Загрузить скрипты на сервер
```bash
# С локального Mac
cd /Users/kirillpetrov/Projects/time-to-travel/backend
scp deploy.sh setup-ssl.sh root@titotr.ru:/root/
```

### Шаг 2: Подключиться к серверу
```bash
ssh root@titotr.ru
```

### Шаг 3: Редактировать переменные в deploy.sh
```bash
nano deploy.sh
```

Найти и заменить:
```bash
POSTGRES_PASSWORD="YOUR_STRONG_PASSWORD"  # → Ваш сгенерированный пароль
REDIS_PASSWORD="YOUR_REDIS_PASSWORD"      # → Ваш Redis пароль
JWT_SECRET="YOUR_JWT_SECRET"              # → Ваш JWT secret
YANDEX_API_KEY="YOUR_YANDEX_API_KEY"      # → Ваш Yandex API key
```

Сохранить: `Ctrl+O`, `Enter`, `Ctrl+X`

### Шаг 4: Запустить деплой
```bash
chmod +x deploy.sh setup-ssl.sh
sudo bash deploy.sh
```

**Важно**: Скрипт спросит email для SSL сертификата → введите свой email!

### Шаг 5: Дождаться завершения
Скрипт выполнит автоматически:
- ✅ Обновление системы
- ✅ Установку Docker
- ✅ Клонирование репозитория
- ✅ Создание .env файла
- ✅ Инициализацию базы данных
- ✅ Установку SSL сертификата
- ✅ Запуск сервисов
- ✅ Проверку health check

---

## ✅ Проверка (После деплоя)

### 1. Health Check
```bash
curl https://titotr.ru/health
```

**Ожидаемый результат**:
```json
{
  "status": "healthy",
  "service": "Time to Travel API",
  "version": "1.0.0",
  "timestamp": "2025-01-..."
}
```

### 2. Регистрация тестового пользователя
```bash
curl -X POST https://titotr.ru/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "name": "Test User"
  }'
```

**Ожидаемый результат**: 
```json
{
  "user": {
    "id": "uuid-here",
    "email": "test@example.com",
    "name": "Test User",
    "role": "client"
  },
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

### 3. Авторизация
```bash
curl -X POST https://titotr.ru/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!"
  }'
```

### 4. Поиск маршрутов (БЕЗ авторизации)
```bash
curl "https://titotr.ru/routes/search?from_latitude=47.2357&from_longitude=39.7015&to_latitude=47.5090&to_longitude=42.1760"
```

**Должен вернуть маршрут**: Ростов-на-Дону → Волгодонск

### 5. Создание заказа (С авторизацией)
```bash
# Сохранить токен из шага 2
TOKEN="your_access_token_here"

curl -X POST https://titotr.ru/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "route_id": "uuid-from-search",
    "passengers": 2,
    "baggage_s": 1,
    "baggage_m": 0,
    "baggage_l": 0,
    "pickup_time": "2025-02-01T10:00:00Z"
  }'
```

### 6. Проверка Docker контейнеров
```bash
ssh root@titotr.ru
docker ps
```

**Должны быть запущены**:
- backend
- postgres
- redis
- nginx

### 7. Проверка логов
```bash
# Backend логи
docker logs backend

# Nginx логи
docker logs nginx

# PostgreSQL логи
docker logs postgres
```

### 8. Проверка базы данных
```bash
docker exec -it postgres psql -U timetotravel_user -d timetotravel

# В psql:
\dt              # Список таблиц (должно быть 6)
SELECT * FROM users;
SELECT * FROM predefined_routes;
\q               # Выход
```

---

## 🔒 Безопасность (Сразу после деплоя)

### 1. Firewall
```bash
# Должен быть активен (deploy.sh уже настроил)
sudo ufw status

# Ожидаемый результат:
# 22/tcp  ALLOW
# 80/tcp  ALLOW
# 443/tcp ALLOW
```

### 2. Fail2Ban
```bash
# Проверить статус
sudo systemctl status fail2ban

# Посмотреть защищённые сервисы
sudo fail2ban-client status
```

### 3. SSL сертификат
```bash
# Проверить срок действия
sudo certbot certificates

# Тестовое обновление (должно пройти без ошибок)
sudo certbot renew --dry-run
```

### 4. Изменить root пароль
```bash
passwd
```

### 5. Создать пользователя для деплоя (опционально)
```bash
adduser deployer
usermod -aG sudo deployer
su - deployer
```

---

## 📱 Интеграция с Flutter приложением

### Шаг 1: Обновить базовый URL
В Flutter проекте найти файл с API конфигурацией и изменить:
```dart
// Было:
static const baseUrl = 'http://localhost:8080';

// Стало:
static const baseUrl = 'https://titotr.ru';
```

### Шаг 2: Установить пакеты для работы с API
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
  flutter_secure_storage: ^9.0.0  # Для хранения токенов
  provider: ^6.1.1                # Для state management
```

### Шаг 3: Создать API сервис
См. файл `FLUTTER_INTEGRATION.md` (будет создан далее)

---

## 🔄 Обслуживание

### Резервное копирование БД
```bash
# Создать бэкап
docker exec postgres pg_dump -U timetotravel_user timetotravel > backup_$(date +%Y%m%d).sql

# Восстановить из бэкапа
cat backup_20250201.sql | docker exec -i postgres psql -U timetotravel_user -d timetotravel
```

### Обновление кода
```bash
ssh root@titotr.ru
cd /opt/time-to-travel/backend
git pull
docker compose down
docker compose up -d --build
```

### Просмотр логов
```bash
# Все сервисы
docker compose logs -f

# Только backend
docker compose logs -f backend

# Последние 100 строк
docker compose logs --tail=100 backend
```

### Перезапуск сервисов
```bash
# Все сервисы
docker compose restart

# Только backend
docker compose restart backend
```

---

## 🚨 Troubleshooting

### Проблема: Backend не запускается
```bash
# Проверить логи
docker logs backend

# Проверить переменные окружения
docker exec backend env | grep DATABASE_URL

# Перезапустить с rebuild
docker compose down
docker compose up -d --build
```

### Проблема: 502 Bad Gateway
```bash
# Проверить статус backend
docker ps | grep backend

# Проверить логи Nginx
docker logs nginx

# Проверить health check
curl http://localhost:8080/health
```

### Проблема: Database connection failed
```bash
# Проверить PostgreSQL
docker ps | grep postgres
docker logs postgres

# Подключиться вручную
docker exec -it postgres psql -U timetotravel_user -d timetotravel
```

### Проблема: SSL не работает
```bash
# Проверить сертификаты
sudo certbot certificates

# Проверить конфигурацию Nginx
docker exec nginx nginx -t

# Перезапустить Nginx
docker restart nginx
```

---

## 📊 Мониторинг

### Использование ресурсов
```bash
# Использование CPU/RAM контейнерами
docker stats

# Использование диска
df -h

# Свободная память
free -h
```

### Проверка доступности
```bash
# Простой скрипт мониторинга
while true; do
  curl -s https://titotr.ru/health | jq '.status'
  sleep 60
done
```

---

## ✅ Финальный чек-лист

- [ ] VPS арендован и настроен
- [ ] Домен titotr.ru привязан к IP
- [ ] SSH доступ работает
- [ ] Секреты сгенерированы и сохранены
- [ ] deploy.sh успешно выполнен
- [ ] Health check возвращает 200 OK
- [ ] Тестовый пользователь создан
- [ ] Авторизация работает
- [ ] Поиск маршрутов работает
- [ ] Создание заказов работает
- [ ] SSL сертификат установлен
- [ ] Firewall настроен
- [ ] Fail2Ban активен
- [ ] Логи без критических ошибок
- [ ] Резервное копирование настроено

---

## 🎯 Следующие шаги

1. **Настроить мониторинг** (опционально):
   - Prometheus + Grafana
   - Sentry для ошибок
   - UptimeRobot для проверки доступности

2. **Интегрировать Flutter приложение**:
   - Обновить API base URL
   - Реализовать JWT authentication
   - Заменить SQLite на REST API

3. **Добавить функционал**:
   - Email верификация
   - Восстановление пароля
   - Push уведомления
   - Платёжная интеграция

4. **Оптимизация**:
   - CDN для статики
   - Redis кэширование
   - Database индексы
   - Nginx rate limiting

---

**Готовы к деплою? Начните с пункта "Подготовка" ☝️**
