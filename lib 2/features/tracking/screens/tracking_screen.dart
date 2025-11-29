import 'package:flutter/cupertino.dart';
import '../../../theme/theme_manager.dart';

/// Экран отслеживания заказа
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
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('Отслеживание', style: TextStyle(color: theme.label)),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.location_circle,
                size: 80,
                color: theme.secondaryLabel,
              ),
              const SizedBox(height: 24),
              Text(
                'Отслеживание заказа',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.label,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Здесь будет отображаться карта с текущим местоположением водителя',
                  style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      theme,
                      CupertinoIcons.car_detailed,
                      'Статус',
                      'В ожидании',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      theme,
                      CupertinoIcons.time,
                      'Время прибытия',
                      'Не определено',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      theme,
                      CupertinoIcons.location,
                      'Водитель',
                      'Не назначен',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(theme, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: theme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: theme.secondaryLabel),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: theme.label,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
