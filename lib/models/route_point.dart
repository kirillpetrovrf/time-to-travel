import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;

enum RoutePointType {
  from,  // Точка отправления (лицом к пользователю)
  to,    // Точка назначения (спиной к пользователю)
}

class RoutePoint {
  final RoutePointType type;
  final mapkit.Point point;
  final String? address;

  const RoutePoint({
    required this.type,
    required this.point,
    this.address,
  });

  RoutePoint copyWith({
    RoutePointType? type,
    mapkit.Point? point,
    String? address,
  }) {
    return RoutePoint(
      type: type ?? this.type,
      point: point ?? this.point,
      address: address ?? this.address,
    );
  }

  @override
  String toString() {
    return 'RoutePoint(type: $type, point: $point, address: $address)';
  }
}
