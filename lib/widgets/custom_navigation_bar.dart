import 'package:flutter/cupertino.dart';
import '../theme/theme_manager.dart';

/// Кастомный navigationBar с поддержкой цвета фона на Android
///
/// CupertinoNavigationBar игнорирует backgroundColor на Android,
/// поэтому используем Container для установки цвета
class CustomNavigationBar extends StatelessWidget {
  final String title;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? leading;
  final Widget? trailing;

  const CustomNavigationBar({
    super.key,
    required this.title,
    this.backgroundColor,
    this.textColor,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    // По умолчанию серый фон navigationBar (как TabBar)
    final bgColor = backgroundColor ?? theme.secondarySystemBackground;
    final titleColor = textColor ?? theme.label;

    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              // Leading (кнопка назад или другое)
              if (leading != null)
                SizedBox(width: 60, child: leading)
              else
                const SizedBox(width: 60),

              // Title по центру
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Trailing (кнопки справа)
              if (trailing != null)
                SizedBox(width: 60, child: trailing)
              else
                const SizedBox(width: 60),
            ],
          ),
        ),
      ),
    );
  }
}
