# 📱 Flutter Integration Guide
# Интеграция Flutter приложения Time to Travel с REST API

## 🎯 Обзор

После успешного деплоя backend на https://titotr.ru, необходимо обновить Flutter приложение для работы с REST API вместо локальной SQLite базы данных.

---

## 📦 Необходимые пакеты

### Добавить в `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP клиент
  http: ^1.1.2
  dio: ^5.4.0  # Альтернатива http с interceptors
  
  # State Management
  provider: ^6.1.1
  
  # Безопасное хранение токенов
  flutter_secure_storage: ^9.0.0
  
  # JSON сериализация
  json_annotation: ^4.8.1
  
  # Логирование
  logger: ^2.0.2

dev_dependencies:
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

Установить:
```bash
cd /Users/kirillpetrov/Projects/time-to-travel
flutter pub get
```

---

## 🏗️ Архитектура

```
lib/
├── api/
│   ├── api_client.dart           # HTTP клиент с interceptors
│   ├── api_constants.dart        # URLs, endpoints
│   ├── auth_service.dart         # Авторизация
│   ├── route_service.dart        # Маршруты
│   └── order_service.dart        # Заказы
├── models/
│   ├── user.dart                 # User model + JSON
│   ├── route.dart                # Route model + JSON
│   └── order.dart                # Order model + JSON
├── providers/
│   ├── auth_provider.dart        # State для авторизации
│   ├── route_provider.dart       # State для маршрутов
│   └── order_provider.dart       # State для заказов
├── utils/
│   └── token_storage.dart        # Хранение JWT токенов
└── screens/
    ├── auth/
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── routes/
    │   └── route_search_screen.dart
    └── orders/
        ├── order_create_screen.dart
        └── order_list_screen.dart
```

---

## 🔧 Реализация

### 1. API Constants (`lib/api/api_constants.dart`)
```dart
class ApiConstants {
  // Production URL
  static const String baseUrl = 'https://titotr.ru';
  
  // Development URL (для тестирования)
  // static const String baseUrl = 'http://localhost:8080';
  
  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  
  // Routes endpoints
  static const String routesSearch = '/routes/search';
  
  // Orders endpoints
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderStatus(String id) => '/orders/$id/status';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

### 2. Token Storage (`lib/utils/token_storage.dart`)
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  
  // Сохранить токены
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
  
  // Получить access token
  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }
  
  // Получить refresh token
  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }
  
  // Обновить access token
  static Future<void> updateAccessToken(String accessToken) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
  }
  
  // Удалить все токены (logout)
  static Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
  
  // Проверить наличие токенов
  static Future<bool> hasTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }
}
```

### 3. API Client (`lib/api/api_client.dart`)
```dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'api_constants.dart';
import '../utils/token_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  
  late final Dio _dio;
  final _logger = Logger();
  
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Interceptor для логирования
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => _logger.d(obj),
      ),
    );
    
    // Interceptor для автоматического добавления JWT токена
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Если 401 - токен истёк, пробуем обновить
          if (error.response?.statusCode == 401) {
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken != null) {
              try {
                // Обновляем токен
                final response = await _dio.post(
                  ApiConstants.refresh,
                  data: {'refreshToken': refreshToken},
                );
                
                final newAccessToken = response.data['accessToken'];
                await TokenStorage.updateAccessToken(newAccessToken);
                
                // Повторяем оригинальный запрос с новым токеном
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                final cloneReq = await _dio.fetch(opts);
                return handler.resolve(cloneReq);
              } catch (e) {
                // Если refresh не удался - выходим
                await TokenStorage.clearTokens();
                _logger.e('Token refresh failed: $e');
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }
  
  Dio get dio => _dio;
  
  // GET запрос
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }
  
  // POST запрос
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }
  
  // PUT запрос
  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }
  
  // DELETE запрос
  Future<Response> delete(String path) {
    return _dio.delete(path);
  }
  
  // PATCH запрос
  Future<Response> patch(String path, {dynamic data}) {
    return _dio.patch(path, data: data);
  }
}
```

### 4. Auth Service (`lib/api/auth_service.dart`)
```dart
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_constants.dart';
import '../models/user.dart';
import '../utils/token_storage.dart';

class AuthService {
  final _client = ApiClient();
  
  // Регистрация
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.register,
        data: {
          'email': email,
          'password': password,
          'name': name,
          if (phone != null) 'phone': phone,
        },
      );
      
      final data = response.data;
      
      // Сохраняем токены
      await TokenStorage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      
      return {
        'user': User.fromJson(data['user']),
        'accessToken': data['accessToken'],
        'refreshToken': data['refreshToken'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Авторизация
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );
      
      final data = response.data;
      
      // Сохраняем токены
      await TokenStorage.saveTokens(
        accessToken: data['accessToken'],
        refreshToken: data['refreshToken'],
      );
      
      return {
        'user': User.fromJson(data['user']),
        'accessToken': data['accessToken'],
        'refreshToken': data['refreshToken'],
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Выход
  Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      
      await _client.post(
        ApiConstants.logout,
        data: {'refreshToken': refreshToken},
      );
      
      await TokenStorage.clearTokens();
    } on DioException catch (e) {
      // Даже при ошибке удаляем локальные токены
      await TokenStorage.clearTokens();
      throw _handleError(e);
    }
  }
  
  // Выход со всех устройств
  Future<void> logoutAll() async {
    try {
      await _client.post(ApiConstants.logoutAll);
      await TokenStorage.clearTokens();
    } on DioException catch (e) {
      await TokenStorage.clearTokens();
      throw _handleError(e);
    }
  }
  
  // Проверка авторизации
  Future<bool> isAuthenticated() async {
    return await TokenStorage.hasTokens();
  }
  
  // Обработка ошибок
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      return data['error'] ?? 'Неизвестная ошибка';
    } else {
      return 'Ошибка подключения к серверу';
    }
  }
}
```

### 5. Route Service (`lib/api/route_service.dart`)
```dart
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_constants.dart';
import '../models/route.dart' as app_route;

class RouteService {
  final _client = ApiClient();
  
  // Поиск маршрутов
  Future<List<app_route.Route>> searchRoutes({
    required double fromLatitude,
    required double fromLongitude,
    required double toLatitude,
    required double toLongitude,
    int? passengers,
  }) async {
    try {
      final queryParams = {
        'from_latitude': fromLatitude,
        'from_longitude': fromLongitude,
        'to_latitude': toLatitude,
        'to_longitude': toLongitude,
        if (passengers != null) 'passengers': passengers,
      };
      
      final response = await _client.get(
        ApiConstants.routesSearch,
        queryParameters: queryParams,
      );
      
      final List<dynamic> data = response.data['routes'];
      return data.map((json) => app_route.Route.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      return data['error'] ?? 'Ошибка поиска маршрутов';
    } else {
      return 'Ошибка подключения к серверу';
    }
  }
}
```

### 6. Order Service (`lib/api/order_service.dart`)
```dart
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_constants.dart';
import '../models/order.dart';

class OrderService {
  final _client = ApiClient();
  
  // Создать заказ
  Future<Order> createOrder({
    required String routeId,
    required int passengers,
    required int baggageS,
    required int baggageM,
    required int baggageL,
    required DateTime pickupTime,
    String? notes,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.orders,
        data: {
          'route_id': routeId,
          'passengers': passengers,
          'baggage_s': baggageS,
          'baggage_m': baggageM,
          'baggage_l': baggageL,
          'pickup_time': pickupTime.toIso8601String(),
          if (notes != null) 'notes': notes,
        },
      );
      
      return Order.fromJson(response.data['order']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Получить список заказов пользователя
  Future<List<Order>> getMyOrders({String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : null;
      
      final response = await _client.get(
        ApiConstants.orders,
        queryParameters: queryParams,
      );
      
      final List<dynamic> data = response.data['orders'];
      return data.map((json) => Order.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Получить заказ по ID
  Future<Order> getOrderById(String orderId) async {
    try {
      final response = await _client.get(
        ApiConstants.orderById(orderId),
      );
      
      return Order.fromJson(response.data['order']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Обновить заказ
  Future<Order> updateOrder({
    required String orderId,
    int? passengers,
    int? baggageS,
    int? baggageM,
    int? baggageL,
    DateTime? pickupTime,
    String? notes,
  }) async {
    try {
      final response = await _client.put(
        ApiConstants.orderById(orderId),
        data: {
          if (passengers != null) 'passengers': passengers,
          if (baggageS != null) 'baggage_s': baggageS,
          if (baggageM != null) 'baggage_m': baggageM,
          if (baggageL != null) 'baggage_l': baggageL,
          if (pickupTime != null) 'pickup_time': pickupTime.toIso8601String(),
          if (notes != null) 'notes': notes,
        },
      );
      
      return Order.fromJson(response.data['order']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Отменить заказ
  Future<void> cancelOrder(String orderId) async {
    try {
      await _client.delete(ApiConstants.orderById(orderId));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  String _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;
      return data['error'] ?? 'Ошибка работы с заказами';
    } else {
      return 'Ошибка подключения к серверу';
    }
  }
}
```

### 7. Auth Provider (`lib/providers/auth_provider.dart`)
```dart
import 'package:flutter/foundation.dart';
import '../api/auth_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final _authService = AuthService();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  
  // Регистрация
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      
      _currentUser = result['user'];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Авторизация
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );
      
      _currentUser = result['user'];
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Выход
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  // Проверка авторизации при запуске
  Future<void> checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    if (!isAuth) {
      _currentUser = null;
      notifyListeners();
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
```

---

## 🎨 Примеры использования в UI

### Login Screen
```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: Text('Вход')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Пароль'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            authProvider.isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      try {
                        await authProvider.login(
                          email: _emailController.text,
                          password: _passwordController.text,
                        );
                        Navigator.pushReplacementNamed(context, '/home');
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Ошибка входа: ${authProvider.error}')),
                        );
                      }
                    },
                    child: Text('Войти'),
                  ),
            if (authProvider.error != null)
              Text(
                authProvider.error!,
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
```

### Route Search Screen
```dart
class RouteSearchScreen extends StatefulWidget {
  @override
  _RouteSearchScreenState createState() => _RouteSearchScreenState();
}

class _RouteSearchScreenState extends State<RouteSearchScreen> {
  final _routeService = RouteService();
  List<app_route.Route> _routes = [];
  bool _isLoading = false;
  
  Future<void> _searchRoutes() async {
    setState(() => _isLoading = true);
    
    try {
      final routes = await _routeService.searchRoutes(
        fromLatitude: 47.2357,  // Ростов
        fromLongitude: 39.7015,
        toLatitude: 47.5090,    // Волгодонск
        toLongitude: 42.1760,
        passengers: 2,
      );
      
      setState(() {
        _routes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка поиска: $e')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Поиск маршрутов')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _searchRoutes,
            child: Text('Найти маршруты'),
          ),
          if (_isLoading)
            CircularProgressIndicator()
          else
            Expanded(
              child: ListView.builder(
                itemCount: _routes.length,
                itemBuilder: (context, index) {
                  final route = _routes[index];
                  return ListTile(
                    title: Text('${route.fromCity} → ${route.toCity}'),
                    subtitle: Text('Цена: ${route.basePrice} ₽'),
                    trailing: Text('${route.distanceKm} км'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## 🔄 Миграция данных

### Перенос существующих данных из SQLite:

1. **Экспорт данных из SQLite**:
```dart
// В вашем существующем коде SQLite
final db = await openDatabase('timetotravel.db');

// Получить всех пользователей
final users = await db.query('users');

// Получить все маршруты
final routes = await db.query('routes');

// Отправить на backend
for (final user in users) {
  await AuthService().register(
    email: user['email'],
    password: 'temporary_password',  // Пользователям нужно будет сбросить
    name: user['name'],
  );
}
```

2. **Удалить SQLite зависимости**:
```yaml
# Удалить из pubspec.yaml:
# sqflite: ^2.3.0
# path_provider: ^2.1.1
```

3. **Удалить старые файлы**:
```bash
rm -rf lib/database/
```

---

## ✅ Чек-лист миграции

- [ ] Установить необходимые пакеты (dio, flutter_secure_storage, provider)
- [ ] Создать структуру папок (api/, models/, providers/, utils/)
- [ ] Реализовать ApiClient с interceptors
- [ ] Реализовать TokenStorage для JWT
- [ ] Создать сервисы (AuthService, RouteService, OrderService)
- [ ] Создать providers (AuthProvider, RouteProvider, OrderProvider)
- [ ] Обновить models с JSON serialization
- [ ] Обновить UI screens для работы с API
- [ ] Протестировать регистрацию и вход
- [ ] Протестировать поиск маршрутов
- [ ] Протестировать создание заказов
- [ ] Добавить обработку ошибок
- [ ] Добавить loading states
- [ ] Протестировать offline режим
- [ ] Удалить SQLite код
- [ ] Обновить документацию

---

## 🚨 Обработка ошибок

### Сетевые ошибки:
```dart
try {
  final routes = await routeService.searchRoutes(...);
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    // Таймаут подключения
    showError('Превышено время ожидания');
  } else if (e.type == DioExceptionType.receiveTimeout) {
    // Таймаут получения данных
    showError('Сервер не отвечает');
  } else if (e.response?.statusCode == 401) {
    // Не авторизован
    navigateToLogin();
  } else {
    showError('Ошибка сети: ${e.message}');
  }
}
```

### Offline режим:
```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkChecker {
  static Future<bool> isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

// Перед API вызовом:
if (!await NetworkChecker.isConnected()) {
  showError('Нет подключения к интернету');
  return;
}
```

---

## 📊 Тестирование

### Unit тесты для сервисов:
```dart
// test/api/auth_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AuthService', () {
    late AuthService authService;
    
    setUp(() {
      authService = AuthService();
    });
    
    test('login успешно', () async {
      final result = await authService.login(
        email: 'test@example.com',
        password: 'Test123!',
      );
      
      expect(result['user'], isNotNull);
      expect(result['accessToken'], isNotNull);
    });
    
    test('login с неверными данными', () async {
      expect(
        () => authService.login(
          email: 'wrong@example.com',
          password: 'wrong',
        ),
        throwsA(isA<String>()),
      );
    });
  });
}
```

---

## 🎯 Следующие шаги

1. **Реализовать базовый функционал**:
   - ✅ Авторизация/регистрация
   - ✅ Поиск маршрутов
   - ✅ Создание заказов

2. **Добавить продвинутые фичи**:
   - [ ] Push уведомления (Firebase Cloud Messaging)
   - [ ] Геолокация в реальном времени
   - [ ] Платёжная интеграция
   - [ ] Чат с водителем

3. **Оптимизация**:
   - [ ] Кэширование данных
   - [ ] Pagination для списков
   - [ ] Image optimization
   - [ ] Background sync

---

**Готовы к интеграции? Начните с установки пакетов и создания API клиента! 🚀**
