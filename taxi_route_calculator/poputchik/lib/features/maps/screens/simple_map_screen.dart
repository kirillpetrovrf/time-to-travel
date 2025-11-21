import 'package:flutter/cupertino.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;
import 'package:yandex_maps_mapkit/yandex_map.dart';
import '../../../managers/route_points_manager_simple.dart';

class SimpleMapScreen extends StatefulWidget {
  const SimpleMapScreen({super.key});

  @override
  State<SimpleMapScreen> createState() => _SimpleMapScreenState();
}

class _SimpleMapScreenState extends State<SimpleMapScreen> {
  mapkit.MapWindow? _mapWindow;
  late final RoutePointsManager _routePointsManager;

  @override
  void initState() {
    super.initState();
    _routePointsManager = RoutePointsManager();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onMapCreated(mapkit.MapWindow mapWindow) {
    _mapWindow = mapWindow;
    _routePointsManager.init(mapWindow);
    
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Карта'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                _routePointsManager.forceTripleClear();
                print('🗑️ Все точки очищены');
              },
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Нажмите на карту для установки точек маршрута',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: CupertinoColors.systemBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Начало'),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: CupertinoColors.systemRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Конец'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}