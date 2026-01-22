import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:backend/services/database_service.dart';
import 'package:backend/repositories/route_repository.dart';

/// GET /routes - Получить список маршрутов
/// GET /routes?from=Ростов&to=Таганрог - Поиск маршрутов
Future<Response> onRequest(RequestContext context) async {
  // Проверяем метод
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: HttpStatus.methodNotAllowed,
      body: {'error': 'Method not allowed'},
    );
  }

  try {
    // Получаем сервисы
    final db = context.read<DatabaseService>();
    final routeRepo = RouteRepository(db);

    // Получаем query параметры
    final uri = context.request.uri;
    final from = uri.queryParameters['from'];
    final to = uri.queryParameters['to'];

    List<dynamic> routes;

    // Поиск по направлению
    if (from != null && to != null) {
      routes = await routeRepo.findByDirection(
        fromCity: from,
        toCity: to,
      );
    }
    // Поиск из города
    else if (from != null) {
      routes = await routeRepo.findFromCity(from);
    }
    // Поиск в город
    else if (to != null) {
      routes = await routeRepo.findToCity(to);
    }
    // Все маршруты
    else {
      routes = await routeRepo.findAll(isActive: true);
    }

    // Возвращаем результат
    return Response.json(
      body: {
        'routes': routes.map((r) => r.toJson()).toList(),
        'count': routes.length,
      },
    );
  } on Exception catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'error': 'Failed to fetch routes: ${e.toString()}'},
    );
  }
}
