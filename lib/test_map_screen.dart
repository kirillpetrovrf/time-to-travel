import 'package:flutter/material.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/yandex_map.dart';

/// 🧪 ТЕСТОВЫЙ ЭКРАН КАРТЫ
/// Простейший экран для проверки работы Yandex Maps
class TestMapScreen extends StatefulWidget {
  const TestMapScreen({super.key});

  @override
  State<TestMapScreen> createState() => _TestMapScreenState();
}

class _TestMapScreenState extends State<TestMapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Тест Yandex Maps'),
        backgroundColor: Colors.blue,
      ),
      body: YandexMap(
        onMapCreated: (controller) {
          print('🗺️ [TEST] Карта создана!');
          print('🗺️ [TEST] Controller: $controller');

          // Перемещаемся на Москву
          controller.moveCamera(
            CameraUpdate.newCameraPosition(
              const CameraPosition(
                target: Point(latitude: 55.751244, longitude: 37.618423),
                zoom: 12.0,
              ),
            ),
          );

          print('🗺️ [TEST] Камера перемещена на Москву');
          print('🗺️ [TEST] Если видите только сетку - проблема с API-ключом');
          print('🗺️ [TEST] Если видите карту - всё работает!');
        },
        onCameraPositionChanged: (position, reason, finished) {
          if (finished) {
            print('🗺️ [TEST] Камера остановилась: $position');
          }
        },
        mapType: MapType.map, // Растровая карта
        nightModeEnabled: false,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        tiltGesturesEnabled: false,
        zoomGesturesEnabled: true,
      ),
    );
  }
}
