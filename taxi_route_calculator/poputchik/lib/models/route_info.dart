/// Информация о маршруте
class RouteInfo {
  final double distance; // в километрах
  final double duration; // в минутах
  final String fromAddress;
  final String toAddress;
  final List<Coordinates>? polyline; // точки маршрута (опционально)

  RouteInfo({
    required this.distance,
    required this.duration,
    required this.fromAddress,
    required this.toAddress,
    this.polyline,
  });

  @override
  String toString() {
    return 'RouteInfo(distance: ${distance.toStringAsFixed(1)} км, duration: ${duration.toInt()} мин, from: $fromAddress, to: $toAddress)';
  }
}

/// Координаты точки на карте
class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates({required this.latitude, required this.longitude});

  @override
  String toString() {
    return 'Coordinates(lat: ${latitude.toStringAsFixed(4)}, lon: ${longitude.toStringAsFixed(4)})';
  }
}
