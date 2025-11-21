import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/user_role.dart';

/// Экран профиля пользователя
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _userName;
  String? _phoneNumber;
  UserRole? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final authService = AuthService.instance;
    final userName = await authService.getUserName();
    final phoneNumber = await authService.getPhoneNumber();
    final userRole = await authService.getUserRole();

    if (mounted) {
      setState(() {
        _userName = userName;
        _phoneNumber = phoneNumber;
        _userRole = userRole;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Определяем заголовок в зависимости от роли
    final String title = _userRole == null
        ? 'Профиль'
        : _userRole == UserRole.driver
        ? 'Профиль водителя'
        : 'Профиль пассажира';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
        backgroundColor: Colors.transparent,
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Аватар и имя
        Center(
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.person_fill,
                  size: 50,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _userName ?? 'Пользователь',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _phoneNumber ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 8),
              // Роль пользователя
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _userRole == UserRole.driver
                      ? CupertinoColors.activeBlue.withOpacity(0.1)
                      : CupertinoColors.activeGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _userRole == UserRole.driver
                          ? CupertinoIcons.car_detailed
                          : CupertinoIcons.person_2_fill,
                      size: 18,
                      color: _userRole == UserRole.driver
                          ? CupertinoColors.activeBlue
                          : CupertinoColors.activeGreen,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _userRole?.displayName ?? 'Не выбрано',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _userRole == UserRole.driver
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.activeGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Раздел Настройки
        _buildSectionHeader('Настройки'),
        _buildSettingsList(),

        const SizedBox(height: 24),

        // Раздел Аккаунт
        _buildSectionHeader('Аккаунт'),
        _buildAccountList(),

        const SizedBox(height: 32),

        // Кнопка выхода
        CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: CupertinoColors.destructiveRed,
          onPressed: _showLogoutDialog,
          child: const Text(
            'Выход',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 🧪 ТЕСТОВАЯ КНОПКА (только для разработки)
        if (_userRole == UserRole.passenger)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: CupertinoColors.systemOrange,
              onPressed: _createTestBooking,
              child: const Text(
                '🧪 Создать тестовое бронирование',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),

        // Версия приложения
        Center(
          child: Text(
            'Версия 1.0.0',
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: CupertinoIcons.bell,
            title: 'Уведомления',
            onTap: () {
              // TODO: Открыть настройки уведомлений
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: CupertinoIcons.lock,
            title: 'Конфиденциальность',
            onTap: () {
              // TODO: Открыть настройки конфиденциальности
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: CupertinoIcons.info_circle,
            title: 'О приложении',
            onTap: () {
              // TODO: Показать информацию о приложении
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountList() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingItem(
            icon: CupertinoIcons.person,
            title: 'Редактировать профиль',
            onTap: () {
              // TODO: Открыть редактирование профиля
            },
          ),
          _buildDivider(),
          _buildSettingItem(
            icon: CupertinoIcons.arrow_2_circlepath,
            title: 'Сменить роль',
            subtitle: 'Переключиться между водителем и пассажиром',
            onTap: _showChangeRoleDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24, color: CupertinoColors.activeBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.label,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.systemGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 52),
      height: 1,
      color: CupertinoColors.systemGrey5,
    );
  }

  void _showChangeRoleDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Сменить роль?'),
        content: Text(
          'Вы ${_userRole == UserRole.driver ? "водитель" : "пассажир"}.\n\nХотите переключиться на ${_userRole == UserRole.driver ? "пассажира" : "водителя"}?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            onPressed: () async {
              Navigator.pop(context);
              await _changeRole();
            },
            child: const Text('Переключить'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeRole() async {
    final newRole = _userRole == UserRole.driver
        ? UserRole.passenger
        : UserRole.driver;

    await AuthService.instance.saveUserRole(newRole);

    if (mounted) {
      // Переходим на новый экран в зависимости от роли
      if (newRole == UserRole.driver) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/driver_home');
      } else {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed('/passenger_home');
      }
    }
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    print('🚪 [PROFILE] Выход из аккаунта...');

    // Очищаем роль пользователя (но оставляем авторизацию)
    await AuthService.instance.saveUserRole(UserRole.driver); // Сброс на дефолт

    // Можно также полностью выйти:
    // await AuthService.instance.logout();

    if (mounted) {
      print('➡️ [PROFILE] Переход на экран выбора роли');
      // Переходим на экран выбора роли
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil('/role_selection', (route) => false);
    }
  }

  /// 🧪 Тестовый метод для создания бронирования (только для разработки)
  Future<void> _createTestBooking() async {
    print('🧪 [PROFILE] Создание тестового бронирования...');

    try {
      await DatabaseService.instance.addTestBooking();

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('✅ Успешно'),
            content: const Text(
              'Тестовое бронирование создано!\n\n'
              'Переключитесь на водителя и откройте:\n'
              'Мои поездки → Заявки на бронирование',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ [PROFILE] Ошибка создания тестового бронирования: $e');

      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('❌ Ошибка'),
            content: Text('Не удалось создать бронирование:\n$e'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
