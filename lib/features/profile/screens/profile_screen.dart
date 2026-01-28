import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/theme_manager.dart';
import '../../settings/screens/settings_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../tracking/screens/tracking_screen.dart';
import '../../home/screens/home_screen.dart'; // Добавляем импорт HomeScreen
import 'about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = true;
  UserType? _currentUserType; // Актуальный тип пользователя из SharedPreferences
  
  // Секретный тап для входа диспетчера
  int _secretTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      // Используем AuthProvider вместо старого AuthService
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser; // Теперь это User объект
      
      // Загружаем актуальный тип пользователя из SharedPreferences  
      final prefs = await SharedPreferences.getInstance();
      final userTypeString = prefs.getString('user_type') ?? 'client';
      final userType = userTypeString == 'dispatcher' 
          ? UserType.dispatcher 
          : UserType.client;
      
      print('📱 [PROFILE] Загружаем данные пользователя из AuthProvider');
      print('📱 [PROFILE] User: $user');
      print('📱 [PROFILE] Актуальный тип из SharedPreferences: $userType');
      print('📱 [PROFILE] Текущая UI должна показывать тип: ${userType == UserType.dispatcher ? "Диспетчер" : "Клиент"}');
      print('📱 [PROFILE] Кнопка должна показывать: "Переключиться в режим ${userType == UserType.dispatcher ? "клиента" : "диспетчера"}"');
      
      // ВАЖНО: Синхронизируем тип с HomeScreen при загрузке
      final homeScreenState = HomeScreen.currentState;
      if (homeScreenState != null) {
        homeScreenState.updateUserType(userType);
        print('✅ [PROFILE] Синхронизировали тип с HomeScreen: $userType');
      }
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _currentUserType = userType;
        });
      }
    } catch (e) {
      // Обработка ошибки - показываем сообщение пользователю
      if (mounted) {
        print('❌ [PROFILE] Ошибка загрузки данных пользователя: $e');
        // Можно добавить показ ошибки пользователю через SnackBar или диалог
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Обработка секретных тапов для входа диспетчера
  void _handleSecretTap() {
    final now = DateTime.now();

    // Сброс счетчика если прошло больше 3 секунд с последнего тапа
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 3) {
      _secretTapCount = 0;
    }

    _secretTapCount++;
    _lastTapTime = now;

    print('🔒 Секретный тап (Профиль) $_secretTapCount/7');

    if (_secretTapCount >= 7) {
      _secretTapCount = 0;
      _showDispatcherLogin();
    }
  }

  /// Показать диалог входа диспетчера
  void _showDispatcherLogin() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Вход диспетчера'),
        content: const Text(
          'Введите пароль диспетчера для доступа к административной панели.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Отмена'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Войти'),
            onPressed: () async {
              Navigator.pop(context);
              // Временный вход без пароля для демо
              await AuthService.instance.upgradeToDispatcher();
              // Обновляем данные пользователя
              await _loadUserData();
            },
          ),
        ],
      ),
    );
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

          // Кнопка переключения режима (только для админов)
          if (context.watch<AuthProvider>().isAdmin)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAdminSwitchButton(theme),
            ),

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
          // Аватар (с секретным тапом для входа диспетчера)
          GestureDetector(
            onTap: _handleSecretTap,
            child: Container(
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
            icon: CupertinoIcons.location,
            title: 'Отслеживание',
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const TrackingScreen(),
                ),
              );
            },
          ),

          Divider(height: 1, color: theme.separator.withOpacity(0.2)),

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

  /// Кнопка переключения в режим диспетчера (только для админов)
  Widget _buildAdminSwitchButton(theme) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: CupertinoColors.systemOrange,
        onPressed: _switchToDispatcher,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.person_badge_plus,
              color: CupertinoColors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _currentUserType == UserType.dispatcher
                  ? 'Переключиться в режим клиента'
                  : 'Переключиться в режим диспетчера',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Переключение между режимами клиента и диспетчера
  Future<void> _switchToDispatcher() async {
    try {
      // Определяем новый тип на основе ТЕКУЩЕГО типа из SharedPreferences
      final newType = _currentUserType == UserType.dispatcher
          ? UserType.client
          : UserType.dispatcher;

      // Показываем диалог подтверждения ПЕРЕД переключением
      final shouldSwitch = await showCupertinoDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: Text(
            newType == UserType.dispatcher
                ? 'Переключиться в режим диспетчера?'
                : 'Переключиться в режим клиента?',
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Отмена'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Переключиться'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        ),
      );

      // Если пользователь отменил - выходим
      if (shouldSwitch != true || !mounted) return;

      print('🔄 [PROFILE] Переключаем с $_currentUserType на $newType');

      // Сохраняем новый тип
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_type', newType.toString().split('.').last);

      // Мгновенно обновляем UI
      if (mounted) {
        setState(() {
          _currentUserType = newType;
        });
      }

      if (!mounted) return;

      // Обновляем HomeScreen без навигации
      final homeScreenState = HomeScreen.currentState;
      if (homeScreenState != null) {
        // Обновляем тип пользователя в HomeScreen
        homeScreenState.updateUserType(newType);
        print('✅ [PROFILE] HomeScreen обновлен с новым типом: $newType');
      } else {
        print('❌ [PROFILE] HomeScreen.currentState не найден, используем навигацию');
        // Fallback к навигации если HomeScreen не доступен
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (mounted) {
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false,
                );
              }
            });
          }
        });
      }
    } catch (e) {
      print('❌ [PROFILE] Ошибка переключения режима: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (dialogContext) => CupertinoAlertDialog(
            title: const Text('Ошибка'),
            content: Text('Не удалось переключить режим: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        );
      }
    }
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
