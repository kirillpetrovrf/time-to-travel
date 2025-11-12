import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../widgets/pricing_settings_widget.dart';

class PricingAdminScreen extends StatelessWidget {
  const PricingAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      color: theme.systemBackground,
      child: SafeArea(child: PricingSettingsWidget(theme: theme)),
    );
  }
}
