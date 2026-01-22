import 'package:json_annotation/json_annotation.dart';

part 'route.g.dart';

/// Модель группы маршрутов
@JsonSerializable()
class RouteGroup {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const RouteGroup({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RouteGroup.fromJson(Map<String, dynamic> json) =>
      _$RouteGroupFromJson(json);

  Map<String, dynamic> toJson() => _$RouteGroupToJson(this);

  factory RouteGroup.fromDb(Map<String, dynamic> row) {
    return RouteGroup(
      id: row['id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}

/// Модель предопределенного маршрута
@JsonSerializable()
class PredefinedRoute {
  final String id;
  final String fromCity;
  final String toCity;
  final double price;
  final String? groupId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PredefinedRoute({
    required this.id,
    required this.fromCity,
    required this.toCity,
    required this.price,
    this.groupId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PredefinedRoute.fromJson(Map<String, dynamic> json) =>
      _$PredefinedRouteFromJson(json);

  Map<String, dynamic> toJson() => _$PredefinedRouteToJson(this);

  factory PredefinedRoute.fromDb(Map<String, dynamic> row) {
    return PredefinedRoute(
      id: row['id'] as String,
      fromCity: row['from_city'] as String,
      toCity: row['to_city'] as String,
      price: (row['price'] as num).toDouble(),
      groupId: row['group_id'] as String?,
      isActive: row['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  PredefinedRoute copyWith({
    String? id,
    String? fromCity,
    String? toCity,
    double? price,
    String? groupId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PredefinedRoute(
      id: id ?? this.id,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      price: price ?? this.price,
      groupId: groupId ?? this.groupId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PredefinedRoute($fromCity -> $toCity, ${price}₽)';
  }
}

/// DTO для создания маршрута
@JsonSerializable()
class CreateRouteDto {
  final String fromCity;
  final String toCity;
  final double price;
  final String? groupId;

  const CreateRouteDto({
    required this.fromCity,
    required this.toCity,
    required this.price,
    this.groupId,
  });

  factory CreateRouteDto.fromJson(Map<String, dynamic> json) =>
      _$CreateRouteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateRouteDtoToJson(this);
}

/// DTO для обновления маршрута
@JsonSerializable()
class UpdateRouteDto {
  final String? fromCity;
  final String? toCity;
  final double? price;
  final String? groupId;
  final bool? isActive;

  const UpdateRouteDto({
    this.fromCity,
    this.toCity,
    this.price,
    this.groupId,
    this.isActive,
  });

  factory UpdateRouteDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateRouteDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateRouteDtoToJson(this);
}
