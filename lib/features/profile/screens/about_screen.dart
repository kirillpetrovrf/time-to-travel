import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/theme_manager.dart';
import '../../../theme/app_theme.dart';

/// Экран "О программе" с обязательной ссылкой на условия Yandex Maps
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Секретный тап для логотипа
  int _logoTapCount = 0;
  DateTime? _lastLogoTapTime;

  /// Обработка секретных тапов на логотип (7 раз)
  void _handleLogoSecretTap() {
    final now = DateTime.now();

    // Сброс счетчика если прошло больше 3 секунд с последнего тапа
    if (_lastLogoTapTime != null && now.difference(_lastLogoTapTime!).inSeconds > 3) {
      _logoTapCount = 0;
    }

    _logoTapCount++;
    _lastLogoTapTime = now;

    print('🔒 Секретный тап (Логотип) $_logoTapCount/7');

    if (_logoTapCount >= 7) {
      _logoTapCount = 0;
      _showLogoSecretMessage();
    }
  }

  /// Показать секретное сообщение при 7 тапах по логотипу
  void _showLogoSecretMessage() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('🎉 Секретный режим'),
        content: const Text(
          'Поздравляем! Вы нашли секретную пасхалку разработчиков!\n\n'
          'Time to Travel v1.0.0\n'
          'Создано с ❤️ для пассажиров',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Круто!'),
            onPressed: () => Navigator.pop(context),
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
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.secondarySystemBackground,
        middle: Text('О программе', style: TextStyle(color: theme.label)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Логотип и название
              Center(
                child: Column(
                  children: [
                    // Логотип с секретным тапом (7 раз для пасхалки)
                    GestureDetector(
                      onTap: _handleLogoSecretTap,
                      child: Icon(
                        CupertinoIcons.car_detailed,
                        size: 80,
                        color: theme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Time to Travel',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.label,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Версия 1.0.0',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Описание
              _buildSection(
                theme: theme,
                title: 'Описание',
                content:
                    'Приложение для заказа трансфера между городами. '
                    'Групповые и индивидуальные поездки, калькулятор маршрутов.',
              ),

              const SizedBox(height: 24),

              // ОБЯЗАТЕЛЬНАЯ ССЫЛКА НА УСЛОВИЯ YANDEX MAPS (п. 4.1.3.2)
              _buildSection(
                theme: theme,
                title: 'Используемые сервисы',
                content:
                    'Приложение использует Яндекс Карты для расчета маршрутов.',
              ),

              const SizedBox(height: 12),

              // Кнопка со ссылкой на условия
              Container(
                decoration: BoxDecoration(
                  color: theme.secondarySystemBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.separator.withOpacity(0.2)),
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(16),
                  onPressed: () => _openYandexMapsTerms(),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_text,
                        color: theme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Условия использования сервиса Яндекс.Карты',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.label,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Обязательно к прочтению',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.arrow_up_right,
                        color: theme.secondaryLabel,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Контакты
              _buildSection(
                theme: theme,
                title: 'Контакты',
                content:
                    'Email: support@timetotravel.ru\nТелефон: +7 (XXX) XXX-XX-XX',
              ),

              const SizedBox(height: 24),

              // Юридическая информация
              _buildSection(
                theme: theme,
                title: 'Юридическая информация',
                content:
                    'ООО "Time to Travel"\nИНН: XXXXXXXXXXXX\nОГРН: XXXXXXXXXXXXXXX',
              ),

              // Отступ снизу
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required CustomTheme theme,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 16,
            color: theme.secondaryLabel,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _openYandexMapsTerms() async {
    // Обязательная ссылка согласно п. 4.1.3.2 условий Yandex Maps API
    final Uri url = Uri.parse('https://yandex.ru/legal/maps_termsofuse');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        print('❌ Не удалось открыть ссылку: $url');
      }
    } catch (e) {
      print('❌ Ошибка при открытии ссылки: $e');
    }
  }
}
