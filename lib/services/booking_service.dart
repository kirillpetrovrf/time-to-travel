import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  // НОВОЕ: Ключи для оффлайн хранения
  static const String _offlineBookingsKey = 'offline_bookings';
  static const String _isOfflineModeKey = 'is_offline_mode';

  // НОВОЕ: Проверка оффлайн режима
  Future<bool> _isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isOfflineModeKey) ?? true;
  }

  /// Создание нового бронирования (с поддержкой оффлайн режима)
  Future<String> createBooking(Booking booking) async {
    if (await _isOfflineMode()) {
      return _createOfflineBooking(booking);
    } else {
      final docRef = await _firestore
          .collection(_collection)
          .add(booking.toJson());
      return docRef.id;
    }
  }

  /// НОВОЕ: Создание оффлайн бронирования
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
    bookingsList.add(bookingWithId.toJson());

    // Сохраняем обратно
    await prefs.setString(_offlineBookingsKey, jsonEncode(bookingsList));

    print('📱 Создано оффлайн бронирование: $bookingId');
    return bookingId;
  }

  /// Получение бронирования по ID (с поддержкой оффлайн режима)
  Future<Booking?> getBookingById(String bookingId) async {
    if (await _isOfflineMode()) {
      return _getOfflineBookingById(bookingId);
    } else {
      final doc = await _firestore.collection(_collection).doc(bookingId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }
      return null;
    }
  }

  /// НОВОЕ: Получение оффлайн бронирования по ID
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

  /// Получение всех бронирований клиента (с поддержкой оффлайн режима)
  Future<List<Booking>> getClientBookings(String clientId) async {
    if (await _isOfflineMode()) {
      return _getOfflineClientBookings(clientId);
    } else {
      final query = await _firestore
          .collection(_collection)
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }).toList();
    }
  }

  /// НОВОЕ: Получение оффлайн бронирований клиента
  Future<List<Booking>> _getOfflineClientBookings(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getString(_offlineBookingsKey);

    if (bookingsJson == null) return [];

    final bookingsList = jsonDecode(bookingsJson) as List<dynamic>;
    final clientBookings = <Booking>[];

    for (final bookingData in bookingsList) {
      final booking = Booking.fromJson(bookingData as Map<String, dynamic>);
      if (booking.clientId == clientId) {
        clientBookings.add(booking);
      }
    }

    // Сортируем по дате создания (самые новые сначала)
    clientBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return clientBookings;
  }

  /// Получение всех активных бронирований (с поддержкой оффлайн режима)
  Future<List<Booking>> getActiveBookings() async {
    if (await _isOfflineMode()) {
      return _getOfflineActiveBookings();
    } else {
      final query = await _firestore
          .collection(_collection)
          .where(
            'status',
            whereIn: [
              BookingStatus.pending.toString(),
              BookingStatus.confirmed.toString(),
              BookingStatus.assigned.toString(),
              BookingStatus.inProgress.toString(),
            ],
          )
          .orderBy('departureDate')
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }).toList();
    }
  }

  /// НОВОЕ: Получение оффлайн активных бронирований
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

  /// Получение бронирований по дате
  Future<List<Booking>> getBookingsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = await _firestore
        .collection(_collection)
        .where(
          'departureDate',
          isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
        )
        .where('departureDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .orderBy('departureDate')
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Booking.fromJson(data);
    }).toList();
  }

  /// Обновление статуса бронирования
  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': status.toString(),
    });
  }

  /// Назначение транспорта на бронирование
  Future<void> assignVehicle(String bookingId, String vehicleId) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'assignedVehicleId': vehicleId,
      'status': BookingStatus.assigned.toString(),
    });
  }

  /// Добавление точки отслеживания
  Future<void> addTrackingPoint(String bookingId, TrackingPoint point) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'trackingPoints': FieldValue.arrayUnion([point.toJson()]),
    });
  }

  /// Обновление бронирования
  Future<void> updateBooking(Booking booking) async {
    final data = booking.toJson();
    data.remove('id'); // Удаляем ID из данных
    await _firestore.collection(_collection).doc(booking.id).update(data);
  }

  /// Отмена бронирования (с поддержкой оффлайн режима)
  Future<void> cancelBooking(String bookingId, [String? reason]) async {
    if (await _isOfflineMode()) {
      await _cancelOfflineBooking(bookingId, reason);
    } else {
      final updateData = {'status': BookingStatus.cancelled.toString()};
      if (reason != null) {
        updateData['notes'] = reason;
      }
      await _firestore
          .collection(_collection)
          .doc(bookingId)
          .update(updateData);
    }
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

  /// Получение статистики по бронированиям
  Future<Map<String, int>> getBookingStats() async {
    final allBookings = await _firestore.collection(_collection).get();

    final stats = <String, int>{};
    for (final status in BookingStatus.values) {
      stats[status.toString()] = 0;
    }

    for (final doc in allBookings.docs) {
      final data = doc.data();
      final status = data['status'] as String;
      stats[status] = (stats[status] ?? 0) + 1;
    }

    return stats;
  }
}
