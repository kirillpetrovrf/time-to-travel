/// Категории животных (НОВАЯ ЛОГИКА v4.0)
/// Упрощённая схема без учёта веса
enum PetCategory {
  upTo5kgWithCarrier, // До 5 кг в переноске - БЕСПЛАТНО
  upTo5kgWithoutCarrier, // До 5 кг без переноски - 1000₽
  over6kg, // Свыше 6 кг - 2000₽ + индивидуальный трансфер
}

/// УСТАРЕВШИЙ enum (для обратной совместимости)
/// TODO: Удалить после миграции всех данных
@Deprecated('Используйте PetCategory вместо PetSize')
enum PetSize { s, m, l }

/// Информация о животном (ОБНОВЛЕНО под ТЗ v4.0 - упрощённая схема)
class PetInfo {
  final PetCategory category;
  final String breed; // Автозаполнение по категории
  final String? description; // Дополнительное описание
  final bool agreementAccepted; // Согласие с условиями перевозки

  // Для обратной совместимости (УСТАРЕВШИЕ)
  @Deprecated('Используйте category')
  final PetSize? size;

  const PetInfo({
    required this.category,
    required this.breed,
    this.description,
    required this.agreementAccepted,
    @Deprecated('Используйте category') this.size,
  });

  /// Автоматическое заполнение названия по категории
  static String getDefaultBreed(PetCategory category) {
    switch (category) {
      case PetCategory.upTo5kgWithCarrier:
        return 'Животное до 5 кг в переноске';
      case PetCategory.upTo5kgWithoutCarrier:
        return 'Животное до 5 кг без переноски';
      case PetCategory.over6kg:
        return 'Животное свыше 6 кг';
    }
  }

  /// Получение описания категории
  String get categoryDescription {
    switch (category) {
      case PetCategory.upTo5kgWithCarrier:
        return 'До 5 кг в переноске';
      case PetCategory.upTo5kgWithoutCarrier:
        return 'До 5 кг без переноски';
      case PetCategory.over6kg:
        return 'Свыше 6 кг';
    }
  }

  /// Требует ли индивидуальную поездку
  bool get requiresIndividualTrip {
    return category == PetCategory.over6kg;
  }

  /// Получение стоимости
  double get cost {
    switch (category) {
      case PetCategory.upTo5kgWithCarrier:
        return 0.0; // Бесплатно
      case PetCategory.upTo5kgWithoutCarrier:
        return 1000.0; // 1000₽
      case PetCategory.over6kg:
        return 2000.0; // 2000₽ (+ индивидуальный трансфер 8000₽)
    }
  }

  /// Получение полной стоимости (с индивидуальным трансфером если нужно)
  double get totalCost {
    if (category == PetCategory.over6kg) {
      return 2000.0 +
          8000.0; // 2000₽ за животное + 8000₽ индивидуальный трансфер
    }
    return cost;
  }

  /// Конвертация в Map для сохранения в Firestore (ОБНОВЛЕНО v4.0)
  Map<String, dynamic> toJson() {
    return {
      'category': category.name,
      'breed': breed,
      'description': description,
      'agreementAccepted': agreementAccepted,
      // Для обратной совместимости сохраняем size
      'size': _categoryToSize(category).name,
    };
  }

  /// Создание из Map из Firestore (ОБНОВЛЕНО v4.0)
  factory PetInfo.fromJson(Map<String, dynamic> json) {
    // Пытаемся загрузить новую категорию
    PetCategory? category;
    if (json.containsKey('category')) {
      try {
        category = PetCategory.values.firstWhere(
          (e) => e.name == json['category'],
        );
      } catch (e) {
        // Если категория не найдена, используем старую логику
      }
    }

    // Если категории нет, конвертируем из старого size
    if (category == null && json.containsKey('size')) {
      final size = PetSize.values.firstWhere(
        (e) => e.name == json['size'],
        orElse: () => PetSize.s,
      );
      category = _sizeToCategory(size);
    }

    // По умолчанию - с переноской
    category ??= PetCategory.upTo5kgWithCarrier;

    return PetInfo(
      category: category,
      breed: json['breed'] ?? getDefaultBreed(category),
      description: json['description'],
      agreementAccepted: json['agreementAccepted'] ?? false,
    );
  }

  /// Копирование с изменениями
  PetInfo copyWith({
    PetCategory? category,
    String? breed,
    String? description,
    bool? agreementAccepted,
  }) {
    return PetInfo(
      category: category ?? this.category,
      breed: breed ?? this.breed,
      description: description ?? this.description,
      agreementAccepted: agreementAccepted ?? this.agreementAccepted,
    );
  }

  @override
  String toString() {
    return 'PetInfo(category: ${category.name}, breed: $breed)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetInfo &&
        other.category == category &&
        other.breed == breed &&
        other.description == description &&
        other.agreementAccepted == agreementAccepted;
  }

  @override
  int get hashCode {
    return category.hashCode ^
        breed.hashCode ^
        description.hashCode ^
        agreementAccepted.hashCode;
  }

  // Вспомогательные методы для конвертации (обратная совместимость)
  static PetCategory _sizeToCategory(PetSize size) {
    switch (size) {
      case PetSize.s:
        return PetCategory.upTo5kgWithCarrier; // По умолчанию с переноской
      case PetSize.m:
      case PetSize.l:
        return PetCategory.over6kg;
    }
  }

  static PetSize _categoryToSize(PetCategory category) {
    switch (category) {
      case PetCategory.upTo5kgWithCarrier:
      case PetCategory.upTo5kgWithoutCarrier:
        return PetSize.s;
      case PetCategory.over6kg:
        return PetSize.l;
    }
  }
}

/// Утилиты для работы с животными (ОБНОВЛЕНО под ТЗ v4.0)
class PetUtils {
  /// Получение краткого описания для животного
  static String formatPetSummary(PetInfo? petInfo) {
    if (petInfo == null) return 'Без животных';

    final categoryText = petInfo.categoryDescription;
    final costText = petInfo.cost > 0
        ? ' (+${petInfo.cost.toInt()}₽)'
        : ' (Бесплатно)';
    return '$categoryText$costText';
  }

  /// Проверка необходимости принудительной индивидуальной поездки
  static bool requiresIndividualTrip(PetInfo? petInfo) {
    return petInfo?.requiresIndividualTrip ?? false;
  }

  /// Получение дополнительной стоимости за животное
  static double getCost(PetInfo? petInfo) {
    return petInfo?.cost ?? 0.0;
  }

  /// Получение описания для отображения в UI
  static String getDisplayDescription(PetInfo petInfo) {
    return '${petInfo.breed} • ${petInfo.categoryDescription}';
  }
}
