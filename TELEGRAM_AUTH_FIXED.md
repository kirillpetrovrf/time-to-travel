# ✅ Telegram Auth - Проблема Решена

## 🐛 Проблема

При нажатии на кнопку "Войти через Telegram" в приложении возникала ошибка:

```
HandshakeException: Connection terminated during handshake
```

## 🔍 Причина

**Nginx контейнер не был запущен**, из-за чего:
- ❌ HTTPS соединения не работали
- ❌ SSL сертификаты не использовались
- ❌ Приложение не могло подключиться к `https://titotr.ru/api/auth/telegram/init`

## ✅ Решение

### 1. Запущен Backend с правильным именем
```bash
docker run -d --name backend \
  --network timetotravel_network \
  -p 8080:8080 \
  -e DATABASE_URL=postgresql://ttadmin:ttadmin123@timetotravel_postgres:5432/timetotravel \
  backend-backend:latest
```

### 2. Запущен Nginx с SSL
```bash
docker run -d --name timetotravel_nginx \
  --network timetotravel_network \
  -p 80:80 -p 443:443 \
  -v /root/time-to-travel/backend/nginx/nginx.conf:/etc/nginx/nginx.conf:ro \
  -v /root/time-to-travel/backend/nginx/conf.d:/etc/nginx/conf.d:ro \
  -v /root/time-to-travel/backend/certbot/conf:/etc/letsencrypt:ro \
  -v /root/time-to-travel/backend/certbot/www:/var/www/certbot:ro \
  nginx:alpine
```

### 3. Отключены дублирующиеся конфигурации Nginx
```bash
cd /root/time-to-travel/backend/nginx/conf.d
mv titotr.conf titotr.conf.disabled
mv titotr_clean.conf titotr_clean.conf.disabled
mv titotr_with_telegram.conf titotr_with_telegram.conf.disabled
# Активна только titotr-https.conf
```

## 🎯 Результат

### ✅ SSL Сертификат
- **Домен**: titotr.ru
- **Срок действия**: до 23 апреля 2026
- **Протокол**: TLSv1.3
- **Статус**: Валиден ✅

### ✅ API Endpoints
```bash
# Health Check
curl https://titotr.ru/health
# Ответ: {"status":"ok","service":"Time to Travel API","version":"1.0.0"}

# Telegram Auth Init
curl -X POST https://titotr.ru/api/auth/telegram/init \
  -H "Content-Type: application/json" \
  -d '{"phone":"+79504455444"}'
# Ответ: {"deepLink":"https://t.me/timetotravelauth_bot?start=AUTH_79504455444",...}
```

### ✅ Запущенные Контейнеры
```
backend               - http://backend:8080 (внутри сети)
timetotravel_nginx    - http://titotr.ru:80 → https://titotr.ru:443
timetotravel_postgres - PostgreSQL база данных
```

## 📱 Следующие Шаги

1. **Протестируйте авторизацию на телефоне**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Нажмите "Войти через Telegram"**
   - Должен открыться Telegram с deep link
   - Бот отправит код подтверждения

3. **Проверьте логи на сервере** (если нужно):
   ```bash
   ssh root@titotr.ru "docker logs backend -f"
   ssh root@titotr.ru "docker logs timetotravel_nginx -f"
   ```

## 🚨 Важные Замечания

### ⚠️ Redis Контейнер
Redis контейнер имеет проблемы с конфигурацией:
```
requirepass "--maxmemory" "256mb" wrong number of arguments
```

**Временное решение**: Backend запущен без Redis.  
**TODO**: Исправить docker-compose.yml (секция redis - некорректный формат аргументов).

### ⚠️ Автозапуск Контейнеров
Backend и Nginx запущены вручную (не через docker-compose).  
При перезагрузке сервера нужно будет запустить их заново.

**Рекомендация**: Исправить docker-compose.yml и использовать `docker compose up -d`.

## 📊 Текущая Архитектура

```
[Flutter App на Android] 
    ↓ HTTPS
[Nginx (443)] → [Backend (8080)] → [PostgreSQL]
    ↓
[SSL Cert от Let's Encrypt]
```

## 🔧 Полезные Команды

```bash
# Проверить статус контейнеров
ssh root@titotr.ru "docker ps"

# Перезапустить Nginx
ssh root@titotr.ru "docker restart timetotravel_nginx"

# Перезапустить Backend
ssh root@titotr.ru "docker restart backend"

# Проверить SSL сертификат
curl -v https://titotr.ru/health 2>&1 | grep -E "expire|SSL"

# Просмотр логов
ssh root@titotr.ru "docker logs backend --tail 50"
ssh root@titotr.ru "docker logs timetotravel_nginx --tail 50"
```

---

**Дата**: 26 января 2026  
**Статус**: ✅ Исправлено  
**Тестирование**: Готово к тестированию на реальном устройстве
