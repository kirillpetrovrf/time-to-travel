import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../models/route_group.dart';

/// Сервис для работы с группами маршрутов в локальной базе SQLite
/// (полная аналогия с LocalRoutesService для маршрутов)
class LocalRouteGroupsService {
  static final LocalRouteGroupsService instance = LocalRouteGroupsService._();
  LocalRouteGroupsService._();

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
      print('📦 [SQLITE_GROUPS] Инициализация базы данных...');
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'route_groups.db');

    if (kDebugMode) {
      print('📦 [SQLITE_GROUPS] Путь к БД: $path');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        if (kDebugMode) {
          print('📦 [SQLITE_GROUPS] Создание таблицы route_groups...');
        }
        
        await db.execute('''
          CREATE TABLE route_groups (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            basePrice REAL NOT NULL,
            originCities TEXT NOT NULL,
            destinationCities TEXT NOT NULL,
            autoGenerateReverse INTEGER NOT NULL DEFAULT 1,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        ''');
        
        // Создаем индекс для быстрого поиска по имени
        await db.execute('''
          CREATE INDEX idx_group_name ON route_groups (name)
        ''');
        
        if (kDebugMode) {
          print('✅ [SQLITE_GROUPS] Таблица route_groups создана');
        }
      },
    );
  }

  /// Сохранение группы в локальную базу
  Future<String> saveGroup(RouteGroup group) async {
    if (kDebugMode) {
      print('💾 [SQLITE_GROUPS] Сохранение группы: ${group.name}');
    }
    
    try {
      final db = await database;
      
      // Генерируем ID если его нет
      final groupId = group.id.isEmpty 
          ? 'group_${DateTime.now().millisecondsSinceEpoch}'
          : group.id;
      
      final groupWithId = group.copyWith(id: groupId);
      
      await db.insert(
        'route_groups',
        _groupToMap(groupWithId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      if (kDebugMode) {
        print('✅ [SQLITE_GROUPS] Группа сохранена: $groupId');
      }
      
      return groupId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SQLITE_GROUPS] Ошибка сохранения группы: $e');
      }
      rethrow;
    }
  }

  /// Получение всех групп
  Future<List<RouteGroup>> getAllGroups() async {
    if (kDebugMode) {
      print('📄 [SQLITE_GROUPS] Загрузка всех групп...');
    }
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'route_groups',
        orderBy: 'name ASC',
      );

      final groups = maps.map((map) => _mapToGroup(map)).toList();
      
      if (kDebugMode) {
        print('✅ [SQLITE_GROUPS] Загружено ${groups.length} групп');
      }
      
      return groups;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SQLITE_GROUPS] Ошибка загрузки групп: $e');
      }
      return [];
    }
  }

  /// Получение группы по ID
  Future<RouteGroup?> getGroupById(String id) async {
    if (kDebugMode) {
      print('🔍 [SQLITE_GROUPS] Поиск группы по ID: $id');
    }
    
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'route_groups',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) {
        if (kDebugMode) {
          print('⚠️ [SQLITE_GROUPS] Группа не найдена');
        }
        return null;
      }

      final group = _mapToGroup(maps.first);
      if (kDebugMode) {
        print('✅ [SQLITE_GROUPS] Группа найдена: ${group.name}');
      }
      
      return group;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SQLITE_GROUPS] Ошибка поиска группы: $e');
      }
      return null;
    }
  }

  /// Обновление группы
  Future<void> updateGroup(RouteGroup group) async {
    if (kDebugMode) {
      print('🔄 [SQLITE_GROUPS] Обновление группы: ${group.name}');
    }
    
    try {
      final db = await database;
      final updatedGroup = group.copyWith(
        updatedAt: DateTime.now(),
      );
      
      await db.update(
        'route_groups',
        _groupToMap(updatedGroup),
        where: 'id = ?',
        whereArgs: [group.id],
      );
      
      if (kDebugMode) {
        print('✅ [SQLITE_GROUPS] Группа обновлена');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SQLITE_GROUPS] Ошибка обновления группы: $e');
      }
      rethrow;
    }
  }

  /// Удаление группы
  Future<void> deleteGroup(String id) async {
    if (kDebugMode) {
      print('🗑️ [SQLITE_GROUPS] Удаление группы: $id');
    }
    
    try {
      final db = await database;
      await db.delete(
        'route_groups',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (kDebugMode) {
        print('✅ [SQLITE_GROUPS] Группа удалена');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SQLITE_GROUPS] Ошибка удаления группы: $e');
      }
      rethrow;
    }
  }

  /// Удаление всех групп
  Future<void> deleteAllGroups() async {
    if (kDebugMode) {
      print('🗑️ [SQLITE_GROUPS] Удаление всех групп...');
    }
    
    try {
      final db = await database;
      await db.delete('route_groups');
      
      if (kDebugMode) {
        print('✅ [SQLITE_GROUPS] Все группы удалены');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SQLITE_GROUPS] Ошибка удаления всех групп: $e');
      }
      rethrow;
    }
  }

  /// Пакетное сохранение групп
  Future<void> saveGroupsBatch(List<RouteGroup> groups) async {
    if (kDebugMode) {
      print('💾 [SQLITE_GROUPS] Пакетное сохранение ${groups.length} групп...');
    }
    
    try {
      final db = await database;
      final batch = db.batch();

      for (final group in groups) {
        final groupId = group.id.isEmpty 
            ? 'group_${DateTime.now().millisecondsSinceEpoch}_${groups.indexOf(group)}'
            : group.id;
        
        final groupWithId = group.copyWith(id: groupId);
        
        batch.insert(
          'route_groups',
          _groupToMap(groupWithId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      
      if (kDebugMode) {
        print('✅ [SQLITE_GROUPS] Пакетное сохранение завершено');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [SQLITE_GROUPS] Ошибка пакетного сохранения: $e');
      }
      rethrow;
    }
  }

  /// Преобразование RouteGroup в Map для SQLite
  Map<String, dynamic> _groupToMap(RouteGroup group) {
    return {
      'id': group.id,
      'name': group.name,
      'description': group.description,
      'basePrice': group.basePrice,
      'originCities': group.originCities.join('|||'), // Разделитель для списка
      'destinationCities': group.destinationCities.join('|||'),
      'autoGenerateReverse': group.autoGenerateReverse ? 1 : 0,
      'createdAt': group.createdAt.millisecondsSinceEpoch,
      'updatedAt': group.updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Преобразование Map из SQLite в RouteGroup
  RouteGroup _mapToGroup(Map<String, dynamic> map) {
    return RouteGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      basePrice: map['basePrice'] as double,
      originCities: (map['originCities'] as String)
          .split('|||')
          .where((city) => city.isNotEmpty)
          .toList(),
      destinationCities: (map['destinationCities'] as String)
          .split('|||')
          .where((city) => city.isNotEmpty)
          .toList(),
      autoGenerateReverse: (map['autoGenerateReverse'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
    );
  }

  /// Закрытие базы данных
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      
      if (kDebugMode) {
        print('✅ [SQLITE_GROUPS] База данных закрыта');
      }
    }
  }
}
