/// Конфигурация для работы с картами
class MapConfig {
  // API ключ Yandex MapKit
  // Получить можно здесь: https://developer.tech.yandex.ru/
  static const String yandexMapKitApiKey = '2f1d6a75-b751-4077-b305-c6abaea0b542';

  // Проверка наличия API ключа
  static bool get hasApiKey =>
      yandexMapKitApiKey.isNotEmpty &&
      yandexMapKitApiKey != 'YOUR_YANDEX_MAPKIT_API_KEY';

  // Настройки карты по умолчанию
  static const double defaultZoom = 15.0;
  static const double minZoom = 5.0;
  static const double maxZoom = 20.0;

  // Координаты центра России (для инициализации карты)
  static const double defaultLatitude = 55.751244;
  static const double defaultLongitude = 37.618423;

  // Настройки для поиска
  static const int maxSearchResults = 20;
  static const double searchRadius = 10000.0; // 10 км

  // Настройки для маршрутов
  static const bool avoidTolls = false;
  static const bool avoidUnpaved = true;
  static const bool avoidPoorConditions = false;
  static const int maxRouteAlternatives = 3;

  /// Показать предупреждение об отсутствии API ключа
  static String get apiKeyWarning =>
      'Для работы с картами необходимо получить API ключ от Yandex MapKit '
      'и добавить его в MapConfig.yandexMapKitApiKey';
}

/// Типы точек на карте для нашего приложения
enum MapPointType {
  pickup, // Точка посадки
  dropoff, // Точка высадки
  waypoint, // Промежуточная точка
  driver, // Местоположение водителя
  passenger, // Местоположение пассажира
}

/// Модель точки на карте
class MapPoint {
  final double latitude;
  final double longitude;
  final String? address;
  final String? description;
  final MapPointType type;

  const MapPoint({
    required this.latitude,
    required this.longitude,
    this.address,
    this.description,
    required this.type,
  });

  @override
  String toString() {
    return 'MapPoint($latitude, $longitude, $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapPoint &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.type == type;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^ longitude.hashCode ^ type.hashCode;
  }
}
