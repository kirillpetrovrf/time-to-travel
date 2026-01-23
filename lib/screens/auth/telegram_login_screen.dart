import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as provider;
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/time_to_travel_logo.dart';

/// Экран входа через Telegram
class TelegramLoginScreen extends StatefulWidget {
  const TelegramLoginScreen({super.key});

  @override
  State<TelegramLoginScreen> createState() => _TelegramLoginScreenState();
}

class _TelegramLoginScreenState extends State<TelegramLoginScreen> {
  final _phoneController = TextEditingController(text: '+7 '); // ✅ Префикс +7
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer; // Таймер для polling

  @override
  void initState() {
    super.initState();
    // Устанавливаем курсор после +7
    _phoneController.selection = TextSelection.fromPosition(
      TextPosition(offset: _phoneController.text.length),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pollingTimer?.cancel(); // Отменяем polling при выходе
    super.dispose();
  }

  /// Форматирование номера телефона
  String _formatPhone(String phone) {
    // Убираем все символы кроме цифр и +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Добавляем +7 если нужно
    if (!cleaned.startsWith('+')) {
      if (cleaned.startsWith('7')) {
        cleaned = '+$cleaned';
      } else if (cleaned.startsWith('8')) {
        cleaned = '+7${cleaned.substring(1)}';
      } else {
        cleaned = '+7$cleaned';
      }
    }
    
    return cleaned;
  }

  /// Начать авторизацию через Telegram
  Future<void> _startTelegramAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _formatPhone(_phoneController.text);
      final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
      
      // Получаем deep link и authCode
      final response = await authProvider.initTelegramAuth(phone);
      final deepLink = response.deepLink;
      final authCode = response.authCode; // Сохраняем authCode для polling
      
      // Открываем Telegram
      final uri = Uri.parse(deepLink);
      final canLaunch = await canLaunchUrl(uri);
      
      if (canLaunch) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        // Показываем диалог с инструкциями и запускаем polling по authCode
        if (mounted) {
          _showWaitingDialog(authCode);
        }
      } else {
        setState(() {
          _errorMessage = 'Не удалось открыть Telegram. Установите приложение.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  /// Диалог ожидания авторизации в Telegram
  void _showWaitingDialog(String authCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Откройте Telegram'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('1. Нажмите START в боте'),
            const SizedBox(height: 8),
            const Text('2. Вернитесь в приложение'),
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _pollingTimer?.cancel(); // Останавливаем polling
              Navigator.of(context).pop();
              setState(() {
                _isLoading = false;
              });
            },
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    // Запускаем polling по authCode каждые 2 секунды
    _startPolling(authCode);
  }

  /// Запуск polling для проверки авторизации по authCode
  void _startPolling(String authCode) {
    const pollingInterval = Duration(seconds: 2);
    const maxAttempts = 150; // 5 минут (150 * 2 сек = 300 сек)
    int attempts = 0;

    _pollingTimer = Timer.periodic(pollingInterval, (timer) async {
      attempts++;

      try {
        final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.checkTelegramAuthByCode(authCode);
        
        if (success) {
          // Успешная авторизация!
          timer.cancel();
          
          if (mounted) {
            // Закрываем диалог если он открыт
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
            
            // Сбрасываем состояние загрузки
            setState(() {
              _isLoading = false;
            });
            
            print('✅ [TG_LOGIN_SCREEN] Авторизация успешна, выполняем навигацию');
            
            // Явная навигация на главный экран
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/main',
              (route) => false,
            );
          }
        } else if (attempts >= maxAttempts) {
          // Таймаут
          timer.cancel();
          
          if (mounted) {
            Navigator.of(context).pop(); // Закрываем диалог
            setState(() {
              _errorMessage = 'Время ожидания истекло. Попробуйте снова.';
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        // Продолжаем polling при ошибках
        if (attempts >= maxAttempts) {
          timer.cancel();
          
          if (mounted) {
            Navigator.of(context).pop();
            setState(() {
              _errorMessage = 'Ошибка авторизации: $e';
              _isLoading = false;
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Фирменные цвета
    const primaryColor = Color(0xFFDC2626); // Красный
    const darkGray = Color(0xFF2C2C2E); // Тёмно-серый
    
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: SingleChildScrollView( // ✅ Исправление overflow
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // ✅ Фирменный логотип
                const Center(
                  child: TimeToTravelLogo(size: 120),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'Time to Travel',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Вход через Telegram',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Поле ввода телефона с префиксом +7
                CupertinoTextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  placeholder: '+7 928 123-45-67',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(
                      CupertinoIcons.phone,
                      color: primaryColor,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemGrey4,
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d+\s\-()]')),
                    // Не даём удалить +7
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      if (!newValue.text.startsWith('+7 ')) {
                        return oldValue;
                      }
                      return newValue;
                    }),
                  ],
                  onChanged: (value) {
                    // Автоматически добавляем пробел после +7
                    if (value == '+7' && !value.endsWith(' ')) {
                      _phoneController.text = '+7 ';
                      _phoneController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _phoneController.text.length),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // ✅ Кнопка Telegram с белым шрифтом
                CupertinoButton(
                  onPressed: _isLoading ? null : _startTelegramAuth,
                  color: const Color(0xFF0088CC), // Telegram blue
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              CupertinoIcons.paperplane_fill,
                              color: CupertinoColors.white, // ✅ Белая иконка
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Войти через Telegram',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white, // ✅ Белый текст
                              ),
                            ),
                          ],
                        ),
                ),

                // Сообщение об ошибке
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_circle,
                          color: CupertinoColors.systemRed,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // ✅ Информация с белым текстом на тёмном фоне
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: darkGray, // ✅ Тёмно-серый фон
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.info_circle_fill,
                            color: CupertinoColors.white, // ✅ Белая иконка
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Как это работает?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: CupertinoColors.white, // ✅ Белый заголовок
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '1. Введите ваш номер телефона\n'
                        '2. Нажмите кнопку "Войти через Telegram"\n'
                        '3. В Telegram боте нажмите START\n'
                        '4. Готово! Вы автоматически войдёте',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: CupertinoColors.white, // ✅ Белый текст
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
