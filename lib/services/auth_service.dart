import 'package:shared_preferences/shared_preferences.dart';
// TODO: Интеграция с Firebase - реализуется позже
// import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as app_user;
import 'user_service.dart';

/// ⚠️ ВАЖНО: Сейчас используются только локальные данные
/// TODO: Интеграция с Firebase - реализуется позже
class AuthService {
  static const String _lastScreenKey = 'last_screen';
  static const String _formDataPrefix = 'form_data_';
  static const String _userTypeKey = 'user_type';

  // Ключи для локальной авторизации
  static const String _offlineUserKey = 'offline_user';
  static const String _isOfflineModeKey = 'is_offline_mode';
  static const String _currentUserIdKey = 'current_user_id';

  static AuthService? _instance;

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  // TODO: Интеграция с Firebase - реализуется позже
  // final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Создание демо-пользователя для локального режима
  Future<void> _createOfflineUser() async {
    final prefs = await SharedPreferences.getInstance();

    final demoUser = app_user.User(
      id: 'offline_user_demo',
      phone: '+7900000000',
      name: 'Демо Пользователь',
      userType: app_user.UserType.client,
      createdAt: DateTime.now(),
    );

    await prefs.setString(_offlineUserKey, jsonEncode(demoUser.toJson()));
    await prefs.setString(_currentUserIdKey, demoUser.id);
    await prefs.setBool(_isOfflineModeKey, true);
    debugPrint('ℹ️ Создан локальный демо-пользователь (Firebase не подключен)');
  }

  // Проверка авторизации
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    // Всегда работаем в локальном режиме
    // Создаем демо-пользователя если его нет
    if (!prefs.containsKey(_offlineUserKey)) {
      await _createOfflineUser();
    }
    debugPrint('ℹ️ Пользователь авторизован локально (Firebase не подключен)');
    return true;
  }

  // TODO: Интеграция с Firebase - реализуется позже
  // Текущий пользователь Firebase
  // User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // Получение текущего пользователя приложения (работает локально)
  Future<app_user.User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_offlineUserKey);

    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return app_user.User.fromJson(userMap);
      } catch (e) {
        debugPrint('⚠️ Ошибка парсинга локального пользователя: $e');
        // Создаем нового демо-пользователя если произошла ошибка
        await _createOfflineUser();
        return getCurrentUser();
      }
    } else {
      // Создаем демо-пользователя если его нет
      await _createOfflineUser();
      return getCurrentUser();
    }
  }

  // Получение типа пользователя
  Future<app_user.UserType?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    final userTypeString = prefs.getString(_userTypeKey);
    if (userTypeString != null) {
      return app_user.UserType.values.firstWhere(
        (e) => e.toString() == userTypeString,
        orElse: () => app_user.UserType.client,
      );
    }

    // Если нет в локальном хранилище, получаем из пользователя
    final user = await getCurrentUser();
    return user?.userType ?? app_user.UserType.client;
  }

  // Установка типа пользователя (для тестирования)
  Future<void> setUserType(app_user.UserType userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userType.toString());
    print('🔧 Сохранен тип пользователя: $userType');
  }

  // Переключение типа пользователя (для тестирования)
  Future<void> toggleUserType() async {
    final currentType = await getUserType() ?? app_user.UserType.client;
    final newType = currentType == app_user.UserType.client
        ? app_user.UserType.dispatcher
        : app_user.UserType.client;
    print('🔄 AuthService: Переключение с $currentType на $newType');
    await setUserType(newType);
    print('✅ AuthService: Переключение завершено');
  }

  /// Повышение до диспетчера через секретный вход (работает локально)
  Future<void> upgradeToDispatcher() async {
    try {
      // Устанавливаем тип диспетчера локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _userTypeKey,
        app_user.UserType.dispatcher.toString(),
      );

      // Обновляем локального пользователя
      final currentUser = await getCurrentUser();
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          userType: app_user.UserType.dispatcher,
        );
        await prefs.setString(
          _offlineUserKey,
          jsonEncode(updatedUser.toJson()),
        );
      }

      debugPrint('🎯 Пользователь повышен до диспетчера (локально)');
    } catch (e) {
      debugPrint('❌ Ошибка повышения до диспетчера: $e');
    }
  }

  // Получение ID текущего пользователя
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserIdKey);
    
    if (userId == null) {
      debugPrint('⚠️ ID текущего пользователя не найден, создаем нового...');
      await _createOfflineUser();
      return prefs.getString(_currentUserIdKey);
    }
    
    return userId;
  }

  // Выход из системы (работает локально)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_offlineUserKey);
    await prefs.remove(_userTypeKey);
    debugPrint('ℹ️ Выход из системы (локальные данные очищены)');
  }

  // Сохранение последнего экрана
  Future<void> saveLastScreen(String screenRoute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastScreenKey, screenRoute);
  }

  // Получение последнего экрана
  Future<String?> getLastScreen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastScreenKey);
  }
}
