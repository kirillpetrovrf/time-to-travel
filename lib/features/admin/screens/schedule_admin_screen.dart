import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../widgets/schedule_settings_widget.dart';

class ScheduleAdminScreen extends StatelessWidget {
  const ScheduleAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Управление расписанием',
          style: TextStyle(color: theme.label),
        ),
      ),
      child: SafeArea(
        child: ScheduleSettingsWidget(theme: theme),
      ),
    );
  }
}
