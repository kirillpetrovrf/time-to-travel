import 'api_client.dart';

/// Модель группы маршрутов из API
class ApiRouteGroup {
  final String id;
  final String name;
  final String? description;
  final double basePrice;
  final bool isActive;
  final int routeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiRouteGroup({
    required this.id,
    required this.name,
    this.description,
    required this.basePrice,
    required this.isActive,
    this.routeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiRouteGroup.fromJson(Map<String, dynamic> json) {
    return ApiRouteGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      routeCount: json['routeCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'basePrice': basePrice,
      'isActive': isActive,
      'routeCount': routeCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Сервис для работы с группами маршрутов через Time to Travel API
class RouteGroupsApiService {
  final ApiClient _apiClient;

  RouteGroupsApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  static const String _endpoint = '/route-groups';

  /// Получить все группы
  /// GET /route-groups
  Future<List<ApiRouteGroup>> getAllGroups({bool activeOnly = false}) async {
    try {
      final queryParams = <String, String>{};
      if (activeOnly) queryParams['active'] = 'true';

      final response = await _apiClient.get(
        _endpoint,
        queryParameters: queryParams,
        requiresAuth: false,
      );

      final groupsJson = response['groups'] as List<dynamic>? ?? [];
      return groupsJson
          .map((e) => ApiRouteGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Получить группу по ID с маршрутами
  /// GET /route-groups/:id
  Future<Map<String, dynamic>> getGroupWithRoutes(String id) async {
    try {
      final response = await _apiClient.get(
        '$_endpoint/$id',
        requiresAuth: false,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  /// Создать группу (только админы)
  /// POST /route-groups
  Future<ApiRouteGroup> createGroup({
    required String name,
    String? description,
    double basePrice = 0,
  }) async {
    try {
      final response = await _apiClient.post(
        _endpoint,
        body: {
          'name': name,
          if (description != null) 'description': description,
          'basePrice': basePrice,
        },
        requiresAuth: true,
      );

      return ApiRouteGroup.fromJson(
        response['group'] as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить группу (только админы)
  /// PUT /route-groups/:id
  Future<ApiRouteGroup> updateGroup({
    required String id,
    String? name,
    String? description,
    double? basePrice,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (basePrice != null) body['basePrice'] = basePrice;
      if (isActive != null) body['isActive'] = isActive;

      final response = await _apiClient.put(
        '$_endpoint/$id',
        body: body,
        requiresAuth: true,
      );

      return ApiRouteGroup.fromJson(
        response['group'] as Map<String, dynamic>,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Удалить группу (только админы)
  /// DELETE /route-groups/:id
  Future<bool> deleteGroup(String id) async {
    try {
      await _apiClient.delete(
        '$_endpoint/$id',
        requiresAuth: true,
      );
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Закрытие клиента
  void dispose() {
    _apiClient.dispose();
  }
}
