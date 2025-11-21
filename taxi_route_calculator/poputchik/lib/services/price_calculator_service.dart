import '../models/price_calculation.dart';

/// Сервис расчета стоимости поездки
class PriceCalculatorService {
  static final PriceCalculatorService instance = PriceCalculatorService._();
  PriceCalculatorService._();

  // Настройки по умолчанию (можно будет загружать из Firebase)
  static const double _defaultBaseCost = 500.0; // Базовая стоимость
  static const double _defaultCostPerKm = 15.0; // Цена за км
  static const double _defaultMinPrice = 1000.0; // Минимальная цена
  static const bool _defaultRoundToThousands = true; // Округление до тысяч

  /// Рассчитать стоимость поездки
  Future<PriceCalculation> calculatePrice(
    double distanceKm, {
    double? baseCost,
    double? costPerKm,
    double? minPrice,
    bool? roundToThousands,
  }) async {
    final base = baseCost ?? _defaultBaseCost;
    final perKm = costPerKm ?? _defaultCostPerKm;
    final min = minPrice ?? _defaultMinPrice;
    final round = roundToThousands ?? _defaultRoundToThousands;

    print('💰 [PRICE CALCULATOR] ========== РАСЧЁТ СТОИМОСТИ ==========');
    print(
      '💰 [PRICE CALCULATOR] Расстояние: ${distanceKm.toStringAsFixed(1)} км',
    );
    print('💰 [PRICE CALCULATOR] Базовая стоимость: $base₽');
    print('💰 [PRICE CALCULATOR] Цена за км: $perKm₽');

    // Формула: Базовая цена + (расстояние × цена_за_км)
    final distancePrice = distanceKm * perKm;
    var totalPrice = base + distancePrice;

    // Применяем минимальную цену
    if (totalPrice < min) {
      print('💰 [PRICE CALCULATOR] Применена минимальная цена: $min₽');
      totalPrice = min;
    }

    // Округление до тысяч вверх (опционально)
    var finalPrice = totalPrice;
    if (round && totalPrice > 1000) {
      finalPrice = (totalPrice / 1000).ceil() * 1000.0;
      print('💰 [PRICE CALCULATOR] Округлено до: $finalPrice₽');
    }

    final formula =
        '$base₽ (база) + ${distanceKm.toStringAsFixed(1)} км × $perKm₽ = ${totalPrice.toStringAsFixed(0)}₽';

    print('💰 [PRICE CALCULATOR] Итого: $finalPrice₽');
    print('💰 [PRICE CALCULATOR] ========================================');

    return PriceCalculation(
      basePrice: base,
      distancePrice: distancePrice,
      finalPrice: finalPrice,
      formula: formula,
    );
  }
}
