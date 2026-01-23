-- Telegram Auth Integration Guide
-- ================================

-- 1. TELEGRAM BOT SETUP
-- Token: 8506333771:AAGmnk_JmIOHDXv649nlv_5NZiNqrt88RfE
-- Bot: @timetotravelauth_bot
-- Webhook: https://titotr.ru/api/telegram/webhook

-- 2. ENVIRONMENT VARIABLES (добавить в docker run)
-- -e TELEGRAM_BOT_TOKEN="8506333771:AAGmnk_JmIOHDXv649nlv_5NZiNqrt88RfE"
-- -e JWT_SECRET="your-super-secret-jwt-key-change-in-production"

-- 3. ПРОЦЕСС ВХОДА:
-- 
-- Шаг 1: Пользователь вводит телефон в приложении
-- Шаг 2: Нажимает "Войти через Telegram"
-- Шаг 3: Открывается: t.me/timetotravelauth_bot?start=AUTH_79281234567
-- Шаг 4: Пользователь жмёт START
-- Шаг 5: Бот получает:
--    - telegram_id (число, например 123456789)
--    - first_name, last_name, username
--    - phone из параметра start
-- Шаг 6: Бот создаёт/обновляет запись в users
-- Шаг 7: Генерирует JWT токены
-- Шаг 8: Возвращает токены в приложение
-- Шаг 9: Приложение сохраняет токены в Secure Storage
-- Шаг 10: ГОТОВО! Пользователь залогинен

-- 4. API ENDPOINTS:

-- POST /auth/telegram/init
-- Body: {"phone": "+79281234567"}
-- Response: {"deepLink": "https://t.me/timetotravelauth_bot?start=AUTH_79281234567"}

-- GET /auth/telegram/status?session=AUTH_79281234567
-- Response (pending): {"status": "pending"}
-- Response (success): {"status": "success", "accessToken": "...", "refreshToken": "..."}

-- POST /auth/refresh
-- Body: {"refreshToken": "..."}
-- Response: {"accessToken": "...", "refreshToken": "..."}

-- POST /auth/logout
-- Headers: Authorization: Bearer <accessToken>
-- Response: {"success": true}

-- GET /auth/me
-- Headers: Authorization: Bearer <accessToken>
-- Response: {"user": {...}}

-- 5. WEBHOOK HANDLER:

-- POST /api/telegram/webhook
-- Получает обновления от Telegram
-- Обрабатывает команды:
--   /start AUTH_79281234567 - регистрация через deep link
--   /start - обычный старт

-- 6. JWT STRUCTURE:

-- Access Token (30 минут):
-- {
--   "userId": "uuid",
--   "telegramId": 123456789,
--   "role": "passenger",
--   "exp": timestamp
-- }

-- Refresh Token (вечный, пока не удалён из БД):
-- {
--   "sessionId": "uuid",
--   "exp": null
-- }

-- 7. DISPATCHER ACCESS:

-- Евгений (@nepeBo34uk, +79895342496)
-- telegram_id: 999999999 (временный, будет заменён при первом входе)
-- role: dispatcher

-- Чтобы обновить настоящий telegram_id:
-- 1. Евгений открывает бота
-- 2. Отправляет /start
-- 3. Бот проверяет username или телефон
-- 4. Если совпадает с диспетчером - обновляет telegram_id
