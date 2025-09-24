enum UserType {
  client, // Клиент
  dispatcher, // Диспетчер
}

class User {
  final String id;
  final String phone;
  final String? email;
  final String name;
  final UserType userType;
  final DateTime createdAt;
  final String? fcmToken; // Для push-уведомлений

  const User({
    required this.id,
    required this.phone,
    this.email,
    required this.name,
    required this.userType,
    required this.createdAt,
    this.fcmToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'email': email,
      'name': name,
      'userType': userType.toString(),
      'createdAt': createdAt.toIso8601String(),
      'fcmToken': fcmToken,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      name: json['name'] as String,
      userType: UserType.values.firstWhere(
        (e) => e.toString() == json['userType'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      fcmToken: json['fcmToken'] as String?,
    );
  }

  User copyWith({
    String? phone,
    String? email,
    String? name,
    UserType? userType,
    String? fcmToken,
  }) {
    return User(
      id: id,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
