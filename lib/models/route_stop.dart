/// Модель остановки на маршруте
class RouteStop {
  final String id;
  final String name;
  final int order; // Порядок остановки на маршруте
  final double latitude;
  final double longitude;
  final int priceFromStart; // Цена от начальной точки маршрута (в рублях)
  final bool isPopular; // Популярная остановка (отображается выше в списке)

  const RouteStop({
    required this.id,
    required this.name,
    required this.order,
    required this.latitude,
    required this.longitude,
    required this.priceFromStart,
    this.isPopular = false,
  });

  /// Конвертация в Map для сохранения в Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'order': order,
      'latitude': latitude,
      'longitude': longitude,
      'priceFromStart': priceFromStart,
      'isPopular': isPopular,
    };
  }

  /// Создание из Map из Firestore
  factory RouteStop.fromJson(Map<String, dynamic> json) {
    return RouteStop(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      priceFromStart: json['priceFromStart'] ?? 0,
      isPopular: json['isPopular'] ?? false,
    );
  }

  @override
  String toString() {
    return 'RouteStop(id: $id, name: $name, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteStop &&
        other.id == id &&
        other.name == name &&
        other.order == order;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ order.hashCode;
  }
}

/// Предустановленные маршруты с остановками
class RouteData {
  /// Маршрут Донецк → Ростов-на-Дону
  static const List<RouteStop> donetskToRostov = [
    RouteStop(
      id: 'donetsk',
      name: 'Донецк',
      order: 0,
      latitude: 48.0159,
      longitude: 37.8031,
      priceFromStart: 0,
      isPopular: true,
    ),
    RouteStop(
      id: 'makeevka',
      name: 'Макеевка',
      order: 1,
      latitude: 48.0477,
      longitude: 37.9266,
      priceFromStart: 200,
      isPopular: true,
    ),
    RouteStop(
      id: 'khartsyzsk',
      name: 'Харцызск',
      order: 2,
      latitude: 48.0433,
      longitude: 38.1544,
      priceFromStart: 400,
    ),
    RouteStop(
      id: 'ilovaysk',
      name: 'Иловайск',
      order: 3,
      latitude: 47.9267,
      longitude: 38.2019,
      priceFromStart: 600,
    ),
    RouteStop(
      id: 'kuteynikovo',
      name: 'Кутейниково',
      order: 4,
      latitude: 47.8833,
      longitude: 38.2667,
      priceFromStart: 800,
    ),
    RouteStop(
      id: 'amvrosievka',
      name: 'Амвросиевка',
      order: 5,
      latitude: 47.7833,
      longitude: 38.4833,
      priceFromStart: 1000,
    ),
    RouteStop(
      id: 'kpp_uspenka',
      name: 'КПП УСПЕНКА',
      order: 6,
      latitude: 47.7167,
      longitude: 38.5833,
      priceFromStart: 1200,
      isPopular: true,
    ),
    RouteStop(
      id: 'matveev_kurgan',
      name: 'Матвеев-Курган',
      order: 7,
      latitude: 47.6167,
      longitude: 38.8667,
      priceFromStart: 1400,
    ),
    RouteStop(
      id: 'pokrovskoe',
      name: 'Покровское',
      order: 8,
      latitude: 47.5333,
      longitude: 39.0167,
      priceFromStart: 1600,
    ),
    RouteStop(
      id: 'taganrog',
      name: 'Таганрог',
      order: 9,
      latitude: 47.2357,
      longitude: 38.8969,
      priceFromStart: 1800,
      isPopular: true,
    ),
    RouteStop(
      id: 'rostov',
      name: 'Ростов-на-Дону',
      order: 10,
      latitude: 47.2357,
      longitude: 39.7015,
      priceFromStart: 2000,
      isPopular: true,
    ),
  ];

  /// Маршрут Ростов-на-Дону → Донецк (обратный порядок)
  static List<RouteStop> get rostovToDonetsk {
    return donetskToRostov.reversed.map((stop) {
      return RouteStop(
        id: stop.id,
        name: stop.name,
        order: donetskToRostov.length - 1 - stop.order,
        latitude: stop.latitude,
        longitude: stop.longitude,
        priceFromStart: 2000 - stop.priceFromStart, // Инвертируем цены
        isPopular: stop.isPopular,
      );
    }).toList();
  }

  /// Получение остановок по направлению
  static List<RouteStop> getRouteStops(String direction) {
    switch (direction) {
      case 'donetsk_to_rostov':
        return donetskToRostov;
      case 'rostov_to_donetsk':
        return rostovToDonetsk;
      default:
        return [];
    }
  }

  /// Поиск остановки по ID
  static RouteStop? findStopById(String stopId, String direction) {
    final stops = getRouteStops(direction);
    try {
      return stops.firstWhere((stop) => stop.id == stopId);
    } catch (e) {
      return null;
    }
  }

  /// Получение цены между двумя остановками
  static int getPriceBetweenStops(RouteStop fromStop, RouteStop toStop) {
    // Для групповых поездок - фиксированная цена 2000₽ независимо от расстояния
    return 2000;
  }
}
