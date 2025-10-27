import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/search.dart';

/// Сервис для автозаполнения адресов через Yandex MapKit SearchManager
///
/// ✅ ПРАВИЛЬНЫЙ ПОДХОД по рекомендации Яндекса:
/// - Использует встроенный SearchManager из MapKit SDK
/// - Работает с вашим MapKit API ключом (e17d0b6b...)
/// - НЕ использует HTTP Geocoder (который запрещен для бесплатного тарифа)
/// - Никаких 403 ошибок!
class YandexSuggestService {
  static const int _suggestNumberLimit = 10;

  late final SearchManager _searchManager;
  late final SuggestSession _suggestSession;

  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) {
      debugPrint('⚠️ [YandexSuggest] Уже инициализирован');
      return;
    }

    try {
      // Создаем SearchManager через SearchFactory
      _searchManager = SearchFactory.instance.createSearchManager(
        SearchManagerType.Combined,
      );

      // Создаем сессию для suggest-запросов
      _suggestSession = _searchManager.createSuggestSession();

      _isInitialized = true;
      debugPrint('✅ [YandexSuggest] Инициализирован (MapKit SearchManager)');
    } catch (e) {
      debugPrint('❌ [YandexSuggest] Ошибка инициализации: $e');
    }
  }

  Future<List<SuggestItem>> getSuggestions({required String query}) async {
    if (!_isInitialized) {
      debugPrint(
        '⚠️ [YandexSuggest] Не инициализирован. Вызовите initialize()',
      );
      initialize();
    }

    if (query.isEmpty) {
      debugPrint('⚠️ [YandexSuggest] Пустой запрос');
      return [];
    }

    debugPrint('🔍 [YandexSuggest] Запрос SearchManager: "$query"');

    try {
      final completer = Completer<List<SuggestItem>>();

      // Создаем BoundingBox для России (широкий охват)
      final boundingBox = BoundingBox(
        southWest: const Point(
          latitude: 41.0,
          longitude: 19.0,
        ), // Юго-запад России
        northEast: const Point(
          latitude: 82.0,
          longitude: 180.0,
        ), // Северо-восток России
      );

      // Настройки suggest-запроса
      final suggestOptions = SuggestOptions(
        suggestTypes: SuggestType(
          SuggestType.Geo.value | SuggestType.Biz.value,
        ),
      );

      // Слушатель ответа
      final listener = SearchSuggestSessionSuggestListener(
        onResponse: (response) {
          debugPrint(
            '✅ [YandexSuggest] Получен ответ: ${response.items.length} подсказок',
          );

          final suggestions = response.items.take(_suggestNumberLimit).map((
            item,
          ) {
            return SuggestItem(
              title: item.title ?? '',
              subtitle: item.subtitle,
              displayText: item.displayText ?? item.title ?? '',
              searchText: item.searchText ?? item.title ?? '',
              uri: item.uri,
            );
          }).toList();

          completer.complete(suggestions);
        },
        onError: (error) {
          debugPrint('❌ [YandexSuggest] Ошибка suggest: $error');
          completer.complete([]);
        },
      );

      // Выполняем suggest-запрос
      _suggestSession.suggest(
        boundingBox,
        suggestOptions,
        listener,
        text: query,
      );

      // Ждем результат с таймаутом
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ [YandexSuggest] Таймаут запроса');
          return [];
        },
      );
    } catch (e) {
      debugPrint('❌ [YandexSuggest] Исключение: $e');
      return [];
    }
  }

  void reset() {
    if (_isInitialized) {
      _suggestSession.reset();
      debugPrint('🔄 [YandexSuggest] Сброс');
    }
  }

  void dispose() {
    if (_isInitialized) {
      // SearchManager и SuggestSession управляются SDK
      _isInitialized = false;
      debugPrint('🗑️ [YandexSuggest] Ресурсы освобождены');
    }
  }
}

class SuggestItem {
  final String title;
  final String? subtitle;
  final String displayText;
  final String searchText;
  final String? uri;

  const SuggestItem({
    required this.title,
    this.subtitle,
    required this.displayText,
    required this.searchText,
    this.uri,
  });

  @override
  String toString() => 'SuggestItem(title: $title, subtitle: $subtitle)';
}
