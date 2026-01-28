import 'package:flutter/foundation.dart';
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

  /// Создание нового бронирования (отправка на backend API)
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
      
      // 4. Получаем ID от сервера
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
      
      // 5. Планируем уведомления
      await _planBookingNotifications(bookingWithId);
      
      return bookingId;
    } catch (e) {
      debugPrint('❌ Ошибка создания заказа: $e');
      // ✅ Не сохраняем локально - показываем ошибку пользователю
      rethrow;
    }
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

  /// Получение бронирования по ID (загрузка с backend)
  Future<Booking?> getBookingById(String bookingId) async {
    debugPrint('🔍 Поиск заказа по ID: $bookingId');
    
    try {
      // Загружаем с backend через OrdersService
      final result = await _ordersService.getOrderById(bookingId);
      
      if (result.isSuccess && result.order != null) {
        return _convertDomainOrderToBooking(result.order!);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Ошибка загрузки заказа: $e');
      return null;
    }
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
      final ordersResult = await _ordersService.getOrders(
        limit: 100,
        forceRefresh: true,
        userType: 'client', // ✅ Для клиента всегда используем режим 'client'
      );
      
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
    }
    
    // 2. Удаляем дубликаты (по ID) - backend данные в приоритете
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
      totalPrice: order.finalPrice.toInt(), // ✅ ИСПРАВЛЕНО: используем finalPrice вместо totalPrice
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
  /// 
  /// [userType] - Режим пользователя: 'client' видит только свои, 'dispatcher' видит все
  Future<List<Booking>> getActiveBookings({String? userType}) async {
    debugPrint('🔍 Получение активных бронирований через OrdersService...');
    
    try {
      // Получаем все заказы через Clean Architecture
      final result = await _ordersService.getOrders(
        limit: 100,
        forceRefresh: true,
        userType: userType, // ✅ ПЕРЕДАЁМ userType
      );
      
      if (!result.isSuccess || result.orders == null) {
        debugPrint('❌ Ошибка загрузки заказов: ${result.error}');
        return [];
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
      // ✅ Возвращаем пустой список вместо offline fallback
      return [];
    }
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

  /// Отмена бронирования (через backend API)
  Future<void> cancelBooking(String bookingId, [String? reason]) async {
    debugPrint('🔍 Отмена заказа: $bookingId');
    
    try {
      // Отменяем на backend через OrdersService
      final result = await _ordersService.cancelOrder(bookingId);
      
      if (!result.isSuccess) {
        throw Exception(result.error ?? 'Ошибка отмены заказа');
      }
      
      debugPrint('✅ Заказ $bookingId отменён');
    } catch (e) {
      debugPrint('❌ Ошибка отмены заказа: $e');
      rethrow;
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
