import '../models/calculator_settings.dart';
import '../models/price_calculation.dart';
import 'calculator_settings_service.dart';

/// Сервис для расчёта стоимости поездки
class PriceCalculatorService {
  static final PriceCalculatorService instance = PriceCalculatorService._();
  PriceCalculatorService._();

  final CalculatorSettingsService _settingsService =
      CalculatorSettingsService.instance;

  /// Рассчитать стоимость поездки по расстоянию
  Future<PriceCalculation> calculatePrice(double distanceKm) async {
    print('💰 [PRICE] ========== РАСЧЁТ СТОИМОСТИ ==========');
    print('💰 [PRICE] Расстояние: ${distanceKm.toStringAsFixed(2)} км');

    final settings = await _settingsService.getSettings();
    print(
      '💰 [PRICE] Настройки: base=${settings.baseCost}₽, perKm=${settings.costPerKm}₽, min=${settings.minPrice}₽',
    );

    // Формула: базовая + (км × коэффициент)
    double rawPrice = settings.baseCost + (distanceKm * settings.costPerKm);
    print('💰 [PRICE] Сырая цена: ${rawPrice.toStringAsFixed(2)}₽');

    // Проверка минимальной цены
    if (rawPrice < settings.minPrice) {
      print(
        '💰 [PRICE] ⚠️ Цена ниже минимума! Применяем минимальную: ${settings.minPrice}₽',
      );
      return PriceCalculation(
        rawPrice: rawPrice,
        finalPrice: settings.minPrice,
        distance: distanceKm,
        baseCost: settings.baseCost,
        costPerKm: settings.costPerKm,
        roundedUp: false,
        appliedMinPrice: true,
      );
    }

    // Округление до тысяч вверх (если включено)
    double finalPrice = rawPrice;
    bool roundedUp = false;

    if (settings.roundToThousands && rawPrice > settings.minPrice) {
      finalPrice = (rawPrice / 1000).ceil() * 1000;
      roundedUp = rawPrice != finalPrice;

      if (roundedUp) {
        print(
          '💰 [PRICE] 🔼 Округлено до тысяч: ${rawPrice.toStringAsFixed(0)}₽ → ${finalPrice.toStringAsFixed(0)}₽',
        );
      }
    }

    final calculation = PriceCalculation(
      rawPrice: rawPrice,
      finalPrice: finalPrice,
      distance: distanceKm,
      baseCost: settings.baseCost,
      costPerKm: settings.costPerKm,
      roundedUp: roundedUp,
      appliedMinPrice: false,
    );

    print(
      '💰 [PRICE] ========== ИТОГО: ${finalPrice.toStringAsFixed(0)}₽ ==========',
    );
    return calculation;
  }

  /// Получить примеры расчёта для админ-панели
  Future<Map<int, double>> getExamples() async {
    final distances = [10, 50, 100, 150, 200];
    final Map<int, double> examples = {};

    for (final distance in distances) {
      final calculation = await calculatePrice(distance.toDouble());
      examples[distance] = calculation.finalPrice;
    }

    return examples;
  }
}
