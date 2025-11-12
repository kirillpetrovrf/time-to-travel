/// Размеры багажа
enum BaggageSize {
  s, // S: 30×40×20 см (рюкзак)
  m, // M: 50×60×25 см (спортивная сумка)
  l, // L: 70×80×30 см (чемодан)
  custom, // Пользовательский размер
}

/// Модель единицы багажа (ОБНОВЛЕНО под ТЗ v3.0)
class BaggageItem {
  final BaggageSize size;
  final int quantity; // НОВОЕ: от 1 до 10
  final String? customDescription; // Для размера "custom"
  final String? customDimensions; // "Д×Ш×В см" для размера "custom"
  final double
  pricePerExtraItem; // НОВОЕ: цена за дополнительный багаж (настраивается диспетчером)

  const BaggageItem({
    required this.size,
    required this.quantity,
    this.customDescription,
    this.customDimensions,
    required this.pricePerExtraItem,
  });

  /// НОВАЯ ЛОГИКА: первое место бесплатно
  double calculateCost() {
    if (quantity <= 1) return 0.0; // Первое место бесплатно
    return (quantity - 1) * pricePerExtraItem;
  }

  /// Проверка на допустимое количество
  bool get isQuantityValid => quantity >= 1 && quantity <= 10;

  /// Получение описания размера (ОБНОВЛЕНО под ТЗ v3.0)
  String get sizeDescription {
    switch (size) {
      case BaggageSize.s:
        return 'Рюкзак (S: 30×40×20 см)';
      case BaggageSize.m:
        return 'Спортивная сумка (M: 50×60×25 см)';
      case BaggageSize.l:
        return 'Чемодан (L: 70×80×30 см)';
      case BaggageSize.custom:
        return customDescription ?? 'Другое';
    }
  }

  /// Получение габаритов (ОБНОВЛЕНО под ТЗ v3.0)
  String get dimensions {
    switch (size) {
      case BaggageSize.s:
        return '30×40×20 см';
      case BaggageSize.m:
        return '50×60×25 см';
      case BaggageSize.l:
        return '70×80×30 см';
      case BaggageSize.custom:
        return customDimensions ?? 'Не указано';
    }
  }

  /// Получение примеров предметов (НОВОЕ)
  String get examples {
    switch (size) {
      case BaggageSize.s:
        return 'Рюкзак, небольшая сумка';
      case BaggageSize.m:
        return 'Спортивная сумка, средний чемодан';
      case BaggageSize.l:
        return 'Большой чемодан, коробка';
      case BaggageSize.custom:
        return 'Гитара, микроволновка, нестандартные предметы';
    }
  }

  /// Получение веса (НОВОЕ)
  String get weightDescription {
    switch (size) {
      case BaggageSize.s:
        return 'до 10 кг';
      case BaggageSize.m:
        return 'до 20 кг';
      case BaggageSize.l:
        return 'до 32 кг';
      case BaggageSize.custom:
        return 'по согласованию';
    }
  }

  /// Получение приблизительного объёма для расчёта места в багажнике
  double get volumeScore {
    switch (size) {
      case BaggageSize.s:
        return 1.0 * quantity;
      case BaggageSize.m:
        return 2.5 * quantity;
      case BaggageSize.l:
        return 4.0 * quantity;
      case BaggageSize.custom:
        // Для пользовательского размера считаем как средний
        return 2.5 * quantity;
    }
  }

  /// Конвертация в Map для сохранения (ОБНОВЛЕНО)
  Map<String, dynamic> toJson() {
    return {
      'size': size.name,
      'quantity': quantity,
      'customDescription': customDescription,
      'customDimensions': customDimensions,
      'pricePerExtraItem': pricePerExtraItem,
    };
  }

  /// Создание из Map (ОБНОВЛЕНО)
  factory BaggageItem.fromJson(Map<String, dynamic> json) {
    return BaggageItem(
      size: BaggageSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () => BaggageSize.s,
      ),
      quantity: json['quantity'] ?? 1,
      customDescription: json['customDescription'],
      customDimensions: json['customDimensions'],
      pricePerExtraItem: (json['pricePerExtraItem'] ?? 0.0).toDouble(),
    );
  }

  /// Копирование с изменениями (НОВОЕ)
  BaggageItem copyWith({
    BaggageSize? size,
    int? quantity,
    String? customDescription,
    String? customDimensions,
    double? pricePerExtraItem,
  }) {
    return BaggageItem(
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      customDescription: customDescription ?? this.customDescription,
      customDimensions: customDimensions ?? this.customDimensions,
      pricePerExtraItem: pricePerExtraItem ?? this.pricePerExtraItem,
    );
  }

  @override
  String toString() {
    if (quantity == 0) return '';
    return '$quantity × $sizeDescription';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaggageItem &&
        other.size == size &&
        other.quantity == quantity &&
        other.customDescription == customDescription &&
        other.customDimensions == customDimensions;
  }

  @override
  int get hashCode {
    return size.hashCode ^
        quantity.hashCode ^
        customDescription.hashCode ^
        customDimensions.hashCode;
  }
}

/// Утилиты для работы с багажом (ОБНОВЛЕНО под ТЗ v3.0)
class BaggageUtils {
  /// Стандартные типы багажа для быстрого выбора
  static const List<BaggageSize> standardSizes = [
    BaggageSize.s,
    BaggageSize.m,
    BaggageSize.l,
  ];

  /// Получение общего объёма багажа для группы пассажиров
  static double getTotalBaggageVolume(List<BaggageItem> baggageList) {
    return baggageList.fold(0.0, (total, item) => total + item.volumeScore);
  }

  /// Проверка, поместится ли багаж в стандартный багажник
  /// (условное максимальное значение для одной машины)
  static bool fitsInStandardTrunk(List<BaggageItem> baggageList) {
    const double maxTrunkVolume = 15.0; // Условные единицы объёма
    return getTotalBaggageVolume(baggageList) <= maxTrunkVolume;
  }

  /// Создание пустого багажа (ОБНОВЛЕНО)
  static List<BaggageItem> createEmptyBaggage() {
    return standardSizes
        .map(
          (size) =>
              BaggageItem(size: size, quantity: 0, pricePerExtraItem: 0.0),
        )
        .toList();
  }

  /// Формирование краткого описания багажа для отображения
  static String formatBaggageSummary(List<BaggageItem> baggageList) {
    final nonEmptyItems = baggageList.where((item) => item.quantity > 0);

    if (nonEmptyItems.isEmpty) {
      return 'Без багажа';
    }

    final descriptions = nonEmptyItems.map((item) => item.toString());
    return descriptions.join(', ');
  }

  /// НОВОЕ: Расчет общей стоимости багажа (первое место бесплатно)
  static double calculateTotalBaggageCost(List<BaggageItem> baggageList) {
    return baggageList.fold(0.0, (total, item) => total + item.calculateCost());
  }

  /// НОВОЕ: Проверка валидности количества багажа
  static bool isValidBaggageQuantity(List<BaggageItem> baggageList) {
    return baggageList.every((item) => item.isQuantityValid);
  }
}
