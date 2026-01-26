import '../core/di/service_locator.dart';
import '../domain/entities/order.dart';
import '../domain/repositories/orders_repository.dart';

/// Orders Service - Facade for OrdersRepository
/// 
/// Provides simple API for UI layer to work with orders.
/// Handles Either monad results from repository.
class OrdersService {
  final OrdersRepository _repository;

  OrdersService() : _repository = ServiceLocator().ordersRepository;

  /// Get all orders (with optional status filter)
  Future<OrdersResult> getOrders({
    OrderStatus? status,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    final result = await _repository.getOrders(
      status: status,
      limit: limit,
      forceRefresh: forceRefresh,
    );

    return result.fold(
      (failure) => OrdersResult.error(failure.message),
      (orders) => OrdersResult.success(orders),
    );
  }

  /// Create new order
  Future<OrderResult> createOrder({
    required String fromAddress,
    required String toAddress,
    double? fromLat,
    double? fromLon,
    double? toLat,
    double? toLon,
    required DateTime departureDate,
    String? departureTime,
    required int passengerCount,
    required double totalPrice,
    required double finalPrice,
    String? notes,
    String? phone,
    required String tripType,
    required String direction,
    List<Passenger> passengers = const [],
    List<BaggageItem> baggage = const [],
    List<Pet> pets = const [],
  }) async {
    final params = CreateOrderParams(
      fromAddress: fromAddress,
      toAddress: toAddress,
      fromLat: fromLat,
      fromLon: fromLon,
      toLat: toLat,
      toLon: toLon,
      departureDate: departureDate,
      departureTime: departureTime,
      passengerCount: passengerCount,
      totalPrice: totalPrice,
      finalPrice: finalPrice,
      notes: notes,
      phone: phone,
      tripType: tripType,
      direction: direction,
      passengers: passengers,
      baggage: baggage,
      pets: pets,
    );

    final result = await _repository.createOrder(params);

    return result.fold(
      (failure) => OrderResult.error(failure.message),
      (order) => OrderResult.success(order),
    );
  }

  /// Get order by ID
  Future<OrderResult> getOrderById(String orderId) async {
    final result = await _repository.getOrderById(orderId);

    return result.fold(
      (failure) => OrderResult.error(failure.message),
      (order) => OrderResult.success(order),
    );
  }

  /// Update order status
  Future<OrderResult> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    final result = await _repository.updateOrderStatus(orderId, newStatus);

    return result.fold(
      (failure) => OrderResult.error(failure.message),
      (order) => OrderResult.success(order),
    );
  }

  /// Cancel order
  Future<CancelResult> cancelOrder(String orderId) async {
    final result = await _repository.cancelOrder(orderId);

    return result.fold(
      (failure) => CancelResult.error(failure.message),
      (_) => CancelResult.success(),
    );
  }
}

/// Result wrapper for single order operations
class OrderResult {
  final Order? order;
  final String? error;
  final bool isSuccess;

  OrderResult.success(this.order)
      : error = null,
        isSuccess = true;

  OrderResult.error(this.error)
      : order = null,
        isSuccess = false;
}

/// Result wrapper for multiple orders operations
class OrdersResult {
  final List<Order>? orders;
  final String? error;
  final bool isSuccess;

  OrdersResult.success(this.orders)
      : error = null,
        isSuccess = true;

  OrdersResult.error(this.error)
      : orders = null,
        isSuccess = false;
}

/// Result wrapper for cancel operation
class CancelResult {
  final String? error;
  final bool isSuccess;

  CancelResult.success()
      : error = null,
        isSuccess = true;

  CancelResult.error(this.error) : isSuccess = false;
}
