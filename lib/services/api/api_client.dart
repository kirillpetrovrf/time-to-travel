import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';
import 'api_exceptions.dart';

/// Базовый HTTP клиент для работы с Time to Travel API
class ApiClient {
  final http.Client _httpClient;
  final FlutterSecureStorage _secureStorage;
  
  String? _accessToken;
  String? _refreshToken;
  
  ApiClient({
    http.Client? httpClient,
    FlutterSecureStorage? secureStorage,
  })  : _httpClient = httpClient ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Инициализация - загрузка сохраненных токенов
  Future<void> init() async {
    _accessToken = await _secureStorage.read(key: ApiConfig.accessTokenKey);
    _refreshToken = await _secureStorage.read(key: ApiConfig.refreshTokenKey);
  }

  /// Сохранение токенов
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    
    await _secureStorage.write(
      key: ApiConfig.accessTokenKey,
      value: accessToken,
    );
    await _secureStorage.write(
      key: ApiConfig.refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Очистка токенов (при выходе)
  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    
    await _secureStorage.delete(key: ApiConfig.accessTokenKey);
    await _secureStorage.delete(key: ApiConfig.refreshTokenKey);
    await _secureStorage.delete(key: ApiConfig.userIdKey);
    await _secureStorage.delete(key: ApiConfig.userEmailKey);
    await _secureStorage.delete(key: ApiConfig.userRoleKey);
  }

  /// GET запрос
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await _httpClient
          .get(uri, headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// POST запрос
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      debugPrint('🌐 [API] POST $uri');
      debugPrint('🌐 [API] Headers: $headers');
      if (body != null) {
        debugPrint('🌐 [API] Body: ${jsonEncode(body)}');
      }
      
      final response = await _httpClient
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);
      
      debugPrint('🌐 [API] Response status: ${response.statusCode}');
      debugPrint('🌐 [API] Response body: ${response.body}');
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('❌ [API] POST ошибка: $e');
      throw _handleError(e);
    }
  }

  /// PUT запрос
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await _httpClient
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH запрос
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await _httpClient
          .patch(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE запрос
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final uri = _buildUri(endpoint);
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await _httpClient
          .delete(uri, headers: headers)
          .timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Построение URI
  Uri _buildUri(String endpoint, [Map<String, String>? queryParameters]) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: queryParameters);
  }

  /// Построение заголовков
  Future<Map<String, String>> _buildHeaders({
    required bool requiresAuth,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  /// Обработка ответа
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    // Попытка распарсить тело ошибки
    Map<String, dynamic>? errorBody;
    try {
      errorBody = jsonDecode(response.body) as Map<String, dynamic>?;
    } catch (_) {
      // Игнорируем ошибки парсинга
    }

    final errorMessage = errorBody?['error'] as String? ??
        errorBody?['message'] as String? ??
        'Unknown error';

    switch (response.statusCode) {
      case 400:
        throw BadRequestException(errorMessage);
      case 401:
        throw UnauthorizedException(errorMessage);
      case 403:
        throw ForbiddenException(errorMessage);
      case 404:
        throw NotFoundException(errorMessage);
      case 409:
        throw ConflictException(errorMessage);
      case 500:
        throw ServerException(errorMessage);
      default:
        throw ApiException(
          'HTTP ${response.statusCode}: $errorMessage',
          statusCode: response.statusCode,
        );
    }
  }

  /// Обработка ошибок
  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    
    if (error is http.ClientException) {
      return NetworkException('Network error: ${error.message}');
    }

    return ApiException('Unexpected error: $error');
  }

  /// Получить текущий access token
  String? get accessToken => _accessToken;

  /// Получить текущий refresh token
  String? get refreshToken => _refreshToken;

  /// Проверка авторизации
  bool get isAuthenticated => _accessToken != null;

  /// Закрытие клиента
  void dispose() {
    _httpClient.close();
  }
}
