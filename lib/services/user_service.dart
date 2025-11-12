import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

/// ⚠️ ВАЖНО: Сейчас используется только SQLite/SharedPreferences
/// TODO: Интеграция с Firebase - реализуется позже
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // TODO: Интеграция с Firebase - реализуется позже
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final String _collection = 'users';

  static const String _usersKey = 'local_users';

  /// Создание нового пользователя
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> createUser(User user) async {
    debugPrint('ℹ️ Создание пользователя локально (Firebase не подключен)');
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);
    List<Map<String, dynamic>> usersList = [];

    if (usersJson != null) {
      final decoded = jsonDecode(usersJson) as List<dynamic>;
      usersList = decoded.cast<Map<String, dynamic>>();
    }

    usersList.add(user.toJson());
    await prefs.setString(_usersKey, jsonEncode(usersList));
  }

  /// Получение пользователя по ID
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<User?> getUserById(String userId) async {
    debugPrint('ℹ️ Поиск пользователя локально (Firebase не подключен)');
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) return null;

    final usersList = jsonDecode(usersJson) as List<dynamic>;
    for (final userData in usersList) {
      final user = User.fromJson(userData as Map<String, dynamic>);
      if (user.id == userId) return user;
    }
    return null;
  }

  /// Получение пользователя по номеру телефона
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<User?> getUserByPhone(String phone) async {
    debugPrint(
      'ℹ️ Поиск пользователя по телефону локально (Firebase не подключен)',
    );
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey);

    if (usersJson == null) return null;

    final usersList = jsonDecode(usersJson) as List<dynamic>;
    for (final userData in usersList) {
      final user = User.fromJson(userData as Map<String, dynamic>);
      if (user.phone == phone) return user;
    }
    return null;
  }

  /// Обновление данных пользователя
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> updateUser(User user) async {
    debugPrint('ℹ️ Обновление пользователя локально (Firebase не подключен)');
    // В будущем здесь будет обновление в Firebase
  }

  /// Обновление FCM токена для push-уведомлений
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> updateFCMToken(String userId, String fcmToken) async {
    debugPrint('ℹ️ Обновление FCM токена локально (Firebase не подключен)');
    // В будущем здесь будет обновление в Firebase
  }

  /// Получение всех диспетчеров
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<List<User>> getDispatchers() async {
    debugPrint('ℹ️ Получение диспетчеров локально (Firebase не подключен)');
    return [];
  }

  /// Удаление пользователя
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> deleteUser(String userId) async {
    debugPrint('ℹ️ Удаление пользователя локально (Firebase не подключен)');
    // В будущем здесь будет удаление из Firebase
  }
}
