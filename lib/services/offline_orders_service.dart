import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/taxi_order.dart';

/// Сервис для работы с заказами в локальной базе SQLite (офлайн режим для тестирования)
class OfflineOrdersService {
  static final OfflineOrdersService instance = OfflineOrdersService._();
  OfflineOrdersService._();

  static Database? _database;

  /// Получение базы данных
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Инициализация базы данных
  Future<Database> _initDatabase() async {
    print('📦 [SQLITE] Инициализация базы данных...');
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'taxi_orders.db');

    print('📦 [SQLITE] Путь к БД: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        print('📦 [SQLITE] Создание таблицы orders...');
        
        await db.execute('''
          CREATE TABLE orders (
            orderId TEXT PRIMARY KEY,
            timestamp INTEGER NOT NULL,
            fromLat REAL NOT NULL,
            fromLon REAL NOT NULL,
            toLat REAL NOT NULL,
            toLon REAL NOT NULL,
            fromAddress TEXT NOT NULL,
            toAddress TEXT NOT NULL,
            distanceKm REAL NOT NULL,
            rawPrice REAL NOT NULL,
            finalPrice REAL NOT NULL,
            baseCost REAL NOT NULL,
            costPerKm REAL NOT NULL,
            status TEXT NOT NULL,
            clientName TEXT,
            clientPhone TEXT
          )
        ''');
        
        print('✅ [SQLITE] Таблица orders создана');
      },
    );
  }

  /// Сохранение заказа
  Future<void> saveOrder(TaxiOrder order) async {
    print('💾 [SQLITE] Сохранение заказа: ${order.orderId}');
    
    try {
      final db = await database;
      await db.insert(
        'orders',
        order.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('✅ [SQLITE] Заказ сохранен: ${order.orderId}');
    } catch (e) {
      print('❌ [SQLITE] Ошибка сохранения заказа: $e');
      rethrow;
    }
  }

  /// Получение всех заказов
  Future<List<TaxiOrder>> getAllOrders() async {
    print('📄 [SQLITE] Загрузка всех заказов...');
    
    try {
      final db = await database;
      final maps = await db.query('orders', orderBy: 'timestamp DESC');
      
      final orders = maps.map((map) => TaxiOrder.fromMap(map)).toList();
      
      print('✅ [SQLITE] Загружено ${orders.length} заказов');
      return orders;
    } catch (e) {
      print('❌ [SQLITE] Ошибка загрузки заказов: $e');
      return [];
    }
  }

  /// Получение заказа по ID
  Future<TaxiOrder?> getOrderById(String orderId) async {
    print('🔍 [SQLITE] Поиск заказа: $orderId');
    
    try {
      final db = await database;
      final maps = await db.query(
        'orders',
        where: 'orderId = ?',
        whereArgs: [orderId],
      );
      
      if (maps.isEmpty) {
        print('⚠️ [SQLITE] Заказ не найден: $orderId');
        return null;
      }
      
      final order = TaxiOrder.fromMap(maps.first);
      print('✅ [SQLITE] Заказ найден: $orderId');
      return order;
    } catch (e) {
      print('❌ [SQLITE] Ошибка поиска заказа: $e');
      return null;
    }
  }

  /// Обновление статуса заказа
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    print('🔄 [SQLITE] Обновление статуса заказа $orderId → $newStatus');
    
    try {
      final db = await database;
      await db.update(
        'orders',
        {'status': newStatus},
        where: 'orderId = ?',
        whereArgs: [orderId],
      );
      
      print('✅ [SQLITE] Статус обновлен: $orderId → $newStatus');
    } catch (e) {
      print('❌ [SQLITE] Ошибка обновления статуса: $e');
      rethrow;
    }
  }

  /// Удаление заказа
  Future<void> deleteOrder(String orderId) async {
    print('🗑️ [SQLITE] Удаление заказа: $orderId');
    
    try {
      final db = await database;
      await db.delete(
        'orders',
        where: 'orderId = ?',
        whereArgs: [orderId],
      );
      
      print('✅ [SQLITE] Заказ удален: $orderId');
    } catch (e) {
      print('❌ [SQLITE] Ошибка удаления заказа: $e');
      rethrow;
    }
  }

  /// Очистка всех заказов (для тестирования)
  Future<void> clearAllOrders() async {
    print('🗑️ [SQLITE] Очистка всех заказов...');
    
    try {
      final db = await database;
      await db.delete('orders');
      
      print('✅ [SQLITE] Все заказы удалены');
    } catch (e) {
      print('❌ [SQLITE] Ошибка очистки заказов: $e');
      rethrow;
    }
  }

  /// Получение количества заказов
  Future<int> getOrdersCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) FROM orders');
      final count = Sqflite.firstIntValue(result) ?? 0;
      
      print('📊 [SQLITE] Всего заказов в БД: $count');
      return count;
    } catch (e) {
      print('❌ [SQLITE] Ошибка подсчета заказов: $e');
      return 0;
    }
  }
}
