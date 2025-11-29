# 🚀 Quick Start: Deploy Backend API

## 1️⃣ Установите Redis

### macOS:
```bash
brew install redis
brew services start redis
```

### Ubuntu/Debian:
```bash
sudo apt update
sudo apt install redis-server
sudo systemctl start redis
```

### Windows:
Скачайте с https://github.com/microsoftarchive/redis/releases

Проверьте:
```bash
redis-cli ping
# Должно вернуть: PONG
```

---

## 2️⃣ Установите Node.js зависимости

```bash
npm install
```

---

## 3️⃣ Запустите Backend

```bash
npm start
```

Увидите:
```
🚖 ============================================
🚖  Taxi Tracking Backend API
🚖 ============================================
🌐 Server running on http://localhost:3000
✅ Ready to accept requests!
```

---

## 4️⃣ Настройте Flutter приложение

Откройте `lib/services/trip_api_service.dart` и измените `BASE_URL`:

### Для Android Emulator:
```dart
static const String BASE_URL = 'http://10.0.2.2:3000/api';
```

### Для iOS Simulator:
```dart
static const String BASE_URL = 'http://localhost:3000/api';
```

### Для реального устройства:
```dart
static const String BASE_URL = 'http://192.168.1.XXX:3000/api';
// Замените 192.168.1.XXX на ваш локальный IP
// Узнать IP: ifconfig (macOS/Linux) или ipconfig (Windows)
```

---

## 5️⃣ Тестирование API

### Создать поездку:
```bash
curl -X POST http://localhost:3000/api/trips \
  -H "Content-Type: application/json" \
  -d '{
    "from": {"latitude": 55.751244, "longitude": 37.618423},
    "to": {"latitude": 55.753215, "longitude": 37.622504},
    "driverId": "driver123",
    "customerId": "customer456"
  }'
```

Ответ:
```json
{"tripId": "trip_1234567890_abc123"}
```

### Отправить локацию:
```bash
curl -X POST http://localhost:3000/api/trips/trip_1234567890_abc123/location \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 55.751500,
    "longitude": 37.618700,
    "bearing": 45.5,
    "speed": 10.2
  }'
```

### Получить локацию:
```bash
curl http://localhost:3000/api/trips/trip_1234567890_abc123/location
```

Ответ:
```json
{
  "latitude": 55.751500,
  "longitude": 37.618700,
  "bearing": 45.5,
  "speed": 10.2,
  "accuracy": 0,
  "timestamp": "2024-01-20T10:30:45.123Z"
}
```

---

## 🎯 Production Deployment

### Option 1: Heroku
```bash
heroku create taxi-tracking-backend
heroku addons:create heroku-redis:mini
git push heroku main
```

### Option 2: AWS EC2
1. Создайте EC2 instance
2. Установите Node.js и Redis
3. Клонируйте репозиторий
4. `npm install && npm start`
5. Настройте Security Group для порта 3000

### Option 3: DigitalOcean
1. Создайте Droplet (Ubuntu)
2. Установите Node.js: `curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -`
3. `sudo apt install nodejs redis-server`
4. Запустите: `npm start`

После деплоя обновите `BASE_URL` в `trip_api_service.dart`:
```dart
static const String BASE_URL = 'https://your-domain.com/api';
```

---

## 📊 Мониторинг

### Просмотр всех ключей в Redis:
```bash
redis-cli KEYS "trip:*"
```

### Просмотр данных поездки:
```bash
redis-cli GET "trip:trip_1234567890_abc123"
```

### Просмотр логов сервера:
Все запросы логируются в консоль с emoji:
- ✅ Trip created
- 🚕 Trip started
- 📍 Location updated
- 📥 Location requested
- ❌ Trip cancelled

---

## 🔧 Troubleshooting

### Redis не запускается:
```bash
# Проверьте статус
redis-cli ping

# Перезапустите
brew services restart redis   # macOS
sudo systemctl restart redis  # Linux
```

### Порт 3000 занят:
Измените в `server.js`:
```javascript
const PORT = 8080; // Вместо 3000
```

### CORS ошибки:
CORS уже настроен в `server.js`, но если проблемы:
```javascript
app.use(cors({
  origin: '*', // Для разработки
  // origin: 'https://yourdomain.com' // Для продакшна
}));
```

---

✅ **Готово!** Backend развернут и готов принимать запросы от Flutter приложения.
