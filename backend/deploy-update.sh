#!/bin/bash

# 🚀 Скрипт обновления backend на production сервере
# Применяет исправление CreateOrderDto

set -e

echo "🎯 Деплой исправления CreateOrderDto на production"
echo "=================================================="

SERVER="root@78.155.202.50"
PROJECT_DIR="/root/time-to-travel"  # Измените если путь другой

echo ""
echo "📡 Подключение к серверу $SERVER..."

ssh $SERVER << 'ENDSSH'
set -e

echo "✅ Подключено к серверу"

# Найти директорию проекта
if [ -d "/root/time-to-travel" ]; then
    PROJECT_DIR="/root/time-to-travel"
elif [ -d "/opt/time-to-travel" ]; then
    PROJECT_DIR="/opt/time-to-travel"
elif [ -d "/home/deploy/time-to-travel" ]; then
    PROJECT_DIR="/home/deploy/time-to-travel"
else
    echo "❌ Не найдена директория проекта!"
    echo "Поиск во всех возможных местах:"
    find /root /opt /home -name "docker-compose.yml" -path "*/backend/*" 2>/dev/null | head -5
    exit 1
fi

echo "📁 Проект найден: $PROJECT_DIR"
cd $PROJECT_DIR

echo ""
echo "📥 Обновление кода из GitHub..."
git pull origin main

echo ""
echo "🔄 Перезапуск Docker контейнеров (с ребилдом)..."
cd backend

# Проверка какая версия docker compose
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose не найден!"
    exit 1
fi

echo "Используется: $COMPOSE_CMD"

$COMPOSE_CMD down
$COMPOSE_CMD up -d --build

echo ""
echo "⏳ Ожидание запуска backend (30 сек)..."
sleep 30

echo ""
echo "🧪 Проверка работоспособности..."
docker-compose ps

echo ""
echo "✅ ДЕПЛОЙ ЗАВЕРШЁН!"
echo ""
echo "Тестирование:"
echo "curl https://titotr.ru/api/health"
echo ""
echo "Проверка логов:"
echo "docker-compose logs -f backend"

ENDSSH

echo ""
echo "=================================================="
echo "✅ Обновление на сервере завершено!"
echo ""
echo "🧪 Тестируем POST /api/orders:"
echo ""

sleep 5

curl -i -X POST https://titotr.ru/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "fromAddress": "Донецк, ул. Артёма 120",
    "toAddress": "Ростов-на-Дону",
    "departureTime": "2026-01-23T08:00:00.000Z",
    "passengerCount": 2,
    "basePrice": 4000,
    "totalPrice": 4000,
    "finalPrice": 4000
  }'

echo ""
echo ""
echo "=================================================="
echo "Если видите '201 Created' - заказы теперь сохраняются! ✅"
echo "Если всё ещё '500 Internal Server Error' - смотрите логи:"
echo "  ssh $SERVER"
echo "  cd $PROJECT_DIR"
echo "  docker-compose logs -f backend"
echo "=================================================="
