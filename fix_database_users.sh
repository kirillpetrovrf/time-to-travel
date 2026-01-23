#!/bin/bash

echo "🔧 Исправление пользователей и базы данных PostgreSQL..."
echo ""

# Подключаемся к PostgreSQL и создаём правильного пользователя
echo "📝 Создаём пользователя 'timetotravel' с паролем 'securE_PaSs2024!'..."

ssh titotr.ru << 'ENDSSH'
docker exec timetotravel_postgres psql -U timetotravel_user -d timetotravel -c "
-- Создаём нового пользователя timetotravel
CREATE USER timetotravel WITH PASSWORD 'securE_PaSs2024!';

-- Даём все права на базу данных
GRANT ALL PRIVILEGES ON DATABASE timetotravel TO timetotravel;

-- Даём права на все таблицы в схеме public
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO timetotravel;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO timetotravel;

-- Даём права на будущие таблицы
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO timetotravel;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO timetotravel;

-- Проверяем что создалось
SELECT usename, usecreatedb, usesuper FROM pg_user WHERE usename = 'timetotravel';
"

echo ""
echo "✅ Пользователь создан!"
echo ""
echo "📋 Список пользователей в PostgreSQL:"
docker exec timetotravel_postgres psql -U timetotravel_user -d timetotravel -c "\du"

echo ""
echo "📋 Список баз данных:"
docker exec timetotravel_postgres psql -U timetotravel_user -d timetotravel -c "\l"

ENDSSH

echo ""
echo "🔄 Перезапускаем бекенд с правильными учётными данными..."

ssh titotr.ru 'docker rm -f timetotravel_backend && docker run -d --name timetotravel_backend --restart unless-stopped -p 8080:8080 --network timetotravel_network -e DB_HOST=db -e DB_PORT=5432 -e DB_NAME=timetotravel -e DB_USER=timetotravel -e DB_PASSWORD="securE_PaSs2024!" backend-backend:latest'

echo ""
echo "⏳ Ждём 3 секунды для запуска..."
sleep 3

echo ""
echo "📋 Проверяем логи бекенда..."
ssh titotr.ru "docker logs timetotravel_backend 2>&1 | tail -20"

echo ""
echo "🧪 Тестируем API..."
curl -s "https://titotr.ru/api/orders" | head -20

echo ""
echo "✅ Готово!"
