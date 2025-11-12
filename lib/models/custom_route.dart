/// Модель произвольного маршрута для калькулятора
class CustomRoute {
  final String fromAddress; // Адрес отправления
  final String toAddress; // Адрес назначения
  final double distance; // Расстояние в км
  final double duration; // Время в пути (минуты)
  final double price; // Итоговая цена

  CustomRoute({
    required this.fromAddress,
    required this.toAddress,
    required this.distance,
    required this.duration,
    required this.price,
  });

  /// Форматированное расстояние для UI
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).toInt()} м';
    }
    return '${distance.toStringAsFixed(1)} км';
  }

  /// Форматированное время для UI
  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration.toInt() % 60;

    if (hours > 0) {
      return '$hours ч $minutes мин';
    }
    return '$minutes мин';
  }

  /// Форматированная цена для UI
  String get formattedPrice {
    return '${price.toInt()} ₽';
  }

  @override
  String toString() {
    return 'CustomRoute($fromAddress → $toAddress, $formattedDistance, $formattedPrice)';
  }
}
