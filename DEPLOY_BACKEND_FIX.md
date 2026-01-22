# Деплой исправления backend на production

## Проблема
Backend падает с 500 ошибкой при создании заказа потому что `CreateOrderDto` требовал обязательные поля (координаты, расчёты) которые приложение не отправляет.

## Решение
Обновлён `CreateOrderDto` - координаты и расчёты теперь опциональны.

## Изменённые файлы
- `backend/backend/lib/models/order.dart` - обновлён `CreateOrderDto`
- `backend/backend/lib/models/order.g.dart` - регенерирован через build_runner

## Как задеплоить на production:

### Вариант 1: Через SSH (если есть доступ)

```bash
# 1. Подключиться к серверу
ssh user@titotr.ru

# 2. Перейти в директорию backend
cd /path/to/backend

# 3. Обновить код из git
git pull

# 4. Пересобрать
dart run build_runner build --delete-conflicting-outputs

# 5. Перезапустить backend
systemctl restart backend
# или
pm2 restart backend
```

### Вариант 2: Через Docker (если используется)

```bash
# На локальной машине
cd /Users/kirillpetrov/Projects/time-to-travel/backend/backend

# Закоммитить изменения
git add lib/models/order.dart lib/models/order.g.dart
git commit -m "fix: сделал CreateOrderDto более гибким - координаты опциональны"
git push

# На сервере
ssh user@titotr.ru
cd /path/to/backend
git pull
docker-compose down
docker-compose up -d --build
```

### Вариант 3: Скопировать файлы вручную

Если нет git на сервере:

```bash
# Скопировать изменённые файлы на сервер
scp /Users/kirillpetrov/Projects/time-to-travel/backend/backend/lib/models/order.dart user@titotr.ru:/path/to/backend/lib/models/
scp /Users/kirillpetrov/Projects/time-to-travel/backend/backend/lib/models/order.g.dart user@titotr.ru:/path/to/backend/lib/models/

# На сервере перезапустить
ssh user@titotr.ru "systemctl restart backend"
```

## Тестирование после деплоя

```bash
# Проверить что backend работает
curl https://titotr.ru/api/health

# Попробовать создать заказ
curl -X POST https://titotr.ru/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "fromAddress": "Донецк",
    "toAddress": "Ростов",
    "departureTime": "2026-01-23T06:00:00.000Z",
    "passengerCount": 2,
    "basePrice": 4000,
    "totalPrice": 4000,
    "finalPrice": 4000
  }'

# Должен вернуть 201 Created вместо 500
```

## Альтернатива: Если нет доступа к серверу

Просто закоммитьте изменения в git:

```bash
cd /Users/kirillpetrov/Projects/time-to-travel
git add backend/backend/lib/models/order.dart backend/backend/lib/models/order.g.dart
git commit -m "fix: упростил CreateOrderDto - координаты и расчёты опциональны"
git push
```

И попросите того кто управляет сервером обновить код и перезапустить backend.
