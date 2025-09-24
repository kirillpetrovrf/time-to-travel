import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme_manager.dart';
import 'routes_admin_screen.dart';
import 'pricing_admin_screen.dart';
import 'schedule_admin_screen.dart';
import 'locations_admin_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: theme.secondarySystemBackground,
        activeColor: theme.primary,
        inactiveColor: theme.secondaryLabel,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.location_circle),
            label: 'Маршруты',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.money_dollar_circle),
            label: 'Цены',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.time),
            label: 'Расписание',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.map_pin_ellipse),
            label: 'Места',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return const RoutesAdminScreen();
          case 1:
            return const PricingAdminScreen();
          case 2:
            return const ScheduleAdminScreen();
          case 3:
            return const LocationsAdminScreen();
          default:
            return const RoutesAdminScreen();
        }
      },
    );
  }
}
