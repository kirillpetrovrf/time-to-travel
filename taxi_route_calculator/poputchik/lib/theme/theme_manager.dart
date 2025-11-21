import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'app_theme.dart';

/// Менеджер тем приложения
class ThemeManager extends ChangeNotifier {
  static const String _themeFileName = 'app_theme.json';
  static const String _customThemesFileName = 'custom_themes.json';

  CustomTheme _currentTheme = AppTheme.defaultLight;
  List<CustomTheme> _customThemes = [];

  /// Текущая тема
  CustomTheme get currentTheme => _currentTheme;

  /// Список пользовательских тем
  List<CustomTheme> get customThemes => _customThemes;

  /// Все доступные темы (встроенные + пользовательские)
  List<CustomTheme> get allThemes => [...AppTheme.allThemes, ..._customThemes];

  /// Установка новой темы
  void setTheme(CustomTheme theme) {
    _currentTheme = theme;
    notifyListeners();
    _saveCurrentTheme();
  }

  /// Добавление пользовательской темы
  void addCustomTheme(CustomTheme theme) {
    _customThemes.add(theme);
    notifyListeners();
    _saveCustomThemes();
  }

  /// Обновление пользовательской темы
  void updateCustomTheme(String id, CustomTheme updatedTheme) {
    final index = _customThemes.indexWhere((theme) => theme.id == id);
    if (index != -1) {
      _customThemes[index] = updatedTheme;

      // Если это текущая тема, обновляем её
      if (_currentTheme.id == id) {
        _currentTheme = updatedTheme;
      }

      notifyListeners();
      _saveCustomThemes();
    }
  }

  /// Удаление пользовательской темы
  void removeCustomTheme(String id) {
    _customThemes.removeWhere((theme) => theme.id == id);

    // Если удаляемая тема была текущей, переключаемся на дефолтную
    if (_currentTheme.id == id) {
      _currentTheme = AppTheme.defaultLight;
    }

    notifyListeners();
    _saveCustomThemes();
  }

  /// Получение темы по ID
  CustomTheme? getThemeById(String id) {
    // Сначала ищем в встроенных темах
    CustomTheme? theme = AppTheme.getThemeById(id);
    if (theme != null) return theme;

    // Затем в пользовательских
    try {
      return _customThemes.firstWhere((theme) => theme.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Загрузка сохраненной темы
  Future<void> loadSavedTheme() async {
    try {
      final file = await _getThemeFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final themeData = json.decode(jsonString);

        // Пытаемся найти сохраненную тему
        final savedTheme = getThemeById(themeData['id']);
        if (savedTheme != null) {
          _currentTheme = savedTheme;
        }
      }
    } catch (e) {
      debugPrint('Ошибка загрузки темы: $e');
    }

    await _loadCustomThemes();
    notifyListeners();
  }

  /// Загрузка пользовательских тем
  Future<void> _loadCustomThemes() async {
    try {
      final file = await _getCustomThemesFile();
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> themesData = json.decode(jsonString);

        _customThemes = themesData
            .map((data) => CustomTheme.fromJson(data))
            .toList();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки пользовательских тем: $e');
    }
  }

  /// Сохранение текущей темы
  Future<void> _saveCurrentTheme() async {
    try {
      final file = await _getThemeFile();
      final themeData = {
        'id': _currentTheme.id,
        'savedAt': DateTime.now().toIso8601String(),
      };
      await file.writeAsString(json.encode(themeData));
    } catch (e) {
      debugPrint('Ошибка сохранения темы: $e');
    }
  }

  /// Сохранение пользовательских тем
  Future<void> _saveCustomThemes() async {
    try {
      final file = await _getCustomThemesFile();
      final themesData = _customThemes.map((theme) => theme.toJson()).toList();
      await file.writeAsString(json.encode(themesData));
    } catch (e) {
      debugPrint('Ошибка сохранения пользовательских тем: $e');
    }
  }

  /// Получение файла для сохранения текущей темы
  Future<File> _getThemeFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_themeFileName');
  }

  /// Получение файла для сохранения пользовательских тем
  Future<File> _getCustomThemesFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_customThemesFileName');
  }

  /// Сброс к дефолтной теме
  void resetToDefault() {
    setTheme(AppTheme.defaultLight);
  }
}

/// Виджет-провайдер для ThemeManager
class ThemeManagerWidget extends StatefulWidget {
  final Widget child;

  const ThemeManagerWidget({super.key, required this.child});

  @override
  State<ThemeManagerWidget> createState() => _ThemeManagerWidgetState();
}

class _ThemeManagerWidgetState extends State<ThemeManagerWidget> {
  late ThemeManager _themeManager;

  @override
  void initState() {
    super.initState();
    _themeManager = ThemeManager();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    await _themeManager.loadSavedTheme();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeManager>.value(
      value: _themeManager,
      child: widget.child,
    );
  }
}

/// Простая реализация ChangeNotifierProvider для минимальных зависимостей
class ChangeNotifierProvider<T extends ChangeNotifier>
    extends InheritedNotifier<T> {
  const ChangeNotifierProvider({
    super.key,
    required T super.notifier,
    required super.child,
  });

  const ChangeNotifierProvider.value({
    super.key,
    required T value,
    required super.child,
  }) : super(notifier: value);

  static T of<T extends ChangeNotifier>(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ChangeNotifierProvider<T>>();
    assert(provider != null, 'No ChangeNotifierProvider<$T> found in context');
    return provider!.notifier!;
  }
}

/// Расширение для удобного доступа к ThemeManager
extension ThemeManagerExtension on BuildContext {
  ThemeManager get themeManager =>
      ChangeNotifierProvider.of<ThemeManager>(this);
  CustomTheme get currentTheme => themeManager.currentTheme;
}
