#!/bin/bash

echo "🤖 Настройка Telegram Auth для Time To Travel"
echo ""

TELEGRAM_BOT_TOKEN="8506333771:AAGmnk_JmIOHDXv649nlv_5NZiNqrt88RfE"
JWT_SECRET="TimeToTravel_JWT_Secret_2026_SecurE_Key_!@#"

echo "📋 Шаг 1: Копирование файлов на сервер..."

# Копируем Telegram сервис
scp backend/backend/lib/services/telegram_bot_service.dart titotr.ru:/tmp/

echo ""
echo "📋 Шаг 2: Обновление контейнера с переменными окружения..."

ssh titotr.ru << ENDSSH
# Останавливаем контейнер
docker stop timetotravel_backend

# Копируем файл в контейнер
docker cp /tmp/telegram_bot_service.dart timetotravel_backend:/app/lib/services/

# Пересоздаём с новыми переменными
docker rm timetotravel_backend

docker run -d \
  --name timetotravel_backend \
  --restart unless-stopped \
  -p 8080:8080 \
  --network timetotravel_network \
  -e DB_HOST=db \
  -e DB_PORT=5432 \
  -e DB_NAME=timetotravel \
  -e DB_USER=timetotravel \
  -e DB_PASSWORD="securE_PaSs2024!" \
  -e TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN" \
  -e JWT_SECRET="$JWT_SECRET" \
  backend-backend:latest

echo "✅ Контейнер перезапущен с Telegram переменными"
ENDSSH

echo ""
echo "📋 Шаг 3: Проверка запуска..."
sleep 3

ssh titotr.ru "docker logs timetotravel_backend --tail 10"

echo ""
echo "🎉 Готово!"
echo ""
echo "📱 Telegram Bot: @timetotravelauth_bot"
echo "🔑 Token: $TELEGRAM_BOT_TOKEN"
echo ""
echo "🔗 Deep Link пример:"
echo "   https://t.me/timetotravelauth_bot?start=AUTH_79281234567"
echo ""
echo "📖 Подробная документация: backend/TELEGRAM_AUTH_GUIDE.md"
