import 'dart:convert';
import 'package:backend/models/order.dart';
import 'package:backend/services/database_service.dart';

/// Repository для работы с заказами
class OrderRepository {
  final DatabaseService db;

  OrderRepository(this.db);

  /// Создать новый заказ
  Future<Order> create(CreateOrderDto dto, {String? userId}) async {
    // Генерируем order_id (например, ORDER-2026-01-001)
    final now = DateTime.now();
    final orderId = 'ORDER-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch % 1000}';

    // Парсим дату и время
    DateTime? parsedDateTime;
    String? dbDate;
    String? dbTime;
    
    // Пробуем распарсить departureTime как DateTime (приложение отправляет ISO string)
    if (dto.departureTime != null) {
      try {
        parsedDateTime = DateTime.parse(dto.departureTime!);
        dbDate = '${parsedDateTime.year}-${parsedDateTime.month.toString().padLeft(2, '0')}-${parsedDateTime.day.toString().padLeft(2, '0')}';
        dbTime = '${parsedDateTime.hour.toString().padLeft(2, '0')}:${parsedDateTime.minute.toString().padLeft(2, '0')}:${parsedDateTime.second.toString().padLeft(2, '0')}';
      } catch (e) {
        // Если не ISO string, используем как есть (формат HH:MM)
        dbTime = dto.departureTime;
      }
    }
    
    // Если есть отдельная дата, используем её
    if (dto.departureDate != null) {
      final d = dto.departureDate!;
      dbDate = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    final id = await db.insert(
      '''
      INSERT INTO orders (
        order_id, user_id,
        from_lat, from_lon, to_lat, to_lon,
        from_address, to_address,
        distance_km, raw_price, final_price, base_cost, cost_per_km,
        status,
        client_name, client_phone,
        departure_date, departure_time,
        passengers, baggage, pets,
        notes, vehicle_class
      ) VALUES (
        @orderId, @userId,
        @fromLat, @fromLon, @toLat, @toLon,
        @fromAddress, @toAddress,
        @distanceKm, @rawPrice, @finalPrice, @baseCost, @costPerKm,
        @status,
        @clientName, @clientPhone,
        @departureDate, @departureTime,
        @passengers, @baggage, @pets,
        @notes, @vehicleClass
      )
      ''',
      parameters: {
        'orderId': orderId,
        'userId': userId,
        'fromLat': dto.fromLat,
        'fromLon': dto.fromLon,
        'toLat': dto.toLat,
        'toLon': dto.toLon,
        'fromAddress': dto.fromAddress,
        'toAddress': dto.toAddress,
        'distanceKm': dto.distanceKm,
        'rawPrice': dto.rawPrice,
        'finalPrice': dto.finalPrice,
        'baseCost': dto.baseCost,
        'costPerKm': dto.costPerKm,
        'status': 'pending',
        'clientName': dto.clientName,
        'clientPhone': dto.clientPhone,
        'departureDate': dbDate, // ✅ Формат YYYY-MM-DD для DATE
        'departureTime': dbTime, // ✅ Формат HH:MM:SS для TIME
        'passengers': dto.passengers != null ? jsonEncode(dto.passengers!.map((p) => p.toJson()).toList()) : null,
        'baggage': dto.baggage != null ? jsonEncode(dto.baggage!.map((b) => b.toJson()).toList()) : null,
        'pets': dto.pets != null ? jsonEncode(dto.pets!.map((p) => p.toJson()).toList()) : null,
        'notes': dto.notes,
        'vehicleClass': dto.vehicleClass,
      },
    );

    final order = await findById(id);
    if (order == null) {
      throw Exception('Failed to retrieve created order');
    }

    return order;
  }

  /// Найти заказ по ID
  Future<Order?> findById(String id) async {
    final row = await db.queryOne(
      'SELECT * FROM orders WHERE id = @id',
      parameters: {'id': id},
    );

    if (row == null) return null;
    return Order.fromDb(row);
  }

  /// Найти заказы пользователя
  Future<List<Order>> findByUserId(String userId, {int? limit, int? offset}) async {
    final sql = StringBuffer('''
      SELECT * FROM orders
      WHERE user_id = @userId
      ORDER BY created_at DESC
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
    }

    if (offset != null) {
      sql.write(' OFFSET $offset');
    }

    final rows = await db.queryMany(
      sql.toString(),
      parameters: {'userId': userId},
    );

    return rows.map((row) => Order.fromDb(row)).toList();
  }

  /// Найти заказы по телефону клиента
  Future<List<Order>> findByPhone(String phone) async {
    final rows = await db.queryMany(
      '''
      SELECT * FROM orders
      WHERE client_phone = @phone
      ORDER BY created_at DESC
      ''',
      parameters: {'phone': phone},
    );

    return rows.map((row) => Order.fromDb(row)).toList();
  }

  /// Найти заказы по статусу
  Future<List<Order>> findByStatus(OrderStatus status, {int? limit}) async {
    final sql = StringBuffer('''
      SELECT * FROM orders
      WHERE status = @status
      ORDER BY created_at DESC
    ''');

    if (limit != null) {
      sql.write(' LIMIT $limit');
    }

    final rows = await db.queryMany(
      sql.toString(),
      parameters: {'status': status.toDb()},
    );

    return rows.map((row) => Order.fromDb(row)).toList();
  }

  /// Получить все заказы (для админа)
  Future<List<Order>> findAll({
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    final conditions = <String>[];
    final params = <String, dynamic>{};

    if (status != null) {
      conditions.add('status = @status');
      params['status'] = status.toDb();
    }

    if (fromDate != null) {
      conditions.add('created_at >= @fromDate');
      params['fromDate'] = fromDate.toIso8601String();
    }

    if (toDate != null) {
      conditions.add('created_at <= @toDate');
      params['toDate'] = toDate.toIso8601String();
    }

    final sql = StringBuffer('SELECT * FROM orders');

    if (conditions.isNotEmpty) {
      sql.write(' WHERE ${conditions.join(' AND ')}');
    }

    sql.write(' ORDER BY created_at DESC');

    if (limit != null) {
      sql.write(' LIMIT $limit');
    }

    if (offset != null) {
      sql.write(' OFFSET $offset');
    }

    final rows = await db.queryMany(sql.toString(), parameters: params);
    return rows.map((row) => Order.fromDb(row)).toList();
  }

  /// Обновить заказ
  Future<Order> update(String id, UpdateOrderDto dto) async {
    final updates = <String>[];
    final params = <String, dynamic>{'id': id};

    if (dto.status != null) {
      updates.add('status = @status');
      params['status'] = dto.status;
    }

    if (dto.clientName != null) {
      updates.add('client_name = @clientName');
      params['clientName'] = dto.clientName;
    }

    if (dto.clientPhone != null) {
      updates.add('client_phone = @clientPhone');
      params['clientPhone'] = dto.clientPhone;
    }

    if (dto.departureDate != null) {
      updates.add('departure_date = @departureDate');
      params['departureDate'] = dto.departureDate!.toIso8601String();
    }

    if (dto.departureTime != null) {
      updates.add('departure_time = @departureTime');
      params['departureTime'] = dto.departureTime;
    }

    if (dto.passengers != null) {
      updates.add('passengers = @passengers');
      params['passengers'] = jsonEncode(dto.passengers!.map((p) => p.toJson()).toList());
    }

    if (dto.baggage != null) {
      updates.add('baggage = @baggage');
      params['baggage'] = jsonEncode(dto.baggage!.map((b) => b.toJson()).toList());
    }

    if (dto.pets != null) {
      updates.add('pets = @pets');
      params['pets'] = jsonEncode(dto.pets!.map((p) => p.toJson()).toList());
    }

    if (dto.notes != null) {
      updates.add('notes = @notes');
      params['notes'] = dto.notes;
    }

    if (updates.isEmpty) {
      throw Exception('No fields to update');
    }

    await db.execute(
      '''
      UPDATE orders
      SET ${updates.join(', ')}
      WHERE id = @id
      ''',
      parameters: params,
    );

    final updated = await findById(id);
    if (updated == null) {
      throw Exception('Order not found after update');
    }

    return updated;
  }

  /// Обновить статус заказа
  Future<Order> updateStatus(String id, OrderStatus status) async {
    await db.execute(
      'UPDATE orders SET status = @status WHERE id = @id',
      parameters: {'id': id, 'status': status.toDb()},
    );

    final updated = await findById(id);
    if (updated == null) {
      throw Exception('Order not found after status update');
    }

    return updated;
  }

  /// Удалить заказ
  Future<void> delete(String id) async {
    await db.execute(
      'DELETE FROM orders WHERE id = @id',
      parameters: {'id': id},
    );
  }

  /// Получить статистику заказов
  Future<Map<String, dynamic>> getStats({String? userId}) async {
    final userCondition = userId != null ? 'WHERE user_id = @userId' : '';
    final params = userId != null ? {'userId': userId} : null;

    final row = await db.queryOne(
      '''
      SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'pending') as pending,
        COUNT(*) FILTER (WHERE status = 'confirmed') as confirmed,
        COUNT(*) FILTER (WHERE status = 'in_progress') as in_progress,
        COUNT(*) FILTER (WHERE status = 'completed') as completed,
        COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled,
        SUM(final_price) FILTER (WHERE status = 'completed') as total_revenue
      FROM orders
      $userCondition
      ''',
      parameters: params,
    );

    return {
      'total': row?['total'] ?? 0,
      'pending': row?['pending'] ?? 0,
      'confirmed': row?['confirmed'] ?? 0,
      'inProgress': row?['in_progress'] ?? 0,
      'completed': row?['completed'] ?? 0,
      'cancelled': row?['cancelled'] ?? 0,
      'totalRevenue': row?['total_revenue'] ?? 0.0,
    };
  }
}
