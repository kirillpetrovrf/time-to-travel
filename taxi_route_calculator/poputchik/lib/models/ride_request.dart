import 'package:uuid/uuid.dart';

/// Запрос на поездку от пассажира
/// Пассажир создает запрос с маршрутом и условиями, водители могут откликнуться
class RideRequest {
  final String id;
  final String passengerId;
  final String passengerName;

  // Маршрут
  final String fromDistrict;
  final String fromAddress;
  final double fromLatitude;
  final double fromLongitude;

  final String toDistrict;
  final String toAddress;
  final double toLatitude;
  final double toLongitude;

  // Детали поездки
  final DateTime departureTime;
  final int passengersCount; // Сколько человек нужно довезти
  final double maxPrice; // Максимальная цена, которую готов заплатить пассажир

  // Дополнительная информация
  final String? comment; // Комментарий от пассажира

  // Статус и метаданные
  final RideRequestStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final String? acceptedByDriverId; // ID водителя, который принял запрос
  final double? agreedPrice; // Согласованная цена

  RideRequest({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.fromDistrict,
    required this.fromAddress,
    required this.fromLatitude,
    required this.fromLongitude,
    required this.toDistrict,
    required this.toAddress,
    required this.toLatitude,
    required this.toLongitude,
    required this.departureTime,
    required this.passengersCount,
    required this.maxPrice,
    this.comment,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.acceptedByDriverId,
    this.agreedPrice,
  });

  /// Создать новый запрос на поездку
  factory RideRequest.create({
    required String passengerId,
    required String passengerName,
    required String fromDistrict,
    required String fromAddress,
    required double fromLatitude,
    required double fromLongitude,
    required String toDistrict,
    required String toAddress,
    required double toLatitude,
    required double toLongitude,
    required DateTime departureTime,
    required int passengersCount,
    required double maxPrice,
    String? comment,
  }) {
    return RideRequest(
      id: const Uuid().v4(),
      passengerId: passengerId,
      passengerName: passengerName,
      fromDistrict: fromDistrict,
      fromAddress: fromAddress,
      fromLatitude: fromLatitude,
      fromLongitude: fromLongitude,
      toDistrict: toDistrict,
      toAddress: toAddress,
      toLatitude: toLatitude,
      toLongitude: toLongitude,
      departureTime: departureTime,
      passengersCount: passengersCount,
      maxPrice: maxPrice,
      comment: comment,
      status: RideRequestStatus.pending,
      createdAt: DateTime.now(),
    );
  }

  /// Конвертация в Map для SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passenger_id': passengerId,
      'passenger_name': passengerName,
      'from_district': fromDistrict,
      'from_address': fromAddress,
      'from_latitude': fromLatitude,
      'from_longitude': fromLongitude,
      'to_district': toDistrict,
      'to_address': toAddress,
      'to_latitude': toLatitude,
      'to_longitude': toLongitude,
      'departure_time': departureTime.toIso8601String(),
      'passengers_count': passengersCount,
      'max_price': maxPrice,
      'comment': comment,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'accepted_by_driver_id': acceptedByDriverId,
      'agreed_price': agreedPrice,
    };
  }

  /// Создать из Map (из SQLite)
  factory RideRequest.fromMap(Map<String, dynamic> map) {
    return RideRequest(
      id: map['id'] as String,
      passengerId: map['passenger_id'] as String,
      passengerName: map['passenger_name'] as String,
      fromDistrict: map['from_district'] as String,
      fromAddress: map['from_address'] as String,
      fromLatitude: map['from_latitude'] as double,
      fromLongitude: map['from_longitude'] as double,
      toDistrict: map['to_district'] as String,
      toAddress: map['to_address'] as String,
      toLatitude: map['to_latitude'] as double,
      toLongitude: map['to_longitude'] as double,
      departureTime: DateTime.parse(map['departure_time'] as String),
      passengersCount: map['passengers_count'] as int,
      maxPrice: map['max_price'] as double,
      comment: map['comment'] as String?,
      status: RideRequestStatus.fromValue(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      acceptedAt: map['accepted_at'] != null
          ? DateTime.parse(map['accepted_at'] as String)
          : null,
      acceptedByDriverId: map['accepted_by_driver_id'] as String?,
      agreedPrice: map['agreed_price'] as double?,
    );
  }

  /// Копировать с изменениями
  RideRequest copyWith({
    String? id,
    String? passengerId,
    String? passengerName,
    String? fromDistrict,
    String? fromAddress,
    double? fromLatitude,
    double? fromLongitude,
    String? toDistrict,
    String? toAddress,
    double? toLatitude,
    double? toLongitude,
    DateTime? departureTime,
    int? passengersCount,
    double? maxPrice,
    String? comment,
    RideRequestStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    String? acceptedByDriverId,
    double? agreedPrice,
  }) {
    return RideRequest(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      fromDistrict: fromDistrict ?? this.fromDistrict,
      fromAddress: fromAddress ?? this.fromAddress,
      fromLatitude: fromLatitude ?? this.fromLatitude,
      fromLongitude: fromLongitude ?? this.fromLongitude,
      toDistrict: toDistrict ?? this.toDistrict,
      toAddress: toAddress ?? this.toAddress,
      toLatitude: toLatitude ?? this.toLatitude,
      toLongitude: toLongitude ?? this.toLongitude,
      departureTime: departureTime ?? this.departureTime,
      passengersCount: passengersCount ?? this.passengersCount,
      maxPrice: maxPrice ?? this.maxPrice,
      comment: comment ?? this.comment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      acceptedByDriverId: acceptedByDriverId ?? this.acceptedByDriverId,
      agreedPrice: agreedPrice ?? this.agreedPrice,
    );
  }
}

/// Статус запроса на поездку
enum RideRequestStatus {
  pending('pending', 'Ожидает откликов'),
  accepted('accepted', 'Принят водителем'),
  inProgress('in_progress', 'В пути'),
  completed('completed', 'Завершен'),
  cancelled('cancelled', 'Отменен');

  const RideRequestStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static RideRequestStatus fromValue(String value) {
    return RideRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RideRequestStatus.pending,
    );
  }
}
