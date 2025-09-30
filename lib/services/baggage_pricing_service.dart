import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/baggage.dart';

/// Сервис для управления ценами на дополнительный багаж (ТЗ v3.0)
/// Цены настраиваются диспетчером через админ-панель
class BaggagePricingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'settings';
  static const String _documentId = 'baggage_pricing';

  /// Получение цен на дополнительный багаж от диспетчера
  static Future<Map<BaggageSize, double>> getExtraBaggagePrices() async {
    try {
      final doc = await _firestore
          .collection(_collectionPath)
          .doc(_documentId)
          .get();

      if (!doc.exists) {
        // Возвращаем дефолтные цены, если настройки не заданы
        return _getDefaultPrices();
      }

      final data = doc.data() as Map<String, dynamic>;

      return {
        BaggageSize.s: (data['extra_s_price'] ?? 0.0).toDouble(),
        BaggageSize.m: (data['extra_m_price'] ?? 0.0).toDouble(),
        BaggageSize.l: (data['extra_l_price'] ?? 0.0).toDouble(),
        BaggageSize.custom: (data['extra_custom_price'] ?? 0.0).toDouble(),
      };
    } catch (e) {
      print('Ошибка загрузки цен на багаж: $e');
      return _getDefaultPrices();
    }
  }

  /// Обновление цен на дополнительный багаж (только для диспетчера)
  static Future<void> updateExtraBaggagePrices({
    required double sPricePerExtra,
    required double mPricePerExtra,
    required double lPricePerExtra,
    required double customPricePerExtra,
  }) async {
    try {
      await _firestore.collection(_collectionPath).doc(_documentId).set({
        'extra_s_price': sPricePerExtra,
        'extra_m_price': mPricePerExtra,
        'extra_l_price': lPricePerExtra,
        'extra_custom_price': customPricePerExtra,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Ошибка обновления цен на багаж: $e');
      throw Exception('Не удалось обновить цены на багаж');
    }
  }

  /// Стрим для отслеживания изменений цен в реальном времени
  static Stream<Map<BaggageSize, double>> getExtraBaggagePricesStream() {
    return _firestore
        .collection(_collectionPath)
        .doc(_documentId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return _getDefaultPrices();
          }

          final data = doc.data() as Map<String, dynamic>;

          return {
            BaggageSize.s: (data['extra_s_price'] ?? 0.0).toDouble(),
            BaggageSize.m: (data['extra_m_price'] ?? 0.0).toDouble(),
            BaggageSize.l: (data['extra_l_price'] ?? 0.0).toDouble(),
            BaggageSize.custom: (data['extra_custom_price'] ?? 0.0).toDouble(),
          };
        });
  }

  /// Дефолтные цены (если диспетчер не задал цены)
  static Map<BaggageSize, double> _getDefaultPrices() {
    return {
      BaggageSize.s: 0.0, // Бесплатно по умолчанию
      BaggageSize.m: 0.0, // Бесплатно по умолчанию
      BaggageSize.l: 0.0, // Бесплатно по умолчанию
      BaggageSize.custom: 0.0, // Бесплатно по умолчанию
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

    if (pricePerExtra == 0.0) {
      return 'БЕСПЛАТНО';
    } else {
      return 'Доп. багаж: ${pricePerExtra.toStringAsFixed(0)}₽/шт';
    }
  }
}
