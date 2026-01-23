import '../models/calculator_settings.dart';

/// Сервис для работы с настройками калькулятора (локальный кеш)
class CalculatorSettingsService {
  static final CalculatorSettingsService instance =
      CalculatorSettingsService._();
  CalculatorSettingsService._();

  CalculatorSettings? _cachedSettings;

  /// Получить текущие настройки (используем дефолтные из класса)
  Future<CalculatorSettings> getSettings() async {
    print('📥 [CALCULATOR] Загрузка настроек калькулятора...');

    try {
      // Проверяем кеш
      if (_cachedSettings != null) {
        print('✅ [CALCULATOR] Настройки взяты из кеша');
        return _cachedSettings!;
      }

      // Используем настройки по умолчанию
      print('⚠️ [CALCULATOR] Используем локальные настройки по умолчанию:');
      final defaultSettings = CalculatorSettings.defaultSettings;
      print('   • Базовая стоимость: ${defaultSettings.baseCost}₽');
      print('   • Цена за км: ${defaultSettings.costPerKm}₽');
      print('   • Минимальная цена: ${defaultSettings.minPrice}₽');
      print('   • Округление: ${defaultSettings.roundToThousands ? "ДА" : "НЕТ"}');
      
      // Кешируем дефолтные настройки
      _cachedSettings = defaultSettings;
      return defaultSettings;
    } catch (e) {
      print('❌ [CALCULATOR] Ошибка загрузки настроек: $e');
      final defaultSettings = CalculatorSettings.defaultSettings;
      _cachedSettings = defaultSettings;
      return defaultSettings;
    }
  }

  /// Обновить настройки (только для админов)
  Future<void> updateSettings(CalculatorSettings settings) async {
    print('💾 [CALCULATOR] Сохранение настроек в кеш...');

    try {
      // Обновляем кеш
      _cachedSettings = settings;

      print('✅ [CALCULATOR] Настройки успешно сохранены в кеш');
      print('⚠️ [CALCULATOR] Настройки НЕ сохраняются на сервере (только локальный кеш)');
    } catch (e) {
      print('❌ [CALCULATOR] Ошибка сохранения настроек: $e');
      throw Exception('Не удалось сохранить настройки: $e');
    }
  }

  /// Создать настройки по умолчанию (stub)
  /// Создать настройки по умолчанию (stub)
  Future<void> _createDefaultSettings() async {
    print('📝 [CALCULATOR] Создание настроек по умолчанию (stub)');
    _cachedSettings = CalculatorSettings.defaultSettings;
  }

  /// Очистить кеш (для тестирования)
  void clearCache() {
    _cachedSettings = null;
    print('🗑️ [CALCULATOR] Кеш настроек очищен');
  }
}
