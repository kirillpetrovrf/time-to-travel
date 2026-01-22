import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/route.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/route_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// POST /admin/routes - Создать новый маршрут (только админы)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    final db = context.read<DatabaseService>();
    final routeRepo = RouteRepository(db);
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

    // Проверяем права доступа (только админы)
    final user = await userRepo.findById(userId);

    if (user == null || !user.isActive) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'User not found or inactive'},
      );
    }

    if (user.role != 'admin') {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'error': 'Access denied. Admin role required'},
      );
    }

    // Парсим body
    final json = await context.request.json() as Map<String, dynamic>;
    final dto = CreateRouteDto.fromJson(json);

    // Валидация
    if (dto.fromCity.isEmpty || dto.toCity.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Cities are required'},
      );
    }

    if (dto.price <= 0) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Invalid price'},
      );
    }

    // Создаем маршрут
    final route = await routeRepo.create(dto);

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'message': 'Route created successfully',
        'route': route.toJson(),
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to create route: ${e.toString()}'},
    );
  }
}
