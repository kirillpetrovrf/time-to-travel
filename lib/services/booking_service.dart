import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking.dart';
import '../models/trip_type.dart';
import '../models/passenger_info.dart';
import '../models/baggage.dart'; // Содержит BaggageItem
import '../models/pet_info_v3.dart'; // Содержит PetInfo
import '../domain/entities/order.dart' as domain; // ✅ Domain entities для API
import 'auth_service.dart';
import 'notification_service.dart';
import 'orders_service.dart'; // ✅ Clean Architecture: OrdersService

/// ✅ ОБНОВЛЕНО: Использует Clean Architecture через OrdersService
/// Заказы сохраняются локально (SharedPreferences) + отправляются на PostgreSQL backend
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  // ✅ Clean Architecture: OrdersService фасад
  final OrdersService _ordersService = OrdersService();

  // Ключи для локального хранения (используется как fallback при отсутствии сети)
  static const String _offlineBookingsKey = 'offline_bookings';

  /// Создание нового бронирования (гибридный режим: API + локальное хранение)
  /// ✅ ОБНОВЛЕНО: Сначала отправка на backend, затем локальное сохранение
  Future<String> createBooking(Booking booking) async {
    debugPrint('📤 Создание бронирования: сначала отправка на backend API...');
    
    try {
      // 1. Парсим дату и время в DateTime для API
      DateTime departureDateTime;
      try {
        final timeComponents = booking.departureTime.split(':');
        final hour = int.parse(timeComponents[0]);
        final minute = int.parse(timeComponents[1]);
        
        departureDateTime = DateTime(
          booking.departureDate.year,
          booking.departureDate.month,
          booking.departureDate.day,
          hour,
          minute,
        );
      } catch (e) {
        debugPrint('⚠️ Ошибка парсинга времени: $e');
        departureDateTime = booking.departureDate;
      }

      // 2. Конвертируем багаж в domain типы (Booking → Domain)
      final domainBaggage = booking.baggage.map((b) => domain.BaggageItem(
        size: b.size.toString().split('.').last,
        quantity: b.quantity,
        pricePerExtraItem: b.pricePerExtraItem,
      )).toList();
      
      // Конвертируем животных в domain типы
      final domainPets = booking.pets.map((p) => domain.Pet(
        category: p.category.toString().split('.').last,
        breed: p.breed.isNotEmpty ? p.breed : null,
        cost: p.cost,
      )).toList();
      
      // Конвертируем пассажиров в domain типы
      final domainPassengers = booking.passengers.map((p) => domain.Passenger(
        type: p.type.toString().split('.').last,
        seatType: p.seatType?.toString().split('.').last,
        ageMonths: p.ageMonths,
      )).toList();

      // 3. Пытаемся отправить на backend через Clean Architecture
      debugPrint('🌐 Отправка заказа на backend через OrdersService...');
      
      final result = await _ordersService.createOrder(
        fromAddress: booking.pickupAddress ?? 'Не указан',
        toAddress: booking.dropoffAddress ?? 'Не указан',
        departureDate: departureDateTime,
        departureTime: booking.departureTime,
        passengerCount: booking.passengerCount,
        totalPrice: booking.totalPrice.toDouble(),
        finalPrice: booking.totalPrice.toDouble(),
        notes: booking.notes,
        tripType: booking.tripType.toString().split('.').last,
        direction: booking.direction.toString().split('.').last,
        passengers: domainPassengers,   // ✅ Domain passengers
        baggage: domainBaggage,          // ✅ Domain baggage
        pets: domainPets,                // ✅ Domain pets
        vehicleClass: booking.vehicleClass, // ✅ ДОБАВЛЕНО
      );
      
      if (!result.isSuccess) {
        throw Exception(result.error ?? 'Ошибка создания заказа на backend');
      }
      
      debugPrint('✅ Заказ успешно создан на backend с ID: ${result.order!.id}');
      
      // 4. Сохраняем локально с реальным ID от сервера
      final bookingId = result.order!.id;
      final bookingWithId = Booking(
        id: bookingId,
        clientId: booking.clientId,
        tripType: booking.tripType,
        direction: booking.direction,
        departureDate: booking.departureDate,
        departureTime: booking.departureTime,
        passengerCount: booking.passengerCount,
        pickupPoint: booking.pickupPoint,
        pickupAddress: booking.pickupAddress,
        dropoffAddress: booking.dropoffAddress,
        fromStop: booking.fromStop,
        toStop: booking.toStop,
        totalPrice: booking.totalPrice,
        status: booking.status,
        createdAt: booking.createdAt,
        notes: booking.notes,
        trackingPoints: booking.trackingPoints,
        baggage: booking.baggage,
        pets: booking.pets,
        passengers: booking.passengers,
        vehicleClass: booking.vehicleClass,
      );
      
      await _saveBookingToSharedPreferences(bookingWithId);
      
      // 5. Планируем уведомления
      await _planBookingNotifications(bookingWithId);
      
      return bookingId;
    } catch (e) {
      debugPrint('⚠️ Ошибка отправки на backend: $e');
      debugPrint('📱 Сохраняем заказ локально для последующей синхронизации');
      
      // Fallback: сохраняем локально, если сервер недоступен
      return _createOfflineBooking(booking);
    }
  }

  /// Сохранение бронирования в SharedPreferences
  Future<void> _saveBookingToSharedPreferences(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();
    final existingBookingsJson = prefs.getString(_offlineBookingsKey);
    List<Map<String, dynamic>> bookingsList = [];

    if (existingBookingsJson != null) {
      final decoded = jsonDecode(existingBookingsJson) as List<dynamic>;
      bookingsList = decoded.cast<Map<String, dynamic>>();
    }

    bookingsList.add(booking.toJson());
    await prefs.setString(_offlineBookingsKey, jsonEncode(bookingsList));
    debugPrint('💾 Бронирование ${booking.id} сохранено локально');
  }

  /// Планирование уведомлений для бронирования
  Future<void> _planBookingNotifications(Booking booking) async {
    debugPrint('🔔 Планирование уведомлений для заказа ${booking.id}');
    
    final notificationService = NotificationService.instance;
    final notificationsScheduled = 
        await notificationService.scheduleAllBookingNotifications(booking);

    if (notificationsScheduled) {
      debugPrint('✅ Уведомления успешно запланированы');
    } else {
      debugPrint('⚠️ Не все уведомления были запланированы');
    }

    final pending = await notificationService.getPendingNotifications();
    debugPrint('📋 Всего запланировано уведомлений: ${pending.length}');
  }

  /// Создание локального бронирования
  Future<String> _createOfflineBooking(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();

    // Генерируем уникальный ID
    final bookingId = 'offline_${DateTime.now().millisecondsSinceEpoch}';
    
    // Генерируем красивый номер заказа в формате 2026-01-27-123-G
    final now = DateTime.now();
    String typeSuffix;
    if (booking.tripType == TripType.group) {
      typeSuffix = 'G'; // Групповая
    } else if (booking.tripType == TripType.individual) {
      typeSuffix = 'I'; // Индивидуальная
    } else {
      typeSuffix = 'S'; // Свободная (Svobodnaya)
    }
    final orderId = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}-${(now.millisecondsSinceEpoch % 1000).toString().padLeft(3, '0')}-$typeSuffix';

    // Создаем бронирование с ID
    final bookingWithId = Booking(
      id: bookingId,
      orderId: orderId, // ✅ Красивый номер заказа
      clientId: booking.clientId,
      tripType: booking.tripType,
      direction: booking.direction,
      departureDate: booking.departureDate,
      departureTime: booking.departureTime,
      passengerCount: booking.passengerCount,
      pickupPoint: booking.pickupPoint,
      pickupAddress: booking.pickupAddress,
      dropoffAddress: booking.dropoffAddress,
      fromStop: booking.fromStop,
      toStop: booking.toStop,
      totalPrice: booking.totalPrice,
      status: booking.status,
      createdAt: booking.createdAt,
      notes: booking.notes,
      trackingPoints: booking.trackingPoints,
      baggage: booking.baggage,
      pets: booking.pets,
      passengers: booking.passengers,
      vehicleClass: booking.vehicleClass, // ← ДОБАВЛЯЕМ ПОЛЕ vehicleClass!
    );

    print('🚗 [SERVICE] Исходный booking.vehicleClass: ${booking.vehicleClass}');
    print('🚗 [SERVICE] bookingWithId.vehicleClass: ${bookingWithId.vehicleClass}');

    // Получаем существующие бронирования
    final existingBookingsJson = prefs.getString(_offlineBookingsKey);
    List<Map<String, dynamic>> bookingsList = [];

    if (existingBookingsJson != null) {
      final decoded = jsonDecode(existingBookingsJson) as List<dynamic>;
      bookingsList = decoded.cast<Map<String, dynamic>>();
    }

    // Добавляем новое бронирование
    final bookingJson = bookingWithId.toJson();
    print('💾 JSON бронирования: ${jsonEncode(bookingJson)}');
    print('💾 Багаж в JSON: ${bookingJson['baggage']}');
    print('🚗 [JSON] vehicleClass в JSON: ${bookingJson['vehicleClass']}');
    print('🚗 [JSON] booking.vehicleClass: ${bookingWithId.vehicleClass}');
    bookingsList.add(bookingJson);

    // Сохраняем обратно
    await prefs.setString(_offlineBookingsKey, jsonEncode(bookingsList));

    print('📱 Создано оффлайн бронирование: $bookingId');

    // 🔔 ПЛАНИРУЕМ УВЕДОМЛЕНИЯ СРАЗУ ПОСЛЕ СОЗДАНИЯ ЗАКАЗА
    debugPrint('🔔 ========================================');
    debugPrint('🔔 ПЛАНИРОВАНИЕ УВЕДОМЛЕНИЙ ДЛЯ ЗАКАЗА');
    debugPrint('🔔 ID заказа: $bookingId');
    debugPrint('🔔 Дата поездки: ${bookingWithId.departureDate}');
    debugPrint('🔔 Время поездки: ${bookingWithId.departureTime}');
    debugPrint('🔔 ========================================');

    final notificationService = NotificationService.instance;
    final notificationsScheduled = await notificationService
        .scheduleAllBookingNotifications(bookingWithId);

    if (notificationsScheduled) {
      debugPrint('✅ Уведомления успешно запланированы для заказа $bookingId');
    } else {
      debugPrint(
        '⚠️ Не все уведомления были запланированы для заказа $bookingId',
      );
    }

    // Показать список запланированных уведомлений
    final pending = await notificationService.getPendingNotifications();
    debugPrint(
      '📋 Всего запланировано уведомлений в системе: ${pending.length}',
    );
    for (final notification in pending) {
      debugPrint(
        '   - ID: ${notification.id}, Title: ${notification.title}, Payload: ${notification.payload}',
      );
    }

    return bookingId;
  }

  /// Получение бронирования по ID (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<Booking?> getBookingById(String bookingId) async {
    debugPrint('ℹ️ Поиск бронирования по ID локально (Firebase не подключен)');
    return _getOfflineBookingById(bookingId);
  }

  /// Получение локального бронирования по ID
  Future<Booking?> _getOfflineBookingById(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString(_offlineBookingsKey);

    print('🔍 [BOOKING] Поиск заказа по ID: $bookingId');

    if (bookingsJson != null) {
      final bookingsList = jsonDecode(bookingsJson) as List<dynamic>;
      print('🔍 [BOOKING] Найдено заказов в SharedPreferences: ${bookingsList.length}');

      for (final bookingData in bookingsList) {
        final jsonData = bookingData as Map<String, dynamic>;
        
        // Отладка: показываем vehicleClass в JSON ПЕРЕД парсингом
        print('🔍 [BOOKING] JSON данные заказа ${jsonData['id']}: vehicleClass = ${jsonData['vehicleClass']}');
        
        final booking = Booking.fromJson(jsonData);
        
        // Отладка: показываем vehicleClass ПОСЛЕ парсинга
        print('🔍 [BOOKING] ПОСЛЕ fromJson заказа ${booking.id}: vehicleClass = ${booking.vehicleClass}');
        
        if (booking.id == bookingId) {
          print('✅ [BOOKING] Найден заказ с ID: $bookingId, vehicleClass: ${booking.vehicleClass}');
          return booking;
        }
      }
    } else {
      print('❌ [BOOKING] SharedPreferences пуст, заказы не найдены');
    }
    print('❌ [BOOKING] Заказ с ID $bookingId не найден');
    return null;
  }

  /// Получение всех бронирований текущего клиента
  Future<List<Booking>> getCurrentClientBookings() async {
    // Получаем ID текущего пользователя через AuthService
    final currentUserId = await AuthService.instance.getCurrentUserId();

    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint('⚠️ ID текущего пользователя не найден');
      return [];
    }

    debugPrint('✅ Загрузка заказов для пользователя: $currentUserId');
    return getClientBookings(currentUserId);
  }

  /// Получение всех бронирований клиента (гибридный режим: API + локальные данные)
  /// ✅ ОБНОВЛЕНО: Использует Clean Architecture через OrdersService
  Future<List<Booking>> getClientBookings(String clientId) async {
    debugPrint('📥 Загрузка бронирований через OrdersService...');
    
    List<Booking> allBookings = [];
    
    try {
      // 1. Пытаемся загрузить с backend через Clean Architecture
      debugPrint('🌐 Загрузка заказов через OrdersService...');
      final ordersResult = await _ordersService.getOrders(limit: 100, forceRefresh: true);
      
      if (ordersResult.isSuccess && ordersResult.orders != null) {
        debugPrint('✅ Получено ${ordersResult.orders!.length} заказов с backend');
        
        // Конвертируем domain.Order → Booking
        final backendBookings = ordersResult.orders!.map((order) => _convertDomainOrderToBooking(order)).toList();
        
        allBookings.addAll(backendBookings);
        debugPrint('✅ Конвертировано ${backendBookings.length} заказов с backend');
      } else {
        debugPrint('⚠️ Ошибка загрузки с backend: ${ordersResult.error}');
      }
    } catch (e) {
      debugPrint('⚠️ Исключение при загрузке с backend: $e');
      debugPrint('📱 Загружаем только локальные данные');
    }
    
    // 2. Загружаем локальные данные (индивидуальные трансферы из SharedPreferences)
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString(_offlineBookingsKey);
      
      if (bookingsJson != null) {
        final decoded = jsonDecode(bookingsJson) as List<dynamic>;
        final localBookings = decoded
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('📦 Загружено ${localBookings.length} локальных индивидуальных трансферов');
        allBookings.addAll(localBookings);
      }
    } catch (e) {
      debugPrint('⚠️ Ошибка загрузки локальных данных: $e');
    }
    
    // 3. Удаляем дубликаты (по ID) - backend данные в приоритете
    final uniqueBookings = <String, Booking>{};
    for (final booking in allBookings) {
      uniqueBookings[booking.id] = booking;
    }
    
    final result = uniqueBookings.values.toList();
    
    // 4. Сортируем по дате (новые сначала)
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    debugPrint('✅ Всего загружено ${result.length} уникальных бронирований');
    return result;
  }

  /// Конвертация domain.Order → Booking
  Booking _convertDomainOrderToBooking(domain.Order order) {
    // Конвертируем passengers: domain → app models
    final passengers = order.passengers.map((p) {
      final passengerType = PassengerType.values.firstWhere(
        (e) => e.toString().split('.').last == p.type,
        orElse: () => PassengerType.adult,
      );
      
      ChildSeatType? seatType;
      if (p.seatType != null) {
        seatType = ChildSeatType.values.firstWhere(
          (e) => e.toString().split('.').last == p.seatType,
          orElse: () => ChildSeatType.none,
        );
      }
      
      return PassengerInfo(
        type: passengerType,
        seatType: seatType,
        useOwnSeat: false, // Domain не хранит это поле
        ageMonths: p.ageMonths,
      );
    }).toList();
    
    // Конвертируем baggage: domain → app models
    final baggage = order.baggage.map((b) {
      final baggageSize = BaggageSize.values.firstWhere(
        (e) => e.toString().split('.').last == b.size,
        orElse: () => BaggageSize.s,
      );
      
      return BaggageItem(
        size: baggageSize,
        quantity: b.quantity,
        pricePerExtraItem: b.pricePerExtraItem ?? 0.0,
        customDescription: null, // Domain не хранит это поле
      );
    }).toList();
    
    // Конвертируем pets: domain → app models
    final pets = order.pets.map((p) {
      final petCategory = PetCategory.values.firstWhere(
        (e) => e.toString().split('.').last == p.category,
        orElse: () => PetCategory.upTo5kgWithCarrier,
      );
      
      return PetInfo(
        category: petCategory,
        breed: p.breed ?? '',
        description: null, // Domain не хранит это поле
        agreementAccepted: true, // Если заказ создан, значит согласие было
      );
    }).toList();
    
    // Конвертируем TripType (domain → app)
    TripType tripType = TripType.values.firstWhere(
      (e) => e.toString().split('.').last == order.tripType.value,
      orElse: () => TripType.customRoute,
    );
    
    // Конвертируем Direction (String → app enum)
    Direction direction = Direction.values.firstWhere(
      (e) => e.toString().split('.').last == order.direction,
      orElse: () => Direction.donetskToRostov,
    );
    
    // Конвертируем OrderStatus → BookingStatus
    BookingStatus status;
    switch (order.status) {
      case domain.OrderStatus.pending:
        status = BookingStatus.pending;
        break;
      case domain.OrderStatus.confirmed:
        status = BookingStatus.confirmed;
        break;
      case domain.OrderStatus.inProgress:
        status = BookingStatus.inProgress;
        break;
      case domain.OrderStatus.completed:
        status = BookingStatus.completed;
        break;
      case domain.OrderStatus.cancelled:
        status = BookingStatus.cancelled;
        break;
    }
    
    return Booking(
      id: order.id,
      orderId: order.orderId, // ✅ Красивый номер заказа (2026-01-26-069-G)
      clientId: order.userId ?? '',  // ✅ userId nullable в domain
      tripType: tripType,
      direction: direction,
      departureDate: order.departureDate,
      departureTime: order.departureTime ?? '00:00',
      passengerCount: order.passengerCount,
      pickupPoint: null,
      pickupAddress: order.fromAddress,
      dropoffAddress: order.toAddress,
      fromStop: null,
      toStop: null,
      totalPrice: order.totalPrice.toInt(),
      status: status,
      createdAt: order.createdAt,
      notes: order.notes,
      trackingPoints: const [],
      passengers: passengers,
      baggage: baggage,
      pets: pets,
      vehicleClass: order.vehicleClass, // ✅ ИСПРАВЛЕНО - теперь берём из Order
    );
  }

  /// Получение всех активных бронирований
  /// ✅ ОБНОВЛЕНО: Использует Clean Architecture через OrdersService
  Future<List<Booking>> getActiveBookings() async {
    debugPrint('🔍 Получение активных бронирований через OrdersService...');
    
    try {
      // Получаем все заказы через Clean Architecture
      final result = await _ordersService.getOrders(limit: 100, forceRefresh: true);
      
      if (!result.isSuccess || result.orders == null) {
        debugPrint('❌ Ошибка загрузки заказов: ${result.error}');
        return _getOfflineActiveBookings();
      }
      
      debugPrint('📥 Получено ${result.orders!.length} заказов с сервера');
      
      // Конвертируем domain.Order → Booking и фильтруем активные
      final bookings = <Booking>[];
      for (final order in result.orders!) {
        try {
          // Фильтруем только активные статусы
          if (order.status == domain.OrderStatus.pending ||
              order.status == domain.OrderStatus.confirmed ||
              order.status == domain.OrderStatus.inProgress) {
            bookings.add(_convertDomainOrderToBooking(order));
          }
        } catch (e) {
          debugPrint('⚠️ Ошибка конвертации заказа ${order.id}: $e');
        }
      }
      
      debugPrint('✅ Успешно загружено ${bookings.length} активных заказов');
      return bookings;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки заказов с сервера: $e');
      debugPrint('⚠️ Fallback: загружаем локальные заказы');
      return _getOfflineActiveBookings();
    }
  }

  /// Получение локальных активных бронирований
  Future<List<Booking>> _getOfflineActiveBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString(_offlineBookingsKey);

    if (bookingsJson == null) return [];

    final bookingsList = jsonDecode(bookingsJson) as List<dynamic>;
    final activeBookings = <Booking>[];

    for (final bookingData in bookingsList) {
      final booking = Booking.fromJson(bookingData as Map<String, dynamic>);

      // Фильтруем активные статусы
      if ([
        BookingStatus.pending,
        BookingStatus.confirmed,
        BookingStatus.assigned,
        BookingStatus.inProgress,
      ].contains(booking.status)) {
        activeBookings.add(booking);
      }
    }

    // Сортируем по дате отправления
    activeBookings.sort((a, b) => a.departureDate.compareTo(b.departureDate));

    return activeBookings;
  }

  /// Получение бронирований по дате (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<List<Booking>> getBookingsByDate(DateTime date) async {
    debugPrint(
      'ℹ️ Получение бронирований по дате локально (Firebase не подключен)',
    );
    // В будущем здесь будет запрос к Firebase
    return [];
  }

  /// Обновление статуса бронирования (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    debugPrint(
      'ℹ️ Обновление статуса бронирования локально (Firebase не подключен)',
    );
    // В будущем здесь будет обновление в Firebase
  }

  /// Назначение транспорта на бронирование (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> assignVehicle(String bookingId, String vehicleId) async {
    debugPrint('ℹ️ Назначение транспорта локально (Firebase не подключен)');
    // В будущем здесь будет обновление в Firebase
  }

  /// Добавление точки отслеживания (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> addTrackingPoint(String bookingId, TrackingPoint point) async {
    debugPrint(
      'ℹ️ Добавление точки отслеживания локально (Firebase не подключен)',
    );
    // В будущем здесь будет обновление в Firebase
  }

  /// Обновление бронирования (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> updateBooking(Booking booking) async {
    debugPrint('ℹ️ Обновление бронирования локально (Firebase не подключен)');
    // В будущем здесь будет обновление в Firebase
  }

  /// Отмена бронирования (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<void> cancelBooking(String bookingId, [String? reason]) async {
    debugPrint('ℹ️ Отмена бронирования локально (Firebase не подключен)');
    await _cancelOfflineBooking(bookingId, reason);
  }

  /// НОВОЕ: Отмена оффлайн бронирования
  Future<void> _cancelOfflineBooking(String bookingId, [String? reason]) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString(_offlineBookingsKey);

    if (bookingsJson != null) {
      final bookingsList = jsonDecode(bookingsJson) as List<dynamic>;

      // Находим и обновляем статус бронирования
      for (int i = 0; i < bookingsList.length; i++) {
        final bookingData = bookingsList[i] as Map<String, dynamic>;
        if (bookingData['id'] == bookingId) {
          bookingData['status'] = BookingStatus.cancelled.toString();
          bookingData['updatedAt'] = DateTime.now().toIso8601String();
          if (reason != null) {
            bookingData['notes'] = reason;
          }
          break;
        }
      }

      // Сохраняем обновленный список
      await prefs.setString(_offlineBookingsKey, jsonEncode(bookingsList));
      print('📱 Бронирование $bookingId отменено в оффлайн режиме');
    }
  }

  /// Получение статистики по бронированиям (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<Map<String, int>> getBookingStats() async {
    debugPrint(
      'ℹ️ Получение статистики бронирований локально (Firebase не подключен)',
    );
    // В будущем здесь будет запрос к Firebase
    final stats = <String, int>{};
    for (final status in BookingStatus.values) {
      stats[status.toString()] = 0;
    }
    return stats;
  }
}
