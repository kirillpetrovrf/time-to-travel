// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String?,
  role: json['role'] as String? ?? 'client',
  isVerified: json['isVerified'] as bool? ?? false,
  isActive: json['isActive'] as bool? ?? true,
  isDispatcher: json['isDispatcher'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  telegramId: (json['telegramId'] as num?)?.toInt(),
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  username: json['username'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'phone': instance.phone,
  'role': instance.role,
  'isVerified': instance.isVerified,
  'isActive': instance.isActive,
  'isDispatcher': instance.isDispatcher,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'telegramId': instance.telegramId,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'username': instance.username,
};

RegisterUserDto _$RegisterUserDtoFromJson(Map<String, dynamic> json) =>
    RegisterUserDto(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$RegisterUserDtoToJson(RegisterUserDto instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'name': instance.name,
      'phone': instance.phone,
    };

LoginDto _$LoginDtoFromJson(Map<String, dynamic> json) => LoginDto(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$LoginDtoToJson(LoginDto instance) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
};

UpdateUserDto _$UpdateUserDtoFromJson(Map<String, dynamic> json) =>
    UpdateUserDto(
      name: json['name'] as String?,
      phone: json['phone'] as String?,
    );

Map<String, dynamic> _$UpdateUserDtoToJson(UpdateUserDto instance) =>
    <String, dynamic>{'name': instance.name, 'phone': instance.phone};
