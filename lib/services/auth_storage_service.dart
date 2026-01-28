import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис для безопасного хранения токенов аутентификации
/// Использует FlutterSecureStorage на реальных устройствах
/// и SharedPreferences как fallback для эмуляторов
class AuthStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  
  // Fallback ключи для SharedPreferences
  static const _accessTokenKeyFallback = 'auth_access_token_fallback';
  static const _refreshTokenKeyFallback = 'auth_refresh_token_fallback';
  static const _userIdKeyFallback = 'auth_user_id_fallback';

  final FlutterSecureStorage _secureStorage;
  bool _useSharedPreferences = false;
  bool _initialized = false;

  AuthStorageService({FlutterSecureStorage? storage})
      : _secureStorage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );
  
  /// Инициализация storage - ОБЯЗАТЕЛЬНО вызвать перед первым использованием!
  Future<void> initialize() async {
    print('🔧 [STORAGE] ========== ИНИЦИАЛИЗАЦИЯ STORAGE ==========');
    print('🔧 [STORAGE] _initialized: $_initialized');
    
    if (_initialized) {
      print('⏭️ [STORAGE] Уже инициализирован, пропускаем');
      return;
    }
    
    print('🔧 [STORAGE] Проверяем работоспособность FlutterSecureStorage...');
    
    try {
      // Пытаемся записать и прочитать тестовое значение
      await _secureStorage.write(key: 'test_key', value: 'test_value');
      final testValue = await _secureStorage.read(key: 'test_key');
      
      if (testValue != 'test_value') {
        print('⚠️ [STORAGE] FlutterSecureStorage не работает → используем SharedPreferences');
        _useSharedPreferences = true;
      } else {
        await _secureStorage.delete(key: 'test_key');
        print('✅ [STORAGE] FlutterSecureStorage работает корректно');
      }
    } catch (e) {
      print('⚠️ [STORAGE] Ошибка FlutterSecureStorage: $e → используем SharedPreferences');
      _useSharedPreferences = true;
    }
    
    _initialized = true;
    print('🔧 [STORAGE] Инициализация завершена. Метод: ${_useSharedPreferences ? "SharedPreferences" : "FlutterSecureStorage"}');
    print('🔧 [STORAGE] ==========================================');
  }
  
  /// Гарантировать что storage инициализирован
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Сохранить токены после успешной авторизации
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
  }) async {
    await _ensureInitialized();
    
    print('💾 [STORAGE] Сохраняем токены:');
    print('   • accessToken: ${accessToken.substring(0, 20)}...');
    print('   • refreshToken: ${refreshToken.substring(0, 20)}...');
    print('   • userId: $userId');
    print('   • Метод: ${_useSharedPreferences ? "SharedPreferences" : "FlutterSecureStorage"}');
    
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        // ✅ Сохраняем в оба ключа для совместимости
        prefs.setString(_accessTokenKeyFallback, accessToken),
        prefs.setString('access_token', accessToken), // Для Dio interceptor
        prefs.setString(_refreshTokenKeyFallback, refreshToken),
        if (userId != null) prefs.setString(_userIdKeyFallback, userId),
      ]);
    } else {
      await Future.wait([
        _secureStorage.write(key: _accessTokenKey, value: accessToken),
        _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
        if (userId != null) _secureStorage.write(key: _userIdKey, value: userId),
      ]);
    }
    
    print('✅ [STORAGE] Токены успешно сохранены');
  }

  /// Получить access token
  Future<String?> getAccessToken() async {
    await _ensureInitialized();
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKeyFallback);
    }
    return await _secureStorage.read(key: _accessTokenKey);
  }

  /// Получить refresh token
  Future<String?> getRefreshToken() async {
    await _ensureInitialized();
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKeyFallback);
    }
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  /// Получить user ID
  Future<String?> getUserId() async {
    await _ensureInitialized();
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKeyFallback);
    }
    return await _secureStorage.read(key: _userIdKey);
  }

  /// Обновить access token
  Future<void> updateAccessToken(String accessToken) async {
    await _ensureInitialized();
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKeyFallback, accessToken);
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    }
  }

  /// Очистить все токены (logout)
  Future<void> clearTokens() async {
    await _ensureInitialized();
    print('🗑️ [STORAGE] Очищаем токены');
    if (_useSharedPreferences) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_accessTokenKeyFallback),
        prefs.remove(_refreshTokenKeyFallback),
        prefs.remove(_userIdKeyFallback),
      ]);
    } else {
      await Future.wait([
        _secureStorage.delete(key: _accessTokenKey),
        _secureStorage.delete(key: _refreshTokenKey),
        _secureStorage.delete(key: _userIdKey),
      ]);
    }
    print('✅ [STORAGE] Токены очищены');
  }

  /// Проверить, есть ли сохранённые токены
  Future<bool> hasTokens() async {
    final refreshToken = await getRefreshToken();
    final accessToken = await getAccessToken();
    final result = refreshToken != null && refreshToken.isNotEmpty;
    
    print('🔍 [STORAGE] hasTokens():');
    print('   • accessToken: ${accessToken != null ? "${accessToken.substring(0, 20)}..." : "null"}');
    print('   • refreshToken: ${refreshToken != null ? "${refreshToken.substring(0, 20)}..." : "null"}');
    print('   • result: $result');
    
    return result;
  }
}
