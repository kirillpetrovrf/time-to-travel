import 'package:flutter/cupertino.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;
import 'package:yandex_maps_mapkit/yandex_map.dart';

class BasicMapScreen extends StatefulWidget {
  const BasicMapScreen({super.key});

  @override
  State<BasicMapScreen> createState() => _BasicMapScreenState();
}

class _BasicMapScreenState extends State<BasicMapScreen> {
  mapkit.MapWindow? _mapWindow;

  void _onMapCreated(mapkit.MapWindow mapWindow) {
    _mapWindow = mapWindow;
    print('✅ Карта создана успешно');

    // Начальная позиция - Москва
    _mapWindow?.map.move(
      const mapkit.CameraPosition(
        mapkit.Point(latitude: 55.753215, longitude: 37.622504),
        zoom: 10,
        azimuth: 0,
        tilt: 0,
      ),
    );
  }

  void _addTestPoint() {
    if (_mapWindow != null) {
      final placemark = _mapWindow!.map.mapObjects.addPlacemark();
      placemark.geometry = const mapkit.Point(latitude: 55.753215, longitude: 37.622504);
      print('📍 Тестовая точка добавлена');
    }
  }

  void _clearMap() {
    _mapWindow?.map.mapObjects.clear();
    print('🗑️ Карта очищена');
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Базовая карта'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _addTestPoint,
              child: const Icon(CupertinoIcons.add),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _clearMap,
              child: const Icon(CupertinoIcons.clear),
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Карта
          YandexMap(
            onMapCreated: _onMapCreated,
          ),
          
          // Информационная панель
          Positioned(
            bottom: 50,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: const Text(
                'Базовый экран карты\nИспользуйте кнопки в навигационной панели для добавления/удаления точек',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}