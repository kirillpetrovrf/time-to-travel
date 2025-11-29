import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/predefined_route.dart';
import 'local_routes_service.dart';

/// Сервис для управления предустановленными маршрутами 
/// SQLite-первый подход с Firebase синхронизацией
class RouteManagementServiceV2 {
  static const String _collectionName = 'predefined_routes';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalRoutesService _localService = LocalRoutesService.instance;
  
  static final RouteManagementServiceV2 instance = RouteManagementServiceV2._();
  RouteManagementServiceV2._();

  CollectionReference get _collection => _firestore.collection(_collectionName);

  /// Получить все маршруты из локальной базы
  Future<List<PredefinedRoute>> getAllRoutes({bool forceRefresh = false}) async {
    try {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Загрузка маршрутов из SQLite...');
      }

      return await _localService.getAllRoutes();
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка загрузки маршрутов - $e');
      }
      return [];
    }
  }

  /// Найти маршрут по городам
  Future<PredefinedRoute?> findRoute(String fromCity, String toCity) async {
    try {
      return await _localService.findRoute(fromCity, toCity);
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка поиска маршрута от $fromCity до $toCity - $e');
      }
      return null;
    }
  }

  /// Получить цену маршрута
  Future<double?> getRoutePrice(String? fromCity, String? toCity) async {
    if (fromCity == null || toCity == null) return null;

    try {
      final route = await findRoute(fromCity, toCity);
      if (route != null) {
        if (kDebugMode) {
          print('RouteManagementServiceV2: Найден маршрут ${route.fromCity} → ${route.toCity}: ${route.price}₽');
        }
        return route.price;
      }

      if (kDebugMode) {
        print('RouteManagementServiceV2: Маршрут "$fromCity" → "$toCity" не найден');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка получения цены маршрута - $e');
      }
      return null;
    }
  }

  /// Добавить маршрут (SQLite-первый подход)
  Future<String> addRoute({
    required String fromCity,
    required String toCity,
    required double price,
  }) async {
    try {
      final now = DateTime.now();
      final route = PredefinedRoute(
        id: '',
        fromCity: fromCity.trim(),
        toCity: toCity.trim(),
        price: price,
        createdAt: now,
        updatedAt: now,
      );

      // Валидация
      final validation = PredefinedRouteHelper.validateRoute(
        route.fromCity, 
        route.toCity, 
        route.price
      );
      if (validation != null) {
        throw Exception('Validation error: $validation');
      }

      // Проверка дубликатов
      final existing = await findRoute(route.fromCity, route.toCity);
      if (existing != null) {
        throw Exception('Маршрут от ${route.fromCity} до ${route.toCity} уже существует');
      }

      if (kDebugMode) {
        print('RouteManagementServiceV2: Добавление маршрута ${route.fromCity} → ${route.toCity} (${route.price}₽)');
      }

      // 1. Сначала сохраняем в SQLite
      final routeId = await _localService.saveRoute(route);
      
      if (kDebugMode) {
        print('RouteManagementServiceV2: Маршрут сохранен в SQLite с ID: $routeId');
      }

      // 2. Попытка синхронизации с Firebase (не блокирующая)
      _syncRouteToFirebase(routeId);
      
      return routeId;
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка добавления маршрута - $e');
      }
      rethrow;
    }
  }

  /// Обновить маршрут
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
        print('RouteManagementServiceV2: Обновление маршрута ${route.id}');
      }

      // 1. Сначала обновляем в SQLite
      await _localService.updateRoute(route);
      
      if (kDebugMode) {
        print('RouteManagementServiceV2: Маршрут обновлен в SQLite');
      }

      // 2. Попытка синхронизации с Firebase (не блокирующая)
      _syncRouteToFirebase(route.id);
      
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка обновления маршрута - $e');
      }
      rethrow;
    }
  }

  /// Удалить маршрут
  Future<void> deleteRoute(String routeId) async {
    try {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Удаление маршрута $routeId');
      }

      // 1. Сначала удаляем из SQLite
      await _localService.deleteRoute(routeId);
      
      if (kDebugMode) {
        print('RouteManagementServiceV2: Маршрут удален из SQLite');
      }

      // 2. Попытка удаления из Firebase (не блокирующая)
      _deleteRouteFromFirebase(routeId);
      
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка удаления маршрута - $e');
      }
      rethrow;
    }
  }

  /// Пакетное добавление маршрутов
  Future<void> addRoutesBatch(List<PredefinedRoute> routes) async {
    try {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Пакетное добавление ${routes.length} маршрутов');
      }

      // Валидация всех маршрутов
      for (final route in routes) {
        final validation = PredefinedRouteHelper.validateRoute(
          route.fromCity, 
          route.toCity, 
          route.price
        );
        if (validation != null) {
          throw Exception('Ошибка валидации для маршрута ${route.fromCity} → ${route.toCity}: $validation');
        }
      }

      // 1. Сохраняем все в SQLite
      for (final route in routes) {
        await _localService.saveRoute(route);
      }
      
      if (kDebugMode) {
        print('RouteManagementServiceV2: Все маршруты сохранены в SQLite');
      }

      // 2. Попытка синхронизации с Firebase (не блокирующая)
      _syncAllUnsyncedRoutes();
      
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка пакетного добавления - $e');
      }
      rethrow;
    }
  }

  /// Получить статистику маршрутов
  Future<Map<String, int>> getRoutesStats() async {
    try {
      return await _localService.getRoutesStats();
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка получения статистики - $e');
      }
      return {'total_routes': 0, 'unsynced_routes': 0, 'unique_cities': 0, 'avg_price': 0};
    }
  }

  /// Синхронизировать все несинхронизированные маршруты с Firebase
  Future<void> syncAllUnsyncedRoutes() async {
    try {
      final unsyncedRoutes = await _localService.getUnsyncedRoutes();
      
      if (unsyncedRoutes.isEmpty) {
        if (kDebugMode) {
          print('RouteManagementServiceV2: Нет несинхронизированных маршрутов');
        }
        return;
      }

      if (kDebugMode) {
        print('RouteManagementServiceV2: Начинаем синхронизацию ${unsyncedRoutes.length} маршрутов с Firebase');
      }

      int synced = 0;
      for (final route in unsyncedRoutes) {
        try {
          await _collection.doc(route.id).set(route.toFirestore());
          await _localService.markAsSynced(route.id);
          synced++;
          
          if (kDebugMode) {
            print('RouteManagementServiceV2: Синхронизирован маршрут ${route.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('RouteManagementServiceV2: Ошибка синхронизации маршрута ${route.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('RouteManagementServiceV2: Синхронизация завершена: $synced из ${unsyncedRoutes.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка общей синхронизации - $e');
      }
    }
  }

  /// Загрузить маршруты из Firebase в SQLite (начальная синхронизация)
  Future<void> loadRoutesFromFirebase() async {
    try {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Загрузка маршрутов из Firebase...');
      }

      final querySnapshot = await _collection.orderBy('fromCity').get();
      
      final routes = querySnapshot.docs
          .map((doc) => PredefinedRoute.fromFirestore(
                doc.data() as Map<String, dynamic>, 
                doc.id))
          .toList();

      if (kDebugMode) {
        print('RouteManagementServiceV2: Загружено ${routes.length} маршрутов из Firebase');
      }

      // Сохраняем в SQLite и помечаем как синхронизированные
      for (final route in routes) {
        try {
          await _localService.saveRoute(route);
          await _localService.markAsSynced(route.id);
        } catch (e) {
          if (kDebugMode) {
            print('RouteManagementServiceV2: Ошибка сохранения маршрута ${route.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('RouteManagementServiceV2: Маршруты загружены из Firebase в SQLite');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка загрузки из Firebase - $e');
      }
    }
  }

  /// Внутренний метод: синхронизация отдельного маршрута с Firebase (не блокирующая)
  void _syncRouteToFirebase(String routeId) {
    Future.microtask(() async {
      try {
        final routes = await _localService.getAllRoutes();
        final route = routes.firstWhere((r) => r.id == routeId);
        
        await _collection.doc(routeId).set(route.toFirestore());
        await _localService.markAsSynced(routeId);
        
        if (kDebugMode) {
          print('RouteManagementServiceV2: Маршрут $routeId синхронизирован с Firebase');
        }
      } catch (e) {
        if (kDebugMode) {
          print('RouteManagementServiceV2: Ошибка синхронизации маршрута $routeId с Firebase: $e');
        }
      }
    });
  }

  /// Внутренний метод: удаление маршрута из Firebase (не блокирующее)
  void _deleteRouteFromFirebase(String routeId) {
    Future.microtask(() async {
      try {
        await _collection.doc(routeId).delete();
        
        if (kDebugMode) {
          print('RouteManagementServiceV2: Маршрут $routeId удален из Firebase');
        }
      } catch (e) {
        if (kDebugMode) {
          print('RouteManagementServiceV2: Ошибка удаления маршрута $routeId из Firebase: $e');
        }
      }
    });
  }

  /// Внутренний метод: синхронизация всех несинхронизированных маршрутов (не блокирующая)
  void _syncAllUnsyncedRoutes() {
    Future.microtask(() => syncAllUnsyncedRoutes());
  }
}