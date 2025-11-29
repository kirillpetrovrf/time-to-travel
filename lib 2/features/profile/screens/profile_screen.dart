import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../theme/theme_manager.dart';
import '../../settings/screens/settings_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.getCurrentUser();
      if (mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      // Обработка ошибки - показываем сообщение пользователю
      if (mounted) {
        print('Ошибка загрузки данных пользователя: $e');
        // Можно добавить показ ошибки пользователю через SnackBar или диалог
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      child: Column(
        children: [
          // Кастомный navigationBar с красным фоном
          Container(
            color: theme.primary, // Красный фирменный цвет
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 44,
                child: const Center(
                  child: Text(
                    'Профиль',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Контент
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _buildProfileContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Аватар и основная информация
          _buildUserInfo(theme),

          const SizedBox(height: 32),

          // Настройки
          _buildSettingsSection(theme),

          const SizedBox(height: 32),

          // Кнопка выхода
          _buildLogoutButton(theme),

          // Отступ снизу для системных кнопок навигации
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildUserInfo(theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Аватар
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              size: 40,
              color: theme.primary,
            ),
          ),

          const SizedBox(height: 16),

          // Имя
          Text(
            _currentUser?.name ?? 'Пользователь',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.label,
            ),
          ),

          const SizedBox(height: 8),

          // Телефон
          Text(
            _currentUser?.phone ?? '',
            style: TextStyle(
              fontSize: 16,
              color: theme.secondaryLabel.withOpacity(0.7),
            ),
          ),

          const SizedBox(height: 12),

          // Тип пользователя
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _getUserTypeText(_currentUser?.userType),
              style: TextStyle(
                color: theme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.separator.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            theme: theme,
            icon: CupertinoIcons.settings,
            title: 'Настройки',
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),

          Divider(height: 1, color: theme.separator.withOpacity(0.2)),

          _buildSettingsItem(
            theme: theme,
            icon: CupertinoIcons.bell,
            title: 'Уведомления',
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),

          Divider(height: 1, color: theme.separator.withOpacity(0.2)),

          _buildSettingsItem(
            theme: theme,
            icon: CupertinoIcons.question_circle,
            title: 'Помощь',
            onTap: () {
              // TODO: Открыть экран помощи
            },
          ),

          Divider(height: 1, color: theme.separator.withOpacity(0.2)),

          _buildSettingsItem(
            theme: theme,
            icon: CupertinoIcons.info_circle,
            title: 'О приложении',
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required theme,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: theme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: theme.label, fontSize: 16),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: theme.secondaryLabel.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(theme) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: CupertinoColors.systemRed,
        onPressed: _showLogoutDialog,
        child: const Text(
          'Выйти из аккаунта',
          style: TextStyle(
            color: CupertinoColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getUserTypeText(UserType? userType) {
    switch (userType) {
      case UserType.client:
        return 'Клиент';
      case UserType.dispatcher:
        return 'Диспетчер';
      case null:
        return 'Пользователь';
    }
  }

  void _showLogoutDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Выйти'),
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.instance.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/auth',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
