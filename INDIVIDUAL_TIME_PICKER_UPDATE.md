# Обновление выбора времени в индивидуальном трансфере

**Дата:** 14 октября 2025 г.  
**Статус:** ✅ Завершено

## 📋 Задача

Изменить выбор времени отправления в экране "Индивидуальный трансфер" с фиксированного списка времён (из TripSettings) на свободный выбор любого времени через TimePicker.

## ✅ Выполненные изменения

### 1. Удалена зависимость от TripSettings

**Удалённые импорты:**
```dart
import '../../../models/trip_settings.dart';
import '../../../services/trip_settings_service.dart';
```

**Удалённые переменные:**
```dart
TripSettings? _tripSettings;
```

**Удалённые методы:**
```dart
Future<void> _loadTripSettings() async {
  // Больше не нужен
}
```

### 2. Обновлён метод `_buildTimePicker()`

**Было:** 
- Проверка на `_tripSettings?.departureTimes`
- Сообщение "Время отправления не настроено" если список пуст

**Стало:**
- Убрана зависимость от `TripSettings`
- Всегда доступен выбор времени
- Красная рамка если время не выбрано (`_selectedTime.isEmpty`)

```dart
Widget _buildTimePicker(theme) {
  return CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: () => _showTimePickerModal(theme),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedTime.isNotEmpty
              ? theme.separator.withOpacity(0.2)
              : theme.systemRed, // Красная рамка если не выбрано
        ),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.clock, color: theme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedTime.isEmpty
                  ? 'Выберите время отправления'
                  : _selectedTime,
              style: TextStyle(
                color: _selectedTime.isEmpty
                    ? theme.tertiaryLabel
                    : theme.label,
                fontSize: 16,
              ),
            ),
          ),
          Icon(CupertinoIcons.chevron_right, color: theme.secondaryLabel),
        ],
      ),
    ),
  );
}
```

### 3. Переделан метод `_showTimePickerModal()`

**Было:**
- `CupertinoPicker` со списком времён из `TripSettings`
- Кнопка "Выбрать"

**Стало:**
- `CupertinoDatePicker` в режиме `time`
- 24-часовой формат
- Кнопка "Готово"
- Автоматическое форматирование в `HH:mm`

```dart
void _showTimePickerModal(theme) {
  // Парсим текущее время или используем текущее системное время
  DateTime initialTime = DateTime.now();
  if (_selectedTime.isNotEmpty) {
    try {
      final timeParts = _selectedTime.split(':');
      initialTime = DateTime(
        initialTime.year,
        initialTime.month,
        initialTime.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      print('⚠️ Не удалось распарсить время: $_selectedTime');
    }
  }

  // Временная переменная для хранения выбранного времени
  DateTime tempSelectedTime = initialTime;

  showCupertinoModalPopup(
    context: context,
    builder: (context) => Container(
      height: 260,
      decoration: BoxDecoration(
        color: theme.systemBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          // Заголовок с кнопкой "Готово"
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.separator)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Время отправления',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.label,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // Форматируем время в строку HH:mm
                    final formattedTime =
                        '${tempSelectedTime.hour.toString().padLeft(2, '0')}:'
                        '${tempSelectedTime.minute.toString().padLeft(2, '0')}';

                    setState(() {
                      _selectedTime = formattedTime;
                    });

                    print('⏰ Выбрано время: $formattedTime');
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Готово',
                    style: TextStyle(
                      color: theme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Time Picker с 24-часовым форматом
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              use24hFormat: true,
              initialDateTime: initialTime,
              onDateTimeChanged: (DateTime newTime) {
                tempSelectedTime = newTime;
              },
            ),
          ),
        ],
      ),
    ),
  );
}
```

## 🔄 Совместимость с существующей логикой

### Формат данных
- **Переменная:** `String _selectedTime = ''`
- **Формат:** `'HH:mm'` (например, `'15:30'`, `'08:00'`, `'22:45'`)
- **SQLite:** Сохраняется напрямую как строка
- **Firebase:** Совместимо с существующей структурой

### Ценообразование
Метод `TripPricing.getIndividualTripPrice()` уже работает с любым временем в формате `HH:mm`:

```dart
static bool isNightTime(String departureTime) {
  final time = departureTime.split(':');
  final hour = int.parse(time[0]);
  return hour >= 22; // После 22:00 - ночной тариф
}

static int getIndividualTripPrice(String departureTime, Direction direction) {
  if (direction == Direction.donetskToRostov) {
    return isNightTime(departureTime)
        ? individualTripNightPrice  // 10000₽
        : individualTripPrice;      // 8000₽
  }
  return individualTripPrice;
}
```

### Валидация
В методе `_bookTrip()` проверяется:
```dart
if (_selectedTime.isEmpty) {
  final theme = context.themeManager.currentTheme;
  _showError(
    'Пожалуйста, выберите время отправления',
    onOkPressed: () => _showTimePickerModal(theme),
  );
  return;
}
```

## 🎯 Преимущества нового подхода

1. **Гибкость:** Пользователь может выбрать любое время, а не только из предустановленного списка
2. **Упрощение кода:** Убрана зависимость от `TripSettings` для индивидуальных поездок
3. **Меньше ошибок:** Нет необходимости проверять, загружены ли настройки времени
4. **Лучший UX:** Стандартный iOS TimePicker знаком пользователям
5. **Ночной тариф:** Автоматически применяется для времени после 22:00

## 📱 Тестирование

### Основные сценарии:
1. ✅ Открытие экрана индивидуального трансфера
2. ✅ Нажатие на "Выберите время отправления"
3. ✅ Прокрутка часов и минут в TimePicker
4. ✅ Нажатие "Готово" для сохранения времени
5. ✅ Отображение выбранного времени в формате `HH:mm`
6. ✅ Красная рамка если время не выбрано
7. ✅ Валидация перед бронированием
8. ✅ Расчёт цены (дневной/ночной тариф)
9. ✅ Сохранение в SQLite
10. ✅ Отправка в Firebase (если включено)

### Проверка ночного тарифа:
- Время до 22:00 → 8000₽
- Время с 22:00 и позже → 10000₽

## 🎨 UI/UX

### Блок выбора времени:
- **Иконка:** 🕐 `CupertinoIcons.clock`
- **Цвет рамки:** Красный если не выбрано, обычный если выбрано
- **Плейсхолдер:** "Выберите время отправления"
- **Отображение:** Время в формате `HH:mm`

### Модальное окно:
- **Высота:** 260px
- **Заголовок:** "Время отправления"
- **Кнопка:** "Готово" (справа, синим цветом)
- **Picker:** 24-часовой формат
- **Анимация:** Стандартная модальная анимация iOS

## 📦 Измененные файлы

1. `/lib/features/booking/screens/individual_booking_screen.dart`
   - Удалены импорты `trip_settings.dart` и `trip_settings_service.dart`
   - Удалена переменная `_tripSettings`
   - Удален метод `_loadTripSettings()`
   - Обновлен метод `_buildTimePicker()`
   - Переделан метод `_showTimePickerModal()`

## ✅ Результат

Теперь в экране "Индивидуальный трансфер" пользователь может выбрать **любое время** для отправления через удобный iOS TimePicker, а не ограничиваться фиксированным списком времён. Это делает бронирование более гибким и удобным.

## 🚀 Запуск приложения

```bash
cd /Users/kirillpetrov/Projects/time-to-travel
flutter run
```

**Статус:** ✅ Приложение успешно скомпилировано и запущено без ошибок.
