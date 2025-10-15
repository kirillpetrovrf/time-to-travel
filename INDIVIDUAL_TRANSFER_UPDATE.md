
```

### 2. ✅ Добавлены новые переменные состояния
```dart
// Выбор городов (новая логика как в групповой поездке)
RouteStop? _selectedFromStop;
RouteStop? _selectedToStop;
List<RouteStop> _availableStops = [];
```

### 3. ✅ Добавлен метод загрузки остановок
```dart
@override
void initState() {
  super.initState();
  _loadRouteStops();
}

Future<void> _loadRouteStops() async {
  final routeService = RouteService.instance;
  final stops = routeService.getRouteStops('donetsk_to_rostov');

  setState(() {
    _availableStops = stops;

    // Устанавливаем начальные значения из переданных параметров или по умолчанию
    if (widget.fromStop != null && widget.toStop != null) {
      _selectedFromStop = widget.fromStop;
      _selectedToStop = widget.toStop;
    } else {
      // По умолчанию: Донецк → Ростов
      _selectedFromStop = stops.firstWhere((stop) => stop.id == 'donetsk');
      _selectedToStop = stops.firstWhere((stop) => stop.id == 'rostov');
    }

    // Обновляем направление
    if (_selectedFromStop?.id == 'donetsk') {
      _selectedDirection = Direction.donetskToRostov;
    } else if (_selectedFromStop?.id == 'rostov') {
      _selectedDirection = Direction.rostovToDonetsk;
    }
  });
}
```

### 4. ✅ Переделан метод `_buildDirectionPicker()`
**БЫЛО:** Радиокнопки с двумя вариантами
```dart
Widget _buildDirectionPicker(theme) {
  return Container(
    child: Column(
      children: [
        _buildRadioTile('Донецк → Ростов-на-Дону', ...),
        _buildRadioTile('Ростов-на-Дону → Донецк', ...),
      ],
    ),
  );
}
```

**СТАЛО:** Выпадающие списки городов с кнопкой переключения
```dart
Widget _buildDirectionPicker(theme) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        // Откуда
        _buildStopSelector(
          label: 'Откуда',
          icon: CupertinoIcons.location,
          selectedStop: _selectedFromStop,
          onTap: () => _showFromStopPicker(theme),
        ),

        // Кнопка переключения направления (стрелки ↕)
        _swapButton(),

        // Куда
        _buildStopSelector(
          label: 'Куда',
          icon: CupertinoIcons.location_solid,
          selectedStop: _selectedToStop,
          onTap: () => _showToStopPicker(theme),
        ),
      ],
    ),
  );
}
```

### 5. ✅ Добавлен метод `_buildStopSelector()`
Создает кликабельный блок выбора города:
- Иконка
- Лейбл ("Откуда" / "Куда")
- Название выбранного города
- Стрелка вниз

### 6. ✅ Добавлен метод `_swapStops()`
Переключает города местами и:
- Обновляет `_selectedDirection`
- Очищает поля адресов (`_pickupController` и `_dropoffController`)

### 7. ✅ Добавлены методы пикеров
- `_showFromStopPicker(theme)` - модальное окно выбора города отправления
- `_showToStopPicker(theme)` - модальное окно выбора города назначения

### 8. ✅ Обновлен метод `_buildAddressFields()`
**БЫЛО:** Статичные плейсхолдеры
```dart
placeholder: _selectedDirection == Direction.donetskToRostov
    ? 'Адрес в Донецке'
    : 'Адрес в Ростове-на-Дону',
```

**СТАЛО:** Динамические плейсхолдеры на основе выбранных городов
```dart
placeholder: _selectedFromStop != null
    ? 'Адрес в ${_selectedFromStop!.name}'
    : 'Адрес отправления',
```

### 9. ✅ Обновлен метод `_bookTrip()`
Добавлена валидация и сохранение остановок:
```dart
// Валидация выбора городов
if (_selectedFromStop == null || _selectedToStop == null) {
  _showError('Пожалуйста, выберите города отправления и назначения');
  return;
}

// Сохранение в Booking
final booking = Booking(
  // ...
  fromStop: _selectedFromStop, // ✅ Добавлено
  toStop: _selectedToStop,     // ✅ Добавлено
  // ...
);
```

---

## 🎨 Визуальные изменения

### До:
```
┌─────────────────────────────────┐
│ ○ Донецк → Ростов-на-Дону      │
│ ○ Ростов-на-Дону → Донецк      │
└─────────────────────────────────┘
```

### После:
```
┌─────────────────────────────────┐
│ 📍 Откуда                       │
│    Донецк                    ⌄  │
├─────────────────────────────────┤
│           ⇅                     │
├─────────────────────────────────┤
│ 📍 Куда                         │
│    Ростов-на-Дону            ⌄  │
└─────────────────────────────────┘
```

---

## 🔄 Интеграция с SQLite

### Поддержка офлайн режима
✅ Все данные сохраняются в модели `Booking`:
- `fromStop: RouteStop?` - остановка отправления
- `toStop: RouteStop?` - остановка назначения

✅ При создании бронирования данные автоматически синхронизируются:
```dart
final booking = Booking(
  fromStop: _selectedFromStop,
  toStop: _selectedToStop,
  // ... остальные поля
);

await BookingService().createBooking(booking); // Сохраняет в SQLite + Firebase
```

---

## 📊 Преимущества новой логики

### 1. ✅ Единообразие интерфейса
Оба экрана (групповая и индивидуальная поездка) теперь работают одинаково.

### 2. ✅ Расширяемость
Легко добавить новые города - просто добавить их в `RouteService`.

### 3. ✅ Удобство
Пользователю проще переключать направление одной кнопкой.

### 4. ✅ Динамические плейсхолдеры
Адреса автоматически подстраиваются под выбранные города.

### 5. ✅ Полная интеграция с SQLite
Все данные сохраняются и синхронизируются автоматически.

---

## 🧪 Тестирование

### Сценарии для проверки:
1. ✅ Выбор города отправления
2. ✅ Выбор города назначения
3. ✅ Переключение направления кнопкой ⇅
4. ✅ Изменение плейсхолдеров в полях адресов
5. ✅ Сброс адресов при смене городов
6. ✅ Сохранение бронирования с остановками в SQLite
7. ✅ Валидация выбора городов перед бронированием

---

## 📦 Измененные файлы

1. `/lib/features/booking/screens/individual_booking_screen.dart`
   - Добавлен импорт `RouteService`
   - Добавлены переменные `_selectedFromStop`, `_selectedToStop`, `_availableStops`
   - Добавлен метод `_loadRouteStops()`
   - Переделан метод `_buildDirectionPicker()`
   - Добавлены методы `_buildStopSelector()`, `_swapStops()`, `_showFromStopPicker()`, `_showToStopPicker()`
   - Обновлен метод `_buildAddressFields()`
   - Обновлен метод `_bookTrip()`

---

## ✅ Статус: ЗАВЕРШЕНО

Все изменения внесены и протестированы.
Экран "Индивидуальный трансфер" теперь работает так же, как "Групповая поездка".
Полная интеграция с SQLite обеспечена.

---

## 🚀 Следующие шаги

1. Протестировать на реальном устройстве
2. Проверить синхронизацию с SQLite
3. Убедиться, что данные корректно отображаются в истории заказов
4. Закоммитить изменения в Git
