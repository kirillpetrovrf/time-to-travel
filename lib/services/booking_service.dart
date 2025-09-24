import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking.dart';

class BookingService {
  static final BookingService _instance = BookingService._internal();
  factory BookingService() => _instance;
  BookingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'bookings';

  /// Создание нового бронирования
  Future<String> createBooking(Booking booking) async {
    final docRef = await _firestore
        .collection(_collection)
        .add(booking.toJson());
    return docRef.id;
  }

  /// Получение бронирования по ID
  Future<Booking?> getBookingById(String bookingId) async {
    final doc = await _firestore.collection(_collection).doc(bookingId).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Booking.fromJson(data);
    }
    return null;
  }

  /// Получение всех бронирований клиента
  Future<List<Booking>> getClientBookings(String clientId) async {
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

  /// Получение всех активных бронирований
  Future<List<Booking>> getActiveBookings() async {
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

  /// Отмена бронирования
  Future<void> cancelBooking(String bookingId, String reason) async {
    await _firestore.collection(_collection).doc(bookingId).update({
      'status': BookingStatus.cancelled.toString(),
      'notes': reason,
    });
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
