// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteGroup _$RouteGroupFromJson(Map<String, dynamic> json) => RouteGroup(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  isActive: json['isActive'] as bool? ?? true,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RouteGroupToJson(RouteGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

PredefinedRoute _$PredefinedRouteFromJson(Map<String, dynamic> json) =>
    PredefinedRoute(
      id: json['id'] as String,
      fromCity: json['fromCity'] as String,
      toCity: json['toCity'] as String,
      price: (json['price'] as num).toDouble(),
      groupId: json['groupId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PredefinedRouteToJson(PredefinedRoute instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fromCity': instance.fromCity,
      'toCity': instance.toCity,
      'price': instance.price,
      'groupId': instance.groupId,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

CreateRouteDto _$CreateRouteDtoFromJson(Map<String, dynamic> json) =>
    CreateRouteDto(
      fromCity: json['fromCity'] as String,
      toCity: json['toCity'] as String,
      price: (json['price'] as num).toDouble(),
      groupId: json['groupId'] as String?,
    );

Map<String, dynamic> _$CreateRouteDtoToJson(CreateRouteDto instance) =>
    <String, dynamic>{
      'fromCity': instance.fromCity,
      'toCity': instance.toCity,
      'price': instance.price,
      'groupId': instance.groupId,
    };

UpdateRouteDto _$UpdateRouteDtoFromJson(Map<String, dynamic> json) =>
    UpdateRouteDto(
      fromCity: json['fromCity'] as String?,
      toCity: json['toCity'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      groupId: json['groupId'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$UpdateRouteDtoToJson(UpdateRouteDto instance) =>
    <String, dynamic>{
      'fromCity': instance.fromCity,
      'toCity': instance.toCity,
      'price': instance.price,
      'groupId': instance.groupId,
      'isActive': instance.isActive,
    };
