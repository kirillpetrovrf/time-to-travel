import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../widgets/pricing_settings_widget.dart';

class PricingAdminScreen extends StatelessWidget {
  const PricingAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Управление ценами',
          style: TextStyle(color: theme.label),
        ),
      ),
      child: SafeArea(
        child: PricingSettingsWidget(theme: theme),
      ),
    );
  }
}
