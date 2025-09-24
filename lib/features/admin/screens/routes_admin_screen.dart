import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../widgets/route_settings_widget.dart';

class RoutesAdminScreen extends StatelessWidget {
  const RoutesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Управление маршрутами',
          style: TextStyle(color: theme.label),
        ),
      ),
      child: SafeArea(
        child: RouteSettingsWidget(theme: theme),
      ),
    );
  }
}
