/// Модель бронирования поездки
class Booking {
  final String id;
  final String rideId;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final int seatsBooked;
  final double totalPrice;
  final BookingStatus status;
  final String? pickupPoint;
  final String? dropoffPoint;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;

  // Информация о поездке (для удобства отображения)
  final String? rideFrom;
  final String? rideTo;
  final String? rideDriverName;
  final DateTime? rideDepartureTime;

  const Booking({
    required this.id,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    required this.seatsBooked,
    required this.totalPrice,
    required this.status,
    this.pickupPoint,
    this.dropoffPoint,
    required this.createdAt,
    this.confirmedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.rideFrom,
    this.rideTo,
    this.rideDriverName,
    this.rideDepartureTime,
  });

  /// Создание из Map (для SQLite)
  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      rideId: map['ride_id'] as String,
      passengerId: map['passenger_id'] as String,
      passengerName: map['passenger_name'] as String,
      passengerPhone: map['passenger_phone'] as String,
      seatsBooked: map['seats_booked'] as int,
      totalPrice: map['total_price'] as double,
      status: BookingStatus.fromString(map['status'] as String),
      pickupPoint: map['pickup_point'] as String?,
      dropoffPoint: map['dropoff_point'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      confirmedAt: map['confirmed_at'] != null
          ? DateTime.parse(map['confirmed_at'] as String)
          : null,
      rejectedAt: map['rejected_at'] != null
          ? DateTime.parse(map['rejected_at'] as String)
          : null,
      rejectionReason: map['rejection_reason'] as String?,
      rideFrom: map['ride_from'] as String?,
      rideTo: map['ride_to'] as String?,
      rideDriverName: map['ride_driver_name'] as String?,
      rideDepartureTime: map['ride_departure_time'] != null
          ? DateTime.parse(map['ride_departure_time'] as String)
          : null,
    );
  }

  /// Преобразование в Map (для SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ride_id': rideId,
      'passenger_id': passengerId,
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      'seats_booked': seatsBooked,
      'total_price': totalPrice,
      'status': status.value,
      'pickup_point': pickupPoint,
      'dropoff_point': dropoffPoint,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'rejected_at': rejectedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'ride_from': rideFrom,
      'ride_to': rideTo,
      'ride_driver_name': rideDriverName,
      'ride_departure_time': rideDepartureTime?.toIso8601String(),
    };
  }

  /// Копирование с изменениями
  Booking copyWith({
    String? id,
    String? rideId,
    String? passengerId,
    String? passengerName,
    String? passengerPhone,
    int? seatsBooked,
    double? totalPrice,
    BookingStatus? status,
    String? pickupPoint,
    String? dropoffPoint,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? rejectedAt,
    String? rejectionReason,
    String? rideFrom,
    String? rideTo,
    String? rideDriverName,
    DateTime? rideDepartureTime,
  }) {
    return Booking(
      id: id ?? this.id,
      rideId: rideId ?? this.rideId,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      seatsBooked: seatsBooked ?? this.seatsBooked,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      pickupPoint: pickupPoint ?? this.pickupPoint,
      dropoffPoint: dropoffPoint ?? this.dropoffPoint,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      rideFrom: rideFrom ?? this.rideFrom,
      rideTo: rideTo ?? this.rideTo,
      rideDriverName: rideDriverName ?? this.rideDriverName,
      rideDepartureTime: rideDepartureTime ?? this.rideDepartureTime,
    );
  }

  @override
  String toString() {
    return 'Booking(id: $id, rideId: $rideId, status: ${status.displayName}, seats: $seatsBooked, price: $totalPrice)';
  }
}

/// Статусы бронирования
enum BookingStatus {
  pending('pending', 'Ожидает подтверждения'),
  confirmed('confirmed', 'Подтверждено'),
  inProgress('in_progress', 'В пути'),
  completed('completed', 'Завершено'),
  cancelled('cancelled', 'Отменено'),
  rejected('rejected', 'Отклонено');

  const BookingStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}
