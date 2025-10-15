import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import '../models/route_info.dart';

/// Сервис для работы с Yandex Maps API
class YandexMapsService {
  static final YandexMapsService instance = YandexMapsService._();
  YandexMapsService._();

  String get _apiKey => ApiKeys.yandexMapsApiKey;

  /// Геокодирование: адрес → координаты
  Future<Coordinates?> geocode(String address) async {
    print('🗺️ [YANDEX] Геокодирование адреса: "$address"');

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

      // Шаг 2: Запрашиваем маршрут
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
}
