import 'api_client.dart';
import 'api_config.dart';

/// Модель предопределенного маршрута из API
class ApiPredefinedRoute {
  final String id;
  final String fromCity;
  final String toCity;
  final double basePrice;
  final int durationMinutes;
  final int distanceKm;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiPredefinedRoute({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.basePrice,
    required this.durationMinutes,
    required this.distanceKm,
    this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiPredefinedRoute.fromJson(Map<String, dynamic> json) {
    return ApiPredefinedRoute(
      id: json['id'] as String,
      fromCity: json['fromCity'] as String,
      toCity: json['toCity'] as String,
      basePrice: (json['basePrice'] as num).toDouble(),
      durationMinutes: json['durationMinutes'] as int,
      distanceKm: json['distanceKm'] as int,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromCity': fromCity,
      'toCity': toCity,
      'basePrice': basePrice,
      'durationMinutes': durationMinutes,
      'distanceKm': distanceKm,
      if (description != null) 'description': description,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Ответ поиска маршрутов
class RoutesSearchResponse {
  final List<ApiPredefinedRoute> routes;
  final int count;

  RoutesSearchResponse({
    required this.routes,
    required this.count,
  });

  factory RoutesSearchResponse.fromJson(Map<String, dynamic> json) {
    return RoutesSearchResponse(
      routes: (json['routes'] as List<dynamic>)
          .map((e) => ApiPredefinedRoute.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int,
    );
  }
}

/// Сервис для работы с маршрутами через Time to Travel API
class RoutesApiService {
  final ApiClient _apiClient;

  RoutesApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Поиск маршрутов
  /// GET /search?from=&to=
  Future<RoutesSearchResponse> searchRoutes({
    String? from,
    String? to,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (from != null) queryParams['from'] = from;
      if (to != null) queryParams['to'] = to;

      final response = await _apiClient.get(
        ApiConfig.routesEndpoint,
        queryParameters: queryParams,
        requiresAuth: false, // Поиск доступен без авторизации
      );

      return RoutesSearchResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Закрытие клиента
  void dispose() {
    _apiClient.dispose();
  }
}
