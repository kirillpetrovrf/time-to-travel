import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/route_group_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// GET /route-groups/:id - Получить группу с маршрутами
/// PUT /route-groups/:id - Обновить группу (только админы)
/// DELETE /route-groups/:id - Удалить группу (только админы)
Future<Response> onRequest(RequestContext context, String id) async {
  final method = context.request.method;

  if (method == HttpMethod.get) {
    return _getGroup(context, id);
  } else if (method == HttpMethod.put) {
    return _updateGroup(context, id);
  } else if (method == HttpMethod.delete) {
    return _deleteGroup(context, id);
  }

  return Response.json(
    statusCode: HttpStatus.methodNotAllowed,
    body: {'error': 'Method not allowed'},
  );
}

/// GET /route-groups/:id
Future<Response> _getGroup(RequestContext context, String id) async {
  try {
    final db = context.read<DatabaseService>();
    final groupRepo = RouteGroupRepository(db);

    final group = await groupRepo.findById(id);

    if (group == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Group not found'},
      );
    }

    // Получаем маршруты группы
    final routes = await db.queryMany(
      '''
      SELECT * FROM predefined_routes 
      WHERE group_id = @groupId 
      ORDER BY from_city, to_city
      ''',
      parameters: {'groupId': id},
    );

    return Response.json(
      body: {
        'group': group.toJson(),
        'routes': routes,
        'routeCount': routes.length,
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to fetch group: ${e.toString()}'},
    );
  }
}

/// PUT /route-groups/:id
Future<Response> _updateGroup(RequestContext context, String id) async {
  try {
    final db = context.read<DatabaseService>();
    final groupRepo = RouteGroupRepository(db);
    final userRepo = UserRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Проверка авторизации
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

    // Проверка прав (только админы)
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

    // Проверяем существование группы
    final existingGroup = await groupRepo.findById(id);

    if (existingGroup == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Group not found'},
      );
    }

    // Парсим body
    final json = await context.request.json() as Map<String, dynamic>;
    final dto = UpdateRouteGroupDto.fromJson(json);

    // Обновляем группу
    final updatedGroup = await groupRepo.update(id, dto);

    return Response.json(
      body: {
        'message': 'Group updated successfully',
        'group': updatedGroup.toJson(),
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to update group: ${e.toString()}'},
    );
  }
}

/// DELETE /route-groups/:id
Future<Response> _deleteGroup(RequestContext context, String id) async {
  try {
    final db = context.read<DatabaseService>();
    final groupRepo = RouteGroupRepository(db);
    final userRepo = UserRepository(db);
    final jwtHelper = JwtHelper.fromEnv(Platform.environment);

    // Проверка авторизации
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

    // Проверка прав (только админы)
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

    // Удаляем группу
    final deleted = await groupRepo.delete(id);

    if (!deleted) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'error': 'Group not found'},
      );
    }

    return Response.json(
      body: {'message': 'Group deleted successfully'},
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to delete group: ${e.toString()}'},
    );
  }
}
