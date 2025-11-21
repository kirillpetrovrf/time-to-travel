/// Модель поездки
class Ride {
  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String fromAddress;
  final String toAddress;
  final String fromDistrict;
  final String toDistrict;
  final String? fromDetails;
  final String? toDetails;
  final DateTime departureTime;
  final int availableSeats;
  final int totalSeats;
  final double pricePerSeat;
  final RideStatus status;
  final String? description;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const Ride({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.fromAddress,
    required this.toAddress,
    required this.fromDistrict,
    required this.toDistrict,
    this.fromDetails,
    this.toDetails,
    required this.departureTime,
    required this.availableSeats,
    required this.totalSeats,
    required this.pricePerSeat,
    required this.status,
    this.description,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  /// Создание из Map (для SQLite)
  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'] as String,
      driverId: map['driver_id'] as String,
      driverName: map['driver_name'] as String,
      driverPhone: map['driver_phone'] as String,
      fromAddress: map['from_address'] as String,
      toAddress: map['to_address'] as String,
      fromDistrict: map['from_district'] as String,
      toDistrict: map['to_district'] as String,
      fromDetails: map['from_details'] as String?,
      toDetails: map['to_details'] as String?,
      departureTime: DateTime.parse(map['departure_time'] as String),
      availableSeats: map['available_seats'] as int,
      totalSeats: map['total_seats'] as int,
      pricePerSeat: map['price_per_seat'] as double,
      status: RideStatus.fromString(map['status'] as String),
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  /// Преобразование в Map (для SQLite)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'from_address': fromAddress,
      'to_address': toAddress,
      'from_district': fromDistrict,
      'to_district': toDistrict,
      'from_details': fromDetails,
      'to_details': toDetails,
      'departure_time': departureTime.toIso8601String(),
      'available_seats': availableSeats,
      'total_seats': totalSeats,
      'price_per_seat': pricePerSeat,
      'status': status.value,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Копирование с изменениями
  Ride copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? fromAddress,
    String? toAddress,
    String? fromDistrict,
    String? toDistrict,
    String? fromDetails,
    String? toDetails,
    DateTime? departureTime,
    int? availableSeats,
    int? totalSeats,
    double? pricePerSeat,
    RideStatus? status,
    String? description,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return Ride(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      fromDistrict: fromDistrict ?? this.fromDistrict,
      toDistrict: toDistrict ?? this.toDistrict,
      fromDetails: fromDetails ?? this.fromDetails,
      toDetails: toDetails ?? this.toDetails,
      departureTime: departureTime ?? this.departureTime,
      availableSeats: availableSeats ?? this.availableSeats,
      totalSeats: totalSeats ?? this.totalSeats,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      status: status ?? this.status,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  String toString() {
    return 'Ride(id: $id, from: $fromDistrict, to: $toDistrict, status: ${status.displayName})';
  }
}

/// Статусы поездки
enum RideStatus {
  active('active', 'Активна'),
  inProgress('in_progress', 'В пути'),
  completed('completed', 'Завершена'),
  cancelled('cancelled', 'Отменена');

  const RideStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static RideStatus fromString(String value) {
    return RideStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RideStatus.active,
    );
  }
}
