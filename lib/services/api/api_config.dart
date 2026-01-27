/// Базовые константы для API
class ApiConfig {
  // Production URL (HTTPS настроен ✅)
  static const String baseUrl = 'https://titotr.ru/api';
  
  // Development URL (для локальной разработки)
  // static const String baseUrl = 'http://localhost:8080/api';
  
  // API версия
  static const String apiVersion = 'v1';
  
  // Endpoints (без /api - уже в baseUrl)
  static const String authEndpoint = '/auth';
  static const String ordersEndpoint = '/orders';
  static const String routesEndpoint = '/search';
  static const String adminEndpoint = '/admin';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  
  // Ключи для хранения токенов
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userRoleKey = 'user_role';
}
