import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../models/user_role.dart';
import '../../../services/auth_service.dart';

/// Экран выбора роли пользователя (водитель или пассажир)
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Иконка приложения
              const Icon(
                CupertinoIcons.car_detailed,
                size: 80,
                color: CupertinoColors.activeBlue,
              ),

              const SizedBox(height: 24),

              // Заголовок
              const Text(
                'Добро пожаловать!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Подзаголовок
              const Text(
                'Выберите, как вы хотите использовать приложение',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Кнопка "Я водитель"
              _RoleCard(
                role: UserRole.driver,
                icon: CupertinoIcons.car_detailed,
                title: UserRole.driver.displayName,
                description: UserRole.driver.description,
                color: CupertinoColors.activeBlue,
                onTap: () => _selectRole(context, UserRole.driver),
              ),

              const SizedBox(height: 16),

              // Кнопка "Я пассажир"
              _RoleCard(
                role: UserRole.passenger,
                icon: CupertinoIcons.person_2_fill,
                title: UserRole.passenger.displayName,
                description: UserRole.passenger.description,
                color: CupertinoColors.activeGreen,
                onTap: () => _selectRole(context, UserRole.passenger),
              ),

              const SizedBox(height: 32),

              // Информация
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.info_circle,
                      size: 20,
                      color: CupertinoColors.systemGrey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Вы сможете изменить роль в настройках приложения',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
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

  Future<void> _selectRole(BuildContext context, UserRole role) async {
    print('🎯 [ROLE_SELECTION] Пользователь выбрал роль: ${role.displayName}');

    // Сохраняем выбранную роль
    await AuthService.instance.saveUserRole(role);
    print('✅ [ROLE_SELECTION] Роль сохранена в SharedPreferences');

    // Переходим на соответствующий экран
    if (context.mounted) {
      if (role == UserRole.driver) {
        print('🚗 [ROLE_SELECTION] Переход на экран водителя');
        Navigator.of(context).pushReplacementNamed('/driver_home');
      } else {
        print('👤 [ROLE_SELECTION] Переход на экран пассажира');
        Navigator.of(context).pushReplacementNamed('/passenger_home');
      }
    }
  }
}

/// Карточка выбора роли
class _RoleCard extends StatelessWidget {
  final UserRole role;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 32, color: color),
            ),

            const SizedBox(width: 16),

            // Текст
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),

            // Стрелка
            Icon(CupertinoIcons.chevron_right, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}
