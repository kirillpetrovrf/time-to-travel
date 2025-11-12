import 'package:flutter/cupertino.dart';
import 'app_theme.dart';

/// Упрощённый менеджер тем приложения
/// Использует только фиксированную тему Time to Travel
class ThemeManager extends ChangeNotifier {
  // Фиксированная тема Time to Travel
  final CustomTheme _currentTheme = AppTheme.timeToTravelDark;

  /// Текущая тема (всегда Time to Travel)
  CustomTheme get currentTheme => _currentTheme;

  /// Инициализация менеджера тем
  Future<void> loadTheme() async {
    // Ничего не загружаем, используем фиксированную тему
    notifyListeners();
  }
}

/// Виджет провайдер для ThemeManager
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
    await _themeManager.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return _ThemeManagerInheritedWidget(
      themeManager: _themeManager,
      child: widget.child,
    );
  }
}

/// Расширение для контекста
extension ThemeManagerContext on BuildContext {
  ThemeManager get themeManager {
    final provider =
        dependOnInheritedWidgetOfExactType<_ThemeManagerInheritedWidget>();
    return provider!.themeManager;
  }
}

/// InheritedWidget для ThemeManager
class _ThemeManagerInheritedWidget extends InheritedNotifier<ThemeManager> {
  const _ThemeManagerInheritedWidget({
    required ThemeManager themeManager,
    required Widget child,
  }) : super(notifier: themeManager, child: child);

  ThemeManager get themeManager => notifier!;

  @override
  bool updateShouldNotify(covariant _ThemeManagerInheritedWidget oldWidget) {
    return oldWidget.themeManager != themeManager;
  }
}

/// ChangeNotifierProvider класс для упрощения
class ChangeNotifierProvider<T extends ChangeNotifier>
    extends InheritedNotifier<T> {
  const ChangeNotifierProvider({
    super.key,
    required T Function(BuildContext) create,
    required Widget child,
  }) : _create = create,
       super(child: child, notifier: null);

  final T Function(BuildContext) _create;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  static T of<T extends ChangeNotifier>(BuildContext context) {
    final result = context
        .dependOnInheritedWidgetOfExactType<ChangeNotifierProvider<T>>();
    return result!._create(context);
  }
}
