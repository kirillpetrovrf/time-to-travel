import 'dart:math';

/// Модель для информации о маршруте
class RouteInfo {
  final double distance; // километры
  final double duration; // минуты
  final String fromAddress;
  final String toAddress;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.fromAddress,
    required this.toAddress,
  });
}

/// Модель для координат
class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  @override
  String toString() => 'Coordinates($latitude, $longitude)';
}

/// Сервис для работы с Yandex MapKit
/// 
/// Использование:
/// ```dart
/// // 1. Геокодирование (адрес → координаты)
/// final coords = await YandexMapsService.instance.geocode('Москва, Красная площадь');
/// 
/// // 2. Расчет маршрута
/// final route = await YandexMapsService.instance.calculateRoute(
///   'Москва, ул. Ленина, 1',
///   'Москва, ул. Пушкина, 10',
/// );
/// print('Расстояние: ${route.distance} км');
/// print('Время: ${route.duration} минут');
/// ```
class YandexMapsService {
  static final YandexMapsService instance = YandexMapsService._();
  YandexMapsService._();

  bool _isInitialized = false;

  /// Инициализация MapKit (вызывается в main.dart)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🗺️ [YANDEX MAPKIT] Инициализация...');
      _isInitialized = true;
      print('✅ [YANDEX MAPKIT] Инициализирован успешно');
    } catch (e) {
      print('❌ [YANDEX MAPKIT] Ошибка инициализации: $e');
    }
  }

  /// Геокодирование: адрес → координаты
  /// 
  /// Для полной реализации используйте SearchManager API
  Future<Coordinates?> geocode(String address) async {
    if (!_isInitialized) await initialize();

    print('🗺️ [YANDEX MAPKIT] Геокодирование адреса: "$address"');

    try {
      // TODO: Реализуйте через SearchManager
      // import 'package:yandex_maps_mapkit/search.dart';
      // 
      // final searchManager = SearchFactory.instance.createSearchManager(SearchManagerType.Combined);
      // final searchSession = searchManager.submit(
      //   TextSearchRequest(
      //     text: address,
      //     geometry: Geometry.fromPoint(Point(latitude: 55.75, longitude: 37.62)),
      //   ),
      //   SearchOptions(searchType: SearchType.geo),
      // );
      // 
      // final result = await searchSession.result;
      // final point = result.items?.first.geometry?.first.point;
      // 
      // return Coordinates(
      //   latitude: point.latitude,
      //   longitude: point.longitude,
      // );

      return _getMockCoordinates(address);
    } catch (e) {
      print('❌ [YANDEX MAPKIT] Ошибка геокодирования: $e');
      return _getMockCoordinates(address);
    }
  }

  /// Построить маршрут и получить расстояние
  Future<RouteInfo?> calculateRoute(
    String fromAddress,
    String toAddress,
  ) async {
    if (!_isInitialized) await initialize();

    print('🚗 [YANDEX MAPKIT] ========== РАСЧЁТ МАРШРУТА ==========');
    print('🚗 [YANDEX MAPKIT] От: $fromAddress');
    print('🚗 [YANDEX MAPKIT] До: $toAddress');

    try {
      final fromCoords = await geocode(fromAddress);
      final toCoords = await geocode(toAddress);

      if (fromCoords == null || toCoords == null) {
        print('❌ [YANDEX MAPKIT] Не удалось получить координаты');
        return null;
      }

      print('📍 [YANDEX MAPKIT] От: $fromCoords');
      print('📍 [YANDEX MAPKIT] До: $toCoords');

      // TODO: Реализуйте через DrivingRouter
      // import 'package:yandex_maps_mapkit/directions.dart';
      // 
      // final drivingRouter = DirectionsFactory.instance.createDrivingRouter(DrivingRouterType.Combined);
      // final drivingSession = drivingRouter.requestRoutes(
      //   points: [
      //     RequestPoint(
      //       point: Point(latitude: fromCoords.latitude, longitude: fromCoords.longitude),
      //       requestPointType: RequestPointType.wayPoint,
      //     ),
      //     RequestPoint(
      //       point: Point(latitude: toCoords.latitude, longitude: toCoords.longitude),
      //       requestPointType: RequestPointType.wayPoint,
      //     ),
      //   ],
      //   drivingOptions: DrivingOptions(routesCount: 1),
      // );
      // 
      // final result = await drivingSession.result;
      // final route = result.routes?.first;
      // 
      // return RouteInfo(
      //   distance: route.metadata.weight.distance.value / 1000, // метры → км
      //   duration: route.metadata.weight.time.value / 60, // секунды → минуты
      //   fromAddress: fromAddress,
      //   toAddress: toAddress,
      // );

      return _calculateRouteByDistance(
        fromCoords,
        toCoords,
        fromAddress,
        toAddress,
      );
    } catch (e) {
      print('❌ [YANDEX MAPKIT] Ошибка расчёта маршрута: $e');
      return null;
    }
  }

  // ========== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ==========

  /// Моковые координаты для популярных городов (fallback)
  Coordinates? _getMockCoordinates(String address) {
    final lowerAddress = address.toLowerCase();

    if (lowerAddress.contains('москва') || lowerAddress.contains('moscow')) {
      return Coordinates(latitude: 55.75, longitude: 37.62);
    } else if (lowerAddress.contains('санкт-петербург') ||
        lowerAddress.contains('petersburg')) {
      return Coordinates(latitude: 59.93, longitude: 30.36);
    } else if (lowerAddress.contains('екатеринбург') ||
        lowerAddress.contains('yekaterinburg')) {
      return Coordinates(latitude: 56.8, longitude: 60.6);
    } else if (lowerAddress.contains('казань') ||
        lowerAddress.contains('kazan')) {
      return Coordinates(latitude: 55.8, longitude: 49.1);
    }

    print('⚠️ [YANDEX MAPKIT] Адрес не распознан: $address');
    return null;
  }

  /// Расчет маршрута по прямой (fallback)
  RouteInfo _calculateRouteByDistance(
    Coordinates from,
    Coordinates to,
    String fromAddress,
    String toAddress,
  ) {
    final distance = _calculateDistance(from, to);
    final duration = distance / 80 * 60; // Примерно 80 км/ч

    print('✅ [YANDEX MAPKIT] Маршрут рассчитан по прямой:');
    print('   📏 Расстояние: ${distance.toStringAsFixed(1)} км');
    print('   ⏱️ Время: ${duration.toInt()} минут');

    return RouteInfo(
      distance: distance,
      duration: duration,
      fromAddress: fromAddress,
      toAddress: toAddress,
    );
  }

  /// Расчет расстояния между двумя точками по формуле Гаверсина
  double _calculateDistance(Coordinates from, Coordinates to) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = from.latitude * pi / 180;
    final lat2Rad = to.latitude * pi / 180;
    final dLatRad = (to.latitude - from.latitude) * pi / 180;
    final dLonRad = (to.longitude - from.longitude) * pi / 180;

    final a =
        sin(dLatRad / 2) * sin(dLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLonRad / 2) * sin(dLonRad / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }
}
