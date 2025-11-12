/// Модель координат для геокодирования
class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  /// Создать из ответа Yandex Geocoder API
  factory Coordinates.fromYandexJson(Map<String, dynamic> json) {
    try {
      final featureMember =
          json['response']['GeoObjectCollection']['featureMember'];
      if (featureMember == null || (featureMember as List).isEmpty) {
        throw Exception('Адрес не найден');
      }

      final point = featureMember[0]['GeoObject']['Point']['pos'];
      final coords = (point as String).split(' ');

      return Coordinates(
        longitude: double.parse(coords[0]),
        latitude: double.parse(coords[1]),
      );
    } catch (e) {
      throw Exception('Ошибка парсинга координат: $e');
    }
  }

  @override
  String toString() {
    return 'Coordinates($latitude, $longitude)';
  }
}

/// Модель информации о маршруте
class RouteInfo {
  final double distance; // Расстояние в км
  final double duration; // Время в минутах
  final String fromAddress;
  final String toAddress;

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.fromAddress,
    required this.toAddress,
  });

  @override
  String toString() {
    return 'RouteInfo(${distance.toStringAsFixed(1)} км, ${duration.toInt()} мин)';
  }
}
