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

    _database = await openDatabase(
      path,
      version: 3, // Увеличиваем версию, чтобы избежать старой миграции
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    return _database!; // ✅ Возвращаем базу данных
  }

  /// Создание таблиц
  Future<void> _onCreate(Database db, int version) async {
    print('🔧 [SQLITE_ROUTES] Создание таблицы predefined_routes...');
    
    await db.execute('''
      CREATE TABLE predefined_routes (
        id TEXT PRIMARY KEY,
        fromCity TEXT NOT NULL,
        toCity TEXT NOT NULL,
        price REAL NOT NULL,
        groupId TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isSynced INTEGER DEFAULT 0
      )
    ''');
    
    print('✅ [SQLITE_ROUTES] Таблица создана успешно');
  }

  /// Миграция базы данных при обновлении версии
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('🔄 [SQLITE_ROUTES] Миграция БД с версии $oldVersion на $newVersion');
    
    if (oldVersion < 2) {
      print('� [SQLITE_ROUTES] Сохраняем существующие маршруты перед миграцией...');
      
      // 1. Читаем ВСЕ существующие маршруты из старой таблицы
      final oldRoutes = await db.query('predefined_routes');
      print('� [SQLITE_ROUTES] Найдено ${oldRoutes.length} маршрутов для миграции');
      
      // 2. Создаем временную таблицу с новой структурой
      print('🔧 [SQLITE_ROUTES] Создаем временную таблицу...');
      await db.execute('''
        CREATE TABLE predefined_routes_temp (
          id TEXT PRIMARY KEY,
          fromCity TEXT NOT NULL,
          toCity TEXT NOT NULL,
          price REAL NOT NULL,
          groupId TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          isSynced INTEGER DEFAULT 0
        )
      ''');
      
      // 3. Копируем данные из старой таблицы в новую, конвертируя форматы
      print('📋 [SQLITE_ROUTES] Копируем данные в новую структуру...');
      for (final oldRoute in oldRoutes) {
        try {
          // Конвертируем старые названия колонок и форматы
          final fromCity = oldRoute['from_city'] as String;
          final toCity = oldRoute['to_city'] as String;
          final price = (oldRoute['price'] as num).toDouble();
          
          // Конвертируем даты из ISO8601 строк в milliseconds
          DateTime createdAt;
          DateTime updatedAt;
          
          try {
            createdAt = DateTime.parse(oldRoute['created_at'] as String);
          } catch (e) {
            print('⚠️ Ошибка парсинга created_at для $fromCity → $toCity: $e');
            createdAt = DateTime.now();
          }
          
          try {
            updatedAt = DateTime.parse(oldRoute['updated_at'] as String);
          } catch (e) {
            print('⚠️ Ошибка парсинга updated_at для $fromCity → $toCity: $e');
            updatedAt = DateTime.now();
          }
          
          await db.insert('predefined_routes_temp', {
            'id': oldRoute['id'],
            'fromCity': fromCity,
            'toCity': toCity,
            'price': price,
            'groupId': null, // Старые маршруты не имели groupId
            'createdAt': createdAt.millisecondsSinceEpoch,
            'updatedAt': updatedAt.millisecondsSinceEpoch,
            'isSynced': oldRoute['is_synced'] ?? 0,
          });
        } catch (e) {
          print('❌ [SQLITE_ROUTES] Ошибка миграции маршрута: $e');
          print('   Данные: $oldRoute');
        }
      }
      
      // 4. Удаляем старую таблицу
      print('🗑️ [SQLITE_ROUTES] Удаляем старую таблицу...');
      await db.execute('DROP TABLE predefined_routes');
      
      // 5. Переименовываем временную таблицу
      print('🔄 [SQLITE_ROUTES] Переименовываем временную таблицу...');
      await db.execute('ALTER TABLE predefined_routes_temp RENAME TO predefined_routes');
      
      print('✅ [SQLITE_ROUTES] Миграция завершена! Сохранено ${oldRoutes.length} маршрутов');
    }
  }

  /// Добавление маршрута в SQLite
  Future<void> addRoute(PredefinedRoute route) async {
    print('💾 [SQLITE_ROUTES] Сохранение маршрута: ${route.fromCity} → ${route.toCity} (${route.price}₽)');
    print('🔍 [DEBUG] OfflineRoutesService.addRoute():');
    print('   route.groupId: ${route.groupId}');
    
    try {
      final db = await database;
      
      // Генерируем уникальный ID, если он пустой
      String routeId = route.id;
      if (routeId.isEmpty) {
        routeId = 'route_${DateTime.now().millisecondsSinceEpoch}_${route.fromCity.toLowerCase()}_${route.toCity.toLowerCase()}';
        print('🔧 [SQLITE_ROUTES] Сгенерирован ID: $routeId');
      }
      
      final map = {
        'id': routeId,
        'fromCity': route.fromCity,
        'toCity': route.toCity,
        'price': route.price,
        'groupId': route.groupId, // Добавляем groupId
        'createdAt': route.createdAt.millisecondsSinceEpoch,
        'updatedAt': route.updatedAt.millisecondsSinceEpoch,
        'isSynced': 0, // Новый маршрут не синхронизирован с Firebase
      };
      
      print('🔍 [DEBUG] SQL map to insert: $map');
      
      await db.insert('predefined_routes', map);
      
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
      final maps = await db.query('predefined_routes', orderBy: 'fromCity ASC');
      
      final routes = maps.map((map) {
        final groupId = map['groupId'] as String?;
        
        // Логируем маршруты с groupId для отладки
        if (groupId != null && groupId.isNotEmpty) {
          print('   📌 Маршрут с groupId "$groupId": ${map['fromCity']} → ${map['toCity']}');
        }
        
        return PredefinedRoute(
          id: map['id'] as String,
          fromCity: map['fromCity'] as String,
          toCity: map['toCity'] as String,
          price: (map['price'] as num).toDouble(),
          groupId: groupId,
          createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
        );
      }).toList();
      
      print('✅ [SQLITE_ROUTES] Загружено ${routes.length} маршрутов');
      return routes;
    } catch (e) {
      print('❌ [SQLITE_ROUTES] Ошибка загрузки маршрутов: $e');
      return [];
    }
  }

  /// Поиск маршрута по направлению (двусторонний - работает в обе стороны)
  Future<PredefinedRoute?> findRoute(String fromCity, String toCity) async {
    print('🔍 [SQLITE_ROUTES] Поиск маршрута: $fromCity → $toCity (двусторонний)');
    
    final fromNormalized = fromCity.toLowerCase().trim();
    final toNormalized = toCity.toLowerCase().trim();
    
    try {
      final db = await database;
      
      // Ищем маршрут в обоих направлениях (A→B или B→A)
      final maps = await db.query(
        'predefined_routes',
        where: '(LOWER(fromCity) = ? AND LOWER(toCity) = ?) OR (LOWER(fromCity) = ? AND LOWER(toCity) = ?)',
        whereArgs: [fromNormalized, toNormalized, toNormalized, fromNormalized],
        limit: 1,
      );
      
      if (maps.isEmpty) {
        print('⚠️ [SQLITE_ROUTES] Маршрут не найден (проверены оба направления)');
        return null;
      }
      
      final map = maps.first;
      final route = PredefinedRoute(
        id: map['id'] as String,
        fromCity: map['fromCity'] as String,
        toCity: map['toCity'] as String,
        price: (map['price'] as num).toDouble(),
        groupId: map['groupId'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      );
      
      // Определяем направление найденного маршрута
      final isReverse = route.fromCity.toLowerCase() != fromNormalized;
      if (isReverse) {
        print('✅ [SQLITE_ROUTES] Найден обратный маршрут: ${route.fromCity} → ${route.toCity} = ${route.price}₽');
        print('   🔄 Применяется для: $fromCity → $toCity');
      } else {
        print('✅ [SQLITE_ROUTES] Найден прямой маршрут: ${route.price}₽');
      }
      
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
          'fromCity': route.fromCity,
          'toCity': route.toCity,
          'price': route.price,
          'groupId': route.groupId,
          'updatedAt': route.updatedAt.millisecondsSinceEpoch,
          'isSynced': 0, // Маршрут изменен, нужна синхронизация
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
        where: 'isSynced = ?',
        whereArgs: [0],
        orderBy: 'updatedAt ASC',
      );
      
      final routes = maps.map((map) => PredefinedRoute(
        id: map['id'] as String,
        fromCity: map['fromCity'] as String,
        toCity: map['toCity'] as String,
        price: (map['price'] as num).toDouble(),
        groupId: map['groupId'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
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
        {'isSynced': 1},
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
          'fromCity': route.fromCity,
          'toCity': route.toCity,
          'price': route.price,
          'groupId': route.groupId,
          'createdAt': route.createdAt.millisecondsSinceEpoch,
          'updatedAt': route.updatedAt.millisecondsSinceEpoch,
          'isSynced': 1, // Маршрут синхронизирован с Firebase
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
          SELECT fromCity as city FROM predefined_routes
          UNION
          SELECT toCity as city FROM predefined_routes
        )
      ''');
      final uniqueCities = citiesResult.first['count'] as int;
      
      // Средняя цена
      final priceResult = await db.rawQuery('SELECT AVG(price) as avg_price FROM predefined_routes');
      final avgPrice = (priceResult.first['avg_price'] as double? ?? 0.0).round();
      
      // Несинхронизированные маршруты
      final unsyncedResult = await db.rawQuery('SELECT COUNT(*) as count FROM predefined_routes WHERE isSynced = 0');
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