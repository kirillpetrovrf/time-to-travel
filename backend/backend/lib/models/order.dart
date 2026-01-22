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

/// Типы поездок
enum TripType {
  group,         // Групповая поездка
  individual,    // Индивидуальный трансфер
  customRoute;   // Свободный маршрут (такси)

  String toDb() => name;

  static TripType? fromDb(String? tripType) {
    if (tripType == null) return null;
    switch (tripType) {
      case 'group':
        return TripType.group;
      case 'individual':
        return TripType.individual;
      case 'customRoute':
        return TripType.customRoute;
      default:
        return null;
    }
  }
}

/// Направления
enum Direction {
  donetskToRostov,   // Донецк → Ростов-на-Дону
  rostovToDonetsk;   // Ростов-на-Дону → Донецк

  String toDb() => name;

  static Direction? fromDb(String? direction) {
    if (direction == null) return null;
    switch (direction) {
      case 'donetskToRostov':
        return Direction.donetskToRostov;
      case 'rostovToDonetsk':
        return Direction.rostovToDonetsk;
      default:
        return null;
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
  final String? name;          // Опционально - может быть не указано
  final int? age;              // Опционально - общий возраст
  final String type;           // 'adult' или 'child' - ОБЯЗАТЕЛЬНО
  final String? seatType;      // Для детей: 'cradle', 'seat', 'booster', 'none'
  final bool? useOwnSeat;      // Своё кресло (true) или водителя (false)
  final int? ageMonths;        // Возраст в месяцах для детей

  const Passenger({
    this.name,
    this.age,
    required this.type,
    this.seatType,
    this.useOwnSeat,
    this.ageMonths,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) =>
      _$PassengerFromJson(json);

  Map<String, dynamic> toJson() => _$PassengerToJson(this);
}

/// Багаж
@JsonSerializable()
class Baggage {
  final String? type;              // Старый формат - опционально
  final String size;               // 's', 'm', 'l', 'custom' - ОБЯЗАТЕЛЬНО
  final int? count;                // Старый формат - опционально
  final int quantity;              // Количество единиц (1-10) - ОБЯЗАТЕЛЬНО
  final double? pricePerExtraItem; // Цена за дополнительную единицу
  final String? customDescription; // Для size='custom'

  const Baggage({
    this.type,
    required this.size,
    this.count,
    required this.quantity,
    this.pricePerExtraItem,
    this.customDescription,
  });

  factory Baggage.fromJson(Map<String, dynamic> json) =>
      _$BaggageFromJson(json);

  Map<String, dynamic> toJson() => _$BaggageToJson(this);
}

/// Питомец
@JsonSerializable()
class Pet {
  final String? type;        // Старый формат - опционально
  final String? name;        // Старый формат - опционально
  final double? weight;      // Старый формат - опционально
  final String category;     // 'upTo5kgWithCarrier', 'upTo5kgWithoutCarrier', 'over6kg' - ОБЯЗАТЕЛЬНО
  final String breed;        // Описание животного - ОБЯЗАТЕЛЬНО
  final double cost;         // Стоимость перевозки - ОБЯЗАТЕЛЬНО
  final String? description; // Дополнительное описание

  const Pet({
    this.type,
    this.name,
    this.weight,
    required this.category,
    required this.breed,
    required this.cost,
    this.description,
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

  // Координаты (опциональны - могут быть null при создании заказа)
  final double? fromLat;
  final double? fromLon;
  final double? toLat;
  final double? toLon;

  // Адреса
  final String fromAddress;
  final String toAddress;

  // Расстояние и цены (опциональны - вычисляются позже)
  final double? distanceKm;
  final double? rawPrice;
  final double finalPrice; // Только finalPrice обязателен
  final double? baseCost;
  final double? costPerKm;

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

  // ✅ НОВОЕ: Тип поездки и направление
  final TripType? tripType;
  final Direction? direction;

  // Метаданные
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.orderId,
    this.userId,
    this.fromLat,
    this.fromLon,
    this.toLat,
    this.toLon,
    required this.fromAddress,
    required this.toAddress,
    this.distanceKm,
    this.rawPrice,
    required this.finalPrice,
    this.baseCost,
    this.costPerKm,
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
    this.tripType,
    this.direction,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);

  factory Order.fromDb(Map<String, dynamic> row) {
    // Helper для парсинга числовых значений (PostgreSQL DECIMAL возвращается как String)
    double? parseOptionalNum(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }
    
    double parseRequiredNum(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.parse(value);
      throw FormatException('Cannot parse $value as double');
    }
    
    return Order(
      id: row['id'] as String,
      orderId: row['order_id'] as String,
      userId: row['user_id'] as String?,
      fromLat: parseOptionalNum(row['from_lat']),
      fromLon: parseOptionalNum(row['from_lon']),
      toLat: parseOptionalNum(row['to_lat']),
      toLon: parseOptionalNum(row['to_lon']),
      fromAddress: row['from_address'] as String,
      toAddress: row['to_address'] as String,
      distanceKm: parseOptionalNum(row['distance_km']),
      rawPrice: parseOptionalNum(row['raw_price']),
      finalPrice: parseRequiredNum(row['final_price']),
      baseCost: parseOptionalNum(row['base_cost']),
      costPerKm: parseOptionalNum(row['cost_per_km']),
      status: OrderStatus.fromDb(row['status'] as String),
      clientName: row['client_name'] as String?,
      clientPhone: row['client_phone'] as String?,
      departureDate: row['departure_date'] != null
          ? parseDbDateTime(row['departure_date'])
          : null,
      departureTime: row['departure_time'] != null
          ? row['departure_time'].toString()
          : null,
      passengers: row['passengers'] != null
          ? (row['passengers'] is String
              ? (jsonDecode(row['passengers'] as String) as List)
              : (row['passengers'] as List))
              .map((e) => Passenger.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      baggage: row['baggage'] != null
          ? (row['baggage'] is String
              ? (jsonDecode(row['baggage'] as String) as List)
              : (row['baggage'] as List))
              .map((e) => Baggage.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      pets: row['pets'] != null
          ? (row['pets'] is String
              ? (jsonDecode(row['pets'] as String) as List)
              : (row['pets'] as List))
              .map((e) => Pet.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      notes: row['notes'] as String?,
      vehicleClass: VehicleClass.fromDb(row['vehicle_class'] as String?),
      tripType: TripType.fromDb(row['trip_type'] as String?),
      direction: Direction.fromDb(row['direction'] as String?),
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

/// DTO для создания заказа (упрощённый для современного API)
@JsonSerializable()
class CreateOrderDto {
  // Координаты опциональны (можно вычислить из адресов позже)
  final double? fromLat;
  final double? fromLon;
  final double? toLat;
  final double? toLon;
  
  // Адреса обязательны
  final String fromAddress;
  final String toAddress;
  
  // Расчёты опциональны (можно вычислить позже)
  final double? distanceKm;
  final double? rawPrice;
  final double? baseCost;
  final double? costPerKm;
  
  // Цена обязательна
  final double finalPrice;
  
  final String? clientName;
  final String? clientPhone;
  final DateTime? departureDate;
  final String? departureTime;
  final List<Passenger>? passengers;
  final List<Baggage>? baggage;
  final List<Pet>? pets;
  final String? notes;
  final String? vehicleClass;
  
  // ✅ НОВОЕ: Тип поездки и направление
  final String? tripType;     // 'group', 'individual', 'customRoute'
  final String? direction;    // 'donetskToRostov', 'rostovToDonetsk'

  const CreateOrderDto({
    this.fromLat,
    this.fromLon,
    this.toLat,
    this.toLon,
    required this.fromAddress,
    required this.toAddress,
    this.distanceKm,
    this.rawPrice,
    required this.finalPrice,
    this.baseCost,
    this.costPerKm,
    this.clientName,
    this.clientPhone,
    this.departureDate,
    this.departureTime,
    this.passengers,
    this.baggage,
    this.pets,
    this.notes,
    this.vehicleClass,
    this.tripType,
    this.direction,
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
