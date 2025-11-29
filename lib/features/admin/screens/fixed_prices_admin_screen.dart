import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../widgets/route_management_widget.dart';

class FixedPricesAdminScreen extends StatelessWidget {
  const FixedPricesAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      color: theme.systemBackground,
      child: SafeArea(
        child: RouteManagementWidget(theme: theme),
      ),
    );
  }
}