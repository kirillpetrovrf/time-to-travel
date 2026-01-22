#!/bin/bash

# 🔒 Скрипт настройки SSL сертификатов Let's Encrypt для titotr.ru
# Использует Certbot для автоматического получения и обновления SSL

set -e

echo "🔒 Настройка SSL сертификатов Let's Encrypt"
echo "============================================"

# Цвета
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Проверка запуска от root
if [ "$EUID" -ne 0 ]; then 
    log_warning "Запустите скрипт с sudo"
    exit 1
fi

# Переменные
DOMAIN="titotr.ru"
EMAIL="admin@titotr.ru"

# Запрос email если не указан
echo -n "Email для уведомлений Let's Encrypt [$EMAIL]: "
read INPUT_EMAIL
if [ ! -z "$INPUT_EMAIL" ]; then
    EMAIL=$INPUT_EMAIL
fi

# 1. Установка Certbot
log_info "Установка Certbot..."
apt update
apt install -y certbot python3-certbot-nginx
log_success "Certbot установлен"

# 2. Остановка Nginx (если запущен)
log_info "Остановка Nginx..."
systemctl stop nginx || true

# 3. Получение сертификата (standalone mode)
log_info "Получение SSL сертификата для $DOMAIN..."
certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email $EMAIL \
    -d $DOMAIN \
    -d www.$DOMAIN

if [ $? -eq 0 ]; then
    log_success "SSL сертификат получен"
else
    log_warning "Не удалось получить сертификат. Проверьте DNS настройки."
    exit 1
fi

# 4. Создание Nginx конфигурации с SSL
log_info "Настройка Nginx с SSL..."

cat > /etc/nginx/sites-available/titotr.ru << 'EOF'
# HTTP -> HTTPS редирект
server {
    listen 80;
    listen [::]:80;
    server_name titotr.ru www.titotr.ru;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name titotr.ru www.titotr.ru;

    # SSL сертификаты
    ssl_certificate /etc/letsencrypt/live/titotr.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/titotr.ru/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/titotr.ru/chain.pem;

    # SSL настройки (Mozilla Intermediate)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    # HSTS (раскомментируйте после тестирования)
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Логи
    access_log /var/log/nginx/titotr_access.log;
    error_log /var/log/nginx/titotr_error.log;

    # API endpoints
    location /api/ {
        proxy_pass http://localhost:8080/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Таймауты
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check
    location /health {
        proxy_pass http://localhost:8080/health;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        access_log off;
    }

    # Основная страница (опционально - для статики)
    location / {
        root /var/www/titotr.ru;
        index index.html;
        try_files $uri $uri/ =404;
    }
}
EOF

# Создание директории для certbot
mkdir -p /var/www/certbot

# Создание директории для статики (опционально)
mkdir -p /var/www/titotr.ru
echo "<html><body><h1>Time to Travel API</h1><p>API работает на <a href='/api/health'>/api/health</a></p></body></html>" > /var/www/titotr.ru/index.html

# Включение сайта
ln -sf /etc/nginx/sites-available/titotr.ru /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Проверка конфигурации
nginx -t

if [ $? -eq 0 ]; then
    log_success "Nginx конфигурация валидна"
else
    log_warning "Ошибка в конфигурации Nginx"
    exit 1
fi

# 5. Запуск Nginx
log_info "Запуск Nginx..."
systemctl enable nginx
systemctl start nginx
log_success "Nginx запущен"

# 6. Настройка автообновления сертификатов
log_info "Настройка автообновления сертификатов..."

# Создание cron задачи
cat > /etc/cron.d/certbot-renew << 'EOF'
# Обновление SSL сертификатов каждый день в 3:00
0 3 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

chmod 644 /etc/cron.d/certbot-renew
log_success "Автообновление настроено"

# 7. Тестирование обновления
log_info "Тестирование обновления сертификата (dry-run)..."
certbot renew --dry-run

if [ $? -eq 0 ]; then
    log_success "Тест обновления прошел успешно"
else
    log_warning "Проблема с автообновлением, проверьте логи"
fi

# Финальная информация
echo ""
echo "=========================================="
log_success "🎉 SSL настроен успешно!"
echo "=========================================="
echo ""
echo "📊 Информация:"
echo "  - Домен: https://$DOMAIN"
echo "  - Сертификат: /etc/letsencrypt/live/$DOMAIN/"
echo "  - Срок действия: 90 дней (автообновление настроено)"
echo ""
echo "📝 Полезные команды:"
echo "  - Проверка сертификата: certbot certificates"
echo "  - Обновление вручную: certbot renew"
echo "  - Проверка Nginx: nginx -t"
echo "  - Перезагрузка Nginx: systemctl reload nginx"
echo ""
echo "🔗 Тестирование:"
echo "  - curl https://$DOMAIN/health"
echo "  - curl https://$DOMAIN/api/health"
echo ""
echo "🔐 SSL проверка:"
echo "  - https://www.ssllabs.com/ssltest/analyze.html?d=$DOMAIN"
