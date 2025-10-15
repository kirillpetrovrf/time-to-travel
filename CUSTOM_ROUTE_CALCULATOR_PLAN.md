# 🚕 План реализации "Свободный маршрут" (Калькулятор такси)

**Дата:** 14 октября 2025 г.  
**Задача:** Полная переделка экрана "Свободный маршрут" в калькулятор такси с произвольными адресами

---

## 📋 Техническое задание

### Основные требования:
1. ✅ Пользователь вводит произвольный адрес отправления
2. ✅ Пользователь вводит произвольный адрес назначения
3. ✅ Интеграция с Yandex Maps API для расчета расстояния
4. ✅ Динамическое ценообразование: `базовая стоимость + (километры × коэффициент)`
5. ✅ Минимальная цена: 1000₽
6. ✅ Округление цены: если > 1000₽ → округлить до тысяч вверх (21150₽ → 22000₽)
7. ✅ Админ может менять формулу в кабинете диспетчера

---

## 🎯 Стратегия реализации

### Подход:
**НЕ переделываем существующий `route_selection_screen.dart`**, а создаём НОВЫЙ экран `custom_route_calculator_screen.dart`.

**Причины:**
- Сохраняем работающий функционал популярных маршрутов
- Избегаем конфликтов с текущей логикой
- Проще тестировать и откатывать
- Возможность A/B тестирования

---

## 📦 Этапы реализации

### 🔷 ЭТАП 1: Подготовка инфраструктуры (Backend)
**Срок:** 1 день  
**Цель:** Настроить Firebase и Yandex Maps API

#### 1.1. Создать модель настроек калькулятора
**Файл:** `lib/models/calculator_settings.dart`

```dart
class CalculatorSettings {
  final double baseCost;          // Базовая стоимость (например, 500₽)
  final double costPerKm;         // Стоимость за км (например, 15₽)
  final double minPrice;          // Минимальная цена (1000₽)
  final bool roundToThousands;    // Округлять до тысяч
  final DateTime updatedAt;       // Когда обновлено
  final String updatedBy;         // Кто обновил (ID админа)
  
  CalculatorSettings({...});
  
  factory CalculatorSettings.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

#### 1.2. Создать сервис для работы с настройками
**Файл:** `lib/services/calculator_settings_service.dart`

```dart
class CalculatorSettingsService {
  // Получить текущие настройки из Firebase
  Future<CalculatorSettings> getSettings();
  
  // Обновить настройки (только для админов)
  Future<void> updateSettings(CalculatorSettings settings);
  
  // Локальный кеш настроек
  CalculatorSettings? _cachedSettings;
}
```

#### 1.3. Добавить структуру в Firebase Firestore

```
/calculator_settings (collection)
  └── /current (document)
      ├── baseCost: 500
      ├── costPerKm: 15
      ├── minPrice: 1000
      ├── roundToThousands: true
      ├── updatedAt: timestamp
      └── updatedBy: "admin_id"
```

#### 1.4. Настроить Yandex Maps API

**Файл:** `lib/services/yandex_maps_service.dart`

```dart
class YandexMapsService {
  static const String _apiKey = 'YOUR_YANDEX_API_KEY';
  
  // Получить расстояние между двумя адресами
  Future<double> getDistance(String fromAddress, String toAddress);
  
  // Геокодирование адреса (адрес → координаты)
  Future<Coordinates> geocode(String address);
  
  // Построить маршрут и получить информацию
  Future<RouteInfo> buildRoute(String from, String to);
}
```

**Зависимость:**
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0  # Для API запросов
```

---

### 🔷 ЭТАП 2: Создание UI калькулятора
**Срок:** 2 дня  
**Цель:** Создать красивый и функциональный интерфейс

#### 2.1. Создать главный экран
**Файл:** `lib/features/booking/screens/custom_route_calculator_screen.dart`

**Структура экрана:**

```
┌─────────────────────────────────────┐
│  ← Калькулятор такси               │ ← CustomNavigationBar
├─────────────────────────────────────┤
│                                     │
│  📍 Откуда                          │ ← Текстовое поле с автодополнением
│  [Введите адрес отправления...]     │
│                                     │
│          🔄                          │ ← Кнопка смены направления
│                                     │
│  📍 Куда                            │ ← Текстовое поле с автодополнением
│  [Введите адрес назначения...]      │
│                                     │
│  ─────────────────────────────      │
│                                     │
│  🚗 Расстояние: ~150 км             │ ← Блок с информацией
│  💰 Стоимость: 3000 ₽               │
│                                     │
│  [    Рассчитать стоимость    ]    │ ← Кнопка расчёта
│                                     │
│  ─────────────────────────────      │
│                                     │
│  ℹ️ Детали расчёта:                 │ ← Разворачиваемый блок
│     Базовая стоимость: 500 ₽        │
│     Расстояние: 150 км × 15 ₽ = 2250 ₽
│     Итого: 2750 ₽ → 3000 ₽          │
│     (округлено до тысяч)            │
│                                     │
│  [      Продолжить заказ      ]    │ ← Кнопка продолжения
│                                     │
└─────────────────────────────────────┘
```

#### 2.2. Компоненты экрана

**a) Поле ввода адреса с автодополнением:**
```dart
Widget _buildAddressField({
  required String label,
  required TextEditingController controller,
  required bool isFrom,
  required CustomTheme theme,
}) {
  return CupertinoTextField(
    controller: controller,
    placeholder: 'Введите адрес...',
    prefix: Icon(CupertinoIcons.location, color: theme.systemRed),
    onChanged: (value) => _onAddressChanged(value, isFrom),
    // Автодополнение через Yandex Suggest API
  );
}
```

**b) Блок информации о маршруте:**
```dart
Widget _buildRouteInfo(CustomTheme theme) {
  if (_routeInfo == null) return SizedBox();
  
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: theme.secondarySystemBackground,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        _buildInfoRow('Расстояние', '${_routeInfo!.distance} км'),
        _buildInfoRow('Стоимость', '${_routeInfo!.price} ₽'),
      ],
    ),
  );
}
```

**c) Детали расчёта (разворачиваемый):**
```dart
Widget _buildCalculationDetails(CustomTheme theme) {
  return CupertinoButton(
    child: Row(
      children: [
        Icon(CupertinoIcons.info_circle),
        Text('Детали расчёта'),
        Spacer(),
        Icon(_isDetailsExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down),
      ],
    ),
    onPressed: () {
      setState(() => _isDetailsExpanded = !_isDetailsExpanded);
    },
  );
  
  if (_isDetailsExpanded) {
    return _buildDetailsContent();
  }
}
```

---

### 🔷 ЭТАП 3: Интеграция с Yandex Maps API
**Срок:** 2 дня  
**Цель:** Получение расстояния и автодополнение адресов

#### 3.1. Настройка API ключа

**Получить ключ:**
1. Зайти на https://developer.tech.yandex.ru/
2. Создать проект
3. Включить Geocoder API и Routing API
4. Скопировать API ключ

**Сохранить ключ:**
```dart
// lib/config/api_keys.dart
class ApiKeys {
  static const String yandexMapsApiKey = 'YOUR_API_KEY_HERE';
}
```

#### 3.2. Реализовать методы API

**a) Геокодирование (адрес → координаты):**
```dart
Future<Coordinates?> geocode(String address) async {
  final url = Uri.parse(
    'https://geocode-maps.yandex.ru/1.x/?apikey=$_apiKey&geocode=$address&format=json'
  );
  
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    // Парсим координаты из ответа
    return Coordinates.fromYandexJson(json);
  }
  
  return null;
}
```

**b) Расчёт расстояния:**
```dart
Future<RouteInfo?> calculateRoute(String fromAddress, String toAddress) async {
  // 1. Геокодируем оба адреса
  final fromCoords = await geocode(fromAddress);
  final toCoords = await geocode(toAddress);
  
  if (fromCoords == null || toCoords == null) {
    return null;
  }
  
  // 2. Запрашиваем маршрут
  final url = Uri.parse(
    'https://api.routing.yandex.net/v2/route?'
    'apikey=$_apiKey&'
    'waypoints=${fromCoords.lon},${fromCoords.lat}|${toCoords.lon},${toCoords.lat}&'
    'mode=driving'
  );
  
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    final distanceMeters = json['route']['distance']['value'];
    final distanceKm = distanceMeters / 1000;
    
    return RouteInfo(
      distance: distanceKm,
      duration: json['route']['duration']['value'],
      fromAddress: fromAddress,
      toAddress: toAddress,
    );
  }
  
  return null;
}
```

**c) Автодополнение адресов (Suggest):**
```dart
Future<List<String>> getSuggestions(String query) async {
  final url = Uri.parse(
    'https://suggest-maps.yandex.ru/v1/suggest?'
    'apikey=$_apiKey&'
    'text=$query&'
    'types=locality,street,house'
  );
  
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return (json['results'] as List)
        .map((r) => r['title']['text'] as String)
        .toList();
  }
  
  return [];
}
```

---

### 🔷 ЭТАП 4: Реализация логики расчёта цены
**Срок:** 1 день  
**Цель:** Динамическое ценообразование с округлением

#### 4.1. Создать сервис расчёта
**Файл:** `lib/services/price_calculator_service.dart`

```dart
class PriceCalculatorService {
  final CalculatorSettingsService _settingsService;
  
  // Рассчитать стоимость поездки
  Future<PriceCalculation> calculatePrice(double distanceKm) async {
    final settings = await _settingsService.getSettings();
    
    // Формула: базовая + (км × коэффициент)
    double rawPrice = settings.baseCost + (distanceKm * settings.costPerKm);
    
    // Минимальная цена
    if (rawPrice < settings.minPrice) {
      return PriceCalculation(
        rawPrice: rawPrice,
        finalPrice: settings.minPrice,
        distance: distanceKm,
        baseCost: settings.baseCost,
        costPerKm: settings.costPerKm,
        roundedUp: false,
        appliedMinPrice: true,
      );
    }
    
    // Округление до тысяч вверх
    double finalPrice = rawPrice;
    bool roundedUp = false;
    
    if (settings.roundToThousands && rawPrice > settings.minPrice) {
      finalPrice = (rawPrice / 1000).ceil() * 1000;
      roundedUp = true;
    }
    
    return PriceCalculation(
      rawPrice: rawPrice,
      finalPrice: finalPrice,
      distance: distanceKm,
      baseCost: settings.baseCost,
      costPerKm: settings.costPerKm,
      roundedUp: roundedUp,
      appliedMinPrice: false,
    );
  }
}
```

#### 4.2. Модель результата расчёта
```dart
class PriceCalculation {
  final double rawPrice;         // Сырая цена (до округления)
  final double finalPrice;       // Финальная цена (после округления)
  final double distance;         // Расстояние в км
  final double baseCost;         // Базовая стоимость
  final double costPerKm;        // Стоимость за км
  final bool roundedUp;          // Было ли округление
  final bool appliedMinPrice;    // Применена ли минимальная цена
  
  PriceCalculation({...});
  
  // Форматированный вывод для UI
  String get explanation {
    String result = 'Базовая стоимость: ${baseCost.toInt()} ₽\n';
    result += 'Расстояние: ${distance.toInt()} км × ${costPerKm.toInt()} ₽ = ${(distance * costPerKm).toInt()} ₽\n';
    result += 'Сумма: ${rawPrice.toInt()} ₽\n';
    
    if (appliedMinPrice) {
      result += '→ Применена минимальная цена: ${finalPrice.toInt()} ₽';
    } else if (roundedUp) {
      result += '→ Округлено до тысяч: ${finalPrice.toInt()} ₽';
    }
    
    return result;
  }
}
```

---

### 🔷 ЭТАП 5: Админ-панель (Кабинет диспетчера)
**Срок:** 2 дня  
**Цель:** Возможность изменения настроек калькулятора

#### 5.1. Создать экран настроек
**Файл:** `lib/features/admin/screens/calculator_settings_screen.dart`

**Структура экрана:**
```
┌─────────────────────────────────────┐
│  ← Настройки калькулятора          │
├─────────────────────────────────────┤
│                                     │
│  Базовая стоимость                  │
│  [   500   ] ₽                      │
│                                     │
│  Стоимость за километр              │
│  [    15   ] ₽/км                   │
│                                     │
│  Минимальная цена                   │
│  [  1000   ] ₽                      │
│                                     │
│  ☑️ Округлять до тысяч вверх        │
│                                     │
│  ─────────────────────────────      │
│                                     │
│  📊 Примеры расчёта:                │
│                                     │
│  50 км  → 1250 ₽ → 2000 ₽          │
│  100 км → 2000 ₽ → 2000 ₽          │
│  150 км → 2750 ₽ → 3000 ₽          │
│                                     │
│  [      Сохранить изменения   ]    │
│                                     │
│  Последнее обновление:              │
│  14.10.2025 17:45 (admin@taxi.ru)  │
│                                     │
└─────────────────────────────────────┘
```

#### 5.2. Реализация сохранения

```dart
Future<void> _saveSettings() async {
  setState(() => _isLoading = true);
  
  try {
    final settings = CalculatorSettings(
      baseCost: _baseCost,
      costPerKm: _costPerKm,
      minPrice: _minPrice,
      roundToThousands: _roundToThousands,
      updatedAt: DateTime.now(),
      updatedBy: currentUser.id,
    );
    
    await CalculatorSettingsService.instance.updateSettings(settings);
    
    _showSuccess('Настройки успешно обновлены');
  } catch (e) {
    _showError('Ошибка сохранения: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
```

#### 5.3. Права доступа

**Добавить проверку прав:**
```dart
// lib/services/auth_service.dart
class AuthService {
  // Проверить, является ли пользователь админом
  Future<bool> isAdmin(String userId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    
    return userDoc.data()?['role'] == 'admin';
  }
}
```

**Защита экрана:**
```dart
@override
void initState() {
  super.initState();
  _checkAdminAccess();
}

Future<void> _checkAdminAccess() async {
  final user = await AuthService.instance.getCurrentUser();
  final isAdmin = await AuthService.instance.isAdmin(user.id);
  
  if (!isAdmin) {
    Navigator.pop(context);
    _showError('Доступ запрещён');
  }
}
```

---

### 🔷 ЭТАП 6: Интеграция с существующим flow
**Срок:** 1 день  
**Цель:** Подключить новый экран к навигации

#### 6.1. Обновить booking_screen.dart

**Заменить переход на "Свободный маршрут":**

```dart
// Было:
CupertinoButton(
  onPressed: () {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => RouteSelectionScreen(...),
      ),
    );
  },
  child: Text('Свободный маршрут'),
)

// Стало:
CupertinoButton(
  onPressed: () {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CustomRouteCalculatorScreen(),
      ),
    );
  },
  child: Text('Свободный маршрут'),
)
```

#### 6.2. Передача данных дальше

**После расчёта переходим на экран деталей бронирования:**

```dart
// В CustomRouteCalculatorScreen
void _proceedToBooking() {
  if (_priceCalculation == null) return;
  
  final customRoute = CustomRoute(
    fromAddress: _fromController.text,
    toAddress: _toController.text,
    distance: _priceCalculation!.distance,
    price: _priceCalculation!.finalPrice,
    priceDetails: _priceCalculation!,
  );
  
  Navigator.push(
    context,
    CupertinoPageRoute(
      builder: (context) => CustomRouteBookingScreen(
        customRoute: customRoute,
      ),
    ),
  );
}
```

---

### 🔷 ЭТАП 7: Тестирование
**Срок:** 2 дня  
**Цель:** Проверить все сценарии

#### 7.1. Unit-тесты

**Файл:** `test/services/price_calculator_test.dart`

```dart
void main() {
  group('PriceCalculatorService', () {
    test('Минимальная цена применяется', () {
      final calc = PriceCalculatorService(...);
      final result = calc.calculatePrice(10); // 10 км
      
      // Ожидаем: 500 + (10 × 15) = 650 ₽ → 1000 ₽ (минимум)
      expect(result.finalPrice, 1000);
      expect(result.appliedMinPrice, true);
    });
    
    test('Округление до тысяч работает', () {
      final result = calc.calculatePrice(150); // 150 км
      
      // Ожидаем: 500 + (150 × 15) = 2750 ₽ → 3000 ₽
      expect(result.finalPrice, 3000);
      expect(result.roundedUp, true);
    });
  });
}
```

#### 7.2. Интеграционные тесты

**Проверить:**
- ✅ Ввод адресов и автодополнение
- ✅ Расчёт расстояния через Yandex API
- ✅ Корректность расчёта цены
- ✅ Сохранение настроек в Firebase
- ✅ Создание бронирования
- ✅ Отображение в списке заказов

#### 7.3. E2E тесты (ручное тестирование)

**Сценарий 1: Короткая поездка**
1. Открыть "Свободный маршрут"
2. Ввести "Москва, Красная площадь"
3. Ввести "Москва, Парк Горького"
4. Нажать "Рассчитать"
5. **Ожидаем:** ~10 км, 1000 ₽ (минимум)
6. Продолжить заказ

**Сценарий 2: Длинная поездка**
1. Ввести "Ростов-на-Дону"
2. Ввести "Москва"
3. Нажать "Рассчитать"
4. **Ожидаем:** ~1000 км, ~15500 ₽ → 16000 ₽
5. Продолжить заказ

**Сценарий 3: Админ меняет настройки**
1. Войти как админ
2. Открыть "Настройки калькулятора"
3. Изменить базовую стоимость: 500 → 800
4. Сохранить
5. Вернуться в калькулятор
6. **Ожидаем:** Цены пересчитаны с новой базой

---

## 📊 Временная оценка

| Этап | Описание | Срок | Зависимости |
|------|----------|------|-------------|
| 1 | Подготовка инфраструктуры | 1 день | - |
| 2 | Создание UI | 2 дня | Этап 1 |
| 3 | Интеграция Yandex API | 2 дня | Этап 1 |
| 4 | Логика расчёта цены | 1 день | Этап 1 |
| 5 | Админ-панель | 2 дня | Этап 1, 4 |
| 6 | Интеграция с flow | 1 день | Этап 2, 3, 4 |
| 7 | Тестирование | 2 дня | Все этапы |

**Итого:** ~11 рабочих дней (2.5 недели)

---

## 📁 Структура файлов

```
lib/
├── models/
│   ├── calculator_settings.dart          # Модель настроек
│   ├── custom_route.dart                 # Модель произвольного маршрута
│   └── price_calculation.dart            # Модель расчёта цены
│
├── services/
│   ├── calculator_settings_service.dart  # Сервис настроек
│   ├── yandex_maps_service.dart          # Интеграция с Yandex
│   └── price_calculator_service.dart     # Расчёт цены
│
├── features/
│   ├── booking/screens/
│   │   ├── custom_route_calculator_screen.dart    # Главный экран
│   │   └── custom_route_booking_screen.dart       # Экран деталей заказа
│   │
│   └── admin/screens/
│       └── calculator_settings_screen.dart        # Настройки для админа
│
└── config/
    └── api_keys.dart                     # API ключи
```

---

## 🔐 Безопасность API ключей

### Важно!
**НЕ хранить API ключи в коде!**

**Правильный подход:**

```dart
// lib/config/api_keys.dart
class ApiKeys {
  static String get yandexMapsApiKey {
    // В продакшене брать из переменных окружения
    const key = String.fromEnvironment('YANDEX_API_KEY');
    if (key.isEmpty) {
      // В разработке - из локального файла (не в git)
      return _devApiKey;
    }
    return key;
  }
  
  // Локальный ключ для разработки (не коммитить!)
  static const String _devApiKey = 'your_dev_key';
}
```

**Добавить в .gitignore:**
```
# API Keys
lib/config/api_keys_local.dart
```

---

## ✅ Чеклист готовности

### Backend:
- [ ] Модель `CalculatorSettings` создана
- [ ] Сервис `CalculatorSettingsService` реализован
- [ ] Firebase Firestore структура настроена
- [ ] Yandex Maps API ключ получен
- [ ] Сервис `YandexMapsService` реализован
- [ ] Сервис `PriceCalculatorService` реализован

### Frontend:
- [ ] Экран `CustomRouteCalculatorScreen` создан
- [ ] Поля ввода адресов работают
- [ ] Автодополнение адресов подключено
- [ ] Расчёт расстояния работает
- [ ] Расчёт цены корректен
- [ ] Блок деталей расчёта отображается
- [ ] Переход на следующий экран работает

### Админ:
- [ ] Экран `CalculatorSettingsScreen` создан
- [ ] Сохранение настроек работает
- [ ] Права доступа проверяются
- [ ] Примеры расчёта обновляются в реальном времени

### Интеграция:
- [ ] Навигация из booking_screen обновлена
- [ ] Данные передаются между экранами
- [ ] Бронирование создаётся корректно
- [ ] Заказ отображается в списке

### Тестирование:
- [ ] Unit-тесты пройдены
- [ ] Интеграционные тесты пройдены
- [ ] E2E тесты выполнены
- [ ] Проверка на разных устройствах

---

## 🚀 Следующие шаги

### Шаг 1: Начать с этапа 1
```bash
# Создать структуру файлов
mkdir -p lib/models
mkdir -p lib/services
mkdir -p lib/features/admin/screens
mkdir -p lib/config

# Создать первые файлы
touch lib/models/calculator_settings.dart
touch lib/services/calculator_settings_service.dart
touch lib/services/yandex_maps_service.dart
```

### Шаг 2: Получить Yandex API ключ
1. Зайти на https://developer.tech.yandex.ru/
2. Создать проект
3. Включить нужные API
4. Скопировать ключ

### Шаг 3: Настроить Firebase
```bash
# Добавить коллекцию calculator_settings
# Создать документ current с начальными значениями
```

---

## 📝 Примечания

### Альтернатива Yandex Maps:
Если возникнут проблемы с Yandex, можно использовать:
- **Google Maps API** (платный, но надёжный)
- **OpenStreetMap Nominatim** (бесплатный, но медленный)
- **Here Maps API** (платный, хороший для России)

### Оптимизация:
- Кешировать результаты геокодирования
- Сохранять популярные маршруты
- Использовать дебаунсинг для автодополнения

### Будущие улучшения:
- История расчётов
- Избранные адреса
- Построение маршрута на карте
- Альтернативные маршруты (через платные дороги / без)

---

**Готовы начинать? Дайте знать, с какого этапа начать! 🚀**
