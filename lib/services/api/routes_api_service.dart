import 'api_client.dart';
import 'api_config.dart';

/// Модель предопределенного маршрута из API
class ApiPredefinedRoute {
  final String id;
  final String fromCity;
  final String toCity;
  final double price;
  final String? groupId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiPredefinedRoute({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.price,
    this.groupId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiPredefinedRoute.fromJson(Map<String, dynamic> json) {
    return ApiPredefinedRoute(
      id: json['id'] as String,
      fromCity: json['fromCity'] as String,
      toCity: json['toCity'] as String,
      price: (json['price'] as num).toDouble(),
      groupId: json['groupId'] as String?,
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
      'price': price,
      if (groupId != null) 'groupId': groupId,
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
/// Поддержка полного CRUD для CRM системы маршрутов
class RoutesApiService {
  final ApiClient _apiClient;

  RoutesApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  // === CRUD операции ===

  /// Получить все маршруты
  /// GET /search
  Future<List<ApiPredefinedRoute>> getAllRoutes() async {
    try {
      final response = await _apiClient.get(
        ApiConfig.routesEndpoint,
        requiresAuth: false,
      );

      final routesJson = response['routes'] as List<dynamic>? ?? [];
      return routesJson
          .map((e) => ApiPredefinedRoute.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Поиск маршрутов по направлению
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
        requiresAuth: false,
      );

      return RoutesSearchResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Создать маршрут (только админы)
  /// POST /admin/predefined
  Future<ApiPredefinedRoute> createRoute({
    required String fromCity,
    required String toCity,
    required double price,
    String? groupId,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.adminEndpoint}/predefined',
        body: {
          'fromCity': fromCity,
          'toCity': toCity,
          'price': price,
          if (groupId != null) 'groupId': groupId,
        },
        requiresAuth: true,
      );

      return ApiPredefinedRoute.fromJson(
        response['route'] as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить маршрут (только админы)
  /// PUT /admin/predefined/:id
  Future<ApiPredefinedRoute> updateRoute({
    required String id,
    String? fromCity,
    String? toCity,
    double? price,
    String? groupId,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (fromCity != null) body['fromCity'] = fromCity;
      if (toCity != null) body['toCity'] = toCity;
      if (price != null) body['price'] = price;
      if (groupId != null) body['groupId'] = groupId;
      if (isActive != null) body['isActive'] = isActive;

      final response = await _apiClient.put(
        '${ApiConfig.adminEndpoint}/predefined/$id',
        body: body,
        requiresAuth: true,
      );

      return ApiPredefinedRoute.fromJson(
        response['route'] as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить маршрут (только админы)
  /// DELETE /admin/predefined/:id
  Future<bool> deleteRoute(String id) async {
    try {
      await _apiClient.delete(
        '${ApiConfig.adminEndpoint}/predefined/$id',
        requiresAuth: true,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Массовая загрузка маршрутов (только админы)
  /// POST /admin/predefined/batch
  Future<Map<String, dynamic>> batchCreateRoutes({
    required List<Map<String, dynamic>> routes,
    bool skipDuplicates = true,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.adminEndpoint}/predefined/batch',
        body: {
          'routes': routes,
          'skipDuplicates': skipDuplicates,
        },
        requiresAuth: true,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Закрытие клиента
  void dispose() {
    _apiClient.dispose();
  }
}
