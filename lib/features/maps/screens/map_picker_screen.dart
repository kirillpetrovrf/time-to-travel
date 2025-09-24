import 'package:flutter/cupertino.dart';
// import 'package:yandex_mapkit/yandex_mapkit.dart'; // Раскомментировать после настройки API ключа
import '../../../config/map_config.dart';

/// Экран выбора точки на карте
///
/// Этот экран будет использоваться для:
/// - Выбора точки посадки
/// - Выбора точки высадки
/// - Просмотра маршрута поездки
/// - Отслеживания местоположения во время поездки
class MapPickerScreen extends StatefulWidget {
  final MapPointType pointType;
  final MapPoint? initialPoint;
  final String title;

  const MapPickerScreen({
    super.key,
    required this.pointType,
    this.initialPoint,
    required this.title,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  MapPoint? _selectedPoint;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selectedPoint != null ? _confirmSelection : null,
          child: const Text('Готово'),
        ),
      ),
      child: _buildMapPlaceholder(),
    );
  }

  /// Временная заглушка вместо карты
  Widget _buildMapPlaceholder() {
    return Container(
      color: CupertinoColors.systemGrey5,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.map,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Карта будет здесь',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Для использования карт нужно:\n'
              '1. Получить API ключ Yandex MapKit\n'
              '2. Настроить конфигурацию\n'
              '3. Раскомментировать код карты',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey2,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _simulatePointSelection,
              child: const Text('Симулировать выбор точки'),
            ),
            if (_selectedPoint != null) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CupertinoColors.separator),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Выбранная точка:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedPoint!.latitude.toStringAsFixed(6)}, '
                      '${_selectedPoint!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                    if (_selectedAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedAddress!,
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Симуляция выбора точки (для демонстрации)
  void _simulatePointSelection() {
    setState(() {
      // Генерируем случайные координаты в районе Москвы
      final random = DateTime.now().millisecondsSinceEpoch % 1000;
      _selectedPoint = MapPoint(
        latitude: MapConfig.defaultLatitude + (random - 500) / 10000,
        longitude: MapConfig.defaultLongitude + (random - 500) / 10000,
        type: widget.pointType,
      );

      // Симулируем получение адреса
      _selectedAddress = _getSimulatedAddress();
    });
  }

  /// Генерация симулированного адреса
  String _getSimulatedAddress() {
    final streets = [
      'ул. Тверская',
      'ул. Арбат',
      'Красная площадь',
      'ул. Ленина',
      'просп. Мира',
    ];
    final buildings = [1, 5, 10, 15, 20, 25];

    final street =
        streets[DateTime.now().millisecondsSinceEpoch % streets.length];
    final building = buildings[DateTime.now().second % buildings.length];

    return 'г. Москва, $street, д. $building';
  }

  /// Подтверждение выбора точки
  void _confirmSelection() {
    if (_selectedPoint != null) {
      Navigator.pop(context, {
        'point': _selectedPoint,
        'address': _selectedAddress,
      });
    }
  }
}

// TODO: Реальная реализация с Yandex MapKit
/*
class _MapPickerScreenState extends State<MapPickerScreen> {
  YandexMapController? _mapController;
  MapPoint? _selectedPoint;
  
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _selectedPoint != null ? _confirmSelection : null,
          child: const Text('Готово'),
        ),
      ),
      child: YandexMap(
        onMapCreated: (YandexMapController controller) {
          _mapController = controller;
        },
        onMapTap: (Point point) {
          _onMapTap(point);
        },
        mapObjects: _buildMapObjects(),
      ),
    );
  }
  
  void _onMapTap(Point point) {
    setState(() {
      _selectedPoint = MapPoint(
        latitude: point.latitude,
        longitude: point.longitude,
        type: widget.pointType,
      );
    });
    
    // Получаем адрес по координатам
    _getAddressFromCoordinates(point);
  }
  
  List<MapObject> _buildMapObjects() {
    if (_selectedPoint == null) return [];
    
    return [
      PlacemarkMapObject(
        mapId: MapObjectId('selected_point'),
        point: Point(
          latitude: _selectedPoint!.latitude,
          longitude: _selectedPoint!.longitude,
        ),
        icon: PlacemarkIcon.single(
          PlacemarkIconStyle(
            image: BitmapDescriptor.fromAssetImage(
              _getIconForPointType(widget.pointType),
            ),
            scale: 0.8,
          ),
        ),
      ),
    ];
  }
  
  String _getIconForPointType(MapPointType type) {
    switch (type) {
      case MapPointType.pickup:
        return 'assets/icons/pickup_marker.png';
      case MapPointType.dropoff:
        return 'assets/icons/dropoff_marker.png';
      default:
        return 'assets/icons/default_marker.png';
    }
  }
}
*/
