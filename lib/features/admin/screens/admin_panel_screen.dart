import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../theme/theme_manager.dart';
import 'routes_admin_screen.dart';
import 'pricing_admin_screen.dart';
import 'schedule_admin_screen.dart';
import 'locations_admin_screen.dart';
import 'baggage_pricing_admin_screen.dart';
import 'fixed_prices_admin_screen.dart';
// import 'admin_routes_screen.dart'; // Скрыто - старое управление маршрутами

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _currentIndex = 0;

  // Убрана вкладка "Предуст." - оставлены только рабочие разделы
  // "Фикс. цены" теперь первая (это управление маршрутами с картой)
  final List<Map<String, dynamic>> _menuItems = [
    {'index': 0, 'title': 'Фикс. цены', 'icon': CupertinoIcons.money_dollar},
    {'index': 1, 'title': 'Маршруты', 'icon': CupertinoIcons.map},
    {'index': 2, 'title': 'Цены', 'icon': CupertinoIcons.tag},
    {'index': 3, 'title': 'Расписание', 'icon': CupertinoIcons.clock},
    {'index': 4, 'title': 'Места', 'icon': CupertinoIcons.location},
    {'index': 5, 'title': 'Багаж', 'icon': CupertinoIcons.cube_box},
  ];

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      color: theme.systemBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Заголовок + меню в одном компактном блоке
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: theme.secondarySystemBackground,
                border: Border(
                  bottom: BorderSide(
                    color: theme.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Заголовок
                  Text(
                    'Панель диспетчера',
                    style: TextStyle(
                      color: theme.label,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Первый ряд - 3 кнопки
                  Row(
                    children: _menuItems.sublist(0, 3).map((item) {
                      return Expanded(
                        child: _buildMenuButton(theme, item),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  // Второй ряд - 3 кнопки
                  Row(
                    children: _menuItems.sublist(3, 6).map((item) {
                      return Expanded(
                        child: _buildMenuButton(theme, item),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Контент выбранного экрана
            Expanded(child: _buildCurrentScreen()),
          ],
        ),
      ),
    );
  }

  // Кнопка меню - компактная в стиле приложения
  Widget _buildMenuButton(dynamic theme, Map<String, dynamic> item) {
    final bool isSelected = _currentIndex == item['index'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = item['index'];
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.primary.withOpacity(0.12)
              : theme.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primary : theme.separator,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item['icon'] as IconData,
              size: 20,
              color: isSelected ? theme.primary : theme.secondaryLabel,
            ),
            const SizedBox(height: 3),
            Text(
              item['title'] as String,
              style: TextStyle(
                color: isSelected ? theme.primary : theme.secondaryLabel,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const FixedPricesAdminScreen(); // Фикс. цены теперь первая (с картой)
      case 1:
        return const RoutesAdminScreen(); // Маршруты
      case 2:
        return const PricingAdminScreen(); // Цены
      case 3:
        return const ScheduleAdminScreen(); // Расписание
      case 4:
        return const LocationsAdminScreen(); // Места
      case 5:
        return const BaggagePricingAdminScreen(); // Багаж
      default:
        return const FixedPricesAdminScreen();
    }
  }
}
