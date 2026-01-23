# ✅ ИСПРАВЛЕНО: Пассажиры, багаж и животные теперь отображаются в кабинете диспетчера

## 📋 Проблема

Вы правы! В логах видно что приложение **отправляло** полные данные:

```json
"metadata": {
  "passengers": [
    {"type":"adult"},
    {"type":"adult"},
    {"type":"adult"},
    {"type":"child"}
  ],
  "baggage": [
    {"size":"s","quantity":2,"pricePerExtraItem":500.0},
    {"size":"m","quantity":3,"pricePerExtraItem":1000.0},
    {"size":"l","quantity":2,"pricePerExtraItem":2000.0}
  ],
  "pets": [
    {"category":"upTo5kgWithoutCarrier","breed":"Животное до 5 кг без переноски","cost":1000.0}
  ]
}
```

Но backend **возвращал** `null`:
```json
"passengers": null,
"baggage": null,
"pets": null
```

## 🔍 Причина

Backend модели `Passenger`, `Baggage` и `Pet` **не соответствовали** данным из приложения:

### Backend (СТАРОЕ):
```dart
class Passenger {
  final String name;    // Требовал имя
  final int? age;       // Возраст в годах
}

class Baggage {
  final String type;    // 'suitcase', 'bag', 'box'
  final String size;    // 'small', 'medium', 'large'
  final int count;      // Количество
}

class Pet {
  final String type;    // 'dog', 'cat', 'other'
  final String? name;
  final double? weight;
}
```

### App (РЕАЛЬНЫЕ ДАННЫЕ):
```dart
class PassengerInfo {
  final PassengerType type;  // adult или child
  final ChildSeatType? seatType;  // cradle/seat/booster/none
  final bool useOwnSeat;
  final int? ageMonths;  // Возраст в месяцах!
}

class BaggageItem {
  final BaggageSize size;  // s/m/l/custom
  final int quantity;  // От 1 до 10
  final double pricePerExtraItem;
  final String? customDescription;
}

class PetInfo {
  final PetCategory category;  // upTo5kgWithCarrier/upTo5kgWithoutCarrier/over6kg
  final String breed;  // Описание животного
  final double cost;  // Стоимость перевозки
  final String? description;
}
```

## ✅ Что исправлено

### 1. **Backend - Passenger модель**

```dart
class Passenger {
  final String? name;          // Опционально
  final int? age;              // Опционально - общий возраст
  final String type;           // 'adult' или 'child' - ОБЯЗАТЕЛЬНО
  final String? seatType;      // Для детей: 'cradle', 'seat', 'booster', 'none'
  final bool? useOwnSeat;      // Своё кресло (true) или водителя (false)
  final int? ageMonths;        // Возраст в месяцах для детей
}
```

**Типы детских кресел:**
- `cradle` - Люлька (0-12 месяцев)
- `seat` - Кресло (1-3 года)
- `booster` - Бустер (4-7 лет)
- `none` - Без кресла (8+ лет, 120+ см)

### 2. **Backend - Baggage модель**

```dart
class Baggage {
  final String? type;              // Старый формат - опционально
  final String size;               // 's', 'm', 'l', 'custom' - ОБЯЗАТЕЛЬНО
  final int? count;                // Старый формат - опционально
  final int quantity;              // Количество единиц (1-10) - ОБЯЗАТЕЛЬНО
  final double? pricePerExtraItem; // Цена за дополнительную единицу
  final String? customDescription; // Для size='custom'
}
```

**Размеры багажа:**
- `s` - Рюкзак (30×40×20 см) - до 10 кг
- `m` - Спортивная сумка (50×60×25 см) - до 20 кг
- `l` - Чемодан (70×80×30 см) - до 32 кг
- `custom` - Нестандартный груз (гитара, микроволновка и т.д.)

**Правила бесплатного багажа:**
- На каждого взрослого пассажира: 2 места размера S бесплатно
- Дополнительный багаж: согласно pricePerExtraItem (500₽/1000₽/2000₽)

### 3. **Backend - Pet модель**

```dart
class Pet {
  final String? type;        // Старый формат - опционально
  final String? name;        // Старый формат - опционально
  final double? weight;      // Старый формат - опционально
  final String category;     // 'upTo5kgWithCarrier', 'upTo5kgWithoutCarrier', 'over6kg' - ОБЯЗАТЕЛЬНО
  final String breed;        // Описание животного - ОБЯЗАТЕЛЬНО
  final double cost;         // Стоимость перевозки - ОБЯЗАТЕЛЬНО
  final String? description; // Дополнительное описание
}
```

**Категории животных:**
- `upTo5kgWithCarrier` - До 5 кг в переноске - **БЕСПЛАТНО**
- `upTo5kgWithoutCarrier` - До 5 кг без переноски - **1000₽**
- `over6kg` - Свыше 6 кг - **2000₽** + **ОБЯЗАТЕЛЬНО** индивидуальный трансфер (8000₽)

### 4. **App - Отправка данных как отдельные поля**

**БЫЛО** (только в metadata):
```dart
final createdOrder = await _ordersApi.createOrder(
  fromAddress: '...',
  toAddress: '...',
  metadata: {
    'passengers': [...],
    'baggage': [...],
    'pets': [...],
  },
);
```

**СТАЛО** (и в metadata, и как отдельные поля):
```dart
final createdOrder = await _ordersApi.createOrder(
  fromAddress: '...',
  toAddress: '...',
  metadata: metadata,  // Для совместимости
  passengers: passengersList,  // ✅ Отдельное поле
  baggage: baggageList,        // ✅ Отдельное поле
  pets: petsList,              // ✅ Отдельное поле
);
```

### 5. **App - Чтение данных из ApiOrder**

ApiOrder теперь содержит:
```dart
class ApiOrder {
  // ...
  final List<Map<String, dynamic>>? passengers;
  final List<Map<String, dynamic>>? baggage;
  final List<Map<String, dynamic>>? pets;
}
```

BookingService конвертирует их в модели приложения:
```dart
// Конвертируем passengers из API
for (final p in apiOrder.passengers!) {
  passengers.add(PassengerInfo(
    type: PassengerType.adult/child,
    seatType: ChildSeatType.cradle/seat/booster/none,
    useOwnSeat: true/false,
    ageMonths: 60,
  ));
}

// Конвертируем baggage из API
for (final b in apiOrder.baggage!) {
  baggage.add(BaggageItem(
    size: BaggageSize.s/m/l/custom,
    quantity: 2,
    pricePerExtraItem: 500.0,
  ));
}

// Конвертируем pets из API
for (final p in apiOrder.pets!) {
  pets.add(PetInfo(
    category: PetCategory.upTo5kgWithCarrier,
    breed: 'Кот Пушок',
    cost: 0.0,
  ));
}
```

## 📊 Результат

### Тестовый заказ (curl):
```bash
curl -X POST "https://titotr.ru/api/orders" \
-d '{
  "passengers": [
    {"type": "adult"},
    {"type": "adult"},
    {"type": "child", "seatType": "booster", "ageMonths": 60}
  ],
  "baggage": [
    {"size": "s", "quantity": 2, "pricePerExtraItem": 500},
    {"size": "l", "quantity": 1, "pricePerExtraItem": 2000}
  ],
  "pets": [
    {"category": "upTo5kgWithCarrier", "breed": "Кот Пушок", "cost": 0}
  ]
}'
```

### Backend возвращает:
```json
{
  "order": {
    "orderId": "ORDER-2026-01-79",
    "passengers": [
      {"type":"adult"},
      {"type":"adult"},
      {"type":"child", "seatType":"booster", "ageMonths":60}
    ],
    "baggage": [
      {"size":"s", "quantity":2, "pricePerExtraItem":500.0},
      {"size":"l", "quantity":1, "pricePerExtraItem":2000.0}
    ],
    "pets": [
      {"category":"upTo5kgWithCarrier", "breed":"Кот Пушок", "cost":0.0}
    ],
    "tripType": "group",
    "direction": "donetskToRostov",
    "finalPrice": 9500.0
  }
}
```

✅ **Все данные сохраняются и возвращаются!**

## 🎯 Что теперь отображается в кабинете диспетчера

### 👥 Пассажиры:
- **Взрослые**: Количество
- **Дети**: 
  - Возраст в месяцах
  - Тип автокресла (люлька/кресло/бустер/без кресла)
  - Своё кресло или водителя

### 🧳 Багаж:
- **Размер**: S (рюкзак) / M (сумка) / L (чемодан) / Custom (нестандартный)
- **Количество**: От 1 до 10 единиц каждого размера
- **Стоимость**: Цена за дополнительный багаж (сверх бесплатной нормы)
- **Описание**: Для нестандартного багажа

### 🐕 Животные:
- **Категория**: 
  - До 5 кг в переноске (бесплатно)
  - До 5 кг без переноски (1000₽)
  - Свыше 6 кг (2000₽ + индивидуальный трансфер)
- **Описание**: Название/порода животного
- **Стоимость**: Цена перевозки

## 📝 Файлы с изменениями

### Backend:
1. `backend/backend/lib/models/order.dart` - Обновлены Passenger/Baggage/Pet модели
2. `backend/backend/lib/models/order.g.dart` - Регенерирован build_runner

### App:
1. `lib/services/api/orders_api_service.dart`:
   - Добавлены параметры passengers/baggage/pets в createOrder()
   - ApiOrder содержит passengers/baggage/pets поля
   
2. `lib/services/booking_service.dart`:
   - Отправка passengers/baggage/pets как отдельных полей
   - Конвертация из ApiOrder в PassengerInfo/BaggageItem/PetInfo

## 🚀 Деплой

1. **Backend обновлен**:
```bash
docker restart timetotravel_backend
# ✓ Модели Passenger/Baggage/Pet обновлены
```

2. **Проверка API**:
```bash
curl POST /api/orders
# ✓ Backend возвращает passengers/baggage/pets в JSON
```

3. **App готов**:
- ✅ Отправляет passengers/baggage/pets как отдельные поля
- ✅ Читает и конвертирует данные из backend
- ✅ Booking модель содержит полную информацию

## ✅ Заключение

Теперь в **кабинете диспетчера** будет отображаться:

```
📋 Заказ ORDER-2026-01-79
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 Маршрут: Донецк → Ростов-на-Дону
🚗 Тип: Групповая поездка
⏰ Отправление: 29 января 2026, 14:00

👥 Пассажиры (3):
  • Взрослый
  • Взрослый
  • Ребенок (5 лет) - Бустер (4-7 лет)

🧳 Багаж:
  • Рюкзак (S) × 2 шт. - бесплатно (норма)
  • Чемодан (L) × 1 шт. - +2000₽

🐕 Животные:
  • Кот Пушок - до 5кг в переноске - БЕСПЛАТНО

💰 Стоимость: 9500₽
```

**Все данные теперь сохраняются и отображаются правильно!** 🎉
