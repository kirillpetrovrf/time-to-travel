import 'package:dartz/dartz.dart' hide Order;
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_cache_datasource.dart';
import '../datasources/orders_remote_datasource.dart';

/// Implementation of OrdersRepository
/// 
/// Combines remote data source (API) and cache data source (in-memory).
/// Implements business logic for when to use cache vs remote source.
class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;
  final OrdersCacheDataSource cacheDataSource;
  final NetworkInfo networkInfo;

  OrdersRepositoryImpl({
    required this.remoteDataSource,
    required this.cacheDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Order>>> getOrders({
    OrderStatus? status,
    int limit = 100,
    bool forceRefresh = false,
    String? userType, // ✅ ДОБАВЛЕНО
  }) async {
    // Check internet connection
    final isConnected = await networkInfo.isConnected;

    if (!isConnected) {
      // Offline - return cache if available
      final cachedOrders = cacheDataSource.getCachedOrders();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        return Right(cachedOrders.map((model) => model.toEntity()).toList());
      }
      return const Left(NetworkFailure(
        message: 'No internet connection. Please check your network settings.',
      ));
    }

    // If not forced refresh and no filter - try cache first
    if (!forceRefresh && status == null) {
      final cachedOrders = cacheDataSource.getCachedOrders();
      if (cachedOrders != null && cachedOrders.isNotEmpty) {
        return Right(cachedOrders.map((model) => model.toEntity()).toList());
      }
    }

    // Fetch from remote
    try {
      final remoteOrders = await remoteDataSource.getOrders(
        status: status?.value,
        limit: limit,
        userType: userType, // ✅ ПЕРЕДАЁМ на datasource
      );

      // Cache only if fetching all orders (no filter)
      if (status == null) {
        cacheDataSource.cacheOrders(remoteOrders);
      }

      return Right(remoteOrders.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> createOrder(CreateOrderParams params) async {
    // Check internet connection
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure(
        message: 'No internet connection. Cannot create order offline.',
      ));
    }

    try {
      // Prepare order data
      final orderData = <String, dynamic>{
        'fromAddress': params.fromAddress,
        'toAddress': params.toAddress,
        if (params.fromLat != null) 'fromLat': params.fromLat,
        if (params.fromLon != null) 'fromLon': params.fromLon,
        if (params.toLat != null) 'toLat': params.toLat,
        if (params.toLon != null) 'toLon': params.toLon,
        'departureDate': params.departureDate.toIso8601String(),
        if (params.departureTime != null) 'departureTime': params.departureTime,
        'passengerCount': params.passengerCount,
        'totalPrice': params.totalPrice,
        'finalPrice': params.finalPrice,
        'tripType': params.tripType,
        'direction': params.direction,
        if (params.notes != null) 'notes': params.notes,
        if (params.phone != null) 'clientPhone': params.phone,
        if (params.vehicleClass != null) 'vehicleClass': params.vehicleClass, // ✅ ДОБАВЛЕНО
        if (params.passengers.isNotEmpty)
          'passengers': params.passengers.map((p) => {
            'type': p.type,
            if (p.seatType != null) 'seatType': p.seatType,
            if (p.ageMonths != null) 'ageMonths': p.ageMonths,
          }).toList(),
        if (params.baggage.isNotEmpty)
          'baggage': params.baggage.map((b) => {
            'size': b.size,
            'quantity': b.quantity,
            if (b.pricePerExtraItem != null) 
              'pricePerExtraItem': b.pricePerExtraItem,
          }).toList(),
        if (params.pets.isNotEmpty)
          'pets': params.pets.map((p) => {
            'category': p.category,
            if (p.breed != null) 'breed': p.breed,
            if (p.cost != null) 'cost': p.cost,
          }).toList(),
      };

      final createdOrder = await remoteDataSource.createOrder(orderData);

      // Add to cache
      cacheDataSource.cacheOrder(createdOrder);

      return Right(createdOrder.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> getOrderById(String orderId) async {
    // Try cache first
    final cachedOrder = cacheDataSource.getCachedOrderById(orderId);
    if (cachedOrder != null) {
      return Right(cachedOrder.toEntity());
    }

    // Check internet connection
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure(
        message: 'No internet connection',
      ));
    }

    try {
      final order = await remoteDataSource.getOrderById(orderId);
      cacheDataSource.cacheOrder(order);
      return Right(order.toEntity());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Order>> updateOrderStatus(
    String orderId,
    OrderStatus newStatus,
  ) async {
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) {
      return const Left(NetworkFailure(
        message: 'No internet connection',
      ));
    }

    try {
      final updatedOrder = await remoteDataSource.updateOrderStatus(
        orderId,
        newStatus.value,
      );

      // Update in cache
      cacheDataSource.cacheOrder(updatedOrder);

      return Right(updatedOrder.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(
        message: e.message,
        statusCode: e.statusCode,
      ));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(String orderId) async {
    return updateOrderStatus(orderId, OrderStatus.cancelled)
        .then((result) => result.fold(
              (failure) => Left(failure),
              (_) => const Right(null),
            ));
  }
}
