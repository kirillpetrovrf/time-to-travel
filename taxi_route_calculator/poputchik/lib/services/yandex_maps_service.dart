import 'dart:math';
import '../models/route_info.dart';

/// Сервис для работы с Yandex MapKit SDK
///
/// СТАТУС: Упрощенная версия с fallback логикой
/// TODO: Реализовать полноценную интеграцию с API:
/// - SearchManager для геокодирования
/// - DrivingRouter для построения маршрутов
/// - SuggestSession для автодополнения
class YandexMapsService {
  static final YandexMapsService instance = YandexMapsService._();
  YandexMapsService._();

  bool _isInitialized = false;

  /// Инициализация MapKit (вызывается автоматически через main.dart)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🗺️ [YANDEX MAPKIT] Инициализация...');
      // MapKit инициализируется в main.dart через mapkit_init.initMapkit()
      _isInitialized = true;
      print('✅ [YANDEX MAPKIT] Инициализирован успешно');
    } catch (e) {
      print('❌ [YANDEX MAPKIT] Ошибка инициализации: $e');
    }
  }

  /// Геокодирование: адрес → координаты
  Future<Coordinates?> geocode(String address) async {
    if (!_isInitialized) await initialize();

    print('🗺️ [YANDEX MAPKIT] Геокодирование адреса: "$address"');

    try {
      // TODO: Обновить под новый API SearchManager
      // Пока используем fallback координаты
      return _getMockCoordinates(address);
    } catch (e) {
      print('❌ [YANDEX MAPKIT] Ошибка геокодирования: $e');
      return _getMockCoordinates(address);
    }
  }

  /// Построить маршрут и получить расстояние
  Future<RouteInfo?> calculateRoute(
    String fromAddress,
    String toAddress,
  ) async {
    if (!_isInitialized) await initialize();

    print('🚗 [YANDEX MAPKIT] ========== РАСЧЁТ МАРШРУТА ==========');
    print('🚗 [YANDEX MAPKIT] От: $fromAddress');
    print('🚗 [YANDEX MAPKIT] До: $toAddress');

    try {
      // Шаг 1: Геокодируем оба адреса
      final fromCoords = await geocode(fromAddress);
      final toCoords = await geocode(toAddress);

      if (fromCoords == null || toCoords == null) {
        print('❌ [YANDEX MAPKIT] Не удалось получить координаты');
        return null;
      }

      print('📍 [YANDEX MAPKIT] От: $fromCoords');
      print('📍 [YANDEX MAPKIT] До: $toCoords');

      // TODO: Реализовать построение маршрута через DrivingRouter API
      // Пока используем fallback расчет по прямой
      return _calculateRouteByDistance(
        fromCoords,
        toCoords,
        fromAddress,
        toAddress,
      );
    } catch (e) {
      print('❌ [YANDEX MAPKIT] Ошибка расчёта маршрута: $e');

      // Fallback: рассчитываем по координатам
      final fromCoords = await geocode(fromAddress);
      final toCoords = await geocode(toAddress);

      if (fromCoords != null && toCoords != null) {
        return _calculateRouteByDistance(
          fromCoords,
          toCoords,
          fromAddress,
          toAddress,
        );
      }

      return null;
    }
  }

  /// Получить подсказки адресов (автодополнение)
  Future<List<String>> getSuggestions(String query) async {
    if (query.length < 3) {
      return []; // Не показываем подсказки для слишком коротких запросов
    }

    if (!_isInitialized) await initialize();

    print('💡 [YANDEX MAPKIT] Поиск подсказок для: "$query"');

    try {
      // TODO: Реализовать через SuggestSession API
      return []; // Пока возвращаем пустой список
    } catch (e) {
      print('❌ [YANDEX MAPKIT] Ошибка получения подсказок: $e');
      return [];
    }
  }

  // ========== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ==========

  /// Моковые координаты для популярных городов (fallback)
  Coordinates? _getMockCoordinates(String address) {
    final lowerAddress = address.toLowerCase();

    if (lowerAddress.contains('пермь') || lowerAddress.contains('perm')) {
      return Coordinates(latitude: 58.0, longitude: 56.3);
    } else if (lowerAddress.contains('екатеринбург') ||
        lowerAddress.contains('yekaterinburg')) {
      return Coordinates(latitude: 56.8, longitude: 60.6);
    } else if (lowerAddress.contains('москва') ||
        lowerAddress.contains('moscow')) {
      return Coordinates(latitude: 55.75, longitude: 37.62);
    } else if (lowerAddress.contains('санкт-петербург') ||
        lowerAddress.contains('petersburg')) {
      return Coordinates(latitude: 59.93, longitude: 30.36);
    } else if (lowerAddress.contains('донецк') ||
        lowerAddress.contains('donetsk')) {
      return Coordinates(latitude: 48.0, longitude: 37.8);
    } else if (lowerAddress.contains('ростов') ||
        lowerAddress.contains('rostov')) {
      return Coordinates(latitude: 47.2, longitude: 39.7);
    } else if (lowerAddress.contains('казань') ||
        lowerAddress.contains('kazan')) {
      return Coordinates(latitude: 55.8, longitude: 49.1);
    } else if (lowerAddress.contains('челябинск') ||
        lowerAddress.contains('chelyabinsk')) {
      return Coordinates(latitude: 55.2, longitude: 61.4);
    } else if (lowerAddress.contains('уфа') || lowerAddress.contains('ufa')) {
      return Coordinates(latitude: 54.7, longitude: 55.9);
    }

    print('⚠️ [YANDEX MAPKIT] Адрес не распознан: $address');
    return null;
  }

  /// Расчет маршрута по прямой (fallback)
  RouteInfo _calculateRouteByDistance(
    Coordinates from,
    Coordinates to,
    String fromAddress,
    String toAddress,
  ) {
    final distance = _calculateDistance(from, to);
    final duration = distance / 80 * 60; // Примерно 80 км/ч

    print('✅ [YANDEX MAPKIT] Маршрут рассчитан по прямой:');
    print('   📏 Расстояние: ${distance.toStringAsFixed(1)} км');
    print('   ⏱️ Время: ${duration.toInt()} минут');

    return RouteInfo(
      distance: distance,
      duration: duration,
      fromAddress: fromAddress,
      toAddress: toAddress,
    );
  }

  /// Расчет расстояния между двумя точками по формуле Гаверсина
  /// Возвращает расстояние в километрах
  double _calculateDistance(Coordinates from, Coordinates to) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = from.latitude * pi / 180;
    final lat2Rad = to.latitude * pi / 180;
    final dLatRad = (to.latitude - from.latitude) * pi / 180;
    final dLonRad = (to.longitude - from.longitude) * pi / 180;

    final a =
        sin(dLatRad / 2) * sin(dLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLonRad / 2) * sin(dLonRad / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }
}
