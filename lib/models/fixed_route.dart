/// Модель фиксированного маршрута с ценой
class FixedRoute {
  final String id;
  final String fromCity;
  final String toCity;
  final double price;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  FixedRoute({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Создание из JSON (Firebase)
  factory FixedRoute.fromJson(String id, Map<String, dynamic> json) {
    return FixedRoute(
      id: id,
      fromCity: json['from_city'] ?? '',
      toCity: json['to_city'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] ?? 0),
      isActive: json['is_active'] ?? true,
    );
  }

  /// Преобразование в JSON (Firebase)
  Map<String, dynamic> toJson() {
    return {
      'from_city': fromCity,
      'to_city': toCity,
      'price': price,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_active': isActive,
    };
  }

  /// Нормализованный ключ маршрута для поиска
  String get routeKey => '${normalizeCity(fromCity)}-${normalizeCity(toCity)}';

  /// Нормализация названия города
  static String normalizeCity(String city) {
    return city
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[,\.\-\s]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' ', '-')
        .replaceAll('ё', 'е')
        .replaceAll('ростов-на-дону', 'ростов');
  }

  /// Форматированное отображение маршрута
  String get displayName => '$fromCity → $toCity';

  /// Форматированная цена
  String get formattedPrice => '${price.toInt()} ₽';

  @override
  String toString() => 'FixedRoute($displayName: $formattedPrice)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FixedRoute && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Копирование с изменениями
  FixedRoute copyWith({
    String? id,
    String? fromCity,
    String? toCity,
    double? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return FixedRoute(
      id: id ?? this.id,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}