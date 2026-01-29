import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/route_group_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// GET /route-groups - Получить все группы маршрутов
/// POST /route-groups - Создать группу (только админы)
Future<Response> onRequest(RequestContext context) async {
  final method = context.request.method;

  if (method == HttpMethod.get) {
    return _getGroups(context);
  } else if (method == HttpMethod.post) {
    return _createGroup(context);
  }

  return Response.json(
    statusCode: HttpStatus.methodNotAllowed,
    body: {'error': 'Method not allowed'},
  );
}

/// GET /route-groups
Future<Response> _getGroups(RequestContext context) async {
  try {
    final db = context.read<DatabaseService>();
    final groupRepo = RouteGroupRepository(db);

    // Получаем query параметры
    final uri = context.request.uri;
    final activeOnly = uri.queryParameters['active'] == 'true';

    final groups = await groupRepo.findAll(
      isActive: activeOnly ? true : null,
    );

    // Добавляем количество маршрутов в каждой группе
    final groupsWithCount = <Map<String, dynamic>>[];

    for (final group in groups) {
      final count = await groupRepo.getRouteCount(group.id);
      groupsWithCount.add({
        ...group.toJson(),
        'routeCount': count,
      });
    }

    return Response.json(
      body: {
        'groups': groupsWithCount,
        'count': groups.length,
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to fetch groups: ${e.toString()}'},
    );
  }
}

/// POST /route-groups
Future<Response> _createGroup(RequestContext context) async {
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

    // Парсим body
    final json = await context.request.json() as Map<String, dynamic>;
    final dto = CreateRouteGroupDto.fromJson(json);

    // Валидация
    if (dto.name.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Group name is required'},
      );
    }

    // Создаем группу
    final group = await groupRepo.create(dto);

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'message': 'Group created successfully',
        'group': group.toJson(),
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to create group: ${e.toString()}'},
    );
  }
}
