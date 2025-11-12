import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../widgets/baggage_pricing_settings_widget.dart';

/// Экран настройки цен на багаж в админ-панели диспетчера
class BaggagePricingAdminScreen extends StatelessWidget {
  const BaggagePricingAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      color: theme.systemBackground,
      child: SafeArea(child: BaggagePricingSettingsWidget(theme: theme)),
    );
  }
}
