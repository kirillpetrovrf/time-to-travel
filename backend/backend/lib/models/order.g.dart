// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Passenger _$PassengerFromJson(Map<String, dynamic> json) => Passenger(
  name: json['name'] as String,
  age: (json['age'] as num?)?.toInt(),
);

Map<String, dynamic> _$PassengerToJson(Passenger instance) => <String, dynamic>{
  'name': instance.name,
  'age': instance.age,
};

Baggage _$BaggageFromJson(Map<String, dynamic> json) => Baggage(
  type: json['type'] as String,
  size: json['size'] as String,
  count: (json['count'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$BaggageToJson(Baggage instance) => <String, dynamic>{
  'type': instance.type,
  'size': instance.size,
  'count': instance.count,
};

Pet _$PetFromJson(Map<String, dynamic> json) => Pet(
  type: json['type'] as String,
  name: json['name'] as String?,
  weight: (json['weight'] as num?)?.toDouble(),
);

Map<String, dynamic> _$PetToJson(Pet instance) => <String, dynamic>{
  'type': instance.type,
  'name': instance.name,
  'weight': instance.weight,
};

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  userId: json['userId'] as String?,
  fromLat: (json['fromLat'] as num).toDouble(),
  fromLon: (json['fromLon'] as num).toDouble(),
  toLat: (json['toLat'] as num).toDouble(),
  toLon: (json['toLon'] as num).toDouble(),
  fromAddress: json['fromAddress'] as String,
  toAddress: json['toAddress'] as String,
  distanceKm: (json['distanceKm'] as num).toDouble(),
  rawPrice: (json['rawPrice'] as num).toDouble(),
  finalPrice: (json['finalPrice'] as num).toDouble(),
  baseCost: (json['baseCost'] as num).toDouble(),
  costPerKm: (json['costPerKm'] as num).toDouble(),
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  clientName: json['clientName'] as String?,
  clientPhone: json['clientPhone'] as String?,
  departureDate: json['departureDate'] == null
      ? null
      : DateTime.parse(json['departureDate'] as String),
  departureTime: json['departureTime'] as String?,
  passengers: (json['passengers'] as List<dynamic>?)
      ?.map((e) => Passenger.fromJson(e as Map<String, dynamic>))
      .toList(),
  baggage: (json['baggage'] as List<dynamic>?)
      ?.map((e) => Baggage.fromJson(e as Map<String, dynamic>))
      .toList(),
  pets: (json['pets'] as List<dynamic>?)
      ?.map((e) => Pet.fromJson(e as Map<String, dynamic>))
      .toList(),
  notes: json['notes'] as String?,
  vehicleClass: $enumDecodeNullable(
    _$VehicleClassEnumMap,
    json['vehicleClass'],
  ),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'userId': instance.userId,
  'fromLat': instance.fromLat,
  'fromLon': instance.fromLon,
  'toLat': instance.toLat,
  'toLon': instance.toLon,
  'fromAddress': instance.fromAddress,
  'toAddress': instance.toAddress,
  'distanceKm': instance.distanceKm,
  'rawPrice': instance.rawPrice,
  'finalPrice': instance.finalPrice,
  'baseCost': instance.baseCost,
  'costPerKm': instance.costPerKm,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'clientName': instance.clientName,
  'clientPhone': instance.clientPhone,
  'departureDate': instance.departureDate?.toIso8601String(),
  'departureTime': instance.departureTime,
  'passengers': instance.passengers,
  'baggage': instance.baggage,
  'pets': instance.pets,
  'notes': instance.notes,
  'vehicleClass': _$VehicleClassEnumMap[instance.vehicleClass],
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.inProgress: 'inProgress',
  OrderStatus.completed: 'completed',
  OrderStatus.cancelled: 'cancelled',
};

const _$VehicleClassEnumMap = {
  VehicleClass.economy: 'economy',
  VehicleClass.comfort: 'comfort',
  VehicleClass.business: 'business',
  VehicleClass.minivan: 'minivan',
};

CreateOrderDto _$CreateOrderDtoFromJson(Map<String, dynamic> json) =>
    CreateOrderDto(
      fromLat: (json['fromLat'] as num).toDouble(),
      fromLon: (json['fromLon'] as num).toDouble(),
      toLat: (json['toLat'] as num).toDouble(),
      toLon: (json['toLon'] as num).toDouble(),
      fromAddress: json['fromAddress'] as String,
      toAddress: json['toAddress'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      rawPrice: (json['rawPrice'] as num).toDouble(),
      finalPrice: (json['finalPrice'] as num).toDouble(),
      baseCost: (json['baseCost'] as num).toDouble(),
      costPerKm: (json['costPerKm'] as num).toDouble(),
      clientName: json['clientName'] as String?,
      clientPhone: json['clientPhone'] as String?,
      departureDate: json['departureDate'] == null
          ? null
          : DateTime.parse(json['departureDate'] as String),
      departureTime: json['departureTime'] as String?,
      passengers: (json['passengers'] as List<dynamic>?)
          ?.map((e) => Passenger.fromJson(e as Map<String, dynamic>))
          .toList(),
      baggage: (json['baggage'] as List<dynamic>?)
          ?.map((e) => Baggage.fromJson(e as Map<String, dynamic>))
          .toList(),
      pets: (json['pets'] as List<dynamic>?)
          ?.map((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      vehicleClass: json['vehicleClass'] as String?,
    );

Map<String, dynamic> _$CreateOrderDtoToJson(CreateOrderDto instance) =>
    <String, dynamic>{
      'fromLat': instance.fromLat,
      'fromLon': instance.fromLon,
      'toLat': instance.toLat,
      'toLon': instance.toLon,
      'fromAddress': instance.fromAddress,
      'toAddress': instance.toAddress,
      'distanceKm': instance.distanceKm,
      'rawPrice': instance.rawPrice,
      'finalPrice': instance.finalPrice,
      'baseCost': instance.baseCost,
      'costPerKm': instance.costPerKm,
      'clientName': instance.clientName,
      'clientPhone': instance.clientPhone,
      'departureDate': instance.departureDate?.toIso8601String(),
      'departureTime': instance.departureTime,
      'passengers': instance.passengers,
      'baggage': instance.baggage,
      'pets': instance.pets,
      'notes': instance.notes,
      'vehicleClass': instance.vehicleClass,
    };

UpdateOrderDto _$UpdateOrderDtoFromJson(Map<String, dynamic> json) =>
    UpdateOrderDto(
      status: json['status'] as String?,
      clientName: json['clientName'] as String?,
      clientPhone: json['clientPhone'] as String?,
      departureDate: json['departureDate'] == null
          ? null
          : DateTime.parse(json['departureDate'] as String),
      departureTime: json['departureTime'] as String?,
      passengers: (json['passengers'] as List<dynamic>?)
          ?.map((e) => Passenger.fromJson(e as Map<String, dynamic>))
          .toList(),
      baggage: (json['baggage'] as List<dynamic>?)
          ?.map((e) => Baggage.fromJson(e as Map<String, dynamic>))
          .toList(),
      pets: (json['pets'] as List<dynamic>?)
          ?.map((e) => Pet.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$UpdateOrderDtoToJson(UpdateOrderDto instance) =>
    <String, dynamic>{
      'status': instance.status,
      'clientName': instance.clientName,
      'clientPhone': instance.clientPhone,
      'departureDate': instance.departureDate?.toIso8601String(),
      'departureTime': instance.departureTime,
      'passengers': instance.passengers,
      'baggage': instance.baggage,
      'pets': instance.pets,
      'notes': instance.notes,
    };
