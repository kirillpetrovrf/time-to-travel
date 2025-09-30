/// Размеры животных (ОБНОВЛЕНО под ТЗ v3.0 - убран XS)
enum PetSize {
  s, // S: до 5 кг (чихуахуа, йорк) - в салоне в переноске
  m, // M: 5-20 кг (шпиц, корги) - в багажнике
  l, // L: 20+ кг (лабрадор, овчарка) - в багажнике
}

/// Модель информации о животном (ПОЛНОСТЬЮ ПЕРЕПИСАНО под ТЗ v3.0)
class PetInfo {
  final PetSize size;
  final String? customDescription; // Дополнительная информация
  final bool agreementAccepted; // НОВОЕ: согласие на условия перевозки
  final String weight; // Вес животного
  final String breed; // Порода

  const PetInfo({
    required this.size,
    this.customDescription,
    required this.agreementAccepted,
    required this.weight,
    required this.breed,
  });

  /// Расчет стоимости перевозки животного (ТЗ v3.0)
  double get cost {
    switch (size) {
      case PetSize.s:
        return 500.0; // S: 500₽
      case PetSize.m:
      case PetSize.l:
        return 2000.0; // M/L: 2000₽ + принудительно индивидуальная поездка
    }
  }

  /// Дополнительная стоимость (для совместимости со старым кодом)
  double get additionalPrice => cost;

  /// Требуется ли индивидуальная поездка
  bool get requiresIndividualTrip {
    return size == PetSize.m || size == PetSize.l;
  }

  /// Описание размера
  String get sizeDescription {
    switch (size) {
      case PetSize.s:
        return 'S: до 5 кг (в салоне в переноске)';
      case PetSize.m:
        return 'M: 5-20 кг (в багажнике)';
      case PetSize.l:
        return 'L: 20+ кг (в багажнике)';
    }
  }

  /// Лимиты веса
  String get weightLimits {
    switch (size) {
      case PetSize.s:
        return 'до 5 кг';
      case PetSize.m:
        return '5-20 кг';
      case PetSize.l:
        return '20+ кг';
    }
  }

  /// Способ перевозки
  String get transportMethod {
    switch (size) {
      case PetSize.s:
        return 'В салоне в переноске';
      case PetSize.m:
      case PetSize.l:
        return 'В багажном отделении';
    }
  }

  /// Преобразование в Map для Firebase
  Map<String, dynamic> toMap() {
    return {
      'size': size.name,
      'customDescription': customDescription,
      'agreementAccepted': agreementAccepted,
      'weight': weight,
      'breed': breed,
    };
  }

  /// Создание из Map (Firebase)
  factory PetInfo.fromMap(Map<String, dynamic> map) {
    return PetInfo(
      size: PetSize.values.firstWhere((e) => e.name == map['size']),
      customDescription: map['customDescription'],
      agreementAccepted: map['agreementAccepted'] ?? false,
      weight: map['weight'] ?? '',
      breed: map['breed'] ?? '',
    );
  }

  /// Преобразование в JSON (для совместимости)
  Map<String, dynamic> toJson() => toMap();

  /// Создание из JSON (для совместимости)
  factory PetInfo.fromJson(Map<String, dynamic> json) => PetInfo.fromMap(json);

  /// Копирование с изменениями
  PetInfo copyWith({
    PetSize? size,
    String? customDescription,
    bool? agreementAccepted,
    String? weight,
    String? breed,
  }) {
    return PetInfo(
      size: size ?? this.size,
      customDescription: customDescription ?? this.customDescription,
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
      weight: weight ?? this.weight,
      breed: breed ?? this.breed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetInfo &&
        other.size == size &&
        other.customDescription == customDescription &&
        other.agreementAccepted == agreementAccepted &&
        other.weight == weight &&
        other.breed == breed;
  }

  @override
  int get hashCode {
    return size.hashCode ^
        customDescription.hashCode ^
        agreementAccepted.hashCode ^
        weight.hashCode ^
        breed.hashCode;
  }

  @override
  String toString() {
    return 'PetInfo(size: $size, weight: $weight, breed: $breed, agreementAccepted: $agreementAccepted)';
  }
}
