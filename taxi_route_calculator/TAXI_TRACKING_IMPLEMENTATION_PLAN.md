# 🚖 ПОЛНЫЙ ПЛАН РЕАЛИЗАЦИИ ОТСЛЕЖИВАНИЯ ТАКСИ В РЕАЛЬНОМ ВРЕМЕНИ

## ✅ ЧТО УЖЕ СДЕЛАНО (ГОТОВО К ИСПОЛЬЗОВАНИЮ):

### 1. ✅ `lib/services/trip_api_service.dart` - HTTP API клиент
**Статус:** Полностью готов ✅

**Что есть:**
- `createTrip()` - создать новую поездку
- `startTrip()` - начать поездку  
- `sendDriverLocation()` - отправить GPS водителя на backend
- `fetchTaxiLocation()` - получить текущую позицию такси
- `fetchTripDetails()` - получить детали поездки
- `completeTrip()` - завершить поездку
- `cancelTrip()` - отменить поездку

**Модели данных:**
- `TaxiLocationData` - координаты такси (lat, lng, bearing, speed)
- `TripData` - информация о поездке (from, to, status)

**Как использовать:**
```dart
final apiService = TripApiService();

// Создать поездку
final tripId = await apiService.createTrip(
  from: Point(latitude: 58.0, longitude: 56.2),
  to: Point(latitude: 58.1, longitude: 56.3),
  driverId: 'driver123',
  customerId: 'customer456',
);

// Отправить GPS
await apiService.sendDriverLocation(
  tripId: tripId,
  latitude: 58.0005,
  longitude: 56.2005,
  bearing: 45.0,
  speed: 15.5,
);

// Получить позицию такси
final location = await apiService.fetchTaxiLocation(tripId);
print('Такси на: ${location?.latitude}, ${location?.longitude}');
```

---

### 2. ✅ `lib/services/taxi_driver_location_service.dart` - Сервис водителя
**Статус:** Полностью готов ✅

**Что есть:**
- Автоматическая отправка GPS каждые 5 секунд
- `Purpose.General` с фоновой работой (`LocationUseInBackground.Allow`)
- `startTrip(tripId)` - начать отслеживание
- `stopTrip()` - остановить отслеживание
- `cancelTrip(reason)` - отменить поездку

**Как использовать:**
```dart
// Инициализация
final driverService = TaxiDriverLocationService(
  locationManager: mapkitFactory.createLocationManager(),
  sendIntervalSeconds: 5, // Отправлять каждые 5 секунд
);

// Начать поездку (начнёт автоматически отправлять GPS)
await driverService.startTrip('trip_abc123');

// Остановить
await driverService.stopTrip();
```

**Логи:**
```
🚕 Starting trip tracking for: trip_abc123
🎯 GPS mode: Purpose.General with background location
✅ Subscribed to location updates
⏱️ Location send timer started (every 5 sec)
📍 Driver location updated: lat=58.000438, lng=56.242981, speed=12.3 m/s
📤 Sent location to backend for trip: trip_abc123
```

---

### 3. ✅ `pubspec.yaml` - Зависимости установлены
**Статус:** Готово ✅

Добавлены пакеты:
- `http: ^1.1.0` - для API запросов
- `share_plus: ^7.2.1` - для sharing ссылок
- `url_launcher: ^6.2.1` - для открытия ссылок

---

## 🚧 ЧТО НУЖНО ДОДЕЛАТЬ:

### 4. 📱 Экран отслеживания для клиента (`lib/screens/taxi_tracking_screen.dart`)

**Проблема:** Сложности с API Yandex MapKit (конфликты типов Icon, TextStyle, Animation)

**Решение:** Использовать как референс `lib/features/main_screen.dart`

**Что нужно реализовать:**

```dart
class TaxiTrackingScreen extends StatefulWidget {
  final String tripId;
  final String shareBaseUrl;
  
  // Конструктор и State
}

class _TaxiTrackingScreenState extends State<TaxiTrackingScreen> {
  // 1. Переменные
  mapkit.MapWindow? _mapWindow;
  mapkit.PlacemarkMapObject? _taxiPlacemark;
  Timer? _updateTimer;
  TripApiService _apiService = TripApiService();
  
  // 2. InitState - запустить обновления
  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }
  
  // 3. Таймер обновления каждые 3 секунды
  void _startLocationUpdates() {
    _updateTimer = Timer.periodic(Duration(seconds: 3), (_) {
      _fetchAndUpdateTaxiLocation();
    });
  }
  
  // 4. Получить координаты с backend и обновить маркер
  Future<void> _fetchAndUpdateTaxiLocation() async {
    final location = await _apiService.fetchTaxiLocation(widget.tripId);
    if (location != null) {
      _updateTaxiMarker(location);
    }
  }
  
  // 5. Обновить маркер такси на карте
  void _updateTaxiMarker(TaxiLocationData location) {
    if (_taxiPlacemark == null) {
      // Создать новый маркер
      final mapObjects = _mapWindow!.map.mapObjects;
      _taxiPlacemark = mapObjects.addPlacemark()
        ..geometry = location.toPoint()
        ..setIcon(_taxiIconProvider)
        ..setIconStyle(const mapkit.IconStyle(
          rotationType: mapkit.RotationType.Rotate,
          scale: 0.8,
        ))
        ..direction = location.bearing;
      
      // Центрировать камеру
      _moveCamera(location.toPoint(), zoom: 16.0);
    } else {
      // Обновить существующий
      _taxiPlacemark!.geometry = location.toPoint();
      _taxiPlacemark!.direction = location.bearing;
      _moveCamera(location.toPoint(), animate: true);
    }
  }
  
  // 6. Двигать камеру вслед за такси
  void _moveCamera(mapkit.Point point, {bool animate = false, double zoom = 15.0}) {
    final cameraPosition = mapkit.CameraPosition(point, zoom: zoom);
    if (animate) {
      _mapWindow!.map.moveWithAnimation(
        cameraPosition,
        const mapkit.Animation(mapkit.AnimationType.Smooth, duration: 1.0),
      );
    } else {
      _mapWindow!.map.move(cameraPosition);
    }
  }
  
  // 7. Поделиться ссылкой
  void _shareTrackingLink() {
    final link = '${widget.shareBaseUrl}/${widget.tripId}';
    Share.share('Отследите моё такси: $link');
  }
  
  // 8. UI с картой
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отслеживание такси'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: _shareTrackingLink,
          ),
        ],
      ),
      body: mapkit.YandexMapWidget(
        onMapCreated: (mapWindow) {
          _mapWindow = mapWindow;
        },
      ),
    );
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }
}
```

**Файл с документацией:** `lib/screens/TAXI_TRACKING_SCREEN_DOCS.dart`

---

### 5. 🔗 Интеграция в `main_screen.dart`

Добавить кнопки для тестирования:

```dart
// В _MainScreenState добавить:
TaxiDriverLocationService? _driverService;

// В initState:
@override
void initState() {
  super.initState();
  _driverService = TaxiDriverLocationService(
    locationManager: _locationManager,
  );
}

// Добавить кнопки в UI:
Row(
  children: [
    ElevatedButton.icon(
      onPressed: () async {
        // Создать поездку
        final tripId = await _apiService.createTrip(...);
        
        // Начать отслеживание (водитель)
        await _driverService!.startTrip(tripId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Поездка начата: $tripId')),
        );
      },
      icon: Icon(Icons.play_arrow),
      label: Text('Начать поездку'),
    ),
    SizedBox(width: 16),
    ElevatedButton.icon(
      onPressed: () {
        // Открыть экран отслеживания (клиент)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TaxiTrackingScreen(
              tripId: 'test_trip_id',
              shareBaseUrl: 'https://your-app.com/track',
            ),
          ),
        );
      },
      icon: Icon(Icons.map),
      label: Text('Отследить такси'),
    ),
  ],
)
```

---

### 6. 📱 Android Permissions для фоновой геолокации

**Файл:** `android/app/src/main/AndroidManifest.xml`

Добавить:
```xml
<manifest>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <!-- Для фоновой работы (Android 10+) -->
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    
    <!-- Для работы в фоне -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    
    <application>
        ...
    </application>
</manifest>
```

**Запрос permission в коде:**
```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestBackgroundLocationPermission() async {
  if (await Permission.locationAlways.request().isGranted) {
    print('✅ Background location permission granted');
  } else {
    print('❌ Background location permission denied');
  }
}
```

---

### 7. 🌐 Backend API (Пример на Node.js/Express)

**Файл:** `server.js`

```javascript
const express = require('express');
const app = express();
const redis = require('redis').createClient();

app.use(express.json());

// Создать поездку
app.post('/api/trips', (req, res) => {
  const tripId = 'trip_' + Date.now();
  const tripData = {
    tripId,
    from: req.body.from,
    to: req.body.to,
    driverId: req.body.driverId,
    customerId: req.body.customerId,
    status: 'created',
    createdAt: new Date().toISOString(),
  };
  
  redis.setex(`trip:${tripId}`, 3600, JSON.stringify(tripData));
  res.json({ tripId });
});

// Начать поездку
app.patch('/api/trips/:tripId/start', (req, res) => {
  const { tripId } = req.params;
  redis.get(`trip:${tripId}`, (err, data) => {
    if (!data) return res.status(404).json({ error: 'Trip not found' });
    
    const trip = JSON.parse(data);
    trip.status = 'in_progress';
    trip.startedAt = new Date().toISOString();
    
    redis.setex(`trip:${tripId}`, 3600, JSON.stringify(trip));
    res.json({ success: true });
  });
});

// Отправить GPS водителя
app.post('/api/trips/:tripId/location', (req, res) => {
  const { tripId } = req.params;
  const locationData = {
    latitude: req.body.latitude,
    longitude: req.body.longitude,
    bearing: req.body.bearing || 0,
    speed: req.body.speed || 0,
    timestamp: new Date().toISOString(),
  };
  
  // Храним локацию 5 минут (300 сек)
  redis.setex(`trip:${tripId}:location`, 300, JSON.stringify(locationData));
  
  console.log(`📍 Location updated for ${tripId}:`, locationData);
  res.json({ success: true });
});

// Получить текущую локацию такси (для клиента)
app.get('/api/trips/:tripId/location', (req, res) => {
  const { tripId } = req.params;
  redis.get(`trip:${tripId}:location`, (err, data) => {
    if (!data) return res.status(404).json({ error: 'Location not found' });
    res.json(JSON.parse(data));
  });
});

// Получить детали поездки
app.get('/api/trips/:tripId', (req, res) => {
  const { tripId } = req.params;
  redis.get(`trip:${tripId}`, (err, data) => {
    if (!data) return res.status(404).json({ error: 'Trip not found' });
    res.json(JSON.parse(data));
  });
});

// Завершить поездку
app.patch('/api/trips/:tripId/complete', (req, res) => {
  const { tripId } = req.params;
  redis.get(`trip:${tripId}`, (err, data) => {
    if (!data) return res.status(404).json({ error: 'Trip not found' });
    
    const trip = JSON.parse(data);
    trip.status = 'completed';
    trip.completedAt = new Date().toISOString();
    
    redis.setex(`trip:${tripId}`, 3600, JSON.stringify(trip));
    res.json({ success: true });
  });
});

app.listen(3000, () => {
  console.log('🚖 Backend API running on http://localhost:3000');
});
```

**Запуск:**
```bash
npm install express redis
node server.js
```

**Для тестирования из эмулятора/устройства:**
- Android emulator: `http://10.0.2.2:3000/api`
- iOS simulator: `http://localhost:3000/api`
- Реальное устройство: `http://YOUR_LOCAL_IP:3000/api`

Замените в `lib/services/trip_api_service.dart`:
```dart
static const String BASE_URL = 'http://10.0.2.2:3000/api'; // Android
```

---

## 🎯 ИТОГОВЫЙ ЧЕКЛИСТ:

- [x] 1. HTTP API сервис (trip_api_service.dart) ✅
- [x] 2. Сервис водителя (taxi_driver_location_service.dart) ✅
- [x] 3. Зависимости (pubspec.yaml) ✅
- [ ] 4. Экран отслеживания (taxi_tracking_screen.dart) ⚠️ Нужно доделать
- [ ] 5. Интеграция в main_screen.dart ⏳
- [ ] 6. Android permissions ⏳
- [ ] 7. Backend API ⏳
- [ ] 8. Тестирование ⏳

---

## 🚀 КАК НАЧАТЬ:

1. **Backend:** Запустите сервер из раздела 7
2. **Измените BASE_URL** в `trip_api_service.dart` на ваш локальный IP
3. **Добавьте permissions** в AndroidManifest.xml (раздел 6)
4. **Доделайте TaxiTrackingScreen** используя документацию и main_screen.dart как пример
5. **Интегрируйте кнопки** в main_screen.dart (раздел 5)
6. **Тестируйте:**
   - Нажмите "Начать поездку" → Начнётся отправка GPS
   - Откройте backend логи → Увидите `📍 Location updated`
   - Нажмите "Отследить такси" → Увидите карту с обновляющимся маркером

---

## 📖 ДОПОЛНИТЕЛЬНЫЕ МАТЕРИАЛЫ:

- **Документация экрана:** `lib/screens/TAXI_TRACKING_SCREEN_DOCS.dart`
- **Пример работы с картой:** `lib/features/main_screen.dart` (строки 1105-1125)
- **Пример LocationManager:** `map_with_user_placemark/lib/camera/camera_manager.dart`

---

## ❓ ЧАСТО ЗАДАВАЕМЫЕ ВОПРОСЫ:

**Q: Как клиент получает ссылку на отслеживание?**
A: Водитель может отправить ссылку через:
- SMS: "Ваше такси в пути: https://app.com/track/trip_abc123"
- WhatsApp/Telegram
- Email
- Push-уведомление

**Q: Как работает обновление в реальном времени?**
A: 
1. Телефон водителя отправляет GPS каждые 5 сек на backend
2. Backend хранит последнюю локацию в Redis
3. Клиент запрашивает локацию каждые 3 сек с backend
4. Клиент обновляет маркер на карте

**Q: Нужен ли WebSocket?**
A: Нет, можно использовать polling (HTTP GET каждые 3 сек). Для производства рекомендуется WebSocket или Firebase Realtime Database.

**Q: Работает ли в фоне?**
A: Да, благодаря `LocationUseInBackground.Allow` и permissions `ACCESS_BACKGROUND_LOCATION`.

**Q: Сколько данных потребляет?**
A: ~1-2 KB на каждый запрос. При отправке каждые 5 сек = ~12 запросов/мин = ~720 запросов/час = ~1.5 MB/час.

---

## ✅ ГОТОВО К ИСПОЛЬЗОВАНИЮ СЕЙЧАС:

```dart
// Создайте сервис и начните поездку:
final driverService = TaxiDriverLocationService(
  locationManager: mapkitFactory.createLocationManager(),
);

await driverService.startTrip('test_trip_123');

// GPS автоматически отправляется каждые 5 секунд!
// Проверьте логи: 📍 Driver location updated...
```

Удачи в разработке! 🚖✨
