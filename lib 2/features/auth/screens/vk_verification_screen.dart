import 'package:flutter/cupertino.dart';
import '../../../services/vk_service.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';

class VKVerificationScreen extends StatefulWidget {
  const VKVerificationScreen({super.key});

  @override
  State<VKVerificationScreen> createState() => _VKVerificationScreenState();
}

class _VKVerificationScreenState extends State<VKVerificationScreen> {
  final VKService _vkService = VKService.instance;
  bool _isVerifying = false;
  bool _isVerified = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final themeManager = context.themeManager;
    final theme = themeManager.currentTheme;

    return CupertinoPageScaffold(
      backgroundColor: theme.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text(
          'Верификация ВКонтакте',
          style: TextStyle(color: theme.label),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Icon(CupertinoIcons.back, color: theme.systemRed),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Иконка VK
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077FF), // VK цвет
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_badge_plus,
                    color: CupertinoColors.white,
                    size: 40,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Заголовок
              Text(
                'Верификация через ВКонтакте',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: theme.label,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Подтвердите свой аккаунт ВКонтакте и получите скидку 30₽ на все поездки',
                style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Преимущества верификации
              _buildBenefitItem(
                icon: CupertinoIcons.money_dollar_circle,
                title: 'Скидка 30₽',
                description: 'На каждую поездку после верификации',
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildBenefitItem(
                icon: CupertinoIcons.checkmark_shield,
                title: 'Повышенная безопасность',
                description: 'Подтвержденная личность для всех пассажиров',
                theme: theme,
              ),

              const SizedBox(height: 16),

              _buildBenefitItem(
                icon: CupertinoIcons.star_circle,
                title: 'Доверие водителей',
                description: 'Верифицированные пользователи имеют приоритет',
                theme: theme,
              ),

              const SizedBox(height: 24),

              // Сообщение об ошибке
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.systemRed, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Статус верификации
              if (_isVerified) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.systemGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        color: theme.systemGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Верификация успешна!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.label,
                              ),
                            ),
                            Text(
                              'Скидка 30₽ активна',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Кнопка верификации
              if (!_isVerified)
                CupertinoButton(
                  color: const Color(0xFF0077FF), // VK цвет
                  onPressed: _isVerifying ? null : _verifyWithVK,
                  child: _isVerifying
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Проверяем...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Войти через ВКонтакте',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                ),

              const SizedBox(height: 16),

              // Кнопка "Пропустить"
              if (!_isVerified)
                CupertinoButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Пропустить',
                    style: TextStyle(fontSize: 16, color: theme.secondaryLabel),
                  ),
                ),

              // Кнопка "Готово" для верифицированных
              if (_isVerified)
                CupertinoButton(
                  color: theme.systemRed,
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Готово',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
    required CustomTheme theme,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: theme.systemRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.systemRed, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.label,
                ),
              ),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: theme.secondaryLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _verifyWithVK() async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final success = await _vkService.authenticate();

      if (success) {
        // Получаем информацию о пользователе
        final userInfo = await _vkService.getCurrentUser();

        if (userInfo != null) {
          setState(() {
            _isVerified = true;
            _isVerifying = false;
          });
        } else {
          setState(() {
            _isVerifying = false;
            _errorMessage = 'Не удалось получить информацию о пользователе';
          });
        }
      } else {
        setState(() {
          _isVerifying = false;
          _errorMessage = 'Ошибка авторизации ВКонтакте';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Произошла ошибка: ${e.toString()}';
      });
    }
  }
}
