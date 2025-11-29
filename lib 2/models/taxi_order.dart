import 'package:yandex_maps_mapkit/mapkit.dart' as mapkit;

/// Модель заказа такси
class TaxiOrder {
  final String orderId;          // Уникальный ID заказа
  final DateTime timestamp;      // Время создания
  
  // Маршрут
  final mapkit.Point fromPoint;  // Откуда (координаты)
  final mapkit.Point toPoint;    // Куда (координаты)
  final String fromAddress;      // Откуда (адрес текстом)
  final String toAddress;        // Куда (адрес текстом)
  
  // Расчёты
  final double distanceKm;       // Расстояние в км
  final double rawPrice;         // Сырая цена
  final double finalPrice;       // Финальная цена
  final double baseCost;         // Базовая стоимость
  final double costPerKm;        // Цена за км
  
  // Статус
  final String status;           // 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled'
  
  // Синхронизация
  final bool isSynced;           // true = синхронизировано с Firebase, false = только в SQLite
  
  // Клиент (опционально для будущего)
  final String? clientName;
  final String? clientPhone;

  TaxiOrder({
    required this.orderId,
    required this.timestamp,
    required this.fromPoint,
    required this.toPoint,
    required this.fromAddress,
    required this.toAddress,
    required this.distanceKm,
    required this.rawPrice,
    required this.finalPrice,
    required this.baseCost,
    required this.costPerKm,
    required this.status,
    this.isSynced = false,         // По умолчанию не синхронизировано
    this.clientName,
    this.clientPhone,
  });

  /// Преобразование в Map для SQLite и Firebase
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'fromLat': fromPoint.latitude,
      'fromLon': fromPoint.longitude,
      'toLat': toPoint.latitude,
      'toLon': toPoint.longitude,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'distanceKm': distanceKm,
      'rawPrice': rawPrice,
      'finalPrice': finalPrice,
      'baseCost': baseCost,
      'costPerKm': costPerKm,
      'status': status,
      'isSynced': isSynced ? 1 : 0,  // SQLite boolean as integer
      'clientName': clientName,
      'clientPhone': clientPhone,
    };
  }

  /// Создание из Map (SQLite/Firebase)
  factory TaxiOrder.fromMap(Map<String, dynamic> map) {
    return TaxiOrder(
      orderId: map['orderId'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      fromPoint: mapkit.Point(
        latitude: map['fromLat'] as double,
        longitude: map['fromLon'] as double,
      ),
      toPoint: mapkit.Point(
        latitude: map['toLat'] as double,
        longitude: map['toLon'] as double,
      ),
      fromAddress: map['fromAddress'] as String,
      toAddress: map['toAddress'] as String,
      distanceKm: map['distanceKm'] as double,
      rawPrice: map['rawPrice'] as double,
      finalPrice: map['finalPrice'] as double,
      baseCost: map['baseCost'] as double,
      costPerKm: map['costPerKm'] as double,
      status: map['status'] as String,
      isSynced: (map['isSynced'] ?? 0) == 1,  // SQLite integer to boolean
      clientName: map['clientName'] as String?,
      clientPhone: map['clientPhone'] as String?,
    );
  }

  /// Копирование с изменением полей
  TaxiOrder copyWith({
    String? orderId,
    DateTime? timestamp,
    mapkit.Point? fromPoint,
    mapkit.Point? toPoint,
    String? fromAddress,
    String? toAddress,
    double? distanceKm,
    double? rawPrice,
    double? finalPrice,
    double? baseCost,
    double? costPerKm,
    String? status,
    bool? isSynced,
    String? clientName,
    String? clientPhone,
  }) {
    return TaxiOrder(
      orderId: orderId ?? this.orderId,
      timestamp: timestamp ?? this.timestamp,
      fromPoint: fromPoint ?? this.fromPoint,
      toPoint: toPoint ?? this.toPoint,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      distanceKm: distanceKm ?? this.distanceKm,
      rawPrice: rawPrice ?? this.rawPrice,
      finalPrice: finalPrice ?? this.finalPrice,
      baseCost: baseCost ?? this.baseCost,
      costPerKm: costPerKm ?? this.costPerKm,
      status: status ?? this.status,
      isSynced: isSynced ?? this.isSynced,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
    );
  }

  @override
  String toString() {
    return 'TaxiOrder{orderId: $orderId, from: $fromAddress, to: $toAddress, distance: ${distanceKm}km, price: ${finalPrice}₽, status: $status}';
  }
}
