# 🎉 Telegram Auth - Backend ГОТОВ!

## ✅ Что сделано на бекенде:

### 1. **Модели обновлены** ✅
- `User` модель: добавлены `telegramId`, `firstName`, `lastName`, `username`
- Методы: `fullName`, `isDispatcher`
- Регенерирован `user.g.dart`

### 2. **UserRepository** ✅  
- `findByTelegramId()` - поиск по Telegram ID
- `upsertFromTelegram()` - создание/обновление из Telegram

### 3. **TelegramBotService** ✅
- `sendMessage()` - отправка сообщений
- `notifyNewOrder()` - уведомление о заказе
- `setWebhook()` - настройка webhook

### 4. **API Endpoints** ✅

#### `/telegram/webhook` (POST)
Принимает обновления от Telegram, обрабатывает `/start`

#### `/auth/telegram/init` (POST)
```json
POST /auth/telegram/init
Body: {"phone": "+79281234567"}
Response: {
  "deepLink": "https://t.me/timetotravelauth_bot?start=AUTH_79281234567",
  "authCode": "AUTH_79281234567"
}
```

#### `/auth/telegram/callback` (POST)  
```json
POST /auth/telegram/callback
Body: {"telegramId": 123456789}
Response: {
  "accessToken": "...",
  "refreshToken": "...",
  "user": {...}
}
```

## 📋 Что нужно сделать СЕЙЧАС:

### 1. **Деплой бекенда**

```bash
# Копируем все файлы
cd /Users/kirillpetrov/Projects/time-to-travel

# Упаковываем изменения
tar -czf telegram_auth_backend.tar.gz \
  backend/backend/lib/models/user.dart \
  backend/backend/lib/models/user.g.dart \
  backend/backend/lib/repositories/user_repository.dart \
  backend/backend/lib/services/telegram_bot_service.dart \
  backend/backend/routes/telegram/webhook.dart \
  backend/backend/routes/auth/telegram/init.dart \
  backend/backend/routes/auth/telegram/callback.dart

# Копируем на сервер
scp telegram_auth_backend.tar.gz titotr.ru:/tmp/

# На сервере
ssh titotr.ru
cd /tmp
tar -xzf telegram_auth_backend.tar.gz
docker cp lib timetotravel_backend:/app/
docker cp routes timetotravel_backend:/app/

# Пересоздаём контейнер с переменными
docker rm -f timetotravel_backend

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
  -e TELEGRAM_BOT_TOKEN="8506333771:AAGmnk_JmIOHDXv649nlv_5NZiNqrt88RfE" \
  -e JWT_SECRET="TimeToTravel_JWT_Secret_2026" \
  backend-backend:latest
```

### 2. **Тест бекенда**

```bash
# Тест init
curl -X POST https://titotr.ru/api/auth/telegram/init \
  -H "Content-Type: application/json" \
  -d '{"phone": "+79281234567"}'

# Откройте полученный deepLink в браузере
# Нажмите START в Telegram

# Тест callback (используйте свой telegram_id)
curl -X POST https://titotr.ru/api/auth/telegram/callback \
  -H "Content-Type: application/json" \
  -d '{"telegramId": 123456789}'
```

### 3. **Flutter приложение**

Теперь нужно создать:
1. Экран входа с полем телефона
2. Кнопку "Войти через Telegram"
3. Логику открытия deep link
4. Polling или WebSocket для получения токенов
5. Сохранение в Secure Storage
6. Auto-login при запуске

**Создаём Flutter часть?** 📱
