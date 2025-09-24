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

  final Map<int, String> _segments = {
    0: 'Маршруты',
    1: 'Цены',
    2: 'Расписание',
    3: 'Места',
  };

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      color: theme.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Заголовок админ панели
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF), // Белый цвет
                border: Border(
                  bottom: BorderSide(
                    color: theme.separator.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: Text(
                'Административная панель',
                style: TextStyle(
                  color: theme.label,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  inherit: false,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Сегментированный контрол
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF), // Белый цвет
                border: Border(
                  bottom: BorderSide(
                    color: theme.separator.withOpacity(0.3),
                    width: 0.5,
                  ),
                ),
              ),
              child: CupertinoSlidingSegmentedControl<int>(
                backgroundColor: theme.tertiarySystemBackground,
                thumbColor: theme.secondarySystemBackground,
                groupValue: _currentIndex,
                onValueChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _currentIndex = value;
                    });
                  }
                },
                children: _segments.map(
                  (key, value) => MapEntry(
                    key,
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        value,
                        style: TextStyle(
                          color: _currentIndex == key
                              ? theme.label
                              : theme.secondaryLabel,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Контент выбранного экрана
            Expanded(child: _buildCurrentScreen()),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
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
  }
}
