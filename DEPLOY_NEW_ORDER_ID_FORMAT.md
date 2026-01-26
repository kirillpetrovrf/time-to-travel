# 🚀 Инструкция по применению нового формата order_id

**Дата**: 26 января 2026  
**Изменение**: Формат номера заказа

---

## 📋 Что изменилось

### Старый формат:
```
ORDER-2026-01-391
```

### Новый формат:
```
2026-01-26-391-G  (Групповая)
2026-01-26-392-I  (Индивидуальная)
2026-01-26-393-S  (Свободная)
```

**Структура**: `YYYY-MM-DD-XXX-T`
- `YYYY-MM-DD` - дата создания заказа
- `XXX` - порядковый номер (001-999)
- `T` - тип поездки:
  - `G` - **G**roup (Групповая)
  - `I` - **I**ndividual (Индивидуальная)
  - `S` - **S**vobodnaya (Свободная/CustomRoute)

---

## 🔧 Шаги деплоя на titotr.ru

### 1. SSH подключение к серверу

```bash
ssh root@titotr.ru
cd /opt/app
```

### 2. Бэкап базы данных (ОБЯЗАТЕЛЬНО!)

```bash
# Создаём бэкап
docker exec postgres pg_dump -U timetotravel_user timetotravel > /root/backup_before_order_id_migration_$(date +%Y%m%d_%H%M%S).sql

# Проверяем что бэкап создан
ls -lh /root/backup_before_order_id_migration_*
```

### 3. Обновление кода backend

```bash
# Останавливаем backend
docker compose stop backend

# Обновляем код из GitHub
git pull origin main

# Пересобираем backend
docker compose build backend

# Запускаем backend
docker compose up -d backend

# Проверяем логи
docker compose logs -f backend --tail=50
```

### 4. Применение миграции БД

```bash
# Подключаемся к PostgreSQL
docker exec -it postgres psql -U timetotravel_user -d timetotravel

# Выполняем миграцию
\i /app/database/migrations/004_update_order_id_format.sql

# Проверяем результат
SELECT order_id, trip_type, status 
FROM orders 
ORDER BY created_at DESC 
LIMIT 10;

# Должны увидеть новый формат: 2026-01-26-XXX-G/I/S

# Проверяем статистику
SELECT 
  COUNT(*) as total_orders,
  COUNT(CASE WHEN order_id LIKE 'ORDER-%' THEN 1 END) as old_format,
  COUNT(CASE WHEN order_id ~ '^\d{4}-\d{2}-\d{2}-\d{3}-[GIS]$' THEN 1 END) as new_format
FROM orders;

# Выходим из psql
\q
```

**Альтернативный способ** (если файл не монтирован):

```bash
# Копируем SQL файл в контейнер
docker cp backend/database/migrations/004_update_order_id_format.sql postgres:/tmp/

# Выполняем миграцию
docker exec -it postgres psql -U timetotravel_user -d timetotravel -f /tmp/004_update_order_id_format.sql
```

### 5. Тестирование нового формата

```bash
# Создаём тестовый заказ (Групповая поездка)
curl -X POST https://titotr.ru/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "fromAddress": "Тест Групповая",
    "toAddress": "Тест Групповая Назначение",
    "fromLat": 47.2357,
    "fromLon": 39.7015,
    "toLat": 47.2313,
    "toLon": 38.8972,
    "departureDate": "2026-01-27T10:00:00Z",
    "vehicleClass": "comfort",
    "finalPrice": 2000.00,
    "tripType": "group",
    "passengers": [{"fullName": "Тест G", "phone": "+79001111111", "isMain": true}],
    "baggage": [],
    "pets": []
  }'

# Ожидаемый результат orderId: 2026-01-26-XXX-G

# Создаём тестовый заказ (Индивидуальная поездка)
curl -X POST https://titotr.ru/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "tripType": "individual",
    "fromAddress": "Тест Individual",
    "toAddress": "Тест Individual Назначение",
    "finalPrice": 8000.00,
    "passengers": [{"fullName": "Тест I", "phone": "+79002222222", "isMain": true}]
  }'

# Ожидаемый результат orderId: 2026-01-26-XXX-I

# Создаём тестовый заказ (Свободная поездка)
curl -X POST https://titotr.ru/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "tripType": "customRoute",
    "fromAddress": "Тест Custom",
    "toAddress": "Тест Custom Назначение",
    "finalPrice": 4000.00,
    "passengers": [{"fullName": "Тест S", "phone": "+79003333333", "isMain": true}]
  }'

# Ожидаемый результат orderId: 2026-01-26-XXX-S
```

### 6. Проверка через API

```bash
# Получить все заказы
curl -s https://titotr.ru/api/orders | jq '.orders[] | {orderId, tripType, status}'

# Проверить что новые заказы имеют правильный формат:
# - Дата соответствует сегодняшней (2026-01-26)
# - Суффикс соответствует типу (G/I/S)
```

---

## ✅ Критерии успеха

После деплоя должно быть:

1. **Backend работает** - `docker ps` показывает running
2. **Старые заказы обновлены** - все ORDER-* заказы имеют новый формат
3. **Новые заказы создаются** - формат `2026-01-26-XXX-G/I/S`
4. **Типы корректны**:
   - Групповые → суффикс `G`
   - Индивидуальные → суффикс `I`
   - Свободные → суффикс `S`

---

## 🔄 Откат (если что-то пошло не так)

```bash
# Останавливаем backend
docker compose stop backend

# Восстанавливаем БД из бэкапа
docker exec -i postgres psql -U timetotravel_user timetotravel < /root/backup_before_order_id_migration_YYYYMMDD_HHMMSS.sql

# Откатываем код
git checkout HEAD~1

# Пересобираем backend
docker compose build backend
docker compose up -d backend
```

---

## 📊 Проверка результата

После успешного деплоя:

```bash
# Подключиться к БД
docker exec -it postgres psql -U timetotravel_user -d timetotravel

# Проверить примеры
SELECT order_id, trip_type, created_at, status
FROM orders
ORDER BY created_at DESC
LIMIT 20;
```

**Ожидаемые результаты**:
```
       order_id        | trip_type   | created_at          | status
-----------------------+-------------+---------------------+---------
2026-01-26-123-G       | group       | 2026-01-26 14:30:00 | pending
2026-01-26-124-I       | individual  | 2026-01-26 14:31:00 | pending
2026-01-26-125-S       | customRoute | 2026-01-26 14:32:00 | pending
```

---

## 💡 Полезные команды

```bash
# Мониторинг логов backend
docker compose logs -f backend

# Перезапуск backend
docker compose restart backend

# Проверка health
curl https://titotr.ru/health

# Подключение к БД
docker exec -it postgres psql -U timetotravel_user -d timetotravel
```

---

**Готово к деплою!** 🚀

После выполнения всех шагов новый формат номеров заказов будет активен.
