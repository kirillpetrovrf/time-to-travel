/// Размеры животных для тарификации (ОБНОВЛЕНО под ТЗ v3.0)
/// ИЗМЕНЕНИЯ: Убран размер XS, добавлена система согласий
enum PetSize {
  s, // S: Маленький (до 8 кг) - кошка, маленькая собака
  m, // M: Средний (до 25 кг) - ТОЛЬКО индивидуальная поездка
  l, // L: Большой (свыше 25 кг) - ТОЛЬКО индивидуальная поездка
}

/// Информация о животном (ОБНОВЛЕНО под ТЗ v3.0)
class PetInfo {
  final PetSize size;
  final String breed;
  final String? description; // Дополнительное описание животного
  final bool agreementAccepted; // НОВОЕ: согласие с условиями перевозки

  const PetInfo({
    required this.size,
    required this.breed,
    this.description,
    required this.agreementAccepted,
  });

  /// Получение описания размера (ОБНОВЛЕНО)
  String get sizeDescription {
    switch (size) {
      case PetSize.s:
        return 'Маленький (S)';
      case PetSize.m:
        return 'Средний (M)';
      case PetSize.l:
        return 'Большой (L)';
    }
  }

  /// Получение ограничения по весу (НОВОЕ)
  String get weightLimit {
    switch (size) {
      case PetSize.s:
        return 'до 8 кг';
      case PetSize.m:
        return 'до 25 кг';
      case PetSize.l:
        return 'свыше 25 кг';
    }
  }

  /// Получение примеров животных (НОВОЕ)
  String get examples {
    switch (size) {
      case PetSize.s:
        return 'Кошка, маленькая собака (чихуахуа, той-терьер)';
      case PetSize.m:
        return 'Средняя собака (спаниель, бигль)';
      case PetSize.l:
        return 'Крупная собака (лабрадор, немецкая овчарка)';
    }
  }

  /// Способ транспортировки (НОВОЕ)
  String get transportMethod {
    switch (size) {
      case PetSize.s:
        return 'В переноске в салоне';
      case PetSize.m:
        return 'Только индивидуальная поездка (отдельное место)';
      case PetSize.l:
        return 'Только индивидуальная поездка (отдельное место)';
    }
  }

  /// Требует ли индивидуальную поездку (НОВОЕ)
  bool get requiresIndividualTrip {
    return size == PetSize.m || size == PetSize.l;
  }

  /// Получение стоимости (ОБНОВЛЕНО под ТЗ v3.0)
  double get cost {
    switch (size) {
      case PetSize.s:
        return 500.0; // +500₽
      case PetSize.m:
      case PetSize.l:
        return 2000.0; // +2000₽ + принудительная индивидуальная поездка
    }
  }

  /// Требует ли обязательного согласия (НОВОЕ)
  bool get requiresAgreement {
    return size == PetSize.m || size == PetSize.l;
  }

  /// Конвертация в Map для сохранения в Firestore (ОБНОВЛЕНО)
  Map<String, dynamic> toJson() {
    return {
      'size': size.name,
      'breed': breed,
      'description': description,
      'agreementAccepted': agreementAccepted,
    };
  }

  /// Создание из Map из Firestore (ОБНОВЛЕНО)
  factory PetInfo.fromJson(Map<String, dynamic> json) {
    return PetInfo(
      size: PetSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () => PetSize.s,
      ),
      breed: json['breed'] ?? '',
      description: json['description'],
      agreementAccepted: json['agreementAccepted'] ?? false,
    );
  }

  /// Копирование с изменениями (НОВОЕ)
  PetInfo copyWith({
    PetSize? size,
    String? breed,
    String? description,
    bool? agreementAccepted,
  }) {
    return PetInfo(
      size: size ?? this.size,
      breed: breed ?? this.breed,
      description: description ?? this.description,
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
    );
  }

  @override
  String toString() {
    return 'PetInfo(size: $size, breed: $breed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetInfo &&
        other.size == size &&
        other.breed == breed &&
        other.description == description &&
        other.agreementAccepted == agreementAccepted;
  }

  @override
  int get hashCode {
    return size.hashCode ^
        breed.hashCode ^
        description.hashCode ^
        agreementAccepted.hashCode;
  }
}

/// Утилиты для работы с животными (ОБНОВЛЕНО под ТЗ v3.0)
class PetUtils {
  /// Получение краткого описания для животного
  static String formatPetSummary(PetInfo? petInfo) {
    if (petInfo == null) return 'Без животных';

    final sizeText = petInfo.sizeDescription;
    final costText = petInfo.cost > 0 ? ' (+${petInfo.cost.toInt()}₽)' : '';
    return '${petInfo.breed} ($sizeText)$costText';
  }

  /// Проверка необходимости принудительной индивидуальной поездки
  static bool requiresIndividualTrip(PetInfo? petInfo) {
    return petInfo?.requiresIndividualTrip ?? false;
  }

  /// Получение дополнительной стоимости за животное
  static double getCost(PetInfo? petInfo) {
    return petInfo?.cost ?? 0.0;
  }

  /// Проверка валидности согласия
  static bool isAgreementValid(PetInfo? petInfo) {
    if (petInfo == null) return true;
    if (!petInfo.requiresAgreement) return true;
    return petInfo.agreementAccepted;
  }

  /// Получение описания для отображения в UI
  static String getDisplayDescription(PetInfo petInfo) {
    final parts = <String>[
      '${petInfo.breed} (${petInfo.sizeDescription})',
      petInfo.weightLimit,
    ];

    if (petInfo.description?.isNotEmpty == true) {
      parts.add(petInfo.description!);
    }

    return parts.join(' • ');
  }
}
