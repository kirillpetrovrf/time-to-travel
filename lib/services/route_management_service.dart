import 'package:flutter/foundation.dart';
import '../models/predefined_route.dart';
import 'api/routes_api_service.dart';

/// Сервис для управления предустановленными маршрутами
/// ✅ Работает через PostgreSQL API
class RouteManagementService {
  static final RouteManagementService instance = RouteManagementService._();
  RouteManagementService._();

  final RoutesApiService _apiService = RoutesApiService();
  List<PredefinedRoute>? _cachedRoutes;

  void clearCache() {
    _cachedRoutes = null;
    if (kDebugMode) {
      print('🔄 [RouteManagementService] Cache cleared');
    }
  }

  /// Получить все маршруты из PostgreSQL API
  Future<List<PredefinedRoute>> getAllRoutes({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedRoutes != null) {
      if (kDebugMode) {
        print('📦 [RouteManagementService] Возвращаем ${_cachedRoutes!.length} маршрутов из кэша');
      }
      return _cachedRoutes!;
    }

    try {
      if (kDebugMode) {
        print('🌐 [RouteManagementService] Загружаем маршруты из PostgreSQL API...');
      }
      
      final apiRoutes = await _apiService.getAllRoutes();
      
      // Конвертируем ApiPredefinedRoute в PredefinedRoute
      _cachedRoutes = apiRoutes.map((apiRoute) => PredefinedRoute(
        id: apiRoute.id,
        fromCity: apiRoute.fromCity,
        toCity: apiRoute.toCity,
        price: apiRoute.price,
        groupId: apiRoute.groupId,
        createdAt: apiRoute.createdAt,
        updatedAt: apiRoute.updatedAt,
      )).toList();

      if (kDebugMode) {
        print('✅ [RouteManagementService] Загружено ${_cachedRoutes!.length} маршрутов');
      }
      
      return _cachedRoutes!;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RouteManagementService] Ошибка загрузки: $e');
      }
      return _cachedRoutes ?? [];
    }
  }

  /// Найти маршрут по направлению
  Future<PredefinedRoute?> findRoute(String fromCity, String toCity) async {
    try {
      final response = await _apiService.searchRoutes(from: fromCity, to: toCity);
      if (response.routes.isEmpty) return null;
      
      final apiRoute = response.routes.first;
      return PredefinedRoute(
        id: apiRoute.id,
        fromCity: apiRoute.fromCity,
        toCity: apiRoute.toCity,
        price: apiRoute.price,
        groupId: apiRoute.groupId,
        createdAt: apiRoute.createdAt,
        updatedAt: apiRoute.updatedAt,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RouteManagementService] Ошибка поиска: $e');
      }
      return null;
    }
  }

  /// Получить цену маршрута
  Future<double?> getRoutePrice(String? fromCity, String? toCity) async {
    if (fromCity == null || toCity == null) return null;
    
    final route = await findRoute(fromCity, toCity);
    return route?.price;
  }

  /// Добавить новый маршрут через API
  Future<String> addRoute({
    required String fromCity,
    required String toCity,
    required String routeGroupId,
    required List<Map<String, dynamic>> stopsData,
    required double basePrice,
    String? description,
  }) async {
    try {
      if (kDebugMode) {
        print('🌐 [RouteManagementService] Создаём маршрут: $fromCity → $toCity, $basePrice ₽');
      }
      
      final apiRoute = await _apiService.createRoute(
        fromCity: fromCity,
        toCity: toCity,
        price: basePrice,
        groupId: routeGroupId,
      );
      
      // Обновляем кэш
      clearCache();
      
      if (kDebugMode) {
        print('✅ [RouteManagementService] Маршрут создан: ${apiRoute.id}');
      }
      
      return apiRoute.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RouteManagementService] Ошибка создания: $e');
      }
      rethrow;
    }
  }

  /// Обновить маршрут
  Future<void> updateRoute(PredefinedRoute route) async {
    try {
      await _apiService.updateRoute(
        id: route.id,
        fromCity: route.fromCity,
        toCity: route.toCity,
        price: route.price,
        groupId: route.groupId,
      );
      
      clearCache();
      
      if (kDebugMode) {
        print('✅ [RouteManagementService] Маршрут обновлён: ${route.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RouteManagementService] Ошибка обновления: $e');
      }
      rethrow;
    }
  }

  /// Удалить маршрут
  Future<void> deleteRoute(String routeId) async {
    try {
      await _apiService.deleteRoute(routeId);
      clearCache();
      
      if (kDebugMode) {
        print('✅ [RouteManagementService] Маршрут удалён: $routeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RouteManagementService] Ошибка удаления: $e');
      }
      rethrow;
    }
  }

  /// Массовая загрузка маршрутов
  Future<void> addRoutesBatch(List<PredefinedRoute> routes) async {
    try {
      final routesList = routes.map((r) => {
        'fromCity': r.fromCity,
        'toCity': r.toCity,
        'price': r.price,
        'groupId': r.groupId,
      }).toList();
      
      await _apiService.batchCreateRoutes(routes: routesList);
      clearCache();
      
      if (kDebugMode) {
        print('✅ [RouteManagementService] Batch загружено ${routes.length} маршрутов');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [RouteManagementService] Ошибка batch загрузки: $e');
      }
      rethrow;
    }
  }

  /// Статистика маршрутов
  Future<Map<String, int>> getRoutesStats() async {
    final routes = await getAllRoutes();
    return {
      'total': routes.length,
      'active': routes.length,
    };
  }

  /// Получить маршруты по группе
  Future<List<PredefinedRoute>> getRoutesByGroup(String groupId) async {
    final routes = await getAllRoutes();
    return routes.where((r) => r.groupId == groupId).toList();
  }

  /// Обновить цены всех маршрутов группы
  Future<void> updateGroupRoutes(String groupId, double newPrice) async {
    final routes = await getRoutesByGroup(groupId);
    for (final route in routes) {
      await _apiService.updateRoute(id: route.id, price: newPrice);
    }
    clearCache();
    
    if (kDebugMode) {
      print('✅ [RouteManagementService] Обновлено ${routes.length} маршрутов в группе');
    }
  }

  /// Обновить цену маршрута
  Future<void> updateRoutePrice(String routeId, double newPrice) async {
    await _apiService.updateRoute(id: routeId, price: newPrice);
    clearCache();
  }

  /// Сбросить цену маршрута к цене группы
  Future<void> resetRouteToGroupPrice(String routeId, double groupPrice) async {
    await updateRoutePrice(routeId, groupPrice);
  }

  /// Создать обратный маршрут
  Future<String> createReverseRoute(PredefinedRoute originalRoute) async {
    return addRoute(
      fromCity: originalRoute.toCity,
      toCity: originalRoute.fromCity,
      routeGroupId: originalRoute.groupId ?? 'default',
      stopsData: [],
      basePrice: originalRoute.price,
    );
  }
}
