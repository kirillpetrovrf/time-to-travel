import 'api_client.dart';
import 'api_config.dart';
import 'routes_api_service.dart';

/// Статистика заказов
class AdminStats {
  final int totalOrders;
  final int pendingOrders;
  final int confirmedOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final Map<String, dynamic>? additionalStats;

  AdminStats({
    required this.totalOrders,
    required this.pendingOrders,
    required this.confirmedOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    this.additionalStats,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalOrders: json['totalOrders'] as int? ?? 0,
      pendingOrders: json['pendingOrders'] as int? ?? 0,
      confirmedOrders: json['confirmedOrders'] as int? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      cancelledOrders: json['cancelledOrders'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      additionalStats: json['additionalStats'] as Map<String, dynamic>?,
    );
  }
}

/// Сервис администрирования для диспетчеров
class AdminApiService {
  final ApiClient _apiClient;

  AdminApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Создать предопределенный маршрут
  /// POST /admin/routes
  Future<ApiPredefinedRoute> createRoute({
    required String fromCity,
    required String toCity,
    required double basePrice,
    required int durationMinutes,
    required int distanceKm,
    String? description,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.adminEndpoint}/routes',
        body: {
          'fromCity': fromCity,
          'toCity': toCity,
          'basePrice': basePrice,
          'durationMinutes': durationMinutes,
          'distanceKm': distanceKm,
          if (description != null) 'description': description,
        },
        requiresAuth: true,
      );

      return ApiPredefinedRoute.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить предопределенный маршрут
  /// PUT /admin/routes/:id
  Future<ApiPredefinedRoute> updateRoute({
    required String routeId,
    String? fromCity,
    String? toCity,
    double? basePrice,
    int? durationMinutes,
    int? distanceKm,
    String? description,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (fromCity != null) body['fromCity'] = fromCity;
      if (toCity != null) body['toCity'] = toCity;
      if (basePrice != null) body['basePrice'] = basePrice;
      if (durationMinutes != null) body['durationMinutes'] = durationMinutes;
      if (distanceKm != null) body['distanceKm'] = distanceKm;
      if (description != null) body['description'] = description;
      if (isActive != null) body['isActive'] = isActive;

      final response = await _apiClient.put(
        '${ApiConfig.adminEndpoint}/routes/$routeId',
        body: body,
        requiresAuth: true,
      );

      return ApiPredefinedRoute.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить предопределенный маршрут
  /// DELETE /admin/routes/:id
  Future<void> deleteRoute(String routeId) async {
    try {
      await _apiClient.delete(
        '${ApiConfig.adminEndpoint}/routes/$routeId',
        requiresAuth: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Получить статистику
  /// GET /admin/stats
  Future<AdminStats> getStats() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.adminEndpoint}/stats',
        requiresAuth: true,
      );

      return AdminStats.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Получить список предопределенных маршрутов (для админа)
  /// GET /admin/predefined
  Future<List<ApiPredefinedRoute>> getPredefinedRoutes() async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.adminEndpoint}/predefined',
        requiresAuth: true,
      );

      final routes = (response['routes'] as List<dynamic>? ?? [])
          .map((e) => ApiPredefinedRoute.fromJson(e as Map<String, dynamic>))
          .toList();

      return routes;
    } catch (e) {
      rethrow;
    }
  }

  /// Закрытие клиента
  void dispose() {
    _apiClient.dispose();
  }
}
