import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/booking.dart';
import '../models/ride.dart';
import '../models/chat_conversation.dart';
import '../models/ride_request.dart';

/// Сервис для работы с локальной SQLite базой данных
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static DatabaseService get instance => _instance;
  DatabaseService._internal();

  Database? _database;
  final _uuid = const Uuid();

  /// Получение базы данных
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Инициализация базы данных
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'taxi_poputchik.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Создание таблиц
  Future<void> _onCreate(Database db, int version) async {
    // Таблица поездок
    await db.execute('''
      CREATE TABLE rides (
        id TEXT PRIMARY KEY,
        driver_id TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        driver_phone TEXT NOT NULL,
        from_address TEXT NOT NULL,
        to_address TEXT NOT NULL,
        from_district TEXT NOT NULL,
        to_district TEXT NOT NULL,
        from_details TEXT,
        to_details TEXT,
        departure_time TEXT NOT NULL,
        available_seats INTEGER NOT NULL,
        total_seats INTEGER NOT NULL,
        price_per_seat REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        description TEXT,
        created_at TEXT NOT NULL,
        started_at TEXT,
        completed_at TEXT
      )
    ''');

    // Таблица бронирований
    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        ride_id TEXT NOT NULL,
        passenger_id TEXT NOT NULL,
        passenger_name TEXT NOT NULL,
        passenger_phone TEXT NOT NULL,
        seats_booked INTEGER NOT NULL,
        total_price REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        pickup_point TEXT,
        dropoff_point TEXT,
        created_at TEXT NOT NULL,
        confirmed_at TEXT,
        rejected_at TEXT,
        rejection_reason TEXT,
        ride_from TEXT,
        ride_to TEXT,
        ride_driver_name TEXT,
        ride_departure_time TEXT,
        FOREIGN KEY (ride_id) REFERENCES rides (id)
      )
    ''');

    // Таблица чатов
    await db.execute('''
      CREATE TABLE chat_conversations (
        id TEXT PRIMARY KEY,
        ride_id TEXT NOT NULL,
        driver_name TEXT NOT NULL,
        route TEXT NOT NULL,
        last_message TEXT NOT NULL,
        last_message_time TEXT NOT NULL,
        has_unread_messages INTEGER NOT NULL DEFAULT 0,
        unread_count INTEGER NOT NULL DEFAULT 0,
        driver_avatar TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (ride_id) REFERENCES rides (id)
      )
    ''');

    // Таблица сообщений чата
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        ride_id TEXT NOT NULL,
        text TEXT NOT NULL,
        is_from_user INTEGER NOT NULL DEFAULT 1,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (conversation_id) REFERENCES chat_conversations (id),
        FOREIGN KEY (ride_id) REFERENCES rides (id)
      )
    ''');

    // Таблица запросов на поездку от пассажиров
    await db.execute('''
      CREATE TABLE ride_requests (
        id TEXT PRIMARY KEY,
        passenger_id TEXT NOT NULL,
        passenger_name TEXT NOT NULL,
        from_district TEXT NOT NULL,
        from_address TEXT NOT NULL,
        from_latitude REAL NOT NULL,
        from_longitude REAL NOT NULL,
        to_district TEXT NOT NULL,
        to_address TEXT NOT NULL,
        to_latitude REAL NOT NULL,
        to_longitude REAL NOT NULL,
        departure_time TEXT NOT NULL,
        passengers_count INTEGER NOT NULL,
        max_price REAL NOT NULL,
        comment TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        accepted_at TEXT,
        accepted_by_driver_id TEXT,
        agreed_price REAL
      )
    ''');

    // Индексы для оптимизации запросов
    await db.execute('CREATE INDEX idx_rides_driver_id ON rides (driver_id)');
    await db.execute('CREATE INDEX idx_rides_status ON rides (status)');
    await db.execute(
      'CREATE INDEX idx_bookings_passenger_id ON bookings (passenger_id)',
    );
    await db.execute('CREATE INDEX idx_bookings_ride_id ON bookings (ride_id)');
    await db.execute('CREATE INDEX idx_bookings_status ON bookings (status)');
    await db.execute(
      'CREATE INDEX idx_chat_conversations_ride_id ON chat_conversations (ride_id)',
    );
    await db.execute(
      'CREATE INDEX idx_chat_messages_conversation_id ON chat_messages (conversation_id)',
    );
    await db.execute(
      'CREATE INDEX idx_chat_messages_timestamp ON chat_messages (timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_ride_requests_passenger_id ON ride_requests (passenger_id)',
    );
    await db.execute(
      'CREATE INDEX idx_ride_requests_status ON ride_requests (status)',
    );

    // Добавляем демо данные
    await _insertDemoData(db);
  }

  /// Обновление базы данных
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Добавляем таблицы для чатов
      await db.execute('''
        CREATE TABLE chat_conversations (
          id TEXT PRIMARY KEY,
          ride_id TEXT NOT NULL,
          driver_name TEXT NOT NULL,
          route TEXT NOT NULL,
          last_message TEXT NOT NULL,
          last_message_time TEXT NOT NULL,
          has_unread_messages INTEGER NOT NULL DEFAULT 0,
          unread_count INTEGER NOT NULL DEFAULT 0,
          driver_avatar TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (ride_id) REFERENCES rides (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE chat_messages (
          id TEXT PRIMARY KEY,
          conversation_id TEXT NOT NULL,
          ride_id TEXT NOT NULL,
          text TEXT NOT NULL,
          is_from_user INTEGER NOT NULL DEFAULT 1,
          timestamp TEXT NOT NULL,
          FOREIGN KEY (conversation_id) REFERENCES chat_conversations (id),
          FOREIGN KEY (ride_id) REFERENCES rides (id)
        )
      ''');

      // Индексы для чатов
      await db.execute(
        'CREATE INDEX idx_chat_conversations_ride_id ON chat_conversations (ride_id)',
      );
      await db.execute(
        'CREATE INDEX idx_chat_messages_conversation_id ON chat_messages (conversation_id)',
      );
      await db.execute(
        'CREATE INDEX idx_chat_messages_timestamp ON chat_messages (timestamp)',
      );
    }

    if (oldVersion < 3) {
      // Добавляем таблицу запросов на поездку
      await db.execute('''
        CREATE TABLE ride_requests (
          id TEXT PRIMARY KEY,
          passenger_id TEXT NOT NULL,
          passenger_name TEXT NOT NULL,
          from_district TEXT NOT NULL,
          from_address TEXT NOT NULL,
          from_latitude REAL NOT NULL,
          from_longitude REAL NOT NULL,
          to_district TEXT NOT NULL,
          to_address TEXT NOT NULL,
          to_latitude REAL NOT NULL,
          to_longitude REAL NOT NULL,
          departure_time TEXT NOT NULL,
          passengers_count INTEGER NOT NULL,
          max_price REAL NOT NULL,
          comment TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          created_at TEXT NOT NULL,
          accepted_at TEXT,
          accepted_by_driver_id TEXT,
          agreed_price REAL
        )
      ''');

      // Индексы для запросов
      await db.execute(
        'CREATE INDEX idx_ride_requests_passenger_id ON ride_requests (passenger_id)',
      );
      await db.execute(
        'CREATE INDEX idx_ride_requests_status ON ride_requests (status)',
      );
    }
  }

  /// Добавление демо данных
  Future<void> _insertDemoData(Database db) async {
    final now = DateTime.now();

    // Демо поездки
    final demoRides = [
      Ride(
        id: _uuid.v4(),
        driverId: 'driver_1',
        driverName: 'Алексей',
        driverPhone: '+7 (999) 123-45-67',
        fromAddress: 'м. Тверская',
        toAddress: 'ТЦ Мега',
        fromDistrict: 'Центр',
        toDistrict: 'Спальный район',
        fromDetails: 'у выхода из метро',
        toDetails: 'главный вход',
        departureTime: now.add(const Duration(hours: 2)),
        availableSeats: 2,
        totalSeats: 3,
        pricePerSeat: 120,
        status: RideStatus.active,
        description: 'Поездка с кондиционером, некурящий',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      Ride(
        id: _uuid.v4(),
        driverId: 'driver_2',
        driverName: 'Мария',
        driverPhone: '+7 (999) 987-65-43',
        fromAddress: 'м. Сокольники',
        toAddress: 'м. Красные ворота',
        fromDistrict: 'Северный район',
        toDistrict: 'Центр',
        fromDetails: 'северный выход',
        toDetails: 'центральный выход',
        departureTime: now.add(const Duration(hours: 4)),
        availableSeats: 3,
        totalSeats: 3,
        pricePerSeat: 100,
        status: RideStatus.active,
        description: 'Можно с детским креслом',
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
    ];

    for (final ride in demoRides) {
      await db.insert('rides', ride.toMap());
    }

    debugPrint('Добавлено ${demoRides.length} демо поездок');
  }

  /// Публичный метод для добавления свежих демо данных
  Future<void> addFreshDemoData() async {
    final db = await database;
    final now = DateTime.now();

    // Добавляем новые демо поездки с актуальными датами
    final freshDemoRides = [
      Ride(
        id: _uuid.v4(),
        driverId: 'driver_demo_1',
        driverName: 'Иван',
        driverPhone: '+7 (999) 111-11-11',
        fromAddress: 'м. Арбатская',
        toAddress: 'Аэропорт Домодедово',
        fromDistrict: 'Центр',
        toDistrict: 'Южный район',
        fromDetails: 'выход к Арбату',
        toDetails: 'терминал 1',
        departureTime: now.add(const Duration(hours: 1)),
        availableSeats: 2,
        totalSeats: 4,
        pricePerSeat: 300,
        status: RideStatus.active,
        description: 'Поездка в аэропорт, помогу с багажом',
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
      Ride(
        id: _uuid.v4(),
        driverId: 'driver_demo_2',
        driverName: 'Елена',
        driverPhone: '+7 (999) 222-22-22',
        fromAddress: 'ТЦ Европейский',
        toAddress: 'м. Парк Культуры',
        fromDistrict: 'Промышленный район',
        toDistrict: 'Центр',
        fromDetails: 'главный вход со стороны площади',
        toDetails: 'выход к парку Горького',
        departureTime: now.add(const Duration(hours: 3)),
        availableSeats: 1,
        totalSeats: 3,
        pricePerSeat: 80,
        status: RideStatus.active,
        description: 'Комфортная поездка, возможна остановка по пути',
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),
      Ride(
        id: _uuid.v4(),
        driverId: 'driver_demo_3',
        driverName: 'Дмитрий',
        driverPhone: '+7 (999) 333-33-33',
        fromAddress: 'Университет МГУ',
        toAddress: 'м. Китай-город',
        fromDistrict: 'Западный район',
        toDistrict: 'Центр',
        fromDetails: 'главное здание',
        toDetails: 'выход к историческому центру',
        departureTime: now.add(const Duration(hours: 5)),
        availableSeats: 3,
        totalSeats: 3,
        pricePerSeat: 150,
        status: RideStatus.active,
        description: 'Быстрая поездка без остановок',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];

    for (final ride in freshDemoRides) {
      await db.insert('rides', ride.toMap());
    }

    debugPrint('✅ Добавлено ${freshDemoRides.length} свежих демо поездок');
  }

  /// Добавление демо истории поездок
  Future<void> addDemoRideHistory() async {
    final db = await database;
    final now = DateTime.now();

    // Создаем завершенные поездки для истории
    final completedRides = [
      Ride(
        id: _uuid.v4(),
        driverId: 'driver_1',
        driverName: 'Алексей',
        driverPhone: '+7 (999) 111-22-33',
        fromAddress: 'м. Тверская',
        toAddress: 'ТЦ Авиапарк',
        fromDistrict: 'Центр',
        toDistrict: 'Спальный район',
        fromDetails: 'у выхода №2',
        toDetails: 'главный вход',
        departureTime: now.subtract(const Duration(days: 2, hours: 3)),
        availableSeats: 0,
        totalSeats: 3,
        pricePerSeat: 450,
        status: RideStatus.completed,
        description: 'Поездка завершена успешно',
        createdAt: now.subtract(const Duration(days: 2, hours: 5)),
        completedAt: now.subtract(const Duration(days: 2, hours: 1)),
      ),
      Ride(
        id: _uuid.v4(),
        driverId: 'passenger_1',
        driverName: 'Анна',
        driverPhone: '+7 (999) 123-45-67',
        fromAddress: 'Аэропорт Шереметьево',
        toAddress: 'м. Белорусская',
        fromDistrict: 'Аэропорт',
        toDistrict: 'Центр',
        fromDetails: 'терминал D',
        toDetails: 'кольцевая линия',
        departureTime: now.subtract(const Duration(days: 1, hours: 4)),
        availableSeats: 0,
        totalSeats: 2,
        pricePerSeat: 1200,
        status: RideStatus.completed,
        description: 'Поездка из аэропорта',
        createdAt: now.subtract(const Duration(days: 1, hours: 6)),
        completedAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      Ride(
        id: _uuid.v4(),
        driverId: 'driver_2',
        driverName: 'Мария',
        driverPhone: '+7 (999) 987-65-43',
        fromAddress: 'Ж/д вокзал',
        toAddress: 'м. Сокольники',
        fromDistrict: 'Вокзал',
        toDistrict: 'Промзона',
        fromDetails: 'центральный вход',
        toDetails: 'станция метро',
        departureTime: now.subtract(const Duration(days: 3, hours: 2)),
        availableSeats: 0,
        totalSeats: 4,
        pricePerSeat: 680,
        status: RideStatus.completed,
        description: 'Поездка с вокзала',
        createdAt: now.subtract(const Duration(days: 3, hours: 4)),
        completedAt: now.subtract(const Duration(days: 3, hours: 1)),
      ),
      Ride(
        id: _uuid.v4(),
        driverId: 'passenger_1',
        driverName: 'Анна',
        driverPhone: '+7 (999) 123-45-67',
        fromAddress: 'Университет МГУ',
        toAddress: 'м. Китай-город',
        fromDistrict: 'Университет',
        toDistrict: 'Домой',
        fromDetails: 'главное здание',
        toDetails: 'выход к дому',
        departureTime: now.subtract(const Duration(days: 4, hours: 1)),
        availableSeats: 0,
        totalSeats: 1,
        pricePerSeat: 320,
        status: RideStatus.completed,
        description: 'Поездка домой после учебы',
        createdAt: now.subtract(const Duration(days: 4, hours: 2)),
        completedAt: now.subtract(const Duration(days: 4)),
      ),
    ];

    for (final ride in completedRides) {
      await db.insert('rides', ride.toMap());
    }

    // Создаем соответствующие бронирования для некоторых поездок
    final completedBookings = [
      Booking(
        id: _uuid.v4(),
        rideId: completedRides[0].id,
        passengerId: 'passenger_1',
        passengerName: 'Анна',
        passengerPhone: '+7 (999) 123-45-67',
        seatsBooked: 2,
        totalPrice: 900,
        status: BookingStatus.completed,
        createdAt: completedRides[0].createdAt.add(const Duration(minutes: 10)),
        rideFrom: completedRides[0].fromAddress,
        rideTo: completedRides[0].toAddress,
        rideDriverName: completedRides[0].driverName,
        rideDepartureTime: completedRides[0].departureTime,
      ),
      Booking(
        id: _uuid.v4(),
        rideId: completedRides[2].id,
        passengerId: 'passenger_1',
        passengerName: 'Анна',
        passengerPhone: '+7 (999) 123-45-67',
        seatsBooked: 1,
        totalPrice: 680,
        status: BookingStatus.completed,
        createdAt: completedRides[2].createdAt.add(const Duration(minutes: 15)),
        rideFrom: completedRides[2].fromAddress,
        rideTo: completedRides[2].toAddress,
        rideDriverName: completedRides[2].driverName,
        rideDepartureTime: completedRides[2].departureTime,
      ),
    ];

    for (final booking in completedBookings) {
      await db.insert('bookings', booking.toMap());
    }

    debugPrint(
      '✅ Добавлено ${completedRides.length} завершенных поездок и ${completedBookings.length} бронирований для истории',
    );
  }

  // ==================== ПОЕЗДКИ ====================

  /// Создание новой поездки
  Future<String> createRide(Ride ride) async {
    try {
      debugPrint('🚀 [DATABASE] Начало создания поездки: ${ride.id}');
      debugPrint('   📍 Откуда: ${ride.fromAddress} (${ride.fromDistrict})');
      debugPrint('   📍 Куда: ${ride.toAddress} (${ride.toDistrict})');
      debugPrint('   ⏰ Время отправления: ${ride.departureTime}');
      debugPrint('   💰 Цена: ${ride.pricePerSeat} ₽');
      debugPrint('   👥 Мест: ${ride.availableSeats}');
      debugPrint('   📊 Статус: ${ride.status}');

      final db = await database;
      final rideMap = ride.toMap();
      debugPrint('   🗺️ Данные для сохранения: $rideMap');

      final result = await db.insert('rides', rideMap);
      debugPrint(
        '✅ [DATABASE] Поездка успешно сохранена в БД! ID в таблице: $result, UUID: ${ride.id}',
      );

      // Проверяем что поездка действительно сохранилась
      final savedRides = await db.query(
        'rides',
        where: 'id = ?',
        whereArgs: [ride.id],
      );
      if (savedRides.isNotEmpty) {
        debugPrint('✅ [DATABASE] Верификация: поездка найдена в БД');
      } else {
        debugPrint(
          '❌ [DATABASE] ОШИБКА: поездка НЕ найдена в БД после сохранения!',
        );
      }

      return ride.id;
    } catch (e, stackTrace) {
      debugPrint('❌ [DATABASE] Ошибка при создании поездки: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Получение всех поездок
  Future<List<Ride>> getAllRides() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rides',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Ride.fromMap(map)).toList();
  }

  /// Поиск поездок по фильтрам
  Future<List<Ride>> searchRides({
    String? fromDistrict,
    String? toDistrict,
    DateTime? date,
    RideStatus? status,
  }) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    // Строим WHERE условие
    List<String> conditions = [];

    if (fromDistrict != null && fromDistrict != 'Любой') {
      conditions.add('from_district = ?');
      whereArgs.add(fromDistrict);
    }

    if (toDistrict != null && toDistrict != 'Любой') {
      conditions.add('to_district = ?');
      whereArgs.add(toDistrict);
    }

    if (status != null) {
      conditions.add('status = ?');
      whereArgs.add(status.value);
    }

    if (conditions.isNotEmpty) {
      whereClause = 'WHERE ${conditions.join(' AND ')}';
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM rides 
      $whereClause
      ORDER BY departure_time ASC
    ''', whereArgs);

    return maps.map((map) => Ride.fromMap(map)).toList();
  }

  /// Получение поездок водителя
  Future<List<Ride>> getDriverRides(String driverId) async {
    try {
      debugPrint('🔍 [DATABASE] Получение поездок для водителя: $driverId');
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'rides',
        where: 'driver_id = ?',
        whereArgs: [driverId],
        orderBy: 'created_at DESC',
      );
      debugPrint('✅ [DATABASE] Найдено поездок: ${maps.length}');

      if (maps.isNotEmpty) {
        debugPrint('   Детали найденных поездок:');
        for (var map in maps) {
          debugPrint(
            '   - ID: ${map['id']}, от: ${map['from_address']}, до: ${map['to_address']}, статус: ${map['status']}',
          );
        }
      } else {
        debugPrint('   ⚠️ Поездок не найдено в БД');
        // Проверим все поездки в таблице
        final allRides = await db.query('rides');
        debugPrint('   📊 Всего поездок в таблице: ${allRides.length}');
        if (allRides.isNotEmpty) {
          debugPrint('   Все поездки в БД:');
          for (var ride in allRides) {
            debugPrint(
              '   - ID: ${ride['id']}, driver_id: ${ride['driver_id']}, от: ${ride['from_address']}',
            );
          }
        }
      }

      return maps.map((map) => Ride.fromMap(map)).toList();
    } catch (e, stackTrace) {
      debugPrint('❌ [DATABASE] Ошибка при получении поездок водителя: $e');
      debugPrint('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Обновление поездки
  Future<void> updateRide(Ride ride) async {
    final db = await database;
    await db.update(
      'rides',
      ride.toMap(),
      where: 'id = ?',
      whereArgs: [ride.id],
    );
    debugPrint('Обновлена поездка: ${ride.id}');
  }

  /// Получение завершенных поездок для истории
  Future<List<Ride>> getCompletedRides({
    String? userId,
    int? limit = 10,
  }) async {
    final db = await database;

    String query = '''
      SELECT * FROM rides 
      WHERE status = 'completed'
    ''';

    List<dynamic> args = [];

    // Если указан пользователь, фильтруем по водителю или пассажиру через бронирования
    if (userId != null) {
      query = '''
        SELECT DISTINCT r.* FROM rides r
        LEFT JOIN bookings b ON r.id = b.ride_id
        WHERE r.status = 'completed' 
        AND (r.driver_id = ? OR (b.passenger_id = ? AND b.status IN ('confirmed', 'completed')))
      ''';
      args = [userId, userId];
    }

    query += ' ORDER BY completed_at DESC, departure_time DESC';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return maps.map((map) => Ride.fromMap(map)).toList();
  }

  /// Получение завершенных бронирований пассажира для истории
  Future<List<Booking>> getCompletedBookings(
    String passengerId, {
    int? limit = 10,
  }) async {
    final db = await database;

    String query = '''
      SELECT b.* FROM bookings b
      JOIN rides r ON b.ride_id = r.id
      WHERE b.passenger_id = ? 
      AND b.status IN ('completed', 'confirmed')
      AND r.status = 'completed'
      ORDER BY r.completed_at DESC, r.departure_time DESC
    ''';

    List<dynamic> args = [passengerId];

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return maps.map((map) => Booking.fromMap(map)).toList();
  }

  /// Получение статистики поездок пользователя
  Future<Map<String, int>> getRideStatistics(String userId) async {
    final db = await database;

    // Статистика как водитель
    final driverStats = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_rides,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_rides,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_rides
      FROM rides WHERE driver_id = ?
    ''',
      [userId],
    );

    // Статистика как пассажир
    final passengerStats = await db.rawQuery(
      '''
      SELECT 
        COUNT(*) as total_bookings,
        COUNT(CASE WHEN b.status = 'completed' THEN 1 END) as completed_bookings,
        COUNT(CASE WHEN b.status = 'cancelled' THEN 1 END) as cancelled_bookings
      FROM bookings b
      JOIN rides r ON b.ride_id = r.id
      WHERE b.passenger_id = ?
    ''',
      [userId],
    );

    final driver = driverStats.first;
    final passenger = passengerStats.first;

    return {
      'total_as_driver': (driver['total_rides'] as int?) ?? 0,
      'completed_as_driver': (driver['completed_rides'] as int?) ?? 0,
      'cancelled_as_driver': (driver['cancelled_rides'] as int?) ?? 0,
      'total_as_passenger': (passenger['total_bookings'] as int?) ?? 0,
      'completed_as_passenger': (passenger['completed_bookings'] as int?) ?? 0,
      'cancelled_as_passenger': (passenger['cancelled_bookings'] as int?) ?? 0,
    };
  }

  /// Завершение поездки
  Future<void> completeRide(String rideId) async {
    final db = await database;
    await db.update(
      'rides',
      {
        'status': RideStatus.completed.value,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [rideId],
    );

    // Также обновляем статус всех подтвержденных бронирований
    await db.update(
      'bookings',
      {'status': BookingStatus.completed.value},
      where: 'ride_id = ? AND status = ?',
      whereArgs: [rideId, BookingStatus.confirmed.value],
    );

    debugPrint('Поездка завершена: $rideId');
  }

  // ==================== БРОНИРОВАНИЯ ====================

  /// Создание бронирования
  Future<String> createBooking(Booking booking) async {
    final db = await database;

    // Сначала проверяем доступность мест
    final ride = await getRideById(booking.rideId);
    if (ride == null) {
      throw Exception('Поездка не найдена');
    }

    final existingBookings = await getRideBookings(booking.rideId);
    final bookedSeats = existingBookings
        .where(
          (b) =>
              b.status != BookingStatus.cancelled &&
              b.status != BookingStatus.rejected,
        )
        .fold<int>(0, (sum, b) => sum + b.seatsBooked);

    if (bookedSeats + booking.seatsBooked > ride.availableSeats) {
      throw Exception('Недостаточно свободных мест');
    }

    await db.insert('bookings', booking.toMap());
    debugPrint('Создано бронирование: ${booking.id}');
    return booking.id;
  }

  /// Получение бронирований пассажира
  Future<List<Booking>> getPassengerBookings(String passengerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: 'passenger_id = ?',
      whereArgs: [passengerId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Booking.fromMap(map)).toList();
  }

  /// Получение бронирований для поездки
  Future<List<Booking>> getRideBookings(String rideId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: 'ride_id = ?',
      whereArgs: [rideId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Booking.fromMap(map)).toList();
  }

  /// Получение заявок для водителя
  Future<List<Booking>> getDriverBookingRequests(String driverId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT b.*, r.driver_id 
      FROM bookings b
      JOIN rides r ON b.ride_id = r.id
      WHERE r.driver_id = ? AND b.status = 'pending'
      ORDER BY b.created_at DESC
    ''',
      [driverId],
    );
    return maps.map((map) => Booking.fromMap(map)).toList();
  }

  /// Подтверждение бронирования
  Future<void> confirmBooking(String bookingId) async {
    final db = await database;
    await db.update(
      'bookings',
      {
        'status': BookingStatus.confirmed.value,
        'confirmed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [bookingId],
    );
    debugPrint('Подтверждено бронирование: $bookingId');
  }

  /// Отклонение бронирования
  Future<void> rejectBooking(String bookingId, String reason) async {
    final db = await database;
    await db.update(
      'bookings',
      {
        'status': BookingStatus.rejected.value,
        'rejected_at': DateTime.now().toIso8601String(),
        'rejection_reason': reason,
      },
      where: 'id = ?',
      whereArgs: [bookingId],
    );
    debugPrint('Отклонено бронирование: $bookingId');
  }

  /// Обновление бронирования
  Future<void> updateBooking(Booking booking) async {
    final db = await database;
    await db.update(
      'bookings',
      booking.toMap(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
    debugPrint('Обновлено бронирование: ${booking.id}');
  }

  // ==================== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ====================

  /// Получение поездки по ID
  Future<Ride?> getRideById(String rideId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'rides',
      where: 'id = ?',
      whereArgs: [rideId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Ride.fromMap(maps.first);
  }

  /// Получение бронирования по ID
  Future<Booking?> getBookingById(String bookingId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      where: 'id = ?',
      whereArgs: [bookingId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Booking.fromMap(maps.first);
  }

  /// Генерация UUID
  String generateId() => _uuid.v4();

  // ==================== МЕТОДЫ ДЛЯ ЧАТОВ ====================

  /// Создание нового чата
  Future<void> createChatConversation(ChatConversation conversation) async {
    final db = await database;
    await db.insert('chat_conversations', {
      'id': conversation.id,
      'ride_id': conversation.rideId,
      'driver_name': conversation.driverName,
      'route': conversation.route,
      'last_message': conversation.lastMessage,
      'last_message_time': conversation.lastMessageTime.toIso8601String(),
      'has_unread_messages': conversation.hasUnreadMessages ? 1 : 0,
      'unread_count': conversation.unreadCount,
      'driver_avatar': conversation.driverAvatar,
      'created_at': DateTime.now().toIso8601String(),
    });
    debugPrint('Создан чат: ${conversation.id}');
  }

  /// Получение всех чатов
  Future<List<ChatConversation>> getAllChatConversations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_conversations',
      orderBy: 'last_message_time DESC',
    );

    return maps.map((map) => ChatConversation.fromMap(map)).toList();
  }

  /// Поиск чата по ID поездки
  Future<ChatConversation?> findChatByRideId(String rideId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_conversations',
      where: 'ride_id = ?',
      whereArgs: [rideId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ChatConversation.fromMap(maps.first);
  }

  /// Обновление последнего сообщения в чате
  Future<void> updateChatLastMessage({
    required String conversationId,
    required String message,
    required bool isFromUser,
  }) async {
    final db = await database;

    // Получаем текущий чат
    final conversation = await getChatById(conversationId);
    if (conversation == null) return;

    // Обновляем данные
    final newUnreadCount = isFromUser ? 0 : conversation.unreadCount + 1;

    await db.update(
      'chat_conversations',
      {
        'last_message': message,
        'last_message_time': DateTime.now().toIso8601String(),
        'has_unread_messages': isFromUser ? 0 : 1,
        'unread_count': newUnreadCount,
      },
      where: 'id = ?',
      whereArgs: [conversationId],
    );
    debugPrint('Обновлено последнее сообщение в чате: $conversationId');
  }

  /// Отметить чат как прочитанный
  Future<void> markChatAsRead(String conversationId) async {
    final db = await database;
    await db.update(
      'chat_conversations',
      {'has_unread_messages': 0, 'unread_count': 0},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
    debugPrint('Чат отмечен как прочитанный: $conversationId');
  }

  /// Получение чата по ID
  Future<ChatConversation?> getChatById(String conversationId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ChatConversation.fromMap(maps.first);
  }

  /// Удаление чата
  Future<void> deleteChatConversation(String conversationId) async {
    final db = await database;
    await db.delete(
      'chat_conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
    // Также удаляем связанные сообщения
    await db.delete(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
    debugPrint('Удален чат: $conversationId');
  }

  /// Получение общего количества непрочитанных сообщений
  Future<int> getTotalUnreadChatsCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(unread_count) as total FROM chat_conversations',
    );
    return result.first['total'] as int? ?? 0;
  }

  // ===== МЕТОДЫ ДЛЯ РАБОТЫ С СООБЩЕНИЯМИ ЧАТА =====

  /// Создание сообщения в чате
  Future<void> createChatMessage({
    required String conversationId,
    required String rideId,
    required String text,
    required bool isFromUser,
  }) async {
    final db = await database;
    final messageId = _uuid.v4();

    await db.insert('chat_messages', {
      'id': messageId,
      'conversation_id': conversationId,
      'ride_id': rideId,
      'text': text,
      'is_from_user': isFromUser ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    });

    debugPrint('Создано сообщение в чате: $messageId');
  }

  /// Получение всех сообщений чата
  Future<List<Map<String, dynamic>>> getChatMessages(
    String conversationId,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );

    return maps;
  }

  /// Удаление всех сообщений чата
  Future<void> deleteChatMessages(String conversationId) async {
    final db = await database;
    await db.delete(
      'chat_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
    );
    debugPrint('Удалены сообщения чата: $conversationId');
  }

  /// Очистка базы данных (для тестирования)
  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('chat_messages');
    await db.delete('chat_conversations');
    await db.delete('bookings');
    await db.delete('rides');
    await db.delete('ride_requests');
    debugPrint('База данных очищена');
  }

  // ============================================================================
  // МЕТОДЫ ДЛЯ РАБОТЫ С ЗАПРОСАМИ НА ПОЕЗДКУ (RideRequest)
  // ============================================================================

  /// Создать новый запрос на поездку от пассажира
  Future<String> createRideRequest(RideRequest request) async {
    print('📝 [DB] Создание запроса на поездку: ${request.id}');
    final db = await database;

    try {
      await db.insert('ride_requests', request.toMap());
      print('✅ [DB] Запрос на поездку создан: ${request.id}');
      print('   Маршрут: ${request.fromAddress} → ${request.toAddress}');
      print('   Пассажиров: ${request.passengersCount}');
      print('   Макс. цена: ${request.maxPrice} ₽');
      return request.id;
    } catch (e) {
      print('❌ [DB] Ошибка создания запроса: $e');
      rethrow;
    }
  }

  /// Получить запросы пассажира
  Future<List<RideRequest>> getPassengerRideRequests(String passengerId) async {
    print('🔍 [DB] Загрузка запросов пассажира: $passengerId');
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'ride_requests',
        where: 'passenger_id = ?',
        whereArgs: [passengerId],
        orderBy: 'created_at DESC',
      );

      final requests = maps.map((map) => RideRequest.fromMap(map)).toList();
      print('✅ [DB] Найдено запросов: ${requests.length}');
      return requests;
    } catch (e) {
      print('❌ [DB] Ошибка загрузки запросов пассажира: $e');
      return [];
    }
  }

  /// Получить все активные запросы (для водителей)
  Future<List<RideRequest>> getActiveRideRequests() async {
    print('🔍 [DB] Загрузка активных запросов на поездку');
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'ride_requests',
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'created_at DESC',
      );

      final requests = maps.map((map) => RideRequest.fromMap(map)).toList();
      print('✅ [DB] Найдено активных запросов: ${requests.length}');
      return requests;
    } catch (e) {
      print('❌ [DB] Ошибка загрузки активных запросов: $e');
      return [];
    }
  }

  /// Получить запрос по ID
  Future<RideRequest?> getRideRequestById(String requestId) async {
    print('🔍 [DB] Поиск запроса: $requestId');
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'ride_requests',
        where: 'id = ?',
        whereArgs: [requestId],
        limit: 1,
      );

      if (maps.isEmpty) {
        print('⚠️ [DB] Запрос не найден');
        return null;
      }

      final request = RideRequest.fromMap(maps.first);
      print(
        '✅ [DB] Запрос найден: ${request.fromAddress} → ${request.toAddress}',
      );
      return request;
    } catch (e) {
      print('❌ [DB] Ошибка поиска запроса: $e');
      return null;
    }
  }

  /// Обновить статус запроса
  Future<void> updateRideRequestStatus({
    required String requestId,
    required RideRequestStatus status,
    String? acceptedByDriverId,
    double? agreedPrice,
  }) async {
    print(
      '🔄 [DB] Обновление статуса запроса $requestId → ${status.displayName}',
    );
    final db = await database;

    try {
      final Map<String, dynamic> updates = {'status': status.value};

      if (status == RideRequestStatus.accepted) {
        updates['accepted_at'] = DateTime.now().toIso8601String();
        if (acceptedByDriverId != null) {
          updates['accepted_by_driver_id'] = acceptedByDriverId;
        }
        if (agreedPrice != null) {
          updates['agreed_price'] = agreedPrice;
        }
      }

      await db.update(
        'ride_requests',
        updates,
        where: 'id = ?',
        whereArgs: [requestId],
      );

      print('✅ [DB] Статус запроса обновлен');
    } catch (e) {
      print('❌ [DB] Ошибка обновления статуса: $e');
      rethrow;
    }
  }

  /// Отменить запрос
  Future<void> cancelRideRequest(String requestId) async {
    print('🚫 [DB] Отмена запроса: $requestId');
    await updateRideRequestStatus(
      requestId: requestId,
      status: RideRequestStatus.cancelled,
    );
  }

  /// Удалить запрос
  Future<void> deleteRideRequest(String requestId) async {
    print('🗑️ [DB] Удаление запроса: $requestId');
    final db = await database;

    try {
      await db.delete('ride_requests', where: 'id = ?', whereArgs: [requestId]);
      print('✅ [DB] Запрос удален');
    } catch (e) {
      print('❌ [DB] Ошибка удаления запроса: $e');
      rethrow;
    }
  }

  /// Добавить тестовое бронирование для проверки взаимодействия водитель-пассажир
  Future<void> addTestBooking() async {
    print('🧪 [TEST] Добавление тестового бронирования...');

    try {
      // Находим активную поездку водителя
      final rides = await getDriverRides('driver_1');
      if (rides.isEmpty) {
        print('❌ [TEST] Нет поездок водителя driver_1 для теста');
        return;
      }

      // Берем первую активную поездку
      final activeRides = rides
          .where((r) => r.status == RideStatus.active)
          .toList();
      if (activeRides.isEmpty) {
        print('❌ [TEST] Нет активных поездок для теста');
        return;
      }

      final ride = activeRides.first;
      print('✅ [TEST] Найдена активная поездка: ${ride.id}');
      print('   Маршрут: ${ride.fromAddress} → ${ride.toAddress}');
      print('   Свободных мест: ${ride.availableSeats}');

      // Создаем тестовое бронирование
      final booking = Booking(
        id: generateId(),
        rideId: ride.id,
        passengerId: 'passenger_1',
        passengerName: 'Анна Тестовая',
        passengerPhone: '+7 (999) 123-45-67',
        seatsBooked: 1,
        totalPrice: ride.pricePerSeat * 1,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        rideFrom: ride.fromAddress,
        rideTo: ride.toAddress,
        rideDriverName: ride.driverName,
        rideDepartureTime: ride.departureTime,
      );

      await createBooking(booking);
      print('✅ [TEST] Тестовое бронирование создано!');
      print('   ID: ${booking.id}');
      print('   Статус: ${booking.status.value}');
      print('   Мест забронировано: ${booking.seatsBooked}');
      print('   Сумма: ${booking.totalPrice} ₽');
      print('');
      print(
        '💡 Теперь переключитесь на водителя и откройте "Заявки на бронирование"',
      );
    } catch (e, stackTrace) {
      print('❌ [TEST] Ошибка создания тестового бронирования: $e');
      print('   Stack trace: $stackTrace');
    }
  }

  /// Закрытие базы данных
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
