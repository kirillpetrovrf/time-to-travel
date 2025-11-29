# 🔗 ИНТЕГРАЦИЯ ТАКСИ В MAIN_SCREEN.DART

## ШАГ 1: Добавить импорты

```dart
// В начало файла lib/features/main_screen.dart добавить:
import 'package:taxi_route_calculator/services/trip_api_service.dart';
import 'package:taxi_route_calculator/services/taxi_driver_location_service.dart';
import 'package:taxi_route_calculator/screens/taxi_tracking_screen.dart';
```

## ШАГ 2: Добавить переменные в _MainScreenState

```dart
class _MainScreenState extends State<MainScreen> {
  // ... существующие переменные ...
  
  // Taxi tracking services
  TaxiDriverLocationService? _driverService;
  TripApiService? _apiService;
  String? _currentTripId;
  mapkit.LocationManager? _locationManager;
```

## ШАГ 3: Инициализировать сервисы в initState()

```dart
@override
void initState() {
  super.initState();
  
  // ... существующий код ...
  
  // Initialize taxi tracking services
  _apiService = TripApiService();
  print('🚖 TripApiService initialized');
}
```

## ШАГ 4: Добавить dispose

```dart
@override
void dispose() {
  // ... существующий код ...
  
  _driverService?.dispose();
  _apiService?.dispose();
  print('🧹 MainScreen disposed (including taxi services)');
  
  super.dispose();
}
```

## ШАГ 5: Добавить методы

```dart
/// Начать поездку такси (для водителя)
Future<void> _startTrip() async {
  print('🚕 Starting taxi trip...');
  
  try {
    // Проверяем есть ли маршрут
    final points = _routePointsManager.points;
    if (points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала постройте маршрут (откуда → куда)')),
      );
      return;
    }
    
    // Создаём поездку на backend
    final tripId = await _apiService!.createTrip(
      from: points.first,
      to: points.last,
      driverId: 'driver_test_001',
      customerId: 'customer_test_001',
    );
    
    setState(() {
      _currentTripId = tripId;
    });
    
    print('✅ Trip created: $tripId');
    
    // Инициализируем LocationManager если ещё не создан
    if (_locationManager == null) {
      _locationManager = mapkitFactory.createLocationManager();
    }
    
    // Создаём сервис водителя если ещё не создан
    if (_driverService == null) {
      _driverService = TaxiDriverLocationService(
        locationManager: _locationManager!,
        sendIntervalSeconds: 5,
      );
    }
    
    // Начинаем отслеживание GPS
    await _driverService!.startTrip(tripId);
    
    // Показываем уведомление с ссылкой для клиента
    final shareLink = 'https://your-app.com/track/$tripId';
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Поездка начата!\nСсылка для клиента:\n$shareLink'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Копировать',
            onPressed: () {
              // TODO: Добавить копирование в буфер обмена
              print('📋 Copied link: $shareLink');
            },
          ),
        ),
      );
    }
    
    print('🚀 GPS tracking started! Location sent every 5 seconds');
    
  } catch (e) {
    print('❌ Error starting trip: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }
}

/// Остановить поездку
Future<void> _stopTrip() async {
  if (_currentTripId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Нет активной поездки')),
    );
    return;
  }
  
  print('🛑 Stopping trip: $_currentTripId');
  
  try {
    await _driverService?.stopTrip();
    setState(() {
      _currentTripId = null;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Поездка завершена')),
      );
    }
    
    print('✅ Trip stopped successfully');
  } catch (e) {
    print('❌ Error stopping trip: $e');
  }
}

/// Открыть экран отслеживания (для клиента)
void _openTrackingScreen() {
  // Тестовый tripId - в реальности клиент получает его через ссылку
  final testTripId = _currentTripId ?? 'test_trip_123';
  
  print('📱 Opening tracking screen for trip: $testTripId');
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TaxiTrackingScreen(
        tripId: testTripId,
        shareBaseUrl: 'https://your-app.com/track',
      ),
    ),
  );
}
```

## ШАГ 6: Добавить кнопки в UI

Найдите в методе `build()` место где кнопка меню (around line 690):

```dart
// ВМЕСТО ЭТОГО:
Positioned(
  bottom: 16,
  left: 16,
  child: FloatingActionButton(
    heroTag: "menu_button",
    // ...
  ),
),

// СДЕЛАЙТЕ ТАК:
Positioned(
  bottom: 16,
  left: 16,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Кнопка "Начать/Остановить поездку"
      FloatingActionButton.extended(
        heroTag: "trip_toggle",
        onPressed: _currentTripId == null ? _startTrip : _stopTrip,
        backgroundColor: _currentTripId == null ? Colors.green : Colors.red,
        icon: Icon(
          _currentTripId == null ? Icons.play_arrow : Icons.stop,
          color: Colors.white,
        ),
        label: Text(
          _currentTripId == null ? 'Начать' : 'Стоп',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      const SizedBox(height: 8),
      
      // Кнопка "Отследить"
      FloatingActionButton(
        heroTag: "track_taxi",
        mini: true,
        backgroundColor: Colors.blue,
        onPressed: _openTrackingScreen,
        child: const Icon(Icons.map, color: Colors.white),
      ),
      const SizedBox(height: 8),
      
      // Оригинальная кнопка меню
      FloatingActionButton(
        heroTag: "menu_button",
        mini: true,
        backgroundColor: Colors.white,
        onPressed: () => _showMenuBottomSheet(context),
        child: const Icon(Icons.more_vert, color: Colors.black54),
      ),
    ],
  ),
),
```

## ГОТОВО! ✅

Теперь в вашем приложении:

1. **Зеленая кнопка "Начать"** - начинает поездку, отправляет GPS каждые 5 сек
2. **Синяя кнопка с картой** - открывает экран отслеживания
3. **Красная кнопка "Стоп"** - завершает поездку

### Тестирование:

1. Запустите backend: `node server.js`
2. Измените BASE_URL в `trip_api_service.dart` на `http://10.0.2.2:3000/api`
3. Постройте маршрут (точка А → точка Б)
4. Нажмите "Начать" → GPS начнёт отправляться
5. Нажмите синюю кнопку → увидите карту с маркером такси
6. В логах backend увидите: `📍 Location updated for trip_xxx`

### Примечания:

- В production замените `driver_test_001` на реальный ID водителя
- Добавьте копирование ссылки в буфер обмена через `flutter/services.dart`
- Используйте Firebase/WebSocket для real-time обновлений вместо polling
