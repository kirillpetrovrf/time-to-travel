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
    final userRepo = UserRepository(db);
    if (userId != null && order.userId != null && order.userId != userId) {
      // Проверяем, является ли пользователь админом или диспетчером
      final user = await userRepo.findById(userId);
      
      if (user?.role != 'admin' && user?.isDispatcher != true) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Access denied'},
        );
      }
    }

    // Формируем базовый ответ
    final responseBody = <String, dynamic>{'order': order.toJson()};

    // Если запрос от диспетчера и есть клиент - добавляем контакты
    if (userId != null) {
      print('🔍 [GET ORDER] userId из токена: $userId');
      final user = await userRepo.findById(userId);
      print('🔍 [GET ORDER] user найден: ${user?.firstName}, isDispatcher: ${user?.isDispatcher}, role: ${user?.role}');
      
      if (user?.isDispatcher == true && order.userId != null) {
        print('✅ [GET ORDER] Пользователь является диспетчером, загружаем контакты клиента');
        print('🔍 [GET ORDER] order.userId (ID клиента): ${order.userId}');
        
        final clientUser = await userRepo.findById(order.userId!);
        print('🔍 [GET ORDER] clientUser найден: ${clientUser?.firstName} ${clientUser?.lastName}, phone: ${clientUser?.phone}');
        
        if (clientUser != null) {
          responseBody['client_contact'] = {
            'phone': clientUser.phone,
            'telegram_id': clientUser.telegramId,
            'username': clientUser.username,
            'first_name': clientUser.firstName,
            'last_name': clientUser.lastName,
          };
          print('✅ [GET ORDER] Добавлены контакты клиента в ответ: ${clientUser.phone}');
        } else {
          print('❌ [GET ORDER] clientUser не найден в базе!');
        }
      } else {
        print('ℹ️ [GET ORDER] Пользователь НЕ диспетчер или нет userId у заказа');
      }
    } else {
      print('ℹ️ [GET ORDER] userId отсутствует в запросе (нет токена)');
    }

    return Response.json(
      body: responseBody,
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
