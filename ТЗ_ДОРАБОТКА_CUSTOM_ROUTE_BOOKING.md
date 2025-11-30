# ТЕХНИЧЕСКОЕ ЗАДАНИЕ
## Доработка Custom Route Booking Modal (Свободный маршрут)

**Дата:** 30 ноября 2025  
**Статус:** На согласовании  
**Приоритет:** Высокий

---

## 📋 СОДЕРЖАНИЕ

1. [Обзор проблем](#обзор-проблем)
2. [Требования по доработке](#требования-по-доработке)
3. [Технические детали](#технические-детали)
4. [План реализации](#план-реализации)
5. [Тестирование](#тестирование)

---

## 🔍 ОБЗОР ПРОБЛЕМ

### Текущее состояние
Модальное окно бронирования свободного маршрута (`custom_route_booking_modal.dart`) имеет следующие проблемы:

1. ❌ **Лишняя кнопка "Пропустить"** на шагах 4-8
2. ❌ **Заголовки не центрированы** (прижаты к левому краю)
3. ❌ **Недостаточные отступы** у блоков (слишком близко к краям)
4. ❌ **Не отображается цена транспорта** при выборе класса
5. ❌ **Неполные данные на экране подтверждения** (нет детей, транспорта, цен)
6. ❌ **Лишний диалог "Заказ создан"** после бронирования
7. ❌ **Не все данные попадают в заказ** (дети, транспорт, животные)

---

## ✅ ТРЕБОВАНИЯ ПО ДОРАБОТКЕ

### 1. Удаление кнопки "Пропустить"

**Файл:** `lib/widgets/custom_route_booking_modal.dart`

**Что делать:**
- Удалить метод `_skipStep()` (строка 86-88)
- Удалить переменную `canSkip` (строка 1234)
- Удалить условный блок с кнопкой "Пропустить" (строки 1263-1279)

**Обоснование:**
Все шаги должны быть обязательными для заполнения, кнопка "Пропустить" вводит в заблуждение.

---

### 2. Центрирование заголовков и подзаголовков

**Файл:** `lib/widgets/custom_route_booking_modal.dart`

**Что делать:**
Для всех заголовков шагов добавить:
```dart
// БЫЛО:
Text(
  'Заголовок',
  style: TextStyle(...),
)

// СТАЛО:
Text(
  'Заголовок',
  textAlign: TextAlign.center,
  style: TextStyle(...),
)
```

**Где применить:**
- Шаг 1: "Выберите дату поездки"
- Шаг 2: "Выберите время отправления"
- Шаг 3: "Количество пассажиров"
- Шаг 4: "Дети" / "Добавить детей"
- Шаг 5: "Багаж"
- Шаг 6: "Животные"
- Шаг 7: "Вид транспорта"
- Шаг 8: "Комментарии к заказу"
- Шаг 9: "Подтверждение заказа"

---

### 3. Добавление отступов у блоков

**Файл:** `lib/widgets/custom_route_booking_modal.dart`

**Что делать:**
Применить отступы как в `individual_booking_screen.dart`:

**Стандартные отступы:**
```dart
// Основные блоки контента
padding: const EdgeInsets.all(16)

// Блоки с выбором опций
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)

// Заголовки секций
padding: const EdgeInsets.only(bottom: 12)
```

**Где применить:**
- Каждый шаг должен иметь `Padding` с `EdgeInsets.all(16)` вокруг контента
- Блоки выбора (дата, время, пассажиры) - `EdgeInsets.symmetric(horizontal: 16, vertical: 12)`
- Между блоками добавить `SizedBox(height: 24)`

---

### 4. Отображение цены выбранного транспорта

**Файл 1:** `lib/widgets/custom_route_booking_modal.dart`

**Добавить в state:**
```dart
double? _vehicleExtraPrice; // Доплата за класс транспорта
```

**Файл 2:** `lib/features/booking/screens/vehicle_selection_screen.dart`

**Что делать:**
1. Добавить цены для каждого класса транспорта в `VehicleClass` enum:
```dart
enum VehicleClass {
  sedan(name: 'Седан', extraPrice: 0),
  wagon(name: 'Универсал', extraPrice: 500),
  minivan(name: 'Минивэн', extraPrice: 1500),
  microbus(name: 'Микроавтобус', extraPrice: 3000);
  
  final String name;
  final double extraPrice;
  const VehicleClass({required this.name, required this.extraPrice});
}
```

2. В `custom_route_booking_modal.dart` обновить отображение в шаге 7:
```dart
// После выбора класса показывать
if (_selectedVehicleClass != null)
  Text(
    'Доплата: ${_selectedVehicleClass!.extraPrice.toInt()}₽',
    style: TextStyle(
      color: theme.systemGreen,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  )
```

3. Обновить `_calculateTotalPrice()`:
```dart
// Добавить доплату за транспорт
if (_selectedVehicleClass != null) {
  total += _selectedVehicleClass!.extraPrice;
}
```

---

### 5. Дополнение экрана подтверждения

**Файл:** `lib/widgets/custom_route_booking_modal.dart`  
**Метод:** `_buildConfirmationStep()`

**Что добавить:**

```dart
Widget _buildConfirmationStep() {
  final theme = context.themeManager.currentTheme;
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Заголовок
        Text(
          'Подтверждение заказа',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.label,
          ),
        ),
        const SizedBox(height: 24),
        
        // Маршрут
        _buildSummarySection(
          'Маршрут',
          '${widget.fromAddress}\n→\n${widget.toAddress}',
          theme,
        ),
        
        // Дата и время
        _buildSummarySection(
          'Дата и время',
          '${_formatDate(_selectedDate)}\n${_selectedTime.format(context)}',
          theme,
        ),
        
        // НОВОЕ: Пассажиры с разбивкой по типам
        _buildPassengersSummary(theme),
        
        // НОВОЕ: Дети (если есть)
        if (_hasChildren()) _buildChildrenSummary(theme),
        
        // Багаж (если есть)
        if (_baggage.isNotEmpty) _buildBaggageSummary(theme),
        
        // НОВОЕ: Животные с ценами (если есть)
        if (_pets.isNotEmpty) _buildPetsSummary(theme),
        
        // НОВОЕ: Транспорт с ценой (если выбран)
        if (_selectedVehicleClass != null) _buildVehicleSummary(theme),
        
        // Комментарии (если есть)
        if (_notes.isNotEmpty)
          _buildSummarySection('Комментарии', _notes, theme),
        
        const SizedBox(height: 24),
        
        // ИТОГОВАЯ ЦЕНА
        _buildTotalPrice(theme),
      ],
    ),
  );
}

// Новые вспомогательные методы:

Widget _buildPassengersSummary(CustomTheme theme) {
  final adults = _passengers.where((p) => p.type == PassengerType.adult).length;
  final children = _passengers.where((p) => p.type == PassengerType.child).length;
  
  String text = '$adults взрослых';
  if (children > 0) {
    text += ', $children детей';
  }
  
  return _buildSummarySection('Пассажиры', text, theme);
}

bool _hasChildren() {
  return _passengers.any((p) => p.type == PassengerType.child);
}

Widget _buildChildrenSummary(CustomTheme theme) {
  final children = _passengers.where((p) => p.type == PassengerType.child).toList();
  
  String details = children.map((child) {
    String ageText = child.ageMonths != null 
      ? '${child.ageMonths! ~/ 12} лет ${child.ageMonths! % 12} мес'
      : 'возраст не указан';
    String seatText = child.childSeatType != null
      ? 'Кресло: ${_getSeatTypeName(child.childSeatType!)}'
      : '';
    return '$ageText${seatText.isNotEmpty ? ", $seatText" : ""}';
  }).join('\n');
  
  return _buildSummarySection('Детали о детях', details, theme);
}

Widget _buildBaggageSummary(CustomTheme theme) {
  // Подсчет багажа по типам
  int sCount = _baggage.where((b) => b.size == BaggageSize.small).length;
  int mCount = _baggage.where((b) => b.size == BaggageSize.medium).length;
  int lCount = _baggage.where((b) => b.size == BaggageSize.large).length;
  
  List<String> items = [];
  if (sCount > 0) items.add('S: $sCount шт (500₽/шт)');
  if (mCount > 0) items.add('M: $mCount шт (1000₽/шт)');
  if (lCount > 0) items.add('L: $lCount шт (2000₽/шт)');
  
  // Расчет стоимости багажа
  double baggageCost = _calculateBaggageCost();
  String summary = items.join('\n');
  if (baggageCost > 0) {
    summary += '\n\nСтоимость: ${baggageCost.toInt()}₽';
  }
  
  return _buildSummarySection('Багаж', summary, theme);
}

Widget _buildPetsSummary(CustomTheme theme) {
  List<String> items = _pets.map((pet) {
    String category = _getPetCategoryName(pet.category);
    return '$category (${pet.cost.toInt()}₽)';
  }).toList();
  
  double totalPetCost = _pets.fold(0, (sum, pet) => sum + pet.cost);
  String summary = items.join('\n');
  summary += '\n\nИтого за животных: ${totalPetCost.toInt()}₽';
  
  return _buildSummarySection('Животные', summary, theme);
}

Widget _buildVehicleSummary(CustomTheme theme) {
  String text = _selectedVehicleClass!.name;
  if (_selectedVehicleClass!.extraPrice > 0) {
    text += '\nДоплата: ${_selectedVehicleClass!.extraPrice.toInt()}₽';
  }
  return _buildSummarySection('Транспорт', text, theme);
}

Widget _buildSummarySection(String title, String content, CustomTheme theme) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.secondarySystemBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: theme.secondaryLabel,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: theme.label,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildTotalPrice(CustomTheme theme) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.systemRed.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: theme.systemRed, width: 2),
    ),
    child: Column(
      children: [
        Text(
          'ИТОГО К ОПЛАТЕ',
          style: TextStyle(
            fontSize: 14,
            color: theme.secondaryLabel,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_calculateTotalPrice().toInt()}₽',
          style: TextStyle(
            fontSize: 32,
            color: theme.systemRed,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

// Вспомогательные методы для получения названий
String _getSeatTypeName(ChildSeatType type) {
  switch (type) {
    case ChildSeatType.baby:
      return 'Автолюлька';
    case ChildSeatType.group1:
      return 'Группа 1 (9-18 кг)';
    case ChildSeatType.group2_3:
      return 'Группа 2-3 (15-36 кг)';
    case ChildSeatType.booster:
      return 'Бустер';
  }
}

String _getPetCategoryName(String category) {
  switch (category) {
    case 'upTo5kgWithCarrier':
      return 'До 5 кг с переноской';
    case 'upTo5kgWithoutCarrier':
      return 'До 5 кг без переноски';
    case 'over6kg':
      return 'Более 6 кг';
    default:
      return category;
  }
}

double _calculateBaggageCost() {
  // Логика расчета стоимости багажа с учетом бесплатных
  // (использовать ту же логику что в BaggageSelectionScreen)
  // Упрощенная версия:
  int freeS = _passengers.length * 2;
  int freeM = _passengers.length;
  int freeL = _passengers.length;
  
  int paidS = max(0, _baggage.where((b) => b.size == BaggageSize.small).length - freeS);
  int paidM = max(0, _baggage.where((b) => b.size == BaggageSize.medium).length - freeM);
  int paidL = max(0, _baggage.where((b) => b.size == BaggageSize.large).length - freeL);
  
  return (paidS * 500) + (paidM * 1000) + (paidL * 2000).toDouble();
}
```

---

### 6. Удаление диалога "Заказ создан"

**Файл:** `lib/widgets/custom_route_booking_modal.dart`

**Что делать:**

1. В методе `_completeBooking()` найти строку с вызовом диалога:
```dart
// УДАЛИТЬ этот блок (если он есть):
showCupertinoDialog(
  context: context,
  builder: (context) => CupertinoAlertDialog(
    title: const Text('Заказ создан'),
    content: const Text('Ваш заказ успешно создан!'),
    actions: [
      CupertinoDialogAction(
        child: const Text('Посмотреть заказ'),
        onPressed: () {
          Navigator.pop(context);
          // переход на BookingDetailScreen
        },
      ),
    ],
  ),
);
```

2. Заменить на прямой переход:
```dart
void _completeBooking() async {
  // Проверка обязательных полей
  if (_passengers.isEmpty) {
    _showError('Добавьте хотя бы одного пассажира');
    return;
  }

  // Создание заказа
  final order = TaxiOrder(
    orderId: const Uuid().v4(),
    timestamp: DateTime.now(),
    fromPoint: widget.fromPoint!,
    toPoint: widget.toPoint!,
    fromAddress: widget.fromAddress,
    toAddress: widget.toAddress,
    distanceKm: widget.distanceKm ?? 0,
    rawPrice: widget.basePrice,
    finalPrice: _calculateTotalPrice(),
    baseCost: widget.baseCost,
    costPerKm: widget.costPerKm,
    status: 'pending',
    isSynced: false,
    departureDate: _selectedDate,
    departureTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
    passengersJson: jsonEncode(_passengers.map((p) => p.toJson()).toList()),
    baggageJson: _baggage.isNotEmpty ? jsonEncode(_baggage.map((b) => b.toJson()).toList()) : null,
    petsJson: _pets.isNotEmpty ? jsonEncode(_pets.map((p) => p.toJson()).toList()) : null,
    notes: _notes.isNotEmpty ? _notes : null,
    vehicleClass: _selectedVehicleClass?.name,
  );

  // Сохранение заказа
  print('✅ [ORDER] Заказ создан через модальное окно: ${order.orderId}');
  
  // TODO: Сохранение в БД (SQLite + Firebase)
  // await _saveOrderToDatabase(order);
  
  // Закрыть модальное окно и вернуться на главный экран
  if (!mounted) return;
  Navigator.of(context).popUntil((route) => route.isFirst);
  
  // Открыть экран деталей заказа
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => BookingDetailScreen(
        booking: _convertTaxiOrderToBooking(order),
      ),
    ),
  );
}

// Новый метод конвертации
Booking _convertTaxiOrderToBooking(TaxiOrder order) {
  return Booking(
    id: order.orderId,
    userId: 'current_user_id', // TODO: получить из AuthService
    tripType: TripType.customRoute,
    fromStop: widget.fromAddress,
    toStop: widget.toAddress,
    departureDate: order.departureDate,
    departureTime: order.departureTime,
    passengers: _passengers,
    baggage: _baggage,
    pets: _pets,
    vehicleClass: _selectedVehicleClass,
    totalPrice: order.finalPrice,
    status: BookingStatus.pending,
    createdAt: DateTime.now(),
    notes: _notes.isNotEmpty ? _notes : null,
  );
}
```

**Импорт:**
```dart
import '../features/orders/screens/booking_detail_screen.dart';
```

---

### 7. Исправление передачи данных в TaxiOrder

**Файл:** `lib/widgets/custom_route_booking_modal.dart`

**Проблема:** Не все данные корректно сохраняются в заказ

**Решение:**

1. Убедиться что в методе `_completeBooking()` все поля заполнены:
```dart
final order = TaxiOrder(
  orderId: const Uuid().v4(),
  timestamp: DateTime.now(),
  fromPoint: widget.fromPoint!,
  toPoint: widget.toPoint!,
  fromAddress: widget.fromAddress,
  toAddress: widget.toAddress,
  distanceKm: widget.distanceKm ?? 0,
  rawPrice: widget.basePrice,
  finalPrice: _calculateTotalPrice(),
  baseCost: widget.baseCost,
  costPerKm: widget.costPerKm,
  status: 'pending',
  isSynced: false,
  
  // ✅ ДАТА И ВРЕМЯ
  departureDate: _selectedDate,
  departureTime: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
  
  // ✅ ПАССАЖИРЫ (включая детей)
  passengersJson: jsonEncode(_passengers.map((p) => p.toJson()).toList()),
  
  // ✅ БАГАЖ
  baggageJson: _baggage.isNotEmpty 
    ? jsonEncode(_baggage.map((b) => b.toJson()).toList()) 
    : null,
  
  // ✅ ЖИВОТНЫЕ
  petsJson: _pets.isNotEmpty 
    ? jsonEncode(_pets.map((p) => p.toJson()).toList()) 
    : null,
  
  // ✅ КОММЕНТАРИИ
  notes: _notes.isNotEmpty ? _notes : null,
  
  // ✅ КЛАСС ТРАНСПОРТА
  vehicleClass: _selectedVehicleClass?.name,
);
```

2. Добавить логирование для отладки:
```dart
print('📦 [ORDER] Создание заказа:');
print('   Пассажиры: ${_passengers.length} (${_passengers.where((p) => p.type == PassengerType.child).length} детей)');
print('   Багаж: ${_baggage.length} предметов');
print('   Животные: ${_pets.length}');
print('   Транспорт: ${_selectedVehicleClass?.name ?? "не выбран"}');
print('   Итоговая цена: ${_calculateTotalPrice().toInt()}₽');
```

3. Проверить что модели имеют правильные методы `toJson()`:
- `PassengerInfo.toJson()` - должен включать все поля (type, ageMonths, childSeatType)
- `BaggageItem.toJson()` - должен включать size, description, cost
- `PetInfo.toJson()` - должен включать category, breed, cost

---

## 📝 ПЛАН РЕАЛИЗАЦИИ

### Этап 1: UI исправления (низкий риск)
**Время:** 30 минут  
**Задачи:**
- ✅ Удалить кнопку "Пропустить"
- ✅ Центрировать заголовки
- ✅ Добавить отступы

### Этап 2: Логика цен транспорта (средний риск)
**Время:** 45 минут  
**Задачи:**
- ✅ Добавить extraPrice в VehicleClass enum
- ✅ Отобразить цену в UI
- ✅ Обновить _calculateTotalPrice()

### Этап 3: Экран подтверждения (средний риск)
**Время:** 1.5 часа  
**Задачи:**
- ✅ Создать новые методы отображения
- ✅ Добавить детали о детях
- ✅ Добавить цены за животных и транспорт
- ✅ Красиво оформить итоговую цену

### Этап 4: Навигация после бронирования (высокий риск)
**Время:** 1 час  
**Задачи:**
- ✅ Удалить диалог "Заказ создан"
- ✅ Добавить прямой переход на BookingDetailScreen
- ✅ Создать метод конвертации TaxiOrder → Booking

### Этап 5: Сохранение данных (высокий риск)
**Время:** 1 час  
**Задачи:**
- ✅ Проверить передачу всех полей в TaxiOrder
- ✅ Добавить логирование
- ✅ Протестировать сохранение в SQLite
- ✅ Проверить синхронизацию с Firebase

**ОБЩЕЕ ВРЕМЯ:** ~4.5 часа чистой работы

---

## 🧪 ТЕСТИРОВАНИЕ

### Тест-кейсы

#### TC-1: Удаление кнопки "Пропустить"
1. Открыть модальное окно бронирования
2. Пройти на шаги 4, 5, 6, 7, 8
3. ✅ **Ожидается:** Кнопка "Пропустить" отсутствует

#### TC-2: Центрированные заголовки
1. Открыть модальное окно бронирования
2. Просмотреть все 9 шагов
3. ✅ **Ожидается:** Все заголовки центрированы

#### TC-3: Отступы блоков
1. Открыть модальное окно бронирования
2. Просмотреть все шаги
3. ✅ **Ожидается:** Блоки не прижаты к краям (отступы 16px)

#### TC-4: Цена транспорта
1. Открыть модальное окно → шаг 7 (транспорт)
2. Выбрать Седан
3. ✅ **Ожидается:** "Доплата: 0₽"
4. Выбрать Минивэн
5. ✅ **Ожидается:** "Доплата: 1500₽"

#### TC-5: Экран подтверждения - полные данные
1. Заполнить все шаги:
   - 2 взрослых + 1 ребенок (3 года)
   - Багаж: 2×S, 1×M
   - Животные: 1 (до 5кг с переноской)
   - Транспорт: Минивэн
2. Перейти на шаг 9 (подтверждение)
3. ✅ **Ожидается:**
   - Пассажиры: "2 взрослых, 1 ребенок"
   - Детали о детях: "3 года 0 мес, Кресло: Группа 1"
   - Багаж: "S: 2 шт (500₽/шт), M: 1 шт (1000₽/шт), Стоимость: 500₽"
   - Животные: "До 5 кг с переноской (1000₽), Итого: 1000₽"
   - Транспорт: "Минивэн, Доплата: 1500₽"
   - ИТОГО: корректная сумма

#### TC-6: Прямой переход на детали заказа
1. Заполнить все шаги
2. Нажать "Забронировать"
3. ✅ **Ожидается:**
   - Диалог "Заказ создан" НЕ появляется
   - Сразу открывается BookingDetailScreen
   - В деталях заказа все данные заполнены

#### TC-7: Сохранение всех данных
1. Создать заказ с:
   - 1 взрослый + 2 детей (разного возраста)
   - Багаж: 1×L
   - Животные: 1 (более 6кг)
   - Транспорт: Микроавтобус
   - Комментарий: "Тестовый заказ"
2. Перейти в детали заказа
3. Закрыть приложение и открыть снова
4. Найти заказ в списке
5. ✅ **Ожидается:** Все данные сохранились и отображаются

---

## ⚠️ КРИТИЧНЫЕ МОМЕНТЫ

### 1. Модели данных
**Проверить наличие полей в моделях:**
- `PassengerInfo` - должен иметь `ageMonths`, `childSeatType`, `useOwnSeat`
- `VehicleClass` - добавить поле `extraPrice`
- `TaxiOrder` - убедиться что есть поля для всех данных

### 2. JSON сериализация
**Проверить методы:**
- `PassengerInfo.toJson()` / `fromJson()`
- `BaggageItem.toJson()` / `fromJson()`
- `PetInfo.toJson()` / `fromJson()`

### 3. BookingDetailScreen
**Убедиться что экран корректно парсит:**
- `passengersJson` → List<PassengerInfo>
- `baggageJson` → List<BaggageItem>
- `petsJson` → List<PetInfo>
- `vehicleClass` → VehicleClass enum

### 4. Расчет итоговой цены
**Формула должна включать:**
```dart
double _calculateTotalPrice() {
  double total = widget.basePrice; // Базовая цена маршрута
  
  // Ночная доплата (>= 22:00)
  if (_selectedTime.hour >= 22) {
    total += 2000;
  }
  
  // Багаж (только платный)
  total += _calculateBaggageCost();
  
  // Животные
  total += _pets.fold(0.0, (sum, pet) => sum + pet.cost);
  
  // Транспорт (доплата за класс)
  if (_selectedVehicleClass != null) {
    total += _selectedVehicleClass!.extraPrice;
  }
  
  // Дети НЕ добавляют стоимость (бесплатно)
  
  return total;
}
```

---

## 📊 КРИТЕРИИ ПРИЕМКИ

### Обязательные (MUST HAVE)
- ✅ Кнопка "Пропустить" полностью удалена
- ✅ Все заголовки центрированы
- ✅ Блоки имеют достаточные отступы (16px)
- ✅ Цена транспорта отображается при выборе
- ✅ Экран подтверждения показывает ВСЕ данные с ценами
- ✅ После бронирования открывается BookingDetailScreen (без промежуточного диалога)
- ✅ Все данные сохраняются в заказ (дети, багаж, животные, транспорт)

### Желательные (NICE TO HAVE)
- 🔄 Анимация перехода на BookingDetailScreen
- 🔄 Показ прогресс-индикатора при сохранении
- 🔄 Toast-уведомление "Заказ успешно создан"

---

## 🔄 ПОСЛЕ ДОРАБОТКИ

### Необходимо протестировать:
1. ✅ Создание заказа с разными комбинациями опций
2. ✅ Корректность расчета цены
3. ✅ Сохранение в SQLite
4. ✅ Синхронизацию с Firebase (при наличии интернета)
5. ✅ Отображение заказа в BookingDetailScreen
6. ✅ Редактирование заказа
7. ✅ Отмену заказа

### Дополнительно проверить:
- Не сломалось ли бронирование индивидуального трансфера
- Не сломалось ли бронирование группового трансфера
- Корректность работы на разных размерах экрана
- Темная/светлая тема

---

## 📞 КОНТАКТЫ

**Разработчик:** GitHub Copilot  
**Дата составления:** 30 ноября 2025  
**Версия ТЗ:** 1.0

---

## ✍️ СОГЛАСОВАНИЕ

**Клиент:** _________________________  
**Дата:** _________________________

**Примечания клиента:**
```
[Здесь клиент может оставить свои комментарии]
```

---

**СТАТУС:** 🟡 Ожидает согласования
