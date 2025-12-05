import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/predefined_route.dart';
import 'offline_routes_service.dart';

/// Сервис для управления предустановленными маршрутами с SQLite + Firebase синхронизацией
class RouteManagementService {
  static const String _collectionName = 'predefined_routes';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final OfflineRoutesService _offlineService = OfflineRoutesService.instance;
  
  static final RouteManagementService instance = RouteManagementService._();
  RouteManagementService._();

  List<PredefinedRoute>? _cachedRoutes;
  DateTime? _lastCacheUpdate;
  static const int _cacheLifetimeMinutes = 30;

  CollectionReference get _collection => _firestore.collection(_collectionName);

  bool get _isCacheValid {
    if (_cachedRoutes == null || _lastCacheUpdate == null) return false;
    final now = DateTime.now();
    return now.difference(_lastCacheUpdate!).inMinutes < _cacheLifetimeMinutes;
  }

  void clearCache() {
    _cachedRoutes = null;
    _lastCacheUpdate = null;
    if (kDebugMode) {
      print('RouteManagementService: Cache cleared');
    }
  }

  Future<List<PredefinedRoute>> getAllRoutes({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _isCacheValid) {
        if (kDebugMode) {
          print('RouteManagementService: Returning cached routes (${_cachedRoutes!.length} routes)');
        }
        return _cachedRoutes!;
      }

      if (kDebugMode) {
        print('RouteManagementService: Loading routes from SQLite...');
      }

      // Загружаем маршруты из SQLite
      final routes = await _offlineService.getAllRoutes();
      
      // Если SQLite пустая, инициализируем fallback данные
      if (routes.isEmpty) {
        if (kDebugMode) {
          print('RouteManagementService: SQLite пустая, добавляем fallback маршруты...');
        }
        await _initializeFallbackRoutes();
        return await _offlineService.getAllRoutes();
      }

      _cachedRoutes = routes;
      _lastCacheUpdate = DateTime.now();

      if (kDebugMode) {
        print('RouteManagementService: Loaded ${routes.length} routes from SQLite');
      }

      // В фоне пытаемся синхронизировать с Firebase
      _syncWithFirebaseInBackground();

      return routes;
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Error loading routes - $e');
      }
      
      if (_cachedRoutes != null) {
        if (kDebugMode) {
          print('RouteManagementService: Returning cached routes due to error');
        }
        return _cachedRoutes!;
      }
      
      // Крайний случай - используем hardcoded данные
      if (kDebugMode) {
        print('RouteManagementService: Using hardcoded fallback routes');
      }
      return _getHardcodedFallbackRoutes();
    }
  }

  Future<PredefinedRoute?> findRoute(String fromCity, String toCity) async {
    try {
      // Используем SQLite для поиска маршрута
      final route = await _offlineService.findRoute(fromCity, toCity);
      if (route != null) {
        return route;
      }

      if (kDebugMode) {
        print('RouteManagementService: Route "$fromCity" → "$toCity" not found');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Error finding route from $fromCity to $toCity - $e');
      }
      return null;
    }
  }

  Future<double?> getRoutePrice(String? fromCity, String? toCity) async {
    if (fromCity == null || toCity == null) return null;

    try {
      final route = await findRoute(fromCity, toCity);
      if (route != null) {
        if (kDebugMode) {
          print('RouteManagementService: Found route ${route.fromCity} → ${route.toCity}: ${route.price}₽');
        }
        return route.price;
      }

      if (kDebugMode) {
        print('RouteManagementService: Route "$fromCity" → "$toCity" not found');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Error getting route price - $e');
      }
      return null;
    }
  }

  Future<String> addRoute({
    required String fromCity,
    required String toCity,
    required double price,
    String? groupId, // Добавляем параметр groupId
  }) async {
    try {
      final now = DateTime.now();
      final routeId = 'route_${now.millisecondsSinceEpoch}_${fromCity.toLowerCase()}_${toCity.toLowerCase()}';
      
      final route = PredefinedRoute(
        id: routeId,
        fromCity: fromCity.trim(),
        toCity: toCity.trim(),
        price: price,
        createdAt: now,
        updatedAt: now,
        groupId: groupId, // Добавляем groupId
      );

      final validation = PredefinedRouteHelper.validateRoute(
        route.fromCity, 
        route.toCity, 
        route.price
      );
      if (validation != null) {
        throw Exception('Validation error: $validation');
      }

      final existing = await findRoute(route.fromCity, route.toCity);
      if (existing != null) {
        throw Exception('Route from ${route.fromCity} to ${route.toCity} already exists');
      }

      if (kDebugMode) {
        print('RouteManagementService: Adding route ${route.fromCity} → ${route.toCity} (${route.price}₽)');
        print('🔍 [DEBUG] RouteManagementService.addRoute():');
        print('   fromCity: ${route.fromCity}');
        print('   toCity: ${route.toCity}');
        print('   price: ${route.price}');
        print('   groupId: ${route.groupId}');
      }

      // Сохраняем в SQLite (автоматически помечается как несинхронизированный)
      await _offlineService.addRoute(route);
      clearCache();
      
      // В фоне пытаемся синхронизировать с Firebase
      _syncWithFirebaseInBackground();
      
      if (kDebugMode) {
        print('RouteManagementService: Route added successfully with ID: $routeId');
      }
      
      return routeId;
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Error adding route - $e');
      }
      rethrow;
    }
  }

  /// Обновить существующий маршрут
  Future<void> updateRoute(PredefinedRoute route) async {
    try {
      final validation = PredefinedRouteHelper.validateRoute(
        route.fromCity, 
        route.toCity, 
        route.price
      );
      if (validation != null) {
        throw Exception('Validation error: $validation');
      }

      if (kDebugMode) {
        print('RouteManagementService: Updating route ${route.id}');
      }

      final updatedRoute = route.copyWith(updatedAt: DateTime.now());
      
      // Обновляем в SQLite
      await _offlineService.updateRoute(updatedRoute);
      clearCache();
      
      // В фоне пытаемся синхронизировать с Firebase
      _syncWithFirebaseInBackground();
      
      if (kDebugMode) {
        print('RouteManagementService: Route updated successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Error updating route - $e');
      }
      rethrow;
    }
  }

  /// Удалить маршрут
  Future<void> deleteRoute(String routeId) async {
    try {
      if (kDebugMode) {
        print('RouteManagementService: Deleting route $routeId');
      }

      // Удаляем из SQLite
      await _offlineService.deleteRoute(routeId);
      clearCache();
      
      // В фоне пытаемся удалить из Firebase
      _deleteFromFirebaseInBackground(routeId);
      
      if (kDebugMode) {
        print('RouteManagementService: Route deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Error deleting route - $e');
      }
      rethrow;
    }
  }

  Future<void> addRoutesBatch(List<PredefinedRoute> routes) async {
    try {
      if (kDebugMode) {
        print('RouteManagementService: Adding ${routes.length} routes in batch');
      }

      // Сохраняем в SQLite (offline-first подход)
      for (final route in routes) {
        final validation = PredefinedRouteHelper.validateRoute(
          route.fromCity, 
          route.toCity, 
          route.price
        );
        if (validation != null) {
          throw Exception('Validation error for route ${route.fromCity} → ${route.toCity}: $validation');
        }

        // Сохраняем каждый маршрут в SQLite
        await _offlineService.addRoute(route);
      }
      
      // Очищаем кеш после успешного сохранения в SQLite
      clearCache();
      
      if (kDebugMode) {
        print('RouteManagementService: Batch add to SQLite completed successfully (${routes.length} routes)');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Error in batch add - $e');
      }
      rethrow;
    }
  }

  /// Получить статистику маршрутов
  Future<Map<String, int>> getRoutesStats() async {
    try {
      final stats = await _offlineService.getRoutesStats();
      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Error getting routes stats - $e');
      }
      return {'total_routes': 0, 'unique_cities': 0, 'avg_price': 0, 'unsynced_routes': 0};
    }
  }

  /// Инициализация fallback маршрутов в SQLite
  Future<void> _initializeFallbackRoutes() async {
    final now = DateTime.now();
    final fallbackRoutes = [
      PredefinedRoute(
        id: 'local_1',
        fromCity: 'Донецк',
        toCity: 'Ростов-на-Дону',
        price: 2500.0,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: 'local_2',
        fromCity: 'Ростов-на-Дону',
        toCity: 'Донецк',
        price: 2500.0,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: 'local_3',
        fromCity: 'Донецк',
        toCity: 'Белгород',
        price: 3500.0,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: 'local_4',
        fromCity: 'Белгород',
        toCity: 'Донецк',
        price: 3500.0,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: 'local_5',
        fromCity: 'Донецк',
        toCity: 'Воронеж',
        price: 4000.0,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    for (final route in fallbackRoutes) {
      await _offlineService.addRoute(route);
    }
  }

  /// Hardcoded fallback маршруты как крайний случай
  List<PredefinedRoute> _getHardcodedFallbackRoutes() {
    final now = DateTime.now();
    return [
      PredefinedRoute(
        id: 'fallback_1',
        fromCity: 'Донецк',
        toCity: 'Ростов-на-Дону',
        price: 2500.0,
        createdAt: now,
        updatedAt: now,
      ),
      PredefinedRoute(
        id: 'fallback_2',
        fromCity: 'Ростов-на-Дону',
        toCity: 'Донецк',
        price: 2500.0,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  /// Фоновая синхронизация с Firebase
  void _syncWithFirebaseInBackground() {
    // TODO: Firebase временно отключён до настройки сервера
    if (kDebugMode) {
      print('RouteManagementService: Firebase sync disabled - working in offline mode');
    }
    // После настройки Firebase раскомментировать:
    // _tryFirebaseSync().catchError((error) {
    //   if (kDebugMode) {
    //     print('RouteManagementService: Background Firebase sync failed: $error');
    //   }
    // });
  }

  /// Попытка синхронизации с Firebase
  Future<void> _tryFirebaseSync() async {
    try {
      // Загружаем несинхронизированные маршруты
      final unsyncedRoutes = await _offlineService.getUnsyncedRoutes();
      
      if (unsyncedRoutes.isEmpty) {
        return;
      }

      if (kDebugMode) {
        print('RouteManagementService: Syncing ${unsyncedRoutes.length} routes to Firebase');
      }

      // Пытаемся загрузить в Firebase
      for (final route in unsyncedRoutes) {
        try {
          await _collection.doc(route.id).set(route.toFirestore());
          await _offlineService.markAsSynced(route.id);
          
          if (kDebugMode) {
            print('RouteManagementService: Route ${route.id} synced to Firebase');
          }
        } catch (e) {
          if (kDebugMode) {
            print('RouteManagementService: Failed to sync route ${route.id}: $e');
          }
          // Продолжаем с другими маршрутами при ошибке
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Firebase sync error: $e');
      }
    }
  }

  /// Фоновое удаление из Firebase
  void _deleteFromFirebaseInBackground(String routeId) {
    // TODO: Firebase временно отключён до настройки сервера
    if (kDebugMode) {
      print('RouteManagementService: Firebase delete disabled - working in offline mode');
    }
    // После настройки Firebase раскомментировать:
    // _tryFirebaseDelete(routeId).catchError((error) {
    //   if (kDebugMode) {
    //     print('RouteManagementService: Background Firebase delete failed: $error');
    //   }
    // });
  }

  /// Попытка удаления из Firebase
  Future<void> _tryFirebaseDelete(String routeId) async {
    try {
      await _collection.doc(routeId).delete();
      
      if (kDebugMode) {
        print('RouteManagementService: Route $routeId deleted from Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Failed to delete route $routeId from Firebase: $e');
      }
    }
  }

  // ========================================
  // 🆕 МЕТОДЫ ДЛЯ РАБОТЫ С ГРУППАМИ
  // ========================================

  /// Получить все маршруты группы
  Future<List<PredefinedRoute>> getRoutesByGroup(String groupId) async {
    try {
      if (kDebugMode) {
        print('RouteManagementService: Загружаем маршруты группы $groupId...');
      }

      // Загружаем из SQLite
      final allRoutes = await _offlineService.getAllRoutes();
      final groupRoutes = allRoutes
          .where((route) => route.groupId == groupId)
          .toList();

      if (kDebugMode) {
        print('RouteManagementService: Найдено ${groupRoutes.length} маршрутов в группе $groupId');
      }

      return groupRoutes;
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: Ошибка получения маршрутов группы: $e');
      }
      return [];
    }
  }

  /// Обновить цены всех маршрутов группы
  Future<void> updateGroupRoutes(String groupId, double newPrice) async {
    try {
      if (kDebugMode) {
        print('RouteManagementService: Обновляем цены группы $groupId на $newPrice₽...');
      }

      // Получаем все маршруты группы
      final routes = await getRoutesByGroup(groupId);

      // Обновляем только те, которые используют групповую цену
      int updatedCount = 0;

      for (final route in routes) {
        if (route.useGroupPrice && !route.customPrice) {
          // Обновляем в SQLite
          await _offlineService.updateRoute(
            route.copyWith(
              price: newPrice,
              updatedAt: DateTime.now(),
            ),
          );
          updatedCount++;
        }
      }

      // Очищаем кэш
      clearCache();

      if (kDebugMode) {
        print('RouteManagementService: ✅ Обновлено $updatedCount маршрутов в группе $groupId');
      }

      // TODO: Синхронизация с Firebase
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: ❌ Ошибка обновления маршрутов группы: $e');
      }
      rethrow;
    }
  }

  /// Изменить цену конкретного маршрута (индивидуально)
  Future<void> updateRoutePrice(String routeId, double newPrice) async {
    try {
      if (kDebugMode) {
        print('RouteManagementService: Обновляем цену маршрута $routeId на $newPrice₽...');
      }

      // Получаем маршрут
      final allRoutes = await _offlineService.getAllRoutes();
      final route = allRoutes.firstWhere((r) => r.id == routeId);

      // Обновляем маршрут
      await _offlineService.updateRoute(
        route.copyWith(
          price: newPrice,
          useGroupPrice: false,
          customPrice: true,
          updatedAt: DateTime.now(),
        ),
      );

      // Очищаем кэш
      clearCache();

      if (kDebugMode) {
        print('RouteManagementService: ✅ Цена маршрута $routeId обновлена на $newPrice₽');
      }

      // TODO: Синхронизация с Firebase
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: ❌ Ошибка обновления цены маршрута: $e');
      }
      rethrow;
    }
  }

  /// Вернуть маршрут к групповой цене
  Future<void> resetRouteToGroupPrice(String routeId, double groupPrice) async {
    try {
      if (kDebugMode) {
        print('RouteManagementService: Возвращаем маршрут $routeId к групповой цене $groupPrice₽...');
      }

      // Получаем маршрут
      final allRoutes = await _offlineService.getAllRoutes();
      final route = allRoutes.firstWhere((r) => r.id == routeId);

      // Обновляем маршрут
      await _offlineService.updateRoute(
        route.copyWith(
          price: groupPrice,
          useGroupPrice: true,
          customPrice: false,
          updatedAt: DateTime.now(),
        ),
      );

      // Очищаем кэш
      clearCache();

      if (kDebugMode) {
        print('RouteManagementService: ✅ Маршрут $routeId возвращён к групповой цене');
      }

      // TODO: Синхронизация с Firebase
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: ❌ Ошибка сброса цены маршрута: $e');
      }
      rethrow;
    }
  }

  /// Создать обратный маршрут
  Future<String> createReverseRoute(PredefinedRoute originalRoute) async {
    try {
      final reverseRoute = originalRoute.createReverse();

      // Сохраняем в SQLite
      await _offlineService.addRoute(reverseRoute);

      // Очищаем кэш
      clearCache();

      if (kDebugMode) {
        print('RouteManagementService: ✅ Создан обратный маршрут: ${reverseRoute.fromCity} → ${reverseRoute.toCity}');
      }

      // TODO: Синхронизация с Firebase

      return reverseRoute.id;
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementService: ❌ Ошибка создания обратного маршрута: $e');
      }
      rethrow;
    }
  }
}
