import 'dart:async';
import 'package:taxi_route_calculator/services/trip_api_service.dart';
import 'package:taxi_route_calculator/location/location_listener_impl.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';

/// Сервис для водителя такси: отслеживание GPS и отправка на backend
/// 
/// Использует Purpose.General с фоновой работой для точного GPS
/// Отправляет координаты каждые 5 секунд во время активной поездки
class TaxiDriverLocationService {
  final LocationManager _locationManager;
  final TripApiService _apiService;

  Timer? _sendTimer;
  LocationListener? _locationListener;
  Location? _lastLocation;
  String? _activeTripId;
  bool _isTracking = false;

  /// Интервал отправки GPS на сервер (секунды)
  final int sendIntervalSeconds;

  TaxiDriverLocationService({
    required LocationManager locationManager,
    TripApiService? apiService,
    this.sendIntervalSeconds = 5,
  })  : _locationManager = locationManager,
        _apiService = apiService ?? TripApiService();

  /// Начать отслеживание поездки
  /// Подписывается на GPS с высокой точностью и включает фоновую работу
  Future<void> startTrip(String tripId) async {
    if (_isTracking) {
      print('⚠️ Tracking already started for trip: $_activeTripId');
      return;
    }

    _activeTripId = tripId;
    _isTracking = true;

    print('🚕 Starting trip tracking for: $tripId');
    print('🎯 GPS mode: Purpose.General with background location');

    // Создаём LocationListener для получения обновлений GPS
    _locationListener = LocationListenerImpl(
      onLocationUpdate: _onLocationUpdated,
      onLocationStatusUpdate: _onLocationStatusUpdated,
    );

    // Подписываемся на обновления локации с высокой точностью
    // ⚠️ ВАЖНО: LocationUseInBackground.Allow обеспечивает работу в фоне
    // ⚠️ Purpose.General дает точное определение GPS для навигации
    try {
      _locationManager.subscribeForLocationUpdates(
        const LocationSubscriptionSettings(
          LocationUseInBackground.Allow, // ← Работа в фоне!
          Purpose.General, // ← Высокая точность GPS для навигации!
        ),
        _locationListener!,
      );
      print('✅ Subscribed to location updates');
    } catch (e) {
      print('❌ Failed to subscribe to location: $e');
      _isTracking = false;
      return;
    }

    // Уведомляем backend о начале поездки
    try {
      await _apiService.startTrip(tripId);
      print('✅ Trip started on backend');
    } catch (e) {
      print('⚠️ Failed to notify backend about trip start: $e');
    }

    // Запускаем таймер отправки локации на сервер
    _sendTimer = Timer.periodic(
      Duration(seconds: sendIntervalSeconds),
      (_) => _sendLocationToBackend(),
    );
    print('⏱️ Location send timer started (every $sendIntervalSeconds sec)');
  }

  /// Callback при получении новых GPS координат
  void _onLocationUpdated(Location location) {
    _lastLocation = location;
    
    print('📍 Driver location updated: '
        'lat=${location.position.latitude.toStringAsFixed(6)}, '
        'lng=${location.position.longitude.toStringAsFixed(6)}, '
        'speed=${location.speed?.toStringAsFixed(1) ?? "0"} m/s, '
        'bearing=${location.heading?.toStringAsFixed(1) ?? "0"}°');
  }

  /// Callback при изменении статуса GPS
  void _onLocationStatusUpdated(LocationStatus status) {
    print('📡 Location status: $status');
    
    // Можно показать уведомление если GPS выключен
    if (status == LocationStatus.NotAvailable) {
      print('⚠️ GPS not available! Please enable location services');
    }
  }

  /// Отправить текущую локацию на backend
  Future<void> _sendLocationToBackend() async {
    if (!_isTracking || _activeTripId == null || _lastLocation == null) {
      return;
    }

    try {
      await _apiService.sendDriverLocation(
        tripId: _activeTripId!,
        latitude: _lastLocation!.position.latitude,
        longitude: _lastLocation!.position.longitude,
        bearing: _lastLocation!.heading,
        speed: _lastLocation!.speed,
        accuracy: _lastLocation!.accuracy,
      );
      print('📤 Sent location to backend for trip: $_activeTripId');
    } catch (e) {
      print('❌ Failed to send location: $e');
      // Не прерываем работу - продолжаем отслеживание
    }
  }

  /// Остановить отслеживание поездки
  Future<void> stopTrip() async {
    if (!_isTracking) {
      print('⚠️ Tracking is not active');
      return;
    }

    print('🛑 Stopping trip tracking for: $_activeTripId');

    // Останавливаем таймер
    _sendTimer?.cancel();
    _sendTimer = null;

    // Отписываемся от GPS обновлений
    if (_locationListener != null) {
      _locationManager.unsubscribe(_locationListener!);
      print('✅ Unsubscribed from location updates');
    }

    // Отправляем последнюю локацию
    if (_lastLocation != null && _activeTripId != null) {
      await _sendLocationToBackend();
    }

    // Уведомляем backend о завершении
    if (_activeTripId != null) {
      try {
        await _apiService.completeTrip(_activeTripId!);
        print('✅ Trip completed on backend');
      } catch (e) {
        print('⚠️ Failed to complete trip on backend: $e');
      }
    }

    // Сбрасываем состояние
    _isTracking = false;
    _activeTripId = null;
    _lastLocation = null;
    _locationListener = null;

    print('✅ Trip tracking stopped');
  }

  /// Отменить поездку
  Future<void> cancelTrip(String reason) async {
    if (!_isTracking || _activeTripId == null) {
      print('⚠️ No active trip to cancel');
      return;
    }

    print('❌ Cancelling trip: $_activeTripId, reason: $reason');

    // Останавливаем отслеживание
    _sendTimer?.cancel();
    if (_locationListener != null) {
      _locationManager.unsubscribe(_locationListener!);
    }

    // Уведомляем backend
    try {
      await _apiService.cancelTrip(_activeTripId!, reason);
      print('✅ Trip cancelled on backend');
    } catch (e) {
      print('⚠️ Failed to cancel trip on backend: $e');
    }

    // Сбрасываем состояние
    _isTracking = false;
    _activeTripId = null;
    _lastLocation = null;
    _locationListener = null;
  }

  /// Получить текущую локацию (для тестирования)
  Location? get currentLocation => _lastLocation;

  /// Проверка активности отслеживания
  bool get isTracking => _isTracking;

  /// ID текущей поездки
  String? get activeTripId => _activeTripId;

  /// Освободить ресурсы
  void dispose() {
    if (_isTracking) {
      stopTrip();
    }
    _apiService.dispose();
  }
}
