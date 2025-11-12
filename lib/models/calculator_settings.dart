/// Модель настроек калькулятора такси для свободного маршрута
/// Хранится в Firebase Firestore: calculator_settings/current
class CalculatorSettings {
  final double baseCost; // Базовая стоимость (₽)
  final double costPerKm; // Стоимость за километр (₽/км)
  final double minPrice; // Минимальная цена поездки (₽)
  final bool roundToThousands; // Округлять до тысяч вверх
  final DateTime updatedAt; // Когда обновлено
  final String updatedBy; // Кто обновил (ID админа)

  CalculatorSettings({
    required this.baseCost,
    required this.costPerKm,
    required this.minPrice,
    required this.roundToThousands,
    required this.updatedAt,
    required this.updatedBy,
  });

  /// Создать из JSON (из Firebase)
  factory CalculatorSettings.fromJson(Map<String, dynamic> json) {
    return CalculatorSettings(
      baseCost: (json['baseCost'] as num).toDouble(),
      costPerKm: (json['costPerKm'] as num).toDouble(),
      minPrice: (json['minPrice'] as num).toDouble(),
      roundToThousands: json['roundToThousands'] as bool,
      updatedAt: (json['updatedAt'] as dynamic).toDate(),
      updatedBy: json['updatedBy'] as String,
    );
  }

  /// Преобразовать в JSON (для сохранения в Firebase)
  Map<String, dynamic> toJson() {
    return {
      'baseCost': baseCost,
      'costPerKm': costPerKm,
      'minPrice': minPrice,
      'roundToThousands': roundToThousands,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  /// Настройки по умолчанию
  static CalculatorSettings get defaultSettings {
    return CalculatorSettings(
      baseCost: 500,
      costPerKm: 15,
      minPrice: 1000,
      roundToThousands: true,
      updatedAt: DateTime.now(),
      updatedBy: 'system',
    );
  }

  @override
  String toString() {
    return 'CalculatorSettings(base: $baseCost₽, perKm: $costPerKm₽, min: $minPrice₽, round: $roundToThousands)';
  }
}
