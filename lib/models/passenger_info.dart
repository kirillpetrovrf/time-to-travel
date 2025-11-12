/// Модель информации о пассажире
class PassengerInfo {
  final PassengerType type;
  final ChildSeatType? seatType; // Только для детей
  final bool useOwnSeat; // Своё кресло или водителя (только для детей)
  final int? ageMonths; // Возраст в месяцах для детей

  PassengerInfo({
    required this.type,
    this.seatType,
    this.useOwnSeat = false,
    this.ageMonths,
  });

  bool get isChild => type == PassengerType.child;
  bool get isAdult => type == PassengerType.adult;

  String get displayName {
    if (isAdult) return 'Взрослый';
    if (seatType != null) {
      return 'Ребенок (${seatType!.displayName})';
    }
    return 'Ребенок';
  }

  String get seatInfo {
    if (isAdult) return '';
    if (seatType == null) return '';
    return useOwnSeat ? 'Своё кресло' : 'Кресло водителя';
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'seatType': seatType?.toString(),
      'useOwnSeat': useOwnSeat,
      'ageMonths': ageMonths,
    };
  }

  factory PassengerInfo.fromJson(Map<String, dynamic> json) {
    return PassengerInfo(
      type: PassengerType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      seatType: json['seatType'] != null
          ? ChildSeatType.values.firstWhere(
              (e) => e.toString() == json['seatType'],
            )
          : null,
      useOwnSeat: json['useOwnSeat'] ?? false,
      ageMonths: json['ageMonths'],
    );
  }

  PassengerInfo copyWith({
    PassengerType? type,
    ChildSeatType? seatType,
    bool? useOwnSeat,
    int? ageMonths,
  }) {
    return PassengerInfo(
      type: type ?? this.type,
      seatType: seatType ?? this.seatType,
      useOwnSeat: useOwnSeat ?? this.useOwnSeat,
      ageMonths: ageMonths ?? this.ageMonths,
    );
  }
}

/// Тип пассажира
enum PassengerType {
  adult, // Взрослый
  child, // Ребенок
}

/// Типы детских автокресел
enum ChildSeatType {
  cradle, // Люлька 0-12 месяцев
  seat, // Кресло 1-3 года
  booster, // Бустер 4-7 лет
  none, // Без кресла (8+ лет и 120+ см)
}

extension ChildSeatTypeExtension on ChildSeatType {
  String get displayName {
    switch (this) {
      case ChildSeatType.cradle:
        return 'Люлька (0-12 месяцев)';
      case ChildSeatType.seat:
        return 'Кресло (1-3 года)';
      case ChildSeatType.booster:
        return 'Бустер (4-7 лет)';
      case ChildSeatType.none:
        return 'Без кресла (8+ лет, 120+ см)';
    }
  }

  String get ageRange {
    switch (this) {
      case ChildSeatType.cradle:
        return '0-12 месяцев';
      case ChildSeatType.seat:
        return '1-3 года';
      case ChildSeatType.booster:
        return '4-7 лет';
      case ChildSeatType.none:
        return '8+ лет и рост 120+ см';
    }
  }

  String get description {
    switch (this) {
      case ChildSeatType.cradle:
        return 'Для младенцев от рождения до года';
      case ChildSeatType.seat:
        return 'Для детей от 1 года до 3 лет';
      case ChildSeatType.booster:
        return 'Для детей от 4 до 7 лет';
      case ChildSeatType.none:
        return 'Ремень безопасности не должен давить на горло';
    }
  }

  /// Рекомендуемый тип кресла по возрасту в месяцах
  static ChildSeatType? recommendByAge(int ageMonths) {
    if (ageMonths <= 12) return ChildSeatType.cradle;
    if (ageMonths <= 36) return ChildSeatType.seat;
    if (ageMonths <= 84) return ChildSeatType.booster;
    if (ageMonths >= 96) return ChildSeatType.none;
    return ChildSeatType.booster; // 7-8 лет по умолчанию бустер
  }
}
