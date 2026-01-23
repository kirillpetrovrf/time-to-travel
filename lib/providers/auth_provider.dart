import 'package:flutter/foundation.dart';
import '../services/auth_storage_service.dart';
import '../services/telegram_auth_api_service.dart';
import '../models/user.dart' as app_user;

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Provider для управления состоянием аутентификации
class AuthProvider extends ChangeNotifier {
  final AuthStorageService _storage;
  final TelegramAuthApiService _api;

  AuthStatus _status = AuthStatus.initial;
  Map<String, dynamic>? _user;
  String? _errorMessage;

  AuthProvider({
    required AuthStorageService storage,
    required TelegramAuthApiService api,
  })  : _storage = storage,
        _api = api;

  AuthStatus get status => _status;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Получение текущего пользователя как объект User
  app_user.User? get currentUser {
    if (_user == null) return null;
    
    try {
      return app_user.User(
        id: _user!['id']?.toString() ?? '',
        phone: _user!['phone']?.toString() ?? '',
        name: _user!['fullName']?.toString() ?? 'Пользователь',
        email: _user!['email']?.toString(),
        userType: _parseUserType(_user!['role']?.toString()),
        createdAt: DateTime.now(), // TODO: parse from backend if available
      );
    } catch (e) {
      print('❌ [AUTH_PROVIDER] Ошибка конвертации user: $e');
      return null;
    }
  }

  /// Парсинг типа пользователя из строки
  app_user.UserType _parseUserType(String? role) {
    switch (role?.toLowerCase()) {
      case 'dispatcher':
        return app_user.UserType.dispatcher;
      case 'passenger':
      case 'client':
      case 'driver': // На случай если в будущем добавится
      default:
        return app_user.UserType.client;
    }
  }

  /// Проверка текущей сессии при запуске приложения
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final hasTokens = await _storage.hasTokens();
      
      if (!hasTokens) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Попытка обновить токен
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      try {
        final response = await _api.refresh(refreshToken);
        
        await _storage.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
          userId: response.user['id']?.toString(),
        );

        _user = response.user;
        _status = AuthStatus.authenticated;
      } catch (e) {
        // Refresh token invalid - need to re-login
        await _storage.clearTokens();
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _errorMessage = 'Ошибка проверки сессии: $e';
      _status = AuthStatus.error;
    }

    notifyListeners();
  }

  /// Инициализация Telegram авторизации
  Future<TelegramInitResponse> initTelegramAuth(String phone) async {
    try {
      _errorMessage = null;
      final response = await _api.init(phone);
      return response; // Возвращаем полный ответ с authCode и deepLink
    } catch (e) {
      _errorMessage = 'Ошибка инициализации: $e';
      rethrow;
    }
  }

  /// Проверка статуса авторизации по authCode (polling)
  /// Возвращает true если пользователь успешно нажал START в боте
  Future<bool> checkTelegramAuthByCode(String authCode) async {
    try {
      print('🔄 [POLLING CLIENT] Проверяем статус авторизации: $authCode');
      
      // Пытаемся получить токены по authCode
      // Бэкенд вернёт данные если пользователь нажал START в боте
      // и webhook уже обработал команду /start с этим кодом
      final response = await _api.callbackByAuthCode(authCode);
      
      print('✅ [POLLING CLIENT] Получен ответ от сервера!');
      print('   • accessToken: ${response.accessToken.substring(0, 20)}...');
      print('   • user: ${response.user}');
      
      await _storage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user['id']?.toString(),
      );

      print('💾 [POLLING CLIENT] Токены сохранены в storage');

      _user = response.user;
      _status = AuthStatus.authenticated;
      
      print('🎉 [POLLING CLIENT] Статус изменён на authenticated');
      notifyListeners();
      
      print('📣 [POLLING CLIENT] Listeners уведомлены');
      
      return true;
    } catch (e, stackTrace) {
      // Пользователь ещё не нажал START или произошла ошибка
      print('❌ [POLLING CLIENT] Ошибка: $e');
      print('📍 [POLLING CLIENT] StackTrace: $stackTrace');
      return false;
    }
  }

  /// Завершение авторизации через Telegram (вызывается после возврата из Telegram)
  /// В реальном приложении telegramId можно получить через deep linking
  /// Пока оставим как параметр для тестирования
  Future<void> completeTelegramAuth(int telegramId) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _api.callback(telegramId);
      
      await _storage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user['id']?.toString(),
      );

      _user = response.user;
      _status = AuthStatus.authenticated;
    } catch (e) {
      _errorMessage = 'Ошибка авторизации: $e';
      _status = AuthStatus.error;
    }

    notifyListeners();
  }

  /// Выход из аккаунта
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        try {
          await _api.logout(refreshToken);
        } catch (e) {
          // Игнорируем ошибки logout на сервере
          debugPrint('Logout error (ignored): $e');
        }
      }
    } finally {
      await _storage.clearTokens();
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  /// Получить текущий access token для API запросов
  Future<String?> getAccessToken() async {
    return await _storage.getAccessToken();
  }

  /// Обновить access token если истёк
  Future<String?> refreshAccessToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) {
      await logout();
      return null;
    }

    try {
      final response = await _api.refresh(refreshToken);
      
      await _storage.saveTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user['id']?.toString(),
      );

      _user = response.user;
      return response.accessToken;
    } catch (e) {
      await logout();
      return null;
    }
  }
}
