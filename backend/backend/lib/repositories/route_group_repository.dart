import 'package:backend/services/database_service.dart';
import '../utils/db_helpers.dart';

/// Модель группы маршрутов с базовой ценой
class RouteGroupFull {
  final String id;
  final String name;
  final String? description;
  final double basePrice;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RouteGroupFull({
    required this.id,
    required this.name,
    this.description,
    this.basePrice = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'basePrice': basePrice,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory RouteGroupFull.fromDb(Map<String, dynamic> row) {
    return RouteGroupFull(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      basePrice: (row['base_price'] as num?)?.toDouble() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: parseDbDateTime(row['created_at']),
      updatedAt: parseDbDateTime(row['updated_at']),
    );
  }
}

/// DTO для создания группы
class CreateRouteGroupDto {
  final String name;
  final String? description;
  final double basePrice;

  const CreateRouteGroupDto({
    required this.name,
    this.description,
    this.basePrice = 0,
  });

  factory CreateRouteGroupDto.fromJson(Map<String, dynamic> json) {
    return CreateRouteGroupDto(
      name: json['name'] as String,
      description: json['description'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// DTO для обновления группы
class UpdateRouteGroupDto {
  final String? name;
  final String? description;
  final double? basePrice;
  final bool? isActive;

  const UpdateRouteGroupDto({
    this.name,
    this.description,
    this.basePrice,
    this.isActive,
  });

  factory UpdateRouteGroupDto.fromJson(Map<String, dynamic> json) {
    return UpdateRouteGroupDto(
      name: json['name'] as String?,
      description: json['description'] as String?,
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool?,
    );
  }
}

/// Repository для работы с группами маршрутов
class RouteGroupRepository {
  final DatabaseService db;

  RouteGroupRepository(this.db);

  /// Получить все группы
  Future<List<RouteGroupFull>> findAll({bool? isActive}) async {
    final sql = StringBuffer('SELECT * FROM route_groups');

    if (isActive != null) {
      sql.write(' WHERE is_active = @isActive');
    }

    sql.write(' ORDER BY name');

    final rows = await db.queryMany(
      sql.toString(),
      parameters: isActive != null ? {'isActive': isActive} : null,
    );

    return rows.map((row) => RouteGroupFull.fromDb(row)).toList();
  }

  /// Найти группу по ID
  Future<RouteGroupFull?> findById(String id) async {
    final row = await db.queryOne(
      'SELECT * FROM route_groups WHERE id = @id',
      parameters: {'id': id},
    );

    if (row == null) return null;
    return RouteGroupFull.fromDb(row);
  }

  /// Создать группу
  Future<RouteGroupFull> create(CreateRouteGroupDto dto) async {
    final id = await db.insert(
      '''
      INSERT INTO route_groups (name, description, base_price)
      VALUES (@name, @description, @basePrice)
      ''',
      parameters: {
        'name': dto.name,
        'description': dto.description,
        'basePrice': dto.basePrice,
      },
    );

    final group = await findById(id);
    if (group == null) {
      throw Exception('Failed to retrieve created group');
    }

    return group;
  }

  /// Обновить группу
  Future<RouteGroupFull> update(String id, UpdateRouteGroupDto dto) async {
    final updates = <String>[];
    final params = <String, dynamic>{'id': id};

    if (dto.name != null) {
      updates.add('name = @name');
      params['name'] = dto.name;
    }

    if (dto.description != null) {
      updates.add('description = @description');
      params['description'] = dto.description;
    }

    if (dto.basePrice != null) {
      updates.add('base_price = @basePrice');
      params['basePrice'] = dto.basePrice;
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
      UPDATE route_groups
      SET ${updates.join(', ')}
      WHERE id = @id
      ''',
      parameters: params,
    );

    final updated = await findById(id);
    if (updated == null) {
      throw Exception('Group not found after update');
    }

    return updated;
  }

  /// Удалить группу
  Future<bool> delete(String id) async {
    // Сначала открепляем маршруты от группы
    await db.execute(
      'UPDATE predefined_routes SET group_id = NULL WHERE group_id = @id',
      parameters: {'id': id},
    );

    final result = await db.execute(
      'DELETE FROM route_groups WHERE id = @id',
      parameters: {'id': id},
    );
    return result > 0;
  }

  /// Получить количество маршрутов в группе
  Future<int> getRouteCount(String groupId) async {
    final row = await db.queryOne(
      'SELECT COUNT(*) as count FROM predefined_routes WHERE group_id = @groupId',
      parameters: {'groupId': groupId},
    );
    return (row?['count'] as num?)?.toInt() ?? 0;
  }
}
