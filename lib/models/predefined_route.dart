/// Модель предустановленного маршрута с фиксированной ценой
class PredefinedRoute {
  final String id;
  final String fromCity;
  final String toCity;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 🆕 НОВЫЕ ПОЛЯ ДЛЯ СИСТЕМЫ ГРУПП:
  final String? groupId; // ID группы (может быть null для старых маршрутов)
  final bool useGroupPrice; // Использовать цену из группы
  final bool customPrice; // Цена переопределена вручную
  final bool isReverse; // Обратный маршрут (автогенерированный)

  PredefinedRoute({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.groupId,
    this.useGroupPrice = true,
    this.customPrice = false,
    this.isReverse = false,
  });

  /// Создает маршрут из Firebase документа
  factory PredefinedRoute.fromFirestore(Map<String, dynamic> data, String id) {
    return PredefinedRoute(
      id: id,
      fromCity: data['fromCity'] ?? '',
      toCity: data['toCity'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      groupId: data['groupId'],
      useGroupPrice: data['useGroupPrice'] ?? true,
      customPrice: data['customPrice'] ?? false,
      isReverse: data['isReverse'] ?? false,
    );
  }

  /// Конвертирует маршрут в формат для Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'fromCity': fromCity,
      'toCity': toCity,
      'price': price,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'groupId': groupId,
      'useGroupPrice': useGroupPrice,
      'customPrice': customPrice,
      'isReverse': isReverse,
    };
  }

  /// Создает ключ маршрута для поиска (нормализованные названия городов)
  String get routeKey => _normalizeCity(fromCity) + '_to_' + _normalizeCity(toCity);

  /// Создает ключ обратного маршрута
  String get reverseRouteKey => _normalizeCity(toCity) + '_to_' + _normalizeCity(fromCity);

  /// Нормализует название города для сравнения
  static String _normalizeCity(String cityName) {
    return cityName
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_')
        .replaceAll('ё', 'е');
  }

  /// Проверяет, подходит ли этот маршрут для указанных городов
  bool matchesRoute(String from, String to) {
    final normalizedFrom = _normalizeCity(from);
    final normalizedTo = _normalizeCity(to);
    final thisFrom = _normalizeCity(fromCity);
    final thisTo = _normalizeCity(toCity);

    return (normalizedFrom == thisFrom && normalizedTo == thisTo) ||
           (normalizedFrom == thisTo && normalizedTo == thisFrom);
  }

  /// Создает копию маршрута с измененными значениями
  PredefinedRoute copyWith({
    String? id,
    String? fromCity,
    String? toCity,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? groupId,
    bool? useGroupPrice,
    bool? customPrice,
    bool? isReverse,
  }) {
    return PredefinedRoute(
      id: id ?? this.id,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      groupId: groupId ?? this.groupId,
      useGroupPrice: useGroupPrice ?? this.useGroupPrice,
      customPrice: customPrice ?? this.customPrice,
      isReverse: isReverse ?? this.isReverse,
    );
  }

  /// Создает обратный маршрут с той же ценой
  PredefinedRoute createReverse({String? newId}) {
    return PredefinedRoute(
      id: newId ?? '${id}_reverse',
      fromCity: toCity,
      toCity: fromCity,
      price: price,
      createdAt: createdAt,
      updatedAt: updatedAt,
      groupId: groupId,
      useGroupPrice: useGroupPrice,
      customPrice: customPrice,
      isReverse: true, // Помечаем как обратный маршрут
    );
  }

  @override
  String toString() {
    return 'PredefinedRoute(id: $id, from: $fromCity, to: $toCity, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredefinedRoute &&
           other.id == id &&
           other.fromCity == fromCity &&
           other.toCity == toCity &&
           other.price == price;
  }

  @override
  int get hashCode {
    return Object.hash(id, fromCity, toCity, price);
  }
}

/// Коллекция методов для работы с предустановленными маршрутами
class PredefinedRouteHelper {
  /// Находит маршрут в списке по городам (с учетом двусторонности)
  static PredefinedRoute? findRoute(List<PredefinedRoute> routes, String fromCity, String toCity) {
    for (final route in routes) {
      if (route.matchesRoute(fromCity, toCity)) {
        return route;
      }
    }
    return null;
  }

  /// Создает список всех уникальных городов из маршрутов
  static List<String> getAllCities(List<PredefinedRoute> routes) {
    final cities = <String>{};
    for (final route in routes) {
      cities.add(route.fromCity);
      cities.add(route.toCity);
    }
    return cities.toList()..sort();
  }

  /// Фильтрует маршруты по городу отправления
  static List<PredefinedRoute> getRoutesFromCity(List<PredefinedRoute> routes, String city) {
    final normalizedCity = PredefinedRoute._normalizeCity(city);
    return routes.where((route) {
      return PredefinedRoute._normalizeCity(route.fromCity) == normalizedCity ||
             PredefinedRoute._normalizeCity(route.toCity) == normalizedCity;
    }).toList();
  }

  /// Валидирует данные маршрута
  static String? validateRoute(String fromCity, String toCity, double price) {
    if (fromCity.trim().isEmpty) {
      return 'Город отправления не может быть пустым';
    }
    if (toCity.trim().isEmpty) {
      return 'Город назначения не может быть пустым';
    }
    if (PredefinedRoute._normalizeCity(fromCity) == PredefinedRoute._normalizeCity(toCity)) {
      return 'Города отправления и назначения не могут быть одинаковыми';
    }
    if (price <= 0) {
      return 'Цена должна быть больше нуля';
    }
    return null;
  }
}