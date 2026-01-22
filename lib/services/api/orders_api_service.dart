import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'api_config.dart';

/// Статус заказа
enum OrderStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  cancelled;

  String toJson() => name;

  static OrderStatus fromString(String status) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Модель заказа из API
class ApiOrder {
  final String id;
  final String userId;
  final String fromAddress;
  final String toAddress;
  final DateTime departureTime;
  final int passengerCount;
  final double basePrice;
  final double totalPrice;
  final OrderStatus status;
  final String? notes;
  final String? phone;
  final Map<String, dynamic>? metadata; // Для багажа, животных и т.д.
  final DateTime createdAt;
  final DateTime updatedAt;

  ApiOrder({
    required this.id,
    required this.userId,
    required this.fromAddress,
    required this.toAddress,
    required this.departureTime,
    required this.passengerCount,
    required this.basePrice,
    required this.totalPrice,
    required this.status,
    this.notes,
    this.phone,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ApiOrder.fromJson(Map<String, dynamic> json) {
    // Backend может вернуть {"order": {...}} или просто {...}
    final data = json.containsKey('order') ? json['order'] as Map<String, dynamic> : json;
    
    // Парсим departureTime: комбинируем departureDate + departureTime
    DateTime parsedDepartureTime = DateTime.now();
    try {
      if (data['departureDate'] != null) {
        final date = DateTime.parse(data['departureDate'] as String);
        
        // Если есть departureTime как строка "Time(HH:MM:SS)" - извлекаем время
        if (data['departureTime'] != null) {
          final timeStr = data['departureTime'] as String;
          // Извлекаем время из "Time(20:31:00.000)" -> "20:31:00"
          final timeMatch = RegExp(r'(\d{2}):(\d{2}):(\d{2})').firstMatch(timeStr);
          if (timeMatch != null) {
            final hour = int.parse(timeMatch.group(1)!);
            final minute = int.parse(timeMatch.group(2)!);
            final second = int.parse(timeMatch.group(3)!);
            parsedDepartureTime = DateTime(date.year, date.month, date.day, hour, minute, second);
          } else {
            parsedDepartureTime = date;
          }
        } else {
          parsedDepartureTime = date;
        }
      }
    } catch (e) {
      // Fallback если не удалось распарсить
      parsedDepartureTime = DateTime.now();
    }
    
    return ApiOrder(
      id: data['orderId'] as String? ?? data['id'] as String, // Используем orderId если есть
      userId: data['userId'] as String? ?? '', // userId может быть null
      fromAddress: data['fromAddress'] as String,
      toAddress: data['toAddress'] as String,
      departureTime: parsedDepartureTime,
      passengerCount: data['passengerCount'] as int? ?? 1,
      basePrice: data['basePrice'] != null ? (data['basePrice'] as num).toDouble() : 0.0,
      totalPrice: data['finalPrice'] != null 
          ? (data['finalPrice'] as num).toDouble()
          : (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(data['status'] as String? ?? 'pending'),
      notes: data['notes'] as String?,
      phone: data['clientPhone'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: data['createdAt'] != null 
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'departureTime': departureTime.toIso8601String(),
      'passengerCount': passengerCount,
      'basePrice': basePrice,
      'totalPrice': totalPrice,
      'status': status.toJson(),
      if (notes != null) 'notes': notes,
      if (phone != null) 'phone': phone,
      if (metadata != null) 'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Ответ со списком заказов
class OrdersListResponse {
  final List<ApiOrder> orders;
  final int count;

  OrdersListResponse({
    required this.orders,
    required this.count,
  });

  factory OrdersListResponse.fromJson(Map<String, dynamic> json) {
    return OrdersListResponse(
      orders: (json['orders'] as List<dynamic>)
          .map((e) => ApiOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int,
    );
  }
}

/// Сервис для работы с заказами через Time to Travel API
class OrdersApiService {
  final ApiClient _apiClient;

  OrdersApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Получить список заказов пользователя
  /// GET /orders
  Future<OrdersListResponse> getOrders({
    String? phone,
    OrderStatus? status,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      
      if (phone != null) queryParams['phone'] = phone;
      if (status != null) queryParams['status'] = status.name;
      if (limit != null) queryParams['limit'] = limit.toString();

      final response = await _apiClient.get(
        ApiConfig.ordersEndpoint,
        queryParameters: queryParams,
        requiresAuth: false, // ✅ Диспетчеры могут смотреть заказы БЕЗ авторизации
      );

      return OrdersListResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Создать новый заказ
  /// POST /orders
  Future<ApiOrder> createOrder({
    required String fromAddress,
    required String toAddress,
    required DateTime departureTime,
    required int passengerCount,
    required double basePrice,
    required double totalPrice,
    String? notes,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      debugPrint('📤 [API] Отправка заказа на backend...');
      debugPrint('   От: $fromAddress');
      debugPrint('   До: $toAddress');
      debugPrint('   Цена: $totalPrice');
      
      final response = await _apiClient.post(
        ApiConfig.ordersEndpoint,
        body: {
          'fromAddress': fromAddress,
          'toAddress': toAddress,
          'departureTime': departureTime.toIso8601String(),
          'passengerCount': passengerCount,
          'basePrice': basePrice,
          'totalPrice': totalPrice,
          'finalPrice': totalPrice, // ✅ ОБЯЗАТЕЛЬНОЕ ПОЛЕ для backend
          if (notes != null) 'notes': notes,
          if (phone != null) 'phone': phone,
          if (metadata != null) 'metadata': metadata,
        },
        requiresAuth: false, // ✅ Заказы можно создавать БЕЗ авторизации
      );

      debugPrint('✅ [API] Backend вернул успешный ответ');
      final apiOrder = ApiOrder.fromJson(response);
      debugPrint('✅ [API] Заказ создан с ID: ${apiOrder.id}');
      return apiOrder;
    } catch (e) {
      debugPrint('❌ [API] Ошибка создания заказа: $e');
      rethrow;
    }
  }

  /// Получить заказ по ID
  /// GET /orders/:id
  Future<ApiOrder> getOrderById(String orderId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.ordersEndpoint}/$orderId',
        requiresAuth: true,
      );

      return ApiOrder.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Обновить заказ
  /// PUT /orders/:id
  Future<ApiOrder> updateOrder({
    required String orderId,
    String? fromAddress,
    String? toAddress,
    DateTime? departureTime,
    int? passengerCount,
    double? basePrice,
    double? totalPrice,
    OrderStatus? status,
    String? notes,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (fromAddress != null) body['fromAddress'] = fromAddress;
      if (toAddress != null) body['toAddress'] = toAddress;
      if (departureTime != null) {
        body['departureTime'] = departureTime.toIso8601String();
      }
      if (passengerCount != null) body['passengerCount'] = passengerCount;
      if (basePrice != null) body['basePrice'] = basePrice;
      if (totalPrice != null) body['totalPrice'] = totalPrice;
      if (status != null) body['status'] = status.name;
      if (notes != null) body['notes'] = notes;
      if (phone != null) body['phone'] = phone;
      if (metadata != null) body['metadata'] = metadata;

      final response = await _apiClient.put(
        '${ApiConfig.ordersEndpoint}/$orderId',
        body: body,
        requiresAuth: true,
      );

      return ApiOrder.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Отменить заказ
  /// DELETE /orders/:id
  Future<void> cancelOrder(String orderId) async {
    try {
      await _apiClient.delete(
        '${ApiConfig.ordersEndpoint}/$orderId',
        requiresAuth: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Изменить статус заказа (только для admin/driver)
  /// PATCH /orders/:id/status
  Future<ApiOrder> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    try {
      final response = await _apiClient.patch(
        '${ApiConfig.ordersEndpoint}/$orderId/status',
        body: {'status': status.name},
        requiresAuth: true,
      );

      return ApiOrder.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Закрытие клиента
  void dispose() {
    _apiClient.dispose();
  }
}
