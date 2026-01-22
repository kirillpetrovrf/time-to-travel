import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

/// Модель пользователя из API
class ApiUser {
  final String id;
  final String email;
  final String? name;
  final String? phone;
  final String role; // 'client', 'driver', 'admin'
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiUser({
    required this.id,
    required this.email,
    this.name,
    this.phone,
    required this.role,
    required this.isVerified,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      isVerified: json['isVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'role': role,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isDriver => role == 'driver';
  bool get isClient => role == 'client';
}

/// Ответ на регистрацию/авторизацию
class AuthResponse {
  final ApiUser user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: ApiUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}

/// Сервис аутентификации для работы с Time to Travel API
class AuthApiService {
  final ApiClient _apiClient;
  final FlutterSecureStorage _secureStorage;
  
  ApiUser? _currentUser;

  AuthApiService({
    ApiClient? apiClient,
    FlutterSecureStorage? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Инициализация - загрузка сохраненных данных
  Future<void> init() async {
    await _apiClient.init();
    
    // Попытка восстановить пользователя из сохраненных данных
    final userId = await _secureStorage.read(key: ApiConfig.userIdKey);
    final userEmail = await _secureStorage.read(key: ApiConfig.userEmailKey);
    final userRole = await _secureStorage.read(key: ApiConfig.userRoleKey);
    
    if (userId != null && userEmail != null && userRole != null) {
      // Создаем временного пользователя (полные данные получим через /auth/me)
      _currentUser = ApiUser(
        id: userId,
        email: userEmail,
        role: userRole,
        isVerified: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Регистрация нового пользователя
  /// POST /auth/register
  Future<AuthResponse> register({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/register',
        body: {
          'email': email,
          'password': password,
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      final authResponse = AuthResponse.fromJson(response);
      
      // Сохраняем токены и данные пользователя
      await _saveAuthData(authResponse);
      
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Вход пользователя
  /// POST /auth/login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/login',
        body: {
          'email': email,
          'password': password,
        },
      );

      final authResponse = AuthResponse.fromJson(response);
      
      // Сохраняем токены и данные пользователя
      await _saveAuthData(authResponse);
      
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  /// Обновление токена
  /// POST /auth/refresh
  Future<AuthResponse> refreshToken() async {
    final refreshToken = _apiClient.refreshToken;
    
    if (refreshToken == null) {
      throw UnauthorizedException('No refresh token available');
    }

    try {
      final response = await _apiClient.post(
        '${ApiConfig.authEndpoint}/refresh',
        body: {
          'refreshToken': refreshToken,
        },
      );

      final authResponse = AuthResponse.fromJson(response);
      
      // Сохраняем новые токены
      await _saveAuthData(authResponse);
      
      return authResponse;
    } catch (e) {
      // При ошибке обновления токена - выходим
      await logout();
      rethrow;
    }
  }

  /// Получение текущего пользователя
  /// GET /auth/me
  Future<ApiUser> getCurrentUser() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.authEndpoint}/me',
        requiresAuth: true,
      );

      final user = ApiUser.fromJson(response);
      _currentUser = user;
      
      // Обновляем сохраненные данные
      await _secureStorage.write(key: ApiConfig.userIdKey, value: user.id);
      await _secureStorage.write(key: ApiConfig.userEmailKey, value: user.email);
      await _secureStorage.write(key: ApiConfig.userRoleKey, value: user.role);
      
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Выход с текущего устройства
  /// POST /auth/logout
  Future<void> logout() async {
    try {
      await _apiClient.post(
        '${ApiConfig.authEndpoint}/logout',
        requiresAuth: true,
      );
    } catch (e) {
      // Игнорируем ошибки при выходе
    } finally {
      await _clearAuthData();
    }
  }

  /// Выход со всех устройств
  /// POST /auth/logout-all
  Future<void> logoutAll() async {
    try {
      await _apiClient.post(
        '${ApiConfig.authEndpoint}/logout-all',
        requiresAuth: true,
      );
    } catch (e) {
      // Игнорируем ошибки при выходе
    } finally {
      await _clearAuthData();
    }
  }

  /// Сохранение данных авторизации
  Future<void> _saveAuthData(AuthResponse authResponse) async {
    _currentUser = authResponse.user;
    
    await _apiClient.saveTokens(
      accessToken: authResponse.accessToken,
      refreshToken: authResponse.refreshToken,
    );
    
    await _secureStorage.write(
      key: ApiConfig.userIdKey,
      value: authResponse.user.id,
    );
    await _secureStorage.write(
      key: ApiConfig.userEmailKey,
      value: authResponse.user.email,
    );
    await _secureStorage.write(
      key: ApiConfig.userRoleKey,
      value: authResponse.user.role,
    );
  }

  /// Очистка данных авторизации
  Future<void> _clearAuthData() async {
    _currentUser = null;
    await _apiClient.clearTokens();
  }

  /// Проверка авторизации
  bool get isAuthenticated => _apiClient.isAuthenticated;

  /// Текущий пользователь (может быть null)
  ApiUser? get currentUser => _currentUser;

  /// Закрытие сервиса
  void dispose() {
    _apiClient.dispose();
  }
}
