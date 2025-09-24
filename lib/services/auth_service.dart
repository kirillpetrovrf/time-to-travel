import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../models/user.dart' as app_user;
import 'user_service.dart';

class AuthService {
  static const String _lastScreenKey = 'last_screen';
  static const String _formDataPrefix = 'form_data_';
  static const String _userTypeKey = 'user_type';

  static AuthService? _instance;

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Проверка авторизации
  Future<bool> isLoggedIn() async {
    final user = _firebaseAuth.currentUser;
    return user != null;
  }

  // Текущий пользователь Firebase
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // Получение текущего пользователя приложения
  Future<app_user.User?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      return await _userService.getUserById(firebaseUser.uid);
    }
    return null;
  }

  // Отправка SMS кода для авторизации
  Future<void> sendVerificationCode({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Автоматическая верификация (Android)
          await _firebaseAuth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Ошибка отправки SMS');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Тайм-аут автоматического получения
        },
      );
    } catch (e) {
      onError('Ошибка: $e');
    }
  }

  // Подтверждение SMS кода и авторизация
  Future<bool> verifyCode({
    required String verificationId,
    required String smsCode,
    required String name,
    required app_user.UserType userType,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final authResult = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = authResult.user;

      if (firebaseUser != null) {
        // Проверяем, существует ли пользователь в Firestore
        app_user.User? existingUser = await _userService.getUserById(
          firebaseUser.uid,
        );

        if (existingUser == null) {
          // Создаём нового пользователя
          final newUser = app_user.User(
            id: firebaseUser.uid,
            phone: firebaseUser.phoneNumber ?? '',
            name: name,
            userType: userType,
            createdAt: DateTime.now(),
          );
          await _userService.createUser(newUser);
        }

        // Сохраняем тип пользователя локально
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userTypeKey, userType.toString());

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Выход из системы
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Очищаем все локальные данные
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

    // Если нет в локальном хранилище, получаем из Firestore
    final user = await getCurrentUser();
    return user?.userType ?? app_user.UserType.client;
  }

  // Установка типа пользователя (для тестирования)
  Future<void> setUserType(app_user.UserType userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTypeKey, userType.toString());
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

  // Сохранение данных формы (для восстановления незавершенных действий)
  Future<void> saveFormData(String key, Map<String, dynamic> formData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(formData);
    await prefs.setString('$_formDataPrefix$key', jsonString);
  }

  // Получение данных формы
  Future<Map<String, dynamic>?> getFormData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_formDataPrefix$key');
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Очистка данных формы
  Future<void> clearFormData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_formDataPrefix$key');
  }
}
