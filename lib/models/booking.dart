import 'trip_type.dart';

enum BookingStatus {
  pending, // Ожидает подтверждения
  confirmed, // Подтверждена
  assigned, // Назначен водитель/машина
  inProgress, // В пути
  completed, // Завершена
  cancelled, // Отменена
}

class Vehicle {
  final String id;
  final String brand; // Марка
  final String model; // Модель
  final String licensePlate; // Гос. номер
  final VehicleClass vehicleClass;
  final int capacity; // Количество мест
  final String? driverName;
  final String? driverPhone;

  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.licensePlate,
    required this.vehicleClass,
    required this.capacity,
    this.driverName,
    this.driverPhone,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'licensePlate': licensePlate,
      'vehicleClass': vehicleClass.toString(),
      'capacity': capacity,
      'driverName': driverName,
      'driverPhone': driverPhone,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      licensePlate: json['licensePlate'] as String,
      vehicleClass: VehicleClass.values.firstWhere(
        (e) => e.toString() == json['vehicleClass'],
      ),
      capacity: json['capacity'] as int,
      driverName: json['driverName'] as String?,
      driverPhone: json['driverPhone'] as String?,
    );
  }
}

class Booking {
  final String id;
  final String clientId;
  final TripType tripType;
  final Direction direction;
  final DateTime departureDate;
  final String departureTime;
  final int passengerCount;
  final String? pickupAddress; // Для индивидуального трансфера
  final String? dropoffAddress; // Для индивидуального трансфера
  final String? pickupPoint; // Для групповых поездок
  final int totalPrice;
  final BookingStatus status;
  final DateTime createdAt;
  final String? assignedVehicleId;
  final String? notes;
  final List<TrackingPoint> trackingPoints; // Точки отслеживания

  const Booking({
    required this.id,
    required this.clientId,
    required this.tripType,
    required this.direction,
    required this.departureDate,
    required this.departureTime,
    required this.passengerCount,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupPoint,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.assignedVehicleId,
    this.notes,
    this.trackingPoints = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'tripType': tripType.toString(),
      'direction': direction.toString(),
      'departureDate': departureDate.toIso8601String(),
      'departureTime': departureTime,
      'passengerCount': passengerCount,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupPoint': pickupPoint,
      'totalPrice': totalPrice,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'assignedVehicleId': assignedVehicleId,
      'notes': notes,
      'trackingPoints': trackingPoints.map((e) => e.toJson()).toList(),
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      tripType: TripType.values.firstWhere(
        (e) => e.toString() == json['tripType'],
      ),
      direction: Direction.values.firstWhere(
        (e) => e.toString() == json['direction'],
      ),
      departureDate: DateTime.parse(json['departureDate'] as String),
      departureTime: json['departureTime'] as String,
      passengerCount: json['passengerCount'] as int,
      pickupAddress: json['pickupAddress'] as String?,
      dropoffAddress: json['dropoffAddress'] as String?,
      pickupPoint: json['pickupPoint'] as String?,
      totalPrice: json['totalPrice'] as int,
      status: BookingStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      assignedVehicleId: json['assignedVehicleId'] as String?,
      notes: json['notes'] as String?,
      trackingPoints: (json['trackingPoints'] as List? ?? [])
          .map((e) => TrackingPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TrackingPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? address;

  const TrackingPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
      'address': address,
    };
  }

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    return TrackingPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      address: json['address'] as String?,
    );
  }
}
