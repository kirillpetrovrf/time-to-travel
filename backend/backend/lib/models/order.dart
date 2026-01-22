import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import '../utils/db_helpers.dart';

part 'order.g.dart';

/// Статусы заказа
enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  String toDb() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromDb(String status) {
    switch (status) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'in_progress':
        return OrderStatus.inProgress;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

/// Классы автомобилей
enum VehicleClass {
  economy,
  comfort,
  business,
  minivan;

  String toDb() => name;

  static VehicleClass? fromDb(String? vehicleClass) {
    if (vehicleClass == null) return null;
    switch (vehicleClass) {
      case 'economy':
        return VehicleClass.economy;
      case 'comfort':
        return VehicleClass.comfort;
      case 'business':
        return VehicleClass.business;
      case 'minivan':
        return VehicleClass.minivan;
      default:
        return null;
    }
  }
}

/// Пассажир
@JsonSerializable()
class Passenger {
  final String name;
  final int? age;

  const Passenger({
    required this.name,
    this.age,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) =>
      _$PassengerFromJson(json);

  Map<String, dynamic> toJson() => _$PassengerToJson(this);
}

/// Багаж
@JsonSerializable()
class Baggage {
  final String type; // suitcase, bag, box
  final String size; // small, medium, large
  final int count;

  const Baggage({
    required this.type,
    required this.size,
    this.count = 1,
  });

  factory Baggage.fromJson(Map<String, dynamic> json) =>
      _$BaggageFromJson(json);

  Map<String, dynamic> toJson() => _$BaggageToJson(this);
}

/// Питомец
@JsonSerializable()
class Pet {
  final String type; // dog, cat, other
  final String? name;
  final double? weight;

  const Pet({
    required this.type,
    this.name,
    this.weight,
  });

  factory Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);

  Map<String, dynamic> toJson() => _$PetToJson(this);
}

/// Модель заказа
@JsonSerializable()
class Order {
  final String id;
  final String orderId; // Внешний ID для клиента
  final String? userId;

  // Координаты
  final double fromLat;
  final double fromLon;
  final double toLat;
  final double toLon;

  // Адреса
  final String fromAddress;
  final String toAddress;

  // Расстояние и цены
  final double distanceKm;
  final double rawPrice;
  final double finalPrice;
  final double baseCost;
  final double costPerKm;

  // Статус
  final OrderStatus status;

  // Информация о клиенте
  final String? clientName;
  final String? clientPhone;

  // Дата и время поездки
  final DateTime? departureDate;
  final String? departureTime;

  // Пассажиры, багаж, животные
  final List<Passenger>? passengers;
  final List<Baggage>? baggage;
  final List<Pet>? pets;

  // Заметки
  final String? notes;

  // Класс автомобиля
  final VehicleClass? vehicleClass;

  // Метаданные
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.orderId,
    this.userId,
    required this.fromLat,
    required this.fromLon,
    required this.toLat,
    required this.toLon,
    required this.fromAddress,
    required this.toAddress,
    required this.distanceKm,
    required this.rawPrice,
    required this.finalPrice,
    required this.baseCost,
    required this.costPerKm,
    required this.status,
    this.clientName,
    this.clientPhone,
    this.departureDate,
    this.departureTime,
    this.passengers,
    this.baggage,
    this.pets,
    this.notes,
    this.vehicleClass,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);

  factory Order.fromDb(Map<String, dynamic> row) {
    return Order(
      id: row['id'] as String,
      orderId: row['order_id'] as String,
      userId: row['user_id'] as String?,
      fromLat: (row['from_lat'] as num).toDouble(),
      fromLon: (row['from_lon'] as num).toDouble(),
      toLat: (row['to_lat'] as num).toDouble(),
      toLon: (row['to_lon'] as num).toDouble(),
      fromAddress: row['from_address'] as String,
      toAddress: row['to_address'] as String,
      distanceKm: (row['distance_km'] as num).toDouble(),
      rawPrice: (row['raw_price'] as num).toDouble(),
      finalPrice: (row['final_price'] as num).toDouble(),
      baseCost: (row['base_cost'] as num).toDouble(),
      costPerKm: (row['cost_per_km'] as num).toDouble(),
      status: OrderStatus.fromDb(row['status'] as String),
      clientName: row['client_name'] as String?,
      clientPhone: row['client_phone'] as String?,
      departureDate: row['departure_date'] != null
          ? parseDbDateTime(row['departure_date'])
          : null,
      departureTime: row['departure_time'] as String?,
      passengers: row['passengers'] != null
          ? (jsonDecode(row['passengers'] as String) as List)
              .map((e) => Passenger.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      baggage: row['baggage'] != null
          ? (jsonDecode(row['baggage'] as String) as List)
              .map((e) => Baggage.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      pets: row['pets'] != null
          ? (jsonDecode(row['pets'] as String) as List)
              .map((e) => Pet.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      notes: row['notes'] as String?,
      vehicleClass: VehicleClass.fromDb(row['vehicle_class'] as String?),
      createdAt: parseDbDateTime(row['created_at']),
      updatedAt: parseDbDateTime(row['updated_at']),
    );
  }

  Order copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? fromLat,
    double? fromLon,
    double? toLat,
    double? toLon,
    String? fromAddress,
    String? toAddress,
    double? distanceKm,
    double? rawPrice,
    double? finalPrice,
    double? baseCost,
    double? costPerKm,
    OrderStatus? status,
    String? clientName,
    String? clientPhone,
    DateTime? departureDate,
    String? departureTime,
    List<Passenger>? passengers,
    List<Baggage>? baggage,
    List<Pet>? pets,
    String? notes,
    VehicleClass? vehicleClass,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      fromLat: fromLat ?? this.fromLat,
      fromLon: fromLon ?? this.fromLon,
      toLat: toLat ?? this.toLat,
      toLon: toLon ?? this.toLon,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      rawPrice: rawPrice ?? this.rawPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      baseCost: baseCost ?? this.baseCost,
      costPerKm: costPerKm ?? this.costPerKm,
      status: status ?? this.status,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      departureDate: departureDate ?? this.departureDate,
      departureTime: departureTime ?? this.departureTime,
      passengers: passengers ?? this.passengers,
      baggage: baggage ?? this.baggage,
      pets: pets ?? this.pets,
      notes: notes ?? this.notes,
      vehicleClass: vehicleClass ?? this.vehicleClass,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Order($orderId: $fromAddress -> $toAddress, $finalPrice₽, $status)';
  }
}

/// DTO для создания заказа
@JsonSerializable()
class CreateOrderDto {
  final double fromLat;
  final double fromLon;
  final double toLat;
  final double toLon;
  final String fromAddress;
  final String toAddress;
  final double distanceKm;
  final double rawPrice;
  final double finalPrice;
  final double baseCost;
  final double costPerKm;
  final String? clientName;
  final String? clientPhone;
  final DateTime? departureDate;
  final String? departureTime;
  final List<Passenger>? passengers;
  final List<Baggage>? baggage;
  final List<Pet>? pets;
  final String? notes;
  final String? vehicleClass;

  const CreateOrderDto({
    required this.fromLat,
    required this.fromLon,
    required this.toLat,
    required this.toLon,
    required this.fromAddress,
    required this.toAddress,
    required this.distanceKm,
    required this.rawPrice,
    required this.finalPrice,
    required this.baseCost,
    required this.costPerKm,
    this.clientName,
    this.clientPhone,
    this.departureDate,
    this.departureTime,
    this.passengers,
    this.baggage,
    this.pets,
    this.notes,
    this.vehicleClass,
  });

  factory CreateOrderDto.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOrderDtoToJson(this);
}

/// DTO для обновления заказа
@JsonSerializable()
class UpdateOrderDto {
  final String? status;
  final String? clientName;
  final String? clientPhone;
  final DateTime? departureDate;
  final String? departureTime;
  final List<Passenger>? passengers;
  final List<Baggage>? baggage;
  final List<Pet>? pets;
  final String? notes;

  const UpdateOrderDto({
    this.status,
    this.clientName,
    this.clientPhone,
    this.departureDate,
    this.departureTime,
    this.passengers,
    this.baggage,
    this.pets,
    this.notes,
  });

  factory UpdateOrderDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateOrderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateOrderDtoToJson(this);
}
