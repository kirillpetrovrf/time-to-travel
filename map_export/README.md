# 🗺️ Yandex Maps Integration Package

Готовые файлы для интеграции Yandex MapKit в Flutter приложение.

## 📦 Содержимое

```
map_export/
├── config.dart                              # API ключ
├── map/
│   └── flutter_map_widget.dart             # Базовый виджет карты
├── widgets/
│   └── address_autocomplete_field.dart     # Автозаполнение адресов
└── services/
    └── yandex_maps_service.dart            # Сервис для работы с картами
```

## 🚀 Установка

### 1. Добавьте зависимости в `pubspec.yaml`

```yaml
dependencies:
  flutter:
    sdk: flutter
  yandex_maps_mapkit: ^4.9.1  # или актуальная версия
```

### 2. Скопируйте файлы

Скопируйте всю папку `map_export/` в папку `lib/` вашего проекта:

```
your_project/
└── lib/
    ├── config.dart
    ├── map/
    │   └── flutter_map_widget.dart
    ├── widgets/
    │   └── address_autocomplete_field.dart
    └── services/
        └── yandex_maps_service.dart
```

### 3. Настройте платформы

#### iOS (ios/Runner/AppDelegate.swift)

```swift
import UIKit
import Flutter
import YandexMapsMobile

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    YMKMapKit.setApiKey("ВАШ_API_КЛЮЧ")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

#### Android (android/app/src/main/AndroidManifest.xml)

```xml
<manifest ...>
    <application ...>
        <meta-data
            android:name="com.yandex.mapkit.ApiKey"
            android:value="ВАШ_API_КЛЮЧ"/>
        ...
    </application>
</manifest>
```

### 4. Инициализация в main.dart

```dart
import 'package:flutter/cupertino.dart';
import 'package:yandex_maps_mapkit/init.dart' as init;
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация MapKit
  await init.initMapkit(apiKey: kYandexMapKitApiKey);
  
  runApp(const MyApp());
}
```

## 📱 Использование

### 1. Базовая карта

```dart
import 'package:flutter/cupertino.dart';
import 'map/flutter_map_widget.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';

class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Карта'),
      ),
      child: FlutterMapWidget(
        onMapCreated: (MapWindow mapWindow) {
          // Настройте карту
          mapWindow.map.move(
            CameraPosition(
              Point(latitude: 55.75, longitude: 37.62), // Москва
              zoom: 12,
            ),
          );
        },
      ),
    );
  }
}
```

### 2. Автозаполнение адресов

```dart
import 'package:flutter/cupertino.dart';
import 'widgets/address_autocomplete_field.dart';

class AddressScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AddressAutocompleteField(
          label: 'Откуда',
          cityContext: 'Москва', // Контекст для поиска
          onAddressSelected: (address, coordinates) {
            print('Выбран адрес: $address');
            if (coordinates != null) {
              print('Координаты: ${coordinates.latitude}, ${coordinates.longitude}');
            }
          },
        ),
      ),
    );
  }
}
```

### 3. Геокодирование и маршруты

```dart
import 'services/yandex_maps_service.dart';

// Геокодирование (адрес → координаты)
final coords = await YandexMapsService.instance.geocode('Москва, Красная площадь');
print('Координаты: ${coords?.latitude}, ${coords?.longitude}');

// Расчет маршрута
final route = await YandexMapsService.instance.calculateRoute(
  'Москва, ул. Ленина, 1',
  'Москва, ул. Пушкина, 10',
);

if (route != null) {
  print('Расстояние: ${route.distance.toStringAsFixed(1)} км');
  print('Время: ${route.duration.toInt()} минут');
}
```

### 4. Добавление маркеров на карту

```dart
import 'package:yandex_maps_mapkit/mapkit.dart';

void _addMarker(MapWindow mapWindow, Point point) {
  final mapObjects = mapWindow.map.mapObjects;
  
  mapObjects.addPlacemark()
    ..geometry = point
    ..setIcon(ImageProvider.fromImageProvider(
      const AssetImage('assets/marker.png'),
    ));
}
```

## 🔑 API Ключ

1. Перейдите на https://developer.tech.yandex.ru/
2. Создайте новый проект
3. Получите API ключ для MapKit
4. Замените ключ в `config.dart`:

```dart
const String kYandexMapKitApiKey = 'ваш-api-ключ-здесь';
```

## ⚙️ Настройка поиска

В `address_autocomplete_field.dart` настройте `boundingBox` под ваш регион:

```dart
final boundingBox = BoundingBox(
  const Point(latitude: 55.0, longitude: 36.5),  // Юго-Запад
  const Point(latitude: 56.5, longitude: 38.5),  // Северо-Восток
);
```

## 📝 Дополнительная реализация

Сервис `yandex_maps_service.dart` содержит заглушки (mock). Для полной работы реализуйте:

### Геокодирование через SearchManager

```dart
import 'package:yandex_maps_mapkit/search.dart';

final searchManager = SearchFactory.instance.createSearchManager(SearchManagerType.Combined);
final searchSession = searchManager.submit(
  TextSearchRequest(
    text: address,
    geometry: Geometry.fromPoint(Point(latitude: 55.75, longitude: 37.62)),
  ),
  SearchOptions(searchType: SearchType.geo),
);

final result = await searchSession.result;
final point = result.items?.first.geometry?.first.point;
```

### Построение маршрута через DrivingRouter

```dart
import 'package:yandex_maps_mapkit/directions.dart';

final drivingRouter = DirectionsFactory.instance.createDrivingRouter(DrivingRouterType.Combined);
final drivingSession = drivingRouter.requestRoutes(
  points: [
    RequestPoint(
      point: Point(latitude: 55.75, longitude: 37.62),
      requestPointType: RequestPointType.wayPoint,
    ),
    RequestPoint(
      point: Point(latitude: 55.76, longitude: 37.64),
      requestPointType: RequestPointType.wayPoint,
    ),
  ],
  drivingOptions: DrivingOptions(routesCount: 1),
);

final result = await drivingSession.result;
final route = result.routes?.first;
```

## 🐛 Известные проблемы

1. **Черный экран на карте**: Убедитесь, что API ключ настроен правильно в AppDelegate (iOS) и AndroidManifest (Android)
2. **Автозаполнение не работает**: Проверьте настройки boundingBox и cityContext
3. **Краши на Android**: Добавьте `<uses-permission android:name="android.permission.INTERNET"/>` в AndroidManifest.xml

## 📚 Документация

- [Yandex MapKit для Flutter](https://yandex.ru/dev/maps/mapkit/)
- [API Reference](https://pub.dev/packages/yandex_maps_mapkit)
- [Примеры использования](https://github.com/yandex/mapkit-flutter-examples)

## 💡 Советы

1. **Оптимизация**: Используйте `PlatformViewType.Hybrid` для лучшей производительности
2. **Темная тема**: Карта автоматически адаптируется к системной теме
3. **Управление жизненным циклом**: `FlutterMapWidget` автоматически управляет запуском/остановкой MapKit
4. **Дебаг**: Все логи выводятся с префиксом `[YANDEX MAPKIT]` или `[AUTOCOMPLETE]`

---

Создано: 16 ноября 2025 г.
