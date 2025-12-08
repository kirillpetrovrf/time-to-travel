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
      name: 'КПП УСПЕНКА (Авиало-Успенка)',
      order: 6,
      latitude: 47.699184,
      longitude: 38.679496,
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
      id: 'sambek',
      name: 'Самбек',
      order: 10,
      latitude: 47.3167,
      longitude: 39.2667,
      priceFromStart: 1850,
    ),
    RouteStop(
      id: 'chaltyr',
      name: 'Чалтырь',
      order: 11,
      latitude: 47.2833,
      longitude: 39.4667,
      priceFromStart: 1900,
    ),
    RouteStop(
      id: 'rostov',
      name: 'Ростов-на-Дону',
      order: 12,
      latitude: 47.2357,
      longitude: 39.7015,
      priceFromStart: 2000,
      isPopular: true,
    ),
  ];

  /// 🆕 НОВЫЙ МАРШРУТ: Донецк → Луганск (без военных КПП)
  /// Фиксированная цена 10,000₽ независимо от места высадки
  static const List<RouteStop> donetskToLuhansk = [
    RouteStop(
      id: 'donetsk',
      name: 'Донецк',
      order: 0,
      latitude: 48.0159,
      longitude: 37.8031,
      priceFromStart: 10000, // Фиксированная цена
      isPopular: true,
    ),
    RouteStop(
      id: 'makeevka',
      name: 'Макеевка',
      order: 1,
      latitude: 48.0477,
      longitude: 37.9266,
      priceFromStart: 10000, // Фиксированная цена
      isPopular: true,
    ),
    RouteStop(
      id: 'khartsyzsk',
      name: 'Харцызск',
      order: 2,
      latitude: 48.0433,
      longitude: 38.1544,
      priceFromStart: 10000, // Фиксированная цена
    ),
    RouteStop(
      id: 'yenakievo',
      name: 'Енакиево',
      order: 3,
      latitude: 48.2333,
      longitude: 38.2167,
      priceFromStart: 10000, // Фиксированная цена
      isPopular: true,
    ),
    RouteStop(
      id: 'debaltsevo',
      name: 'Дебальцево',
      order: 4,
      latitude: 48.3409,
      longitude: 38.4066,
      priceFromStart: 10000, // Фиксированная цена
    ),
    RouteStop(
      id: 'luhansk',
      name: 'Луганск',
      order: 5,
      latitude: 48.5742,
      longitude: 39.3078,
      priceFromStart: 10000, // Фиксированная цена
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

  /// 🆕 Маршрут Луганск → Донецк (обратный порядок)
  /// Фиксированная цена 10,000₽ независимо от места высадки
  static List<RouteStop> get luhanskToDonetsk {
    return donetskToLuhansk.reversed.map((stop) {
      return RouteStop(
        id: stop.id,
        name: stop.name,
        order: donetskToLuhansk.length - 1 - stop.order,
        latitude: stop.latitude,
        longitude: stop.longitude,
        priceFromStart: 10000, // Фиксированная цена в обе стороны
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
      case 'donetsk_to_luhansk':     // 🆕 НОВОЕ
        return donetskToLuhansk;
      case 'luhansk_to_donetsk':     // 🆕 НОВОЕ
        return luhanskToDonetsk;
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

/// Места посадки для каждого города на маршруте
class PickupPoints {
  /// Места посадки в Донецке
  static const List<String> donetsk = ['Южный', 'Крытый рынок', 'Мотель'];

  /// Места посадки в Макеевке
  static const List<String> makeevka = [
    'МИСИ',
    'Галактика',
    'Папирус',
    'Красный рынок',
    'Зеленый',
    'Кольцо 4/13',
  ];

  /// Места посадки в Харцызске
  static const List<String> khartsyzsk = ['Родничек'];

  /// Места посадки в Иловайске
  static const List<String> ilovaysk = ['памятник Медаль'];

  /// Места посадки в Кутейниково
  static const List<String> kuteynikovo = ['АЗС'];

  /// Места посадки в Амвросиевке
  static const List<String> amvrosievka = ['кафе Лолита', 'пост ДПС'];

  /// Места посадки на КПП УСПЕНКА
  static const List<String> kppUspenka = ['КПП Успенка'];

  /// Места посадки в Матвеев-Кургане
  static const List<String> matveevKurgan = ['автостанция'];

  /// Места посадки в Покровском
  static const List<String> pokrovskoe = ['автостанция'];

  /// Места посадки в Таганроге
  static const List<String> taganrog = ['ул. Маршала Жукова 1а'];

  /// Места посадки в Ростове-на-Дону
  static const List<String> rostov = [
    'Таганрогское кольцо (АЗС)',
    'ул. Малиновского + ул. Доватора',
    'Главный ЖД вокзал',
  ];

  /// 🆕 Места посадки в Енакиево
  static const List<String> yenakievo = ['Центральная площадь', 'Автостанция'];

  /// 🆕 Места посадки в Дебальцево  
  static const List<String> debaltsevo = ['Железнодорожный вокзал', 'Центр города'];

  /// 🆕 Места посадки в Луганске
  static const List<String> luhansk = ['Автовокзал', 'ТЦ Украина', 'Площадь Героев'];

  /// Получение мест посадки по ID города
  static List<String> getPickupPointsForCity(String cityId) {
    switch (cityId) {
      case 'donetsk':
        return donetsk;
      case 'makeevka':
        return makeevka;
      case 'khartsyzsk':
        return khartsyzsk;
      case 'ilovaysk':
        return ilovaysk;
      case 'kuteynikovo':
        return kuteynikovo;
      case 'amvrosievka':
        return amvrosievka;
      case 'kpp_uspenka':
        return kppUspenka;
      case 'matveev_kurgan':
        return matveevKurgan;
      case 'pokrovskoe':
        return pokrovskoe;
      case 'taganrog':
        return taganrog;
      case 'rostov':
        return rostov;
      // 🆕 НОВЫЕ ГОРОДА
      case 'yenakievo':
        return yenakievo;
      case 'debaltsevo':
        return debaltsevo;
      case 'luhansk':
        return luhansk;
      default:
        return [];
    }
  }

  /// Получение полного названия остановки (город + место посадки)
  static String getFullStopName(String cityName, String pickupPoint) {
    return '$cityName ($pickupPoint)';
  }
}
