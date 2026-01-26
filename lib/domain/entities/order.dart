import 'package:equatable/equatable.dart';

/// Order status enum
enum OrderStatus {
  pending('pending'),
  confirmed('confirmed'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const OrderStatus(this.value);

  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Trip type enum
enum TripType {
  toAirport('toAirport'),
  fromAirport('fromAirport'),
  intercity('intercity');

  final String value;
  const TripType(this.value);

  static TripType fromString(String value) {
    return TripType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TripType.toAirport,
    );
  }
}

/// Domain entity: Passenger
class Passenger extends Equatable {
  final String type; // 'adult' | 'child'
  final String? seatType; // 'standard' | 'booster' | 'infant'
  final int? ageMonths;

  const Passenger({
    required this.type,
    this.seatType,
    this.ageMonths,
  });

  @override
  List<Object?> get props => [type, seatType, ageMonths];
}

/// Domain entity: Baggage Item
class BaggageItem extends Equatable {
  final String size; // 's' | 'm' | 'l'
  final int quantity;
  final double? pricePerExtraItem;

  const BaggageItem({
    required this.size,
    required this.quantity,
    this.pricePerExtraItem,
  });

  @override
  List<Object?> get props => [size, quantity, pricePerExtraItem];
}

/// Domain entity: Pet
class Pet extends Equatable {
  final String category; // 'upTo5kg' | 'over6kg'
  final String? breed;
  final double? cost;

  const Pet({
    required this.category,
    this.breed,
    this.cost,
  });

  @override
  List<Object?> get props => [category, breed, cost];
}

/// Domain entity: Order
/// 
/// This is a pure business logic entity with no dependencies on frameworks.
/// Used in the domain layer for use cases and business rules.
class Order extends Equatable {
  final String id;
  final String orderId; // Human-readable order ID (e.g., "ORD-20260126-001")
  final String? userId;
  final String? clientPhone;
  final String fromAddress;
  final String toAddress;
  final double? fromLat;
  final double? fromLon;
  final double? toLat;
  final double? toLon;
  final DateTime departureDate;
  final String? departureTime;
  final int passengerCount;
  final double totalPrice;
  final double finalPrice;
  final OrderStatus status;
  final TripType tripType;
  final String direction;
  final List<Passenger> passengers;
  final List<BaggageItem> baggage;
  final List<Pet> pets;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.orderId,
    this.userId,
    this.clientPhone,
    required this.fromAddress,
    required this.toAddress,
    this.fromLat,
    this.fromLon,
    this.toLat,
    this.toLon,
    required this.departureDate,
    this.departureTime,
    required this.passengerCount,
    required this.totalPrice,
    required this.finalPrice,
    required this.status,
    required this.tripType,
    required this.direction,
    this.passengers = const [],
    this.baggage = const [],
    this.pets = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if order is for guest (no user_id)
  bool get isGuestOrder => userId == null || userId!.isEmpty;

  /// Check if order has coordinates
  bool get hasCoordinates =>
      fromLat != null && fromLon != null && toLat != null && toLon != null;

  /// Get full departure datetime
  DateTime? get fullDepartureDateTime {
    if (departureTime == null) return null;
    
    final timeParts = departureTime!.split(':');
    if (timeParts.length != 2) return null;
    
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    
    if (hour == null || minute == null) return null;
    
    return DateTime(
      departureDate.year,
      departureDate.month,
      departureDate.day,
      hour,
      minute,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderId,
        userId,
        fromAddress,
        toAddress,
        status,
        createdAt,
      ];

  /// Copy with method for creating modified copies
  Order copyWith({
    String? id,
    String? orderId,
    String? userId,
    String? clientPhone,
    String? fromAddress,
    String? toAddress,
    double? fromLat,
    double? fromLon,
    double? toLat,
    double? toLon,
    DateTime? departureDate,
    String? departureTime,
    int? passengerCount,
    double? totalPrice,
    double? finalPrice,
    OrderStatus? status,
    TripType? tripType,
    String? direction,
    List<Passenger>? passengers,
    List<BaggageItem>? baggage,
    List<Pet>? pets,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      clientPhone: clientPhone ?? this.clientPhone,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      fromLat: fromLat ?? this.fromLat,
      fromLon: fromLon ?? this.fromLon,
      toLat: toLat ?? this.toLat,
      toLon: toLon ?? this.toLon,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      passengerCount: passengerCount ?? this.passengerCount,
      totalPrice: totalPrice ?? this.totalPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      status: status ?? this.status,
      tripType: tripType ?? this.tripType,
      direction: direction ?? this.direction,
      passengers: passengers ?? this.passengers,
      baggage: baggage ?? this.baggage,
      pets: pets ?? this.pets,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
