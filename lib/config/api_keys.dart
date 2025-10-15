/// Конфигурация API ключей
/// ВАЖНО: НЕ коммитить реальные ключи в git!
class ApiKeys {
  /// Yandex Maps API ключ
  static String get yandexMapsApiKey {
    // TODO: Получите ключ на https://developer.tech.yandex.ru/
    // В продакшене - брать из переменных окружения
    const key = String.fromEnvironment('YANDEX_API_KEY');

    if (key.isNotEmpty) {
      return key;
    }

    // Временная заглушка для разработки
    // ЗАМЕНИТЕ на реальный ключ после получения!
    return 'YOUR_YANDEX_API_KEY_HERE';
  }
}
