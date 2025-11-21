import 'package:yandex_maps_mapkit/mapkit.dart';

class RoutePointsManager {
  MapWindow? _mapWindow;
  final List<Point> _points = [];
  
  RoutePointsManager();

  void init(MapWindow mapWindow) {
    _mapWindow = mapWindow;
  }

  void handleMapTap(Point point) {
    print('📍 Добавлена точка: ${point.latitude}, ${point.longitude}');
    _points.add(point);
    
    // Ограничиваем до 2 точек
    if (_points.length > 2) {
      _points.removeAt(0);
    }
    
    _updateMapObjects();
  }

  void forceTripleClear() {
    print('🗑️ Очистка всех точек');
    _points.clear();
    _mapWindow?.map.mapObjects.clear();
  }

  List<Point> getPoints() => List.from(_points);

  Future<void> buildRoute(Point from, Point to) async {
    // Простое логирование - в будущем здесь будет построение маршрута
    print('🛣️ Построение маршрута от ${from.latitude},${from.longitude} до ${to.latitude},${to.longitude}');
  }

  void _updateMapObjects() {
    _mapWindow?.map.mapObjects.clear();
    
    for (int i = 0; i < _points.length; i++) {
      final point = _points[i];
      final placemark = _mapWindow?.map.mapObjects.addPlacemark();
      placemark?.geometry = point;
      
      // Первая точка - синяя, вторая - красная
      // TODO: Добавить иконки
      print('📍 Точка $i добавлена на карту');
    }
  }
}