import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для управления ценообразованием свободных маршрутов (ТЗ v3.0)
/// Диспетчер может изменять формулу расчета через админ-панель
class FreeRoutePricingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionPath = 'settings';
  static const String _documentId = 'free_route_pricing';

  /// Получение настроек ценообразования от диспетчера
  static Future<PricingSettings> getPricingSettings() async {
    try {
      final doc = await _firestore
          .collection(_collectionPath)
          .doc(_documentId)
          .get();

      if (!doc.exists) {
        return _getDefaultPricingSettings();
      }

      final data = doc.data() as Map<String, dynamic>;
      
      return PricingSettings(
        basePrice: (data['basePrice'] ?? 500.0).toDouble(),
        pricePerKm: (data['pricePerKm'] ?? 15.0).toDouble(),
        cityFee: (data['cityFee'] ?? 200.0).toDouble(),
        minimumPrice: (data['minimumPrice'] ?? 1000.0).toDouble(),
        roundUpToThousands: data['roundUpToThousands'] ?? true,
      );
    } catch (e) {
      print('Ошибка загрузки настроек ценообразования: $e');
      return _getDefaultPricingSettings();
    }
  }

  /// Обновление настроек ценообразования (только для диспетчера)
  static Future<void> updatePricingSettings(PricingSettings settings) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(_documentId)
          .set({
        'basePrice': settings.basePrice,
        'pricePerKm': settings.pricePerKm,
        'cityFee': settings.cityFee,
        'minimumPrice': settings.minimumPrice,
        'roundUpToThousands': settings.roundUpToThousands,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Ошибка обновления настроек ценообразования: $e');
      throw Exception('Не удалось обновить настройки ценообразования');
    }
  }

  /// Стрим для отслеживания изменений настроек в реальном времени
  static Stream<PricingSettings> getPricingSettingsStream() {
    return _firestore
        .collection(_collectionPath)
        .doc(_documentId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return _getDefaultPricingSettings();
      }

      final data = doc.data() as Map<String, dynamic>;
      
      return PricingSettings(
        basePrice: (data['basePrice'] ?? 500.0).toDouble(),
        pricePerKm: (data['pricePerKm'] ?? 15.0).toDouble(),
        cityFee: (data['cityFee'] ?? 200.0).toDouble(),
        minimumPrice: (data['minimumPrice'] ?? 1000.0).toDouble(),
        roundUpToThousands: data['roundUpToThousands'] ?? true,
      );
    });
  }

  /// Расчет стоимости поездки по формуле (ТЗ v3.0)
  static Future<double> calculatePrice(double distanceKm) async {
    final settings = await getPricingSettings();
    return calculatePriceWithSettings(distanceKm, settings);
  }

  /// Расчет стоимости с переданными настройками
  static double calculatePriceWithSettings(double distanceKm, PricingSettings settings) {
    // Базовая формула: Стоимость = Базовая_ставка + (Расстояние_км × Коэффициент_за_км) + Городские_доплаты
    double price = settings.basePrice + (distanceKm * settings.pricePerKm) + settings.cityFee;
    
    // Применяем минимальную цену
    if (price < settings.minimumPrice) {
      price = settings.minimumPrice;
    }
    
    // Округление вверх до тысяч (если включено)
    if (settings.roundUpToThousands) {
      price = (price / 1000).ceil() * 1000.0;
    }
    
    return price;
  }

  /// Дефолтные настройки ценообразования
  static PricingSettings _getDefaultPricingSettings() {
    return const PricingSettings(
      basePrice: 500.0,      // Базовая ставка
      pricePerKm: 15.0,      // Коэффициент за км
      cityFee: 200.0,        // Городские доплаты
      minimumPrice: 1000.0,  // Минимальная цена
      roundUpToThousands: true, // Округление вверх до тысяч
    );
  }

  /// Получение описания формулы для отображения
  static Future<String> getPricingFormulaDescription() async {
    final settings = await getPricingSettings();
    return 'Стоимость = ${settings.basePrice.toInt()}₽ + (км × ${settings.pricePerKm.toInt()}₽) + ${settings.cityFee.toInt()}₽\n'
           'Минимум: ${settings.minimumPrice.toInt()}₽${settings.roundUpToThousands ? ', округление до тысяч' : ''}';
  }
}

/// Настройки ценообразования для свободных маршрутов
class PricingSettings {
  final double basePrice;        // Базовая ставка (стартовая цена)
  final double pricePerKm;       // Коэффициент за км
  final double cityFee;          // Городские доплаты
  final double minimumPrice;     // Минимальная цена поездки
  final bool roundUpToThousands; // Округление вверх до тысяч

  const PricingSettings({
    required this.basePrice,
    required this.pricePerKm,
    required this.cityFee,
    required this.minimumPrice,
    required this.roundUpToThousands,
  });

  Map<String, dynamic> toJson() {
    return {
      'basePrice': basePrice,
      'pricePerKm': pricePerKm,
      'cityFee': cityFee,
      'minimumPrice': minimumPrice,
      'roundUpToThousands': roundUpToThousands,
    };
  }

  factory PricingSettings.fromJson(Map<String, dynamic> json) {
    return PricingSettings(
      basePrice: (json['basePrice'] ?? 500.0).toDouble(),
      pricePerKm: (json['pricePerKm'] ?? 15.0).toDouble(),
      cityFee: (json['cityFee'] ?? 200.0).toDouble(),
      minimumPrice: (json['minimumPrice'] ?? 1000.0).toDouble(),
      roundUpToThousands: json['roundUpToThousands'] ?? true,
    );
  }

  PricingSettings copyWith({
    double? basePrice,
    double? pricePerKm,
    double? cityFee,
    double? minimumPrice,
    bool? roundUpToThousands,
  }) {
    return PricingSettings(
      basePrice: basePrice ?? this.basePrice,
      pricePerKm: pricePerKm ?? this.pricePerKm,
      cityFee: cityFee ?? this.cityFee,
      minimumPrice: minimumPrice ?? this.minimumPrice,
      roundUpToThousands: roundUpToThousands ?? this.roundUpToThousands,
    );
  }
}
