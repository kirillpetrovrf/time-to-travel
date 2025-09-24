import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../widgets/pickup_dropoff_widget.dart';

class LocationsAdminScreen extends StatelessWidget {
  const LocationsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Управление местами',
          style: TextStyle(color: theme.label),
        ),
      ),
      child: SafeArea(
        child: PickupDropoffWidget(theme: theme),
      ),
    );
  }
}
