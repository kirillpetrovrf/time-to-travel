import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

/// Модель пользователя
@JsonSerializable()
class User {
  final String id;
  final String email;
  
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? passwordHash;
  
  final String name;
  final String? phone;
  final String role;
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    this.passwordHash,
    required this.name,
    this.phone,
    this.role = 'client',
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создание из JSON
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  /// Конвертация в JSON (без пароля)
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Создание из строки БД
  factory User.fromDb(Map<String, dynamic> row) {
    return User(
      id: row['id'] as String,
      email: row['email'] as String,
      passwordHash: row['password_hash'] as String?,
      name: row['name'] as String,
      phone: row['phone'] as String?,
      role: row['role'] as String? ?? 'client',
      isVerified: row['is_verified'] as bool? ?? false,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  /// Копирование с изменениями
  User copyWith({
    String? id,
    String? email,
    String? passwordHash,
    String? name,
    String? phone,
    String? role,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, role: $role, isVerified: $isVerified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// DTO для регистрации
@JsonSerializable()
class RegisterUserDto {
  final String email;
  final String password;
  final String name;
  final String? phone;

  const RegisterUserDto({
    required this.email,
    required this.password,
    required this.name,
    this.phone,
  });

  factory RegisterUserDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterUserDtoToJson(this);
}

/// DTO для входа
@JsonSerializable()
class LoginDto {
  final String email;
  final String password;

  const LoginDto({
    required this.email,
    required this.password,
  });

  factory LoginDto.fromJson(Map<String, dynamic> json) =>
      _$LoginDtoFromJson(json);

  Map<String, dynamic> toJson() => _$LoginDtoToJson(this);
}

/// DTO для обновления профиля
@JsonSerializable()
class UpdateUserDto {
  final String? name;
  final String? phone;

  const UpdateUserDto({
    this.name,
    this.phone,
  });

  factory UpdateUserDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserDtoToJson(this);
}
