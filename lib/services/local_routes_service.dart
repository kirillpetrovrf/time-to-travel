import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/predefined_route.dart';

/// Сервис для работы с маршрутами в локальной базе SQLite 
/// (офлайн-первый подход с синхронизацией в Firebase)
class LocalRoutesService {
  static final LocalRoutesService instance = LocalRoutesService._();
  LocalRoutesService._();

  static Database? _database;

  /// Получение базы данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Инициализация базы данных
  Future<Database> _initDatabase() async {
    if (kDebugMode) {
      print('📦 [LOCAL_ROUTES] Инициализация базы данных...');
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'predefined_routes.db');

    if (kDebugMode) {
      print('📦 [LOCAL_ROUTES] Путь к БД: $path');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        if (kDebugMode) {
          print('📦 [LOCAL_ROUTES] Создание таблицы predefined_routes...');
        }
        
        await db.execute('''
          CREATE TABLE predefined_routes (
            id TEXT PRIMARY KEY,
            fromCity TEXT NOT NULL,
            toCity TEXT NOT NULL,
            price REAL NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            isSynced INTEGER NOT NULL DEFAULT 0
          )
        ''');
        
        // Создаем индекс для быстрого поиска по городам
        await db.execute('''
          CREATE INDEX idx_cities ON predefined_routes (fromCity, toCity)
        ''');
        
        if (kDebugMode) {
          print('✅ [LOCAL_ROUTES] Таблица predefined_routes создана');
        }
      },
    );
  }

  /// Сохранение маршрута в локальную базу
  Future<String> saveRoute(PredefinedRoute route) async {
    if (kDebugMode) {
      print('💾 [LOCAL_ROUTES] Сохранение маршрута: ${route.fromCity} → ${route.toCity}');
    }
    
    try {
      final db = await database;
      
      // Генерируем ID если его нет
      final routeId = route.id.isEmpty 
          ? 'route_${DateTime.now().millisecondsSinceEpoch}'
          : route.id;
      
      final routeWithId = route.copyWith(id: routeId);
      
      await db.insert(
        'predefined_routes',
        _routeToMap(routeWithId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      if (kDebugMode) {
        print('✅ [LOCAL_ROUTES] Маршрут сохранен: $routeId');
      }
      
      return routeId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка сохранения маршрута: $e');
      }
      rethrow;
    }
  }

  /// Получение всех маршрутов из локальной базы
  Future<List<PredefinedRoute>> getAllRoutes() async {
    if (kDebugMode) {
      print('📄 [LOCAL_ROUTES] Загрузка всех маршрутов...');
    }
    
    try {
      final db = await database;
      final maps = await db.query(
        'predefined_routes', 
        orderBy: 'fromCity, toCity'
      );
      
      final routes = maps.map((map) => _mapToRoute(map)).toList();
      
      if (kDebugMode) {
        print('✅ [LOCAL_ROUTES] Загружено ${routes.length} маршрутов');
      }
      return routes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка загрузки маршрутов: $e');
      }
      return [];
    }
  }

  /// Поиск маршрута по городам
  Future<PredefinedRoute?> findRoute(String fromCity, String toCity) async {
    if (kDebugMode) {
      print('🔍 [LOCAL_ROUTES] Поиск маршрута: $fromCity → $toCity');
    }
    
    try {
      final routes = await getAllRoutes();
      final route = PredefinedRouteHelper.findRoute(routes, fromCity, toCity);
      
      if (route != null && kDebugMode) {
        print('✅ [LOCAL_ROUTES] Маршрут найден: ${route.fromCity} → ${route.toCity} (${route.price}₽)');
      } else if (kDebugMode) {
        print('⚠️ [LOCAL_ROUTES] Маршрут не найден: $fromCity → $toCity');
      }
      
      return route;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка поиска маршрута: $e');
      }
      return null;
    }
  }

  /// Обновление маршрута
  Future<void> updateRoute(PredefinedRoute route) async {
    if (kDebugMode) {
      print('🔄 [LOCAL_ROUTES] Обновление маршрута: ${route.id}');
    }
    
    try {
      final db = await database;
      final updatedRoute = route.copyWith(
        updatedAt: DateTime.now(),
        // Сбрасываем флаг синхронизации при изменении
      );
      
      await db.update(
        'predefined_routes',
        _routeToMap(updatedRoute),
        where: 'id = ?',
        whereArgs: [route.id],
      );
      
      if (kDebugMode) {
        print('✅ [LOCAL_ROUTES] Маршрут обновлен: ${route.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка обновления маршрута: $e');
      }
      rethrow;
    }
  }

  /// Удаление маршрута
  Future<void> deleteRoute(String routeId) async {
    if (kDebugMode) {
      print('🗑️ [LOCAL_ROUTES] Удаление маршрута: $routeId');
    }
    
    try {
      final db = await database;
      await db.delete(
        'predefined_routes',
        where: 'id = ?',
        whereArgs: [routeId],
      );
      
      if (kDebugMode) {
        print('✅ [LOCAL_ROUTES] Маршрут удален: $routeId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка удаления маршрута: $e');
      }
      rethrow;
    }
  }

  /// Получение несинхронизированных маршрутов
  Future<List<PredefinedRoute>> getUnsyncedRoutes() async {
    if (kDebugMode) {
      print('🔄 [LOCAL_ROUTES] Загрузка несинхронизированных маршрутов...');
    }
    
    try {
      final db = await database;
      final maps = await db.query(
        'predefined_routes',
        where: 'isSynced = ?',
        whereArgs: [0],
        orderBy: 'createdAt ASC',
      );
      
      final routes = maps.map((map) => _mapToRoute(map)).toList();
      
      if (kDebugMode) {
        print('✅ [LOCAL_ROUTES] Найдено ${routes.length} несинхронизированных маршрутов');
      }
      return routes;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка загрузки несинхронизированных маршрутов: $e');
      }
      return [];
    }
  }

  /// Пометить маршрут как синхронизированный
  Future<void> markAsSynced(String routeId) async {
    if (kDebugMode) {
      print('✅ [LOCAL_ROUTES] Помечаем маршрут как синхронизированный: $routeId');
    }
    
    try {
      final db = await database;
      await db.update(
        'predefined_routes',
        {'isSynced': 1},
        where: 'id = ?',
        whereArgs: [routeId],
      );
      
      if (kDebugMode) {
        print('✅ [LOCAL_ROUTES] Маршрут $routeId помечен как синхронизированный');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка обновления флага синхронизации: $e');
      }
      rethrow;
    }
  }

  /// Проверка существования маршрута
  Future<bool> routeExists(String fromCity, String toCity) async {
    try {
      final route = await findRoute(fromCity, toCity);
      return route != null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка проверки существования маршрута: $e');
      }
      return false;
    }
  }

  /// Получение статистики маршрутов
  Future<Map<String, int>> getRoutesStats() async {
    try {
      final db = await database;
      
      // Общее количество маршрутов
      final totalResult = await db.rawQuery('SELECT COUNT(*) FROM predefined_routes');
      final total = Sqflite.firstIntValue(totalResult) ?? 0;
      
      // Количество несинхронизированных
      final unsyncedResult = await db.rawQuery(
        'SELECT COUNT(*) FROM predefined_routes WHERE isSynced = 0'
      );
      final unsynced = Sqflite.firstIntValue(unsyncedResult) ?? 0;
      
      // Уникальные города
      final citiesResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT city) FROM (
          SELECT fromCity as city FROM predefined_routes
          UNION
          SELECT toCity as city FROM predefined_routes
        )
      ''');
      final uniqueCities = Sqflite.firstIntValue(citiesResult) ?? 0;
      
      // Средняя цена
      final avgPriceResult = await db.rawQuery('SELECT AVG(price) FROM predefined_routes');
      final avgPriceDouble = avgPriceResult.first['AVG(price)'];
      final avgPrice = avgPriceDouble != null ? (avgPriceDouble as num).round() : 0;

      final stats = {
        'total_routes': total,
        'unsynced_routes': unsynced,
        'unique_cities': uniqueCities,
        'avg_price': avgPrice,
      };

      if (kDebugMode) {
        print('📊 [LOCAL_ROUTES] Статистика: $stats');
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка получения статистики: $e');
      }
      return {
        'total_routes': 0,
        'unsynced_routes': 0,
        'unique_cities': 0,
        'avg_price': 0,
      };
    }
  }

  /// Очистка всех маршрутов (для тестирования)
  Future<void> clearAllRoutes() async {
    if (kDebugMode) {
      print('🗑️ [LOCAL_ROUTES] Очистка всех маршрутов...');
    }
    
    try {
      final db = await database;
      await db.delete('predefined_routes');
      
      if (kDebugMode) {
        print('✅ [LOCAL_ROUTES] Все маршруты удалены');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [LOCAL_ROUTES] Ошибка очистки маршрутов: $e');
      }
      rethrow;
    }
  }

  /// Конвертация PredefinedRoute в Map для SQLite
  Map<String, dynamic> _routeToMap(PredefinedRoute route) {
    return {
      'id': route.id,
      'fromCity': route.fromCity,
      'toCity': route.toCity,
      'price': route.price,
      'createdAt': route.createdAt.millisecondsSinceEpoch,
      'updatedAt': route.updatedAt.millisecondsSinceEpoch,
      'isSynced': 0, // По умолчанию маршрут не синхронизирован
    };
  }

  /// Конвертация Map из SQLite в PredefinedRoute
  PredefinedRoute _mapToRoute(Map<String, dynamic> map) {
    return PredefinedRoute(
      id: map['id'],
      fromCity: map['fromCity'],
      toCity: map['toCity'],
      price: map['price'].toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}