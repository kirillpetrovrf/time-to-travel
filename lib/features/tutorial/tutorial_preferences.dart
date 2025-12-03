import 'package:shared_preferences/shared_preferences.dart';

/// Менеджер для управления состоянием туториала
class TutorialPreferences {
  static const String _tutorialCompletedKey = 'tutorial_completed';

  /// Проверяет, был ли туториал уже пройден
  static Future<bool> isTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialCompletedKey) ?? false;
  }

  /// Отмечает туториал как пройденный
  static Future<void> setTutorialCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialCompletedKey, true);
  }

  /// Сбрасывает состояние туториала (для тестирования)
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tutorialCompletedKey);
  }
}
