import 'package:yandex_maps_mapkit/mapkit.dart';

final class GeometryProvider {
  // Fallback позиция Москва (если геолокация недоступна)
  static const fallbackPosition = CameraPosition(
    Point(latitude: 55.753284, longitude: 37.622034),
    zoom: 13.0,
    azimuth: 0.0,
    tilt: 0.0,
  );
  
  // Более широкий зум для начальной позиции до получения геолокации
  static const initialPosition = CameraPosition(
    Point(latitude: 55.753284, longitude: 37.622034),
    zoom: 10.0,
    azimuth: 0.0,
    tilt: 0.0,
  );
}
