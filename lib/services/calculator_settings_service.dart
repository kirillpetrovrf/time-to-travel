import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/calculator_settings.dart';

/// Сервис для работы с настройками калькулятора в Firebase
class CalculatorSettingsService {
  static final CalculatorSettingsService instance =
      CalculatorSettingsService._();
  CalculatorSettingsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CalculatorSettings? _cachedSettings;

  /// Получить текущие настройки из Firebase
  Future<CalculatorSettings> getSettings() async {
    print('📥 [CALCULATOR] Загрузка настроек калькулятора...');

    try {
      // Проверяем кеш
      if (_cachedSettings != null) {
        print('✅ [CALCULATOR] Настройки взяты из кеша: $_cachedSettings');
        return _cachedSettings!;
      }

      // Загружаем из Firebase
      final doc = await _firestore
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

      print('✅ [CALCULATOR] Настройки загружены: $settings');
      return settings;
    } catch (e) {
      print('❌ [CALCULATOR] Ошибка загрузки настроек: $e');
      print('⚠️ [CALCULATOR] Используем настройки по умолчанию');
      return CalculatorSettings.defaultSettings;
    }
  }

  /// Обновить настройки (только для админов)
  Future<void> updateSettings(CalculatorSettings settings) async {
    print('💾 [CALCULATOR] Сохранение настроек: $settings');

    try {
      await _firestore
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
      await _firestore
          .collection('calculator_settings')
          .doc('current')
          .set(defaultSettings.toJson());

      _cachedSettings = defaultSettings;
      print('✅ [CALCULATOR] Настройки по умолчанию созданы в Firebase');
    } catch (e) {
      print('❌ [CALCULATOR] Ошибка создания настроек по умолчанию: $e');
    }
  }

  /// Очистить кеш (для тестирования)
  void clearCache() {
    _cachedSettings = null;
    print('🗑️ [CALCULATOR] Кеш настроек очищен');
  }
}
