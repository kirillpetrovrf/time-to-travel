import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Такси Попутчик'),
        backgroundColor: CupertinoColors.systemBackground,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Добавляем отступ сверху только когда клавиатура скрыта
              SizedBox(height: isKeyboardVisible ? 20 : 60),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Логотип приложения (адаптируем размер при клавиатуре)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isKeyboardVisible ? 60 : 120,
                    height: isKeyboardVisible ? 60 : 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        isKeyboardVisible ? 12 : 24,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        isKeyboardVisible ? 12 : 24,
                      ),
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SizedBox(height: isKeyboardVisible ? 12 : 32),

                  // Заголовок
                  Text(
                    'Добро пожаловать!',
                    style: TextStyle(
                      fontSize: isKeyboardVisible ? 20 : 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: isKeyboardVisible ? 4 : 8),

                  // Подзаголовок
                  Text(
                    'Введите номер телефона для входа или регистрации',
                    style: TextStyle(
                      fontSize: isKeyboardVisible ? 13 : 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: isKeyboardVisible ? 12 : 32),

                  // Поле ввода телефона
                  CupertinoTextField(
                    controller: _phoneController,
                    placeholder: '+7 (999) 123-45-67',
                    keyboardType: TextInputType.phone,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 12.0),
                      child: Icon(
                        CupertinoIcons.phone,
                        color: CupertinoColors.secondaryLabel,
                        size: 20,
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.separator),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  SizedBox(height: isKeyboardVisible ? 16 : 24),

                  // Кнопка входа
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.systemBlue,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Получить код',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors
                                    .white, // Явно указываем белый цвет
                              ),
                            ),
                    ),
                  ),

                  SizedBox(height: isKeyboardVisible ? 8 : 32),

                  // Соглашение (уменьшаем при клавиатуре)
                  if (!isKeyboardVisible)
                    Text(
                      'Продолжая, вы соглашаетесь с условиями использования и политикой конфиденциальности',
                      style: TextStyle(
                        fontSize: isKeyboardVisible ? 10 : 12,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),

              // Добавляем отступ снизу только когда клавиатура скрыта
              SizedBox(height: isKeyboardVisible ? 20 : 60),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_phoneController.text.isEmpty) {
      _showAlert('Ошибка', 'Введите номер телефона');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Имитация запроса к серверу
      await Future.delayed(const Duration(seconds: 2));

      // Сохраняем данные авторизации
      final authService = AuthService.instance;
      await authService.login(
        phoneNumber: _phoneController.text,
        userName: 'Пользователь', // В реальном приложении получим с сервера
      );

      // Сохраняем данные профиля для отображения в интерфейсе
      await authService.saveFormData('user_profile', {
        'userName': 'Пользователь',
        'phoneNumber': _phoneController.text,
      });

      setState(() {
        _isLoading = false;
      });

      // Переход к экрану выбора роли
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/role_selection');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showAlert('Ошибка', 'Произошла ошибка при авторизации: $e');
    }
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
