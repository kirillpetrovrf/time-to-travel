import '../../domain/entities/order.dart';

/// Data model for Order (used in data layer)
/// 
/// This model knows how to serialize/deserialize from/to JSON
/// and how to convert to domain entity.
class OrderModel {
  final String id;
  final String orderId;
  final String? userId;
  final String? clientPhone;
  final String fromAddress;
  final String toAddress;
  final double? fromLat;
  final double? fromLon;
  final double? toLat;
  final double? toLon;
  final String departureDate; // ISO 8601 string
  final String? departureTime; // "HH:MM" format
  final int passengerCount;
  final double totalPrice;
  final double finalPrice;
  final String status;
  final String tripType;
  final String direction;
  final List<Map<String, dynamic>> passengers;
  final List<Map<String, dynamic>> baggage;
  final List<Map<String, dynamic>> pets;
  final String? notes;
  final String createdAt; // ISO 8601 string
  final String updatedAt; // ISO 8601 string

  const OrderModel({
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

  /// Create from JSON (API response)
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Backend may return {"order": {...}} or just {...}
    final data = json.containsKey('order') 
        ? json['order'] as Map<String, dynamic> 
        : json;

    return OrderModel(
      id: data['id'] as String,
      orderId: data['orderId'] as String? ?? data['id'] as String,
      userId: data['userId'] as String?,
      clientPhone: data['clientPhone'] as String?,
      fromAddress: data['fromAddress'] as String,
      toAddress: data['toAddress'] as String,
      fromLat: data['fromLat'] != null ? (data['fromLat'] as num).toDouble() : null,
      fromLon: data['fromLon'] != null ? (data['fromLon'] as num).toDouble() : null,
      toLat: data['toLat'] != null ? (data['toLat'] as num).toDouble() : null,
      toLon: data['toLon'] != null ? (data['toLon'] as num).toDouble() : null,
      departureDate: data['departureDate'] as String? ?? DateTime.now().toIso8601String(),
      departureTime: data['departureTime'] as String?,
      passengerCount: data['passengerCount'] as int? ?? 1,
      totalPrice: data['totalPrice'] != null 
          ? (data['totalPrice'] as num).toDouble() 
          : 0.0,
      finalPrice: data['finalPrice'] != null 
          ? (data['finalPrice'] as num).toDouble()
          : (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'pending',
      tripType: data['tripType'] as String? ?? 'toAirport',
      direction: data['direction'] as String? ?? '',
      passengers: data['passengers'] != null 
          ? (data['passengers'] as List).cast<Map<String, dynamic>>()
          : const [],
      baggage: data['baggage'] != null 
          ? (data['baggage'] as List).cast<Map<String, dynamic>>()
          : const [],
      pets: data['pets'] != null 
          ? (data['pets'] as List).cast<Map<String, dynamic>>()
          : const [],
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: data['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Convert to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      if (userId != null) 'userId': userId,
      if (clientPhone != null) 'clientPhone': clientPhone,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      if (fromLat != null) 'fromLat': fromLat,
      if (fromLon != null) 'fromLon': fromLon,
      if (toLat != null) 'toLat': toLat,
      if (toLon != null) 'toLon': toLon,
      'departureDate': departureDate,
      if (departureTime != null) 'departureTime': departureTime,
      'passengerCount': passengerCount,
      'totalPrice': totalPrice,
      'finalPrice': finalPrice,
      'status': status,
      'tripType': tripType,
      'direction': direction,
      if (passengers.isNotEmpty) 'passengers': passengers,
      if (baggage.isNotEmpty) 'baggage': baggage,
      if (pets.isNotEmpty) 'pets': pets,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Convert to domain entity
  Order toEntity() {
    return Order(
      id: id,
      orderId: orderId,
      userId: userId,
      clientPhone: clientPhone,
      fromAddress: fromAddress,
      toAddress: toAddress,
      fromLat: fromLat,
      fromLon: fromLon,
      toLat: toLat,
      toLon: toLon,
      departureDate: DateTime.parse(departureDate),
      departureTime: departureTime,
      passengerCount: passengerCount,
      totalPrice: totalPrice,
      finalPrice: finalPrice,
      status: OrderStatus.fromString(status),
      tripType: TripType.fromString(tripType),
      direction: direction,
      passengers: passengers.map((p) => Passenger(
        type: p['type'] as String,
        seatType: p['seatType'] as String?,
        ageMonths: p['ageMonths'] as int?,
      )).toList(),
      baggage: baggage.map((b) => BaggageItem(
        size: b['size'] as String,
        quantity: b['quantity'] as int,
        pricePerExtraItem: b['pricePerExtraItem'] != null
            ? (b['pricePerExtraItem'] as num).toDouble()
            : null,
      )).toList(),
      pets: pets.map((p) => Pet(
        category: p['category'] as String,
        breed: p['breed'] as String?,
        cost: p['cost'] != null ? (p['cost'] as num).toDouble() : null,
      )).toList(),
      notes: notes,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }

  /// Create from domain entity
  factory OrderModel.fromEntity(Order order) {
    return OrderModel(
      id: order.id,
      orderId: order.orderId,
      userId: order.userId,
      clientPhone: order.clientPhone,
      fromAddress: order.fromAddress,
      toAddress: order.toAddress,
      fromLat: order.fromLat,
      fromLon: order.fromLon,
      toLat: order.toLat,
      toLon: order.toLon,
      departureDate: order.departureDate.toIso8601String(),
      departureTime: order.departureTime,
      passengerCount: order.passengerCount,
      totalPrice: order.totalPrice,
      finalPrice: order.finalPrice,
      status: order.status.value,
      tripType: order.tripType.value,
      direction: order.direction,
      passengers: order.passengers.map((p) => {
        'type': p.type,
        if (p.seatType != null) 'seatType': p.seatType,
        if (p.ageMonths != null) 'ageMonths': p.ageMonths,
      }).toList(),
      baggage: order.baggage.map((b) => {
        'size': b.size,
        'quantity': b.quantity,
        if (b.pricePerExtraItem != null) 'pricePerExtraItem': b.pricePerExtraItem,
      }).toList(),
      pets: order.pets.map((p) => {
        'category': p.category,
        if (p.breed != null) 'breed': p.breed,
        if (p.cost != null) 'cost': p.cost,
      }).toList(),
      notes: order.notes,
      createdAt: order.createdAt.toIso8601String(),
      updatedAt: order.updatedAt.toIso8601String(),
    );
  }
}
