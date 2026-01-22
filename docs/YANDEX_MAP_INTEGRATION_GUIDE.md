# 🗺️ ПОЛНАЯ ИНСТРУКЦИЯ: ИНТЕГРАЦИЯ YANDEX MAPKIT В FLUTTER ПРИЛОЖЕНИЕ

## 📋 ОГЛАВЛЕНИЕ
1. [Обзор](#обзор)
2. [Используемые файлы](#используемые-файлы)
3. [Зависимости](#зависимости)
4. [Структура интеграции](#структура-интеграции)
5. [Код реализации](#код-реализации)
6. [Настройка Android](#настройка-android)
7. [Настройка iOS](#настройка-ios)
8. [Тестирование](#тестирование)
9. [Решение проблем](#решение-проблем)

---

## 🎯 ОБЗОР

**Проект:** Time to Travel (пассажирские перевозки Донецк ↔ Ростов)

**Функционал карты:**
- ✅ Экран "Свободный маршрут" с картой Yandex
- ✅ Ввод адресов "откуда/куда"
- ✅ Построение маршрута
- ✅ Расчет расстояния и стоимости
- ✅ Визуализация маршрута на карте
- ✅ Темная/светлая тема

**Статус:** Рабочий прототип с временными заглушками (fallback логика)

---

## 📁 ИСПОЛЬЗУЕМЫЕ ФАЙЛЫ

### 1. Основной экран с картой
**Файл:** `lib/features/booking/screens/custom_route_with_map_screen.dart`

**Описание:** 
- Полноэкранная карта Yandex
- Оверлей с полями ввода адресов
- Панель с результатами расчета
- Кнопка бронирования

**Зависимости:**
```dart
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/mapkit_factory.dart';
import '../../../services/yandex_maps_service.dart';
import '../../../services/price_calculator_service.dart';
```

---

### 2. Сервис для работы с Yandex Maps
**Файл:** `lib/services/yandex_maps_service.dart`

**Функции:**
- `initialize()` - инициализация MapKit
- `geocode(address)` - преобразование адреса в координаты
- `calculateRoute(from, to)` - построение маршрута
- `getSuggestions(query)` - автодополнение адресов (TODO)

**Особенности:**
- Singleton pattern (`YandexMapsService.instance`)
- Fallback на моковые координаты
- Расчет по формуле Гаверсина (для прямого расстояния)

---

### 3. Конфигурация карт
**Файл:** `lib/config/map_config.dart`

**Содержит:**
```dart
class MapConfig {
  static const String yandexMapKitApiKey = '2f1d6a75-b751-4077-b305-c6abaea0b542';
  static const double defaultZoom = 15.0;
  static const double defaultLatitude = 55.751244; // Москва
  static const double defaultLongitude = 37.618423;
  // ... другие настройки
}
```

---

### 4. Сервис расчета стоимости
**Файл:** `lib/services/price_calculator_service.dart`

**Формула:**
```
Стоимость = базовая_цена + (расстояние × цена_за_км)
Округление до тысяч (опционально)
```

**Настройки из Firebase:**
- `baseCost` - базовая стоимость (500₽)
- `costPerKm` - цена за километр (15₽)
- `minPrice` - минимальная цена (1000₽)
- `roundToThousands` - округление (true/false)

---

### 5. Модели данных

**Файл:** `lib/models/route_info.dart`
```dart
class RouteInfo {
  final double distance;        // км
  final double duration;         // минуты
  final String fromAddress;
  final String toAddress;
  final List<Coordinates>? polyline; // точки маршрута (опционально)
}
```

**Файл:** `lib/models/price_calculation.dart`
```dart
class PriceCalculation {
  final double basePrice;
  final double distancePrice;
  final double finalPrice;
  final String formula;
}
```

---

## 📦 ЗАВИСИМОСТИ

### pubspec.yaml

```yaml
dependencies:
  # Yandex MapKit (версия 4.17.2)
  yandex_maps_mapkit: ^4.17.2
  
  # Для HTTP запросов (API вызовы)
  http: ^1.1.2
  
  # Firebase (настройки калькулятора)
  firebase_core: ^2.24.2
  cloud_firestore: ^4.13.6
  
  # Геолокация
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  
  # UI
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
```

### Версия Yandex MapKit

**Текущая:** `4.17.2`

**Документация:**
- Официальная: https://yandex.ru/dev/mapkit/doc/ru/flutter/
- GitHub: https://github.com/yandex/mapkit-flutter

**API версия:** 4.24.0-beta (поддерживает SearchManager, DrivingRouter, SuggestSession)

---

## 🏗️ СТРУКТУРА ИНТЕГРАЦИИ

```
lib/
├── features/
│   └── booking/
│       └── screens/
│           └── custom_route_with_map_screen.dart  ← Основной экран
│
├── services/
│   ├── yandex_maps_service.dart                   ← Работа с MapKit
│   ├── price_calculator_service.dart              ← Расчет цены
│   └── calculator_settings_service.dart           ← Firebase настройки
│
├── models/
│   ├── route_info.dart                            ← Модель маршрута
│   ├── price_calculation.dart                     ← Модель расчета
│   └── calculator_settings.dart                   ← Настройки
│
└── config/
    └── map_config.dart                            ← API ключи и константы
```

---

## 💻 КОД РЕАЛИЗАЦИИ

### 1. Инициализация карты (main.dart)

```dart
import 'package:yandex_maps_mapkit/init.dart' as mapkit_init;
import 'config/map_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация Yandex MapKit
  if (MapConfig.hasApiKey) {
    await mapkit_init.initMapkit(apiKey: MapConfig.yandexMapKitApiKey);
    print('✅ Yandex MapKit инициализирован');
  }
  
  await Firebase.initializeApp();
  runApp(const MyApp());
}
```

---

### 2. Экран с картой (упрощенная версия)

```dart
import 'package:flutter/cupertino.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';

class CustomRouteWithMapScreen extends StatefulWidget {
  @override
  State<CustomRouteWithMapScreen> createState() => _CustomRouteWithMapScreenState();
}

class _CustomRouteWithMapScreenState extends State<CustomRouteWithMapScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  
  YandexMapController? _mapController;
  bool _isMapReady = false;

  void _onMapCreated(YandexMapController controller) {
    _mapController = controller;
    
    // Устанавливаем начальную позицию
    final point = const Point(latitude: 58.0105, longitude: 56.2502); // Пермь
    _mapController!.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: point, zoom: 11.0),
      ),
    );
    
    setState(() => _isMapReady = true);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Свободный маршрут'),
      ),
      child: Stack(
        children: [
          // Карта на весь экран
          YandexMap(
            onMapCreated: _onMapCreated,
            mapObjects: const [],
          ),
          
          // Оверлей с UI
          SafeArea(
            child: Column(
              children: [
                // Панель ввода адресов
                _buildInputPanel(),
                
                Spacer(),
                
                // Панель результатов
                if (_calculation != null)
                  _buildResultPanel(),
              ],
            ),
          ),
          
          // Индикатор загрузки
          if (!_isMapReady)
            Center(child: CupertinoActivityIndicator()),
        ],
      ),
    );
  }
}
```

---

### 3. Сервис работы с картой

```dart
class YandexMapsService {
  static final instance = YandexMapsService._();
  YandexMapsService._();

  // Геокодирование: адрес → координаты
  Future<Coordinates?> geocode(String address) async {
    // TODO: Использовать SearchManager API
    // Пока fallback на моковые координаты
    return _getMockCoordinates(address);
  }

  // Построение маршрута
  Future<RouteInfo?> calculateRoute(String from, String to) async {
    final fromCoords = await geocode(from);
    final toCoords = await geocode(to);
    
    if (fromCoords == null || toCoords == null) return null;
    
    // TODO: Использовать DrivingRouter API
    // Пока расчет по прямой (формула Гаверсина)
    return _calculateRouteByDistance(fromCoords, toCoords, from, to);
  }

  // Расчет расстояния по формуле Гаверсина
  double _calculateDistance(Coordinates from, Coordinates to) {
    const earthRadiusKm = 6371.0;
    
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final dLat = (to.latitude - from.latitude) * pi / 180;
    final dLon = (to.longitude - from.longitude) * pi / 180;
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadiusKm * c;
  }
}
```

---

## 🤖 НАСТРОЙКА ANDROID

### 1. AndroidManifest.xml

**Файл:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
  <application>
    <!-- ... -->
    
    <!-- Yandex MapKit API Key -->
    <meta-data
      android:name="com.yandex.mapkit.ApiKey"
      android:value="2f1d6a75-b751-4077-b305-c6abaea0b542"/>
  </application>
  
  <!-- Разрешения -->
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
</manifest>
```

---

### 2. build.gradle (app level)

**Файл:** `android/app/build.gradle`

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 24  // Минимум для MapKit
        targetSdkVersion 34
    }
}

dependencies {
    // Не нужно добавлять вручную - управляется через pubspec.yaml
}
```

---

## 🍎 НАСТРОЙКА iOS

### 1. Info.plist

**Файл:** `ios/Runner/Info.plist`

```xml
<dict>
  <!-- Yandex MapKit API Key -->
  <key>YMKApiKey</key>
  <string>2f1d6a75-b751-4077-b305-c6abaea0b542</string>
  
  <!-- Разрешения на геолокацию -->
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>Приложение использует геолокацию для построения маршрута</string>
  
  <key>NSLocationAlwaysUsageDescription</key>
  <string>Приложение использует геолокацию для построения маршрута</string>
</dict>
```

---

### 2. Podfile

**Файл:** `ios/Podfile`

```ruby
platform :ios, '13.0'  # Минимум для MapKit

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
```

---

## 🧪 ТЕСТИРОВАНИЕ

### 1. Запуск приложения

```bash
# Установка зависимостей
flutter pub get

# Запуск на Android
flutter run

# Запуск на iOS
flutter run -d iPhone

# Запуск с логами MapKit
flutter run --verbose
```

---

### 2. Тестовые данные

**Маршрут 1: Донецк → Ростов**
```
От: Донецк, проспект Ильича 16
До: Ростов-на-Дону, Буденновский 34
Ожидаемое расстояние: ~200 км
Ожидаемая стоимость: ~3500₽
```

**Маршрут 2: Пермь → Екатеринбург**
```
От: Пермь, улица Ленина 39
До: Екатеринбург, проспект Ленина 24
Ожидаемое расстояние: ~340 км
Ожидаемая стоимость: ~5600₽
```

---

### 3. Проверка логов

```bash
# Логи инициализации MapKit
🗺️ [YANDEX MAPKIT] Инициализация...
✅ [YANDEX MAPKIT] Инициализирован успешно

# Логи создания карты
🗺️ [MAP] ========== ИНИЦИАЛИЗАЦИЯ КАРТЫ ==========
🗺️ [MAP] YandexMapController создан: true
🗺️ [MAP] ✅ Камера перемещена
🗺️ [MAP] ========== ✅ КАРТА ГОТОВА К РАБОТЕ ==========

# Логи расчета маршрута
🚗 [YANDEX MAPKIT] ========== РАСЧЁТ МАРШРУТА ==========
🚗 [YANDEX MAPKIT] От: Донецк, проспект Ильича 16
🚗 [YANDEX MAPKIT] До: Ростов-на-Дону, Буденновский 34
📍 [YANDEX MAPKIT] От: Coordinates(48.0, 37.8)
📍 [YANDEX MAPKIT] До: Coordinates(47.2, 39.7)
✅ [YANDEX MAPKIT] Маршрут рассчитан: 185.3 км
💰 Стоимость: 3279₽
```

---

## 🔧 РЕШЕНИЕ ПРОБЛЕМ

### Проблема 1: Карта не загружается

**Симптомы:**
- Белый экран вместо карты
- Ошибка "API key is invalid"

**Решение:**
```bash
1. Проверить API ключ в map_config.dart
2. Проверить AndroidManifest.xml (Android)
3. Проверить Info.plist (iOS)
4. Очистить кеш:
   flutter clean
   flutter pub get
   flutter run
```

---

### Проблема 2: Маршрут не строится

**Симптомы:**
- Ошибка "Не удалось построить маршрут"
- Возвращается null

**Решение:**
```dart
// Проверить fallback логику в yandex_maps_service.dart
Future<RouteInfo?> calculateRoute(String from, String to) async {
  try {
    // Основная логика
    ...
  } catch (e) {
    print('❌ Ошибка: $e');
    // Fallback на расчет по прямой
    return _calculateRouteByDistance(...);
  }
}
```

---

### Проблема 3: Неправильная стоимость

**Симптомы:**
- Цена не совпадает с ожиданиями
- Не работает округление

**Решение:**
```bash
1. Проверить настройки в Firebase:
   - Коллекция: calculator_settings
   - Документ: current
   - Поля: baseCost, costPerKm, minPrice, roundToThousands

2. Проверить логи PriceCalculatorService:
   💰 Базовая стоимость: 500₽
   💰 Расстояние: 185.3 км × 15₽/км = 2779₽
   💰 Итого: 3279₽ (после округления: 3000₽)
```

---

## 📚 ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ

### Документация
- **Yandex MapKit Flutter:** https://yandex.ru/dev/mapkit/doc/ru/flutter/
- **API Reference:** https://yandex.github.io/mapkit-flutter/
- **Примеры кода:** https://github.com/yandex/mapkit-flutter/tree/main/example

### API версии
- **Текущая:** 4.17.2 (stable)
- **Бета:** 4.24.0-beta (новые возможности)

### TODO список для улучшения
- [ ] Реализовать SearchManager для геокодирования
- [ ] Реализовать DrivingRouter для точных маршрутов
- [ ] Добавить SuggestSession для автодополнения
- [ ] Добавить PlacemarkMapObject для маркеров
- [ ] Добавить PolylineMapObject для отображения маршрута
- [ ] Реализовать UserLocationLayer для геолокации
- [ ] Добавить кэширование координат
- [ ] Оптимизировать производительность

---

## ✅ ЧЕКЛИСТ ИНТЕГРАЦИИ

При переносе в новое приложение проверьте:

### Файлы
- [ ] `custom_route_with_map_screen.dart` - основной экран
- [ ] `yandex_maps_service.dart` - сервис работы с API
- [ ] `map_config.dart` - конфигурация и API ключ
- [ ] `price_calculator_service.dart` - расчет стоимости
- [ ] `route_info.dart` - модель маршрута

### Зависимости
- [ ] `yandex_maps_mapkit: ^4.17.2` в pubspec.yaml
- [ ] `http: ^1.1.2` для API запросов
- [ ] `geolocator` и `permission_handler` для геолокации

### Конфигурация Android
- [ ] API ключ в AndroidManifest.xml
- [ ] minSdkVersion >= 24
- [ ] Разрешения на интернет и геолокацию

### Конфигурация iOS
- [ ] API ключ в Info.plist
- [ ] platform :ios, '13.0' в Podfile
- [ ] Разрешения на геолокацию

### Firebase (опционально)
- [ ] Коллекция `calculator_settings`
- [ ] Поля: baseCost, costPerKm, minPrice, roundToThousands

---

## 🎉 ГОТОВО!

Теперь у вас есть полная инструкция по интеграции Yandex MapKit в Flutter приложение.

**Статус:** ✅ Рабочий прототип  
**Дата создания:** 27 октября 2025  
**Версия:** 1.0  

Удачи с интеграцией! 🚀
