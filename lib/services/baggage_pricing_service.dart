import 'package:flutter/foundation.dart';
import '../models/baggage.dart';

/// Сервис для управления ценами на дополнительный багаж (ТЗ v3.0)
///
/// ⚠️ ВАЖНО: Сейчас используются только локальные данные
/// TODO: Интеграция с Firebase - реализуется позже
class BaggagePricingService {
  // TODO: Интеграция с Firebase - реализуется позже
  // static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // static const String _collectionPath = 'settings';
  // static const String _documentId = 'baggage_pricing';

  // Дефолтные цены (локальные)
  static const double defaultSPricePerExtra = 500.0; // S: 500₽
  static const double defaultMPricePerExtra = 1000.0; // M: 1000₽
  static const double defaultLPricePerExtra = 2000.0; // L: 2000₽
  static const double defaultCustomPricePerExtra =
      0.0; // Custom: цена определяется диспетчером

  // Текст для индивидуального багажа
  static const String customBaggagePriceText =
      'Для уточнения цены нужно связаться с диспетчером. '
      'После оформления заказа с Вами свяжется диспетчер и скажет точную стоимость индивидуального багажа.';

  /// Получение цен на дополнительный багаж (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  static Future<Map<BaggageSize, double>> getExtraBaggagePrices() async {
    debugPrint('ℹ️ Используются локальные цены багажа (Firebase не подключен)');
    return _getDefaultPrices();
  }

  /// Обновление цен на дополнительный багаж (для диспетчера)
  /// TODO: Интеграция с Firebase - реализуется позже
  static Future<void> updateExtraBaggagePrices({
    required double sPricePerExtra,
    required double mPricePerExtra,
    required double lPricePerExtra,
    required double customPricePerExtra,
  }) async {
    debugPrint(
      'ℹ️ Обновление цен багажа сохранено локально (Firebase не подключен)',
    );
    // В будущем здесь будет сохранение в Firebase
  }

  /// Стрим для отслеживания изменений цен в реальном времени
  /// TODO: Интеграция с Firebase - реализуется позже
  static Stream<Map<BaggageSize, double>> getExtraBaggagePricesStream() {
    debugPrint(
      'ℹ️ Используется локальный стрим цен багажа (Firebase не подключен)',
    );
    return Stream.value(_getDefaultPrices());
  }

  /// Получение дефолтных цен
  static Map<BaggageSize, double> _getDefaultPrices() {
    return {
      BaggageSize.s: defaultSPricePerExtra,
      BaggageSize.m: defaultMPricePerExtra,
      BaggageSize.l: defaultLPricePerExtra,
      BaggageSize.custom: defaultCustomPricePerExtra,
    };
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
