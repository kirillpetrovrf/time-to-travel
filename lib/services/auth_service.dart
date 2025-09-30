import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/user.dart' as app_user;
import 'user_service.dart';

class AuthService {
  static const String _lastScreenKey = 'last_screen';
  static const String _formDataPrefix = 'form_data_';
  static const String _userTypeKey = 'user_type';

  // НОВОЕ: Ключи для оффлайн авторизации
  static const String _offlineUserKey = 'offline_user';
  static const String _isOfflineModeKey = 'is_offline_mode';

  static AuthService? _instance;

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // НОВОЕ: Проверка, работаем ли мы в оффлайн режиме
  Future<bool> _isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isOfflineModeKey) ??
        true; // По умолчанию - оффлайн режим
  }

  // НОВОЕ: Создание демо-пользователя для оффлайн режима
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
    await prefs.setBool(_isOfflineModeKey, true);
  }

  // Проверка авторизации
  Future<bool> isLoggedIn() async {
    if (await _isOfflineMode()) {
      final prefs = await SharedPreferences.getInstance();
      // В оффлайн режиме всегда считаем пользователя авторизованным
      // Создаем демо-пользователя если его нет
      if (!prefs.containsKey(_offlineUserKey)) {
        await _createOfflineUser();
      }
      return true;
    } else {
      final user = _firebaseAuth.currentUser;
      return user != null;
    }
  }

  // Текущий пользователь Firebase
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // ОБНОВЛЕННОЕ: Получение текущего пользователя приложения (поддерживает оффлайн режим)
  Future<app_user.User?> getCurrentUser() async {
    if (await _isOfflineMode()) {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_offlineUserKey);

      if (userJson != null) {
        try {
          final userMap = jsonDecode(userJson) as Map<String, dynamic>;
          return app_user.User.fromJson(userMap);
        } catch (e) {
          print('Ошибка парсинга оффлайн пользователя: $e');
          // Создаем нового демо-пользователя если произошла ошибка
          await _createOfflineUser();
          return getCurrentUser();
        }
      } else {
        // Создаем демо-пользователя если его нет
        await _createOfflineUser();
        return getCurrentUser();
      }
    } else {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        return await _userService.getUserById(firebaseUser.uid);
      }
      return null;
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

  /// НОВОЕ (ТЗ v3.0): Повышение до диспетчера через секретный вход
  Future<void> upgradeToDispatcher() async {
    try {
      // Устанавливаем тип диспетчера локально
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _userTypeKey,
        app_user.UserType.dispatcher.toString(),
      );

      if (await _isOfflineMode()) {
        // В оффлайн режиме обновляем локального пользователя
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
      }

      print('🎯 Пользователь повышен до диспетчера');
    } catch (e) {
      print('❌ Ошибка повышения до диспетчера: $e');
    }
  }

  // Выход из системы
  Future<void> logout() async {
    if (await _isOfflineMode()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineUserKey);
      await prefs.remove(_userTypeKey);
      return;
    }

    await _firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Очищаем все локальные данные
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
