/// Модель результата расчёта цены для калькулятора
class PriceCalculation {
  final double rawPrice; // Сырая цена (до округления)
  final double finalPrice; // Финальная цена (после округления)
  final double distance; // Расстояние в км
  final double baseCost; // Базовая стоимость
  final double costPerKm; // Стоимость за км
  final bool roundedUp; // Было ли округление
  final bool appliedMinPrice; // Применена ли минимальная цена
  final bool isSpecialRoute; // Специальный маршрут (фиксированная цена)
  final double? roundedDistanceKm; // Округлённое расстояние, если применялось

  PriceCalculation({
    required this.rawPrice,
    required this.finalPrice,
    required this.distance,
    required this.baseCost,
    required this.costPerKm,
    required this.roundedUp,
    required this.appliedMinPrice,
    this.roundedDistanceKm,
    this.isSpecialRoute = false,
  });

  /// Форматированное объяснение расчёта для UI
  String get explanation {
    if (isSpecialRoute) {
      return 'Специальный маршрут: Донецк ↔ Ростов-на-Дону\n'
             'Фиксированная стоимость: ${finalPrice.toInt()} ₽\n'
             '${finalPrice == 8000 ? 'Дневной тариф (до 22:00)' : 'Ночной тариф (после 22:00)'}';
    }

    String result = 'Базовая стоимость: ${baseCost.toInt()} ₽\n';
  // Показываем округленное расстояние, если оно отличается
  final displayKm = (roundedDistanceKm != null && roundedDistanceKm != distance)
    ? '${distance.toInt()} → ${roundedDistanceKm!.toInt()}'
    : '${distance.toInt()}';
  result +=
    'Расстояние: $displayKm км × ${costPerKm.toInt()} ₽ = ${( (roundedDistanceKm ?? distance) * costPerKm).toInt()} ₽\n';
    result += 'Сумма: ${rawPrice.toInt()} ₽\n';

    if (appliedMinPrice) {
      result += '→ Применена минимальная цена: ${finalPrice.toInt()} ₽';
    } else if (roundedUp) {
      result += '→ Округлено до тысяч: ${finalPrice.toInt()} ₽';
    }

    return result;
  }

  /// Короткое объяснение для UI
  String get shortExplanation {
    if (isSpecialRoute) {
      return finalPrice == 8000 
          ? 'Спец. тариф Донецк-Ростов (дневной)'
          : 'Спец. тариф Донецк-Ростов (ночной)';
    }
    if (appliedMinPrice) {
      return 'Применена минимальная цена';
    } else if (roundedUp) {
      return 'Округлено до тысяч вверх';
    }
    return 'Точная стоимость';
  }

  /// Формула расчёта
  String get formula {
    final usedKm = (roundedDistanceKm != null) ? roundedDistanceKm!.toInt() : distance.toInt();
    return '$baseCost + (${usedKm} × $costPerKm) = ${rawPrice.toInt()} ₽';
  }

  @override
  String toString() {
    return 'PriceCalculation(${distance.toInt()} км → ${finalPrice.toInt()} ₽)';
  }
}
