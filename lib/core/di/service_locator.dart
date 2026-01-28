import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/network_info.dart';
import '../../data/datasources/orders_cache_datasource.dart';
import '../../data/datasources/orders_remote_datasource.dart';
import '../../data/repositories/orders_repository_impl.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../services/api/api_config.dart';

/// Service Locator for Dependency Injection
/// 
/// Simple singleton pattern for managing dependencies.
/// In production, consider using get_it or riverpod.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Singletons
  Dio? _dio;
  NetworkInfo? _networkInfo;
  OrdersCacheDataSource? _ordersCacheDataSource;
  OrdersRemoteDataSource? _ordersRemoteDataSource;
  OrdersRepository? _ordersRepository;
  SharedPreferences? _sharedPreferences;

  /// Initialize all services
  Future<void> init() async {
    // Initialize SharedPreferences
    _sharedPreferences ??= await SharedPreferences.getInstance();

    // Initialize Dio with interceptors
    _dio ??= _createDio();

    // Initialize Network Info
    _networkInfo ??= NetworkInfoImpl(connectivity: Connectivity());

    // Initialize Data Sources
    _ordersCacheDataSource ??= OrdersCacheDataSource();
    _ordersRemoteDataSource ??= OrdersRemoteDataSourceImpl(dio: _dio!);

    // Initialize Repository
    _ordersRepository ??= OrdersRepositoryImpl(
      remoteDataSource: _ordersRemoteDataSource!,
      cacheDataSource: _ordersCacheDataSource!,
      networkInfo: _networkInfo!,
    );
  }

  /// Create configured Dio instance
  Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    dio.interceptors.add(_AuthInterceptor(_sharedPreferences!));
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => print('🌐 DIO: $obj'),
    ));

    return dio;
  }

  // Getters
  OrdersRepository get ordersRepository {
    if (_ordersRepository == null) {
      throw Exception('ServiceLocator not initialized. Call init() first.');
    }
    return _ordersRepository!;
  }

  Dio get dio {
    if (_dio == null) {
      throw Exception('ServiceLocator not initialized. Call init() first.');
    }
    return _dio!;
  }

  SharedPreferences get sharedPreferences {
    if (_sharedPreferences == null) {
      throw Exception('ServiceLocator not initialized. Call init() first.');
    }
    return _sharedPreferences!;
  }

  /// Reset (useful for testing)
  void reset() {
    _dio = null;
    _networkInfo = null;
    _ordersCacheDataSource = null;
    _ordersRemoteDataSource = null;
    _ordersRepository = null;
    _sharedPreferences = null;
  }
}

/// Auth Interceptor for adding JWT token to requests
class _AuthInterceptor extends Interceptor {
  final SharedPreferences prefs;
  final FlutterSecureStorage secureStorage;

  _AuthInterceptor(this.prefs) 
      : secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  @override
  Future<void> onRequest(
    RequestOptions options, 
    RequestInterceptorHandler handler,
  ) async {
    // 🔐 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Читаем токен из FlutterSecureStorage И SharedPreferences
    String? token;
    
    try {
      // 1. Пробуем прочитать из FlutterSecureStorage (основной метод)
      token = await secureStorage.read(key: 'access_token');
      if (token != null && token.isNotEmpty) {
        print('🔐 [AUTH_INTERCEPTOR] Токен найден в FlutterSecureStorage');
      }
    } catch (e) {
      print('⚠️ [AUTH_INTERCEPTOR] Ошибка чтения из FlutterSecureStorage: $e');
    }
    
    // 2. Fallback: пробуем SharedPreferences
    if (token == null || token.isEmpty) {
      token = prefs.getString('auth_access_token_fallback') ?? 
              prefs.getString('access_token');
      if (token != null && token.isNotEmpty) {
        print('🔐 [AUTH_INTERCEPTOR] Токен найден в SharedPreferences');
      }
    }
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('✅ [AUTH_INTERCEPTOR] Добавлен токен: ${token.substring(0, 20)}...');
    } else {
      print('❌ [AUTH_INTERCEPTOR] Токен НЕ НАЙДЕН ни в FlutterSecureStorage, ни в SharedPreferences!');
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized - token expired
    if (err.response?.statusCode == 401) {
      print('🔐 Token expired, need to refresh');
      // TODO: Implement token refresh logic
    }
    handler.next(err);
  }
}
