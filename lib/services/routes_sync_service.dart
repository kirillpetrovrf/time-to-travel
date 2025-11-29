import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/predefined_route.dart';
import 'local_routes_service.dart';
import 'route_management_service_v2.dart';

/// Сервис автоматической синхронизации маршрутов: SQLite → Firebase
class RoutesSyncService {
  static final RoutesSyncService instance = RoutesSyncService._();
  RoutesSyncService._();

  final LocalRoutesService _localService = LocalRoutesService.instance;
  final RouteManagementServiceV2 _routeService = RouteManagementServiceV2.instance;
  
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Начать автоматическую синхронизацию каждые 30 секунд
  void startAutoSync() {
    if (_syncTimer?.isActive == true) {
      if (kDebugMode) {
        print('🔄 [ROUTES_SYNC] Автоматическая синхронизация уже запущена');
      }
      return;
    }

    if (kDebugMode) {
      print('🔄 [ROUTES_SYNC] Запуск автоматической синхронизации маршрутов...');
    }

    // Первая синхронизация сразу после запуска
    syncNow();

    // Автоматическая синхронизация каждые 30 секунд
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncNow();
    });

    if (kDebugMode) {
      print('✅ [ROUTES_SYNC] Автоматическая синхронизация настроена');
    }
  }

  /// Остановить автоматическую синхронизацию
  void stopAutoSync() {
    if (_syncTimer?.isActive == true) {
      _syncTimer?.cancel();
      _syncTimer = null;
      
      if (kDebugMode) {
        print('⏹️ [ROUTES_SYNC] Автоматическая синхронизация остановлена');
      }
    }
  }

  /// Синхронизировать все несинхронизированные маршруты сейчас
  Future<void> syncNow() async {
    if (_isSyncing) {
      if (kDebugMode) {
        print('⏳ [ROUTES_SYNC] Синхронизация уже выполняется, пропускаем...');
      }
      return;
    }

    _isSyncing = true;

    try {
      final unsyncedRoutes = await _localService.getUnsyncedRoutes();
      
      if (unsyncedRoutes.isEmpty) {
        if (kDebugMode) {
          print('✅ [ROUTES_SYNC] Все маршруты синхронизированы');
        }
        return;
      }

      if (kDebugMode) {
        print('🔄 [ROUTES_SYNC] Найдено ${unsyncedRoutes.length} несинхронизированных маршрутов');
      }

      int synced = 0;
      int failed = 0;

      for (final route in unsyncedRoutes) {
        try {
          await _routeService._syncSingleRoute(route);
          synced++;
          
          if (kDebugMode) {
            print('✅ [ROUTES_SYNC] Синхронизирован: ${route.fromCity} → ${route.toCity}');
          }
        } catch (e) {
          failed++;
          
          if (kDebugMode) {
            print('❌ [ROUTES_SYNC] Ошибка синхронизации ${route.fromCity} → ${route.toCity}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('📊 [ROUTES_SYNC] Результат: синхронизировано $synced, ошибок $failed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ROUTES_SYNC] Критическая ошибка синхронизации: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Получить статистику синхронизации
  Future<Map<String, int>> getSyncStats() async {
    try {
      final stats = await _localService.getRoutesStats();
      return {
        'total_routes': stats['total_routes'] ?? 0,
        'synced_routes': (stats['total_routes'] ?? 0) - (stats['unsynced_routes'] ?? 0),
        'unsynced_routes': stats['unsynced_routes'] ?? 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ROUTES_SYNC] Ошибка получения статистики: $e');
      }
      return {
        'total_routes': 0,
        'synced_routes': 0,
        'unsynced_routes': 0,
      };
    }
  }

  /// Принудительная полная синхронизация всех маршрутов
  Future<void> forceSyncAll() async {
    if (kDebugMode) {
      print('🔄 [ROUTES_SYNC] Принудительная полная синхронизация...');
    }

    try {
      await _routeService.syncAllUnsyncedRoutes();
      
      if (kDebugMode) {
        print('✅ [ROUTES_SYNC] Принудительная синхронизация завершена');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ROUTES_SYNC] Ошибка принудительной синхронизации: $e');
      }
      rethrow;
    }
  }

  /// Загрузить маршруты из Firebase в локальную базу (первичная загрузка)
  Future<void> downloadFromFirebase() async {
    if (kDebugMode) {
      print('📥 [ROUTES_SYNC] Загрузка маршрутов из Firebase...');
    }

    try {
      await _routeService.loadRoutesFromFirebase();
      
      if (kDebugMode) {
        print('✅ [ROUTES_SYNC] Маршруты загружены из Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ROUTES_SYNC] Ошибка загрузки из Firebase: $e');
      }
      rethrow;
    }
  }
}

/// Расширение для RouteManagementServiceV2 чтобы получить доступ к внутреннему методу синхронизации
extension RoutesSyncServiceExtension on RouteManagementServiceV2 {
  Future<void> _syncSingleRoute(PredefinedRoute route) async {
    try {
      final collection = FirebaseFirestore.instance.collection('predefined_routes');
      
      await collection.doc(route.id).set(route.toFirestore());
      await LocalRoutesService.instance.markAsSynced(route.id);
      
      if (kDebugMode) {
        print('RouteManagementServiceV2: Маршрут ${route.id} синхронизирован с Firebase');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RouteManagementServiceV2: Ошибка синхронизации маршрута ${route.id} с Firebase: $e');
      }
      rethrow;
    }
  }
}