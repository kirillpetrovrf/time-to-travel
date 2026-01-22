# 🚕 ОТСЛЕЖИВАНИЕ ВОДИТЕЛЕЙ В РЕАЛЬНОМ ВРЕМЕНИ

## 📋 СОДЕРЖАНИЕ
1. [Концепция](#концепция)
2. [Сравнение: Yandex vs Google](#сравнение-yandex-vs-google)
3. [Архитектура решения](#архитектура-решения)
4. [Установка пакетов](#установка-пакетов)
5. [Реализация](#реализация)
6. [Альтернативные решения](#альтернативные-решения)

---

## 🎯 КОНЦЕПЦИЯ

### Ваш вопрос:
> "Если использовать Google сервисы, то мы сможем получать данные 
> маршрутизации пользователей и такси наших у которых будет приложение, 
> что бы знать где оно едет?"

### ✅ ОТВЕТ: ДА, НО...

**Google Maps SDK** сам по себе **НЕ** отслеживает водителей автоматически!

Нужна **комбинация сервисов:**

```
Google Maps SDK (карта) + Firebase (база данных) + Geolocator (GPS)
```

---

## 📊 СРАВНЕНИЕ: YANDEX VS GOOGLE

### Yandex Maps + Firebase:

| Компонент | Что делает | Стоимость |
|-----------|------------|-----------|
| **Yandex MapKit** | Показывает карту | ~1000₽+ |
| **Firebase Realtime DB** | Хранит координаты | Бесплатно (10GB) |
| **Geolocator** | Получает GPS | Бесплатно |

**Итого:** ~1000₽ + Firebase (бесплатно для малых проектов)

---

### Google Maps + Firebase:

| Компонент | Что делает | Стоимость |
|-----------|------------|-----------|
| **Google Maps SDK** | Показывает карту | $200 бесплатно/мес |
| **Firebase Realtime DB** | Хранит координаты | Бесплатно (10GB) |
| **Geolocator** | Получает GPS | Бесплатно |

**Итого:** Бесплатно (в рамках лимитов)

---

### ✅ РЕКОМЕНДАЦИЯ:

**Для отслеживания водителей:**
- Firebase Realtime Database (уже есть в проекте!)
- Geolocator (бесплатный пакет)
- **Карта на ваш выбор** (Yandex или Google)

**Вывод:** Отслеживание водителей работает **ОДИНАКОВО** с Yandex и Google картами!

---

## 🏗️ АРХИТЕКТУРА РЕШЕНИЯ

### Схема работы:

```
┌──────────────────────────────────────────────────────────────────┐
│                        FIREBASE CLOUD                             │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  /drivers                                                   │  │
│  │    ├── driver123                                            │  │
│  │    │   ├── location                                         │  │
│  │    │   │   ├── latitude: 55.751244                         │  │
│  │    │   │   ├── longitude: 37.618423                        │  │
│  │    │   │   ├── speed: 45.5                                 │  │
│  │    │   │   ├── heading: 180                                │  │
│  │    │   │   └── timestamp: 1697545678                       │  │
│  │    │   ├── status: "on_trip"                               │  │
│  │    │   └── currentTripId: "trip456"                        │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
        ↑                                      ↓
        │                                      │
        │ GPS каждые 10 сек                   │ Слушает изменения
        │                                      │
┌───────────────────┐              ┌───────────────────────┐
│  ПРИЛОЖЕНИЕ       │              │   ПРИЛОЖЕНИЕ          │
│  ВОДИТЕЛЯ         │              │   ПАССАЖИРА           │
│                   │              │                       │
│  [Geolocator]     │              │   [Firebase Listener] │
│       ↓           │              │         ↓             │
│  [Firebase Upload]│              │   [Google Maps]       │
│                   │              │   Показывает маркер   │
│  "Я здесь 📍"     │              │   "Водитель едет 🚕"  │
└───────────────────┘              └───────────────────────┘
```

### Как это работает:

1. **Приложение водителя:**
   - Получает GPS-координаты каждые 10 секунд
   - Отправляет в Firebase Realtime Database
   - Обновляет статус (едет, ждёт, свободен)

2. **Firebase:**
   - Хранит текущее местоположение всех водителей
   - Синхронизирует данные в реальном времени

3. **Приложение пассажира:**
   - Слушает изменения в Firebase
   - Обновляет маркер водителя на карте
   - Показывает расстояние до водителя
   - Обновляет ETA (время прибытия)

---

## 📦 УСТАНОВКА ПАКЕТОВ

### Шаг 1: Добавьте в `pubspec.yaml`

```yaml
dependencies:
  # ✅ УЖЕ ЕСТЬ в вашем проекте:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  
  # ➕ ДОБАВЬТЕ ЭТО:
  firebase_database: ^10.3.8  # Realtime Database (для GPS)
  geolocator: ^10.1.0         # GPS-координаты
  geocoding: ^2.1.1           # Адреса из координат
  
  # ЕСЛИ ВЫБЕРЕТЕ GOOGLE MAPS:
  google_maps_flutter: ^2.5.0
  
  # ЕСЛИ ОСТАНЕТЕСЬ НА YANDEX:
  # yandex_mapkit: ^4.1.0  # (уже есть)
```

### Шаг 2: Установите пакеты

```bash
flutter pub add firebase_database geolocator geocoding
```

### Шаг 3: Настройте разрешения

#### Android (`android/app/src/main/AndroidManifest.xml`):

```xml
<!-- ✅ УЖЕ ЕСТЬ у вас -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- ➕ ДОБАВЬТЕ ДЛЯ ФОНОВОГО ОТСЛЕЖИВАНИЯ -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

#### iOS (`ios/Runner/Info.plist`):

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Нужно для отображения вашего местоположения на карте</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Нужно для отслеживания вашего маршрута во время поездки</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Нужно для отслеживания вашего маршрута</string>
```

---

## 💻 РЕАЛИЗАЦИЯ

### 1️⃣ Сервис для отслеживания водителя

Создайте файл: `lib/services/driver_tracking_service.dart`

```dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class DriverTrackingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  Timer? _locationTimer;
  
  /// Начать отслеживание водителя (вызывать в приложении ВОДИТЕЛЯ)
  Future<void> startTracking(String driverId) async {
    // Проверка разрешений
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS отключен');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Нет разрешения на GPS');
      }
    }

    // Отправляем координаты каждые 10 секунд
    _locationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        await _updateDriverLocation(driverId);
      },
    );

    // Отправляем сразу при старте
    await _updateDriverLocation(driverId);
  }

  /// Обновить местоположение водителя
  Future<void> _updateDriverLocation(String driverId) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await _database.ref('drivers/$driverId/location').set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'accuracy': position.accuracy,
        'timestamp': ServerValue.timestamp,
      });

      print('📍 Местоположение водителя обновлено: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Ошибка обновления местоположения: $e');
    }
  }

  /// Остановить отслеживание
  void stopTracking(String driverId) {
    _locationTimer?.cancel();
    _database.ref('drivers/$driverId/location').remove();
    print('🛑 Отслеживание остановлено');
  }

  /// Обновить статус водителя
  Future<void> updateDriverStatus(
    String driverId, {
    required String status, // "free", "on_trip", "offline"
    String? currentTripId,
  }) async {
    await _database.ref('drivers/$driverId').update({
      'status': status,
      'currentTripId': currentTripId,
      'lastUpdated': ServerValue.timestamp,
    });
  }

  /// Слушать местоположение водителя (в приложении ПАССАЖИРА)
  Stream<Map<String, dynamic>> watchDriverLocation(String driverId) {
    return _database
        .ref('drivers/$driverId/location')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return <String, dynamic>{};
      }
      return Map<String, dynamic>.from(event.snapshot.value as Map);
    });
  }

  /// Получить всех доступных водителей рядом
  Stream<List<Map<String, dynamic>>> watchNearbyDrivers({
    required double userLatitude,
    required double userLongitude,
    double radiusInKm = 5.0,
  }) {
    return _database
        .ref('drivers')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];

      final driversMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      final nearbyDrivers = <Map<String, dynamic>>[];

      driversMap.forEach((driverId, driverData) {
        final data = Map<String, dynamic>.from(driverData);
        
        // Проверяем статус
        if (data['status'] != 'free') return;
        
        // Проверяем наличие координат
        if (data['location'] == null) return;
        
        final location = Map<String, dynamic>.from(data['location']);
        final driverLat = location['latitude'] as double;
        final driverLng = location['longitude'] as double;

        // Вычисляем расстояние
        final distance = Geolocator.distanceBetween(
          userLatitude,
          userLongitude,
          driverLat,
          driverLng,
        ) / 1000; // в километрах

        if (distance <= radiusInKm) {
          nearbyDrivers.add({
            'driverId': driverId,
            'latitude': driverLat,
            'longitude': driverLng,
            'distance': distance,
            ...data,
          });
        }
      });

      // Сортируем по расстоянию
      nearbyDrivers.sort((a, b) => 
        (a['distance'] as double).compareTo(b['distance'] as double)
      );

      return nearbyDrivers;
    });
  }
}
```

---

### 2️⃣ Экран для ВОДИТЕЛЯ (старт отслеживания)

```dart
import 'package:flutter/material.dart';
import 'package:time_to_travel/services/driver_tracking_service.dart';

class DriverModeScreen extends StatefulWidget {
  final String driverId;

  const DriverModeScreen({required this.driverId});

  @override
  _DriverModeScreenState createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends State<DriverModeScreen> {
  final DriverTrackingService _trackingService = DriverTrackingService();
  bool _isTracking = false;

  @override
  void dispose() {
    if (_isTracking) {
      _trackingService.stopTracking(widget.driverId);
    }
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      // Остановить отслеживание
      _trackingService.stopTracking(widget.driverId);
      await _trackingService.updateDriverStatus(
        widget.driverId,
        status: 'offline',
      );
      setState(() => _isTracking = false);
    } else {
      // Начать отслеживание
      try {
        await _trackingService.startTracking(widget.driverId);
        await _trackingService.updateDriverStatus(
          widget.driverId,
          status: 'free',
        );
        setState(() => _isTracking = true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Режим водителя')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTracking ? Icons.gps_fixed : Icons.gps_off,
              size: 100,
              color: _isTracking ? Colors.green : Colors.grey,
            ),
            SizedBox(height: 20),
            Text(
              _isTracking ? 'Отслеживание включено' : 'Отслеживание выключено',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _toggleTracking,
              child: Text(_isTracking ? 'Остановить' : 'Начать работу'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: _isTracking ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 3️⃣ Экран для ПАССАЖИРА (показать водителя на карте)

#### Вариант A: С Yandex Maps

```dart
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:time_to_travel/services/driver_tracking_service.dart';

class TrackDriverScreen extends StatefulWidget {
  final String driverId;

  const TrackDriverScreen({required this.driverId});

  @override
  _TrackDriverScreenState createState() => _TrackDriverScreenState();
}

class _TrackDriverScreenState extends State<TrackDriverScreen> {
  final DriverTrackingService _trackingService = DriverTrackingService();
  YandexMapController? _mapController;
  PlacemarkMapObject? _driverMarker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Водитель едет')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _trackingService.watchDriverLocation(widget.driverId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Водитель не найден'));
          }

          final location = snapshot.data!;
          final driverPoint = Point(
            latitude: location['latitude'],
            longitude: location['longitude'],
          );

          // Обновляем маркер водителя
          _driverMarker = PlacemarkMapObject(
            mapId: MapObjectId('driver'),
            point: driverPoint,
            icon: PlacemarkIcon.single(
              PlacemarkIconStyle(
                image: BitmapDescriptor.fromAssetImage('assets/images/taxi_marker.png'),
                scale: 0.5,
              ),
            ),
          );

          return YandexMap(
            mapObjects: [_driverMarker!],
            onMapCreated: (controller) {
              _mapController = controller;
              _mapController!.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: driverPoint, zoom: 15),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

#### Вариант B: С Google Maps

```dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:time_to_travel/services/driver_tracking_service.dart';

class TrackDriverScreen extends StatefulWidget {
  final String driverId;

  const TrackDriverScreen({required this.driverId});

  @override
  _TrackDriverScreenState createState() => _TrackDriverScreenState();
}

class _TrackDriverScreenState extends State<TrackDriverScreen> {
  final DriverTrackingService _trackingService = DriverTrackingService();
  GoogleMapController? _mapController;
  Marker? _driverMarker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Водитель едет')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _trackingService.watchDriverLocation(widget.driverId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Водитель не найден'));
          }

          final location = snapshot.data!;
          final driverPosition = LatLng(
            location['latitude'],
            location['longitude'],
          );

          // Обновляем маркер водителя
          _driverMarker = Marker(
            markerId: MarkerId('driver'),
            position: driverPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: 'Ваш водитель',
              snippet: 'Едет к вам',
            ),
          );

          // Перемещаем камеру к водителю
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(driverPosition),
          );

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: driverPosition,
              zoom: 15,
            ),
            markers: {_driverMarker!},
            myLocationEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          );
        },
      ),
    );
  }
}
```

---

## 🌟 ДОПОЛНИТЕЛЬНЫЕ ВОЗМОЖНОСТИ

### 1️⃣ Показать расстояние до водителя

```dart
StreamBuilder<Map<String, dynamic>>(
  stream: _trackingService.watchDriverLocation(driverId),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox();
    
    final location = snapshot.data!;
    final distance = Geolocator.distanceBetween(
      userLat,
      userLng,
      location['latitude'],
      location['longitude'],
    ) / 1000; // в км

    return Text('Водитель в ${distance.toStringAsFixed(1)} км от вас');
  },
);
```

### 2️⃣ Вычислить время прибытия (ETA)

```dart
double distance = 5.2; // км
double averageSpeed = 40.0; // км/ч
double eta = (distance / averageSpeed) * 60; // минуты

print('Водитель приедет через ${eta.toInt()} минут');
```

### 3️⃣ Показать маршрут водителя до пассажира

```dart
// Используйте Google Directions API или Yandex Routing
// Получите polyline (линию маршрута)
// Нарисуйте на карте
```

---

## 🆚 АЛЬТЕРНАТИВНЫЕ РЕШЕНИЯ

### 1️⃣ **Google Cloud Fleet Tracking** (профессиональное решение)

**Что это:**
- Специальный сервис Google для отслеживания флота такси
- Оптимизирован для коммерческих перевозок
- Встроенная маршрутизация и ETA

**Стоимость:**
- $0.05 за 1000 обновлений местоположения
- Бесплатно до 100,000 обновлений/месяц

**Документация:**
https://developers.google.com/maps/documentation/transportation-logistics

---

### 2️⃣ **Yandex Fleet API** (аналог от Яндекса)

**Что это:**
- API для управления парком такси
- Интеграция с Яндекс.Такси
- Автоматическое распределение заказов

**Стоимость:**
- По запросу (коммерческий продукт)

**Документация:**
https://yandex.ru/dev/fleet/

---

### 3️⃣ **Собственное решение на Firebase** (рекомендуется для старта)

**Что это:**
- Firebase Realtime Database + Geolocator
- Полный контроль над данными
- Бесплатно для малых проектов

**Стоимость:**
- Бесплатно до 10GB трафика
- $1/GB после превышения лимита

**Преимущества:**
- ✅ Простая интеграция (у вас уже есть Firebase!)
- ✅ Работает с любыми картами (Yandex/Google)
- ✅ Низкая стоимость

---

## 💰 СТОИМОСТЬ ОТСЛЕЖИВАНИЯ

### Пример расчёта для 100 водителей:

**Условия:**
- 100 водителей работают по 8 часов/день
- Обновление GPS каждые 10 секунд
- 30 дней в месяц

**Расчёт:**
```
Обновлений в час = 3600 сек / 10 сек = 360 обновлений
Обновлений за 8 часов = 360 × 8 = 2,880 обновлений
Обновлений за день (100 водителей) = 2,880 × 100 = 288,000
Обновлений за месяц = 288,000 × 30 = 8,640,000
```

**Стоимость Firebase:**
- Трафик: ~86 MB (при 10 байт на обновление)
- **Бесплатно!** (в рамках 10GB)

**Стоимость Google Fleet Tracking:**
- 8,640,000 обновлений
- 100,000 бесплатно
- (8,640,000 - 100,000) / 1000 × $0.05 = **$427/месяц**

**Вывод:** Firebase **в 427 раз дешевле** Google Fleet Tracking! 🎉

---

## ✅ РЕКОМЕНДАЦИЯ

### Для вашего проекта (Time to Travel):

**Используйте:**
1. ✅ **Firebase Realtime Database** (уже есть!)
2. ✅ **Geolocator** (бесплатный пакет)
3. ✅ **Yandex Maps** (если пополните баланс) ИЛИ **Google Maps** (если хотите бесплатно)

**Почему:**
- Уже есть Firebase в проекте
- Простая интеграция
- Практически бесплатно
- Работает одинаково с Yandex и Google картами

---

## 📝 КОНТРОЛЬНЫЙ СПИСОК

- [ ] Установить `firebase_database`, `geolocator`, `geocoding`
- [ ] Добавить разрешения GPS в AndroidManifest.xml и Info.plist
- [ ] Создать `DriverTrackingService`
- [ ] Создать экран для водителя (старт отслеживания)
- [ ] Создать экран для пассажира (показать водителя на карте)
- [ ] Протестировать на двух устройствах
- [ ] Настроить Firebase Realtime Database Rules (безопасность)

---

## 🔒 БЕЗОПАСНОСТЬ (Firebase Rules)

Настройте правила доступа к Firebase:

```json
{
  "rules": {
    "drivers": {
      "$driverId": {
        ".read": true,  // Все могут читать местоположение водителей
        ".write": "$driverId == auth.uid"  // Только сам водитель может обновлять
      }
    }
  }
}
```

---

## 🚀 СЛЕДУЮЩИЕ ШАГИ

1. **Решите:** Yandex или Google Maps?
2. **Установите пакеты:** `firebase_database`, `geolocator`
3. **Скопируйте код** `DriverTrackingService` (выше)
4. **Протестируйте** на двух устройствах

**Нужна помощь с интеграцией?** Дайте знать! 🎯
