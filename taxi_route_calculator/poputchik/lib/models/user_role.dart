/// Роль пользователя в приложении
enum UserRole {
  /// Водитель - создает поездки, принимает пассажиров
  driver,

  /// Пассажир - ищет и бронирует поездки
  passenger,
}

extension UserRoleExtension on UserRole {
  /// Получить текстовое представление роли
  String get displayName {
    switch (this) {
      case UserRole.driver:
        return 'Водитель';
      case UserRole.passenger:
        return 'Пассажир';
    }
  }

  /// Получить описание роли
  String get description {
    switch (this) {
      case UserRole.driver:
        return 'Создавайте поездки и находите попутчиков';
      case UserRole.passenger:
        return 'Ищите поездки и экономьте на дороге';
    }
  }

  /// Конвертировать в строку для хранения
  String toStorageString() {
    return name;
  }

  /// Создать из строки
  static UserRole? fromStorageString(String? value) {
    if (value == null) return null;
    try {
      return UserRole.values.firstWhere((role) => role.name == value);
    } catch (_) {
      return null;
    }
  }
}
