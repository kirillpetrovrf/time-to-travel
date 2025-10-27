import 'package:flutter/cupertino.dart';
import '../../../services/permission_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/booking_service.dart';
import '../../../theme/theme_manager.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'address_autocomplete_test_screen.dart';
import 'package:permission_handler/permission_handler.dart';

/// Экран настроек приложения
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _locationEnabled = false;
  bool _locationPermission = false;
  bool _notificationPermission = false;
  bool _isLoading = true;
  int _pendingNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    final permissionService = PermissionService.instance;

    final locationEnabled = await permissionService.isLocationEnabled();
    final locationPermission = await permissionService.hasLocationPermission();
    final notificationPermission = await permissionService
        .hasNotificationPermission();

    // Считаем реальное количество уведомлений из заказов
    final notificationsCount = await _getNotificationsCount();

    setState(() {
      _locationEnabled = locationEnabled;
      _locationPermission = locationPermission;
      _notificationPermission = notificationPermission;
      _pendingNotificationsCount = notificationsCount;
      _isLoading = false;
    });
  }

  /// Получить количество запланированных уведомлений (только БУДУЩИЕ)
  Future<int> _getNotificationsCount() async {
    try {
      final bookingService = BookingService();
      final bookings = await bookingService.getCurrentClientBookings();

      int count = 0;
      final now = DateTime.now();

      debugPrint('🔔 [SETTINGS] Подсчет уведомлений...');
      debugPrint('🔔 [SETTINGS] Текущее время: $now');
      debugPrint('🔔 [SETTINGS] Количество заказов: ${bookings.length}');

      for (final booking in bookings) {
        // Парсим время отправления
        final timeParts = booking.departureTime.split(':');
        final departureDateTime = DateTime(
          booking.departureDate.year,
          booking.departureDate.month,
          booking.departureDate.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );

        debugPrint('🔔 [SETTINGS] --- Заказ #${booking.id} ---');
        debugPrint('🔔 [SETTINGS]   Время отправления: $departureDateTime');

        // Уведомление за 1 день (в 9:00 утра)
        final reminderDate = departureDateTime.subtract(
          const Duration(days: 1),
        );
        final notification24h = DateTime(
          reminderDate.year,
          reminderDate.month,
          reminderDate.day,
          9, // 9:00 утра
          0,
        );

        // ✅ ИСПРАВЛЕНО: Проверяем, что уведомление в БУДУЩЕМ
        if (notification24h.isAfter(now)) {
          count++;
          debugPrint(
            '🔔 [SETTINGS]   ✅ Уведомление за 1 день: $notification24h (БУДУЩЕЕ)',
          );
        } else {
          debugPrint(
            '🔔 [SETTINGS]   ⏱️ Уведомление за 1 день: $notification24h (ПРОШЛОЕ - не считаем)',
          );
        }

        // Уведомление за 1 час
        final notification1h = departureDateTime.subtract(
          const Duration(hours: 1),
        );

        // ✅ ИСПРАВЛЕНО: Проверяем, что уведомление в БУДУЩЕМ
        if (notification1h.isAfter(now)) {
          count++;
          debugPrint(
            '🔔 [SETTINGS]   ✅ Уведомление за 1 час: $notification1h (БУДУЩЕЕ)',
          );
        } else {
          debugPrint(
            '🔔 [SETTINGS]   ⏱️ Уведомление за 1 час: $notification1h (ПРОШЛОЕ - не считаем)',
          );
        }
      }

      debugPrint('🔔 [SETTINGS] ========================================');
      debugPrint('🔔 [SETTINGS] ИТОГО: $count действующих уведомлений');
      debugPrint('🔔 [SETTINGS] ========================================');

      return count;
    } catch (e) {
      debugPrint('❌ Ошибка подсчёта уведомлений: $e');
      return 0;
    }
  }

  Future<void> _requestLocationPermission() async {
    final permissionService = PermissionService.instance;
    final granted = await permissionService.requestLocationPermission();

    if (granted) {
      _showSuccessDialog('Разрешение на геолокацию получено');
      await _checkPermissions();
    } else {
      _showPermissionDeniedDialog('геолокацию');
    }
  }

  Future<void> _requestNotificationPermission() async {
    final permissionService = PermissionService.instance;
    final granted = await permissionService.requestNotificationPermission();

    if (granted) {
      _showSuccessDialog('Разрешение на уведомления получено');
      await _checkPermissions();
    } else {
      _showPermissionDeniedDialog('уведомления');
    }
  }

  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Успешно'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog(String permissionName) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Разрешение не получено'),
        content: Text(
          'Для полноценной работы приложения необходимо разрешение на $permissionName.\n\n'
          'Вы можете выдать разрешение в настройках устройства.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Открыть настройки'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  /// Открыть экран уведомлений
  Future<void> _openNotificationsScreen() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => const NotificationsScreen()),
    );
    // Обновляем счетчик после возврата
    await _checkPermissions();
  }

  /// Открыть тестовый экран автозаполнения адресов
  Future<void> _openAutocompleteTestScreen() async {
    await Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => const AddressAutocompleteTestScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Настройки'),
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : ListView(
                children: [
                  // Секция: Разрешения
                  _buildSectionHeader('Разрешения приложения'),
                  _buildPermissionTile(
                    icon: CupertinoIcons.location_fill,
                    title: 'Геолокация',
                    subtitle: _getLocationStatusText(),
                    isEnabled: _locationPermission && _locationEnabled,
                    onTap: _locationPermission
                        ? () => openAppSettings()
                        : _requestLocationPermission,
                  ),
                  _buildPermissionTile(
                    icon: CupertinoIcons.bell_fill,
                    title: 'Уведомления',
                    subtitle: _notificationPermission
                        ? 'Разрешено • $_pendingNotificationsCount запланировано'
                        : 'Не разрешено',
                    isEnabled: _notificationPermission,
                    onTap: _notificationPermission
                        ? () => _openNotificationsScreen()
                        : _requestNotificationPermission,
                  ),

                  const SizedBox(height: 20),

                  // Секция: Тестирование уведомлений
                  _buildSectionHeader('Тестирование уведомлений'),
                  _buildTestNotificationTile(
                    icon: CupertinoIcons.timer,
                    title: 'Тест: Сейчас',
                    subtitle: 'Немедленное уведомление (приложение включено)',
                    onTap: () => _testNotificationNow(),
                  ),
                  _buildTestNotificationTile(
                    icon: CupertinoIcons.clock_fill,
                    title: 'Тест: Через 5 секунд',
                    subtitle: 'Уведомление с приложением включенным',
                    onTap: () => _testNotification1Minute(),
                  ),
                  _buildTestNotificationTile(
                    icon: CupertinoIcons.moon_fill,
                    title: 'Тест: Через 10 секунд',
                    subtitle: 'Закройте приложение после нажатия!',
                    onTap: () => _testNotification2Minutes(),
                  ),
                  _buildActionTile(
                    icon: CupertinoIcons.rocket_fill,
                    title: 'Запустить все 3 теста',
                    subtitle: 'Сейчас, через 5 и 10 секунд',
                    color: CupertinoColors.systemOrange,
                    onTap: () => _testAllNotifications(),
                  ),

                  const SizedBox(height: 20),

                  // Секция: Разработка
                  _buildSectionHeader('Разработка'),
                  _buildActionTile(
                    icon: CupertinoIcons.location_north_line_fill,
                    title: 'Автозаполнение адресов',
                    subtitle: 'Тестирование геосаджеста Яндекс.Карт',
                    color: CupertinoColors.systemPurple,
                    onTap: () => _openAutocompleteTestScreen(),
                  ),

                  const SizedBox(height: 20),

                  // Секция: Информация
                  _buildSectionHeader('Информация'),
                  _buildInfoTile(
                    icon: CupertinoIcons.info_circle_fill,
                    title: 'О приложении',
                    subtitle: 'Time to Travel v1.0.2',
                    onTap: () => _showAboutDialog(),
                  ),

                  const SizedBox(height: 40),

                  // Кнопка выхода
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoButton.filled(
                      child: const Text('Выйти из аккаунта'),
                      onPressed: () => _showLogoutDialog(),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.secondaryLabel.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: CupertinoListTile(
        leading: Icon(
          icon,
          color: isEnabled
              ? CupertinoColors.systemGreen
              : CupertinoColors.systemRed,
          size: 28,
        ),
        title: Text(title, style: TextStyle(color: theme.label)),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isEnabled
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemRed,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          CupertinoIcons.chevron_forward,
          color: theme.secondaryLabel.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: CupertinoListTile(
        leading: Icon(
          icon,
          color: color ?? CupertinoColors.systemBlue,
          size: 28,
        ),
        title: Text(title, style: TextStyle(color: theme.label)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.secondaryLabel, fontSize: 13),
        ),
        trailing: Icon(
          CupertinoIcons.chevron_forward,
          color: theme.secondaryLabel.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildTestNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: CupertinoListTile(
        leading: Icon(icon, color: CupertinoColors.systemPurple, size: 28),
        title: Text(title, style: TextStyle(color: theme.label)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.secondaryLabel, fontSize: 13),
        ),
        trailing: Icon(
          CupertinoIcons.play_arrow_solid,
          color: CupertinoColors.systemPurple,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: CupertinoListTile(
        leading: Icon(icon, color: CupertinoColors.systemGrey, size: 28),
        title: Text(title, style: TextStyle(color: theme.label)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: theme.secondaryLabel, fontSize: 13),
        ),
        trailing: Icon(
          CupertinoIcons.chevron_forward,
          color: theme.secondaryLabel.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeTile(ThemeManager themeManager) {
    final theme = themeManager.currentTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: CupertinoListTile(
        leading: const Icon(
          CupertinoIcons.moon_fill,
          color: CupertinoColors.systemIndigo,
          size: 28,
        ),
        title: Text('Темная тема', style: TextStyle(color: theme.label)),
        subtitle: Text(
          'Time to Travel Dark (по умолчанию)',
          style: TextStyle(color: theme.secondaryLabel, fontSize: 13),
        ),
        trailing: CupertinoSwitch(
          value: true, // Всегда темная тема
          onChanged: null, // Отключаем переключение
        ),
      ),
    );
  }

  String _getLocationStatusText() {
    if (!_locationEnabled) {
      return 'Геолокация отключена на устройстве';
    } else if (_locationPermission) {
      return 'Разрешено';
    } else {
      return 'Не разрешено';
    }
  }

  void _showAboutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Time to Travel'),
        content: const Text(
          'Приложение для пассажирских перевозок\n\n'
          'Версия: 1.0.2 (build 3)\n\n'
          '© 2024 Time to Travel',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  // Тестовые методы для уведомлений
  Future<void> _testNotificationNow() async {
    await NotificationService.instance.sendTestNotificationNow();
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('✅ Тест запущен'),
          content: const Text('Уведомление отправлено немедленно!'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _testNotification1Minute() async {
    await NotificationService.instance.sendTestNotification1MinuteAppOn();
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('⏱️ Тест запущен'),
          content: const Text(
            'Уведомление придет через 5 секунд.\n\n'
            'Оставьте приложение открытым.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _testNotification2Minutes() async {
    await NotificationService.instance.sendTestNotification2MinuteAppOff();
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('🌙 Тест запущен'),
          content: const Text(
            'Уведомление придет через 10 секунд.\n\n'
            '⚠️ ЗАКРОЙТЕ ПРИЛОЖЕНИЕ СЕЙЧАС!\n\n'
            'Нажмите ОК и закройте приложение для проверки работы уведомлений в фоновом режиме.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK, закрываю приложение'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _testAllNotifications() async {
    await NotificationService.instance.sendAllTestNotifications();
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('🚀 Все тесты запущены!'),
          content: const Text(
            '1️⃣ Сейчас - уведомление отправлено\n'
            '2️⃣ Через 5 секунд (приложение включено)\n'
            '3️⃣ Через 10 секунд (ЗАКРОЙТЕ ПРИЛОЖЕНИЕ!)\n\n'
            'Нажмите ОК и закройте приложение для полного тестирования.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Выйти из аккаунта?'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Выйти'),
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthService.instance.logout();
              if (mounted) {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/auth', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
