# Time to Travel - API Documentation

REST API для такси-сервиса на базе Dart Frog.

## 🔗 Base URL
```
Production: https://titotr.ru/api
Development: http://localhost:8080
```

## 📋 Содержание
- [Аутентификация](#authentication)
- [Пользователи](#users)
- [Маршруты](#routes)
- [Заказы](#orders)
- [Админ-панель](#admin)

---

## 🔐 Authentication

### POST /auth/register
Регистрация нового пользователя

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "name": "Иван Иванов",
  "phone": "+79001234567"
}
```

**Response 201:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Иван Иванов",
    "phone": "+79001234567",
    "role": "client",
    "isVerified": false,
    "isActive": true,
    "createdAt": "2026-01-20T12:00:00Z",
    "updatedAt": "2026-01-20T12:00:00Z"
  },
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

**Errors:**
- `400` - Некорректные данные (невалидный email, короткий пароль)
- `409` - Email уже используется

**Note:** Refresh token автоматически сохраняется в БД с истечением через 7 дней.

---

### POST /auth/login
Вход пользователя

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response 200:**
```json
{
  "user": { /* User object */ },
  "accessToken": "eyJhbGc...",
  "refreshToken": "eyJhbGc..."
}
```

**Errors:**
- `401` - Неверный email или пароль
- `403` - Аккаунт деактивирован

**Note:** При каждом входе создается новый refresh token и сохраняется в БД.

---

### GET /auth/me
Получить данные текущего пользователя

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response 200:**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Иван Иванов",
    "role": "client",
    "isVerified": true,
    "isActive": true
  }
}
```

**Errors:**
- `401` - Невалидный или истекший токен
- `404` - Пользователь не найден

---

### POST /auth/refresh
Обновить access token используя refresh token

**Request (Body):**
```json
{
  "refreshToken": "eyJhbGc..."
}
```

**OR Headers:**
```
Authorization: Bearer <refresh_token>
```

**Response 200:**
```json
{
  "accessToken": "eyJhbGc...",
  "user": {
    "id": "uuid",
    "email": "user@example.com",
    "name": "Иван Иванов",
    "role": "client"
  }
}
```

**Errors:**
- `400` - Refresh token не предоставлен или неверный тип токена
- `401` - Refresh token истек или был отозван
- `403` - Аккаунт деактивирован

**Note:** Access token обновляется, refresh token остается тем же.

---

### POST /auth/logout
Выход (отзыв refresh token)

**Request (Body):**
```json
{
  "refreshToken": "eyJhbGc..."
}
```

**OR Headers:**
```
Authorization: Bearer <refresh_token>
```

**Response 200:**
```json
{
  "message": "Logged out successfully",
  "revokedTokens": 1
}
```

**Note:** Даже если токен уже невалиден, возвращается успешный ответ.

---

### POST /auth/logout-all
Выйти со всех устройств (отозвать все refresh tokens пользователя)

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response 200:**
```json
{
  "message": "Logged out from all devices successfully",
  "revokedTokens": 5
}
```

**Errors:**
- `401` - Требуется авторизация через access token
- `404` - Пользователь не найден

**Note:** Отзывает все активные refresh tokens пользователя. Требует access token (не refresh).

---

## 🗺️ Routes

### GET /routes
Получить список маршрутов

**Query Parameters:**
- `from` - Город отправления (опционально)
- `to` - Город назначения (опционально)

**Examples:**
```
GET /routes
GET /routes?from=Ростов-на-Дону
GET /routes?from=Ростов-на-Дону&to=Таганрог
```

**Response 200:**
```json
{
  "routes": [
    {
      "id": "uuid",
      "fromCity": "Ростов-на-Дону",
      "toCity": "Таганрог",
      "price": 1500.00,
      "groupId": "uuid",
      "isActive": true,
      "createdAt": "2026-01-20T12:00:00Z",
      "updatedAt": "2026-01-20T12:00:00Z"
    }
  ],
  "count": 1
}
```

---

## 🚕 Orders

### GET /orders
Получить список заказов

**Headers:**
```
Authorization: Bearer <access_token> (опционально)
```

**Query Parameters:**
- `phone` - Телефон для поиска заказа
- `status` - Статус заказа (`pending`, `confirmed`, `in_progress`, `completed`, `cancelled`)
- `limit` - Максимальное количество результатов (по умолчанию 50)

**Examples:**
```
GET /orders (вернет заказы авторизованного пользователя)
GET /orders?phone=%2B79001234567
GET /orders?status=pending&limit=10
```

**Response 200:**
```json
{
  "orders": [
    {
      "id": "uuid",
      "orderId": "ORDER-2026-01-001",
      "userId": "uuid",
      "fromAddress": "ул. Пушкинская 1, Ростов-на-Дону",
      "toAddress": "ул. Ленина 10, Таганрог",
      "fromLat": 47.2357,
      "fromLon": 39.7015,
      "toLat": 47.2313,
      "toLon": 38.8972,
      "departureDate": "2026-01-25T10:00:00Z",
      "vehicleClass": "comfort",
      "finalPrice": 1500.00,
      "status": "pending",
      "passengers": [
        {
          "fullName": "Иван Иванов",
          "phone": "+79001234567",
          "isMain": true
        }
      ],
      "baggage": [
        {
          "size": "S",
          "count": 1,
          "price": 0
        }
      ],
      "pets": [],
      "createdAt": "2026-01-20T12:00:00Z",
      "updatedAt": "2026-01-20T12:00:00Z"
    }
  ],
  "count": 1
}
```

---

### POST /orders
Создать новый заказ

**Headers:**
```
Authorization: Bearer <access_token> (опционально)
```

**Request:**
```json
{
  "fromAddress": "ул. Пушкинская 1, Ростов-на-Дону",
  "toAddress": "ул. Ленина 10, Таганрог",
  "fromLat": 47.2357,
  "fromLon": 39.7015,
  "toLat": 47.2313,
  "toLon": 38.8972,
  "departureDate": "2026-01-25T10:00:00Z",
  "vehicleClass": "comfort",
  "finalPrice": 1500.00,
  "passengers": [
    {
      "fullName": "Иван Иванов",
      "phone": "+79001234567",
      "isMain": true
    }
  ],
  "baggage": [
    {
      "size": "S",
      "count": 1,
      "price": 0
    }
  ],
  "pets": []
}
```

**Response 201:**
```json
{
  "order": {
    "id": "uuid",
    "orderId": "ORDER-2026-01-001",
    "status": "pending",
    /* остальные поля заказа */
  }
}
```

**Errors:**
- `400` - Невалидные данные (пустые адреса, некорректная цена)
- `403` - Пользователь не найден или деактивирован

---

### GET /orders/:id
Получить заказ по ID

**Headers:**
```
Authorization: Bearer <access_token> (опционально)
```

**Response 200:**
```json
{
  "order": {
    "id": "uuid",
    "orderId": "ORDER-2026-01-001",
    /* полные данные заказа */
  }
}
```

**Errors:**
- `404` - Заказ не найден
- `403` - Нет доступа к заказу (только свои заказы или админ)

---

### PUT /orders/:id
Обновить заказ

**Headers:**
```
Authorization: Bearer <access_token> (обязательно)
```

**Request:**
```json
{
  "fromAddress": "Новый адрес отправления",
  "toAddress": "Новый адрес прибытия",
  "departureDate": "2026-01-26T14:00:00Z",
  "passengers": [ /* обновленный список */ ]
}
```

**Response 200:**
```json
{
  "order": {
    "id": "uuid",
    /* обновленные данные заказа */
  }
}
```

**Errors:**
- `401` - Требуется авторизация
- `403` - Нет доступа (не владелец и не админ)
- `404` - Заказ не найден
- `400` - Нельзя редактировать завершенный/отмененный заказ

---

### DELETE /orders/:id
Отменить заказ

**Headers:**
```
Authorization: Bearer <access_token> (обязательно)
```

**Response 200:**
```json
{
  "message": "Order cancelled successfully",
  "order": {
    "id": "uuid",
    "status": "cancelled",
    /* данные отмененного заказа */
  }
}
```

**Errors:**
- `401` - Требуется авторизация
- `403` - Нет доступа
- `404` - Заказ не найден
- `400` - Заказ уже завершен или отменен

---

### PATCH /orders/:id/status
Обновить статус заказа (только админы и водители)

**Headers:**
```
Authorization: Bearer <access_token> (обязательно)
```

**Request:**
```json
{
  "status": "confirmed"
}
```

**Допустимые переходы:**
- `pending` → `confirmed`, `cancelled`
- `confirmed` → `in_progress`, `cancelled`
- `in_progress` → `completed`, `cancelled`

**Ограничения:**
- Водители не могут отменять заказы
- Нельзя изменить статус завершенного/отмененного заказа

**Response 200:**
```json
{
  "message": "Order status updated successfully",
  "order": {
    "id": "uuid",
    "status": "confirmed",
    /* данные заказа */
  }
}
```

**Errors:**
- `401` - Требуется авторизация
- `403` - Доступ запрещен (требуется роль admin или driver)
- `404` - Заказ не найден
- `400` - Невалидный переход статуса

---

## 👤 Admin Panel

### POST /admin/routes
Создать новый маршрут (только админы)

**Headers:**
```
Authorization: Bearer <access_token> (обязательно, роль admin)
```

**Request:**
```json
{
  "fromCity": "Ростов-на-Дону",
  "toCity": "Краснодар",
  "price": 2500.00,
  "groupId": "uuid" (опционально)
}
```

**Response 201:**
```json
{
  "message": "Route created successfully",
  "route": {
    "id": "uuid",
    "fromCity": "Ростов-на-Дону",
    "toCity": "Краснодар",
    "price": 2500.00,
    "isActive": true,
    "createdAt": "2026-01-20T12:00:00Z",
    "updatedAt": "2026-01-20T12:00:00Z"
  }
}
```

**Errors:**
- `401` - Требуется авторизация
- `403` - Требуется роль admin
- `400` - Невалидные данные

---

### PUT /admin/routes/:id
Обновить маршрут (только админы)

**Headers:**
```
Authorization: Bearer <access_token> (обязательно, роль admin)
```

**Request:**
```json
{
  "fromCity": "Ростов-на-Дону",
  "toCity": "Краснодар",
  "price": 2800.00,
  "isActive": true
}
```

**Response 200:**
```json
{
  "message": "Route updated successfully",
  "route": {
    "id": "uuid",
    /* обновленные данные */
  }
}
```

**Errors:**
- `401` - Требуется авторизация
- `403` - Требуется роль admin
- `404` - Маршрут не найден

---

### DELETE /admin/routes/:id
Удалить маршрут (только админы)

**Headers:**
```
Authorization: Bearer <access_token> (обязательно, роль admin)
```

**Response 200:**
```json
{
  "message": "Route deleted successfully",
  "routeId": "uuid"
}
```

**Errors:**
- `401` - Требуется авторизация
- `403` - Требуется роль admin
- `404` - Маршрут не найден

---

### GET /admin/stats
Получить статистику по заказам (только админы)

**Headers:**
```
Authorization: Bearer <access_token> (обязательно, роль admin)
```

**Response 200:**
```json
{
  "stats": {
    "totalOrders": 150,
    "pendingOrders": 12,
    "confirmedOrders": 8,
    "inProgressOrders": 5,
    "completedOrders": 120,
    "cancelledOrders": 5,
    "totalRevenue": 450000.00
  },
  "timestamp": "2026-01-20T12:00:00Z"
}
```

**Errors:**
- `401` - Требуется авторизация
- `403` - Требуется роль admin

---

## 📊 Response Status Codes

| Код | Описание |
|-----|----------|
| 200 | OK - Запрос выполнен успешно |
| 201 | Created - Ресурс создан |
| 400 | Bad Request - Невалидные данные |
| 401 | Unauthorized - Требуется авторизация |
| 403 | Forbidden - Доступ запрещен |
| 404 | Not Found - Ресурс не найден |
| 409 | Conflict - Конфликт (например, email уже существует) |
| 500 | Internal Server Error - Внутренняя ошибка сервера |

---

## 🔑 JWT Tokens

### Access Token
- **Срок действия:** 1 час
- **Использование:** Передается в заголовке `Authorization: Bearer <token>`
- **Содержит:** `userId`, `type: "access"`

### Refresh Token
- **Срок действия:** 7 дней
- **Использование:** Для получения нового access token (TODO: реализовать `/auth/refresh`)
- **Содержит:** `userId`, `type: "refresh"`

---

## 🧪 Testing

### Тестовые аккаунты (только для development):
```
Admin:
  email: admin@titotr.ru
  password: Test123!
  
Driver:
  email: driver@titotr.ru
  password: Test123!
  
Client:
  email: client@example.com
  password: Test123!
```

### Example Request (cURL):
```bash
# Регистрация
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User",
    "phone": "+79001234567"
  }'

# Вход
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'

# Получить профиль
curl -X GET http://localhost:8080/auth/me \
  -H "Authorization: Bearer <access_token>"

# Создать заказ
curl -X POST http://localhost:8080/orders \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "fromAddress": "ул. Пушкинская 1",
    "toAddress": "ул. Ленина 10",
    "fromLat": 47.2357,
    "fromLon": 39.7015,
    "toLat": 47.2313,
    "toLon": 38.8972,
    "departureDate": "2026-01-25T10:00:00Z",
    "vehicleClass": "comfort",
    "finalPrice": 1500.00,
    "passengers": [
      {
        "fullName": "Test User",
        "phone": "+79001234567",
        "isMain": true
      }
    ],
    "baggage": [],
    "pets": []
  }'
```

---

## 📝 TODO
- [x] Реализовать `POST /auth/refresh` для обновления access token
- [x] Реализовать `POST /auth/logout` для инвалидации refresh token
- [x] Реализовать `POST /auth/logout-all` для выхода со всех устройств
- [ ] Добавить пагинацию для GET /orders
- [ ] Добавить фильтрацию по датам для GET /orders
- [ ] Реализовать WebSocket для real-time обновлений статуса заказа
- [ ] Добавить rate limiting
- [ ] Добавить логирование запросов
- [ ] Настроить CORS для production
- [ ] Написать интеграционные тесты для auth endpoints
