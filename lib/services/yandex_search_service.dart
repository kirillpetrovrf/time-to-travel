import 'package:yandex_maps_mapkit/search.dart';

/// Глобальный сервис для работы с Yandex Maps Search API
/// Инициализируется один раз в main() и доступен везде через instance
/// 
/// Использование:
/// ```dart
/// // В main.dart после initMapkit():
/// await YandexSearchService.initialize();
/// 
/// // В виджетах:
/// final suggestSession = YandexSearchService.instance.createSuggestSession();
/// ```
class YandexSearchService {
  static YandexSearchService? _instance;
  
  /// Получить singleton instance сервиса
  /// Throws Exception если сервис не был инициализирован
  static YandexSearchService get instance {
    if (_instance == null) {
      throw Exception(
        '❌ YandexSearchService не инициализирован!\n'
        'Вызовите YandexSearchService.initialize() в main() после initMapkit()',
      );
    }
    return _instance!;
  }

  late final SearchManager searchManager;
  bool _isInitialized = false;
  
  /// Проверка готовности сервиса
  bool get isInitialized => _isInitialized;

  // Приватный конструктор для Singleton паттерна
  YandexSearchService._();

  /// Инициализация сервиса (вызывать в main() после initMapkit)
  /// 
  /// Пример:
  /// ```dart
  /// await mapkit_init.initMapkit(apiKey: "...");
  /// await YandexSearchService.initialize();
  /// ```
  static Future<void> initialize() async {
    if (_instance != null) {
      print('⚠️ YandexSearchService уже инициализирован');
      return;
    }

    print('🔧 [YandexSearchService] Инициализация...');
    _instance = YandexSearchService._();

    try {
      _instance!.searchManager = SearchFactory.instance.createSearchManager(
        SearchManagerType.Combined,
      );
      _instance!._isInitialized = true;
      print('✅ [YandexSearchService] Инициализирован успешно');
      print('✅ [YandexSearchService] SearchManager: ${_instance!.searchManager}');
    } catch (e, stackTrace) {
      print('❌ [YandexSearchService] Ошибка инициализации: $e');
      print('❌ [YandexSearchService] Stack trace: $stackTrace');
      _instance = null; // Сбрасываем instance при ошибке
      rethrow;
    }
  }

  /// Создать новую сессию для автокомплита адресов
  /// 
  /// Пример:
  /// ```dart
  /// final suggestSession = YandexSearchService.instance.createSuggestSession();
  /// suggestSession.suggest(boundingBox, options, listener, text: query);
  /// ```
  SearchSuggestSession createSuggestSession() {
    if (!_isInitialized) {
      throw Exception('❌ YandexSearchService не инициализирован!');
    }
    
    final session = searchManager.createSuggestSession();
    print('✅ [YandexSearchService] Создана новая SuggestSession');
    return session;
  }

  /// Проверка готовности сервиса (статический метод)
  static bool get isReady => _instance?._isInitialized ?? false;
  
  /// Сбросить состояние сервиса (для тестирования)
  static void reset() {
    print('🔄 [YandexSearchService] Сброс состояния');
    _instance = null;
  }
}
