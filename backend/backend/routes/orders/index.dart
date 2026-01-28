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
    final userRepo = UserRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Получаем токен (опционально)
    final authHeader = context.request.headers['authorization'];
    String? userId;

    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      final payload = jwtHelper.verifyToken(token);
      userId = payload?['userId'] as String?;
      
      // Для авторизованных пользователей проверяем существование
      if (userId != null) {
        final user = await userRepo.findById(userId);
        if (user == null) {
          userId = null; // Пользователь не найден - считаем неавторизованным
        }
      }
    }

    // Получаем query параметры
    final uri = context.request.uri;
    final phone = uri.queryParameters['phone'];
    final status = uri.queryParameters['status'];
    final limit = int.tryParse(uri.queryParameters['limit'] ?? '100');
    final userType = uri.queryParameters['userType']; // ✅ НОВОЕ: режим UI

    List<Order> orders;

    // Поиск по телефону (для всех)
    if (phone != null) {
      orders = await orderRepo.findByPhone(phone);
    }
    // Поиск по статусу (для всех)
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
    // ✅ РЕЖИМ ДИСПЕТЧЕРА (userType=dispatcher из query) - видит ВСЕ заказы
    else if (userType == 'dispatcher') {
      // Проверяем авторизацию
      if (userId == null) {
        return Response.json(
          statusCode: HttpStatus.unauthorized,
          body: {
            'error': 'Authentication required',
            'message': 'Please login to view all orders',
          },
        );
      }
      
      // 🔐 ПРОВЕРКА ПРАВ: Только пользователи с is_dispatcher = true могут видеть все заказы
      final user = await userRepo.findById(userId);
      print('🔍 [DISPATCHER CHECK] userId=$userId, user found=${user != null}, isDispatcher=${user?.isDispatcher}');
      
      if (user == null || !user.isDispatcher) {
        print('❌ [DISPATCHER CHECK] Access denied for userId=$userId');
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {
            'error': 'Access denied',
            'message': 'You do not have dispatcher privileges',
          },
        );
      }
      
      print('✅ [DISPATCHER CHECK] User ${user.fullName} has dispatcher privileges, returning ALL orders');
      orders = await orderRepo.findAll(limit: limit);
    }
    // Обычные пользователи - свои заказы
    else if (userId != null) {
      orders = await orderRepo.findByUserId(userId, limit: limit);
    }
    // 🚨 КРИТИЧЕСКОЕ ИСПРАВЛЕНИЕ: Требуем авторизацию вместо показа всех заказов
    else {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {
          'error': 'Authentication required',
          'message': 'Please login to view orders',
        },
      );
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
