import '../models/baggage.dart';

/// Сервис для управления ценами на дополнительный багаж (ТЗ v3.0)
/// ВРЕМЕННО: Хардкодированные цены (до подключения Firebase)
/// TODO: Заменить на Firebase когда будет готово
class BaggagePricingService {
  // Хардкодированные цены на дополнительный багаж
  static const double sPricePerExtra = 500.0;   // S: 500₽
  static const double mPricePerExtra = 1000.0;  // M: 1000₽
  static const double lPricePerExtra = 2000.0;  // L: 2000₽
  static const double customPricePerExtra = 0.0; // Custom: цена определяется диспетчером

  // Текст для индивидуального багажа
  static const String customBaggagePriceText = 
    'Для уточнения цены нужно связаться с диспетчером. '
    'После оформления заказа с Вами свяжется диспетчер и скажет точную стоимость индивидуального багажа.';

  /// Получение цен на дополнительный багаж
  static Future<Map<BaggageSize, double>> getExtraBaggagePrices() async {
    // Возвращаем хардкодированные цены
    // Для custom багажа цена = 0, так как определяется диспетчером
    return {
      BaggageSize.s: sPricePerExtra,
      BaggageSize.m: mPricePerExtra,
      BaggageSize.l: lPricePerExtra,
      BaggageSize.custom: customPricePerExtra, // 0.0 - цена определяется диспетчером
    };
  }

  /// Обновление цен на дополнительный багаж (пока не реализовано)
  static Future<void> updateExtraBaggagePrices({
    required double sPricePerExtra,
    required double mPricePerExtra,
    required double lPricePerExtra,
    required double customPricePerExtra,
  }) async {
    print('⚠️ Обновление цен пока недоступно (Firebase не подключен)');
    // TODO: Реализовать когда подключится Firebase
  }

  /// Стрим для отслеживания изменений цен (пока возвращает статичные данные)
  static Stream<Map<BaggageSize, double>> getExtraBaggagePricesStream() {
    return Stream.value({
      BaggageSize.s: sPricePerExtra,
      BaggageSize.m: mPricePerExtra,
      BaggageSize.l: lPricePerExtra,
      BaggageSize.custom: customPricePerExtra,
    });
  }

  /// Создание BaggageItem с актуальными ценами
  static Future<BaggageItem> createBaggageItemWithPricing({
    required BaggageSize size,
    required int quantity,
    String? customDescription,
    String? customDimensions,
  }) async {
    final prices = await getExtraBaggagePrices();
    final pricePerExtraItem = prices[size] ?? 0.0;

    return BaggageItem(
      size: size,
      quantity: quantity,
      customDescription: customDescription,
      customDimensions: customDimensions,
      pricePerExtraItem: pricePerExtraItem,
    );
  }

  /// Получение информации о стоимости для отображения в UI
  static Future<String> getPriceDisplayText(BaggageSize size) async {
    final prices = await getExtraBaggagePrices();
    final pricePerExtra = prices[size] ?? 0.0;

    if (size == BaggageSize.custom) {
      return 'Цена уточняется диспетчером';
    } else if (pricePerExtra == 0.0) {
      return 'БЕСПЛАТНО';
    } else {
      return 'Доп. багаж: ${pricePerExtra.toStringAsFixed(0)}₽/шт';
    }
  }
}
