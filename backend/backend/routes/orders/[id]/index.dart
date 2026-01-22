import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/order.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/order_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// GET /orders/:id - Получить заказ по ID
/// PUT /orders/:id - Обновить заказ
/// DELETE /orders/:id - Отменить заказ
Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;

  if (method == HttpMethod.get) {
    return _getOrder(context, id);
  } else if (method == HttpMethod.put) {
    return _updateOrder(context, id);
  } else if (method == HttpMethod.delete) {
    return _cancelOrder(context, id);
  }

  return Response.json(
    statusCode: HttpStatus.methodNotAllowed,
    body: {'error': 'Method not allowed'},
  );
}

/// GET /orders/:id - Получить заказ
Future<Response> _getOrder(RequestContext context, String id) async {
  try {
    final db = context.read<DatabaseService>();
    final orderRepo = OrderRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем userId если есть токен
    String? userId;
    final authHeader = context.request.headers['authorization'];

    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      final payload = jwtHelper.verifyToken(token);
      userId = payload?['userId'] as String?;
    }

    // Находим заказ
    final order = await orderRepo.findById(id);

    if (order == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Order not found'},
      );
    }

    // Проверяем права доступа (только свои заказы или если нет userId)
    if (userId != null && order.userId != null && order.userId != userId) {
      // Проверяем, является ли пользователь админом
      final userRepo = UserRepository(db);
      final user = await userRepo.findById(userId);
      
      if (user?.role != 'admin') {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Access denied'},
        );
      }
    }

    return Response.json(
      body: {'order': order.toJson()},
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to fetch order: ${e.toString()}'},
    );
  }
}

/// PUT /orders/:id - Обновить заказ
Future<Response> _updateOrder(RequestContext context, String id) async {
  try {
    final db = context.read<DatabaseService>();
    final orderRepo = OrderRepository(db);
    final userRepo = UserRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем userId из токена (обязательно для обновления)
    final authHeader = context.request.headers['authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Authorization required'},
      );
    }

    final token = authHeader.substring(7);
    final payload = jwtHelper.verifyToken(token);

    if (payload == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid token'},
      );
    }

    final userId = payload['userId'] as String?;
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid token payload'},
      );
    }

    // Находим заказ
    final order = await orderRepo.findById(id);

    if (order == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Order not found'},
      );
    }

    // Проверяем права доступа
    final user = await userRepo.findById(userId);
    final isAdmin = user?.role == 'admin';

    if (!isAdmin && order.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    // Проверяем, можно ли редактировать заказ
    if (order.status == OrderStatus.completed || 
        order.status == OrderStatus.cancelled) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Cannot update completed or cancelled order'},
      );
    }

    // Парсим body
    final json = await context.request.json() as Map<String, dynamic>;
    final dto = UpdateOrderDto.fromJson(json);

    // Обновляем заказ
    final updatedOrder = await orderRepo.update(id, dto);

    return Response.json(
      body: {'order': updatedOrder.toJson()},
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to update order: ${e.toString()}'},
    );
  }
}

/// DELETE /orders/:id - Отменить заказ
Future<Response> _cancelOrder(RequestContext context, String id) async {
  try {
    final db = context.read<DatabaseService>();
    final orderRepo = OrderRepository(db);
    final userRepo = UserRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем userId из токена (обязательно для отмены)
    final authHeader = context.request.headers['authorization'];

    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Authorization required'},
      );
    }

    final token = authHeader.substring(7);
    final payload = jwtHelper.verifyToken(token);

    if (payload == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid token'},
      );
    }

    final userId = payload['userId'] as String?;
    if (userId == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'error': 'Invalid token payload'},
      );
    }

    // Находим заказ
    final order = await orderRepo.findById(id);

    if (order == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Order not found'},
      );
    }

    // Проверяем права доступа
    final user = await userRepo.findById(userId);
    final isAdmin = user?.role == 'admin';

    if (!isAdmin && order.userId != userId) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied'},
      );
    }

    // Проверяем, можно ли отменить заказ
    if (order.status == OrderStatus.completed || 
        order.status == OrderStatus.cancelled) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Order already completed or cancelled'},
      );
    }

    // Отменяем заказ (меняем статус на cancelled)
    final cancelledOrder = await orderRepo.updateStatus(
      id, 
      OrderStatus.cancelled,
    );

    return Response.json(
      body: {
        'message': 'Order cancelled successfully',
        'order': cancelledOrder.toJson(),
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to cancel order: ${e.toString()}'},
    );
  }
}
