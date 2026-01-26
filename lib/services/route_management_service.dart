import 'package:flutter/foundation.dart';
import '../models/predefined_route.dart';

/// ⚠️ DEPRECATED: SQLite удалён, предустановленные маршруты должны храниться в PostgreSQL
/// Сервис для управления предустановленными маршрутами
/// TODO: Переписать на использование PostgreSQL API или удалить если не нужен
class RouteManagementService {
  static final RouteManagementService instance = RouteManagementService._();
  RouteManagementService._();

  List<PredefinedRoute>? _cachedRoutes;

  void clearCache() {
    _cachedRoutes = null;
    if (kDebugMode) {
      print('⚠️ RouteManagementService DEPRECATED: cache cleared');
    }
  }

  Future<List<PredefinedRoute>> getAllRoutes({bool forceRefresh = false}) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.getAllRoutes DEPRECATED');
    }
    return _cachedRoutes ?? [];
  }

  Future<PredefinedRoute?> findRoute(String fromCity, String toCity) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.findRoute DEPRECATED');
    }
    return null;
  }

  Future<double?> getRoutePrice(String? fromCity, String? toCity) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.getRoutePrice DEPRECATED');
    }
    return null;
  }

  Future<String> addRoute({
    required String fromCity,
    required String toCity,
    required String routeGroupId,
    required List<Map<String, dynamic>> stopsData,
    required double basePrice,
    String? description,
  }) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.addRoute DEPRECATED');
    }
    return 'deprecated_route';
  }

  Future<void> updateRoute(PredefinedRoute route) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.updateRoute DEPRECATED');
    }
  }

  Future<void> deleteRoute(String routeId) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.deleteRoute DEPRECATED');
    }
  }

  Future<void> addRoutesBatch(List<PredefinedRoute> routes) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.addRoutesBatch DEPRECATED');
    }
  }

  Future<Map<String, int>> getRoutesStats() async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.getRoutesStats DEPRECATED');
    }
    return {};
  }

  Future<List<PredefinedRoute>> getRoutesByGroup(String groupId) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.getRoutesByGroup DEPRECATED');
    }
    return [];
  }

  Future<void> updateGroupRoutes(String groupId, double newPrice) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.updateGroupRoutes DEPRECATED');
    }
  }

  Future<void> updateRoutePrice(String routeId, double newPrice) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.updateRoutePrice DEPRECATED');
    }
  }

  Future<void> resetRouteToGroupPrice(String routeId, double groupPrice) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.resetRouteToGroupPrice DEPRECATED');
    }
  }

  Future<String> createReverseRoute(PredefinedRoute originalRoute) async {
    if (kDebugMode) {
      print('⚠️ RouteManagementService.createReverseRoute DEPRECATED');
    }
    return 'deprecated_reverse_route';
  }
}
