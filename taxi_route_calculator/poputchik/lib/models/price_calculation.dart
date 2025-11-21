/// Результат расчета стоимости поездки
class PriceCalculation {
  final double basePrice; // Базовая стоимость
  final double distancePrice; // Стоимость за расстояние
  final double finalPrice; // Итоговая стоимость
  final String formula; // Формула расчета (для отладки)

  PriceCalculation({
    required this.basePrice,
    required this.distancePrice,
    required this.finalPrice,
    required this.formula,
  });

  @override
  String toString() {
    return 'PriceCalculation(base: $basePrice₽, distance: $distancePrice₽, final: $finalPrice₽)';
  }
}
