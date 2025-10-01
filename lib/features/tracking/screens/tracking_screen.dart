import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';
import '../../../widgets/custom_navigation_bar.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      child: Column(
        children: [
          // Кастомный navigationBar с серым фоном
          const CustomNavigationBar(title: 'Отслеживание'),
          // Контент
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.location,
                    size: 64,
                    color: theme.secondaryLabel.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Отслеживание поездок',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.label,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Здесь будет карта с отслеживанием\nтекущих поездок в реальном времени',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.secondaryLabel.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: theme.secondarySystemBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.separator.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.map,
                          color: theme.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Функция будет доступна после интеграции с Yandex Maps',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.secondaryLabel.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
