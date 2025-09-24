import 'package:flutter/cupertino.dart';
import '../../theme/theme_manager.dart';
import '../../theme/app_theme.dart';

class DebugThemeScreen extends StatefulWidget {
  const DebugThemeScreen({super.key});

  @override
  State<DebugThemeScreen> createState() => _DebugThemeScreenState();
}

class _DebugThemeScreenState extends State<DebugThemeScreen> {
  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Тест темы')),
      child: SafeArea(
        child: Column(
          children: [
            // Тест заголовка админ панели
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.secondarySystemBackground,
                border: Border(
                  bottom: BorderSide(
                    color: theme.separator.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Административная панель',
                    style: TextStyle(
                      color: theme.label,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      inherit: false,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Цвет заголовка: ${theme.label.value.toRadixString(16).toUpperCase()}',
                    style: TextStyle(color: theme.secondaryLabel, fontSize: 12),
                  ),
                  Text(
                    'Фон: ${theme.secondarySystemBackground.value.toRadixString(16).toUpperCase()}',
                    style: TextStyle(color: theme.secondaryLabel, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Переключатели тем для тестирования
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Доступные темы:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Светлая тема
                  _buildThemeButton(
                    'Светлая тема',
                    AppTheme.defaultLight,
                    themeManager,
                  ),

                  // Темная тема
                  _buildThemeButton(
                    'Темная тема',
                    AppTheme.defaultDark,
                    themeManager,
                  ),

                  // Компактная тема
                  _buildThemeButton(
                    'Компактная тема',
                    AppTheme.compact,
                    themeManager,
                  ),

                  const SizedBox(height: 20),

                  // Дополнительная информация о текущей теме
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.secondarySystemBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Текущая тема: ${theme.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('ID: ${theme.id}'),
                        Text('Темная: ${theme.isDark ? 'Да' : 'Нет'}'),
                        Text(
                          'Label цвет: #${theme.label.value.toRadixString(16).toUpperCase()}',
                        ),
                        Text(
                          'Фон: #${theme.secondarySystemBackground.value.toRadixString(16).toUpperCase()}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeButton(
    String name,
    CustomTheme theme,
    ThemeManager themeManager,
  ) {
    final isActive = themeManager.currentTheme.id == theme.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: CupertinoButton(
        color: isActive
            ? CupertinoColors.activeBlue
            : CupertinoColors.systemGrey5,
        onPressed: () {
          themeManager.setTheme(theme);
        },
        child: Text(
          name,
          style: TextStyle(
            color: isActive ? CupertinoColors.white : CupertinoColors.label,
          ),
        ),
      ),
    );
  }
}
