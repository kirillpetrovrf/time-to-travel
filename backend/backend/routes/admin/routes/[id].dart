import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/route.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/route_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// PUT /admin/routes/:id - Обновить маршрут (только админы)
/// DELETE /admin/routes/:id - Удалить маршрут (только админы)
Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;

  if (method == HttpMethod.put) {
    return _updateRoute(context, id);
  } else if (method == HttpMethod.delete) {
    return _deleteRoute(context, id);
  }

  return Response.json(
    statusCode: HttpStatus.methodNotAllowed,
    body: {'error': 'Method not allowed'},
  );
}

/// PUT /admin/routes/:id - Обновить маршрут
Future<Response> _updateRoute(RequestContext context, String id) async {
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

    // Проверяем что маршрут существует
    final existingRoute = await routeRepo.findById(id);

    if (existingRoute == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Route not found'},
      );
    }

    // Парсим body
    final json = await context.request.json() as Map<String, dynamic>;
    final dto = UpdateRouteDto.fromJson(json);

    // Обновляем маршрут
    final updatedRoute = await routeRepo.update(id, dto);

    return Response.json(
      body: {
        'message': 'Route updated successfully',
        'route': updatedRoute.toJson(),
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to update route: ${e.toString()}'},
    );
  }
}

/// DELETE /admin/routes/:id - Удалить маршрут
Future<Response> _deleteRoute(RequestContext context, String id) async {
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

    // Проверяем что маршрут существует
    final existingRoute = await routeRepo.findById(id);

    if (existingRoute == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Route not found'},
      );
    }

    // Удаляем маршрут
    final deleted = await routeRepo.delete(id);

    if (!deleted) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': 'Failed to delete route'},
      );
    }

    return Response.json(
      body: {
        'message': 'Route deleted successfully',
        'routeId': id,
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to delete route: ${e.toString()}'},
    );
  }
}
