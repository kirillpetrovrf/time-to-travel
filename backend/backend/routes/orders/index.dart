import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/order.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/order_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// GET /orders - Получить заказы пользователя
/// POST /orders - Создать новый заказ
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (method == HttpMethod.get) {
    return _getOrders(context);
  } else if (method == HttpMethod.post) {
    return _createOrder(context);
  }

  return Response.json(
    statusCode: HttpStatus.methodNotAllowed,
    body: {'error': 'Method not allowed'},
  );
}

/// GET /orders - Получить заказы
Future<Response> _getOrders(RequestContext context) async {
  try {
    final db = context.read<DatabaseService>();
    final orderRepo = OrderRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем токен (опционально)
    final authHeader = context.request.headers['authorization'];
    String? userId;

    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      final payload = jwtHelper.verifyToken(token);
      userId = payload?['userId'] as String?;
    }

    // Получаем query параметры
    final uri = context.request.uri;
    final phone = uri.queryParameters['phone'];
    final status = uri.queryParameters['status'];
    final limit = int.tryParse(uri.queryParameters['limit'] ?? '50');

    List<Order> orders;

    // Поиск по телефону
    if (phone != null) {
      orders = await orderRepo.findByPhone(phone);
    }
    // Поиск по статусу
    else if (status != null) {
      final orderStatus = _parseOrderStatus(status);
      if (orderStatus == null) {
        return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'Invalid status value'},
        );
      }
      orders = await orderRepo.findByStatus(orderStatus, limit: limit);
    }
    // Заказы пользователя (если аутентифицирован)
    else if (userId != null) {
      orders = await orderRepo.findByUserId(userId, limit: limit);
    }
    // Все заказы (для неавторизованных - пустой список)
    else {
      orders = [];
    }

    return Response.json(
      body: {
        'orders': orders.map((o) => o.toJson()).toList(),
        'count': orders.length,
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to fetch orders: ${e.toString()}'},
    );
  }
}

/// POST /orders - Создать заказ
Future<Response> _createOrder(RequestContext context) async {
  try {
    final db = context.read<DatabaseService>();
    final orderRepo = OrderRepository(db);
    final userRepo = UserRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем userId если есть токен
    String? userId;
    final authHeader = context.request.headers['authorization'];

    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      final payload = jwtHelper.verifyToken(token);
      userId = payload?['userId'] as String?;

      // Проверяем что пользователь существует и активен
      if (userId != null) {
        final user = await userRepo.findById(userId);
        if (user == null || !user.isActive) {
          return Response.json(
            statusCode: HttpStatus.forbidden,
            body: {'error': 'User not found or inactive'},
          );
        }
      }
    }

    // Парсим body
    final json = await context.request.json() as Map<String, dynamic>;
    final dto = CreateOrderDto.fromJson(json);

    // Валидация
    if (dto.fromAddress.isEmpty || dto.toAddress.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Addresses are required'},
      );
    }

    if (dto.finalPrice <= 0) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Invalid price'},
      );
    }

    // Создаем заказ
    final order = await orderRepo.create(dto, userId: userId);

    return Response.json(
      statusCode: HttpStatus.created,
      body: {'order': order.toJson()},
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to create order: ${e.toString()}'},
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
