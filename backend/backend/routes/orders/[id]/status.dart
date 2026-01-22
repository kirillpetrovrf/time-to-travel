import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/order.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/order_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// PATCH /orders/:id/status - Обновить статус заказа (только для админов и водителей)
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.patch) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final db = context.read<DatabaseService>();
    final orderRepo = OrderRepository(db);
    final userRepo = UserRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем userId из токена (обязательно)
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

    // Проверяем права доступа (только админы и водители)
    final user = await userRepo.findById(userId);

    if (user == null || !user.isActive) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'User not found or inactive'},
      );
    }

    if (user.role != 'admin' && user.role != 'driver') {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied. Only admins and drivers can update order status'},
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

    // Парсим body
    final json = await context.request.json() as Map<String, dynamic>;
    final statusStr = json['status'] as String?;

    if (statusStr == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Status is required'},
      );
    }

    // Парсим статус
    final newStatus = _parseOrderStatus(statusStr);

    if (newStatus == null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Invalid status value'},
      );
    }

    // Валидация переходов статусов
    final validationError = _validateStatusTransition(order.status, newStatus, user.role);
    if (validationError != null) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': validationError},
      );
    }

    // Обновляем статус
    final updatedOrder = await orderRepo.updateStatus(id, newStatus);

    return Response.json(
      body: {
        'message': 'Order status updated successfully',
        'order': updatedOrder.toJson(),
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to update order status: ${e.toString()}'},
    );
  }
}

/// Парсинг строки в OrderStatus
OrderStatus? _parseOrderStatus(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return OrderStatus.pending;
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'in_progress':
    case 'inprogress':
      return OrderStatus.inProgress;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return null;
  }
}

/// Валидация переходов между статусами
String? _validateStatusTransition(
  OrderStatus currentStatus,
  OrderStatus newStatus,
  String userRole,
) {
  // Нельзя изменить статус завершенного или отмененного заказа
  if (currentStatus == OrderStatus.completed || 
      currentStatus == OrderStatus.cancelled) {
    return 'Cannot change status of completed or cancelled order';
  }

  // Валидация переходов
  switch (currentStatus) {
    case OrderStatus.pending:
      // pending -> confirmed, cancelled
      if (newStatus != OrderStatus.confirmed && 
          newStatus != OrderStatus.cancelled) {
        return 'Pending order can only be confirmed or cancelled';
      }
      break;

    case OrderStatus.confirmed:
      // confirmed -> in_progress, cancelled
      if (newStatus != OrderStatus.inProgress && 
          newStatus != OrderStatus.cancelled) {
        return 'Confirmed order can only move to in_progress or be cancelled';
      }
      break;

    case OrderStatus.inProgress:
      // in_progress -> completed, cancelled
      if (newStatus != OrderStatus.completed && 
          newStatus != OrderStatus.cancelled) {
        return 'In-progress order can only be completed or cancelled';
      }
      break;

    default:
      break;
  }

  // Дополнительные проверки для водителей
  if (userRole == 'driver') {
    // Водители не могут отменять заказы
    if (newStatus == OrderStatus.cancelled) {
      return 'Drivers cannot cancel orders';
    }
  }

  return null; // Переход валиден
}
