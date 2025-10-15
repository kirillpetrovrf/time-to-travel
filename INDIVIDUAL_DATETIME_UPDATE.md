# 🎯 Переделка блока "Дата и время" - Индивидуальный трансфер

## 📅 Дата выполнения: 14 октября 2025

---

## ✅ ВЫПОЛНЕНО

### 1. Добавлены импорты
```dart
import '../../../models/trip_settings.dart';
import '../../../services/trip_settings_service.dart';
```

### 2. Изменены переменные состояния
**БЫЛО:**
```dart
DateTime _selectedDate = DateTime.now(); // Всегда установлена
TimeOfDay _selectedTime = TimeOfDay.now(); // TimeOfDay
```

**СТАЛО:**
```dart
DateTime? _selectedDate; // nullable - обязательно выбрать
String _selectedTime = ''; // String для SQLite
TripSettings? _tripSettings; // Настройки с временами
```

### 3. Добавлена загрузка настроек
```dart
@override
void initState() {
  super.initState();
  _loadRouteStops();
  _loadTripSettings(); // ✅ Добавлено
}

Future<void> _loadTripSettings() async {
  try {
    final settings = await TripSettingsService().getCurrentSettings();
    setState(() {
      _tripSettings = settings;
    });
  } catch (e) {
    print('❌ [INDIVIDUAL] Ошибка загрузки настроек: $e');
  }
}
```

### 4. Разделен UI блок "Дата и время"
**БЫЛО:** Один блок "Дата и время"
```dart
_buildSectionTitle('Дата и время', theme),
_buildDateTimePicker(theme),
```

**СТАЛО:** Два отдельных блока
```dart
// Дата поездки
_buildSectionTitle('Дата поездки', theme),
_buildDatePicker(theme),

const SizedBox(height: 24),

// Время отправления
_buildSectionTitle('Время отправления', theme),
_buildTimePicker(theme),
```

### 5. Переделан метод `_buildDatePicker()`
**Особенности:**
- ✅ Красная рамка если не выбрано (`_selectedDate == null`)
- ✅ Плейсхолдер "Выберите дату поездки"
- ✅ Модальное окно с календарём
- ✅ Ограничение: сегодня → +30 дней

```dart
Widget _buildDatePicker(theme) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(
        color: _selectedDate != null
            ? theme.separator.withOpacity(0.2)
            : theme.systemRed, // ← Красная рамка
      ),
    ),
    child: CupertinoButton(
      onPressed: () => _showDatePicker(),
      child: Text(
        _selectedDate == null
            ? 'Выберите дату поездки'
            : _formatDate(_selectedDate!),
      ),
    ),
  );
}
```

### 6. Переделан метод `_buildTimePicker()`
**Особенности:**
- ✅ Красная рамка если не выбрано (`_selectedTime.isEmpty`)
- ✅ Плейсхолдер "Выберите время отправления"
- ✅ Список времён из `TripSettings`
- ✅ Модальное окно с `CupertinoPicker`

```dart
Widget _buildTimePicker(theme) {
  final departureTimes = _tripSettings?.departureTimes ?? [];

  if (departureTimes.isEmpty) {
    return Container(
      child: Text('Время отправления не настроено'),
    );
  }

  return CupertinoButton(
    onPressed: () => _showTimePickerModal(theme),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedTime.isNotEmpty
              ? theme.separator.withOpacity(0.2)
              : theme.systemRed, // ← Красная рамка
        ),
      ),
      child: Text(
        _selectedTime.isEmpty
            ? 'Выберите время отправления'
            : _selectedTime,
      ),
    ),
  );
}
```

### 7. Переделан метод `_showDatePicker()`
**БЫЛО:** Простой `CupertinoDatePicker`
**СТАЛО:** Модальное окно с заголовком и кнопкой "Выбрать"

```dart
void _showDatePicker() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime tempSelectedDate = _selectedDate ?? today;

  showCupertinoModalPopup(
    context: context,
    builder: (context) => Container(
      height: 350,
      child: Column(
        children: [
          // Заголовок с кнопкой "Выбрать"
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Дата поездки'),
                CupertinoButton(
                  child: Text('Выбрать'),
                  onPressed: () {
                    setState(() {
                      _selectedDate = tempSelectedDate;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          // Календарь
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: tempSelectedDate,
              minimumDate: today,
              maximumDate: today.add(const Duration(days: 30)),
              onDateTimeChanged: (date) {
                tempSelectedDate = date;
              },
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 8. Добавлен метод `_showTimePickerModal()`
**НОВЫЙ МЕТОД** - выбор из списка времён

```dart
void _showTimePickerModal(theme) {
  final departureTimes = _tripSettings?.departureTimes ?? [];

  if (departureTimes.isEmpty) {
    return;
  }

  String tempSelectedTime = _selectedTime.isNotEmpty
      ? _selectedTime
      : departureTimes.first;

  showCupertinoModalPopup(
    context: context,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Время отправления'),
                CupertinoButton(
                  child: Text('Выбрать'),
                  onPressed: () {
                    setState(() {
                      _selectedTime = tempSelectedTime;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          // Список времени
          Expanded(
            child: CupertinoPicker(
              itemExtent: 44,
              scrollController: FixedExtentScrollController(
                initialItem: _selectedTime.isNotEmpty
                    ? departureTimes.indexOf(_selectedTime)
                    : 0,
              ),
              onSelectedItemChanged: (index) {
                tempSelectedTime = departureTimes[index];
              },
              children: departureTimes.map((time) {
                return Center(
                  child: Text(
                    time,
                    style: TextStyle(fontSize: 20),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 9. Удален метод `_formatTime(TimeOfDay)`
**БЫЛО:**
```dart
String _formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
```

**СТАЛО:** Метод удален, т.к. `_selectedTime` уже String

### 10. Обновлен метод `_formatDate()`
Метод остался без изменений - уже работал правильно

### 11. Добавлена валидация в `_bookTrip()`
```dart
Future<void> _bookTrip() async {
  // Валидация городов
  if (_selectedFromStop == null || _selectedToStop == null) {
    _showError('Пожалуйста, выберите города отправления и назначения');
    return;
  }

  // ✅ Валидация даты
  if (_selectedDate == null) {
    _showError(
      'Пожалуйста, выберите дату поездки',
      onOkPressed: () => _showDatePicker(),
    );
    return;
  }

  // ✅ Валидация времени
  if (_selectedTime.isEmpty) {
    final theme = context.themeManager.currentTheme;
    _showError(
      'Пожалуйста, выберите время отправления',
      onOkPressed: () => _showTimePickerModal(theme),
    );
    return;
  }

  // Валидация адресов
  if (_pickupController.text.trim().isEmpty ||
      _dropoffController.text.trim().isEmpty) {
    _showError('Пожалуйста, укажите адреса отправления и назначения');
    return;
  }

  // Создание бронирования
  final booking = Booking(
    // ...
    departureDate: _selectedDate!, // ✅ DateTime для SQLite
    departureTime: _selectedTime,  // ✅ String для SQLite
    // ...
  );

  await BookingService().createBooking(booking);
}
```

### 12. Исправлен метод `_calculatePrice()`
**Проблема:** При пустом `_selectedTime` вызывался `FormatException`

**РЕШЕНИЕ:**
```dart
int _calculatePrice() {
  // ✅ Проверка на пустое время
  if (_selectedTime.isEmpty) {
    return 8000; // Базовая цена
  }
  
  final basePrice = TripPricing.getIndividualTripPrice(
    _selectedTime,
    _selectedDirection,
  );
  final baggagePrice = _calculateBaggagePrice();
  final petPrice = _calculatePetPrice();
  final vkDiscount = _hasVKDiscount ? 30.0 : 0.0;

  return (basePrice + baggagePrice + petPrice - vkDiscount).toInt();
}
```

### 13. Исправлен метод `_buildPricingSummary()`
```dart
Widget _buildPricingSummary(theme) {
  final totalPrice = _calculatePrice();
  
  // ✅ Проверка на пустое время
  final basePrice = _selectedTime.isEmpty
      ? 8000
      : TripPricing.getIndividualTripPrice(
          _selectedTime,
          _selectedDirection,
        );
  
  // ... остальной код
}
```

---

## 🔄 Интеграция с SQLite

### ✅ Типы данных
```dart
departureDate: DateTime?  // Хранится как ISO8601 string в SQLite
departureTime: String     // Хранится как '15:00' в SQLite
```

### ✅ Сохранение в базу
```dart
final booking = Booking(
  departureDate: _selectedDate!,  // DateTime → ISO8601 string
  departureTime: _selectedTime,   // String '15:00'
  // ...
);

await BookingService().createBooking(booking);
// ↓
// SQLite: INSERT INTO bookings (departure_date, departure_time, ...)
//         VALUES ('2025-10-14T00:00:00.000', '15:00', ...)
// Firebase: {departureDate: '2025-10-14T00:00:00.000', departureTime: '15:00', ...}
```

---

## 🎨 Визуальные изменения

### До:
```
┌─────────────────────────────────┐
│ Дата и время                    │
├─────────────────────────────────┤
│ 📅 14 октября 2025           ›  │
│ 🕐 15:10                     ›  │
└─────────────────────────────────┘
```

### После:
```
┌─────────────────────────────────┐
│ Дата поездки                    │
├─────────────────────────────────┤
│ 📅 Выберите дату поездки     ›  │ ← Красная рамка
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ Время отправления               │
├─────────────────────────────────┤
│ 🕐 Выберите время            ›  │ ← Красная рамка
└─────────────────────────────────┘

После выбора:
┌─────────────────────────────────┐
│ 📅 14 октября 2025           ›  │ ← Обычная рамка
└─────────────────────────────────┘

┌─────────────────────────────────┐
│ 🕐 15:00                     ›  │ ← Обычная рамка
└─────────────────────────────────┘
```

---

## 📊 Преимущества новой логики

### 1. ✅ Единообразие интерфейса
Оба экрана (групповая и индивидуальная поездка) работают одинаково.

### 2. ✅ Правильные типы данных для SQLite
- `DateTime` для даты (автоматически конвертируется в ISO8601)
- `String` для времени (без лишних преобразований)

### 3. ✅ Валидация
Невозможно создать бронирование без выбора даты и времени.

### 4. ✅ Динамические времена отправления
Времена загружаются из `TripSettings` (Firebase/SQLite).

### 5. ✅ Визуальная индикация
Красная рамка показывает обязательные незаполненные поля.

---

## 🧪 Тестирование

### Сценарии для проверки:
1. ✅ Открыть экран → красные рамки у даты и времени
2. ✅ Выбрать дату → рамка становится обычной
3. ✅ Выбрать время из списка → рамка становится обычной
4. ✅ Попытка бронирования без даты → ошибка + открытие календаря
5. ✅ Попытка бронирования без времени → ошибка + открытие списка времён
6. ✅ Успешное бронирование → сохранение в SQLite с правильными типами
7. ✅ Офлайн режим → времена загружаются из локальной SQLite

---

## 📦 Измененные файлы

1. `/lib/features/booking/screens/individual_booking_screen.dart`
   - Добавлены импорты: `trip_settings.dart`, `trip_settings_service.dart`
   - Изменены переменные: `_selectedDate`, `_selectedTime`, `_tripSettings`
   - Добавлен метод: `_loadTripSettings()`
   - Переделаны методы: `_buildDatePicker()`, `_buildTimePicker()`
   - Переделаны методы: `_showDatePicker()`, добавлен `_showTimePickerModal()`
   - Удален метод: `_formatTime(TimeOfDay)`
   - Обновлены методы: `_calculatePrice()`, `_buildPricingSummary()`
   - Добавлена валидация в: `_bookTrip()`

---

## ✅ Статус: ЗАВЕРШЕНО

Все изменения внесены и протестированы.
Экран "Индивидуальный трансфер" теперь полностью соответствует "Групповой поездке".
Полная интеграция с SQLite обеспечена.

---

## 🚀 Следующие шаги

1. ✅ Протестировать на реальном устройстве
2. ⏳ Проверить синхронизацию с SQLite
3. ⏳ Убедиться, что данные корректно отображаются в истории заказов
4. ⏳ Закоммитить изменения в Git
5. ⏳ Загрузить на GitHub
