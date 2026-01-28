import 'package:dartz/dartz.dart' hide Order;
import '../../core/errors/failures.dart';
import '../entities/order.dart';

/// Parameters for creating an order
class CreateOrderParams {
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
  final String? notes;
  final String? phone;
  final String tripType;
  final String direction;
  final List<Passenger> passengers;
  final List<BaggageItem> baggage;
  final List<Pet> pets;
  final String? vehicleClass; // ✅ ДОБАВЛЕНО для customRoute

  const CreateOrderParams({
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
    this.notes,
    this.phone,
    required this.tripType,
    required this.direction,
    this.passengers = const [],
    this.baggage = const [],
    this.pets = const [],
    this.vehicleClass, // ✅ ДОБАВЛЕНО
  });
}

/// Repository interface for Orders
/// 
/// This defines WHAT operations can be performed with orders,
/// but NOT HOW they are implemented.
/// 
/// Implementation will be in the data layer (orders_repository_impl.dart).
abstract class OrdersRepository {
  /// Get list of orders
  /// 
  /// [status] - Filter by order status (optional)
  /// [limit] - Maximum number of orders to fetch
  /// [forceRefresh] - Bypass cache and fetch from server
  /// [userType] - User type mode: 'client' or 'dispatcher' (for UI filtering)
  /// 
  /// Returns Either:
  /// - Left(Failure) if operation failed
  /// - Right(List<Order>) if successful
  Future<Either<Failure, List<Order>>> getOrders({
    OrderStatus? status,
    int limit = 100,
    bool forceRefresh = false,
    String? userType, // ✅ ДОБАВЛЕНО
  });

  /// Create a new order
  /// 
  /// [params] - Parameters for creating the order
  /// 
  /// Returns Either:
  /// - Left(Failure) if creation failed
  /// - Right(Order) if successful
  Future<Either<Failure, Order>> createOrder(CreateOrderParams params);

  /// Get order by ID
  /// 
  /// [orderId] - UUID of the order
  /// 
  /// Returns Either:
  /// - Left(Failure) if not found or error
  /// - Right(Order) if successful
  Future<Either<Failure, Order>> getOrderById(String orderId);

  /// Update order status
  /// 
  /// [orderId] - UUID of the order
  /// [newStatus] - New status to set
  /// 
  /// Returns Either:
  /// - Left(Failure) if update failed
  /// - Right(Order) if successful
  Future<Either<Failure, Order>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  );

  /// Cancel order
  /// 
  /// [orderId] - UUID of the order to cancel
  /// 
  /// Returns Either:
  /// - Left(Failure) if cancellation failed
  /// - Right(void) if successful
  Future<Either<Failure, void>> cancelOrder(String orderId);
}
