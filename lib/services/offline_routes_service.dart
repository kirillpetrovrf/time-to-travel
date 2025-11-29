import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/predefined_route.dart';

/// Сервис для работы с маршрутами в локальной базе SQLite (офлайн режим)
class OfflineRoutesService {
  static final OfflineRoutesService instance = OfflineRoutesService._();
  OfflineRoutesService._();

  static Database? _database;

  /// Получение базы данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Инициализация базы данных
  Future<Database> _initDatabase() async {
    print('📦 [SQLITE_ROUTES] Инициализация базы данных маршрутов...');
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'predefined_routes.db');

    print('📦 [SQLITE_ROUTES] Путь к БД: $path');

    return await openDatabase(
      path,
      version: 2, // Увеличиваем версию для миграции
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Создание таблиц
  Future<void> _onCreate(Database db, int version) async {
    print('🔧 [SQLITE_ROUTES] Создание таблицы predefined_routes...');
    
    await db.execute('''
      CREATE TABLE predefined_routes (
        id TEXT PRIMARY KEY,
        from_city TEXT NOT NULL,
        to_city TEXT NOT NULL,
        price REAL NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');
    
    print('✅ [SQLITE_ROUTES] Таблица создана успешно');
  }

  /// Миграция базы данных при обновлении версии
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 [SQLITE_ROUTES] Миграция БД с версии $oldVersion на $newVersion');
    
    if (oldVersion < 2) {
      // Пересоздаем таблицу с правильной структурой
      print('🗑️ [SQLITE_ROUTES] Удаляем старую таблицу...');
      await db.execute('DROP TABLE IF EXISTS predefined_routes');
      
      print('🔧 [SQLITE_ROUTES] Создаем новую таблицу с правильной структурой...');
      await db.execute('''
        CREATE TABLE predefined_routes (
          id TEXT PRIMARY KEY,
          from_city TEXT NOT NULL,
          to_city TEXT NOT NULL,
          price REAL NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0
        )
      ''');
      
      print('✅ [SQLITE_ROUTES] Миграция завершена успешно');
    }
  }

  /// Добавление маршрута в SQLite
  Future<void> addRoute(PredefinedRoute route) async {
    print('💾 [SQLITE_ROUTES] Сохранение маршрута: ${route.fromCity} → ${route.toCity} (${route.price}₽)');
    
    try {
      final db = await database;
      
      // Генерируем уникальный ID, если он пустой
      String routeId = route.id;
      if (routeId.isEmpty) {
        routeId = 'route_${DateTime.now().millisecondsSinceEpoch}_${route.fromCity.toLowerCase()}_${route.toCity.toLowerCase()}';
        print('🔧 [SQLITE_ROUTES] Сгенерирован ID: $routeId');
      }
      
      await db.insert('predefined_routes', {
        'id': routeId,
        'from_city': route.fromCity,
        'to_city': route.toCity,
        'price': route.price,
        'created_at': route.createdAt.toIso8601String(),
        'updated_at': route.updatedAt.toIso8601String(),
        'is_synced': 0, // Новый маршрут не синхронизирован с Firebase
      });
      
      print('✅ [SQLITE_ROUTES] Маршрут сохранен в SQLite');
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка сохранения маршрута: $e');
      rethrow;
    }
  }

  /// Получение всех маршрутов из SQLite
  Future<List<PredefinedRoute>> getAllRoutes() async {
    print('📄 [SQLITE_ROUTES] Загрузка всех маршрутов...');
    
    try {
      final db = await database;
      final maps = await db.query('predefined_routes', orderBy: 'from_city ASC');
      
      final routes = maps.map((map) => PredefinedRoute(
        id: map['id'] as String,
        fromCity: map['from_city'] as String,
        toCity: map['to_city'] as String,
        price: map['price'] as double,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      )).toList();
      
      print('✅ [SQLITE_ROUTES] Загружено ${routes.length} маршрутов');
      return routes;
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка загрузки маршрутов: $e');
      return [];
    }
  }

  /// Поиск маршрута по направлению
  Future<PredefinedRoute?> findRoute(String fromCity, String toCity) async {
    print('🔍 [SQLITE_ROUTES] Поиск маршрута: $fromCity → $toCity');
    
    try {
      final db = await database;
      final maps = await db.query(
        'predefined_routes',
        where: 'LOWER(from_city) = ? AND LOWER(to_city) = ?',
        whereArgs: [fromCity.toLowerCase().trim(), toCity.toLowerCase().trim()],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        print('⚠️ [SQLITE_ROUTES] Маршрут не найден');
        return null;
      }
      
      final map = maps.first;
      final route = PredefinedRoute(
        id: map['id'] as String,
        fromCity: map['from_city'] as String,
        toCity: map['to_city'] as String,
        price: map['price'] as double,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
      
      print('✅ [SQLITE_ROUTES] Маршрут найден: ${route.price}₽');
      return route;
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка поиска маршрута: $e');
      return null;
    }
  }

  /// Обновление маршрута в SQLite
  Future<void> updateRoute(PredefinedRoute route) async {
    print('🔄 [SQLITE_ROUTES] Обновление маршрута: ${route.id}');
    
    try {
      final db = await database;
      await db.update(
        'predefined_routes',
        {
          'from_city': route.fromCity,
          'to_city': route.toCity,
          'price': route.price,
          'updated_at': route.updatedAt.toIso8601String(),
          'is_synced': 0, // Маршрут изменен, нужна синхронизация
        },
        where: 'id = ?',
        whereArgs: [route.id],
      );
      
      print('✅ [SQLITE_ROUTES] Маршрут обновлен');
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка обновления маршрута: $e');
      rethrow;
    }
  }

  /// Удаление маршрута из SQLite
  Future<void> deleteRoute(String routeId) async {
    print('🗑️ [SQLITE_ROUTES] Удаление маршрута: $routeId');
    
    try {
      final db = await database;
      await db.delete(
        'predefined_routes',
        where: 'id = ?',
        whereArgs: [routeId],
      );
      
      print('✅ [SQLITE_ROUTES] Маршрут удален');
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка удаления маршрута: $e');
      rethrow;
    }
  }

  /// Получение несинхронизированных маршрутов (для загрузки в Firebase)
  Future<List<PredefinedRoute>> getUnsyncedRoutes() async {
    print('🔄 [SQLITE_ROUTES] Загрузка несинхронизированных маршрутов...');
    
    try {
      final db = await database;
      final maps = await db.query(
        'predefined_routes',
        where: 'is_synced = ?',
        whereArgs: [0],
        orderBy: 'updated_at ASC',
      );
      
      final routes = maps.map((map) => PredefinedRoute(
        id: map['id'] as String,
        fromCity: map['from_city'] as String,
        toCity: map['to_city'] as String,
        price: map['price'] as double,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      )).toList();
      
      print('✅ [SQLITE_ROUTES] Найдено ${routes.length} несинхронизированных маршрутов');
      return routes;
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка загрузки несинхронизированных маршрутов: $e');
      return [];
    }
  }

  /// Пометить маршрут как синхронизированный
  Future<void> markAsSynced(String routeId) async {
    print('✅ [SQLITE_ROUTES] Помечаем маршрут как синхронизированный: $routeId');
    
    try {
      final db = await database;
      await db.update(
        'predefined_routes',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [routeId],
      );
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка маркировки синхронизации: $e');
    }
  }

  /// Синхронизация маршрутов из Firebase в SQLite
  Future<void> syncFromFirebase(List<PredefinedRoute> firebaseRoutes) async {
    print('🔄 [SQLITE_ROUTES] Синхронизация из Firebase (${firebaseRoutes.length} маршрутов)...');
    
    try {
      final db = await database;
      
      // Очищаем синхронизированные маршруты
      await db.delete('predefined_routes', where: 'is_synced = ?', whereArgs: [1]);
      
      // Добавляем новые маршруты из Firebase
      for (final route in firebaseRoutes) {
        await db.insert('predefined_routes', {
          'id': route.id,
          'from_city': route.fromCity,
          'to_city': route.toCity,
          'price': route.price,
          'created_at': route.createdAt.toIso8601String(),
          'updated_at': route.updatedAt.toIso8601String(),
          'is_synced': 1, // Маршрут синхронизирован с Firebase
        });
      }
      
      print('✅ [SQLITE_ROUTES] Синхронизация завершена');
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка синхронизации: $e');
      rethrow;
    }
  }

  /// Статистика маршрутов
  Future<Map<String, int>> getRoutesStats() async {
    print('📊 [SQLITE_ROUTES] Получение статистики маршрутов...');
    
    try {
      final db = await database;
      
      // Общее количество маршрутов
      final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM predefined_routes');
      final totalRoutes = totalResult.first['count'] as int;
      
      // Уникальные города
      final citiesResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT city) as count FROM (
          SELECT from_city as city FROM predefined_routes
          UNION
          SELECT to_city as city FROM predefined_routes
        )
      ''');
      final uniqueCities = citiesResult.first['count'] as int;
      
      // Средняя цена
      final priceResult = await db.rawQuery('SELECT AVG(price) as avg_price FROM predefined_routes');
      final avgPrice = (priceResult.first['avg_price'] as double? ?? 0.0).round();
      
      // Несинхронизированные маршруты
      final unsyncedResult = await db.rawQuery('SELECT COUNT(*) as count FROM predefined_routes WHERE is_synced = 0');
      final unsyncedRoutes = unsyncedResult.first['count'] as int;
      
      final stats = {
        'total_routes': totalRoutes,
        'unique_cities': uniqueCities,
        'avg_price': avgPrice,
        'unsynced_routes': unsyncedRoutes,
      };
      
      print('✅ [SQLITE_ROUTES] Статистика: $stats');
      return stats;
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка получения статистики: $e');
      return {'total_routes': 0, 'unique_cities': 0, 'avg_price': 0, 'unsynced_routes': 0};
    }
  }

  /// Очистка базы данных (для тестирования)
  Future<void> clearDatabase() async {
    print('🧹 [SQLITE_ROUTES] Очистка базы данных...');
    
    try {
      final db = await database;
      await db.delete('predefined_routes');
      print('✅ [SQLITE_ROUTES] База данных очищена');
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка очистки базы данных: $e');
    }
  }
}