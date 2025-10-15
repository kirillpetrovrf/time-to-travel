import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calculator_settings.dart';

/// Сервис для работы с настройками калькулятора в Firebase
class CalculatorSettingsService {
  static final CalculatorSettingsService instance =
      CalculatorSettingsService._();
  CalculatorSettingsService._();

  FirebaseFirestore? _firestore;
  CalculatorSettings? _cachedSettings;
  
  FirebaseFirestore get firestore {
    _firestore ??= FirebaseFirestore.instance;
    return _firestore!;
  }

  /// Получить текущие настройки из Firebase
  Future<CalculatorSettings> getSettings() async {
    print('📥 [CALCULATOR] Загрузка настроек калькулятора...');

    try {
      // Проверяем кеш
      if (_cachedSettings != null) {
        print('✅ [CALCULATOR] Настройки взяты из кеша');
        return _cachedSettings!;
      }

      // Загружаем из Firebase
      print('📡 [CALCULATOR] Попытка загрузки из Firebase...');
      final doc = await firestore
          .collection('calculator_settings')
          .doc('current')
          .get();

      if (!doc.exists) {
        print(
          '⚠️ [CALCULATOR] Настройки не найдены в Firebase, создаём по умолчанию',
        );
        await _createDefaultSettings();
        return CalculatorSettings.defaultSettings;
      }

      final settings = CalculatorSettings.fromJson(doc.data()!);
      _cachedSettings = settings;

      print('✅ [CALCULATOR] Настройки загружены из Firebase');
      return settings;
    } catch (e) {
      print('❌ [CALCULATOR] Ошибка загрузки настроек из Firebase: $e');
      print('⚠️ [CALCULATOR] Используем локальные настройки по умолчанию:');
      final defaultSettings = CalculatorSettings.defaultSettings;
      print('   • Базовая стоимость: ${defaultSettings.baseCost}₽');
      print('   • Цена за км: ${defaultSettings.costPerKm}₽');
      print('   • Минимальная цена: ${defaultSettings.minPrice}₽');
      print('   • Округление: ${defaultSettings.roundToThousands ? "ДА" : "НЕТ"}');
      
      // Кешируем дефолтные настройки
      _cachedSettings = defaultSettings;
      return defaultSettings;
    }
  }

  /// Обновить настройки (только для админов)
  Future<void> updateSettings(CalculatorSettings settings) async {
    print('💾 [CALCULATOR] Сохранение настроек...');

    try {
      await firestore
          .collection('calculator_settings')
          .doc('current')
          .set(settings.toJson());

      // Обновляем кеш
      _cachedSettings = settings;

      print('✅ [CALCULATOR] Настройки успешно сохранены');
    } catch (e) {
      print('❌ [CALCULATOR] Ошибка сохранения настроек: $e');
      throw Exception('Не удалось сохранить настройки: $e');
    }
  }

  /// Создать настройки по умолчанию в Firebase
  Future<void> _createDefaultSettings() async {
    try {
      final defaultSettings = CalculatorSettings.defaultSettings;
      await firestore
          .collection('calculator_settings')
          .doc('current')
          .set(defaultSettings.toJson());

      _cachedSettings = defaultSettings;
      print('✅ [CALCULATOR] Настройки по умолчанию созданы в Firebase');
    } catch (e) {
      print('❌ [CALCULATOR] Ошибка создания настроек: $e');
      // Не бросаем ошибку - просто используем локальные настройки
    }
  }

  /// Очистить кеш (для тестирования)
  void clearCache() {
    _cachedSettings = null;
    print('🗑️ [CALCULATOR] Кеш настроек очищен');
  }
}
