import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yandex_maps_mapkit/mapkit.dart';
import 'package:yandex_maps_mapkit/search.dart';

/// Сервис для автозаполнения адресов через Yandex MapKit SearchManager
///
/// ✅ ПРАВИЛЬНЫЙ ПОДХОД по рекомендации Яндекса:
/// - Использует встроенный SearchManager из MapKit SDK
/// - Работает с вашим MapKit API ключом
/// - НЕ использует HTTP Geocoder (который запрещен)
/// - Никаких 403 ошибок!
class YandexSuggestService {
  static const int _suggestNumberLimit = 10;

  // ✅ СОЗДАЕМ SearchManager СРАЗУ как final (КАК В ПРИМЕРЕ ЯНДЕКСА!)
  final _searchManager = SearchFactory.instance.createSearchManager(
    SearchManagerType.Combined,
  );

  // ✅ SuggestSession создаётся через late final (лениво)
  late final _suggestSession = _searchManager.createSuggestSession();

  // ✅ КРИТИЧЕСКИ ВАЖНО: MapKit хранит слабые ссылки на listener'ы!
  // Listener создаётся на уровне поля класса (КАК В ПРИМЕРЕ ЯНДЕКСА)
  late final _suggestListener = SearchSuggestSessionSuggestListener(
    onResponse: _onSuggestResponse,
    onError: _onSuggestError,
  );

  Completer<List<SuggestItem>>? _currentCompleter;
  String _currentQuery = '';

  /// Обработчик успешного ответа от Яндекс API
  void _onSuggestResponse(response) {
    debugPrint('');
    debugPrint('📦 [Step 4] ПОЛУЧЕН ОТВЕТ ОТ ЯНДЕКС API!');
    debugPrint('📦 [Step 4.1] Это РЕАЛЬНЫЕ данные от Яндекса (не моки)');
    debugPrint(
      '📦 [Step 4.2] Количество результатов: ${response.items.length}',
    );
    debugPrint('📦 [Step 4.3] Запрос был: "$_currentQuery"');

    if (response.items.isEmpty) {
      debugPrint('⚠️  [Step 4.4] Яндекс вернул ПУСТОЙ список!');
      debugPrint('⚠️  [Step 4.5] Возможные причины:');
      debugPrint('      - Запрос "$_currentQuery" не дал результатов');
      debugPrint('      - BoundingBox слишком узкий');
      debugPrint('      - Проблема с API ключом');
    } else {
      debugPrint('✅ [Step 4.6] Список результатов:');
      final itemsToShow = response.items.take(10);
      var index = 1;
      for (final item in itemsToShow) {
        debugPrint(
          '   $index. "${item.title}" - ${item.subtitle?.text ?? "без описания"}',
        );
        index++;
      }
      if (response.items.length > 10) {
        debugPrint('   ... и еще ${response.items.length - 10} результатов');
      }
    }

    final suggestions = response.items.take(_suggestNumberLimit).map((item) {
      // item.title - это Object, конвертируем в String
      final titleStr = item.title.toString();
      final subtitleStr = item.subtitle?.text;
      final displayTextStr = item.displayText?.toString() ?? titleStr;
      final searchTextStr = item.searchText;

      return SuggestItem(
        title: titleStr,
        subtitle: subtitleStr,
        displayText: displayTextStr,
        searchText: searchTextStr,
        uri: item.uri,
      );
    }).toList();

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('');

    // ✅ Завершаем completer если он еще не завершен
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.complete(suggestions);
    }
  }

  /// Обработчик ошибки от Яндекс API
  void _onSuggestError(error) {
    debugPrint('');
    debugPrint('❌ [Step 4.ERROR] ОШИБКА ОТ ЯНДЕКС API!');
    debugPrint('❌ Запрос был: "$_currentQuery"');
    debugPrint('❌ Тип ошибки: ${error.runtimeType}');
    debugPrint('❌ Описание: $error');
    debugPrint(
      '❌ Это значит, что запрос ДОШЕЛ до Яндекса, но вернулась ошибка',
    );
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('');

    // ✅ Завершаем completer если он еще не завершен
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.complete([]);
    }
  }

  Future<List<SuggestItem>> getSuggestions({required String query}) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔍 [Step 1] НОВЫЙ ЗАПРОС АВТОЗАПОЛНЕНИЯ');
    debugPrint('🔍 [Step 1.1] Введенный текст: "$query"');
    debugPrint('🔍 [Step 1.2] Длина текста: ${query.length} символов');

    if (query.isEmpty) {
      debugPrint('⚠️ [Step 1.3] Пустой запрос - возвращаем пустой список');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');
      return [];
    }

    try {
      // Сохраняем текущий запрос для логирования в listener
      _currentQuery = query;

      // ✅ ИСПРАВЛЕНИЕ: Создаем Completer ОДИН РАЗ и храним ссылку
      _currentCompleter = Completer<List<SuggestItem>>();

      // BoundingBox для ВСЕЙ России (юго-запад и северо-восток)
      final boundingBox = BoundingBox(
        const Point(latitude: 41.0, longitude: 19.0), // Калининград (юго-запад)
        const Point(
          latitude: 82.0,
          longitude: 180.0,
        ), // Владивосток (северо-восток)
      );

      debugPrint('🔵 [Step 2] Формируем параметры запроса к Яндекс API:');
      debugPrint(
        '   - BoundingBox: юго-запад=(lat:41.0, lon:19.0), северо-восток=(lat:82.0, lon:180.0)',
      );
      debugPrint('   - SuggestTypes: GEO | BIZ');
      debugPrint('   - Лимит результатов: $_suggestNumberLimit');

      // Настройки suggest
      final suggestOptions = SuggestOptions(
        suggestTypes: SuggestType(
          SuggestType.Geo.value | SuggestType.Biz.value,
        ),
      );

      debugPrint('🚀 [Step 3] ОТПРАВЛЯЕМ ЗАПРОС К ЯНДЕКС API...');
      debugPrint('⏳ [Step 3.1] Ждем ответ от Яндекса (таймаут 5 секунд)...');
      debugPrint('⏳ [Step 3.2] Listener создан на уровне класса (late final)');

      // Выполняем suggest запрос с СОХРАНЕННЫМ listener'ом
      // ✅ ПРАВИЛЬНЫЙ ПОРЯДОК ПАРАМЕТРОВ согласно документации и примерам
      _suggestSession.suggest(
        boundingBox, // BoundingBox
        suggestOptions, // SuggestOptions
        _suggestListener, // ✅ Listener ИЗ ПОЛЯ КЛАССА!
        text: query, // Именованный параметр text
      );

      // Ждем результат с таймаутом
      return await _currentCompleter!.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('');
          debugPrint(
            '⏱️  [Step 4.TIMEOUT] ТАЙМАУТ! Яндекс не ответил за 5 секунд',
          );
          debugPrint('⏱️  Возможные причины:');
          debugPrint('      - Нет интернета');
          debugPrint('      - Яндекс API недоступен');
          debugPrint('      - MapKit не инициализирован правильно');
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('');
          return [];
        },
      );
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('❌ [Step ERROR] ИСКЛЮЧЕНИЕ ПРИ РАБОТЕ С API!');
      debugPrint('❌ Исключение: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');
      return [];
    }
  }

  void reset() {
    _suggestSession.reset();
    debugPrint('🔄 [YandexSuggest] Сброс');
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
