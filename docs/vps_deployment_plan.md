# План развертывания VPS хостинга для "Такси Попутчик"

## 1. Архитектура инфраструктуры

### 1.1 Общая схема
```
[Пользователи] 
    ↓
[Load Balancer (nginx)]
    ↓
[API Gateway (Dart Frog)]
    ↓
[Микросервисы]
    ↓
[База данных PostgreSQL] + [Redis Cache]
```

### 1.2 Этапы масштабирования

#### Этап 1: MVP (0-1000 пользователей)
- **1 VPS сервер** - все компоненты на одной машине
- **Конфигурация**: 4 CPU, 8GB RAM, 100GB SSD
- **Стоимость**: ~3,000-5,000 руб/месяц

#### Этап 2: Рост (1,000-10,000 пользователей)
- **2 VPS сервера**: 
  - Сервер 1: API + приложение
  - Сервер 2: База данных + Redis
- **Конфигурация каждого**: 4 CPU, 16GB RAM, 200GB SSD
- **Стоимость**: ~8,000-12,000 руб/месяц

#### Этап 3: Масштабирование (10,000+ пользователей)
- **4+ VPS серверов**:
  - Load Balancer
  - 2x API серверы (horizontal scaling)
  - База данных + Redis
- **Конфигурация**: 8 CPU, 32GB RAM, 500GB SSD
- **Стоимость**: ~25,000-40,000 руб/месяц

## 2. Выбор провайдера VPS

### 2.1 Рекомендуемые провайдеры (по приоритету)

#### 1. Яндекс.Облако 🥇
**Преимущества:**
- Российская резидентность (соответствие 152-ФЗ)
- Высокая производительность
- Хорошая техподдержка на русском языке
- Интеграция с Яндекс.Картами

**Тарифы (Москва):**
- 4 vCPU, 8GB RAM, 100GB SSD: ~4,500 руб/месяц
- 8 vCPU, 16GB RAM, 200GB SSD: ~9,000 руб/месяц
- 16 vCPU, 32GB RAM, 500GB SSD: ~18,000 руб/месяц

**Дополнительные сервисы:**
- Managed PostgreSQL: +2,000 руб/месяц
- Load Balancer: +1,000 руб/месяц
- Object Storage: ~500 руб/месяц за 100GB

#### 2. VK Cloud (Mail.ru Cloud) 🥈
**Преимущества:**
- Российская резидентность
- Хорошее соотношение цена/качество
- Бесплатные публичные IP

**Тарифы:**
- 4 vCPU, 8GB RAM, 100GB SSD: ~3,500 руб/месяц
- 8 vCPU, 16GB RAM, 200GB SSD: ~7,000 руб/месяц

#### 3. Selectel 🥉
**Преимущества:**
- Российский провайдер
- Гибкие тарифы
- Хорошая сеть

**Тарифы:**
- 4 vCPU, 8GB RAM, 100GB SSD: ~4,000 руб/месяц

### 2.2 Международные варианты (для будущего расширения)

#### DigitalOcean
- Простота использования
- Глобальная сеть дата-центров
- $40-80/месяц за аналогичные конфигурации

#### AWS/Google Cloud
- Максимальная масштабируемость
- Pay-as-you-use модель
- Дороже, но больше возможностей

## 3. Конфигурация серверов

### 3.1 Операционная система
**Ubuntu 22.04 LTS** (рекомендуется)
- Долгосрочная поддержка до 2027 года
- Хорошая совместимость с Dart
- Большое сообщество

### 3.2 Базовая настройка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка необходимых пакетов
sudo apt install -y curl wget git nginx postgresql redis-server

# Настройка файрвола
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443

# Установка Dart SDK
sudo apt update
sudo apt install apt-transport-https
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
sudo apt update
sudo apt install dart

# Установка Docker (для контейнеризации)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### 3.3 Конфигурация Nginx (Load Balancer)

```nginx
# /etc/nginx/sites-available/taxi-poputchik
server {
    listen 80;
    server_name api.taxi-poputchik.ru;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3.4 Конфигурация PostgreSQL

```sql
-- Создание базы данных
CREATE DATABASE taxi_poputchik;
CREATE USER taxi_user WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE taxi_poputchik TO taxi_user;

-- Основные таблицы
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis"; -- для работы с геоданными
```

### 3.5 Конфигурация Redis

```conf
# /etc/redis/redis.conf
maxmemory 2gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
```

## 4. Развертывание приложения

### 4.1 Структура проекта на сервере

```
/opt/taxi-poputchik/
├── app/                    # Dart Frog приложение
├── scripts/               # Скрипты развертывания
├── logs/                  # Логи приложения
├── backups/              # Резервные копии
└── ssl/                  # SSL сертификаты
```

### 4.2 Systemd сервис для приложения

```ini
# /etc/systemd/system/taxi-poputchik.service
[Unit]
Description=Taxi Poputchik API
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=taxi
WorkingDirectory=/opt/taxi-poputchik/app
ExecStart=/usr/bin/dart run bin/server.dart
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

### 4.3 Скрипт автоматического развертывания

```bash
#!/bin/bash
# deploy.sh

set -e

echo "🚀 Начинаем развертывание Taxi Poputchik..."

# Остановка сервиса
sudo systemctl stop taxi-poputchik || true

# Создание резервной копии
echo "📦 Создание резервной копии..."
sudo -u postgres pg_dump taxi_poputchik > /opt/taxi-poputchik/backups/db_backup_$(date +%Y%m%d_%H%M%S).sql

# Обновление кода
echo "⬇️ Обновление кода..."
cd /opt/taxi-poputchik/app
git pull origin main

# Установка зависимостей
echo "📋 Установка зависимостей..."
dart pub get

# Применение миграций
echo "🗄️ Применение миграций..."
dart run migrations.dart

# Запуск сервиса
echo "▶️ Запуск сервиса..."
sudo systemctl start taxi-poputchik
sudo systemctl status taxi-poputchik

echo "✅ Развертывание завершено!"
```

## 5. Мониторинг и логирование

### 5.1 Prometheus + Grafana

```yaml
# docker-compose.monitoring.yml
version: '3.8'
services:
  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
    volumes:
      - grafana-storage:/var/lib/grafana

volumes:
  grafana-storage:
```

### 5.2 Система алертов

```yaml
# alertmanager.yml
global:
  slack_api_url: 'YOUR_SLACK_WEBHOOK_URL'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  slack_configs:
  - channel: '#alerts'
    text: 'Проблема с сервером: {{ .CommonAnnotations.summary }}'
```

### 5.3 Логирование

```dart
// lib/utils/logger.dart
import 'dart:developer' as developer;

class Logger {
  static void info(String message) {
    developer.log(message, name: 'TaxiPoputchik.INFO');
  }
  
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'TaxiPoputchik.ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
```

## 6. Безопасность

### 6.1 SSL сертификаты (Let's Encrypt)

```bash
# Установка Certbot
sudo apt install certbot python3-certbot-nginx

# Получение сертификата
sudo certbot --nginx -d api.taxi-poputchik.ru

# Автоматическое обновление
sudo crontab -e
# Добавить строку:
0 12 * * * /usr/bin/certbot renew --quiet
```

### 6.2 Файрвол и безопасность

```bash
# Настройка UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow from 10.0.0.0/8 to any port 5432  # PostgreSQL только из внутренней сети
sudo ufw enable

# Fail2ban для защиты от брут-форса
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

### 6.3 Резервное копирование

```bash
#!/bin/bash
# backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/taxi-poputchik/backups"

# Резервная копия базы данных
sudo -u postgres pg_dump taxi_poputchik | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# Резервная копия файлов
tar -czf "$BACKUP_DIR/files_$DATE.tar.gz" /opt/taxi-poputchik/app

# Загрузка в облако (опционально)
# rclone copy "$BACKUP_DIR/db_$DATE.sql.gz" yandex-cloud:backups/
# rclone copy "$BACKUP_DIR/files_$DATE.tar.gz" yandex-cloud:backups/

# Удаление старых резервных копий (старше 30 дней)
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete
```

## 7. Стоимость развертывания по этапам

### 7.1 Этап 1 (MVP, 0-1000 пользователей)
**Месячные расходы:**
- VPS (Яндекс.Облако): 4,500 руб
- Домен .ru: 200 руб
- SSL сертификат: 0 руб (Let's Encrypt)
- Мониторинг: 0 руб (self-hosted)
- **Итого**: ~4,700 руб/месяц

### 7.2 Этап 2 (1,000-10,000 пользователей)
**Месячные расходы:**
- VPS x2: 9,000 руб
- Load Balancer: 1,000 руб
- Object Storage: 500 руб
- Backup Storage: 300 руб
- **Итого**: ~10,800 руб/месяц

### 7.3 Этап 3 (10,000+ пользователей)
**Месячные расходы:**
- VPS x4: 18,000 руб
- Managed PostgreSQL: 3,000 руб
- Load Balancer: 1,500 руб
- CDN: 2,000 руб
- Monitoring (Grafana Cloud): 1,000 руб
- Backup Storage: 1,000 руб
- **Итого**: ~26,500 руб/месяц

## 8. Чек-лист развертывания

### 8.1 Подготовка
- [ ] Регистрация домена
- [ ] Выбор и настройка VPS провайдера
- [ ] Создание SSH ключей
- [ ] Настройка DNS записей

### 8.2 Базовая настройка сервера
- [ ] Установка Ubuntu 22.04 LTS
- [ ] Обновление системы
- [ ] Создание пользователя приложения
- [ ] Настройка SSH (отключение root логина)
- [ ] Настройка файрвола
- [ ] Установка Dart SDK

### 8.3 Установка компонентов
- [ ] PostgreSQL + создание БД
- [ ] Redis + настройка
- [ ] Nginx + конфигурация
- [ ] SSL сертификаты
- [ ] Docker (для мониторинга)

### 8.4 Развертывание приложения
- [ ] Клонирование репозитория
- [ ] Настройка переменных окружения
- [ ] Создание systemd сервиса
- [ ] Применение миграций БД
- [ ] Запуск и тестирование

### 8.5 Мониторинг и безопасность
- [ ] Настройка Prometheus + Grafana
- [ ] Конфигурация алертов
- [ ] Настройка логирования
- [ ] Создание скриптов резервного копирования
- [ ] Тестирование восстановления

### 8.6 Документация
- [ ] Создание runbook для администраторов
- [ ] Документирование процедур развертывания
- [ ] Инструкции по мониторингу
- [ ] Процедуры восстановления после сбоев

## 9. Контакты поддержки

### 9.1 Техническая поддержка провайдеров
- **Яндекс.Облако**: support@cloud.yandex.ru, +7 495 739-70-00
- **VK Cloud**: support@mcs.mail.ru, +7 495 725-11-11
- **Selectel**: support@selectel.ru, +7 812 603-70-80

### 9.2 Документация
- **Dart Frog**: https://dartfrog.vgv.dev/
- **PostgreSQL**: https://www.postgresql.org/docs/
- **Redis**: https://redis.io/documentation
- **Nginx**: https://nginx.org/ru/docs/

---

**Важно**: Данный план является базовым и может требовать корректировок в зависимости от специфических требований проекта и нагрузки.
