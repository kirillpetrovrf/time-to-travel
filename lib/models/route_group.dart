/// Модель группы маршрутов для управления ценами
class RouteGroup {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final List<String> destinationCities; // Города назначения
  final List<String> originCities; // Города отправления
  final bool autoGenerateReverse; // Автоматически создавать обратные маршруты
  final DateTime createdAt;
  final DateTime updatedAt;

  const RouteGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.destinationCities,
    required this.originCities,
    required this.autoGenerateReverse,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создание из Map (SQLite)
  factory RouteGroup.fromMap(Map<String, dynamic> data, String id) {
    return RouteGroup(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      basePrice: (data['basePrice'] ?? 0.0).toDouble(),
      destinationCities: List<String>.from(data['destinationCities'] ?? []),
      originCities: List<String>.from(data['originCities'] ?? []),
      autoGenerateReverse: data['autoGenerateReverse'] ?? true,
      createdAt: data['createdAt'] is String 
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] is String
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
    );
  }

  /// Создание копии с измененными значениями
  RouteGroup copyWith({
    String? id,
    String? name,
    String? description,
    double? basePrice,
    List<String>? destinationCities,
    List<String>? originCities,
    bool? autoGenerateReverse,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RouteGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      destinationCities: destinationCities ?? this.destinationCities,
      originCities: originCities ?? this.originCities,
      autoGenerateReverse: autoGenerateReverse ?? this.autoGenerateReverse,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'RouteGroup(id: $id, name: $name, basePrice: $basePrice, routes: ${originCities.length * destinationCities.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RouteGroup && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Получить количество возможных маршрутов в группе
  int get potentialRoutesCount {
    int count = originCities.length * destinationCities.length;
    if (autoGenerateReverse) {
      count *= 2; // Удваиваем для обратных маршрутов
    }
    return count;
  }
  
  /// Получить количество уникальных направлений (без учета обратных)
  int get uniqueRoutesCount {
    return originCities.length * destinationCities.length;
  }
}
