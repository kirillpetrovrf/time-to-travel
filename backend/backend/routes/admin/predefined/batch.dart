import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/models/route.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/route_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:backend/utils/jwt_helper.dart';

/// POST /admin/predefined/batch - Массовая загрузка маршрутов (только админы)
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
    final routesList = json['routes'] as List<dynamic>?;
    final skipDuplicates = json['skipDuplicates'] as bool? ?? true;

    if (routesList == null || routesList.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'error': 'Routes list is required'},
      );
    }

    var created = 0;
    var skipped = 0;
    var errors = 0;
    final createdRoutes = <PredefinedRoute>[];
    final errorMessages = <String>[];

    for (final routeData in routesList) {
      try {
        final routeMap = routeData as Map<String, dynamic>;
        final fromCity = routeMap['fromCity'] as String?;
        final toCity = routeMap['toCity'] as String?;
        final price = (routeMap['price'] as num?)?.toDouble();
        final groupId = routeMap['groupId'] as String?;

        if (fromCity == null || toCity == null || price == null) {
          errors++;
          errorMessages.add('Invalid route data: $routeMap');
          continue;
        }

        // Проверяем дубликат
        if (skipDuplicates) {
          final existing = await routeRepo.findByDirection(
            fromCity: fromCity,
            toCity: toCity,
          );

          if (existing.isNotEmpty) {
            skipped++;
            continue;
          }
        }

        // Создаём маршрут
        final dto = CreateRouteDto(
          fromCity: fromCity,
          toCity: toCity,
          price: price,
          groupId: groupId,
        );

        final route = await routeRepo.create(dto);
        createdRoutes.add(route);
        created++;
      } catch (e) {
        errors++;
        errorMessages.add('Error creating route: $e');
      }
    }

    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'message': 'Batch import completed',
        'summary': {
          'total': routesList.length,
          'created': created,
          'skipped': skipped,
          'errors': errors,
        },
        'routes': createdRoutes.map((r) => r.toJson()).toList(),
        if (errorMessages.isNotEmpty) 'errorMessages': errorMessages,
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Batch import failed: ${e.toString()}'},
    );
  }
}
