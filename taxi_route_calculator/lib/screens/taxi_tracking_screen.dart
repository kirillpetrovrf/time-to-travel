import 'dart:async';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:taxi_route_calculator/services/trip_api_service.dart';
import 'package:yandex_maps_mapkit/image.dart' as image_provider;
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;

/// Экран отслеживания такси для клиента
/// 
/// Показывает карту с маркером такси в реальном времени
/// Автоматически обновляет позицию каждые 3 секунды
class TaxiTrackingScreen extends StatefulWidget {
  final String tripId;
  final String shareBaseUrl;

  const TaxiTrackingScreen({
    super.key,
    required this.tripId,
    this.shareBaseUrl = 'https://your-app.com/track',
  });

  @override
  State<TaxiTrackingScreen> createState() => _TaxiTrackingScreenState();
}

class _TaxiTrackingScreenState extends State<TaxiTrackingScreen> {
  mapkit.MapWindow? _mapWindow;
  mapkit.PlacemarkMapObject? _taxiPlacemark;
  Timer? _updateTimer;
  final TripApiService _apiService = TripApiService();

  TaxiLocationData? _currentTaxiLocation;
  TripData? _tripData;
  bool _isLoading = true;
  String? _errorMessage;

  // Иконка такси (используем встроенную иконку из assets)
  late final _taxiIconProvider = image_provider.ImageProvider.fromImageProvider(
    const AssetImage("assets/search_result.png"),
  );

  @override
  void initState() {
    super.initState();
    _fetchTripDetails();
    _startLocationUpdates();
  }

  /// Загрузить детали поездки
  Future<void> _fetchTripDetails() async {
    try {
      final tripData = await _apiService.fetchTripDetails(widget.tripId);
      if (mounted) {
        setState(() {
          _tripData = tripData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Запустить автоматическое обновление позиции такси
  void _startLocationUpdates() {
    // Сразу загружаем первую локацию
    _fetchTaxiLocation();

    // Затем обновляем каждые 3 секунды
    _updateTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _fetchTaxiLocation(),
    );
    
    print('⏱️ Started location updates every 3 seconds');
  }

  /// Получить текущую локацию такси с backend
  Future<void> _fetchTaxiLocation() async {
    try {
      final location = await _apiService.fetchTaxiLocation(widget.tripId);
      if (location != null && mounted) {
        setState(() {
          _currentTaxiLocation = location;
          _errorMessage = null;
        });
        _updateTaxiMarker(location);
        print('📍 Taxi location: ${location.latitude}, ${location.longitude}');
      }
    } catch (e) {
      print('⚠️ Error fetching taxi location: $e');
    }
  }

  /// Обновить маркер такси на карте
  void _updateTaxiMarker(TaxiLocationData location) {
    if (_mapWindow == null) return;

    final map = _mapWindow!.map;
    final mapObjects = map.mapObjects;

    if (_taxiPlacemark == null) {
      // Создаём маркер такси первый раз
      _taxiPlacemark = mapObjects.addPlacemark()
        ..geometry = location.toPoint()
        ..setIcon(_taxiIconProvider)
        ..setIconStyle(const mapkit.IconStyle(
          rotationType: mapkit.RotationType.Rotate,
          scale: 0.8,
        ))
        ..direction = location.bearing;

      print('🚕 Created taxi marker');
      
      // Центрируем камеру на такси
      _moveCameraToTaxi(location.toPoint(), zoom: 16.0);
    } else {
      // Обновляем позицию существующего маркера
      _taxiPlacemark!.geometry = location.toPoint();
      _taxiPlacemark!.direction = location.bearing;

      // Плавно двигаем камеру вслед за такси
      _moveCameraToTaxi(location.toPoint(), animate: true);
    }
  }

  /// Передвинуть камеру на позицию такси
  void _moveCameraToTaxi(mapkit.Point position, {bool animate = false, double zoom = 15.0}) {
    if (_mapWindow == null) return;

    final map = _mapWindow!.map;
    final cameraPosition = mapkit.CameraPosition(
      position,
      zoom: zoom,
      azimuth: 0.0,
      tilt: 0.0,
    );

    if (animate) {
      map.moveWithAnimation(
        cameraPosition,
        mapkit.Animation(mapkit.AnimationType.Smooth, duration: 1.0),
      );
    } else {
      map.move(cameraPosition);
    }
  }

  /// Поделиться ссылкой на отслеживание
  void _shareTrackingLink() {
    final shareUrl = '${widget.shareBaseUrl}/${widget.tripId}';
    Share.share(
      'Отследите моё такси в реальном времени: $shareUrl',
      subject: 'Отслеживание такси',
    );
    print('📤 Shared tracking link: $shareUrl');
  }

  /// Построить индикатор состояния поездки
  Widget _buildTripStatus() {
    if (_tripData == null) return const SizedBox.shrink();

    String statusText;
    Color statusColor;

    switch (_tripData!.status) {
      case 'created':
        statusText = 'Ожидание водителя';
        statusColor = Colors.orange;
        break;
      case 'in_progress':
        statusText = 'В пути';
        statusColor = Colors.green;
        break;
      case 'completed':
        statusText = 'Завершено';
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusText = 'Отменено';
        statusColor = Colors.red;
        break;
      default:
        statusText = _tripData!.status;
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          const Spacer(),
          if (_currentTaxiLocation != null) ...[
            const Icon(Icons.speed, size: 18, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              '${(_currentTaxiLocation!.speed * 3.6).toStringAsFixed(0)} км/ч',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отслеживание такси'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTrackingLink,
            tooltip: 'Поделиться ссылкой',
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentTaxiLocation != null) {
                _moveCameraToTaxi(_currentTaxiLocation!.toPoint(), zoom: 16.0);
              }
            },
            tooltip: 'Показать такси',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });
                          _fetchTripDetails();
                        },
                        child: const Text('Попробовать снова'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // Карта
                    FlutterMapWidget(
                      onMapCreated: (mapWindow) {
                        _mapWindow = mapWindow;
                        print('🗺️ Map created');
                        
                        // Если уже есть данные о такси, показываем
                        if (_currentTaxiLocation != null) {
                          _updateTaxiMarker(_currentTaxiLocation!);
                        }
                      },
                    ),

                    // Статус поездки (сверху)
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: _buildTripStatus(),
                    ),

                    // Информация о последнем обновлении (снизу)
                    if (_currentTaxiLocation != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time, size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Обновлено: ${_formatTime(_currentTaxiLocation!.timestamp)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} сек назад';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else {
      return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _apiService.dispose();
    super.dispose();
  }
}
