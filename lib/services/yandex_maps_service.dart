import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/route_info.dart';

/// Сервис для работы с Yandex Maps API
class YandexMapsService {
  static final YandexMapsService instance = YandexMapsService._();
  YandexMapsService._();

  String get _apiKey => ApiKeys.yandexMapsApiKey;

  /// ТЕСТОВЫЙ РЕЖИМ: используется когда API недоступен
  /// Установите в true для тестирования без реального API
  static const bool _useTestMode = true;

  /// Геокодирование: адрес → координаты
  Future<Coordinates?> geocode(String address) async {
    print('🗺️ [YANDEX] Геокодирование адреса: "$address"');

    // Тестовый режим: возвращаем моковые координаты
    if (_useTestMode) {
      print('🧪 [YANDEX] ТЕСТОВЫЙ РЕЖИМ: используем моковые координаты');
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Имитация задержки

      // Простая мок-логика по ключевым словам
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
      }

      // Для неизвестного адреса - случайные координаты в России
      print('⚠️ [YANDEX] Адрес не распознан, используем примерные координаты');
      return Coordinates(latitude: 55.0, longitude: 37.0);
    }

    try {
      final url = Uri.parse(
        'https://geocode-maps.yandex.ru/1.x/?'
        'apikey=$_apiKey&'
        'geocode=${Uri.encodeComponent(address)}&'
        'format=json',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final coords = Coordinates.fromYandexJson(json);
        print('✅ [YANDEX] Координаты найдены: $coords');
        return coords;
      } else {
        print('❌ [YANDEX] Ошибка геокодирования: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [YANDEX] Ошибка геокодирования: $e');
      return null;
    }
  }

  /// Построить маршрут и получить расстояние
  Future<RouteInfo?> calculateRoute(
    String fromAddress,
    String toAddress,
  ) async {
    print('🚗 [YANDEX] ========== РАСЧЁТ МАРШРУТА ==========');
    print('🚗 [YANDEX] От: $fromAddress');
    print('🚗 [YANDEX] До: $toAddress');

    try {
      // Шаг 1: Геокодируем оба адреса
      final fromCoords = await geocode(fromAddress);
      final toCoords = await geocode(toAddress);

      if (fromCoords == null || toCoords == null) {
        print('❌ [YANDEX] Не удалось получить координаты');
        return null;
      }

      // ТЕСТОВЫЙ РЕЖИМ: рассчитываем расстояние по формуле Гаверсина
      if (_useTestMode) {
        print('🧪 [YANDEX] ТЕСТОВЫЙ РЕЖИМ: расчет расстояния по координатам');
        final distance = _calculateDistance(fromCoords, toCoords);
        final duration = distance / 80 * 60; // Примерно 80 км/ч

        print('✅ [YANDEX] Маршрут рассчитан (тестовый):');
        print('   📏 Расстояние: ${distance.toStringAsFixed(1)} км');
        print('   ⏱️ Время: ${duration.toInt()} минут');

        return RouteInfo(
          distance: distance,
          duration: duration,
          fromAddress: fromAddress,
          toAddress: toAddress,
        );
      }

      // Шаг 2: Запрашиваем маршрут через реальный API
      final url = Uri.parse(
        'https://api.routing.yandex.net/v2/route?'
        'apikey=$_apiKey&'
        'waypoints=${fromCoords.longitude},${fromCoords.latitude}|${toCoords.longitude},${toCoords.latitude}&'
        'mode=driving',
      );

      print('🚗 [YANDEX] Запрос маршрута...');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        // Извлекаем расстояние и время
        final route = json['route'];
        final distanceMeters = route['distance']['value'] as int;
        final durationSeconds = route['duration']['value'] as int;

        final distanceKm = distanceMeters / 1000;
        final durationMinutes = durationSeconds / 60;

        final routeInfo = RouteInfo(
          distance: distanceKm,
          duration: durationMinutes,
          fromAddress: fromAddress,
          toAddress: toAddress,
        );

        print('✅ [YANDEX] Маршрут построен: $routeInfo');
        print('🚗 [YANDEX] =========================================');
        return routeInfo;
      } else {
        print('❌ [YANDEX] Ошибка построения маршрута: ${response.statusCode}');
        print('❌ [YANDEX] Ответ: ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ [YANDEX] Ошибка расчёта маршрута: $e');
      return null;
    }
  }

  /// Получить подсказки адресов (автодополнение)
  Future<List<String>> getSuggestions(String query) async {
    if (query.length < 3) {
      return []; // Не показываем подсказки для слишком коротких запросов
    }

    print('💡 [YANDEX] Поиск подсказок для: "$query"');

    try {
      final url = Uri.parse(
        'https://suggest-maps.yandex.ru/v1/suggest?'
        'apikey=$_apiKey&'
        'text=${Uri.encodeComponent(query)}&'
        'types=locality,street,house',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final results = json['results'] as List;

        final suggestions = results
            .map((r) => r['title']['text'] as String)
            .toList();

        print('✅ [YANDEX] Найдено подсказок: ${suggestions.length}');
        return suggestions;
      } else {
        print('❌ [YANDEX] Ошибка получения подсказок: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ [YANDEX] Ошибка получения подсказок: $e');
      return [];
    }
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
