import 'package:backend/models/route.dart';
import 'package:backend/services/database_service.dart';

/// Repository для работы с предопределенными маршрутами
class RouteRepository {
  final DatabaseService db;

  RouteRepository(this.db);

  /// Получить все активные маршруты
  Future<List<PredefinedRoute>> findAll({bool? isActive}) async {
    final sql = StringBuffer('SELECT * FROM predefined_routes');

    if (isActive != null) {
      sql.write(' WHERE is_active = @isActive');
    }

    sql.write(' ORDER BY from_city, to_city');

    final rows = await db.queryMany(
      sql.toString(),
      parameters: isActive != null ? {'isActive': isActive} : null,
    );

    return rows.map((row) => PredefinedRoute.fromDb(row)).toList();
  }

  /// Найти маршрут по ID
  Future<PredefinedRoute?> findById(String id) async {
    final row = await db.queryOne(
      'SELECT * FROM predefined_routes WHERE id = @id',
      parameters: {'id': id},
    );

    if (row == null) return null;
    return PredefinedRoute.fromDb(row);
  }

  /// Найти маршруты между городами
  Future<List<PredefinedRoute>> findByDirection({
    required String fromCity,
    required String toCity,
  }) async {
    final rows = await db.queryMany(
      '''
      SELECT * FROM predefined_routes
      WHERE from_city ILIKE @fromCity
        AND to_city ILIKE @toCity
        AND is_active = true
      ORDER BY price
      ''',
      parameters: {
        'fromCity': '%$fromCity%',
        'toCity': '%$toCity%',
      },
    );

    return rows.map((row) => PredefinedRoute.fromDb(row)).toList();
  }

  /// Найти маршруты из города
  Future<List<PredefinedRoute>> findFromCity(String city) async {
    final rows = await db.queryMany(
      '''
      SELECT * FROM predefined_routes
      WHERE from_city ILIKE @city
        AND is_active = true
      ORDER BY to_city
      ''',
      parameters: {'city': '%$city%'},
    );

    return rows.map((row) => PredefinedRoute.fromDb(row)).toList();
  }

  /// Найти маршруты в город
  Future<List<PredefinedRoute>> findToCity(String city) async {
    final rows = await db.queryMany(
      '''
      SELECT * FROM predefined_routes
      WHERE to_city ILIKE @city
        AND is_active = true
      ORDER BY from_city
      ''',
      parameters: {'city': '%$city%'},
    );

    return rows.map((row) => PredefinedRoute.fromDb(row)).toList();
  }

  /// Создать маршрут
  Future<PredefinedRoute> create(CreateRouteDto dto) async {
    final id = await db.insert(
      '''
      INSERT INTO predefined_routes (from_city, to_city, price, group_id)
      VALUES (@fromCity, @toCity, @price, @groupId)
      ''',
      parameters: {
        'fromCity': dto.fromCity,
        'toCity': dto.toCity,
        'price': dto.price,
        'groupId': dto.groupId,
      },
    );

    final route = await findById(id);
    if (route == null) {
      throw Exception('Failed to retrieve created route');
    }

    return route;
  }

  /// Обновить маршрут
  Future<PredefinedRoute> update(String id, UpdateRouteDto dto) async {
    final updates = <String>[];
    final params = <String, dynamic>{'id': id};

    if (dto.fromCity != null) {
      updates.add('from_city = @fromCity');
      params['fromCity'] = dto.fromCity;
    }

    if (dto.toCity != null) {
      updates.add('to_city = @toCity');
      params['toCity'] = dto.toCity;
    }

    if (dto.price != null) {
      updates.add('price = @price');
      params['price'] = dto.price;
    }

    if (dto.groupId != null) {
      updates.add('group_id = @groupId');
      params['groupId'] = dto.groupId;
    }

    if (dto.isActive != null) {
      updates.add('is_active = @isActive');
      params['isActive'] = dto.isActive;
    }

    if (updates.isEmpty) {
      throw Exception('No fields to update');
    }

    await db.execute(
      '''
      UPDATE predefined_routes
      SET ${updates.join(', ')}
      WHERE id = @id
      ''',
      parameters: params,
    );

    final updated = await findById(id);
    if (updated == null) {
      throw Exception('Route not found after update');
    }

    return updated;
  }

  /// Удалить маршрут
  Future<bool> delete(String id) async {
    final result = await db.execute(
      'DELETE FROM predefined_routes WHERE id = @id',
      parameters: {'id': id},
    );
    return result > 0;
  }

  /// Деактивировать маршрут
  Future<void> deactivate(String id) async {
    await db.execute(
      'UPDATE predefined_routes SET is_active = false WHERE id = @id',
      parameters: {'id': id},
    );
  }
}
