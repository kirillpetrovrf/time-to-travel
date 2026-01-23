import 'dart:convert';
import 'package:http/http.dart' as http;

/// Модель ответа с токенами
class AuthTokensResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  AuthTokensResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthTokensResponse.fromJson(Map<String, dynamic> json) {
    return AuthTokensResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: json['user'] as Map<String, dynamic>,
    );
  }
}

/// Модель ответа от /auth/telegram/init
class TelegramInitResponse {
  final String deepLink;
  final String authCode;
  final String phone;

  TelegramInitResponse({
    required this.deepLink,
    required this.authCode,
    required this.phone,
  });

  factory TelegramInitResponse.fromJson(Map<String, dynamic> json) {
    return TelegramInitResponse(
      deepLink: json['deepLink'] as String,
      authCode: json['authCode'] as String,
      phone: json['phone'] as String,
    );
  }
}

/// Сервис для работы с Telegram аутентификацией
class TelegramAuthApiService {
  final String baseUrl;
  final http.Client _client;

  TelegramAuthApiService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Инициализация Telegram авторизации - получение deep link
  Future<TelegramInitResponse> init(String phone) async {
    print('📡 [API_SERVICE] Начинаем init для телефона: $phone');
    final url = Uri.parse('$baseUrl/auth/telegram/init');
    print('🌐 [API_SERVICE] URL: $url');
    
    try {
      print('⏳ [API_SERVICE] Отправляем POST запрос...');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏰ [API_SERVICE] TIMEOUT через 10 секунд!');
          throw Exception('Request timeout after 10 seconds');
        },
      );

      print('📥 [API_SERVICE] Получен ответ: ${response.statusCode}');
      print('📄 [API_SERVICE] Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ [API_SERVICE] JSON распарсен успешно');
        final result = TelegramInitResponse.fromJson(json);
        print('✅ [API_SERVICE] Возвращаем TelegramInitResponse');
        return result;
      } else {
        print('❌ [API_SERVICE] Ошибка статус код: ${response.statusCode}');
        throw Exception('Failed to init Telegram auth: ${response.statusCode} ${response.body}');
      }
    } catch (e, stackTrace) {
      print('❌ [API_SERVICE] EXCEPTION в init: $e');
      print('📍 [API_SERVICE] StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Получение токенов по Telegram ID
  Future<AuthTokensResponse> callback(int telegramId) async {
    final url = Uri.parse('$baseUrl/auth/telegram/callback');
    
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'telegramId': telegramId}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthTokensResponse.fromJson(json);
    } else {
      throw Exception('Failed to get tokens: ${response.statusCode} ${response.body}');
    }
  }

  /// Получение токенов по номеру телефона (polling после нажатия START)
  Future<AuthTokensResponse> callbackByPhone(String phone) async {
    final url = Uri.parse('$baseUrl/auth/telegram/callback-phone');
    
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthTokensResponse.fromJson(json);
    } else {
      throw Exception('Failed to get tokens by phone: ${response.statusCode} ${response.body}');
    }
  }

  /// Получение токенов по authCode (polling после нажатия START)
  /// Это основной метод для polling - проверяем, нажал ли пользователь START
  Future<AuthTokensResponse> callbackByAuthCode(String authCode) async {
    final url = Uri.parse('$baseUrl/auth/telegram/callback-code');
    
    print('📡 [API] POST $url');
    print('📦 [API] Request: {"authCode": "$authCode"}');
    
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'authCode': authCode}),
    );

    print('📥 [API] Response status: ${response.statusCode}');
    print('📥 [API] Response body: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      print('✅ [API] Успешный ответ, парсим JSON...');
      return AuthTokensResponse.fromJson(json);
    } else {
      print('❌ [API] Ошибка: ${response.statusCode} ${response.body}');
      throw Exception('Failed to get tokens by authCode: ${response.statusCode} ${response.body}');
    }
  }

  /// Обновление access token через refresh token
  Future<AuthTokensResponse> refresh(String refreshToken) async {
    final url = Uri.parse('$baseUrl/auth/refresh');
    
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthTokensResponse.fromJson(json);
    } else {
      throw Exception('Failed to refresh token: ${response.statusCode} ${response.body}');
    }
  }

  /// Получение информации о текущем пользователе
  Future<Map<String, dynamic>> me(String accessToken) async {
    final url = Uri.parse('$baseUrl/auth/me');
    
    final response = await _client.get(
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get user info: ${response.statusCode} ${response.body}');
    }
  }

  /// Logout - удаление сессии на сервере
  Future<void> logout(String refreshToken) async {
    final url = Uri.parse('$baseUrl/auth/logout');
    
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to logout: ${response.statusCode} ${response.body}');
    }
  }
}
