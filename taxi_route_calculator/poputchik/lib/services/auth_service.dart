import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_role.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _phoneNumberKey = 'phone_number';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';
  static const String _lastScreenKey = 'last_screen';
  static const String _formDataPrefix = 'form_data_';

  static AuthService? _instance;

  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  // Проверка авторизации
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Сохранение данных авторизации
  Future<void> login({required String phoneNumber, String? userName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_phoneNumberKey, phoneNumber);
    if (userName != null) {
      await prefs.setString(_userNameKey, userName);
    }
  }

  // Выход из системы
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Очищаем все данные
  }

  // Получение номера телефона
  Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneNumberKey);
  }

  // Получение имени пользователя
  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Сохранение роли пользователя
  Future<void> saveUserRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role.toStorageString());
  }

  // Получение роли пользователя
  Future<UserRole?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(_userRoleKey);
    return UserRoleExtension.fromStorageString(roleString);
  }

  // Проверка, выбрана ли роль
  Future<bool> hasSelectedRole() async {
    final role = await getUserRole();
    return role != null;
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
