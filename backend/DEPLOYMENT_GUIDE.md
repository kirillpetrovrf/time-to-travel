# 🚀 Руководство по развертыванию на Selectel VPS

**Дата:** 22 января 2026  
**Домен:** titotr.ru  
**Стоимость VPS:** ~600-800 руб/мес

---

## 📋 Содержание

1. [Требования к серверу](#требования-к-серверу)
2. [Подготовка VPS на Selectel](#подготовка-vps-на-selectel)
3. [Автоматическое развертывание](#автоматическое-развертывание)
4. [Ручное развертывание](#ручное-развертывание)
5. [Настройка SSL](#настройка-ssl)
6. [Проверка работоспособности](#проверка-работоспособности)
7. [Обслуживание](#обслуживание)
8. [Troubleshooting](#troubleshooting)

---

## 🖥️ Требования к серверу

### Минимальные характеристики VPS:
- **CPU:** 2 ядра
- **RAM:** 2 GB
- **Disk:** 20 GB SSD
- **OS:** Ubuntu 22.04 LTS
- **Network:** 100 Mbps

### Рекомендуемые характеристики:
- **CPU:** 4 ядра
- **RAM:** 4 GB
- **Disk:** 40 GB SSD
- **Network:** 1 Gbps

### Порты:
- `22` - SSH
- `80` - HTTP (будет редиректить на HTTPS)
- `443` - HTTPS (основной API)
- `8080` - Backend (только localhost)
- `5432` - PostgreSQL (только localhost)
- `6379` - Redis (только localhost)

---

## 🏗️ Подготовка VPS на Selectel

### Шаг 1: Создание VPS

1. Войдите в [панель Selectel](https://my.selectel.ru/)
2. Перейдите в **Cloud Platform** → **Серверы**
3. Нажмите **Создать сервер**
4. Выберите конфигурацию:
   - **Регион:** Москва (ru-1)
   - **Образ:** Ubuntu 22.04 LTS
   - **Конфигурация:** 2 vCPU, 2 GB RAM, 20 GB SSD (~600 руб/мес)
   - **SSH ключ:** Добавьте ваш публичный ключ
5. Нажмите **Создать**

### Шаг 2: Настройка DNS

1. В панели Selectel перейдите в **DNS**
2. Добавьте зону `titotr.ru`
3. Создайте A-записи:
   ```
   titotr.ru.      A    <IP_ВАШЕГО_VPS>
   www.titotr.ru.  A    <IP_ВАШЕГО_VPS>
   ```
4. Проверьте DNS серверы Selectel уже настроены в домене

### Шаг 3: Первое подключение

```bash
# Подключение к серверу
ssh root@<IP_ВАШЕГО_VPS>

# Создание пользователя (опционально, для безопасности)
adduser deploy
usermod -aG sudo deploy
su - deploy
```

---

## ⚡ Автоматическое развертывание

### Способ 1: Быстрое развертывание (рекомендуется)

```bash
# 1. Подключение к серверу
ssh root@<IP_ВАШЕГО_VPS>

# 2. Скачивание и запуск скрипта развертывания
curl -fsSL https://raw.githubusercontent.com/kirillpetrovrf/time-to-travel/main/backend/deploy.sh -o deploy.sh
chmod +x deploy.sh
./deploy.sh
```

**Скрипт автоматически:**
- ✅ Обновит систему
- ✅ Установит Docker, Docker Compose, Nginx
- ✅ Настроит файрвол (UFW)
- ✅ Клонирует репозиторий
- ✅ Создаст .env файл
- ✅ Запустит Docker Compose
- ✅ Инициализирует базу данных
- ✅ Настроит автозапуск

### Способ 2: Скрипт SSL (после основного развертывания)

```bash
# После успешного развертывания
sudo curl -fsSL https://raw.githubusercontent.com/kirillpetrovrf/time-to-travel/main/backend/setup-ssl.sh -o setup-ssl.sh
sudo chmod +x setup-ssl.sh
sudo ./setup-ssl.sh
```

**Скрипт настроит:**
- ✅ Let's Encrypt SSL сертификаты
- ✅ Nginx с HTTPS
- ✅ Автообновление сертификатов
- ✅ HTTP → HTTPS редирект

---

## 🔧 Ручное развертывание

### Шаг 1: Обновление системы

```bash
sudo apt update && sudo apt upgrade -y
```

### Шаг 2: Установка Docker

```bash
# Установка зависимостей
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Добавление GPG ключа Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Добавление репозитория
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER
```

### Шаг 3: Настройка файрвола

```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status
```

### Шаг 4: Клонирование репозитория

```bash
# Создание директории
sudo mkdir -p /opt/time-to-travel
sudo chown $USER:$USER /opt/time-to-travel
cd /opt/time-to-travel

# Клонирование (замените на ваш URL)
git clone https://github.com/kirillpetrovrf/time-to-travel.git .
```

### Шаг 5: Создание .env файла

```bash
cd /opt/time-to-travel/backend

# Создание .env
cat > .env << 'EOF'
# Database
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=timetotravel
POSTGRES_USER=postgres
POSTGRES_PASSWORD=ваш_пароль_postgres

# JWT (сгенерируйте надежный ключ)
JWT_SECRET=ваш_секретный_ключ_минимум_32_символа
JWT_ACCESS_EXPIRY_SECONDS=3600
JWT_REFRESH_EXPIRY_SECONDS=604800

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Server
PORT=8080
ENVIRONMENT=production

# Domain
DOMAIN=titotr.ru
LETSENCRYPT_EMAIL=admin@titotr.ru
EOF

chmod 600 .env
```

### Шаг 6: Запуск Docker Compose

```bash
docker compose up -d --build

# Проверка статуса
docker compose ps

# Просмотр логов
docker compose logs -f
```

---

## 🔒 Настройка SSL

### Автоматическая настройка (рекомендуется)

```bash
sudo ./setup-ssl.sh
```

### Ручная настройка

#### 1. Установка Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

#### 2. Получение сертификата

```bash
sudo certbot certonly --standalone -d titotr.ru -d www.titotr.ru
```

#### 3. Настройка Nginx

```bash
sudo nano /etc/nginx/sites-available/titotr.ru
```

Вставьте конфигурацию из `backend/nginx/conf.d/titotr.conf`

#### 4. Включение сайта

```bash
sudo ln -s /etc/nginx/sites-available/titotr.ru /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### 5. Автообновление сертификатов

```bash
sudo crontab -e

# Добавьте строку:
0 3 * * * certbot renew --quiet --post-hook "systemctl reload nginx"
```

---

## ✅ Проверка работоспособности

### 1. Проверка контейнеров

```bash
docker compose ps

# Все контейнеры должны быть Up (healthy)
```

### 2. Проверка API

```bash
# Health check
curl http://localhost:8080/health

# Должен вернуть:
# {"status":"ok","service":"timetotravel-api","version":"1.0.0","timestamp":"..."}
```

### 3. Проверка HTTPS

```bash
# После настройки SSL
curl https://titotr.ru/health
curl https://titotr.ru/api/health
```

### 4. Проверка PostgreSQL

```bash
docker compose exec postgres psql -U postgres -d timetotravel -c "\dt"

# Должны отобразиться таблицы: users, orders, routes, etc.
```

### 5. Тестирование регистрации

```bash
curl -X POST https://titotr.ru/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@test.com",
    "password": "test123",
    "name": "Test User",
    "phone": "+79001234567"
  }'
```

---

## 🔧 Обслуживание

### Просмотр логов

```bash
# Все сервисы
docker compose logs -f

# Конкретный сервис
docker compose logs -f backend
docker compose logs -f postgres
docker compose logs -f nginx
```

### Перезапуск сервисов

```bash
# Все сервисы
docker compose restart

# Конкретный сервис
docker compose restart backend
```

### Обновление кода

```bash
cd /opt/time-to-travel
git pull origin main
docker compose up -d --build
```

### Бэкап базы данных

```bash
# Создание бэкапа
docker compose exec postgres pg_dump -U postgres timetotravel > backup_$(date +%Y%m%d).sql

# Восстановление из бэкапа
docker compose exec -T postgres psql -U postgres timetotravel < backup_20260122.sql
```

### Мониторинг ресурсов

```bash
# Использование ресурсов контейнерами
docker stats

# Использование диска
df -h

# Память
free -h

# CPU
htop
```

---

## 🐛 Troubleshooting

### Проблема: Backend не запускается

```bash
# Проверка логов
docker compose logs backend

# Проверка .env файла
cat .env

# Пересоздание контейнера
docker compose down
docker compose up -d --build
```

### Проблема: PostgreSQL не доступна

```bash
# Проверка контейнера
docker compose ps postgres

# Проверка логов
docker compose logs postgres

# Пересоздание с удалением volumes
docker compose down -v
docker compose up -d
```

### Проблема: SSL сертификат не получается

```bash
# Проверка DNS
dig titotr.ru
nslookup titotr.ru

# Проверка портов
sudo ufw status
sudo netstat -tulpn | grep :80
sudo netstat -tulpn | grep :443

# Остановка Nginx и повтор
sudo systemctl stop nginx
sudo certbot certonly --standalone -d titotr.ru -d www.titotr.ru
```

### Проблема: Нет места на диске

```bash
# Очистка Docker
docker system prune -a

# Очистка логов
sudo journalctl --vacuum-time=3d

# Проверка больших файлов
du -h --max-depth=1 /opt/time-to-travel | sort -hr
```

### Проблема: 502 Bad Gateway

```bash
# Проверка backend
docker compose ps backend

# Проверка логов Nginx
sudo tail -f /var/log/nginx/error.log

# Проверка Nginx конфигурации
sudo nginx -t

# Перезапуск
docker compose restart backend
sudo systemctl restart nginx
```

---

## 📊 Мониторинг и метрики

### Установка мониторинга (опционально)

```bash
# Установка node_exporter для Prometheus
docker run -d \
  --name=node_exporter \
  --restart=always \
  -p 9100:9100 \
  prom/node-exporter
```

### Простой health check скрипт

```bash
cat > /usr/local/bin/check-api.sh << 'EOF'
#!/bin/bash
if ! curl -s http://localhost:8080/health | grep -q "ok"; then
    echo "$(date): API is DOWN" >> /var/log/api-health.log
    # Опционально: отправка уведомления
fi
EOF

chmod +x /usr/local/bin/check-api.sh

# Добавить в cron каждые 5 минут
echo "*/5 * * * * /usr/local/bin/check-api.sh" | sudo crontab -
```

---

## 🔗 Полезные ссылки

- **Selectel Cloud:** https://my.selectel.ru/
- **SSL Test:** https://www.ssllabs.com/ssltest/
- **Docker Docs:** https://docs.docker.com/
- **Let's Encrypt:** https://letsencrypt.org/
- **Nginx Docs:** https://nginx.org/ru/docs/

---

## 📝 Чек-лист развертывания

- [ ] VPS создан на Selectel
- [ ] DNS настроен (titotr.ru → IP VPS)
- [ ] Подключение по SSH работает
- [ ] Docker установлен
- [ ] Репозиторий склонирован
- [ ] .env файл создан и заполнен
- [ ] Docker Compose запущен
- [ ] База данных инициализирована
- [ ] API отвечает на /health
- [ ] SSL сертификат получен
- [ ] Nginx настроен с HTTPS
- [ ] Автообновление SSL настроено
- [ ] Файрвол настроен
- [ ] Бэкапы настроены
- [ ] Мониторинг настроен

---

**Готово к production! 🚀**
