/// Модель настроек калькулятора такси для свободного маршрута
/// Хранится в Firebase Firestore: calculator_settings/current
class CalculatorSettings {
  final double baseCost; // Базовая стоимость (₽)
  final double costPerKm; // Стоимость за километр (₽/км)
  final double minPrice; // Минимальная цена поездки (₽)
  final bool roundToThousands; // Округлять до тысяч вверх
  final double? pricePerKmBeyondRostov; // Цена за км дальше Ростова (₽/км) для маршрута Донецк-Ростов
  final DateTime updatedAt; // Когда обновлено
  final String updatedBy; // Кто обновил (ID админа)

  CalculatorSettings({
    required this.baseCost,
    required this.costPerKm,
    required this.minPrice,
    required this.roundToThousands,
    this.pricePerKmBeyondRostov,
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
      pricePerKmBeyondRostov: json['pricePerKmBeyondRostov'] != null 
          ? (json['pricePerKmBeyondRostov'] as num).toDouble() 
          : null,
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
      'pricePerKmBeyondRostov': pricePerKmBeyondRostov,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }

  /// Настройки по умолчанию
  static CalculatorSettings get defaultSettings {
    return CalculatorSettings(
      baseCost: 500,
      costPerKm: 60, // Обновлено: 60₽/км вместо 15₽/км
      minPrice: 1000,
      roundToThousands: true,
      pricePerKmBeyondRostov: 60.0, // По умолчанию 60₽ за км дальше Ростова
      updatedAt: DateTime.now(),
      updatedBy: 'system',
    );
  }

  @override
  String toString() {
    return 'CalculatorSettings(base: $baseCost₽, perKm: $costPerKm₽, min: $minPrice₽, round: $roundToThousands)';
  }
}
