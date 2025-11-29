import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking.dart';
import '../models/trip_type.dart';
import '../models/route_stop.dart';
import 'auth_service.dart';
import 'notification_service.dart';
import 'offline_orders_service.dart';

/// ⚠️ ВАЖНО: Сейчас используется только SQLite/SharedPreferences
/// TODO: Интеграция с Firebase - реализуется позже
class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  // TODO: Интеграция с Firebase - реализуется позже
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // final String _collection = 'bookings';

  // Ключи для локального хранения
  static const String _offlineBookingsKey = 'offline_bookings';

  /// Создание нового бронирования (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<String> createBooking(Booking booking) async {
    debugPrint('ℹ️ Создание бронирования локально (Firebase не подключен)');
    return _createOfflineBooking(booking);
  }

  /// Создание локального бронирования
  Future<String> _createOfflineBooking(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();

    // Генерируем уникальный ID
    final bookingId = 'offline_${DateTime.now().millisecondsSinceEpoch}';

    // Создаем бронирование с ID
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
      trackingPoints: booking.trackingPoints,
      baggage: booking.baggage,
      pets: booking.pets,
      passengers: booking.passengers,
    );

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

    if (bookingsJson != null) {
      final bookingsList = jsonDecode(bookingsJson) as List<dynamic>;

      for (final bookingData in bookingsList) {
        final booking = Booking.fromJson(bookingData as Map<String, dynamic>);
        if (booking.id == bookingId) {
          return booking;
        }
      }
    }
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

  /// Получение всех бронирований клиента (локально)
  /// Загружает:
  /// 1. Индивидуальные трансферы из SharedPreferences (Booking)
  /// 2. Заказы такси из SQLite (TaxiOrder → конвертирует в Booking)
  Future<List<Booking>> getClientBookings(String clientId) async {
    debugPrint(
      'ℹ️ Получение бронирований клиента из SharedPreferences + SQLite',
    );
    
    try {
      // 1. Загружаем индивидуальные трансферы из SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final bookingsJson = prefs.getString(_offlineBookingsKey);
      List<Booking> individualBookings = [];
      
      if (bookingsJson != null) {
        final decoded = jsonDecode(bookingsJson) as List<dynamic>;
        individualBookings = decoded
            .map((json) => Booking.fromJson(json as Map<String, dynamic>))
            .toList();
        debugPrint('📦 [BOOKING] Загружено ${individualBookings.length} индивидуальных трансферов из SharedPreferences');
      }
      
      // 2. Загружаем заказы такси из SQLite (TaxiOrder)
      final taxiBookings = await _getTaxiOrdersAsBookings(clientId);
      debugPrint('📦 [BOOKING] Загружено ${taxiBookings.length} заказов такси из SQLite');
      
      // 3. Объединяем оба списка
      final allBookings = [...individualBookings, ...taxiBookings];
      
      // 4. Сортируем по дате (новые сначала)
      allBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('✅ [BOOKING] Всего загружено ${allBookings.length} бронирований (${individualBookings.length} индивидуальных + ${taxiBookings.length} такси)');
      return allBookings;
    } catch (e) {
      debugPrint('❌ [BOOKING] Ошибка загрузки бронирований: $e');
      return [];
    }
  }

  /// Конвертация TaxiOrder из SQLite в Booking для отображения
  Future<List<Booking>> _getTaxiOrdersAsBookings(String clientId) async {
    try {
      // Загружаем все заказы из SQLite
      final taxiOrders = await OfflineOrdersService.instance.getAllOrders();
      debugPrint('📦 [BOOKING] Загружено ${taxiOrders.length} заказов из SQLite');

      // Конвертируем TaxiOrder → Booking
      final bookings = taxiOrders.map((order) {
        // Создаём RouteStop объекты из координат и адресов TaxiOrder
        final fromStop = RouteStop(
          id: 'taxi_from_${order.orderId}',
          name: order.fromAddress,
          order: 0,
          latitude: order.fromPoint.latitude,
          longitude: order.fromPoint.longitude,
          priceFromStart: 0,
        );
        
        final toStop = RouteStop(
          id: 'taxi_to_${order.orderId}',
          name: order.toAddress,
          order: 1,
          latitude: order.toPoint.latitude,
          longitude: order.toPoint.longitude,
          priceFromStart: order.finalPrice.round(),
        );
        
        return Booking(
          id: order.orderId,
          clientId: clientId,
          tripType: TripType.customRoute, // ✅ Свободный маршрут (такси)
          direction: Direction.donetskToRostov, // Для customRoute не используется
          departureDate: order.timestamp, // Уже DateTime
          departureTime: 
              '${order.timestamp.hour.toString().padLeft(2, '0')}:${order.timestamp.minute.toString().padLeft(2, '0')}',
          passengerCount: 1, // TaxiOrder не хранит пассажиров, используем 1
          pickupAddress: order.fromAddress,
          dropoffAddress: order.toAddress,
          totalPrice: order.finalPrice.round(), // Округляем до int для Booking
          status: _convertOrderStatusToBookingStatus(order.status),
          createdAt: order.timestamp, // Уже DateTime
          baggage: [],
          pets: [],
          passengers: [],
          pickupPoint: null,
          fromStop: fromStop,  // ✅ Добавляем fromStop с адресом
          toStop: toStop,      // ✅ Добавляем toStop с адресом
        );
      }).toList();

      // Сортируем по дате (новые сначала)
      bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      debugPrint('✅ [BOOKING] Конвертировано в ${bookings.length} Booking объектов');
      return bookings;
    } catch (e) {
      debugPrint('❌ [BOOKING] Ошибка загрузки заказов: $e');
      return [];
    }
  }

  /// Конвертация статуса TaxiOrder → BookingStatus
  BookingStatus _convertOrderStatusToBookingStatus(String orderStatus) {
    switch (orderStatus.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'in_progress':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  /// Получение всех активных бронирований (локально)
  /// TODO: Интеграция с Firebase - реализуется позже
  Future<List<Booking>> getActiveBookings() async {
    debugPrint(
      'ℹ️ Получение активных бронирований локально (Firebase не подключен)',
    );
    return _getOfflineActiveBookings();
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
