import '../models/route_stop.dart';

/// Сервис для работы с маршрутами и остановками
class RouteService {
  static const RouteService _instance = RouteService._internal();

  const RouteService._internal();

  static const RouteService instance = _instance;

  /// Получение всех доступных маршрутов
  List<String> getAvailableRoutes() {
    return ['donetsk_to_rostov', 'rostov_to_donetsk'];
  }

  /// Получение названия маршрута
  String getRouteName(String routeId) {
    switch (routeId) {
      case 'donetsk_to_rostov':
        return 'Донецк → Ростов-на-Дону';
      case 'rostov_to_donetsk':
        return 'Ростов-на-Дону → Донецк';
      default:
        return 'Неизвестный маршрут';
    }
  }

  /// Получение остановок маршрута
  List<RouteStop> getRouteStops(String routeId) {
    return RouteData.getRouteStops(routeId);
  }

  /// Получение популярных остановок для быстрого выбора
  List<RouteStop> getPopularStops(String routeId) {
    return RouteData.getRouteStops(
      routeId,
    ).where((stop) => stop.isPopular).toList();
  }

  /// Поиск остановки по ID
  RouteStop? findStopById(String stopId, String routeId) {
    return RouteData.findStopById(stopId, routeId);
  }

  /// Получение цены между остановками
  int getPriceBetweenStops(RouteStop fromStop, RouteStop toStop) {
    return RouteData.getPriceBetweenStops(fromStop, toStop);
  }

  /// Проверка валидности маршрута (от не может быть равно до)
  bool isValidRoute(RouteStop? fromStop, RouteStop? toStop) {
    if (fromStop == null || toStop == null) return false;
    if (fromStop.id == toStop.id) return false;
    return true;
  }

  /// Получение времени в пути между остановками (примерное)
  Duration getEstimatedTravelTime(RouteStop fromStop, RouteStop toStop) {
    final distance = (toStop.order - fromStop.order).abs();
    // Примерно 30 минут между соседними остановками
    return Duration(minutes: distance * 30);
  }

  /// Получение расстояния между остановками (в км, примерное)
  double getEstimatedDistance(RouteStop fromStop, RouteStop toStop) {
    final orderDiff = (toStop.order - fromStop.order).abs();
    // Примерно 25 км между соседними остановками
    return orderDiff * 25.0;
  }
}
