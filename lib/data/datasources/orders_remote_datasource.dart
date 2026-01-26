import 'package:dio/dio.dart';
import '../../core/errors/exceptions.dart';
import '../models/order_model.dart';

/// Remote Data Source for Orders (API client)
/// 
/// Handles all HTTP requests to the backend API using Dio.
abstract class OrdersRemoteDataSource {
  Future<List<OrderModel>> getOrders({
    String? status,
    int limit = 100,
  });

  Future<OrderModel> createOrder(Map<String, dynamic> orderData);

  Future<OrderModel> getOrderById(String orderId);

  Future<OrderModel> updateOrderStatus(String orderId, String newStatus);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final Dio dio;

  OrdersRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<OrderModel>> getOrders({
    String? status,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (status != null) 'status': status,
      };

      final response = await dio.get(
        '/orders',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final ordersList = data['orders'] as List;

        return ordersList
            .map((json) => OrderModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          message: 'Failed to load orders',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OrderModel> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await dio.post(
        '/orders',
        data: orderData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        // Backend may return {"order": {...}} or {"data": {"order": {...}}}
        if (data.containsKey('data')) {
          return OrderModel.fromJson(data['data'] as Map<String, dynamic>);
        } else if (data.containsKey('order')) {
          return OrderModel.fromJson(data);
        } else {
          return OrderModel.fromJson(data);
        }
      } else {
        throw ServerException(
          message: 'Failed to create order',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await dio.get('/orders/$orderId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        if (data.containsKey('order')) {
          return OrderModel.fromJson(data);
        } else {
          return OrderModel.fromJson(data);
        }
      } else {
        throw ServerException(
          message: 'Order not found',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<OrderModel> updateOrderStatus(
    String orderId,
    String newStatus,
  ) async {
    try {
      final response = await dio.put(
        '/orders/$orderId',
        data: {'status': newStatus},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        
        if (data.containsKey('order')) {
          return OrderModel.fromJson(data);
        } else {
          return OrderModel.fromJson(data);
        }
      } else {
        throw ServerException(
          message: 'Failed to update order',
          statusCode: response.statusCode,
          data: response.data,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle Dio exceptions and convert to app exceptions
  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final errorMessage = _extractErrorMessage(e.response?.data);
        
        if (statusCode == 401 || statusCode == 403) {
          return AuthException(
            message: errorMessage ?? 'Authentication failed',
            statusCode: statusCode,
          );
        } else if (statusCode == 404) {
          return NotFoundException(
            message: errorMessage ?? 'Resource not found',
            statusCode: statusCode,
          );
        } else if (statusCode == 422) {
          return ValidationException(
            message: errorMessage ?? 'Validation failed',
            statusCode: statusCode,
            data: e.response?.data,
          );
        } else {
          return ServerException(
            message: errorMessage ?? 'Server error',
            statusCode: statusCode,
            data: e.response?.data,
          );
        }

      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request cancelled');

      case DioExceptionType.connectionError:
        return const NetworkException(
          message: 'No internet connection. Please check your network settings.',
        );

      default:
        return NetworkException(
          message: 'Network error: ${e.message}',
        );
    }
  }

  /// Extract error message from response data
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;
    
    if (data is Map<String, dynamic>) {
      return data['error'] as String? ?? 
             data['message'] as String? ?? 
             data['detail'] as String?;
    }
    
    if (data is String) return data;
    
    return null;
  }
}
